"""The neural mechanics: every input drives its own target, only in the True Prince, fast enough to feel responsive."""

from __future__ import annotations

import numpy as np
import pytest

from brain.tests.conftest import needs_data, settle

# input group -> (target output, minimum True Prince z at full drive)
TARGETS = {
    "forward": ("DNp09", 25.0), "back": ("MDN", 3.0), "left": ("DNa02_L", 6.0), "right": ("DNa02_R", 8.0),
    "up": ("DNg02", 3.5), "down": ("DNp07_10", 25.0), "duck": ("DNp01", 60.0), "serenade": ("pIP10", 6.0),
    "lock_L": ("DNa02_L", 12.0), "lock_R": ("DNa02_R", 12.0),
    "her_L": ("seer_her_L", 10.0), "her_R": ("seer_her_R", 10.0), "loom_L": ("seer_loom_L", 50.0),
    "loom_R": ("seer_loom_R", 50.0), "wind_L": ("seer_wind_L", 10.0), "wind_R": ("seer_wind_R", 10.0),
}
OPPOSITE = {"left": "DNa02_R", "right": "DNa02_L", "lock_L": "DNa02_R", "lock_R": "DNa02_L", "her_L": "seer_her_R",
            "her_R": "seer_her_L", "loom_L": "seer_loom_R", "loom_R": "seer_loom_L", "wind_L": "seer_wind_R", "wind_R": "seer_wind_L"}


@needs_data
@pytest.mark.slow
@pytest.mark.parametrize("group", list(TARGETS))
def test_each_input_drives_its_target_only_in_the_true_prince(group, true_brain, changeling_brains):
    target, min_z = TARGETS[group]
    t = settle(true_brain, {group: 1.0})
    worst_changeling = max(abs(settle(b, {group: 1.0})[target]) for b in changeling_brains)
    assert t[target] >= min_z, f"{group} -> {target}: {t[target]:.1f} < {min_z}"
    assert t[target] >= 2.0 * worst_changeling, f"{group}: True {t[target]:.1f} vs Changeling {worst_changeling:.1f}"
    if group in OPPOSITE:  # side-specific inputs must favor their own side strongly
        assert t[target] > 5.0 * max(t[OPPOSITE[group]], 0.5), f"{group}: same side {t[target]:.1f}, other side {t[OPPOSITE[group]]:.1f}"


@needs_data
@pytest.mark.slow
def test_serenade_needs_both_eyes(true_brain):
    both = settle(true_brain, {"serenade": 1.0})["pIP10"]
    one = settle(true_brain, {"lock_L": 1.0})["pIP10"]
    assert both > 1.5 * one, f"both eyes {both:.1f} vs one eye {one:.1f}"


@needs_data
@pytest.mark.slow
def test_every_input_responds_within_80_ms(true_brain):
    for group, (target, _) in TARGETS.items():
        true_brain.reset()
        trace = [true_brain.step({group: 1.0})[target] for _ in range(40)]
        final = float(np.mean(trace[-10:]))
        half = next(i for i, v in enumerate(trace) if v >= final / 2)
        assert half * 20 <= 80, f"{group}: half response at {half * 20} ms"
