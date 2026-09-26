# Game flow v2: the whole game, start to finish

The build spec for one run of *His Royal Flyness* v2 (three pilots and a Spymaster, third-person, low-poly). It turns
[GAME_DESIGN.md](GAME_DESIGN.md) into exact states, durations, controls, numbers and course layouts. Every number is a **starting
value**: tune it, then update this file. Owners follow [team/README.md](../team/README.md).

## 1. One run at a glance

```
LOBBY ──start──> ROLE REVEAL ──> PRINCE INTRO (first run only)
   ^                                  │
   │                                  v
   │        ┌──> CHAPTER INTRO ──> FLY ──> CHAPTER CLEAR ──> CHRONICLE ──┐
   │        └───────────── next chapter (1 Pantry, 2 Great Hall, 3 Kitchen, 4 Banquet) <──┘
   │                                  │ after chapter 4
   │                                  v
   │                     FINALE: the Royal Fruit Bowl (serenade)
   │                                  v
   └──── ROYAL DECREE <── FINAL CHRONICLE <── WEDDING
```

About 6 to 8 minutes: 5 flying segments of 45 to 90 s, plus about 20 s of intro and Chronicle around each.

## 2. States

| State | Lasts | Main screen (Anshul) | Phones (Ved) | Server (Arnav) | Voice / sound (Anshul) |
|---|---|---|---|---|---|
| **LOBBY** | Until the host presses Start (1+ players) | Wax-seal room code, QR, domain, 4 crests (lit when taken), names; the Prince idling on a jar lid | Join → name → crest | Relay room open; roles assigned/merged | `H_TITLE`; `H_JOIN` every 30 s; lobby music |
| **ROLE REVEAL** | 8 s | Each crest pops with its player's name and a one-line job | Role card with the controls | Locks roles | `H_ROLE_*` |
| **PRINCE INTRO** | 10 s (first run only) | Camera swoops around the Prince; the Royal Nervous System strip appears | "Get ready" | Brain `reset()` | `H_PRINCE` |
| **CHAPTER INTRO** | 5 s | Chapter title + flavor line + one Royal Fact | Role card | Loads the course; resets actors, brain, recorder | `H_CH_n`; fanfare |
| **FLY** | Up to the chapter's time limit | Chase camera, low-poly stage, HUD (crests, candle, jewels, strip) | Live controls (+ radar and tells for the Spymaster) | 50 Hz loop: buttons → brain → body; obstacles; rings; checkpoints; mini task | Warnings, wing buzz, whooshes; chapter music |
| **CHAPTER CLEAR** | 3 s | Crowns earned (1 to 3), time, jewels | Gold flash | Freezes; hands the recording to the Chronicler | Fanfare + Herald quip |
| **CHRONICLE** | About 15 s (host can skip) | Credit banners per crest, Knight of the Realm, the blunder | Personal numbers | Chronicler JSON (Neil) → Jester script (Ved) | Jester lines |
| **FINALE** | Up to 60 s | The Fruit Bowl; the Princess on a grape; one last Giant | Same controls; SERENADE pulses on the Spymaster's phone | Serenade meter | Princess reactions |
| **WEDDING** | 15 s | Crowns, confetti, both flies bowing | "Long live the crew!" | Totals | `H_WEDDING`, wedding theme |
| **FINAL CHRONICLE** | 20 s | Crowns per chapter, overall credit, overall Knight | Personal totals | Sums the Chronicles | One Jester line |
| **ROYAL DECREE** | Until dismissed | Honesty panel + MaleCNS credit ([LORE.md](LORE.md#the-royal-decree-honesty-panel-text)) | "Play again?" | Keeps players and roles | `H_DECREE` |

A run always moves on: each chapter has a time limit, and if it runs out, the Herald skips ahead with a joke.

## 3. Host controls (laptop keyboard)

| Key | Does |
|---|---|
| Space | Start / next / skip a screen |
| **C** | Toggle TRUE PRINCE / CHANGELING (badge flips; `H_CHANGELING` / `H_TRUE_PRINCE`) |
| **R** | Restart the current chapter (use right after C for the demo) |
| **M** | **Controls matrix** screen: the button x movement grid for the True Prince next to the Changeling (from `team/neil/probes_v2_*.csv`) |
| L | Level Lab (Matchmaker / Master of Trials log) |
| D | Royal Decree |
| K | Keyboard/gamepad mode on/off |
| 1 to 5 | Jump to chapter 1 to 4 or the finale |
| Esc | Pause |

## 4. Controls: what each button does

Each button stimulates one named group of real neurons ([brain/brain.py](../brain/brain.py) `INPUT_GROUPS`) at a **drive** between 0 and 1.
Press drives: FORWARD 0.6, BACK 1.0, LEFT/RIGHT 0.7, UP 0.8, DOWN 0.7, DUCK 1.0, SERENADE 1.0, Lock on 1.0. Specials (Charge, Launch)
send **1.0 for 1.5 s** (5 s cooldown). BACK and UP always send 1.0 because they're the weakest channels (they pass the gate at 1.0).

| Role | Button | Brain input | Neurons stimulated | Target output (True Prince z at 1.0) |
|---|---|---|---|---|
| Coachman | FORWARD | `forward` 0.6 | LC9 + LC31a | DNp09 thrust (37) |
| | BACK | `back` 1.0 | SNta02/09 + LC16 + LoVP26 | MDN back up / brake (3.9) |
| | **Charge!** | `forward` 1.0 for 1.5 s | same | a thrust burst |
| Helmsman | LEFT / RIGHT | `left` / `right` 0.7 | LLPC1 on that side | DNa02 on that side: turn (9.4 / 12.0) |
| | **Lock on** | `lock_L` or `lock_R` 1.0 (the side the Princess is on) | LC10a + LC10d, one eye | turn toward her (18) |
| Falconer | UP / DOWN | `up` 0.8 / `down` 0.7 | LPLC1 + LLPC2 / LPLC4 | DNg02 wing power (5.0) / DNp07 + DNp10 landing (43) |
| | **Launch** | `up` 1.0 for 1.5 s | same | a climb burst |
| Spymaster | DUCK | `duck` 1.0 (tap) | LC4 + LPLC2 | DNp01 Giant Fiber escape (99) |
| | SERENADE | `serenade` 1.0 (hold) | LC10a + LC10d, both eyes | pIP10 song (8.7) |

Full grids (every button x every output, True Prince and 3 Changelings): `team/neil/probes_v2_level06.csv` and `team/neil/probes_v2_level10.csv`.

## 5. Flight numbers (put them all in `server/config.py`)

World units: **centimeters**. The kitchen is built big (a chapter course is 15 to 30 m long); the Prince is drawn about 3 cm long.

### Loop rates
| Thing | Value |
|---|---|
| Game tick (brain + body) | 50 Hz (brain 11.2 ms per tick, measured) |
| State to Godot | 30 Hz (Godot interpolates to 60 fps) |
| Private views to phones | 10 Hz (Spymaster radar and tells) |
| Phone input | On change + 1 s heartbeat |

### Body out (server/body.py): brain z-scores → flight
| Motion | Rule (start values; smooth every output over ~100 ms) |
|---|---|
| Forward speed | target `v = 120 * clamp((z(DNp09) - 2) / 25, 0, 1)` cm/s; accelerate at 150 cm/s², drag back to 0 at 80 cm/s² when released |
| Back / brake | if `z(MDN) > 1.5`: target speed `-30` cm/s (brakes first, then drifts back) |
| Turning | `yaw_rate = 90 * clamp((z(DNa02_R) - z(DNa02_L)) / 10, -1.5, 1.5)` deg/s; the camera banks up to 12 degrees |
| Climb | if `z(DNg02) > 1`: climb at `40 * clamp(z(DNg02) / 5, 0, 1.5)` cm/s |
| Descend | if `z(DNp07_10) > 5`: descend at `60 * clamp(z(DNp07_10) / 40, 0, 1)` cm/s |
| Gravity | with no climb, sink at 8 cm/s (a gentle glide) |
| Duck (escape dart) | if `z(DNp01) > 10`: dart 40 cm away from the nearest threat over 0.25 s; 0.4 s safe window; 1.5 s refractory |
| Serenade | if `z(pIP10) > 4`: wings out, buzz; the song meter fills while he's within 8 cm of her and facing her (±45°) |
| Wings | flap animation speed = 1 + z(DNp09)/20 + z(DNg02)/5 |

### Rules of the kitchen
| Rule | Value |
|---|---|
| Rings | Fly through a ring (inside its radius) = +1 jewel bonus and the route arrow advances |
| Jewels | Touch within 4 cm = collected |
| Collision | Floor, walls and boxes: bounce back 10 cm, lose all speed, 0.5 s stun |
| SPLAT | The Giant's hand lands within 12 cm of him and he didn't dart in the last 0.4 s: back to the checkpoint, +5 s |
| Spray cloud | Inside the cloud: speed halved and a cough; 3 s in the cloud = back to the checkpoint |
| Chapter time limit | 90 s (finale 60 s); on timeout the Herald skips ahead (0 crowns) |
| Crowns per chapter | Finish = 1; under the par time = +1; mini task done first try and no SPLAT = +1 |
| Win the run | Finale: 3.0 s of serenade (near + facing + pIP10 above threshold) |

## 6. Human obstacles (the Spymaster hears them first)

Each obstacle plays its **tell** on the Spymaster's phone `tell_s` seconds before it shows on the main screen, panned left/right by direction.

| Kind | What happens | Tell (Spymaster's phone) | Counter |
|---|---|---|---|
| `door_swing` | A cupboard door swings through the route | Creak | Falconer/Helmsman fly around; mini task in ch. 1 |
| `breath_gust` | A Giant exhales: a sideways push of 60 cm/s for 1.5 s | Deep inhale | Helmsman counter-steers |
| `giant_hand` | A shadow grows over him for 0.8 s, then the hand slams | Whoosh, rising pitch | Spymaster: DUCK in time |
| `spray_can` | A hissing cloud (particles) fills a volume for 4 s | Hiss | Fly around or over |
| `fork_stab` | A fork comes down on the table in a line | Clink-clink | Coachman: speed up or brake |
| `rival_racer` | Sir Cheapdate races to the bowl on a fixed path | His buzzing wings | Coachman: Charge! |

## 7. The chapters (course JSON, owned by Arnav; variants by Ved's Matchmaker)

Course format (`agents/schema.py`, v2):
```text
Course: id, chapter (1-5), title, flavor, herald_intro, time_limit_s, par_s,
        start {x, y, z, heading_deg}, checkpoint {x, y, z},
        boxes [{x, y, z, w, d, h, color}]            # shelves, jars, tables, walls (low-poly boxes)
        rings [{x, y, z, r}]                          # the route, in order
        jewels [{x, y, z}]
        obstacles [{kind, t_s | trigger_ring, x, y, z, params{}, tell_s}]
        mini_task {role, kind: launch|lock_on|duck|charge|serenade, trigger_ring, window_s}
        princess {x, y, z} | null                     # finale, and the ch. 2 glimpse
        goal {x, y, z, r}                             # chapter exit
```

Chapter 1 as a worked example (ground at z = 0; the Prince starts on a jar lid 40 cm up):
```json
{"id": "ch1_pantry", "chapter": 1, "title": "The Pantry", "flavor": "Every prince starts somewhere. Ours starts on a jam jar.",
 "herald_intro": "Chapter the First: the Pantry. Mind the doors.", "time_limit_s": 90, "par_s": 45,
 "start": {"x": 0, "y": 0, "z": 40, "heading_deg": 0}, "checkpoint": {"x": 0, "y": 0, "z": 40},
 "boxes": [{"x": 0, "y": 0, "z": 0, "w": 30, "d": 30, "h": 38, "color": "#E63946"},
           {"x": 250, "y": 60, "z": 0, "w": 400, "d": 40, "h": 80, "color": "#F4B41A"},
           {"x": 500, "y": -80, "z": 0, "w": 60, "d": 200, "h": 150, "color": "#2F5BEA"}],
 "rings": [{"x": 150, "y": 0, "z": 60, "r": 30}, {"x": 320, "y": -40, "z": 110, "r": 30}, {"x": 600, "y": 0, "z": 180, "r": 35}],
 "jewels": [{"x": 200, "y": 10, "z": 70}, {"x": 400, "y": -30, "z": 130}, {"x": 560, "y": 0, "z": 170}],
 "obstacles": [{"kind": "door_swing", "trigger_ring": 1, "x": 450, "y": 0, "z": 0, "params": {"width": 120, "height": 220, "swing_s": 2.0}, "tell_s": 1.5}],
 "mini_task": {"role": "falconer", "kind": "launch", "trigger_ring": 1, "window_s": 2.0},
 "princess": null, "goal": {"x": 700, "y": 0, "z": 190, "r": 50}}
```

| Chapter | Layout idea | Obstacles | Mini task |
|---|---|---|---|
| 2. The Great Hall | Long hall of candles (tall thin cylinders) and banners; an arch at the end shows the Princess for 3 s | `breath_gust` x2 | Helmsman **Lock on** while she's visible through the arch |
| 3. The Kitchen | Stove, sink, fruit; tighter turns | `giant_hand` x3 (one fake shadow), `spray_can` x1 | Spymaster **Duck!** on the second hand |
| 4. The Banquet | The feast table as a runway; plates and goblets as boxes | `fork_stab` x2, `rival_racer` | Coachman **Charge!** to beat Sir Cheapdate to the bowl |
| 5. Finale: the Royal Fruit Bowl | A big bowl of fruit; the Princess on a grape | one `giant_hand` | Spymaster **Serenade** 3 s while the pilots hold him close and facing her |

## 8. The Chronicle (per player)

Neil's Chronicler replays each chapter's recorded button drives with **one player's buttons removed** and compares with the real run:
thrust, turning, altitude change, escapes, song time. Share per player = their change / the sum over players. **Knight of the Realm** =
highest overall share. **Blunder of the round** = the single worst moment (e.g. flew into the door, missed DUCK, charged into a fork).
JSON: `{"chapter": id, "brain": "true"|"changeling", "players": {name: {"roles": [...], "share": {...}, "events": [...]}}, "knight": name, "blunder": {...}}`.

## 9. The demo path

Lobby with the judges' phones → chapter 1 (they learn to fly) → chapter 3 (the Giant's hand) → Chronicle → **C + R** (the Changeling:
same buttons, scrambled flight) → **M** (the controls matrix: a clean diagonal vs noise) → L (Level Lab) → D (Royal Decree).
Script: [DEMO_SCRIPT.md](DEMO_SCRIPT.md).
