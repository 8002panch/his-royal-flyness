# brain/

Owner: **Neil**. The MaleCNS v1.0 nervous system as a rate model.

Planned files: `build_graph.py`, `io_sets.py` + `io_sets.json`, `brain.py` (the `Brain` class the server calls), `sim.py`,
`changeling.py`, `probes.py`, `replay.py`.

API for Arnav (stub by 16:15): `Brain(kind="true"|"changeling", seed=0)`, `.reset()`, `.step(drives) -> outputs`.
Spec: [docs/TECH_ARCHITECTURE.md](../docs/TECH_ARCHITECTURE.md#the-brain). Numbers to match: [docs/DATA_CHECK.md](../docs/DATA_CHECK.md).
