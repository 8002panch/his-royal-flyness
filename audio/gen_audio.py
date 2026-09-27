"""Batch voice generation: lines.csv -> audio/out/<id>.mp3 via ElevenLabs text-to-speech.

    python audio/gen_audio.py --dry-run     # list what would be generated, no API calls
    python audio/gen_audio.py               # generate missing files (existing mp3s are skipped)
    python audio/gen_audio.py --force H_WIN # regenerate one id

Secrets and voice IDs come from the environment / .env (never committed):
    ELEVENLABS_API_KEY, ELEVEN_VOICE_HERALD, ELEVEN_VOICE_PRINCESS, ELEVEN_VOICE_JESTER,
    ELEVEN_VOICE_RIVAL (optional, falls back to the herald voice), ELEVEN_MODEL (default eleven_v3).
Library voices only (no cloning real people).
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
SPEAKER_VOICE_ENV = {
    "herald": "ELEVEN_VOICE_HERALD",
    "princess": "ELEVEN_VOICE_PRINCESS",
    "jester": "ELEVEN_VOICE_JESTER",
    "rival": "ELEVEN_VOICE_RIVAL",
}


def load_env() -> None:
    try:
        from dotenv import load_dotenv

        load_dotenv(HERE.parent / ".env")
    except ImportError:
        pass


def voice_for(speaker: str) -> str | None:
    return os.environ.get(SPEAKER_VOICE_ENV[speaker]) or os.environ.get("ELEVEN_VOICE_HERALD")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--force", nargs="*", default=[], help="ids to regenerate even if the mp3 exists")
    args = ap.parse_args()
    load_env()
    rows = list(csv.DictReader(open(HERE / "lines.csv", encoding="utf-8", newline="")))
    todo = [r for r in rows if r["id"] in args.force or not (OUT / f"{r['id']}.mp3").exists()]
    print(f"{len(rows)} lines, {len(todo)} to generate")
    if args.dry_run:
        for r in todo:
            print(f"  {r['id']:<18} {r['speaker']:<9} {r['text'][:60]}")
        return 0
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        print("ELEVENLABS_API_KEY is not set (put it in .env)", file=sys.stderr)
        return 1
    from elevenlabs.client import ElevenLabs

    client = ElevenLabs(api_key=key)
    model = os.environ.get("ELEVEN_MODEL", "eleven_v3")
    OUT.mkdir(exist_ok=True)
    for r in todo:
        voice = voice_for(r["speaker"])
        if not voice:
            print(f"skip {r['id']}: no voice id for {r['speaker']}", file=sys.stderr)
            continue
        audio = client.text_to_speech.convert(voice_id=voice, text=r["text"], model_id=model, output_format="mp3_44100_128")
        (OUT / f"{r['id']}.mp3").write_bytes(b"".join(audio))
        print("wrote", r["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
