# Cast animation package 1.0

Built from the approved v3 artwork on 2026-09-26. All original PNGs remain unchanged. The game stays at its existing 640x360 render resolution, nearest-neighbor scaled to 1280x720. The chase-camera gameplay and direct phone controls remain the reference.

## Included

- 13 reusable Godot scenes in `rigs/`: Hamlet, Miranda, Prospero nice/mad, Helmsman, Liftmaster, Wingmaster, Royal Seer, Tinman, Cheapdate, Rutabaga, Jester, and the Giant fist.
- Insect characters are 72 visible pixels high; the fist is 80. Their original colors and costumes are sampled into colored cutout meshes with independent wings, arms, legs, and body. No texture generation, image decoding, shader, or new animation allocation happens per frame.
- Each insect supports idle, walk, fly, takeoff and land. Gestures: talk, wave, point, bow, approve, angry, celebrate, hit, toast, confused, scan, sing. The Giant supports slam and hit; it does not walk or fly.
- These are small cutout motions using the existing hand shapes, not newly drawn hand poses or phoneme lip-sync. Takeoff/land finish automatically. Gestures finish and return to the current locomotion pose. The caller controls translation through the world.
- A local JSON cue director and `example_cues.json` for the forthcoming dialogue script. These sample cues are theatrical animation, never brain output.
- The court's existing rear-view Hamlet now has eight wing poses with a broad downstroke and thin recovery, a 3-5 cycle/sec display cadence, gentle velocity-driven bank, cloak sway, and hit/victory reactions. It uses his established crown/body/cosmetic art.

## Review

Open `res://scenes/AnimationPreview.tscn` in Godot 4.3 and run the current scene (F6), or:

```text
godot --path host res://scenes/AnimationPreview.tscn
godot --path host res://scenes/AnimationPreview.tscn -- --timeline
```

Keys: 1 idle, 2 walk, 3 fly, 4 land, G cycle gestures, S slow motion, Space pause, R reduced motion. The last tile is the actual rear-view Hamlet from the court. `cast-tour.mp4` shows the full roster in motion. `preview-court.png` verifies the changed wings in the court.

## Integration for Claude

```gdscript
var actor = preload("res://assets/pixelart/animation_v1/rigs/hamlet.scn").instantiate()
add_child(actor)
actor.position = Vector2(160, 220) # feet origin; parent owns world motion
actor.set_motion("fly", 0.6, 1.0) # mode, normalized speed, facing sign
actor.play_gesture("bow", 1.6) # overlays locomotion, then returns
actor.gesture_finished.connect(func(cue): print(cue))
```

For perspective, scale this 72px rig to the desired on-screen height with nearest rendering. Horizontal facing mirrors the existing three-quarter pose, not a newly authored side/back view. The current chase Hamlet already has a separate native rear view and stays in gameplay. Use the front cast rigs for NPCs and dialogue staging. Wire their poses/visibility from the actual scene or script; the package does not invent NPC world paths, outcomes, or dialogue timings.

```gdscript
var director = preload("res://scripts/animation/cue_director.gd").new()
add_child(director)
director.register_actor("hamlet", actor) # register every actor named in the cue file
if director.load_cues("res://assets/pixelart/animation_v1/example_cues.json"):
    director.play()
```

The director accepts the `cast_rig.gd` interface (the scenes in this package). The existing chase `HamletActor` has a different velocity-based movement interface; its bank/wingbeats are already wired in `court_world.gd`. Do not register it as a front cast rig. Use its `play_gesture("hit"|"celebrate"|"bow", seconds)` directly.

## Performance and validation

Measured on this Windows RTX 5070 laptop using Godot 4.3 Compatibility renderer: full preview at 60 FPS; animation update code averaged 0.42 ms/frame; 148 total preview draw calls (including labels/panels and the rear Hamlet). Thirteen compressed rigs total 558,086 bytes, approximately 545 KiB. This is a preview measurement, not a benchmark of the brain/server running simultaneously. Profile that combined workload on the presentation laptop.

Pose updates are capped at 30 Hz, invisible cast rigs skip work, geometry is baked once, and there are no particle simulations or real-time lights. All 13 rigs passed the Godot smoke check: five locomotion modes, supported gesture completion, changing wing transforms, finite transforms, stable gameplay root, and sample cue timeline completion. The preview and court were also rendered and visually checked.

Rebuild the meshes after editing the source-mask profiles:

```text
godot --headless --path host --script tools/build_cast_rigs.gd
godot --headless --path host --script test/animation_smoke.gd
```

The builder reads raw PNGs on the development machine and emits exportable `.scn` files; Godot's raw-image export warning applies to this offline tool only. Runtime scenes load the baked meshes. Each source is split using its own mask coordinates in the builder. Source changes require reviewing those masks before rebuilding.

Next input: the dialogue script, including who speaks and approximate line durations. Map it onto the named gesture cues; bespoke poses can be added if a line requires an action outside this restrained hybrid range.
