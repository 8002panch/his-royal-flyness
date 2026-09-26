# Anshul: Godot host, art + audio

**GitHub:** `darkspaz-v1` (confirm) · **Load:** 15¼ h · **Extra jobs:** timekeeper at check-ins; demo video · **Sleep:** 03:30-05:15

## You own
- `host/`: the Godot 4 project (all main-screen screens, sprites, the Royal Nervous System chart, animations, audio playback, captions)
- `audio/`: `gen_audio.py`, `lines.csv`, `sfx.csv`, `music.csv`, the generated files, and live Chronicle voice playback
- The demo video and Devpost screenshots

## You give others
| To | What | By |
|---|---|---|
| Arnav | Voice/sound event IDs and how the server triggers them | 21:00 |
| Everyone | A main screen that runs from live server state | 20:00 |
| Ved | Screenshots and the video link for Devpost | 09:00 |

## You need
- Arnav: `server/sample_state.json` (16:30), then the live server. Neil: `io_sets.json` names for the chart (16:30); Chronicle JSON (21:00).
- Ved: Jester text hand-off + `levels/lab_log.jsonl` (01:00). The ElevenLabs code (MLH).

## Tasks

### B1 · 15:45-17:45 (2 h)
- [ ] **15 min:** claim the ElevenLabs code; install Godot 4.
- [x] **40 min:** `host/` project + main scene layout — rebuilt against the real direct-movement + Seer design (not
      the original 4-senses layout): Helmsman/Liftmaster/Wingmaster panel, Royal Seer panel (compass, Giant hazard,
      nervous-system bars), hall center, bottom role cards.
- [x] **30 min:** WebSocket client reading server state (`server/sample_state.json` still doesn't exist — Arnav
      hasn't built the movement/arena step; built an offline `test/sample_sequence.json` fixture in the real
      `cues` shape instead, auto-switches to the real server once it's up).
- [ ] **35 min:** lobby: wax-seal code, QR (PNG from the server), crests lighting up as players join. *(Lobby
      screen exists; code/QR still placeholder — no owner has defined a room-code field in any real message yet.)*

### B2 · 17:55-20:00 (2 h)
- [ ] **30 min:** fonts (UnifrakturMaguntia, IM Fell English), palette, parchment + manuscript margins ([GAME_DESIGN.md](../../docs/GAME_DESIGN.md#art-direction-no-dedicated-artist-needed)).
- [ ] **60 min:** sprites: Hamlet (crown), Miranda (tiara), rivals (tabards), the Giant's shadow, the Feast. Scents are never drawn (only the Perfumer sees them).
- [ ] **30 min:** wing buzz, jump arc + dust puff, SPLAT ink blot, hearts.

### B3 · 20:00-23:30 (3½ h)
- [ ] **75 min:** the Royal Nervous System chart: live bars for inputs and outputs, real neuron names in small type.
- [ ] **45 min:** trial intro cards with Royal Facts (from `docs/LORE.md`).
- [ ] **60 min:** Chronicle screen: credit banners per crest, Knight of the Realm, the blunder of the round (from Neil's Chronicle JSON).
- [ ] **30 min:** captions bar for every voice line.

### B4 · 23:30-03:30 (4 h)
- [ ] **90 min:** `audio/gen_audio.py` + `lines.csv` / `sfx.csv` / `music.csv` from [LORE.md](../../docs/LORE.md#voice-line-bank); pick 3 library voices (no voice cloning); generate about 80 lines (v3 model), sound effects and music.
- [ ] **60 min:** playback by event ID in Godot; live Chronicle audio (Ved's Jester text → ElevenLabs Flash → MP3 into Godot) with a fallback line after about 4 s.
- [ ] **60 min:** Level Lab screen (reads `levels/lab_log.jsonl`), Royal Decree screen, wedding screen.
- [ ] **30 min:** TRUE PRINCE / CHANGELING badge + transition.

### B5 · 05:15-07:00 awake (1¾ h), after sleep
- [ ] **105 min:** polish: candle flicker, banners, screen shake, transitions, anything the stranger test flagged as confusing.

### B6 · 07:00-09:00 (2 h)
- [ ] **90 min:** demo video: 2 full takes with phones in frame, voiceover, export about 90 s (30 s minimum), upload ([DEMO_SCRIPT.md](../../docs/DEMO_SCRIPT.md#demo-video-required-30-s-minimum-aim-for-about-90-s)).
- [ ] **30 min:** 5 screenshots for Devpost; give them and the video link to Ved.

## Notes
- **Accepting the open ask in `team/README.md#open-requests`:** yes to the proposed HUD grouping —
  vision = `her_L`/`her_R`, reaction = `looming`/`escape`, flight = `steer`, song = `song`. Built `host/` against it.
- `host/` now reads `cues.princess` / `cues.giant` exactly as `team/README.md#proposed-formats` specifies. If that shape
  changes, the only place to update is `host/scripts/main.gd::_update_seer`.
- **Brain-activity HUD contract (supersedes the vision/flight/reaction/song grouping above; decided Sat 26 Sept):** the panel
  renders whatever keys are in the state message's top-level `brainActivity` dict ({key: z-score}): one bar per key, key name
  as the label, no hardcoded list (`host/scripts/main.gd::_update_brain_activity`). Works with `{}` now and with Neil's real keys
  (`her_L`, `her_R`, `looming`, `escape`, `steer`, `song`) or a 7th key later, with zero host changes. `cues.activity` is a
  fallback if the server nests it. Bars clamp to +/-6 and show the raw number. Offline fixture frames are tagged
  `offline_sample` and the HUD says "OFFLINE SAMPLE, not brain output", so no fixture number passes as brain output.
  Server-side changes needed are in `team/arnav/README.md` Notes (waiting on Arnav; the `brainActivity` name is my
  proposal, unconfirmed).
- **Doc mismatch:** the `"brainActivity":{"vision":0.8,"looming":0.5,"motor":0.6}` wireframe in `FIRST_PERSON_REDESIGN.md`
  lives in the frozen planning repo (not in this repo) and doesn't match the real keys. Anyone reading it should use
  `her_L`, `her_R`, `looming`, `escape`, `steer`, `song` instead. It needs the team's OK to change if it's ever copied here.
- Still need from Arnav: the actual `state.controls` field (each movement axis's current value) for the
  Helmsman/Liftmaster/Wingmaster bars — not defined anywhere yet since the movement/arena step isn't built.
  Degrades to 0 in the meantime, doesn't block anything.
- Explored (with my user, not built): reskinning this into a Pokémon-style overworld with NPCs/quests. Not
  reflected in any of the team's actual committed docs/code, so left out of `host/` pending real confirmation.
- **Pixel-art host direction accepted:** `host/PIXEL_ART_WORLD_CONCEPT.md` is the implementation plan and
  `host/CLAUDE_PIXEL_ART_PROMPT.md` is the handoff prompt for the world builder. It preserves the live direct-movement
  and Seer interfaces while replacing the dashboard visual treatment with a versioned royal-court pixel-art world.
