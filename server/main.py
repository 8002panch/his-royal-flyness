"""Phase 3 authoritative movement server.

Run ``python -m server.main --room BZKT [--seer true|changeling|placeholder]`` after starting ``relay/relay.py``,
or start everything at once with ``python run_local.py``.
The server accepts role-scoped intent from the relay, advances deterministic body
state at 50 Hz, sends 30 Hz state to Godot, and supplies phone feedback at 10 Hz.
"""

from __future__ import annotations

import argparse
import asyncio
import os
import sys
import threading
import time
from typing import Any

from .campaign import Campaign
from .godot_link import GodotLink
from .movement import MovementSimulator, WallGate
from .relay_client import HostJoinError, RelayClient
from .seer_adapter import PlaceholderSeerAdapter, projected_stimuli
from .state import MOVEMENT_ROLES, RoomState


STALE_INPUT_SECONDS = 1.2
TICK_S = 1 / 50
GODOT_S = 1 / 30
PHONE_S = 1 / 10
SEER_SOURCES = ("true", "changeling", "placeholder")
# Distance at which the Princess fully drives the Seer's Princess detectors, set to this hall's scale (world units x 220 cm, so
# she is 10 to 540 cm away): NEAR within ~170 cm, MID to ~330 cm, FAR to ~530 cm (detection limit ~5x this). Retune for Phase 5's hall.
SEER_PRINCESS_FULL_CM = 100.0

# Part 2 Banquet Hall wall course. Godot mirrors these openings in
# host/scripts/court/hall_builder.gd.
COURSE_WALLS = (
    WallGate("left_gate", -0.50, -1.00, 0.25, -0.80, 0.80),
    WallGate("right_gate", -0.10, -0.25, 1.00, -0.80, 0.80),
    WallGate("low_gate", 0.35, -0.75, 0.75, -1.00, 0.15),
    WallGate("high_gate", 0.75, -0.75, 0.75, -0.15, 1.00),
)


def make_seer(source: str = "true") -> Any:
    """The brain-powered Seer (brain/seer.py) when its data files are present, else the deterministic placeholder.

    Both brains are loaded up front so the host's True Prince / Changeling toggle is instant during the demo.
    """
    if source == "placeholder":
        return PlaceholderSeerAdapter()
    try:
        from brain.seer import SeerAdapter

        seer = SeerAdapter(source, princess_full_cm=SEER_PRINCESS_FULL_CM)
        seer.swap("changeling" if source == "true" else "true")
        seer.swap(source)
        return seer
    except Exception as exc:  # missing data/ files or any brain failure: the game still runs
        print(f"[server] brain unavailable ({exc!r}); the Seer uses placeholder cues")
        return PlaceholderSeerAdapter()


class GameSession:
    """Pure authoritative game state; importable for headless replay and tests."""

    def __init__(self, room_code: str, seer: Any = None, join_url: str | None = None, campaign: bool = False) -> None:
        """`join_url` is the phone link shown with the room code; put `{room}` where the code goes so it follows a new code.
        `campaign`: run the story (server/campaign.py) instead of the free-flight test world (tests, replays, practice)."""
        self.state = RoomState(room_code=room_code)
        self.simulator = MovementSimulator(walls=COURSE_WALLS)
        self.seer = seer or PlaceholderSeerAdapter()
        self.join_url_template = join_url
        self.locked = False  # from the relay's roster
        # Tests and replays sense inside step() (exact and deterministic). The live server sets this False and runs the brain on
        # its own thread (GameServer), so a slow brain step never delays movement, the relay or the host screen.
        self.sense_in_step = True
        self._last_bump = -1.0
        self.seer_lock = threading.Lock()
        self.brain_steps = 0  # senses done by the brain thread (for the host's status line)
        self.players: list[dict[str, str]] = []  # [{"name", "role"}] for the host screens, from the relay's roster messages
        self.stimuli: dict[str, Any] | None = None
        self.cues: dict[str, Any] | None = None
        self.campaign = Campaign(self) if campaign else None
        self._phase_sent: dict[str, Any] | None = None
        self._phase_sent_at = -10.0
        self._qr: tuple[str, list[str]] | None = None

    def apply_input(self, message: dict[str, Any], now: float) -> None:
        kind, role = message.get("t"), message.get("role")
        if kind == "roster":  # from the relay whenever a phone takes or leaves a role
            self.locked = bool(message.get("locked", False))
            self.players = [{"name": str(p.get("name", "?"))[:32], "role": p["role"]}
                            for p in message.get("players", []) if isinstance(p, dict) and p.get("role") in self.state.inputs]
            return
        if kind == "input_cleared" and role in self.state.inputs:
            self.state.inputs[role].value = 0
            self.state.inputs[role].updated_at = now
            return
        if kind == "move" and role in MOVEMENT_ROLES:
            if message.get("axis") != MOVEMENT_ROLES[role] or message.get("value") not in {-1, 0, 1}:
                raise ValueError("Invalid movement message for assigned role.")
            self.state.inputs[role].value = int(message["value"])
            self.state.inputs[role].updated_at = now
            return
        if kind == "sense" and role == "seer" and message.get("scan") in {0, 1}:
            self.state.inputs[role].value = int(message["scan"])
            self.state.inputs[role].updated_at = now
            return
        if kind == "answer":  # a quiz answer: only the Seer's counts, and only once (the campaign checks both)
            if role != "seer" or message.get("choice") not in {"A", "B"}:
                raise ValueError("Only the Royal Seer can answer.")
            if self.campaign is not None:
                self.campaign.answer(str(message["choice"]))
            return
        raise ValueError("Unsupported relay input.")

    def step(self, dt: float, now: float) -> None:
        for input_state in self.state.inputs.values():
            if now - input_state.updated_at > STALE_INPUT_SECONDS:
                input_state.value = 0
        intents = {axis: self.state.inputs[role].value for role, axis in MOVEMENT_ROLES.items()}
        if self.campaign is None or self.campaign.flying:  # comics, quizzes and the count-in freeze the fly
            if self.campaign is not None:
                intents = self.campaign.steer(intents, dt)
            self.simulator.step(self.state.fly, intents, dt)
            if self.campaign is not None and self.simulator.bump >= 0.2 and self.state.elapsed_s - self._last_bump >= 0.4:
                self._last_bump = self.state.elapsed_s  # a wall hit: the screens thud (a solid wall, not a glitch)
                self.campaign.events.append({"t": "event", "kind": "bump", "speed": round(self.simulator.bump, 2)})
        self.state.elapsed_s += dt
        fly = self.state.fly
        if self.campaign is not None:
            self.campaign.step(dt)
            self.stimuli = self.campaign.stimuli()
        else:
            self.stimuli = projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        if self.sense_in_step:
            self._sense()

    @property
    def join_url(self) -> str | None:
        template = self.join_url_template
        return template.replace("{room}", self.state.room_code) if template else None

    def _sense(self) -> dict[str, Any]:
        """Sense once per tick; the Seer's phone view and Godot's brainActivity both reuse these cues."""
        if self.stimuli is None:
            fly = self.state.fly
            self.stimuli = projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        with self.seer_lock:
            self.cues = self.seer.sense(self.stimuli)
        return self.cues

    def set_brain(self, source: str, seed: int = 0) -> str:
        """Host toggle between the True Prince, the Changeling and placeholder cues; returns the source now in use."""
        if source not in SEER_SOURCES:
            raise ValueError(f"source must be one of {SEER_SOURCES}")
        swap = getattr(self.seer, "swap", None)
        if swap is not None:
            with self.seer_lock:
                swap(source, seed)
                self.cues = None
        return self.seer.source

    def phone_views(self) -> list[dict[str, Any]]:
        fly = self.state.fly
        views = [
            {"t": "control_view", "role": "helmsman", "actualX": round(fly.x, 3), "momentum": round(fly.vx, 3)},
            {"t": "control_view", "role": "liftmaster", "altitude": round(fly.y, 3), "verticalVelocity": round(fly.vy, 3)},
            {"t": "control_view", "role": "wingmaster", "speed": round(fly.vz, 3), "braking": self.state.inputs["wingmaster"].value < 0},
        ]
        guide = self.campaign.guide() if self.campaign is not None else {}
        if guide:  # tutorial coaching on each mover's phone: "Grape: steer right", "Chalice: lined up"
            words = {"x": {"right": "steer right", "left": "steer left"}, "y": {"up": "climb", "down": "descend"},
                     "z": {"forward": "fly forward", "back": "brake / back up"}}
            for view, axis in zip(views, ("x", "y", "z")):
                view["tip"] = f"{guide['goal'].capitalize()}: " + words[axis].get(guide[axis], "lined up")
        if self.state.inputs["seer"].value:
            cues = self.cues if self.cues is not None else (self._sense() if self.sense_in_step else None)
            if cues is not None:
                views.append(self.seer.to_phone_view(cues))
        if self.campaign is not None:  # every phone's screen mode: on a change, and once a second for phones that rejoin
            phase = self.campaign.phone_phase()
            if phase != self._phase_sent or self.state.elapsed_s - self._phase_sent_at >= 1.0:
                self._phase_sent, self._phase_sent_at = phase, self.state.elapsed_s
                views.append(phase)
        return views

    def join_qr(self) -> list[str] | None:
        """The join link as QR rows ("1" = dark), for the Godot lobby; None without a link or the qrcode package."""
        url = self.join_url
        if not url:
            return None
        if self._qr is None or self._qr[0] != url:
            try:
                import qrcode

                qr = qrcode.QRCode(border=0, error_correction=qrcode.constants.ERROR_CORRECT_M)
                qr.add_data(url)
                qr.make(fit=True)
                self._qr = (url, ["".join("1" if cell else "0" for cell in row) for row in qr.get_matrix()])
            except Exception:
                self._qr = (url, [])
        return self._qr[1] or None

    def godot_state(self) -> dict[str, Any]:
        fly = self.state.fly
        stimuli = self.stimuli or projected_stimuli(fly.x, fly.y, fly.z, self.state.elapsed_s)
        cues = self.cues or {}
        # Brain activity for the HUD: only real brain output (side-free keys from brain/seer.py), never placeholder numbers.
        activity = cues.get("activity", {}) if cues.get("source") in ("true", "changeling") else {}
        if self.campaign is not None and self.campaign.fight is not None:
            # In a fight the only thing the brain sees is the approaching hand (or Prospero's throw), so any bar moving on
            # the shared screen would tell everyone when an attack is coming. The Seer's phone is the only place for that.
            activity = {}
        return {
            "t": "state", "phase": "play", "time": round(self.state.elapsed_s, 3),
            "room": self.state.room_code, "joinUrl": self.join_url, "locked": self.locked,
            "brain": self.seer.source, "brainActivity": activity,
            "fly": {"x": round(fly.x, 4), "y": round(fly.y, 4), "z": round(fly.z, 4), "vx": round(fly.vx, 4), "vy": round(fly.vy, 4), "vz": round(fly.vz, 4)},
            "render": {"princess": stimuli["princess"]},
            "roles": {role: self.state.inputs[role].value != 0 for role in self.state.inputs},
            "players": [dict(p) for p in self.players],
        } | self._campaign_fields()

    def _campaign_fields(self) -> dict[str, Any]:
        if self.campaign is None:
            return {}
        fields = self.campaign.state_fields()
        if fields["phase"] == "lobby":
            fields["joinQr"] = self.join_qr()
        return fields


class GameServer:
    def __init__(self, session: GameSession, relay: RelayClient, godot: GodotLink, new_code=None) -> None:
        """`new_code`: a callable giving a fresh room code. With it, the host can start a new game with a new code, and a code
        that's already taken on a shared relay is swapped automatically; without it (a pinned --room) the code never changes."""
        self.session, self.relay, self.godot = session, relay, godot
        self.new_code = new_code
        self._switching_room = False

    async def new_room(self) -> str:
        """Jackbox/Kahoot style: every game gets a fresh code. The old room closes (its phones are told to scan the new code)."""
        if self.new_code is None:
            return self.session.state.room_code
        await self.relay.send_host({"t": "close_room"})
        code = self.new_code()
        self._move_to(code)
        return code

    def _move_to(self, code: str) -> None:
        self.session.state.room_code = self.relay.room = code
        self.session.players, self.session.locked = [], False
        for input_state in self.session.state.inputs.values():
            input_state.value = 0
        self._switching_room = True
        asyncio.create_task(self.relay.close())  # relay_forever reconnects straight away as the new room's host

    async def set_locked(self, locked: bool) -> None:
        await self.relay.send_host({"t": "lock", "locked": locked})

    async def kick(self, role: str) -> None:
        await self.relay.send_host({"t": "kick", "role": role})

    async def handle_host_command(self, message: dict[str, Any]) -> None:
        """Lobby commands from a local host screen (see GodotLink) or the launcher's keys."""
        command = message.get("command")
        if self.story_command(message):
            return
        if command == "new_room":
            code = await self.new_room()
            print(f"[host]  New game: room code {code}", flush=True)
        elif command == "lock":
            locked = bool(message.get("locked", not self.session.locked))
            await self.set_locked(locked)
            print(f"[host]  Court {'locked: no new phones' if locked else 'unlocked'}", flush=True)
        elif command == "kick" and message.get("role") in self.session.state.inputs:
            await self.kick(message["role"])
            print(f"[host]  Removed the {message['role']}", flush=True)

    async def accept_input(self, message: dict[str, Any]) -> None:
        self.session.apply_input(message, time.monotonic())

    def story_command(self, message: dict[str, Any]) -> bool:
        """The presenter's story controls (Godot keys, the launcher's letters): start, next, back, skip, restart, jump."""
        campaign = self.session.campaign
        command = message.get("command")
        if campaign is None or command not in {"start", "next", "back", "skip", "restart", "jump"}:
            return False
        if command == "start":
            campaign.start()
        elif command == "next":
            campaign.next()
        elif command == "back":
            campaign.back()
        elif command == "skip":
            campaign.skip()
        elif command == "restart":
            campaign.restart_stage()
        elif command == "jump":
            campaign.jump(str(message.get("scene", "")).upper())
        return True

    async def relay_forever(self) -> None:
        """Stay connected to the relay: retry until it's up, and reconnect if it drops (vital for a relay on the internet)."""
        delay, announced_down = 0.25, False
        while True:
            try:
                await self.relay.connect()
                if announced_down:
                    print("[server] reconnected to the relay", flush=True)
                announced_down, delay = False, 0.25
                await self.relay.receive_forever(self.accept_input)
            except asyncio.CancelledError:
                raise
            except HostJoinError as exc:
                if exc.code == "HOST_EXISTS" and self.new_code is not None:  # that code is in use on a shared relay: take another
                    self.session.state.room_code = self.relay.room = self.new_code()
                    print(f"[server] that room code was taken; new code {self.relay.room}", flush=True)
                    continue
                if not announced_down:
                    print(f"[server] the relay refused this game ({exc}); retrying...", flush=True)
                    announced_down = True
            except Exception as exc:  # refused, dropped: keep the game running and try again
                if self._switching_room:
                    self._switching_room = False
                elif not announced_down:
                    print(f"[server] relay connection lost or refused ({exc.__class__.__name__}); retrying...", flush=True)
                    announced_down = True
            if self._switching_room:  # a new code: reconnect at once, quietly
                self._switching_room = False
                await self.relay.close()
                continue
            await self.relay.close()
            for input_state in self.session.state.inputs.values():  # nobody's input can be trusted until phones are heard again
                input_state.value = 0
            self.session.players = []  # the relay's roster arrives again on reconnect
            await asyncio.sleep(delay)
            delay = min(delay * 2, 1.0)  # retry at least once a second, so phones are back quickly

    async def _send_views(self, views: list[dict[str, Any]]) -> None:
        for view in views:
            await self.relay.send_phone_view(view)

    def seer_forever(self, stop: threading.Event) -> None:
        """The brain on its own thread: one 20 ms step per slot. If the laptop is slow it falls behind real time instead of
        bursting to catch up, so the game stays smooth and the Seer's cues just update less often."""
        session, next_slot = self.session, time.monotonic()
        while not stop.is_set():
            if session.stimuli is not None:
                try:
                    with session.seer_lock:
                        session.cues = session.seer.sense(session.stimuli, dt=TICK_S)
                    session.brain_steps += 1
                except Exception as exc:  # the adapter already falls back on brain errors; never let this thread die
                    print(f"[server] Seer thread error: {exc!r}", flush=True)
            next_slot += TICK_S
            delay = next_slot - time.monotonic()
            if delay > 0:
                stop.wait(delay)
            else:  # a slow laptop: leave the game loop a few ms of the GIL before the next step, so movement never stutters
                next_slot = time.monotonic()
                stop.wait(0.004)

    async def run(self) -> None:
        sys.setswitchinterval(0.001)  # the brain thread hands the GIL back to the game loop quickly
        receiver = asyncio.create_task(self.relay_forever())
        stop_seer = threading.Event()
        if hasattr(self.session.seer, "swap"):  # the brain-powered Seer; the placeholder is instant and stays in step()
            self.session.sense_in_step = False
            threading.Thread(target=self.seer_forever, args=(stop_seer,), name="seer-brain", daemon=True).start()
        last = time.monotonic()
        next_tick = next_godot = next_phone = last
        views_task: asyncio.Task | None = None
        try:
            while True:
                now = time.monotonic()
                self.session.step(now - last, now)
                last = now
                # Fixed-rate schedules (next += period) so a ~6 ms brain step doesn't stretch every tick and frame.
                campaign = self.session.campaign
                while campaign is not None and campaign.events:  # voice, dodge and hit events for the screens
                    await self.godot.publish_event(campaign.events.pop(0))
                if now >= next_godot:
                    await self.godot.publish(self.session.godot_state())
                    next_godot = _next_time(next_godot, GODOT_S, now)
                if now >= next_phone:
                    # sent in the background, so a slow network (or relay) never holds up the game loop; skip a round if
                    # the previous one is still going out
                    if views_task is None or views_task.done():
                        views_task = asyncio.create_task(self._send_views(self.session.phone_views()))
                    next_phone = _next_time(next_phone, PHONE_S, now)
                next_tick = _next_time(next_tick, TICK_S, time.monotonic())
                await asyncio.sleep(max(0.0, next_tick - time.monotonic()))
        finally:
            stop_seer.set()
            receiver.cancel()
            await self.relay.close()


def _next_time(scheduled: float, period: float, now: float) -> float:
    """The next slot of a fixed-rate schedule; after a stall, restart from now instead of bursting to catch up."""
    scheduled += period
    return scheduled if scheduled > now - period else now + period


async def run(room: str, relay_url: str, secret: str, godot_port: int, seer: str = "true", join_url: str | None = None) -> None:
    session = GameSession(room, seer=make_seer(seer), join_url=join_url, campaign=True)
    print(f"[server] room {room}, Seer source: {session.seer.source}")
    godot = GodotLink()
    async with godot.serve(port=godot_port):
        await GameServer(session, RelayClient(relay_url, room, secret), godot).run()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="His Royal Flyness authoritative movement server")
    parser.add_argument("--room", default=os.getenv("ROOM_CODE", "BZKT"))
    parser.add_argument("--relay-url", default=os.getenv("RELAY_URL", "ws://127.0.0.1:8080"))
    parser.add_argument("--godot-port", type=int, default=8765)
    parser.add_argument("--seer", choices=SEER_SOURCES, default=os.getenv("SEER_SOURCE", "true"),
                        help="true = the real MaleCNS brain (falls back to placeholder if data/ is missing)")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    asyncio.run(run(args.room, args.relay_url, os.getenv("ROOM_SECRET", ""), args.godot_port, args.seer))
