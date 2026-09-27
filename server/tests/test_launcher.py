from __future__ import annotations

import re
import unittest

from server.main import GameSession


class LauncherTests(unittest.TestCase):
    def test_godot_state_lists_the_players_for_the_host_screen(self) -> None:
        session = GameSession("BZKT")
        session.players = [{"name": "Ava", "role": "helmsman"}, {"name": "Dee", "role": "seer"}]
        session.step(0.02, now=0.02)
        self.assertEqual(session.godot_state()["players"], [{"name": "Ava", "role": "helmsman"}, {"name": "Dee", "role": "seer"}])

    def test_host_screen_qr_code_decodes_to_the_join_link(self) -> None:
        from run_local import qr_svg

        link = "http://192.168.1.23:8000/?room=BZKT"
        svg = qr_svg(link)
        if svg is None:
            self.skipTest("no QR library installed (qrcode or OpenCV)")
        try:
            import cv2
            import numpy as np
        except ImportError:
            self.skipTest("OpenCV is needed to decode the QR code")
        n = int(re.search(r'viewBox="0 0 (\d+) ', svg).group(1))
        image = np.full((n, n), 255, np.uint8)
        for x, y in re.findall(r"M(\d+) (\d+)h1", svg):
            image[int(y), int(x)] = 0
        image = cv2.resize(image, (n * 8, n * 8), interpolation=cv2.INTER_NEAREST)
        self.assertEqual(cv2.QRCodeDetector().detectAndDecode(image)[0], link)



class RelayReconnectTests(unittest.IsolatedAsyncioTestCase):
    async def test_game_server_survives_a_relay_restart(self) -> None:
        import asyncio
        import json

        from websockets.client import connect
        from websockets.server import serve

        from relay.relay import RelayServer, RelayState
        from server.main import GameServer
        from server.relay_client import RelayClient

        class NoGodot:
            async def publish(self, state) -> None:
                pass

        async def start_relay(port: int = 0):
            server = await serve(RelayServer(RelayState()).handler, "127.0.0.1", port)
            return server, server.sockets[0].getsockname()[1]

        async def phone(port: int, ask_role: bool) -> object:
            ws = await connect(f"ws://127.0.0.1:{port}")
            join = {"t": "join", "room": "BZKT", "name": "Ava", "clientId": "ava", "seq": 1, **({"role": "helmsman"} if ask_role else {})}
            await ws.send(json.dumps(join))
            if json.loads(await ws.recv())["t"] == "joined":
                await ws.send(json.dumps({"t": "pick", "role": "helmsman", "seq": 2}))
                await ws.recv()

            async def hold() -> None:  # like the phone page: resend the held button every 0.4 s
                for seq in range(3, 1000):
                    await ws.send(json.dumps({"t": "move", "role": "helmsman", "axis": "x", "value": 1, "seq": seq}))
                    await asyncio.sleep(0.4)

            ws.holding = asyncio.create_task(hold())
            return ws

        async def until(condition, timeout: float = 3.0) -> bool:
            for _ in range(int(timeout / 0.05)):
                if condition():
                    return True
                await asyncio.sleep(0.05)
            return False

        relay, port = await start_relay()
        session = GameSession("BZKT")
        game = asyncio.create_task(GameServer(session, RelayClient(f"ws://127.0.0.1:{port}", "BZKT"), NoGodot()).run())
        try:
            ws = await phone(port, ask_role=False)
            self.assertTrue(await until(lambda: session.state.inputs["helmsman"].value == 1 and len(session.players) == 1))
            ws.holding.cancel()
            await ws.close()
            relay.close()
            await relay.wait_closed()
            self.assertTrue(await until(lambda: session.players == [] and session.state.inputs["helmsman"].value == 0),
                            "a lost relay must clear the seats and held inputs")
            relay, _ = await start_relay(port)  # a restarted relay remembers nobody
            ws = await phone(port, ask_role=True)
            self.assertTrue(await until(lambda: session.players == [{"name": "Ava", "role": "helmsman"}]
                                        and session.state.inputs["helmsman"].value == 1), "reconnected and heard the phone again")
            ws.holding.cancel()
            await ws.close()
        finally:
            game.cancel()
            relay.close()
            await relay.wait_closed()



class JoinCodeTests(unittest.IsolatedAsyncioTestCase):
    def test_codes_are_four_consonants_and_never_repeat_back_to_back(self) -> None:
        from run_local import new_room_code

        codes = [new_room_code(avoid="BZKT") for _ in range(500)]
        self.assertTrue(all(re.fullmatch(r"[BCDFGHJKLMNPQRSTVWXZ]{4}", code) for code in codes))
        self.assertNotIn("BZKT", codes)
        self.assertGreater(len(set(codes)), 490, "codes should be spread over the 160,000 possibilities")

    async def test_new_code_closes_the_old_room_and_opens_the_new_one(self) -> None:
        import asyncio
        import json

        from websockets.client import connect
        from websockets.server import serve

        from relay.relay import RelayServer, RelayState
        from server.main import GameServer
        from server.relay_client import RelayClient

        class NoGodot:
            async def publish(self, state) -> None:
                pass

        relay_server = await serve(RelayServer(RelayState(require_host=True)).handler, "127.0.0.1", 0)
        url = f"ws://127.0.0.1:{relay_server.sockets[0].getsockname()[1]}"
        codes = iter(["QWRT"])
        session = GameSession("BZKT", join_url="http://laptop:8000/?room={room}")
        server = GameServer(session, RelayClient(url, "BZKT"), NoGodot(), new_code=lambda: next(codes))
        game = asyncio.create_task(server.run())

        async def join(code: str, client: str):
            ws = await connect(url)
            await ws.send(json.dumps({"t": "join", "room": code, "name": client, "clientId": client, "seq": 1}))
            return ws, json.loads(await ws.recv())

        try:
            for _ in range(40):
                if server.relay.connected:
                    break
                await asyncio.sleep(0.05)
            phone, reply = await join("BZKT", "ava")
            self.assertEqual(reply["t"], "joined")
            await server.handle_host_command({"command": "new_room"})
            self.assertEqual(json.loads(await asyncio.wait_for(phone.recv(), 2))["t"], "room_closed")
            self.assertEqual((session.state.room_code, session.join_url), ("QWRT", "http://laptop:8000/?room=QWRT"))
            for _ in range(40):
                if server.relay.connected and server.relay.room == "QWRT":
                    break
                await asyncio.sleep(0.05)
            await asyncio.sleep(0.1)
            _, old = await join("BZKT", "bo")
            _, new = await join("QWRT", "cy")
            self.assertEqual((old.get("code"), new["t"]), ("ROOM_NOT_FOUND", "joined"))
        finally:
            game.cancel()
            relay_server.close()
            await relay_server.wait_closed()


if __name__ == "__main__":
    unittest.main()
