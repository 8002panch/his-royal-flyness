extends Node

## Plays the campaign's voice lines and sound effects (audio/, made by audio/gen_voices.py; see docs/TECH.md, "Voices").
##
## court_main.gd adds this node when the file exists. It hears the server's events through GameState, the keyboard demo's
## through court_main, and every state frame through court_main's `on_state` call.
##
## Events it plays:
##   {"kind": "voice", "id": "C01_P4_PROSPERO"}   that line, after its `sfx` cue from the manifest has a short head start.
##                                                  A new line cuts off the one playing (a comic panel changed).
##   {"kind": "sfx", "id": "GIANT_SWAT"}          one sound.
##   {"kind": "dodge" | "hit", "fight": "giant" | "father", "n": 3}
##                                                  an attack resolved: its sound, then sometimes one shout from that
##                                                  fight's pool (the GIANT / FATHER scenes in audio/lines.csv; a milestone
##                                                  such as dodge 5 always speaks). Without `n` the dodges and hits are counted.
##   {"kind": "splat"} (the keyboard demo's hit) counts as a Giant hit; {"kind": "win"} is a cheer.
## The Seer's secret: nothing here plays on a warning ({"kind": "giant"} and the H_WARN_GIANT caption stay silent), a shout
## never starts or stops because a warning began, and every sound file is mono.
##
## Host-side moments from the state feed (never from offline sample frames): a role filled (H_ROLE_*), a role dropped
## (H_FAINTED_*) and the True Prince / Changeling swap (H_CHANGELING, H_TRUE_PRINCE). They go out as ordinary voice events
## on GameState, so the caption scroll shows them, and they wait their turn instead of talking over a line.
##
## Files: res://audio/ if the folder is copied into the project, else the repo's audio/ next to host/ (fine when running
## from the project folder; an exported build needs the copy). A line whose take is stale or missing stays silent.

const CUE_LEAD_S := 0.9         # a line starts this long after its sound cue, or when the cue ends if sooner
const SHOUT_CHANCE := 0.6       # share of ordinary dodges and hits that get a shout
const GAP_S := 0.2              # between queued lines
const BUZZ_ID := "FLY_BUZZ_LOOP"
const BUZZ_DUCK_DB := -8.0      # the flight buzz steps back while someone speaks
const FLYING_SPEED := 0.05      # |v| above this counts as flying
const RESOLVE_SOUND := {
	"giant": {"dodge": "GIANT_SWAT", "hit": "GIANT_SPLAT"},
	"father": {"dodge": "FATHER_MISS", "hit": "FATHER_HIT"},
}
const MILESTONES := {           # [fight, kind, n] -> the pool that replaces the ordinary one
	"giant|dodge|5": "after dodge 5", "giant|dodge|9": "after dodge 9", "giant|hit|2": "after hit 2",
	"father|dodge|4": "after dodge 4", "father|hit|1": "after the hit",
}

var audio_dir := ""
var lines := {}          # id -> voice manifest entry
var sounds := {}         # id -> sfx manifest entry
var pools := {}          # "giant|after a dodge" -> [ids]
var history: Array[String] = []   # "line:ID" / "sound:ID", in the order they started (tests read it)
var rng := RandomNumberGenerator.new()

var _t := 0.0
var _speak_id := ""
var _speak_at := 0.0
var _busy_until := 0.0
var _queue: Array[String] = []
var _reply := {}         # setup line id -> reply id (a pool line without a cue answers the one before it)
var _counts := {}        # "giant|dodge" -> n, when the server doesn't send n
var _last_shout := ""
var _roles := {}
var _brain := ""
var _room := ""
var _live_seen := false
var _voice: AudioStreamPlayer
var _buzz: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _streams := {}


func _ready() -> void:
	rng.randomize()
	_voice = _player()
	_buzz = _player()
	for i in 3:
		_sfx.append(_player())
	_find_audio()
	_load_manifests()
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.event_received.connect(_on_event)


func _exit_tree() -> void:
	for p in [_voice, _buzz] + _sfx:
		p.stop()
		p.stream = null
	_streams.clear()


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


func _find_audio() -> void:
	var beside := ProjectSettings.globalize_path("res://").path_join("../audio").simplify_path()
	for dir in ["res://audio", beside]:
		if FileAccess.file_exists(dir.path_join("voice/manifest.json")):
			audio_dir = dir
			return
	push_warning("VoicePlayer: no audio/voice/manifest.json in res://audio or %s; voices stay silent" % beside)


func _load_manifests() -> void:
	if audio_dir == "":
		return
	var voice: Variant = JSON.parse_string(FileAccess.get_file_as_string(audio_dir.path_join("voice/manifest.json")))
	if voice is Dictionary:
		var fights: Array = []
		for e in voice.get("lines", []):
			lines[str(e["id"])] = e
			if str(e.get("scene", "")) in ["GIANT", "FATHER"]:
				fights.append(e)
		for i in fights.size():
			var e: Dictionary = fights[i]
			if e.get("sfx") == null and i > 0:  # a reply: it follows the line before it, never picked on its own
				_reply[str(fights[i - 1]["id"])] = str(e["id"])
				continue
			var key := "%s|%s" % [str(e["scene"]).to_lower(), str(e.get("panel", ""))]
			if not pools.has(key):
				pools[key] = []
			pools[key].append(str(e["id"]))
	var sfx: Variant = JSON.parse_string(FileAccess.get_file_as_string(audio_dir.path_join("sfx/manifest.json")))
	if sfx is Dictionary:
		for e in sfx.get("sounds", []):
			sounds[str(e["id"])] = e


func _stream(folder: String, entry: Variant) -> AudioStreamMP3:
	if not entry is Dictionary or entry.get("file") == null or bool(entry.get("stale", false)):
		return null
	var path := audio_dir.path_join(folder).path_join(str(entry["file"]))
	if _streams.has(path):
		return _streams[path]
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var s := AudioStreamMP3.new()
	s.data = bytes
	s.loop = bool(entry.get("loop", false))
	_streams[path] = s
	return s


func busy() -> bool:
	return _speak_id != "" or _t < _busy_until


## A voice line: its cue first, then the line. Cuts off whatever line is playing. `skip_cue` names a sound that already
## played for this moment, so it isn't heard twice.
func play_line(id: String, skip_cue: String = "") -> bool:
	var entry: Variant = lines.get(id)
	var stream := _stream("voice", entry)
	if stream == null:
		return false
	_voice.stop()
	var lead := 0.0
	var cue: Variant = entry.get("sfx")
	if cue != null and str(cue) != skip_cue and play_sound(str(cue)):
		lead = minf(CUE_LEAD_S, _stream("sfx", sounds.get(str(cue))).get_length())
	elif skip_cue != "":
		lead = 0.35  # let the resolution sound land first
	_speak_id = id
	_speak_at = _t + lead
	_busy_until = _speak_at + stream.get_length() + GAP_S
	if lead <= 0.0:
		_start_voice()
	return true


func play_sound(id: String) -> bool:
	var entry: Variant = sounds.get(id)
	var stream := _stream("sfx", entry)
	if stream == null or stream.loop:
		return false
	var p := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx.size()
	p.stream = stream
	p.play()
	history.append("sound:" + id)
	return true


## A host-side line: sent as a voice event on GameState (so it gets a caption), or queued while someone is talking.
func say(id: String) -> void:
	if not lines.has(id):
		return
	if busy():
		if not _queue.has(id):
			_queue.append(id)
		return
	var e: Dictionary = lines[id]
	var ev := {"t": "event", "kind": "voice", "id": id, "speaker": str(e.get("name", "")), "caption": str(e.get("caption", "")),
		"host": true}
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.event_received.emit(ev)  # _on_event plays it
	else:
		_on_event(ev)


func _start_voice() -> void:
	var id := _speak_id
	_speak_id = ""
	_voice.stream = _stream("voice", lines.get(id))
	_voice.play()
	history.append("line:" + id)
	if _reply.has(id):
		_queue.push_front(_reply[id])


func _process(delta: float) -> void:
	_t += delta
	if _speak_id != "" and _t >= _speak_at:
		_start_voice()
	if not busy() and not _queue.is_empty():
		say(_queue.pop_front())
	if _buzz.playing:
		_buzz.volume_db = BUZZ_DUCK_DB if busy() else 0.0


func _on_event(ev: Dictionary) -> void:
	var kind := str(ev.get("kind", ""))
	match kind:
		"voice":
			play_line(str(ev.get("id", "")))
		"sfx":
			play_sound(str(ev.get("id", "")))
		"dodge", "hit", "splat":
			_resolved(str(ev.get("fight", "giant")), "dodge" if kind == "dodge" else "hit", ev.get("n"))
		"win", "charmed":
			play_sound("COURT_CHEER")
		_:
			pass  # "giant" is a warning: silent on purpose (the Seer's secret)


## An attack resolved (never called at warning onset). Its sound always plays; a shout sometimes follows.
func _resolved(fight: String, kind: String, n: Variant) -> void:
	var key := "%s|%s" % [fight, kind]
	_counts[key] = int(n) if n != null else int(_counts.get(key, 0)) + 1
	var sound: String = RESOLVE_SOUND.get(fight, {}).get(kind, "")
	if sound != "":
		play_sound(sound)
	var milestone: String = MILESTONES.get("%s|%d" % [key, _counts[key]], "")
	var pool: Array = pools.get("%s|%s" % [fight, milestone], []) if milestone != "" else []
	if pool.is_empty():
		pool = pools.get("%s|after a %s" % [fight, kind], [])
		if rng.randf() > SHOUT_CHANCE:
			return
	if pool.is_empty() or busy():
		return  # never talk over a line
	var pick: Array = pool.filter(func(id): return id != _last_shout)
	if pick.is_empty():
		pick = pool
	_last_shout = str(pick[rng.randi() % pick.size()])
	play_line(_last_shout, sound)


## Every state frame (court_main forwards live and keyboard-demo frames).
func on_state(msg: Dictionary) -> void:
	var fly: Variant = msg.get("fly", {})
	var speed := 0.0
	if fly is Dictionary:
		speed = absf(float(fly.get("vx", 0.0))) + absf(float(fly.get("vy", 0.0))) + absf(float(fly.get("vz", 0.0)))
	if bool(msg.get("offline_sample", false)) or bool(msg.get("sample", false)):
		_set_buzz(false)
		return  # fixture frames: no buzz, no host-side lines
	_set_buzz(speed > FLYING_SPEED)
	var filled := {}
	var players: Variant = msg.get("players", [])
	if players is Array:
		for p in players:
			if p is Dictionary and str(p.get("role", "")) != "":
				filled[str(p["role"])] = true
	var brain := str(msg.get("brain", ""))
	var room := str(msg.get("room", ""))
	if _live_seen and room == _room:
		# one phone at a time is a person joining or dropping; several at once is a new room or a relay reconnect: stay quiet
		var joined := filled.keys().filter(func(r): return not _roles.has(r))
		var dropped := _roles.keys().filter(func(r): return not filled.has(r))
		if joined.size() == 1:
			say("H_ROLE_" + str(joined[0]).to_upper())
		if dropped.size() == 1:
			say("H_FAINTED_" + str(dropped[0]).to_upper())
		if brain != _brain:
			if brain == "changeling":
				say("H_CHANGELING")
			elif brain == "true" and _brain == "changeling":
				say("H_TRUE_PRINCE")
	_live_seen = true
	_roles = filled
	_brain = brain
	_room = room


func _set_buzz(on: bool) -> void:
	if on and not _buzz.playing:
		var s := _stream("sfx", sounds.get(BUZZ_ID))
		if s != null:
			_buzz.stream = s
			_buzz.play()
	elif not on and _buzz.playing:
		_buzz.stop()
