"""Probes v2: does every phone button drive its own movement neuron, only in the True Prince?

Owner: Neil. Run:  python -m brain.probes [--level 0.6] [--runs 3] [--csv team/neil/probes_v2.csv]

For each button (brain.INPUT_GROUPS) held at `level` for 0.8 s, reads the mean z-score of every output over the last 0.4 s,
on the True Prince and each Changeling. Prints the button x output grid (the "controls matrix") and a pass/fail per button:
pass = the target output's z is above MIN_Z and at least 2x the largest Changeling value for that target.
This is the brain gate (docs/TEAM.md, "Gates") for the button channels.
"""

from __future__ import annotations

import argparse
import time

import numpy as np
import pandas as pd

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES
from brain.model import Params, RateModel

TARGET = {
    "forward": "DNp09", "back": "MDN", "left": "DNa02_L", "right": "DNa02_R", "up": "DNg02",
    "down": "DNp07_10", "duck": "DNp01", "serenade": "pIP10", "lock_L": "DNa02_L", "lock_R": "DNa02_R",
}
MIN_Z = 3.0
BRAINS = (("true", 0), ("changeling", 0), ("changeling", 1), ("changeling", 2))


def grid(model: RateModel, level: float, runs: int) -> pd.DataFrame:
    rows = {}
    for button in INPUT_GROUPS:
        vals = []
        for r in range(runs):
            model.rng = np.random.default_rng(100 + r)
            model.reset()
            out = [model.step({button: level}) for _ in range(40)]
            vals.append([np.mean([o[name] for o in out[20:]]) for name in OUTPUT_NAMES])
        rows[button] = np.mean(vals, axis=0)
    return pd.DataFrame(rows, index=OUTPUT_NAMES).T


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--level", type=float, default=0.6, help="button drive (0.6 = normal press, 1.0 = special)")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--csv", default="")
    args = ap.parse_args()
    t0 = time.time()
    grids = {}
    for kind, seed in BRAINS:
        grids[(kind, seed)] = grid(RateModel(kind, seed, Params()), args.level, args.runs)
    true = grids[("true", 0)]
    chg = [grids[b] for b in BRAINS[1:]]
    pd.set_option("display.width", 200)
    print(f"Controls matrix, True Prince, button level {args.level} ({time.time() - t0:.0f} s)")
    print(true.round(1).to_string())
    print(f"\nPass rule: target z > {MIN_Z} and >= 2x the largest Changeling value")
    results = []
    for button, target in TARGET.items():
        t = true.loc[button, target]
        c = max(abs(g.loc[button, target]) for g in chg)
        ok = t > MIN_Z and t >= 2 * c
        results.append((button, target, round(t, 1), round(c, 1), "PASS" if ok else "FAIL"))
    print(pd.DataFrame(results, columns=["button", "target", "true z", "max changeling |z|", "result"]).to_string(index=False))
    if args.csv:
        out = pd.concat({f"{k}{s}": g for (k, s), g in grids.items()})
        out.to_csv(args.csv)
        print(f"wrote {args.csv}")


if __name__ == "__main__":
    main()
