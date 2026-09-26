# His Royal Flyness — Pixel-Art World Concept

**Status:** accepted host-art direction proposal · **Owner:** Anshul (`host/`) · **Version:** 1.0.0 · **26 Sept 2026**

## The decision

The host must become a **warm, intentional pixel-art royal court**, not a dark sci-fi telemetry dashboard with medieval labels pasted on top.

The current host screen is functionally valuable: it has the correct direct-movement roles, a candle timer, a Royal Seer, Giant warnings, and nervous-system readings. Keep those working interfaces. Its visual treatment, however, needs a full reskin because it currently emphasizes thin vector lines, blue-black panels, glow, charts, and empty space over the playable royal world.

The player should immediately see: **tiny Prince Hamlet, vast banquet hall, Princess Miranda, and a hand about to swat him.** Information panels should support that scene, never replace it.

## Non-negotiable pixel rules

- Draw the world at an internal **640×360** base resolution and scale to the presentation resolution with nearest-neighbor/integer scaling.
- Use deliberate 2–4 px clusters, one dark ink-like outline, flat colors, and sparse highlights.
- Palette anchors: parchment `#F3E9D2`, ink `#2B2118`, royal blue `#1F3A8A`, crimson `#9B1C1C`, gold `#C9A227`; add only muted stone, wood, and Miranda-lavender where necessary.
- Depth comes from overlap, scale, floor tiling, arches, banners, and contrast—not gradients, bloom, blur, glass, or soft glows.
- Any source image imported into Godot must use nearest-neighbor filtering. No bilinear filtering, no anti-aliased scale transforms.
- Readability wins: Hamlet, Miranda, the Giant, active controls, and warnings must remain distinct on a 1280×720 projector view.

## Layout to build

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ Trial parchment · candle timer · True Prince / Changeling badge           │
├──────────────┬───────────────────────────────┬───────────────────────────┤
│ Helmsman     │  ROYAL BANQUET HALL            │ Royal Seer                │
│ Liftmaster   │  ceiling arch / columns         │ compact compass           │
│ Wingmaster   │  banners / feast tables         │ Giant warning             │
│              │  carpet to Miranda              │ four neural bars          │
│              │  Hamlet + rivals + Giant        │                           │
├──────────────┴───────────────────────────────┴───────────────────────────┤
│ Four connected-player crests · caption bar · small Hamlet Reliquary       │
└──────────────────────────────────────────────────────────────────────────┘
```

### The central world is the priority

Use separate render layers/nodes:

1. Far layer: blue vaulted ceiling, moonlit arch, distant palace door.
2. Mid layer: stone columns, crimson and royal-blue banners, wall candles.
3. Play layer: tiled floor and a carpet leading toward Miranda.
4. Prop layer: side feast tables, fruit, goblets, bread, and small court décor.
5. Actor layer: Hamlet, Miranda, scripted rivals, and the Giant’s Hand/shadow.
6. FX layer: wing buzz, jump dust, hand telegraph, Splat ink burst, hearts.

Never bake actors into the hall image. Their `Sprite2D`/`Node2D` nodes need independent position, z-index, animation, and event control.

### Supporting UI

- Convert cards to parchment panels with 1–2 px ink borders, gold corner brackets, and shape-first icons.
- Keep the **actual current roles** and protocol names: Helmsman (left/right), Liftmaster (up/down), Wingmaster (forward/back), and Royal Seer (scan/cues).
- The Seer retains `cues.princess`, `cues.giant`, and `cues.activity`, but presents them as compact compass/warning/bar widgets. Dense waveforms belong in debug tooling, not in the main playable view.
- Keep timer, True Prince badge, captions, names, and connected state. Reduce prose and low-priority labels.

## Asset plan and inventory

Create a non-destructive versioned asset tree:

```text
host/assets/pixelart/
  VERSION_HISTORY.md
  v1/
    characters/hamlet_idle_px_v1.png
    characters/miranda_idle_px_v1.png
    characters/rival_01_px_v1.png
    hazards/giant_hand_px_v1.png
    props/feast_table_px_v1.png
    accessories/royal_mantle_px_v1.png
    accessories/sun_halo_px_v1.png
    accessories/wing_filigree_px_v1.png
    ui/crest_helmsman_px_v1.png
    ui/crest_liftmaster_px_v1.png
    ui/crest_wingmaster_px_v1.png
    ui/crest_seer_px_v1.png
    fx/wing_buzz_01_px_v1.png
    fx/jump_dust_px_v1.png
    fx/splat_px_v1.png
```

The **Hamlet’s Reliquary** is a small three-slot inventory strip, not a large RPG menu:

| Slot | Visual | First implementation |
| --- | --- | --- |
| Royal Mantle | crimson/blue cape | local equipped state, cosmetic only |
| Sun Halo | gold ring | local equipped state, cosmetic only |
| Wing Filigree | gold wing trim | local equipped state, cosmetic only |

Keep `equipped_accessories` isolated from the server state until the team chooses a protocol. Never change the relay or state-message shape for cosmetic inventory.

## Step-by-step migration

1. **Preserve the current screen.** Duplicate/retain the dashboard scene as a fallback; do not touch `game_state.gd` message parsing or the live server contract.
2. **Set pixel rendering.** Configure the internal viewport, nearest texture filtering, and integer scale. Verify screenshots show hard pixels.
3. **Build world layers.** Make the banquet hall first, with no actors baked in. Validate that the world fills the visual center.
4. **Add gameplay anchors.** Place Hamlet, Miranda, rivals, and Giant as independent nodes tied to current state positions/events.
5. **Reskin existing controls.** Map current Helmsman/Liftmaster/Wingmaster values and Seer cues into parchment components without changing bindings.
6. **Install compact telemetry.** Preserve the actual activity values (vision, flight, reaction, song) as icon/bar rows; remove dashboard-dominant waveforms.
7. **Add Reliquary v1.** Local visual equip toggles only; no network change. Use assets with immutable versioned names.
8. **Add cheap feedback.** Two-frame wing buzz, dust puff, pre-swat hand shadow, very short shake, ink Splat, and Miranda hearts.
9. **Perform projector test.** At 1280×720, ask a new player to identify Hamlet, Miranda, the hazard, their role, and the next action in under five seconds.
10. **Polish only after clarity passes.** Candle flicker, banner movement, margin insects, and extra props are optional; cut any effect that reduces clarity or frame rate.

## Done means

- [ ] The first read is “royal fly game in a banquet hall,” not “neural telemetry app.”
- [ ] The scene visibly uses pixel-art construction, not vector UI plus a pixel texture.
- [ ] No gradient depth, blur, bloom, glass panel, cyan glow, or non-integer scaling remains in the main scene.
- [ ] Hamlet, Miranda, and the Giant remain legible at demo distance.
- [ ] All current host state updates still work with the real message formats.
- [ ] Every accepted art asset is recorded in `host/assets/pixelart/VERSION_HISTORY.md`; revisions use a new version/folder and never overwrite accepted art.
