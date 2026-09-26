"""The rate model behind brain.brain.Brain (owner: Neil).

    r <- r + (dt / tau) * ( -r + clip(g * W @ r + I - theta, 0, 1) )

W[i, j] = sign[j] * count[i, j] / in_total[i]: each input is its share of the receiving neuron's input synapses,
with the presynaptic neuron's predicted sign. Built from data/graph_<kind>.npz by brain/build_graph.py or
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


@dataclass
class Params:
    dt: float = 0.010        # s per step (two steps per 20 ms tick)
    tau: float = 0.020       # s
    gain: float = 3.0        # g, tuned in probes
    theta: float = 0.0       # threshold
    i_max: float = 1.0       # input current at drive = 1 (per neuron, before side balancing)
    noise_sd: float = 0.05   # noise on input neurons each step (spontaneous activity)
    settle_ticks: int = 100  # 2 s of rest before measuring the baseline
    baseline_ticks: int = 150  # 3 s of rest to measure mean and spread
    sd_floor: float = 0.01   # smallest spread used for z-scores


def graph_path(kind: str, seed: int) -> Path:
    return DATA / ("graph_true.npz" if kind == "true" else f"graph_changeling_{seed}.npz")


def load_weights(path: Path) -> sp.csr_matrix:
    g = np.load(path)
    n = int(g["n"])
    post, pre, count = g["post"], g["pre"], g["count"]
    sign, in_total = g["sign"].astype(np.float32), g["in_total"].astype(np.float32)
    w = sign[pre] * count.astype(np.float32) / np.maximum(in_total[post], 1.0)
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
        # side balancing: both sides of a pair deliver the same total drive even if one side has fewer neurons
        self.input_scale = {}
        for g, idx in self.inputs.items():
            base, side = g.rsplit("_", 1)
            pair = [len(self.inputs[f"{base}_{s}"]) for s in "LR"]
            self.input_scale[g] = float(np.mean(pair) / len(idx))
        self.rng = np.random.default_rng(seed)
        self._baselines: dict[tuple[str, int], tuple[np.ndarray, np.ndarray, np.ndarray]] = {}
        self.load(kind, seed)

    # --- wiring -------------------------------------------------------------------------------------------
    def load(self, kind: str, seed: int = 0) -> None:
        self.kind, self.seed = kind, seed
        self.W = load_weights(graph_path(kind, seed))
        key = (kind, seed)
        if key not in self._baselines:
            self._baselines[key] = self._calibrate()
        self.r0, self.mu, self.sd = self._baselines[key]
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
        target = np.clip(p.gain * (self.W @ self.r) + noisy - p.theta, 0.0, 1.0)
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
        self.r = np.zeros(self.n, dtype=np.float32)
        for _ in range(self.p.settle_ticks):
            self._tick({})
        r0 = self.r.copy()
        samples = []
        for _ in range(self.p.baseline_ticks):
            self._tick({})
            samples.append(self._readout())
        samples = np.array(samples)
        return r0, samples.mean(axis=0), np.maximum(samples.std(axis=0), self.p.sd_floor)
