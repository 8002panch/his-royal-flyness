"""The Royal Seer's senses: the `seer_adapter` (owner: Neil).

The Prince's real wiring turns what he sees and feels into the Seer's cues. Every tick the server passes **world stimuli** (where the
Princess and the Giants are relative to the Prince); the adapter drives the matching sensory neurons, steps the brain, and reads
**side-selective descending neurons** back out as coarse cues for the Seer's phone and the HUD.

    from brain.seer import SeerAdapter
    seer = SeerAdapter(source="true")          # "true" | "changeling" | "placeholder"; mode="neural" (default) or "hybrid"
    cues = seer.sense(stimuli)                 # every 20 ms tick
    seer.swap("changeling", seed=0)            # the Changeling toggle (also: "true", "placeholder")

Formats (team/README.md, "Open requests"):

    stimuli = {"princess": {"bearing_deg": -35, "elevation_deg": 10, "distance_cm": 420} | None,
               "giants": [{"bearing_deg": 80, "elevation_deg": 30, "distance_cm": 150, "approach_cm_s": 300, "size_cm": 40}],
               "wind": {"bearing_deg": 80, "strength": 0.6} | None}
    bearing: 0 = straight ahead, negative = left, positive = right (degrees). approach_cm_s > 0 = getting closer.

    cues = {"princess": {"side": "left"|"ahead"|"right", "bearing_deg": float, "confidence": 0-1, "distance": "near"|"mid"|"far"} | None,
            "giant": {"warning": 0-1, "side": "left"|"right"|"ahead"|None, "eta_s": float | None},
            "activity": {"her_L", "her_R", "looming", "escape", "steer", "song": z-scores for the HUD},
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
Evaluate True vs Changeling: python -m brain.seer --evaluate.
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path
from typing import Any

import numpy as np


# --- encoding: world -> sensory drives (all our assumptions; documented on the Royal Decree) ----------------------------------
PRINCESS_FULL_CM = 150.0    # the Princess fully drives the Princess detectors at this distance or closer (tune to the course
                            # scale: she's detected out to roughly 7x this distance). SeerAdapter(princess_full_cm=...) overrides it.
EYE_OVERLAP_DEG = 12.0      # width of the soft left/right handover straight ahead (both eyes see her there)
BLIND_BEHIND_DEG = 165.0    # nothing is seen within 15 degrees of straight behind
LOOM_FULL_DEG_S = 300.0     # a looming object growing this fast (degrees per second) fully drives the looming detectors


def side_weights(bearing_deg: float, width: float = EYE_OVERLAP_DEG) -> tuple[float, float]:
    """(left, right) weights for something at this bearing: 1/0 far left, 0/1 far right, about 0.5/0.5 straight ahead."""
    right = 1.0 / (1.0 + math.exp(-bearing_deg / (width / 4.0)))
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
        wl, wr = side_weights(p["bearing_deg"])
        drives["her_L"], drives["her_R"] = strength * wl, strength * wr
    for g in stimuli.get("giants") or []:
        if abs(g["bearing_deg"]) >= BLIND_BEHIND_DEG:
            continue
        rate = looming_rate_deg_s(g.get("size_cm", 40.0), g["distance_cm"], g.get("approach_cm_s", 0.0))
        strength = min(1.0, rate / LOOM_FULL_DEG_S)
        wl, wr = side_weights(g["bearing_deg"], width=30.0)
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


def decode(out: dict[str, float], state: dict) -> dict:
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
    warning = max(min(1.0, max(0.0, loom - LOOM_WARN_Z) / (LOOM_FULL_Z - LOOM_WARN_Z)), 0.5 * min(1.0, max(wl, wr) / WIND_FULL_Z))
    gside = None
    if warning > 0.05:
        a, b = (ll, lr) if loom >= LOOM_WARN_Z else (wl, wr)
        gside = "ahead" if abs(b - a) < 0.25 * max(a + b, 1e-6) else ("right" if b > a else "left")
    # time to impact from how fast the warning is rising (the brain's own estimate; None if it isn't rising)
    rise = (warning - state.get("last_warning", 0.0)) / 0.02
    state["last_warning"] = warning
    eta = round(max(0.0, (1.0 - warning) / rise), 2) if rise > 0.05 and warning > 0.05 else None
    return {
        "princess": princess,
        "giant": {"warning": round(warning, 2), "side": gside, "eta_s": eta},
        "activity": {"her_L": round(out["seer_her_L"], 1), "her_R": round(out["seer_her_R"], 1), "looming": round(loom, 1),
                     "escape": round(out["DNp01"], 1), "steer": round(out["DNa02_R"] - out["DNa02_L"], 1),
                     "song": round(out["pIP10"], 1)},
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
            "activity": {"her_L": 0.0, "her_R": 0.0, "looming": 0.0, "escape": 0.0, "steer": 0.0, "song": 0.0}}


class SeerAdapter:
    """One interface for the placeholder, the True Prince and the Changeling."""

    def __init__(self, source: str = "true", seed: int = 0, mode: str = "neural", princess_full_cm: float = PRINCESS_FULL_CM) -> None:
        if mode not in ("neural", "hybrid"):
            raise ValueError("mode must be 'neural' or 'hybrid'")
        self.mode = mode
        self.princess_full_cm = princess_full_cm
        self._brain = None
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
        if self._brain is not None:
            self._brain.reset()

    def sense(self, stimuli: dict[str, Any]) -> dict:
        if self._brain is None:
            return {**placeholder(stimuli, self.princess_full_cm), "source": "placeholder", "mode": "placeholder"}
        try:
            out = self._brain.step(encode(stimuli, self.princess_full_cm))
            cues = decode(out, self._state)
        except Exception:  # never let the brain break the game: fall back to the placeholder for this tick
            return {**placeholder(stimuli, self.princess_full_cm), "source": "placeholder", "mode": "placeholder", "error": True}
        if self.mode == "hybrid":
            truth = placeholder(stimuli, self.princess_full_cm)
            if cues["princess"] is not None and truth["princess"] is not None:
                cues["princess"]["side"] = truth["princess"]["side"]
                cues["princess"]["bearing_deg"] = truth["princess"]["bearing_deg"]
            if cues["giant"]["warning"] > 0.05:
                cues["giant"]["side"] = truth["giant"]["side"]
        return {**cues, "source": self.source, "mode": self.mode}


# --- calibration and evaluation ------------------------------------------------------------------------------------------------
def _settle(adapter: SeerAdapter, stimuli: dict, ticks: int = 25) -> dict:
    adapter.reset()
    cues = None
    for _ in range(ticks):
        cues = adapter.sense(stimuli)
    return cues


def evaluate(n: int = 60, seed: int = 7, out_csv: str | None = None) -> None:
    """True Prince vs Changelings: how often the Seer gets the side right, bearing error, and how fast cues appear."""
    import pandas as pd

    rng = np.random.default_rng(seed)
    princess_cases = [(float(rng.uniform(-150, 150)), float(rng.uniform(40, 800))) for _ in range(n)]
    giant_cases = [(float(rng.choice([-1, 1]) * rng.uniform(20, 150)), float(rng.uniform(150, 400)), float(rng.uniform(200, 500))) for _ in range(n)]
    rows = []
    for source, s in (("true", 0), ("changeling", 0), ("changeling", 1), ("changeling", 2), ("placeholder", 0)):
        adapter = SeerAdapter(source, s)
        t0 = time.time()
        side_ok, err, detect, lat = 0, [], 0, []
        for bearing, dist in princess_cases:
            truth = "ahead" if abs(bearing) < 10 else ("right" if bearing > 0 else "left")
            adapter.reset()
            first = None
            cues = None
            for t in range(40):
                cues = adapter.sense({"princess": {"bearing_deg": bearing, "elevation_deg": 0.0, "distance_cm": dist}})
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
        g_ok, g_lat, g_warn = 0, [], []
        for bearing, dist, speed in giant_cases:
            adapter.reset()
            first = None
            cues = None
            for t in range(40):
                d = max(5.0, dist - speed * 0.02 * t)
                cues = adapter.sense({"giants": [{"bearing_deg": bearing, "elevation_deg": 20.0, "distance_cm": d,
                                                  "approach_cm_s": speed, "size_cm": 40.0}]})
                if first is None and cues["giant"]["warning"] >= 0.3:
                    first = t
            truth = "right" if bearing > 0 else "left"
            g_ok += cues["giant"]["side"] == truth
            g_warn.append(cues["giant"]["warning"])
            if first is not None:
                g_lat.append(first * 20)
        rows.append({
            "brain": source if source != "changeling" else f"changeling {s}",
            "princess side correct": f"{side_ok}/{n}",
            "princess detected": f"{detect}/{n}",
            "median bearing error (deg)": round(float(np.median(err)), 1) if err else None,
            "princess cue delay (ms)": round(float(np.median(lat)), 0) if lat else None,
            "giant side correct": f"{g_ok}/{n}",
            "giant warned (warning >= 0.3)": f"{len(g_lat)}/{n}",
            "giant warning delay (ms)": round(float(np.median(g_lat)), 0) if g_lat else None,
            "ms per tick": round((time.time() - t0) / (n * 80) * 1000, 1),
        })
    df = pd.DataFrame(rows)
    pd.set_option("display.width", 220)
    print(df.to_string(index=False))
    if out_csv:
        df.to_csv(out_csv, index=False)
        print(f"wrote {out_csv}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--evaluate", action="store_true")
    ap.add_argument("--n", type=int, default=60)
    ap.add_argument("--csv", default="")
    args = ap.parse_args()
    if args.evaluate:
        evaluate(args.n, out_csv=args.csv or None)
    if not args.evaluate:
        s = SeerAdapter("true")
        for _ in range(25):
            c = s.sense({"princess": {"bearing_deg": -40, "elevation_deg": 0, "distance_cm": 120},
                         "giants": [{"bearing_deg": 70, "elevation_deg": 20, "distance_cm": 120, "approach_cm_s": 400, "size_cm": 40}]})
        print(json.dumps(c, indent=1))
