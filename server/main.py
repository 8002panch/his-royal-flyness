"""Phase 3 authoritative movement server.

Run ``python -m server.main --room BZKT`` after starting ``relay/relay.py``.
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


class GameSession:
    """Pure authoritative game state; importable for headless replay and tests."""

    def __init__(self, room_code: str, seer: PlaceholderSeerAdapter | None = None) -> None:
        self.state = RoomState(room_code=room_code)
        self.simulator = MovementSimulator()
        self.seer = seer or PlaceholderSeerAdapter()

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

    def phone_views(self) -> list[dict[str, Any]]:
        fly = self.state.fly
        views = [
            {"t": "control_view", "role": "helmsman", "actualX": round(fly.x, 3), "momentum": round(fly.vx, 3)},
            {"t": "control_view", "role": "liftmaster", "altitude": round(fly.y, 3), "verticalVelocity": round(fly.vy, 3)},
            {"t": "control_view", "role": "wingmaster", "speed": round(fly.vz, 3), "braking": self.state.inputs["wingmaster"].value < 0},
        ]
        if self.state.inputs["seer"].value:
            stimuli = projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
            views.append(self.seer.to_phone_view(self.seer.sense(stimuli)))
        return views

    def godot_state(self) -> dict[str, Any]:
        fly = self.state.fly
        stimuli = projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        giant = (stimuli["giants"] or [None])[0]
        return {
            "t": "state", "phase": "play", "time": round(self.state.elapsed_s, 3),
            "fly": {"x": round(fly.x, 4), "y": round(fly.y, 4), "z": round(fly.z, 4), "vx": round(fly.vx, 4), "vy": round(fly.vy, 4), "vz": round(fly.vz, 4)},
            "render": {"princess": stimuli["princess"], "giant": giant},
            "roles": {role: self.state.inputs[role].value != 0 for role in self.state.inputs},
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
        next_godot = next_phone = last
        try:
            while True:
                now = time.monotonic()
                self.session.step(now - last, now)
                last = now
                if now >= next_godot:
                    await self.godot.publish(self.session.godot_state())
                    next_godot = now + 1 / 30
                if now >= next_phone:
                    for view in self.session.phone_views():
                        await self.relay.send_phone_view(view)
                    next_phone = now + 1 / 10
                await asyncio.sleep(0.02)
        finally:
            receiver.cancel()
            await self.relay.close()


async def run(room: str, relay_url: str, secret: str, godot_port: int) -> None:
    godot = GodotLink()
    async with godot.serve(port=godot_port):
        await GameServer(GameSession(room), RelayClient(relay_url, room, secret), godot).run()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="His Royal Flyness authoritative movement server")
    parser.add_argument("--room", default=os.getenv("ROOM_CODE", "BZKT"))
    parser.add_argument("--relay-url", default=os.getenv("RELAY_URL", "ws://127.0.0.1:8080"))
    parser.add_argument("--godot-port", type=int, default=8765)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    asyncio.run(run(args.room, args.relay_url, os.getenv("ROOM_SECRET", ""), args.godot_port))
