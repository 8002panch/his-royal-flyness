from __future__ import annotations

import unittest

from server.main import COURSE_WALLS, GODOT_S, GameSession, STALE_INPUT_SECONDS, _next_time
from server.seer_adapter import PlaceholderSeerAdapter


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
                initial = {axis: getattr(session.state.fly, axis) for axis in ("x", "y", "z")}
                session.apply_input({"t": "move", "role": role, "axis": axis, "value": 1}, now=0.0)
                session.step(0.5, now=0.5)
                fly = session.state.fly
                self.assertNotEqual(getattr(fly, changed), initial[changed])
                for other_axis in {"x", "y", "z"} - {changed}:
                    self.assertEqual(getattr(fly, other_axis), initial[other_axis])

    def test_every_wall_blocks_a_closed_section_and_allows_its_opening(self) -> None:
        for wall in COURSE_WALLS:
            with self.subTest(wall=wall.name, route="blocked"):
                session = self.make_session()
                session.state.fly.z = wall.z - 0.05
                session.state.fly.x = -0.95 if wall.gap_min_x > -0.9 else 0.95
                session.state.fly.y = 0.95 if wall.gap_max_y < 0.9 else -0.95
                session.state.fly.vz = 1.0
                session.simulator.step(session.state.fly, {"z": 1.0}, 0.2)
                self.assertLess(session.state.fly.z, wall.z)
                self.assertEqual(session.state.fly.vz, 0.0)

            with self.subTest(wall=wall.name, route="opening"):
                session = self.make_session()
                session.state.fly.z = wall.z - 0.05
                session.state.fly.x = (wall.gap_min_x + wall.gap_max_x) / 2.0
                session.state.fly.y = (wall.gap_min_y + wall.gap_max_y) / 2.0
                session.state.fly.vz = 1.0
                session.simulator.step(session.state.fly, {"z": 1.0}, 0.2)
                self.assertGreater(session.state.fly.z, wall.z)

    def test_wall_collision_cannot_be_tunnelled_in_either_direction(self) -> None:
        wall = COURSE_WALLS[0]
        for start_z, velocity, intent, comparison in [
            (wall.z - 0.4, 1.0, 1.0, lambda z: z < wall.z),
            (wall.z + 0.4, -1.0, -1.0, lambda z: z > wall.z),
        ]:
            session = self.make_session()
            session.state.fly.z = start_z
            session.state.fly.x = 0.9
            session.state.fly.vz = velocity
            session.simulator.step(session.state.fly, {"z": intent}, 0.8)
            self.assertTrue(comparison(session.state.fly.z))
            self.assertEqual(session.state.fly.vz, 0.0)

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

    def test_godot_state_carries_the_room_join_link_and_brain_fields(self) -> None:
        session = GameSession("BZKT", join_url="http://10.0.0.2:8000/?room=BZKT")
        session.step(0.02, now=0.02)
        state = session.godot_state()
        self.assertEqual((state["room"], state["joinUrl"], state["brain"]), ("BZKT", "http://10.0.0.2:8000/?room=BZKT", "placeholder"))
        self.assertEqual(state["brainActivity"], {}, "placeholder cues must never show up as brain activity")

    def test_senses_once_per_tick_and_reuses_the_cues(self) -> None:
        class CountingSeer(PlaceholderSeerAdapter):
            calls = 0

            def sense(self, stimuli):
                CountingSeer.calls += 1
                return super().sense(stimuli)

        session = GameSession("BZKT", seer=CountingSeer())
        session.apply_input({"t": "sense", "role": "seer", "scan": 1}, now=0.0)
        session.step(0.02, now=0.02)
        session.phone_views()
        session.godot_state()
        self.assertEqual(CountingSeer.calls, 1)

    def test_held_input_refreshed_by_the_phone_never_goes_stale(self) -> None:
        """Phones resend a held control every 0.4 s; the server must keep it for as long as the player holds it."""
        session = self.make_session()
        now = 0.0
        for tick in range(150):  # 3 s at 50 Hz
            if tick % 20 == 0:
                session.apply_input({"t": "move", "role": "wingmaster", "axis": "z", "value": 1}, now=now)
            now += 0.02
            session.step(0.02, now=now)
            self.assertEqual(session.state.inputs["wingmaster"].value, 1, f"dropped at {now:.2f}s")

    def test_fixed_rate_schedule_keeps_its_average_and_does_not_burst_after_a_stall(self) -> None:
        scheduled, now, sent = 0.0, 0.0, 0
        for _ in range(500):  # 10 s of 20 ms ticks, sending whenever the slot has come up
            now += 0.02
            if now >= scheduled:
                sent += 1
                scheduled = _next_time(scheduled, GODOT_S, now)
        self.assertAlmostEqual(sent / 10.0, 30.0, delta=1.0)
        self.assertGreater(_next_time(0.0, GODOT_S, now=5.0), 5.0, "after a 5 s stall the next frame is in the future")

    def test_world_geometry_puts_the_princess_behind_and_has_no_hand_hazard(self) -> None:
        from server.seer_adapter import projected_stimuli

        ahead = projected_stimuli(0.25, 0.18, 0.0, 0.0)["princess"]
        behind = projected_stimuli(0.0, 0.18, 1.0, 0.0)["princess"]  # the fly has flown past her
        self.assertAlmostEqual(ahead["bearing_deg"], 0.0)
        self.assertGreater(behind["bearing_deg"], 90.0)
        self.assertEqual(projected_stimuli(0, 0, 0, 5.0)["giants"], [])
        self.assertNotIn("giant", GameSession("BZKT").godot_state()["render"])


if __name__ == "__main__":
    unittest.main()
