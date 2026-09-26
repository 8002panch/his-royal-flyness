# brain/

Owner: **Neil**. The MaleCNS v1.0 nervous system as a rate model, driven by the phone buttons.

## Use it (server side)

```python
from brain.brain import Brain, INPUT_GROUPS, OUTPUT_NAMES
brain = Brain("true")                 # or Brain("changeling", seed=0..2); Brain(stub=True) needs no data files
brain.reset()                         # start of a chapter/trial (instant)
out = brain.step({"forward": 0.6, "left": 0.7})   # one 20 ms tick; returns a z-score per output name
brain.swap("changeling", seed=1)      # the Changeling toggle (resets to rest)
```

## Interface v2 (Sat 16:50): one input group per button

Every button stimulates a named group of real sensory neurons. It works for 2D or 3D: use whichever buttons your mechanics need.

| Input | Neurons | Drives (True Prince z at full drive / best Changeling) |
|---|---|---|
| `forward` | LC9 + LC31a | `DNp09` thrust/walk 36.7 / 1.4 |
| `back` | SNta02,SNta09 + LC16 + LoVP26 | `MDN` back up 3.9 / 1.8 (weakest; send 1.0) |
| `left` / `right` | LLPC1, one side | `DNa02_L` 9.4 / 0.9, `DNa02_R` 12.0 / 1.6 (turn) |
| `up` | LPLC1 + LLPC2 | `DNg02` wing power 5.0 / 0.3 (send 0.8 to 1.0) |
| `down` | LPLC4 | `DNp07_10` landing neurons 43.3 / 4.1 |
| `duck` | LC4 + LPLC2 | `DNp01` Giant Fiber escape 99.2 / 2.1 |
| `serenade` | LC10a + LC10d, both eyes | `pIP10` song 8.7 / 1.3 |
| `lock_L` / `lock_R` | LC10a + LC10d, one eye | `DNa02` same side 18.2 / 17.3 (turn toward her) |

Outputs: `DNp09, DNg100, MDN, DNa02_L, DNa02_R, DNg02, DNp07_10, DNp01, pIP10, pC1` (z-scores; 0 = resting).
Suggested press drives: forward 0.6, back 1.0, left/right 0.7, up 0.8, down 0.7, duck 1.0, serenade 1.0, lock 1.0; specials 1.0.
Turning = `DNa02_R - DNa02_L`. All 10 pass the gate (target z > 3 and at least 2x every Changeling):
`team/neil/probes_v2_level10.csv` (full drive) and `..._level06.csv` (light presses: back and up are weaker there).

## Files

`brain.py` (API), `model.py` (rate model: input-fraction weights, gain 4), `build_graph.py`, `io_sets.py` + `io_sets.json`,
`changeling.py`, `probes.py` (the controls matrix). Coming: `replay.py` (for the Chronicler).

## Setup (about 1 minute)

Put the three MaleCNS Feather files in `data/`, then run `python -m brain.build_graph` and `python -m brain.changeling`
(`python -m brain.io_sets` only if the groups change). Teammates can skip this: AirDrop `data/graph_*.npz` + `data/neurons.parquet` from Neil.
Check it: `python -m brain.probes --level 1.0` (about 1 minute).
