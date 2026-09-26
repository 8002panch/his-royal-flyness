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
cues = seer.sense(stimuli)               # every tick; ~6 ms with the real brain, ~0 for the placeholder
# Sharing one brain with button-driven movement: SeerAdapter(brain=my_brain); seer.sense(stimuli, extra_drives=buttons);
# the movement outputs are then in seer.last_outputs (one brain step per tick for both).
seer.swap("changeling", seed=0)          # the Changeling toggle
```

Formats for `stimuli` and `cues`: [team/README.md](../team/README.md#proposed-formats) (and the module docstring).
If the brain ever throws, `sense()` returns placeholder cues with `"error": true`, so the game never stops.

| Readout (each side) | Neurons | Left vs right, True Prince (same side / other side) |
|---|---|---|
| `seer_her_L/R` (where she is) | DNa02, DNg111, DNae002, DNae001, DNg41, DNa10 | 9.5 / -0.6 and 9.9 / -0.6 |
| `seer_loom_L/R` (where the Giant is) | DNp04, DNp02, DNp01 (Giant Fiber), DNg40, DNp11, DNp03 | 85 / 1.0 and 81 / 0.6 |
| `seer_wind_L/R` (the gust) | DNge016, DNg29, DNge175, DNp18, DNg05_a | 16 / 1.1 and 19 / 0.2 |

**Evaluation** (`python -m brain.seer --evaluate`, 60 fresh random scenes per brain; `team/neil/seer_eval.csv`):

| Brain | Princess side correct | Giant warned before impact | Warning lead time | Giant side correct | Time-to-impact error |
|---|---|---|---|---|---|
| **True Prince** | **59/60** (in 20 ms) | **60/60** | **1.20 s** | **60/60** | **0.12 s** |
| Changelings (3 seeds) | 1 to 10 of 60 | **0/60** | none | 0 to 25 of 60 | none |
| Placeholder (true geometry) | 60/60 | 60/60 | 1.18 s | 60/60 | 0.15 s |

How the senses are encoded (our assumptions, stated on the Royal Decree): each eye sees its own side plus a **binocular strip** of
+/-10 degrees (both eyes see the Princess there, which reads as "ahead"); looming drive is **logarithmic** in how fast the Giant grows
(like real looming detectors), which gives about a second of warning; seconds-to-impact come from a lookup of the looming warning level
measured on the True Prince (`seer_calibration.json`, rebuilt by `python -m brain.seer --calibrate`).

Bearing is **coarse on purpose**: left / ahead / right (reported as -60 / 0 / +60 degrees). Each eye's Princess detectors are driven as
one group, so beyond the narrow zone straight ahead the wiring only says "left" or "right". The Princess's detection range is a
setting (`princess_full_cm`, default 150 cm; she's detected out to about 7x that): tune it to the course scale.
Known interactions in the real wiring (not bugs): seeing the Princess pulls steering toward her and damps forward drive; brain
activity carries over ~100 ms after a button is released.

## Speed

One brain tick is **one 20 ms step** (`Params.dt = 0.02`). Sustained 2.5-minute test on the M2: median 5.7-6.3 ms per tick, p99 mostly
6.4-8 ms, rare spikes to ~38 ms. (Two 10 ms steps per tick ran at median ~12 ms with p99 up to 20.7 ms: too close to the 20 ms budget
once Godot and the server share the laptop.) Loaded wiring and resting baselines are cached per process, so a second `Brain` costs ~0.01 s.
**For the server loop:** use a fixed 20 ms timestep that catches up after a rare slow tick instead of drifting.

## Tests

`python -m pytest brain/tests -q` runs **61 tests in about 2 minutes** (`-m "not slow"` skips the slowest). They cover:
- **the wiring:** 166,606 neurons, 6,240,402 connections, signs follow the transmitter rule, modulators silent, every group on its side;
- **the Changelings:** every neuron keeps its exact input, out-degree and sender signs; >99% of partners changed; three distinct seeds;
- **the simulation:** 30 s of random play stays finite and bounded, rest is quiet, same inputs give identical outputs, reset and
  True/Changeling swaps are exact, bad inputs are rejected or clamped, a tick fits the 20 ms budget;
- **the neural mechanics:** every input (10 buttons + 6 senses) drives its own target far above all three Changelings, side-specific
  inputs favor their own side at least 5:1, the serenade needs both eyes, every input responds within 80 ms;
- **the Seer:** one interface for placeholder / True Prince / Changeling, safe fallback when the brain fails, swaps, Ved's `seer_view`
  format, shared-brain mode, correct sides, no flicker, no Princess/Giant cross-talk, wind warnings, hybrid mode, and accuracy on fresh
  scenes (True Prince at least 18/20 sides, warns every Giant at least 0.6 s ahead with time-to-impact error at most 0.25 s;
  every Changeling warns 0 times);
- **replay and the Chronicler:** exactly one brain step per tick, deterministic replays, correct credit, silent players get nothing,
  empty chapters don't crash, the multi-process Chronicler end to end.

## Files

`brain.py` (API), `model.py` (rate model: input-fraction weights, gain 4), `build_graph.py`, `io_sets.py` + `io_sets.json`,
`changeling.py`, `probes.py` (the controls matrix), `replay.py` (for the Chronicler), `seer.py` (the Seer) + `seer_calibration.json`,
`figures.py`, `tests/` (the suite above).

## Setup (about 1 minute)

Put the three MaleCNS Feather files in `data/`, then run `python -m brain.build_graph` and `python -m brain.changeling`
(`python -m brain.io_sets` only if the groups change). Teammates can skip this: AirDrop `data/graph_*.npz` + `data/neurons.parquet` from Neil.
Check it: `python -m brain.probes --level 1.0` (about 1 minute).
