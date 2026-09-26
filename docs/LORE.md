# Lore bible: the Kingdom of the Fruit Bowl

Rules for anyone writing text, voice lines or art for the game. The mechanics are in [GAME_DESIGN.md](GAME_DESIGN.md).

## The world

The Kingdom of the Fruit Bowl sits on a kitchen counter ruled by Giants (the humans). Tonight Duke Prospero holds the Royal
Ball, and Prince Hamlet hopes to win Princess Miranda. Hamlet is the first prince whose entire mind has been mapped: every one
of his 166,606 neurons. He can't see, smell, taste or hear without his **Privy Council**, the four players.

## The cast

The personalities are ours. **Every name is a real fly gene.** All facts below were checked by Neil on Sat 26 Sept (sources in the Status column).

| Character | Role in the game | Real gene fact (fact card) | Status |
|---|---|---|---|
| **Prince Hamlet** | The player fly, running the MaleCNS v1.0 nervous system | *hamlet* is a real gene that switches which kind of neuron a cell becomes. Its discoverers named it for "to be or not to be" ("IIB or not IIB", after the cells it affects) | Verified (RSB "IIB or not IIB"; SDB Interactive Fly) |
| **Princess Miranda** | The one he's courting (scripted) | *miranda* is named after Prospero's daughter in The Tempest. When a neural stem cell divides, the Miranda protein carries the Prospero protein into the daughter cell | Verified (Shen, Jan & Jan 1997, *Cell*) |
| **Duke Prospero** | Her father; opens the ball | *prospero* is named after The Tempest's magician because it controls the fate of the cells a neural stem cell makes | Verified (SDB Interactive Fly) |
| **Sir Indy, the Knight Who Is Not Dead Yet** | A rival who keeps coming back | *I'm not dead yet* (*Indy*) is named after the Monty Python and the Holy Grail line. In some experiments, flies with less of it lived much longer (the result is debated) | Verified (Wikipedia *Indy (gene)*, FlyBase FBgn0036816); lifespan claim softened because it's contested |
| **Lord Tinman** | The heartless rival | *tinman* flies grow no heart; named for the Wizard of Oz | Verified (UNBC gene-names page) |
| **Sir Cheapdate** | The rival who gets tipsy at the Banquet | *cheapdate* flies get drunk on less alcohol; it turned out to be an allele of the memory gene *amnesiac* | Verified (Moore et al. 1998, *Cell*) |
| **Count Rutabaga** | The rival who can't remember whom he's courting | *rutabaga* flies are bad at learning and memory (the gene makes an enzyme, adenylyl cyclase, that memory needs) | Verified (Levin et al. 1992, *Cell*) |
| **Clown, the Court Jester** | Voices the Chronicle and roasts the council | *clown* mutants have red-and-white eyes | Verified (UNBC gene-names page) |
| **The Herald** | The announcer (the Jackbox host voice) | None | None |
| **The Giant** | The human with the swatter | From a fly's point of view, humans are Giants | None |
| **The Giant Fiber** | Hamlet's only defense | The neuron that fires a fly's escape jump is really called the giant fiber (DNp01). In Hamlet, the looming-detector neurons connect straight to it with more than 11,000 synapses | Verified from the data ([DATA_CHECK.md](DATA_CHECK.md)) |
| **The Changeling** | The ablation toggle: same body, scrambled insides | Same 166,606 neurons, same number of connections, same total input to every neuron; only the partners are shuffled | By construction ([TECH_ARCHITECTURE.md](TECH_ARCHITECTURE.md#the-changeling-brainchangelingpy)) |

## The Privy Council

| Title | Sense | Lore line | Real fact behind it |
|---|---|---|---|
| Royal Lookout | Eyes | "Watch for the Princess. Watch for the Giant." | LC10a neurons help males track females; LPLC2 and LC4 detect looming |
| Royal Perfumer | Nose | "A rival's scent on her kills the mood." | cVA from another male reduces courtship |
| Royal Taster | Feet | "No suitor proceeds without the Taster." | Flies taste with their feet; males tap females to taste their pheromones |
| Royal Spymaster | Ears | "Hear the Giant's whoosh before it lands." | Antennal ear (JO) neurons connect directly to the giant fiber |

## Tone rules

- Playful and a little pompous, like a costume drama narrated by someone who's had one glass of wine. Never mean to players.
- The biology jokes must be true. If a joke needs a fact, the fact has to be on the verified list above.
- **Don't use these gene names:** *fruitless* (its naming history involves male-male courtship; the joke lands badly),
  *ken and barbie* (named for missing genitalia), *doublesex* / *transformer* (sex determination; easy to misread as gender jokes).
- Don't quote song lyrics (e.g. no Wizard of Oz lyrics for Lord Tinman). Short allusions only.
- The Princess is a character with opinions, not a prize. She judges the serenade; she can prefer a rival.

## Royal Facts (loading-screen cards)

1. **Prince Hamlet.** *hamlet* is a real fly gene that decides what kind of neuron a cell becomes. IIB or not IIB.
2. **Miranda and Prospero.** Both are real fly genes named after The Tempest. Miranda carries Prospero into the next generation of cells.
3. **The mapped mind.** MaleCNS v1.0 maps an entire male fruit fly nervous system: about 166,000 neurons and 125 million synapses (Janelia, Google, Cambridge, MRC LMB; *Cell*, 3 Sept 2026).
4. **The Royal Taster.** Flies taste with their feet. Hamlet has 71 pheromone-tasting neurons on his front legs.
5. **The Serenade.** Male flies sing by vibrating one wing. pIP10, a male-only neuron, is the song command.
6. **The Giant Fiber.** The escape neuron is really called the giant fiber, and it's fed directly by thousands of synapses from looming detectors.
7. **The Changeling.** Same neurons, same number of connections, same input per neuron. Only the partners are scrambled, and that's enough to ruin everything.
8. **Sir Indy.** *I'm not dead yet* is a real fly gene, named after Monty Python. In some experiments, flies with less of it lived much longer (scientists still argue about it).
9. **Lord Tinman.** *tinman* flies grow no heart.
10. **Clown.** *clown* flies have red-and-white eyes.
11. **Sir Cheapdate.** *cheapdate* flies get drunk on less alcohol.
12. **Count Rutabaga.** *rutabaga* flies are bad at learning and memory.

## Voice line bank

Drafts for the ElevenLabs batch (`lines.csv`: id, speaker, text). Square brackets are ElevenLabs v3 audio tags. `{braces}`
are filled in at runtime from the Chronicler's numbers. Keep every line under about 12 seconds.

### Herald
| id | Line |
|---|---|
| H_TITLE | [fanfare] Hear ye, hear ye! By order of Duke Prospero, the Royal Ball of the Fruit Bowl begins! |
| H_JOIN | Present your seal at the gate, and take your place on the Prince's Privy Council. |
| H_PRINCE | Behold Prince Hamlet, the first prince whose entire mind has been mapped. Every one of his hundred and sixty-six thousand neurons. [pause] He cannot see, smell, taste or hear without you. |
| H_ROLE_LOOKOUT | The Royal Lookout! Eyes of the Prince. Watch for the Princess. Watch for the Giant. |
| H_ROLE_PERFUMER | The Royal Perfumer! Keeper of scents. Beware the perfume of rivals. |
| H_ROLE_TASTER | The Royal Taster! For a fly tastes with his feet, and no suitor proceeds without the Taster. |
| H_ROLE_SPYMASTER | The Royal Spymaster! Ears of the court. Listen for the whoosh of the Giant. |
| H_TRIAL_1 | The First Trial: the Garden Audience. Her Highness awaits. |
| H_TRIAL_2 | The Second Trial: the Banquet. The feast is fragrant. So, alas, is Sir Cheapdate. |
| H_TRIAL_3 | The Third Trial: the Giant's Shadow. Only the Giant Fiber is faster than the Giant's hand. |
| H_HINT_LEFT | Lookout! Her Highness is to the left! |
| H_HINT_RIGHT | Lookout! Her Highness is to the right! |
| H_HINT_TAP | Taster! He touches her. Taste, taste! |
| H_HINT_SNIFF | Perfumer! Find her perfume. |
| H_WARN_GIANT | [urgent] The Giant stirs! |
| H_JUMP | [gasp] The Giant Fiber fires! |
| H_SPLAT | [solemn] The Giant has claimed another suitor. |
| H_WIN | [fanfare] Her Highness is charmed! |
| H_TIMEOUT | [sigh] The candle is spent. Her Highness retires to her chambers. |
| H_RIVAL_WINS | Alas! The Princess favors another. |
| H_CHANGELING | [gasp] A changeling! The same body, the same neurons, but scrambled within. Let us see how the council fares now. |
| H_TRUE_PRINCE | The true Prince returns. |
| H_WEDDING | [bells] Let it be recorded: Prince Hamlet and Princess Miranda, wed by committee. |
| H_DECREE | By royal decree: his wiring is real. Everything else, we will tell you. |
| H_FAINTED | The {role} has fainted! Revive them, quickly! |

### Princess Miranda
| id | Line |
|---|---|
| P_GREET | [curious] Another suitor? Very well. Let us hear you sing. |
| P_CHARMED | [delighted] Now that is a serenade. |
| P_BORED | [sighs] I have seen livelier fruit. |
| P_JUMPED | [laughs] Was it something I said? |
| P_RIVAL | Sir Indy again? He is simply not dead yet. |
| P_WEDDING | [warmly] By committee, then. I accept. |

### Clown the Jester (Chronicle; templates)
| id | Line |
|---|---|
| J_MVP | [laughs] The Royal {role} did {share} percent of the steering. The rest of you were decorative. |
| J_TASTER | The Taster tapped {taps} times. Her Highness felt every single one. |
| J_JUMPS | {jumps} jumps from the {role}'s side. The Giant wasn't even swinging! |
| J_SNIFF | At {time}, someone sniffed Sir Cheapdate. The romance never recovered. I name no names. [pause] Perfumer. |
| J_CHANGELING | The changeling had the very same neurons as our Prince. [laughs] It still walked into the fruit. |
| J_GENERIC_1 | A fine effort, my lords and ladies. Mostly fine. Partly effort. |
| J_GENERIC_2 | The court will remember this trial. The court will try to forget it. |

### Rivals
| id | Line |
|---|---|
| R_INDY | [wheezing] I'm not dead yet! |
| R_TINMAN | Courting? I would need a heart for that. |
| R_CHEAPDATE | [hiccup] One more grape and I shall be royalty. |
| R_RUTABAGA | Have we met? I never remember. |

### Sound effects list (`sfx.csv`)
fanfare_short, fanfare_long, seal_stamp, whoosh_giant, whoosh_fake (softer), splat, crowd_gasp, crowd_cheer, wing_buzz_loop,
hearts_chime, candle_out, wedding_bells, page_turn, lute_sting_win, lute_sting_lose.

### Music list (`music.csv`)
court_dance_loop (lobby, Garden), banquet_loop (livelier), giants_shadow_loop (tense, low drums), wedding_theme (short).

## Trial intro cards

| Trial | Title card | Flavor line |
|---|---|---|
| I | The Garden Audience | "Her Highness takes the evening air among the grapes." |
| II | The Banquet | "The feast is fragrant. So, alas, is Sir Cheapdate." |
| III | The Giant's Shadow | "The Giants stir. The hall grows dark." |

The Matchmaker writes new titles and flavor lines in the same voice for generated trials, drawing only from the cast above.

## The Royal Decree (honesty panel text)

> **By royal decree.** Prince Hamlet runs on the MaleCNS v1.0 wiring diagram of a real male fruit fly (Berg et al., *Cell*, 2026; CC-BY 4.0).
> The connection counts are real. Everything else is our assumption: how strong each connection is, whether it excites or inhibits
> (predicted from neurotransmitters), and leaving out neuromodulators and connections under 5 synapses. Real neurons have dynamics,
> modulation and learning that this model doesn't. How his output neurons become walking is our code. The Princess, the rivals and
> the Giant are scripted. The names are real fly genes; the personalities are ours.
