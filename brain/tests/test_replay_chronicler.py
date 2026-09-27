"""Replay and the Chronicler: deterministic replays, sensible credit, robust edge cases."""

from __future__ import annotations

import numpy as np
import pytest

from brain.brain import INPUT_GROUPS
from brain.replay import combine, credit, credit_from_recording, metrics
from brain.tests.conftest import needs_data


def test_combine_sums_players_and_caps_at_one():
    tick = {"Ava": {"forward": 0.7}, "Ben": {"forward": 0.7, "left": 0.2}}
    d = combine(tick)
    assert d["forward"] == 1.0 and d["left"] == 0.2 and set(d) == set(INPUT_GROUPS)
    assert combine(tick, without="Ava")["forward"] == 0.7


def test_credit_shares_sum_to_one_per_active_category():
    rng = np.random.default_rng(0)
    full = rng.normal(size=(200, 16)) * 5
    without = {"A": full * 0.2, "B": full * 0.9}
    shares = credit(full, without)
    for k in ("thrust", "brake", "turn", "altitude"):
        total = shares["A"][k] + shares["B"][k]
        assert total == pytest.approx(1.0) or total == 0.0


@needs_data
def test_replay_is_deterministic_and_credits_the_right_player():
    rec = [{"Ava": {"forward": 0.6} if t < 150 else {}, "Ben": {"left": 0.7} if 150 <= t < 300 else {}} for t in range(300)]
    a = credit_from_recording(rec)
    b = credit_from_recording(rec)
    assert a == b
    # Brain activity carries over ~100 ms after a button is released, so the forward player keeps a small share of the turning.
    assert a["Ava"]["thrust"] > 0.9 and a["Ben"]["turn"] > 0.75 and a["Ava"]["turn"] < 0.25


@needs_data
def test_replay_steps_the_brain_exactly_once_per_tick():
    from brain.model import Params, RateModel
    from brain.replay import REPLAY_PARAMS, replay
    from brain.brain import OUTPUT_NAMES

    rec = [{"Ava": {"forward": 0.6} if t % 20 < 10 else {}} for t in range(60)]
    m = RateModel("true", 0, Params(**REPLAY_PARAMS))
    calls = {"n": 0}
    real_step = m.step

    def counting_step(drives):
        calls["n"] += 1
        return real_step(drives)

    m.step = counting_step
    out = replay(m, rec)
    assert calls["n"] == len(rec) and out.shape == (len(rec), len(OUTPUT_NAMES))
    m.step = real_step
    m.reset()
    by_hand = np.array([[o[k] for k in OUTPUT_NAMES] for o in (m.step(combine(t)) for t in rec)])
    assert np.allclose(out, by_hand)


@needs_data
def test_a_silent_player_gets_no_credit():
    rec = [{"Ava": {"forward": 0.6}, "Ben": {}} for _ in range(150)]
    shares = credit_from_recording(rec)
    assert shares["Ben"]["overall"] == 0.0 and shares["Ava"]["thrust"] > 0.9


def test_metrics_shapes():
    m = metrics(np.zeros((10, 16)))
    assert all(v.shape == (10,) for v in m.values())
    assert all(v.shape == (0,) for v in metrics(np.zeros((0, 16))).values())


def test_credit_on_an_empty_round_is_all_zero():
    shares = credit(np.zeros((0, 16)), {"A": np.zeros((0, 16)), "B": np.zeros((0, 16))})
    assert all(v == 0.0 for p in shares.values() for v in p.values())


@needs_data
@pytest.mark.slow
def test_chronicler_processes_end_to_end():
    from server.chronicler import Chronicler

    chron = Chronicler(["Ava", "Ben"])
    try:
        chron.start_chapter("t1", roles={"Ava": ["wingmaster"], "Ben": ["seer"]})
        for t in range(300):
            chron.record({"Ava": {"forward": 0.6} if t < 200 else {}, "Ben": {"duck": 1.0} if 250 <= t < 262 else {}})
        r = chron.finish(events=[{"tick": 280, "kind": "splat", "severity": 3}])
        assert r["ticks"] == 300 and r["knight"] in ("Ava", "Ben")
        assert r["players"]["Ava"]["share"]["thrust"] > 0.9
        assert r["players"]["Ben"]["share"]["escape"] > 0.9
        assert r["blunder"]["kind"] == "splat"
        chron.start_chapter("t2")  # an empty chapter must not crash
        empty = chron.finish()
        assert empty["ticks"] == 0
    finally:
        chron.close()
