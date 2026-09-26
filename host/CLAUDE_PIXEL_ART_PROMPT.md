# Prompt for the World Builder

Copy this prompt to the teammate/Claude building the Godot world.

---

Rebuild the visual presentation of **His Royal Flyness** in Godot 4 as a polished **medieval pixel-art royal court**. Preserve all current gameplay behavior, WebSocket/phone input, timer logic, audio hooks, `GameState` parsing, and state-message contracts. This is a host-world reskin, not a networking or server rewrite.

The current screen functions, but it looks like a dark sci-fi medical dashboard: thin vector lines, blue-black cards, glows, grid charts, empty central space, and too much small text. Replace that visual language. It should instead feel like an illuminated manuscript translated into high-quality 16/32-bit pixel art.

## Pixel rules

- Render at **640×360** internally; present at 1280×720 with nearest-neighbor/integer scaling.
- Build with hard 2–4 px clusters, dark ink outlines, flat colors, and sparse highlights.
- Palette: `#F3E9D2` parchment, `#2B2118` ink, `#1F3A8A` royal blue, `#9B1C1C` crimson, `#C9A227` gold.
- No blur, bloom, soft glows, gradient depth, glass cards, futuristic grids, bilinear scaling, or anti-aliased sprites.

## Visual hierarchy

1. The central **Banquet Hall** is the hero: arched ceiling, columns, banners, side feast tables, tiled floor, and a red carpet leading to Princess Miranda.
2. Hamlet is bright and obvious in the foreground; Miranda is the clear destination; the Giant’s Hand and its pre-impact shadow are the clear hazard.
3. UI becomes parchment-and-gold support chrome around the world.
4. Keep the existing real roles and bindings: Helmsman, Liftmaster, Wingmaster, and Royal Seer. Do not change protocol names or signal formats.
5. Keep the Seer’s compass, Giant warning, and activity data, but display activity as four compact icon/bar rows. Main-play waveforms are debug-only.

## Required build order

1. Preserve the current screen as a fallback scene.
2. Configure nearest-neighbor pixel rendering.
3. Build the hall in independent far/mid/play/prop/actor/FX layers.
4. Add Hamlet, Miranda, rivals, and Giant as independent sprites/nodes; do not bake them into a background.
5. Port existing live values into compact parchment panels.
6. Add a small Hamlet’s Reliquary inventory with local cosmetic state only: Royal Mantle, Sun Halo, Wing Filigree.
7. Add only cheap, readable feedback: wing buzz, dust, hand telegraph, Splat, hearts.
8. Test at 1280×720. A new player must find Hamlet, Miranda, danger, their role, and their next action within five seconds.

Read `host/PIXEL_ART_WORLD_CONCEPT.md` before implementation. It contains asset structure, layout, acceptance checks, and the constraint that we do not alter the live game interfaces.
