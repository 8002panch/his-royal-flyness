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
- [x] **40 min:** `host/` project + main scene layout: hall in the center, chart panel on the right, title + candle on top, captions + crests on the bottom ([GAME_DESIGN.md](../../docs/GAME_DESIGN.md#screens)).
- [x] **30 min:** WebSocket client reading server state (use `sample_state.json` until the server is up); the fly sprite moves and rotates. *(No `server/sample_state.json` yet — built `host/test/sample_sequence.json` as an offline fixture against the documented message schema; GameState auto-switches to the real server once it's reachable.)*
- [ ] **35 min:** lobby: wax-seal code, QR (PNG from the server), crests lighting up as players join. *(Lobby screen exists; wax-seal code shows a placeholder — the `state` message has no room-code field yet, flagged for Arnav/Ved. QR image display not wired.)*

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
(your notes here)
