"""Probes A to D: the tests behind the 20:00 GO / HYBRID gate (docs/BUILD_PLAN.md#gates).

Owner: Neil. Run:  python -m brain.probes [--gain 3.0] [--runs 10]

Each probe runs on the True Prince and each Changeling, `runs` times with different noise seeds.
  A. Looming:  left LPLC2 + LC4 at full drive for 0.5 s   -> z(DNp01); pass: > 3 within 200 ms in >= 9/10 runs
  B. Tapping:  foreleg ppk23 taps at ~4 Hz for 2 s          -> peak z(pIP10), mean z(pC1); pass: > 2 and >= 2x the Changelings
  C. Steering: LC10a on one side for 1 s                     -> z(DNa02 same side) - z(DNa02 other side); pass: toward the
                                                                stimulus on both sides and >= 2x the Changelings
  D. Smell:    each odor on the left antenna for 1 s        -> strongest output change (reported, no pass/fail)
"""

from __future__ import annotations

import argparse
import time

import numpy as np

from brain.brain import OUTPUT_NAMES
from brain.model import Params, RateModel

TICKS_PER_S = 50


def run(model: RateModel, schedule, ticks: int) -> list[dict[str, float]]:
    model.reset()
    return [model.step(schedule(t)) for t in range(ticks)]


def probe_a(model: RateModel) -> dict:
    stim = lambda t: {"LPLC2_L": 1.0, "LC4_L": 1.0} if t < 25 else {}
    out = run(model, stim, 50)
    z = np.array([o["DNp01"] for o in out])
    return {"fast": float(z[:10].max()), "peak": float(z.max())}


def probe_b(model: RateModel) -> dict:
    # a 100 ms tap every 250 ms: 5 ticks on, 7-8 ticks off
    stim = lambda t: {"ppk23_L": 1.0, "ppk23_R": 1.0} if (t % 12.5) < 5 and t < 100 else {}
    out = run(model, stim, 110)
    return {"pIP10": float(max(o["pIP10"] for o in out)), "pC1": float(np.mean([o["pC1"] for o in out[50:100]]))}


def probe_c(model: RateModel) -> dict:
    result = {}
    for side, other in (("L", "R"), ("R", "L")):
        out = run(model, lambda t: {f"LC10a_{side}": 1.0}, TICKS_PER_S)
        late = out[25:]
        result[side] = {
            "DNa02": float(np.mean([o[f"DNa02_{side}"] - o[f"DNa02_{other}"] for o in late])),
            "DNa01": float(np.mean([o[f"DNa01_{side}"] - o[f"DNa01_{other}"] for o in late])),
            "walk": float(np.mean([(o["DNp09"] + o["DNg100"]) / 2 for o in late])),
        }
    return result


def probe_d(model: RateModel) -> dict:
    result = {}
    for odor in ("ORN_VA1v", "ORN_DM1", "ORN_DA1"):
        out = run(model, lambda t: {f"{odor}_L": 1.0}, TICKS_PER_S)
        late = {name: float(np.mean([o[name] for o in out[25:]])) for name in OUTPUT_NAMES}
        top = max(late, key=lambda k: abs(late[k]))
        result[odor] = (top, round(late[top], 2), round(late["pC1"], 2))
    return result


def summarize(label: str, values: list[float]) -> str:
    return f"{label} {np.mean(values):6.2f} +/- {np.std(values):4.2f}"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gain", type=float, default=Params.gain)
    ap.add_argument("--weights", default=Params.weights, choices=["counts", "fractions"])
    ap.add_argument("--w-syn", type=float, default=Params.w_syn)
    ap.add_argument("--runs", type=int, default=10)
    args = ap.parse_args()
    t0 = time.time()
    brains = [("true", 0), ("changeling", 0), ("changeling", 1), ("changeling", 2)]
    results = {}
    for kind, seed in brains:
        model = RateModel(kind, seed, Params(gain=args.gain, weights=args.weights, w_syn=args.w_syn))
        rows = {"A": [], "B": [], "C": [], "D": []}
        for r in range(args.runs):
            model.rng = np.random.default_rng(1000 + r)
            rows["A"].append(probe_a(model))
            rows["B"].append(probe_b(model))
            rows["C"].append(probe_c(model))
        model.rng = np.random.default_rng(0)
        rows["D"] = probe_d(model)
        results[(kind, seed)] = rows

    print(f"weights {args.weights}, w_syn {args.w_syn}, gain {args.gain}, {args.runs} runs per brain, {time.time() - t0:.0f} s\n")
    for (kind, seed), rows in results.items():
        name = "TRUE PRINCE " if kind == "true" else f"Changeling {seed}"
        a_fast = [x["fast"] for x in rows["A"]]
        print(f"{name}  A: DNp01 {summarize('peak', [x['peak'] for x in rows['A']])}  "
              f"fast>3 in {sum(v > 3 for v in a_fast)}/{len(a_fast)}")
        print(f"{'':12}  B: {summarize('pIP10 peak', [x['pIP10'] for x in rows['B']])}  "
              f"{summarize('pC1 mean', [x['pC1'] for x in rows['B']])}")
        for side in "LR":
            print(f"{'':12}  C({side} eye): {summarize('DNa02 same-other', [x[side]['DNa02'] for x in rows['C']])}  "
                  f"{summarize('DNa01 same-other', [x[side]['DNa01'] for x in rows['C']])}  "
                  f"{summarize('walk', [x[side]['walk'] for x in rows['C']])}")
        print(f"{'':12}  D (odor: strongest output, value, pC1): {rows['D']}")


if __name__ == "__main__":
    main()
