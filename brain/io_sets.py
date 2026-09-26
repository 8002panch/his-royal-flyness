"""Which neurons each input group and output name refers to.

Owner: Neil. Run after build_graph:  python -m brain.io_sets
Writes brain/io_sets.json (committed; it's small). Group names must match brain.brain.INPUT_GROUPS / OUTPUT_NAMES.
Counts should match docs/DATA_CHECK.md ("Input and output groups").
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
    groups: dict[str, pd.DataFrame] = {}

    # Eyes: visual projection neurons, sided by soma
    for cell in ("LC10a", "LPLC2", "LC4"):
        for s in "LR":
            groups[f"{cell}_{s}"] = _side(neurons[t == cell], "somaSide", s)
    # Nose: olfactory receptor neurons, sided by the antenna they come from (rootSide); "unknown" side left out
    for glom in ("VA1v", "DM1", "DA1"):
        for s in "LR":
            groups[f"ORN_{glom}_{s}"] = _side(neurons[t == f"ORN_{glom}"], "rootSide", s)
    # Feet: foreleg pheromone-taste neurons (putative ppk23 entering by the prothoracic leg nerve)
    foreleg = neurons[(neurons["receptorType"] == "putative_ppk23") & (neurons["entryNerve"] == "ProLN")]
    for s in "LR":
        groups[f"ppk23_{s}"] = _side(foreleg, "rootSide", s)
    # Ears: Johnston's organ, wind (JO-C*, JO-E*) and sound (JO-A*, JO-B*)
    wind = neurons[t.str.match(r"^JO-(C|E)")]
    sound = neurons[t.str.match(r"^JO-(A|B)")]
    for s in "LR":
        groups[f"JO_wind_{s}"] = _side(wind, "rootSide", s)
        groups[f"JO_sound_{s}"] = _side(sound, "rootSide", s)

    outputs: dict[str, pd.DataFrame] = {}
    for cell in ("DNa02", "DNa01"):
        for s in "LR":
            outputs[f"{cell}_{s}"] = _side(neurons[t == cell], "somaSide", s)
    for cell in ("DNp09", "DNg100", "MDN", "DNp01", "pIP10"):
        outputs[cell] = neurons[t == cell]
    male_specific = neurons["dimorphism"].fillna("").str.contains("male-specific")
    outputs["pC1"] = neurons[t.str.startswith("pC1") & male_specific]

    assert tuple(groups) == INPUT_GROUPS or set(groups) == set(INPUT_GROUPS), "input names out of sync with brain.py"
    assert set(outputs) == set(OUTPUT_NAMES), "output names out of sync with brain.py"
    for name, df in {**groups, **outputs}.items():
        if df.empty:
            raise ValueError(f"group {name} is empty")

    return {
        "source": "MaleCNS v1.0; built by brain/build_graph.py + brain/io_sets.py",
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
