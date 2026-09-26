# Ved: phones, relay, cloud + AI agents

**GitHub:** `shahved25` · **Load:** 15¼ h · **Extra jobs:** Devpost submitter; recruits strangers for the 23:30 test · **Sleep:** 05:15-07:00

## You own
- `relay/`: `relay.py`, `Caddyfile`, `PROTOCOL.md`, `public/` (the phone page: join, crests, the 4 role screens, accessibility modes)
- The DigitalOcean Droplet and the domain (MLH coupon)
- `agents/matchmaker.py`, `agents/master_of_trials.py`, `agents/jester.py`, `levels/lab_log.jsonl` format
- The Devpost submission (with everyone's text)

## You give others
| To | What | By |
|---|---|---|
| Arnav | `relay/PROTOCOL.md` | 16:30 |
| Everyone | The relay live at the domain; the latency number in the team chat | 17:45 |
| Anshul | Jester text hand-off + `levels/lab_log.jsonl` format | 01:00 |
| Everyone | At least 10 certified trials | 05:15 |

## You need
- Arnav: `agents/schema.py` (18:30). Neil: `run_trials` + `get_trace` (00:30).
- Keys: Gemini (AI Studio), DigitalOcean credits and domain coupon (MLH coach).

## Tasks

### B1 · 15:45-17:45 (2 h)
- [ ] **20 min:** create the Devpost draft and add all 4 members; claim the DigitalOcean credits and the domain coupon; get a Gemini key.
- [ ] **30 min:** smallest Droplet; Caddy; point the domain's A record at it (do this first; DNS takes a while).
- [ ] **50 min:** `relay/relay.py`: rooms with 4-consonant codes, host auth with `ROOM_SECRET`, clientId reconnect, heartbeat, forwarding; serves `public/`.
- [ ] **20 min:** `relay/PROTOCOL.md` (from [TECH_ARCHITECTURE.md](../../docs/TECH_ARCHITECTURE.md#messages-json)), **pushed by 16:30**; latency test with 4 phones on venue Wi-Fi and on cellular.

### B2 · 17:55-20:00 (2 h)
- [x] **45 min:** phone join page (code from the QR/URL, name, audio-unlock tap) + crest pick (with "Let the Herald decide").
- [x] **75 min:** the 4 role screens v1: half-screen hold buttons (Lookout left/right eye, Perfumer left/right antenna), Taster tap pad, Spymaster hold; events on change + a 1 s heartbeat.

### B3 · 20:00-23:30 (3½ h)
- [ ] **90 min:** live role views: Lookout panels (icons first), Perfumer 3 x 2 scent meters, Taster contact glow, Spymaster meters; fx flashes; personal Chronicle honors screen.
- [ ] **45 min:** role merging for 2 or 3 players; reconnect UX; the "fainted" pause.
- [ ] **30 min:** LAN fallback (`relay.py --lan` on the laptop + a phone hotspot).
- [ ] **45 min:** accessibility: hold-to-toggle; audio-only Perfumer (stereo pitch) and Spymaster; the whoosh on the Spymaster's phone speaker.
- [ ] Recruit 4 strangers for 23:30.

### B4 · 23:30-03:30 (4 h)
- [ ] **75 min:** `agents/matchmaker.py`: Gemini structured output → Trial JSON (Arnav's schema); geometry checks; the cast and tone rules from `docs/LORE.md` in the prompt.
- [ ] **105 min:** `agents/master_of_trials.py`: Gemini function calling with `run_trials` / `get_trace`; certification rule in code (True Prince win rate 30 to 80% and at least 25 points above the Changeling); up to 3 revisions; saves `levels/certified/` and `levels/rejected/` with notes.
- [ ] **30 min:** `agents/jester.py`: Chronicle JSON → 2 or 3 lines using only those numbers → text for Anshul's voice step.
- [ ] **30 min:** `levels/lab_log.jsonl` format for Anshul's Level Lab screen.

### B5 · 03:30-05:15 awake (1¾ h), then sleep
- [ ] **75 min:** run the batch certification with Neil.
- [ ] **30 min:** curate at least 10 certified trials; play two to check they're fun.

### B6 · 07:00-09:00 (2 h)
- [ ] **75 min:** Devpost text (Inspiration, What it does, tracks, "Try it out" links) from [DEVPOST_DRAFT.md](../../docs/DEVPOST_DRAFT.md).
- [ ] **45 min:** run the [rules checklist](../../docs/RULES_COMPLIANCE.md#quick-checklist-for-sunday-morning-ved-runs-it-at-1030); check the repo is public and the domain works from a fresh phone.
- [ ] **By 10:30:** Devpost complete. **By 11:00:** created. **By 11:45:** final.

## Notes
(your notes here)
