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

## Interface v2 (Sat 16:50): one input group per button (for movement through the brain, if the team uses it)

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

## The Royal Seer (`brain/seer.py`): the brain's job in the first-person redesign

Players move the fly directly; the brain powers the **Seer's senses**. Every tick the server passes where the Princess and the Giants
are; the adapter drives the matching sensory neurons (Princess detectors LC10a/LC10d, looming detectors LC4/LPLC2, wind sensors JO-C/E,
each side separately), steps the brain, and reads **side-selective descending neurons** back out as coarse cues.

```python
from brain.seer import SeerAdapter
seer = SeerAdapter(source="true")        # "true" | "changeling" | "placeholder"; mode="neural" (default) or "hybrid"
cues = seer.sense(stimuli)               # every tick; ~12 ms with the real brain, ~0 for the placeholder
seer.swap("changeling", seed=0)          # the Changeling toggle
```

Formats for `stimuli` and `cues`: [team/README.md](../team/README.md#proposed-formats) (and the module docstring).
If the brain ever throws, `sense()` returns placeholder cues with `"error": true`, so the game never stops.

| Readout (each side) | Neurons | Left vs right, True Prince (same side / other side) |
|---|---|---|
| `seer_her_L/R` (where she is) | DNa02, DNg111, DNae002, DNae001, DNg41, DNa10 | 9.5 / -0.6 and 9.9 / -0.6 |
| `seer_loom_L/R` (where the Giant is) | DNp04, DNp02, DNp01 (Giant Fiber), DNg40, DNp11, DNp03 | 85 / 1.0 and 81 / 0.6 |
| `seer_wind_L/R` (the gust) | DNge016, DNg29, DNge175, DNp18, DNg05_a | 16 / 1.1 and 19 / 0.2 |

**Evaluation** (`python -m brain.seer --evaluate`, 60 random scenes each; `team/neil/seer_eval.csv`):

| Brain | Princess detected | Princess side correct | Giant side correct | Giant warned in time | Delay |
|---|---|---|---|---|---|
| True Prince | 60/60 | **55/60** | **60/60** | **55/60** | Princess 20 ms, Giant 400 ms |
| Changelings (3 seeds) | 12 to 16 of 60 | 0 to 10 of 60 | 0 to 19 of 60 | **0/60** | never |
| Placeholder (true geometry) | 60/60 | 60/60 | 60/60 | 60/60 | 0 |

Bearing is **coarse on purpose**: left / ahead / right (reported as -60 / 0 / +60 degrees). Each eye's Princess detectors are driven as
one group, so beyond the narrow zone straight ahead the wiring only says "left" or "right". The Princess's detection range is a
setting (`princess_full_cm`, default 150 cm; she's detected out to about 7x that): tune it to the course scale.
Tests: `python -m brain.test_seer` (5 tests: same interface for every source, fallback on failure, swaps, sides, unseen Princess).

## Files

`brain.py` (API), `model.py` (rate model: input-fraction weights, gain 4), `build_graph.py`, `io_sets.py` + `io_sets.json`,
`changeling.py`, `probes.py` (the controls matrix), `replay.py` (for the Chronicler), `seer.py` + `test_seer.py` (the Seer), `figures.py`.

## Setup (about 1 minute)

Put the three MaleCNS Feather files in `data/`, then run `python -m brain.build_graph` and `python -m brain.changeling`
(`python -m brain.io_sets` only if the groups change). Teammates can skip this: AirDrop `data/graph_*.npz` + `data/neurons.parquet` from Neil.
Check it: `python -m brain.probes --level 1.0` (about 1 minute).
