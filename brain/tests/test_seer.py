"""The Royal Seer: one interface for every source, correct senses, safe fallback, and a clear True Prince vs Changeling gap."""

from __future__ import annotations

import numpy as np
import pytest

from brain.seer import (BINOCULAR_DEG, SeerAdapter, encode, eye_weights, looming_rate_deg_s, placeholder,
                        to_seer_view)
from brain.tests.conftest import needs_data

SCENES = [
    {},
    {"princess": None, "giants": [], "wind": None},
    {"princess": {"bearing_deg": 50.0, "elevation_deg": 0.0, "distance_cm": 90.0}},
    {"princess": {"bearing_deg": 179.0, "elevation_deg": 0.0, "distance_cm": 90.0}},  # straight behind: unseen
    {"giants": [{"bearing_deg": -70.0, "elevation_deg": 20.0, "distance_cm": 100.0, "approach_cm_s": 400.0, "size_cm": 40.0}]},
    {"wind": {"bearing_deg": 90.0, "strength": 0.8}},
]
CUE_KEYS = {"princess", "giant", "activity", "source", "mode"}


def S(*args, **kwargs) -> SeerAdapter:
    """A Seer that takes exactly one brain step per call (deterministic tests)."""
    return SeerAdapter(*args, realtime=False, **kwargs)
ACTIVITY_KEYS = {"her_L", "her_R", "looming", "escape", "steer", "song"}


def _check_shape(cues: dict) -> None:
    assert CUE_KEYS <= set(cues)
    assert set(cues["activity"]) == ACTIVITY_KEYS
    assert set(cues["giant"]) == {"warning", "side", "eta_s"}
    assert 0.0 <= cues["giant"]["warning"] <= 1.0
    if cues["princess"] is not None:
        p = cues["princess"]
        assert p["side"] in ("left", "ahead", "right") and 0.0 <= p["confidence"] <= 1.0
        assert p["distance"] in ("near", "mid", "far")


def _hold(seer: SeerAdapter, scene: dict, ticks: int = 30) -> dict:
    seer.reset()
    for _ in range(ticks):
        cues = seer.sense(scene)
    return cues


def _approach(seer: SeerAdapter, bearing: float, d0: float, v: float, size: float = 40.0):
    seer.reset()
    t_imp = (d0 - size) / v
    for t in range(int(t_imp / 0.02)):
        yield seer.sense({"giants": [{"bearing_deg": bearing, "elevation_deg": 20.0, "distance_cm": d0 - v * 0.02 * t,
                                      "approach_cm_s": v, "size_cm": size}]}), t_imp - t * 0.02


# --- encoding (no brain needed) -------------------------------------------------------------------------------------------------
def test_eye_fields_have_a_binocular_strip():
    assert eye_weights(0.0) == pytest.approx((1.0, 1.0), abs=0.01)
    assert eye_weights(-60.0) == pytest.approx((1.0, 0.0), abs=0.01)
    assert eye_weights(60.0) == pytest.approx((0.0, 1.0), abs=0.01)
    for b in np.linspace(-150, 150, 61):  # mirror symmetric
        l, r = eye_weights(b)
        assert eye_weights(-b) == pytest.approx((r, l), abs=1e-9)
    assert eye_weights(BINOCULAR_DEG - 4)[1] > 0.8 and eye_weights(BINOCULAR_DEG + 4)[0] < 0.2


def test_looming_grows_as_the_giant_closes_in():
    rates = [looming_rate_deg_s(40, d, 300) for d in (600, 300, 150, 80)]
    assert rates == sorted(rates) and looming_rate_deg_s(40, 100, 0) == 0.0 and looming_rate_deg_s(40, 100, -50) == 0.0
    drives = [encode({"giants": [{"bearing_deg": -80, "elevation_deg": 0, "distance_cm": d, "approach_cm_s": 300, "size_cm": 40}]})["loom_L"]
              for d in (600, 300, 150, 80)]
    assert drives == sorted(drives) and all(0.0 <= x <= 1.0 for x in drives)


def test_princess_drives_the_eye_that_sees_her():
    left = encode({"princess": {"bearing_deg": -60, "elevation_deg": 0, "distance_cm": 100}})
    ahead = encode({"princess": {"bearing_deg": 0, "elevation_deg": 0, "distance_cm": 100}})
    assert left["her_L"] > 0.9 and left["her_R"] < 0.01
    assert ahead["her_L"] > 0.9 and ahead["her_R"] > 0.9
    far = encode({"princess": {"bearing_deg": -60, "elevation_deg": 0, "distance_cm": 1000}})
    assert 0 < far["her_L"] < left["her_L"]


def test_placeholder_reads_the_geometry():
    c = placeholder(SCENES[2])
    assert c["princess"]["side"] == "right"
    g = placeholder({"giants": [{"bearing_deg": -30, "elevation_deg": 0, "distance_cm": 200, "approach_cm_s": 400}]})["giant"]
    assert g["side"] == "left" and g["eta_s"] == pytest.approx(0.5) and 0 < g["warning"] <= 1


# --- the adapter interface --------------------------------------------------------------------------------------------------------
def test_placeholder_source_never_needs_data():
    seer = SeerAdapter("placeholder")
    for scene in SCENES:
        _check_shape(seer.sense(scene))


@needs_data
def test_same_interface_for_every_source():
    for source in ("placeholder", "true", "changeling"):
        seer = S(source)
        for scene in SCENES:
            cues = _hold(seer, scene, 5)
            _check_shape(cues)
            assert cues["source"] == source


@needs_data
def test_falls_back_to_placeholder_if_the_brain_fails():
    seer = S("true")

    def broken(_drives):
        raise RuntimeError("simulated brain failure")

    seer._brain.step = broken
    cues = seer.sense(SCENES[2])
    _check_shape(cues)
    assert cues["source"] == "placeholder" and cues.get("error") is True


@needs_data
def test_swap_between_sources():
    seer = S("placeholder")
    for source in ("true", "changeling", "placeholder", "true"):
        seer.swap(source, seed=1 if source == "changeling" else 0)
        cues = seer.sense(SCENES[2])
        _check_shape(cues)
        assert cues["source"] == source


@needs_data
def test_converts_to_ved_seer_view():
    for source in ("placeholder", "true"):
        seer = S(source)
        for scene in SCENES:
            view = to_seer_view(_hold(seer, scene, 10))
            assert view["t"] == "seer_view" and set(view) >= {"bearing", "distance", "confidence", "giant"}
            assert view["bearing"] in (None, "NW", "N", "NE") and view["distance"] in (None, "NEAR", "MID", "FAR")
            assert set(view["giant"]) == {"direction", "seconds", "confidence"}


@needs_data
def test_shared_brain_runs_buttons_and_senses_in_one_step():
    from brain.brain import Brain

    brain = Brain("true")
    seer = S(brain=brain)
    for _ in range(30):
        cues = seer.sense({"princess": {"bearing_deg": 60, "elevation_deg": 0, "distance_cm": 100}}, extra_drives={"forward": 0.6})
    # Seeing the Princess damps forward drive in this wiring (thrust ~8 with her in view vs ~20 without), so the bar is > 5.
    assert cues["princess"]["side"] == "right" and seer.last_outputs["DNp09"] > 5
    seer.swap("changeling", 1)
    assert brain.kind == "changeling" and brain.seed == 1


# --- the senses themselves (True Prince) ------------------------------------------------------------------------------------------
@needs_data
def test_true_prince_gets_sides_right():
    seer = S("true")
    for bearing, side in ((-70, "left"), (0, "ahead"), (5, "ahead"), (70, "right"), (-140, "left"), (140, "right")):
        c = _hold(seer, {"princess": {"bearing_deg": bearing, "elevation_deg": 0.0, "distance_cm": 120.0}})
        assert c["princess"] is not None and c["princess"]["side"] == side, (bearing, c["princess"])
    for bearing, side in ((-70, "left"), (70, "right")):
        c = _hold(seer, {"giants": [{"bearing_deg": bearing, "elevation_deg": 20, "distance_cm": 100, "approach_cm_s": 400, "size_cm": 40}]})
        assert c["giant"]["side"] == side and c["giant"]["warning"] > 0.3


@needs_data
def test_unseen_princess_is_not_reported():
    assert _hold(S("true"), SCENES[3])["princess"] is None


@needs_data
def test_no_flicker_on_a_steady_scene():
    seer = S("true")
    for bearing in (-45, 0, 45):
        seer.reset()
        cues = [seer.sense({"princess": {"bearing_deg": bearing, "elevation_deg": 0, "distance_cm": 150}})["princess"]
                for _ in range(60)]
        settled = [c["side"] if c else None for c in cues[10:]]
        assert None not in settled and len(set(settled)) == 1, (bearing, settled)


@needs_data
def test_princess_and_giant_together_dont_confuse_each_other():
    c = _hold(S("true"), {"princess": {"bearing_deg": 60, "elevation_deg": 0, "distance_cm": 100},
                                    "giants": [{"bearing_deg": -60, "elevation_deg": 20, "distance_cm": 120, "approach_cm_s": 400, "size_cm": 40}]})
    assert c["princess"]["side"] == "right" and c["giant"]["side"] == "left"


@needs_data
def test_wind_alone_warns_without_a_time_estimate():
    c = _hold(S("true"), {"wind": {"bearing_deg": -90, "strength": 1.0}})
    assert c["giant"]["warning"] > 0.1 and c["giant"]["side"] == "left" and c["giant"]["eta_s"] is None


@needs_data
def test_hybrid_mode_takes_sides_from_geometry_and_strength_from_the_brain():
    scene = {"princess": {"bearing_deg": -80, "elevation_deg": 0, "distance_cm": 100}}
    t = _hold(S("true", mode="hybrid"), scene)["princess"]
    c = _hold(S("changeling", mode="hybrid"), scene)["princess"]
    assert t["side"] == "left" and t["confidence"] > 0.8
    assert c is None or c["confidence"] < 0.3


@needs_data
@pytest.mark.slow
def test_seer_accuracy_true_prince_vs_changelings():
    rng = np.random.default_rng(123)  # fresh scenes, not the calibration or evaluation seeds
    princess = [(float(rng.uniform(-150, 150)), float(rng.uniform(40, 800))) for _ in range(20)]
    giants = [(float(rng.choice([-1, 1]) * rng.uniform(20, 150)), float(rng.uniform(150, 700)), float(rng.uniform(150, 500))) for _ in range(12)]

    def score(source, seed=0):
        seer = S(source, seed)
        sides = 0
        for b, d in princess:
            truth = "ahead" if abs(b) < BINOCULAR_DEG else ("right" if b > 0 else "left")
            p = _hold(seer, {"princess": {"bearing_deg": b, "elevation_deg": 0, "distance_cm": d}}, 40)["princess"]
            sides += p is not None and p["side"] == truth
        warned, leads, eta_err = 0, [], []
        for b, d0, v in giants:
            first = None
            for cues, left in _approach(seer, b, d0, v):
                if first is None and cues["giant"]["warning"] >= 0.3:
                    first = left
                if cues["giant"]["eta_s"] is not None and 0.3 <= left <= 2.0:
                    eta_err.append(abs(cues["giant"]["eta_s"] - left))
            if first is not None:
                warned += 1
                leads.append(first)
        return sides, warned, (np.median(leads) if leads else 0.0), (np.median(eta_err) if eta_err else None)

    sides, warned, lead, eta = score("true")
    assert sides >= 18, f"True Prince Princess sides {sides}/20"
    assert warned == len(giants) and lead >= 0.6, f"True Prince warned {warned}/{len(giants)}, lead {lead:.2f} s"
    assert eta is not None and eta <= 0.25, f"time-to-impact error {eta}"
    for s in (0, 1, 2):
        c_sides, c_warned, _, _ = score("changeling", s)
        assert c_warned == 0 and c_sides <= 12, f"Changeling {s}: sides {c_sides}/20, warned {c_warned}"


# --- real-time stepping and the server integration ----------------------------------------------------------------------------------
@needs_data
def test_realtime_catch_up_steps():
    seer = SeerAdapter("true")
    calls = {"n": 0}
    real = seer._brain.step

    def counting(drives):
        calls["n"] += 1
        return real(drives)

    seer._brain.step = counting
    seer.sense(SCENES[2], dt=0.1)
    assert calls["n"] == 5, "100 ms = five 20 ms steps"
    calls["n"] = 0
    seer.sense(SCENES[2], dt=5.0)
    assert calls["n"] == SeerAdapter.MAX_CATCHUP_STEPS, "long gaps are capped"
    calls["n"] = 0
    seer.sense(SCENES[2], dt=0.001)
    assert calls["n"] == 1, "at least one step per call"


@needs_data
def test_realtime_senses_keep_up_when_called_at_10_hz():
    """The server currently calls sense() only while the Seer scans, at the 10 Hz phone rate. Wall-clock catch-up must give
    the same warning as calling every tick."""
    import time as _time

    scene = SCENES[4]
    every_tick = S("true")
    for _ in range(25):
        a = every_tick.sense(scene)
    ten_hz = SeerAdapter("true")
    ten_hz.sense(scene)
    for _ in range(5):
        _time.sleep(0.1)
        b = ten_hz.sense(scene)
    assert b["giant"]["side"] == a["giant"]["side"] == "left"
    assert abs(b["giant"]["warning"] - a["giant"]["warning"]) < 0.15


@needs_data
def test_plugs_into_the_server_game_session():
    from server.main import GameSession

    for source in ("true", "changeling"):
        session = GameSession("BZKT", seer=SeerAdapter(source))
        session.apply_input({"t": "sense", "role": "seer", "scan": 1}, now=0.0)
        session.apply_input({"t": "move", "role": "wingmaster", "axis": "z", "value": 1}, now=0.0)
        views = []
        for k in range(30):
            session.step(0.02, now=0.02 * k)
            if k % 5 == 0:
                views.append(session.phone_views()[-1])
        view = views[-1]
        assert view["t"] == "seer_view" and view["source"] == source
        assert set(view["giant"]) == {"direction", "seconds", "confidence"}
    # the True Prince should see the Princess the server places ahead-right of the start position
    session = GameSession("BZKT", seer=S("true"))
    session.apply_input({"t": "sense", "role": "seer", "scan": 1}, now=0.0)
    for k in range(25):
        view = session.phone_views()[-1]
    assert view["bearing"] in ("N", "NE") and view["confidence"] > 0.3
