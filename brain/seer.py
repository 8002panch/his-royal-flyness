"""The Royal Seer's senses: the `seer_adapter` (owner: Neil).

The Prince's real wiring turns what he sees and feels into the Seer's cues. Every tick the server passes **world stimuli** (where the
Princess and the Giants are relative to the Prince); the adapter drives the matching sensory neurons, steps the brain, and reads
**side-selective descending neurons** back out as coarse cues for the Seer's phone and the HUD.

    from brain.seer import SeerAdapter
    seer = SeerAdapter(source="true")          # "true" | "changeling" | "placeholder"; mode="neural" (default) or "hybrid"
    cues = seer.sense(stimuli)                 # every 20 ms tick
    seer.swap("changeling", seed=0)            # the Changeling toggle (also: "true", "placeholder")
    view = to_seer_view(cues)                  # Ved's relay format: {"t": "seer_view", "bearing": "NE", "distance": "FAR", ...}

Formats (docs/TECH.md, "The Royal Seer"):

    stimuli = {"princess": {"bearing_deg": -35, "elevation_deg": 10, "distance_cm": 420} | None,
               "giants": [{"bearing_deg": 80, "elevation_deg": 30, "distance_cm": 150, "approach_cm_s": 300, "size_cm": 40}],
               "wind": {"bearing_deg": 80, "strength": 0.6} | None}
    bearing: 0 = straight ahead, negative = left, positive = right (degrees). approach_cm_s > 0 = getting closer.

    cues = {"princess": {"side": "left"|"ahead"|"right", "bearing_deg": float, "confidence": 0-1, "distance": "near"|"mid"|"far"} | None,
            "giant": {"warning": 0-1, "side": "left"|"right"|"ahead"|None, "eta_s": float | None},
            "activity": {"vision", "looming", "escape": z-scores for the main-screen HUD; side-free on purpose},
            "source": "true"|"changeling"|"placeholder", "mode": "neural"|"hybrid"|"placeholder"}

Modes:
  neural      side, bearing, confidence and warning all come from the brain's readouts (the honest default).
  hybrid      the disclosed fallback: side and bearing come from the server's true geometry; confidence, warning strength and
              timing come from the brain. Say so on the Royal Decree if it's used.
  placeholder no brain; deterministic cues straight from the stimuli (Ved's default; also the safe fallback on any error).

The readout is fixed, not trained: left-vs-right population balance for the side, total response for confidence and warning.
The Changeling is read out the same way, so its cues degrade. Bearing is **coarse on purpose**: each eye's Princess detectors are
driven as one group, so beyond the narrow zone straight ahead the wiring only says "left" or "right" (the balance is all-or-nothing;
measured Sat 17:15). `bearing_deg` is therefore the sector center: -60 (left), 0 (ahead), +60 (right).
Calibrate the time-to-impact table: python -m brain.seer --calibrate. Evaluate True vs Changeling: python -m brain.seer --evaluate.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path
from typing import Any

import numpy as np


CALIBRATION = Path(__file__).resolve().parent / "seer_calibration.json"


def _load_eta_table() -> dict | None:
    """Warning level -> seconds to impact, measured on the True Prince (python -m brain.seer --calibrate)."""
    if CALIBRATION.exists():
        return json.loads(CALIBRATION.read_text())
    return None


# --- encoding: world -> sensory drives (all our assumptions; documented on the Royal Decree) ----------------------------------
PRINCESS_FULL_CM = 150.0    # the Princess fully drives the Princess detectors at this distance or closer (tune to the course
                            # scale: she's detected out to roughly 7x this distance). SeerAdapter(princess_full_cm=...) overrides it.
BINOCULAR_DEG = 10.0        # each eye sees its own side plus this far across the midline: both eyes see anything within +/-10 degrees
EYE_EDGE_DEG = 2.0          # softness of each eye's field edge (degrees)
BLIND_BEHIND_DEG = 165.0    # nothing is seen within 15 degrees of straight behind
LOOM_REF_DEG_S = 2.0        # looming drive is logarithmic in expansion speed: log(1 + v/ref) / log(1 + full/ref)
LOOM_FULL_DEG_S = 300.0     # expansion speed (degrees per second) that fully drives the looming detectors


def _step(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))


def eye_weights(bearing_deg: float) -> tuple[float, float]:
    """(left eye, right eye) visibility of a point at this bearing. Each eye sees its own side plus a binocular strip across the
    midline, so something within +/-BINOCULAR_DEG is seen fully by both eyes (1, 1); far left is (1, 0), far right (0, 1)."""
    left = _step((BINOCULAR_DEG - bearing_deg) / EYE_EDGE_DEG)
    right = _step((bearing_deg + BINOCULAR_DEG) / EYE_EDGE_DEG)
    return left, right


def side_weights(bearing_deg: float, width: float = 40.0) -> tuple[float, float]:
    """Smooth (left, right) split for the antennae's wind sense: 1/0 far left, 0/1 far right, 0.5/0.5 straight ahead."""
    right = _step(bearing_deg / (width / 4.0))
    return 1.0 - right, right


def angular_size_deg(size_cm: float, distance_cm: float) -> float:
    return math.degrees(2.0 * math.atan2(size_cm / 2.0, max(distance_cm, 1e-3)))


def looming_rate_deg_s(size_cm: float, distance_cm: float, approach_cm_s: float) -> float:
    """How fast the object's angular size grows: d(theta)/dt = size * v / (d^2 + size^2 / 4), in degrees per second."""
    if approach_cm_s <= 0:
        return 0.0
    return math.degrees(size_cm * approach_cm_s / (distance_cm ** 2 + size_cm ** 2 / 4.0))


def encode(stimuli: dict[str, Any], princess_full_cm: float = PRINCESS_FULL_CM) -> dict[str, float]:
    drives = {"her_L": 0.0, "her_R": 0.0, "loom_L": 0.0, "loom_R": 0.0, "wind_L": 0.0, "wind_R": 0.0}
    p = stimuli.get("princess")
    if p and abs(p["bearing_deg"]) < BLIND_BEHIND_DEG:
        strength = min(1.0, princess_full_cm / max(p["distance_cm"], 1.0))
        wl, wr = eye_weights(p["bearing_deg"])
        drives["her_L"], drives["her_R"] = strength * wl, strength * wr
    for g in stimuli.get("giants") or []:
        if abs(g["bearing_deg"]) >= BLIND_BEHIND_DEG:
            continue
        rate = looming_rate_deg_s(g.get("size_cm", 40.0), g["distance_cm"], g.get("approach_cm_s", 0.0))
        strength = min(1.0, math.log1p(rate / LOOM_REF_DEG_S) / math.log1p(LOOM_FULL_DEG_S / LOOM_REF_DEG_S))
        wl, wr = eye_weights(g["bearing_deg"])
        drives["loom_L"] = max(drives["loom_L"], strength * wl)
        drives["loom_R"] = max(drives["loom_R"], strength * wr)
    w = stimuli.get("wind")
    if w and w.get("strength", 0) > 0:
        wl, wr = side_weights(w["bearing_deg"], width=40.0)
        drives["wind_L"], drives["wind_R"] = w["strength"] * wl, w["strength"] * wr
    return drives


# --- decoding: brain readouts -> cues --------------------------------------------------------------------------------------------
HER_DETECT_Z = 1.5      # total Princess readout needed to report her at all
HER_FULL_Z = 12.0       # total readout that counts as full confidence
AHEAD_BALANCE = 0.25    # |R - L| / (R + L) below this = "ahead"
LOOM_WARN_Z = 3.0       # looming readout where a warning starts
LOOM_FULL_Z = 60.0      # looming readout that counts as a full warning
WIND_FULL_Z = 15.0
SECTOR_DEG = {"left": -60.0, "ahead": 0.0, "right": 60.0}


def decode(out: dict[str, float], state: dict, eta_table: dict | None = None) -> dict:
    hl, hr = max(out["seer_her_L"], 0.0), max(out["seer_her_R"], 0.0)
    ll, lr = max(out["seer_loom_L"], 0.0), max(out["seer_loom_R"], 0.0)
    wl, wr = max(out["seer_wind_L"], 0.0), max(out["seer_wind_R"], 0.0)

    princess = None
    total = hl + hr
    if total >= HER_DETECT_Z:
        balance = (hr - hl) / total
        side = "ahead" if abs(balance) < AHEAD_BALANCE else ("right" if balance > 0 else "left")
        bearing = SECTOR_DEG[side]
        confidence = float(min(1.0, (total - HER_DETECT_Z) / (HER_FULL_Z - HER_DETECT_Z)))
        distance = "near" if confidence > 0.66 else ("mid" if confidence > 0.25 else "far")
        princess = {"side": side, "bearing_deg": round(bearing, 1), "confidence": round(confidence, 2), "distance": distance}

    loom = max(ll, lr)
    loom_warning = min(1.0, max(0.0, loom - LOOM_WARN_Z) / (LOOM_FULL_Z - LOOM_WARN_Z))
    warning = max(loom_warning, 0.5 * min(1.0, max(wl, wr) / WIND_FULL_Z))
    gside = None
    if warning > 0.05:
        a, b = (ll, lr) if loom >= LOOM_WARN_Z else (wl, wr)
        gside = "ahead" if abs(b - a) < 0.25 * max(a + b, 1e-6) else ("right" if b > a else "left")
    # seconds to impact: looked up from the looming warning level (table measured on the True Prince; wind alone gives no estimate)
    eta = None
    if eta_table is not None and loom_warning >= eta_table["warning"][0]:
        eta = round(float(np.interp(loom_warning, eta_table["warning"], eta_table["seconds"])), 2)
    return {
        "princess": princess,
        "giant": {"warning": round(warning, 2), "side": gside, "eta_s": eta},
        # For the shared main-screen HUD, so no left/right (or both-eyes "ahead") signal: that would give away the Seer's secret.
        "activity": {"vision": round(max(hl, hr), 1), "looming": round(loom, 1), "escape": round(out["DNp01"], 1)},
    }


def placeholder(stimuli: dict[str, Any], princess_full_cm: float = PRINCESS_FULL_CM) -> dict:
    """No brain: cues straight from the geometry (deterministic). Also the fallback if the brain ever fails."""
    p = stimuli.get("princess")
    princess = None
    if p and abs(p["bearing_deg"]) < BLIND_BEHIND_DEG:
        conf = min(1.0, princess_full_cm / max(p["distance_cm"], 1.0))
        b = p["bearing_deg"]
        princess = {"side": "ahead" if abs(b) < 10 else ("right" if b > 0 else "left"), "bearing_deg": round(b, 1),
                    "confidence": round(conf, 2), "distance": "near" if conf > 0.66 else ("mid" if conf > 0.25 else "far")}
    warning, gside, eta = 0.0, None, None
    for g in stimuli.get("giants") or []:
        v = g.get("approach_cm_s", 0.0)
        if v > 0:
            t = g["distance_cm"] / v
            w = max(0.0, min(1.0, 1.0 - t / 2.0))
            if w > warning:
                warning, eta = w, round(t, 2)
                gside = "ahead" if abs(g["bearing_deg"]) < 15 else ("right" if g["bearing_deg"] > 0 else "left")
    return {"princess": princess, "giant": {"warning": round(warning, 2), "side": gside, "eta_s": eta},
            "activity": {"vision": 0.0, "looming": 0.0, "escape": 0.0}}


COMPASS = {"left": "NW", "ahead": "N", "right": "NE"}  # relative to the Prince's heading (N = straight ahead)


def to_seer_view(cues: dict) -> dict:
    """Convert cues to Ved's relay `seer_view` message (docs/TECH.md, "Protocol")."""
    p, g = cues.get("princess"), cues["giant"]
    return {
        "t": "seer_view",
        "bearing": COMPASS[p["side"]] if p else None,
        "distance": p["distance"].upper() if p else None,
        "confidence": p["confidence"] if p else 0.0,
        "giant": {"direction": g["side"].upper() if g["side"] else None, "seconds": g["eta_s"], "confidence": g["warning"]},
        "source": cues["source"],
    }


class SeerAdapter:
    """One interface for the placeholder, the True Prince and the Changeling."""

    TICK_S = 0.020
    MAX_CATCHUP_STEPS = 10  # after a long gap (e.g. the Seer wasn't scanning), settle on the current scene in at most 200 ms

    def __init__(self, source: str = "true", seed: int = 0, mode: str = "neural", princess_full_cm: float = PRINCESS_FULL_CM,
                 brain: Any = None, realtime: bool = True) -> None:
        """`brain`: pass an existing brain.brain.Brain to share it with button-driven movement (one brain step per tick for both).
        Its kind/seed win over `source`/`seed`.
        `realtime`: each `sense()` call advances the brain by the wall-clock time since the previous call (in 20 ms steps, at least
        one, at most MAX_CATCHUP_STEPS), so the senses stay in real time whether the server calls every tick or only while the
        Seer scans. `realtime=False` = exactly one step per call (tests, evaluation). An explicit `dt=` always wins."""
        if mode not in ("neural", "hybrid"):
            raise ValueError("mode must be 'neural' or 'hybrid'")
        self.mode = mode
        self.princess_full_cm = princess_full_cm
        self._eta_table = _load_eta_table()
        self._brain = brain
        self.realtime = realtime
        self.last_outputs: dict[str, float] | None = None
        self._last_call: float | None = None
        self._time_debt = 0.0
        self._last_cues: dict | None = None
        if brain is not None:
            source, seed = brain.kind, brain.seed
        self.swap(source, seed)

    def swap(self, source: str, seed: int = 0) -> None:
        if source not in ("true", "changeling", "placeholder"):
            raise ValueError("source must be 'true', 'changeling' or 'placeholder'")
        self.source, self.seed = source, seed
        if source == "placeholder":
            self._brain = None
        else:
            from brain.brain import Brain

            if self._brain is None:
                self._brain = Brain(source, seed)
            else:
                self._brain.swap(source, seed)
        self.reset()

    def reset(self) -> None:
        self._state: dict = {}
        self._last_call = None
        self._time_debt = 0.0
        self._last_cues = None
        if self._brain is not None:
            self._brain.reset()

    def _steps_for(self, dt: float | None) -> int:
        """How many 20 ms brain steps this call should take. Time is accumulated, so calling sense() several times within one
        tick (e.g. once for Godot, once for the phones) never runs the brain faster than real time: extra calls take 0 steps
        and return the latest cues."""
        now = time.perf_counter()
        if dt is None and not self.realtime:
            self._last_call = now
            return 1
        if dt is None:
            dt = self.TICK_S if self._last_call is None else now - self._last_call
        self._last_call = now
        self._time_debt += max(0.0, dt)
        steps = int(self._time_debt / self.TICK_S + 1e-9)
        if steps > self.MAX_CATCHUP_STEPS:  # after a long gap, settle on the current scene and drop the rest of the debt
            steps, self._time_debt = self.MAX_CATCHUP_STEPS, 0.0
        else:
            self._time_debt -= steps * self.TICK_S
        if self._last_cues is None:  # the very first call always senses
            steps = max(steps, 1)
        return steps

    def to_phone_view(self, cues: dict) -> dict:
        """The relay's `seer_view` message (same method name as server/seer_adapter.PlaceholderSeerAdapter)."""
        return to_seer_view(cues)

    def sense(self, stimuli: dict[str, Any], extra_drives: dict[str, float] | None = None, dt: float | None = None) -> dict:
        """Advance the senses (see `realtime`) and return cues. `extra_drives` (e.g. button drives) go into the same brain steps;
        the last step's full outputs land in `self.last_outputs`."""
        steps = self._steps_for(dt)
        if self._brain is None:
            self.last_outputs = None
            cues = {**placeholder(stimuli, self.princess_full_cm), "source": "placeholder", "mode": "placeholder"}
            self._last_cues = cues
            return cues
        if steps == 0 and self._last_cues is not None:
            return self._last_cues
        try:
            drives = encode(stimuli, self.princess_full_cm)
            for g, v in (extra_drives or {}).items():
                drives[g] = min(1.0, drives.get(g, 0.0) + float(v))
            for _ in range(steps):
                out = self._brain.step(drives)
            self.last_outputs = out
            self._state["last_warning"] = self._state.get("last_warning", 0.0)
            cues = decode(out, self._state, self._eta_table)
        except Exception:  # never let the brain break the game: fall back to the placeholder for this tick
            return {**placeholder(stimuli, self.princess_full_cm), "source": "placeholder", "mode": "placeholder", "error": True}
        if self.mode == "hybrid":
            truth = placeholder(stimuli, self.princess_full_cm)
            if cues["princess"] is not None and truth["princess"] is not None:
                cues["princess"]["side"] = truth["princess"]["side"]
                cues["princess"]["bearing_deg"] = truth["princess"]["bearing_deg"]
            if cues["giant"]["warning"] > 0.05:
                cues["giant"]["side"] = truth["giant"]["side"]
        cues = {**cues, "source": self.source, "mode": self.mode}
        self._last_cues = cues
        return cues


# --- calibration and evaluation ------------------------------------------------------------------------------------------------
def _settle(adapter: SeerAdapter, stimuli: dict, ticks: int = 25) -> dict:
    adapter.reset()
    cues = None
    for _ in range(ticks):
        cues = adapter.sense(stimuli)
    return cues


def _approach(adapter: SeerAdapter, bearing: float, d0: float, v: float, size: float):
    """Fly one Giant straight at the Prince until impact; yields (cues, true seconds left) every tick."""
    adapter.reset()
    t_imp = (d0 - size) / v
    for t in range(int(t_imp / 0.02)):
        d = d0 - v * 0.02 * t
        cues = adapter.sense({"giants": [{"bearing_deg": bearing, "elevation_deg": 20.0, "distance_cm": d,
                                          "approach_cm_s": v, "size_cm": size}]})
        yield cues, t_imp - t * 0.02


def _random_giants(rng, n):
    return [(float(rng.choice([-1, 1]) * rng.uniform(20, 150)), float(rng.uniform(150, 700)), float(rng.uniform(150, 500)),
             float(rng.uniform(25, 60))) for _ in range(n)]


def calibrate(n: int = 80, seed: int = 11) -> None:
    """Measure warning level vs true seconds to impact on the True Prince; save a monotonic lookup table."""
    seer = SeerAdapter("true", realtime=False)
    seer._eta_table = None
    pairs = []
    for case in _random_giants(np.random.default_rng(seed), n):
        for cues, left in _approach(seer, *case):
            a = cues["activity"]["looming"]
            w = min(1.0, max(0.0, a - LOOM_WARN_Z) / (LOOM_FULL_Z - LOOM_WARN_Z))
            if 0.02 <= w and left <= 3.0:
                pairs.append((w, left))
    w, left = np.array(pairs).T
    edges = np.linspace(0.02, 1.0, 26)
    idx = np.clip(np.digitize(w, edges) - 1, 0, len(edges) - 2)
    centers, secs = [], []
    for i in range(len(edges) - 1):
        m = idx == i
        if m.sum() >= 20:
            centers.append(float(w[m].mean()))
            secs.append(float(np.median(left[m])))
    secs = np.minimum.accumulate(np.array(secs))  # more warning never means more time left
    table = {"warning": [round(c, 4) for c in centers], "seconds": [round(float(x), 3) for x in secs],
             "note": f"Looming warning level vs median seconds to impact, True Prince, {n} random approaches (python -m brain.seer --calibrate)"}
    CALIBRATION.write_text(json.dumps(table, indent=1))
    print(f"wrote {CALIBRATION.name}: {len(centers)} points from {len(pairs)} samples; warning {centers[0]:.2f}-{centers[-1]:.2f} -> {secs[0]:.2f}-{secs[-1]:.2f} s")


def evaluate(n: int = 60, seed: int = 7, out_csv: str | None = None) -> None:
    """True Prince vs Changelings on fresh random scenes (not the calibration scenes)."""
    import pandas as pd

    rng = np.random.default_rng(seed)
    princess_cases = [(float(rng.uniform(-150, 150)), float(rng.uniform(40, 800))) for _ in range(n)]
    giant_cases = _random_giants(rng, n)
    rows = []
    for source, s in (("true", 0), ("changeling", 0), ("changeling", 1), ("changeling", 2), ("placeholder", 0)):
        adapter = SeerAdapter(source, s, realtime=False)
        t0, ticks = time.time(), 0
        side_ok, err, detect, lat = 0, [], 0, []
        for bearing, dist in princess_cases:
            truth = "ahead" if abs(bearing) < BINOCULAR_DEG else ("right" if bearing > 0 else "left")
            adapter.reset()
            first, cues = None, None
            for t in range(40):
                cues = adapter.sense({"princess": {"bearing_deg": bearing, "elevation_deg": 0.0, "distance_cm": dist}})
                ticks += 1
                pc = cues["princess"]
                if first is None and pc is not None and pc["side"] == truth:
                    first = t
            pc = cues["princess"]
            if pc is not None:
                detect += 1
                side_ok += pc["side"] == truth
                err.append(abs(pc["bearing_deg"] - bearing))
            if first is not None:
                lat.append(first * 20)
        g_side, leads, eta_err, warned = 0, [], [], 0
        for case in giant_cases:
            t_warn, last = None, None
            for cues, left in _approach(adapter, *case):
                ticks += 1
                last = cues
                if t_warn is None and cues["giant"]["warning"] >= 0.3:
                    t_warn = left
                if cues["giant"]["eta_s"] is not None and 0.3 <= left <= 2.0:
                    eta_err.append(abs(cues["giant"]["eta_s"] - left))
            if t_warn is not None:
                warned += 1
                leads.append(t_warn)
            g_side += last is not None and last["giant"]["side"] == ("right" if case[0] > 0 else "left")
        rows.append({
            "brain": source if source != "changeling" else f"changeling {s}",
            "princess detected": f"{detect}/{n}",
            "princess side correct": f"{side_ok}/{n}",
            "princess cue delay (ms)": round(float(np.median(lat)), 0) if lat else None,
            "giant warned before impact": f"{warned}/{n}",
            "warning lead time (s)": round(float(np.median(leads)), 2) if leads else None,
            "giant side correct": f"{g_side}/{n}",
            "time-to-impact error (s)": round(float(np.median(eta_err)), 2) if eta_err else None,
            "ms per tick": round((time.time() - t0) / max(ticks, 1) * 1000, 1),
        })
    df = pd.DataFrame(rows)
    pd.set_option("display.width", 240)
    print(df.to_string(index=False))
    if out_csv:
        df.to_csv(out_csv, index=False)
        print(f"wrote {out_csv}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--calibrate", action="store_true")
    ap.add_argument("--evaluate", action="store_true")
    ap.add_argument("--n", type=int, default=60)
    ap.add_argument("--csv", default="")
    args = ap.parse_args()
    if args.calibrate:
        calibrate()
    if args.evaluate:
        evaluate(args.n, out_csv=args.csv or None)
    if not (args.calibrate or args.evaluate):
        s = SeerAdapter("true")
        for _ in range(25):
            c = s.sense({"princess": {"bearing_deg": -40, "elevation_deg": 0, "distance_cm": 120},
                         "giants": [{"bearing_deg": 70, "elevation_deg": 20, "distance_cm": 120, "approach_cm_s": 400, "size_cm": 40}]})
        print(json.dumps(c, indent=1))
