from __future__ import annotations

import argparse
import dataclasses
import json
import re
import tempfile
import unittest
from pathlib import Path

from audio import gen_voices as gv

CAST = {"clown", "hamlet", "miranda", "prospero", "tinman", "cheapdate", "rutabaga"}  # GAME.md, "Cast lock"
BANNED_GENES = ("fruitless", "ken and barbie", "doublesex", "transformer")  # GAME.md, "Tone rules"
VID = {"clown": "AAAAAAAAAAAAAAAAAAAA", "hamlet": "BBBBBBBBBBBBBBBBBBBB"}


class LineBankTests(unittest.TestCase):
    def setUp(self) -> None:
        self.lines, self.cast, self.sounds = gv.load_lines(), gv.load_cast(), gv.load_sounds()

    def test_bank_has_no_problems(self) -> None:
        self.assertEqual(gv.problems(self.lines, self.cast, self.sounds), [])

    def test_the_suitors_ask_and_explain_their_own_questions(self) -> None:
        asker = {"Q01": "tinman", "Q02": "rutabaga", "Q03": "cheapdate"}
        for ln in self.lines:
            if ln.id.endswith(("_QUESTION", "_EXPLAIN")):
                self.assertEqual(ln.speaker, asker[ln.scene], ln.id)

    def test_miranda_is_passionate_only_when_she_refuses(self) -> None:
        miranda = [ln for ln in self.lines if ln.speaker == "miranda"]
        self.assertEqual([ln.id for ln in miranda if "passionate" in ln.line], ["E02_P3_MIRANDA"])
        self.assertEqual(self.cast["speakers"]["miranda"]["stability"], 1.0)

    def test_fight_shouts_never_give_away_the_attack(self) -> None:
        # The Seer alone knows where and when: a shout names no direction or timing and plays only once an attack resolves.
        hints = re.compile(r"\b(left|right|up|down|above|below|behind|ahead|overhead|beneath|duck|dive|climb|now|soon|"
                           r"incoming|coming|look out|watch out|here it comes)\b", re.I)
        barks = [ln for ln in self.lines if ln.scene in ("GIANT", "FATHER")]
        self.assertGreaterEqual(len(barks), 20)
        for ln in barks:
            self.assertIsNone(hints.search(ln.caption), ln.id)
            self.assertTrue(ln.panel.startswith("after"), ln.id)
            self.assertLessEqual(len(ln.caption.split()), 12, ln.id)
            self.assertTrue(ln.sfx or "reply" in ln.note.lower(), ln.id)  # a reply follows its cue
        self.assertTrue(all(ln.branch == "giant_loss" for ln in barks if ln.scene == "FATHER"))
        self.assertGreaterEqual(sum(ln.speaker == "miranda" for ln in barks), 8)

    def test_giant_sounds_are_never_directional_or_early(self) -> None:
        giant = [s for s in self.sounds if s.id.startswith(("GIANT_", "FATHER_", "COURT_"))]
        self.assertTrue(giant)
        self.assertTrue(all(gv.sound_post(s).startswith("mono") for s in self.sounds))
        for s in giant:
            self.assertNotIn("warning onset", s.when.lower().replace("never at warning onset", ""), s.id)

    def test_bad_rows_are_caught(self) -> None:
        bad = gv.Line("X_1", "S", "", "", "clown", "Hi.", "", stability="0.7", sfx="NOPE")
        found = gv.problems([bad], self.cast, self.sounds)
        self.assertTrue(any("stability" in p for p in found) and any("sfx" in p for p in found), found)

    def test_only_the_final_cast_speaks(self) -> None:
        self.assertEqual(set(self.cast["speakers"]), CAST)
        self.assertEqual({ln.speaker for ln in self.lines}, CAST)

    def test_no_banned_gene_names(self) -> None:
        for ln in self.lines:
            for gene in BANNED_GENES:
                self.assertNotIn(gene, ln.line.lower(), ln.id)

    def test_every_quiz_has_both_outcomes_and_every_ending_exists(self) -> None:
        for quiz in ("Q01", "Q02", "Q03"):
            branches = {ln.branch for ln in self.lines if ln.scene == quiz}
            self.assertTrue({"correct", "wrong"} <= branches, quiz)
            self.assertTrue(any(ln.id == f"{quiz}_QUESTION" for ln in self.lines), quiz)
        e01 = {ln.branch for ln in self.lines if ln.scene == "E01"}
        self.assertTrue({"giant_win", "father_win"} <= e01)
        for scene in ("TUTORIAL", "C01", "STAGE1", "STAGE2", "C02", "C03", "C04", "E02"):
            self.assertTrue(any(ln.scene == scene for ln in self.lines), scene)


class TextTests(unittest.TestCase):
    def test_captions_drop_audio_tags(self) -> None:
        self.assertEqual(gv.caption("[hiccups] Hamlet! Excellent. [laughs]  Yes."), "Hamlet! Excellent. Yes.")

    def test_only_v3_hears_the_tags(self) -> None:
        ln = gv.Line("X", "S", "", "", "clown", "[sighs] Fine.", "")
        self.assertEqual(gv.spoken_text(ln, "eleven_v3"), "[sighs] Fine.")
        self.assertEqual(gv.spoken_text(ln, "eleven_multilingual_v2"), "Fine.")

    def test_line_stability_overrides_the_speaker_and_changes_the_hash(self) -> None:
        sp = {"voice_id": "A" * 20, "stability": 1.0}
        plain = gv.Line("X", "S", "", "", "miranda", "Hi.", "")
        loud = gv.Line("X", "S", "", "", "miranda", "Hi.", "", stability="0.5")
        self.assertEqual((gv.stability_for(plain, sp), gv.stability_for(loud, sp)), (1.0, 0.5))
        self.assertNotEqual(gv.line_hash(plain, sp, "eleven_v3", "mp3"), gv.line_hash(loud, sp, "eleven_v3", "mp3"))

    def test_volume_and_level_changes_need_no_new_take(self) -> None:
        self.assertEqual(gv.in_place("mono,volume_db=0", "mono,volume_db=-6"), {"volume_db": -6.0, "level": None})
        self.assertEqual(gv.in_place("tempo=1.15,max_pause=0.4", "tempo=1.15,max_pause=0.4,level=-16"),
                         {"volume_db": 0.0, "level": -16.0})
        self.assertIsNone(gv.in_place("tempo=1.1,max_pause=0.4", "tempo=1.2,max_pause=0.4"))  # tempo can't be undone
        self.assertIsNone(gv.in_place("level=-16", ""))
        self.assertIsNone(gv.in_place("", "level=-16"))  # a raw take is simply polished

    def test_voice_id_from_ids_and_links(self) -> None:
        vid = "JBFqnCBsd6RMkjVDRZzb"
        self.assertEqual(gv.voice_id_from(vid), vid)
        self.assertEqual(gv.voice_id_from(f"https://elevenlabs.io/app/voice-library?voiceId={vid}"), vid)
        self.assertEqual(gv.voice_id_from(f"https://elevenlabs.io/app/voice-lab/share/{'a' * 64}/{vid}"), vid)
        self.assertEqual(gv.voice_id_from(""), "")


class FakeTTS:
    def __init__(self, missing: set[str] = frozenset()) -> None:
        self.calls: list[tuple[str, str]] = []
        self.missing = missing
        self.bad_key = False
        self.attempts = 0

    def convert(self, voice_id: str, *, text: str, **_: object):
        self.attempts += 1
        if self.bad_key:
            from elevenlabs.core.api_error import ApiError

            raise ApiError(status_code=400, body={"detail": {"status": "api_key_id_used_as_api_key", "message": "no"}})
        if voice_id in self.missing:
            from elevenlabs.core.api_error import ApiError

            raise ApiError(status_code=404, body={"detail": {"status": "voice_not_found", "message": "gone"}})
        self.calls.append((voice_id, text))
        yield b"ID3fake-"
        yield text.encode()


class FakeSFX:
    def __init__(self) -> None:
        self.calls: list[str] = []

    def convert(self, *, text: str, **_: object):
        self.calls.append(text)
        yield b"ID3sound"


class FakeClient:
    def __init__(self, tts: FakeTTS, sfx: FakeSFX | None = None) -> None:
        self.text_to_speech = tts
        self.text_to_sound_effects = sfx or FakeSFX()


class GenerateTests(unittest.TestCase):
    def setUp(self) -> None:
        try:
            import elevenlabs  # noqa: F401
        except ImportError:
            self.skipTest("elevenlabs is not installed (pip install -r requirements.txt)")
        self.tmp = Path(tempfile.mkdtemp())
        self.lines = [ln for ln in gv.load_lines() if ln.scene == "C01"]
        self.cast = gv.load_cast()
        for sp in self.cast["speakers"].values():  # only the fake voices below are cast
            sp["voice_id"] = ""
        for name, vid in VID.items():
            self.cast["speakers"][name]["voice_id"] = vid
        for sp in self.cast["speakers"].values():  # polish is tested on real audio below
            sp.pop("tempo", None), sp.pop("max_pause", None), sp.pop("level", None)
        self.tts, self.sfx = FakeTTS(), FakeSFX()
        self.sounds = gv.load_sounds()[:2]
        self._orig = gv._client
        gv._client = lambda: FakeClient(self.tts, self.sfx)

    def tearDown(self) -> None:
        gv._client = self._orig

    def run_gen(self, **kw: object) -> int:
        args = argparse.Namespace(only=[], force=False, dry_run=False, model="", workers=2, out=self.tmp,
                                  sfx_out=self.tmp / "sfx", no_sfx=True)
        vars(args).update(kw)
        return gv.cmd_generate(self.lines, self.sounds, self.cast, args)

    def manifest(self) -> dict:
        return {e["id"]: e for e in json.loads((self.tmp / "manifest.json").read_text())["lines"]}

    def test_generates_cast_lines_then_caches_them(self) -> None:
        self.assertEqual(self.run_gen(), 0)
        cast_lines = [ln for ln in self.lines if ln.speaker in VID]
        self.assertEqual(len(self.tts.calls), len(cast_lines))
        m = self.manifest()
        for ln in self.lines:
            self.assertEqual(m[ln.id]["file"] is not None, ln.speaker in VID, ln.id)  # Prospero isn't cast: skipped
        self.assertTrue((self.tmp / "manifest.js").read_text().startswith("//"))
        self.tts.calls.clear()
        self.assertEqual(self.run_gen(), 0)
        self.assertEqual(self.tts.calls, [])

    def test_recasting_one_voice_regenerates_only_its_lines(self) -> None:
        self.run_gen()
        self.tts.calls.clear()
        self.cast["speakers"]["hamlet"]["voice_id"] = "CCCCCCCCCCCCCCCCCCCC"
        self.run_gen()
        self.assertEqual({v for v, _ in self.tts.calls}, {"CCCCCCCCCCCCCCCCCCCC"})
        self.assertEqual(len(self.tts.calls), sum(ln.speaker == "hamlet" for ln in self.lines))

    def test_a_missing_voice_fails_its_lines_and_keeps_the_rest(self) -> None:
        self.tts.missing = {VID["hamlet"]}
        self.assertEqual(self.run_gen(), 1)
        m = self.manifest()
        self.assertTrue(all(m[ln.id]["file"] for ln in self.lines if ln.speaker == "clown"))
        self.assertFalse(any(m[ln.id]["file"] for ln in self.lines if ln.speaker == "hamlet"))

    def test_sounds_are_generated_once(self) -> None:
        self.assertEqual(self.run_gen(no_sfx=False), 0)
        self.assertEqual(len(self.sfx.calls), len(self.sounds))
        m = json.loads((self.tmp / "sfx" / "manifest.json").read_text())
        self.assertTrue(all(e["file"] for e in m["sounds"]))
        self.sfx.calls.clear()
        self.run_gen(no_sfx=False)
        self.assertTrue(self.sfx.calls == [] or gv._ffmpeg() is not None)  # without ffmpeg nothing is re-sent either

    def test_adopted_files_are_not_generated_again(self) -> None:
        clown = [ln for ln in self.lines if ln.speaker == "clown"]
        self.tmp.mkdir(exist_ok=True)
        (self.tmp / f"{clown[0].id}.mp3").write_bytes(b"ID3made-in-the-app")
        gv.cmd_adopt(self.lines, self.cast, argparse.Namespace(only=[], model="", out=self.tmp))
        self.assertEqual(self.manifest()[clown[0].id]["file"], f"{clown[0].id}.mp3")
        self.run_gen()
        self.assertNotIn(gv.spoken_text(clown[0], "eleven_v3"), [t for _, t in self.tts.calls])
        self.assertEqual((self.tmp / f"{clown[0].id}.mp3").read_bytes(), b"ID3made-in-the-app")

    def test_a_rewritten_line_is_marked_stale_until_regenerated(self) -> None:
        self.run_gen()
        i = next(i for i, ln in enumerate(self.lines) if ln.speaker == "clown")
        self.lines[i] = ln = dataclasses.replace(self.lines[i], line="[briskly] A brand new line.")
        old = {k: v["hash"] for k, v in self.manifest().items() if v["hash"]}
        gv.write_manifest(self.lines, self.cast, self.tmp, old)
        m = self.manifest()
        self.assertEqual([k for k, v in m.items() if v["stale"]], [ln.id])
        self.assertEqual(m[ln.id]["file"], f"{ln.id}.mp3")  # the old take is still on disk
        self.run_gen()
        self.assertFalse(any(v["stale"] for v in self.manifest().values()))

    def test_a_bad_key_stops_the_run_instead_of_failing_every_line(self) -> None:
        self.tts.bad_key = True
        self.assertEqual(self.run_gen(workers=1), 1)
        self.assertEqual(self.tts.attempts, 1)

    def test_dry_run_sends_and_writes_nothing(self) -> None:
        self.assertEqual(self.run_gen(dry_run=True), 0)
        self.assertEqual(self.tts.calls, [])
        self.assertFalse((self.tmp / "manifest.json").exists())


class PolishTests(unittest.TestCase):
    def setUp(self) -> None:
        if gv._ffmpeg() is None:
            self.skipTest("no ffmpeg (pip install imageio-ffmpeg)")
        import numpy as np
        import subprocess

        self.np, self.tmp = np, Path(tempfile.mkdtemp())
        tone = lambda sec: (0.3 * np.sin(2 * np.pi * 220 * np.arange(int(gv.SR * sec)) / gv.SR)).astype(np.float32)  # noqa: E731
        x = np.concatenate([tone(1.0), np.zeros(gv.SR * 2, np.float32), tone(1.0)])  # 1 s, a 2 s pause, 1 s
        self.src = self.tmp / "take.mp3"
        subprocess.run([gv._ffmpeg(), "-v", "error", "-f", "f32le", "-ar", str(gv.SR), "-ac", "1", "-i", "-",
                        "-c:a", "libmp3lame", str(self.src)], input=x.tobytes(), check=True)

    def seconds(self, path: Path) -> float:
        import subprocess

        raw = subprocess.run([gv._ffmpeg(), "-v", "error", "-i", str(path), "-ac", "1", "-ar", str(gv.SR), "-f", "f32le", "-"],
                             capture_output=True, check=True).stdout
        return len(raw) / 4 / gv.SR

    def test_long_pauses_shrink_and_tempo_speeds_up(self) -> None:
        before = self.seconds(self.src)
        gv.polish(self.src, tempo=1.25, max_pause=0.4)
        after = self.seconds(self.src)
        self.assertAlmostEqual(before, 4.0, delta=0.15)
        self.assertAlmostEqual(after, (2.0 + 0.4) / 1.25, delta=0.2)

    def test_level_evens_out_speech_loudness(self) -> None:
        gv.polish(self.src, level=-20.0)
        raw = __import__("subprocess").run([gv._ffmpeg(), "-v", "error", "-i", str(self.src), "-ac", "1", "-ar", str(gv.SR),
                                            "-f", "f32le", "-"], capture_output=True, check=True).stdout
        self.assertAlmostEqual(gv.speech_db(self.np.frombuffer(raw, self.np.float32)), -20.0, delta=0.7)

    def test_a_new_tempo_reuses_this_machines_raw_take(self) -> None:
        try:
            import elevenlabs  # noqa: F401
        except ImportError:
            self.skipTest("elevenlabs is not installed")
        audio, calls = self.src.read_bytes(), []

        class TTS:
            def convert(self, voice_id: str, *, text: str, **_: object):
                calls.append(text)
                yield audio

        line = gv.Line("C01_P2_CLOWN", "C01", "", "", "clown", "And not a drop tasted.", "")
        cast = gv.load_cast()
        orig, gv._client = gv._client, lambda: FakeClient(TTS())
        try:
            args = argparse.Namespace(only=[], force=False, dry_run=False, model="", workers=1, out=self.tmp,
                                      sfx_out=self.tmp / "sfx", no_sfx=True)
            self.assertEqual(gv.cmd_generate([line], [], cast, args), 0)
            first = self.seconds(self.tmp / "C01_P2_CLOWN.mp3")
            cast["speakers"]["clown"]["tempo"] = 1.5
            self.assertEqual(gv.cmd_generate([line], [], cast, args), 0)
        finally:
            gv._client = orig
        self.assertEqual(len(calls), 1)  # the second run polished the kept raw take instead of paying again
        self.assertLess(self.seconds(self.tmp / "C01_P2_CLOWN.mp3"), first * 0.9)
        self.assertEqual(gv.read_manifest(self.tmp)["C01_P2_CLOWN"]["post"], gv.voice_post(cast["speakers"]["clown"]))

    def test_a_polished_take_is_not_polished_again(self) -> None:
        line = gv.Line("C01_P2_CLOWN", "C01", "", "", "clown", "And not a drop tasted.", "")
        cast = gv.load_cast()
        sp = cast["speakers"]["clown"]
        (self.tmp / "C01_P2_CLOWN.mp3").write_bytes(self.src.read_bytes())
        h = gv.line_hash(line, sp, "eleven_v3", "mp3_44100_128")
        args = argparse.Namespace(only=[], force=False, model="", out=self.tmp, sfx_out=self.tmp / "sfx", no_sfx=True)
        raw = {line.id: {"hash": h, "post": ""}}
        jobs, _, _ = gv.plan([line], [], cast, args, raw, {})
        self.assertEqual([(j.call, j.post) for j in jobs], [(False, gv.voice_post(sp))])  # polish only, no credits
        done = {line.id: {"hash": h, "post": gv.voice_post(sp)}}
        jobs, cached, _ = gv.plan([line], [], cast, args, done, {})
        self.assertEqual((jobs, cached), ([], 1))


if __name__ == "__main__":
    unittest.main()
