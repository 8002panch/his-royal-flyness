# The game: His Royal Flyness

*A Courtship by Committee.* hackUMBC 2026 (theme: royalty). This is the current plan: Ved's first-person 2D redesign, adopted
Sat 26 Sept at 17:00. It replaces the earlier four-senses, top-down design; that version is in git history.

The repo has three docs: **GAME.md** (this file: what we're making), [TECH.md](TECH.md) (how it works and how to run it),
[TEAM.md](TEAM.md) (who does what, status, schedule, rules, submission).

## In one breath

Four players share one fly in a front-facing 2D royal chase. Three of them each control one axis of Prince Hamlet's flight.
The fourth, the **Royal Seer**, is the only one who can sense where Princess Miranda is and when the Giant's hand will strike,
and those senses run through the real wiring of a male fruit fly's nervous system (MaleCNS v1.0, all 166,606 neurons).

| | |
|---|---|
| Genre | Party co-op for 4, Jackbox-style: phones are controllers, one shared main screen |
| Where the fun comes from | Short shouted calls, overcorrection and recovery, not memorizing controls |
| A session | Three trials and a finale, about 8 minutes |
| The brain's job | It powers the Seer's senses. The players move the fly directly |
| The twist | **The Changeling:** the same neurons and connection counts with scrambled partners. The Seer goes blind |
| Pitch line | "Three of you fly him. Only the Seer knows where she is, and the Seer is reading a real fly's brain." |

## How a round plays

1. **Join.** The main screen shows a four-letter room code (consonants only, so it never spells a word). Each player opens the
   page on their phone, enters the code and a name, and picks a role. A phone that drops and comes back gets its role back.
2. **Call.** The Seer holds SCAN and calls short instructions: "Princess right, closing." "Hand from the left, two seconds!"
3. **Fly.** The three movement players coordinate their axes. The main screen reacts at once, but nobody except the Seer gets
   exact directions or timing.
4. **Court.** Near Miranda, the team holds all three axes steady inside a target window, and the serenade plays automatically.
5. **Fail.** A mistimed dodge, an overshoot, a rival or a Giant strike resets progress or ends the trial.

## The four roles

Names can change after a playtest. The split of responsibilities doesn't.

| Role | Phone controls | Phone feedback (only this player sees it) | Job |
|---|---|---|---|
| **Royal Helmsman** | Hold LEFT / RIGHT | Actual sideways drift and momentum | `x`: strafe and turn |
| **Royal Liftmaster** | Hold UP / DOWN | Altitude and vertical speed | `y`: climb and descend |
| **Royal Wingmaster** | Hold FORWARD / BACK | Speed and braking | `z`: advance, brake, reverse |
| **Royal Seer** | Hold SCAN | Princess bearing (NW / N / NE), distance (NEAR / MID / FAR) and confidence; Giant direction, seconds to impact and confidence | Tell the other three where to go and when to dodge |

Rules that make it work:

- **Phones are controllers only.** They never show the hall, the fly, Miranda, the Giant, a map or the shared HUD. The Godot app
  on the demo laptop is the only full-game screen.
- **Only the Seer ever receives target or hazard information.** The relay and the server both enforce and test this. The
  main-screen HUD shows brain activity without left/right, so it can't give the secret away either.
- **Every axis matters every second.** No role waits around for a special moment.
- **Tap-to-latch** (tap on, tap off) for anyone who can't hold a button. Big half-screen buttons with labels and shapes.
- **Fewer than four players:** keyboard fallback on the laptop (planned for Phase 5, see TEAM.md).

## Movement (what the players feel)

Each movement phone sends -1, 0 or +1 for its axis. The server turns that into motion with acceleration, drag, a speed cap and
a small dead zone, so Hamlet glides, overshoots a little and settles; let go and he drifts to a stop. Held inputs expire after
1.2 seconds if a phone goes quiet. The body is simulated in Python. Godot fakes depth with 2D scale, parallax and overlap:
there's no 3D engine.

## The Seer and the brain

- Every tick the server tells the brain where Miranda and any Giants are, relative to Hamlet. That becomes activity in his real
  sensory neurons: the Princess detectors in each eye (LC10a, LC10d), the looming detectors (LC4, LPLC2) and the wind sensors in
  his antennae (Johnston's organ).
- His whole nervous system steps forward, and the Seer's cues are read out of real descending neurons that fire on the side of
  the Princess or the threat (the Giant Fiber, DNp01, is one of them).
- The cues are **coarse on purpose**: left / ahead / right, NEAR / MID / FAR, a confidence, and a Giant warning with a direction
  and seconds to impact. The Seer has to talk; the others have to listen.
- **True Prince vs Changeling**, measured on 60 fresh random scenes each (`team/neil/seer_eval.csv`):

  | Brain | Princess found (side right) | Giants warned before impact | Average warning lead |
  |---|---|---|---|
  | True Prince | 54 / 60 (53 right; the 6 missed were the farthest) | 60 / 60 | 1.20 s |
  | Changelings (3 seeds) | 0 / 60 | 0 / 60 | none |

  In the game's own hall the True Prince gets her side right from 116 of 120 fly positions, NEAR / MID / FAR track the real
  distance, and none of the three Changelings ever reports her or the test Giant.

- Movement is player-controlled in both modes, so the comparison is fair: only the senses change.
- **Hybrid fallback (disclosed if used):** direction from the game's geometry, confidence and warnings from the brain. The
  neural mode passes, so it isn't needed so far.

## Trials

| Trial | What happens | New pressure |
|---|---|---|
| **I. The Garden Approach** (tutorial) | Teach the three axes one at a time, then reveal that only the Seer knows where Miranda is | None. No Giant |
| **II. The Banquet** | False targets, a rival (Sir Cheapdate) and food distractions. The Seer must tell Miranda from misleading cues | Overshooting, decoys |
| **III. The Giant's Shadow** | Real and fake hand warnings from different directions; the Seer calls the timing, the three dodge together, then find Miranda again. Sir Indy keeps coming back | Real and fake swats |
| **Finale: the Royal Wedding** | Hold alignment near Miranda to trigger the serenade, then bells and the final Chronicle | None |

- **Win:** hold x/y/z alignment near Miranda for the set time (Phase 5 picks the number); the serenade triggers automatically.
- **Lose:** the Giant's hand lands (SPLAT), the candle burns out (timeout), or an overshoot condition (Phase 5 defines it).
- **Scoring (proposal):** communication, movement efficiency, near misses and the Seer's call accuracy, shown in the Chronicle.
- Trial I plus one Giant hazard is the must-have. II and III come after the playable gate.

## The main screen

```text
+----------------------------------------------------------------+
| Trial title             candle timer            TRUE / CHANGELING|
|                                                                |
|                   first-person royal hall                      |
|        Giant shadow          Miranda / rivals / obstacles      |
|                                                                |
| x/y/z motion indicators              Royal Nervous System HUD   |
|                                                                |
| Helmsman   Liftmaster   Wingmaster   Seer        team status    |
+----------------------------------------------------------------+
```

- The main screen never shows a full map, Miranda's exact bearing or the hand's exact timing.
- The **Royal Nervous System HUD** draws one bar per brain-activity value (`vision`, `looming`, `escape`, as z-scores). With the
  Changeling the bars stay low (its looming readout never reaches the warning level), which is the demo's clearest picture of
  "the wiring matters."
- Captions for every voice line; a badge for TRUE PRINCE or CHANGELING.

## Art direction

- **Current host direction (Anshul, on branch `anshul/host-seer-hud`, not merged yet):** a warm pixel-art royal court. The world
  is drawn at 640x360 and scaled up with nearest-neighbor filtering, with 2 to 4 px clusters, one dark ink outline and flat color.
  The banquet hall fills the center (vaulted ceiling, columns, banners, feast tables, a carpet leading to Miranda), with actors on
  their own layers. Depth comes from overlap, scale and tiling, never gradients, blur or glow. The first read must be "royal fly
  game in a banquet hall," not "neural telemetry app."
- **Palette** (kept from the manuscript plan): parchment `#F3E9D2`, ink `#2B2118`, royal blue `#1F3A8A`, crimson `#9B1C1C`,
  gold `#C9A227`, plus muted stone, wood and a Miranda lavender.
- **Fonts (Google Fonts):** UnifrakturMaguntia for titles only, IM Fell English for body text.
- **Juice:** wing buzz, dust puff, a hand shadow before the swat, a short shake, an ink SPLAT, hearts for the serenade.
- **Hamlet's Reliquary (cosmetic, optional):** three accessories (Royal Mantle, Sun Halo, Wing Filigree) toggled locally in Godot,
  with no protocol change.
- Every role crest uses a distinct shape as well as a color, so nothing depends on color alone.

## Audio and voice (ElevenLabs)

- Pre-generated library voices (no cloning real people): the **Herald**, **Princess Miranda**, **Clown the Jester** and rival
  one-liners. Captions on every line.
- Sound effects: fanfare, seal stamp, the Giant's whoosh (and a softer fake whoosh), SPLAT, crowd gasp and cheer, wing buzz,
  hearts chime, candle out, wedding bells.
- Music: a court-dance loop (lobby, Garden), a livelier banquet loop, a tense Giant's Shadow loop, a short wedding theme.
- Stretch: the Jester reads a short roast written from the round's real numbers. It never blocks the game; a pre-recorded line
  plays if it isn't ready in about 4 seconds.
- Browsers only allow sound after the first tap, so the join button doubles as the audio-unlock tap.

### Voice lines (drafts)

Square brackets are ElevenLabs v3 audio tags. `{braces}` are filled in at runtime from computed numbers only.

| id | Speaker | Line |
|---|---|---|
| H_TITLE | Herald | [fanfare] Hear ye, hear ye! By order of Duke Prospero, the Royal Ball of the Fruit Bowl begins! |
| H_JOIN | Herald | Present your seal at the gate, and take your place on the Prince's Privy Council. |
| H_PRINCE | Herald | Behold Prince Hamlet, the first prince whose entire mind has been mapped. Every one of his hundred and sixty-six thousand neurons. |
| H_ROLE_HELMSMAN | Herald | The Royal Helmsman! Left and right are yours. |
| H_ROLE_LIFTMASTER | Herald | The Royal Liftmaster! You hold the heights. |
| H_ROLE_WINGMASTER | Herald | The Royal Wingmaster! Forward, and mind the brakes. |
| H_ROLE_SEER | Herald | The Royal Seer! You alone can sense the Princess, and the Giant. Speak up. |
| H_TRIAL_1 | Herald | The First Trial: the Garden Approach. Her Highness awaits. |
| H_TRIAL_2 | Herald | The Second Trial: the Banquet. The feast is fragrant. So, alas, is Sir Cheapdate. |
| H_TRIAL_3 | Herald | The Third Trial: the Giant's Shadow. Only the Giant Fiber is faster than the Giant's hand. |
| H_WARN_GIANT | Herald | [urgent] The Giant stirs! |
| H_SPLAT | Herald | [solemn] The Giant has claimed another suitor. |
| H_WIN | Herald | [fanfare] Her Highness is charmed! |
| H_TIMEOUT | Herald | [sigh] The candle is spent. Her Highness retires to her chambers. |
| H_RIVAL_WINS | Herald | Alas! The Princess favors another. |
| H_CHANGELING | Herald | [gasp] A changeling! The same neurons, but scrambled within. Let us see how the Seer fares now. |
| H_TRUE_PRINCE | Herald | The true Prince returns. |
| H_WEDDING | Herald | [bells] Let it be recorded: Prince Hamlet and Princess Miranda, wed by committee. |
| H_DECREE | Herald | By royal decree: his wiring is real. Everything else, we will tell you. |
| H_FAINTED | Herald | The {role} has fainted! Revive them, quickly! |
| P_GREET | Miranda | [curious] Another suitor? Very well. Let us hear you sing. |
| P_CHARMED | Miranda | [delighted] Now that is a serenade. |
| P_BORED | Miranda | [sighs] I have seen livelier fruit. |
| P_RIVAL | Miranda | Sir Indy again? He is simply not dead yet. |
| P_WEDDING | Miranda | [warmly] By committee, then. I accept. |
| J_CHANGELING | Jester | The changeling had the very same neurons as our Prince. [laughs] Its Seer still could not find a princess in a banquet hall. |
| J_GENERIC_1 | Jester | A fine effort, my lords and ladies. Mostly fine. Partly effort. |
| J_GENERIC_2 | Jester | The court will remember this trial. The court will try to forget it. |
| R_INDY | Sir Indy | [wheezing] I'm not dead yet! |
| R_TINMAN | Lord Tinman | Courting? I would need a heart for that. |
| R_CHEAPDATE | Sir Cheapdate | [hiccup] One more grape and I shall be royalty. |
| R_RUTABAGA | Count Rutabaga | Have we met? I never remember. |

## Lore: the Kingdom of the Fruit Bowl

The Kingdom sits on a kitchen counter ruled by Giants (the humans). Tonight Duke Prospero holds the Royal Ball, and Prince Hamlet
hopes to win Princess Miranda. Hamlet is the first prince whose entire mind has been mapped. He flies by committee: three
courtiers at the wings and one Seer reading his senses.

**Every name is a real fly gene; the personalities are ours.** All facts were checked by Neil on Sat 26 Sept.

| Character | In the game | Real gene fact (source) |
|---|---|---|
| **Prince Hamlet** | The player fly | *hamlet* switches which kind of neuron a cell becomes; named for "to be or not to be" ("IIB or not IIB", after the cells it affects) (RSB; SDB Interactive Fly) |
| **Princess Miranda** | The one he's courting (scripted; she has opinions and can prefer a rival) | *miranda* carries the Prospero protein into the daughter cell when a neural stem cell divides; named for Prospero's daughter in The Tempest (Shen, Jan & Jan 1997, *Cell*) |
| **Duke Prospero** | Her father; opens the ball | *prospero* controls the fate of the cells a neural stem cell makes; named for The Tempest's magician (SDB Interactive Fly) |
| **Sir Indy, the Knight Who Is Not Dead Yet** | A rival who keeps coming back | *I'm not dead yet* (*Indy*), after Monty Python and the Holy Grail. In some experiments flies with less of it lived much longer; the result is debated (FlyBase FBgn0036816) |
| **Lord Tinman** | The heartless rival | *tinman* flies grow no heart; named for the Wizard of Oz (UNBC gene-names page) |
| **Sir Cheapdate** | The tipsy rival at the Banquet | *cheapdate* flies get drunk on less alcohol; it turned out to be an allele of the memory gene *amnesiac* (Moore et al. 1998, *Cell*) |
| **Count Rutabaga** | The rival who forgets whom he's courting | *rutabaga* flies are bad at learning and memory; the gene makes adenylyl cyclase (Levin et al. 1992, *Cell*) |
| **Clown, the Court Jester** | Voices the Chronicle | *clown* mutants have red-and-white eyes (UNBC gene-names page) |
| **The Herald** | The announcer | None |
| **The Giant** | The human with the swatter | From a fly's point of view, humans are Giants |
| **The Giant Fiber** | Hamlet's escape neuron, and part of the Seer's Giant sense | The neuron that fires a fly's escape jump really is called the giant fiber (DNp01). Hamlet's looming detectors connect straight to it with more than 11,000 synapses (our data check) |
| **The Changeling** | Same body, scrambled insides | Same 166,606 neurons, same connection counts, same total input to every neuron; only the partners are shuffled (by construction) |

**The Privy Council.** The Seer's sense is real biology: LC10a neurons help males track females, LC4 and LPLC2 detect looming
objects and feed the giant fiber, and the antennae's Johnston's organ senses air movement. The three movement roles are ours (no
neuron claims).

**Tone rules**

- Playful and a little pompous, like a costume drama narrated by someone who's had one glass of wine. Never mean to players.
- Biology jokes must be true and on the verified list above.
- **Don't use these gene names:** *fruitless*, *ken and barbie*, *doublesex*, *transformer* (the jokes land badly or read as
  jokes about sex or gender).
- No song lyrics (no Wizard of Oz lyrics for Lord Tinman). Short allusions only.
- Nothing about real people or groups.

**Royal Facts (loading cards)**

1. *hamlet* is a real fly gene that decides what kind of neuron a cell becomes. IIB or not IIB.
2. Miranda and Prospero are both real fly genes named after The Tempest. Miranda carries Prospero into the next generation of cells.
3. MaleCNS v1.0 maps an entire male fruit fly nervous system: about 166,000 neurons and 125 million synapses (Janelia, Google,
   Cambridge, MRC LMB; *Cell*, 3 Sept 2026).
4. The escape neuron really is called the giant fiber, and thousands of synapses feed it straight from the looming detectors.
5. The Changeling has the same neurons, the same number of connections and the same input per neuron. Only the partners are
   scrambled, and that's enough to blind the Seer.
6. *I'm not dead yet* is a real fly gene named after Monty Python.
7. *tinman* flies grow no heart. 8. *clown* flies have red-and-white eyes. 9. *cheapdate* flies get drunk on less alcohol.
10. *rutabaga* flies are bad at learning and memory.

**Trial cards:** I, The Garden Approach: "Her Highness takes the evening air among the grapes." II, The Banquet: "The feast is
fragrant. So, alas, is Sir Cheapdate." III, The Giant's Shadow: "The Giants stir. The hall grows dark."

## The Royal Decree (honesty panel)

The exact text is in the [README](../README.md#rules-and-honesty) (Neil maintains it). It must appear on the main screen, in the
README and on Devpost, and it says: players control movement directly; the connectome mediates only the Seer's senses; the
connection counts are real and everything else is our assumption; the Princess, rivals and Giant are scripted. If the hybrid
fallback is used, the Decree says so.

## Accessibility

1. Tap-to-latch on every hold control (built).
2. Captions for every voice line; crests use shapes as well as colors; each button is half the screen.
3. Every phone vibration also has a visual flash (vibration only works in Android browsers).
4. Stretch: an audio-only Seer (stereo pitch for the Princess's side, a rising tone for the Giant).

## Demo plan

In-person judging is 3 to 5 minutes; the Game Jamathon presents to industry judges (use the 5-minute version there). The
presenter is Arnav, Ved or Anshul; Neil takes the science questions.

**Setup before judges arrive:** laptop plugged in, sleep off, heavy apps closed; relay, server and Godot running; four team
phones joined with sound unlocked and auto-lock off; room code big enough to read from 2 m; a phone hotspot ready for LAN mode;
the Decree one key away; the backup video queued.

**3-minute version**

| Time | Beat | Say / do |
|---|---|---|
| 0:00-0:20 | The Herald | "Prince Hamlet is a real male fruit fly. We run his entire nervous system, all 166,000 neurons from the map published this month. Three of you fly him. One of you is his senses." Judges join on phones |
| 0:20-1:10 | The Garden | The Seer calls, the three fly. "The Seer's arrow isn't game code: it's his Princess detectors, through his brain, read from the neurons that steer him toward her." |
| 1:10-1:50 | The Giant's Shadow | Shouting, a dodge. "That warning came from the Giant Fiber, the real neuron that fires his escape. Looming detectors feed it with thousands of synapses." |
| 1:50-2:30 | The Changeling | Flip the toggle, play again. "Same neurons, same connections per neuron, scrambled partners. Same controls, same game. The Seer is blind." Show the measured numbers (the table above) |
| 2:30-3:00 | The Royal Decree | "Every name here is a real fly gene. His wiring is real. Everything we assumed, we tell you." |

**5-minute additions:** play the Banquet (decoys and the rival); show the art, voices and music; the royal cast and fact cards.

**If something breaks:** a phone won't join, hand over a joined team phone; Wi-Fi drops, switch to LAN mode on the hotspot, then
keyboard mode; the laptop lags, keep playing and skip the extras; a voice line fails, captions carry it; total failure, play the
backup video.

**Q&A drill**

| Question | Answer |
|---|---|
| Is the fly actually thinking? | It's the real wiring diagram run as a simple rate model. The connection counts are real; strengths, signs and how the game becomes neural input are our assumptions, and we list them |
| Why does the brain only do the senses? | So the comparison is fair: the controls are identical in both modes, and only the wiring changes. Whatever breaks with the Changeling is the wiring's doing |
| Did you hand-pick neurons? | All 166,606 run every tick. We chose where the senses enter (named sensory types) and which descending neurons we read out; both lists are public in the repo |
| What exactly is the Changeling? | Each connection's sender is shuffled among neurons of the same sign. Every neuron keeps its exact total input, its excitatory/inhibitory mix and its number of outputs. Only who talks to whom changes |
| Why not a spiking model? | Speed. The rate model steps the whole CNS in about 6 ms; a spiking whole-brain model took about 42 s per simulated second on this laptop |
| Why is the Seer's direction so coarse? | Each eye's Princess detectors are driven as one group, and this dataset has no eye-position data for them, so the wiring honestly says left, ahead or right |
| What's new about this map? | It's the first complete male nervous system: brain and nerve cord in one animal |
| Is the Princess simulated? | She's scripted. Stretch idea: run her on the female nervous system map |
| Are the gene names real? | Yes: hamlet, miranda, prospero, I'm not dead yet, tinman, clown, cheapdate, rutabaga |
| Why does it matter? | More than 100 fly-brain projects appeared in three weeks, and nearly all show a fly playing an existing game. Here you work with the fly's senses, with a scientific control you can play, on any phone with no install |

**Demo video** (required, at least 30 seconds; aim for about 90): title and Herald; gameplay with a phone in frame for each role;
the Giant's Shadow and a dodge; the Changeling flip and the measured numbers; the Decree and the link. Record by 08:00 Sunday.

## Borrowed lessons

- **Keep Talking and Nobody Explodes:** one player has information the others need, so talking is the game.
- **PEAK:** shared chaos and funny failure make a great live demo.
- **Jackbox:** join by code on any phone, zero install.
- **Different from all three:** the information comes from a real nervous system, and a scrambled copy of it is one toggle away.
