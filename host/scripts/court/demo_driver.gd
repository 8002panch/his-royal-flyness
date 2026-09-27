class_name DemoDriver
extends Node

## Keyboard demo (F3, or `-- --demo`): stands in for the server so the court can
## be played on one laptop with no phones. It mirrors server/movement.py's
## integration and server/seer_adapter.py's Princess maths, then emits `state`
## messages in the real Phase 3 shape (tagged "demo": true) straight to the court.
## GameState, the relay and the real server are untouched.
##
##   A / D        Helmsman    x  left / right
##   W / S        Wingmaster  z  forward / brake
##   Space/Shift  Liftmaster  y  climb / dive
##   E (hold)     Seer        scan
##
## Reaching Miranda wins. That outcome is decided here only because this driver
## is standing in for the server during a demo.

signal state_ready(msg: Dictionary)
signal event_ready(ev: Dictionary)

# server/movement.py MovementTuning
const ACCEL := 2.4
const DRAG := 3.2
const MAX_SPEED := 1.0
const DEAD_ZONE := 0.05
const BOUNDS := 1.0
# server/seer_adapter.py placeholder world
const PRINCESS := Vector3(0.25, 0.18, 0.85)
const UNIT_CM := 220.0
const START := Vector3(0.0, -0.2, -0.95)
const WIN_RADIUS := 0.22

var pos := START
var vel := Vector3.ZERO
var time := 0.0
var _pub := 0.0
var _pause := 0.0           # after a win, hold still, then reset


func _physics_process(dt: float) -> void:
	time += dt
	var intent := Vector3.ZERO
	if _pause > 0.0:
		_pause -= dt
		if _pause <= 0.0:
			_reset()
	else:
		intent = Vector3(
			_axis(KEY_D, KEY_A),
			_axis(KEY_SPACE, KEY_SHIFT),
			_axis(KEY_W, KEY_S))
	for i in 3:
		var p := _step(pos[i], vel[i], int(intent[i]), dt)
		pos[i] = p.x
		vel[i] = p.y
	if _pause <= 0.0 and pos.distance_to(PRINCESS) < WIN_RADIUS:
		_voice("H_WIN", "Herald", "Her Highness is charmed!")
		event_ready.emit({"t": "event", "kind": "win"})
		_pause = 2.5
	_pub += dt
	if _pub >= 1.0 / 30.0:
		_pub = 0.0
		state_ready.emit(_state(intent))


func _axis(pos_key: Key, neg_key: Key) -> int:
	return int(Input.is_physical_key_pressed(pos_key)) - int(Input.is_physical_key_pressed(neg_key))


func _step(p: float, v: float, intent: int, dt: float) -> Vector2:
	if intent != 0:
		v += intent * ACCEL * dt
	else:
		v *= maxf(0.0, 1.0 - DRAG * dt)
		if absf(v) < DEAD_ZONE:
			v = 0.0
	v = clampf(v, -MAX_SPEED, MAX_SPEED)
	p += v * dt
	if p <= -BOUNDS or p >= BOUNDS:
		p = clampf(p, -BOUNDS, BOUNDS)
		v = 0.0
	return Vector2(p, v)


func _state(intent: Vector3) -> Dictionary:
	return {
		"t": "state", "phase": "play", "time": snappedf(time, 0.001), "demo": true,
		"fly": {"x": pos.x, "y": pos.y, "z": pos.z, "vx": vel.x, "vy": vel.y, "vz": vel.z},
		"render": {"princess": _cue(PRINCESS)},
		"roles": {"helmsman": intent.x != 0, "liftmaster": intent.y != 0, "wingmaster": intent.z != 0,
			"seer": Input.is_physical_key_pressed(KEY_E)},
		"controls": {"x": intent.x, "y": intent.y, "z": intent.z},
		"trial": "II",
	}


## Same maths as server/seer_adapter.py projected_stimuli.
func _cue(target: Vector3) -> Dictionary:
	var depth := maxf(0.05, target.z - pos.z)
	return {
		"bearing_deg": rad_to_deg(atan2(target.x - pos.x, depth)),
		"elevation_deg": rad_to_deg(atan2(target.y - pos.y, depth)),
		"distance_cm": sqrt(pow(target.x - pos.x, 2) + pow(target.y - pos.y, 2) + depth * depth) * UNIT_CM,
	}


func _voice(id: String, speaker: String, caption: String) -> void:
	event_ready.emit({"t": "event", "kind": "voice", "id": id, "speaker": speaker, "caption": caption})


func _reset() -> void:
	pos = START
	vel = Vector3.ZERO
