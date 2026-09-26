# Instructions for AI coding agents (Codex, Claude and others)

This is **His Royal Flyness**, a team project being built at **hackUMBC 2026**. Before changing anything, read `README.md`,
`team/README.md`, the task list of the person you're working for (`team/<name>/README.md`), and `docs/TECH_ARCHITECTURE.md`.

## Hard rules (breaking these can disqualify the whole team)

1. **Commit window.** Every commit must be made between **12:00 PM Sat 26 Sept and 11:45 AM Sun 27 Sept 2026 (EDT)**.
   Don't commit after 11:45 AM Sunday. **Never force-push, rebase or amend pushed commits, squash-rewrite `main`, or change commit dates.**
2. **New code only.** Write everything fresh. Don't copy code from pre-existing projects: not from `fly-cns-sim`, not from the
   old Fly-by-Wire repo, not from the private planning repo's scripts or plugins. Installing open-source libraries through a package manager is fine.
3. **No secrets.** The repo is public. Never commit `.env`, API keys or tokens. Read keys from environment variables; list new ones in `.env.example` with blank values.
4. **No data files.** `data/` is git-ignored. Don't commit `.feather`, `.npz` or `.parquet` files.
5. **Honesty.** Never hard-code a fly behavior and present it as coming from the brain simulation. Never put a number in the UI,
   a voice line or the Devpost text unless the code computed it.

## Who owns what

Only edit the files owned by the person you're working for. If something outside their area needs to change, don't edit it:
leave a note in `team/<owner>/README.md` under "Notes" or tell your user, so the owner can do it.

| Owner | GitHub | Owns |
|---|---|---|
| Neil | `8002panch` | `brain/`, `agents/run_trials.py`, `agents/bots.py`, `server/chronicler.py` |
| Arnav | `arnavp-1` | `server/` (except `chronicler.py`), `agents/schema.py`, `levels/` (hand-made trials), `run.sh` |
| Ved | `shahved25` | `relay/`, `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py`, `levels/` (generated trials, `lab_log.jsonl`) |
| Anshul | `darkspaz-v1` | `host/` (Godot 4), `audio/` |

Everyone may edit their own `team/<name>/` folder. `docs/` changes need the team's agreement.

## How to work

- Branch names: `<name>/<feature>` (e.g. `ved/relay-rooms`). Keep changes small. `main` must always run the demo.
- Follow the message formats in `docs/TECH_ARCHITECTURE.md` and the interfaces in `team/README.md`. Don't change a shared
  interface (brain API, state JSON, relay protocol, Trial schema, Chronicle JSON) without the owner agreeing.
- Python 3.11+, type hints, standard library + the packages listed in `docs/KICKOFF_CHECKLIST.md`. Godot 4 for `host/`.
- There's no test suite yet. Run the module you changed and the smoke check your task list gives ("Done when ...") before committing.
- Tick the matching box in `team/<name>/README.md` when a task is done.
