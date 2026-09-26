# Fly by Committee: Steps 1 to 5 for the party co-op (as delivered, Sat 26 Sept 2026)

> Record only. The team's request: "We decide on the party co-op game where each player is one of the fly's senses and everyone
> has to work together. We can create some sort of jackbox-like feature where people enter codes from a main screen."
> The game was later reskinned for the royalty theme ([03_royalty_reskin.md](03_royalty_reskin.md)). The living plan is in `docs/`.

I ran some checks on your local MaleCNS files before writing this, and one result changes the plan.

## What the data check changed

- **You don't need to cut out a subcircuit. The whole male CNS can run live.** Take every neuron within three strong connections of both a sense neuron and a movement neuron, and you already have at least 140,000 of the 166,606 neurons. So there's no small circuit to extract. But the whole graph is fast enough:
  - Keeping only connections with 5 or more synapses leaves 6.24M connections, which carry 72% of all synapses.
  - One simulation step on your M2 takes **5.3 ms**.
  - Keeping every connection takes 24.5 ms per step, which is too slow to run live.
- **The key paths are in the wiring:**

| Path | Synapses |
|---|---|
| LC4 (looming detectors) to the giant fiber (DNp01), direct | 6,362 |
| LPLC2 (looming detectors) to the giant fiber, direct | 4,862 |
| JO ear neurons to the giant fiber, direct | 709 |
| Foreleg ppk23 taste neurons (71 of them) to all 6 vAB3 ascending neurons, direct | (direct link confirmed) |
| vAB3 to the pC1/P1 courtship cluster | 1,322 |
| That cluster to pIP10, the male-only song command neuron | 1,941 |
| LC10a (the neurons males use to chase females) to DNa02, the steering neuron, direct | **0** |

  LC10a's signal has to go through a relay neuron to reach steering. So "will the model steer?" is the first thing to test.
- **Naming traps:** no cell type is called "P1". P1 is somewhere among the 148 male-specific pC1-cluster neurons. vAB3 is listed as AN09B017e/f/g.

---

## Step 1: The Visionary

**Core concept.** One male fruit fly, one main screen, four phones. Each phone is one of his senses: Eyes, Nose, Feet or Ears. Each phone shows only what that sense can detect. Nobody controls his legs. His real, fully mapped nervous system decides what to do with whatever you let through. The goal is to get him to a female and make him sing before the swatter comes down.

**Why the brain is the heart of it.** We don't hand-pick neurons. All 166,606 neurons of the MaleCNS graph run every tick. The funny moments in the game come straight from wiring we can point to:
- When the Eyes player holds an eye open as the swatter looms, he jumps. That's because LC4 and LPLC2 connect directly to the giant fiber.
- When the Feet player taps her, the signal climbs his leg, goes up the neck through vAB3, into the courtship cluster, and back down through pIP10 to the wings.

**Agents.** Three agents, and each one calls the brain simulation as a tool:
- **Director:** designs each "date": the arena, her route, the rival male, the swatter schedule and a title.
- **Playtester:** plays each date with bot players on the real brain and on a shuffled brain. It only certifies a date if the bots win with the real wiring and mostly lose with the shuffled one. Otherwise it sends the Director a specific revision request.
- **Referee:** after each round, replays it with each player's sense switched off, and tells each person how much of the fly's behavior was actually theirs.

**Why now.** The wiring the game needs only exists as one graph in a male CNS:
- FlyWire is a female brain.
- BANC is a female brain plus nerve cord.
- MANC is a male nerve cord without the brain.

MaleCNS v1.0 has been public since June 8, and the Cell paper came out Sept 3. It's the first dataset with a male brain and nerve cord from the same animal. The Feet-to-song loop crosses the neck twice and runs through pIP10, which is male-specific. Before MaleCNS, you'd have had to stitch that loop together from different animals.

---

## Step 2: The Game Designer

**Verb: signal.**

**Core loop (one date takes about 90 seconds):** join, pick a sense, then find her, get close, tap, and sing. Then the Referee's reveal on the main screen and every phone, then the next certified date, which is a bit harder.

**The four senses**

| Sense | What the phone shows (only this player sees it) | Controls | Real input neurons | What it can make him do |
|---|---|---|---|---|
| **Eyes** | Left and right eye views, drawn as blurry hex pixels | Hold LEFT and/or RIGHT eye open | LC10a (275), LPLC2 (185), LC4 (126), split by side | Turn and walk toward her; jump when something looms |
| **Nose** | Scent levels at each antenna (scent plumes are hidden on the main screen) | Hold LEFT and/or RIGHT antenna to sniff | ORN_VA1v (Or47b, courtship scent, 130), ORN_DM1 (Or42b, vinegar, 74), ORN_DA1 (Or67d, rival male's cVA, 204) | Get him interested; kill the mood if he sniffs the rival |
| **Feet** | A contact pad that lights up when his forelegs touch her | Tap in rhythm while touching her | Foreleg ppk23 (71) | Drive the courtship cluster and trigger the song |
| **Ears** | A meter for wind and sound | Hold to listen | JO-A/B (sound), JO-C/E (wind) | Hear the swatter's whoosh and start the jump in time |

**Where the tension comes from.** Every open sense sends real data into the brain, including data you don't want in there:
- If the Eyes player keeps the left eye on her while the swatter comes in from the left, he jumps and loses his spot.
- If the Nose player sniffs on the wrong side, he gets a nose full of the rival's cVA and loses interest.

So players end up shouting things like "Close your left eye!" and "Don't sniff, Kevin's over there!" That's the game. Nobody's input is enough alone, and the brain settles every argument.

**Joining (the Jackbox part):**
- **The code.** The main screen shows a 4-letter room code in huge type, a QR code, and a short URL. Codes use consonants only, so they can't spell words.
- **Joining.** On their phone, a player enters a name and the code, then taps a sense icon, or "Surprise me." Senses are first come, first served.
- **Player counts:**
  - 1 player: keyboard mode.
  - 2 players: Eyes+Feet and Nose+Ears.
  - 3 players: Eyes, Nose, and Feet+Ears.
  - 4 players: one sense each.
  - A 5th person and beyond joins the audience (stretch goal).
- **Reconnecting.** Phones go to sleep. Rejoining with the same name gets you your sense back. If a sense drops, the game pauses for 5 seconds.
- **Between dates.** Each phone shows personal Referee stats, for example "You caused 41% of his turning" or "Your sniff at 0:47 ended the romance." Those numbers are examples; the real ones always come from the Referee's calculations.

**The first 30 seconds:**
- **0 to 10 s:** Players join. Each phone flips to a sense card with a big icon, a color and one sentence, like "You're the EYES. Hold the side you want him to look at."
- **10 to 20 s:** The tutorial date starts, with no hazards. The host line says "EYES: she's on the left." The fly turns and walks. The "neck panel" beside the arena lights up from LC10a down to the steering neurons.
- **20 to 30 s:** He touches her. The Feet phone flashes TAP TAP TAP. His wings buzz, the pIP10 bar lights up, and hearts appear.

**Win and fail:**
- **Win:** he sings (pIP10 above his resting level) near her and facing her for 5 seconds in total, within 90 seconds.
- **Fail:** he gets swatted (SPLAT), the clock runs out, or she wanders off.
- **Game structure:** three dates per game (Kitchen Counter, Fruit Bowl, Picnic), each with a star rating.

**Lessons borrowed:**
- **PEAK:** the fun is in shared chaos and funny failure. The difference: PEAK gives every player their own body. Here all four share one body, and nobody controls where it goes.
- **Mage Arena:** a new kind of input can be the whole hook. Here your phone is literally one sense organ. The difference: your input isn't carried out directly. It goes through a nervous system that can ignore it or misread it.

**Art that a team without an artist can pull off:**
- **The fly:** drawn in the style of an old entomology plate (ink outlines, flat colors). The female uses the same sprite with a different palette.
- **The arena:** top-down flat shapes.
- **The neck panel:** brain at the top, neck in the middle, nerve cord at the bottom, with glowing bars for each sense's input neurons and for the output neurons (DNa02 left/right, DNp09, DNp01, pIP10).
- **Sense colors:** Eyes teal, Nose amber, Feet coral, Ears violet. Every color always comes with an icon, so no information depends on color alone.
- **The Eyes phone view:** just the arena render pixelated into hexes. It's cheap to make and looks great.

**Accessibility:**
1. **Hold-to-toggle mode:** any hold button becomes tap-on, tap-off, for players who can't keep a finger pressed.
2. **Senses you can play without the screen:** Nose and Ears get full audio versions. Nose uses stereo pitch for scent strength on each side. Ears plays the whoosh through the phone speaker. A blind or low-vision player can fully play either sense. (This is where the Buzzkill idea from Phase 0 ended up.)

---

## Step 3: The Realist

**What's unrealistic, and what gets cut:**
- **Real spiking dynamics.** We run a rate model with assumed signs and one tuned gain, and we say so.
- **Steering straight from the wiring.** It's unknown until we test it, because LC10a has no direct line to DNa02. It gets a GO / HYBRID decision at 17:00 (details below).
- **Things cut to stretch goals:** the flybody 3D body (we use a 2D body), the female brain (the female is scripted), audience mode, LLM-written host lines, and bundling the Python server into an installer (a run script is fine).
- **LLMs in the live game loop.** None. The live game never waits on an API call.

**Architecture**

```
[phones: plain web page]  <->  [relay: small cloud WebSocket server, rooms + codes, serves the phone page]
                                     ^  laptop connects OUT as "host" (works on any Wi-Fi)
                                     v
                     [game server, Python, on the laptop]
                       - arena + 2D body, 50 Hz
                       - brain: whole MaleCNS rate model, REAL or SHUFFLED
                       - Referee: 4 "shadow" copies of the brain (each re-runs the round with one sense switched off)
                       - Level Lab: Director + Playtester (Claude API), between rounds and overnight
                                     ^  local WebSocket, state at 30 Hz
                                     v
                     [Godot 4 host: main screen, room code, QR, neck panel, sound]
```

- **Why Python owns the game state and Godot only draws it:** the Playtester and the Referee have to replay rounds headless, many times, without Godot running.
- **Why a cloud relay instead of a local server:**
  - Venue Wi-Fi often blocks devices from talking to each other. Everyone connecting outward to the relay gets around that.
  - Measure the latency in hour 1. Hold-buttons are forgiving of a little lag.
  - Fallback 1: LAN mode, with the laptop serving the page over a phone hotspot.
  - Fallback 2: keyboard mode.
- **Vibration only works in Android browsers,** so every haptic also needs a visual flash.

**Data flow on each tick (50 Hz):**
1. Phone events come in through the relay.
2. The server builds input only for senses that are open, using what's really in the arena on that side.
3. The brain runs two 10 ms steps (about 11 ms of compute).
4. The server reads the output neurons, measured against their own resting levels.
5. The server updates the body.
6. State goes to Godot, and each phone gets its own private view (10 to 20 Hz).

**The brain model**
- **Update rule:** `r ← r + (dt/τ)(−r + clip(g·W·r + I − θ, 0, 1))`.
- **Weights:** W = synapse count × sign, including only connections with 5 or more synapses.
- **Signs:** acetylcholine excitatory; GABA, glutamate and histamine inhibitory.
- **Neuromodulators:** dopamine, octopamine and serotonin neurons (541 total) are silenced, because the wiring diagram can't say what they do.
- **Unclear transmitters:** 2,966 neurons have an "unclear" transmitter prediction. They default to excitatory, and we flag that.
- **Gain g:** tuned in hour 2 so the brain settles at rest and sensory pulses give bounded, readable output. The same g is used for the shuffled brain.
- **Body mapping (our code, stated openly):**
  - turn = DNa02 right minus left
  - walk forward = DNp09 + DNg100
  - back up = MDN
  - jump = DNp01 crosses its threshold
  - wings out and buzzing = pIP10 crosses its threshold

**The shuffled brain (the ablation toggle).**
- Randomly reassign the sending neuron of every connection among sending neurons of the same sign. Each connection's receiving neuron and synapse count stay fixed.
- Every neuron keeps exactly the same total input and the same excitatory/inhibitory mix. Every neuron keeps the same number of outgoing connections. Only who talks to whom changes.
- This avoids the "random brain explodes" problem from your earlier spike tests, which judges would otherwise call rigged.
- Precompute three random versions. The toggle swaps the matrix while the game runs.

**Agents** (using `claude-opus-5` through the Anthropic Python SDK):
- **Director:** uses structured outputs with a Pydantic `Date` schema, so every date parses. The schema covers her route, scent sources, the rival's route, the swatter schedule (including fakes), the time limit, a title and a flavor line. The Director's input includes the Referee's note on which sense the last team neglected, so the next date leans on that sense.
- **Playtester:** uses strict tool definitions:
  - `run_trials(date, brain, n)` returns the win rate plus a failure reason per trial, for example "SPLAT at 31 s, ears closed, DNp01 never crossed."
  - `get_trace(trial)` returns a timeline of output-neuron events.

  **Certification rule:** bots must win 30 to 80% of the time with the real brain, and at least 25 points more often than with the shuffled brain. Each date gets at most 3 revision rounds.
- **Bots:** scripted players that see exactly what the phones show.
- **Referee:** code, not an LLM. It replays the recorded inputs with one sense set to zero and measures how much steering, jumping and singing changed. The four shadow brains run on separate cores during the round, so the reveal is almost instant.
- **Budget:**
  - One 90-second trial is about 48 seconds of compute per core, so certifying one date takes about 3 minutes on 6 worker processes.
  - Batch-certify around 15 dates overnight.
  - Memory for 5 brain copies stays under about 1.5 GB.

**Hour-by-hour.** The Brain role goes to Neil (he knows the dataset). The other three pick among the remaining roles. The presenter isn't Neil, same as your old plan.

| Time | Brain (Neil) | Server + agents | Phones + relay | Godot host |
|---|---|---|---|---|
| 12:00-14:00 | See "First 2 hours" below | | | |
| 14:00-17:00 | Test all 4 senses, real vs shuffled; tune | Put the real brain in the loop; round state machine; win/fail | Haptics, reconnect, LAN fallback, merging senses for 2 or 3 players | Neck panel with live output bars; wing buzz, jump and splat |
| **17:00** | **GO / HYBRID decision + first playable, end to end** | | | |
| 17:00-19:00 | Fixes, dinner | | | |
| 19:00-23:00 | Live real/shuffled swap; record and replay input streams | Swatter, rival, scent plumes; Referee v1; bots | Real sense views: Eyes hexes, Nose meters, Ears meter, Feet pad | Reveal screen, Level Lab screen, sound |
| **23:00** | **Hand the phones to 4 strangers and watch what confuses them** | | | |
| 23:00-03:00 | Parallel `run_trials`, trace summaries | Director + Playtester loop, certification rules | Accessibility modes | Tutorial prompts, polish, honesty panel |
| **03:00** | **Fallback checkpoint** | | | |
| 03:00-07:00 | Batch-certify dates; sleep in 2-hour shifts | Same | Same | Same |
| 07:00-09:00 | Backup demo video, screenshots, Devpost draft, README | | | |
| 09:00-11:00 | Feature freeze at 09:00. Rehearse the demo 5 times. Test joining from fresh phones on venue Wi-Fi | | | |
| 11:00-12:00 | Submit: public repo, Devpost, video. Buffer time | | | |

**Biggest risk: the brain doesn't give controllable behavior.** Decide at 17:00 using three tests:
1. **Looming makes DNp01 fire.** This should be easy, given 11,000+ direct synapses.
2. **Foreleg tapping pushes pIP10 clearly above its noise within about 1 second, and doesn't in the shuffled brain.** This is the heart of the game. If it fails:
   - First, re-tune the gain or include connections with 3 or more synapses along that path.
   - If it still fails, the song trigger moves one step earlier, to the pC1 cluster, and we say so openly.
3. **Opening the eye on her side moves DNa02 left versus right the right way, at least twice as much as in the shuffled brain.** If it fails, switch to hybrid steering:
   - The brain still decides whether he goes, jumps, stops or sings.
   - Code turns him toward whichever open sense's stimulus is strongest.
   - The honesty panel says so.

The Nose is the furthest sense from any movement neuron (3 or more hops), so it may feel weak. If it does, its main job becomes raising or lowering the courtship cluster.

**3 AM fallback:**
- Whatever steering works by 3 AM ships, hybrid or not.
- If the relay is flaky, switch to LAN mode on a hotspot.
- If phones fail completely, 4 players share one keyboard.
- If the agent loop isn't done, ship the dates certified so far and show the Level Lab log from the batch.
- Never hard-code a behavior and credit it to the brain.

---

## Step 4: The Pitchman

**Name: Fly by Committee.** It's exactly what the game is, it sounds like a Jackbox title, and it quietly keeps your team name (Fly-by-Wire).

**One-liner:** "Four friends, four senses, one real fly nervous system: get him to his date before the swatter gets him."

**Target players:** groups at parties and hackathons, and intro biology or neuro classes. A teacher puts the room code on the projector, four students play, and the rest of the class watches the neck panel.

**Why it matters for education:** it teaches the core idea in neuroscience that behavior comes from combining senses, not from any one of them. You learn it by being one of those senses. The ablation toggle also teaches what a scientific control is.

**Demo script (3 minutes):**
- **0:00 to 0:15, the hook.** "This is the entire nervous system of a real male fruit fly, 166,000 neurons, published this month. We split his senses between you." Judges scan the QR code. Four team phones are already joined as a backup.
- **0:15 to 0:45, the tutorial date.** He turns, walks, touches her. The Feet judge taps, and his wings buzz. "That buzz is pIP10, a male-only neuron. Your tap went up his leg, through his neck to his brain, and back down."
- **0:45 to 1:30, date 2.** The rival male and the swatter show up, and people start shouting. He jumps: "That's thousands of direct synapses from his looming detectors to the giant fiber."
- **1:30 to 1:55, the Referee reveal.** The main screen names the MVP sense. Every judge's phone shows their own numbers.
- **1:55 to 2:25, the lean-in moment.** Flip REAL WIRING to SHUFFLED WIRING. "Same neurons, same number of connections, same input to every neuron. Only the partners are random." Replay the same date and watch the fly stop making sense of the team. Then put up the Playtester's certified numbers: [real win %] vs [shuffled win %], filled in from real results only.
  - If the shuffled fly doesn't look obviously different in live play during testing, lead this beat with the bot numbers instead.
- **2:25 to 2:50, the Level Lab.** Scroll the agent log: "Director proposed a date. Playtester rejected it because the shuffled brain won too often. Director revised it. Certified."
- **2:50 to 3:00, the honesty line.** "The connection counts are real. The strengths and signs are our assumptions, and the walking is our code. The wiring decides what he does, and you just felt it."

**Tracks to enter:**
- Best Design Hack
- Most Engaging Demo (if offered)
- Best AI/ML Hack (the agent loop plus a whole-CNS simulation)
- Best Educational Hack, as a second choice
- The MLH .Tech domain prize, using the domain for the join URL
- Recheck the 2026 prize list at the opening ceremony.

---

## Step 5: Final consensus blueprint

| | |
|---|---|
| **Name / one-liner** | Fly by Committee. Four friends, four senses, one real fly nervous system. |
| **Genre / verb** | Party co-op (1 to 4 players on phones) / **signal** |
| **Core loop** | Join by code, pick a sense, then find her, touch her, sing; Referee reveal; next certified date |
| **Fly brain's role** | All 166,606 MaleCNS neurons run live as a rate model. Only open senses feed it. Output neurons drive the body |
| **Agents** | Director (designs dates), Playtester (certifies them against the real and shuffled brains), Referee (per-player credit from the shadow brains). The Referee's stats feed the Director's next brief |
| **MVP** | Jackbox-style join and reconnect; 4 senses (Ears is the first cut); tutorial + 2 dates; swatter + rival; real/shuffled toggle; Referee reveal; about 15 certified dates; honesty panel; 2 accessibility modes |
| **Stretch goals** | Swap in the female nervous system (BANC) as the player fly, so there's no pIP10 and no song (needs the density normalization); audience voting; flybody 3D; LLM host lines; installer build |
| **Honesty statement (Devpost)** | "We run the MaleCNS v1.0 wiring diagram (Berg et al., Cell 2026, CC-BY 4.0) as a simple rate model. Connection counts are real. Everything else is an assumption: strength scales with synapse count under one tuned gain; signs come from predicted transmitters; neuromodulators are left out; connections under 5 synapses are dropped. Real neurons have dynamics, modulation and learning that this model doesn't. The mapping from descending neurons to movement is our code, and the female is scripted. It shows what this wiring does under these assumptions, not what a living fly would do." |
| **Risks** | Controllability (17:00 decision), venue network (relay plus two fallbacks), scope (Ears and agents are cuttable) |

---

## First 2 hours (12:00 to 14:00)

**Repo** (create it fresh and public at 12:00):

```
fly-by-committee/
  README.md              honesty statement, run instructions
  brain/                 build_graph.py  shuffle.py  sim.py  probes.py  io_sets.json
  server/                game server: arena, body, rounds, websockets
  agents/                director.py  playtester.py  referee.py  bots.py  schema.py
  relay/                 relay server + public/ (phone page, one JS file per sense)
  host/                  Godot 4 project
  levels/                certified date JSONs
  data/                  .gitignored; README with download links + checksums
```

**Who does what:**
- **Brain (Neil):**
  - First hour: write `build_graph.py` from the raw Feather files. It keeps connections with 5 or more synapses, applies signs, silences modulators, and saves a compressed sparse-matrix `.npz` file (about 50 MB). Also write `io_sets.json` with every sense and output group from the tables above, split by side.
  - Second hour: write `sim.py`, sweep the gain, write `shuffle.py` (3 random versions), and run the first two probes: looming to DNp01, and foreleg taps to pIP10, each on the real and shuffled brains.
  - By 14:00: a printout of both probes.
- **Server + agents:**
  - First hour: a 50 Hz tick loop with a FakeBrain that returns random output levels, a 2D arena and body, and a state feed to Godot.
  - Second hour: the round state machine, the Pydantic `Date` schema, and a hand-made tutorial date.
- **Phones + relay:**
  - First hour: rooms, codes, joining, reconnecting by name. Deploy the relay and test 4 phones on venue Wi-Fi *and* on cellular.
  - Second hour: the join screen plus four sense controllers with big buttons, sending events only when something changes.
- **Godot host:**
  - First hour: the main screen layout (arena, code, QR, neck panel placeholder) reading state from the server.
  - Second hour: the lobby (who joined which sense), a rotating fly sprite, and a key bound to the real/shuffled toggle.
- **14:00:** a 10-minute sync on the probe results.

**Which subgraph to extract first:** none. Build the input/output neuron lists first (`io_sets.json`), because every other part depends on them.

**Download and set up before noon if there's time, otherwise first thing:**
- **Data, on two laptops plus a USB stick:** the three MaleCNS Feather files (1.1 GB connections, 13 MB annotations, 42 MB transmitters).
- **Software:** Godot 4; a Python environment with numpy, scipy, pandas, pyarrow, websockets and anthropic.
- **Accounts:** a relay host account and an API key.

Downloading data is allowed before the event, but code isn't. The numbers above came from scratch checks I ran outside any repo, so rebuild the graph at noon with fresh code. Don't copy anything from fly-cns-sim.

**Outcome:** the event theme was announced as royalty, and the team asked to reskin the game. See [03_royalty_reskin.md](03_royalty_reskin.md).
