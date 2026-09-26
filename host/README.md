# host/

Owner: **Anshul**. The Godot 4 project for the main screen: lobby with the wax seal + QR, the hall, the Royal Nervous System
chart, trial intros, Chronicle, Level Lab, Royal Decree and wedding screens, audio playback and captions.

Spec: [docs/GAME_DESIGN.md](../docs/GAME_DESIGN.md#screens).

## Status (B1)

- `project.godot` + `scenes/Main.tscn` + `scripts/main.gd`: lobby screen and a trial screen — left panel with
  Left/Right, Up/Down, Forward/Back flight-axis readouts, center hall (placeholder actors), right "Royal Seer"
  panel (compass to the princess, Giant-hand hazard meter, grouped nervous-system bars), bottom 4 player cards,
  candle timer, TRUE PRINCE/CHANGELING badge.
- **Mechanic pivot (see [docs/DECISIONS.md#O5](../docs/DECISIONS.md)):** this replaces the original 4-senses HUD
  with a direct 3-axis flight control + 1 Navigator role, matching a reference UI. Not yet confirmed with
  Neil/Arnav — `host/` is built against a *proposed* state-message shape (`controls`, `navigator` fields) with an
  offline fixture; no `brain/`, `server/`, or `relay/` files were touched.
- `scripts/game_state.gd` (autoload `GameState`): connects to the game server's local WebSocket at `ws://127.0.0.1:8765`
  and parses `state`/`event` messages per [docs/TECH_ARCHITECTURE.md#messages-json](../docs/TECH_ARCHITECTURE.md#messages-json),
  plus the proposed `controls`/`navigator` fields. If the server isn't up yet (or drops, or doesn't send those
  fields), it degrades gracefully (centered bars / "clear" hazard) or falls back to looping
  `test/sample_sequence.json` at 30 Hz, retrying the real server in the background.
- Open question for Arnav/Ved: the documented `state` message has no room-code field, so the lobby screen currently
  shows a `----` placeholder for the wax-seal code. Needs a `room` field on `state`, or a separate message.
- Not done yet: real sprites/art (Codex's track — hall background, Prince/Princess/Giant/rival art, compass
  needle art, player-card icons), QR image display, audio playback hookup, all non-trial screens (Chronicle,
  Level Lab, Royal Decree, wedding).

