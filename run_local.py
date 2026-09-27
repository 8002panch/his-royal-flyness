"""One command for a local game: the relay, the phone page, the game server and the host screen.

    python run_local.py                   # new room code, the real MaleCNS brain if data/ is present
    python run_local.py --room BZKT       # pin the room code so phones reconnect on their own after a restart
    python run_local.py --seer placeholder
    python run_local.py --relay-url wss://royalflyness.club/ws   # phones join through a relay on the internet (relay/Caddyfile)

The main screen is the Godot court (godot --path host, then Enter the Court): it reads the state feed at ws://127.0.0.1:8765 and
shows the room code and QR code; players scan it with phones on the same Wi-Fi. A browser backup of the host screen is served at
http://localhost:8001 (add --browser to open it automatically, for a laptop without Godot).
Host keys (type a letter, then Enter): c = Changeling, t = True Prince, p = placeholder cues, s = status, q = quit.
Story keys: g = start the story, Enter = next bubble, b = back, k = skip the comic, r = restart the stage,
j GIANT = jump to a chapter (TUTORIAL C01 Q01 STAGE1 Q02 STAGE2 Q03 C02 GIANT C03 C04 FATHER E01 E02; marks DEMO).
The Godot screen has the same controls (Enter, Space, Left, S, R, 1-9).
On a Mac, allow incoming connections for Python the first time, or the phones can't reach the laptop.
"""

from __future__ import annotations

import os

# The brain's heavy step is single-threaded sparse maths; stop NumPy's BLAS from starting a busy thread per core (set before
# NumPy is imported), which leaves the demo laptop's CPU for Godot and the browser.
for _var in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ.setdefault(_var, "1")

import argparse
import asyncio
import contextlib
import functools
import http.server
import secrets
import re
import socket
import sys
import threading
import time
import warnings
import webbrowser
from pathlib import Path
from urllib.parse import urlsplit

warnings.filterwarnings("ignore", category=DeprecationWarning, module=r"websockets(\.|$)")
warnings.filterwarnings("ignore", category=DeprecationWarning, message=r".*websockets.*")

from websockets.server import serve  # noqa: E402

from relay.relay import SERVE_OPTIONS, RelayServer, RelayState  # noqa: E402
from server.godot_link import GodotLink  # noqa: E402
from server.main import SEER_SOURCES, GameServer, GameSession, make_seer  # noqa: E402
from server.relay_client import RelayClient  # noqa: E402

ROOT = Path(__file__).resolve().parent
PHONE_PAGE = ROOT / "relay" / "public"
HOST_PAGE = ROOT / "host" / "web"
CONSONANTS = "BCDFGHJKLMNPQRSTVWXZ"  # no vowels (or Y), so a room code never spells a word (Jackbox filters bad words instead)


def new_room_code(avoid: str = "") -> str:
    """A fresh four-consonant code (20^4 = 160,000 possibilities) from a cryptographic random source, never the one just used."""
    while True:
        code = "".join(secrets.choice(CONSONANTS) for _ in range(4))
        if code != avoid:
            return code
ROLE_TITLES = {"helmsman": "Helmsman", "liftmaster": "Liftmaster", "wingmaster": "Wingmaster", "seer": "Seer"}


def port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        return probe.connect_ex(("127.0.0.1", port)) == 0


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


def qr_svg(text: str) -> str | None:
    """A QR code for `text` as SVG, from the qrcode package or OpenCV, whichever is installed (None if neither)."""
    try:
        import qrcode

        qr = qrcode.QRCode(border=4, error_correction=qrcode.constants.ERROR_CORRECT_M)
        qr.add_data(text)
        qr.make(fit=True)
        modules = [[bool(v) for v in row] for row in qr.get_matrix()]
    except ImportError:
        try:
            import cv2

            modules = [[px == 0 for px in row] for row in cv2.QRCodeEncoder.create().encode(text).tolist()]
        except Exception:
            return None
    n = len(modules)
    dark = "".join(f"M{x} {y}h1v1h-1z" for y, row in enumerate(modules) for x, on in enumerate(row) if on)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {n} {n}" shape-rendering="crispEdges">'
            f'<rect width="{n}" height="{n}" fill="#fff"/><path d="{dark}" fill="#000"/></svg>')


def serve_host_screen(port: int, current_join_url) -> http.server.ThreadingHTTPServer:
    """The host screen, on this laptop only (127.0.0.1), so phones can't open the game view. /qr.svg always encodes the
    current join link, so the QR changes with the room code."""
    cache: dict[str, str | None] = {}

    class HostPageHandler(PhonePageHandler):
        def do_GET(self) -> None:
            if self.path.split("?")[0] == "/qr.svg":
                url = current_join_url() or ""
                if url not in cache:
                    cache.clear()
                    cache[url] = qr_svg(url) if url else None
                svg = cache[url]
                if svg is None:
                    self.send_error(404, "No QR library (pip install qrcode)")
                    return
                body = svg.encode()
                self.send_response(200)
                self.send_header("Content-Type", "image/svg+xml")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            super().do_GET()

    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", port), functools.partial(HostPageHandler, directory=str(HOST_PAGE)))
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def print_banner(room: str, phone_url: str, host_url: str, godot_port: int, seer_source: str, remote_relay: str | None,
                 pinned: bool = False) -> None:
    print("\nHis Royal Flyness: " + ("online game" if remote_relay else "local game"))
    print(f"  Main screen:  Godot: godot --path host, then Enter the Court   (browser backup: {host_url})")
    print(f"  Room code:    {room}" + ("   (pinned with --room)" if pinned else "   (a fresh code every game: n = new code)"))
    print(f"  Phones:       {phone_url}" + ("" if remote_relay else "   (same Wi-Fi as this laptop)"))
    if remote_relay:
        print(f"  Relay:        {remote_relay}")
    print(f"  Godot feed:   ws://127.0.0.1:{godot_port}")
    print(f"  Seer:         {seer_source}")
    print("  Host keys:    n new code | l lock/unlock | c Changeling | t True Prince | p placeholder | s status | q quit"
          "   (then Enter)\n", flush=True)


async def watch_players(session: GameSession) -> None:
    """Print a line whenever a phone takes or leaves a role (from the relay's roster, local or online)."""
    seen: dict[str, str] = {}
    while True:
        await asyncio.sleep(0.25)
        now = {p["role"]: p["name"] for p in session.players}
        for role in ROLE_TITLES:
            if now.get(role) != seen.get(role):
                if role in now:
                    print(f"[join]  {ROLE_TITLES[role]}: {now[role]}", flush=True)
                else:
                    print(f"[leave] {ROLE_TITLES[role]} ({seen[role]})", flush=True)
        seen = now


_last_status = {"t": time.monotonic(), "steps": 0}


def status_line(session: GameSession, room: str) -> str:
    fly, taken = session.state.fly, {p["role"]: p["name"] for p in session.players}
    seats = ", ".join(f"{ROLE_TITLES[r]}={taken.get(r, '-')}" for r in ROLE_TITLES)
    held = ", ".join(f"{r}={session.state.inputs[r].value}" for r in ROLE_TITLES)
    now = time.monotonic()
    rate = (session.brain_steps - _last_status["steps"]) / max(now - _last_status["t"], 1e-6)
    _last_status.update(t=now, steps=session.brain_steps)
    brain = f"brain {rate:.0f} steps/s (50 = real time)" if not session.sense_in_step else "brain in step"
    return (f"[status] room {room} | Seer {session.seer.source} | {brain} | {seats}\n"
            f"         inputs {held} | fly x={fly.x:+.2f} y={fly.y:+.2f} z={fly.z:+.2f}")


def start_host_keys(loop: asyncio.AbstractEventLoop, on_key) -> None:
    if not sys.stdin or not sys.stdin.isatty():
        return

    def read() -> None:
        for line in sys.stdin:
            loop.call_soon_threadsafe(on_key, line.strip().lower())

    threading.Thread(target=read, daemon=True).start()


async def main(args: argparse.Namespace) -> None:
    pinned = bool(args.room)  # a fixed code only for testing; normally every launch and every new game gets a fresh one
    room = (args.room or new_room_code()).upper()
    if not re.fullmatch(r"[BCDFGHJKLMNPQRSTVWXYZ]{4}", room):
        raise SystemExit("--room must be four consonants, e.g. BZKT")
    secret = os.getenv("ROOM_SECRET", "")
    remote = bool(args.relay_url)  # phones reach a relay on the internet; this laptop only runs the game server
    if remote:
        relay_url = args.relay_url
        page = args.join_url or f"https://{urlsplit(relay_url).netloc}/"  # the relay's own site by default (relay/Caddyfile)
        phone_url = f"{page}{'&' if '?' in page else '?'}room={{room}}"
    else:
        ip = lan_ip()
        relay_url = f"ws://127.0.0.1:{args.relay_port}"
        page = args.join_url or f"http://{ip}:{args.http_port}/"
        phone_url = f"{page}{'&' if '?' in page else '?'}room={{room}}"
        if args.relay_port != 8080 and not args.join_url:  # the phone page assumes 8080 unless told otherwise
            phone_url += f"&relay=ws://{ip}:{args.relay_port}"
    host_url = f"http://localhost:{args.host_port}/"
    if args.godot_port != 8765:
        host_url += f"?feed=ws://127.0.0.1:{args.godot_port}"
    ports = (args.host_port, args.godot_port) if remote else (args.http_port, args.host_port, args.relay_port, args.godot_port)
    busy = [port for port in ports if port_in_use(port)]
    if busy:
        ports = f"Ports {', '.join(map(str, busy))} are" if len(busy) > 1 else f"Port {busy[0]} is"
        raise SystemExit(f"{ports} already in use. Is the game already running in another terminal? "
                         "Quit it there (q, then Enter, or Ctrl+C) and run this again.")

    print("Starting His Royal Flyness" + (": loading the MaleCNS brain (about 5 s)..." if args.seer != "placeholder" else "..."), flush=True)
    relay_state = RelayState(room_secret=secret, require_host=True)  # a code only works while this game hosts it
    relay = RelayServer(relay_state)
    session = GameSession(room, seer=make_seer(args.seer), join_url=phone_url, campaign=True)  # phone_url has {room}
    if not remote:
        serve_phone_page(args.http_port)
    serve_host_screen(args.host_port, lambda: session.join_url)
    godot = GodotLink()

    async with contextlib.AsyncExitStack() as stack:
        await stack.enter_async_context(godot.serve(port=args.godot_port))
        background = [asyncio.create_task(watch_players(session))]
        if not remote:
            await stack.enter_async_context(serve(relay.handler, "0.0.0.0", args.relay_port, **SERVE_OPTIONS))
            background.append(asyncio.create_task(relay.watchdog()))
        server = GameServer(session, RelayClient(relay_url, room, secret), godot,
                            new_code=None if pinned else (lambda: new_room_code(avoid=session.state.room_code)))
        godot.on_command = server.handle_host_command  # New code / Lock / Remove from the host screen
        game = asyncio.create_task(server.run())
        print_banner(room, session.join_url, host_url, args.godot_port, session.seer.source, relay_url if remote else None, pinned)
        if args.browser and not args.no_browser:
            threading.Thread(target=webbrowser.open, args=(host_url,), daemon=True).start()

        def on_key(key: str) -> None:
            story = {"g": "start", "": "next", ".": "next", "b": "back", "k": "skip", "r": "restart"}
            if key in story or key.startswith("j "):
                command = {"command": "jump", "scene": key[2:].strip()} if key.startswith("j ") else {"command": story[key]}
                server.story_command(command)
                c = session.campaign
                print(f"[story] {c.scene} ({c.phase}){'  DEMO' if c.demo else ''}", flush=True)
            elif key in ("c", "t", "p"):
                source = {"c": "changeling", "t": "true", "p": "placeholder"}[key]
                now = session.set_brain(source)
                print(f"[host]  Seer now: {now}" + ("" if now == source else " (the brain isn't loaded; placeholder only)"), flush=True)
            elif key == "s":
                print(status_line(session, session.state.room_code), flush=True)
            elif key == "n":
                if pinned:
                    print("[host]  The room code is pinned with --room; restart without it for fresh codes", flush=True)
                else:
                    asyncio.ensure_future(server.handle_host_command({"command": "new_room"}))
            elif key == "l":
                asyncio.ensure_future(server.handle_host_command({"command": "lock"}))
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
    parser.add_argument("--room", default=os.getenv("ROOM_CODE"),
                        help="pin the code (testing only); by default every launch and every new game gets a fresh random code")
    parser.add_argument("--seer", choices=SEER_SOURCES, default=os.getenv("SEER_SOURCE", "true"))
    parser.add_argument("--http-port", type=int, default=8000, help="phone page")
    parser.add_argument("--relay-port", type=int, default=8080, help="WebSocket relay (the phone page expects 8080)")
    parser.add_argument("--godot-port", type=int, default=8765)
    parser.add_argument("--host-port", type=int, default=8001, help="host screen (this laptop only)")
    parser.add_argument("--browser", action="store_true", help="also open the browser backup host screen (Godot is the main screen)")
    parser.add_argument("--no-browser", action="store_true", help=argparse.SUPPRESS)  # the old opt-out; the tab is off by default now
    parser.add_argument("--relay-url", default=os.getenv("RELAY_URL"),
                        help="use a relay on the internet (e.g. wss://royalflyness.club/ws) instead of running one here")
    parser.add_argument("--join-url", default=os.getenv("JOIN_URL"),
                        help="the phone page link to show (default: this laptop's page, or https://<relay host>/ with --relay-url)")
    return parser.parse_args()


if __name__ == "__main__":
    try:
        asyncio.run(main(parse_args()))
    except KeyboardInterrupt:
        pass
