# Neil: brain + science

**GitHub:** `8002panch` · **Load:** 15¼ h · **Extra job:** science Q&A at judging (not the presenter) · **Sleep:** 05:15-07:00

## You own
- `brain/`: `build_graph.py`, `io_sets.py` + `io_sets.json`, `brain.py` (the Brain class), `sim.py`, `changeling.py`, `probes.py`, `replay.py`
- `agents/run_trials.py`, `agents/bots.py`
- `server/chronicler.py` (the credit math and shadow processes; Arnav's server calls it)
- Fact checks in `docs/LORE.md`; the Royal Decree text

## You give others
| To | What | By |
|---|---|---|
| Arnav | Brain API stub (`brain/brain.py`) so he can code against it | 16:15 |
| Arnav, Anshul | `brain/io_sets.json` (group names) | 16:30 |
| Arnav | The real Brain (tuned) replacing the stub | 20:00 |
| Everyone | Chronicle JSON format | 21:00 |
| Ved | `run_trials` + `get_trace` working headless | 00:30 |

## You need

**Current requests to teammates (with deadlines and fallback proposals): [team/README.md#open-requests](../README.md#open-requests-who-is-waiting-on-whom-updated-sat-1700).**
In short: Arnav (Seer world stimuli, 18:30; is run_trials still mine?), Ved (seer_view format + what SCAN does, 18:30),
Anshul (which brain signals the HUD shows, 19:00), everyone (movement direct or through the brain? keep the Chronicler? demo laptop).

## Tasks

### B1 · 15:45-17:45 (2 h)
- [x] **15 min:** venv; copy the three MaleCNS Feather files into `data/` (and a USB stick).
- [x] **45 min:** `brain/build_graph.py` (neurons with a superclass not containing "tbc"; signs from `consensus_nt`; modulators silenced; edges with 5+ synapses; input-fraction weights) → `data/graph_true.npz`, `data/neurons.parquet`. **Done when** it prints 166,606 neurons and about 6.24M edges.
- [x] **15 min:** `brain/brain.py` stub with the agreed API (returns zeros). **Push by 16:15.**
- [x] **20 min:** `brain/io_sets.py` → `brain/io_sets.json` (commit it). **Done when** counts match [DATA_CHECK.md](../../docs/DATA_CHECK.md#input-and-output-groups-counts-and-sides).
- [x] **15 min:** rate model step (in `brain/model.py`). **Done when** one step is 6 ms or less. *(5.6 ms per step, 11.2 ms per tick.)*
- [x] **10 min:** `brain/changeling.py` with 3 seeds. **Done when** every row's input sum matches the True Prince exactly.

### B2 · 17:55-20:00 (2 h)
- [x] **60 min:** `brain/probes.py`: probes A to D ([TECH_ARCHITECTURE.md](../../docs/TECH_ARCHITECTURE.md#probes-brainprobespy-the-tests-behind-the-2000-gate)) on the True Prince and 3 Changelings, 10 runs each. Print a table (read the first results at the 17:45 sync).
- [x] **45 min:** tune g, tau, I_max, theta, noise; baseline z-scoring inside `Brain`. *(input fractions, gain 4)*
- [x] **15 min:** replace the stub with the real `Brain`; hand it to Arnav for the 20:00 first playable. *(v2 button API on main 16:43)*

### B3 · 20:00-23:30 (3½ h)
- [x] **30 min:** gate decision with the team; if probe C fails, add the hybrid-steering flag with Arnav. *(v2: all 10 button channels pass at full drive; no hybrid needed)*
- [x] **60 min:** `brain/replay.py`: open-loop replay of a recorded trial with one role's drives set to zero.
- [x] **90 min:** `server/chronicler.py`: 4 shadow processes, credit shares (turn, walk, jump, song) and event credit → Chronicle JSON. **Post the format by 21:00.**
- [x] **30 min:** verify the fact cards (*cheapdate*, *rutabaga* on FlyBase; the *Indy* name origin) and update `docs/LORE.md`. *(All verified; Indy lifespan claim softened: it's debated.)*

### B4 · 23:30-03:30 (4 h)
- [ ] **120 min:** `agents/run_trials.py`: headless arena + body + brain + bots, multiprocessing pool; returns win rate + one failure reason per run; `get_trace(run_id)`. **Done by 00:30** for Ved.
- [ ] **60 min:** `agents/bots.py`: the four bot policies plus the "shout" channel ([TECH_ARCHITECTURE.md](../../docs/TECH_ARCHITECTURE.md#bots-agentsbotspy-scripted-councils-for-testing)).
- [ ] **30 min:** speed check on the demo laptop (tick rate with Godot + shadows); drop to 2 shadows or the 2-hop core if needed.
- [ ] **30 min:** pair with Ved to wire `run_trials` / `get_trace` as Gemini tools.

### B5 · 03:30-05:15 awake (1¾ h), then sleep
- [ ] **75 min:** batch-certify trials with Ved; record the real [True Prince %] vs [Changeling %] numbers.
- [ ] **30 min:** final Royal Decree text (say whether hybrid steering is used) for the game screen and README.

### B6 · 07:00-09:00 (2 h)
- [ ] **60 min:** Devpost "How we built it", the Decree and credits, with real numbers.
- [ ] **30 min:** README science + credits section.
- [ ] **30 min:** Q&A drill with the presenter ([DEMO_SCRIPT.md](../../docs/DEMO_SCRIPT.md#qa-drill)).

## Notes
- 15:46 first look (gain sweep, one mixed stimulus): tick 11.2 ms; at gain 3 rest is quiet (4.7% of neurons above 0.1, 0.4% saturated);
  left stimulus drives DNa02_L (z 8.5) not DNa02_R (0.2); DNp01 z ~50; pIP10 weak at gain 3 (1.1), better at 5 (2.9). Probes will separate stimuli and add the Changeling.
- **16:10 to 16:30 probes and scans (scripts in team/neil/scratch/, git-ignored):**
  - Weights: "fractions" at gain 4 is the default. Rest: ~5-7% of neurons active, <1% saturated; Changelings are silent at rest.
  - A (looming → Giant Fiber) passes hugely: LC4+LPLC2 → DNp01 z ~50-76 vs Changelings ~1.
  - C (steering) passes: LC10a+LC10d left eye → DNa02_L 17.8, right → DNa02_R 17.6; Changelings small and inconsistent.
  - **Serenade comes from seeing her, not tapping:** both eyes on her → pIP10 8.9 (one eye ~4); Changelings ≤1.3.
  - B (foreleg taste taps → song) fails in every setting tried (≤0.4 fractions; 2.2 only with raw counts at settings that break steering).
    Taps do raise vAB3 (0.20 → 0.32) but vAB3 is ~0.8% of its pC1 targets' input and those are ~0.8% of pIP10's input.
  - Scan of all 330 sensory types (≥10 neurons): vision drives nearly everything. Walk: LC9+LC31a (21-34). Motion: LPC1+LLPC1
    (turn to that side 9-12, walk 4-5). Ears: JO sound → DNp01 3.8. Nose and feet ≤1.4 on any output.
  - Proposed: roles built on these channels (see chat / DECISIONS). Needs team sign-off.
- **16:40 v2 (team pivot to three pilots + Spymaster):** new brain API, one input group per button (see brain/README.md).
  Scan of 1,443 stimulus groups x 501 descending-neuron readouts picked the channels. All 10 buttons pass the gate at full drive
  (forward 36.7, back 3.9, left 9.4, right 12.0, up 5.0, down 43.3, duck 99.2, serenade 8.7, lock 18.2/17.3; Changelings ≤4.1).
  Grids: team/neil/probes_v2_level06.csv, probes_v2_level10.csv. Works for the team's 2D plan (use any subset of buttons).
- **17:00 Chronicler done:** 4 player shadows + 1 full shadow, deterministic one-step brains (6 ms/tick), ~8 ms/tick each with 5
  running, so it keeps up with the 20 ms game tick. Self-test (python -m server.chronicler): each player owns their axis
  (thrust 99.5%, turn 67%, altitude 100%, escape + song 100%). Turning is partly shared with FORWARD (a real interaction in the model).
  **For Arnav:** call Chronicler.record() every tick with {player: {input_group: drive}} and finish() at the chapter end.
- 17:00 fact cards verified (cheapdate = amnesiac allele, Moore 1998; rutabaga = adenylyl cyclase, Levin 1992; Indy named after Monty Python, lifespan result debated).
- 17:10 controls-matrix figure: team/neil/figures/controls_matrix_light.png (+ _dark). `python -m brain.figures` redraws it from the probe CSV.
  For the demo's M screen, the Devpost gallery and slides.
- **17:00 redesign (Ved's first-person 2D plan):** players move the fly directly; my job is the **Royal Seer's sensory decoder**
  (`brain/seer.py`). Deliver `SeerAdapter` (placeholder / True Prince / Changeling) by 18:30; accuracy and delay comparison by 20:00.
  Waiting on teammates: see "You need" above.
- **17:25 Seer done (ahead of 18:30):** `brain/seer.py` + `brain/test_seer.py` (5 pass). A left-vs-right scan found side-selective
  descending neurons: looming → DNp04/DNp02/DNp01 on the threat's side (same side 81-85 vs other side ~1; Changelings ~0-5).
  Evaluation (60 scenes): True Prince gets the Princess's side 55/60, the Giant's side 60/60, warns 55/60; Changelings warn 0/60.
  Bearing is coarse (left/ahead/right) because each eye's detectors are driven as a group. Results: team/neil/seer_eval.csv.
- **18:10 backbone audit + test suite (61 tests pass, ~2 min):** fixed (1) "ahead" misses: added a binocular strip to the eye model
  (Princess sides 55 → 59/60); (2) Giant warnings came only 0.23 s before impact: log looming encoding → 1.2 s lead; (3) time-to-impact:
  calibrated lookup, error 0.39 → 0.12 s; (4) sustained-load timing: default is now one 20 ms step per tick (median ~6 ms, p99 ~6-8 ms);
  (5) replay() stepped the brain 16x per tick (wrong and slow): fixed + regression test; (6) Chronicler crashed on an empty chapter:
  fixed + test. Also: wiring/baseline caching (second Brain 0.01 s), shared-brain mode for buttons + senses in one step.
- **18:20 server integration:** Ved's `server/main.py` GameSession takes `SeerAdapter("true")` directly (tested). The server calls
  sense() only while scanning at 10 Hz, so the adapter now advances the brain by wall-clock time between calls (capped at 200 ms).
  Brain + server + relay tests: 80 pass. Asked Ved/Arnav (team/README.md) to call sense() every tick to avoid catch-up bursts.
- **18:25 Royal Decree** rewritten for the first-person design (README + docs/LORE.md). Finer Princess direction is not feasible:
  LC10a/LC10d and LC4/LPLC2 have no eye-position (column) data in MaleCNS; only small columnar neurons (L1-L5, Mi1, Tm1...) do.
- Next for me: run_trials + bots (waiting on Arnav's answer), Devpost science (on hold per Neil).
- Build: 30 s, under 600 MB. graph_true.npz is 22 MB: AirDrop it (plus neurons.parquet and the 3 Changelings) to teammates who need the real brain.
