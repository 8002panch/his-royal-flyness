# Pixel-art version history

## Animation package 1.0 — 2026-09-26 — hybrid cast rigs

Added `animation_v1/`: thirteen compact Godot cutout rigs derived from the unchanged v3 art, idle/walk/fly/takeoff/land, named theatrical hand/body gestures, Giant slam/recoil, a cue timeline, and a runnable all-cast preview. Character bodies use a 72px visible height, not higher-resolution artwork. The actual court's rear-view Hamlet now has eight wing poses, foreshortened recovery, restrained banking and cloak sway. See the package README for measured preview performance, tests, integration boundaries, and pending script timing.

## v3.1 — 2026-09-26 — Giant fist revision

Replaced the v3 Giant open-hand hazard with a matching transparent clenched-fist PNG, preserving its royal-blue sleeve, gold cuff, scale, and original pixel-art treatment. The v3 manifest and roster notes now identify it as a slam fist.

## v3 — 2026-09-26 — complete consistent roster

Added new Hamlet and Miranda in the compact RPG style, four player council characters, and a shorter Tinman. Combined these with the six retained v2 images into a complete 13-PNG roster (including both Prospero moods). See `v3/README.md`, `v3/manifest.json` and `v3/gallery.html`. Source PNGs decode correctly and have transparent corner samples. Runtime integration and production pixel-grid normalization remain pending.

## v2 — 2026-09-26 — simpler handheld RPG character direction

User requested moderate detail inspired by classic handheld RPG games. Added seven original transparent PNG sprite studies: Prospero nice/mad, Lord Tinman, Sir Cheapdate, Count Rutabaga, Clown the Court Jester, and a simplified Giant hand.

See `v2/README.md` for dimensions, generation provenance, status, and Claude's integration notes. The batch is saved locally; no gameplay code or runtime scene integration is included. Native pixel normalization and animations are pending.

## v1 — earlier experiments in this conversation

The earlier standalone project at `C:/Users/anshu/Desktop/Claude/host/assets/pixelart/v1` contains Hamlet, Miranda, Giant hand, feast table and Royal Mantle studies. These were created before the simpler RPG direction and are not automatically approved for v2. The preceding ornate Prospero and Giant generated previews were also superseded by this style correction.

## Revision rule

Keep each art iteration under its version folder. Never overwrite accepted files. Record changes and distinguish generated studies, normalized sprites, animation-ready assets, and in-engine-verified assets explicitly.
