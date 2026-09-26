# Demo script

Judging is in person, 3 to 5 minutes. The Game Jamathon also presents to industry judges. Use the 3-minute version for general
judges and the 5-minute version for the Game Jam.

## Team positions during the demo

| Who | Job |
|---|---|
| Presenter (not Neil) | Talks. Owns the timing |
| Driver | At the laptop: starts trials, flips TRUE PRINCE / CHANGELING, opens the Level Lab and the Decree |
| Phone wrangler | Hands out team phones if judges don't want to scan; makes sure every role is filled |
| Neil | Science questions; plays a role if a judge sits out |

## Setup checklist (before the judges arrive)

- [ ] Laptop plugged in, fan-noise check, Chrome and other heavy apps closed, sleep disabled.
- [ ] Server + Godot running; tick rate shown in the debug overlay is at 50 Hz.
- [ ] Relay warm (open the domain on one phone); a backup phone hotspot ready for LAN mode.
- [ ] 4 team phones already joined with sound unlocked (one tap each), brightness up, auto-lock off.
- [ ] Speaker volume checked for the Herald. Captions on.
- [ ] Main screen shows the lobby with the seal code and QR large enough to scan from 2 m.
- [ ] Level Lab log and certified numbers ready to show. The Decree screen one key away.
- [ ] Backup video queued in case everything fails.

## 3-minute version

| Time | Beat | Say / do |
|---|---|---|
| 0:00-0:20 | **The Herald** | Herald: "Hear ye! The Royal Ball begins!" Presenter: "Prince Hamlet is a real male fruit fly. We run his entire nervous system, all 166,000 neurons from the map published this month. He can't see, smell, taste or hear. You are his senses." Judges scan the seal |
| 0:20-0:50 | **The Garden** | Lookout holds left, he turns and walks, the Taster taps, his wing buzzes. "That serenade is pIP10, a male-only neuron. The Taster's tap went up his leg, through his neck into his brain, and back down to his wing." |
| 0:50-1:40 | **The Giant's Shadow** | People start shouting. He jumps. "The only thing faster than the Giant's hand is the Giant Fiber, the real neuron that fires his escape. Thousands of synapses connect his looming detectors straight to it." |
| 1:40-2:05 | **The Chronicle** | The Jester roasts the council; honors show on each judge's phone. "We replayed that trial with each of your senses switched off to see who really moved him." |
| 2:05-2:35 | **The Changeling** | Flip the toggle; replay the same trial. "Same neurons, same number of connections, same input to every neuron. Only the partners are scrambled." Show the certified numbers: **[True Prince win %] vs [Changeling win %]**, filled in from real results only. If the live replay isn't clearly different, lead with the numbers |
| 2:35-2:50 | **The Level Lab** | Scroll the log: "The Matchmaker designed a trial, the Master of Trials tested it on the real prince and the Changeling, rejected it, and asked for a revision. Only certified trials reach you." |
| 2:50-3:00 | **The Royal Decree** | "Every name in this kingdom is a real fly gene. His wiring is real. Everything we assumed, we tell you." |

## 5-minute version (Game Jamathon)

Everything above, plus:
- **After the Garden (+1:00):** play the Banquet. Point out the Perfumer's hidden information ("only the Perfumer knows where the scents are") and the rival's scent.
- **Before the Changeling (+0:30):** the art and audio: the manuscript style, the Royal Nervous System chart, the Herald, Jester and Princess voices, the generated music.
- **Before the Decree (+0:30):** the royal cast and the fact cards (Hamlet, Miranda and Prospero, Sir Indy, Lord Tinman).

## If something breaks

| Problem | Do this |
|---|---|
| A judge's phone won't join | Hand them a team phone that's already joined |
| The relay or Wi-Fi drops | Switch to LAN mode (phone hotspot); if that fails, keyboard mode with the Driver narrating |
| The laptop lags | Toggle off the Chronicler shadows (debug key); keep playing |
| A voice line doesn't play | Captions carry it; the Presenter reads the line |
| Total failure | Play the backup video and talk over it |

## Q&A drill

| Question | Answer |
|---|---|
| Is the fly actually thinking? | It's the real wiring diagram run as a simple model. The connection counts are real; the strengths, signs and the walking code are our assumptions, and we list them. It shows what this wiring does under those assumptions, not what a living fly would do |
| Why not a spiking model? | Speed. A rate model runs the whole nervous system at 50 Hz on a laptop. A spiking whole-brain model took about 42 seconds per simulated second on this laptop |
| Did you hand-pick neurons? | No. All 166,606 run. We chose where each sense enters (named sensory neuron types) and which named output neurons move the body; they're all listed on the chart |
| What exactly is the Changeling? | Every connection's sender is shuffled among neurons with the same sign. Every neuron keeps its exact total input and its excitatory/inhibitory mix, and its number of outputs. Only who talks to whom changes |
| How do you know it isn't just your movement code? | The movement code is identical for the True Prince and the Changeling. The certified numbers show the difference comes from the wiring |
| What's new here since the map came out? | It's the first complete male nervous system, brain and nerve cord in one animal. The tap-to-song loop crosses the neck twice and uses pIP10, which only males have |
| Is the Princess simulated? | She's scripted. The stretch goal is to run her on the female nervous system map, which has no pIP10 |
| What do the AI agents do? | The Matchmaker designs trials. The Master of Trials calls our brain simulation as a tool to test each trial on the real prince and the Changeling with bot councils, and rejects or sends back anything unfair. The Chronicler credits each player |
| Are those gene names real? | Yes: hamlet, miranda, prospero, I'm not dead yet, tinman, clown. The personalities are ours |
| Why does this matter? | More than 100 fly-brain projects showed up in three weeks, and nearly all of them show a fly playing an existing game. This one makes you part of the fly and shows what the wiring does and doesn't do. It runs on any phone with no install, so it works in a classroom |
| How long did it take? | Built in 24 hours at hackUMBC. The plans were written before and at the start |

## Demo video (required, 30 s minimum; aim for about 90 s)

Record by 08:00 Sunday. A screen recording with voiceover is fine.

1. 0-8 s: title card + Herald line.
2. 8-35 s: gameplay, with a phone in frame for each role (film the phones and the screen).
3. 35-55 s: the Giant's Shadow and the Giant Fiber jump.
4. 55-70 s: the Chronicle with the Jester.
5. 70-85 s: the Changeling flip and the certified numbers.
6. 85-90 s: the Royal Decree + the domain.
