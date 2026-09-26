"""Game-server host connection to Ved's controller relay."""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable
from typing import Any

from websockets.client import connect


class RelayClient:
    def __init__(self, url: str, room: str, secret: str = "") -> None:
        self.url, self.room, self.secret = url, room, secret
        self.websocket: Any | None = None
        self.sequence = 0

    def _message(self, payload: dict[str, Any]) -> str:
        self.sequence += 1
        return json.dumps({**payload, "seq": self.sequence})

    async def connect(self) -> None:
        self.websocket = await connect(self.url)
        await self.websocket.send(self._message({"t": "host_join", "room": self.room, "secret": self.secret}))
        reply = json.loads(await self.websocket.recv())
        if reply.get("t") != "host_joined":
            raise RuntimeError(f"Relay host join failed: {reply}")

    async def receive_forever(self, on_input: Callable[[dict[str, Any]], Awaitable[None]]) -> None:
        if self.websocket is None:
            raise RuntimeError("connect before receiving")
        async for raw in self.websocket:
            message = json.loads(raw)
            if message.get("t") in {"move", "sense", "input_cleared"}:
                await on_input(message)

    async def send_phone_view(self, view: dict[str, Any]) -> None:
        if self.websocket is not None:
            await self.websocket.send(self._message({"t": "phone_view", "view": view}))

    async def close(self) -> None:
        if self.websocket is not None:
            await self.websocket.close()
            self.websocket = None
