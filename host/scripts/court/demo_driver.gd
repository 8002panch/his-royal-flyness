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
## The Giant's hand comes down every 8 s where Hamlet is heading; move away before
## it lands. Reaching Miranda wins. Both outcomes are decided here only because
## this driver is standing in for the server during a demo.

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
const GIANT_EVERY := 8.0
const GIANT_FALL := 2.2
const HIT_RADIUS := 0.28
const WIN_RADIUS := 0.22

var pos := START
var vel := Vector3.ZERO
var time := 0.0
var _pub := 0.0
var _giant_t := -3.0        # seconds into the current Giant cycle (starts with a grace period)
var _giant_at := Vector3.ZERO
var _giant_live := false
var _pause := 0.0           # after a splat or a win, hold still, then reset


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
	_update_giant(dt)
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


func _update_giant(dt: float) -> void:
	_giant_t += dt
	if _giant_t >= GIANT_EVERY:
		_giant_t = 0.0
	var falling := _giant_t >= 0.0 and _giant_t < GIANT_FALL and _pause <= 0.0
	if falling and not _giant_live:
		# aim where Hamlet is heading, a little ahead of him
		_giant_at = Vector3(clampf(pos.x + vel.x * 0.6, -0.9, 0.9), -1.0, clampf(pos.z + 0.3, -0.8, 0.8))
		_voice("H_WARN_GIANT", "Herald", "The Giant stirs!")
	if _giant_live and not falling and _pause <= 0.0 and _giant_t >= GIANT_FALL:
		# it just landed: did it catch him?
		var d := Vector2(pos.x - _giant_at.x, pos.z - _giant_at.z).length()
		if d < HIT_RADIUS:
			_voice("H_SPLAT", "Herald", "The Giant has claimed another suitor.")
			event_ready.emit({"t": "event", "kind": "splat"})
			_pause = 2.0
	_giant_live = falling


func _state(intent: Vector3) -> Dictionary:
	var giant: Variant = null
	if _giant_live:
		var remaining := GIANT_FALL - _giant_t
		giant = _cue(_giant_at)
		giant["distance_cm"] = maxf(15.0, remaining / GIANT_FALL * 300.0)
		giant["approach_cm_s"] = 300.0 / GIANT_FALL
		giant["size_cm"] = 40.0
	return {
		"t": "state", "phase": "play", "time": snappedf(time, 0.001), "demo": true,
		"fly": {"x": pos.x, "y": pos.y, "z": pos.z, "vx": vel.x, "vy": vel.y, "vz": vel.z},
		"render": {"princess": _cue(PRINCESS), "giant": giant},
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
	_giant_t = -3.0
	_giant_live = false
