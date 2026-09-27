"""Game-server host connection to Ved's controller relay."""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable
from typing import Any

from websockets.client import connect
from websockets.exceptions import ConnectionClosed


class RelayClient:
    def __init__(self, url: str, room: str, secret: str = "") -> None:
        self.url, self.room, self.secret = url, room, secret
        self.websocket: Any | None = None
        self.sequence = 0

    def _message(self, payload: dict[str, Any]) -> str:
        self.sequence += 1
        return json.dumps({**payload, "seq": self.sequence})

    @property
    def connected(self) -> bool:
        return self.websocket is not None

    async def connect(self) -> None:
        self.sequence = 0  # a new connection starts a new sequence at the relay
        websocket = await connect(self.url, ping_interval=5, ping_timeout=5, close_timeout=2)  # notice a dead relay in ~10 s
        await websocket.send(self._message({"t": "host_join", "room": self.room, "secret": self.secret}))
        reply = json.loads(await websocket.recv())
        if reply.get("t") != "host_joined":
            await websocket.close()
            raise RuntimeError(f"Relay host join failed: {reply}")
        self.websocket = websocket

    async def receive_forever(self, on_input: Callable[[dict[str, Any]], Awaitable[None]]) -> None:
        if self.websocket is None:
            raise RuntimeError("connect before receiving")
        async for raw in self.websocket:
            message = json.loads(raw)
            if message.get("t") in {"move", "sense", "input_cleared", "roster"}:
                await on_input(message)

    async def send_phone_view(self, view: dict[str, Any]) -> None:
        if self.websocket is None:
            return  # between reconnects: phones simply miss a few feedback frames
        try:
            await self.websocket.send(self._message({"t": "phone_view", "view": view}))
        except ConnectionClosed:
            self.websocket = None

    async def close(self) -> None:
        websocket, self.websocket = self.websocket, None
        if websocket is not None:
            try:
                await websocket.close()
            except Exception:  # already broken: nothing to close cleanly
                pass
