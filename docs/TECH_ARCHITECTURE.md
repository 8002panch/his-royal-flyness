# Technical architecture

How His Royal Flyness works under the hood. Numbers marked *measured* come from [DATA_CHECK.md](DATA_CHECK.md). Everything else
is a starting value to tune.

## System overview

```
[phones: plain web page, one per role]
        |  WSS (JSON)
        v
[relay: small Python WebSocket server on a DigitalOcean Droplet, behind Caddy, at https://royalflyness.club]
   - serves the phone page (static HTML/JS)
   - rooms keyed by 4-letter seal codes; one "host" socket per room
        ^  the laptop connects OUT as the host (works on venue Wi-Fi that blocks device-to-device traffic)
        |
[game server: Python on the demo laptop]
   - tick loop, 50 Hz: phone buttons -> brain -> 3D flight body; scripted Princess, rivals, human obstacles; course
   - brain: whole MaleCNS rate model; TRUE PRINCE or CHANGELING matrix, hot-swappable
   - recorder: every sense's input stream + every output reading, per trial
   - Chronicler: 4 shadow brains in separate processes (one sense switched off each)
   - Level Lab (between rounds / overnight): Matchmaker + Master of Trials (Gemini), run_trials worker pool
   - voice: pre-generated ElevenLabs audio; live Chronicle lines (Gemini text -> ElevenLabs speech)
        |  local WebSocket, 30 Hz state + events
        v
[Godot 4 host: the main screen. Low-poly 3D stage + chase camera, interpolated to 60 fps; lobby with seal code + QR; HUD; screens; audio]
```

**Why Python owns the game state:** the Master of Trials and the Chronicler must replay trials headless, many times, without Godot.
Godot is a pure renderer and UI. It sends only host commands back (start, next, toggle Changeling, reassign role).

**Owners:** Neil = brain, `run_trials`, bots, Chronicler math. Arnav = game server. Ved = relay, phone page, cloud, Matchmaker + Master of Trials + Jester script. Anshul = Godot host, art, ElevenLabs audio ([BUILD_PLAN.md](BUILD_PLAN.md)).

## Submission repo layout (created at kickoff)

```
his-royal-flyness/
  README.md                  what it is, how to run, the Royal Decree, credits (MaleCNS citation, CC-BY)
  docs/                      copied from the planning repo
  brain/                     build_graph.py  io_sets.py  sim.py  changeling.py  probes.py  io_sets.json
  server/                    main.py (tick loop)  arena.py  body.py  script_actors.py  relay_client.py  godot_link.py
                             recorder.py  chronicler.py  voice.py
  agents/                    schema.py (Trial model)  matchmaker.py  master_of_trials.py  bots.py  run_trials.py
  relay/                     relay.py  Caddyfile  public/ (index.html, app.js, roles/*.js, crests/*.svg)
  host/                      Godot 4 project (scenes, sprites, fonts, audio/)
  audio/                     lines.csv  sfx.csv  music.csv  gen_audio.py  (generated mp3s are git-ignored or small)
  levels/                    certified/*.json  rejected/*.json  (with the Master of Trials' notes)
  data/                      git-ignored: MaleCNS Feather files, built graph .npz files
  run.sh                     starts the server and the Godot host
  .env.example               GEMINI_API_KEY=, ELEVENLABS_API_KEY=, RELAY_URL=, ROOM_SECRET=
```

## The brain

### Building the graph (`brain/build_graph.py`)

Inputs: the three MaleCNS v1.0 Feather files (see [KICKOFF_CHECKLIST.md](KICKOFF_CHECKLIST.md#2-environment-each-person-15-minutes)).

1. **Neurons:** bodies with a `superclass` annotation that doesn't contain "tbc" (the Berg et al. rule). *Measured: 166,606 neurons.*
2. **Signs** from `consensus_nt` (neurotransmitter file):
   - acetylcholine: excitatory (+1)
   - GABA, glutamate, histamine: inhibitory (-1)
   - dopamine, octopamine, serotonin (541 neurons): **silenced** (outputs set to 0), since a wiring diagram can't say what modulators do
   - "unclear" (2,966) and missing (166): excitatory by default, flagged in the Decree
3. **Edges:** read `connectome-weights` in chunks (the full table is 152M rows, about 3.6 GB in memory if loaded at once). Keep
   edges between kept neurons with **5 or more synapses**. *Measured: 6.24M edges carrying 72.4% of all synapses.*
4. **Weights:** start with **input-fraction** weights, `W[i,j] = sign[j] * count[i,j] / total_input_synapses[i]` (row i = receiving neuron).
   This keeps every neuron comparably excitable. Alternative if the dynamics look wrong: raw counts times one gain.
   The Decree wording covers both ("strength derived from synapse counts under one tuned gain").
5. Save `data/graph_true.npz` (CSR, float32, rows = receiving neuron) and `data/neurons.parquet` (index, bodyId, type, sides, sign).

### The rate model (`brain/model.py`)

```
r  <- r + (dt / tau) * ( -r + clip( g * W @ r + I_button + I_noise - theta, 0, 1 ) )
```

| Parameter | Value | Notes |
|---|---|---|
| Weights | **input fractions**: `W[i,j] = sign[j] * count[i,j] / in_total[i]` | Chosen over raw counts after the probes (raw counts kept as `Params(weights="counts")`) |
| dt / tau | 10 ms / 20 ms | two steps per 20 ms game tick |
| g (gain) | **4.0** | rest: ~5-7% of neurons active, <1% saturated; Changelings are silent at rest |
| theta | 0.0 | |
| I_noise | sd 0.05 on the button neurons | spontaneous activity, so outputs have a baseline |
| Baseline | 2 s settle + 3 s measured at load, cached per brain | `reset()` returns to the settled state instantly |

*Measured on Neil's M2:* one tick (2 steps) = **11.2 ms**; loading a brain + baseline = about 3 s; graph build 30 s.
Speed fallback: the 2-hop core (37,004 neurons) if the demo laptop can't hold 50 Hz.

### Inputs (v2): one neuron group per phone button (`brain/io_sets.json`)

Each button stimulates a named group of real sensory neurons, chosen from a scan of all 330 sensory types against all 480 descending-neuron
types (True Prince vs Changeling). `Brain.step(drives)` takes one drive (0 to 1) per group.

| Group | Button | Neurons | Count | Target (True Prince z at 0.6 / 1.0) |
|---|---|---|---|---|
| `forward` | Coachman FORWARD | LC9 + LC31a | 251 | DNp09 18 / 34 |
| `back` | Coachman BACK | SNta02,SNta09 + LC16 + LoVP26 | 435 | MDN 2.2 / 4.2 (weakest; press sends 1.0) |
| `left`, `right` | Helmsman | LLPC1, left / right | 143 / 142 | DNa02 L 6.4 / R 8.0 at 0.6 |
| `up` | Falconer UP | LPLC1 + LLPC2 | 384 | DNg02 3.0 / 5.2 (press sends 0.8) |
| `down` | Falconer DOWN | LPLC4 | 97 | DNp07 + DNp10 25 / 44 |
| `duck` | Spymaster DUCK | LC4 + LPLC2 | 311 | DNp01 95 / 99 |
| `serenade` | Spymaster SERENADE | LC10a + LC10d, both eyes | 489 | pIP10 6.5 / 8.9 |
| `lock_L`, `lock_R` | Helmsman Lock on | LC10a + LC10d, one eye | 243 / 246 | DNa02 same side 8.7 / 18 |

Left/right pairs are side-balanced (both deliver the same total drive). Full grids: `team/neil/probes_v2_level06.csv` and `..._level10.csv`.

### Outputs (v2): from neurons to flight (`server/body.py`)

`Brain.step` returns a z-score per output (0 = resting). Mapping rules and starting numbers are in [GAME_FLOW.md](GAME_FLOW.md#body-out-serverbodypy-brain-z-scores--flight).

| Output | Neurons | Moves |
|---|---|---|
| `DNp09` | DNp09 (2) | forward speed |
| `DNg100` | DNg100 (2) | chart only (small) |
| `MDN` | MDN (4) | back up / brake |
| `DNa02_L`, `DNa02_R` | DNa02 | turning (right minus left) |
| `DNg02` | the DNg02 population (29) | climb (wing power) |
| `DNp07_10` | DNp07 + DNp10 (4) | descend (landing neurons) |
| `DNp01` | the Giant Fiber (2) | escape dart |
| `pIP10` | pIP10 (2, male-only) | serenade |
| `pC1` | male-specific pC1 cluster (148) | chart only |

### The body and course (`server/body.py`, `server/course.py`, `server/obstacles.py`)

- 3D flight in centimeters: position (x, y, z = altitude), heading, speed with inertia and drag, gravity glide; the camera needs `pitch`/`bank` too.
- Courses are JSON ([GAME_FLOW.md](GAME_FLOW.md#7-the-chapters-course-json-owned-by-arnav-variants-by-veds-matchmaker)): boxes, rings, jewels, obstacles, a mini task, checkpoint, goal.
- Collisions: the Prince is a sphere (r = 2 cm) against axis-aligned boxes and the floor. Obstacles (hand, spray cloud, door, fork, gust, rival) are
  scripted with timings or ring triggers, and each sends a **tell** to the Spymaster's phone `tell_s` before it appears.

### The Changeling (`brain/changeling.py`)

For each sign group (excitatory senders, inhibitory senders), randomly permute the **sender** column of the edge list while
keeping each edge's (receiver, synapse count) fixed. Then:

- Every neuron keeps **exactly** the same total input and the same excitatory/inhibitory mix, so input-fraction weights are identical row by row.
- Every neuron keeps the same number of outgoing connections.
- Duplicate edges created by the shuffle are merged; self-connections are dropped (report how many).
- Make 3 seeds: `data/graph_changeling_{0,1,2}.npz`. The live toggle swaps the matrix between ticks and resets `r` to the resting state.
- **Sanity checks** (print them): resting activity distribution of the True Prince vs each Changeling (they should look alike); per-row input sums identical.

Why not a plain global shuffle: in the earlier Fly-by-Wire spike, shuffling synapse counts across the whole graph made activity
explode. That makes the random brain look broken for a boring reason, and judges would call it rigged.

### Probes (`brain/probes.py`): the 20:00 gate (v2)

`python -m brain.probes --level 0.6` holds each button for 0.8 s on the True Prince and 3 Changelings and prints the **controls matrix**
(button x output) plus pass/fail: target z > 3 and at least 2x the largest Changeling value. Result at 16:55 Sat, level 0.6: 8 of 10 pass
(forward 18, left 6.4, right 8.0, down 25, duck 95, serenade 6.5, lock 8.7/8.8); `back` (2.2) and `up` (3.0) are weaker, so their presses send
a stronger drive. The same matrix is the demo's **M** screen.

## Networking

### Relay (`relay/relay.py`)

- Python `websockets` server behind Caddy. The Caddyfile is just the domain plus a reverse proxy to the local port; Caddy gets HTTPS certificates automatically.
- Serves `public/` (the phone page) and a WebSocket at `/ws`.
- **Rooms:** a 4-letter code from consonants only (e.g. `BZKT`). A room has one host socket (the game server) and up to 8 phones.
- **Host auth:** the host joins with `ROOM_SECRET` from `.env`, so random visitors can't claim to be the host.
- **Reconnect:** each phone generates a `clientId` once and stores it in `localStorage` (wrapped in try/catch); rejoining with the same clientId restores the role.
- Heartbeat every 1 s; a phone missing for 3 s counts as dropped (the game pauses up to 5 s).
- **Fallback (LAN mode):** the same relay runs on the laptop (`python relay/relay.py --lan`) and phones join via a phone hotspot at `http://<laptop-ip>:8080`.
- **Last fallback:** keyboard mode (no phones).

### Messages (JSON, v2)

Phone to host (through the relay):
```json
{"t":"join","room":"BZKT","name":"Ava","clientId":"c-7f3a"}
{"t":"pick","role":"coachman"}                  // coachman | helmsman | falconer | spymaster | auto
{"t":"btn","role":"coachman","b":"forward","down":1,"seq":42}   // every press/release; plus a 1 s heartbeat of held buttons
{"t":"btn","role":"helmsman","b":"special","down":1,"seq":43}   // specials: charge | lock | launch (server picks lock side)
{"t":"btn","role":"spymaster","b":"duck","down":1,"seq":44}
{"t":"btn","role":"spymaster","b":"serenade","down":1,"seq":45}
```

Host to phone(s):
```json
{"t":"assigned","roles":["coachman"],"name":"Ava"}
{"t":"phase","phase":"lobby|role|intro|fly|clear|chronicle|finale|wedding|decree","chapter":3}
{"t":"special","role":"coachman","ready":true,"cooldown_s":0}
{"t":"radar","princess":{"bearing_deg":-35,"dist_cm":420,"dz_cm":60},"threats":[{"kind":"giant_hand","bearing_deg":80,"eta_s":1.2}]}  // Spymaster only, 10 Hz
{"t":"tell","kind":"giant_hand","pan":0.7,"eta_s":1.5}                              // Spymaster only: play the sound now
{"t":"fx","kind":"splat|dart|ring|jewel|win|hint","text":"Spymaster! Something's coming from the right!"}
{"t":"honors","share":{"thrust":0.41,"turn":0.0,"altitude":0.0,"escape":0.0,"song":0.0},"events":["Charged into a fork"],"line":"..."}
```

Server to Godot (local WebSocket, 30 Hz):
```json
{"t":"state","time":41.3,"brain":"true","phase":"fly","chapter":3,"room":"BZKT",
 "prince":{"x":312.0,"y":-40.5,"z":118.2,"heading":87.0,"pitch":4.0,"bank":-8.0,"speed":64.0,"wing_hz":1.8,"darting":false,"singing":false},
 "princess":{"x":900,"y":0,"z":95}, "rivals":[{"name":"Sir Cheapdate","x":700,"y":20,"z":90,"heading":180}],
 "obstacles":[{"id":"hand2","kind":"giant_hand","x":330,"y":-30,"z":0,"phase":"shadow","size":0.6}],
 "pressed":{"coachman":["forward"],"helmsman":["left"],"falconer":[],"spymaster":[]},
 "inputs":{"forward":0.6,"left":0.6},
 "outputs":{"DNp09":17.8,"MDN":0.1,"DNa02_L":6.1,"DNa02_R":0.0,"DNg02":0.0,"DNp07_10":0.2,"DNp01":0.4,"pIP10":0.0,"pC1":0.1},
 "meters":{"song":0.0,"rival":0.2,"candle":0.54,"jewels":7},
 "players":[{"name":"Ava","roles":["coachman"],"connected":true}]}
{"t":"course","course":{...}}        // once per chapter: the course JSON so Godot builds the stage
{"t":"event","kind":"voice","id":"H_CH_3","caption":"Chapter the Third: the Kitchen."}
{"t":"event","kind":"voice_live","mp3_b64":"...","caption":"..."}
```
`room` is on every state message, so the lobby can show the wax-seal code (flagged by Anshul).

Godot to server: `{"t":"cmd","cmd":"start|next|toggle_brain|restart|matrix|lab|decree|keyboard|chapter","arg":...}`.

## The Chronicler

After each chapter (and while it runs, in 4 shadow processes):
1. The recorder saved each player's button drives per tick and the full-brain outputs.
2. For each player, replay the brain **open loop** with that player's drives set to 0.
3. Credit = how much thrust, turning, altitude outputs, escapes (DNp01 darts) and song time change without them; shares normalized across players.
4. Output JSON per [GAME_FLOW.md](GAME_FLOW.md#8-the-chronicle-per-player).

Honest caveat: open loop (we replay the same inputs with a player's buttons removed; the flight path isn't re-simulated).

## Agents

No agent ever runs inside the live tick loop. Certified trials are cached on disk, so the game still works offline.

### Course schema (`agents/schema.py`, Pydantic; the Matchmaker's output format)

The chapter course format is in [GAME_FLOW.md](GAME_FLOW.md#7-the-chapters-course-json-owned-by-arnav-variants-by-veds-matchmaker)
(boxes, rings, jewels, obstacles with tells, mini task, checkpoint, goal). Arnav owns the schema; the hand-made chapters live in `levels/`.

### The Matchmaker (designs chapter variants)

- **Model:** Gemini (decision O1), structured output with the Course schema.
- **Input:** the chapter style (Pantry, Great Hall, Kitchen, Banquet, Fruit Bowl), the Chronicler's note on which role was idle last time
  ("give the Falconer more height changes"), recent rejections with reasons, and the lore rules.
- **Output:** one Course. Code checks geometry (rings reachable, no box inside a ring, obstacle tells ≥ 0.8 s) before testing.

### The Master of Trials (tests and certifies)

- **Model:** Gemini with function calling (Claude: strict tool use).
- **Tools:**
  - `run_trials(trial_json, brain: "true" | "changeling", n: int)` returns the win rate plus one failure reason per failed run,
    e.g. `"SPLAT at 31.2 s: left eye open, DNp01 never crossed"`, `"timeout: turned toward the Feast at 12 s"`.
  - `get_trace(run_id)` returns a compact timeline of output events (jumps, song on/off, big turns) and sense states.
- **Certification rule (code, not the LLM):** the True Prince's bot win rate is **30 to 80%**, and at least **25 points** higher than
  the Changeling's, over 10 seeded runs each. No crashes.
- **Loop:** if not certified, the Master of Trials writes a specific revision note to the Matchmaker (e.g. "the swing at 31 s lands while
  he's tapping; move it to 45 s or add a 1 s warning whoosh"). At most 3 revisions, then the trial is rejected and saved with its notes.
- **Visible:** every step goes to `levels/*.json` and to the Level Lab screen.

### Bots (`agents/bots.py`): scripted crews for testing

The bots see what the phones show plus the course route:
- Coachman bot: FORWARD while the next ring is ahead within 45°; BACK when a box is within 30 cm ahead; Charge on the rival task.
- Helmsman bot: LEFT/RIGHT toward the next ring's bearing (dead zone 8°); Lock on when the Princess is visible.
- Falconer bot: UP/DOWN toward the next ring's height (dead zone 10 cm); Launch on its mini task.
- Spymaster bot: DUCK when a hand's eta < 0.5 s; SERENADE when within 8 cm of the Princess and facing her.

The Master of Trials certifies a course if the bot crew finishes within the time limit in **60 to 90%** of seeded runs on the True Prince and at
least **40 points less often** on the Changeling (its controls are scrambled, so the bots mostly fail).

### `run_trials` worker pool (`agents/run_trials.py`)

- Headless: arena + body + brain + bots, no Godot, no network. Multiprocessing, one brain per process.
- *Estimated cost:* a 90 s trial is 9,000 steps x 5.3 ms, about 48 s per run per core. Certifying one trial (10 True Prince runs + 10 Changeling runs)
  takes about 3 minutes on 6 processes. Batch-certify about 15 trials overnight on the laptop, or on a CPU-optimized DigitalOcean Droplet
  (measure its per-step time first; a Droplet core may be slower than the M2's).

### Voice (`server/voice.py`, `audio/gen_audio.py`)

- **Batch (build time):** `gen_audio.py` reads `lines.csv`, `sfx.csv`, `music.csv` ([LORE.md](LORE.md#voice-line-bank)) and writes mp3s.
  Lines use the expressive ElevenLabs v3 model with audio tags; sound effects use the sound effects API; music uses the music API.
- **Live (Chronicle):** the Chronicler JSON goes to Gemini with a strict prompt ("only use these numbers and events; 2 or 3 lines in the
  Jester's voice; under 25 words each"), then to ElevenLabs text-to-speech on the low-latency Flash model. The mp3 bytes go to Godot
  (Godot 4 can load MP3 data at runtime) along with the caption text.
- **Fallback:** if the live line isn't back within about 4 s, play a pre-generated generic Jester line.
- Voice IDs and model names live in `.env` / config, not in code.

## Rendering (Godot host, Anshul)

- **Low-poly 3D, built from primitives:** `MeshInstance3D` with `BoxMesh`, `SphereMesh`, `CylinderMesh`, `PrismMesh`, `CapsuleMesh`, flat colors
  (`StandardMaterial3D`, no textures; flat shading), one `DirectionalLight3D` with shadows off, an `Environment` with a flat sky color.
  The Prince = 3 squashed spheres + 2 translucent prism wings (flap speed from `wing_hz`) + red sphere eyes + a gold cone crown.
- **Stage from the course JSON:** boxes → `BoxMesh`; rings → `TorusMesh`; jewels → small rotating `PrismMesh`; obstacles as simple shapes
  (a giant hand = boxes for palm and fingers; spray cloud = `GPUParticles3D` with ~200 particles; door = a thin box on a hinge).
- **Chase camera:** a `SpringArm3D` behind and above the Prince; smooth position with an exponential lerp (~8 per second) and rotation
  (~6 per second); bank up to 12°; FOV 70.
- **Interpolation:** keep the last two `state` snapshots; render at `now - 100 ms` and lerp positions/angles between them (60 fps from 30 Hz).
- **Blob shadow:** a dark transparent disc projected straight down onto the ground or box top under the Prince.
- **HUD:** a `CanvasLayer` with the crests (light up on `pressed`), candle timer, jewel count, and the Royal Nervous System strip (bars for
  the active inputs and the outputs).
- **Budget:** 60 fps on the demo laptop with the server running; profile with Godot's monitor overlay at the 23:30 integration.

## Performance and memory budget (Neil's M2, 8 GB)

## Environment

- Python 3.11+: numpy, scipy, pandas, pyarrow, websockets, pydantic, qrcode, google-genai, elevenlabs, python-dotenv.
- Godot 4 (latest stable). Fonts: UnifrakturMaguntia, IM Fell English (Google Fonts, OFL).
- DigitalOcean: smallest Droplet for the relay; Caddy; the domain's A record points at the Droplet's IP.
- Secrets in `.env` only (git-ignored): `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`, `ROOM_SECRET`, voice IDs.
