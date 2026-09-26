# Build plan: Sat 15:45 to Sun 11:45

Kickoff slipped from the planned 13:15 to **15:45**, so every time below is shifted and the cut order matters more.
Each person's full task list, with time boxes and "done when" checks, is in **`team/<name>/README.md`** in the submission repo.

## Roles and the equal split

| Person | GitHub | Role | Owns | Also |
|---|---|---|---|---|
| **Neil** | `8002panch` | Brain + science | `brain/`, `agents/run_trials.py`, `agents/bots.py`, `server/chronicler.py` (credit math), fact checks, the Royal Decree | Science Q&A at judging; Devpost science sections |
| **Arnav** | `arnavp-1` | Game server | `server/` (tick loop, arena, body, sense encoders, scripted actors, rounds, Godot link, relay client), `agents/schema.py`, `levels/`, `run.sh` | Integration lead at every gate; README "how to run" |
| **Ved** | `shahved25` | Phones, relay, cloud + AI agents | `relay/` (phone page, relay, Caddy), DigitalOcean, the domain, `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py` | Devpost submitter; recruits strangers for the 23:30 test |
| **Anshul** | `darkspaz-v1` (check) | Godot host, art + audio | `host/` (all main-screen screens, sprites, chart, juice), `audio/` (ElevenLabs lines, sound effects, music, playback) | Demo video + screenshots; timekeeper at check-ins |
| Presenter | pick at kickoff (not Neil) | Pitch | None | Rehearses 09:00-10:30 with everyone |

**Hours by block** (every person has the same load in every block):

| Block | Time | Neil | Arnav | Ved | Anshul |
|---|---|---|---|---|---|
| B1 | 15:45-17:45 | 2 | 2 | 2 | 2 |
| B2 | 17:55-20:00 | 2 | 2 | 2 | 2 |
| B3 | 20:00-23:30 | 3½ | 3½ | 3½ | 3½ |
| B4 | 23:30-03:30 | 4 | 4 | 4 | 4 |
| B5 | 03:30-07:00 (1¾ h awake, 1¾ h sleep) | 1¾ | 1¾ | 1¾ | 1¾ |
| B6 | 07:00-09:00 | 2 | 2 | 2 | 2 |
| **Total** | | **15¼** | **15¼** | **15¼** | **15¼** |

## What each person does, block by block

| Block | Neil (brain) | Arnav (server) | Ved (phones, relay, agents) | Anshul (Godot, art, audio) |
|---|---|---|---|---|
| **B1** 15:45-17:45 | Graph build, `io_sets.json`, step timing, 3 Changelings; brain API stub to Arnav by 16:15 | 50 Hz loop + FakeBrain, arena + body + output mapping, state JSON to Godot | Droplet + Caddy + domain, relay (rooms, codes, host secret, reconnect), latency test | Godot scaffold + layout, WebSocket client + moving fly, lobby with seal + QR + crests |
| **B2** 17:55-20:00 | Probes A to D on True Prince vs Changelings; tune gain, tau, I_max, thresholds, baselines | Relay client as host, phone events to sense states, sense encoders v1 (eyes, contact, wind), Trial loader + Garden JSON | Phone join + crest pick, 4 role screens v1 | Fonts, palette, parchment; sprites (Hamlet, Miranda, rivals, Giant); wing/jump/SPLAT animations |
| **20:00** | **Gate: GO or HYBRID (below) + first playable end to end** | | | |
| **B3** 20:00-23:30 | Hybrid switch if needed; recorder + replay; Chronicler credit math with shadow processes; fact-check the cards | Real brain in the loop; scent plumes + rival trail; scripted Princess, rivals, the Giant (with fake swings); rounds + win/lose/stars | Live role views (Lookout panels, Perfumer meters, Taster pad, Spymaster meters); merging + reconnect UX; LAN fallback; accessibility + phone audio | Royal Nervous System chart; trial intro cards + Royal Facts; Chronicle screen; captions |
| **23:30** | **Stranger test: four people who've never seen it play the Garden and the Banquet** | | | |
| **B4** 23:30-03:30 | `run_trials` headless + worker pool; bots; speed check on the demo laptop; wire the tools for Ved | Trials II and III tuned; keyboard mode; host commands (Changeling toggle, next, reassign); Eyes hex render (P1) | Matchmaker (Gemini, structured output); Master of Trials (function calling + certification loop); Jester script; Level Lab log format | ElevenLabs: voices, ~80 lines, sound effects, music; event playback + live Chronicle audio; Level Lab, Decree, wedding screens; Changeling badge |
| **03:30** | **Fallback checkpoint (below)** | | | |
| **B5** 03:30-07:00 | Awake 03:30-05:15: batch-certify trials; Decree final. Sleep 05:15-07:00 | Sleep 03:30-05:15. Awake 05:15-07:00: stabilize, performance with shadows | Awake 03:30-05:15: run the batch with Neil, curate trials. Sleep 05:15-07:00 | Sleep 03:30-05:15. Awake 05:15-07:00: polish and juice |
| **B6** 07:00-09:00 | Devpost science + Decree; Q&A drill; README credits | README "how to run", `run.sh`, final build on the demo laptop; test LAN + keyboard fallbacks | Devpost text, tracks, links; check the repo is public; domain on Devpost | Demo video (record + voiceover, 30 s minimum, aim 90 s), screenshots |
| **09:00** | **Feature freeze.** Bug fixes only | | | |
| 09:00-10:30 | Rehearse the 3-minute and 5-minute scripts 3 times each; fresh-phone join test; Q&A drill ([DEMO_SCRIPT.md](DEMO_SCRIPT.md)) | | | |
| **10:30** | **Devpost complete** (public repo link, video, all 4 members, tracks). Ved submits | | | |
| **11:00** | **Devpost create deadline** | | | |
| **11:45** | **Final deadline. No commits after this** | | | |

## Interfaces between people (agree on these first)

| From → to | What | By |
|---|---|---|
| Neil → Arnav | Brain API stub: `Brain(kind="true"\|"changeling", seed=0)`, `.reset()`, `.step(drives: dict[str, float]) -> dict[str, float]` (group drives 0 to 1 in, output z-scores out) | 16:15 |
| Neil → Arnav, Anshul | Group names (`brain/io_sets.json`): input groups by side, output names | 16:30 |
| Arnav → Anshul | `server/sample_state.json` (the 30 Hz state message) | 16:30 |
| Ved → Arnav | `relay/PROTOCOL.md` (join, pick, in, tap, view, fx, honors) | 16:30 |
| Arnav → Ved | `agents/schema.py` (the Trial model) | 18:30 |
| Neil → everyone | Chronicle JSON format (shares + events per player) | 21:00 |
| Anshul → Arnav | Voice/sound event IDs (from [LORE.md](LORE.md#voice-line-bank)) and how the server triggers them | 21:00 |
| Neil → Ved | `run_trials(trial, brain, n)` and `get_trace(run_id)` working headless | 00:30 |

Message formats are specified in [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md#messages-json).

## Gates

### 17:45: sync (10 minutes)
Neil reads out probes A to C (the first results). Everyone says what's blocked. Confirm the 20:00 gate.

### 20:00: GO or HYBRID
| Test | Pass | If it fails |
|---|---|---|
| A. Looming makes the Giant Fiber fire | z(DNp01) above 3 within 200 ms in at least 9 of 10 runs | Tune I_max and thresholds (this should pass easily: over 11,000 direct synapses) |
| B. Tapping makes him sing | z(pIP10) above 2 and at least 2x the Changeling | Re-tune; include 3-or-more-synapse connections along the path. Last resort: trigger the song from the pC1 cluster and say so |
| C. Eye on her side turns him toward her | Consistent DNa02 left/right difference toward the stimulus, at least 2x the Changeling | **Hybrid steering:** brain decides go/jump/sing/stop; code picks the direction; the Decree says so |
| D. Smell does something | Any clear output change | The Perfumer's main job becomes the mood (pC1 meter) |

### 23:30: the stranger test
Four people who've never seen it play the Garden and the Banquet. If nobody gets it in 30 seconds, fix the tutorial prompts first, before anything else.

### 03:30: fallback checkpoint (no heroics after this)
- Whatever steering works ships (hybrid or not).
- If the relay is flaky: LAN mode on a phone hotspot. If phones fail: keyboard mode.
- If the agent loop isn't done: ship the certified trials so far plus 3 hand-made ones, and show the Level Lab log from the batch.
- If live Chronicle voice is flaky: pre-generated lines only.
- **Never** hard-code a behavior and credit it to the brain.

### 09:00: feature freeze
Only fixes after this. `main` must always run the demo.

## Scope

**MVP (P0), must ship:**
1. Jackbox-style join through the domain, 4 royal roles, reconnect, role merging, keyboard mode.
2. The whole-CNS brain live; the True Prince / Changeling toggle.
3. Trials I, II and III + wedding; win, lose, stars.
4. The Chronicle (shadow-brain credit) with pre-generated voice lines.
5. ElevenLabs Herald voice, sound effects and music (pre-generated).
6. Level Lab: at least 10 certified trials from the Matchmaker + Master of Trials loop, with the log screen.
7. Manuscript art, Royal Nervous System chart, the Royal Decree panel.
8. Two accessibility modes + captions.

**P1, if P0 is done by 03:30:** live Chronicle voice; Eyes hex view (instead of icons); Royal Facts cards on every intro; the certification farm on DigitalOcean; Spymaster phone audio.

**P2, stretch:** Tiger Data archive of trial runs; the Court (audience voting); Princess brain (female CNS); replay theater; flybody 3D; installer build.

**Cut order if behind** (we lost 2 hours, so expect to use it): Tiger Data → the Court → live Chronicle voice → Eyes hex view (use icons) →
rival singing (keep rival scent) → live Matchmaker generation (use cached certified trials) → merge the Spymaster into the Lookout.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| The brain doesn't give controllable behavior | Medium | Probes by 17:45, gate at 20:00, hybrid steering, honest Decree |
| Venue network blocks or drops phones | Medium | Cloud relay (outbound only), LAN hotspot, keyboard mode |
| Scope (4 components + agents + audio), now with 2 fewer hours | High | Strict P0, cut order above, 2x time-box rule |
| APIs (Gemini, ElevenLabs) slow or down during judging | Medium | Nothing live depends on them: cached trials, pre-generated audio, fallback lines |
| The Changeling doesn't look different live | Low to medium | Lead with certified bot numbers; show the chart |
| Lore overstates the science | Low | Neil verifies every fact card; the Decree on screen and on Devpost |
| Laptop too slow with Godot + shadows | Low | Measure at 23:30; drop to 2 shadows or the 2-hop core (37,004 neurons) |
| A rule violation (commit outside the window, pre-event code) | Low | [RULES_COMPLIANCE.md](RULES_COMPLIANCE.md); laptop clocks on automatic; no history rewrites |
| Missing the Devpost deadlines | Low | Draft created in B1; complete by 10:30; Ved owns it |

## Rules of the road

- `main` always runs the demo. Work on `<name>/<feature>` branches, pull often, merge small, re-run the demo after each merge.
- **Never force-push or rewrite history** (commit times are how the organizers check the hacking window).
- No number goes on screen, in a voice line, on a slide or on Devpost unless the game or a results file computed it.
- If a task runs 2x over its time box, say so at the next check-in (Anshul keeps time).
- Secrets only in `.env`. Never in code, commits, chat or Devpost. The repo is public.
- Every behavior on screen is either the brain's or labeled as ours.
