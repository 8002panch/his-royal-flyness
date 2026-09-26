# Arnav: game server

**GitHub:** `arnavp-1` · **Load:** 15¼ h · **Extra job:** integration lead at every gate · **Sleep:** 03:30-05:15

## You own
- `server/`: `main.py` (tick loop), `arena.py`, `body.py`, `senses.py` (sense encoders), `script_actors.py` (Princess, rivals, the Giant),
  `rounds.py` (state machine, scoring), `recorder.py`, `godot_link.py`, `relay_client.py`, `sample_state.json` (everything except `chronicler.py`, which is Neil's)
- `agents/schema.py` (the Trial model) and `levels/` (hand-made trials)
- `run.sh` and the README's "how to run"

## You give others
| To | What | By |
|---|---|---|
| Anshul | `server/sample_state.json` | 16:30 |
| Ved | `agents/schema.py` | 18:30 |
| Neil | Recorder input-log format; arena/body importable headless for `run_trials` | 21:00 |
| Everyone | The first playable, end to end | 20:00 |

## You need
- Neil: Brain API stub (16:15), `io_sets.json` (16:30), real Brain (20:00), Chronicle JSON (21:00).
- Ved: `relay/PROTOCOL.md` (16:30). Anshul: voice/sound event IDs (21:00).

## Tasks

### B1 · 15:45-17:45 (2 h)
- [ ] **15 min:** venv; `server/` skeleton; `run.sh` placeholder.
- [ ] **40 min:** `server/main.py`: asyncio loop at 50 Hz with a `FakeBrain` (random output z-scores).
- [ ] **40 min:** `server/arena.py` + `server/body.py`: 2D kinematics in mm; outputs to movement (turn, walk, back up, jump, song); contact and win geometry ([TECH_ARCHITECTURE.md](../../docs/TECH_ARCHITECTURE.md#outputs-from-neurons-to-movement-serverbodypy)).
- [ ] **25 min:** `server/godot_link.py` (local WebSocket, 30 Hz state). **Push `server/sample_state.json` by 16:30.**

### B2 · 17:55-20:00 (2 h)
- [ ] **45 min:** `server/relay_client.py`: connect to the relay as host (`ROOM_SECRET`), handle join / pick / in / tap, role assignment and merging, send view / fx.
- [ ] **60 min:** `server/senses.py` v1: eyes (LC10a from angular size and motion per side; LPLC2/LC4 from looming rate), Taster contact pulses, Spymaster wind; output a drives dict keyed by `io_sets.json` names.
- [ ] **15 min:** `agents/schema.py` (Trial model) + `levels/certified/trial_I_garden.json`. **Give the schema to Ved by 18:30.**

### B3 · 20:00-23:30 (3½ h)
- [ ] **30 min:** swap FakeBrain for Neil's Brain; run the **20:00 first playable** with everyone.
- [ ] **45 min:** scent plumes (her, the Feast, rival) + the rival's cVA trail → Perfumer encoder.
- [ ] **90 min:** `server/script_actors.py`: Princess (waypoints, pauses, patience), rivals (waypoints, scripted song, cVA), the Giant (real and fake swings, growing shadow, wind).
- [ ] **45 min:** `server/rounds.py` (lobby, role, intro, play, chronicle, wedding; win/lose/stars; candle timer) + `server/recorder.py` (drives per role and outputs per tick).

### B4 · 23:30-03:30 (4 h)
- [ ] **90 min:** author and tune Trial II (the Banquet) and Trial III (the Giant's Shadow) as JSON.
- [ ] **30 min:** keyboard mode (Q/W eyes, O/P antennae, Space tap, L listen).
- [ ] **30 min:** host commands from Godot (start, next, toggle Changeling, reassign) + voice/sound event emission.
- [ ] **60 min (P1):** Eyes hex render for the Lookout phone (37 hex brightness values per eye at 10 Hz).
- [ ] **30 min:** fix what the 23:30 stranger test found.

### B5 · 05:15-07:00 awake (1¾ h), after sleep
- [ ] **60 min:** run the full ball 3 times end to end; fix crashes.
- [ ] **45 min:** performance with the shadows running on the demo laptop.

### B6 · 07:00-09:00 (2 h)
- [ ] **45 min:** README "how to run" + a working `run.sh`.
- [ ] **45 min:** final build on the demo laptop from a clean checkout.
- [ ] **30 min:** test both fallbacks: LAN mode on a hotspot, and keyboard mode.

## Notes
(your notes here)
