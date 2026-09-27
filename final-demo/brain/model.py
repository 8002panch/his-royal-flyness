"""The rate model behind brain.brain.Brain (owner: Neil).

    r <- r + (dt / tau) * ( -r + clip(g * W @ r + I - theta, 0, 1) )

Weights (Params.weights):
  "fractions" (default)  W[i, j] = sign[j] * count[i, j] / in_total[i]   each input as its share of all input synapses
  "counts"               W[i, j] = w_syn * sign[j] * count[i, j]           raw synapse counts, as in Shiu et al. 2024
Chosen Sat 26 Sept after probes (docs/TECH.md, "The brain"): "fractions" at gain 4 gives clean, side-specific visual channels
that vanish in every Changeling; "counts" rescues foreleg taste -> song only at settings that break right-eye steering. Built from data/graph_<kind>.npz by brain/build_graph.py or
brain/changeling.py. Outputs are z-scores of each output group's mean rate against its own resting activity.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
import scipy.sparse as sp

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
IO_SETS = Path(__file__).resolve().parent / "io_sets.json"
PAIRS = (("left", "right"), ("lock_L", "lock_R"), ("her_L", "her_R"), ("loom_L", "loom_R"), ("wind_L", "wind_R"))


@dataclass
class Params:
    dt: float = 0.020        # s per step: one step per 20 ms tick. Sustained 2.5-minute test on the M2 (Sat 17:45):
                             # 1 x 20 ms step = median 5.7-6.3 ms/tick, p99 mostly 6.4-8 ms (one window 18); 2 x 10 ms = median ~12, p99 up to 20.7
    tau: float = 0.020       # s
    weights: str = "fractions"  # "fractions" or "counts" (see module docstring)
    w_syn: float = 0.003        # weight per synapse when weights == "counts"
    gain: float = 4.0           # g, global multiplier on W
    theta: float = 0.0       # threshold
    i_max: float = 1.0       # input current at drive = 1 (per neuron, before side balancing)
    noise_sd: float = 0.05   # noise on input neurons each step (spontaneous activity)
    settle_ticks: int = 100  # 2 s of rest before measuring the baseline
    baseline_ticks: int = 150  # 3 s of rest to measure mean and spread
    sd_floor: float = 0.01   # smallest spread used for z-scores


def graph_path(kind: str, seed: int) -> Path:
    return DATA / ("graph_true.npz" if kind == "true" else f"graph_changeling_{seed}.npz")


_WEIGHT_CACHE: dict[tuple, sp.csr_matrix] = {}
_BASELINE_CACHE: dict[tuple, tuple[np.ndarray, np.ndarray, np.ndarray]] = {}


def load_weights(path: Path, weights: str = "fractions", w_syn: float = 0.003) -> sp.csr_matrix:
    """Signed weight matrix (rows = receiving neuron). Cached per process: every Brain shares one read-only copy."""
    key = (str(path), weights, w_syn, path.stat().st_mtime if path.exists() else None)
    if key not in _WEIGHT_CACHE:
        _WEIGHT_CACHE[key] = _build_weights(path, weights, w_syn)
    return _WEIGHT_CACHE[key]


def _build_weights(path: Path, weights: str, w_syn: float) -> sp.csr_matrix:
    g = np.load(path)
    n = int(g["n"])
    post, pre, count = g["post"], g["pre"], g["count"]
    sign, in_total = g["sign"].astype(np.float32), g["in_total"].astype(np.float32)
    if weights == "counts":
        w = w_syn * sign[pre] * count.astype(np.float32)
    elif weights == "fractions":
        w = sign[pre] * count.astype(np.float32) / np.maximum(in_total[post], 1.0)
    else:
        raise ValueError(f"weights must be 'counts' or 'fractions', got {weights!r}")
    # duplicates (possible after a Changeling shuffle) are summed, so every row keeps its exact input total
    return sp.csr_matrix((w.astype(np.float32), (post, pre)), shape=(n, n))


class RateModel:
    def __init__(self, kind: str = "true", seed: int = 0, params: Params | None = None) -> None:
        self.p = params or Params()
        neurons = pd.read_parquet(DATA / "neurons.parquet", columns=["index", "bodyId"])
        body_ids = neurons["bodyId"].to_numpy()
        self.n = len(body_ids)
        sets = json.loads(IO_SETS.read_text())
        to_index = lambda ids: np.searchsorted(body_ids, np.asarray(ids, dtype=np.int64))
        self.inputs = {g: to_index(sets["inputs"][g]) for g in INPUT_GROUPS}
        self.outputs = {o: to_index(sets["outputs"][o]) for o in OUTPUT_NAMES}
        self.input_neurons = np.unique(np.concatenate(list(self.inputs.values())))
        # side balancing: both groups of a left/right pair deliver the same total drive even if one side has fewer neurons
        self.input_scale = {g: 1.0 for g in self.inputs}
        for a, b in PAIRS:
            if a in self.inputs and b in self.inputs:
                mean = (len(self.inputs[a]) + len(self.inputs[b])) / 2
                self.input_scale[a] = mean / len(self.inputs[a])
                self.input_scale[b] = mean / len(self.inputs[b])
        self.rng = np.random.default_rng(seed)
        self.pre_scale: np.ndarray | None = None
        self.load(kind, seed)

    # --- wiring -------------------------------------------------------------------------------------------
    def load(self, kind: str, seed: int = 0) -> None:
        self.kind, self.seed = kind, seed
        self.W = load_weights(graph_path(kind, seed), self.p.weights, self.p.w_syn)
        key = (kind, seed, tuple(sorted(vars(self.p).items())), graph_path(kind, seed).stat().st_mtime)
        if key not in _BASELINE_CACHE:
            _BASELINE_CACHE[key] = self._calibrate()
        self.r0, self.mu, self.sd = _BASELINE_CACHE[key]
        self.reset()

    # --- dynamics -----------------------------------------------------------------------------------------
    def reset(self) -> None:
        self.r = self.r0.copy()

    def _current(self, drives: dict[str, float]) -> np.ndarray:
        current = np.zeros(self.n, dtype=np.float32)
        for g, d in drives.items():
            if d > 0:
                current[self.inputs[g]] += self.p.i_max * d * self.input_scale[g]
        return current

    def _substep(self, current: np.ndarray) -> None:
        p = self.p
        noisy = current.copy()
        noisy[self.input_neurons] += self.rng.normal(0.0, p.noise_sd, len(self.input_neurons)).astype(np.float32)
        # pre_scale: an optional per-sender output strength (brain/brain_map.py's alcohol assumption); None for the Seer
        sent = self.r if self.pre_scale is None else self.r * self.pre_scale
        target = np.clip(p.gain * (self.W @ sent) + noisy - p.theta, 0.0, 1.0)
        self.r += (p.dt / p.tau) * (target - self.r)

    def _tick(self, drives: dict[str, float]) -> None:
        current = self._current(drives)
        steps = max(1, round(0.020 / self.p.dt))
        for _ in range(steps):
            self._substep(current)

    def _readout(self) -> np.ndarray:
        return np.array([self.r[self.outputs[o]].mean() for o in OUTPUT_NAMES], dtype=np.float64)

    def step(self, drives: dict[str, float]) -> dict[str, float]:
        self._tick(drives)
        z = (self._readout() - self.mu) / self.sd
        return {o: float(v) for o, v in zip(OUTPUT_NAMES, z)}

    def rates(self) -> dict[str, float]:
        """Raw mean rate per output group (for debugging and the chart)."""
        return {o: float(v) for o, v in zip(OUTPUT_NAMES, self._readout())}

    # --- baseline -----------------------------------------------------------------------------------------
    def _calibrate(self) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        saved_rng = self.rng
        self.rng = np.random.default_rng(12345)  # the baseline is the same every time for a given brain
        self.r = np.zeros(self.n, dtype=np.float32)
        for _ in range(self.p.settle_ticks):
            self._tick({})
        r0 = self.r.copy()
        samples = []
        for _ in range(self.p.baseline_ticks):
            self._tick({})
            samples.append(self._readout())
        samples = np.array(samples)
        self.rng = saved_rng
        return r0, samples.mean(axis=0), np.maximum(samples.std(axis=0), self.p.sd_floor)
