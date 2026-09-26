"""Prince Hamlet's nervous system: the Brain API the game server calls.

Owner: Neil. The server (Arnav) only uses this file's public API:

    brain = Brain(kind="true")          # or kind="changeling", seed=0..2
    brain.reset()                       # back to the resting state (start of a trial)
    out = brain.step(drives)            # advance one 20 ms game tick
    brain.swap("changeling", seed=1)    # hot-swap the wiring between ticks

`drives` maps input group names (INPUT_GROUPS, one per phone button) to a drive between 0 and 1. Missing groups count as 0.
A normal press is 0.6; specials (Charge, Launch) use 1.0.
`step` returns every name in OUTPUT_NAMES mapped to a z-score against that neuron group's resting activity
(0 = resting, 3 = strongly active).

Until the real model is built, use `Brain(stub=True)`. The stub is a toy mapping so the server can be tested
end to end. It is NOT the fly's brain and must never be shown as one.
"""

from __future__ import annotations

TICK_S = 0.020  # one game tick; the real model runs two 10 ms steps per tick

# Input groups (v2): one per phone button. Each stimulates a named group of real sensory neurons (like optogenetics).
# Chosen from a scan of all sensory types (docs/TECH.md, "The brain"); the comment gives the target the wiring drives.
INPUT_GROUPS: tuple[str, ...] = (
    "forward",    # Coachman:  LC9 + LC31a                      -> DNp09 thrust (z 34)
    "back",       # Coachman:  SNta02/SNta09 + LC16 + LoVP26    -> MDN back up (z 4)
    "left",       # Helmsman:  LLPC1, left side                 -> DNa02 left, turn left (z 10)
    "right",      # Helmsman:  LLPC1, right side                -> DNa02 right, turn right (z 13)
    "up",         # Falconer:  LPLC1 + LLPC2                    -> DNg02 wing power (z 5)
    "down",       # Falconer:  LPLC4                            -> DNp07 + DNp10 landing (z 44)
    "duck",       # Spymaster: LC4 + LPLC2                      -> DNp01 Giant Fiber escape (z 99)
    "serenade",   # Spymaster: LC10a + LC10d, both eyes         -> pIP10 song (z 9)
    "lock_L",     # Helmsman special: LC10a + LC10d, left eye   -> turn left toward her (z 18)
    "lock_R",     # Helmsman special: LC10a + LC10d, right eye  -> turn right toward her
    # Seer senses (world stimuli, not buttons): brain/seer.py drives these from where the Princess and the Giants are
    "her_L", "her_R",     # Princess detectors LC10a + LC10d, each eye
    "loom_L", "loom_R",   # looming detectors LC4 + LPLC2, each eye
    "wind_L", "wind_R",   # antennal wind sensors JO-C + JO-E, each antenna
)

# Output names (v2): what moves the body (mapping to movement lives in server/body.py).
OUTPUT_NAMES: tuple[str, ...] = (
    "DNp09",                       # thrust / forward
    "DNg100",                      # walking (small; kept for the chart)
    "MDN",                         # back up / brake
    "DNa02_L", "DNa02_R",          # turning
    "DNg02",                       # wing power: climb
    "DNp07_10",                    # landing neurons DNp07 + DNp10: descend
    "DNp01",                       # the Giant Fiber: escape dart
    "pIP10",                       # male-only song command: serenade
    "pC1",                         # male-specific courtship cluster (display only)
    # Seer readouts: side-selective descending-neuron populations (chosen by a left-vs-right scan; docs/TECH.md, "The Royal Seer")
    "seer_her_L", "seer_her_R",    # DNa02, DNg111, DNae002, DNae001, DNg41, DNa10 on each side: where the Princess is
    "seer_loom_L", "seer_loom_R",  # DNp04, DNp02, DNp01, DNg40, DNp11, DNp03 on each side: where the Giant is
    "seer_wind_L", "seer_wind_R",  # DNge016, DNg29, DNge175, DNp18, DNg05_a on each side: where the gust comes from
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
        target = {
            "DNp09": 30 * d["forward"],
            "DNg100": 2 * d["forward"],
            "MDN": 4 * d["back"],
            "DNa02_L": 10 * d["left"] + 18 * max(d["lock_L"], d["her_L"]) + 11 * d["serenade"],
            "DNa02_R": 12 * d["right"] + 18 * max(d["lock_R"], d["her_R"]) + 11 * d["serenade"],
            "DNg02": 5 * d["up"],
            "DNp07_10": 40 * d["down"],
            "DNp01": 90 * max(d["duck"], d["loom_L"], d["loom_R"]),
            "pIP10": 9 * d["serenade"] + 3.5 * max(d["lock_L"], d["lock_R"]) + 9 * min(d["her_L"], d["her_R"]),
            "pC1": 1.5 * d["serenade"],
            "seer_her_L": 18 * d["her_L"], "seer_her_R": 18 * d["her_R"],
            "seer_loom_L": 90 * d["loom_L"], "seer_loom_R": 90 * d["loom_R"],
            "seer_wind_L": 12 * d["wind_L"], "seer_wind_R": 12 * d["wind_R"],
        }
        a = self._ALPHA
        for name in OUTPUT_NAMES:
            self._z[name] += a * (target[name] - self._z[name])
        return dict(self._z)


if __name__ == "__main__":
    # Smoke test: FORWARD + LEFT on the real brain (falls back to the stub if data/ isn't built).
    try:
        b = Brain("true")
    except FileNotFoundError:
        b = Brain(stub=True)
    for _ in range(40):
        out = b.step({"forward": 1.0, "left": 1.0})
    print("stub" if b.stub else "real", {k: round(v, 1) for k, v in out.items()})
