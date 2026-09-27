"""Local WebSocket broadcaster for Godot's renderer-only state feed."""

from __future__ import annotations

import asyncio
import json
from typing import Any

from websockets.server import WebSocketServerProtocol, serve


class GodotLink:
    def __init__(self) -> None:
        self.clients: set[WebSocketServerProtocol] = set()
        self._busy: set[WebSocketServerProtocol] = set()

    async def handler(self, websocket: WebSocketServerProtocol) -> None:
        self.clients.add(websocket)
        try:
            async for _ in websocket:
                pass  # Godot is renderer-only in this phase.
        finally:
            self.clients.discard(websocket)

    async def publish(self, state: dict[str, Any]) -> None:
        """Send a frame to every screen without waiting on any of them: a browser tab in the background (or a frozen Godot)
        must never stall the game loop. A screen that can't take a frame in time just misses it."""
        encoded = json.dumps(state, separators=(",", ":"))
        for client in tuple(self.clients):
            if not client.open:
                self.clients.discard(client)
                continue
            if client in self._busy:
                continue  # still sending its previous frame: skip this one rather than queue up
            self._busy.add(client)
            asyncio.create_task(self._send(client, encoded))

    async def _send(self, client: WebSocketServerProtocol, encoded: str) -> None:
        try:
            await asyncio.wait_for(client.send(encoded), 1.0)
        except Exception:
            pass
        finally:
            self._busy.discard(client)

    def serve(self, host: str = "127.0.0.1", port: int = 8765):
        return serve(self.handler, host, port)
