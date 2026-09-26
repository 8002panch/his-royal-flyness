"""One command for a local game: the relay, the phone page and the game server, with the join link and a QR code.

    python run_local.py                   # new room code, the real MaleCNS brain if data/ is present
    python run_local.py --room BZKT       # pin the room code so phones reconnect on their own after a restart
    python run_local.py --seer placeholder

Phones on the same Wi-Fi open the printed link (or scan the QR). Godot connects to ws://127.0.0.1:8765.
Host keys (type a letter, then Enter): c = Changeling, t = True Prince, p = placeholder cues, s = status, q = quit.
On a Mac, allow incoming connections for Python the first time, or the phones can't reach the laptop.
"""

from __future__ import annotations

import argparse
import asyncio
import functools
import http.server
import os
import random
import re
import socket
import sys
import threading
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", category=DeprecationWarning, module=r"websockets(\.|$)")
warnings.filterwarnings("ignore", category=DeprecationWarning, message=r".*websockets.*")

from websockets.server import serve  # noqa: E402

from relay.relay import RelayServer, RelayState  # noqa: E402
from server.godot_link import GodotLink  # noqa: E402
from server.main import SEER_SOURCES, GameServer, GameSession, make_seer  # noqa: E402
from server.relay_client import RelayClient  # noqa: E402

ROOT = Path(__file__).resolve().parent
PHONE_PAGE = ROOT / "relay" / "public"
CONSONANTS = "BCDFGHJKLMNPQRSTVWXZ"  # no vowels (or Y), so a room code never spells a word
ROLE_TITLES = {"helmsman": "Helmsman", "liftmaster": "Liftmaster", "wingmaster": "Wingmaster", "seer": "Seer"}


def lan_ip() -> str:
    """This laptop's address on the local network (no packet is sent)."""
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("10.255.255.255", 1))
        return probe.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        probe.close()


class PhonePageHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args) -> None:  # keep the terminal for game events
        pass

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")  # phones always get the latest page after an edit
        super().end_headers()


def serve_phone_page(port: int) -> http.server.ThreadingHTTPServer:
    handler = functools.partial(PhonePageHandler, directory=str(PHONE_PAGE))
    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", port), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def print_banner(room: str, phone_url: str, local_url: str, godot_port: int, seer_source: str) -> None:
    print("\nHis Royal Flyness: local game")
    print(f"  Room code:    {room}")
    print(f"  Phones:       {phone_url}   (same Wi-Fi as this laptop)")
    print(f"  This laptop:  {local_url}")
    print(f"  Godot:        ws://127.0.0.1:{godot_port}")
    print(f"  Seer:         {seer_source}")
    try:
        import qrcode

        qr = qrcode.QRCode(border=1)
        qr.add_data(phone_url)
        qr.print_ascii(invert=True)
    except ImportError:
        print("  (pip install qrcode to show a QR code here)")
    print("  Host keys:    c Changeling | t True Prince | p placeholder | s status | q quit   (then Enter)\n", flush=True)


def players(state: RelayState, room: str) -> dict[str, str]:
    """role -> player name for the phones currently holding a role in this room."""
    room_state = state.rooms.get(room)
    if room_state is None:
        return {}
    return {role: state.clients[cid].name or "?" for role, cid in room_state.role_connections.items() if cid in state.clients}


async def watch_players(state: RelayState, room: str) -> None:
    """Print a line whenever a phone takes or leaves a role."""
    seen: dict[str, str] = {}
    while True:
        await asyncio.sleep(0.5)
        now = players(state, room)
        for role in ROLE_TITLES:
            if now.get(role) != seen.get(role):
                if role in now:
                    print(f"[join]  {ROLE_TITLES[role]}: {now[role]}", flush=True)
                else:
                    print(f"[leave] {ROLE_TITLES[role]} ({seen[role]})", flush=True)
        seen = now


def status_line(session: GameSession, state: RelayState, room: str) -> str:
    fly, taken = session.state.fly, players(state, room)
    seats = ", ".join(f"{ROLE_TITLES[r]}={taken.get(r, '-')}" for r in ROLE_TITLES)
    held = ", ".join(f"{r}={session.state.inputs[r].value}" for r in ROLE_TITLES)
    return (f"[status] room {room} | Seer {session.seer.source} | {seats}\n"
            f"         inputs {held} | fly x={fly.x:+.2f} y={fly.y:+.2f} z={fly.z:+.2f}")


def start_host_keys(loop: asyncio.AbstractEventLoop, on_key) -> None:
    if not sys.stdin or not sys.stdin.isatty():
        return

    def read() -> None:
        for line in sys.stdin:
            loop.call_soon_threadsafe(on_key, line.strip().lower())

    threading.Thread(target=read, daemon=True).start()


async def main(args: argparse.Namespace) -> None:
    room = (args.room or "".join(random.choice(CONSONANTS) for _ in range(4))).upper()
    if not re.fullmatch(r"[BCDFGHJKLMNPQRSTVWXYZ]{4}", room):
        raise SystemExit("--room must be four consonants, e.g. BZKT")
    secret = os.getenv("ROOM_SECRET", "")
    ip = lan_ip()
    phone_url = f"http://{ip}:{args.http_port}/?room={room}"
    local_url = f"http://localhost:{args.http_port}/?room={room}"
    if args.relay_port != 8080:  # the phone page assumes 8080 unless told otherwise
        phone_url += f"&relay=ws://{ip}:{args.relay_port}"
        local_url += f"&relay=ws://localhost:{args.relay_port}"

    relay_state = RelayState(room_secret=secret)
    relay = RelayServer(relay_state)
    serve_phone_page(args.http_port)
    session = GameSession(room, seer=make_seer(args.seer), join_url=phone_url)
    godot = GodotLink()

    async with serve(relay.handler, "0.0.0.0", args.relay_port), godot.serve(port=args.godot_port):
        background = [asyncio.create_task(relay.watchdog()), asyncio.create_task(watch_players(relay_state, room))]
        game = asyncio.create_task(GameServer(session, RelayClient(f"ws://127.0.0.1:{args.relay_port}", room, secret), godot).run())
        print_banner(room, phone_url, local_url, args.godot_port, session.seer.source)

        def on_key(key: str) -> None:
            if key in ("c", "t", "p"):
                source = {"c": "changeling", "t": "true", "p": "placeholder"}[key]
                now = session.set_brain(source)
                print(f"[host]  Seer now: {now}" + ("" if now == source else " (the brain isn't loaded; placeholder only)"), flush=True)
            elif key == "s":
                print(status_line(session, relay_state, room), flush=True)
            elif key == "q":
                game.cancel()

        start_host_keys(asyncio.get_running_loop(), on_key)
        try:
            await game
        except asyncio.CancelledError:
            pass
        finally:
            for task in background:
                task.cancel()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run His Royal Flyness locally: relay, phone page and game server")
    parser.add_argument("--room", default=os.getenv("ROOM_CODE"), help="four consonants; default: a new random code")
    parser.add_argument("--seer", choices=SEER_SOURCES, default=os.getenv("SEER_SOURCE", "true"))
    parser.add_argument("--http-port", type=int, default=8000, help="phone page")
    parser.add_argument("--relay-port", type=int, default=8080, help="WebSocket relay (the phone page expects 8080)")
    parser.add_argument("--godot-port", type=int, default=8765)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        asyncio.run(main(parse_args()))
    except KeyboardInterrupt:
        pass
