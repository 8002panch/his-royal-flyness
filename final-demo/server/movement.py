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
    z_scale: float = 1.0  # forward/back acceleration and top speed, relative to the other axes (the wall courses slow it)


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

    # How far from a wall's plane the fly's body stops: it has a body, so it never pokes into the wall on screen.
    WALL_STANDOFF = 0.06

    def __init__(self, tuning: MovementTuning = MovementTuning(), walls: tuple[WallGate, ...] = ()) -> None:
        self.tuning = tuning
        self.walls = walls
        self.bump = 0.0  # speed of the last wall hit this step (0 = none): the screens thud on it

    def step(self, fly: FlyState, inputs: dict[str, float], dt: float) -> None:
        if dt <= 0:
            return
        self.bump = 0.0
        for axis in ("x", "y", "z"):
            intent = float(inputs.get(axis, 0.0))
            if abs(intent) < self.tuning.dead_zone:
                intent = 0.0
            velocity_name = f"v{axis}"
            velocity = getattr(fly, velocity_name)
            scale = self.tuning.z_scale if axis == "z" else 1.0
            if intent:
                velocity += intent * self.tuning.acceleration * scale * dt
            else:
                velocity *= max(0.0, 1.0 - self.tuning.drag_per_second * dt)
                if abs(velocity) < self.tuning.dead_zone * scale:
                    velocity = 0.0
            top = self.tuning.max_speed * scale
            velocity = max(-top, min(top, velocity))
            previous_position = getattr(fly, axis)
            position = previous_position + velocity * dt
            if position <= -self.tuning.bounds or position >= self.tuning.bounds:
                position = max(-self.tuning.bounds, min(self.tuning.bounds, position))
                velocity = 0.0
            if axis == "z":
                # A wall is solid from its plane out to the body's standoff on each side: moving towards it, the fly
                # stops at the standoff unless it is lined up with the opening. Checked against the standoff zone, not
                # just the plane, so a fly resting against a wall can never creep through it.
                pad = self.WALL_STANDOFF
                for wall in sorted(self.walls, key=lambda w: abs(w.z - previous_position)):
                    if wall.opening_contains(fly):
                        continue
                    if velocity > 0.0 and previous_position <= wall.z and position > wall.z - pad:
                        stop = min(previous_position, wall.z - pad) if previous_position > wall.z - pad else wall.z - pad
                    elif velocity < 0.0 and previous_position >= wall.z and position < wall.z + pad:
                        stop = max(previous_position, wall.z + pad) if previous_position < wall.z + pad else wall.z + pad
                    else:
                        continue
                    self.bump = max(self.bump, abs(velocity))
                    position, velocity = stop, 0.0
                    break
            setattr(fly, axis, position)
            setattr(fly, velocity_name, velocity)
