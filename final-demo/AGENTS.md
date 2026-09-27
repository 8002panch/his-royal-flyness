# Instructions for AI coding agents (Codex, Claude and others)

This is **His Royal Flyness**, a team project being built at **hackUMBC 2026**. Before changing anything, read `README.md` and
the three docs: `docs/GAME.md` (the game), `docs/TECH.md` (architecture, protocol, how to run and test) and `docs/TEAM.md`
(owners, status, open requests, rules).

## Hard rules (breaking these can disqualify the whole team)

1. **Commit window.** Every commit must be made between **12:00 PM Sat 26 Sept and 11:45 AM Sun 27 Sept 2026 (EDT)**.
   Don't commit after 11:45 AM Sunday. **Never force-push, rebase or amend pushed commits, squash-rewrite `main`, or change commit dates.**
2. **New code only.** Write everything fresh. Don't copy code from pre-existing projects: not from `fly-cns-sim`, not from the
   private planning repo's scripts or plugins. Installing open-source libraries through a package manager is fine.
3. **No secrets.** The repo is public. Never commit `.env`, API keys or tokens. Read keys from environment variables; list new ones in `.env.example` with blank values.
4. **No data files.** `data/` is git-ignored. Don't commit `.feather`, `.npz` or `.parquet` files.
5. **Honesty.** Never hard-code a fly behavior and present it as coming from the brain simulation. Never put a number in the UI,
   a voice line or the Devpost text unless the code computed it.
6. **The Seer's secret.** Only the Seer's phone may receive Princess or Giant information. Don't send it to other phones or draw it
   on the shared screen (the HUD's brain activity is side-free on purpose).

## Who owns what

Only edit the files owned by the person you're working for. If something outside their area needs to change, don't edit it:
add a row to "Open requests" in `docs/TEAM.md` or tell your user, so the owner can do it.

| Owner | GitHub | Owns |
|---|---|---|
| Neil | `8002panch` | `brain/`, `server/chronicler.py`, `agents/run_trials.py`, `agents/bots.py` |
| Arnav | `arnavp-1` | `server/` (except `chronicler.py`), `agents/schema.py`, `levels/` (hand-made trials), `run_local.py` |
| Ved | `shahved25` | `relay/`, `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py`, `levels/` (generated trials) |
| Anshul | `darkspaz-v1` | `host/` (Godot 4), `audio/` |

## Docs: three files only

- Keep the plan in `docs/GAME.md`, `docs/TECH.md` and `docs/TEAM.md`. **Don't create new markdown files** (no new READMEs, status
  files or design docs); add a section to the right doc instead. Edit your owner's sections and component; ask before changing
  someone else's.
- Phase prompts that say "update `docs/IMPLEMENTATION_STATUS.md`": update "Implementation status" and the phase log in `docs/TEAM.md`.
- Prompts that refer to `relay/PROTOCOL.md` or `docs/WEBAPP_ARCHITECTURE.md`: use `docs/TECH.md` ("Protocol", "Architecture").
- `team/<name>/` is each person's work folder (results, figures, scratch).

## How to work

- Branch names: `<name>/<feature>` (e.g. `ved/relay-rooms`). Keep changes small. `main` must always run the demo.
- Follow the message formats in `docs/TECH.md`. Don't change a shared interface (brain and Seer API, state JSON, relay protocol)
  without the owner agreeing.
- Python 3.11+, type hints, packages from `requirements.txt`. Godot 4 for `host/`. Plain HTML/JS for `relay/public/`.
- Before committing, run the tests: `python -m pytest brain/tests server/tests relay/tests -q` (and
  `npm test --prefix relay/public` for phone changes), plus the manual check in `docs/TECH.md` if you touched the live flow.
