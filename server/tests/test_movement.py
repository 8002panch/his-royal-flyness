from __future__ import annotations

import unittest

from server.main import GameSession, STALE_INPUT_SECONDS


class GameSessionTests(unittest.TestCase):
    def make_session(self) -> GameSession:
        return GameSession("BZKT")

    def test_each_role_changes_only_its_owned_axis(self) -> None:
        cases = [
            ("helmsman", "x", "x"),
            ("liftmaster", "y", "y"),
            ("wingmaster", "z", "z"),
        ]
        for role, axis, changed in cases:
            with self.subTest(role=role):
                session = self.make_session()
                session.apply_input({"t": "move", "role": role, "axis": axis, "value": 1}, now=0.0)
                session.step(0.5, now=0.5)
                fly = session.state.fly
                self.assertNotEqual(getattr(fly, changed), 0.0)
                for other_axis in {"x", "y", "z"} - {changed}:
                    self.assertEqual(getattr(fly, other_axis), 0.0)

    def test_release_and_stale_input_stop_acceleration(self) -> None:
        session = self.make_session()
        session.apply_input({"t": "move", "role": "helmsman", "axis": "x", "value": 1}, now=0.0)
        session.step(0.2, now=0.2)
        accelerated = session.state.fly.vx
        session.apply_input({"t": "move", "role": "helmsman", "axis": "x", "value": 0}, now=0.2)
        session.step(0.2, now=0.4)
        self.assertLess(abs(session.state.fly.vx), abs(accelerated))
        session.apply_input({"t": "move", "role": "helmsman", "axis": "x", "value": 1}, now=0.4)
        session.step(0.2, now=0.6)
        session.step(0.2, now=0.6 + STALE_INPUT_SECONDS + 0.01)
        self.assertEqual(session.state.inputs["helmsman"].value, 0)

    def test_identical_input_trace_is_deterministic(self) -> None:
        trace = [
            (0.0, {"t": "move", "role": "helmsman", "axis": "x", "value": 1}),
            (0.1, {"t": "move", "role": "liftmaster", "axis": "y", "value": 1}),
            (0.2, {"t": "move", "role": "wingmaster", "axis": "z", "value": 1}),
            (0.5, {"t": "move", "role": "helmsman", "axis": "x", "value": 0}),
        ]
        snapshots = []
        for _ in range(2):
            session = self.make_session()
            last = 0.0
            for now, message in trace:
                session.step(now - last, now)
                session.apply_input(message, now)
                last = now
            session.step(0.5, 1.0)
            snapshots.append(session.godot_state())
        self.assertEqual(snapshots[0], snapshots[1])

    def test_server_rejects_wrong_axis_before_simulation(self) -> None:
        session = self.make_session()
        with self.assertRaisesRegex(ValueError, "Invalid movement"):
            session.apply_input({"t": "move", "role": "helmsman", "axis": "y", "value": 1}, now=0.0)

    def test_seer_data_is_never_in_movement_phone_views(self) -> None:
        session = self.make_session()
        movement_views = session.phone_views()
        self.assertEqual([view["role"] for view in movement_views], ["helmsman", "liftmaster", "wingmaster"])
        session.apply_input({"t": "sense", "role": "seer", "scan": 1}, now=0.0)
        views = session.phone_views()
        self.assertEqual(views[-1]["t"], "seer_view")
        self.assertNotIn("bearing", movement_views[0])
        self.assertNotIn("giant", movement_views[1])


if __name__ == "__main__":
    unittest.main()
