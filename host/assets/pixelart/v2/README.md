# Character art v2 — handheld RPG direction

User direction: more like classic Pokemon-era handheld RPG visuals, with moderate detail. Original characters, larger heads, compact bodies, readable silhouettes, broad shade clusters, simpler costume ornament. Use Cheapdate and the Jester as the proportion reference.

These are transparent high-resolution generated sprite studies. They are not yet normalized 48x64 pixel sheets, animation frames, or validated native-resolution sprites. Use them for art review and prototype placement; a final pixel-grid and animation pass is still needed. Nearest filtering alone does not convert a high-resolution illustration into consistent native pixel art.

## Files

| File | Source canvas | Visual identity |
| --- | --- | --- |
| `characters/prospero_nice_v2.png` | 1086x1448 | relaxed brows, welcoming hand; after defeating the Giant |
| `characters/prospero_mad_v2.png` | 1086x1448 | angry brows, frown, fist; after losing to the Giant |
| `npcs/lord_tinman_v2.png` | 1085x1449 | angular silver helm, cold blue tabard; tall rival |
| `npcs/sir_cheapdate_v2.png` | 1086x1448 | tilted feather cap, goblet, sheepish face |
| `npcs/count_rutabaga_v2.png` | 1086x1448 | floppy cap, monocle, mismatched boots, puzzled face |
| `npcs/clown_jester_v2.png` | 1086x1448 | two-point bell hat, diamond tunic, joke baton |
| `hazards/giant_hand_v2.png` | 1254x1254 | chunky gray hand and simple blue/gold cuff |

## Integration handoff for Claude

- Target native sprites around 48x64 for the court characters, with consistent pixel density and feet anchors. Test actual display size before accepting exports.
- Preserve aspect ratio; trim transparent padding or define an explicit texture region before applying a common display height.
- Nice/mad Prospero use matching source canvases. Keep the same anchor when switching textures; verify the pose doesn't jump.
- Outcome mapping is a requested visual behavior; this asset delivery does not implement boss or server logic.
- The player council still uses the live Helmsman/Liftmaster/Wingmaster/Seer role contract. No new role behavior is introduced here.
- Existing Hamlet/Miranda and the council portraits have not been revised in this batch.

## Generation provenance and prompt set

Generated with the built-in image generator in this conversation. Shared brief: original medieval fruit-fly characters, classic handheld top-down RPG pixel-art aesthetic, compact full-body three-quarter view, approximately 48x64 native-pixel complexity, chunky clusters, three-tone shading, ink outline, royal blue/crimson/gold/parchment palette, transparent background, no scenery/text/franchise character likeness.

Subject prompts: Tinman = cold steel noble with angular helm; Cheapdate = tipsy rival with feather cap and goblet; Rutabaga = forgetful count with monocle, floppy cap and mismatched boots; Clown = cheerful narrator with bell hat, diamond tunic and baton; Prospero nice = elderly duke with white brows/moustache, blue cloak, crimson sash, welcoming hand; Prospero mad = edit of nice with angry eyebrows, frown and fist while preserving costume/canvas; Giant = simple gray five-finger swatting hand with blue sleeve and gold cuff.

QA: each image was visually inspected in generation output and decodes as a PNG; top-left alpha is zero on all seven. Full edge-alpha and in-engine readability remain unverified.
