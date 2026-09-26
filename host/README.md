# host/

Owner: **Anshul**. The Godot 4 project for the main screen: lobby with the wax seal + QR, the hall, the Royal Nervous System
chart, trial intros, Chronicle, Level Lab, Royal Decree and wedding screens, audio playback and captions.

Spec: [docs/GAME_DESIGN.md](../docs/GAME_DESIGN.md#screens).

## Status

Built against the **real, live interfaces** as of Sat 17:00+ (direct movement + the Royal Seer), not the original
4-senses design — see `brain/README.md`, `relay/PROTOCOL.md`, and `team/README.md#proposed-formats`.

- `project.godot` + `scenes/Main.tscn` + `scripts/main.gd`: lobby screen and a trial screen. Left panel: Helmsman
  (left/right), Liftmaster (up/down), Wingmaster (forward/back) — the 3 direct-movement roles, matching
  `relay/PROTOCOL.md`'s role names exactly. Right panel ("Royal Seer"): compass + distance/confidence from
  `cues.princess`, a Giant hazard meter from `cues.giant` (warning/side/eta_s), and nervous-system bars grouped
  **vision/flight/reaction/song** from `cues.activity` — this is the literal grouping `team/README.md` proposed
  to Anshul (accepted here, since nobody answered it before this was built). Bottom: the 4 player role cards.
- `scripts/game_state.gd` (autoload `GameState`): parses the `state` message (`prince`/`princess`/`giant`/`controls`/
  `cues`/`meters`) at 30 Hz, falling back to looping `test/sample_sequence.json` (built in the same shape) when no
  server is up, and retrying the real server in the background.
- **Provisional / not yet defined by anyone:** `state.controls` (each movement axis's live value, for the
  Helmsman/Liftmaster/Wingmaster bars) — Arnav hasn't built the movement/arena step yet (`server/` only has
  `chronicler.py` so far). Reads as 0 until that exists; nothing crashes.
- **Still open, per `team/README.md`'s "Everyone" decisions:** whether the Chronicler stays (credited to the Seer
  only, since movement is now direct) — `host/` doesn't depend on this either way.
- Not done: real sprites/art (Codex's track), QR image display, audio playback hookup, non-trial screens (Chronicle,
  Level Lab, Royal Decree, wedding).
- **Explicitly not built:** the overworld/NPC/quest/Pokémon-tile concept discussed with Anshul directly — that
  isn't reflected in any of the team's actual committed docs or code, so it's on hold pending confirmation.
