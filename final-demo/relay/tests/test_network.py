from __future__ import annotations

import asyncio
import json
import unittest

from websockets.client import connect
from websockets.server import serve

from relay.relay import RelayServer, RelayState


class HangingSocket:
    """A phone that went to sleep: its connection still looks open, but a send to it never finishes."""
    open = True

    async def send(self, data: str) -> None:
        await asyncio.Event().wait()


class RecordingSocket:
    open = True

    def __init__(self) -> None:
        self.sent: list[dict] = []

    async def send(self, data: str) -> None:
        self.sent.append(json.loads(data))


class SlowPeerTests(unittest.IsolatedAsyncioTestCase):
    async def test_a_sleeping_phone_never_delays_anyone_else(self) -> None:
        relay = RelayServer(RelayState())
        relay.sockets = {"sleepy": HangingSocket(), "awake": RecordingSocket()}
        events = [{"to": "sleepy", "payload": {"t": "control_view", "role": "wingmaster"}},
                  {"to": "awake", "payload": {"t": "control_view", "role": "helmsman"}}]
        await asyncio.wait_for(relay._deliver(events), 0.5)  # used to hang here for the whole close timeout
        await asyncio.sleep(0.05)
        self.assertEqual(relay.sockets["awake"].sent, [{"t": "control_view", "role": "helmsman"}])

    async def test_a_frozen_host_screen_never_stalls_the_game(self) -> None:
        from server.godot_link import GodotLink

        link = GodotLink()
        frozen, live = HangingSocket(), RecordingSocket()
        link.clients = {frozen, live}
        for frame in range(3):
            await asyncio.wait_for(link.publish({"t": "state", "time": frame}), 0.5)
            await asyncio.sleep(0.01)
        self.assertEqual([m["time"] for m in live.sent], [0, 1, 2])


class RelayNetworkTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.relay = RelayServer(RelayState(room_secret="secret"))
        self.server = await serve(self.relay.handler, "127.0.0.1", 0)
        self.port = self.server.sockets[0].getsockname()[1]

    async def asyncTearDown(self) -> None:
        self.server.close()
        await self.server.wait_closed()

    async def test_two_phone_clients_join_and_choose_distinct_roles(self) -> None:
        uri = f"ws://127.0.0.1:{self.port}"
        async with connect(uri) as first_phone, connect(uri) as second_phone:
            await first_phone.send(json.dumps({"t": "join", "room": "BZKT", "name": "Ava", "clientId": "ava-phone", "seq": 1}))
            self.assertEqual(json.loads(await first_phone.recv())["t"], "joined")
            await second_phone.send(json.dumps({"t": "join", "room": "BZKT", "name": "Bo", "clientId": "bo-phone", "seq": 1}))
            self.assertEqual(json.loads(await second_phone.recv())["t"], "joined")

            await first_phone.send(json.dumps({"t": "pick", "role": "helmsman", "seq": 2}))
            self.assertEqual(json.loads(await first_phone.recv())["role"], "helmsman")
            update = json.loads(await second_phone.recv())  # the phone still choosing sees the seat go
            self.assertEqual(update, {"t": "roles", "roles": ["liftmaster", "wingmaster", "seer"]})
            await second_phone.send(json.dumps({"t": "pick", "role": "seer", "seq": 2}))
            self.assertEqual(json.loads(await second_phone.recv())["role"], "seer")

