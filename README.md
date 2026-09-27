# His Royal Flyness

*A Courtship by Committee.* Built at **hackUMBC 2026** (UMBC, Sat 26 Sept 12:00 PM to Sun 27 Sept 11:45 AM EDT).

> Four friends share one fly. Three of you fly Prince Hamlet with your phones: left and right, up and down, forward and back.
> The fourth, the Royal Seer, is the only one who can sense where Princess Miranda is and when the Giant's hand will strike,
> and those senses run through the real, fully mapped nervous system of a male fruit fly (MaleCNS v1.0, all 166,606 neurons).
> Swap in the Changeling, with the same neurons and scrambled wiring, and the Seer goes blind.

**Status:** being built now. Working so far: joining by room code on phones, server-side movement, and the brain-powered Seer
running live in the server (True Prince vs Changeling, tested). In progress: the Godot main screen and the first playable trial. Details: [docs/TEAM.md](docs/TEAM.md#implementation-status).

## How it works

- **The main screen** (Godot 4, 2D) shows Hamlet's first-person view of the royal hall. It's the only screen that shows the game.
- **Four phones** join with a room code and each take one role: the **Helmsman**, **Liftmaster** and **Wingmaster** each hold one
  axis of flight; the **Royal Seer** holds SCAN to get coarse cues (Princess left / ahead / right, near or far; the Giant's side
  and seconds to impact) and calls them out.
- **A Python server** owns the game: it moves the fly from the three movement inputs and feeds what Hamlet would see and feel into
  his real sensory neurons. The whole nervous system runs as a rate model, and the Seer's cues are read from real descending neurons.
- **The Changeling** has the same neurons, connection counts and input per neuron, with scrambled partners. With it, the Seer
  warned of 0 of 60 Giants; the True Prince warned of 60 of 60, about 1.2 s ahead ([team/neil/seer_eval.csv](team/neil/seer_eval.csv)).

## Docs

| Doc | What's in it |
|---|---|
| [docs/GAME.md](docs/GAME.md) | The game: roles, trials, the Seer and the brain, art and audio, lore and cast, demo plan |
| [docs/TECH.md](docs/TECH.md) | How it works: architecture, protocol, server, brain and Seer, how to run and test |
| [docs/TEAM.md](docs/TEAM.md) | Who does what, status, open requests, schedule, decisions, rules compliance, submission |

**Approved campaign plan:** [comic script and levels](docs/GAME.md#story-campaign-and-comic-cutscenes--approved-team-plan), [implementation handoff](docs/TECH.md#arnavs-comic-campaign--implementation-planning-not-a-protocol-change), and [remaining tasks](docs/TEAM.md#arnavs-approved-story-plan-and-remaining-implementation-work). This is the plan for upcoming gameplay, not a claim that the campaign already runs. It adds a grape tutorial, three rival questions, two stages, Giant/father dodge encounters and branching comic endings. No keyboard player mode.

## Team

| Person | GitHub | Role |
|---|---|---|
| Neil | `8002panch` | Brain + science |
| Arnav | `arnavp-1` | Game server |
| Ved | `shahved25` | Phones, relay, cloud + agents |
| Anshul | `darkspaz-v1` | Godot host, art + audio |

## Repo layout

| Folder | What | Owner |
|---|---|---|
| `relay/` | WebSocket relay and the controller-only phone page | Ved |
| `server/` | Authoritative game server: movement, world, Seer adapter, Godot feed (`chronicler.py`: Neil) | Arnav |
| `brain/` | MaleCNS graph build, rate model, the Changeling, the Royal Seer, tests | Neil |
| `host/` | Godot 4 main screen | Anshul |
| `team/` | Each person's work folder (results, figures, scratch) | Each person |
| `data/` | MaleCNS data files (git-ignored; [how to get them](docs/TECH.md#setup-the-brains-data)) | Neil |

## Run it

`pip install -r requirements.txt`, then `python run_local.py --room BZKT` from the repo folder. It starts the relay, the phone
page and the game server, and opens the host screen in your browser with the room code and a QR code; phones on the same Wi-Fi
scan it to join. The main screen is the Godot court: `godot --path host` (Godot 4.3), then **Enter the Court**. It shows the same QR.
Enter starts the story; Space (or a clicker's Page Down) moves through the comics; Ctrl+1..9 jumps to a chapter for judging.
To host the join link on your domain, see [docs/TECH.md](docs/TECH.md#hosting-the-join-link-godaddy-domain).
Details: [docs/TECH.md](docs/TECH.md#run-it-locally) and [the campaign](docs/TECH.md#the-campaign-servercampaignpy).
Tests: `python -m pytest brain/tests server/tests relay/tests audio/tests -q`, `npm test --prefix relay/public`, and the Godot
smoke tests in `host/test/`.

## Rules and honesty

- **All code in this repository was written during hackUMBC 2026**, inside the hacking window. The plans in `docs/` were written
  before and during the event and contain no pre-event code. This project isn't submitted to any other hackathon.
  Details: [docs/TEAM.md](docs/TEAM.md#hackumbc-2026-rules-how-we-comply).
- **The Royal Decree** (canonical text; shown on the main screen and on Devpost):
  Three players steer Prince Hamlet directly: left and right, up and down, forward and back. The fourth, the Royal Seer, senses the world through his real nervous system: the MaleCNS v1.0 wiring diagram of a real male fruit fly (Berg et al., *Cell*, 2026; CC-BY 4.0) runs live as a simple rate model, and the Seer's cues (where the Princess is, where a Giant's hand is coming from, and how soon) are read from his descending neurons. The connection counts are real. Everything else is our assumption: how strong each connection is (derived from synapse counts under one tuned gain), whether it excites or inhibits (predicted from neurotransmitters), leaving out neuromodulators and connections under 5 synapses, and how positions in the game become activity in his eyes and antennae. Real neurons have dynamics, modulation and learning that this model doesn't. Swap in the Changeling (same neurons and connection counts, scrambled partners) and the Seer goes blind. If the hybrid fallback is used, the Seer's directions come from the game and only the confidence and warnings from the brain. The Princess, the Giants and the course are scripted. The names are real fly genes; the personalities are ours.

## AI tools used

- Code and docs were written with help from AI coding assistants (Claude, Codex). Everyone on the team can explain the code they committed.
- In the game (if they ship): Gemini for trial design and the Jester's lines; ElevenLabs for voices, sound effects and music.

## Credits

- **MaleCNS v1.0** connectome: Berg et al., *Cell* (2026). HHMI Janelia FlyEM, Google Research, University of Cambridge and the
  MRC Laboratory of Molecular Biology. Licensed **CC-BY 4.0**. Data: [male-cns.janelia.org](https://male-cns.janelia.org/download/).
- Fonts: UnifrakturMaguntia and IM Fell English (Google Fonts, SIL Open Font License).
- Gene facts behind the character names: FlyBase, SDB Interactive Fly and the papers listed in [docs/GAME.md](docs/GAME.md#lore-the-kingdom-of-the-fruit-bowl).
- Built with Godot 4, Python (NumPy, SciPy, pandas, PyArrow, websockets) and plain HTML/JavaScript.
