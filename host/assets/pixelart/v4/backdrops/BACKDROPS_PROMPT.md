# v4 backdrops prompt (paste into Codex image generation; make ALL 8 in one go, or one at a time with this header)

Reference images (style only): host/screenshots/01-trial.png (the current Banquet Hall in the Godot court) and
host/assets/pixelart/v3/characters/hamlet.png. Every new backdrop must look like it belongs in that same game.

## THE LOOK TO MATCH (from the existing court)
- Camera: behind-and-slightly-above, looking straight down the room (one-point perspective, vanishing point near the middle of
  the picture). Walls and columns recede toward a far wall.
- Materials: dark warm stone brick walls (grout lines visible), a tiled stone floor in two close browns, grey-brown stone columns
  in a receding arcade, gothic pointed arches with thin gold outlines, tall lancet windows on the side walls.
- Decor: hanging royal-blue and crimson banners with small gold emblems (crown, star, heart), gold candelabra with tiny flames,
  a red carpet with gold stud pattern, a royal-blue dais, cloth-of-estate behind the far arch, a round rose window.
- Pixel style: flat colour, no gradients, no blur, no glow, no soft shadows, no photo textures. 2-4 px clusters, one dark ink
  outline on big shapes, hard-edged 2-3 tone shading. Depth comes from overlap, scale and repeating tiles only.
- Native pixel grid 640x360. Deliver at 1920x1080 (each art pixel is exactly 3x3), crisp nearest-neighbour edges, no anti-aliasing.
- PALETTE ONLY (exact hex): parchment #F3E9D2, ink #2B2118, royal blue #1F3A8A, crimson #9B1C1C, gold #C9A227,
  stone deep #2A221C, stone dark #3A3028, stone #4E4136, stone light #665545, stone highlight #83705A,
  floor A #43362B, floor B #56473A, grout #30271F, wood #5A3A22, wood light #7C5232, vault blue #141F48.
  Extra tints allowed only from these families (dark/light steps of the same hue).
- The room is darker and warmer than the characters, so characters read first. Keep the centre-bottom third calm and low-contrast:
  a flying character, HUD bars (top strip, bottom cards, right-hand panel) and captions will sit on top.
- No text, no lettering, no characters, no creatures, no people, no crowd. Furniture is EMPTY.

## HARD PRIVACY RULES (story requires them)
Only the Seer's phone may know the hidden route. So in the basement and passage images:
- NO visible safe path, NO route markers, NO arrows, NO lit lane, NO wall-edge outlines that reveal where walls or spikes are,
  NO shadow of a hand or any target marker. Paint plain atmosphere and generic clutter only, evenly spread so no lane stands out.
- Do not draw any Giant, hand, spike row or projectile in the backdrops (those are separate assets).

## THE 8 BACKDROPS (save as host/assets/pixelart/v4/backdrops/<name>.png; never overwrite v1-v3)

1. bg_garden.png  (Tutorial: Royal Garden)
   Open royal garden at warm evening, same one-point view. Low hedge walls and grape-vine trellises receding down both sides,
   stone paving, a small empty round flagstone plaza in the middle distance where a gold cup on a stand will be placed later.
   Stone palace wall with a tall pointed doorway and rose window at the far end, blue and crimson banners on it.
   Sky strip at top in royal blue steps (flat bands, no gradient). Purple grape clusters on the vines are OK as decoration only.

2. bg_gate_outside.png  (comic: Hamlet locked out)
   The palace's closed iron gate seen from outside, evening. Stone gatehouse with two gold-capped pillars, blue and crimson banners
   above, cobbled ground. Gate is shut and empty. Small low side window visible far left in the wall.

3. bg_window_ledge.png  (comic: Tinman's window)
   A low stone window ledge seen close up from outside: thick stone sill, a partly open leaded window, warm light inside, ivy.
   Empty ledge, nothing on it. Foreground calm for a character to lean on.

4. bg_basement.png  (Stage 1: The Journey to the Court)
   A dim, crowded basement in the same stone style: low vaulted ceiling with heavy arches, dark stone walls, hanging lanterns
   with tiny flames, barrels, crates, sacks and shelves EVENLY scattered on both sides and far end, cobweb corners.
   Much darker (use vault blue, stone deep, stone dark) but not black; the centre stays readable. No lane, no path, no arrows.

5. bg_inner_passage.png  (Stage 2: Prove Yourselves)
   A long stone inner passage with a stair at the near end and a pair of big gold-trimmed double doors at the far end
   (the banquet doors), closed. Arched niches, wall torches, banners. Neutral and symmetrical. No route markers, no danger marks.

6. bg_banquet.png  (banquet comics, and the hall in the current game)
   The existing Banquet Hall look, redrawn clean: pointed great arch with rose window and cloth of estate at the far end,
   red carpet and blue dais, two long feast tables with plates, goblets and candelabra, arcade columns, hanging banners.
   All chairs EMPTY. Include one punch bowl on a side table (a chair tipped into it is added later, do not draw the chair in it).

7. bg_arena.png  (Giant encounter: Outlast the Giant)
   The banquet hall's wide clear floor: tables pushed to the walls and overturned chairs stacked at the edges, a big open
   tiled floor in the middle so there is space to dodge. Same walls, columns and banners, dimmer and tenser (more stone dark, fewer
   candles). No hand, no shadow, no target marks on the floor.

8. bg_father_arena.png  (Prospero's Last Word)
   A small side chamber off the banquet hall: a low round-vaulted room, one pointed arch back to the hall, a stone bench and a
   banner on each side wall, plain tiled floor. The left side is empty because Prospero is added later as a separate sprite.
   No spitball, no acid, no puddles.

## OUTPUT CHECKLIST
- 8 PNG files, opaque, 1920x1080, exactly on a 3x3 pixel grid, only the palette above, no text, no characters.
- Also give a contact sheet (2x4) so I can compare them next to host/screenshots/01-trial.png.
