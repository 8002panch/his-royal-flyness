"""Phase 3 authoritative movement server.

Run ``python -m server.main --room BZKT [--seer true|changeling|placeholder]`` after starting ``relay/relay.py``,
or start everything at once with ``python run_local.py``.
The server accepts role-scoped intent from the relay, advances deterministic body
state at 50 Hz, sends 30 Hz state to Godot, and supplies phone feedback at 10 Hz.
"""

from __future__ import annotations

import argparse
import asyncio
import os
import time
from typing import Any

from .godot_link import GodotLink
from .movement import MovementSimulator
from .relay_client import RelayClient
from .seer_adapter import PlaceholderSeerAdapter, projected_stimuli
from .state import MOVEMENT_ROLES, RoomState


STALE_INPUT_SECONDS = 1.2
TICK_S = 1 / 50
GODOT_S = 1 / 30
PHONE_S = 1 / 10
SEER_SOURCES = ("true", "changeling", "placeholder")


def make_seer(source: str = "true") -> Any:
    """The brain-powered Seer (brain/seer.py) when its data files are present, else the deterministic placeholder.

    Both brains are loaded up front so the host's True Prince / Changeling toggle is instant during the demo.
    """
    if source == "placeholder":
        return PlaceholderSeerAdapter()
    try:
        from brain.seer import SeerAdapter

        seer = SeerAdapter(source)
        seer.swap("changeling" if source == "true" else "true")
        seer.swap(source)
        return seer
    except Exception as exc:  # missing data/ files or any brain failure: the game still runs
        print(f"[server] brain unavailable ({exc!r}); the Seer uses placeholder cues")
        return PlaceholderSeerAdapter()


class GameSession:
    """Pure authoritative game state; importable for headless replay and tests."""

    def __init__(self, room_code: str, seer: Any = None, join_url: str | None = None) -> None:
        self.state = RoomState(room_code=room_code)
        self.simulator = MovementSimulator()
        self.seer = seer or PlaceholderSeerAdapter()
        self.join_url = join_url
        self.players: dict[str, str] = {}  # role -> display name, for the host screen (run_local.py fills it from its relay)
        self.stimuli: dict[str, Any] | None = None
        self.cues: dict[str, Any] | None = None

    def apply_input(self, message: dict[str, Any], now: float) -> None:
        kind, role = message.get("t"), message.get("role")
        if kind == "input_cleared" and role in self.state.inputs:
            self.state.inputs[role].value = 0
            self.state.inputs[role].updated_at = now
            return
        if kind == "move" and role in MOVEMENT_ROLES:
            if message.get("axis") != MOVEMENT_ROLES[role] or message.get("value") not in {-1, 0, 1}:
                raise ValueError("Invalid movement message for assigned role.")
            self.state.inputs[role].value = int(message["value"])
            self.state.inputs[role].updated_at = now
            return
        if kind == "sense" and role == "seer" and message.get("scan") in {0, 1}:
            self.state.inputs[role].value = int(message["scan"])
            self.state.inputs[role].updated_at = now
            return
        raise ValueError("Unsupported relay input.")

    def step(self, dt: float, now: float) -> None:
        for input_state in self.state.inputs.values():
            if now - input_state.updated_at > STALE_INPUT_SECONDS:
                input_state.value = 0
        intents = {axis: self.state.inputs[role].value for role, axis in MOVEMENT_ROLES.items()}
        self.simulator.step(self.state.fly, intents, dt)
        self.state.elapsed_s += dt
        self._sense()

    def _sense(self) -> dict[str, Any]:
        """Sense once per tick; the Seer's phone view and Godot's brainActivity both reuse these cues."""
        fly = self.state.fly
        self.stimuli = projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        self.cues = self.seer.sense(self.stimuli)
        return self.cues

    def set_brain(self, source: str, seed: int = 0) -> str:
        """Host toggle between the True Prince, the Changeling and placeholder cues; returns the source now in use."""
        if source not in SEER_SOURCES:
            raise ValueError(f"source must be one of {SEER_SOURCES}")
        swap = getattr(self.seer, "swap", None)
        if swap is not None:
            swap(source, seed)
            self.cues = None
        return self.seer.source

    def phone_views(self) -> list[dict[str, Any]]:
        fly = self.state.fly
        views = [
            {"t": "control_view", "role": "helmsman", "actualX": round(fly.x, 3), "momentum": round(fly.vx, 3)},
            {"t": "control_view", "role": "liftmaster", "altitude": round(fly.y, 3), "verticalVelocity": round(fly.vy, 3)},
            {"t": "control_view", "role": "wingmaster", "speed": round(fly.vz, 3), "braking": self.state.inputs["wingmaster"].value < 0},
        ]
        if self.state.inputs["seer"].value:
            views.append(self.seer.to_phone_view(self.cues if self.cues is not None else self._sense()))
        return views

    def godot_state(self) -> dict[str, Any]:
        fly = self.state.fly
        stimuli = self.stimuli or projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        giant = (stimuli["giants"] or [None])[0]
        cues = self.cues or {}
        # Brain activity for the HUD: only real brain output (side-free keys from brain/seer.py), never placeholder numbers.
        activity = cues.get("activity", {}) if cues.get("source") in ("true", "changeling") else {}
        return {
            "t": "state", "phase": "play", "time": round(self.state.elapsed_s, 3),
            "room": self.state.room_code, "joinUrl": self.join_url, "brain": self.seer.source, "brainActivity": activity,
            "fly": {"x": round(fly.x, 4), "y": round(fly.y, 4), "z": round(fly.z, 4), "vx": round(fly.vx, 4), "vy": round(fly.vy, 4), "vz": round(fly.vz, 4)},
            "render": {"princess": stimuli["princess"], "giant": giant},
            "roles": {role: self.state.inputs[role].value != 0 for role in self.state.inputs},
            "players": dict(self.players),
        }


class GameServer:
    def __init__(self, session: GameSession, relay: RelayClient, godot: GodotLink) -> None:
        self.session, self.relay, self.godot = session, relay, godot

    async def accept_input(self, message: dict[str, Any]) -> None:
        self.session.apply_input(message, time.monotonic())

    async def run(self) -> None:
        await self.relay.connect()
        receiver = asyncio.create_task(self.relay.receive_forever(self.accept_input))
        last = time.monotonic()
        next_tick = next_godot = next_phone = last
        try:
            while True:
                now = time.monotonic()
                self.session.step(now - last, now)
                last = now
                # Fixed-rate schedules (next += period) so a ~6 ms brain step doesn't stretch every tick and frame.
                if now >= next_godot:
                    await self.godot.publish(self.session.godot_state())
                    next_godot = _next_time(next_godot, GODOT_S, now)
                if now >= next_phone:
                    for view in self.session.phone_views():
                        await self.relay.send_phone_view(view)
                    next_phone = _next_time(next_phone, PHONE_S, now)
                next_tick = _next_time(next_tick, TICK_S, time.monotonic())
                await asyncio.sleep(max(0.0, next_tick - time.monotonic()))
        finally:
            receiver.cancel()
            await self.relay.close()


def _next_time(scheduled: float, period: float, now: float) -> float:
    """The next slot of a fixed-rate schedule; after a stall, restart from now instead of bursting to catch up."""
    scheduled += period
    return scheduled if scheduled > now - period else now + period


async def run(room: str, relay_url: str, secret: str, godot_port: int, seer: str = "true", join_url: str | None = None) -> None:
    session = GameSession(room, seer=make_seer(seer), join_url=join_url)
    print(f"[server] room {room}, Seer source: {session.seer.source}")
    godot = GodotLink()
    async with godot.serve(port=godot_port):
        await GameServer(session, RelayClient(relay_url, room, secret), godot).run()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="His Royal Flyness authoritative movement server")
    parser.add_argument("--room", default=os.getenv("ROOM_CODE", "BZKT"))
    parser.add_argument("--relay-url", default=os.getenv("RELAY_URL", "ws://127.0.0.1:8080"))
    parser.add_argument("--godot-port", type=int, default=8765)
    parser.add_argument("--seer", choices=SEER_SOURCES, default=os.getenv("SEER_SOURCE", "true"),
                        help="true = the real MaleCNS brain (falls back to placeholder if data/ is missing)")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    asyncio.run(run(args.room, args.relay_url, os.getenv("ROOM_SECRET", ""), args.godot_port, args.seer))
