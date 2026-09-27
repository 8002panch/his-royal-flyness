from __future__ import annotations

import unittest

from relay.relay import RelayError, RelayState


def phone(state: RelayState, connection_id: str, client_id: str, seq: int = 1, room: str = "BZKT") -> None:
    state.connect(connection_id)
    state.handle(connection_id, {"t": "join", "room": room, "name": connection_id, "clientId": client_id, "seq": seq})


class RelayStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.state = RelayState(room_secret="secret")

    def test_rooms_are_isolated(self) -> None:
        phone(self.state, "a", "a")
        phone(self.state, "b", "b", room="CFGH")
        self.state.handle("a", {"t": "pick", "role": "helmsman", "seq": 2})
        self.state.handle("b", {"t": "pick", "role": "helmsman", "seq": 2})
        self.assertEqual(self.state.rooms["BZKT"].role_connections["helmsman"], "a")
        self.assertEqual(self.state.rooms["CFGH"].role_connections["helmsman"], "b")

    def test_duplicate_role_is_rejected(self) -> None:
        phone(self.state, "a", "a")
        phone(self.state, "b", "b")
        self.state.handle("a", {"t": "pick", "role": "seer", "seq": 2})
        with self.assertRaisesRegex(RelayError, "already filled"):
            self.state.handle("b", {"t": "pick", "role": "seer", "seq": 2})

    def test_fifth_phone_can_wait_but_not_take_a_seat(self) -> None:
        for index, role in enumerate(("helmsman", "liftmaster", "wingmaster", "seer")):
            phone(self.state, f"p{index}", f"p{index}")
            self.state.handle(f"p{index}", {"t": "pick", "role": role, "seq": 2})
        self.state.connect("fifth")
        response, _ = self.state.handle("fifth", {"t": "join", "room": "BZKT", "name": "fifth", "clientId": "fifth", "seq": 1})
        self.assertEqual((response["t"], response["roles"]), ("joined", []))
        with self.assertRaisesRegex(RelayError, "already filled"):
            self.state.handle("fifth", {"t": "pick", "role": "seer", "seq": 2})

    def test_waiting_phones_and_extra_tabs_never_fill_the_court(self) -> None:
        # the bug the team hit: a second tab (or a phone that never picked) made the relay say "full" with seats free
        phone(self.state, "tab1", "neil")
        phone(self.state, "tab2", "neil")
        for index, role in enumerate(("helmsman", "liftmaster")):
            phone(self.state, f"p{index}", f"p{index}")
            self.state.handle(f"p{index}", {"t": "pick", "role": role, "seq": 2})
        self.state.connect("late")
        response, _ = self.state.handle("late", {"t": "join", "room": "BZKT", "name": "Ved", "clientId": "ved", "seq": 1})
        self.assertEqual((response["t"], response["roles"]), ("joined", ["wingmaster", "seer"]))
        for index in range(11):  # 16 phones are allowed in a room; the 17th is refused
            phone(self.state, f"x{index}", f"x{index}")
        self.state.connect("too-many")
        with self.assertRaisesRegex(RelayError, "Too many"):
            self.state.handle("too-many", {"t": "join", "room": "BZKT", "name": "x", "clientId": "x", "seq": 1})

    def test_a_phone_that_slept_gets_its_role_back_from_its_dead_connection(self) -> None:
        phone(self.state, "old", "ap")
        self.state.handle("old", {"t": "pick", "role": "seer", "seq": 2})
        self.state.connect("new")  # the old socket hasn't timed out yet, so it still holds the seat
        response, events = self.state.handle("new", {"t": "join", "room": "BZKT", "name": "AP", "clientId": "ap", "role": "seer", "seq": 1})
        self.assertEqual((response["t"], response["role"]), ("assigned", "seer"))
        self.assertEqual(self.state.rooms["BZKT"].role_connections["seer"], "new")
        self.assertIn({"to": "old", "payload": {"t": "seat_moved", "role": "seer"}}, events, "an open older page is told")
        self.assertEqual(self.state.disconnect("old"), [], "the dead connection closing later must not unseat the player")

    def test_phones_still_choosing_see_seats_fill_and_free_up(self) -> None:
        phone(self.state, "a", "a")
        phone(self.state, "b", "b")
        _, events = self.state.handle("a", {"t": "pick", "role": "helmsman", "seq": 2})
        to_b = [e["payload"] for e in events if e["to"] == "b"]
        self.assertEqual(to_b, [{"t": "roles", "roles": ["liftmaster", "wingmaster", "seer"]}])
        events = self.state.disconnect("a")
        self.assertIn({"t": "roles", "roles": ["helmsman", "liftmaster", "wingmaster", "seer"]},
                      [e["payload"] for e in events if e["to"] == "b"])

    def test_reconnect_restores_role(self) -> None:
        phone(self.state, "a", "same")
        self.state.handle("a", {"t": "pick", "role": "wingmaster", "seq": 2})
        self.state.disconnect("a")
        self.state.connect("reconnected")
        response, _ = self.state.handle("reconnected", {"t": "join", "room": "BZKT", "name": "new", "clientId": "same", "seq": 1})
        self.assertEqual(response["t"], "assigned")
        self.assertEqual(response["role"], "wingmaster")
        self.assertTrue(response["restored"])

    def test_phone_gets_its_role_back_after_a_relay_restart(self) -> None:
        # a fresh RelayState is a restarted relay: it has no saved roles, so the phone's own memory decides
        self.state.connect("a")
        response, _ = self.state.handle("a", {"t": "join", "room": "BZKT", "name": "Ava", "clientId": "ava", "role": "seer", "seq": 1})
        self.assertEqual((response["t"], response["role"], response["restored"]), ("assigned", "seer", True))
        self.state.connect("b")  # a second phone asking for the same role gets the picker instead
        response, _ = self.state.handle("b", {"t": "join", "room": "BZKT", "name": "Bo", "clientId": "bo", "role": "seer", "seq": 1})
        self.assertEqual(response["t"], "joined")
        self.assertNotIn("seer", response["roles"])

    def test_host_gets_a_roster_on_join_pick_and_leave(self) -> None:
        self.state.connect("host")
        _, events = self.state.handle("host", {"t": "host_join", "room": "BZKT", "secret": "secret", "seq": 1})
        self.assertEqual(events[0]["payload"], {"t": "roster", "players": []})
        phone(self.state, "a", "a")
        _, events = self.state.handle("a", {"t": "pick", "role": "liftmaster", "seq": 2})
        self.assertEqual(events[0]["payload"]["players"], [{"name": "a", "role": "liftmaster"}])
        self.assertEqual(self.state.rooms[events[0]["room"]].host_connection_id, "host")
        events = self.state.disconnect("a")
        self.assertEqual(events[-1]["payload"], {"t": "roster", "players": []})

    def test_stale_input_clears_and_notifies_host(self) -> None:
        self.state.connect("host")
        self.state.handle("host", {"t": "host_join", "room": "BZKT", "secret": "secret", "seq": 1}, now=0.0)
        phone(self.state, "a", "a")
        self.state.handle("a", {"t": "pick", "role": "helmsman", "seq": 2}, now=0.0)
        self.state.handle("a", {"t": "move", "role": "helmsman", "axis": "x", "value": 1, "seq": 3}, now=0.0)
        events = self.state.expire_stale_inputs(now=1.3)
        self.assertEqual(self.state.clients["a"].held_input, 0)
        self.assertEqual(events[0]["payload"], {"t": "input_cleared", "role": "helmsman"})

    def test_disconnect_mid_hold_notifies_this_rooms_host(self) -> None:
        self.state.connect("host")
        self.state.handle("host", {"t": "host_join", "room": "BZKT", "secret": "secret", "seq": 1}, now=0.0)
        phone(self.state, "a", "a")
        self.state.handle("a", {"t": "pick", "role": "helmsman", "seq": 2}, now=0.0)
        self.state.handle("a", {"t": "move", "role": "helmsman", "axis": "x", "value": 1, "seq": 3}, now=0.0)
        events = self.state.disconnect("a")
        self.assertEqual(events[0]["payload"], {"t": "input_cleared", "role": "helmsman"})
        # RelayServer._deliver finds the host through the event's room; without it the clear was silently dropped
        self.assertEqual(self.state.rooms[events[0]["room"]].host_connection_id, "host")

    def test_non_seer_never_receives_seer_view(self) -> None:
        phone(self.state, "seer", "seer")
        phone(self.state, "helm", "helm")
        self.state.handle("seer", {"t": "pick", "role": "seer", "seq": 2})
        self.state.handle("helm", {"t": "pick", "role": "helmsman", "seq": 2})
        recipients = self.state.recipients_for_view("BZKT", {"t": "seer_view", "bearing": "NE"})
        self.assertEqual(recipients, ["seer"])
        self.assertNotIn("helm", recipients)

    def test_host_seer_view_routes_only_to_seer(self) -> None:
        self.state.connect("host")
        self.state.handle("host", {"t": "host_join", "room": "BZKT", "secret": "secret", "seq": 1})
        phone(self.state, "seer", "seer")
        phone(self.state, "helm", "helm")
        self.state.handle("seer", {"t": "pick", "role": "seer", "seq": 2})
        self.state.handle("helm", {"t": "pick", "role": "helmsman", "seq": 2})
        response, events = self.state.handle("host", {"t": "phone_view", "seq": 2, "view": {"t": "seer_view", "bearing": "NE"}})
        self.assertEqual(response["recipients"], 1)
        self.assertEqual(events[0]["to"], "seer")

    def test_each_role_can_only_control_its_assigned_axis(self) -> None:
        phone(self.state, "a", "a")
        self.state.handle("a", {"t": "pick", "role": "helmsman", "seq": 2})
        with self.assertRaisesRegex(RelayError, "assigned axis"):
            self.state.handle("a", {"t": "move", "role": "helmsman", "axis": "y", "value": 1, "seq": 3})

    def test_stale_sequence_is_rejected(self) -> None:
        phone(self.state, "a", "a")
        with self.assertRaisesRegex(RelayError, "stale"):
            self.state.handle("a", {"t": "heartbeat", "seq": 1})


if __name__ == "__main__":
    unittest.main()
