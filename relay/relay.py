"""WebSocket relay for the four-phone His Royal Flyness controller platform.

The relay owns rooms, role assignment, reconnect identity, input validation, and
role-filtered routing.  It never simulates the fly or renders the game: the
Python game server is authoritative and the Godot host is the only full game
display.
"""

from __future__ import annotations

import asyncio
import json
import os
import re
import time
import uuid
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any

from websockets.server import WebSocketServerProtocol, serve


ROLES = ("helmsman", "liftmaster", "wingmaster", "seer")
ROLE_AXES = {"helmsman": "x", "liftmaster": "y", "wingmaster": "z"}
ROOM_RE = re.compile(r"^[BCDFGHJKLMNPQRSTVWXYZ]{4}$")
STALE_AFTER_SECONDS = 1.2


class RelayError(ValueError):
    """A client-visible protocol error."""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message

    def payload(self) -> dict[str, str]:
        return {"t": "error", "code": self.code, "message": self.message}


@dataclass
class ClientSession:
    connection_id: str
    websocket: WebSocketServerProtocol | None = None
    room_code: str | None = None
    client_id: str | None = None
    name: str | None = None
    role: str | None = None
    is_host: bool = False
    last_seq: int = -1
    last_seen: float = field(default_factory=time.monotonic)
    held_input: int = 0


@dataclass
class Room:
    code: str
    host_connection_id: str | None = None
    role_connections: dict[str, str] = field(default_factory=dict)
    saved_roles: dict[str, str] = field(default_factory=dict)


class RelayState:
    """In-memory relay state, kept independent from WebSockets for testability."""

    def __init__(self, room_secret: str = "") -> None:
        self.room_secret = room_secret
        self.clients: dict[str, ClientSession] = {}
        self.rooms: dict[str, Room] = {}

    def connect(self, connection_id: str | None = None) -> ClientSession:
        connection_id = connection_id or str(uuid.uuid4())
        if connection_id in self.clients:
            raise RelayError("DUPLICATE_CONNECTION", "Connection is already registered.")
        session = ClientSession(connection_id=connection_id)
        self.clients[connection_id] = session
        return session

    def disconnect(self, connection_id: str) -> list[dict[str, Any]]:
        session = self.clients.pop(connection_id, None)
        if session is None:
            return []
        events: list[dict[str, Any]] = []
        if session.room_code is None:
            return events
        room = self.rooms.get(session.room_code)
        if room is None:
            return events
        if session.is_host and room.host_connection_id == connection_id:
            room.host_connection_id = None
        if session.role and room.role_connections.get(session.role) == connection_id:
            del room.role_connections[session.role]
            session.held_input = 0
            events.append({"to": "host", "payload": {"t": "input_cleared", "role": session.role}})
        return events

    def handle(self, connection_id: str, payload: dict[str, Any], now: float | None = None) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        session = self._session(connection_id)
        now = time.monotonic() if now is None else now
        self._validate_sequence(session, payload)
        session.last_seen = now
        message_type = payload.get("t")
        if message_type == "host_join":
            return self._host_join(session, payload), []
        if message_type == "join":
            return self._join(session, payload), []
        if message_type == "pick":
            return self._pick(session, payload), []
        if message_type == "heartbeat":
            self._require_phone(session)
            return {"t": "heartbeat_ok"}, []
        if message_type == "move":
            return self._move(session, payload), [self._host_event(session, payload)]
        if message_type == "sense":
            return self._sense(session, payload), [self._host_event(session, payload)]
        if message_type == "phone_view":
            return self._host_phone_view(session, payload)
        raise RelayError("UNKNOWN_MESSAGE", "Unsupported message type.")

    def expire_stale_inputs(self, now: float | None = None) -> list[dict[str, Any]]:
        now = time.monotonic() if now is None else now
        events: list[dict[str, Any]] = []
        for session in self.clients.values():
            if session.is_host or session.role is None or session.held_input == 0:
                continue
            if now - session.last_seen > STALE_AFTER_SECONDS:
                session.held_input = 0
                events.append(self._host_event(session, {"t": "input_cleared", "role": session.role}))
        return events

    def recipients_for_view(self, room_code: str, payload: dict[str, Any]) -> list[str]:
        """Return phone connection ids allowed to receive one host-originated view."""
        room = self.rooms.get(room_code)
        if room is None:
            raise RelayError("UNKNOWN_ROOM", "Room does not exist.")
        message_type = payload.get("t")
        if message_type == "seer_view":
            seer = room.role_connections.get("seer")
            return [seer] if seer else []
        role = payload.get("role")
        if message_type == "control_view" and role in ROLE_AXES:
            target = room.role_connections.get(role)
            return [target] if target else []
        if message_type in {"phase", "error", "fx"}:
            return list(room.role_connections.values())
        raise RelayError("FORBIDDEN_ROUTE", "This view cannot be routed to phones.")

    def _host_join(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        room_code = self._room_code(payload.get("room"))
        if self.room_secret and payload.get("secret") != self.room_secret:
            raise RelayError("HOST_AUTH_FAILED", "Host authentication failed.")
        room = self.rooms.setdefault(room_code, Room(code=room_code))
        if room.host_connection_id not in {None, session.connection_id}:
            raise RelayError("HOST_EXISTS", "This room already has a host.")
        session.room_code = room_code
        session.is_host = True
        room.host_connection_id = session.connection_id
        return {"t": "host_joined", "room": room_code}

    def _join(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        if session.is_host:
            raise RelayError("HOST_CANNOT_JOIN", "A host cannot join as a phone.")
        room_code = self._room_code(payload.get("room"))
        client_id = payload.get("clientId")
        name = payload.get("name")
        if not isinstance(client_id, str) or not 1 <= len(client_id) <= 128:
            raise RelayError("INVALID_CLIENT_ID", "clientId must be a short non-empty string.")
        if not isinstance(name, str) or not 1 <= len(name.strip()) <= 32:
            raise RelayError("INVALID_NAME", "Name must contain 1 to 32 characters.")
        room = self.rooms.setdefault(room_code, Room(code=room_code))
        if session.room_code is None and self._phone_count(room_code) >= len(ROLES):
            raise RelayError("ROOM_FULL", "This royal court is full.")
        session.room_code = room_code
        session.client_id = client_id
        session.name = name.strip()
        restored_role = room.saved_roles.get(client_id)
        if restored_role and restored_role not in room.role_connections:
            session.role = restored_role
            room.role_connections[restored_role] = session.connection_id
            return {"t": "assigned", "room": room_code, "role": restored_role, "name": session.name, "restored": True}
        return {"t": "joined", "room": room_code, "name": session.name, "roles": self._available_roles(room)}

    def _pick(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        self._require_phone(session)
        role = payload.get("role")
        if role not in ROLES:
            raise RelayError("INVALID_ROLE", "Choose a valid royal role.")
        room = self._room(session)
        if session.role == role:
            return {"t": "assigned", "room": room.code, "role": role, "name": session.name, "restored": False}
        if role in room.role_connections:
            raise RelayError("ROLE_TAKEN", "That royal role is already filled.")
        if session.role and room.role_connections.get(session.role) == session.connection_id:
            del room.role_connections[session.role]
        session.role = role
        room.role_connections[role] = session.connection_id
        assert session.client_id is not None
        room.saved_roles[session.client_id] = role
        return {"t": "assigned", "room": room.code, "role": role, "name": session.name, "restored": False}

    def _move(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        self._require_phone(session)
        if session.role not in ROLE_AXES:
            raise RelayError("FORBIDDEN_CONTROL", "Only movement roles may send movement input.")
        if payload.get("role") != session.role or payload.get("axis") != ROLE_AXES[session.role]:
            raise RelayError("FORBIDDEN_CONTROL", "A role may only control its assigned axis.")
        value = payload.get("value")
        if value not in {-1, 0, 1}:
            raise RelayError("INVALID_INPUT", "Movement value must be -1, 0, or 1.")
        session.held_input = value
        return {"t": "input_ok", "role": session.role, "axis": payload["axis"], "value": value}

    def _sense(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        self._require_phone(session)
        if session.role != "seer" or payload.get("role") != "seer":
            raise RelayError("FORBIDDEN_CONTROL", "Only the Royal Seer may scan.")
        scan = payload.get("scan")
        if scan not in {0, 1}:
            raise RelayError("INVALID_INPUT", "scan must be 0 or 1.")
        session.held_input = scan
        return {"t": "input_ok", "role": "seer", "scan": scan}

    def _host_phone_view(self, session: ClientSession, payload: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        if not session.is_host:
            raise RelayError("HOST_ONLY", "Only the game server may send phone views.")
        room = self._room(session)
        view = payload.get("view")
        if not isinstance(view, dict):
            raise RelayError("INVALID_MESSAGE", "phone_view requires a view object.")
        recipients = self.recipients_for_view(room.code, view)
        return {"t": "view_accepted", "recipients": len(recipients)}, [{"to": recipient, "payload": view} for recipient in recipients]

    def _host_event(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        room = self._room(session)
        return {"to": "host", "room": room.code, "payload": payload}

    def _available_roles(self, room: Room) -> list[str]:
        return [role for role in ROLES if role not in room.role_connections]

    def _phone_count(self, room_code: str) -> int:
        return sum(
            1
            for session in self.clients.values()
            if not session.is_host and session.room_code == room_code
        )

    def _session(self, connection_id: str) -> ClientSession:
        try:
            return self.clients[connection_id]
        except KeyError as exc:
            raise RelayError("UNKNOWN_CONNECTION", "Connection is not registered.") from exc

    def _room(self, session: ClientSession) -> Room:
        if session.room_code is None or session.room_code not in self.rooms:
            raise RelayError("NOT_JOINED", "Join a room first.")
        return self.rooms[session.room_code]

    def _require_phone(self, session: ClientSession) -> None:
        if session.is_host or session.room_code is None or session.client_id is None:
            raise RelayError("NOT_JOINED", "Join as a phone first.")

    @staticmethod
    def _room_code(value: Any) -> str:
        if not isinstance(value, str):
            raise RelayError("INVALID_ROOM", "Room code must be four consonants.")
        room_code = value.upper()
        if not ROOM_RE.fullmatch(room_code):
            raise RelayError("INVALID_ROOM", "Room code must be four consonants.")
        return room_code

    @staticmethod
    def _validate_sequence(session: ClientSession, payload: dict[str, Any]) -> None:
        seq = payload.get("seq")
        if not isinstance(seq, int) or seq < 0:
            raise RelayError("INVALID_SEQUENCE", "seq must be a non-negative integer.")
        if seq <= session.last_seq:
            raise RelayError("STALE_SEQUENCE", "Message sequence is stale.")
        session.last_seq = seq


class RelayServer:
    """Network wrapper around RelayState."""

    def __init__(self, state: RelayState) -> None:
        self.state = state
        self.sockets: dict[str, WebSocketServerProtocol] = {}

    async def handler(self, websocket: WebSocketServerProtocol) -> None:
        session = self.state.connect()
        self.sockets[session.connection_id] = websocket
        try:
            async for raw_message in websocket:
                try:
                    payload = json.loads(raw_message)
                    if not isinstance(payload, dict):
                        raise RelayError("INVALID_MESSAGE", "Message must be a JSON object.")
                    response, events = self.state.handle(session.connection_id, payload)
                    await websocket.send(json.dumps(response))
                    await self._deliver(events)
                except (json.JSONDecodeError, RelayError) as exc:
                    error = exc.payload() if isinstance(exc, RelayError) else {"t": "error", "code": "INVALID_JSON", "message": "Message must be valid JSON."}
                    await websocket.send(json.dumps(error))
        finally:
            events = self.state.disconnect(session.connection_id)
            self.sockets.pop(session.connection_id, None)
            await self._deliver(events)

    async def watchdog(self) -> None:
        while True:
            await asyncio.sleep(0.25)
            await self._deliver(self.state.expire_stale_inputs())

    async def _deliver(self, events: list[dict[str, Any]]) -> None:
        for event in events:
            target = event["to"]
            if target == "host":
                room = self.state.rooms.get(event.get("room"))
                connection_id = room.host_connection_id if room else None
            else:
                connection_id = target
            websocket = self.sockets.get(connection_id) if connection_id else None
            if websocket is not None:
                await websocket.send(json.dumps(event["payload"]))


async def run(host: str = "0.0.0.0", port: int = 8080) -> None:
    state = RelayState(room_secret=os.getenv("ROOM_SECRET", ""))
    relay = RelayServer(state)
    async with serve(relay.handler, host, port):
        await relay.watchdog()


if __name__ == "__main__":
    asyncio.run(run(port=int(os.getenv("RELAY_PORT", "8080"))))
