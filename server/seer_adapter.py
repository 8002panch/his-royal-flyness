"""Deterministic placeholder Seer adapter for Phase 3.

This is deliberately independent of movement. Phase 6 can replace it with Neil's
brain-backed adapter behind the same ``sense`` and ``to_phone_view`` methods.
"""

from __future__ import annotations

import math
from typing import Any


class PlaceholderSeerAdapter:
    source = "placeholder"

    def sense(self, stimuli: dict[str, Any]) -> dict[str, Any]:
        princess = stimuli.get("princess")
        giant = next(iter(stimuli.get("giants") or []), None)
        princess_cue = None
        if princess:
            bearing = float(princess["bearing_deg"])
            distance_cm = float(princess["distance_cm"])
            side = "ahead" if abs(bearing) < 12 else ("right" if bearing > 0 else "left")
            confidence = round(max(0.0, min(1.0, 180.0 / max(distance_cm, 1.0))), 2)
            distance = "near" if distance_cm < 80 else ("mid" if distance_cm < 180 else "far")
            princess_cue = {"side": side, "distance": distance, "confidence": confidence}
        giant_cue = {"side": None, "seconds": None, "confidence": 0.0}
        if giant and float(giant.get("approach_cm_s", 0.0)) > 0:
            bearing = float(giant["bearing_deg"])
            side = "ahead" if abs(bearing) < 15 else ("right" if bearing > 0 else "left")
            eta = max(0.0, float(giant["distance_cm"]) / float(giant["approach_cm_s"]))
            giant_cue = {"side": side, "seconds": round(eta, 1), "confidence": round(max(0.0, min(1.0, 1.0 - eta / 2.5)), 2)}
        return {"princess": princess_cue, "giant": giant_cue, "source": self.source}

    def to_phone_view(self, cues: dict[str, Any]) -> dict[str, Any]:
        princess = cues["princess"]
        giant = cues["giant"]
        compass = {"left": "NW", "ahead": "N", "right": "NE"}
        return {
            "t": "seer_view",
            "bearing": compass[princess["side"]] if princess else None,
            "distance": princess["distance"].upper() if princess else None,
            "confidence": princess["confidence"] if princess else 0.0,
            "giant": {"direction": giant["side"].upper() if giant["side"] else None, "seconds": giant["seconds"], "confidence": giant["confidence"]},
            "source": self.source,
        }


def projected_stimuli(fly_x: float, fly_y: float, fly_z: float, elapsed_s: float) -> dict[str, Any]:
    """Small deterministic world used until authored trials arrive in a later phase."""
    princess_x, princess_y, princess_z = 0.25, 0.18, 0.85
    dx, dy, dz = princess_x - fly_x, princess_y - fly_y, princess_z - fly_z
    bearing = math.degrees(math.atan2(dx, dz))  # 0 = straight ahead; up to +/-180 once the fly has flown past her
    elevation = math.degrees(math.atan2(dy, math.hypot(dx, dz)))
    distance = max(1.0, math.sqrt(dx * dx + dy * dy + dz * dz) * 220.0)
    # No test hand any more (Ved removed it with the wall course): the campaign's attacks supply the giants.
    return {"princess": {"bearing_deg": bearing, "elevation_deg": elevation, "distance_cm": distance}, "giants": []}
