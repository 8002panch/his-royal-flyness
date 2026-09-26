# brain/

Owner: **Neil**. The MaleCNS v1.0 nervous system as a rate model.

Files: `brain.py` (the `Brain` API the server calls), `model.py` (the rate model), `build_graph.py`, `io_sets.py` + `io_sets.json`,
`changeling.py`. Coming: `probes.py`, `replay.py`.

Setup (about 1 minute): put the three MaleCNS Feather files in `data/`, then run `python -m brain.build_graph`,
`python -m brain.io_sets` (only if the groups change) and `python -m brain.changeling`.

API for Arnav (stub by 16:15): `Brain(kind="true"|"changeling", seed=0)`, `.reset()`, `.step(drives) -> outputs`.
Spec: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#the-brain). Numbers to match: [docs/DATA_CHECK.md](../docs/DATA_CHECK.md).
