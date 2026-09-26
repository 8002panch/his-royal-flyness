"""Regenerate the host's offline fixtures (owner: Anshul). Standard library only.

    python host/test/make_fixtures.py

Writes, next to this file:
  sample_sequence.json   300 frames at 30 Hz: what Godot plays when no server is up (GameState's fallback)
  sample_events.json     captions/FX cues for that sequence, by frame (voice lines from docs/LORE.md)
  sample_lobby.json      one lobby-phase state
  sample_chronicle.json  one chronicle-phase state wrapping a Chronicler-shaped result

GameState tags every fallback frame "offline_sample": true, and the main screen stamps OFFLINE SAMPLE on it.
None of these numbers come from the brain; they are hand-scripted placeholders.

Frame shape (real fields first, copied from server/main.py GameSession.godot_state on main):
  t, phase, time, fly{x,y,z,vx,vy,vz}, render{princess, giant}, roles{helmsman, liftmaster, wingmaster, seer}
Provisional fields nobody has defined yet (the host shows them if present, neutral if absent):
  trial, brain, meters.candle, controls{x,y,z},
  brainActivity{her_L, her_R, looming, escape, steer, song} (the host contract in team/anshul/README.md)
Legacy fields only for the preserved dashboard (scenes/Main.tscn), which predates the real feed:
  prince, princess, giant (top-down cm), cues{source}
No Seer cue (Princess bearing / Giant direction or ETA) is written into any top-level field;
render.* is the world geometry Godot draws, exactly as the real server sends it.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent
HZ = 30
FRAMES = 300

# server/movement.py MovementTuning, so the sample moves like the real body
ACCEL, DRAG, MAX_SPEED, DEAD_ZONE, BOUNDS = 2.4, 3.2, 1.0, 0.05, 1.0
# server/seer_adapter.py projected_stimuli: Princess position and cm per body unit
PRINCESS = (0.25, 0.18, 0.85)
UNIT_CM = 220.0

# (start s, end s, value) held inputs per axis, and the Seer's scan windows
SCRIPT = {
    "z": [(1.5, 1.9, 1), (5.6, 6.0, 1), (6.5, 6.7, -1), (7.4, 8.0, 1)],
    "x": [(0.8, 1.0, 1), (3.9, 4.3, -1), (6.0, 6.3, 1)],
    "y": [(0.5, 0.75, 1), (4.0, 4.7, -1), (6.2, 6.9, 1)],
}
SCANS = [(2.0, 5.4)]
GIANT_START, GIANT_END = 3.0, 5.2
GIANT_APPROACH = 135.0

EVENTS = [
    (6, "Herald", "H_TRIAL_2", "The Second Trial: the Banquet. The feast is fragrant. So, alas, is Sir Cheapdate."),
    (60, "Sir Cheapdate", "R_CHEAPDATE", "One more grape and I shall be royalty."),
    (95, "Herald", "H_WARN_GIANT", "The Giant stirs!"),
    (180, "Princess Miranda", "P_RIVAL", "Sir Indy again? He is simply not dead yet."),
    (262, "Princess Miranda", "P_CHARMED", "Now that is a serenade."),
]


def held(axis: str, t: float) -> int:
    for a, b, v in SCRIPT[axis]:
        if a <= t < b:
            return v
    return 0


def step_axis(pos: float, vel: float, intent: int, dt: float) -> tuple[float, float]:
    """Same integration as server/movement.py MovementSimulator.step, one axis."""
    if intent:
        vel += intent * ACCEL * dt
    else:
        vel *= max(0.0, 1.0 - DRAG * dt)
        if abs(vel) < DEAD_ZONE:
            vel = 0.0
    vel = max(-MAX_SPEED, min(MAX_SPEED, vel))
    pos += vel * dt
    if pos <= -BOUNDS or pos >= BOUNDS:
        pos = max(-BOUNDS, min(BOUNDS, pos))
        vel = 0.0
    return pos, vel


def princess_stimulus(fx: float, fy: float, fz: float) -> dict:
    """Same maths as server/seer_adapter.py projected_stimuli (princess part)."""
    px, py, pz = PRINCESS
    depth = max(0.05, pz - fz)
    return {
        "bearing_deg": round(math.degrees(math.atan2(px - fx, depth)), 3),
        "elevation_deg": round(math.degrees(math.atan2(py - fy, depth)), 3),
        "distance_cm": round(math.sqrt((px - fx) ** 2 + (py - fy) ** 2 + depth**2) * UNIT_CM, 2),
    }


def giant_stimulus(t: float) -> dict | None:
    if not GIANT_START <= t < GIANT_END:
        return None
    u = (t - GIANT_START) / (GIANT_END - GIANT_START)
    return {
        "bearing_deg": round(30.0 - 22.0 * u, 2),
        "elevation_deg": 25.0,
        "distance_cm": round(max(15.0, 300.0 - GIANT_APPROACH * (t - GIANT_START)), 2),
        "approach_cm_s": GIANT_APPROACH,
        "size_cm": 40.0,
    }


def sample_activity(t: float, princess: dict, giant: dict | None, x_intent: int) -> dict:
    """Hand-made z-scores so the HUD rows have something to show offline. Not brain output."""
    near = max(0.0, 1.0 - princess["distance_cm"] / 450.0)
    loom = 0.0 if giant is None else 4.0 * max(0.0, 1.0 - giant["distance_cm"] / 300.0)
    return {
        "her_L": round(0.4 + 2.2 * near + 0.3 * math.sin(t * 3.1), 3),
        "her_R": round(0.3 + 2.0 * near + 0.3 * math.cos(t * 2.3), 3),
        "looming": round(loom + 0.2 * math.sin(t * 5.0), 3),
        "escape": round(max(0.0, loom - 1.5) * 1.2, 3),
        "steer": round(1.8 * x_intent + 0.2 * math.sin(t * 1.7), 3),
        "song": round(2.8 * near * near, 3),
    }


def sequence() -> list[dict]:
    dt = 1.0 / HZ
    pos = {"x": 0.0, "y": -0.2, "z": -0.95}
    vel = {"x": 0.0, "y": 0.0, "z": 0.0}
    frames = []
    for i in range(FRAMES):
        t = i * dt
        intents = {a: held(a, t) for a in ("x", "y", "z")}
        for a in ("x", "y", "z"):
            pos[a], vel[a] = step_axis(pos[a], vel[a], intents[a], dt)
        scanning = any(a <= t < b for a, b in SCANS)
        princess = princess_stimulus(pos["x"], pos["y"], pos["z"])
        giant = giant_stimulus(t)
        activity = sample_activity(t, princess, giant, intents["x"])
        g_prog = 0.0 if giant is None else 1.0 - (giant["distance_cm"] - 15.0) / 285.0
        frames.append({
            "t": "state", "phase": "play", "time": round(t, 3), "frame": i,
            "fly": {"x": round(pos["x"], 4), "y": round(pos["y"], 4), "z": round(pos["z"], 4),
                    "vx": round(vel["x"], 4), "vy": round(vel["y"], 4), "vz": round(vel["z"], 4)},
            "render": {"princess": princess, "giant": giant},
            "roles": {"helmsman": intents["x"] != 0, "liftmaster": intents["y"] != 0,
                      "wingmaster": intents["z"] != 0, "seer": scanning},
            # provisional
            "trial": "II", "brain": "true", "meters": {"candle": round(1.0 - t / 60.0, 4)},
            "brainActivity": activity, "controls": intents,
            # legacy, for the preserved dashboard's top-down hall (600 x 400 cm)
            "prince": {"x": round(300 + 250 * pos["x"], 1), "y": round(330 - 140 * (pos["z"] + 1), 1), "h": -90.0},
            "princess": {"x": round(300 + 250 * PRINCESS[0], 1), "y": round(330 - 140 * (PRINCESS[2] + 1), 1), "h": 90.0},
            "giant": {"active": giant is not None, "x": 200.0, "y": 150.0, "size": round(g_prog, 3)},
            "cues": {"source": "true"},
        })
    return frames


def events() -> list[dict]:
    return [{"frame": f, "t": "event", "kind": "voice", "id": i, "speaker": who, "caption": text}
            for f, who, i, text in EVENTS]


def lobby() -> dict:
    return {"t": "state", "phase": "lobby", "room": "BZKT", "trial": "II",
            "players": [{"name": "Ava", "role": "helmsman"}, {"name": "Ben", "role": "liftmaster"},
                        {"name": "Cy", "role": "seer"}]}


def chronicle() -> dict:
    """Shaped like server/chronicler.py Chronicler.finish(); shares per category sum to 1."""
    cats = ["thrust", "brake", "turn", "altitude", "escape", "song"]
    raw = {
        "Ava": {"roles": ["helmsman"], "w": [0.20, 0.10, 0.62, 0.10, 0.20, 0.25]},
        "Ben": {"roles": ["liftmaster"], "w": [0.15, 0.10, 0.13, 0.70, 0.50, 0.15]},
        "Cy": {"roles": ["wingmaster"], "w": [0.60, 0.72, 0.15, 0.10, 0.10, 0.10]},
        "Dee": {"roles": ["seer"], "w": [0.05, 0.08, 0.10, 0.10, 0.20, 0.50]},
    }
    totals = [sum(p["w"][k] for p in raw.values()) for k in range(len(cats))]
    players = {}
    for name, p in raw.items():
        share = {c: round(p["w"][k] / totals[k], 3) for k, c in enumerate(cats)}
        share["overall"] = round(sum(share[c] for c in cats) / len(cats), 3)
        players[name] = {"roles": p["roles"], "share": share, "events": []}
    players["Ben"]["events"] = ["1 escape happened because of you"]
    players["Dee"]["events"] = ["2.4 s of the serenade was yours"]
    knight = max(players, key=lambda n: players[n]["share"]["overall"])
    result = {"chapter": "ii_banquet", "brain": "true", "ticks": 500, "players": players, "knight": knight,
              "blunder": {"player": "Ben", "kind": "crash", "tick": 412},
              "note": "Replayed open loop: same button presses, one player's removed."}
    return {"t": "state", "phase": "chronicle", "trial": "II", "chronicle": result}


def main() -> None:
    files = {
        "sample_sequence.json": sequence(),
        "sample_events.json": events(),
        "sample_lobby.json": lobby(),
        "sample_chronicle.json": chronicle(),
    }
    for name, data in files.items():
        path = OUT / name
        path.write_text(json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8")
        print(f"wrote {path.relative_to(OUT.parent.parent)} ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
