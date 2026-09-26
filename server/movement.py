"""Deterministic direct x/y/z movement for the controller prototype."""

from __future__ import annotations

from dataclasses import dataclass

from .state import FlyState


@dataclass(frozen=True)
class MovementTuning:
    acceleration: float = 2.4
    drag_per_second: float = 3.2
    max_speed: float = 1.0
    dead_zone: float = 0.05
    bounds: float = 1.0


class MovementSimulator:
    """Integrates controller intent into a bounded three-axis body state."""

    def __init__(self, tuning: MovementTuning = MovementTuning()) -> None:
        self.tuning = tuning

    def step(self, fly: FlyState, inputs: dict[str, float], dt: float) -> None:
        if dt <= 0:
            return
        for axis in ("x", "y", "z"):
            intent = float(inputs.get(axis, 0.0))
            if abs(intent) < self.tuning.dead_zone:
                intent = 0.0
            velocity_name = f"v{axis}"
            velocity = getattr(fly, velocity_name)
            if intent:
                velocity += intent * self.tuning.acceleration * dt
            else:
                velocity *= max(0.0, 1.0 - self.tuning.drag_per_second * dt)
                if abs(velocity) < self.tuning.dead_zone:
                    velocity = 0.0
            velocity = max(-self.tuning.max_speed, min(self.tuning.max_speed, velocity))
            position = getattr(fly, axis) + velocity * dt
            if position <= -self.tuning.bounds or position >= self.tuning.bounds:
                position = max(-self.tuning.bounds, min(self.tuning.bounds, position))
                velocity = 0.0
            setattr(fly, axis, position)
            setattr(fly, velocity_name, velocity)
