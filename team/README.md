# Team: who does what

Four people, four equal loads: **about 15¼ hours of tasks each, with the same hours in every block.** Each person has a folder
here with their own ordered task list. Tick boxes as you go and commit, so everyone can see progress.

| Person | GitHub | Role | Your folder | Code you own |
|---|---|---|---|---|
| **Neil** | `8002panch` | Brain + science | [team/neil/](neil/README.md) | `brain/`, `agents/run_trials.py`, `agents/bots.py`, `server/chronicler.py` |
| **Arnav** | `arnavp-1` | Game server | [team/arnav/](arnav/README.md) | `server/` (except `chronicler.py`), `agents/schema.py`, `levels/`, `run.sh` |
| **Ved** | `shahved25` | Phones, relay, cloud + AI agents | [team/ved/](ved/README.md) | `relay/`, `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py` |
| **Anshul** | `darkspaz-v1` | Godot host, art + audio | [team/anshul/](anshul/README.md) | `host/`, `audio/` |

Your folder holds your task list, notes, and a `scratch/` subfolder for experiments that don't ship. Anything the game actually
imports goes in the component folder you own. One owner per file means nobody overwrites anybody.

## Hours by block

| Block | Time | Neil | Arnav | Ved | Anshul |
|---|---|---|---|---|---|
| B1 | Sat 15:45-17:45 | 2 | 2 | 2 | 2 |
| B2 | 17:55-20:00 | 2 | 2 | 2 | 2 |
| B3 | 20:00-23:30 | 3½ | 3½ | 3½ | 3½ |
| B4 | 23:30-03:30 | 4 | 4 | 4 | 4 |
| B5 | 03:30-07:00 (1¾ h awake, 1¾ h asleep) | 1¾ | 1¾ | 1¾ | 1¾ |
| B6 | Sun 07:00-09:00 | 2 | 2 | 2 | 2 |
| **Total** | | **15¼** | **15¼** | **15¼** | **15¼** |

Shared by everyone and not counted above: check-ins, dinner, the 23:30 stranger test, and rehearsal 09:00-10:30.

**Extra jobs, one each:** Neil answers science questions at judging. Arnav leads integration at every gate. Ved owns the Devpost
submission and recruits the strangers. Anshul keeps time at check-ins and makes the demo video. The presenter is Arnav, Ved or Anshul (decide at kickoff).

## Check-ins

| When | What | Led by |
|---|---|---|
| 17:45 | Sync: first probe results, blockers | Anshul (time), Neil (probes) |
| **20:00** | **Gate: GO or HYBRID + first playable end to end** | Arnav |
| **23:30** | **Stranger test** (four people who've never seen it) | Ved recruits, everyone watches |
| **03:30** | **Fallback checkpoint**, then sleep shifts | Arnav |
| 07:00 | Everyone awake; the finishing jobs start | Anshul |
| **09:00** | **Feature freeze** | Everyone |
| **10:30** | **Devpost complete** | Ved |
| **11:00 / 11:45** | **Devpost create deadline / final deadline (no commits after 11:45)** | Ved |

Sleep shifts: **Neil + Ved 05:15-07:00**, **Arnav + Anshul 03:30-05:15**.

## Open requests: who is waiting on whom (updated Sat 17:00)

Neil is building the **Royal Seer's sensory decoder** (`brain/seer.py`, the `seer_adapter` from Ved's playbook). The brain turns what the
Prince sees and hears into the Seer's cues, for the True Prince and the Changeling. Proposed formats are below, so nobody has to
wait: **if you don't answer by the time shown, build against the proposal.** Reply by editing this table (or tell Neil).

### Neil is waiting on

| From | What | Needed by | Proposal if no answer |
|---|---|---|---|
| **Arnav** | The **world stimuli** the server passes to the Seer every tick (where the Princess and the Giants are relative to the Prince) | 18:30 | `stimuli` format below; the server calls `seer.sense(stimuli)` every tick (50 Hz) |
| **Arnav** | Is `run_trials` + bots still Neil's job now that players move the fly directly? If yes: the server's movement step function to import headless | 19:00 | Neil pauses `run_trials` until Arnav's step function exists |
| ~~**Ved**~~ | ~~`seer_view` format and what SCAN does~~ **Answered in relay/PROTOCOL.md (17:03):** SCAN is hold-to-scan; `seer_view` = compass bearing, distance, confidence, giant direction/seconds/confidence. Neil added `brain.seer.to_seer_view(cues)` to convert | Done | |
| **Anshul** | Which brain signals the HUD's nervous-system bars show (your vision / flight / balance / reaction groups) | 19:00 | `cues["activity"]` below, grouped: vision = `her_L`, `her_R`; reaction = `looming`, `escape`; flight = `steer`; song = `song` |
| **Everyone** | **Decision:** does movement stay fully direct (brain only powers the Seer), or does some movement go through the brain? It changes what the Changeling toggle shows in the demo | 18:00 check-in | Direct movement; the Changeling scrambles only the Seer's senses; the Royal Decree says so |
| **Everyone** | **Decision:** keep the Chronicler (`server/chronicler.py`, per-player credit through the brain)? With direct movement it can only credit the Seer | 18:00 check-in | Keep it for the Seer only, or drop it; Neil's call if no answer |
| **Everyone** | Whose laptop runs the demo (for Neil's speed test with Godot + server + brain running together) | 20:00 | Neil's M2 |

### Others are waiting on Neil

| For | What | When |
|---|---|---|
| Arnav, Ved | `brain/seer.py`: `SeerAdapter` with placeholder, True Prince and Changeling modes behind one interface | **Done 17:25** (see brain/README.md) |
| Everyone | Seer accuracy and delay, True Prince vs Changeling (for the demo and the Devpost) | **Done 17:25**: team/neil/seer_eval.csv |
| Anyone running the real brain | `data/graph_*.npz` + `data/neurons.parquet` (AirDrop from Neil; about 90 MB total) | On request |

### Ready to plug in: the brain-powered Seer (Neil → Ved, Arnav)

`server/main.py`'s `GameSession` already accepts it (tested in `brain/tests/test_seer.py::test_plugs_into_the_server_game_session`):

```python
from brain.seer import SeerAdapter
session = GameSession(room, seer=SeerAdapter("true"))   # has .sense(), .to_phone_view(), .source like PlaceholderSeerAdapter
session.seer.swap("changeling", seed=0)                 # the Changeling toggle; swap("true") / swap("placeholder") to go back
```

- **Please call `seer.sense(stimuli)` every game tick (50 Hz)** and only send the `seer_view` while the Seer holds scan. The adapter is
  real-time safe either way (it advances the brain by the wall-clock time between calls), but calling it only at the 10 Hz phone rate
  means ~30 ms catch-up bursts that can make a 50 Hz tick late. One brain tick costs ~6 ms.
- Needs the data files in `data/` (AirDrop from Neil) or falls back to placeholder cues if the brain can't run.

### Proposed formats

```python
# Arnav -> Seer, every tick (angles in degrees; bearing: 0 = straight ahead, negative = left, positive = right;
# elevation: positive = above; distances in cm; approach_cm_s > 0 means getting closer)
stimuli = {
    "princess": {"bearing_deg": -35.0, "elevation_deg": 10.0, "distance_cm": 420.0} or None,  # None = not in the scene
    "giants": [{"bearing_deg": 80.0, "elevation_deg": 30.0, "distance_cm": 150.0, "approach_cm_s": 300.0, "size_cm": 40.0}],
    "wind": {"bearing_deg": 80.0, "strength": 0.6} or None,                                      # strength 0 to 1
}

# Seer -> Ved (seer_view) and Anshul (HUD)
cues = {
    "princess": {"side": "left" | "ahead" | "right", "bearing_deg": -30.0, "confidence": 0.7, "distance": "near" | "mid" | "far"} or None,
    "giant": {"warning": 0.0 to 1.0, "side": "left" | "right" | "ahead" | None, "eta_s": 1.2 or None},
    "activity": {"her_L": z, "her_R": z, "looming": z, "escape": z, "steer": z, "song": z},   # z-scores for the HUD bars
    "source": "true" | "changeling" | "placeholder",
}
```

## Interfaces (agree on these first)

| From → to | What | By |
|---|---|---|
| Neil → Arnav | Brain API stub in `brain/brain.py`: `Brain(kind="true"\|"changeling", seed=0)`, `.reset()`, `.step(drives: dict[str, float]) -> dict[str, float]` | 16:15 |
| Neil → Arnav, Anshul | `brain/io_sets.json`: input group names by side, output names | 16:30 |
| Arnav → Anshul | `server/sample_state.json` (the 30 Hz state message) | 16:30 |
| Ved → Arnav | `relay/PROTOCOL.md` (join, pick, in, tap, view, fx, honors) | 16:30 |
| Arnav → Ved | `agents/schema.py` (the Trial model) | 18:30 |
| Neil → everyone | Chronicle JSON format (shares + events per player) in `server/chronicler.py` docstring | 21:00 |
| Anshul → Arnav | Voice/sound event IDs (from `docs/LORE.md`) and how the server triggers them | 21:00 |
| Ved → Anshul | Jester text hand-off (`agents/jester.py`) and the Level Lab log format (`levels/lab_log.jsonl`) | 01:00 |
| Neil → Ved | `run_trials(trial, brain, n)` and `get_trace(run_id)` working headless | 00:30 |

Message formats: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#messages-json). States, screens, trial layouts and starting numbers: [docs/GAME_FLOW.md](../docs/GAME_FLOW.md).

## How we use git (the rules depend on it)

- Every commit must be made between **12:00 PM Sat and 11:45 AM Sun**. Set your laptop clock to automatic now.
- **Never force-push, rebase `main`, amend pushed commits, or change commit dates.** Commit times are how organizers check the window.
- Work on a branch named `<name>/<feature>`, pull often, merge small. `main` must always run the demo.
- Don't paste in code written before 12:00 Sat (no `fly-cns-sim`, no code from our earlier pre-event plan, no pre-event plugins). Libraries are fine.
- Keys only in `.env` (git-ignored). The repo is public. If a key ever gets committed, revoke it right away and tell the team.
- If a task runs 2x over its time box, say so at the next check-in.

Full rules checklist: [docs/RULES_COMPLIANCE.md](../docs/RULES_COMPLIANCE.md). Whole plan: [docs/BUILD_PLAN.md](../docs/BUILD_PLAN.md).
