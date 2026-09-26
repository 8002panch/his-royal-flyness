# Kickoff checklist (Sat 26 Sept, from 15:45)

Do these in order. Your own full task list is in `team/<your name>/README.md` in the submission repo.

## 0. Decide (5 minutes, all four)

Recommendations are in [DECISIONS.md](DECISIONS.md).

- [ ] LLM for the agents: Gemini (recommended) or Claude.
- [ ] Domain: `royalflyness.club` (fallbacks: `hisroyalflyness.club`, `royalflyness.co`).
- [ ] First hackathon for all four? If yes, tick Best First Time Hack on Devpost.
- [ ] Presenter: Arnav, Ved or Anshul (not Neil).
- [x] Roles: **Neil = brain + science, Arnav = game server, Ved = phones, relay, cloud + AI agents, Anshul = Godot host, art + audio** (equal split, see [BUILD_PLAN.md](BUILD_PLAN.md#roles-and-the-equal-split)). Swap if someone strongly prefers another role, but keep the loads equal.

## 1. Admin (first 15 minutes)

- [x] Public repo created: `github.com/8002panch/his-royal-flyness` (inside the hacking window).
- [ ] Accept the repo invite (Arnav `arnavp-1`, Ved `shahved25`, Anshul `darkspaz-v1`), then clone it.
- [ ] **Everyone: set your laptop clock to automatic** (commit times must fall between 12:00 PM Sat and 11:45 AM Sun). See [RULES_COMPLIANCE.md](RULES_COMPLIANCE.md).
- [ ] Ved: create the **Devpost project** as a draft now (the create deadline is 11:00 AM Sun) and add all 4 members.
- [ ] Ved: claim MLH codes (MLH coach / MLH emails): **DigitalOcean** credits and the **domain** coupon (GoDaddy Registry TLDs such as .club).
- [ ] Anshul: claim the **ElevenLabs** code (3 months free).
- [ ] Ved: **Gemini API key** from Google AI Studio; confirm the Gemini 3.8 Flash model ID.
- [ ] Keys go in a git-ignored `.env` (copy `.env.example`). Never commit keys; the repo is public.
- [ ] Neil: tell an organizer what was prepared before the event (plans and a data check, no code).

## 2. Environment (each person, 15 minutes)

Python 3.11 or newer, fresh venv inside the submission repo:

```bash
python3 -m venv .venv
```

```bash
.venv/bin/pip install numpy scipy pandas pyarrow websockets pydantic qrcode google-genai elevenlabs python-dotenv
```

- Anshul: Godot 4 (latest stable).
- Ved: a DigitalOcean account; Caddy gets installed on the Droplet.
- Neil: copy the three MaleCNS v1.0 Feather files into the repo's git-ignored `data/` (they're in `~/fly-cns-sim/data/raw/malecns/`;
  public CC-BY data, fine to copy; the code is not reused): `connectome-weights-male-cns-v1.0-minconf-0.5.feather` (1.1 GB),
  `body-annotations-male-cns-v1.0-minconf-0.5.feather` (13 MB), `body-neurotransmitters-male-cns-v1.0.feather` (42 MB). Put a copy on a USB stick too.

## 3. Block 1 (15:45 to 17:45)

| Person | By 17:45 |
|---|---|
| Neil | Graph built (166,606 neurons, about 6.24M connections), `io_sets.json`, step timed, 3 Changelings, brain API stub to Arnav by 16:15 |
| Arnav | 50 Hz loop with a fake brain, arena + body, state JSON to Godot, `server/sample_state.json` by 16:30 |
| Ved | Relay live on the Droplet behind the domain, join by seal code, `relay/PROTOCOL.md` by 16:30, latency measured on venue Wi-Fi and cellular |
| Anshul | Parchment main screen, lobby with seal code + QR, crests lighting up, a fly sprite moving from server state |

## 4. 17:45 sync (10 minutes)

- Neil reads out the first probe results (looming, tapping, steering) on the True Prince vs the Changeling.
- Everyone: what's blocked. Anything running at twice its time box gets cut or swapped.
- Confirm the 20:00 gate criteria ([BUILD_PLAN.md](BUILD_PLAN.md#gates)).
