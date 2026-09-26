"""Authoritative room state for the first-person controller prototype."""

from __future__ import annotations

from dataclasses import dataclass, field


MOVEMENT_ROLES = {"helmsman": "x", "liftmaster": "y", "wingmaster": "z"}
ALL_ROLES = (*MOVEMENT_ROLES, "seer")


@dataclass
class AxisInput:
    value: int = 0
    updated_at: float = 0.0


@dataclass
class FlyState:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    vx: float = 0.0
    vy: float = 0.0
    vz: float = 0.0


@dataclass
class RoomState:
    room_code: str
    elapsed_s: float = 0.0
    fly: FlyState = field(default_factory=FlyState)
    inputs: dict[str, AxisInput] = field(default_factory=lambda: {role: AxisInput() for role in ALL_ROLES})
