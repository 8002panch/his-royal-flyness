# How it works: His Royal Flyness

The system, the message formats, the brain and how to run and test everything. The game itself: [GAME.md](GAME.md). Owners,
status and schedule: [TEAM.md](TEAM.md). Numbers here come from code or results files in this repo.

## Architecture

```text
4 phones (plain HTML/JS, controller-only)
   |  WebSocket JSON (move / sense / heartbeat)
   v
relay/relay.py (rooms, roles, reconnect, validation; later on DigitalOcean behind Caddy)
   |  WebSocket (the game server joins as the room's host)
   v
server/ (Python, authoritative: 50 Hz tick)
   - room and role state, x/y/z movement, world and hazards (trials, collisions, scoring: Phase 5)
   - Seer adapter: brain/seer.py (True Prince / Changeling), placeholder if data/ is missing
   |  local WebSocket, port 8765, 30 Hz "state"
   v
host/ (Godot 4, 2D): the only full-game screen; renders state, decides nothing
```

- **Python owns every outcome.** Godot renders; the relay validates and routes; phones send intent and show role feedback.
- **Only the Seer's socket ever receives `seer_view`.** The relay refuses to route it anywhere else (tested).
- **The brain never moves the fly.** It only produces the Seer's cues and the HUD's activity bars.

| Component | Owner | Files |
|---|---|---|
| Relay + phone page | Ved | `relay/relay.py`, `relay/public/` (join, role pick, 4 role screens), `relay/tests/` |
| Game server | Arnav | `server/main.py`, `state.py`, `movement.py`, `seer_adapter.py` (placeholder + graybox world), `godot_link.py`, `relay_client.py`, `sample_state.json`, `server/tests/`; `run_local.py` (one-command launcher) |
| Brain + Seer | Neil | `brain/` (graph, model, Changeling, probes, replay, `seer.py`), `server/chronicler.py` |
| Godot host + audio | Anshul | `host/` (on branch `anshul/host-seer-hud`), `audio/` (voice lines, sound effects and their generator: [Voices](#voices-elevenlabs)) |

## Run it locally

Python 3.11+ in a venv: `pip install -r requirements.txt`. Then one command starts the relay, the phone page, the game server and
the host screen (from the repo folder, or give the full path to `run_local.py`):

```bash
python run_local.py
```

- The **host screen** opens in the laptop's browser (`http://localhost:8001`, this laptop only): a lobby with the big **room code**,
  a **QR code** and the **join link** (`http://<laptop-lan-ip>:8000/?room=BZKT`, which fills in the code), and four seats that fill
  in as players pick roles. When all four are in, it switches to the live view: each role's card lights up while that player
  presses, the Helmsman, Liftmaster and Wingmaster cards show their axis, the Royal Nervous System bars show the brain, and the room
  code stays in the corner. On the host screen, **F** is full screen and **Enter** starts with fewer than four players. The QR comes
  from the `qrcode` package or OpenCV, whichever is installed.
- Phones must be on the same Wi-Fi. On a Mac, allow incoming connections for Python the first time, or phones can't reach the laptop.
- If it says a port is in use, the game is already running in another terminal: quit that one first (`q`, then Enter).
- Without `--room` every game gets a fresh code (Jackbox style). `--room BZKT` pins it (handy for testing; a phone reloading
  mid-game gets its seat back either way, from the tab's sessionStorage); `--seer true|changeling|placeholder`
  (default `true`, the real brain; it falls back to placeholder cues if `data/` is missing). Ports: `--http-port 8000`,
  `--relay-port 8080`, `--godot-port 8765`, `--host-port 8001`; `--browser` also opens the browser backup host screen (off by default: Godot is the main screen). `ROOM_SECRET` comes
  from the environment; locally it may be blank.
- **Host keys** in that terminal (letter, then Enter): `c` Changeling, `t` True Prince, `p` placeholder cues, `s` status (who holds
  which role, live inputs, fly position), `q` quit. It also prints a line whenever a phone takes or leaves a role.
- **The main screen is the Godot court** (`godot --path host`, Godot 4.3; open the project once or run
  `godot --headless --path host --import` on a fresh clone). It connects to `ws://127.0.0.1:8765`, shows the lobby with the join
  QR, and runs the story (see [The campaign](#the-campaign-servercampaignpy)); with no server it loops an offline sample, clearly
  labeled "OFFLINE SAMPLE". The browser host screen (`host/web/index.html`) reads the same feed and has the same story keys.
- **Story keys** in the launcher's terminal: `g` start, Enter next, `b` back, `k` skip, `r` restart the stage, `j GIANT` jump.
- **Online** (relay on the internet, see [Hosting the join link](#hosting-the-join-link-godaddy-domain)):
  `python run_local.py --room BZKT --relay-url wss://<domain>/ws` runs only the game server and host screen on the laptop; the
  join link and QR become `https://<domain>/?room=BZKT` (`--join-url` to show a different page).
- Running the parts separately still works: `python3 relay/relay.py`, `python3 -m http.server 8000 --directory relay/public`,
  `python3 -m server.main --room BZKT --seer true` (`--relay-url` or `RELAY_URL` for a remote relay).

## Protocol

### Transport and envelope

- Local development: WebSocket at `ws://<laptop>:8080`.
- Every client message is a JSON object with a strictly increasing, non-negative integer `seq` per connection.
- A malformed, stale, unauthorized or out-of-range message gets `{"t":"error","code":"...","message":"..."}`.
- While a control is held, the phone **resends it every 0.4 s**; otherwise it sends a `heartbeat` every second. The game server
  drops any held input it hasn't heard about for 1.2 s, and heartbeats stop at the relay, so the resend is what keeps a hold alive.

### Joining

Game server (host):

```json
{"t":"host_join","room":"BZKT","secret":"from-env","seq":1}
{"t":"host_joined","room":"BZKT"}
```

Only one host may claim a room. In production the host must send `ROOM_SECRET`; locally an empty secret works only when no
`ROOM_SECRET` is configured.

Phone:

```json
{"t":"join","room":"BZKT","name":"Ava","clientId":"stable-browser-uuid","seq":1}
{"t":"joined","room":"BZKT","name":"Ava","roles":["helmsman","liftmaster","wingmaster","seer"]}
{"t":"pick","role":"helmsman","seq":2}
{"t":"assigned","room":"BZKT","role":"helmsman","name":"Ava","restored":false}
```

`clientId` is generated once and kept in `localStorage`. If its saved role isn't occupied when it reconnects to the same room,
the relay restores that role automatically. A phone that reconnects on its own also sends its last role
(`{"t":"join", ..., "role":"seer"}`), so it gets the role back even from a restarted relay that remembers nobody (granted if
free; otherwise it sees the role picker). If the same phone still holds that role on an older connection (a reloaded page, or
a socket that died when the phone slept), the new connection takes it over and an older page that's still open gets
`{"t":"seat_moved","role":"seer"}`. Rooms are isolated by code. **Seats, not connections, are limited:** four roles, each once;
up to 16 phones may be in a room (waiting phones see the picker), so extra tabs or dead connections can never fill the court.
Phones still choosing get the open roles live whenever a seat changes: `{"t":"roles","roles":["liftmaster","seer"]}` (an empty
list shows "The court is full").

The relay tells the game server who holds which role, on the host's join and on every change:

```json
{"t":"roster","players":[{"name":"Ava","role":"helmsman"},{"name":"Dee","role":"seer"}]}
```

### Phone input

| Role | Message | Values |
|---|---|---|
| Helmsman | `{"t":"move","role":"helmsman","axis":"x","value":-1\|0\|1,"seq":n}` | left, neutral, right |
| Liftmaster | `{"t":"move","role":"liftmaster","axis":"y","value":-1\|0\|1,"seq":n}` | descend, neutral, climb |
| Wingmaster | `{"t":"move","role":"wingmaster","axis":"z","value":-1\|0\|1,"seq":n}` | brake/reverse, neutral, forward |
| Seer | `{"t":"sense","role":"seer","scan":0\|1,"seq":n}` | stop / hold scan |
| Any assigned phone | `{"t":"heartbeat","seq":n}` | liveness only |

A phone may only send its own role's message. Release, pointer cancel, page hide and socket close send neutral input where
possible; the relay also clears stale input itself.

### Host to phone (through the relay)

The host sends `phone_view`; the relay picks the recipients (hosts never see connection IDs).

```json
{"t":"phone_view","role":"helmsman","seq":2,
 "view":{"t":"control_view","role":"helmsman","actualX":-0.4,"momentum":0.7}}

{"t":"phone_view","role":"seer","seq":3,
 "view":{"t":"seer_view","bearing":"NE","distance":"FAR","confidence":0.82,
         "giant":{"direction":"LEFT","seconds":2.1,"confidence":0.73},"source":"true"}}
```

Movement views: Helmsman `actualX`, `momentum`; Liftmaster `altitude`, `verticalVelocity`; Wingmaster `speed`, `braking`.
`seer_view` goes to the active Seer only, and only while the Seer holds scan. `bearing` is `NW` / `N` / `NE` (left / ahead /
right of Hamlet's heading) or null; `distance` is `NEAR` / `MID` / `FAR` or null; Giant `direction` is `LEFT` / `AHEAD` / `RIGHT`
or null, `seconds` may be null.

### Error codes

| Code | Meaning |
|---|---|
| `INVALID_ROOM` | Room isn't four uppercase consonants |
| `INVALID_NAME` / `INVALID_CLIENT_ID` | Join fields are malformed |
| `ROLE_TAKEN` | Another active phone has that role (the picker updates itself; the phone shows a short notice) |
| `ROOM_FULL` | More than 16 phones in one room (an abuse guard; the four seats are limited separately) |
| `FORBIDDEN_CONTROL` | A phone tried to control another role or axis |
| `STALE_SEQUENCE` | `seq` isn't newer than the last accepted one |
| `HOST_AUTH_FAILED` / `HOST_EXISTS` | Invalid room claim by a host |
| `FORBIDDEN_ROUTE` | That view type can't be delivered to phones |

### Server to Godot (`state`, 30 Hz)

```json
{"t":"state","phase":"play","time":12.4,
 "room":"BZKT","joinUrl":"http://192.168.1.23:8000/?room=BZKT","brain":"true",
 "brainActivity":{"vision":8.8,"looming":46.1,"escape":28.2},
 "fly":{"x":0.2,"y":0.0,"z":0.1,"vx":0.4,"vy":0.0,"vz":0.1},
 "render":{"princess":{"bearing_deg":16.4,"elevation_deg":11.9,"distance_cm":199.6},"giant":null},
 "roles":{"helmsman":true,"liftmaster":false,"wingmaster":false,"seer":true},
 "players":{"helmsman":"Ava","liftmaster":"Bo","wingmaster":"Cy","seer":"Dee"}}
```

- `room` and `joinUrl`: for the lobby's big room code and QR (`joinUrl` is null when the server runs without `run_local.py`).
- `brain`: `"true"`, `"changeling"` or `"placeholder"`, for the TRUE PRINCE / CHANGELING badge.
- `brainActivity`: the Seer adapter's `cues["activity"]`, z-scores; `{}` whenever the cues aren't from a brain, so no placeholder
  number is ever shown as brain output. The HUD draws one bar per key, whatever the keys are. The keys are **side-free on purpose**:
  a left/right or "straight ahead" bar on the shared screen would give away the Seer's secret (tested:
  `test_hud_activity_does_not_give_away_where_the_princess_is`).
- `roles`: whether each role's input is currently non-zero.
- `players`: role to display name for the phones holding a role (filled by `run_local.py` from its relay; `{}` otherwise).
- Still to define (Arnav, Anshul's request): `"controls"`, each movement axis's live value for the HUD's axis indicators.

Godot may render this state but never decides outcomes. The whole-map positions in `render` must not be drawn as a map or an
exact bearing (GAME.md, "The main screen").

## The campaign (`server/campaign.py`)

Arnav's story (GAME.md, "Story campaign"), run by the server: `GameSession(..., campaign=True)` (the launcher and
`server.main` turn it on; without it the session is the free-flight test world the older tests use).

- **Flow:** lobby -> TUTORIAL -> C01 -> Q01 -> STAGE1 -> Q02 -> STAGE2 -> Q03 -> C02 -> GIANT -> C03 or C04 -> (FATHER) ->
  E01 or E02 -> end. Comic and quiz lines come from `audio/lines.csv` on the route taken, so the script lives in one place.
  Play-time lines (tutorial tips, Stage 2 notices) are queued so none cuts another off.
- **Phases** (`state.phase`): `lobby`, `comic`, `question` (the Seer must answer), `ready` (a 2 s count-in; inputs clear, so
  players press again), `play`, `end`. Flight, clocks and attacks are frozen outside `play`.
- **Quizzes:** only the Seer's phone can answer (`{"t": "answer", "choice": "A"|"B"}`; the relay refuses it from any other role),
  once per quiz; Back rereads but never undoes it; Skip stops at an unanswered question. A wrong answer adds a dizziness level
  (0 to 3): 25% less drag each, controls that answer 0.1 s later per level and a slow sway that pushes Hamlet off line
  (`Campaign.steer`), and a swirl-and-wave wobble of the court on screen: a scripted movement change, not alcohol in the
  nervous system. Walls are solid: the body stops 0.06 short of a wall and a hit sends a `bump` event (a thud).
- **Courses:** Ved's four wall gates (Stage 2 mirrored), openings off the centre line; the server sends them in `state.walls`
  and Godot draws those. Stage 2 has a 60 s clock and three swats; a timeout or a hit restarts it without repeating anything.
- **Attacks** (Stage 2, Giant, father): the target is locked at onset beside Hamlet on the hand's side; he's hit if still within
  0.3 of it when it lands (2 to 2.4 s later). During the warning the attack exists only as a looming hand in the brain's stimuli,
  so the Seer's phone warns from the real brain (the True Prince warned 3 of 3 attacks, on the right side, about 2.2 s ahead; the
  Changeling none: `test_campaign.py`). Godot gets `state.impact` only after it lands, plus `dodge`/`hit` events. Giant: 10 dodges
  -> C03, 3 hits -> C04. Father: 5 dodges -> E01, 1 hit -> E02.
- **State fields for the screens:** `phase`, `scene`, `backdrop` (Anshul's v4 backdrop id), `objective`, `beat` {id, speaker,
  name, caption, panel, gesture, index, count, cast, prev}, `question` {id, text, a, b, chosen, correct}, `counters`, `props`,
  `walls`, `impact`, `dizzy`, `steadiness`, `ready`, `storyDemo`, and `joinQr` (the join link as QR rows) in the lobby. Phones get
  `{"t": "phase", ...}` on each change and once a second.
- **Presenter commands** (`{"t": "host_command", "command": ...}` on the Godot link, this laptop only): `start`, `next`, `back`,
  `skip`, `restart`, `jump` (+ `scene`; marks the run DEMO and never grants a story result). Godot keys: Enter (start / next), Space,
  Right or Page Down (next), Left or Page Up (back), S (skip), R (restart), Ctrl+1..9 (TUTORIAL, Q01, STAGE1, Q02, STAGE2, Q03,
  C02, GIANT, FATHER), F6 the Royal Decree.
- **Tutorial:** GAME.md's teaching order (grape 1 straight ahead, 2 to the side, 3 up high, 4 everything); pickup within 0.3 at
  any speed, delivery within 0.32 of the chalice: forgiving, because three people each steer one axis. `state.guide` and each
  mover's `control_view.tip` coach the way to the grape or chalice ("Grape: steer right"); off for the Seer's lesson (the last
  return), which flies towards Miranda so the fly's eyes can see her.
- **The shared screen in fights:** `brainActivity` is empty while a fight is on. The brain's only input then is the approaching
  hand, so a moving bar would tell everyone when an attack is coming; that stays on the Seer's phone.
- **Godot** (`host/scripts/court/`): `hud/comic_overlay.gd` (backdrop, the cast as Anshul's animated rigs, bubbles, the quiz
  card), `hud/story_banner.gd` (objective, counters, tutorial coaching row, count-in, end card, DEMO), `story_art.gd`
  (backdrops and rigs), `story_props.gd` (chalice, grape, goal arrow), `story_cast.gd` (Anshul's backgrounds_v2 sets and their
  casts: the garden for the tutorial, the Great Hall for the Giant, the Banquet for Prospero), `court_world.gd` (set, hall or
  backdrop, walls, the landed fist), `voice_player.gd`. The tutorial and fights use a still camera (`HallCam.stage`) with the
  server's cube mapped onto the set in front of it; the wall courses keep the chase camera in the hall. Hamlet and Miranda in
  play are the animation_v1 rigs.
  `--state=file.json --shot=out.png` renders a saved server state.
- **Tests:** `server/tests/test_campaign.py` (Arnav's acceptance checklist with an autopilot, the Seer's secret, the real brain in
  the fight), `relay/tests` (Seer-only answers), `relay/public/tests` (phone story screens), `host/test/story_smoke.gd`.

## The game server (`server/`)

- **Never waits on the network:** the relay sends every message on its own with a 2 s limit and skips closing connections; the
  game server sends phone feedback and host-screen frames in the background, skipping a round if one is still going out. Before
  this, one phone going to sleep froze everyone's feedback and the host screen for about 10 s once its connection timed out
  (tested: `SlowPeerTests`). Keepalive pings every 5 s drop a dead phone within about 10 s.
- **The brain runs on its own thread** in the live server (one 20 ms step per slot; under load it falls behind real time rather
  than stalling the game). Measured with four players and six CPU hogs: 50 brain steps per second and a steady 30 frames per second.
- **Relay connection:** the server keeps retrying until the relay is up and reconnects within about a second if it drops.
  While disconnected the game keeps running, held inputs are cleared and the host screen's seats empty until the relay's
  roster arrives again (tested: `test_game_server_survives_a_relay_restart`).

- `GameSession(room, seer=None, join_url=None)` is pure and importable (headless replay and tests). `apply_input()` validates role
  and axis; `step(dt, now)` expires inputs older than 1.2 s, moves the body and **senses once** (stimuli and cues are kept for the
  tick); `phone_views()` builds the four views (the Seer's only while scanning); `godot_state()` builds the state message;
  `set_brain("true" | "changeling" | "placeholder")` is the host toggle.
- `make_seer(source)`: the brain-powered `SeerAdapter` with both brains preloaded (so the toggle is instant), or the placeholder
  if `data/` is missing.
- `GameServer.run()`: 50 Hz tick, Godot state at 30 Hz, phone views at 10 Hz, all on fixed-rate schedules, so the ~6 ms brain step
  doesn't stretch every tick (measured: Godot gets a steady 30.0 frames per second with the real brain).
- **Movement** (`server/movement.py`, `MovementTuning`): acceleration 2.4, drag 3.2 per second when released, max speed 1.0,
  dead zone 0.05, positions bounded to [-1, 1] per axis (hitting a bound stops that axis). Deterministic: the same inputs give the
  same trace (tested).
- **Graybox world** (`projected_stimuli()` in `server/seer_adapter.py`): one stationary Princess at (0.25, 0.18, 0.85) and a
  test Giant from the left for 2 s of every 8 s; world units x 220 = cm. Real trials, collisions, win/lose and scoring are Phase 5.
- **Seer adapter boundary:** anything with `sense(stimuli) -> cues`, `to_phone_view(cues) -> seer_view` and `.source`. The
  internal `cues` dicts of the placeholder and the brain adapter differ; the stable contracts are `seer_view` (phones) and
  `brainActivity` (Godot).

## The brain (`brain/`)

### Graph (`brain/build_graph.py`, about 35 s, peak memory about 700 MB)

- MaleCNS v1.0 (Berg et al., *Cell* 2026; CC-BY 4.0). Neurons with a superclass not containing "tbc": **166,606**.
- Connections with 5 or more synapses: **6,240,402** (72.4% of all synapses). Output: `data/graph_true.npz`, `data/neurons.parquet`.
- Signs from `consensus_nt`: acetylcholine +1; GABA, glutamate, histamine -1; dopamine, octopamine, serotonin silenced (0, 541
  neurons); unclear or missing +1.
- Weights are input fractions: `W[i, j] = sign[j] * count / in_total[i]`, where `in_total` counts all of neuron i's input
  synapses (including the pruned ones), so every row's absolute sum is at most 1.

### Rate model (`brain/model.py`)

- `r <- r + (dt / tau) * (-r + clip(gain * W @ r + I - theta, 0, 1))` with gain 4, theta 0, input current 1 at full drive,
  **dt = tau = 20 ms: one step per game tick**, and noise SD 0.05 on the input neurons each step.
- Outputs are z-scores against a cached resting baseline (100 ticks to settle, 150 to measure, SD floor 0.01). Weights and
  baselines are cached per process, so a second `Brain` costs about 0.01 s.
- Chosen Sat 26 Sept from a gain sweep and probes: input fractions at gain 4 keep 5 to 7% of neurons active at rest, under 1%
  saturated, and give clean, side-specific visual channels. Changelings are silent at rest.

### The Changeling (`brain/changeling.py`, seeds 0 to 2)

Each connection's sender is shuffled among neurons of the same sign; receivers and synapse counts stay fixed. So every neuron
keeps its exact total input, its excitatory/inhibitory mix and its out-degree; more than 99% of partners change (all tested).

### API (`brain/brain.py`)

```python
from brain.brain import Brain, INPUT_GROUPS, OUTPUT_NAMES
brain = Brain("true")                 # or Brain("changeling", seed=0..2); Brain(stub=True) needs no data files
brain.reset()                         # back to rest (instant)
out = brain.step({"her_L": 0.8})      # one 20 ms tick; drives 0..1 per input group; returns a z-score per output name
brain.swap("changeling", seed=1)      # the Changeling toggle (resets to rest)
```

Groups live in `brain/io_sets.json` (built by `brain/io_sets.py`; left and right groups never overlap and sit on the right side).

| Input group | Neurons | Target output (True Prince z at full drive / best Changeling) |
|---|---|---|
| `her_L`, `her_R` | LC10a + LC10d, one eye (Seer) | `seer_her_L/R` |
| `loom_L`, `loom_R` | LC4 + LPLC2, one side (Seer) | `seer_loom_L/R` |
| `wind_L`, `wind_R` | JO-C/E by root side (Seer) | `seer_wind_L/R` |
| `forward` | LC9 + LC31a | `DNp09` walk/thrust 36.7 / 1.4 |
| `back` | SNta02, SNta09 + LC16 + LoVP26 | `MDN` back up 3.9 / 1.8 |
| `left`, `right` | LLPC1, one side | `DNa02_L` 9.4 / 0.9, `DNa02_R` 12.0 / 1.6 |
| `up` | LPLC1 + LLPC2 | `DNg02` wing power 5.0 / 0.3 |
| `down` | LPLC4 | `DNp07_10` landing 43.3 / 4.1 |
| `duck` | LC4 + LPLC2 | `DNp01` Giant Fiber 99.2 / 2.1 |
| `serenade` | LC10a + LC10d, both eyes | `pIP10` song 8.7 / 1.3 |
| `lock_L`, `lock_R` | LC10a + LC10d, one eye | `DNa02` same side: left 18.1 / 2.0, right 17.3 / 1.0 |

The button groups (forward to lock) are from the earlier brain-driven movement plan. Movement is direct now, so the game only
uses the Seer groups; the button channels stay available and tested. All pass the gate (target z above 3 and at least 2x every
Changeling): `team/neil/probes_v2_level10.csv`, figure `team/neil/figures/controls_matrix_light.png` (`python -m brain.figures`).

Outputs: `DNp09, DNg100, MDN, DNa02_L, DNa02_R, DNg02, DNp07_10, DNp01, pIP10, pC1, seer_her_L/R, seer_loom_L/R, seer_wind_L/R`.

## The Royal Seer (`brain/seer.py`)

```python
from brain.seer import SeerAdapter
seer = SeerAdapter("true")          # "true" | "changeling" | "placeholder"; mode="neural" (default) or "hybrid"
cues = seer.sense(stimuli)          # once per game tick; about 6 ms with the real brain
view = seer.to_phone_view(cues)     # the relay's seer_view
seer.swap("changeling", seed=0)     # the Changeling toggle; swap("true") / swap("placeholder") to go back
```

**Formats**

```python
# server -> Seer, every tick. Degrees: bearing 0 = straight ahead, negative = left, positive = right; elevation positive = above.
# Distances in cm; approach_cm_s > 0 means getting closer.
stimuli = {
    "princess": {"bearing_deg": -35.0, "elevation_deg": 10.0, "distance_cm": 420.0} or None,
    "giants": [{"bearing_deg": 80.0, "elevation_deg": 30.0, "distance_cm": 150.0, "approach_cm_s": 300.0, "size_cm": 40.0}],
    "wind": {"bearing_deg": 80.0, "strength": 0.6} or None,      # strength 0 to 1
}
# Seer -> server
cues = {
    "princess": {"side": "left" | "ahead" | "right", "bearing_deg": -60 | 0 | 60, "confidence": 0-1,
                 "distance": "near" | "mid" | "far"} or None,
    "giant": {"warning": 0-1, "side": "left" | "right" | "ahead" | None, "eta_s": float or None},
    "activity": {"vision": z, "looming": z, "escape": z},     # for the main-screen HUD (brainActivity); side-free
    "source": "true" | "changeling" | "placeholder", "mode": "neural" | "hybrid" | "placeholder",
}
```

**Encoding (our assumptions, stated on the Royal Decree)**

- Each eye sees its own side plus a **binocular strip of +/-10 degrees** across the midline (edge softness 2 degrees); the
  Princess straight ahead drives both eyes, which reads as "ahead". Nothing is seen within 15 degrees of straight behind.
- Princess drive falls with distance: `min(1, princess_full_cm / distance)`. `princess_full_cm` defaults to 150 cm; the server
  sets 100 cm to fit its hall (`SEER_PRINCESS_FULL_CM` in `server/main.py`). She's detected out to about 5x that distance.
- Looming drive is **logarithmic** in the Giant's angular expansion rate, `log1p(v/2) / log1p(300/2)` for v in degrees per
  second (like real looming detectors), which gives about a second of warning.
- Wind drives the antenna on the gust's side (smooth left/right split).

**Decoding (fixed, not trained)**

- **Princess found** when the stronger eye's readout is at least **3 z above rest** (resting noise is about 0.3 z, so that's
  about 10x the noise). Using the stronger eye, not the sum, keeps "straight ahead" (both eyes) from reading as "closer".
- **Side** from the left-vs-right balance (under 0.25 = ahead). **Confidence** = (stronger eye - 3) / (17 - 3), where 17 z is the
  measured single-eye readout at full drive; it grows in proportion to the drive, so it tracks distance. **Distance band**:
  confidence at least 0.5 NEAR (about 1.7x `princess_full_cm` or closer), at least 0.15 MID (about 3.3x), else FAR.
- **Giant warning level** from the looming readout (rises from z 3, full at z 60), or half-strength from wind. The Seer is told
  about a Giant (side and seconds) once the level reaches **0.3**, the same bar the evaluation counts as "warned".
- **Seconds to impact** (contact = the hand reaching the fly) from a lookup of warning level measured on the True Prince
  (`brain/seer_calibration.json`, 24 points, rebuilt with `python -m brain.seer --calibrate`). It comes from looming strength
  alone, so it's most accurate for Giants like the calibration mix (median error 0.12 s; 0.23 s for the server's slow test Giant).
  Wind alone gives no time estimate.
- The Changeling is read out exactly the same way. Its single-eye Princess readout stays at or below 3.1 z even at full drive
  (the True Prince reaches about 18), so it essentially never crosses the detection bar: it goes blind rather than guessing.

**Readouts** (side-selective descending neurons found by a left-vs-right scan; same side / other side z, True Prince):

| Readout | Neurons | Response |
|---|---|---|
| `seer_her_L/R` | DNa02, DNg111, DNae002, DNae001, DNg41, DNa10 | 18.0 / -0.9 and 17.9 / -0.7 (full drive) |
| `seer_loom_L/R` | DNp04, DNp02, DNp01 (Giant Fiber), DNg40, DNp11, DNp03 | 85 / 1.0 and 81 / 0.6 |
| `seer_wind_L/R` | DNge016, DNg29, DNge175, DNp18, DNg05_a | 16 / 1.1 and 19 / 0.2 |

**Why these neurons** (for judges' questions; the readout populations were picked by a left-vs-right scan of the data, and not
every neuron in them has a known role):

| Choice | Biology behind it |
|---|---|
| LC10a as Princess detectors | Males use LC10a visual projection neurons to track the female during courtship (Ribeiro et al. 2018). LC10d is our addition from the same LC10 family, chosen by the scan |
| LC4 + LPLC2 as looming detectors, DNp01 in the Giant readout | Both detect looming and drive the giant fiber (DNp01), the escape neuron (von Reyn et al. 2014; Ache et al. 2019); in MaleCNS they send it 11,224 synapses |
| DNp02, DNp04, DNp11 in the Giant readout | Looming-responsive descending neurons downstream of LC4/LPLC2 (von Reyn et al. 2017) |
| JO-C/E as wind sensors | Johnston's organ C and E neurons respond to sustained antennal deflection (wind), A and B to sound (Yorozu et al. 2009) |
| DNa02 in the Princess readout | A steering descending neuron whose left-right activity predicts turning (Rayshubskiy et al. 2020) |
| Rate model, signs from transmitters | A simplification: real neurons spike, adapt and are modulated. The Royal Decree says so |

**Evaluation** (`python -m brain.seer --evaluate`: 60 fresh random scenes per brain; `team/neil/seer_eval.csv`)

| Brain | Princess found | Side correct | Giant warned before impact | Warning lead | Giant side correct | Time-to-impact error |
|---|---|---|---|---|---|---|
| **True Prince** | **54/60** | **53/60** (cue in 40 ms) | **60/60** | **1.20 s** | **60/60** | **0.12 s** |
| Changelings (3 seeds) | **0/60** | 0/60 | **0/60** | none | 0/60 | none |
| Placeholder (true geometry) | 60/60 | 60/60 | 60/60 | 1.28 s | 60/60 | 0.00 s |

The scenes put the Princess 40 to 800 cm away at the default 150 cm scale; the 6 the True Prince missed were beyond about 700 cm
(its detection range), and its one wrong side was at 8.7 degrees, on the edge of "ahead".

**In the game's own hall** (the server's `projected_stimuli` at its 100 cm scale, 120 fly positions; tested in
`test_in_the_game_world_the_cues_make_sense`): True Prince sides right from 116 of 120 positions, including when the fly has flown
past her; NEAR 69 to 173 cm, MID 170 to 330 cm, FAR 305 to 510 cm, nothing reported beyond about 410 to 540 cm; the three
Changelings report her 0 times. The test Giant is warned 1.96 s before contact by the True Prince and never by a Changeling.

**Behavior worth knowing**

- **Real-time stepping:** each `sense()` advances the brain by the wall-clock time since the last call, in 20 ms steps (at least
  one on the first call, at most 10 after a long gap, then it settles on the current scene). A second call within the same 20 ms
  returns the cached cues, so calling it from both `phone_views()` and `godot_state()` can't speed the brain up (tested).
  `SeerAdapter(realtime=False)` takes exactly one step per call (tests, replays).
- **Best practice for the server:** call `sense()` once per 50 Hz tick and reuse the cues for the phone view and the HUD.
  Calling only at 10 Hz works but makes 5-step (about 30 ms) catch-up bursts that can make a tick late.
- **Safe fallback:** if the brain throws or its data is missing, `sense()` returns placeholder cues with `"error": true`.
- **Hybrid mode** (`mode="hybrid"`, disclosed if used): side and bearing from the true geometry, confidence, warning and timing
  from the brain.
- **Coarse bearing is honest:** each eye's Princess detectors are driven as one group, and MaleCNS has no eye-position (column)
  data for LC10a/LC10d or LC4/LPLC2, so the wiring only says left, ahead or right.
- **Shared-brain mode:** `SeerAdapter(brain=my_brain)` plus `sense(stimuli, extra_drives=buttons)` runs button inputs and senses
  in one brain step (only needed if some movement ever goes through the brain).
- Known interactions in the real wiring (not bugs): seeing the Princess pulls steering toward her and damps forward drive; activity
  carries over about 100 ms after an input stops.

### In the server (Phase 6, done)

`run_local.py` and `python -m server.main` use `make_seer("true")` by default; `GameSession` senses once per tick and sends
`brain` and `brainActivity` to Godot (tested in `brain/tests/test_seer.py::test_plugs_into_the_server_game_session` and
`test_server_uses_the_real_brain_and_falls_back_without_it`).

```python
from server.main import GameSession, make_seer
session = GameSession(room, seer=make_seer("true"))
session.set_brain("changeling")                         # host toggle; set_brain("true") to go back
```

## The Chronicler and replay (`server/chronicler.py`, `brain/replay.py`)

Built for the earlier brain-driven design: one shadow brain per player plus a full shadow, each in its own process, replaying the
chapter with that player's inputs removed (deterministic, one step per tick, about 8 ms per tick each with five running). Credit
per category (turn, walk, jump, song) with dead zones, so silent players get nothing. The result JSON format is in the module
docstring. With direct movement it can only credit the Seer; whether it stays is an open team decision (TEAM.md).

## Agents (planned, lowest priority)

Gemini agents from the original plan: the Matchmaker designs trials (structured output against a Pydantic Trial schema), the
Master of Trials tests them with `run_trials` on the True Prince and the Changeling and certifies only fair ones (True Prince
win rate 30 to 80% and at least 25 points above the Changeling), and the Jester writes roast lines from computed numbers. None
of it runs inside the live game loop. The redesign's cut order drops generated trials first; `run_trials` waits on Arnav's
answer (TEAM.md).

## Hosting the join link (GoDaddy domain)

The phone page is plain files, so any web host can serve it. The **relay is a program** that keeps a live WebSocket open to
every phone and to the game laptop, and static hosting (GoDaddy's free website hosting, Website Builder, basic shared hosting)
can't run one. So the domain needs one of these, best first:

1. **Domain + a small server (recommended).** Point the GoDaddy domain's A record at a server such as a DigitalOcean Droplet
   (MLH credits; also the MLH DigitalOcean prize) and run the relay behind Caddy there: steps are at the top of
   `relay/Caddyfile` (automatic HTTPS). Phones open `https://<domain>/?room=BZKT` (the page connects to `wss://<domain>/ws`); the
   laptop connects out with `ROOM_SECRET=<secret> python run_local.py --room BZKT --relay-url wss://<domain>/ws`. Works on venue
   Wi-Fi, cellular, and Wi-Fi that blocks phone-to-laptop traffic.
2. **Page on GoDaddy hosting, relay on a server.** Upload the contents of `relay/public/` to the GoDaddy hosting and set
   `window.RELAY_URL = "wss://relay.<domain>/ws"` in its `config.js` (a `relay` subdomain pointed at the server running the relay
   and Caddy). Laptop: `python run_local.py --room BZKT --relay-url wss://relay.<domain>/ws --join-url https://<domain>/`. Still
   needs the server; it only moves the page. (Rehearsed locally: a file-host copy with `config.js` joined a separate relay.)
3. **No server: forward the domain to the laptop.** GoDaddy domain forwarding to `http://<laptop-lan-ip>:8000/?room=BZKT` (plain
   `http`, since browsers block `ws://` from an `https` page). Only for phones on the laptop's Wi-Fi; it breaks if the venue Wi-Fi
   isolates devices, and the laptop's IP changes per network, so the forward must be updated at the venue.

- Set the same `ROOM_SECRET` on the relay and the laptop so nobody else can claim your room as its host.
- Cloud and DNS changes need the team's approval and credentials (Ved owns the Droplet and the domain).
- Fallbacks at the demo: the local mode (`python run_local.py`) on venue Wi-Fi or a phone hotspot; there is no keyboard player mode in Arnav's approved campaign.
- Secrets only in `.env` (git-ignored); `.env.example` lists the names with blank values.

## Voices (ElevenLabs)

Every voiced line of Arnav's story script (GAME.md, "Panel-by-panel story script", on `arnav/story-comic-draft` until it merges), the tutorial and stage popups, and the lobby,
Changeling and Decree lines are in **`audio/lines.csv`**: 145 lines in story order, one row per speech bubble, with an `id`, the
`scene` and `panel`, a `branch` (`correct` / `wrong` for the quizzes, `giant_win` / `giant_loss`, `father_win` / `father_loss`),
the `speaker`, an optional `stability` override and an optional `sfx` cue. Square brackets are ElevenLabs v3 audio tags
(`[hiccups]`, `[softly]`): they direct the voice and are stripped from captions. Delete a tag if a take sounds wrong. The bank
started as Arnav's words and the voice pass changed some of them (TEAM.md, Neil to Arnav): each suitor now asks and explains
their own quiz question, each quiz opens with a short suitor line (`Q0x_P1B`), C04 panel 2 is Prospero's own line, and
Miranda has eight more bubbles (tutorial, C01, C02, C03, C04, E01).

**Fight shouts.** The `GIANT` and `FATHER` scenes are pools of short shouts (Miranda, Hamlet, the Clown, Prospero and the
rivals) for the two dodge fights, grouped by the event in `panel`: `after a dodge`, `after a hit`, and milestones (`after dodge
5`, `after hit 2`, `after dodge 9`; `after dodge 4` and `after the hit` against Prospero). After an attack resolves, the game
plays that event's sound (the shout's `sfx`) and may add one shout from the pool (a milestone line replaces the ordinary one).
A shout never starts, stops or changes because a warning began, and none names a direction or a timing word (a test checks);
that keeps the Seer's secret. Skip a shout if one is still playing.

**`audio/voices.json`** is the cast: one ElevenLabs voice per speaker (Clown, Hamlet, Miranda, Prospero, Lord Tinman,
Sir Cheapdate, Count Rutabaga), a short casting brief and the v3 `stability` (0.0 creative, 0.5 natural, 1.0 robust, closest to
the voice's sample). Miranda runs at 1.0 so she stays soft; her refusal (E02_P3) overrides it to 0.5. Voice IDs are not secret,
so they're committed and everyone generates the same cast; a voice-library link works in place of an ID. Library voices only,
no clones of real people.

**`audio/sfx.csv`** is the sound bank (ElevenLabs sound effects): the Giant's grunts, growls, huffs, swats and crashes, the
comic-panel noises, three quiet fly sounds (`FLY_BUZZ_LOOP` for under flight, `FLY_TAKEOFF`, `FLY_ZIP`), a courtiers' gasp
and cheer, and something Prospero throws missing or hitting Hamlet (there's no sound when he throws, which would give away the timing). Each has a prompt,
a length, whether it loops, a `volume_db` baked into the file and a `when` column saying where it plays. Every sound is made mono.

```bash
python audio/gen_voices.py --dry-run      # no key needed: checks both banks and the cast, lists what would be sent
python audio/gen_voices.py --my-voices    # the voices in your account, with IDs to paste into voices.json
python audio/gen_voices.py --check        # the key works, each cast voice is found, characters left this month
python audio/gen_voices.py                # generates what changed; --only C01 hamlet H_TITLE sfx, --force to redo
python audio/gen_voices.py --prune        # also deletes mp3s whose line or sound was removed from a bank
python audio/gen_voices.py --polish-only  # no key needed: applies polish changes that need no new take
```

- The key: `ELEVENLABS_API_KEY` in `.env` at the repo root (git-ignored) or the environment. Never in a commit.
- Output: `audio/voice/<id>.mp3` and `audio/sfx/<id>.mp3`, each folder with a `manifest.json` (every entry with its caption or
  cue and its file, `null` until generated, `stale: true` if the file was made from an older version of the line) and a
  `manifest.js` (the same, for the table read). A line is regenerated only when its text, voice, model or stability changes, and
  a sound only when its prompt, length or loop changes, so rerunning costs nothing for work that's done. The mp3s are committed so
  the demo laptop needs no key. `--no-sfx` skips the sounds.
- **Polish** (after generation, free): `level` in voices.json brings every speaker's speech to -16 dB so the cast sits at
  one loudness (a gentle limiter keeps peaks such as hiccups below -1 dBFS); `tempo` (pitch kept) and `max_pause` speed up the
  Clown (1.15, 0.4 s) and trim Miranda's long pauses (0.45 s); each sound gets its `volume_db`. It needs ffmpeg, which
  `pip install -r requirements.txt` brings (`imageio-ffmpeg`). The manifest records the polish, so a take is never polished
  twice. A new `level` or `volume_db` is applied to the polished take in place, for free, anywhere. The machine that generated
  a take also keeps its raw version in a git-ignored `.raw/` folder, so a new `tempo` or `max_pause` is free there; on another
  machine it means new takes.
- A voice-library voice the API can't find has to be added to "My Voices" on elevenlabs.io first; `--check` says which.
- Takes made in the ElevenLabs app or through Claude's ElevenLabs connector: save them as `audio/voice/<id>.mp3` and run
  `--adopt` (or `--adopt --only <id>`) so the script treats them as up to date and polishes them on the next run.
  `stability: null` in voices.json means the voice's own saved setting, which is what the app and the connector use.
- Plan limits to know: the free account allows 2 generations at once, and the Miranda, Prospero and Lord Tinman library voices
  need the Creator tier or above. An API key must be the secret that starts with `sk_` (shown once when created), not the key's
  ID. The first bad-key or quota error stops the run. `--dry-run` lists anything left to do.
- **Table read:** open `audio/table_read.html` from disk. Pick the quiz answers and the Giant and father outcomes, then play the
  story route, one scene or one line, with captions and sound cues (a line starts 0.9 s after its cue). The story run plays a
  short sample of each fight's shouts for the chosen outcome; a fight's ▶ Scene plays the whole pool. Lines without a current
  take show for reading time, so it works as a script read before any voice exists. Filter by speaker to audition one voice;
  the Fly buzz box loops the flight ambience to judge its level; every sound is listed at the bottom.
- **In the game** (`host/scripts/voice_player.gd`, on branch `neil/game-voices` until Anshul merges it): the Godot court
  reads both manifests from the repo's `audio/` folder (or `host/audio/` if copied in for an exported build) and plays:
  - `{"t":"event","kind":"voice","id":"C01_P4_PROSPERO","speaker":"Prospero","caption":"..."}`: the line, after its `sfx` cue
    (the shape `caption_scroll.gd` already reads, so the caption shows too). A new line cuts off the one playing.
  - `{"t":"event","kind":"sfx","id":"GIANT_SWAT"}`: one sound.
  - `{"t":"event","kind":"dodge"|"hit","fight":"giant"|"father","n":3}`, sent **only when an attack resolves**: that fight's
    sound, then sometimes one shout from its pool (always at a milestone). Without `n` it counts. The keyboard demo sends these.
  - From the state feed, host-side: a role filling up (`H_ROLE_*`), a phone dropping (`H_FAINTED_*`), the True Prince /
    Changeling swap (`H_CHANGELING`, `H_TRUE_PRINCE`), and the quiet flight buzz while the fly moves. Never from sample frames.
  - Nothing on a warning: `{"kind":"giant"}` and the old `H_WARN_GIANT` stay silent.
  The server doesn't send story or fight events yet (TEAM.md, open requests). Only send lines on the route the server chose.
- **The Seer's secret:** no voice line or sound may reveal a hidden hazard's side or timing (GAME.md). Giant, father-fight and crowd
  sounds and the fight shouts are mono and centred, and they play only once an attack resolves (hit or miss), never when the
  warning starts. `FLY_BUZZ_LOOP` sits 18 dB down
  and stops during comics and questions.
- Tests: `python -m pytest audio/tests -q` (both banks are sound, only the final cast speaks, the suitors ask their own questions,
  fight shouts hold no direction or timing word,
  every quiz has both outcomes, generation against a fake ElevenLabs client caches, recasts and survives a missing voice, and
  polishing shortens pauses and runs once).

## Tests

```bash
python -m pytest brain/tests server/tests relay/tests -q
```

```bash
npm test --prefix relay/public
```

- **100 Python tests** (about 2 minutes on a quiet laptop): 68 brain, 14 server, 18 relay. `-m "not slow"` skips the slowest brain tests. Brain tests
  that need `data/` skip with a clear message on a fresh clone.
- **3 JavaScript tests** for the phone modules (role-owned message shapes, private Seer view detection, room codes); they need Node.
- What the brain suite covers: the graph matches the data check; signs follow the transmitter rule; the Changelings keep every
  neuron's input, out-degree and sender signs; 30 s of random play stays bounded; rest is quiet; identical inputs give identical
  outputs; a tick fits the 20 ms budget; every input drives its own target far above all three Changelings and responds within
  80 ms; the Seer's one interface, fallback, sides, no flicker, no Princess/Giant cross-talk, wind, hybrid mode, the HUD privacy
  rule, real-time stepping, server integration and accuracy on fresh scenes; replay and the Chronicler.

**Manual four-phone check** (repeat after big changes):

1. `python run_local.py` (see [Run it locally](#run-it-locally)).
2. Join four phones with the printed link; pick each role once. Each phone shows only its own controller, and the terminal
   prints each `[join]`.
3. Hold each movement button for 3 seconds or more: only that role's axis changes, it keeps moving the whole time (type `s` to
   see the live inputs), and release sends 0.
4. Hold and release scan: `sense` 1 then 0; only the Seer's screen ever shows bearing, distance, confidence or a Giant warning.
5. Background the browser mid-hold: a neutral event goes out; after 1.2 s the input is cleared anyway.
6. Kill one phone's network and restore it: the reconnect overlay appears and the role comes back.
7. Tap-to-latch: tap on, tap off, same messages as hold and release.
8. Portrait at narrow width: every control stays large, labeled and reachable.

## Performance (Neil's M2, 8 GB)

- One brain tick (one 20 ms step of all 166,606 neurons, SciPy sparse, float32): sustained 2.5-minute test, median 5.7 to 6.3 ms,
  p99 mostly 6.4 to 8 ms, rare spikes to about 38 ms. Two 10 ms steps per tick reached p99 20.7 ms, too close to the budget.
- Keep the server on a fixed 20 ms timestep that catches up after a rare slow tick instead of drifting.
- Still to measure: the full stack (relay, server, brain and Godot) together on the demo laptop.

## Setup: the brain's data

The three MaleCNS v1.0 Feather files go in `data/` (git-ignored; public CC-BY 4.0 data, download from
[male-cns.janelia.org](https://male-cns.janelia.org/download/)):

- `connectome-weights-male-cns-v1.0-minconf-0.5.feather` (1.1 GB)
- `body-annotations-male-cns-v1.0-minconf-0.5.feather` (13 MB)
- `body-neurotransmitters-male-cns-v1.0.feather` (42 MB)

```bash
python -m brain.build_graph && python -m brain.changeling
```

The same files are in Janelia's public bucket, which also works where the download page is blocked:
`https://storage.googleapis.com/flyem-male-cns/v1.0/connectome-data/flat-connectome/<file name>`. A fresh build on Sun 27
Sept reproduced every number here, all 68 brain tests, the probes gate and `team/neil/seer_eval.csv`.

Teammates can skip this: ask Neil to AirDrop `data/graph_true.npz`, `data/graph_changeling_{0,1,2}.npz` and
`data/neurons.parquet` (about 90 MB). Check it with `python -m brain.probes --level 1.0` (about 1 minute).

## Data facts (from the pre-event data check)

| Fact | Value |
|---|---|
| Release | v1.0 public since 8 June 2026; Cell paper (Berg et al.) 3 Sept 2026; CC-BY 4.0 |
| All connections / synapses | 25,574,615 / 124,144,950 (median 2 synapses per connection; 40.3% single-synapse) |
| Transmitters | acetylcholine 103,691; glutamate 29,298; GABA 22,053; histamine 7,891; unclear 2,966; dopamine 392; octopamine 101; serotonin 48; missing 166 |
| Pruning | 1+ synapses: 24.5 ms per step (too slow); 3+: 9.0 ms; **5+: 5.3 ms** (the plan) |
| No small subcircuit | Neurons within 3 hops of both the senses and the outputs: 140,223 of 166,606 (2 hops: 37,004). So the whole CNS runs |
| Looming to the Giant Fiber | LC4 to DNp01 6,362 synapses; LPLC2 to DNp01 4,862; JO ear neurons to DNp01 709 |
| Naming | The Giant Fiber is type `DNp01`; pIP10 is its own male-specific type (2 neurons); there is no type named "P1" (P1 sits in the 148 male-specific pC1-cluster neurons) |
| Why a rate model | A spiking whole-brain model took about 42 s per simulated second on this laptop |

These are structural facts; the behavior claims come from the probes and the Seer evaluation above.

## Arnav's comic campaign — implementation planning, not a protocol change

See [GAME.md](GAME.md#story-campaign-and-comic-cutscenes--approved-team-plan) for the full
approved story script. This section is the implementation handoff; interface details still need owner agreement. It adds no working messages,
screens, tests or neural abilities. Coordinate message names with Ved and Anshul before code.

### State the server will need

- Current scene, page/panel, phase (comic, question, ready, active, outcome), and previous result.
- Four unique grape IDs; carried grape or none; delivered set. Count comes from that set.
- Three quiz encounter IDs, pending/committed answer, correct/incorrect result and whether its
  one-time drink effect was applied. Page navigation cannot mutate committed outcomes.
- Dizziness 0–3; stage-entry snapshot; retry count; checkpoint; remaining active-play time.
- Hazard ID, locked path/zone, warning and impact times, resolved flag, hit-or-dodge result;
  Giant dodge/hit counters and father dodge counter. Never count an attack twice.
- Campaign or DEMO mode. Test overrides and revealed positions cannot enter campaign results.

The transition graph and named IDs in GAME.md are authoring labels, not a new relay envelope.
Keep existing room/role identity, reconnect behavior and monotonically increasing input
sequence rules. Send question choices only from the current Seer; validate encounter ID and
reject duplicate, stale, wrong-role or previous-room answers. Persist committed outcomes for
the current session across reconnect. Do not persist personal player data after the session.

### Shared state versus Seer-only state

Shared: phase, comic text/panels, question/options/result, grape/dodge counts, active timer,
steadiness label, fly motion, neutral event feedback, roles and side-free brain activity.
Seer only: hidden obstacle guidance, hazard direction/landing/path assistance and neural cues.
Movement phones get controls and public scene/choice status, never hidden hazard data.

The current coarse neural outputs cannot supply an exact wall map, safe altitude corridor
or validated thrown-object detector. First-version obstacle guidance is scripted and
labeled as such. Keep that separate from measured brain cues. Large hand-attack sectors can
use coarse neural side warnings; if exact help is added, disclose its source. Neil owns
neural changes. No encoding of every object as a Princess merely to make the interface fit.

### Pause, retry and hazard rules

- Pause simulation time for comics, questions, ready screens and a connection pause. Wall-clock
  time alone cannot expire a stage or deliver a paused attack. Stop advancing/sampling live
  Seer stimuli while the world is frozen, and agree resume/reset behavior with Neil's adapter.
- Clear held control/scan state on pause/transition; retain input sequence history. Ignore
  live movement during comics and require a fresh press after ready. A latched phone control
  must not immediately resend its old hold and move the fly behind the comic.
- Stage 1 checkpoints retain delivered tutorial/quiz history; Stage 2 restarts with 60 seconds
  and its entry dizziness. Retry never re-applies a drink, reveals a correct answer again
  as a new choice, or carries an old projectile into the reset scene.
- Giant: ten resolved threatening attacks avoided before three hits. Count a hit once, grant
  recovery, then schedule a new attack. Father: five avoided projectiles before any hit.
- Targets lock at warning onset. Check movement across an update for fast projectile hits;
  do not check only its final point. Resolve final hit/dodge and scene transition together.
- Dizziness changes only explicitly authored movement tuning, not the brain's weights,
  reported measurements or role permissions. Release/disconnect clearing remains reliable.

### Build order (story approved; implementation pending)

1. Agree scene/choice/private-guidance fields with Ved and Anshul; keep current live loop working.
2. Add pure campaign state, transition/choice persistence and table-driven tests without art.
3. Make tutorial grapes and the reusable comic/question flow work end to end.
4. Add reusable course collision/checkpoints, then Stage 1 and Stage 2 timer/private hazards.
5. Reuse attacks for ten-dodge Giant; add the small projectile variant for Prospero; wire endings.
6. Add isolated Demo presets and run all story paths with 0/1/2/3 dizziness levels.

Accept only after verifying: one quiz effect per encounter; no stale input across panels;
reconnect cannot answer twice; Stage 2 clock pauses correctly; maximum dizziness leaves safe
routes; hidden data absent from shared messages and directional sound; 10th dodge/3rd hit
choose exclusive outcomes; father 5th dodge stops future shots and one hit loses; Demo cannot
award campaign progress; missing audio never blocks a panel. These tests are proposed, not run.
