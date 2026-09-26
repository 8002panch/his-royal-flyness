# Decisions

Log of what's decided, why, and what was rejected. Newest open questions at the top.

## Open (decide at kickoff)

| # | Question | Recommendation | Why |
|---|---|---|---|
| O1 | LLM for the agents (Matchmaker, Master of Trials, Jester's script) | **Gemini** (Gemini 3.8 Flash, released 2 Sept 2026; confirm the model ID in AI Studio) | Makes us eligible for **[MLH] Best Use of Gemini API**. It supports function calling and JSON-schema output, which is all we need. The switching cost is near zero if we decide now. Claude also works if the team prefers it; there's no Anthropic prize here. |
| O2 | Name and domain | ***His Royal Flyness***, subtitle *A Courtship by Committee*, at **`royalflyness.club`** | It's a pun on "His Royal Highness", it fits the theme, and .club suits a party game. Check availability; fallbacks `hisroyalflyness.club`, `royalflyness.co`. The domain is the join URL, which is also the GoDaddy Registry prize entry. |
| O3 | Is this everyone's first hackathon? | Answer honestly | If all four are first-timers, enter **Best First Time Hack** (a prize most teams can't enter). |
| O4 | Presenter | Not Neil | Same as the earlier plan. Neil coaches and takes the science questions. |

## Pending tests (decided by data, not by vote)

| # | Question | When | Rule |
|---|---|---|---|
| T1 | Does the whole-CNS model steer toward the princess? | 20:00 gate | If not, switch to **hybrid steering** (the brain decides go/jump/sing/stop, code picks the direction) and say so. See [BUILD_PLAN.md#gates](BUILD_PLAN.md#gates). |
| T2 | Does Taster tapping push pIP10 (song) clearly, and more than in the Changeling? | 20:00 gate | If not: re-tune, or include connections with 3 or more synapses along that path. Last resort: trigger the song from the pC1 cluster and say so. |
| T3 | Is the Nose too far from movement to matter (3 or more hops)? | 20:00 | If weak, the Perfumer's main job becomes the mood (courtship cluster) rather than steering. |
| T4 | Does the Changeling look clearly different in live play? | 23:30 | If not, the demo leads with the certified bot numbers instead of the live replay. |

## Decided

| Date/time | Decision | Why | Rejected |
|---|---|---|---|
| 26 Sept | **Party co-op where each player is one of the fly's senses** (team choice from the three finalists) | Best demo (judges play), clear 30-second loop, strongest "Most Engaging Demo" fit | *Reviewer 2* lab sim, *Mixed Signals* pheromone strategy (see [council/01_phase0_idea_factory.md](council/01_phase0_idea_factory.md)) |
| 26 Sept | **Jackbox-style joining**: room code + QR on the main screen, phones as controllers in the browser | No install, any phone, instant for judges | Gamepads only (kept as the keyboard/gamepad fallback) |
| 26 Sept | **Royalty reskin**: Prince Hamlet, Princess Miranda, the Privy Council of senses, the Giant, the Changeling | The announced theme is royalty (Game Jamathon requires a strong theme link). Real gene names make the lore teach real biology | Generic lab/fly skin |
| 26 Sept | **Whole CNS, no subcircuit** (all 166,606 neurons, connections with 5 or more synapses) | Everything within 3 hops of the senses and outputs is already 140,223 neurons, so no small circuit exists. The whole thing runs at 5.3 ms per step. Also answers "did you hand-pick neurons?" | Hand-extracted subcircuit (the 2-hop core of 37,004 neurons is the speed fallback) |
| 26 Sept | **Rate model**, signs from predicted transmitters, neuromodulators silenced, one tuned gain | Fast enough for 50 Hz; honest to state | Spiking LIF (the Shiu-style whole brain took 42 s per simulated second on Neil's M2) |
| 26 Sept | **The Changeling** = shuffle each connection's sender among same-sign neurons, keeping (receiver, synapse count) | Every neuron keeps its exact total input and excitatory/inhibitory mix, so the random brain doesn't just explode. Fair control | Global synapse-count shuffle (the earlier spike showed activity explodes, which looks rigged) |
| 26 Sept | **Python owns the game state; Godot only renders** | The Master of Trials and the Chronicler must replay rounds headless | Game logic in Godot |
| 26 Sept | **Cloud relay on DigitalOcean**, laptop connects out; LAN hotspot and keyboard as fallbacks | Venue Wi-Fi often blocks device-to-device traffic. Also the DigitalOcean prize | Laptop as the only server |
| 26 Sept | **No LLM or voice call inside the live game loop**; everything pre-generated or behind a short animation | Demo reliability | Live LLM host |
| 26 Sept | **The Princess, rivals and the Giant are scripted** | Scope; honest to say. Female CNS (BANC) is a stretch goal | Two brains live |
| 26 Sept | **2D body, not flybody/MuJoCo** | 20 build hours | flybody 3D (stretch) |
| 26 Sept | **This repo = private planning repo; fresh public repo for the submission** | This repo has commits from before the hacking window | Submitting this repo |
| 26 Sept | Prize integrations only where the game needs them anyway (voice, relay, domain, agent LLM) | Avoid bolt-ons that eat the night | Tiger Data, Backboard, Snowflake, Solana as core work |
| 26 Sept 15:30 | **Roles by name, equal load (about 15¼ h of tasks each, same hours in every block):** Neil = brain + science; Arnav = game server; Ved = phones, relay, cloud + AI agents; Anshul = Godot host, art + audio | The user asked for an equal split with a folder per person. The Chronicler math, `run_trials` and bots moved to Neil; the Gemini agents to Ved; ElevenLabs audio to Anshul, to even out the loads | Unnamed roles picked at kickoff |
| 26 Sept 15:30 | **Kickoff moved from 13:15 to 15:45**; gate at 20:00, stranger test 23:30, checkpoint 03:30 | Planning ran long | None |
| 26 Sept 15:30 | **Public submission repo `8002panch/his-royal-flyness` created** (inside the hacking window) with the plan docs, per-person folders in `team/`, and empty component folders. No code yet | Rules: every commit must be between 12:00 PM Sat and 11:45 AM Sun | Reusing this planning repo |
| 26 Sept 15:30 | **Kept out of the public repo:** the earlier idea's archive (included pre-event code; deleted on 26 Sept), the reference probe scripts, the Codex handoff plugin and scripts (pushed before 12:00) | "Building upon existing projects" makes a project ineligible for prizes | Copying everything |
