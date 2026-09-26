"""The wiring itself: graph build, signs, the Changelings' guarantees, and the neuron groups."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES
from brain.tests.conftest import DATA, needs_data

IO = json.loads((Path(__file__).resolve().parents[1] / "io_sets.json").read_text())
PAIRS_IN = [("left", "right"), ("lock_L", "lock_R"), ("her_L", "her_R"), ("loom_L", "loom_R"), ("wind_L", "wind_R")]
PAIRS_OUT = [("DNa02_L", "DNa02_R"), ("seer_her_L", "seer_her_R"), ("seer_loom_L", "seer_loom_R"), ("seer_wind_L", "seer_wind_R")]


@needs_data
def test_graph_matches_the_data_check(graph):
    n = int(graph["n"])
    assert n == 166_606
    assert len(graph["post"]) == 6_240_402
    assert graph["count"].min() >= 5
    pairs = graph["post"].astype(np.int64) * n + graph["pre"]
    assert len(np.unique(pairs)) == len(pairs), "duplicate connections"
    assert np.all(np.diff(graph["post"]) >= 0), "edges must be sorted by receiving neuron"
    assert graph["pre"].min() >= 0 and graph["pre"].max() < n


@needs_data
def test_in_totals_cover_the_kept_inputs(graph):
    kept = np.bincount(graph["post"], weights=graph["count"], minlength=int(graph["n"]))
    assert np.all(graph["in_total"] >= kept)


@needs_data
def test_signs_follow_the_transmitter_rule(graph, neurons):
    nt = neurons["nt"]
    expected = np.where(nt.isin(["gaba", "glutamate", "histamine"]), -1,
                        np.where(nt.isin(["dopamine", "octopamine", "serotonin"]), 0, 1))
    assert np.array_equal(expected, graph["sign"])
    assert int((graph["sign"] == 0).sum()) == 541


@needs_data
def test_weights_are_finite_and_modulators_are_silent(graph):
    from brain.model import load_weights

    w = load_weights(DATA / "graph_true.npz")
    assert np.isfinite(w.data).all()
    silent = np.flatnonzero(graph["sign"] == 0)
    assert float(abs(w[:, silent]).sum()) == 0.0
    assert float(abs(w).sum(axis=1).max()) <= 1.0 + 1e-5, "input fractions can't exceed 1 per neuron"


@needs_data
def test_changelings_keep_every_neurons_input_and_scramble_partners(graph):
    from brain.model import load_weights

    w_true = load_weights(DATA / "graph_true.npz")
    pos_true = np.asarray(w_true.maximum(0).sum(axis=1)).ravel()
    neg_true = np.asarray(w_true.minimum(0).sum(axis=1)).ravel()
    outdeg = np.bincount(graph["pre"], minlength=int(graph["n"]))
    seen = set()
    for seed in (0, 1, 2):
        path = DATA / f"graph_changeling_{seed}.npz"
        c = np.load(path)
        assert np.array_equal(c["post"], graph["post"]) and np.array_equal(c["count"], graph["count"])
        assert np.array_equal(graph["sign"][c["pre"]], graph["sign"][graph["pre"]]), "sender signs must be kept"
        assert np.array_equal(np.bincount(c["pre"], minlength=int(graph["n"])), outdeg), "out-degrees must be kept"
        w = load_weights(path)
        assert abs(np.asarray(w.maximum(0).sum(axis=1)).ravel() - pos_true).max() < 1e-5
        assert abs(np.asarray(w.minimum(0).sum(axis=1)).ravel() - neg_true).max() < 1e-5
        assert np.mean(c["pre"] != graph["pre"]) > 0.99
        seen.add(c["pre"].tobytes()[:4096])
    assert len(seen) == 3, "the three Changelings must differ"


def test_group_names_match_the_api():
    assert list(IO["inputs"]) == list(INPUT_GROUPS)
    assert list(IO["outputs"]) == list(OUTPUT_NAMES)
    for name, ids in {**IO["inputs"], **IO["outputs"]}.items():
        assert ids, f"{name} is empty"


def test_left_and_right_groups_never_overlap():
    for a, b in PAIRS_IN:
        assert not set(IO["inputs"][a]) & set(IO["inputs"][b]), (a, b)
    for a, b in PAIRS_OUT:
        assert not set(IO["outputs"][a]) & set(IO["outputs"][b]), (a, b)


@needs_data
def test_groups_exist_and_sit_on_the_right_side(neurons):
    ids = set(neurons["bodyId"])
    soma = dict(zip(neurons["bodyId"], neurons["somaSide"]))
    root = dict(zip(neurons["bodyId"], neurons["rootSide"]))
    for grp in (*IO["inputs"].values(), *IO["outputs"].values()):
        assert all(b in ids for b in grp)
    for name in ("left", "lock_L", "her_L", "loom_L"):
        assert all(soma[b] == "L" for b in IO["inputs"][name]), name
    for name in ("right", "lock_R", "her_R", "loom_R"):
        assert all(soma[b] == "R" for b in IO["inputs"][name]), name
    assert all(root[b] == "L" for b in IO["inputs"]["wind_L"]) and all(root[b] == "R" for b in IO["inputs"]["wind_R"])
    for name in ("DNa02_L", "seer_her_L", "seer_loom_L", "seer_wind_L"):
        assert all(soma[b] == "L" for b in IO["outputs"][name]), name
    for name in ("DNa02_R", "seer_her_R", "seer_loom_R", "seer_wind_R"):
        assert all(soma[b] == "R" for b in IO["outputs"][name]), name
