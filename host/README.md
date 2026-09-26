# host/

Owner: **Anshul**. The Godot 4.3 project for the main screen: the one full-game display everyone watches (phones are
controllers only, see [docs/WEBAPP_ARCHITECTURE.md](../docs/WEBAPP_ARCHITECTURE.md)).

## The main screen: a pixel-art royal court (`scenes/Court.tscn`)

A banquet hall seen from the doors, drawn as 16/32-bit pixel art: rendered at **640x360** and scaled 2x to **1280x720** with
nearest-neighbour filtering (`project.godot`: `stretch/mode="viewport"`, `scale_mode="integer"`, texture filter Nearest,
2D pixel snapping). Palette: parchment `#F3E9D2`, ink `#2B2118`, royal blue `#1F3A8A`, crimson `#9B1C1C`, gold `#C9A227`
(`scripts/court/pal.gd`). No blur, glow, gradients or imported art: every sprite and layer is drawn in code by
`scripts/court/pixel_canvas.gd` at its exact on-screen size, with hard ink outlines and checker dithering for shade.

**The world is the hero.** Independent layers, back to front (`scripts/court/court_world.gd`):

| Layer | What | How |
|---|---|---|
| `FarBackground` | vault, side walls with lancet windows, the great pointed arch, rose window, cloth of estate | baked once (`hall_builder.gd`) |
| `FloorCarpet` | tiled floor, red carpet, royal-blue dais | baked once |
| `ColumnsBanners` | arcade, columns, hanging banners; two back-wall banners sway | baked + animated `Sprite2D`s |
| `Feast` | two feast tables and their dishes; candle flames flicker | baked + animated `Sprite2D`s |
| `Shadows` | dithered floor shadows, the Giant's pulsing target ring | `_draw` |
| `Actors` | Prince Hamlet, Princess Miranda, Sir Cheapdate, Sir Indy, the Giant's hand, depth-sorted | independent `Node2D`/`Sprite2D` |
| `FX` | wing buzz, dust puffs, ink SPLAT, hearts, sparkles, short screen shake | `fx_layer.gd` |
| `Labels` | name tags over Hamlet and Miranda | `name_tags.gd` |

The camera is fixed at the doors (`hall_cam.gd`), so Hamlet shrinks as he flies up the carpet towards Miranda.
The rivals are scenery only: no server field drives them.

**The parchment HUD stays at the edges** (`scripts/court/hud/`): ribbon (trial title, candle timer, TRUE PRINCE /
CHANGELING badge, SAMPLE DATA stamp), one objective line (it turns crimson while the Giant's hand is in the hall), the four
role cards along the bottom (Helmsman `x` left/right, Liftmaster `y` climb/dive, Wingmaster `z` forward/brake, Seer
hold-to-scan; each card lights gold while its role is pressing and shows the server's authoritative position on its axis),
the Royal Seer panel, captions on a scroll, and lobby / Chronicle overlays.

**Hamlet's Reliquary** (top-left): Royal Mantle, Sun Halo and Wing Filigree, toggled with a click or keys `1` `2` `3`.
Cosmetic and local only: nothing goes to the relay or the server. The choice is kept in `user://reliquary.cfg`.

Keys: `1`/`2`/`3` relics, `F1` debug overlay (raw state + the six brain-activity waveforms, which are debug-only),
`F2` the old dashboard, `F11` fullscreen.

## What it reads (and what it never shows)

`scripts/court/court_state.gd` reads each `state` message from `GameState` without changing GameState or any format.

- **Real, from the server** (`server/main.py` `GameSession.godot_state()`, Phase 3 on `main`): `phase`, `time`,
  `fly{x,y,z,vx,vy,vz}`, `render.princess{bearing_deg, elevation_deg, distance_cm}`, `render.giant{…, approach_cm_s, size_cm}`,
  `roles{helmsman, liftmaster, wingmaster, seer}`. Render cues are turned back into hall positions with the 220 cm per body
  unit that `server/seer_adapter.py` uses (`HallCam.UNIT_CM`).
- **Provisional, nobody has defined them yet**; each one shows as neutral until a server sends it: `trial`,
  `brain` / `cues.source`, `meters.candle`, `activity` (or `cues.activity`), `controls`, `room`, `players`, `chronicle`.
- **Private, never on this screen:** the Seer's cues (Princess bearing, Giant direction and countdown) go only to the
  Seer's phone. The Seer panel shows scanning/resting (its compass sweeps, it never points), a Giant lamp that lights only
  once the hand is already visible in the hall, and four brain-activity rows (vision, flight, reaction, song, the grouping
  in `team/README.md#proposed-formats`) as magnitudes, so no bar can give away a side.
- The Chronicle shows `server/chronicler.py`'s result as it comes: percent = `round(share * 100)`, seconds = `tick * 0.02`.

Audio: the Court scene loads `scripts/voice_player.gd` when that file exists (the same hook the dashboard uses).

## Run it

```sh
godot --path host                       # the court; plays test/sample_sequence.json until a server is up
godot --path host -- --dashboard        # the previous dashboard (scenes/Main.tscn), kept as a fallback
```

The first time on a fresh clone, open the project in the editor once, or run `godot --headless --path host --import`, so
Godot builds its class cache. The court scripts use `class_name`.

Screenshots at 1280x720 from the fixtures (windows opened this way never take keyboard focus):

```sh
godot --path host -- --screen=lobby --shot=lobby.png
godot --path host -- --screen=trial --frame=45 --shot=trial.png
godot --path host -- --screen=trial --frame=136 --shot=giant.png
godot --path host -- --screen=chronicle --shot=chronicle.png
godot --path host -- --screen=trial --frame=45 --relics=123 --shot=relics.png
godot --path host -- --live_shot=live.png --after=6     # the real GameState pipeline instead of fixtures
```

## Fixtures (`test/`)

`python host/test/make_fixtures.py` (standard library only) writes `sample_sequence.json` (300 frames at 30 Hz, using
`server/movement.py`'s tuning and `server/seer_adapter.py`'s Princess maths), `sample_events.json` (captions from
`docs/LORE.md`, by frame), `sample_lobby.json` and `sample_chronicle.json`. Every frame says `"sample": true`, so the
screen stamps SAMPLE DATA. The numbers are hand-scripted placeholders, not brain output. The sequence also carries the old
dashboard's fields so the fallback scene still animates offline.

## Fonts

`assets/fonts/`, all SIL OFL from google/fonts (licences alongside): Jacquarda Bastarda 9 (blackletter titles, 18 px),
Silkscreen (labels, 8 px), Pixelify Sans (captions, 16 px). They load straight from the `.ttf` bytes with antialiasing off.

## Known issues

- **Offline start is slow on Windows.** With no server running, `GameState`'s first WebSocket attempt stays "connecting"
  for about 30 s before it falls back to the sample sequence (measured: first frame 35.7 s after launch). Its 3 s retry
  probe also restarts the sample at frame 0 each time it fails. The court just shows the idle hall meanwhile.
  Not changed here, because GameState was out of scope for the reskin.
- No room code or QR is defined in any real message yet. The lobby shows `room` if sent, otherwise `----`.
- Final sprite art is not integrated; all art is placeholder pixel art drawn in code.
