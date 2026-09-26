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
   - tick loop, 50 Hz: arena + 2D body + scripted Princess / rivals / Giant
   - brain: whole MaleCNS rate model; TRUE PRINCE or CHANGELING matrix, hot-swappable
   - recorder: every sense's input stream + every output reading, per trial
   - Chronicler: 4 shadow brains in separate processes (one sense switched off each)
   - Level Lab (between rounds / overnight): Matchmaker + Master of Trials (Gemini), run_trials worker pool
   - voice: pre-generated ElevenLabs audio; live Chronicle lines (Gemini text -> ElevenLabs speech)
        |  local WebSocket, 30 Hz state + events
        v
[Godot 4 host: the main screen. Draws, plays audio, shows the seal code + QR, Royal Nervous System chart, Level Lab, Decree]
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

### The rate model (`brain/sim.py`)

```
r  <- r + (dt / tau) * ( -r + clip( g * W @ r + I_sense + I_noise - theta, 0, 1 ) )
```

| Parameter | Start | Notes |
|---|---|---|
| dt | 10 ms | two steps per 20 ms game tick |
| tau | 20 ms | try 10 to 50 |
| g | tune | largest value where resting activity stays low and doesn't sustain itself, and sensory pulses give bounded, readable outputs |
| theta | 0.0 to 0.1 | threshold |
| I_noise | small uniform noise on sensory neurons only | spontaneous activity, so outputs have a measurable baseline |
| r range | 0 to 1 | rates are unitless |

*Measured on Neil's M2 (single-threaded SciPy, float32):* one `W @ r` = **5.3 ms** at 5 or more synapses (6.24M edges),
9.0 ms at 3 or more (10.5M), 24.5 ms with every edge (25.6M, too slow for live play). Two steps per tick = about 11 ms of a 20 ms budget.

**Speed fallback:** the 2-hop core (neurons within 2 strong connections of both a sense and an output) is **37,004 neurons**.
Use it only if the laptop can't keep 50 Hz, and say so.

### Inputs: which neurons each role drives (`brain/io_sets.py` -> `io_sets.json`)

| Role | Cell types | Count | Split by | Drive rule (per tick, if that sense is open) |
|---|---|---|---|---|
| Lookout (Eyes) | LC10a | 275 | `somaSide` (L/R) | Sum over small moving objects (Princess, rivals) in that eye's half of the view of angular size x motion, normalized 0 to 1 |
| | LPLC2, LC4 | 185, 126 | `somaSide` | Looming rate (growth of angular size per second) of approaching objects on that side (the Giant's hand, fast rivals), 0 to 1 |
| Perfumer (Nose) | ORN_VA1v (Or47b, her scent) | 130 | `rootSide` (L/R; about 90 ORNs are "unknown", leave them out) | Concentration of that scent at that antenna |
| | ORN_DM1 (Or42b, the Feast) | 74 | `rootSide` | Same |
| | ORN_DA1 (Or67d, rival cVA) | 204 | `rootSide` | Same |
| Taster (Feet) | Foreleg ppk23 (`receptorType` = putative_ppk23 and `entryNerve` = ProLN) | 71 (37 L, 34 R) | `rootSide` | 100 ms pulse per tap, only while a foreleg touches her |
| Spymaster (Ears) | JO-C*, JO-E* (wind) | part of 473 | `rootSide` (280 L, 193 R) | Wind from the Giant's swing (ramps up about 300 ms before impact; fake swings are weaker) |
| | JO-A*, JO-B* (sound) | part of 473 | `rootSide` | Rival song loudness |

- Current per neuron = `I_max * drive`, spread evenly over that side's neurons of that type. `I_max` is tuned.
- Side counts are unequal (e.g. ORNs 101 L vs 217 R), so normalize drive **per side by neuron count**.
- **Antenna spacing is exaggerated** (about 2 mm apart instead of well under 1 mm) so left/right scent differences are playable. The Decree says so.
- **Arena scents** are Gaussian blobs: `c(x) = strength * exp(-d^2 / (2 sigma^2))`. The rival leaves a cVA trail that decays over about 10 s.

### Outputs: from neurons to movement (`server/body.py`)

Each output neuron's rate is turned into a z-score against its own resting baseline (5 seconds of rest with noise at the start
of each trial): `z = (r - mean_rest) / sd_rest`, smoothed over about 100 ms.

| Output type (count) | Movement | Rule (start values) |
|---|---|---|
| DNa02 (1 L, 1 R), DNa01 (1 L, 1 R) | Turning | `turn_rate = k_turn * (z_R - z_L)`. Check the sign in probe C (DNa02 activity predicts turning toward the same side) |
| DNp09 (2), DNg100 (2) | Walking forward | `speed = v_max * sigmoid(mean z - theta_walk)`, v_max about 15 mm/s |
| MDN (4) | Backing up | If z(MDN) > theta_back, walk backward at 5 mm/s |
| DNp01 (2, the Giant Fiber) | Escape jump | If z(DNp01) > theta_jump: jump 10 to 20 mm away from the loom source; 1 s refractory |
| pIP10 (2, male-only) | Wing out + serenade | If z(pIP10) > theta_song: wing extended, buzz plays, song meter counts when near and facing her |
| pC1 cluster (148 male-specific) | Mood meter (display only) | Mean z shown as a "Courting" bar on the chart |

**Hybrid steering (fallback if probe C fails at the 20:00 gate):** the brain still decides *whether* he walks, jumps, backs up or sings.
Code turns him toward the strongest stimulus reaching an open sense, scaled by the walking output. The Decree says so.

### The arena and body (`server/arena.py`, `server/body.py`, `server/script_actors.py`)

- Units: millimeters and seconds. Hall about 60 x 40 mm. Fly body about 2.5 mm long.
- **Contact:** foreleg touching = centers within 3 mm and she's within +/- 60 degrees of his heading.
- **Win geometry:** within 5 mm and facing her within +/- 45 degrees while pIP10 is above threshold; 5 s total wins.
- **Princess:** walks waypoints at 3 to 6 mm/s, pauses; after `patience_s` without song she moves farther away.
- **Rivals:** walk waypoints; may "sing" on a script (the song meter races the Prince's); leave cVA trails.
- **The Giant:** a list of swings `{t, target, from_deg, fake, warning_whoosh_s}`. A swing is a shadow whose angular size grows
  over about 0.5 s (drives LPLC2/LC4 on that side) plus wind (drives JO-C/E). A real swing lands after the growth. A fake one stops short.
- **Eyes phone image:** the server renders each half of the view at low resolution and sends 2 x 37 hex brightness values at 10 Hz.

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

### Probes (`brain/probes.py`): the tests behind the 20:00 gate

| Probe | Stimulus | Read | Pass |
|---|---|---|---|
| A. Looming | Looming drive on the left LPLC2 + LC4 for 0.5 s | z(DNp01) | Above 3 within 200 ms in at least 9 of 10 runs |
| B. Tapping | Foreleg ppk23 pulses at 4 Hz for 2 s | z(pIP10), mean pC1 | pIP10 above 2, and at least 2x the Changeling |
| C. Steering | LC10a drive on the left only | z(DNa02 L) - z(DNa02 R), and DNa01 | Consistent sign that turns toward the stimulus, at least 2x the Changeling |
| D. Smell | Or42b (Feast) on one side | Any output | Report the size. If tiny, the Perfumer's main job becomes the mood |

Each probe runs on the True Prince and all 3 Changelings, 10 runs each with different noise seeds. Print a table.

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

### Messages (JSON)

Phone to host (through the relay):
```json
{"t":"join","room":"BZKT","name":"Ava","clientId":"c-7f3a"}
{"t":"pick","role":"lookout"}                 // lookout | perfumer | taster | spymaster | auto
{"t":"in","role":"lookout","L":1,"R":0,"seq":42}   // sent on change, plus every 1 s
{"t":"in","role":"perfumer","L":0,"R":1,"seq":43}
{"t":"tap","role":"taster","seq":44}
{"t":"in","role":"spymaster","listen":1,"seq":45}
```

Host to phone(s):
```json
{"t":"assigned","roles":["lookout"],"name":"Ava"}
{"t":"phase","phase":"lobby|role|intro|play|chronicle|wedding","trial":"II"}
{"t":"view","role":"lookout","L":[0,12,200,...],"R":[...],"alert":"loom_left"}      // 37 hex values per eye, 10 Hz
{"t":"view","role":"perfumer","L":{"her":0.2,"feast":0.7,"rival":0.0},"R":{"her":0.4,"feast":0.1,"rival":0.3}}
{"t":"view","role":"taster","contact":true}
{"t":"view","role":"spymaster","wind":0.8,"song":0.1}
{"t":"fx","kind":"splat|jump|win|hint","text":"Lookout! Her Highness is to the left!"}
{"t":"honors","share":{"turn":0.41,"walk":0.22,"jump":0.0,"song":0.1},"events":["2 jumps from your left eye"],"line":"..."}
```

Server to Godot (local WebSocket, 30 Hz):
```json
{"t":"state","time":62.3,"brain":"true","phase":"play","trial":"II",
 "prince":{"x":21.5,"y":14.0,"h":87,"wing":0.8,"jumping":false},
 "princess":{"x":30.1,"y":16.2,"h":270},"rivals":[{"name":"Sir Cheapdate","x":40,"y":10,"h":180,"singing":false}],
 "giant":{"active":true,"x":25,"y":15,"size":0.6,"fake":false},
 "senses":{"lookout":{"L":1,"R":0},"perfumer":{"L":0,"R":0},"taster":{"tapping":false},"spymaster":{"listen":1}},
 "inputs":{"LC10a_L":0.6,"LC10a_R":0.0,"LPLC2_L":0.1,"ORN_VA1v_L":0.2,"ppk23":0.0,"JO_wind":0.1},
 "outputs":{"DNa02_L":1.8,"DNa02_R":0.2,"DNp09":1.1,"DNg100":0.9,"MDN":0.0,"DNp01":0.3,"pIP10":0.4,"pC1":1.2},
 "meters":{"song":0.4,"rival_song":0.1,"candle":0.69},
 "players":[{"name":"Ava","roles":["lookout"],"connected":true}]}
{"t":"event","kind":"voice","id":"H_HINT_LEFT","caption":"Lookout! Her Highness is to the left!"}
{"t":"event","kind":"voice_live","mp3_b64":"...","caption":"The Royal Perfumer did 41 percent of the steering..."}
```

Godot to server: `{"t":"cmd","cmd":"start|next|toggle_brain|reassign","arg":...}`.

## The Chronicler

After each trial (and while it's running, in 4 shadow processes):

1. The recorder saved each sense's input stream `I_s(t)` and the full-brain outputs.
2. For each sense `s`, replay the brain **open loop** with `I_s = 0` and every other sense unchanged.
3. Credit for sense `s` = how much each output changed without it: steering (DNa02 R minus L), walking, jump events, song time.
   Shares are normalized across senses. Events (a jump, a song) are credited to the sense whose removal makes the event disappear.
4. Output: a JSON of shares and events per player, used by the main screen, the phones and the Jester.

**Honest caveat:** it's open loop. Without your sense he might have walked somewhere else and seen different things. We say
"we replay the same trial with your sense switched off".

Budget: 4 shadows x about 5.3 ms per step x 100 steps per simulated second is about 0.5 s of compute per simulated second each,
so each shadow keeps up on its own core. Memory is about 50 to 100 MB per brain copy.

## Agents

No agent ever runs inside the live tick loop. Certified trials are cached on disk, so the game still works offline.

### Trial schema (`agents/schema.py`, Pydantic; the Matchmaker's output format)

```text
Trial:
  id: str
  act: "I" | "II" | "III"                     # style: garden, banquet, great hall
  title: str                                   # "The Banquet of Many Grapes"
  flavor: str                                  # one line, in the lore voice
  herald_intro: str                            # spoken by the Herald (must be under ~12 s)
  arena: {w_mm: float, h_mm: float, theme: "garden" | "banquet" | "great_hall"}
  prince_start: {x: float, y: float, heading_deg: float}
  princess: {start: {x, y}, waypoints: [{x, y, pause_s}], speed_mm_s: float, patience_s: float}
  scents: [{kind: "her" | "feast" | "rival", x, y, strength: 0-1, sigma_mm: float}]
  rival: null | {name: "Sir Indy" | "Lord Tinman" | "Sir Cheapdate" | "Count Rutabaga",
                 start: {x, y}, waypoints: [...], speed_mm_s, sings_at_s: float | null, cva_trail: bool}
  giant: [{t_s: float, target: "prince" | "near", from_deg: float, fake: bool, warning_whoosh_s: float}]
  time_limit_s: float                          # default 90
  focus_roles: [role]                          # which senses this trial leans on
```

### The Matchmaker (designs trials)

- **Model:** Gemini (decision O1), structured output with the Trial JSON schema. With Claude instead: structured outputs with the same schema.
- **Input:** act style, the Chronicler's note on which sense the last team neglected ("focus the Perfumer"), the list of recent rejections with reasons, and the lore rules (cast list, tone).
- **Output:** one Trial. Checked by code for geometry (inside the arena, reachable, no swing in the first 5 s) before testing.

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

### Bots (`agents/bots.py`): scripted councils for testing

The bots see what the phones show plus a simulated "shout" channel (the team talking):
- Lookout bot: opens the eye on the Princess's side; opens both eyes when the Spymaster bot shouts "whoosh"; closes the eye on the loom side otherwise.
- Perfumer bot: sniffs the side with more of her scent unless that side's rival scent is above 0.3.
- Taster bot: taps at 4 Hz during contact.
- Spymaster bot: listens always; shouts "whoosh" when wind rises above 0.2.

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

## Performance and memory budget (Neil's M2, 8 GB)

| Item | Budget |
|---|---|
| Live brain | about 11 ms per 20 ms tick (2 steps at 5.3 ms, measured) |
| Chronicler shadows | 4 processes, each about half a core |
| Memory | under 100 MB per brain copy; under 1.5 GB total with shadows |
| Godot | the rest. Close Chrome tabs during the demo |
| Raw data build | once, in chunks (the full edge table is about 3.6 GB in memory) |

The demo laptop should be the fastest machine on the team. Measure the tick rate on it at the 23:30 integration.

## Environment

- Python 3.11+: numpy, scipy, pandas, pyarrow, websockets, pydantic, qrcode, google-genai, elevenlabs, python-dotenv.
- Godot 4 (latest stable). Fonts: UnifrakturMaguntia, IM Fell English (Google Fonts, OFL).
- DigitalOcean: smallest Droplet for the relay; Caddy; the domain's A record points at the Droplet's IP.
- Secrets in `.env` only (git-ignored): `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`, `ROOM_SECRET`, voice IDs.
