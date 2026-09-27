"""The weather sounds, made here from filtered noise (no API, no recordings): rain and thunder for the Giant's storm, and
the crackle of Prospero's hellfire. Deterministic (fixed seeds), so the files only change when this script does.

    python -m audio.gen_weather        # writes audio/weather/*.wav and audio/weather/manifest.json

The loops are WAV (seamless, crossfaded ends); host/scripts/voice_player.gd loads them next to the ElevenLabs sounds.
"""

from __future__ import annotations

import json
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

RATE = 22050
OUT = Path(__file__).resolve().parent / "weather"


def _band(x: np.ndarray, lo: float | None, hi: float | None) -> np.ndarray:
    if lo and hi:
        sos = butter(2, [lo, hi], btype="bandpass", fs=RATE, output="sos")
    elif lo:
        sos = butter(2, lo, btype="highpass", fs=RATE, output="sos")
    else:
        sos = butter(2, hi, btype="lowpass", fs=RATE, output="sos")
    return sosfilt(sos, x)


def _brown(n: int, rng: np.random.Generator) -> np.ndarray:
    b = np.cumsum(rng.standard_normal(n))
    b -= _band(b, None, 8.0)  # take out the drift
    return b / (np.abs(b).max() + 1e-9)


def _loop(x: np.ndarray, fade_s: float = 1.0) -> np.ndarray:
    """A seamless loop: the tail is crossfaded over the head."""
    f = int(fade_s * RATE)
    head, body, tail = x[:f], x[f:-f], x[-f:]
    ramp = np.linspace(0.0, 1.0, f)
    return np.concatenate([tail * (1 - ramp) + head * ramp, body])


def _norm(x: np.ndarray, peak_db: float) -> np.ndarray:
    return x / (np.abs(x).max() + 1e-9) * 10 ** (peak_db / 20)


def rain(rng: np.random.Generator) -> np.ndarray:
    n = int(11 * RATE)
    hiss = _band(rng.standard_normal(n), 900, 7000) * 0.5
    wash = _band(rng.standard_normal(n), 250, 1400) * 0.35
    drops = np.zeros(n)
    t = np.arange(int(0.02 * RATE)) / RATE
    for at in rng.integers(0, n - len(t), 700):  # single drops ticking on stone
        f = rng.uniform(2500, 6000)
        drops[at:at + len(t)] += np.sin(2 * np.pi * f * t) * np.exp(-t * 300) * rng.uniform(0.2, 0.8)
    swell = 1 + 0.25 * np.sin(2 * np.pi * np.arange(n) / RATE / 5.5)
    return _norm(_loop((hiss + wash + drops * 0.6) * swell), -9)


def thunder(rng: np.random.Generator, crack: bool, seconds: float) -> np.ndarray:
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    rumble = _band(_brown(n, rng), 25, 180)
    rolls = 0.6 + 0.4 * np.abs(_band(rng.standard_normal(n), None, 3.0)) / 0.05  # the rolling swells
    rolls = np.clip(rolls / rolls.max() * 1.6, 0.3, 1.0)
    attack = 0.02 if crack else 0.35
    env = np.minimum(t / attack, 1.0) * np.exp(-t / (seconds * 0.32))
    out = rumble * rolls * env
    out = out / (np.abs(out).max() + 1e-9)
    if crack:  # the close strike: a sharp tearing crack on top
        k = int(0.35 * RATE)
        c = _band(rng.standard_normal(k), 400, 6000) * np.exp(-np.arange(k) / RATE * 14)
        out[:k] += c / (np.abs(c).max() + 1e-9) * 0.7
    return _norm(out, -1)


def fire(rng: np.random.Generator) -> np.ndarray:
    n = int(9 * RATE)
    roar = _band(_brown(n, rng), 40, 500) * 0.7
    crackle = np.zeros(n)
    for at in rng.integers(0, n - 400, 260):  # pops and snaps
        k = int(rng.uniform(40, 300))
        crackle[at:at + k] += _band(rng.standard_normal(k), 1500, 8000) * np.exp(-np.arange(k) / k * 5) * rng.uniform(0.3, 1)
    return _norm(_loop(roar + crackle * 0.8), -8)


def _write(name: str, x: np.ndarray) -> None:
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())


SOUNDS = [
    ("RAIN_LOOP", True, "Under the whole Giant fight: the storm outside the Great Hall", lambda r: rain(r)),
    ("THUNDER_CLOSE", False, "Just after a close lightning strike (a sharp crack, then the roll)", lambda r: thunder(r, True, 4.5)),
    ("THUNDER_ROLL", False, "Just after a distant flash: a long low roll", lambda r: thunder(r, False, 5.5)),
    ("THUNDER_FAR", False, "Just after a faint, far flash", lambda r: thunder(r, False, 4.0) * 0.6),
    ("FIRE_LOOP", True, "Under Prospero's fight: the hellfire's roar and crackle", lambda r: fire(r)),
]


def main() -> None:
    OUT.mkdir(exist_ok=True)
    entries = []
    for i, (name, loop, when, make) in enumerate(SOUNDS):
        _write(name, make(np.random.default_rng(100 + i)))
        entries.append({"id": name, "when": when, "loop": loop, "file": f"{name}.wav", "stale": False})
    (OUT / "manifest.json").write_text(json.dumps({"model": "procedural (audio/gen_weather.py)", "sounds": entries}, indent=1) + "\n")
    print("wrote", ", ".join(e["file"] for e in entries))


if __name__ == "__main__":
    main()
