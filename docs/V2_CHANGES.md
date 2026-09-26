# v2 changes: what's different for each person (Sat 26 Sept, 16:20)

The team switched to **v2: three pilots and a Spymaster, in a third-person 2.5D view** ([GAME_DESIGN.md](GAME_DESIGN.md)).
Same roles for the four of us, same equal loads, same blocks and check-ins. **Update your own `team/<name>/README.md`** from the list
below (replace or edit tasks; keep your ticks). Anything already built for the lobby, relay, WebSocket client or brain still counts.

## What changed in the game

| v1 | v2 |
|---|---|
| Four senses: Lookout, Perfumer, Taster, Spymaster | **Coachman** (forward/back), **Helmsman** (left/right), **Falconer** (up/down), **Spymaster** (listens for Giants, senses the Princess) |
| Each role opened a sense; the arena decided what came in | Each **button stimulates a named group of real sensory neurons**; the wiring turns it into movement |
| Top-down hall, walking fly, manuscript art | **Third-person chase camera, low-poly flat-shaded 3D (BOMBANANA!-style), flying fly** (x, y, altitude, heading) |
| 3 trials in one room | **A journey: 4 chapters + the finale** (Pantry, Great Hall, Kitchen, Banquet, Royal Fruit Bowl), each with one **mini task** |
| Win: serenade 5 s | Win: reach the Fruit Bowl and serenade her 3 s |

## Neil (brain)

- **Done (16:50):** `brain/brain.py` v2 with `INPUT_GROUPS` = `forward, back, left, right, up, down, duck, serenade, lock_L, lock_R` and
  `OUTPUT_NAMES` = `DNp09, DNg100, MDN, DNa02_L, DNa02_R, DNg02, DNp07_10, DNp01, pIP10, pC1`; `io_sets.json` v2; stub updated.
  **All 10 buttons pass the gate at full drive** (controls matrix in `team/neil/probes_v2_level10.csv`).
- Probes v2 (B2): one probe per button, True Prince vs Changelings; post the z ranges so Arnav can set thresholds.
- Chronicler (B3) credits per **player** instead of per sense. `run_trials` + bots (B4) fly chapters instead of trials.

## Arnav (server)

- **B1:** body becomes 3D flight: position (x, y, z in cm), heading, speed with inertia; state JSON v2 adds `z`, `pitch`, `bank`, `speed`,
  `wing_hz`, per-role `pressed`, and **`room`** (the seal code for Anshul's lobby). Keep the 50 Hz loop and the stub brain. Spec:
  [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md#messages-json-v2).
- **B2:** role input → drives: each button maps to one brain input group (names from Neil at 17:15); buttons are simple holds (no arena
  sensing needed for the pilots). Chapter loader (course JSON: rings, jewels, walls/boxes, obstacles, checkpoints).
- **B3:** human obstacles with timings and **audio-tell events for the Spymaster's phone** (door, gust, the hand, spray can, forks); collisions
  (floor, walls, boxes as simple boxes); checkpoints and setbacks; chapter state machine; mini-task triggers and success checks; recorder.
- **B4:** tune Chapters 1 to 4 + finale; keyboard/gamepad mode (W/S, A/D, R/F, Space, E, Q); host commands.

## Ved (phones, relay, agents)

- **B1:** relay unchanged.
- **B2:** controller layouts: **pilots** = two big hold buttons (FORWARD/BACK, LEFT/RIGHT, UP/DOWN) + one special button;
  **Spymaster** = DUCK + SERENADE + the private radar. Send button state on change + 1 s heartbeat.
- **B3:** Spymaster radar (heart compass: direction and distance to the Princess; danger arrows) and **directional audio tells** (stereo pan)
  that arrive before the danger shows on the main screen; role merging (Pilot = forward/back + up/down; Navigator = left/right + Spymaster);
  reconnect; LAN fallback; accessibility (hold-to-toggle, spoken compass).
- **B4:** Matchmaker generates **chapter variants** (course layouts + obstacle timings); Master of Trials certifies them with bots flying the
  True Prince vs the Changeling; Jester script; Level Lab log.

## Anshul (Godot host, art, audio)

- Keep: WebSocket state client, lobby, HUD, screens.
- **B1/B2:** the play view becomes a **low-poly 3D stage** (BOMBANANA! / Fall Guys style): everything built from Godot primitive meshes
  (boxes, spheres, cylinders, prisms, tori) with flat bright colors and no textures; the Prince = 3 squashed spheres + 2 translucent prism wings
  + a gold cone crown; `SpringArm3D` chase camera behind the Prince (smoothed, banks in turns); a **blob shadow** under him. **Interpolate**
  between 30 Hz states so it renders at 60 fps. Spec: [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md#rendering-godot-host-anshul).
- **B3:** chapter environments from the course JSON (Pantry, Great Hall, Kitchen, Banquet, Fruit Bowl); crests light up instantly on press;
  Royal Nervous System strip; Chronicle screen; captions.
- **B4:** ElevenLabs lines, sound effects and music (new lines for chapters and mini tasks); Level Lab, Decree and wedding screens;
  Changeling badge; **performance pass: steady 60 fps**.

## Shared

- The Perfumer and Taster are gone; their facts become Royal Facts cards ("why smell and taste don't move him in a wiring-only model").
- Numbers, controls, obstacles and the chapter course format: [GAME_FLOW.md](GAME_FLOW.md) (v2, done).
- Message formats v2 (phone buttons, Spymaster radar/tells, state with `room`): [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md#messages-json-v2).
