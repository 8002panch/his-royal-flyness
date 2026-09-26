# Phase 0: the idea factory (as delivered, Sat 26 Sept 2026)

> Record only. The living plan is in `docs/`. Sources are listed at the end.

I checked the MaleCNS download page and two community lists of fly-connectome projects first, so the uniqueness filter runs against what's already been built.

---

## Before anyone pitches: the Realist's fact check

**Realist:** Four things before we get attached to anything.

1. **Getting the data is easy.** MaleCNS v1.0 has been public since June 8, 2026, under CC-BY 4.0. The Cell paper and Google's blog post came out Sept 3, and that's when it went viral. We only need three files: the connection table (1.1 GB Feather file: pre, post, synapse count), annotations (13 MB) and per-neuron neurotransmitter predictions (42 MB). So we can sign the weights, as long as we say the signs are assumed. We skip the 12.7 GB synapse-location file.
2. **"First complete CNS" is wrong. "First complete *male* CNS" is right.** BANC is a female brain plus nerve cord. So any why-now that rests on "brain and nerve cord in one animal" also has to be about males. BANC also has about a third as many synapses as MaleCNS. That comes from how the two were imaged and processed, not from sex, so any male vs female comparison has to be normalized. Otherwise we're comparing microscopes.
3. **The field got crowded in three weeks.** On top of the banned list, people have already shipped:
   - arcade versions of Mario 64, Flappy Bird, Asteroids, chess, poker and Fruit Ninja
   - *Swat*, where you swat a fly whose dodging runs on MaleCNS neurons
   - *FlyBreak*, a heist where you cut neurons
   - *flywire-fly-lab*, with 17,628 virtual knockouts
   - *fly-escape*, where you place furniture and the fly reacts
   - *FLYFEAR*, a Godot horror game
   - *Same Smell*, which puffs one male pheromone (cVA) into a male brain and a female brain
   - *Fruitflysynth*, a courtship synth running on a male nerve cord connectome
   - "Bi fly," the viral rewired-mating demo
   - *flyputer*, a local LLM that runs small brain subcircuits as tools

   So "an LLM can call the brain" isn't new on its own. Our agents need real jobs.
4. **Lessons from our own spike tests.** If you shuffle synapse counts across the whole brain, activity explodes, and the random brain looks broken for a boring reason. The ablation toggle has to keep each neuron's inputs, outputs and sign the same, or judges will call it rigged. And we write everything fresh at noon. Nothing gets copied from fly-cns-sim.

---

## Round 1: sixteen raw concepts

**The Visionary**
1. *Serenade* (rhythm): Sing into your mic as the male fly. Your rhythm travels his real path from brain, down the neck, to the wings, and a female brain decides whether she's impressed.
2. *Neck* (party co-op): Up to four players each become one sense of the same male fly: eyes, nose, feet or ears. The real brain turns whatever you all feed it into one body's actions.
3. *Dimorph* (deduction): Same smell, two brains, two different reactions. Find the sex-differing cell type responsible.
4. *Left Brain* (horror): The fly's two hemispheres are wired slightly differently, and one of them is lying to you.

**The Game Designer**
5. *Draft* (roguelike): Build a path from a sense to an action by drafting one real neuron at a time from its real downstream partners. Blue Prince with synapses.
6. *Fruit Bowl* (cozy logic): Seat flies around a fruit bowl so nobody fights and the right pairs meet.
7. *Mission Control* (asymmetric co-op): One player sees the arena. The other only has an optogenetics console and spike traces. Together they talk the fly home.
8. *Blockade* (tower defense): Place scents and shadows to keep flies off the fruit.

**The Realist**
9. *Dose* (sim): A fly has a "condition," like it won't court or it attacks everything. Mix drugs that turn transmitter systems up or down, then deal with the side effects.
10. *Lesion* (puzzle): Cut the fewest neurons that stop one behavior without breaking another.
11. *Real or Shuffled* (party quiz): Two flies on screen, one with the real brain and one with a scrambled brain. Guess which is which.
12. *Gait Lab* (sandbox): Wire the real nerve cord into the flybody model and poke leg circuits until it walks.

**The Pitchman**
13. *Reviewer 2* (lab sim): You're a first-year in a fly lab trying to publish. An AI Reviewer 2 reruns every claim you make on a shuffled brain and a female brain, and trashes whatever doesn't hold up.
14. *Mixed Signals* (strategy): Protect a fruit harvest with pheromone decoys instead of insecticide. Every male fly's response runs through the real male pheromone circuit.
15. *Wingman* (dating sim): Coach a shy male fly through a date.
16. *Buzzkill* (audio game): Guide a fly through a dark room by sound alone, fully playable without a screen.

---

## Round 2: running the filters

### Quick kills

| # | Idea | Filter it fails | Reason |
|---|---|---|---|
| 4 | Left Brain | Ablation, uniqueness | The differences between the left and right halves are small and look like noise, so a random brain would feel the same. FLYFEAR already did fly horror in Godot. |
| 6 | Fruit Bowl | Ablation | We'd have to write the "who fights whom" rule ourselves to keep it readable, so the rule wouldn't come from the brain. We also have one male connectome and two female ones, which isn't enough flies for a cast. |
| 8 | Blockade | Uniqueness, why-now | fly-escape already does "place objects and the fly reacts." Any fly brain, or a simple flocking script, would play the same. |
| 10 | Lesion | Uniqueness | FlyBreak and flywire-fly-lab already shipped it. |
| 11 | Real or Shuffled | Verb | The verb is "watch," then guess. It survives as every finalist's ablation toggle. |
| 12 | Gait Lab | Feasibility | **Realist, killing their own idea:** a project called therealfly plugged the full MaleCNS into flybody with no hand-written controller, and its preregistered test failed. Walking from raw wiring is a research project, not a weekend. |
| 15 | Wingman | Ablation | Picking dialogue options never touches the circuit. And "Bi fly" already owns the courtship joke. |
| 16 | Buzzkill | Ablation | A 20-line steering script would play exactly the same, so the brain is decoration. Audio-first play moves over to the finalists as an accessibility option. |

### The real fights

**On Serenade**

**Visionary:** This is the one I'd frame on a wall. MaleCNS is the only dataset where a male's P1 courtship neurons, the pIP10 descending neuron and the song circuit in the nerve cord all sit in one graph. You sing into a mic, and your voice travels that real path.

**Realist:** The path is real, but the song isn't. Fly pulse song lives in its timing, about 35 ms between pulses. Both producing that rhythm and the female's tuning to it come from how individual cells behave over time, and the wiring diagram doesn't record that. Our model would pass along whatever rhythm you give it. The part that makes it a rhythm game would come from us, not the fly. And Fruitflysynth already built a courtship synth on the nerve cord.

**Visionary:** So it fails the ablation test exactly where it matters.

**Realist:** Yes. A shuffled female would judge your song about as well as the real one.

**Visionary:** Fine, it's dead. But I want that brain-to-wing moment somewhere. When a male in one of our finalists finds a female, his wings should buzz because pIP10 fired, not because we played a sound file.

**Council:** Agreed. That carries forward.

**On Draft**

**Game Designer:** Draft is the most "game" thing on this board. Blue Prince proved that building the structure can be the puzzle.

**Realist:** It fails the ablation test in a sneaky way. A random graph where every neuron keeps the same number of connections still has short paths everywhere. From a sugar neuron you still reach a feeding motor neuron in about four hops. Drafting through a shuffled brain would feel almost the same.

**Game Designer:** Then the win check runs the simulation instead of just checking that a path exists.

**Realist:** Then you've built Lesion in reverse, and FlyBreak is sitting right there.

**Game Designer:** ...Fine, it's dead. I'm keeping the Blue Prince lesson, though.

**On Dose**

**Pitchman:** Dose is my Health-track dream: drugs, side effects, real pharmacology.

**Realist:** I pitched it, and I'm killing it. The interesting drugs work through neuromodulators, like octopamine for aggression or dopamine for arousal. Those act through receptors and on timescales the wiring diagram doesn't show. The drugs we can model honestly, like more GABA or less acetylcholine, just turn the whole brain up or down. A shuffled brain responds to "more GABA" in about the same way, so it fails ablation.

**Pitchman:** That hurts. Agreed.

**On Mixed Signals**

**Pitchman:** This one has a real-world hook. Pheromone mating disruption is a working alternative to spraying, and apple growers already use it against codling moth. That gives us a one-sentence Sustainability pitch.

**Realist:** Two problems. First, the berry pest everyone means is *Drosophila suzukii*, and its pheromone system differs from melanogaster's. It doesn't even make cVA. So we can't claim this protects real farms. Second, following an odor gradient from raw wiring won't work reliably.

**Visionary:** But look at what it uses. A male taps a female with his foreleg. The ppk23 taste neurons in that leg feed into the nerve cord. An ascending neuron, vAB3, carries the signal up the neck to P1 in the brain. P1 decides to court, and pIP10 sends the song command back down to the wings. That's leg to nerve cord to brain and back down again. The annotations even tag 269 putative ppk23 neurons. Only a complete male CNS has that loop.

**Realist:** I'll accept it on two conditions. First, the brain decides what each fly wants (court, feed or ignore), plain code walks it there, and we say so openly. Second, we pitch it as a teaching game about why pheromone control works, shown on the one insect whose whole male nervous system is mapped. It's not a farm tool.

**Pitchman:** I can sell honest. Promoted.

### Merges

- **Dimorph and Mission Control's console fold into Reviewer 2.** Dimorph asks a great question, but it's thin as a game, and Same Smell already did the one-shot male vs female demo. Reviewer 2 turns it into a loop, with a villain and a joke every grad student gets. The optogenetics console becomes the player's hands.
- **Neck beats Mission Control for the co-op slot.** A judge walking past gets "I'm the nose" in five seconds. Mission Control takes a minute to explain.

---

## Promoted: the three finalists

| | **Reviewer 2** | **Neck** | **Mixed Signals** |
|---|---|---|---|
| Genre | Deduction lab sim | Party co-op (2 to 4 players) | Strategy / wave defense |
| Verb | **Test** | **Signal** | **Lure** |
| 30-second read | Zap a neuron, see what the fly does, make a claim, and the AI reviewer tries to debunk it. | Each player is one of the fly's senses. Get him to the female together. | Place decoy scents. Males chase decoys instead of females, so the next wave is smaller. |
| Why now | Every case is about male-specific or sex-differing cell types. Answering them needs the male CNS next to the female brains (FlyWire and BANC). | The goal is courtship, which needs male-only circuits (P1 and pIP10) wired through the neck to the nerve cord in one animal. | The pheromone loop from leg to nerve cord to brain and back down to the wings only exists as a single graph in a male CNS. |
| Ablation | The ablation is a rule of the game. Reviewer 2 reruns your result on the shuffled brain: real findings survive and flukes don't. On a shuffled brain, the cases have no answers. | Flip to shuffled and the fly stops making sense of the team. Same inputs, nonsense body. | On a shuffled brain, males stop caring about your decoys, and the strategy you learned stops working. |
| Agents, first sketch | **Rival Lab** races you on the same question with the same tools (stimulate, silence, record, compare sexes). **Reviewer 2** checks both of you with controls and writes the rejection letter. | **Director** builds arenas. **Playtester** runs each arena through the brain with scripted inputs and throws out any that are unsolvable or too easy. **Referee** replays each round with one player's input removed to show who actually moved the fly. | **Agronomist** designs its own decoy layout by testing setups on the brain. **Field Trial** runs every layout, yours and the AI's, across many randomized swarms plus a shuffled-brain control, and only certifies layouts that beat doing nothing. |
| Likely tracks | Education, AI/ML | Design, Most Engaging Demo, AI/ML | Sustainability, AI/ML |

The three finalists use different genres, verbs and main tracks. Each one has its ablation toggle built in, and each one is only possible because the male brain is mapped.

**Visionary:** Phase 0 is closed. Next is Step 1 on Reviewer 2, then Neck, then Mixed Signals.

---

Two notes from outside the Council:
- **This clashes with the plan you already have for today.** Your notes have Fly-by-Wire planned, with hacking starting at noon. If this is a pivot, the first-2-hours plan at the end will need to fit whatever time is left.
- **Your current plan has an overlap problem.** *Swat* (a browser arcade where a MaleCNS circuit runs the fly's dodging) and *flyputer*'s swatter game are both on the community lists. That overlaps with Swat the Fly, so your Devpost should say what makes yours different.

**Outcome:** the team chose **Neck** (the party co-op) and asked for Jackbox-style joining. See [02_party_coop_council.md](02_party_coop_council.md).

Sources:
- [MaleCNS download page](https://male-cns.janelia.org/download/)
- [MaleCNS release notes](https://male-cns.janelia.org/release/)
- [Google Research blog on MaleCNS](https://research.google/blog/a-connectomics-milestone-mapping-the-complete-male-fruit-fly-brain/)
- [AI Weekly on the viral demos](https://aiweekly.co/alerts/janelia-google-male-fly-connectome-goes-viral-on-minecraft-demo)
- [awesome-fly list (cobanov)](https://github.com/cobanov/awesome-fly)
- [awesome-fruit-fly list (townie)](https://github.com/townie/awesome-fruit-fly)
- [nfly](https://github.com/zhengxuyu/nfly)
- [flybody](https://github.com/TuragaLab/flybody)
