# Game design v2: three pilots and a Spymaster

*His Royal Flyness: A Courtship by Committee.* Version 2, Sat 26 Sept 16:15. Replaces v1 (four senses), which is kept in git history
and in `docs/council/`. Why it changed: the team wanted simpler controls, a third-person view and a low-poly look, and the brain data showed that the
nose and feet barely reach any movement neuron while the eyes' channels are strong. **All 10 button channels pass the gate** (each drives
its own movement neuron, only in the True Prince): [DATA_CHECK.md](DATA_CHECK.md#v2-button-channels-the-controls-matrix).

## In one breath

Prince Hamlet must fly from the Pantry to the Royal Fruit Bowl to win Princess Miranda, past the Giants who rule the kitchen.
**Three friends pilot him** (one forward/back, one left/right, one up/down), **one friend is his Spymaster** (listens for Giants and
senses the Princess). Every button press stimulates a real group of his sensory neurons, and his real, fully mapped nervous system
turns it into movement. Swap in the Changeling and the same buttons do nonsense.

| | |
|---|---|
| Genre | Party co-op flight game, 1 to 4 players, Jackbox-style (phones as controllers, one shared screen) |
| Player verb | **Steer** (the pilots) / **warn** (the Spymaster) |
| 30-second read | "Three of you fly the fly, one of you listens. His real brain is the steering wheel." |
| Camera | Third person, behind and above the Prince (like Fortnite); low-poly, flat-shaded indie look |
| A session | One journey: 4 chapters plus the finale, about 6 to 8 minutes |

## The crew (one role per phone)

| Role | Phone buttons | Each button stimulates (real MaleCNS neurons) | Which drives (measured, True Prince vs Changeling) | Special (mini task) |
|---|---|---|---|---|
| **Royal Coachman** (front/back) | FORWARD, BACK, special | Forward: LC9 + LC31a. Back: touch bristles SNta02/09 + LC16 + LoVP26 | Forward: DNp09 thrust, z 37 vs ≤1.4. Back: MDN (the "moonwalker" neurons), z 3.9 vs ≤1.8 | **Charge!**: forward at full drive for 1.5 s (a speed burst) |
| **Royal Helmsman** (side to side) | LEFT, RIGHT, special | LLPC1 on that side (wide-field motion) | DNa02 on that side (turn), z 9.4 / 12.0 vs ≤1.6 | **Lock on**: the Princess-detector (LC10a + LC10d) in the eye on her side, which turns him toward her (z 18 vs ≤2) |
| **Royal Falconer** (up/down) | UP, DOWN, special | Up: LPLC1 + LLPC2. Down: LPLC4 | Up: DNg02 wing power, z 5.0 vs ≤0.3. Down: the landing neurons DNp07 + DNp10, z 43 vs ≤4 | **Launch**: up at full drive for 1.5 s (a climb burst) |
| **Royal Spymaster** (ears + senses) | DUCK, SERENADE; private radar | Duck: looming detectors LC4 + LPLC2 (the Giant Fiber's inputs). Serenade: LC10a + LC10d in both eyes | Duck: DNp01 escape dart, z 99 vs ≤2.1. Serenade: pIP10 song, z 8.7 vs ≤1.3 | The Spymaster alone hears the Giants (their phone plays directional whooshes, footsteps, spray hisses) and sees the heart compass pointing to the Princess |

**Why this plays well:** nobody can fly him alone. Forward without a Helmsman flies into walls; the Falconer has to keep him at the height of
the next doorway; only the Spymaster knows a Giant is coming and where the Princess is, so they shout ("UP! LEFT! DUCK!"). It's a
Spaceteam / Lovers in a Dangerous Spacetime crew with one fly as the ship.

### How a button becomes movement

Pressing FORWARD doesn't move the fly. It stimulates the named neurons in the table (like optogenetics in a real lab); the signal runs
through all 166,606 neurons of his wiring, and the movement comes from what his descending neurons do. That's why:
- the response has a short, organic lag and a little wobble (it's a nervous system, not a joystick),
- **the Changeling breaks the controls**: same neurons, same number of connections, scrambled partners, so FORWARD might spin him and
  DUCK does nothing. That's the ablation test, and it's the best moment in the demo.

## Camera and look: third person, low-poly, built for fluidity

- **Chase camera** behind and a little above the Prince, like Fortnite, on a spring arm (it lags and eases, tilts slightly into turns).
- **Low-poly indie look** (think BOMBANANA!, A Short Hike, Fall Guys): chunky, flat-shaded polygon shapes in bright saturated colors,
  no textures needed. Everything is built from Godot's primitive meshes (boxes, spheres, cylinders, prisms, cones), so there's **no
  modeling tool and no downloaded art**: the Prince is three squashed spheres (head, thorax, abdomen), two flat translucent prisms for
  wings, big red eyes and a tiny gold cone crown.
- **Cheap to render:** flat colors, one directional light, no real-time shadows except **a blob shadow under the Prince** (a soft dark
  disc on the ground so players can judge height when flying up and down), no post-processing, a few hundred primitives per chapter.
- **Fluidity budget:** the main screen renders at 60 fps; the server sends state at 30 Hz and Godot **interpolates** between states, so
  the camera and the Prince never snap. Target: steady 60 fps on the demo laptop while the brain uses one CPU core.
- **Instant feedback:** each crest on screen lights up the moment its player presses (before the fly responds), and phones animate the
  button instantly, so controls feel responsive even with the nervous system's short lag. Wings flap faster with more thrust.

## The journey (progression)

One run through the palace, four chapters and a finale (about 60 to 90 s each). Each chapter has a route (rings or arches to fly
through), royal jewels to collect (sugar crystals), human obstacles, and one **mini task** for one role's special button.

| Chapter | Place | Human obstacles (the Spymaster hears them first) | Mini task | Teaches |
|---|---|---|---|---|
| 1. **The Pantry** | Shelves and jars | A Giant opening the cupboard (door swings) | **Falconer: Launch** off the jar lid when the door opens | Flying together; up/down |
| 2. **The Great Hall** | Candles, banners, the long table | A Giant's breath (a gust that pushes him sideways) | **Helmsman: Lock on** to a glimpse of the Princess through the arch | Turning; the heart compass |
| 3. **The Kitchen** | Stove, sink, fruit | **The Giant's hand** (the swatter), a spray can (a hissing cloud to avoid) | **Spymaster: Duck!** when the hand comes down | Listening; the Giant Fiber |
| 4. **The Banquet** | The feast table | Giants' forks and a rival suitor racing him | **Coachman: Charge!** to beat Sir Cheapdate to the fruit bowl | Speed; teamwork under pressure |
| Finale: **The Royal Fruit Bowl** | The Princess on a grape | One last Giant | **Spymaster: Serenade** while the pilots hold him facing her, close | The serenade (the win) |

Checkpoints at each chapter start: a SPLAT or a fall costs time, not the run. After the finale: the Royal Wedding and the Chronicle.

## Winning, losing, scoring

- **Win the run:** reach the Fruit Bowl and serenade her for 3 s in total (Serenade held while he's within 5 mm of her and facing her,
  and pIP10 is above its threshold, which is the brain's call).
- **Setbacks:** SPLAT (the hand lands on him), a fall to the floor, or crashing into a wall send him back to the chapter's checkpoint (+5 s).
- **Score:** finish time; royal jewels collected; mini tasks done on the first try; no SPLATs. Crowns 1 to 3 per chapter.
- A run always finishes (there's a time cap per chapter; if it runs out, the Herald skips ahead with a joke), so a party never gets stuck.

## The Chronicle (between chapters and at the end)

The Chronicler replays each chapter with one player's inputs removed and measures how much of the flight (thrust, turning, altitude,
escapes, song) disappears. Main screen: credit banners per crest, **Knight of the Realm** (the MVP), and the **blunder of the round**.
Phones show personal numbers. Clown the Jester roasts the crew (live voice when available).

## Joining (the Jackbox part)

Same as v1: the main screen shows a wax-seal room code, a QR code and the domain; phones join, sign a name, pick a crest (Coachman,
Helmsman, Falconer, Spymaster) or "Let the Herald decide"; reconnect by name; a dropped player pauses the game for up to 5 s.

| Players | Roles |
|---|---|
| 1 | Keyboard or gamepad: W/S forward/back, A/D left/right, R/F up/down, Space duck, E serenade, Q special |
| 2 | Pilot (forward/back + up/down) · Navigator (left/right + Spymaster) |
| 3 | Pilot (forward/back + up/down) · Helmsman · Spymaster |
| 4 | One each |

## Inspiration (award-winning and similar games) and what we take

| Game | What it's known for | What we take | How we're different |
|---|---|---|---|
| **Spaceteam** (IGF 2013 finalist) | Co-op shouting on phones; each panel has what others need | Phones as panels; information split across players | Our panels feed a real nervous system |
| **Lovers in a Dangerous Spacetime** | Each player mans a station of one ship | One vehicle, several stations | The "ship" is a fly and its stations are his senses |
| **Octodad** (IGF 2011 Student Showcase winner, original) | Clumsy control of one body is the comedy | Split control of one body | The clumsiness comes from real wiring, not a physics joke |
| **It Takes Two** (The Game Awards 2021 Game of the Year) | Co-op journey with a new mechanic per chapter | Chapters, each with its own mini task | Four players, one character |
| **Keep Talking and Nobody Explodes** | One player has information the others need | The Spymaster's private radar and audio | The information comes from the fly's own senses |
| **PEAK** (Steam 2025, Better With Friends) | Simple co-op chaos that's fun to watch | Short runs, funny failures, checkpoints | One shared body |
| **BOMBANANA!** (Lefto Studio, Sept 2026; Steam Next Fest's top party game) | 3-player co-op where each player has only part of the information; stylized, friendly look | The Spymaster's private information; a bright, chunky, readable style | We add a real brain between the players and the character |
| **Fall Guys / A Short Hike** | Chunky low-poly characters in bright colors | Flat-shaded primitive shapes, readable at a glance | One tiny royal fly in a giant kitchen |
| **Jackbox** | Join with a room code on your phone | The whole join flow | Phones are controllers, not answer pads |

## Art direction (low-poly royal kitchen)

- **World:** a giant castle kitchen seen from fly height. Chunky low-poly shelves, jars, candles, banners, a long feast table, a stove, fruit
  bowls, all flat-shaded in bright colors. Royal touches everywhere: crowns on the jars, pennant banners, a red carpet runner on the table.
- **Characters:** the Prince (gold crown, blue body), the Princess (tiara, pink body, sitting on a giant grape), rivals (tabard colors),
  the Giants (huge simplified low-poly hands, a fork, a spray can with a hissing cloud of particles).
- **Palette:** saturated and friendly: royal blue `#2F5BEA`, crimson `#E63946`, gold `#F4B41A`, grape purple `#7B2FBE`, mint `#3DDC97`,
  cream background `#FFF4E0`. Crests: Coachman = horse (gold), Helmsman = ship's wheel (blue), Falconer = falcon (mint),
  Spymaster = ear (purple). Each crest has a distinct shape, not just a color.
- **HUD:** the four crests along the bottom (light up while pressed), chapter title, a candle timer, jewel count, and a small **Royal Nervous
  System** strip showing which neuron groups are firing (button channels → output neurons).
- **Fonts (Google Fonts, OFL):** a chunky rounded font for HUD and phones (e.g. Fredoka or Baloo 2); a blackletter (UnifrakturMaguntia)
  only for chapter titles and the Royal Decree, for the royal flavor.

## Audio

ElevenLabs voices (Herald, Princess, Clown the Jester, rivals), sound effects (whooshes, footsteps, spray hiss, SPLAT, fanfares, wing
buzz) and music (court dance, tense kitchen theme, wedding theme). The Spymaster's phone plays the Giants' tells **before** they show on
screen, panned left/right by direction. Captions on every line.

## Accessibility

1. **Hold-to-toggle** for every hold button.
2. **The Spymaster role is fully playable by ear** (directional audio, spoken compass: "Her Highness, ahead and up").
3. Captions on all voice lines; crests use shapes and colors; big buttons (half the phone screen each).
4. Vibration only works in Android browsers, so every haptic also has a visual flash.

## What's real and what's ours (the Royal Decree)

| Part | Where it comes from |
|---|---|
| Turning his button presses into thrust, turning, climbing, escapes and song | The MaleCNS v1.0 wiring run as a rate model (counts real; strengths, signs and the model are our assumptions) |
| Which neurons each button stimulates | Real, named cell types chosen by us from the brain scan |
| How output neurons become flight (speeds, inertia) | Our code |
| The Princess, rivals, Giants, the course | Scripted |
| The names | Real fly genes; the personalities are ours |

## Not in v2 (from v1)

The Perfumer (nose) and the Taster (feet) are gone: in a wiring-only model, smell and taste barely reach his movement neurons
(they work through learning and neuromodulation, which a wiring diagram doesn't capture). They become Royal Facts cards instead.
