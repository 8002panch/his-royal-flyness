# Data check: what MaleCNS v1.0 actually supports

Run on Sat 26 Sept 2026 on Neil's M2 (8 GB), against MaleCNS v1.0 tables already on the laptop. The scripts are in
`docs/data_check/` of the private planning repo, for reference only. They read tables built by Neil's separate `fly-cns-sim` project, so they are
**not** project code and must not be copied into the submission repo. Rebuild the graph from the raw Feather files at the event.

## Dataset

| Fact | Value |
|---|---|
| Release | v1.0 public since 8 June 2026; Cell paper (Berg et al.) and Google blog on 3 Sept 2026 |
| License | CC-BY 4.0 |
| Files we need | `connectome-weights-...-minconf-0.5.feather` (1.1 GB), `body-annotations-...-minconf-0.5.feather` (13 MB), `body-neurotransmitters-....feather` (42 MB) |
| Files we skip | synapse points (12.7 GB), synapse partners (6.8 GB), per-synapse transmitter predictions (2.7 GB), body stats (780 MB) |
| Neurons (superclass present, not "tbc") | 166,606 (206 have no edges) |
| Connections / synapses | 25,574,615 connections; 124,144,950 synapses |
| Connection strength | median 2 synapses; 90th percentile 10; 99th 46; 40.3% are single-synapse |
| Inhibitory neurons (GABA, glutamate, histamine) | 59,242; 38.4% of connections |
| Transmitter counts | acetylcholine 103,691; glutamate 29,298; GABA 22,053; histamine 7,891; unclear 2,966; dopamine 392; octopamine 101; serotonin 48; missing 166 |

## Pruning and speed

| Keep connections with | Connections | Share of synapses | One simulation step (SciPy, float32, single thread) |
|---|---|---|---|
| 1 or more synapses (everything) | 25,574,615 | 100% | 24.5 ms (too slow for 50 Hz) |
| 3 or more | 10,517,265 | not measured | 9.0 ms |
| **5 or more (the plan)** | **6,240,402** | **72.4%** | **5.3 ms** |

## No small subcircuit exists

Using connections with 5 or more synapses, starting from all sense input groups and all output neurons below:

| Hops | Downstream of the senses | Upstream of the outputs | Both |
|---|---|---|---|
| 2 | 59,585 | 69,720 | **37,004** |
| 3 | 147,662 | 151,691 | **140,223** of 166,606 |

So "extract the circuit" doesn't shrink anything past 2 hops. The plan runs the whole CNS. The 2-hop core (37,004 neurons) is the speed fallback only.

## Fewest hops from each sense to each output (connections with 5 or more synapses)

| Sense | DNa02 | DNa01 | DNp09 | DNg100 | MDN | DNp01 (Giant Fiber) | pIP10 (song) | MN9 |
|---|---|---|---|---|---|---|---|---|
| Eyes: LC10a + LPLC2 + LC4 | 2 | 2 | 1 | 2 | 2 | **1** | 2 | 3 |
| Nose: ORN VA1v + DM1 + DA1 | 3 | 3 | 3 | 2 | 3 | 3 | 3 | 3 |
| Feet: foreleg ppk23 | 2 | 2 | 3 | 3 | 2 | 2 | **2** | 3 |
| Ears: JO-A/B/C/E | 2 | 2 | 2 | 2 | 2 | **1** | 2 | 2 |

The Nose is the furthest from any movement neuron, so it's the most likely to feel weak (test D at the 20:00 gate).

## Key pathways (total synapses between the groups)

| From | To | Synapses | What it means for the game |
|---|---|---|---|
| LC4 (looming) | DNp01, the Giant Fiber | **6,362** (126 connections) | The Lookout can trigger the escape jump |
| LPLC2 (looming) | DNp01 | **4,862** (185 connections) | Same |
| JO ear neurons | DNp01 | **709** | The Spymaster can trigger it too |
| Foreleg ppk23 | vAB3 (AN09B017e/f/g, ascending) | all 6 vAB3 get direct input | The Taster's tap climbs the nerve cord |
| vAB3 | pC1 cluster (P1 is in here) | **1,322** (157 connections) | ...into the courtship cluster in the brain |
| pC1 cluster | pIP10 (male-only song command) | **1,941** (167 connections) | ...and back down to the wing |
| LC10a (female tracking) | DNa02 (steering) | **0** direct | Steering needs a relay neuron, so test C decides it |
| LC10a / LPLC2 | DNp09 (walking) | 65 / 111 | A small direct walk signal |
| ORN DA1/VA1v/DM1 | their projection neurons | e.g. DA1_lPN 30,070 | Normal olfactory wiring; far from movement |

Top inputs to the Giant Fiber: LC4 6,362; LPLC2 4,862; DNp70 1,416; PVLP122 1,216; SAD064 1,215; SAD073 1,177.
Top inputs to pIP10: aIPg7 1,280; ICL008m 916; AVLP717m 754; AVLP710m 754; AVLP718m 723; VES024_a 578; AVLP256 575; pC1_14a 565.

## Input and output groups (counts and sides)

| Group | Types | Neurons | Side column | Left / right |
|---|---|---|---|---|
| Eyes | LC10a 275, LPLC2 185, LC4 126 | 586 | `somaSide` | 300 / 286 |
| Nose | ORN_VA1v 130, ORN_DM1 74, ORN_DA1 204 | 408 | `rootSide` | 101 / 217 (90 unknown) |
| Feet | putative ppk23 entering by the prothoracic leg nerve (ProLN) | 71 | `rootSide` | 37 / 34 |
| Ears | JO-A*, JO-B*, JO-C*, JO-E* | 473 | `rootSide` | 280 / 193 |
| Outputs | DNa02, DNa01, DNp09, DNg100, pIP10, MN9, DNp01 (2 each); MDN (4) | 16 | `somaSide` | 1 / 1 each (MDN 2 / 2) |

All output neurons are predicted cholinergic (excitatory).

Other annotation facts:
- `receptorType` only holds putative ppk23 (269), ppk25 (257) and IR52b (226). All 269 ppk23 are VNC sensory neurons, entering
  by ADMN (96), ProLN (71), MetaLN (52), MesoLN (50). There are no sugar or bitter receptor labels.
- Other eye types available: LC9 219, LC11 143, LC10b 95.

## Naming gotchas

- **There is no type named "P1".** The P1 neurons are among the **148 male-specific pC1-cluster neurons** (126 labeled male-specific,
  22 potentially male-specific; 49 pC1 types in total including 8 dimorphic neurons).
- **vAB3** is `AN09B017e`, `AN09B017f`, `AN09B017g` (found through the `synonyms` column, e.g. "Yu 2010: vAB3").
- **The Giant Fiber** is type `DNp01` (hemibrain type "Giant Fiber").
- **pIP10** is its own type, labeled male-specific (2 neurons).
- **MN9** is type `MN9` (FlyWire CB0701).
- mAL shows up as many `mAL_m*` male-specific types.
- The neurotransmitter table has more rows than there are bodies; join on `body` carefully.

## Caveats

- The first reachability count had an integer-overflow bug (int8 frontier vectors). The corrected run, used above, gives 140,223 at 3 hops (the first run gave 140,189) and confirms the eyes reach the Giant Fiber in 1 hop.
- These are structural facts. **Nothing here shows the model will steer, sing or jump on cue.** That's what the probes at the 17:45 sync and the 20:00 gate test.
- BANC (female brain + nerve cord) has about a third of MaleCNS's synapse total because of how it was imaged and processed, not
  because of sex. Any male vs female feature (the stretch "Princess brain") must normalize for that.
- Earlier measurement from `fly-cns-sim`: a Shiu-style spiking model of the whole FlyWire brain took 42 s per simulated second and about 3.1 GB on this laptop. That's why we use a rate model.
