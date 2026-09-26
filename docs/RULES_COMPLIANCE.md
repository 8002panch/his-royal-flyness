# hackUMBC 2026 rules: how we comply

Sources: the hackUMBC 2026 Devpost overview and rules pages, and hackumbc.tech (read Sat 26 Sept 2026). A violation of the rules or
the Code of Conduct means **disqualification, removal from the event and a permanent ban** from hackUMBC events, so treat this as a checklist.

| # | Rule (source) | How we comply | Owner | Status |
|---|---|---|---|---|
| 1 | **Hacking period is 12:00 PM Sat 26 Sept to 11:45 AM Sun 27 Sept. "Any commits made in the project Github repo must have been made within this timeframe."** (Devpost rules) | The public repo `his-royal-flyness` was created at 15:21 Sat. **No commits after 11:45 AM Sun.** Everyone sets their laptop clock to automatic (commit times come from your clock). **Never force-push, rebase `main`, amend old commits or change commit dates.** The private planning repo (with commits from before 12:00) is never submitted | Everyone | Set clocks now |
| 2 | **Building on an existing project makes it ineligible for prizes** (hackumbc.tech: organizers "strongly discourage building upon existing projects, as they will not be eligible for prizes") | All code is written during the event. **Not copied in:** Neil's `fly-cns-sim` code; code from our earlier pre-event plan (including a camera-check tool, 23 Sept); the Codex session-handoff plugin (pushed 01:24 Sat, before the window; fine to use locally, not committed to this repo); the reference probe scripts in the planning repo. Open-source libraries and engines (NumPy, SciPy, Godot, websockets, Caddy) and public APIs are tools, not projects | Everyone | In place |
| 3 | Plans made before the event | `docs/` holds plans and a data check written before and at the start of the event. **No code.** The README says so. Tell an organizer at the start what was prepared (plans, data check, no code) | Neil | Tell an organizer |
| 4 | **No cross-submissions**: this project may not be submitted to other hackathons, and projects from other hackathons aren't accepted (Devpost rules) | We submit only here. Don't enter this project anywhere else afterwards without checking the rules | Everyone | In place |
| 5 | **Team of at most 4, all checked in** (Devpost requirements; hackumbc.tech) | Neil, Arnav, Ved, Anshul. All four must be checked in | Everyone | Confirm check-in |
| 6 | Eligibility: enrolled university students aged 18+, or enrolled UMBC students under 18 | Confirm all four qualify | Everyone | Confirm |
| 7 | **One project per team** | Only *His Royal Flyness* | Ved (submitter) | In place |
| 8 | **Devpost submission created by 11:00 AM Sun; finalized by 11:45 AM Sun** | Draft created in B1; complete by 10:30; Ved submits | Ved | To do |
| 9 | **GitHub link to all code written for the hack, repo set to public** before attaching | `github.com/8002panch/his-royal-flyness` is public. Everything the game runs is committed (except secrets and the large public data files, which the README says how to get) | Arnav (README), Ved (link) | Repo created |
| 10 | **Demo video, at least 30 seconds** (screen recording + voiceover is fine) | Aim for about 90 s, recorded by 08:00 Sun | Anshul | To do |
| 11 | **In-person demo of 3 to 5 minutes**; projects not present aren't judged | Stay at the table during judging; 3-minute and 5-minute scripts rehearsed | Presenter + everyone | To do |
| 12 | Tracks: enter as many as fit, but **each must clearly fit**; organizers can remove a project from a track that doesn't | Only the tracks in [TRACKS_AND_PRIZES.md](TRACKS_AND_PRIZES.md). Sponsor tech must be genuinely used (ElevenLabs voices, DigitalOcean relay, GoDaddy Registry domain, Gemini agents). Don't tick Tiger Data unless it's actually built | Ved | To do |
| 13 | **Best First Time Hack: all members must be at their first hackathon** | Only tick it if that's true for all four | Everyone | Decide |
| 14 | **MLH Code of Conduct** + hackUMBC rules | Be respectful to everyone; follow organizer instructions; report problems to organizers. Lore jokes are never about real people or groups ([LORE.md](LORE.md#tone-rules)) | Everyone | In place |
| 15 | Data license: MaleCNS v1.0 is **CC-BY 4.0** (attribution required) | Credit in the README, the Royal Decree screen and Devpost: Berg et al., *Cell* 2026; HHMI Janelia FlyEM, Google Research, University of Cambridge, MRC LMB. Data files aren't committed (size); the README says where to get them | Neil | In README |
| 16 | Third-party assets | Fonts: Google Fonts (SIL Open Font License), credited. Sprites and UI drawn during the event. Voices, sound effects and music generated with our ElevenLabs account during the event, using **library voices only (no cloning real people)** | Anshul | In place |
| 17 | API terms and secrets | Gemini and ElevenLabs keys live only in `.env` (git-ignored); `.env.example` has blanks. **The repo is public, so a leaked key is abused within minutes.** If a key is ever committed, revoke it immediately; don't try to rewrite history (rule 1) | Everyone | In place |
| 18 | AI tools (no restriction stated) | Allowed. We disclose them in the README and on Devpost: planning drafted with Claude (Anthropic); in-game agents use Gemini; voices by ElevenLabs. Everyone must be able to explain the code they commit | Everyone | In README |
| 19 | Honesty to judges | The Royal Decree on screen, in the README and on Devpost says what's real (the wiring) and what's assumed or scripted. No number on screen unless the game computed it | Neil | In place |
| 20 | Privacy | Phone players give only a display name; nothing is stored after the session; no analytics | Ved | In place |

## Quick checklist for Sunday morning (Ved runs it at 10:30)

- [ ] Repo public; README has the plans note, the Decree, credits, the AI-tools line and how to run.
- [ ] Last commit is before 11:45 AM; nobody force-pushed.
- [ ] Devpost: all 4 members, public repo link, video (30 s or more), description, tracks that fit, domain link.
- [ ] First Time Hack ticked only if all four are first-timers.
- [ ] No keys in the repo.
- [ ] Team at the table for judging.
