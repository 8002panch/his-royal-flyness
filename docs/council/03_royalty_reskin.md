# His Royal Flyness: the royalty reskin (as delivered, Sat 26 Sept 2026)

> Record only. The team's request: "The game theme is royalty so I was thinking that we should reskin the party game to something
> with lore and prince princess type thing. Research. [...] Make sure that if there are other categories this works for, fill it in.
> Don't start creating yet even though the hackathon started, just plan everything out first."
> The living plan is in `docs/`.

The research turned up more than we hoped for. Most of the royal cast can be named after real fruit fly genes, so the lore teaches real biology. And five of the 20 prizes fit things the game needs anyway. Nothing below has been built yet. This is the full plan.

## What the research found

**Real fly biology that already sounds royal:**
- **Genes named after royalty.** *hamlet* is a real fly gene, named for "to be or not to be" ("IIB or not IIB," after the IIB cells it affects). It switches which kind of neuron a cell becomes. *prospero* is named after the Duke-magician in The Tempest. *miranda* is named after his daughter, and the Miranda protein literally carries Prospero into the right daughter cell when a neural stem cell divides.
- **More gene names for rival suitors:**
  - *I'm not dead yet* (Indy) is named after the Monty Python and the Holy Grail scene, and those flies live longer.
  - *tinman* mutants have no heart.
  - *clown* mutants have red-and-white eyes.
  - Two more I'm fairly sure of but still need to check: *rutabaga* (learning and memory) and *cheapdate* (very sensitive to alcohol).
- **Courtship really is a court ritual:** he approaches, taps her, sings by vibrating one wing, and she decides.
- **Flies taste with their feet.** A royal food taster is a real job, so that's the Feet role.
- **The escape neuron is really called the giant fiber,** so "the only defense against the Giant's hand is the Giant Fiber" is literally true.

**Prize facts:**
- MLH gives free ElevenLabs credits for 3 months. The API does text-to-speech, sound effects and music.
- The MLH domain coupons cover GoDaddy Registry domains like .club, .co and .us. `.club` suits a party game.
- Gemini 3.8 Flash came out Sept 2. It supports function calling and structured JSON output.

**Deadlines:** create the Devpost project by **11:00 AM Sunday**, finalize by **11:45 AM**. You also need a public GitHub repo, a demo video of at least 30 seconds, and a live demo of 3 to 5 minutes.

---

## The Visionary: the lore

**The world.** The Kingdom of the Fruit Bowl sits on a kitchen counter ruled by Giants. Tonight is the Royal Ball.

**The cast.** The personalities are ours, but every name is a real fly gene.

| Character | Role | Real gene fact (goes on a loading-screen card) |
|---|---|---|
| **Prince Hamlet** | The player fly (the real MaleCNS nervous system) | *hamlet* decides a neuron's fate: "IIB or not IIB" |
| **Princess Miranda** | The one he's courting (scripted) | *miranda* carries Prospero into the next cell generation |
| **Duke Prospero** | Her father; he opens the ball | *prospero*, named for The Tempest's magician, controls the fate of neurons |
| **Sir Indy, the Knight Who Is Not Dead Yet** | A rival who keeps coming back | *I'm not dead yet*, named after the Holy Grail |
| **Lord Tinman** | The heartless rival | *tinman* flies have no heart |
| **Sir Cheapdate** | The rival who gets tipsy at the banquet | *cheapdate* flies are very sensitive to alcohol (check before use) |
| **Clown, the Court Jester** | Voices the end-of-round honors and roasts the council | *clown* mutants have red-and-white eyes |
| **The Giant** | The human with the swatter | Humans, from a fly's point of view |
| **The Changeling** | The ablation toggle | A fairy-tale swap: same body, scrambled insides |

**The Changeling is the best part of the reskin.** A changeling is the fairy-tale creature that looks exactly like the real child but isn't. That's exactly what the shuffled brain is: same neurons, same number of connections, partners scrambled. The toggle in the demo becomes **TRUE PRINCE / CHANGELING**, and the science control now makes sense inside the story.

**Why this is more than new paint.** Hamlet's council can't do anything themselves. They can only let senses through to a mind that has actually been mapped. "The first prince whose entire mind has been mapped" is simply what MaleCNS is. The why-now claim hasn't changed: only a male CNS has his leg, neck, brain and wing in one graph.

---

## The Game Designer: how the reskin plays

**The mechanics don't change. Every name and every screen does.** The verb is still **signal**.

**The Privy Council, one per phone:**

| Title | Sense | Controls | Real neurons | Lore line |
|---|---|---|---|---|
| **Royal Lookout** | Eyes | Hold left/right eye | LC10a, LPLC2, LC4 | "Watch for the Princess. Watch for the Giant." |
| **Royal Perfumer** | Nose | Hold left/right antenna | Or47b (courtship scent), Or42b (the feast), Or67d (a rival's scent) | "A rival's scent on her kills the mood." |
| **Royal Taster** | Feet | Tap while touching her | Foreleg ppk23 | "No suitor proceeds without the Taster." Flies really do taste with their feet. |
| **Royal Spymaster** | Ears | Hold to listen | JO sound and wind neurons | "Hear the Giant's whoosh before it lands." |

**One night at the ball: three trials plus a finale.** Everything below is scripted except Hamlet, whose moves come from the brain simulation.

| Trial | What happens | New pressure | Real biology behind it |
|---|---|---|---|
| **I. The Garden Audience** | Meet Miranda (tutorial) | None | Chasing, tapping, singing |
| **II. The Banquet** | The feast's fermenting fruit pulls him toward the table. Sir Cheapdate leaves his scent around her | Food smell vs her; a rival's scent | Vinegar draws flies to food through Or42b. A rival male's cVA puts other males off |
| **III. The Giant's Shadow** | The Giant's hand strikes; Sir Indy won't quit | Swatter, fake shadows, a persistent rival | LC4 and LPLC2 connect straight to the giant fiber |
| **Finale: the Royal Wedding** | Fanfare, crowns, then the Chronicle of honors | None | None |

- **Win:** sing to her for 5 seconds total, near her and facing her.
- **Lose:** SPLAT ("The Giant claims another suitor"), the rival sings first, or she retires to her chambers.

**Joining, the Jackbox part:**
1. The main screen shows the room code as a **wax seal** with 4 consonants, plus a QR code and "royalflyness.club".
2. On their phone, each player signs their name on a scroll, then picks a heraldic crest.
3. The phone becomes that role's card, with a stamp sound.
4. The reconnect and role-merging rules from the last plan stay the same.

**The first 30 seconds:**
- The Herald's voice announces the ball.
- Each phone shows its crest.
- The Herald says: "Lookout, Her Highness is to your left."
- Hamlet turns, walks and touches her. The Taster's phone flashes TAP.
- His wing buzzes, and the pIP10 bar lights up on the "Royal Nervous System" chart.

**Art for a team without an artist: an illuminated manuscript.**
- Parchment background, ink-line fly sprites with tiny crowns, and heraldic crests for each role.
- Margin doodles of bugs. Medieval manuscripts really are full of insects in the margins.
- Titles in UnifrakturMaguntia and body text in IM Fell English (both free on Google Fonts).
- The neck panel becomes the Royal Nervous System, drawn like an old anatomy chart with the real neuron names in small type.

**Audio (this is also the ElevenLabs entry):**
- **Voices:** the Herald announces, Miranda reacts, and Clown the Jester roasts the council during the Chronicle.
- **Sound effects:** fanfares, the Giant's whoosh, SPLAT, the seal stamp, wedding bells.
- **Music:** a court-dance loop, plus a tense version for Trial III.
- **The Spymaster's phone** plays the whoosh through its own speaker.

**Accessibility:** same two modes as before, hold-to-toggle and audio-only Nose/Ears, plus **captions on every voice line**.

---

## The Realist: cost, stack, schedule

**What the reskin costs:**
- Lore, names and art direction: nearly free, because the art style is decided either way.
- Trial II (banquet and rival): about 3 hours.
- Voice and audio: about 4 hours in total, spread across people.

**Prize integrations.** Only take ones the game needs anyway:
- **ElevenLabs:** the game needs a host voice.
- **DigitalOcean:** the game needs a relay server.
- **GoDaddy Registry domain:** the game needs a join URL.
- **Gemini:** the agents need an LLM.
- **Tiger Data:** only after the 03:00 freeze, if at all.

**Updated architecture:**

```
phones (web page)  <->  relay on a DigitalOcean Droplet at royalflyness.club
                        (Caddy gives HTTPS/WSS automatically once the domain points at it)
                              ^ laptop connects OUT (works on any venue Wi-Fi)
                              v
        game server (Python, laptop): arena + body @ 50 Hz, whole MaleCNS brain,
        TRUE PRINCE / CHANGELING matrices, Chronicler shadow brains
              |- Matchmaker + Master of Trials (Gemini): between rounds and overnight
              |- Voice: ~80 lines, sound effects and music generated in advance (ElevenLabs);
              |         the live Chronicle is written by Gemini, then spoken by ElevenLabs
              v local WebSocket, 30 Hz
        Godot 4 host: manuscript main screen, seal + QR, Royal Nervous System chart, audio
```

**Renamed agents** (the jobs are the same as last plan):

| Agent | Job | Tools | Runs on |
|---|---|---|---|
| **The Matchmaker** | Writes each trial: layout, rival suitor, Herald intro | JSON schema output | Gemini |
| **The Master of Trials** | Runs each trial with bot councils on the True Prince and the Changeling, then certifies it or sends a revision | `run_trials`, `get_trace` | Gemini (function calling). The pass/fail rule is code |
| **The Chronicler** | Replays the trial with each sense switched off and awards honors | Shadow brains | Code; Gemini writes the Jester's lines from its numbers only |

**Safety rules:**
- No LLM or voice call ever sits in the live game loop.
- The live Chronicle plays behind a 3 to 5 second "The Chronicler consults the scrolls..." animation.
- If Gemini or ElevenLabs is slow, the game falls back to pre-generated lines.

**Schedule (starting at 13:15):**

| Time | Brain (Neil) | Server + agents | Phones + relay + audio | Godot + art |
|---|---|---|---|---|
| 13:15-15:15 | See "First 2 hours" below | | | |
| 15:15-18:00 | Test every sense on the True Prince vs the Changeling; tune | Real brain in the loop; rounds; win/lose | Reconnect, role merging, LAN fallback; pick 3 voices | Royal Nervous System chart; Hamlet and Miranda sprites |
| **18:00** | **Controllability decision (same 3 tests as before) + first playable** | | | |
| 19:00-23:00 | Record and replay; check every gene fact for the cards | Trials II and III; Chronicler v1 | ElevenLabs batch: lines, sound effects, music; Spymaster phone audio | Chronicle screen, trial intro cards, audio hookup |
| **23:00** | **Four strangers play it** | | | |
| 23:00-03:00 | Parallel `run_trials` | Matchmaker + Master of Trials on Gemini | Captions, accessibility, live Chronicle voice | Level Lab screen, polish, Royal Decree (honesty) panel |
| **03:00** | **Fallback checkpoint** (same rules as before) | | | |
| 03:00-07:00 | Batch-certify trials on the laptop or a DigitalOcean CPU Droplet; sleep in shifts | | | |
| 07:00-09:00 | Demo video (aim for 90 s), screenshots, Devpost text | | | |
| 09:00-10:30 | Feature freeze. Rehearse the 3-minute and 5-minute versions; test joining from fresh phones | | | |
| **10:30-11:00** | **Devpost project exists with all 4 members, public repo, tracks selected** | | | |
| 11:00-11:45 | Final check of links and video. Submit | | | |

**New risks:**
- **Scope creep from sponsor prizes.** The rule above handles it: only integrations the game needs anyway.
- **An API being down during judging.** The game still runs, because everything is pre-generated or has a fallback.
- **Lore overstating the science.** Neil checks every fact card before it ships.

---

## The Pitchman: name, tracks, demo

**Name: *His Royal Flyness*.** Subtitle: *A Courtship by Committee*. Domain: `royalflyness.club` (check it's available).

**One-liner:** "Prince Hamlet can't see, smell, taste or hear. You and three friends are his senses, and his real, fully mapped nervous system decides what to do with you."

**Which tracks to enter:**

| Track | Enter? | Why |
|---|---|---|
| First / Second Overall | **Yes** | See the judging criteria below |
| **Game Jamathon** (3 winners) | **Yes, main target** | Functional, polished, creative, and tied to the royalty theme in every name and screen |
| **Most Engaging Demo** | **Yes** | The judges play it on their own phones |
| **[MLH] ElevenLabs** | **Yes** | Herald, Princess and Jester voices, live commentary written from game data, generated sound effects and music |
| **[MLH] GoDaddy Registry domain** | **Yes** | The domain is the join URL, which judges type during the demo |
| **[MLH] DigitalOcean** | **Yes** | Relay hosting, plus an optional overnight certification server |
| **[MLH] Gemini API** | **Yes, if you choose Gemini** | The Matchmaker, the Master of Trials' function calls, and the Jester's script |
| [MLH] Tiger Data | Only if there's time after 03:00 | It could store trial time-series and power the Level Lab stats, but it's an extra add-on |
| Best First Time Hack | **Only if all four of you are first-timers** | A prize most teams can't enter |
| Health Beyond the Clinic, Community Impact, Entrepreneurial | Skip | The fit isn't clear, and organizers can drop you from tracks that don't fit |
| T. Rowe, DoIT, Environmental, Cyber, Solana, Snowflake, Backboard | No | No fit |

There's an Education tag but no Education prize this year. Use the education angle for the **Impact** score anyway.

**How the project maps to the judging criteria:**
- **Creativity:** a royal cast made of real genes, senses split across phones, and the Changeling.
- **Technical complexity:** all 166,606 neurons running live at 50 Hz, phone networking, and the agent certification loop.
- **Impact:** more than 100 community projects appeared in three weeks, and almost all of them just show a fly playing a game. Ours puts you inside the fly, teaches sensory integration and scientific controls, and needs no install, so it works in a classroom.
- **Execution:** the fallback plan.

**Demo script (3 minutes; the Game Jam version adds Trial II and an art/audio walkthrough, for up to 5):**
- **0:00 to 0:20, the Herald.** "Hear ye!" Then: "Prince Hamlet is a real male fruit fly. We run his entire nervous system, 166,000 neurons. You are his senses." Judges scan the seal QR code.
- **0:20 to 0:50, the Garden.** His wing buzzes. "That serenade is pIP10, a male-only neuron. The Taster's tap went up his leg, through his neck, into his brain and back down to his wing."
- **0:50 to 1:40, the Giant's Shadow.** People start shouting. He jumps. "The only thing faster than the Giant's hand is the Giant Fiber, the real neuron that fires his escape."
- **1:40 to 2:05, the Chronicle.** The Jester's voice roasts the council, and honors appear on each phone.
- **2:05 to 2:35, the Changeling.** Flip the toggle and replay the same trial. Show the certified numbers: [True Prince win %] vs [Changeling win %]. These come from real results only.
- **2:35 to 2:50, the Level Lab log.** Matchmaker, Master of Trials, revision, certified.
- **2:50 to 3:00, the Royal Decree.** "Every name in this kingdom is a real fly gene. The wiring is real. Everything we assumed, we tell you."

**Devpost checklist:**
- Public repo.
- A demo video of at least 30 seconds, including the Changeling moment.
- All four members added.
- Tracks selected.
- The Royal Decree (honesty statement) in the description.
- "Try it out" link: the domain.
- Built-with tags: Godot, Python, SciPy, Gemini, ElevenLabs, DigitalOcean.

---

## Council consensus

- **Mechanics:** unchanged from the last plan.
- **Lore:** Prince Hamlet's Privy Council; three trials and a wedding; rivals named after real genes; the Changeling as the ablation toggle.
- **Prizes:** five natural integrations (ElevenLabs, DigitalOcean, the domain, Gemini, and the Game Jam theme), plus Overall and Most Engaging Demo.
- **Honesty:** the Royal Decree says the wiring is real, and that the strengths, signs, walking code and the Princess are ours.

**Four decisions for the team, with the Council's recommendations:**
1. **LLM for the agents: Gemini.** It makes you eligible for a prize and costs almost nothing to choose now. Claude still works if you'd rather.
2. **Name and domain: *His Royal Flyness* at `royalflyness.club`.** Ask the MLH coach for the domain coupon.
3. **First Time Hack:** is this every member's first hackathon?
4. **Presenter:** not Neil (Neil handles science questions), same as your earlier plan.

## First 2 hours (13:15 to 15:15)

- **Everyone, first 15 minutes:**
  - Create the fresh public repo.
  - Create the Devpost project as a draft and add all four members.
  - Claim the MLH codes: ElevenLabs, DigitalOcean credits, the domain coupon.
  - Get a Gemini API key from AI Studio.
- **Brain (Neil):** everything from the last plan's first 2 hours (graph, `io_sets.json`, rate model, gain sweep). The shuffled brain is now called `changeling.py`.
- **Server + agents:** tick loop with a fake brain, arena, body, and the Trial JSON schema with lore fields (title, rival, Herald intro).
- **Phones + relay:** DigitalOcean Droplet, domain pointed at it, Caddy, relay, the seal-code join screen, and four crest pages.
- **Godot + art:** manuscript main-screen layout, seal and QR, lobby with crests. Pick the fonts and the parchment look.

**Outcome:** the team asked to put everything into this repo and rename it for the new idea (this commit).

Sources: see [../RESEARCH.md](../RESEARCH.md).
