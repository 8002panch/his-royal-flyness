# Complete cast — v3

All requested cast entries are represented by **13 PNGs**: Hamlet, Miranda, four player council members, two Prospero moods, Giant hand, and four NPCs.

Use v3 for the current roster. Hamlet, Miranda, council members, and Tinman were generated against Cheapdate as the common style reference. Prospero's two moods, Giant, Cheapdate, Rutabaga and Clown are retained from v2.

| Character | File | Detail |
| --- | --- | --- |
| Prince Hamlet | [characters/hamlet.png](characters/hamlet.png) | New: compact gold prince with small crown |
| Princess Miranda | [characters/miranda.png](characters/miranda.png) | New: tiara and lavender wings |
| Duke Prospero — nice | [characters/prospero_nice.png](characters/prospero_nice.png) | Welcoming; use after defeating the Giant |
| Duke Prospero — mad | [characters/prospero_mad.png](characters/prospero_mad.png) | Frowning; use after losing to the Giant |
| Council — Helmsman | [council/helmsman.png](council/helmsman.png) | New: wheel, blue navigator coat |
| Council — Liftmaster | [council/liftmaster.png](council/liftmaster.png) | New: arrow staff, rope, green hood |
| Council — Wingmaster | [council/wingmaster.png](council/wingmaster.png) | New: goggles, scarf, feather |
| Council — Royal Seer | [council/royal_seer.png](council/royal_seer.png) | New: eye emblem, purple hood, orb |
| Giant | [hazards/giant_hand.png](hazards/giant_hand.png) | Hand representation of the established obstacle |
| Lord Tinman | [npcs/lord_tinman.png](npcs/lord_tinman.png) | Revised: compact armor and broken-heart tabard |
| Sir Cheapdate | [npcs/sir_cheapdate.png](npcs/sir_cheapdate.png) | Tipsy expression, feather cap, goblet |
| Count Rutabaga | [npcs/count_rutabaga.png](npcs/count_rutabaga.png) | Puzzled expression, monocle, mismatched boots |
| Clown, the Court Jester | [npcs/clown_jester.png](npcs/clown_jester.png) | Narrator: bell hat and joke baton |

## Status and handoff

- Built-in image generator; original character designs. Full new prompts and file dimensions are in `manifest.json`.
- High-resolution static pixel-style sprite studies, not normalized 48x64 animation sheets. Sprite footprint and palette still need a production pixel-grid pass. Use nearest filtering and preserve aspect ratio in prototype previews.
- PNG decoding and transparent corner samples checked for all 13 files; generated outputs visually inspected. In-engine animation and readability have not been validated.
- Prospero's outcome mapping is documented for Claude; this pack does not implement boss logic.
- The Giant is represented by the established hand hazard. Council uses current live roles: Helmsman, Liftmaster, Wingmaster and Royal Seer.
- Runtime files are being edited in parallel by the world builder. Point scene textures at `res://assets/pixelart/v3/...` during integration; the old standalone demo may still reference older Hamlet art.

Open [gallery.html](gallery.html) to review the entire roster together.
