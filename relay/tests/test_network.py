from __future__ import annotations

import json
import unittest

from websockets.client import connect
from websockets.server import serve

from relay.relay import RelayServer, RelayState


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
            await second_phone.send(json.dumps({"t": "pick", "role": "seer", "seq": 2}))
            self.assertEqual(json.loads(await second_phone.recv())["role"], "seer")

