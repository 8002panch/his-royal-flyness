"""The simulation: stability, determinism, reset/swap, input validation, the stub, and speed."""

from __future__ import annotations

import time

import numpy as np
import pytest

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES, Brain
from brain.tests.conftest import needs_data


def test_stub_covers_every_input_and_output():
    b = Brain(stub=True)
    out = b.step({g: 1.0 for g in INPUT_GROUPS})
    assert set(out) == set(OUTPUT_NAMES)
    assert all(np.isfinite(v) for v in out.values())


def test_unknown_inputs_are_rejected():
    with pytest.raises(KeyError):
        Brain(stub=True).step({"not_a_group": 1.0})


def test_drives_are_clamped_and_sanitized():
    b = Brain(stub=True)
    out = b.step({"forward": float("nan"), "left": float("inf"), "right": -3.0})
    assert all(np.isfinite(v) for v in out.values())
    b.reset()
    ref = Brain(stub=True)
    assert b.step({"left": 5.0}) == ref.step({"left": 1.0})


def test_bad_kinds_are_rejected():
    with pytest.raises(ValueError):
        Brain("real_prince")
    with pytest.raises(ValueError):
        Brain(stub=True).swap("prince")


@needs_data
@pytest.mark.parametrize("kind", ["true", "changeling"])
def test_long_random_play_stays_stable(kind):
    b = Brain(kind)
    rng = np.random.default_rng(0)
    worst = 0.0
    for _ in range(1500):  # 30 s of random button and sense presses
        drives = {g: float(rng.random() < 0.15) * float(rng.uniform(0.3, 1.0)) for g in INPUT_GROUPS}
        out = np.array(list(b.step(drives).values()))
        assert np.isfinite(out).all()
        worst = max(worst, float(np.abs(out).max()))
    r = b._impl.r
    assert np.isfinite(r).all() and r.min() >= 0.0 and r.max() <= 1.0
    assert worst < 200.0
    assert np.mean(r > 0.9) < 0.05, "a runaway would saturate much of the brain"


@needs_data
def test_same_inputs_and_noise_give_identical_outputs(true_brain):
    rng = np.random.default_rng(3)
    seq = [{g: float(rng.random() < 0.2) for g in INPUT_GROUPS} for _ in range(60)]

    def run():
        true_brain.reset()
        true_brain._impl.rng = np.random.default_rng(42)
        return np.array([[o[k] for k in OUTPUT_NAMES] for o in (true_brain.step(d) for d in seq)])

    assert np.array_equal(run(), run())


@needs_data
def test_reset_and_swap_round_trip(true_brain):
    true_brain.reset()
    assert np.array_equal(true_brain._impl.r, true_brain._impl.r0)
    true_brain._impl.rng = np.random.default_rng(1)
    a = [true_brain.step({"forward": 1.0})["DNp09"] for _ in range(20)]
    true_brain.swap("changeling", 2)
    assert true_brain.kind == "changeling"
    true_brain.swap("true", 0)
    true_brain._impl.rng = np.random.default_rng(1)
    b = [true_brain.step({"forward": 1.0})["DNp09"] for _ in range(20)]
    assert a == b


@needs_data
def test_rest_is_quiet(true_brain):
    true_brain.reset()
    outs = [true_brain.step({}) for _ in range(50)]
    assert max(abs(o[k]) for o in outs for k in OUTPUT_NAMES) < 6.0, "no output should fire strongly with no input"


@needs_data
def test_a_tick_fits_the_20_ms_budget(true_brain):
    """Best of three 100-tick batches, so a background process can't fail the test; the sustained-load numbers
    (2.5 minutes on the M2: median ~6 ms, p99 mostly 6.4-8 ms) are in brain/model.py."""
    batches = []
    for _ in range(3):
        true_brain.reset()
        times = []
        for i in range(100):
            t0 = time.perf_counter()
            true_brain.step({"forward": 0.6, "left": 0.7} if i % 2 else {"her_L": 0.5})
            times.append(time.perf_counter() - t0)
        batches.append(np.array(times[10:]) * 1000)
    best = min(batches, key=np.median)
    assert np.median(best) < 12.0, f"median {np.median(best):.1f} ms"
    assert np.percentile(best, 95) < 20.0, f"p95 {np.percentile(best, 95):.1f} ms"
