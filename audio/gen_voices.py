"""Voice lines for the campaign: the script in audio/lines.csv, cast in audio/voices.json, spoken by ElevenLabs into audio/voice/.

    python audio/gen_voices.py --dry-run          # no key needed: checks the lines and the cast, counts what would be sent
    python audio/gen_voices.py --my-voices        # lists the voices in your ElevenLabs account with their IDs
    python audio/gen_voices.py --check            # checks the key, each cast voice and the characters left on the account
    python audio/gen_voices.py                    # generates every line whose text, voice or settings changed
    python audio/gen_voices.py --only C01 Q01     # just these scenes, speakers or line ids (e.g. --only clown H_TITLE)
    python audio/gen_voices.py --force --only miranda
    python audio/gen_voices.py --manifest-only    # rewrites the manifest from the mp3s already on disk
    python audio/gen_voices.py --adopt --only H_TITLE   # an mp3 made in the ElevenLabs app counts as up to date

The API key comes from ELEVENLABS_API_KEY in the environment or in .env at the repo root (never commit it). Voice IDs are not
secret and live in voices.json, so the whole team generates the same cast. A speaker without a voice ID is skipped.

Square brackets in a line are ElevenLabs v3 audio tags ([sighs], [hiccups]): spoken as direction, stripped from captions, and
stripped from the text too if a non-v3 model is chosen (older models would read them out loud).

Output: voice/<id>.mp3 per line, plus voice/manifest.json (story order; id, scene, panel, branch, speaker, caption, file) for
Godot and the server, and voice/manifest.js (the same data) so table_read.html works when opened straight from disk.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

AUDIO = Path(__file__).resolve().parent
ROOT = AUDIO.parent
LINES_CSV = AUDIO / "lines.csv"
VOICES_JSON = AUDIO / "voices.json"
OUT_DIR = AUDIO / "voice"

TAG = re.compile(r"\[[^\[\]]*\]")
ID_OK = re.compile(r"^[A-Z0-9_]+$")  # ids double as file names and Godot resource paths
VOICE_ID = re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9]{20}(?![A-Za-z0-9])")  # ElevenLabs voice IDs are 20 characters
BRANCHES = {"", "correct", "wrong", "giant_win", "giant_loss", "father_win", "father_loss"}
RETRY_STATUS = {429, 500, 502, 503, 504}
RETRIES = 4


@dataclass(frozen=True)
class Line:
    id: str
    scene: str
    panel: str
    branch: str
    speaker: str
    line: str
    note: str

    @property
    def caption(self) -> str:
        return caption(self.line)


def caption(text: str) -> str:
    """The text players read: audio tags removed, spacing tidied."""
    return re.sub(r"\s{2,}", " ", TAG.sub("", text)).strip()


def spoken_text(line: Line, model: str) -> str:
    """What is sent to ElevenLabs. Only the v3 models understand audio tags."""
    return line.line.strip() if model.startswith("eleven_v3") else line.caption


def voice_id_from(value: str) -> str:
    """Accepts a bare voice ID or a link that contains one (voice library or share links); '' if there isn't one."""
    value = (value or "").strip()
    found = VOICE_ID.findall(value)
    return found[-1] if found else ""


def load_lines(path: Path = LINES_CSV) -> list[Line]:
    with path.open(newline="", encoding="utf-8") as f:
        return [Line(**{k: (row.get(k) or "").strip() for k in Line.__dataclass_fields__}) for row in csv.DictReader(f)]


def load_cast(path: Path = VOICES_JSON) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def problems(lines: list[Line], cast: dict) -> list[str]:
    """Everything that would make a line unplayable or wrong. Empty means the bank is sound."""
    out: list[str] = []
    speakers = cast.get("speakers", {})
    seen: set[str] = set()
    for ln in lines:
        where = ln.id or "(row without an id)"
        if not ID_OK.match(ln.id):
            out.append(f"{where}: ids use A-Z, 0-9 and _ only")
        if ln.id in seen:
            out.append(f"{where}: duplicate id")
        seen.add(ln.id)
        if ln.speaker not in speakers:
            out.append(f"{where}: speaker '{ln.speaker}' is not in voices.json")
        if ln.branch not in BRANCHES:
            out.append(f"{where}: unknown branch '{ln.branch}'")
        if ln.line.count("[") != ln.line.count("]"):
            out.append(f"{where}: unbalanced [ ]")
        if not ln.caption:
            out.append(f"{where}: no text")
    return out


def line_hash(line: Line, speaker: dict, model: str, output_format: str) -> str:
    """Changes when anything that affects the audio changes, so unchanged lines are never paid for twice."""
    key = [spoken_text(line, model), voice_id_from(speaker.get("voice_id", "")), speaker.get("stability"), model, output_format]
    return hashlib.sha256(json.dumps(key).encode()).hexdigest()[:16]


def read_manifest(out_dir: Path) -> dict[str, dict]:
    path = out_dir / "manifest.json"
    if not path.exists():
        return {}
    try:
        return {e["id"]: e for e in json.loads(path.read_text(encoding="utf-8")).get("lines", [])}
    except (ValueError, KeyError, TypeError):
        return {}


def write_manifest(lines: list[Line], cast: dict, out_dir: Path, hashes: dict[str, str]) -> dict:
    """Story-ordered index of every line; `file` is null until its mp3 exists."""
    speakers = cast.get("speakers", {})
    manifest = {
        "model": cast.get("model", ""),
        "speakers": {k: v.get("name", k) for k, v in speakers.items()},
        "lines": [
            {
                "id": ln.id, "scene": ln.scene, "panel": ln.panel, "branch": ln.branch,
                "speaker": ln.speaker, "name": speakers.get(ln.speaker, {}).get("name", ln.speaker),
                "caption": ln.caption,
                "file": f"{ln.id}.mp3" if (out_dir / f"{ln.id}.mp3").exists() else None,
                "hash": hashes.get(ln.id) if (out_dir / f"{ln.id}.mp3").exists() else None,
            }
            for ln in lines
        ],
    }
    out_dir.mkdir(parents=True, exist_ok=True)
    one = lambda v: json.dumps(v, ensure_ascii=False)  # noqa: E731
    text = ('{"model": %s,\n "speakers": %s,\n "lines": [\n  %s\n ]}' % (
        one(manifest["model"]), one(manifest["speakers"]), ",\n  ".join(one(e) for e in manifest["lines"])))  # a line per entry
    (out_dir / "manifest.json").write_text(text + "\n", encoding="utf-8")
    (out_dir / "manifest.js").write_text(
        "// Written by audio/gen_voices.py for table_read.html (browsers block fetch() from file://).\n"
        f"window.VOICE_MANIFEST = {text};\n", encoding="utf-8")
    return manifest


def _api_detail(err: Exception) -> tuple[int, str, str]:
    """(HTTP status, ElevenLabs status code such as 'voice_not_found', message) from an SDK error."""
    status = getattr(err, "status_code", None) or 0
    body = getattr(err, "body", None)
    detail = body.get("detail") if isinstance(body, dict) else None
    if isinstance(detail, dict):
        return status, str(detail.get("status") or detail.get("code") or ""), str(detail.get("message") or detail)
    return status, "", str(detail or body or err)


def _client():
    try:
        from dotenv import load_dotenv
        load_dotenv(ROOT / ".env")
    except ImportError:
        pass
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        sys.exit("ELEVENLABS_API_KEY is not set. Put it in .env at the repo root (see .env.example) or export it.")
    try:
        from elevenlabs.client import ElevenLabs
    except ImportError:
        sys.exit("The elevenlabs package is missing: pip install -r requirements.txt")
    return ElevenLabs(api_key=key)


def synthesize(client, line: Line, speaker: dict, model: str, output_format: str) -> bytes:
    from elevenlabs import VoiceSettings

    settings = VoiceSettings(stability=speaker["stability"]) if speaker.get("stability") is not None else None
    for attempt in range(RETRIES):
        try:
            return b"".join(client.text_to_speech.convert(
                voice_id=voice_id_from(speaker["voice_id"]), text=spoken_text(line, model), model_id=model,
                output_format=output_format, voice_settings=settings))
        except Exception as err:  # the SDK's ApiError, or a network error from httpx underneath it
            import httpx

            status, _, _ = _api_detail(err)
            transient = status in RETRY_STATUS or isinstance(err, httpx.TransportError)
            if not transient or attempt == RETRIES - 1:
                raise
            time.sleep(2 ** (attempt + 1))
    raise RuntimeError("unreachable")


def _select(lines: list[Line], only: list[str]) -> list[Line]:
    if not only:
        return lines
    want = {w.lower() for w in only}
    return [ln for ln in lines if {ln.id.lower(), ln.scene.lower(), ln.speaker.lower()} & want]


def cmd_my_voices() -> None:
    client = _client()
    voices = client.voices.get_all().voices
    for v in sorted(voices, key=lambda v: (v.category or "", v.name or "")):
        print(f"  {v.voice_id}  {v.name}  ({v.category})")
    print(f"{len(voices)} voices. Paste IDs into audio/voices.json.")


def cmd_check(cast: dict, lines: list[Line]) -> None:
    client = _client()
    try:
        sub = client.user.subscription.get()
        left = (sub.character_limit or 0) - (sub.character_count or 0)
        print(f"Key works. Plan: {sub.tier}. Characters left this period: {left:,} of {sub.character_limit:,}.")
    except Exception as err:
        status, code, msg = _api_detail(err)
        sys.exit(f"The key was rejected ({status} {code}): {msg}")
    for name, sp in cast["speakers"].items():
        vid = voice_id_from(sp.get("voice_id", ""))
        count = sum(ln.speaker == name for ln in lines)
        if not vid:
            print(f"  {name:10} not cast yet ({count} lines)")
            continue
        try:
            print(f"  {name:10} {vid}  '{client.voices.get(vid).name}'  ({count} lines)")
        except Exception as err:
            _, code, msg = _api_detail(err)
            print(f"  {name:10} {vid}  NOT FOUND in your account ({code or msg}). If it's a Voice Library voice, open it on "
                  "elevenlabs.io and add it to My Voices, then check again.")


def cmd_adopt(lines: list[Line], cast: dict, args: argparse.Namespace) -> int:
    """Records mp3s made elsewhere (the ElevenLabs app or connector, same voice and model) as current, so they aren't paid
    for again. Without --only it adopts only files that have no record yet; with --only it re-adopts those lines."""
    model = args.model or cast.get("model", "eleven_v3")
    fmt = cast.get("output_format", "mp3_44100_128")
    old = read_manifest(args.out)
    hashes = {k: v["hash"] for k, v in old.items() if v.get("hash")}
    adopted = []
    for ln in _select(lines, args.only):
        sp = cast["speakers"][ln.speaker]
        if not (args.out / f"{ln.id}.mp3").exists() or not voice_id_from(sp.get("voice_id", "")):
            continue
        if not args.only and ln.id in hashes:
            continue
        hashes[ln.id] = line_hash(ln, sp, model, fmt)
        adopted.append(ln.id)
    write_manifest(lines, cast, args.out, hashes)
    print(f"Adopted {len(adopted)} line(s): {' '.join(adopted) or '-'}")
    return 0


def cmd_generate(lines: list[Line], cast: dict, args: argparse.Namespace) -> int:
    model = args.model or cast.get("model", "eleven_v3")
    fmt = cast.get("output_format", "mp3_44100_128")
    speakers = cast["speakers"]
    out_dir: Path = args.out
    old = read_manifest(out_dir)
    hashes = {k: v["hash"] for k, v in old.items() if v.get("hash")}

    todo, cached, uncast = [], 0, {}
    for ln in _select(lines, args.only):
        sp = speakers[ln.speaker]
        if not voice_id_from(sp.get("voice_id", "")):
            uncast[ln.speaker] = uncast.get(ln.speaker, 0) + 1
            continue
        h = line_hash(ln, sp, model, fmt)
        if not args.force and hashes.get(ln.id) == h and (out_dir / f"{ln.id}.mp3").exists():
            cached += 1
            continue
        todo.append((ln, h))

    chars = sum(len(spoken_text(ln, model)) for ln, _ in todo)
    for name, n in sorted(uncast.items()):
        print(f"skip: {name} has no voice_id in voices.json ({n} lines)")
    print(f"{len(todo)} lines to generate ({chars:,} characters, model {model}); {cached} already up to date.")
    if args.dry_run:
        for ln, _ in todo:
            print(f"  {ln.id:22} {ln.speaker:10} {spoken_text(ln, model)}")
        return 0
    if not todo:
        write_manifest(lines, cast, out_dir, hashes)
        return 0

    client = _client()
    out_dir.mkdir(parents=True, exist_ok=True)
    stop = threading.Event()  # a bad key or an empty quota stops everything
    dead: set[str] = set()     # speakers whose voice can't be found
    lock = threading.Lock()
    failed: list[str] = []

    def work(ln: Line, h: str) -> None:
        if stop.is_set() or ln.speaker in dead:
            failed.append(f"{ln.id}: skipped")
            return
        try:
            audio = synthesize(client, ln, speakers[ln.speaker], model, fmt)
        except Exception as err:
            status, code, msg = _api_detail(err)
            if status == 401 or code in {"quota_exceeded", "invalid_api_key", "missing_permissions"}:
                stop.set()
                failed.append(f"{ln.id}: {code or status} {msg} (stopping)")
            elif code == "voice_not_found" or status == 404:
                with lock:
                    dead.add(ln.speaker)
                failed.append(f"{ln.id}: {ln.speaker}'s voice was not found. If it's a Voice Library voice, add it to "
                              "My Voices on elevenlabs.io")
            else:
                failed.append(f"{ln.id}: {status} {code} {msg}")
            return
        tmp = out_dir / f".{ln.id}.mp3.part"
        tmp.write_bytes(audio)
        os.replace(tmp, out_dir / f"{ln.id}.mp3")
        with lock:
            hashes[ln.id] = h
        print(f"  ok  {ln.id:22} {ln.speaker:10} {len(audio) // 1024} KB")

    try:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            for fut in as_completed([pool.submit(work, ln, h) for ln, h in todo]):
                fut.result()
    except KeyboardInterrupt:
        stop.set()
        print("Interrupted; keeping what finished.")
    finally:
        write_manifest(lines, cast, out_dir, hashes)

    done = len(todo) - len(failed)
    print(f"Generated {done} of {len(todo)} lines into {out_dir.relative_to(ROOT) if out_dir.is_relative_to(ROOT) else out_dir}.")
    for f in failed:
        print("  FAILED " + f)
    return 1 if failed else 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--dry-run", action="store_true", help="validate and list what would be generated; no key, no API calls")
    p.add_argument("--check", action="store_true", help="check the key, the cast voices and the characters left")
    p.add_argument("--my-voices", action="store_true", help="list the voices in your ElevenLabs account")
    p.add_argument("--manifest-only", action="store_true", help="rewrite voice/manifest.json and .js from the files on disk")
    p.add_argument("--adopt", action="store_true", help="count mp3s made in the ElevenLabs app or connector as up to date")
    p.add_argument("--only", nargs="+", default=[], metavar="WHAT", help="scene, speaker or line id (any mix)")
    p.add_argument("--force", action="store_true", help="regenerate even if a line is up to date")
    p.add_argument("--model", default="", help="override the model in voices.json (e.g. eleven_multilingual_v2)")
    p.add_argument("--workers", type=int, default=2, help="parallel requests (keep within your plan's concurrency)")
    p.add_argument("--out", type=Path, default=OUT_DIR, help="output folder (default audio/voice)")
    args = p.parse_args(argv)
    args.out = args.out.resolve()

    lines, cast = load_lines(), load_cast()
    bad = problems(lines, cast)
    if bad:
        print("Fix these in audio/lines.csv or audio/voices.json first:")
        print("\n".join("  " + b for b in bad))
        return 2
    if args.my_voices:
        cmd_my_voices()
        return 0
    if args.check:
        cmd_check(cast, lines)
        return 0
    if args.adopt:
        return cmd_adopt(lines, cast, args)
    if args.manifest_only:
        old = read_manifest(args.out)
        write_manifest(lines, cast, args.out, {k: v["hash"] for k, v in old.items() if v.get("hash")})
        print(f"Manifest written for {len(lines)} lines.")
        return 0
    return cmd_generate(lines, cast, args)


if __name__ == "__main__":
    sys.exit(main())
