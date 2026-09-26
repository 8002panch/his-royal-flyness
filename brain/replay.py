"""Open-loop replay of a recorded round: the shared engine behind the Chronicler and run_trials.

Owner: Neil.

A recording is one entry per 20 ms tick: {player_name: {input_group: drive}}. Replaying it with one player's drives removed
("what would the Prince have done without Ava?") and comparing with the full replay gives each player's credit.

All replays use the same deterministic brain settings (one 20 ms step per tick, no noise), so differences come only from the
removed inputs, never from random noise. They don't re-simulate the flight path (open loop), and the Chronicle says so.
"""

from __future__ import annotations

import numpy as np

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES
from brain.model import Params, RateModel

Recording = list[dict[str, dict[str, float]]]

# Deterministic, cheaper settings for every replay (6 ms per tick instead of 11).
REPLAY_PARAMS = dict(dt=0.020, noise_sd=0.0)

# What counts as each kind of contribution, from the output z-scores of one tick.
ESCAPE_Z = 10.0   # DNp01 above this = an escape dart
SONG_Z = 4.0      # pIP10 above this = singing


def combine(tick: dict[str, dict[str, float]], without: str | None = None) -> dict[str, float]:
    """Sum every player's drives for one tick (optionally leaving one player out), capped at 1."""
    drives = {g: 0.0 for g in INPUT_GROUPS}
    for player, d in tick.items():
        if player == without:
            continue
        for g, v in d.items():
            drives[g] = min(1.0, drives[g] + float(v))
    return drives


def replay(model: RateModel, recording: Recording, without: str | None = None) -> np.ndarray:
    """Outputs (ticks x OUTPUT_NAMES) for the recording, optionally with one player's inputs removed."""
    model.reset()
    return np.array([[model.step(combine(tick, without))[o] for o in OUTPUT_NAMES] for tick in recording])


def metrics(outputs: np.ndarray) -> dict[str, np.ndarray]:
    """Per-tick behavior signals from an outputs array (ticks x OUTPUT_NAMES)."""
    col = {o: outputs[:, i] for i, o in enumerate(OUTPUT_NAMES)}
    return {
        "thrust": np.maximum(col["DNp09"], 0.0),
        "brake": np.maximum(col["MDN"], 0.0),
        "turn": col["DNa02_R"] - col["DNa02_L"],
        "altitude": np.maximum(col["DNg02"], 0.0) - np.maximum(col["DNp07_10"], 0.0) / 8.0,
        "escape": (col["DNp01"] > ESCAPE_Z).astype(float),
        "song": (col["pIP10"] > SONG_Z).astype(float),
    }


# Per-tick changes smaller than this don't count (side effects, not steering). Escape and song are 0/1 per tick.
DEADBAND = {"thrust": 2.0, "brake": 1.0, "turn": 2.0, "altitude": 1.0, "escape": 0.5, "song": 0.5}
# A category only gets shares if its total change across players reaches this many tick-units (20 ticks = 0.4 s).
# Escapes are short (one dart is ~5-15 ticks), so they need a lower bar.
MIN_TOTAL = {"thrust": 20.0, "brake": 20.0, "turn": 20.0, "altitude": 20.0, "escape": 3.0, "song": 5.0}


def credit(full: np.ndarray, without: dict[str, np.ndarray]) -> dict[str, dict[str, float]]:
    """Share of each behavior that disappears when each player is removed. Shares within a category sum to 1."""
    m_full = metrics(full)
    raw = {}
    for p, out in without.items():
        m = metrics(out)
        raw[p] = {}
        for k in m_full:
            diff = np.abs(m_full[k] - m[k])
            raw[p][k] = float(np.sum(np.where(diff >= DEADBAND[k], diff, 0.0)))
    categories = list(m_full)
    shares: dict[str, dict[str, float]] = {p: {} for p in without}
    active = []
    for k in categories:
        total = sum(raw[p][k] for p in without)
        if total >= MIN_TOTAL[k]:
            active.append(k)
        for p in without:
            shares[p][k] = raw[p][k] / total if total >= MIN_TOTAL[k] else 0.0
    for p in without:
        shares[p]["overall"] = float(np.mean([shares[p][k] for k in active])) if active else 0.0
    return shares


def credit_from_recording(recording: Recording, kind: str = "true", seed: int = 0) -> dict[str, dict[str, float]]:
    """Single-process version (for run_trials, tests and offline use). The live game uses server/chronicler.py."""
    model = RateModel(kind, seed, Params(**REPLAY_PARAMS))
    players = sorted({p for tick in recording for p in tick})
    full = replay(model, recording)
    return credit(full, {p: replay(model, recording, without=p) for p in players})
