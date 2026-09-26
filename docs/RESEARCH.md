# Research notes and sources

Everything the plan leans on, with sources. The measured data facts are in [DATA_CHECK.md](DATA_CHECK.md).

## MaleCNS v1.0 (the brain)

- v1.0 went public on **8 June 2026** under **CC-BY 4.0**. The Cell paper (Berg et al.) and Google's blog post came out on **3 Sept 2026**, which is when it went viral.
- About 166,000 neurons (166,606 by the Berg et al. rule) and about 125 million synapses: brain, both optic lobes and the ventral nerve cord of one adult male, with the neck connective intact.
- Collaboration: HHMI Janelia FlyEM, Google Research, University of Cambridge (Zoology), MRC Laboratory of Molecular Biology.
- Downloads (Feather): annotations 13 MB, neurotransmitters 42 MB, body stats 780 MB, connection weights 1.1 GB, synapse points 12.7 GB,
  synapse partners 6.8 GB, per-synapse transmitter predictions 2.7 GB. Skeletons in Google Storage. Neuroglancer and neuPrint for browsing.
- Sources: [MaleCNS download page](https://male-cns.janelia.org/download/) · [MaleCNS release notes](https://male-cns.janelia.org/release/) ·
  [Janelia project page](https://www.janelia.org/project-team/flyem/male-cns-connectome) ·
  [Google Research blog](https://research.google/blog/a-connectomics-milestone-mapping-the-complete-male-fruit-fly-brain/)

## Why now: what the other maps don't have

| Dataset | Sex | Covers |
|---|---|---|
| FlyWire (FAFB) | Female | Brain only |
| hemibrain | Female | Part of the brain |
| MANC | Male | Nerve cord only |
| BANC (Bates et al., *Nature* 2026) | Female | Brain + nerve cord |
| **MaleCNS v1.0** | **Male** | **Brain + nerve cord in one animal** |

So "first complete CNS" is wrong; "first complete **male** CNS" is right. The Taster's loop (foreleg taste neurons in the nerve cord,
up the neck through vAB3 to the pC1/P1 cluster, back down through pIP10 to the wing) needs a male brain and nerve cord in one graph.
BANC has about a third of MaleCNS's synapses because of how it was imaged and processed, so male vs female comparisons must normalize.

## The crowded field (why our angle is different)

Within about three weeks of the 3 Sept paper, the community shipped more than 100 projects. Taken or banned ideas include:
- **Games a fly "plays":** Doom (DOOMFLY, FlyDoom), Minecraft (several mods), Super Mario 64, Mario, Flappy Bird, Asteroids, Snake, chess, poker,
  blackjack, tic-tac-toe, Fruit Ninja, Five Nights at Freddy's, Half-Life, Pong, Tetris, Craftax, Beat Saber, Clone Hero.
- **Swat / escape games:** *Swat* (browser arcade; a MaleCNS circuit drives the dodging), *fly-escape* (place furniture, the fly navigates),
  *Help the Fly Escape*, *flyputer* (a swatter game plus a local LLM that runs small brain circuits as tools), *DesktopFly* (looming escape).
- **Lesion / rewiring games:** *FlyBreak* (a neural heist where you cut nodes), *flywire-fly-lab* (17,628 virtual knockouts).
- **Courtship:** *Same Smell* (one cVA puff into a male and a female brain), *Fruitless* (a courtship assay), *Fruitflysynth* (courtship
  song synth on the nerve cord), "Bi fly" (rewired mating preference, viral).
- **Horror:** *FLYFEAR* (Godot). **Pets:** several Tamagotchis and desktop pets. **Trading:** Stonkfly and many others.
- **Agents with the brain as a tool:** *flyputer*, *fly-brain* (natural-language interface). So "an LLM can call the brain" isn't new by itself.

Our angle: **players are the senses, together, in one body**, with a fair scrambled control (the Changeling) as a game mechanic, and agents
that must *prove* each trial depends on the real wiring.

Sources: [awesome-fly (cobanov)](https://github.com/cobanov/awesome-fly) · [awesome-fruit-fly (townie)](https://github.com/townie/awesome-fruit-fly) ·
[AI Weekly on the viral demos](https://aiweekly.co/alerts/janelia-google-male-fly-connectome-goes-viral-on-minecraft-demo) ·
[nfly](https://github.com/zhengxuyu/nfly) · [flybody](https://github.com/TuragaLab/flybody)

## Real fly gene names for the royal cast

- *hamlet*: named from "to be or not to be" ("IIB or not IIB", after the IIB cells it affects); a binary switch between neuron types.
  [RSB: IIB or not IIB?](https://www.rsb.org.uk/biologist-features/iib-or-not-iib) · [SDB Interactive Fly: Hamlet](https://www.sdbonline.org/sites/fly/dbzhnsky/hamlet1.htm) ·
  [Alliance of Genome Resources: ham](https://www.alliancegenome.org/gene/FB:FBgn0045852)
- *prospero*: named after The Tempest's magician because it controls the fate of neural progeny. [SDB Interactive Fly: Prospero](https://www.sdbonline.org/sites/fly/neural/prospero.htm)
- *miranda*: binds Prospero and anchors it so it goes into the daughter cell during neuroblast division.
  [Shen, Jan & Jan 1997, *Cell*](https://www.cell.com/fulltext/S0092-8674(00)80505-X)
- *I'm not dead yet* (Indy), *tinman*, *clown*, *ken and barbie*: [UNBC BIOL312 gene-names post](https://biol312.opened.ca/where-would-hamlet-the-tinman-ken-and-barbie-all-be-found-in-the-same-place-in-drosophila-melanogaster-of-course/)
- *cheapdate*, *rutabaga*: from memory, **not yet checked**. Verify on FlyBase before use.

## Biology behind the mechanics (confirm citations before quoting)

- Males track females visually with LC10a neurons during courtship (Ribeiro et al. 2018, *Cell*).
- LPLC2 and LC4 looming detectors drive the giant fiber escape (von Reyn et al. 2017; Ache et al. 2019). *Confirmed in our data: 4,862 and 6,362 direct synapses.*
- pIP10 is a descending neuron that drives courtship song (von Philipsborn et al. 2011). *Labeled male-specific in MaleCNS.*
- vAB3 ascending neurons relay foreleg ppk23 pheromone taste to P1 and mAL (Clowney et al. 2015). *Confirmed in our data: all 6 vAB3 get direct ppk23 input; vAB3 to pC1 cluster 1,322 synapses.*
- cVA from other males reduces male courtship toward a female (e.g. Ejima et al. 2007).
- DNa02 activity predicts turning (Rayshubskiy et al.); DNp09 drives forward walking (Bidaye et al. 2020); MDN drives backward walking (Bidaye et al. 2014).
- Or42b (DM1) responds to vinegar-like food odors; Or47b (VA1v) to courtship-promoting fatty-acid odors; Or67d (DA1) to cVA.
- Flies taste with gustatory neurons on their legs.

## Prize tools

- **ElevenLabs:** text-to-speech (v3 with audio tags for expressive delivery; Flash v2.5 for low latency; streaming), a sound effects API,
  a music API (3 s to 10 min), speech-to-text (Scribe v2). MLH gives 3 months free.
  [MLH ElevenLabs page](https://www.mlh.com/partners/elevenlabs) · [ElevenLabs API](https://elevenlabs.io/api) ·
  [Text to speech docs](https://elevenlabs.io/docs/overview/capabilities/text-to-speech) · [Sound effects docs](https://elevenlabs.io/docs/overview/capabilities/sound-effects)
- **Gemini:** Gemini 3.8 Flash released 2 Sept 2026, with function calling and JSON-schema structured output.
  [What's new in Gemini 3.8 Flash](https://ai.google.dev/gemini-api/docs/latest-model) · [OpenRouter listing](https://openrouter.ai/google/gemini-3.8-flash)
- **GoDaddy Registry domains via MLH:** TLDs such as .co, .biz, .us, .club, .design, .wiki through MLH coupons.
  [Free domain guide](https://pem.com.np/posts/get-free-domain-from-mlh/) · [MLH story on GoDaddy Registry domains](https://stories.mlh.io/host-your-godaddy-registry-domain-name-on-google-cloud-in-minutes-d24549ca1b5a?gi=d29d66956c7c)
- **Claude** (alternative for the agents): `claude-opus-5` through the Anthropic Python SDK, structured outputs and strict tool use.

## Design lessons (from the original brief)

- Blue Prince: building the structure is the puzzle. Chants of Sennaar: decoding a system is the game. Is This Seat Taken?: one charming rule.
  Consume Me: impact through humor. Pine Hearts and Art of Fauna: accessibility from the start. Mage Arena: a new input as the hook.
  Hollow Knight: Silksong: a bug hero can carry a game. PEAK: simple co-op chaos makes a great live demo.
- Ours borrows **PEAK** and **Mage Arena** (see [GAME_DESIGN.md](GAME_DESIGN.md#lessons-borrowed-from-award-winning-games)), plus Jackbox and Keep Talking.

## What has won hackUMBC before

See [research/HACKUMBC_WINNERS_ANALYSIS.md](research/HACKUMBC_WINNERS_ANALYSIS.md). Most useful points for us:
- Most Engaging Demo goes to something judges can play, not something sophisticated.
- Full teams of 4 win First Overall; an Impact line with a real human stake helps.
- Accessibility shows up among winners almost every year.
- Sponsor and MLH prizes are the easiest wins when the integration is real.
