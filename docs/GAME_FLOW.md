# Game flow: the whole game, start to finish

The build spec for one full session of *His Royal Flyness*. It turns [GAME_DESIGN.md](GAME_DESIGN.md) into exact states,
durations, screens, numbers and trial layouts. Every number here is a **starting value**: tune it, then update this file.
Owners follow [team/README.md](../team/README.md).

## 1. The session at a glance

```
LOBBY ──start──> ROLE REVEAL ──> PRINCE INTRO (first game only)
   ^                                  │
   │                                  v
   │          ┌──> TRIAL INTRO ──> PLAY ──> OUTCOME ──> CHRONICLE ──┐
   │          └──────────────────── next trial (I, II, III) <───────┘
   │                                  │ after Trial III
   │                                  v
   └──── ROYAL DECREE <── FINAL CHRONICLE <── WEDDING
```

One session is about 8 minutes: 3 trials of up to 90 s, plus about 25 s of intro, outcome and Chronicle around each.

## 2. States

| State | Lasts | Main screen (Anshul) | Phones (Ved) | Server does (Arnav) | Voice / sound (Anshul) |
|---|---|---|---|---|---|
| **LOBBY** | Until the host presses Start (needs at least 1 player) | Wax seal code, QR, domain, 4 crests (lit when taken), player names | Join → name → crest pick | Relay room open; assigns roles; merges roles for 2 or 3 players | `H_TITLE` on load; `H_JOIN` every 30 s; court_dance_loop |
| **ROLE REVEAL** | 8 s | Each crest grows in turn with the player's name | Role card: crest, one line, the controls | Locks roles; starts the brain (True Prince unless toggled) | `H_ROLE_*` for each taken role |
| **PRINCE INTRO** | 10 s (first game only) | Hamlet on parchment; the Royal Nervous System chart fades in | "Get ready" | Brain `reset()` | `H_PRINCE` |
| **TRIAL INTRO** | 6 s | Title card, flavor line, one Royal Fact card | Role card again | Loads the trial; resets actors, brain and recorder | `H_TRIAL_n`; fanfare_short |
| **PLAY** | Up to 90 s (the candle) | Hall, sprites, chart, crests lit while senses are open, captions | Live controls + private view | 50 Hz loop: senses → brain → body; actors; win/lose checks; recording | Hints (Trial I only), warnings, wing buzz, whooshes; the trial's music loop |
| **OUTCOME** | 4 s | Win: hearts + banner. SPLAT: ink blot. Rival: rival bows. Timeout: candle out | Flash (win gold / lose red) | Freezes; hands the recording to the Chronicler | `H_WIN` / `H_SPLAT` / `H_RIVAL_WINS` / `H_TIMEOUT` |
| **CHRONICLE** | About 20 s (host can skip with Next) | "The Chronicler consults the scrolls..." (3 to 5 s), then credit banners per crest, Knight of the Realm, the blunder | Personal honors | Chronicler JSON (Neil) → Jester script (Ved) | Jester lines (live, or pre-generated after about 4 s) |
| **WEDDING** | 15 s | Crowns, bells, both flies bowing | "Long live the council!" | Totals the stars | `H_WEDDING`, `P_WEDDING`, wedding_theme |
| **FINAL CHRONICLE** | 20 s | Stars per trial, overall credit per crest, overall Knight | Personal totals | Sums the three Chronicles | One Jester line |
| **ROYAL DECREE** | Until dismissed | The honesty panel ([LORE.md](LORE.md#the-royal-decree-honesty-panel-text)) + MaleCNS credit | "Play again?" | Keeps the players and roles | `H_DECREE` |

The game still moves on if a trial is lost; nobody gets stuck.

## 3. Host controls (keyboard on the laptop)

| Key | Does |
|---|---|
| Space | Start / next (skip a screen) |
| **C** | Toggle TRUE PRINCE / CHANGELING (badge flips, `H_CHANGELING` or `H_TRUE_PRINCE`) |
| **R** | Replay the current trial with the same actor timings (use after C for the demo) |
| L | Level Lab screen (the Matchmaker / Master of Trials log) |
| D | Royal Decree screen |
| K | Keyboard mode on/off (Q/W eyes, O/P antennae, Space tap, L listen) |
| 1 / 2 / 3 | Jump to Trial I / II / III |
| Esc | Pause |

## 4. The three hand-made trials

Coordinates in mm; the hall is 60 x 40 with (0, 0) at the bottom left. Headings in degrees: 0 = east (+x), 90 = north (+y).
**The Princess always carries her own scent** (kind `her`, sigma 6 mm), so `scents` only lists fixed sources.
Arnav turns these into `levels/certified/trial_*.json` using `agents/schema.py`.

### Trial I: the Garden Audience (tutorial)
```json
{"id": "trial_I_garden", "act": "I", "title": "The Garden Audience",
 "flavor": "Her Highness takes the evening air among the grapes.", "herald_intro": "The First Trial: the Garden Audience. Her Highness awaits.",
 "arena": {"w_mm": 60, "h_mm": 40, "theme": "garden"},
 "prince_start": {"x": 10, "y": 20, "heading_deg": 0},
 "princess": {"start": {"x": 34, "y": 26}, "speed_mm_s": 3.0, "patience_s": 60,
              "waypoints": [{"x": 34, "y": 26, "pause_s": 3}, {"x": 40, "y": 21, "pause_s": 3}, {"x": 34, "y": 15, "pause_s": 3}]},
 "scents": [], "rival": null, "giant": [], "time_limit_s": 90, "focus_roles": ["lookout", "taster"]}
```
Hints (Trial I only): Lookout left/right when she's more than 30 degrees off his heading for 3 s; `H_HINT_TAP` on first contact.

### Trial II: the Banquet
```json
{"id": "trial_II_banquet", "act": "II", "title": "The Banquet",
 "flavor": "The feast is fragrant. So, alas, is Sir Cheapdate.", "herald_intro": "The Second Trial: the Banquet. The feast is fragrant. So, alas, is Sir Cheapdate.",
 "arena": {"w_mm": 60, "h_mm": 40, "theme": "banquet"},
 "prince_start": {"x": 8, "y": 8, "heading_deg": 45},
 "princess": {"start": {"x": 30, "y": 14}, "speed_mm_s": 3.0, "patience_s": 50,
              "waypoints": [{"x": 25, "y": 12, "pause_s": 2}, {"x": 32, "y": 19, "pause_s": 2}, {"x": 27, "y": 25, "pause_s": 2}]},
 "scents": [{"kind": "feast", "x": 48, "y": 32, "strength": 1.0, "sigma_mm": 10}],
 "rival": {"name": "Sir Cheapdate", "start": {"x": 46, "y": 10}, "speed_mm_s": 3.5, "sings_at_s": 55, "cva_trail": true,
           "waypoints": [{"x": 36, "y": 12}, {"x": 30, "y": 20}, {"x": 24, "y": 16}]},
 "giant": [], "time_limit_s": 90, "focus_roles": ["perfumer"]}
```

### Trial III: the Giant's Shadow
```json
{"id": "trial_III_shadow", "act": "III", "title": "The Giant's Shadow",
 "flavor": "The Giants stir. The hall grows dark.", "herald_intro": "The Third Trial: the Giant's Shadow. Only the Giant Fiber is faster than the Giant's hand.",
 "arena": {"w_mm": 60, "h_mm": 40, "theme": "great_hall"},
 "prince_start": {"x": 10, "y": 30, "heading_deg": -30},
 "princess": {"start": {"x": 40, "y": 20}, "speed_mm_s": 4.0, "patience_s": 45,
              "waypoints": [{"x": 46, "y": 28, "pause_s": 2}, {"x": 38, "y": 12, "pause_s": 2}, {"x": 30, "y": 22, "pause_s": 2}]},
 "scents": [],
 "rival": {"name": "Sir Indy", "start": {"x": 52, "y": 34}, "speed_mm_s": 4.0, "sings_at_s": 65, "cva_trail": true,
           "waypoints": [{"x": 44, "y": 26}, {"x": 36, "y": 18}, {"x": 44, "y": 14}]},
 "giant": [{"t_s": 15, "target": "near", "from_deg": 90, "fake": true, "warning_whoosh_s": 0.6},
           {"t_s": 28, "target": "prince", "from_deg": 180, "fake": false, "warning_whoosh_s": 1.0},
           {"t_s": 45, "target": "near", "from_deg": 0, "fake": true, "warning_whoosh_s": 0.6},
           {"t_s": 58, "target": "prince", "from_deg": 270, "fake": false, "warning_whoosh_s": 1.0},
           {"t_s": 75, "target": "prince", "from_deg": 90, "fake": false, "warning_whoosh_s": 0.8}],
 "time_limit_s": 90, "focus_roles": ["lookout", "spymaster"]}
```

## 5. Numbers to start from (put them all in `server/config.py`)

### Loop rates
| Thing | Value |
|---|---|
| Game tick (brain + body) | 50 Hz (brain: two 10 ms steps per tick, 11.2 ms measured) |
| State to Godot | 30 Hz |
| Private views to phones | 10 Hz |
| Phone input | On change + 1 s heartbeat |

### Senses in (server/senses.py → `Brain.step` drives, all 0 to 1)
| Group | Rule |
|---|---|
| `LC10a_L/R` | For each small mover (Princess, rival) in that eye's field (each eye covers 170 degrees on its side, 10 degrees overlap ahead): angular size in degrees / 30, times 1.0 if moving or 0.5 if still; sum, cap at 1 |
| `LPLC2_L/R`, `LC4_L/R` | Growth rate of the biggest looming object on that side (degrees per second) / 200, cap at 1. The Giant's shadow grows from 5 to 120 degrees in 0.5 s |
| `ORN_VA1v_L/R`, `ORN_DM1_L/R`, `ORN_DA1_L/R` | Concentration of her scent / the Feast / rival cVA at each antenna, sampled 2 mm to each side of the head (exaggerated for play). `c = strength * exp(-d^2 / (2 sigma^2))`, cap at 1 |
| `ppk23_L/R` | Each Taster tap while his forelegs touch her: drive 1.0 for 100 ms on both sides |
| `JO_wind_L/R` | The Giant's wind: ramps 0 to 1 over the last 300 ms before a real impact (0.4 peak for a fake), stronger on the side it comes from |
| `JO_sound_L/R` | Rival song loudness: 1.0 within 10 mm, falling to 0 at 30 mm |

A role's drives are only sent while that sense is open (held). Closed senses send 0.

### Body out (server/body.py, from `Brain.step` z-scores)
| Output | Rule |
|---|---|
| Turning | `turn_deg_s = 120 * (z(DNa02_R) - z(DNa02_L)) / 5`, capped at +/- 240 deg/s (sign checked by probe C; flip if needed) |
| Walking | `speed = 15 * sigmoid(mean(z(DNp09), z(DNg100)) - 1.0)` mm/s |
| Backing up | if z(MDN) > 2.0: 5 mm/s backward |
| Jump | if z(DNp01) > 3.0: move 15 mm away from the loom source over 0.2 s; 1 s refractory |
| Serenade | if z(pIP10) > 2.0: wing out, buzz loop; song meter counts while within 5 mm and facing her within +/- 45 degrees |
| Courting meter | mean z of pC1 → the "Courting" bar (display only) |

These thresholds are placeholders until Neil's probes (by 20:00) give the real z ranges; Neil posts final values in `team/neil/README.md`.

### Rules of the hall
| Rule | Value |
|---|---|
| Contact (forelegs touching) | Centers within 3 mm and she's within +/- 60 degrees of his heading |
| Win | 5.0 s of serenade in total (near + facing) |
| Rival win | The rival's scripted song meter reaches 5.0 s first (it starts at `sings_at_s` and only fills while he's within 5 mm of her) |
| SPLAT | A real swing lands within 4 mm of him, unless he jumped in the last 0.3 s |
| Princess patience | If no serenade for `patience_s`, she walks to the far edge; if still none after 15 s more, timeout |
| Stars | Win = 1; win with more than 30 s left = +1; no jumps from fake swings = +1 |

## 6. The Chronicle (what gets credited)

For each trial, Neil's Chronicler replays the recorded drives with one role's senses set to 0 and compares with the real run:

| Category | Measure |
|---|---|
| Steering | Change in `z(DNa02_R) - z(DNa02_L)` over the trial |
| Walking | Change in the walking output |
| Escapes | Which jumps disappear without that role |
| Serenade | How much song time disappears without that role |

- **Share** per role = its total change / the sum over roles (per category and overall).
- **Knight of the Realm** = highest overall share.
- **Blunder of the round** = the single event that hurt most. For example: a jump from a fake swing with that role's sense open, a cVA sniff that dropped the Courting meter, or a missed swing (SPLAT) while the Lookout and Spymaster were both closed.
- Output JSON (Neil defines it by 21:00): `{"trial": id, "brain": "true"|"changeling", "roles": {role: {"share": {...}, "events": [...]}}, "knight": role, "blunder": {...}}`.

## 7. The demo path (what the judges see)

Lobby with judges' phones → Trial I (they learn it) → Trial III (the chaos) → Chronicle → **C + R** (the Changeling replays Trial III)
→ Level Lab (**L**) → Royal Decree (**D**). Script and timings: [DEMO_SCRIPT.md](DEMO_SCRIPT.md).
