"""Hamlet's brain map: the live picture in the main screen's top-right corner (owner: Neil).

A second copy of the same whole-CNS rate model (brain/model.py, all 166,606 neurons) that is driven only by Hamlet's own
movement, never by the Princess or the Giant, so the shared screen can show it without giving away the Seer's secret.

    bm = BrainMap("true")
    bm.set_drinks(1)                          # cordials drunk so far (the campaign's wrong answers), 0..3
    bm.step({"x": fly.vx, "y": fly.vy, "z": fly.vz})   # one 20 ms model step from his velocity (-1..1 per axis)
    bm.view()     # {"regions": {key: log2 of mean rate vs sober rest}, "drinks": 1, "kind": "true", "neurons": 166606, ...}
    bm.drink_table()   # [{region: mean rate}] for 0..3 drinks in steady forward flight (for the quiz comparison)

Movement -> neurons (our assumption): each direction of travel stimulates the named visual neuron group used for that
direction in brain v2 (brain/brain.py INPUT_GROUPS "forward", "back", "left", "right", "up", "down"), in proportion to
his speed on that axis. The rest of the brain responds through the real wiring.

Alcohol (our assumption, a deliberate simplification): ethanol strengthens GABA-mediated inhibition and weakens excitatory
transmission. Here each cordial multiplies the output of every GABAergic neuron by (1 + GABA_PER_DRINK) and of every
excitatory (acetylcholine) neuron by (1 - EXCITE_PER_DRINK), cumulatively. That is not a measured fly result; it is a
single, disclosed knob on the real wiring, and the map shows what the wiring does with it. The Seer's brain is never
changed: the Seer's cues always come from the sober True Prince (or the Changeling).

Regions are groups of real neurons picked by their MaleCNS annotations (REGIONS below). Values are log2(mean rate / sober
resting mean rate), so 0 = as at sober rest, +1 = twice as active, -1 = half.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

from brain.model import DATA, RateModel

GABA_PER_DRINK = 0.20
EXCITE_PER_DRINK = 0.08
MAX_DRINKS = 3
MOVE_DRIVE = 0.8          # drive at full speed on an axis (a phone button press was 0.6 in brain v2)
EPS = 0.002               # rate floor in the log ratio, so near-silent regions don't flicker between extremes
SMOOTH = 0.35             # per-step smoothing of the displayed values
TABLE_TICKS, TABLE_AVG = 80, 40   # steady state for the drink table: settle, then average the last TABLE_AVG steps

# key, label on the map, what it does (for the legend and docs), how its neurons are picked
REGIONS: tuple[tuple[str, str, str], ...] = (
    ("eye_L", "LEFT EYE", "optic lobe, left: all its intrinsic, sensory and projection neurons"),
    ("eye_R", "RIGHT EYE", "optic lobe, right"),
    ("smell", "SMELL", "antennal lobe: olfactory receptor, projection and local neurons"),
    ("memory", "MEMORY", "mushroom body: Kenyon cells, MBONs and dopamine neurons (learning and memory)"),
    ("balance", "BALANCE", "central complex (CX class): navigation, steering and coordinated movement"),
    ("instinct", "INSTINCT", "lateral horn neurons (LH*): innate responses"),
    ("courtship", "COURTSHIP", "male-specific pC1, P1 and pIP10 neurons"),
    ("taste", "TASTE", "gustatory neurons"),
    ("commands", "COMMANDS", "all descending neurons: the brain's commands to the body"),
    ("escape", "ESCAPE", "the Giant Fiber, DNp01"),
    ("cord", "NERVE CORD", "ventral nerve cord intrinsic and ascending neurons"),
    ("muscles", "MUSCLES", "motor neurons"),
    # the main screen's simpler view joins some of these: both eyes, and the whole body side (nerve cord + motor neurons)
    ("eyes", "EYES", "both optic lobes"),
    ("body", "WINGS & LEGS", "ventral nerve cord intrinsic, ascending and motor neurons"),
)
REGION_KEYS = tuple(r[0] for r in REGIONS)


def region_indices(neurons: pd.DataFrame) -> dict[str, np.ndarray]:
    t = neurons["type"].fillna("")
    cls = neurons["class"].fillna("")
    sc = neurons["superclass"].fillna("")
    side = neurons["somaSide"].fillna("")
    male = neurons["dimorphism"].fillna("").str.contains("male")
    visual = sc.isin(["ol_intrinsic", "ol_sensory", "visual_projection", "visual_centrifugal"])
    masks = {
        "eye_L": visual & (side == "L"),
        "eye_R": visual & (side == "R"),
        "smell": cls.isin(["olfactory", "ALPN", "ALLN", "ALIN", "ALON"]),
        "memory": cls.isin(["Kenyon_Cell", "MBON", "DAN"]),
        "balance": cls == "CX",
        "instinct": t.str.startswith("LH"),
        "courtship": (t.str.startswith("pC1") | t.str.startswith("P1") | t.str.startswith("pIP10")) & male,
        "taste": cls == "gustatory",
        "commands": sc == "descending_neuron",
        "escape": t == "DNp01",
        "cord": sc.isin(["vnc_intrinsic", "ascending_neuron"]),
        "muscles": sc.isin(["vnc_motor", "cb_motor"]),
        "eyes": visual,
        "body": sc.isin(["vnc_intrinsic", "ascending_neuron", "vnc_motor"]),
    }
    return {k: np.flatnonzero(masks[k].to_numpy()) for k in REGION_KEYS}


def motion_drives(motion: dict[str, float]) -> dict[str, float]:
    """Velocity per axis (-1..1; x right, y up, z forward) -> drives for the v2 direction groups."""
    x, y, z = (max(-1.0, min(1.0, float(motion.get(a, 0.0)))) for a in ("x", "y", "z"))
    return {"right": MOVE_DRIVE * max(0.0, x), "left": MOVE_DRIVE * max(0.0, -x),
            "up": MOVE_DRIVE * max(0.0, y), "down": MOVE_DRIVE * max(0.0, -y),
            "forward": MOVE_DRIVE * max(0.0, z), "back": MOVE_DRIVE * max(0.0, -z)}


class BrainMap:
    def __init__(self, kind: str = "true", seed: int = 0) -> None:
        self.model = RateModel(kind, seed)
        neurons = pd.read_parquet(DATA / "neurons.parquet", columns=["type", "class", "superclass", "somaSide", "dimorphism", "nt", "sign"])
        self.regions = region_indices(neurons)
        nt, sign = neurons["nt"].fillna("").to_numpy(), neurons["sign"].to_numpy()
        self._gaba = nt == "gaba"
        self._excite = sign > 0
        self.drinks = 0
        self._tables: dict[tuple[str, int], list[dict[str, float]]] = {}
        self._calibrate()

    @property
    def kind(self) -> str:
        return self.model.kind

    def _scale(self, drinks: int) -> np.ndarray | None:
        if drinks <= 0:
            return None
        s = np.ones(self.model.n, dtype=np.float32)
        s[self._gaba] *= 1.0 + GABA_PER_DRINK * drinks
        s[self._excite] *= max(0.0, 1.0 - EXCITE_PER_DRINK * drinks)
        return s

    def _means(self) -> np.ndarray:
        r = self.model.r
        return np.array([r[self.regions[k]].mean() if len(self.regions[k]) else 0.0 for k in REGION_KEYS])

    def _calibrate(self) -> None:
        """Sober resting mean per region (the map's zero), then carry on from rest at the current drinks."""
        m = self.model
        m.pre_scale = None
        m.reset()
        acc = np.zeros(len(REGION_KEYS))
        for _ in range(50):
            m.step({})
            acc += self._means()
        self.base = acc / 50
        self._shown = np.zeros(len(REGION_KEYS))
        m.pre_scale = self._scale(self.drinks)

    def set_drinks(self, drinks: int) -> None:
        drinks = max(0, min(MAX_DRINKS, int(drinks)))
        if drinks != self.drinks:
            self.drinks = drinks
            self.model.pre_scale = self._scale(drinks)

    def swap(self, kind: str, seed: int = 0) -> None:
        """Follow the True Prince / Changeling toggle (the map then shows the scrambled wiring's response)."""
        self.model.pre_scale = None
        self.model.load(kind, seed)
        self._calibrate()

    def step(self, motion: dict[str, float]) -> None:
        self.model.step(motion_drives(motion))
        now = np.log2((self._means() + EPS) / (self.base + EPS))
        self._shown += SMOOTH * (now - self._shown)

    def view(self) -> dict:
        return {"regions": {k: round(float(v), 2) for k, v in zip(REGION_KEYS, self._shown)},
                "drinks": self.drinks, "kind": self.kind, "neurons": int(self.model.n),
                "gabaPct": round(100 * GABA_PER_DRINK), "excitePct": round(100 * EXCITE_PER_DRINK)}

    def drink_table(self) -> list[dict[str, float]]:
        """Steady-state mean rate per region in forward flight at 0..MAX_DRINKS drinks (computed once per wiring; takes about
        2 s, so call it off the game loop). The live state is saved and restored around it."""
        key = (self.model.kind, self.model.seed)
        if key not in self._tables:
            m = self.model
            saved_r, saved_scale = m.r.copy(), m.pre_scale
            rows = []
            for d in range(MAX_DRINKS + 1):
                m.pre_scale = self._scale(d)
                m.reset()
                acc = np.zeros(len(REGION_KEYS))
                for k in range(TABLE_TICKS):
                    m.step(motion_drives({"z": 0.75}))
                    if k >= TABLE_TICKS - TABLE_AVG:
                        acc += self._means()
                rows.append({kk: float(v) for kk, v in zip(REGION_KEYS, acc / TABLE_AVG)})
            m.r, m.pre_scale = saved_r, saved_scale
            self._tables[key] = rows
        return self._tables[key]

    def compare(self, before: int, after: int) -> dict:
        """The quiz comparison: every region at `before` and `after` drinks (log2 vs sober rest, like the live map) and the
        percent change in mean rate between them. All computed by the model; nothing here is hand-set."""
        table = self.drink_table()
        b, a = table[max(0, min(MAX_DRINKS, before))], table[max(0, min(MAX_DRINKS, after))]
        base = dict(zip(REGION_KEYS, self.base))
        log = lambda row: {k: round(float(np.log2((row[k] + EPS) / (base[k] + EPS))), 2) for k in REGION_KEYS}
        pct = {k: round(100.0 * (a[k] / b[k] - 1.0)) if b[k] > 1e-6 else 0 for k in REGION_KEYS}
        return {"before": before, "after": after, "from": log(b), "to": log(a), "pct": pct}


if __name__ == "__main__":
    import time

    bm = BrainMap("true")
    t0 = time.time()
    for _ in range(50):
        bm.step({"z": 0.8, "x": -0.5})
    print(f"{(time.time() - t0) / 50 * 1000:.1f} ms per step", bm.view())
    t0 = time.time()
    c = bm.compare(0, 1)
    print(f"drink table in {time.time() - t0:.1f} s")
    for d in range(MAX_DRINKS):
        print(f"{d} -> {d + 1} drinks:", bm.compare(d, d + 1)["pct"])
