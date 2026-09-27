extends Node

## Background music (autoload "Music"; audio/music/manifest.json): one track per part of the story, so the tune carries on
## from the title screen into the court. Each track loops; a scene change crossfades to the next one; the music steps back
## while a voice line plays (the voice player calls `duck`).
##
##   Music.play_for(scene, phase, ending)   from the court's state feed (court_main.gd)
##   Music.play("PROMENADE")               a track by id (the title screen)
## Track ids and their scenes are in the manifest; a scene without a track keeps the one playing.

const LEVEL_DB := -13.0       # under the voices and sounds
const DUCK_DB := -21.0        # while someone speaks
const FADE_S := 1.2

var audio_dir := ""
var tracks := {}              # id -> manifest entry
var by_scene := {}            # scene key -> id
var current := ""
var history: Array[String] = []   # "music:ID" in the order tracks started (tests read it)

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _ducked := false
var _streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	var beside := ProjectSettings.globalize_path("res://").path_join("../audio").simplify_path()
	for dir in ["res://audio", beside]:
		if FileAccess.file_exists(dir.path_join("music/manifest.json")):
			audio_dir = dir
			break
	if audio_dir == "":
		return
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(audio_dir.path_join("music/manifest.json")))
	if m is Dictionary:
		for t in m.get("tracks", []):
			tracks[str(t["id"])] = t
			for s in t.get("scenes", []):
				by_scene[str(s)] = str(t["id"])


## The track for this moment of the story: the scene's own, or at the end the ending's.
func play_for(scene: String, phase: String, ending: String = "") -> void:
	var key := scene
	if phase == "lobby" or scene == "":
		key = "LOBBY"
	elif phase == "end":
		key = "END_" + (ending if ending != "" else "wedding")
	if by_scene.has(key):
		play(by_scene[key])


func play(id: String) -> void:
	if id == current or not tracks.has(id):
		return
	var stream := _stream(id)
	if stream == null:
		return
	current = id
	history.append("music:" + id)
	var old := _players[_active]
	_active = 1 - _active
	var p := _players[_active]
	p.stream = stream
	p.volume_db = -40.0
	p.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "volume_db", _level(), FADE_S)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, FADE_S)
		tw.chain().tween_callback(old.stop)


func stop() -> void:
	current = ""
	for p in _players:
		p.stop()


## The voice player's hook: quieter while a line plays.
func duck(on: bool) -> void:
	if on == _ducked:
		return
	_ducked = on
	var p := _players[_active]
	if p.playing:
		create_tween().tween_property(p, "volume_db", _level(), 0.3)


func _level() -> float:
	return DUCK_DB if _ducked else LEVEL_DB


func _stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var bytes := FileAccess.get_file_as_bytes(audio_dir.path_join("music").path_join(str(tracks[id]["file"])))
	if bytes.is_empty():
		return null
	var s := AudioStreamMP3.new()
	s.data = bytes
	s.loop = true
	_streams[id] = s
	return s
