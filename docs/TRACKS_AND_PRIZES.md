# Tracks and prizes

hackUMBC 2026 has 20 non-cash prizes. Teams can enter as many tracks as they like, but each entry must clearly fit the
track's description, and organizers can drop a project from a track that doesn't fit. Full event rules: [HACKUMBC_2026.md](HACKUMBC_2026.md).

## Decision table

| Prize | Enter? | Why | Extra work |
|---|---|---|---|
| **First Overall** (PS5 Slim) / **Second Overall** (Switch Lite) | Yes (automatic) | Judged on creativity, technical complexity, impact, execution (mapping below) | Impact framing in the pitch |
| **Game Jamathon** (Game Dev Club, 3 winners) | **Yes, main target** | Must be functional, good-looking, polished, creative, with a strong connection to the theme (royalty). We have a royal court, a prince and princess, the Herald, the Giant, the Changeling, and real gene names | Royalty everywhere; polish; a 5-minute version of the demo for the industry judges |
| **Most Engaging Demo** (TONOR mic) | **Yes** | The judges play on their own phones | None |
| **[MLH] Best Use of ElevenLabs** (earbuds) | **Yes** | Herald, Princess and Jester voices; live commentary written from game data; generated sound effects and music; the Spymaster's phone speaker | ~4 h spread across people |
| **[MLH] Best Domain Name from GoDaddy Registry** | **Yes** | The domain is the join URL judges type during the demo | 15 min |
| **[MLH] Best Use of DigitalOcean** (retro mouse) | **Yes** | The relay and phone page run on a Droplet; optional overnight certification server | ~1 h (we need a relay anyway) |
| **[MLH] Best Use of Gemini API** (swag kits) | **Yes, if decision O1 = Gemini** | The Matchmaker (structured output), the Master of Trials (function calling on the brain), the Jester's script | Near zero if decided now |
| **Best First Time Hack** (Keychron K10) | **Only if all four of us are at our first hackathon** | A prize most teams can't enter | None |
| [MLH] Best Use of Tiger Data | Maybe, P2 | Could store every test run and 50 Hz output readings as time series, with continuous aggregates for the certification stats | 2 to 3 h, a cloud dependency. Only after the 03:30 checkpoint |
| Health Beyond the Clinic (Pre-Med Society) | Skip | "Health education" is a stretch for this game; the fit isn't clear | Would need a real health-education component |
| Community Impact and Social Innovation (STARS) | Skip | Needs a specific Baltimore/UMBC community need and an impact-evaluation plan | Not our focus |
| Best Entrepreneurial Idea | Skip | Needs a business case | None |
| [MLH] Backboard | Skip | Memory for the Princess across sessions is a bolt-on | None |
| T. Rowe Price, DoIT, Environmental, CyberDawgs, Solana, Snowflake | No | No fit | None |

The Devpost page tags the event "Education", but there's **no education prize** this year. We still use the education angle for the **Impact** criterion.

## How we score on the judging criteria

| Criterion | Our answer |
|---|---|
| **Creativity** | You don't watch a fly play a game; you *are* one of its senses. A royal cast named after real fly genes. The Changeling. |
| **Technical complexity** | All 166,606 neurons of a real male nervous system running live at 50 Hz on a laptop; phone networking with rooms and reconnect; an agent loop that designs trials and certifies them against a scrambled brain; counterfactual credit from shadow brains; generated voice |
| **Impact** | More than 100 fly-connectome community projects appeared in three weeks, and nearly all show a fly playing an existing game. Ours teaches the core idea of neuroscience (behavior comes from combining senses) by making you one of the senses. It shows honestly what a wiring diagram does and doesn't do (the Changeling is a scientific control you can play). It runs on any phone with no install, so it works in a classroom |
| **Execution** | Fallbacks at every layer; strangers tested it at 23:30; rehearsed demo |

## Integration specs

### ElevenLabs
- **Claim:** MLH sends a promo code during event week (3 months free). Create the account from that link.
- **What we build:**
  1. **Pre-generated voices** from `lines.csv` ([LORE.md](LORE.md#voice-line-bank)): Herald, Princess Miranda, Clown the Jester, rival one-liners. Use the expressive v3 model with audio tags.
  2. **Live voice:** the Jester's Chronicle lines. Gemini writes them from the Chronicler's numbers only; ElevenLabs Flash (low latency) speaks them; captions shown.
  3. **Sound effects** (sound effects API): fanfare, seal stamp, the Giant's whoosh, SPLAT, gasps, wing buzz, wedding bells.
  4. **Music** (music API): court dance, banquet, the Giant's Shadow, wedding theme.
  5. The Spymaster hears the whoosh on their own phone.
- **Fallback:** everything except the live Chronicle is pre-generated; the live line falls back to a pre-generated one after about 4 s.
- **Pitch line:** "Every voice, sound and note in the kingdom is generated, and the Jester's roast is written live from what your team actually did."

### DigitalOcean
- **Claim:** ask the MLH coach for credits.
- **What we build:** the smallest Droplet running the relay (`relay/relay.py`) behind Caddy (automatic HTTPS) at the domain; serves the phone page.
  Optional: a CPU-optimized Droplet overnight to batch-certify trials (measure its speed first; destroy it after).
- **Pitch line:** "Every phone in the room talks to the prince through our DigitalOcean relay, which is why it works on any Wi-Fi."

### GoDaddy Registry domain
- **Claim:** the MLH domain coupon (GoDaddy Registry TLDs such as .club, .co, .us, .biz, .design, .wiki).
- **Candidates:** `royalflyness.club` (first choice), `hisroyalflyness.club`, `royalflyness.co`, `flycourt.club`. Check availability.
- **Use:** the join URL on the main screen and the "Try it out" link on Devpost.

### Gemini (if chosen)
- **Model:** Gemini 3.8 Flash (released 2 Sept 2026; supports function calling and JSON-schema output). Confirm the exact model ID in AI Studio.
- **Uses:** the Matchmaker (structured output = the Trial schema), the Master of Trials (function calling: `run_trials`, `get_trace`), the Jester's script.
- **Pitch line:** "Gemini designs every trial and then has to prove it's fair by calling our fly brain as a tool: the real prince must be able to win, and the Changeling must mostly lose."

### Tiger Data (P2 only)
- Tables: `runs(run_id, trial_id, brain, seed, win, reason, finished_at)`; hypertable `readouts(ts, run_id, group, value)`.
- A continuous aggregate of win rate per trial and brain feeds the Level Lab screen.
- Only if P0 and P1 are done. Needs the Tiger Cloud free tier and a network connection during judging.

## Devpost submission form: tick these

- [ ] Game Jamathon
- [ ] Most Engaging Demo
- [ ] [MLH] Best Use of ElevenLabs
- [ ] [MLH] Best Domain Name from GoDaddy Registry
- [ ] [MLH] Best Use of DigitalOcean
- [ ] [MLH] Best Use of Gemini API (if we used Gemini)
- [ ] Best First Time Hack (only if all four are first-timers)
- [ ] [MLH] Best Use of Tiger Data (only if actually built)
- Overall prizes need no box.
