"""Which neurons each input group and output name refers to.

Owner: Neil. Run after build_graph:  python -m brain.io_sets
Writes brain/io_sets.json (committed; it's small). Group names must match brain.brain.INPUT_GROUPS / OUTPUT_NAMES.
v2 (Sat 16:45): one input group per phone button, chosen from the full sensory scan.
"""

from __future__ import annotations

import json
from pathlib import Path

import pandas as pd

from brain.brain import INPUT_GROUPS, OUTPUT_NAMES

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent / "io_sets.json"


def _side(df: pd.DataFrame, column: str, side: str) -> pd.DataFrame:
    return df[df[column] == side]


def build(neurons: pd.DataFrame) -> dict:
    t = neurons["type"].fillna("")
    side = neurons["somaSide"]
    pick = lambda types, s=None: neurons[t.isin(types) & ((side == s) if s else True)]

    groups: dict[str, pd.DataFrame] = {
        "forward": pick(["LC9", "LC31a"]),
        "back": pick(["SNta02,SNta09", "LC16", "LoVP26"]),
        "left": pick(["LLPC1"], "L"),
        "right": pick(["LLPC1"], "R"),
        "up": pick(["LPLC1", "LLPC2"]),
        "down": pick(["LPLC4"]),
        "duck": pick(["LC4", "LPLC2"]),
        "serenade": pick(["LC10a", "LC10d"]),
        "lock_L": pick(["LC10a", "LC10d"], "L"),
        "lock_R": pick(["LC10a", "LC10d"], "R"),
    }
    male_specific = neurons["dimorphism"].fillna("").str.contains("male-specific")
    outputs: dict[str, pd.DataFrame] = {
        "DNp09": pick(["DNp09"]),
        "DNg100": pick(["DNg100"]),
        "MDN": pick(["MDN"]),
        "DNa02_L": pick(["DNa02"], "L"),
        "DNa02_R": pick(["DNa02"], "R"),
        "DNg02": neurons[t.str.startswith("DNg02_")],
        "DNp07_10": pick(["DNp07", "DNp10"]),
        "DNp01": pick(["DNp01"]),
        "pIP10": pick(["pIP10"]),
        "pC1": neurons[t.str.startswith("pC1") & male_specific],
    }

    assert set(groups) == set(INPUT_GROUPS), "input names out of sync with brain.py"
    assert set(outputs) == set(OUTPUT_NAMES), "output names out of sync with brain.py"
    for name, df in {**groups, **outputs}.items():
        if df.empty:
            raise ValueError(f"group {name} is empty")

    return {
        "source": "MaleCNS v1.0; built by brain/build_graph.py + brain/io_sets.py (v2: one group per phone button)",
        "inputs": {g: sorted(int(x) for x in groups[g]["bodyId"]) for g in INPUT_GROUPS},
        "outputs": {o: sorted(int(x) for x in outputs[o]["bodyId"]) for o in OUTPUT_NAMES},
    }


def main() -> None:
    neurons = pd.read_parquet(ROOT / "data" / "neurons.parquet")
    sets = build(neurons)
    OUT.write_text(json.dumps(sets, indent=1))
    for kind in ("inputs", "outputs"):
        print(kind + ":", {k: len(v) for k, v in sets[kind].items()})
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
