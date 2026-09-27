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

from websockets.exceptions import ConnectionClosed
from websockets.server import WebSocketServerProtocol, serve


ROLES = ("helmsman", "liftmaster", "wingmaster", "seer")
ROLE_AXES = {"helmsman": "x", "liftmaster": "y", "wingmaster": "z"}
ROOM_RE = re.compile(r"^[BCDFGHJKLMNPQRSTVWXYZ]{4}$")
STALE_AFTER_SECONDS = 1.2
MAX_ROOM_CONNECTIONS = 16  # phones in one room, seated or waiting; only a guard against abuse, never the seat limit
HOST_GRACE_S = 30.0        # a room stays joinable this long after its game server drops (it usually reconnects in ~1 s)
SEND_TIMEOUT_S = 2.0       # a message a phone can't take within this is dropped (it's 10 Hz feedback; the next one follows)
# Keepalive: a phone that went to sleep or lost Wi-Fi stops answering pings; notice it within ~10 s (not ~40 s) so its seat
# frees up, and don't wait long for a close handshake it will never finish. Used by run() and run_local.py.
SERVE_OPTIONS = {"ping_interval": 5, "ping_timeout": 5, "close_timeout": 2}


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
    locked: bool = False                              # Kahoot-style lock: only phones that already joined may (re)join
    members: set[str] = field(default_factory=set)    # clientIds that have joined this room
    banned: set[str] = field(default_factory=set)     # clientIds the host removed
    host_left_at: float | None = None


class RelayState:
    """In-memory relay state, kept independent from WebSockets for testability."""

    def __init__(self, room_secret: str = "", require_host: bool = False) -> None:
        """`require_host`: a code only works while a game server hosts that room (Jackbox/Kahoot style), so a phone with an
        old code hears "no game with that code" instead of waiting in an empty room. The live relay turns it on."""
        self.room_secret = room_secret
        self.require_host = require_host
        self.clients: dict[str, ClientSession] = {}
        self.rooms: dict[str, Room] = {}
        self._moved_seats: list[dict[str, Any]] = []

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
            room.host_left_at = time.monotonic()
        if session.role and room.role_connections.get(session.role) == connection_id:
            del room.role_connections[session.role]
            session.held_input = 0
            events.append({"to": "host", "room": room.code, "payload": {"t": "input_cleared", "role": session.role}})
            events.extend(self._seat_events(room))
        return events

    def handle(self, connection_id: str, payload: dict[str, Any], now: float | None = None) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        session = self._session(connection_id)
        now = time.monotonic() if now is None else now
        self._validate_sequence(session, payload)
        session.last_seen = now
        message_type = payload.get("t")
        if message_type == "host_join":
            response = self._host_join(session, payload)
            return response, [self._roster_event(self._room(session))]  # a (re)connecting game server learns who is here
        if message_type == "join":
            response = self._join(session, payload)
            moved, self._moved_seats = self._moved_seats, []
            return response, moved + (self._seat_events(self._room(session)) if response["t"] == "assigned" else [])
        if message_type == "pick":
            return self._pick(session, payload), self._seat_events(self._room(session))
        if message_type == "heartbeat":
            self._require_phone(session)
            return {"t": "heartbeat_ok"}, []
        if message_type == "move":
            return self._move(session, payload), [self._host_event(session, payload)]
        if message_type == "sense":
            return self._sense(session, payload), [self._host_event(session, payload)]
        if message_type == "answer":
            response = self._answer(session, payload)
            return response, [self._host_event(session, {"t": "answer", "role": "seer", "choice": response["choice"]})]
        if message_type == "phone_view":
            return self._host_phone_view(session, payload)
        if message_type in {"close_room", "lock", "kick"}:
            return self._host_command(session, payload)
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
        room.host_left_at = None
        return {"t": "host_joined", "room": room_code}

    def _room_is_live(self, room: Room | None) -> bool:
        if room is None:
            return False
        if room.host_connection_id is not None:
            return True
        return room.host_left_at is not None and time.monotonic() - room.host_left_at < HOST_GRACE_S

    def _host_command(self, session: ClientSession, payload: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        """The game server closes its room (new code), locks it, or removes a player (Kahoot-style lobby controls)."""
        if not session.is_host:
            raise RelayError("HOST_ONLY", "Only the game server may do that.")
        room = self._room(session)
        kind = payload.get("t")
        if kind == "lock":
            room.locked = bool(payload.get("locked", True))
            return {"t": "lock_ok", "locked": room.locked}, [self._roster_event(room)]
        if kind == "kick":
            role = payload.get("role")
            connection_id = room.role_connections.get(role) if role in ROLES else None
            target = self.clients.get(connection_id) if connection_id else None
            if target is None:
                return {"t": "kick_ok", "role": role, "removed": False}, []
            del room.role_connections[role]
            if target.client_id:
                room.banned.add(target.client_id)
                room.saved_roles.pop(target.client_id, None)
            target.role, target.room_code, target.held_input = None, None, 0
            events = [{"to": connection_id, "payload": {"t": "kicked"}},
                      {"to": "host", "room": room.code, "payload": {"t": "input_cleared", "role": role}}]
            return {"t": "kick_ok", "role": role, "removed": True}, events + self._seat_events(room)
        # close_room: the game moved to a new code; every phone here is told, and the old code stops working at once
        events = []
        for connection_id, client in self.clients.items():
            if client.room_code == room.code and not client.is_host:
                events.append({"to": connection_id, "payload": {"t": "room_closed"}})
                client.role, client.room_code, client.held_input = None, None, 0
        del self.rooms[room.code]
        session.room_code, session.is_host = None, False
        return {"t": "room_closed_ok"}, events

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
        if self.require_host and not self._room_is_live(self.rooms.get(room_code)):
            raise RelayError("ROOM_NOT_FOUND", "No game with that code right now. Check the code on the main screen.")
        room = self.rooms.setdefault(room_code, Room(code=room_code))
        if client_id in room.banned:
            raise RelayError("REMOVED", "The host removed you from this court.")
        if room.locked and client_id not in room.members:
            raise RelayError("ROOM_LOCKED", "This court is locked. Ask the host to unlock it.")
        wanted = name.strip().casefold()
        if any(other is not session and other.room_code == room_code and not other.is_host and other.client_id != client_id
               and (other.name or "").casefold() == wanted for other in self.clients.values()):
            raise RelayError("NAME_TAKEN", "Someone in this court already has that name. Pick another.")
        # Seats, not connections, decide who can play: phones waiting on the picker, a second tab, or a dead connection from a
        # phone that went to sleep must never make the court look full while a role is free.
        if session.room_code is None and self._phone_count(room_code) >= MAX_ROOM_CONNECTIONS:
            raise RelayError("ROOM_FULL", "Too many phones in this room.")
        session.room_code = room_code
        session.client_id = client_id
        session.name = name.strip()
        room.members.add(client_id)
        restored_role = room.saved_roles.get(client_id)
        if restored_role is None and payload.get("role") in ROLES:
            # the phone remembers its last role; after a relay restart the relay has no record, so honor the request if free
            restored_role = payload["role"]
        if restored_role:
            self._release_stale_seat(room, restored_role, client_id, session.connection_id)
        if restored_role and restored_role not in room.role_connections:
            session.role = restored_role
            room.role_connections[restored_role] = session.connection_id
            room.saved_roles[client_id] = restored_role
            return {"t": "assigned", "room": room_code, "role": restored_role, "name": session.name, "restored": True}
        return {"t": "joined", "room": room_code, "name": session.name, "roles": self._available_roles(room)}

    def _release_stale_seat(self, room: Room, role: str, client_id: str, new_connection_id: str) -> None:
        """If this same phone (clientId) still holds the role on an older connection (a page it reloaded, or a socket that died
        when the phone slept and hasn't timed out yet), hand the role to the new connection."""
        holder_id = room.role_connections.get(role)
        holder = self.clients.get(holder_id) if holder_id else None
        if holder is not None and holder_id != new_connection_id and holder.client_id == client_id:
            del room.role_connections[role]
            holder.role = None
            holder.held_input = 0
            # if that older page is actually still open (a second tab), tell it, so it doesn't keep showing controls
            self._moved_seats.append({"to": holder_id, "payload": {"t": "seat_moved", "role": role}})

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

    def _answer(self, session: ClientSession, payload: dict[str, Any]) -> dict[str, Any]:
        """A quiz answer (docs/GAME.md: only the current Seer answers, after the council discusses it)."""
        self._require_phone(session)
        if session.role != "seer":
            raise RelayError("FORBIDDEN_CONTROL", "Only the Royal Seer may answer.")
        choice = payload.get("choice")
        if choice not in {"A", "B"}:
            raise RelayError("INVALID_INPUT", "choice must be A or B.")
        return {"t": "answer_ok", "choice": choice}

    def _host_phone_view(self, session: ClientSession, payload: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        if not session.is_host:
            raise RelayError("HOST_ONLY", "Only the game server may send phone views.")
        room = self._room(session)
        view = payload.get("view")
        if not isinstance(view, dict):
            raise RelayError("INVALID_MESSAGE", "phone_view requires a view object.")
        recipients = self.recipients_for_view(room.code, view)
        return {"t": "view_accepted", "recipients": len(recipients)}, [{"to": recipient, "payload": view} for recipient in recipients]

    def _seat_events(self, room: Room) -> list[dict[str, Any]]:
        """After any seat change: the roster for the game server, and the open roles for every phone still choosing."""
        events = [self._roster_event(room)]
        open_roles = self._available_roles(room)
        for cid, client in self.clients.items():
            if client.room_code == room.code and not client.is_host and client.role is None and client.client_id is not None:
                events.append({"to": cid, "payload": {"t": "roles", "roles": open_roles}})
        return events

    def _roster_event(self, room: Room) -> dict[str, Any]:
        """Who holds which role, for the game server's host screens (names only; sent on every change)."""
        players = [{"name": self.clients[cid].name or "?", "role": role}
                   for role, cid in room.role_connections.items() if cid in self.clients]
        return {"to": "host", "room": room.code, "payload": {"t": "roster", "players": players, "locked": room.locked}}

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
        self._sends: set[asyncio.Task] = set()

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
                    # The reply and the resulting updates each go out on their own (in this order), so a sender whose
                    # connection is already closing (a game server switching to a new code, a phone that just locked)
                    # can't block or cancel everyone else's updates.
                    self._send_later(websocket, json.dumps(response))
                    await self._deliver(events)
                except (json.JSONDecodeError, RelayError) as exc:
                    error = exc.payload() if isinstance(exc, RelayError) else {"t": "error", "code": "INVALID_JSON", "message": "Message must be valid JSON."}
                    self._send_later(websocket, json.dumps(error))
        except ConnectionClosed:
            pass  # phones vanish without a close frame all the time (lock screen, Wi-Fi); cleanup below handles it
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
                # Never wait on one recipient: a phone that just went to sleep can make a send hang for ~10 s while its
                # connection closes, and that used to stall everyone's feedback and the game server behind it.
                self._send_later(websocket, json.dumps(event["payload"]))

    def _send_later(self, websocket: WebSocketServerProtocol, data: str) -> None:
        """Queue one message; tasks start in creation order, so each connection still gets its messages in order."""
        if not websocket.open:
            return
        task = asyncio.create_task(self._send_quietly(websocket, data))
        self._sends.add(task)
        task.add_done_callback(self._sends.discard)

    @staticmethod
    async def _send_quietly(websocket: WebSocketServerProtocol, data: str) -> None:
        try:
            await asyncio.wait_for(websocket.send(data), SEND_TIMEOUT_S)
        except (ConnectionClosed, asyncio.TimeoutError):
            pass  # closing or too slow: its own handler cleans up; feedback is sent again next tick


async def run(host: str = "0.0.0.0", port: int = 8080) -> None:
    state = RelayState(room_secret=os.getenv("ROOM_SECRET", ""), require_host=True)
    relay = RelayServer(state)
    async with serve(relay.handler, host, port, **SERVE_OPTIONS):
        await relay.watchdog()


if __name__ == "__main__":
    # Behind Caddy on a server, set RELAY_HOST=127.0.0.1 so only Caddy's wss:// endpoint is public.
    asyncio.run(run(host=os.getenv("RELAY_HOST", "0.0.0.0"), port=int(os.getenv("RELAY_PORT", "8080"))))
