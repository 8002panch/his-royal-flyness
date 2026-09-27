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


@dataclass(frozen=True)
class WallGate:
    """A solid course wall with one body-radius-safe opening."""

    name: str
    z: float
    gap_min_x: float
    gap_max_x: float
    gap_min_y: float
    gap_max_y: float
    fly_radius: float = 0.10

    def opening_contains(self, fly: FlyState) -> bool:
        return (
            self.gap_min_x + self.fly_radius <= fly.x <= self.gap_max_x - self.fly_radius
            and self.gap_min_y + self.fly_radius <= fly.y <= self.gap_max_y - self.fly_radius
        )

    def crossed(self, previous_z: float, next_z: float) -> bool:
        return (previous_z < self.z <= next_z) or (previous_z > self.z >= next_z)


class MovementSimulator:
    """Integrates controller intent into a bounded three-axis body state."""

    def __init__(self, tuning: MovementTuning = MovementTuning(), walls: tuple[WallGate, ...] = ()) -> None:
        self.tuning = tuning
        self.walls = walls

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
            previous_position = getattr(fly, axis)
            position = previous_position + velocity * dt
            if position <= -self.tuning.bounds or position >= self.tuning.bounds:
                position = max(-self.tuning.bounds, min(self.tuning.bounds, position))
                velocity = 0.0
            if axis == "z":
                crossed = [wall for wall in self.walls if wall.crossed(previous_position, position)]
                crossed.sort(key=lambda wall: abs(wall.z - previous_position))
                for wall in crossed:
                    if wall.opening_contains(fly):
                        continue
                    position = wall.z - 0.001 if velocity > 0.0 else wall.z + 0.001
                    velocity = 0.0
                    break
            setattr(fly, axis, position)
            setattr(fly, velocity_name, velocity)
