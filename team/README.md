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

Message formats: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#messages-json).

## How we use git (the rules depend on it)

- Every commit must be made between **12:00 PM Sat and 11:45 AM Sun**. Set your laptop clock to automatic now.
- **Never force-push, rebase `main`, amend pushed commits, or change commit dates.** Commit times are how organizers check the window.
- Work on a branch named `<name>/<feature>`, pull often, merge small. `main` must always run the demo.
- Don't paste in code written before 12:00 Sat (no `fly-cns-sim`, no old Fly-by-Wire code, no pre-event plugins). Libraries are fine.
- Keys only in `.env` (git-ignored). The repo is public. If a key ever gets committed, revoke it right away and tell the team.
- If a task runs 2x over its time box, say so at the next check-in.

Full rules checklist: [docs/RULES_COMPLIANCE.md](../docs/RULES_COMPLIANCE.md). Whole plan: [docs/BUILD_PLAN.md](../docs/BUILD_PLAN.md).
