extends Node2D

## A living piece of scenery: one animated cast rig standing at a hall-space
## spot, scaled by the chase camera's projection, with a small idle script of
## gestures. Never drives or blocks anything (scenery only).

const RIG_DIR := "res://assets/pixelart/animation_v1/rigs/"

var hall_pos := Vector3.ZERO
var height_units := 0.8
var facing := 1.0
var beats: Array = []      # [[gesture, duration, pause_after], ...] looped
var sway := 0.0            # radians of tipsy lean
var pace: Array = []       # optional [x_a, x_b, seconds] walk path along x
var rig: Node2D
var _t := 0.0
var _beat := 0
var _wait := 1.0
var _px := 0


func setup(id: String, pos: Vector3, h: float, face: float, beat_list: Array, start_delay := 1.0) -> void:
	hall_pos = pos
	height_units = h
	facing = face
	beats = beat_list
	_wait = start_delay
	rig = load(RIG_DIR + id + ".scn").instantiate()
	rig.autoplay = true
	add_child(rig)
	rig.set_motion("idle", 0.4, facing)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func depth() -> float:
	return hall_pos.z


func tick(delta: float) -> void:
	_t += delta
	var pos := hall_pos
	if pace.size() == 3:
		var u := fmod(_t / float(pace[2]), 1.0)
		var tri := 1.0 - absf(2.0 * u - 1.0)   # 0..1..0
		pos.x = lerpf(float(pace[0]), float(pace[1]), smoothstep(0.0, 1.0, tri))
		var dir := 1.0 if u < 0.5 else -1.0
		var moving := absf(u - 0.5) > 0.04 and u > 0.04 and u < 0.96
		rig.set_motion("walk" if moving else "idle", 0.35, dir)
	var p := HallCam.project(pos)
	visible = p.z > 0.0 and pos.z > HallCam.near_z() + 0.5
	if not visible:
		return
	var px := clampi(roundi(height_units * p.z), 8, 150)
	# keep the rig's mesh scale on a coarse grid so edges stay steady
	var sc := roundf(px / 72.0 * 16.0) / 16.0
	rig.scale = Vector2(sc, sc)
	position = Vector2(roundf(p.x), roundf(p.y))
	if px != _px:
		_px = px
		queue_redraw()
	rotation = sin(_t * 1.3) * sway
	_wait -= delta
	if _wait <= 0.0 and not beats.is_empty():
		var b: Array = beats[_beat % beats.size()]
		rig.play_gesture(str(b[0]), float(b[1]))
		_wait = float(b[1]) + float(b[2])
		_beat += 1


func _draw() -> void:
	var rx := maxi(6, roundi(_px * 0.3))
	var ry := maxi(2, roundi(rx * 0.3))
	draw_texture(SpriteForge.shadow(rx, ry), Vector2(-rx, -ry))
