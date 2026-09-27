"""Start His Royal Flyness.

    Mac:      python3 play.py
    Windows:  py play.py

The first run installs the game's Python packages (a minute or two) and prepares the art. Then the game server starts in
this window and the main screen opens (Godot 4.3). Keep this window open while you play; type q then Enter to quit.
"""

from __future__ import annotations

import glob
import os
import shutil
import subprocess
import sys
import threading
import venv
from pathlib import Path

HERE = Path(__file__).resolve().parent
WINDOWS = os.name == "nt"
VENV = HERE / ".venv"
PY = VENV / ("Scripts/python.exe" if WINDOWS else "bin/python")
GODOT_PAGE = "https://godotengine.org/download/archive/4.3-stable/"


def stop(message: str) -> None:
    print("\n" + message)
    input("Press Enter to close.")
    sys.exit(1)


def find_godot() -> str | None:
    """Godot 4.3 on PATH, in Applications (Mac), or left where it was unzipped (Downloads, Desktop, this folder)."""
    for name in ("godot", "godot4", "Godot"):
        if shutil.which(name):
            return shutil.which(name)
    home = Path.home()
    places = [HERE, home / "Downloads", home / "Desktop", home / "Applications", Path("/Applications")]
    patterns = ["Godot*.app/Contents/MacOS/Godot", "*/Godot*.app/Contents/MacOS/Godot"] if not WINDOWS else \
        ["Godot*.exe", "*/Godot*.exe"]
    for place in places:
        for pattern in patterns:
            found = [p for p in sorted(glob.glob(str(place / pattern))) if "console" not in p.lower() and "mono" not in p.lower()]
            if found:
                return found[-1]
    return None


def main() -> None:
    os.chdir(HERE)
    if sys.version_info < (3, 11):
        stop(f"His Royal Flyness needs Python 3.11 or newer (this is {sys.version.split()[0]}).\n"
             "Get it from https://www.python.org/downloads/ and run this again.")
    if not PY.exists():
        print("First run: installing the game's Python packages (a minute or two)...")
        venv.create(VENV, with_pip=True)
        if subprocess.call([str(PY), "-m", "pip", "install", "-q", "--disable-pip-version-check", "-r", str(HERE / "requirements-play.txt")]) != 0:
            shutil.rmtree(VENV, ignore_errors=True)
            stop("Installing the packages failed. Check your internet connection and run this again.")
    godot = find_godot()
    extra = sys.argv[1:]  # passed on to the game server (e.g. --room BZKT, or other ports)
    args = [str(PY), "run_local.py", *extra]
    screen = [godot, "--path", str(HERE / "host")] if godot else []
    if godot and "--godot-port" in extra:  # the main screen follows the server to another port
        screen += ["--", f"--server=ws://127.0.0.1:{extra[extra.index('--godot-port') + 1]}"]
    if godot:
        if not (HERE / "host" / ".godot" / "imported").exists():
            print("First run: preparing the game's art...")
            subprocess.call([godot, "--headless", "--path", str(HERE / "host"), "--import"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # the main screen opens once the brain has loaded
        threading.Timer(8.0, lambda: subprocess.Popen(screen, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)).start()
    else:
        print("Godot 4.3 wasn't found, so the main screen opens in your browser instead.")
        print(f"For the full pixel-art screen, get Godot 4.3 (standard): {GODOT_PAGE}")
        print("and put it in Applications (Mac), or in Downloads or on the Desktop (Windows), then run this again.\n")
        args.append("--browser")
    sys.exit(subprocess.call(args))


if __name__ == "__main__":
    main()
