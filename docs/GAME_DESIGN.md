# Game design: His Royal Flyness

*A Courtship by Committee.* Plan as of Sat 26 Sept 2026. Lore details live in [LORE.md](LORE.md); the systems behind each
mechanic are in [TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md).

## In one breath

Prince Hamlet can't see, smell, taste or hear. Up to four friends each become one of his senses on their phones. His real,
fully mapped nervous system runs live and decides what to do with whatever you let through. Get him to Princess Miranda and
make him sing before the Giant's hand comes down.

| | |
|---|---|
| Genre | Party co-op, 1 to 4 players, Jackbox-style (phones as controllers, one shared main screen) |
| Player verb | **Signal** |
| 30-second read | "Each phone is one of the fly's senses. He only feels what you let through. Get him to the princess and make him sing." |
| A session | One Royal Ball: three trials and a wedding, about 8 minutes |
| The fly brain's job | All 166,606 MaleCNS neurons run every tick. Only open senses feed it. Named output neurons move the body |

## Core loop

1. Scan the wax seal (QR) or type the code at the domain; sign your name; get a royal role.
2. **Trial:** find her, get close, touch her, sing (about 90 seconds).
3. **The Chronicle:** the game replays the trial with each sense switched off and shows who really moved him.
4. Next trial: harder, designed by the Matchmaker and certified by the Master of Trials.
5. After Trial III: the Royal Wedding.

## The Privy Council (one role per phone)

| Title | Sense | Phone shows (only this player sees it) | Controls | Real input neurons | Useful for | Goes wrong when |
|---|---|---|---|---|---|---|
| **Royal Lookout** | Eyes | LEFT EYE and RIGHT EYE panels with that side's view as blurry hex pixels; red flash on looming | Hold the left and/or right panel to open that eye | LC10a (275), LPLC2 (185), LC4 (126), split by side | Turning and walking toward her; letting him see the Giant so the Giant Fiber fires | An eye is open on the Giant's side and he jumps away from her; a fake shadow makes him jump for nothing |
| **Royal Perfumer** | Nose | Two antennae, each with three scent bars: Her Highness, the Feast, a Rival's scent. Scent plumes are hidden on the main screen | Hold the LEFT or RIGHT antenna to sniff | ORN_VA1v (Or47b, courtship scent, 130), ORN_DM1 (Or42b, fermenting fruit, 74), ORN_DA1 (Or67d, the rival male's cVA, 204) | Getting him interested and steering by scent | Sniffing the Feast pulls him to the table; sniffing a rival's cVA kills the mood |
| **Royal Taster** | Feet | His six feet on a pad; glows gold when his forelegs touch her | Tap while touching. Each tap is one foreleg tap on her | Foreleg ppk23 pheromone-taste neurons (71: 37 left, 34 right) | Confirming she's royalty, which drives the courtship cluster and triggers the serenade | Tapping when he isn't touching her does nothing, because there's nothing to taste |
| **Royal Spymaster** | Ears | Wind meter and sound meter; the Giant's whoosh plays from the phone's speaker | Hold to listen | JO-C/E (wind), JO-A/B (sound: a rival's song), 473 total | Hearing the Giant's hand before it lands (the ear neurons connect straight to the Giant Fiber); hearing rivals | Listening during a false-alarm gust makes him jump |

**Why it plays well together:** no role is enough alone. The Lookout can aim him but can't make him court. The Taster makes
him court but only after the others get him there. The Perfumer knows where things are but can only hint. The Spymaster
hears the danger first. Players end up shouting "close your left eye!" and "don't sniff, Sir Cheapdate is over there!",
and the brain settles every argument.

### Player counts

| Players | Roles |
|---|---|
| 1 | Keyboard mode: Q/W = left/right eye, O/P = left/right antenna, Space = tap, L = listen |
| 2 | Lookout + Taster · Perfumer + Spymaster |
| 3 | Lookout · Perfumer · Taster + Spymaster |
| 4 | One each |
| 5+ | The Court (audience). Stretch goal: vote on the next trial's twist from the certified list |

## A night at the Royal Ball (the trials)

| Trial | What happens | New pressure | Senses tested | Real biology behind it |
|---|---|---|---|---|
| **I. The Garden Audience** (tutorial) | Meet Miranda in the palace garden. She wanders slowly | None | Lookout, Taster | Males track females with LC10a, tap them with their forelegs to taste pheromones, then sing |
| **II. The Banquet** | The Royal Feast (fermenting fruit) sits on one side of the hall. Sir Cheapdate, tipsy, circles her and leaves his scent | A food smell that competes with her; a rival's scent that kills the mood; a rival who might sing first | Perfumer | Vinegar smells pull flies to food through Or42b. A rival male's cVA puts other males off |
| **III. The Giant's Shadow** | The Giant's hand strikes the hall, with fake shadows mixed in. Sir Indy, the Knight Who Is Not Dead Yet, keeps coming back | Real and fake swats; a persistent rival | Lookout, Spymaster | LC4 and LPLC2 looming detectors and the ear neurons connect straight to the giant fiber, the neuron that fires the escape jump |
| **Finale: the Royal Wedding** | Fanfare, crowns, bells, then the final Chronicle | None | None | None |

The Matchmaker generates more trials in these three styles (garden, banquet, great hall). Only trials certified by the
Master of Trials go into rotation ([TECH_ARCHITECTURE.md#agents](TECH_ARCHITECTURE.md#agents)).

## Winning, losing, scoring

- **Win the trial:** he sings (pIP10 above its threshold) while within about 2 body lengths of her and facing her,
  for **5 seconds in total** before the candle burns out (90 seconds).
- **Lose the trial:**
  - **SPLAT**: the Giant's hand lands on him. "The Giant has claimed another suitor."
  - **A rival wins**: the rival's scripted serenade reaches 5 seconds first. "Alas! The Princess favors another."
  - **Timeout**: the candle burns out. "Her Highness retires to her chambers."
- **Stars (1 to 3):** win = 1 star, win with more than 30 seconds left = +1, no jumps triggered by fake shadows = +1.
- A lost trial still moves the ball forward (the party keeps moving). The final screen totals the stars.

## The Chronicle (between trials, about 20 seconds)

- The Chronicler replays the trial with each sense switched off and measures how much his steering, walking, jumps and
  song changed without it ([TECH_ARCHITECTURE.md#the-chronicler](TECH_ARCHITECTURE.md#the-chronicler)).
- **Main screen:** each crest's share of the credit as a banner, one "Knight of the Realm" (the MVP), and one blunder of the round.
- **Each phone:** that player's personal numbers. For example "You caused 41% of his turning", "Your left eye caused 2 jumps",
  "Your sniff at 0:47 ended the romance". These numbers are examples; real ones always come from the Chronicler.
- **Voice:** Clown the Jester reads two or three roast lines written from those numbers (Gemini writes, ElevenLabs speaks).
  If the live line isn't ready in about 4 seconds, a pre-recorded generic line plays instead.

## Joining (the Jackbox part)

1. **Main screen:** a big wax seal with a 4-letter code (consonants only, so it never spells a word), a QR code, and the domain,
   e.g. "Go to **royalflyness.club** and present your seal".
2. **Phone:** open the link (the QR fills in the code) → sign your name on a scroll → pick a heraldic crest, or "Let the Herald decide".
3. The phone flips to that role's card with a stamp sound, one line of instructions and the controls.
4. **Reconnecting:** phones sleep. Opening the page again with the same name (stored in the browser) gets you your role back.
   If a sense drops mid-trial, the game pauses for up to 5 seconds and shows "The Royal Lookout has fainted!".
5. **Leaving:** the host can reassign an empty role to someone else or merge it into another player (see the table above).

## The first 30 seconds (tutorial)

| Time | Main screen | Phones |
|---|---|---|
| 0 to 10 s | The Herald: "Hear ye! The Royal Ball begins!" Seal code and QR. Crests light up as players join | Join, sign, crest |
| 10 to 20 s | The Garden. Herald: "Lookout, Her Highness is to your left!" Hamlet turns and walks. The Royal Nervous System chart lights up from LC10a down to the steering neurons | The Lookout holds LEFT |
| 20 to 30 s | Hamlet touches her. His wing buzzes and the pIP10 bar lights up. Hearts. "Her Highness is charmed!" | The Taster's pad glows and flashes TAP TAP TAP |

The tutorial gives a hint only for the next useful action. Hints stop after the Garden.

## Screens

**Main screen (Godot):** title/lobby → role reveal → trial intro card (with a Royal Fact) → trial → Chronicle →
next trial ... → wedding → final Chronicle. Plus two utility screens: the **Level Lab** (the Matchmaker/Master of Trials log)
and the **Royal Decree** (the honesty panel).

**Main screen layout during a trial:**
- **Center:** the hall, top-down, framed like an illuminated manuscript page (margins with doodled insects).
- **Right:** the **Royal Nervous System** chart: brain at the top, neck, nerve cord below. Glowing bars for each sense's
  input neurons (LC10a L/R, LPLC2/LC4 L/R, ORN types, ppk23, JO) and for the outputs (DNa02 L/R, DNp09, DNg100, MDN, DNp01, pIP10),
  with real neuron names in small type.
- **Top:** the trial title in blackletter; the timer is a candle burning down.
- **Bottom:** captions for every voice line; the four crests, lit while that sense is open.
- **Corner badge:** TRUE PRINCE or CHANGELING.

**Phone screens (browser):** join → crest pick → role card → live controls → Chronicle (personal honors) → "Next trial" wait screen.

## Art direction (no dedicated artist needed)

- **Look:** an illuminated manuscript. Parchment background, ink-line sprites, flat color, gold leaf accents. Medieval
  manuscripts really are full of insects in the margins; we use that for decoration.
- **Palette:** parchment `#F3E9D2`, ink `#2B2118`, royal blue `#1F3A8A`, crimson `#9B1C1C`, gold `#C9A227`. The four crests use
  distinct shapes as well as colors (Lookout = eye sigil, Perfumer = flower, Taster = boot, Spymaster = ear), so no information
  depends on color alone.
- **Fonts (Google Fonts):** titles in **UnifrakturMaguntia**, body in **IM Fell English**. Keep blackletter for titles only; it's hard to read small.
- **Sprites:** Hamlet in gold with a tiny crown; Miranda with a tiara and a different wing tint; rivals in muted colors with
  heraldic tabards; the Giant's hand as a big gray shadow that grows (drawn, not photographed).
- **Eyes phone:** pixelate the hall render into hexes on the server and send brightness values (cheap and looks great). MVP fallback: icons sized by closeness.
- **Juice:** wing buzz shake, jump arc with a dust puff, SPLAT ink blot, hearts, fanfare banners, candle flicker.

## Audio direction (this is also the ElevenLabs entry)

- **Voices (ElevenLabs):** the **Herald** (booming announcer), **Princess Miranda** (a few reactions), **Clown the Jester**
  (Chronicle roasts), and one-liners for rivals. About 80 lines generated in advance from [LORE.md](LORE.md#voice-line-bank).
- **Live voice:** the Jester's Chronicle lines are written from the Chronicler's numbers and spoken while the scroll animation plays.
- **Sound effects (ElevenLabs sound effects API):** fanfare, seal stamp, the Giant's whoosh, SPLAT, crowd gasp, wing buzz, wedding bells.
- **Music (ElevenLabs music API):** a court-dance loop for the lobby and Garden; a tense version for the Giant's Shadow; a wedding theme.
- **Phones:** the Spymaster's phone plays the whoosh through its own speaker. Browsers only allow sound after the first tap,
  so the join button doubles as the "unlock audio" tap.
- **Captions** on every line, always.

## Accessibility

1. **Hold-to-toggle mode:** any hold control becomes tap on / tap off, for players who can't keep pressing.
2. **Play without the screen:** Perfumer and Spymaster have full audio versions. The Perfumer hears scent strength as stereo
   pitch (left/right); the Spymaster hears wind and song directly. A blind or low-vision player can fully play either role.
3. **Captions** for all voice lines; crests use shapes as well as colors; big touch targets (the whole half-screen is the button).
4. Phone vibration only works in Android browsers, so every haptic also has a visual flash.

## What's real and what's scripted (shown on the Royal Decree screen)

| Part | Where it comes from |
|---|---|
| Hamlet's decisions (turn, walk, back up, jump, sing) | The MaleCNS v1.0 wiring run as a rate model. The connection counts are real; strengths and signs are our assumptions |
| Where the senses enter and which neurons move him | Real, named cell types chosen by us (listed on the chart) |
| How output neurons become movement | Our code |
| Princess, rivals, the Giant | Scripted |
| The names | Real fly genes. The personalities are ours |

## Lessons borrowed from award-winning games

- **PEAK** (Steam 2025, Better With Friends): the fun is shared chaos and funny failure. **Different:** in PEAK everyone has a
  body. Here four people share one body, and nobody directly controls where it goes.
- **Mage Arena** (Steam 2025 Most Innovative finalist): a new kind of input can be the whole hook. **Different:** your input isn't
  carried out. It goes through a real nervous system that can ignore it or misread it.
- **Jackbox** (join by code): zero-install party onboarding. **Different:** the phones are sense organs, not answer pads.
- **Keep Talking and Nobody Explodes:** each player has information the others don't, so talking is the game.

## Stretch features (only after the 03:30 checkpoint, in this order)

1. **The Court:** extra phones vote on the next trial's twist from the certified list.
2. **Princess brain:** let her run on the female CNS (BANC). She has no pIP10, so the demo line is "she literally can't sing
   his song". Needs the synapse-density normalization ([DATA_CHECK.md](DATA_CHECK.md#caveats)).
3. **Replay theater:** rewatch the last trial side by side with the Changeling.
4. flybody 3D body.
