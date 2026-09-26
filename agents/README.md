# agents/

| File | Owner | What |
|---|---|---|
| `schema.py` | Arnav | The Trial model (Pydantic) |
| `matchmaker.py` | Ved | Designs trials (Gemini, structured output) |
| `master_of_trials.py` | Ved | Tests and certifies trials (Gemini, function calling) |
| `jester.py` | Ved | Writes the Jester's Chronicle lines from the numbers |
| `run_trials.py` | Neil | Headless trial runner (the tool the Master of Trials calls) |
| `bots.py` | Neil | Scripted councils for testing |

No agent runs inside the live game loop. Spec: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#agents).
