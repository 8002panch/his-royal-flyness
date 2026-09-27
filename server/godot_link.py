"""Local WebSocket broadcaster for Godot's renderer-only state feed."""

from __future__ import annotations

import asyncio
import json
from typing import Any

from websockets.server import WebSocketServerProtocol, serve


class GodotLink:
    """30 Hz state out to every local screen (Godot, the browser host screen). Screens decide nothing, but the host screen may
    send lobby commands back ({"t": "host_command", ...}: new code, lock, remove a player), which on_command handles.
    It listens on 127.0.0.1 only, so only this laptop can send them."""

    def __init__(self) -> None:
        self.on_command = None  # async callable(dict), set by the launcher
        self.clients: set[WebSocketServerProtocol] = set()
        self._busy: set[WebSocketServerProtocol] = set()

    async def handler(self, websocket: WebSocketServerProtocol) -> None:
        self.clients.add(websocket)
        try:
            async for raw in websocket:
                try:
                    message = json.loads(raw)
                except (TypeError, ValueError):
                    continue
                if isinstance(message, dict) and message.get("t") == "host_command" and self.on_command is not None:
                    await self.on_command(message)
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

    async def publish_event(self, event: dict[str, Any]) -> None:
        """An event (a voice line, a dodge): unlike state frames it isn't skipped for a busy screen, only timed out."""
        encoded = json.dumps(event, separators=(",", ":"))
        for client in tuple(self.clients):
            if client.open:
                asyncio.create_task(self._send_event(client, encoded))

    async def _send_event(self, client: WebSocketServerProtocol, encoded: str) -> None:
        try:
            await asyncio.wait_for(client.send(encoded), 2.0)
        except Exception:
            pass

    async def _send(self, client: WebSocketServerProtocol, encoded: str) -> None:
        try:
            await asyncio.wait_for(client.send(encoded), 1.0)
        except Exception:
            pass
        finally:
            self._busy.discard(client)

    def serve(self, host: str = "127.0.0.1", port: int = 8765):
        return serve(self.handler, host, port)
