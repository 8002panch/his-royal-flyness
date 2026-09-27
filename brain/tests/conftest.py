"""Shared fixtures for the brain test suite (owner: Neil).

Run everything:   python -m pytest brain/tests -q
Skip the slow ones (controls matrix, Seer accuracy, Chronicler processes):   python -m pytest brain/tests -q -m "not slow"

The suite needs the built data files in data/ (python -m brain.build_graph && python -m brain.changeling). Tests that need
them are skipped with a clear message if they're missing, so the stub-level tests still run on a fresh clone.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

DATA = Path(__file__).resolve().parents[2] / "data"
HAVE_DATA = all((DATA / f).exists() for f in ("graph_true.npz", "neurons.parquet", "graph_changeling_0.npz",
                                                 "graph_changeling_1.npz", "graph_changeling_2.npz"))
needs_data = pytest.mark.skipif(not HAVE_DATA, reason="data/ not built: run python -m brain.build_graph && python -m brain.changeling")


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: takes more than ~10 s (controls matrix, Seer accuracy, Chronicler processes)")


@pytest.fixture(scope="session")
def graph():
    return dict(np.load(DATA / "graph_true.npz"))


@pytest.fixture(scope="session")
def neurons():
    import pandas as pd

    return pd.read_parquet(DATA / "neurons.parquet")


@pytest.fixture(scope="session")
def true_brain():
    from brain.brain import Brain

    return Brain("true")


@pytest.fixture(scope="session")
def changeling_brains():
    from brain.brain import Brain

    return [Brain("changeling", s) for s in (0, 1, 2)]


def settle(brain, drives: dict, ticks: int = 40, tail: int = 20) -> dict:
    """Hold `drives` for `ticks` ticks from rest; return the mean output over the last `tail` ticks."""
    brain.reset()
    outs = [brain.step(drives) for _ in range(ticks)]
    return {k: float(np.mean([o[k] for o in outs[-tail:]])) for k in outs[0]}
