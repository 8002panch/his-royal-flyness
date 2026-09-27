from __future__ import annotations

import asyncio
import json
import unittest

from websockets.client import connect
from websockets.server import serve

from relay.relay import RelayServer, RelayState
from server.main import GameSession
from server.relay_client import RelayClient


class FourClientFlowTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.relay_server = RelayServer(RelayState(room_secret="secret"))
        self.socket_server = await serve(self.relay_server.handler, "127.0.0.1", 0)
        self.port = self.socket_server.sockets[0].getsockname()[1]
        self.session = GameSession("BZKT")
        self.host = RelayClient(f"ws://127.0.0.1:{self.port}", "BZKT", "secret")
        await self.host.connect()
        self.host_inputs: list[dict] = []

        async def accept(message: dict) -> None:
            self.host_inputs.append(message)
            self.session.apply_input(message, now=0.0)

        self.receiver = asyncio.create_task(self.host.receive_forever(accept))

    async def asyncTearDown(self) -> None:
        self.receiver.cancel()
        await self.host.close()
        self.socket_server.close()
        await self.socket_server.wait_closed()

    async def phone(self, name: str, role: str):
        socket = await connect(f"ws://127.0.0.1:{self.port}")
        await socket.send(json.dumps({"t": "join", "room": "BZKT", "name": name, "clientId": f"{name}-phone", "seq": 1}))
        self.assertEqual(json.loads(await socket.recv())["t"], "joined")
        await socket.send(json.dumps({"t": "pick", "role": role, "seq": 2}))
        self.assertEqual(json.loads(await socket.recv())["role"], role)
        return socket

    async def test_four_controllers_reach_authoritative_session_and_private_seer_view(self) -> None:
        helmsman = await self.phone("Ava", "helmsman")
        liftmaster = await self.phone("Bo", "liftmaster")
        wingmaster = await self.phone("Cy", "wingmaster")
        seer = await self.phone("Dee", "seer")
        try:
            inputs = [
                (helmsman, {"t": "move", "role": "helmsman", "axis": "x", "value": 1, "seq": 3}),
                (liftmaster, {"t": "move", "role": "liftmaster", "axis": "y", "value": 1, "seq": 3}),
                (wingmaster, {"t": "move", "role": "wingmaster", "axis": "z", "value": 1, "seq": 3}),
                (seer, {"t": "sense", "role": "seer", "scan": 1, "seq": 3}),
            ]
            for socket, message in inputs:
                await socket.send(json.dumps(message))
                self.assertEqual(json.loads(await socket.recv())["t"], "input_ok")
            await asyncio.sleep(0.03)
            controls = [message for message in self.host_inputs if message["t"] in {"move", "sense"}]
            self.assertEqual({message["role"] for message in controls}, {"helmsman", "liftmaster", "wingmaster", "seer"})
            self.assertEqual(len(self.session.players), 4, "the relay's roster tells the game who holds each role")

            self.session.step(0.25, now=0.25)
            fly = self.session.state.fly
            self.assertGreater(fly.x, 0.0)
            self.assertGreater(fly.y, 0.0)
            self.assertGreater(fly.z, 0.0)

            seer_view = self.session.phone_views()[-1]
            await self.host.send_phone_view(seer_view)
            self.assertEqual(json.loads(await seer.recv())["t"], "seer_view")
            for socket in (helmsman, liftmaster, wingmaster):
                with self.assertRaises(asyncio.TimeoutError):
                    await asyncio.wait_for(socket.recv(), timeout=0.03)
        finally:
            await asyncio.gather(*(socket.close() for socket in (helmsman, liftmaster, wingmaster, seer)))


if __name__ == "__main__":
    unittest.main()
