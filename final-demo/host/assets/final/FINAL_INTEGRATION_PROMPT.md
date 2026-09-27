# Final Godot Art Integration Handoff

## Objective

Integrate the approved team-created final visual assets in this folder into the
Godot demo. The game must continue to run at its native **640 x 360** viewport
with nearest-neighbour scaling to 1280 x 720.

This is a visual integration task only. Do not redesign the game loop, change
the relay protocol, alter server authority, change brain/Seer behavior, or add
new gameplay rules.

## Final-art source of truth

Use only the approved reference sheets in `host/assets/final/`:

```
characters/hamlet_asset_sheet_final.png
characters/miranda_asset_sheet_final.png
characters/prospero_asset_sheet_final.png
characters/helmsman_asset_sheet_final.png
characters/liftmaster_asset_sheet_final.png
characters/wingmaster_asset_sheet_final.png
characters/royal_seer_asset_sheet_final.png
characters/lord_tinman_asset_sheet_final.png
characters/sir_cheapdate_asset_sheet_final.png
characters/count_rutabaga_asset_sheet_final.png
characters/clown_jester_asset_sheet_final.png
hazards/giant_hand_asset_sheet_final.png
```

These are 1024 x 1024 **reference sheets** with labels and presentation
backgrounds. They are not direct runtime textures.

## Required asset preparation

1. Create `host/assets/final/runtime/`.
2. Export or crop each selected pose into an individual transparent PNG.
3. Use these native dimensions:
   - Hamlet flight frames: 48 x 48 px.
   - Giant hand/hazard frames: 96 x 96 px.
   - All other character frames: 64 x 80 px.
4. Do not include labels, checkerboards, parchment panels, or sheet borders in
   runtime files.
5. Preserve crisp pixel edges: nearest-neighbour filtering only; no blur,
   anti-aliasing, smoothing, bloom, or gradient shading.
6. Keep each character's anchor stable from frame to frame.

## Initial integration order

Do these in order. Stop and retain a working build after every step.

1. **Hamlet:** replace the playable rear-view fly presentation with the final
   Hamlet hover, wing, bank, hit, and victory frames. Keep existing movement,
   wing timing, camera behavior, collision behavior, and FX intact.
2. **Miranda:** use her idle/hover presentation for the target and cutscene
   scenes. Her location remains server-authored; do not reveal her bearing on
   the shared HUD.
3. **Giant's Hand:** use raised, descending, impact, recoil, sweep, and retreat
   frames while preserving the existing warning/privacy behavior. Do not expose
   hidden Giant direction or ETA on the shared screen.
4. **Prospero:** use calm frames in neutral/win scenes and angry/throw frames in
   the father-loss branch. The final sheet contains both moods.
5. **Council and rivals:** place the Helmsman, Liftmaster, Wingmaster, Royal
   Seer, Tinman, Cheapdate, Rutabaga, and Jester in cutscenes, role panels, and
   background crowd moments only after the first four integrations work.

## Visual rules

- Keep the established palette: parchment `#F3E9D2`, ink `#2B2118`, royal blue
  `#1F3A8A`, crimson `#9B1C1C`, and gold `#C9A227`.
- Preserve the clean hand-drawn pixel-art style and one-pixel ink outlines.
- No photorealism, UI gradients, soft shadows, or franchise likenesses.
- The Council crests remain shape-distinct; no gameplay information may rely on
  color alone.
- The Royal Seer's Princess bearing and Giant timing remain private to the
  Seer's phone. Art must never accidentally add a map, directional arrow, or
  countdown to the shared game screen.

## Files and ownership

- Modify only `host/` and `audio/` files for this handoff.
- Do not modify `server/`, `relay/`, `brain/`, or shared game protocol files.
- Keep older `host/assets/pixelart/v2`, `v3`, and `v4` folders untouched. They
  are retained as non-shipping prototype history, not runtime art sources.

## Acceptance checklist

- Godot opens at 640 x 360 and displays correctly at 2x.
- No missing-texture errors, checkerboards, labels, or sheet borders appear in
  the running game.
- Hamlet's wing cycle, banks, hit pose, and victory pose work with the existing
  movement state.
- Miranda and the Giant render without leaking Seer-only information.
- The entry screen, keyboard demo, and live server mode still launch.
- The build remains responsive on a normal laptop.
- Add a short runtime-file manifest to `host/assets/final/README.md` and update
  `host/README.md` only with claims verified by the running build.

## Provenance

The final sheets in this folder are team-created hand-drawn art. Do not replace
them with the older prototype studies and do not make any false claim about
what the running build currently loads.
