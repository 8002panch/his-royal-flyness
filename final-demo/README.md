# final-demo/

The playable **His Royal Flyness** demo with only the final assets: the Godot 4.3 project
(`host/`) and its audio (`audio/`), pruned of the superseded placeholder art studies
(`host/assets/pixelart/v2`, `v3`, `v4`) that lived alongside the real final art during
development. This folder is a snapshot for hand-off and judging, not a place for further
day-to-day development — keep working in `host/` and `audio/` at the repo root; re-export
this folder from there if it needs to be refreshed.

## What's in here

- `host/` — the full Godot project: scenes, scripts, shaders, fonts, screenshots, and
  `host/assets/final/` (the team's approved hand-drawn asset sheets, plus the runtime frames
  cropped from them — see `host/assets/final/README.md` for provenance and what's wired in).
  `host/assets/pixelart/animation_v1/` (the animated cast rigs) is kept: several scenes load
  those files directly and the game will not run without them, so it isn't a "previous
  version" in the same sense as `v2`/`v3`/`v4`.
- `audio/` — every voice line, music track and sound effect the demo plays.

## What was left out, and why

`host/assets/pixelart/v2`, `v3` and `v4` are the team's own early concept-art studies,
explicitly called out in `host/assets/final/README.md` as superseded and not final demo art.
Leaving them out means two small things won't show in this copy:

- The Clown's caption speech-bubble head icon (`StoryArt.clown_head()`, sourced from `v3`) —
  the caption line still shows, just without the little portrait.
- A handful of story-scene backdrop images (`StoryArt.backdrop()`, sourced from `v4`) — those
  scenes fall back to whatever the scene's other code-drawn layers already provide.

Both are read through the codebase's own "load if present, else skip quietly" pattern, so
their absence does not error or crash the game — confirmed with Godot 4.3 headless
(`--import`, then `--shot` on the trial and chronicle screens; no console errors, screenshots
below). Only Hamlet is currently drawn from the final hand-drawn art at runtime; every other
character still uses the game's code-drawn placeholder look until their sheets are cropped
and wired in the same way (see `host/assets/final/README.md`).

## Run it

Same as the root project:

```sh
godot --path host
```

First run on a fresh clone: open the project in the editor once, or run
`godot --headless --path host --import`, so Godot builds its class cache.

## Provenance

The art in `host/assets/final/` is the team's own approved final production art, made
entirely by hand. No AI image-generation tool was used to create it. See
`host/assets/final/README.md` for the full manifest and per-asset notes.
