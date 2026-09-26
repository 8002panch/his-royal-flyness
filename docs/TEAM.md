# Team: who does what, status, schedule and rules

Updated Sat 26 Sept 19:25 by Neil. The game: [GAME.md](GAME.md). The system and how to run it: [TECH.md](TECH.md).
These three files are the whole plan; earlier docs (the four-senses design, the build plan, the per-person task lists) were merged
here and are in git history. **Please keep it to three docs:** add to the right section instead of creating new markdown files.

## The team

| Person | GitHub | Role | Owns (only edit your own files) |
|---|---|---|---|
| **Neil** | `8002panch` | Brain + science: the Seer's sensory decoder, True Prince vs Changeling, the Royal Decree and lore facts. Science Q&A at judging (not the presenter) | `brain/`, `server/chronicler.py`, `agents/run_trials.py`, `agents/bots.py` |
| **Arnav** | `arnavp-1` | Game server: three-axis body, world and hazards, trial loop, Godot state. Integration lead at every gate | `server/` (except `chronicler.py`), `agents/schema.py`, `levels/` (hand-made), `run_local.py` |
| **Ved** | `shahved25` | Relay and phone controllers, rooms and reconnect, the Seer's phone screen, cloud and domain, agents. Devpost submitter | `relay/`, `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py`, `levels/` (generated) |
| **Anshul** | `darkspaz-v1` | Godot host: the first-person 2D hall, art, hand-shadow effects, HUD, audio and captions. Demo video; timekeeper at check-ins | `host/`, `audio/` |

Docs are shared: edit your own section here, and the parts of GAME.md and TECH.md about your component. `team/<name>/` is each
person's work folder (scratch, figures, results). Presenter: Arnav, Ved or Anshul (decide by 09:00 Sun).

## Implementation status

**For Codex and other agents running Ved's phase prompts:** when a prompt says "update IMPLEMENTATION_STATUS.md", update this
table and add an entry to the phase log below instead. The protocol that prompts call `relay/PROTOCOL.md` is now TECH.md, "Protocol".

| Phase | What | Owner | Status |
|---|---|---|---|
| 0 | Foundation: architecture boundary, blank `.env.example` | Ved | **Done** (PR #1) |
| 1 | Relay: rooms, roles, reconnect, `seq` validation, 1.2 s stale input, Seer-only routing | Ved | **Done** (PR #2), 10 tests |
| 2 | Four phone controller screens, tap-to-latch, reconnect overlay | Ved | **Done** (PR #3, fix PR #5), 3 JS tests. Not yet tried on physical phones |
| 3 | Authoritative x/y/z movement graybox; placeholder Seer; 50 / 30 / 10 Hz loops | Arnav (built with Ved's playbook) | **Done** (PR #4), 6 tests |
| 4 | Godot first-person 2D graybox driven by live state; one-command local launch | Anshul (launcher: Arnav) | **Launcher done** (`python run_local.py`, Sat 19:25) and it opens a **browser host screen** (lobby with room code, QR and seats; live roster and brain bars), a stand-in until the Godot screen is merged. Godot project + HUD on `anshul/host-seer-hud` (not merged); pixel-art direction chosen |
| 5 | Playable Garden trial: phases, win by alignment, lose on Giant / timeout / overshoot, real and fake Giant warnings, keyboard fallback, host restart | Arnav | Not started |
| 6 | Brain-backed Seer in the server, `brainActivity` to Godot, Decree wording | Neil | **Done** (Sat 19:25): the server runs the real brain by default (placeholder if `data/` is missing), sends `brain` and `brainActivity` to Godot, host toggle for the Changeling. Decree already updated |
| 7 | DigitalOcean + Caddy + domain, polish, demo runbook | Ved, everyone | Not started |
| Audio | ElevenLabs voices, sound effects, music (GAME.md) | Anshul | Not started |
| Agents | Matchmaker, Master of Trials, Jester | Ved (+ Neil `run_trials`) | Not started; first thing to cut |

**Brain (Neil), done:** whole-CNS rate model (166,606 neurons, about 6 ms per tick); three fair Changelings; all 10 button
channels pass; the Royal Seer (neural, hybrid and placeholder modes, safe fallback, real-time stepping, side-free HUD activity);
True Prince vs Changeling evaluation (GAME.md, TECH.md); Chronicler and replay; 68 brain tests. Full suite: 92 Python tests pass.

### Phase log

- **Phase 0 (Ved):** architecture boundary and secret template; no runtime code.
- **Phase 1 (Ved):** `relay/relay.py` with isolated four-letter rooms, one host per room, at most four phones, unique roles,
  reconnect restore, monotonic `seq`, 1.2 s stale-input clearing; state and two-client network tests.
- **Phase 2 (Ved):** no-build vanilla JS phone app (join, role pick, restore, reconnect overlay, heartbeats), one screen per role,
  touch safety (release, cancel, lost capture, page hide, socket close all neutralize input), tap-to-latch. Limitation: relay and
  static page run as two local processes until Caddy; not yet exercised on four physical phones.
- **Phase 3 (built with Ved's playbook, Arnav's files):** deterministic bounded x/y/z body, 50 Hz tick, 30 Hz Godot feed on port
  8765, 10 Hz phone feedback, placeholder Seer with a graybox world, four-real-client integration test, deterministic replay.
  Limitation: graybox world only (one Princess, a periodic test Giant); trials, collisions and scoring are Phase 5.
- **Brain (Neil), Sat 15:45 to 19:10:** graph, model, Changelings, controls matrix, the Seer, evaluation, Chronicler, tests.
  Sat 19:05: the Seer's HUD activity keys changed to `vision`, `looming`, `escape` (no left/right: a side bar on the shared screen
  gave away the Princess's side) and extra `sense()` calls within one tick now return cached cues.
- **Join flow connected to the game (Neil, Sat 19:25, at Ved's request):** tested live with scripted phones and the real phone page.
  Fixed: (1) every held button and the Seer's scan died after 1.2 s, because phones sent one message per press and heartbeats
  stop at the relay; the phone now resends a held control every 0.4 s; (2) the phone page rebuilt its buttons 10 times a second,
  which can drop or stick a hold on a phone; now only the readouts update; (3) a phone disconnecting mid-hold never cleared the
  server's input (the relay addressed it to no room); (4) a phone dropping while the server sent it a view crashed the server's
  relay connection, and every drop printed a traceback; (5) Godot got about 15 frames a second with the brain running; fixed-rate
  schedules give a steady 30. Added: `run_local.py` (relay + phone page + server, room code, join link and QR, host keys, join and
  leave log), `?room=` join links, the real brain in the server by default, `room`, `joinUrl`, `brain` and `brainActivity` in the
  Godot state. 6 new tests. Sat 19:35: `run_local.py` also opens the browser host screen (room code, QR, seats), explains a busy
  port, and the state has `players`; 2 more tests.
- **Neuron audit (Neil, Sat 19:55):** checked the Seer inside the game's own hall, not just random test scenes. Fixed: (1) the
  distance cue said NEAR from 69 to 464 cm and never FAR (a 150 cm scale in a 5 m hall, and both eyes summed, so "ahead" read as
  "closer"); now the stronger eye decides, the server sets a 100 cm scale, and the bands track distance; (2) the Changelings' weak
  noise crossed the old detection bar (1.5 z on the summed eyes), producing chance-level guesses; the bar is now 3 z on the
  stronger eye (about 10x resting noise) and the Changelings report nothing; (3) the phone showed Giant warnings from level 0.05
  while the evaluation counted from 0.3; both use 0.3 now; (4) the test world never put the Princess behind the fly and let the
  hand pass through it (to 15 cm); fixed; (5) HUD labels now say what's measured. New numbers: True Prince 54/60 found, 53 sides,
  60/60 Giants, 1.20 s lead; Changelings 0/60 on everything. In the hall: 116/120 sides, Changelings 0. 92 tests pass. Verified in the browser: a 3 s hold stays held on the server for 2.96 s; the Seer's phone shows brain
  cues (bearing, distance, a Giant warning counting down from 1.4 s).

## Open requests: who is waiting on whom

Updated Sat 19:25. Reply by editing this section (or tell the person). If there's no answer by the time shown, build against the
proposal.

### Waiting on Neil

Nothing is blocked on Neil right now. On request: the data files for anyone running the real brain (AirDrop, about 90 MB).

### Neil is waiting on

| From | What | Needed by | Proposal if no answer |
|---|---|---|---|
| **Arnav** | Are `run_trials` and bots still wanted now that players move the fly directly? If yes: a headless trial step to import | 21:00 | Paused; Neil works on the demo-laptop speed test and Phase 6 support instead |
| **Everyone** | Keep the Chronicler? With direct movement it can only credit the Seer | 20:00 check-in | Drop it from the demo; keep the code |
| **Everyone** | Whose laptop runs the demo (for the full-stack speed test) | 20:00 | Neil's M2 |

### Between others (seen in branches and notes)

| From → to | What | Status |
|---|---|---|
| Anshul → Arnav | Add `brainActivity` to the Godot state; wire the real Seer | **Done by Neil** (Sat 19:25): `brainActivity` (keys `vision`, `looming`, `escape`), `brain`, `room` and `joinUrl` are in the state, sensed once per tick |
| Anshul → Arnav | `"controls"` (each axis's live value) for the HUD's axis bars | Waiting on Arnav to pick a format; `roles` (input non-zero) and `fly` velocities are there meanwhile |
| Neil → Arnav, Ved | Heads-up: Neil edited your files to connect the join flow to the game (see the phase log): `server/main.py` (sensing, state fields, fixed-rate loop, `--seer`), `relay/relay.py` (disconnect clear, dropped-phone handling), `relay/public/app.js` (0.4 s resend, readout-only updates, `?room=` links), plus tests. Pull before you change these files | Please pull |
| Neil → Anshul | Neil added `host/web/index.html` (a browser host screen: lobby with the room code, QR and seats, then a live roster and brain bars) so the game can be run and shown before your Godot screen merges. `host/web/.gdignore` keeps Godot from importing it. Keep it as the lobby, restyle it, or replace it; it reads the same state feed, now with `players` (role to name) | FYI |
| Neil → Arnav | Movement feels very fast in the graybox: holding a direction crosses from the center to the wall in about 1 s (max speed 1.0 in a [-1, 1] box). Worth tuning with Phase 5's world scale | Your call |
| Neil → Arnav, Ved | With a remote relay (DigitalOcean), the server doesn't reconnect if the relay connection drops; it needs a retry loop before Phase 7. The in-process relay in `run_local.py` doesn't have this problem | Before deploying |
| Anshul → everyone | The `brainActivity` example in the planning repo's redesign (`vision`/`looming`/`motor`) doesn't match the code | Resolved: TECH.md has the real keys |
| Neil → Anshul | When you merge `main` into `anshul/host-seer-hud`, git reports modify/delete conflicts on `host/README.md`, `team/anshul/README.md` and `team/arnav/README.md`. Their content (your status and notes) is now in this file and GAME.md, so resolve with `git rm` on those three. The pixel-art concept is summarized in GAME.md, "Art direction"; please extend that section rather than adding new .md files (the Claude prompt file can live in `team/anshul/`) | Please do at your next merge |
| Neil → Ved | Codex phase prompts: record status in this file (see "Implementation status"); the protocol is in TECH.md | Please pass to your Codex runs |

## Next tasks (by person)

From the redesign's ownership table and Ved's phase playbook. Owners, edit freely.

**Neil**
- [x] Brain, Changelings, Seer adapter, evaluation, tests, Decree, fact checks, HUD privacy fix.
- [ ] If not done yet: tell an organizer what was prepared before the event (plans and a data check, no code).
- [x] Connect Ved's join flow to the game mechanics (Phase 6 wiring, launcher, hold and disconnect fixes).
- [ ] AirDrop the data files to whoever runs the demo laptop; check that the Decree matches what ships.
- [ ] Full-stack speed test on the demo laptop (relay + server + brain + Godot together) once Phase 4 runs.
- [ ] `run_trials` + bots only if Arnav says yes.
- [ ] On hold until the team says: Devpost science section; Q&A drill with the presenter (GAME.md).

**Arnav**
- [x] Phase 4 launcher and Phase 6 wiring (done by Neil: `run_local.py`, the real Seer, `brain` and `brainActivity`, host toggle).
- [ ] Phase 5: the Garden trial (phases, alignment win, Giant / timeout / overshoot losses, real and fake warnings, keyboard
      fallback, host start and restart), plus `controls` in the state message; tune the movement speed.
- [ ] A reconnect loop for the relay connection (needed before a remote relay).
- [ ] README "Run it" check from a clean checkout on the demo laptop; test the LAN and keyboard fallbacks.

**Ved**
- [ ] Four physical phones on venue Wi-Fi with `python run_local.py` (TECH.md, manual check).
- [ ] Phase 7 prep: Caddyfile, deployment steps and a health check (deploy only with the team's approval and credentials);
      claim DigitalOcean credits and the domain coupon.
- [ ] Devpost: create the draft and add all four members before Sunday (create deadline 11:00); you submit.
- [ ] Recruit four strangers for the 23:30 test.
- [ ] Agents only if everything above is done.

**Anshul**
- [ ] Phase 4: the hall in layers, x/y/z as screen shift, height and scale, Miranda, the hand shadow, candle timer, role
      indicators, the HUD; then merge `anshul/host-seer-hud`.
- [ ] Pixel-art reskin (GAME.md, "Art direction"): nearest-neighbor, no baked-in actors, versioned assets.
- [ ] Audio: claim the ElevenLabs code; library voices; the lines in GAME.md; sound effects and music; captions.
- [ ] Demo video (at least 30 s, aim 90) by 08:00 Sun and five screenshots for Devpost; timekeeper at check-ins.

## Schedule (Sat 26 to Sun 27 Sept, EDT)

| When | What | Led by |
|---|---|---|
| **20:00** | **First integration:** four phones connected, each role changes only its own channel; confirm the brain gate | Arnav |
| **23:30** | **Stranger test:** new players understand their role within 20 seconds and finish Trial I without help | Ved recruits |
| **03:30** | **Fallback checkpoint:** whatever works ships; no heroics after this | Arnav |
| 07:00 | Everyone awake; finishing jobs start | Anshul |
| 08:00 | Demo video recorded | Anshul |
| **09:00** | **Feature freeze** (bug fixes only), then rehearse the 3- and 5-minute demos until 10:30 | Everyone |
| **10:30** | **Devpost complete** | Ved |
| **11:00 / 11:45** | **Devpost create deadline / final deadline. No commits after 11:45** | Ved |

Sleep shifts: Neil + Ved 05:15-07:00; Arnav + Anshul 03:30-05:15. If a task runs 2x over its time box, say so at the next check-in.

**Gates (from the redesign)**

| Gate | Pass | Status |
|---|---|---|
| First integration | All four phones connected; each role changes only its own channel | Phase 1-3 tests pass; needs the live four-phone run |
| Playable | A blind team reaches Miranda using only the Seer's calls | Needs Phases 4-5 |
| Brain | True Prince sensing measurably more accurate or timely than the Changeling; otherwise the disclosed hybrid | **Passed** (Princess side 59/60 vs 1-10/60; Giant warned 60/60 vs 0/60). No hybrid needed |
| Stranger test | Role understood within 20 s; Trial I finished without help | 23:30 |
| Feature freeze | Movement, sensing, one Giant hazard, win/lose, reconnect and keyboard fallback stable | 09:00 |

**Cut order if behind:** generated trials (agents), live Jester voice, advanced Chronicle, decorative HUD animation, extra rivals,
Trials II and III. Never cut: the four-role controller loop, the Seer's information asymmetry, the Giant warning, reconnect, the
keyboard fallback.

## Decisions

| When | Decision | Why |
|---|---|---|
| Sat | Party co-op on phones, Jackbox-style join; royalty reskin with real fly-gene names | Best live demo; theme fit; the lore teaches real biology |
| Sat | Whole CNS (166,606 neurons, connections with 5+ synapses) as a rate model | No small subcircuit exists (140,223 neurons within 3 hops); fast enough for 50 Hz; answers "did you hand-pick neurons?" |
| Sat | The Changeling = shuffle senders within sign groups, keeping receivers and counts | Every neuron keeps its exact input, so the control is fair, not a broken brain |
| Sat | Python owns the game state; Godot only renders | Headless tests and replays |
| Sat | Fresh public repo for the submission; the planning repo is never submitted | Every commit must be inside the hacking window |
| Sat | No LLM or voice call inside the live game loop; the Princess, rivals and Giant are scripted | Reliability and scope |
| Sat 17:00 | **First-person 2D redesign (Ved):** three players move the fly directly, the brain powers only the Seer | Simpler to build and to understand; a fair comparison (identical controls in both modes) |
| Sat 17:00 | 2D only (no 3D engine) | 3D is too much for the time left |
| Sat 18:00 | Host art: pixel-art royal court (Anshul) with the manuscript palette | Owner's call; reads well on a projector |
| Sat 19:05 | HUD brain activity is side-free (`vision`, `looming`, `escape`) | The shared screen must not reveal the Seer's secret |

**Still open:** keep the Chronicler; demo laptop; presenter; the LLM if agents get built (Gemini makes us eligible for the MLH
Gemini prize); the domain name (`royalflyness.club` suggested); whether all four are first-time hackers.

## hackUMBC 2026 rules: how we comply

A violation means disqualification, removal from the event and a ban from hackUMBC events.

| Rule | How we comply |
|---|---|
| **Every commit between 12:00 PM Sat 26 Sept and 11:45 AM Sun 27 Sept** | Laptop clocks on automatic. No commits after 11:45 Sun. **Never force-push, rebase `main`, amend pushed commits or change commit dates** |
| **No building on existing projects** (not eligible for prizes) | All code written during the event. Not copied in: Neil's `fly-cns-sim` code, the old Fly-by-Wire code (including its camera-check tool), the pre-event Codex handoff plugin, the planning repo's probe scripts. Libraries (NumPy, SciPy, Godot, websockets, Caddy) and public APIs are fine |
| Plans made before the event | Plans and a data check, no code. The README says so; tell an organizer |
| No cross-submission; one project per team | Submit only *His Royal Flyness*, only here |
| Team of at most 4, all checked in; students 18+ (or enrolled UMBC students under 18) | Neil, Arnav, Ved, Anshul; confirm check-in and eligibility |
| Devpost created by 11:00 Sun, finalized by 11:45 | Draft early; complete by 10:30; Ved submits |
| Public GitHub link to all code | `github.com/8002panch/his-royal-flyness` is public; everything the game runs is committed except secrets and the large public data files (TECH.md says how to get them) |
| Demo video at least 30 s; in-person demo of 3 to 5 min | Video by 08:00; stay at the table during judging |
| Tracks must clearly fit | Only tracks whose tech we genuinely use (see Submission) |
| MLH Code of Conduct | Respect everyone; follow organizers; lore never jokes about real people or groups |
| MaleCNS is CC-BY 4.0 | Credit Berg et al., *Cell* 2026 (HHMI Janelia FlyEM, Google Research, University of Cambridge, MRC LMB) in the README, the Decree screen and Devpost |
| Third-party assets | Google Fonts (SIL Open Font License), credited; art made during the event; ElevenLabs library voices only |
| Secrets | Keys only in `.env` (git-ignored); the repo is public. If a key is ever committed, revoke it at once; don't rewrite history |
| AI tools | Allowed; disclosed in the README and on Devpost (Claude and Codex for code and docs; Gemini and ElevenLabs in the game if used). Everyone can explain the code they commit |
| Honesty | The Decree says what's real and what's assumed; no number on screen, in a voice line or on Devpost unless the code computed it |
| Privacy | Players give only a display name; nothing is stored after the session |

**Git habits:** branches named `<name>/<feature>`; pull often, merge small; `main` must always run the demo.

**Sunday 10:30 checklist (Ved):** repo public; README has the plans note, the Decree, credits, AI-tools line and how to run; last
commit before 11:45 and no force-pushes; Devpost has all four members, the repo link, the video, the description and only tracks
that fit; First Time Hack only if all four are first-timers; no keys in the repo; team at the table for judging.

## Event facts

- **Where:** RAC (Retriever Activities Center), UMBC, in person. **When:** Sat 26 Sept 12:00 PM to Sun 27 Sept 11:45 AM.
- **Theme:** royalty. **Judging:** creativity, technical complexity, impact, execution. Judges are secret; Game Jamathon entries
  present to industry judges.
- **Submission:** public GitHub link, a video of at least 30 seconds, one project per team, in-person demo of 3 to 5 minutes.

## Submission (Devpost): on hold

Not started on purpose; the team decides when. When it starts:

- **Title:** His Royal Flyness: A Courtship by Committee. Keep the Royal Decree section, and use numbers only from results files
  (e.g. `team/neil/seer_eval.csv`).
- **Tracks to consider** (tick only if genuinely built): Game Jamathon (main target: function, looks, polish, creativity, theme);
  Most Engaging Demo (judges play on their phones); MLH Best Use of ElevenLabs (if the voices ship); MLH Best Domain Name from
  GoDaddy Registry (if the join URL uses one); MLH Best Use of DigitalOcean (if the relay runs there); MLH Best Use of Gemini API
  (only if agents ship); Best First Time Hack (only if all four are first-timers). Overall prizes need no box.
- **Impact angle:** more than 100 fly-connectome projects appeared in three weeks, nearly all a fly playing an existing game. This
  one puts players inside the fly's senses with a scientific control you can play, on any phone with no install (classroom-ready).
