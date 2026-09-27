extends Node2D
## All motion is cosmetic. Caller owns world position and gameplay outcomes.
signal gesture_finished(cue: String)

@export var character_id := "hamlet"
@export var native_height := 72.0
@export var giant := false
@export var autoplay := true
var locomotion := "idle"
var speed := 0.0
var facing := 1.0
var motion_scale := 1.0
var _time := 0.0
var _gesture := ""
var _gesture_time := 0.0
var _duration := 1.2
var _step := -1
var _motion_time := 0.0
var _rests: Dictionary = {}
var _parts: Dictionary = {}

const GESTURES := ["talk", "wave", "point", "bow", "approve", "angry", "celebrate", "hit", "toast", "confused", "scan", "sing", "slam"]
const MODES := ["idle", "walk", "fly", "takeoff", "land"]

func _ready() -> void:
	for part in $Pivot.get_children():
		_parts[str(part.name)] = part
		_rests[str(part.name)] = part.position
	set_process(autoplay)
	pose_at(0.0)

func set_motion(mode: String, amount := 0.5, direction := 1.0) -> void:
	if not mode in MODES:
		push_warning("Unknown locomotion: " + mode)
		return
	if mode != locomotion:
		_motion_time = 0.0
	locomotion = mode
	speed = clampf(amount, 0.0, 1.0)
	facing = -1.0 if direction < 0.0 else 1.0
	_step = -1

func play_gesture(cue: String, seconds := 1.2) -> bool:
	if not cue in GESTURES or (cue == "slam" and not giant):
		return false
	if giant and not cue in ["slam", "hit"]:
		return false
	_gesture = cue
	_gesture_time = 0.0
	_duration = clampf(seconds, 0.15, 30.0)
	_step = -1
	return true

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_motion_time += delta
	if locomotion == "takeoff" and _motion_time >= 0.55:
		locomotion = "fly"
	elif locomotion == "land" and _motion_time >= 0.45:
		locomotion = "idle"
	if _gesture != "":
		_gesture_time += delta
		if _gesture_time >= _duration:
			var finished := _gesture
			_gesture = ""
			gesture_finished.emit(finished)
	# 30 poses/s, even on a 144 Hz display; no mesh/texture allocation here.
	var step := int(_time * 30.0)
	if step != _step:
		_step = step
		pose_at(_time)

func pose_at(t: float) -> void:
	if _parts.is_empty():
		return
	for key in _parts:
		var part: Node2D = _parts[key]
		part.position = _rests[key]
		part.rotation = 0.0
		part.scale = Vector2.ONE
	var pivot: Node2D = $Pivot
	pivot.position = Vector2.ZERO
	pivot.rotation = 0.0
	pivot.scale = Vector2(facing, 1.0)
	if giant:
		_pose_giant(pivot)
		return
	var flying := locomotion in ["fly", "takeoff"]
	var walking := locomotion == "walk"
	var beat := sin(t * TAU * lerpf(4.0, 6.0, speed))
	var stride := sin(t * TAU * lerpf(1.0, 2.4, speed))
	if flying:
		pivot.position.y = roundf((-5.0 + sin(t * 2.5) * 1.0) * motion_scale)
		if locomotion == "takeoff":
			pivot.position.y *= smoothstep(0.0,0.55,_motion_time)
		_wing("WingL", -1.0, beat)
		_wing("WingR", 1.0, beat)
		_turn("LegL", -0.13)
		_turn("LegR", 0.13)
	elif walking:
		pivot.position.y = -roundf(absf(stride) * motion_scale)
		_turn("LegL", stride * 0.14 * motion_scale)
		_turn("LegR", -stride * 0.14 * motion_scale)
		_turn("ArmL", -stride * 0.04 * motion_scale)
		_turn("ArmR", stride * 0.04 * motion_scale)
	else:
		pivot.position.y = -roundf(maxf(0.0, sin(t * 2.0)) * motion_scale)
	if locomotion == "land":
		var landing := clampf(_motion_time / 0.45,0.0,1.0)
		pivot.position.y = roundf(-5.0 * (1.0-smoothstep(0.0,0.65,landing)) * motion_scale)
		pivot.scale.y = 1.0 - sin(landing * PI) * 0.04 * motion_scale
	if _gesture == "":
		return
	var u := clampf(_gesture_time / _duration, 0.0, 1.0)
	var envelope := smoothstep(0.0, 0.18, u) * (1.0 - smoothstep(0.8, 1.0, u)) * motion_scale
	match _gesture:
		"wave": _turn("ArmR", (-0.24 + sin(t * 10.0) * 0.13) * envelope)
		"point": _turn("ArmR", -0.3 * envelope)
		"talk":
			_turn("ArmL", sin(t * 5.0) * 0.07 * envelope)
			_turn("ArmR", -sin(t * 5.0 + 0.7) * 0.08 * envelope)
		"bow":
			pivot.scale.y = 1.0 - 0.10 * envelope
			pivot.rotation = 0.045 * envelope
			_turn("ArmR", 0.1 * envelope)
		"approve":
			_turn("ArmR", -0.16 * envelope)
			pivot.position.y -= roundf(absf(sin(t * 4.0)) * envelope)
		"angry":
			_turn("ArmR", -0.22 * envelope)
			pivot.rotation = sin(t * 12.0) * 0.025 * envelope
		"celebrate":
			_turn("ArmL", 0.22 * envelope)
			_turn("ArmR", -0.22 * envelope)
			pivot.position.y -= roundf(absf(sin(t * 4.0)) * 3.0 * envelope)
		"hit": pivot.rotation = sin(t * 25.0) * 0.07 * envelope
		"toast": _turn("ArmL", 0.20 * envelope)
		"confused": pivot.rotation = sin(t * 3.0) * 0.05 * envelope
		"scan": _turn("ArmL", 0.12 * envelope)
		"sing":
			_wing("WingR", 1.0, sin(t * 25.0))
			_turn("ArmL", 0.08 * envelope)

func _wing(key: String, side: float, beat: float) -> void:
	if not _parts.has(key):
		return
	var wing: Node2D = _parts[key]
	# Folded source wings open sideways from their shoulder; the return stroke
	# foreshortens, so flight is not just the whole character bouncing.
	wing.rotation = side * (-0.64 + beat * 0.48) * motion_scale
	wing.scale.x = lerpf(1.0, 0.38 + 0.62 * absf(beat), motion_scale)

func _turn(key: String, angle: float) -> void:
	if _parts.has(key):
		_parts[key].rotation = angle

func _pose_giant(pivot: Node2D) -> void:
	if _gesture == "hit":
		pivot.rotation = sin(_gesture_time * 22.0) * 0.04 * sin(clampf(_gesture_time/_duration,0.0,1.0) * PI)
		return
	if _gesture != "slam":
		return
	var u := clampf(_gesture_time / _duration, 0.0, 1.0)
	# Anticipation, fast fall, impact hold, recoil. Root remains caller-owned.
	if u < 0.38:
		pivot.position.y = -12.0 * smoothstep(0.0, 0.38, u)
	elif u < 0.56:
		pivot.position.y = lerpf(-12.0, 4.0, pow((u - 0.38) / 0.18, 2.0))
	elif u < 0.68:
		pivot.position.y = 4.0
		pivot.scale = Vector2(1.05, 0.94)
	else:
		pivot.position.y = 4.0 * (1.0 - smoothstep(0.68, 1.0, u))
