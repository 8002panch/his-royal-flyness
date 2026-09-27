# Final art handoff

This folder is reserved for the **approved hand-drawn final assets** used by the
demo running on Neil's laptop.

## Current status

The final hand-drawn source files are being copied into this checkout as they
are approved. Do not place the older generated art studies from
`../pixelart/v2`, `../pixelart/v3`, or `../pixelart/v4` here and do not
describe those studies as final art.

- Approved Hamlet visual reference:
  `characters/hamlet_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and a checkerboard display background;
  export its individual transparent frames before using them as runtime Godot
  textures.
- Approved Princess Miranda visual reference:
  `characters/miranda_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and a checkerboard display background;
  export its individual transparent frames before using them as runtime Godot
  textures.
- Approved Duke Prospero visual reference:
  `characters/prospero_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and a parchment display background;
  export its individual transparent frames before using them as runtime Godot
  textures.
- Approved Giant's Hand visual reference:
  `hazards/giant_hand_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and scene display backgrounds; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Royal Helmsman visual reference:
  `characters/helmsman_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Royal Liftmaster visual reference:
  `characters/liftmaster_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and a checkerboard display background;
  export its individual transparent frames before using them as runtime Godot
  textures.
- Approved Royal Wingmaster visual reference:
  `characters/wingmaster_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Royal Seer visual reference:
  `characters/royal_seer_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display background; export
  its individual transparent frames before using them as runtime Godot textures.
- Approved Lord Tinman visual reference:
  `characters/lord_tinman_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Sir Cheapdate visual reference:
  `characters/sir_cheapdate_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Count Rutabaga visual reference:
  `characters/count_rutabaga_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.
- Approved Clown, the Court Jester visual reference:
  `characters/clown_jester_asset_sheet_final.png` (1024 x 1024 asset sheet).
  It is a reference sheet with labels and parchment display panels; export its
  individual transparent frames before using them as runtime Godot textures.

When the final files are available, copy them here without changing their
approved appearance:

```
final/
  characters/     # Hamlet, Miranda, Prospero, council, rivals, Jester
  backgrounds/    # Garden, basement, passage, banquet, Giant and father arenas
  hazards/        # Giant fist, spikes, thrown objects, collision markers
  ui/             # Crests, panels, title cards, icons
  fx/             # Wing buzz, dust, splat, hearts
  animations/     # Final frame sheets or Godot-ready animation resources
```

The current Godot demo also has code-drawn environment art under
`host/scripts/court/backgrounds/` and `host/scripts/court/backgrounds_v2/`.
Those source scripts remain the runtime source until the hand-drawn files are
imported and wired into scenes.

## Runtime export (`final/runtime/`)

`host/tools/export_final_art.py` crops each approved sheet above into individual
transparent frames at the native sizes `FINAL_INTEGRATION_PROMPT.md` specifies
(Hamlet flight frames 48x48, the Giant hand 96x96, everyone else 64x80), and
writes them to `final/runtime/<character>/<pose>.png` plus a `manifest.json`.
Run it again after any sheet is replaced:

```
python host/tools/export_final_art.py
```

**Wired into the running game:** Hamlet only, via `scripts/court/final_art.gd`
and `scripts/court/hamlet.gd` (`_tick_final_art`). When `final/runtime/hamlet/`
is present, his hover/wing/bank/hit/victory frames replace the animated cast
rig; if the folder is missing, the game falls back to the rig as before. This
has been written and reasoned through but **not yet opened in the Godot
editor to confirm on screen** — there is no Godot install in the environment
this change was made in. Before the demo, open `project.godot`, fly Hamlet
around, and check the wing cycle, banking, hit pose and victory pose look
right; the older code-drawn rear view is still there as a second fallback if
anything is missing a texture.

**Exported but not yet wired:** Miranda, Prospero, the four council roles,
Lord Tinman, Sir Cheapdate, Count Rutabaga, the Clown, and the Giant's Hand.
Their sheets use a different caption/background layout than Hamlet's, so the
same automatic crop only isolated a rough bounding box per pose for them
(`pose_<row>_<col>.png`, not named poses) and should be spot-checked and
re-cropped by hand before wiring them into `giant_hand.gd`, `miranda.gd`,
`rival.gd`, etc. Don't wire these in without checking each frame first.

## Provenance

The assets in this folder are the approved final production art for the
hackathon demo. They were created entirely by the team by hand; no AI
image-generation tool was used to create these final assets.

The older `host/assets/pixelart/v2`, `v3`, and `v4` studies were temporary
placeholder visuals used to test the early concept. They are not final demo
art and are retained only as development history. The team planned to replace
those studies with its own final assets, which are collected here.

Keep this folder limited to approved final files and this small factual
manifest.
