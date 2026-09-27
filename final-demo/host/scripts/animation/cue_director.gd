extends Node
## Local presentation timeline, designed for the forthcoming script.
## Cues do not change server state, world position, audio, or outcome.
signal cue_rejected(reason: String)
signal finished
var actors: Dictionary = {}
var cues: Array = []
var cursor := 0
var clock := 0.0
var running := false

func register_actor(id: String, actor: Node) -> void:
	actors[id] = actor

func load_cues(path: String) -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.get("cues") is Array:
		cue_rejected.emit("Cue file needs a cues array")
		return false
	var candidate: Array = parsed.cues.duplicate(true)
	for cue in candidate:
		if not cue is Dictionary or not cue.get("at") is float and not cue.get("at") is int:
			cue_rejected.emit("Each cue needs numeric at (seconds)")
			return false
		if float(cue.at) < 0.0 or not actors.has(str(cue.get("actor",""))):
			cue_rejected.emit("Negative time or unregistered actor")
			return false
	candidate.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a.at) < float(b.at))
	cues = candidate
	return true

func play() -> void:
	cursor = 0
	clock = 0.0
	running = true

func stop() -> void:
	running = false

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not running: return
	clock += maxf(0.0,delta)
	while cursor < cues.size() and float(cues[cursor].at) <= clock:
		var cue: Dictionary = cues[cursor]
		cursor += 1
		var actor: Node = actors.get(str(cue.actor))
		if not is_instance_valid(actor):
			cue_rejected.emit("Actor was removed: " + str(cue.actor))
			continue
		if cue.has("motion"):
			actor.call("set_motion",str(cue.motion),float(cue.get("speed",0.5)),float(cue.get("facing",1.0)))
		if cue.has("gesture"):
			if not actor.call("play_gesture",str(cue.gesture),float(cue.get("duration",1.2))):
				cue_rejected.emit("Unsupported gesture: " + str(cue.gesture))
	if cursor >= cues.size():
		running = false
		finished.emit()
