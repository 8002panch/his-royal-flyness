# What wins at hackUMBC (analysis, 2026-09-23)

**Source:** every hackUMBC Devpost gallery (13 events, 2014–2025, plus the April 2026 mini hackathon). We scraped winners from
2019–2026 and prize names and tech stacks for **2022–2026** (≈60 winning projects).
Raw data: [hackumbc_winners_2022_2026.csv](hackumbc_winners_2022_2026.csv).

## Size of the field
| Event | Submissions | Winners | Winner rate |
|---|---|---|---|
| 2025 | 143 | 20 | 14% |
| Fall 2024 | 101 | 14 | 14% |
| Fall 2023 | 47 | 12 | 26% |
| Fall 2022 | 57 | 13 | 23% |
| Fall 2021 | 64 | 20 | 31% |
| Mini 2026 (12 h) | 32 | 5 | 16% |

About 1 in 7 projects wins *something* now that the event has grown. There are 15+ prize categories, so a team can realistically win 2–3 at once
(TestifAI: 2nd Overall + Educational; GreenCrew: Health/Env + .Tech domain; Play More: 2nd Overall + Booz Allen).

## Top winners
| Year | 1st Overall | 2nd Overall | Best AI/ML | Most Engaging Demo |
|---|---|---|---|---|
| 2025 | **Focus Flow**: EEG headset + PyTorch measures real focus (ADHD framing), team of 4 | Meridian: DevOps learning platform (solo, Gemini) | Visionary: AI app for blind users (Gemini) | Redbull Gives You Things: a joke pygame |
| 2024 | Vector Mentor: AI study companion (LangGraph), 4 | TestifAI: AI test generator, 4 | amberAI: narrates the world (OpenAI + ElevenLabs) | FairNote: career-fair recorder + summaries |
| 2023 | Voicebox: Discord voice access for deaf UMBC students, 4 | Play More: accessibility reviews for disabled gamers | Banana Blindness: webcam hand-gesture control (MediaPipe) | InspoPicker: hobby-tutorial spinner |
| 2022 | KeyLimePi: Raspberry Pi password manager, 4 | PitchShift (Unity) | n/a | n/a |
| Mini 2026 | Atlas: agentic "autopilot" for course registration | NoDoze: **webcam drowsiness detection → alarm** (won the drone) | n/a | n/a |

## Patterns

1. **Full teams win the top prize.** Every First Overall from 2022–2025 was a 4-person team. Solo and duo winners cluster in track and sponsor prizes.
2. **A named human problem, stated with a number, in the first line.** Focus Flow opens with "over 6 million children in the U.S. are diagnosed with ADHD". Voicebox opens with "over 300 deaf people at UMBC". Winners answer *"who is this for?"* before *"how does it work?"*
3. **Accessibility wins almost every year.** 2022 ASL translator (3rd Overall) + accessibility checker; 2023 Voicebox (1st) + Play More (2nd);
   2024 amberAI (AI/ML) + Visionaria (DEI); 2025 Visionary (AI/ML) + Learning Land. Blind/low-vision assistive apps took Best AI/ML in both 2024 and 2025.
4. **LLM wrappers are now saturated.** Most 2024–26 winners call Gemini/OpenAI. Judges still reward them, but they are everywhere. The one
   2025 First Overall that stood out, **Focus Flow, was real sensing + real ML on brain signals, not an LLM wrapper.** That's the closest precedent to us.
5. **Real-world sensing and hardware reach the top.** EEG (2025 1st), Raspberry Pi (2022 1st), Arduino turret, upcycled jukebox, Pi + camera for the blind.
   Live **camera computer vision** shows up constantly (Banana Blindness, NoDoze, GreenCrew, Amber Alert Helper, face recognition).
6. **"Detect something from a webcam and raise an alarm" already wins.** NoDoze (mini 2026) is structurally identical to our collision alarm and won the drone.
7. **Most Engaging Demo goes to fun and playful, not sophisticated.** It went to a joke game, a spinner and a recorder. Something a judge can *play with* beats something they watch.
8. **Sponsor and MLH prizes are the soft targets.** A bolt-on is enough (MongoDB Atlas, Streamlit, GitHub, TinyMCE, a .Tech domain, the Gemini API).
   GreenCrew picked up the .Tech domain prize on top of its main prize. T. Rowe Price runs a fintech/investor-education challenge every year.
9. **Every event has a theme** (2025 "center stage" / arcade game jam; 2024 "direct the future of tech"; 2023 movies; 2022 retro). The 2026 theme gets announced at the opening.
   Winners rarely depend on the theme, but a nod to it is free.
10. **Write-ups are complete and visual.** Winners' Devposts have screenshots, a clear Inspiration → What it does → How we built it structure, and a video.

## Honest caveats
- Judging panels change every year. These are correlations from ~60 winners, not rules.
- Nothing like a connectome project has ever entered hackUMBC, so there's no direct precedent. Focus Flow (neuro + ML + real sensing) is the nearest.
- The 2026 prize list isn't public yet (Devpost 403). Re-check it at the opening ceremony.
