# Devpost draft

Fill the brackets with real results only. Keep the Royal Decree section. Create the project by 11:00 AM Sunday; finalize by 11:45 AM.

---

## Title
**His Royal Flyness: A Courtship by Committee**

## Tagline
Four friends, four senses, one real fly nervous system. Get Prince Hamlet to the princess before the Giant's hand comes down.

## Inspiration
In September 2026, Janelia, Google and their partners published MaleCNS v1.0: the first complete wiring diagram of a male fruit
fly's nervous system, brain and nerve cord together, about 166,000 neurons. Within three weeks the internet had wired it into
Doom, Minecraft, Beat Saber and crypto trading. In almost every demo you watch a fly play a game.

We wanted the opposite: to put you *inside* the fly. A nervous system is a committee. Eyes, nose, feet and ears all report in,
and behavior is whatever the wiring makes of them. So we split one fly's senses between four friends, gave him a royal court,
and asked a simple question: does the real wiring matter, or would any tangle of neurons do?

## What it does
- The main screen shows the Royal Ball. Each player joins on their phone at **[domain]** with a wax-seal code and becomes one of
  Prince Hamlet's senses: the **Royal Lookout** (eyes), **Royal Perfumer** (nose), **Royal Taster** (feet, since flies taste
  with their feet) or **Royal Spymaster** (ears).
- Each phone shows only what that sense can detect. You choose when to let it through.
- Hamlet's whole nervous system (166,606 neurons) runs live. Whatever you let through goes into his real sensory neurons, and his
  real output neurons decide whether he turns, walks, jumps or sings.
- Three trials (the Garden, the Banquet, the Giant's Shadow), then a wedding. Win by making him serenade Princess Miranda.
- After each trial, **the Chronicle** replays it with each sense switched off and tells every player how much of his behavior
  was really theirs, roasted live by Clown the Jester.
- **The Changeling:** one switch swaps his brain for one with the same neurons, the same number of connections and the same
  input per neuron, but scrambled partners. [Result: the council wins X% of certified trials with the true prince and Y% with the Changeling.]
- Every character is named after a real fly gene: *hamlet*, *miranda*, *prospero*, *I'm not dead yet*, *tinman*, *clown*.

## How we built it
- **Brain:** MaleCNS v1.0 (CC-BY 4.0). We built a signed, sparse graph of all 166,606 neurons (connections with 5 or more synapses:
  6.24M connections carrying 72% of synapses) and run it as a rate model in NumPy/SciPy at 50 Hz on a laptop (about 5 ms per step).
  Signs come from predicted neurotransmitters; neuromodulators are left out.
- **Senses in, behavior out:** eyes drive LC10a, LPLC2 and LC4; the nose drives three olfactory receptor neuron types; the feet
  drive 71 foreleg pheromone-taste neurons; the ears drive Johnston's organ neurons. Output neurons DNa02/DNa01 (steering),
  DNp09/DNg100 (walking), MDN (backing up), DNp01 (the giant fiber: escape) and pIP10 (the male-only song command) move the body.
- **The Changeling:** we shuffle each connection's sending neuron among neurons of the same sign, so every neuron keeps its exact
  total input. A fair control, not a broken brain.
- **Game:** Godot 4 main screen; a Python game server; phones join through a WebSocket relay on a **DigitalOcean** Droplet
  behind Caddy at our **GoDaddy Registry** domain.
- **Agents:** the Matchmaker (**Gemini**, structured output) designs trials. The Master of Trials (**Gemini**, function calling)
  calls our brain simulation as a tool, plays each trial with bot councils on the true prince and the Changeling, and only
  certifies trials the real prince can win and the Changeling mostly can't. The Chronicler runs shadow brains to credit each sense.
- **Voice and sound:** **ElevenLabs** for the Herald, the Princess and the Jester (the Jester's lines are written live from game
  data), plus generated sound effects and music.

## Challenges we ran into
[Fill in honestly. Likely: tuning a whole-brain model so it's neither silent nor exploding; whether the eyes could steer
(result of our 20:00 gate test: ...); getting phones to connect on venue Wi-Fi; making a fair random control.]

## Accomplishments that we're proud of
[e.g. the whole male nervous system running live on a laptop; the Changeling test result; strangers understanding the game in 30 seconds.]

## What we learned
[e.g. which senses mattered most; what the wiring alone can and can't do.]

## What's next
- Let Princess Miranda run on the female nervous system map (she has no pIP10, so she can't sing his song).
- A classroom mode: the teacher's screen, students' phones, and lesson cards on sensory integration and controls.
- More senses (taste of food, wind direction) and more of the royal court.

## The Royal Decree (what's real and what isn't)
Prince Hamlet runs on the MaleCNS v1.0 wiring diagram of a real male fruit fly (Berg et al., *Cell*, 2026; CC-BY 4.0).
The connection counts are real. Everything else is our assumption: how strong each connection is (derived from synapse counts
under one tuned gain), whether it excites or inhibits (predicted from neurotransmitters), and leaving out neuromodulators and
connections under 5 synapses. Real neurons have dynamics, modulation and learning that this model doesn't. How his output neurons
become walking is our code [and, if hybrid steering was used: the direction he turns is chosen by our code; his brain decides
whether he goes]. The Princess, the rivals and the Giant are scripted. The names are real fly genes; the personalities are ours.

## Built with
godot, python, numpy, scipy, pandas, pyarrow, websockets, caddy, digitalocean, gemini, elevenlabs, malecns, neuroscience

## Try it out
- [domain]
- GitHub: [public repo link]

## Video
[link], about 90 s: title and Herald, gameplay with phones, the Giant Fiber jump, the Chronicle, the Changeling, the Decree.

## Credits
MaleCNS v1.0: HHMI Janelia FlyEM, Google Research, University of Cambridge, MRC Laboratory of Molecular Biology (CC-BY 4.0).
Gene facts: FlyBase / SDB Interactive Fly and the papers in our repo's docs.
