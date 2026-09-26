# server/

Owner: **Arnav** (`chronicler.py`: **Neil**). The Python game server: owns all game state; Godot only draws it.

## Phase 3 local movement prototype

Start the relay first, then start the authoritative server for one four-consonant room:

```sh
python3 relay/relay.py
python3 -m server.main --room BZKT
```

The server integrates direct Helmsman (`x`), Liftmaster (`y`), and Wingmaster (`z`) controller intent at 50 Hz. It publishes
render-only state to local Godot clients at 30 Hz on port `8765` and role-specific controller feedback at 10 Hz through the
relay. `server/seer_adapter.py` supplies deterministic placeholder cues until Neil's adapter is wired in a later phase.

Run server checks with `python3 -m unittest discover -s server/tests -v`.

Planned files: `main.py` (50 Hz loop), `arena.py`, `body.py`, `senses.py`, `script_actors.py`, `rounds.py`, `recorder.py`,
`godot_link.py`, `relay_client.py`, `sample_state.json` (Arnav); `chronicler.py` (Neil).

Spec: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#the-arena-and-body-serverarenapy-serverbodypy-serverscript_actorspy).
