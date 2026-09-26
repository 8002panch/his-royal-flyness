"""Prince Hamlet's nervous system: the Brain API the game server calls.

Owner: Neil. The server (Arnav) only uses this file's public API:

    brain = Brain(kind="true")          # or kind="changeling", seed=0..2
    brain.reset()                       # back to the resting state (start of a trial)
    out = brain.step(drives)            # advance one 20 ms game tick
    brain.swap("changeling", seed=1)    # hot-swap the wiring between ticks

`drives` maps input group names (INPUT_GROUPS) to a drive between 0 and 1. Missing groups count as 0.
`step` returns every name in OUTPUT_NAMES mapped to a z-score against that neuron group's resting activity
(0 = resting, 3 = strongly active).

Until the real model is built, use `Brain(stub=True)`. The stub is a toy mapping so the server can be tested
end to end. It is NOT the fly's brain and must never be shown as one.
"""

from __future__ import annotations

TICK_S = 0.020  # one game tick; the real model runs two 10 ms steps per tick

# Input groups: which sensory neurons each phone role drives (sides are the fly's left and right).
INPUT_GROUPS: tuple[str, ...] = (
    # Royal Lookout (eyes)
    "LC10a_L", "LC10a_R",          # small moving objects (the Princess, rivals)
    "LPLC2_L", "LPLC2_R",          # looming
    "LC4_L", "LC4_R",              # looming
    # Royal Perfumer (nose): olfactory receptor neurons by antenna
    "ORN_VA1v_L", "ORN_VA1v_R",    # Or47b, her courtship scent
    "ORN_DM1_L", "ORN_DM1_R",      # Or42b, the Feast (fermenting fruit)
    "ORN_DA1_L", "ORN_DA1_R",      # Or67d, a rival male's cVA
    # Royal Taster (feet): foreleg pheromone-taste neurons
    "ppk23_L", "ppk23_R",
    # Royal Spymaster (ears): Johnston's organ
    "JO_wind_L", "JO_wind_R",      # JO-C / JO-E
    "JO_sound_L", "JO_sound_R",    # JO-A / JO-B
)

# Output names: what moves the body (mapping to movement lives in server/body.py).
OUTPUT_NAMES: tuple[str, ...] = (
    "DNa02_L", "DNa02_R",          # steering
    "DNa01_L", "DNa01_R",          # steering
    "DNp09",                       # walk forward (both sides averaged)
    "DNg100",                      # walk forward
    "MDN",                         # back up
    "DNp01",                       # the Giant Fiber: escape jump
    "pIP10",                       # male-only song command: wing out, serenade
    "pC1",                         # male-specific courtship cluster (display only: the "Courting" meter)
)

KINDS = ("true", "changeling")


class Brain:
    """The whole MaleCNS v1.0 nervous system as a rate model (or a toy stub for testing)."""

    def __init__(self, kind: str = "true", seed: int = 0, stub: bool = False) -> None:
        if kind not in KINDS:
            raise ValueError(f"kind must be one of {KINDS}, got {kind!r}")
        self.kind = kind
        self.seed = seed
        self.stub = stub
        if stub:
            self._impl = _StubImpl()
        else:
            from brain.model import RateModel  # real model; needs data/graph_*.npz from build_graph.py

            self._impl = RateModel(kind=kind, seed=seed)
        self.reset()

    def reset(self) -> None:
        self._impl.reset()

    def step(self, drives: dict[str, float]) -> dict[str, float]:
        unknown = set(drives) - set(INPUT_GROUPS)
        if unknown:
            raise KeyError(f"unknown input groups: {sorted(unknown)}")
        clean = {g: min(1.0, max(0.0, float(drives.get(g, 0.0)))) for g in INPUT_GROUPS}
        return self._impl.step(clean)

    def swap(self, kind: str, seed: int = 0) -> None:
        """Swap the True Prince for a Changeling (or back). Resets to rest."""
        if kind not in KINDS:
            raise ValueError(f"kind must be one of {KINDS}, got {kind!r}")
        self.kind, self.seed = kind, seed
        if not self.stub:
            self._impl.load(kind=kind, seed=seed)
        self.reset()


class _StubImpl:
    """Toy stand-in with smoothed, hand-written responses. For plumbing tests only: NOT the fly's brain."""

    _ALPHA = 0.2  # smoothing per tick

    def reset(self) -> None:
        self._z = {name: 0.0 for name in OUTPUT_NAMES}

    def step(self, d: dict[str, float]) -> dict[str, float]:
        loom_l = max(d["LPLC2_L"], d["LC4_L"])
        loom_r = max(d["LPLC2_R"], d["LC4_R"])
        court = d["ORN_VA1v_L"] + d["ORN_VA1v_R"] + 2 * (d["ppk23_L"] + d["ppk23_R"])
        mood_kill = d["ORN_DA1_L"] + d["ORN_DA1_R"]
        target = {
            "DNa02_L": 3 * d["LC10a_L"] + 1.5 * d["ORN_VA1v_L"] + d["ORN_DM1_L"],
            "DNa02_R": 3 * d["LC10a_R"] + 1.5 * d["ORN_VA1v_R"] + d["ORN_DM1_R"],
            "DNa01_L": 2 * d["LC10a_L"],
            "DNa01_R": 2 * d["LC10a_R"],
            "DNp09": 2 * (d["LC10a_L"] + d["LC10a_R"]) + d["ORN_DM1_L"] + d["ORN_DM1_R"],
            "DNg100": 1.5 * (d["LC10a_L"] + d["LC10a_R"]),
            "MDN": 2 * mood_kill,
            "DNp01": 4 * max(loom_l, loom_r) + 3 * max(d["JO_wind_L"], d["JO_wind_R"]),
            "pIP10": max(0.0, 2 * court - 2 * mood_kill),
            "pC1": max(0.0, 1.5 * court - 2 * mood_kill),
        }
        a = self._ALPHA
        for name in OUTPUT_NAMES:
            self._z[name] += a * (target[name] - self._z[name])
        return dict(self._z)


if __name__ == "__main__":
    # Smoke test: the stub should turn left, walk and sing when the left eye sees her and the Taster taps.
    b = Brain(stub=True)
    for _ in range(50):
        out = b.step({"LC10a_L": 1.0, "ppk23_L": 1.0, "ppk23_R": 1.0})
    print({k: round(v, 2) for k, v in out.items()})
