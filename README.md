# His Royal Flyness

*A Courtship by Committee.* Built at **hackUMBC 2026** (UMBC, Sat 26 Sept 12:00 PM to Sun 27 Sept 11:45 AM EDT).

> Prince Hamlet can't see, smell, taste or hear. Up to four friends each become one of his senses on their phones.
> His real, fully mapped nervous system (MaleCNS v1.0, all 166,606 neurons) runs live and decides what to do with
> whatever you let through. Get him to Princess Miranda and make him sing before the Giant's hand comes down.

**Status:** being built right now. Nothing below is working yet unless it says so.

## How it works (the short version)

- The main screen (Godot 4) shows the Royal Ball. Players join on their phones with a wax-seal room code.
- Each phone is one royal sense: the **Royal Lookout** (eyes), **Royal Perfumer** (nose), **Royal Taster** (feet) or
  **Royal Spymaster** (ears). You only see what your sense detects, and you choose when to let it through.
- A Python game server feeds the open senses into the male fruit fly's whole nervous system, run as a rate model, and
  named output neurons (steering, walking, escape, song) move his body.
- **The Changeling** swaps his brain for one with the same neurons, connection counts and input per neuron, but scrambled partners.
- AI agents design each trial and certify it only if the real prince can win and the Changeling mostly can't.

Full design: [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) · The whole game, state by state: [docs/GAME_FLOW.md](docs/GAME_FLOW.md) · System: [docs/TECH_ARCHITECTURE.md](docs/TECH_ARCHITECTURE.md)

## Team

| Person | GitHub | Role | Task list |
|---|---|---|---|
| Neil | `8002panch` | Brain + science | [team/neil](team/neil/README.md) |
| Arnav | `arnavp-1` | Game server | [team/arnav](team/arnav/README.md) |
| Ved | `shahved25` | Phones, relay, cloud + AI agents | [team/ved](team/ved/README.md) |
| Anshul | `darkspaz-v1` | Godot host, art + audio | [team/anshul](team/anshul/README.md) |

How the work is split (equal loads), check-in times and interfaces: [team/README.md](team/README.md).

## Repo layout

| Folder | What | Owner |
|---|---|---|
| `brain/` | MaleCNS graph build, rate model, the Changeling, probes, replay | Neil |
| `server/` | Tick loop, arena, body, sense encoders, scripted actors, rounds, recorder, links to the relay and Godot (`chronicler.py`: Neil) | Arnav |
| `agents/` | Trial schema (Arnav); Matchmaker, Master of Trials, Jester script (Ved); `run_trials`, bots (Neil) | Arnav, Ved, Neil |
| `relay/` | Phone page and WebSocket relay (DigitalOcean + Caddy) | Ved |
| `host/` | Godot 4 main screen | Anshul |
| `audio/` | ElevenLabs voices, sound effects, music | Anshul |
| `levels/` | Hand-made and certified trials, Level Lab log | Arnav, Ved |
| `data/` | MaleCNS data files (git-ignored; see [data/README.md](data/README.md)) | Neil |
| `docs/` | The plan: design, lore, architecture, build plan, rules, demo, Devpost draft | Everyone |
| `team/` | One folder per person: task list, notes, scratch | Each person |

## How to run

To be written by Arnav once it runs (target Sun 09:00). Planned: `./run.sh` starts the game server and the Godot host, and players join at the domain.

## Rules and honesty

- **All code in this repository was written during hackUMBC 2026**, inside the hacking window. The plans in `docs/` were written
  before and at the start of the event and contain no code. This project isn't submitted to any other hackathon.
  Details: [docs/RULES_COMPLIANCE.md](docs/RULES_COMPLIANCE.md).
- **The Royal Decree** (updated Sat 18:25 for the first-person design; if the team routes movement through the brain, Neil rewrites it):
  Three players steer Prince Hamlet directly: left and right, up and down, forward and back. The fourth, the Royal Seer, senses the world through his real nervous system: the MaleCNS v1.0 wiring diagram of a real male fruit fly (Berg et al., *Cell*, 2026; CC-BY 4.0) runs live as a simple rate model, and the Seer's cues (where the Princess is, where a Giant's hand is coming from, and how soon) are read from his descending neurons. The connection counts are real. Everything else is our assumption: how strong each connection is (derived from synapse counts under one tuned gain), whether it excites or inhibits (predicted from neurotransmitters), leaving out neuromodulators and connections under 5 synapses, and how positions in the game become activity in his eyes and antennae. Real neurons have dynamics, modulation and learning that this model doesn't. Swap in the Changeling (same neurons and connection counts, scrambled partners) and the Seer goes blind. If the hybrid fallback is used, the Seer's directions come from the game and only the confidence and warnings from the brain. The Princess, the Giants and the course are scripted. The names are real fly genes; the personalities are ours.

## AI tools used

- Planning documents were drafted with help from Claude (Anthropic).
- In the game: Gemini designs and checks trials and writes the Jester's lines; ElevenLabs generates voices, sound effects and music.
- Everyone on the team can explain the code they committed.

## Credits

- **MaleCNS v1.0** connectome: Berg et al., *Cell* (2026). HHMI Janelia FlyEM, Google Research, University of Cambridge and the
  MRC Laboratory of Molecular Biology. Licensed **CC-BY 4.0**. Data: [male-cns.janelia.org](https://male-cns.janelia.org/download/).
- Fonts: UnifrakturMaguntia and IM Fell English (Google Fonts, SIL Open Font License).
- Gene facts behind the character names: SDB Interactive Fly, FlyBase and the sources in [docs/RESEARCH.md](docs/RESEARCH.md).
- Built with Godot 4, Python (NumPy, SciPy, pandas, PyArrow, websockets), Caddy, DigitalOcean, Gemini and ElevenLabs.
