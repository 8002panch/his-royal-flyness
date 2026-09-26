"""Tests for the Seer adapter (owner: Neil). Run:  python -m brain.test_seer   (or pytest brain/test_seer.py)

Covers what Ved's playbook asks of the adapter: one interface for every source, safe fallback on failure, clean swaps,
plus sanity checks that the True Prince's readout gets sides right.
"""

from __future__ import annotations

from brain.seer import SeerAdapter

SCENES = [
    {},
    {"princess": None, "giants": [], "wind": None},
    {"princess": {"bearing_deg": 50.0, "elevation_deg": 0.0, "distance_cm": 90.0}},
    {"princess": {"bearing_deg": 179.0, "elevation_deg": 0.0, "distance_cm": 90.0}},  # straight behind: unseen
    {"giants": [{"bearing_deg": -70.0, "elevation_deg": 20.0, "distance_cm": 100.0, "approach_cm_s": 400.0, "size_cm": 40.0}]},
    {"wind": {"bearing_deg": 90.0, "strength": 0.8}},
]
CUE_KEYS = {"princess", "giant", "activity", "source", "mode"}
ACTIVITY_KEYS = {"her_L", "her_R", "looming", "escape", "steer", "song"}


def _check_shape(cues: dict) -> None:
    assert CUE_KEYS <= set(cues), cues.keys()
    assert set(cues["activity"]) == ACTIVITY_KEYS
    assert set(cues["giant"]) == {"warning", "side", "eta_s"}
    assert 0.0 <= cues["giant"]["warning"] <= 1.0
    if cues["princess"] is not None:
        p = cues["princess"]
        assert p["side"] in ("left", "ahead", "right") and 0.0 <= p["confidence"] <= 1.0
        assert p["distance"] in ("near", "mid", "far")


def test_same_interface_for_every_source() -> None:
    for source in ("placeholder", "true", "changeling"):
        seer = SeerAdapter(source)
        for scene in SCENES:
            seer.reset()
            for _ in range(5):
                cues = seer.sense(scene)
            _check_shape(cues)
            assert cues["source"] == source


def test_falls_back_to_placeholder_if_the_brain_fails() -> None:
    seer = SeerAdapter("true")

    def broken(_drives):
        raise RuntimeError("simulated brain failure")

    seer._brain.step = broken
    cues = seer.sense(SCENES[2])
    _check_shape(cues)
    assert cues["source"] == "placeholder" and cues.get("error") is True


def test_swap_between_sources() -> None:
    seer = SeerAdapter("placeholder")
    for source in ("true", "changeling", "placeholder", "true"):
        seer.swap(source, seed=1 if source == "changeling" else 0)
        cues = seer.sense(SCENES[2])
        _check_shape(cues)
        assert cues["source"] == source


def test_true_prince_gets_sides_right() -> None:
    seer = SeerAdapter("true")
    for _ in range(25):
        cues = seer.sense(SCENES[2])  # Princess at +50 degrees
    assert cues["princess"] is not None and cues["princess"]["side"] == "right"
    seer.reset()
    for _ in range(25):
        cues = seer.sense(SCENES[4])  # Giant looming from -70 degrees
    assert cues["giant"]["side"] == "left" and cues["giant"]["warning"] > 0.3


def test_unseen_princess_is_not_reported() -> None:
    seer = SeerAdapter("true")
    for _ in range(25):
        cues = seer.sense(SCENES[3])
    assert cues["princess"] is None


if __name__ == "__main__":
    tests = [v for k, v in dict(globals()).items() if k.startswith("test_")]
    for t in tests:
        t()
        print(f"ok  {t.__name__}")
    print(f"{len(tests)} passed")
