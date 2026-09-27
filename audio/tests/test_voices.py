from __future__ import annotations

import argparse
import json
import tempfile
import unittest
from pathlib import Path

from audio import gen_voices as gv

CAST = {"clown", "hamlet", "miranda", "prospero", "tinman", "cheapdate", "rutabaga"}  # GAME.md, "Cast lock"
BANNED_GENES = ("fruitless", "ken and barbie", "doublesex", "transformer")  # GAME.md, "Tone rules"
VID = {"clown": "AAAAAAAAAAAAAAAAAAAA", "hamlet": "BBBBBBBBBBBBBBBBBBBB"}


class LineBankTests(unittest.TestCase):
    def setUp(self) -> None:
        self.lines, self.cast = gv.load_lines(), gv.load_cast()

    def test_bank_has_no_problems(self) -> None:
        self.assertEqual(gv.problems(self.lines, self.cast), [])

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

    def convert(self, voice_id: str, *, text: str, **_: object):
        if voice_id in self.missing:
            from elevenlabs.core.api_error import ApiError

            raise ApiError(status_code=404, body={"detail": {"status": "voice_not_found", "message": "gone"}})
        self.calls.append((voice_id, text))
        yield b"ID3fake-"
        yield text.encode()


class FakeClient:
    def __init__(self, tts: FakeTTS) -> None:
        self.text_to_speech = tts


class GenerateTests(unittest.TestCase):
    def setUp(self) -> None:
        try:
            import elevenlabs  # noqa: F401
        except ImportError:
            self.skipTest("elevenlabs is not installed (pip install -r requirements.txt)")
        self.tmp = Path(tempfile.mkdtemp())
        self.lines = [ln for ln in gv.load_lines() if ln.scene == "C01"]
        self.cast = gv.load_cast()
        for name, vid in VID.items():
            self.cast["speakers"][name]["voice_id"] = vid
        self.tts = FakeTTS()
        self._orig = gv._client
        gv._client = lambda: FakeClient(self.tts)

    def tearDown(self) -> None:
        gv._client = self._orig

    def run_gen(self, **kw: object) -> int:
        args = argparse.Namespace(only=[], force=False, dry_run=False, model="", workers=2, out=self.tmp)
        vars(args).update(kw)
        return gv.cmd_generate(self.lines, self.cast, args)

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

    def test_dry_run_sends_and_writes_nothing(self) -> None:
        self.assertEqual(self.run_gen(dry_run=True), 0)
        self.assertEqual(self.tts.calls, [])
        self.assertFalse((self.tmp / "manifest.json").exists())


if __name__ == "__main__":
    unittest.main()
