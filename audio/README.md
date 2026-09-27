# audio/

Owner: **Anshul**. ElevenLabs voices, sound effects and music.

Planned files: `gen_audio.py`, `lines.csv`, `sfx.csv`, `music.csv`, and the generated files. Library voices only (no cloning real people).
Line bank: [docs/LORE.md](../docs/LORE.md#voice-line-bank).

## Voice pipeline (built Sat 26 Sept)

- `lines.csv`: id, speaker, text. Only lines that still fit the direct-movement design (the old Lookout/Perfumer/Taster
  roles and the "brain steers the fly" lines were dropped or rewritten for Helmsman/Liftmaster/Wingmaster/Seer).
- `python audio/gen_audio.py --dry-run` lists what would be made; without the flag it writes `audio/out/<id>.mp3`
  (skips existing files). Needs `ELEVENLABS_API_KEY` and `ELEVEN_VOICE_HERALD|PRINCESS|JESTER|RIVAL` in `.env`.
- Godot: `host/scripts/voice_player.gd` plays `{"kind":"voice","id":...}` from `audio/out/` and `{"kind":"voice_live","mp3_b64":...}`
  from the Chronicle. Add it to a scene with `add_child(preload("res://scripts/voice_player.gd").new())`.
