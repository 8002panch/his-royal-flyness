# host/

Owner: **Anshul**. The Godot 4 project for the main screen: lobby with the wax seal + QR, the hall, the Royal Nervous System
chart, trial intros, Chronicle, Level Lab, Royal Decree and wedding screens, audio playback and captions.

Spec: [docs/GAME_DESIGN.md](../docs/GAME_DESIGN.md#screens).

## Status (B1)

- `project.godot` + `scenes/Main.tscn` + `scripts/main.gd`: lobby screen and a trial screen (placeholder
  ColorRect actors, live Royal Nervous System bars, crest lighting, captions, candle timer, TRUE PRINCE/CHANGELING badge).
- `scripts/game_state.gd` (autoload `GameState`): connects to the game server's local WebSocket at `ws://127.0.0.1:8765`
  and parses `state`/`event` messages per [docs/TECH_ARCHITECTURE.md#messages-json](../docs/TECH_ARCHITECTURE.md#messages-json).
  If the server isn't up yet (or drops), it falls back to looping `test/sample_sequence.json` at 30 Hz and keeps
  retrying the real server in the background — no restart needed once Arnav's server comes online.
- Open question for Arnav/Ved: the documented `state` message has no room-code field, so the lobby screen currently
  shows a `----` placeholder for the wax-seal code. Needs a `room` field on `state`, or a separate message.
- Not done yet: real sprites/art (Codex's track), QR image display, audio playback hookup, all non-trial screens
  (Chronicle, Level Lab, Royal Decree, wedding).

