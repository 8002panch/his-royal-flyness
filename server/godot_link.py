"""Local WebSocket broadcaster for Godot's renderer-only state feed."""

from __future__ import annotations

import json
from typing import Any

from websockets.server import WebSocketServerProtocol, serve


class GodotLink:
    def __init__(self) -> None:
        self.clients: set[WebSocketServerProtocol] = set()

    async def handler(self, websocket: WebSocketServerProtocol) -> None:
        self.clients.add(websocket)
        try:
            async for _ in websocket:
                pass  # Godot is renderer-only in this phase.
        finally:
            self.clients.discard(websocket)

    async def publish(self, state: dict[str, Any]) -> None:
        encoded = json.dumps(state, separators=(",", ":"))
        for client in tuple(self.clients):
            try:
                await client.send(encoded)
            except Exception:
                self.clients.discard(client)

    def serve(self, host: str = "127.0.0.1", port: int = 8765):
        return serve(self.handler, host, port)
