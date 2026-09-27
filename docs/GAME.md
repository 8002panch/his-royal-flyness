# The game: His Royal Flyness

*A Courtship by Committee.* hackUMBC 2026 (theme: royalty). Technical baseline: the latest
team-built direct movement and neural Seer. The story/levels below are Arnav's expanded
comic-campaign plan, approved by Arnav for team sharing. These features are not yet implemented. The older
three-trial story is superseded by this proposal; its implementation remains in git history.

The repo has three docs: **GAME.md** (this file: what we're making), [TECH.md](TECH.md) (how it works and how to run it),
[TEAM.md](TEAM.md) (who does what, status, schedule, rules, submission).

## In one breath

Players share one fly in a royal chase. The implemented baseline has four phone roles;
Arnav's requested campaign supports 2–4 players once combined-role controls are added. Three of them each control one axis of Prince Hamlet's flight.
The fourth, the **Royal Seer**, is the only one who can sense where Princess Miranda is and when the Giant's hand will strike,
and those senses run through the real wiring of a male fruit fly's nervous system (MaleCNS v1.0, all 166,606 neurons).

| | |
|---|---|
| Genre | Phone-controlled party co-op; four roles today, 2–4 players requested for the campaign |
| Where the fun comes from | Short shouted calls, overcorrection and recovery, not memorizing controls |
| A session | Tutorial, two stages, Giant encounter, conditional father encounter, branching comic ending; duration to measure after playtests |
| The brain's job | It powers the Seer's senses. The players move the fly directly |
| The twist | **The Changeling:** the same neurons and connection counts with scrambled partners. The Seer goes blind |
| Pitch line | "Three of you fly him. Only the Seer knows where she is, and the Seer is reading a real fly's brain." |

## How the planned campaign plays

Join → the cast introduction (Dramatis Personae) → garden grape tutorial → opening comic → Tinman's drink question → basement Stage 1 →
Rutabaga's drink question → sixty-second Stage 2 → Cheapdate's drink question → banquet comic →
ten Giant dodges → Prospero's own test either way (five untouched dodges; built Sun 27 Sept: a Giant win
no longer skips him) → one of two endings. Full layouts, questions and panel script are in [the story plan](#story-campaign-and-comic-cutscenes--approved-team-plan).

Players move directly; the brain powers the Seer's Princess/Giant cues. New wall/spike/throw
guidance must be implemented and honestly labeled; it is not already a neural capability.
Only the Seer receives actionable hidden-course and hazard information. Comic questions pause
play, and only the Seer submits the council's answer. Retry rules are specified per level.
There is no automatic serenade/alignment requirement for these new story endings.

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
- **Requested 2–4-player campaign:** combine movement jobs on fewer phones; keep a Seer. No keyboard or one-player gameplay mode. The existing four-role code still needs combined-role support from Arnav and Ved.

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

## Planned levels (replaces the old three trials)

| Part | Objective | Result / next scene |
|---|---|---|
| Tutorial: Royal Garden | Carry four grapes, one at a time, to the Royal Harvest Chalice | Opening comic, then Tinman quiz |
| Stage 1: The Journey to the Court | Use the Seer's private obstacle guidance through the dim basement to the stairs | Rutabaga quiz |
| Stage 2: Prove Yourselves | Reach banquet doors within 60 active seconds; avoid hidden swats and obstacles | Cheapdate quiz, then banquet comic |
| Giant: Outlast the Giant | 10 genuine successful dodges before taking 3 hits | Success comic and happy ending, or failure comic and father encounter |
| Father: Prospero's Last Word | Dodge 5 grapes Prospero throws, without a hit | Reconciliation ending or Miranda chooses herself |
| Demo/testing | Inspect and reset any feature/scene independently | No effect on campaign progress |

The full [story plan](#story-campaign-and-comic-cutscenes--approved-team-plan) distinguishes
confirmed rules from proposed tuning. No extra star formula, automatic wedding or hidden
certification claim is required. Display delivery/dodge/time counts computed by the game.

## The main screen

```text
+----------------------------------------------------------------+
| Trial title             candle timer            TRUE / CHANGELING|
|                                                                |
|          Hamlet and atmospheric royal surroundings             |
|          no live hidden hazard locations or route map          |
|                                                                |
| x/y/z motion indicators                Hamlet's brain map (top right) |
|                                                                |
| Helmsman   Liftmaster   Wingmaster   Seer        team status    |
+----------------------------------------------------------------+
```

- During hidden-navigation/hazard play, the shared screen reveals no actionable wall/spike layout, hand landing zone or throw path. No shadows or directional sounds can leak those secrets. Authored comic panels are separate from live sensing.
- **Hamlet's brain map** (top right; built Sun 27 Sept, replacing the Seer panel; simplified at 08:30 because the
  labelled drawing was too busy to read): a small picture of his brain with four parts (eyes, memory, balance, body =
  nerve cord and motor neurons) and one big row per part saying in a word how it's doing (VERY BUSY, BUSY, NORMAL, SLOW,
  VERY SLOW) in the colour it has in the picture, plus goblets for cordials drunk. It shows while flying and in the drink
  questions only; other cutscenes and the cast introduction have the whole screen. The server still computes twelve finer
  regions (instinct, courting, taste, escape...). Each region is a group of
  real neurons picked by MaleCNS annotation; its colour is log2 of its mean rate against sober rest (dark = quieter, gold then
  crimson = busier). It runs a second copy of the whole-CNS model (`brain/brain_map.py`) driven only by Hamlet's movement
  (each direction stimulates the brain-v2 visual group for that direction), so it never carries the Seer's secret. Each
  wrong quiz answer (a grape cordial) adds one step of the disclosed alcohol assumption: GABA neurons' output +20%, excitatory
  neurons' output -8%, per cordial. During the three drink questions the panel grows down the right side (the comic moves
  left), rings the parts the question is about (Q01 balance and body, Q02 memory, Q03 memory and balance) and shows, big,
  the model's computed change for one cordial (from sober in forward flight: memory -32%, balance -10%, body -30%; the
  drink table uses fixed noise, so every game shows the same numbers). These are
  model outputs under our assumption, not measured fly or human results. The Seer's brain is never given alcohol.
- *(Older, replaced by the brain map:)* The **Royal Nervous System HUD** draws one bar per brain-activity value (`vision`, `looming`, `escape`, as z-scores). With the
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
- **Feedback:** wing buzz, dust puff, a short nondirectional shake or ink flash after impact. The new hidden-hazard stages must not show a warning shadow or live projectile on the shared screen. Story art may show authored hazards in paused comics.
- **Hamlet's Reliquary (cosmetic, optional):** three accessories (Royal Mantle, Sun Halo, Wing Filigree) toggled locally in Godot,
  with no protocol change.
- Every role crest uses a distinct shape as well as a color, so nothing depends on color alone.

## Audio and voice (ElevenLabs)

- Pre-generated library voices (no cloning real people): **Clown the Jester**, **Princess Miranda**, **Duke Prospero** and rival
  one-liners. Captions on every line.
- Sound effects: fanfare, seal stamp, the Giant's whoosh (and a softer fake whoosh), SPLAT, crowd gasp and cheer, wing buzz,
  hearts chime, candle out, wedding bells.
- Music (built Sun 27 Sept; `audio/music/`, played by `host/scripts/music_player.gd`, the `Music` autoload): each track
  loops, crossfades on a scene change and ducks under voice lines. Title, lobby and cast: *Majesty's Playful Promenade*;
  garden tutorial: *The Sovereign's Playful Hedge*; story comics (C01-C04): *Chamber Wobble*; drink questions: *The Tilted
  Goblet*; Stage 1 basement: *Depths of the Keep*; Stage 2: *Siege at the Keep*; the Giant: *Storm over the Keep*;
  Prospero: *Scourge of the Volcanic Keep*; the wedding ending: *A Royal Union*; Miranda's own path: the Promenade again.
- Stretch: the Jester reads a short roast written from the round's real numbers. It never blocks the game; a pre-recorded line
  plays if it isn't ready in about 4 seconds.
- Browsers only allow sound after the first tap, so the join button doubles as the audio-unlock tap.

### Voice links supplied by Arnav

The panel dialogue in the story plan is the campaign writing source. Keep existing IDs for
compatibility until Anshul maps/replaces them; old trial/wedding lines are not required in
the new flow. These are the ElevenLabs voice pages supplied in Arnav's original storyline so the audio owner can review them.
They are references only; no audio has been generated or committed by this planning change.

| Character | ElevenLabs voice page |
|---|---|
| Prince Hamlet | [yhf80q1381zd2JJQ4tM7](https://elevenlabs.io/voices/yhf80q1381zd2JJQ4tM7) |
| Princess Miranda | [fgDJOgmENIR82PueQrVs](https://elevenlabs.io/voices/fgDJOgmENIR82PueQrVs) |
| Duke Prospero | [LvmvHEBEmMJBJw9UuhwO](https://elevenlabs.io/voices/LvmvHEBEmMJBJw9UuhwO) |
| Lord Tinman | [1aPDmPEYltTp3yDMQLiT](https://elevenlabs.io/voices/1aPDmPEYltTp3yDMQLiT) |
| Sir Cheapdate | [eadgjmk4R4uojdsheG9t](https://elevenlabs.io/voices/eadgjmk4R4uojdsheG9t) |
| Count Rutabaga | [GsfuR3Wo2BACoxELWyEF](https://elevenlabs.io/voices/GsfuR3Wo2BACoxELWyEF) |
| Clown, the Court Jester | [7rQX8r6PVq3gfJ8rZzyE](https://elevenlabs.io/voices/7rQX8r6PVq3gfJ8rZzyE) |

The Giant has no supplied voice link because the approved plan treats it as a static obstacle.

Square brackets are ElevenLabs v3 audio tags. `{braces}` are filled in at runtime from computed numbers only.

| id | Speaker | Line |
|---|---|---|
| H_TITLE | Clown | [fanfare] Hear ye, hear ye! By order of Duke Prospero, the Royal Ball of the Fruit Bowl begins! |
| H_JOIN | Clown | Present your seal at the gate, and take your place on the Prince's Privy Council. |
| H_PRINCE | Clown | Behold Prince Hamlet, the first prince whose entire mind has been mapped. Every one of his hundred and sixty-six thousand neurons. |
| H_ROLE_HELMSMAN | Clown | The Royal Helmsman! Left and right are yours. |
| H_ROLE_LIFTMASTER | Clown | The Royal Liftmaster! You hold the heights. |
| H_ROLE_WINGMASTER | Clown | The Royal Wingmaster! Forward, and mind the brakes. |
| H_ROLE_SEER | Clown | The Royal Seer! You alone can sense the Princess, and the Giant. Speak up. |
| H_TRIAL_1 | Clown | The First Trial: the Garden Approach. Her Highness awaits. |
| H_TRIAL_2 | Clown | The Second Trial: the Banquet. The feast is fragrant. So, alas, is Sir Cheapdate. |
| H_TRIAL_3 | Clown | The Third Trial: the Giant's Shadow. Only the Giant Fiber is faster than the Giant's hand. |
| H_WARN_GIANT | Clown | [urgent] The Giant stirs! |
| H_SPLAT | Clown | [solemn] The Giant has claimed another suitor. |
| H_WIN | Clown | [fanfare] Her Highness is charmed! |
| H_TIMEOUT | Clown | [sigh] The candle is spent. Her Highness retires to her chambers. |
| H_RIVAL_WINS | Clown | Alas! The Princess favors another. |
| H_CHANGELING | Clown | [gasp] A changeling! The same neurons, but scrambled within. Let us see how the Seer fares now. |
| H_TRUE_PRINCE | Clown | The true Prince returns. |
| H_WEDDING | Clown | [bells] Let it be recorded: Prince Hamlet and Princess Miranda, wed by committee. |
| H_DECREE | Clown | By royal decree: his wiring is real. Everything else, we will tell you. |
| H_FAINTED | Clown | The {role} has fainted! Revive them, quickly! |
| P_GREET | Miranda | [curious] Another suitor? Very well. Let us hear you sing. |
| P_CHARMED | Miranda | [delighted] Now that is a serenade. |
| P_BORED | Miranda | [sighs] I have seen livelier fruit. |
| P_RIVAL | Miranda | Sir Cheapdate, the banquet has barely begun. |
| P_WEDDING | Miranda | [warmly] By committee, then. I accept. |
| J_CHANGELING | Jester | The changeling had the very same neurons as our Prince. [laughs] Its Seer still could not find a princess in a banquet hall. |
| J_GENERIC_1 | Jester | A fine effort, my lords and ladies. Mostly fine. Partly effort. |
| J_GENERIC_2 | Jester | The court will remember this trial. The court will try to forget it. |
| R_TINMAN | Lord Tinman | Courting? I would need a heart for that. |
| R_CHEAPDATE | Sir Cheapdate | [hiccup] One more grape and I shall be royalty. |
| R_RUTABAGA | Count Rutabaga | Have we met? I never remember. |

## Lore: the Kingdom of the Fruit Bowl

The Kingdom sits on a kitchen counter ruled by Giants (the humans). Tonight Duke Prospero holds the Royal Ball, and Prince Hamlet
expects their intended marriage to be announced alongside Princess Miranda. Hamlet is the first prince whose entire mind has been mapped. He flies by committee: three
courtiers at the wings and one Seer reading his senses.

**Every name is a real fly gene; the personalities are ours.** All facts were checked by Neil on Sat 26 Sept.

| Character | In the game | Real gene fact (source) |
|---|---|---|
| **Prince Hamlet** | Protagonist; engaged to Miranda in Arnav's story | *hamlet* switches which kind of neuron a cell becomes; named for "to be or not to be" ("IIB or not IIB", after the cells it affects) (RSB; SDB Interactive Fly) |
| **Hamlet's council** | The players coordinating his flight and Seer information | Player roles, not an additional named character |
| **Princess Miranda** | Hamlet's intended bride; chooses reconciliation or independence in the branching endings | *miranda* carries the Prospero protein into the daughter cell when a neural stem cell divides; named for Prospero's daughter in The Tempest (Shen, Jan & Jan 1997, *Cell*) |
| **Duke Prospero** | Her father; welcoming after Giant success, hostile after Giant failure; second-chance opponent | *prospero* controls the fate of the cells a neural stem cell makes; named for The Tempest's magician (SDB Interactive Fly) |
| **Lord Tinman** | The heartless rival | *tinman* flies grow no heart; named for the Wizard of Oz (UNBC gene-names page) |
| **Sir Cheapdate** | The tipsy rival at the Banquet | *cheapdate* flies get drunk on less alcohol; it turned out to be an allele of the memory gene *amnesiac* (Moore et al. 1998, *Cell*) |
| **Count Rutabaga** | The rival who forgets whom he's courting | *rutabaga* flies are bad at learning and memory; the gene makes adenylyl cyclase (Levin et al. 1992, *Cell*) |
| **Clown, the Court Jester** | Narrates the tutorial and game, announces events, and makes cameos | *clown* mutants have red-and-white eyes (UNBC gene-names page) |
| **The Giant** | The human with the swatter | From a fly's point of view, humans are Giants |

**Cast is final:** only the characters listed above appear as story characters. The Giant
Fiber is a neuron name, and the Changeling is a scrambled-brain comparison mode, not an
additional actor or speaking character. Keep those scientific explanations without casting
them as people. Existing `H_*` audio identifiers remain identifiers; their speaker is Clown.

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
6. *tinman* flies grow no heart.
7. *clown* mutants have red-and-white eyes.
8. *cheapdate* flies get drunk on less alcohol.
9. *rutabaga* flies are bad at learning and memory.

**Campaign title cards:** Royal Garden; Stage 1 — The Journey to the Court; Stage 2 — Prove Yourselves; Outlast the Giant; Prospero's Last Word. Comic endings use the titles in the story script.

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

## Judging presentation (existing outline; adapt to the new testing menu)

The separate Demo/testing area is defined in the story plan. The timed presentation below
is a previous rehearsal outline, not additional campaign levels. Use a selected feature
rather than forcing judges through the entire comic story. Replace old Garden/Shadow/wedding
beats with the new tutorial, a hand-dodge example and the neural comparison when implemented.

In-person judging is 3 to 5 minutes; the Game Jamathon presents to industry judges (use the 5-minute version there). The
presenter is Arnav, Ved or Anshul; Neil takes the science questions.

**Setup before judges arrive:** laptop plugged in, sleep off, heavy apps closed; relay, server and Godot running; four team
phones joined with sound unlocked and auto-lock off; room code big enough to read from 2 m; a phone hotspot ready for LAN mode;
the Decree one key away; the backup video queued.

**3-minute version**

| Time | Beat | Say / do |
|---|---|---|
| 0:00-0:20 | Clown the Jester | "Prince Hamlet is a real male fruit fly. We run his entire nervous system, all 166,000 neurons from the map published this month. Three of you fly him. One of you is his senses." Judges join on phones |
| 0:20-1:10 | The Garden | The Seer calls, the three fly. "The Seer's arrow isn't game code: it's his Princess detectors, through his brain, read from the neurons that steer him toward her." |
| 1:10-1:50 | The Giant's Shadow | Shouting, a dodge. "That warning came from the Giant Fiber, the real neuron that fires his escape. Looming detectors feed it with thousands of synapses." |
| 1:50-2:30 | The Changeling | Flip the toggle, play again. "Same neurons, same connections per neuron, scrambled partners. Same controls, same game. The Seer is blind." Show the measured numbers (the table above) |
| 2:30-3:00 | The Royal Decree | "Every name here is a real fly gene. His wiring is real. Everything we assumed, we tell you." |

**5-minute additions:** play the Banquet (decoys and the rival); show the art, voices and music; the royal cast and fact cards.

**If something breaks:** a phone won't join, hand over a joined team phone; Wi-Fi drops, switch to LAN mode on the hotspot;
the laptop lags, simplify the demonstration; a voice line fails, captions carry it; total failure, play the
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
| Are the gene names real? | Yes: hamlet, miranda, prospero, tinman, clown, cheapdate, rutabaga |
| Why does it matter? | More than 100 fly-brain projects appeared in three weeks, and nearly all show a fly playing an existing game. Here you work with the fly's senses, with a scientific control you can play, on any phone with no install |

**Demo video** (required, at least 30 seconds; aim for about 90): title and Clown; gameplay with a phone in frame for each role;
the Giant's Shadow and a dodge; the Changeling flip and the measured numbers; the Decree and the link. Record by 08:00 Sunday.

## Story campaign and comic cutscenes — approved team plan

**Status: built and on `main` (Sun 27 Sept, 02:00): `server/campaign.py`, the Godot court and the phones; see TECH.md, "The
campaign".** Built as written, with these choices: the courses use Ved's visible wall gates (openings moved off the centre line;
no hidden walls or spikes, so no scripted Seer guidance to disclose); the tutorial teaches one grape at a time; attacks come from
the left or the right and the real brain warns the Seer; Stage 2 has three swats; Prospero throws grapes. Tune difficulty after
playtests. The original plan note follows.

**Status then: approved by Arnav for team sharing and prototyping on September 26; planning only, not implemented.** This expands Arnav's
supplied storyline. Existing team code remains the technical starting point. The cast,
scene order, four grapes, sixty-second Stage 2, ten Giant dodges and five untouched father
dodges come from his story. The strict cast, drink names and three-hit Giant limit are also
confirmed. Values explicitly called **proposed** are editable defaults,
starting values to validate during implementation and playtesting, not measured results. The older three-trial/wedding flow does not govern this draft.

### 1. The complete story at a glance

Hamlet and Miranda are due to have their intended marriage announced at the royal banquet.
Hamlet helps Clown gather grapes, but an accident makes him look drunk. Prospero suspends
the announcement and shuts him out. Hamlet takes a side-window route through the basement
and inner passages, meeting three rivals who test his knowledge with a drink challenge.
At the banquet, a human Giant interrupts everything. Prospero offers Hamlet a chance to
prove himself by surviving its swats. Success brings reconciliation. Failure leads to
Prospero's own dodge challenge, and Miranda ultimately speaks for herself in either ending.

```text
TUTORIAL: FOUR GRAPES
  → C01 OPENING: THE MISUNDERSTANDING
  → Q01 TINMAN: WINDOW DRINK CHALLENGE
  → STAGE 1: THE JOURNEY TO THE COURT (BASEMENT)
  → Q02 RUTABAGA: STAIRCASE DRINK CHALLENGE
  → STAGE 2: PROVE YOURSELVES (60 SECONDS)
  → Q03 CHEAPDATE: BANQUET DRINK CHALLENGE
  → C02 THE BANQUET AND PROSPERO'S CHALLENGE
  → GIANT: 10 SUCCESSFUL DODGES
       WIN → C03 THE GIANT RETREATS → E01 RECONCILIATION (direct-success version)
       LOSE → C04 PROSPERO TAKES OVER → FATHER: 5 DODGES, NO HIT
                   WIN → E01 RECONCILIATION (second-chance version)
                   LOSE → E02 MIRANDA CHOOSES HERSELF
```

Demo/testing is a separate menu, never a chapter or an automatically granted story result.
Stage retries do not replay a drink question or add another drink penalty.

### 2. Cast lock and continuity fixes

Only these appear as characters: **Prince Hamlet; his council (the players); Princess
Miranda; Duke Prospero; the Giant; Lord Tinman; Sir Cheapdate; Count Rutabaga; Clown the
Court Jester.** Miranda and Prospero are the consistent spellings. Clown narrates all scenes;
there is no separate Herald and no Sir Indy. Giant Fiber and Changeling are scientific
terms/modes, not additional characters.

The source includes guards, two girls beside Tinman and an unnamed crowd. **Confirmed strict-cast
solution:** Prospero closes the gate himself; Tinman presents both drinks alone; the three
named rivals and the council supply reactions. Empty banquet chairs,
banners and sound effects can convey a large court without drawing extra people. Do not add
background characters until Arnav changes the cast rule.

Preserve the earlier local draft's garden misunderstanding: Hamlet does not consume alcohol
in the tutorial. A splash stains his face and his awkward recovery convinces Prospero he has
been drinking. Later wrong answers really do add a fictional movement penalty. Hamlet's line
"The garden wasn't what it looked like" therefore remains true even on a later dizzy route.

**Drink wording confirmed by Arnav:** troublesome drink = *fermented grape cordial*;
safe drink = *pear nectar*. Ordinary grapes/ordinary grape juice are not presented as alcohol.
The purple cordial may still look like the grape drink in Arnav's story. There is no magical grape effect in this draft; the garden grapes themselves do not intoxicate Hamlet.

The happy ending says Miranda chooses Hamlet, rather than Prospero awarding her as a prize.
The unhappy ending preserves Arnav's line that she never wanted an arranged marriage. Its
meaning is "I did not choose this public competition," not "winning obliges me to marry."
No automatic wedding animation is required; the announcement is the conclusion.

### 3. Comic-strip popup format

- Put a parchment comic over a darkened, frozen game. Gold frame, existing royal palette,
  reusable character portraits/poses, speech bubbles and Clown's rectangular caption boxes.
- A page contains **two or three panels**; scenes below specify their page breaks. Reveal
  panels one at a time, leaving earlier panels visible. One or two short bubbles per panel;
  each bubble should normally stay below about 25 words. Split text instead of shrinking it.
- No automatic reading deadline. Presenter controls **Next panel**, **Previous panel** and
  **Skip scene**. These are menu controls, not a keyboard flight mode. A visible panel/page
  indicator explains progress. Keyboard shortcuts, if added, only duplicate these buttons.
- Captions always work without sound. Optional voice follows the current panel and stops
  when it changes. Tiny slides, fades, a crown tilt or a shake are enough; no animation movie.
- Pause flight, the stage clock, hazard clocks and dizziness during comics/questions. Clear
  movement and scan holds on entry. After closing, show a short **Ready → Fly** cue and require
  fresh button presses. A sleeping/disconnected phone pauses an unanswered choice.
- Static story illustrations may show Miranda and the Giant. They must never show the next
  live attack's position, route or a paused screenshot containing private Seer markings.
- In interactive comics, the shared screen shows the question/options. Only the current
  Seer submits an answer from their phone, after the group discusses it. Movement phones show
  "Discuss with your council." The presenter can advance dialogue, not answer for the Seer.
- Previous rereads committed panels; it cannot undo an answer or apply its effect twice.
  **Skip dialogue** stops at an unanswered question. No automatic answer, random penalty or
  silent bypass. Any developer bypass is clearly marked DEMO and awards no campaign result.

### 4. Level-by-level play plan

#### Tutorial — A Small Favor in the Royal Garden

**Objective:** deliver four distinct grapes to the **Royal Harvest Chalice**, a gold cup
on a low stand carrying Prospero's crest. No timer, no damage and no dizzy controls.

Carry one grape at a time, preserving the existing local tutorial draft. Approaching a grape
slowly picks it up automatically; approaching the chalice deposits it. No pickup button or
inventory screen. The server counts unique deliveries, never repeated touches. A carried grape
follows Hamlet without changing movement. Top bar: **Grapes delivered 0/4**; small label:
**Carrying a grape**. Filled slots represent delivery, not pickup.

| Step | Layout and teaching | Clown's popup |
|---|---|---|
| Welcome | Garden, empty chalice, objective. Show each phone's job. | "Four grapes for the royal banquet. Surely an entire council can manage breakfast." |
| Grape 1 | Directly ahead at starting height. Move, release, slow down and return. | "Wingmaster: forward gently. Release to slow. The grape is not fleeing." |
| Grape 2 | Sideways offset with a wide approach. | "Helmsman: left and right. Small corrections; we are gardening, not invading." |
| Grape 3 | Above the path; climb, then descend toward the cup. | "Liftmaster: up for the grape, down for the chalice. Keep the crown attached." |
| Grape 4 | Combine all three directions. | "Together now. Slow before the turn; the chalice has suffered enough." |
| Seer return lesson | Miranda briefly waits beside the chalice. Seer scans her and guides the final return. | "Seer: find Miranda beside the chalice. Tell your council which way to fly." |
| Finish | Fourth delivery fills the bar. Miranda heads indoors. | "Four delivered! Responsibility has never looked so purple." |

Grapes and the cup are visible tutorial objects. Private directional readings remain on the
Seer phone. Detect Miranda with Neil's existing system; do not relabel a grape as a Princess
input or claim the brain can recognize grapes. Repeat hints on inactivity; do not secretly
auto-complete. A replay tutorial option belongs in the testing menu.

**The cast introduction (built Sun 27 Sept):** Enter in the lobby opens *Dramatis Personae* before the tutorial: one card
per character (Hamlet, Miranda, Prospero, Clown, Tinman, Rutabaga, Cheapdate, the Giant, then the council's four roles), each
with the character large and animated, a spoken introduction by the Clown (`INTRO_*` lines), their part in the story and
the real gene behind the name. The Giant is drawn as the fights draw its hand. Space/Right moves on, Left goes back, S skips
to the garden. Phones show "story time".

**Cutscenes play by themselves (built Sun 27 Sept):** comics and cast cards move on once each line has been spoken and
there's been time to read it (at least 2.5 s, about four words a second). A question still waits for the Seer. **A** toggles
auto play and manual (Space) on the main screen. Text in the bubbles always stays at the big caption size: a long line makes
its bubble taller and the picture shorter. In the three drink questions both chalices stand in the picture, labelled PEAR
NECTAR and GRAPE CORDIAL; the one Hamlet gets lights up. Eight Clown quips that interrupted scenes mid-way were cut
(C01 panels 2, 3, 7, 8; Q01's two; Q02's and Q03's last line); his scene-setting narration stays. Anshul's TWIST/E03 joke
ending stays script-only and is not in the game.

#### Stage 1 — The Journey to the Court

**Arrival:** the low side window leads to a storage landing and down into the crowded basement.
This fixes the geography: the window does not inexplicably open directly into the throne room.
**Objective:** traverse the basement and reach the staircase. The timer is not the challenge.

**Speed (Sun 27 Sept):** in both wall courses forward/back flight has 45% of the other axes' acceleration and top speed
(`COURSE_Z_SCALE`), because the walls came at the council too fast to steer through. A wall Hamlet has flown through is
no longer drawn (it stood between the chase camera and him, hiding the course ahead).

Proposed course has three readable sections: a wide sideways bend between stacked objects;
an up/down passage with a safe resting pocket; a final narrow section with spikes on alternating
sides. No moving enemy or hand attack yet. Exact dimensions await movement-speed tests.

The shared screen shows Hamlet, dim scenery and his motion, but **not the actionable wall
edges, spike locations or route markers**. Decorative background must not accidentally outline
the hidden safe route. Keep Hamlet and progress readable; darkness is not a black screen.
The Seer gets local obstacle guidance: blocked side, safe opening and up/down/advance guidance.
This is a proposed new phone feature, not something the current neural adapter already does.
Prefer a simple direction card to a full map; it preserves the controller-only phone design.

Only reveal the staircase as the team reaches the last safe landing. Proposed progress bar:
**Basement sections cleared 0/3**, awarded when a checkpoint is crossed, not from time spent.
Walls stop the fly; spikes return him to the last safe pocket with a short Clown popup:
"An excellent inspection of the masonry. Let us try the opening."

**Proposed retry rule:** unlimited checkpoint retries, no repeating Tinman's quiz and no extra
drink penalty. Reset motion to still; allow a brief recovery before control resumes. No failure
route can bypass the staircase. Reaching it starts Rutabaga's comic.

#### Stage 2 — Prove Yourselves

**Arrival:** stairs lead into the inner passage toward the banquet doors. **Objective:** reach
the far doors within **60 seconds of active play**, while avoiding walls and the Giant's hand.

Clown: "One minute before Prospero's inner gate closes. Quiet wings, council. Quiet wings!"
Under the strict cast rule, the gate deadline replaces unlisted guards noticing Hamlet.

Proposed course: wide first stretch with one slow practice warning; a turn with alternate
left/right openings; final approach combining height changes with an occasional swat.
Every hazard must leave a reachable escape. Avoid a forced collision between a wall and a hand.

The Seer alone receives the hand's direction/impact warning. No shared shadow, hot-zone marker,
directional arrow, hand position or left/right sound before resolution. Main-screen impact
feedback is nondirectional (brief shake/ink flash); it must not preview the next attack.
Wall/spike guidance follows the same rule as Stage 1.

"Random" warnings mean a small, repeatable selection of safe attacks with variable pauses,
not unbounded surprise hits. **Proposed starting warning window: 2 seconds**, adjusted after
testing neural warning delay and phone latency. First attack waits until players have control.

**Proposed restart rules:** timeout or a direct hand hit restarts Stage 2 at 60 seconds. A wall
blocks motion; a spike returns to its safe pocket while the clock keeps running. Keep the same
drink level and quiz history on retry. No cutscene reading, ready cue or connection pause uses
the sixty seconds. A new attempt clears attacks and velocity before it starts.

Popup on timeout: "The gate beat you to the banquet. Once more, with quieter confidence."
Passing the final doorway starts Cheapdate's comic, not another timed section.

#### Giant encounter — Outlast the Giant

**Objective fixed by Arnav:** survive **10 successful dodges**; the Giant tires and leaves.

**Tuning (Sun 27 Sept, Neil: "the hand is too easy to dodge"):** warnings of 1.9 s for the first three dodges, 1.6 s up to
seven, then 1.4 s (was 2.4 / 2.0 s); the hand is wider (hit radius 0.34, was 0.30), lands almost on Hamlet and aims where
he's heading at onset (still locked, never chasing); second hands from 3 dodges and third from 6 (was 4 and 7), 1.0 s apart
(was 1.3 s); shorter gaps (2.0 / 1.6 / 1.2 s). In simulation the old tuning was won with no hits even by a pilot reacting
0.9 s after the Seer's cue; the new one costs slow teams hits and sometimes the fight.
No player attack, enemy health bar, weapons or combat button. Use normal flight controls.

Arena: a broad clear space where sideways, height and forward/back movement can avoid a hand.
One attack at a time. Lock its target at warning onset: it does not chase Hamlet after he moves.
The Seer gets the warning privately; all players see only **Dodges 0/10** and any hit allowance.
Suggested progression: first three slower, next four alternate direction, last three use the
same patterns with shorter recovery gaps. Never add an unannounced attack type at the end.

A dodge counts once when a real attack that threatened Hamlet at warning onset resolves
without hitting him. Each attack has a unique ID. Idle time, a harmless decorative miss,
a fake warning or frames spent away from danger cannot farm the counter. Attack targets
should challenge the current position so camping in one corner is not an automatic win.

**Confirmed hit budget: three hits lose**, while successful dodges
accumulate toward ten. One attack can cause at most one hit. After a hit, stop the current
attack, reset to a safe position and allow a short recovery before the next warning.

Resolve hit/dodge atomically: an attack cannot both hurt Hamlet and be his tenth success.
Ten dodges → C03. Exhausted hit allowance → C04. Do not use the earlier suggested 45-second
survival timer; Arnav replaced it with a dodge count.

#### Father encounter — Prospero's Last Word

**Objective fixed by Arnav:** dodge **five grapes Prospero throws, without being hit**. One hit → E02;
five successful dodges → E01's second-chance version. **Changed Sun 27 Sept (Neil):** it follows a Giant win too:
C03 ends with Prospero's challenge ("But a giant is not a duke..."), and E01 then opens with Miranda's "Enough, Father".
Originally this encounter appeared only after losing to the Giant. No repeat quiz, new penalty stack or replay of Prospero's rescue on entry.

Prospero stays at one side of a small arena. Each thrown grape is a simple moving hazard, one at
a time, with a locked path and a recovery gap. Reuse warning → dodge → collision → result logic
from the Giant. The player still only flies; this adds a projectile hazard, not player combat.
The Seer alone sees its direction/path cue. No shared visible projectile, trail, splat mark,
aiming animation or directional audio giving away its route. Shared counter: **Dodges 0/5**.

The comic may show Prospero winding up a throw; live play must preserve private hazard information.
Throwing grapes is a cartoon story device, not fly behavior.
Fast projectiles require checking the space they traveled through between updates, so they
cannot pass through Hamlet without registering a hit. Proposed slow speed first; tune later.

### 5. The three drink questions and dizziness

All three encounters use the same reusable question panel. Two answers, no countdown,
team discussion, Seer selects then confirms. The server accepts one answer for that encounter
and shows a brief explanation before the drink panel. Answers are predetermined; there is no
cup guessing, hidden random swap or second choice after the result.

| ID / rival | Question and two choices | Correct / explanation |
|---|---|---|
| Q01 / Tinman | "Alcohol can make balance and coordination... A: worse. B: more precise." | **A.** Alcohol can interfere with the brain functions used for balance and coordinated movement. |
| Q02 / Rutabaga | "Can heavy drinking interfere with forming new memories? A: No. B: Yes." | **B.** Alcohol can disrupt the formation of new memories. That is not the same as magically deleting every old memory. |
| Q03 / Cheapdate | "Does coffee remove alcohol's effects on judgment and coordination? A: Yes. B: No." | **B.** Feeling more awake does not remove those impairing effects. |

These are general human-health teaching facts, not results from this fly simulation. Sources
checked for the quiz: [NIAAA: Alcohol and the Brain](https://www.niaaa.nih.gov/publications/alcohol-and-brain-overview)
and [NIAAA: The Truth About Holiday Spirits](https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/truth-about-holiday-spirits).
Neil should review wording before voice production. The supplied voice links above are references for the audio owner; voice selection and production still require that review.

Correct → safe pear nectar; no new penalty. Wrong → grape cordial; add one dizziness level.
**Proposed persistence:** 0–3 levels, carried through the rest of the run, including the father
encounter. A correct later answer prevents a new stack; it does not sober Hamlet up. Retrying
a stage restores its entry state and never repeats the drink effect. New campaign resets to 0.

**Proposed feel:** a small, predictable increase in gliding after release, capped at three
steps (initial tuning candidates: 10%, 20%, 30% extra stopping distance at matched speed).
Test and adjust these values; they are not measured alcohol effects. Do not reverse buttons,
swap player jobs, add random uncontrollable motion, change neuron weights or falsify Seer cues.
Emergency input clearing on disconnect/pause still works normally. Each course must remain
possible at level 3, including Stage 2's sixty-second limit.

Show **Steadiness: steady / wobbly / very wobbly / extremely wobbly** with an icon and text.
When a wrong answer changes it, say "Dizziness increased: allow more room to stop." No BAC,
real dose, metabolism estimate or claim that the connectome simulates intoxication.

### 6. Panel-by-panel story script

Dialogue below is a first writing pass for Arnav to change. Lines after correct/wrong are
mutually exclusive branches; do not play both. Pages are deliberately short for projector reading.

#### C01 — A Royal Misunderstanding (3 pages, 8 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Invitation with Hamlet and Miranda's crests; banquet beyond. | **Clown:** "Tonight, Prospero would announce Hamlet and Miranda's intended marriage. First: one tiny royal errand." |
| 1, 2 | Hamlet beside the four grapes in the Royal Harvest Chalice; Miranda heads indoors. | **Hamlet:** "Four grapes. Delivered with princely precision." **Clown:** "And not a drop tasted." |
| 1, 3 | Hamlet clips the cup's rim, splashing his face; crown slips. | **Hamlet:** "Perfectly under—oh." **Clown:** "Innocence, unfortunately, does not remove grape stains." |
| Page 2, 4 | Prospero arrives during the wobbly recovery. | **Prospero:** "Grape-stained lips? Swaying beside the banquet cup? Hamlet!" **Hamlet:** "A landing accident, Your Grace. An extremely purple one." |
| 2, 5 | Prospero angry; Hamlet tries to explain. | **Prospero:** "Tonight I must trust you beside my daughter. You cannot even arrive at breakfast with your judgment intact?" |
| 2, 6 | Prospero returns toward the gate. | **Hamlet:** "I haven't drunk anything! Ask the council!" **Prospero:** "Then show me the judgment your appearance has failed to demonstrate. The announcement is suspended." |
| Page 3, 7 | Prospero pulls the gate chain himself and enters; Hamlet remains outside. | **Prospero:** "Stay outside until you can conduct yourself." **Clown:** "A royal misunderstanding. Naturally, nobody listened to the useful witnesses." |
| 3, 8 | Hamlet spots a low side window; Tinman's silhouette waits there. | **Hamlet:** "A window. Council, we can still explain." **Clown:** "Provided the window has fewer opinions than the door." |

Do not show an actual sip in the opening. Tutorial deliveries stay completed after the splash.

#### Q01 — Tinman's Courtesy (2 pages plus question)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Tinman leans elegantly against the window ledge, blocking entry; two glasses on his tray. | **Tinman:** "Locked out of your own announcement? Bold entrance, Hamlet." |
| 1, 2 | He raises both drinks, composed and amused. | **Tinman:** "My window, my little test of judgment. Answer well: pear nectar. Answer poorly: the grape cordial you appear to favor." |
| Question | Q01 options, Seer phone selection. | **Hamlet:** "Council, help me answer." **Tinman:** "Take your time. Composure cannot be hurried." |
| Page 2, 3A | Correct: safe drink handed over. | **Tinman:** "A correct answer. How inconvenient for my first impression. Pear nectar, as promised." |
| 2, 3B | Wrong: cordial handed over; wobble indicator increases. | **Tinman:** "A charming answer. Entirely wrong. Grape cordial, as agreed." **Clown:** "And now the misunderstanding has acquired a sequel." |
| 2, 4 | Tinman flies away alone; Hamlet enters the low window. | **Tinman:** "Do try not to arrive in pieces. Miranda dislikes a scene." **Clown:** "Below the window: storage. Below the storage: trouble." |

Tinman's motive is to embarrass a competing suitor while acting impeccably polite. He offers
the test openly; this is not a claim the drinks are interchangeable or accidentally switched.

#### Q02 — Rutabaga on the Stairs (2 pages plus question)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Rutabaga sits by the staircase, nervously balancing two glasses. | **Rutabaga:** "Oh! A person. Was I coming downstairs or escaping them? Never mind. You look... scheduled." |
| 1, 2 | He studies a little card tucked under his tray. | **Rutabaga:** "I wrote a question to remember which drink to offer. Or whom to offer it to. Could you help?" |
| Question | Q02 options; council discusses. | **Hamlet:** "We need the stairs." **Rutabaga:** "Yes! Those. Of course. A quick test, then I'll stop occupying them." |
| Page 2, 3A | Correct: pear nectar. | **Rutabaga:** "Yes! New memories. I knew that was important. Pear nectar for the person who remembered." |
| 2, 3B | Wrong: cordial; add one stack, including if already wobbly. | **Rutabaga:** "My card says otherwise. That means the purple one. I think the card is more organized than either of us." |
| 2, 4 | A heavy groan and THUD above; Rutabaga startles and exits. | **Rutabaga:** "I remember why I came down! Goodbye!" **Hamlet:** "What was that?" |
| 2, 5 | Hamlet looks up the stairs, then continues. | **Clown:** "A sensible question. Naturally, we went upstairs to investigate it personally." |

Split the last page into two if bubbles crowd the layout. Sound hints at the Giant; it must
not reveal a forthcoming Stage 2 attack's exact side or time.

#### Q03 — Cheapdate's Welcome (2 pages plus question)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Cheapdate staggers out of the banquet doors, crooked wings, two glasses. | **Cheapdate:** "Hamlet! Excellent. I have two drinks and almost enough hands." |
| 1, 2 | He poses as an expert, nearly spilling both. | **Cheapdate:** "Before you enter, a toast. Pass my little test and take the pear. Fail, and share my purple vintage." |
| Question | Q03 options. | **Cheapdate:** "A question of recovery. A subject on which I have conducted extensive, regrettable research." |
| Page 2, 3A | Correct: pear nectar. | **Cheapdate:** "No? Coffee doesn't fix it? That explains several breakfasts. Pear nectar it is." |
| 2, 3B | Wrong: cordial; apply one stack. | **Cheapdate:** "Wrong, apparently. Clown wrote the answer on my sleeve. Purple for you; humility for neither of us." |
| 2, 4 | Off-panel Clown calls him; Cheapdate hurries back. | **Clown:** "Cheapdate! Your chair is in the punch bowl again!" **Cheapdate:** "My seat has arrived before me!" |
| 2, 5 | Hamlet crosses the banquet threshold as a huge crash interrupts. | **Hamlet:** "At last—" **Clown:** "A sentence the evening declined to let him finish." |

This comic resolves once. Its wrong answer sets the final possible dizziness stack for the
Giant and optional father encounter. No extra toast adds an unrecorded fourth drink.

#### C02 — A Much Larger Problem (2 pages, 5 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | A huge hand disrupts the banquet; named rivals scatter behind furniture. | **Clown:** "The Giant had arrived. It had neither invitation nor table manners." |
| 1, 2 | Prospero spots Hamlet; anger competes with fear. | **Prospero:** "You? I told you to stay outside!" **Hamlet:** "The garden wasn't what it looked like. Please, let me explain." |
| 1, 3 | Another crash; Prospero turns toward the hand. | **Prospero:** "Then show me. Keep its attention. Outlast its swats until it abandons this hall." |
| Page 2, 4 | Hamlet looks to the council; Miranda looks worried. | **Hamlet:** "Council, together. We don't have to hurt it. We have to stay out of reach." |
| 2, 5 | Arena title over an authored silhouette, no live target. | **Clown:** "Ten dodges. One very large temper. Let us test which lasts longer." **Objective:** "Outlast the Giant: 10 dodges." |

Prospero's request offers another chance to explain and restore the announcement. It is not
a new attack mechanic. End on a ready cue before the first hazard begins.

#### C03 — The Giant Gives Up (1 page, 3 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| 1 | The hand withdraws; a receding silhouette conveys the human leaving. | **Clown:** "Ten swats survived. The Giant departed to find something less organized to squash." |
| 2 | Hamlet returns; Prospero relieved; council celebrates, rivals exchange looks. | **Prospero:** "You stood your ground by refusing to stay in one place. Well flown, Hamlet." |
| 3 | Miranda embraces Hamlet; reuse two still poses. | **Miranda:** "You're safe. Next time, find me before volunteering for the hand." **Hamlet:** "Next time, I'm delivering flowers." |

Continue to E01's direct-success opening, not to the father encounter.

#### C04 — Prospero's Patience Ends (2 pages, 4 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Hamlet retreats disheveled, alive; Prospero furious. | **Prospero:** "First the garden. Now this. Stand back." |
| 1, 2 | Three still silhouettes show Prospero avoiding swats; the hand finally withdraws. | **Clown:** "Prospero finished the task himself—and returned with considerably less patience than he left with." |
| Page 2, 3 | Prospero bars Hamlet's path toward Miranda. | **Prospero:** "You expect my blessing after this? You will not pass me." **Hamlet:** "Then let Miranda speak for herself." |
| 2, 4 | Prospero bristles and picks up a grape in a static panel. | **Clown:** "His Grace decided to settle this personally." **Objective:** "Dodge five throws. Do not get hit." |

The Duke's rescue is a comic, not an NPC battle simulation or a new playable stage. Reset
hazard count and motion for the father encounter; retain the already-earned dizziness level.

#### E01 — An Announcement by Choice (2 pages, 4 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1A — after Giant win | Miranda stands with Hamlet before a calmer Prospero. | **Miranda:** "Father, thank him. Then listen to him." |
| 1, 1B — after father win | Miranda steps between them after the fifth dodge; no sixth throw comes. | **Miranda:** "Enough, Father. I love Hamlet. You do not get to throw things at the person I choose." |
| 1, 2 — shared | Clown gestures at his own grape-stained cuff. | **Clown:** "For the record: he was delivering my grapes. The chalice splashed him. I was there." |
| Page 2, 3 | Prospero lowers his head; Miranda keeps Hamlet's hand. | **Prospero:** "Then I judged before I listened. Miranda—do you still wish the announcement to go ahead?" **Miranda:** "Yes. Because I choose it." |
| 2, 4 | Small royal banner; Hamlet, Miranda and Prospero; council crests below. | **Prospero:** "Then let the banquet begin again." **Clown:** "A royal announcement, approved by Miranda. The grapes abstained." |

Use one ending with two entry panels, not two competing win endings. If later drinks occurred,
Clown clears only the garden accusation; he does not falsely say Hamlet drank nothing all night.

#### E02 — Miranda Writes Her Own Ending (2 pages, 4 panels)

| Panel | Still picture | Dialogue / caption |
|---|---|---|
| Page 1, 1 | Hamlet sits on the floor, embarrassed; the three named rivals snicker. | **Clown:** "Hamlet's evening had reached the floor. The competition mistook this for a promotion." |
| 1, 2 | Tinman, Cheapdate and Rutabaga flatter Prospero. | **Tinman:** "A more composed candidate stands before you." **Cheapdate:** "And one behind him!" **Rutabaga:** "Which position am I applying for?" |
| Page 2, 3 | Miranda steps forward and silences them. | **Miranda:** "Enough. I never wanted a marriage chosen for me. Not by a contest. Not by any of you." |
| 2, 4 | Miranda leaves with confidence; Hamlet picks up his crown; rivals speechless. | **Miranda:** "I can decide my own future." **Clown:** "For once, the entire court had nothing useful to add. It was a peaceful ending." |

The mockery belongs to the fictional rivals, not an insult aimed at the players. No new suitor
replaces Hamlet automatically. End with Replay / Demo / Lobby controls and computed results only.

### 7. Separate Demo and testing area

Selectable scenes: movement practice; grape pickup/delivery; any comic page; each drink question
with correct/wrong outcome; basement obstacle; one hand attack; full Giant counter; one throw;
full father counter; either final ending; real-brain/Changeling comparison.

Presenter controls: reset chosen scene, pause/resume, choose fixed attack example, set a test
dizziness level 0–3, inspect a hit/dodge count and return to menu. These are visible developer
controls, not hidden changes to a campaign. Test state never carries into a new campaign.

Any option exposing true hazard positions uses a large **DEBUG — POSITIONS REVEALED** label.
Normal presentation keeps Seer-only privacy. Do not compare a revealed/debug scene with a
hidden/neural scene as if only the wiring changed. Brain comparisons use identical scene
inputs and movement settings; scripted wall/throw guidance remains explicitly labeled.

### 8. What is real, what is new, and what still needs review

| Feature | Status / explanation |
|---|---|
| Phone movement, joining, real-brain Princess/Giant cues | Existing team baseline; reuse latest code and inspect its interfaces before integration. |
| Comic overlay, quiz choice, campaign branches, grapes | New planned game features. Not implemented by this document. |
| Exact wall/spike/opening guidance | New scripted navigation aid proposed for the Seer only. Existing brain output does not provide wall maps or up/down safe paths. Label it as game-authored guidance. |
| Exact hand landing zone | Server knows it for collision; current neural cue is coarse direction/time. Do not present an exact coordinate as measured brain output. For first implementation, use large readable attack sectors that coarse cues can distinguish; exact private assistance needs explicit disclosure. |
| Father projectile cues | New hazard type. Reuse delivery/privacy/avoidance rules, but do not silently label thrown-object detection as an already validated neural feature. Neil reviews any looming-input reuse; scripted guidance is disclosed. |
| Dizziness | Scripted movement modifier. Separately, the brain map shows a disclosed alcohol assumption on a second copy of the model; the Seer's brain and cues are never altered. |
| 2/3-player combined jobs and requested behind/above view | Requested product direction; current technical baseline is four phone roles and 2D presentation. Owner integration remains necessary; no new 3D engine implied. |

**Confirmed in this review:** strict cast substitutions; fermented grape cordial/pear nectar;
three-hit Giant limit. **Approved starting plan:** checkpoint/restart defaults, stacked gliding penalty, branching
endings and disclosed scripted wall/throw guidance. Tune difficulty after playtests; coordinate
new phone/renderer fields with their owners. Dialogue can be polished without changing the
cast or agreed story branches.

**Acceptance checklist before the team calls this playable:** four unique deliveries; only Seer
can answer; each quiz applies once across reconnect/retry; no wrong cup on a correct answer;
maximum dizziness still allows completion; Stage 2 clock freezes in popups; hidden hazards never
leak through shared geometry/audio; ten genuine dodges choose C03; exhausted hits choose C04;
father win requires five untouched dodges; one hit selects E02; no sixth shot after success;
Skip cannot award a win or answer; restarting clears previous trial hazards; Demo cannot change
campaign history; story panels use only the cast above. These are planned checks, not test results.

## Borrowed lessons

- **Keep Talking and Nobody Explodes:** one player has information the others need, so talking is the game.
- **PEAK:** shared chaos and funny failure make a great live demo.
- **Jackbox:** join by code on any phone, zero install.
- **Different from all three:** the information comes from a real nervous system, and a scrambled copy of it is one toggle away.
