extends Node2D

## A cast rig from animation_v1 placed in the Great Hall as living scenery: a
## frightened courtier hiding at the edge of the arena. Scenery only: it never
## affects the game. Its hall position goes through HallCam every frame, so it
## keeps its place as the chase camera moves; the rig is scaled to suit the
## perspective and drawn with nearest filtering.
##
## moods: "cower" (crouched, trembling), "confused" (looks about, shrugs),
##        "scan" (the Royal Seer works at his reading), "idle".

const RIG_DIR := "res://assets/pixelart/animation_v1/rigs/"
const ST := preload("gh2_state.gd")

var rig_id := "count_rutabaga"
var hall_pos := Vector3(-1.5, -1.3, -0.4)
var height_units := 0.6
var mood := "cower"
var facing := 1.0
var seed_offset := 0.0
var dim := Color(0.8, 0.8, 0.9)

var rig: Node2D
var _t := 0.0
var _next := 0.0
var _flip_t := 0.0
var _react := 0.0
var _was_alarmed := false


func _ready() -> void:
	modulate = dim
	rig = (load(RIG_DIR + rig_id + ".scn") as PackedScene).instantiate()
	rig.autoplay = true
	add_child(rig)
	rig.set_motion("idle", 0.4, facing)
	_t = seed_offset
	_next = 0.6 + seed_offset * 0.3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func depth() -> float:
	return hall_pos.z


func tick(delta: float) -> void:
	_t += delta
	var pr := HallCam.project(hall_pos)
	if pr.z <= 0.0 or pr.x < -60.0 or pr.x > HallCam.W + 60.0:
		visible = false
		return
	visible = true
	# scale so the 72 px rig is `height_units` tall here, in sixteenths so it stays tidy
	var k := roundf(height_units * pr.z / 72.0 * 16.0) / 16.0
	k = clampf(k, 0.3, 1.6)
	var squat := 1.0
	var jitter := Vector2.ZERO
	var alarm := ST.alarm
	if mood == "cower":
		squat = 0.88 - 0.05 * alarm
		# a constant tremble, worse when the hand is close
		if fmod(_t * (8.0 + 8.0 * alarm), 1.0) < 0.5:
			jitter.x = 1.0 if alarm > 0.25 else 0.0
	scale = Vector2(k, k * squat)
	position = Vector2(roundf(pr.x) + jitter.x, roundf(pr.y))

	# gestures
	_next -= delta
	if _next <= 0.0:
		match mood:
			"cower":
				rig.play_gesture("hit", 0.6)
				_next = 0.7 + (0.3 if alarm < 0.2 else 0.0)
			"confused":
				rig.play_gesture("confused", 2.2)
				_next = 3.2
				if alarm > 0.4:
					rig.play_gesture("hit", 0.7)
					_next = 1.0
			"scan":
				rig.play_gesture("scan", 4.0)
				_next = 4.4
			_:
				rig.play_gesture("talk", 1.5)
				_next = 5.0
	# looking about nervously: mirror now and then
	if mood == "confused" or mood == "cower":
		_flip_t += delta
		if _flip_t > 2.6:
			_flip_t = 0.0
			facing = -facing
			rig.set_motion("idle", 0.4, facing)
	# a flinch when the hand starts to fall
	var alarmed := alarm > 0.5
	if alarmed and not _was_alarmed:
		rig.play_gesture("hit", 1.0)
		_next = 1.0
	_was_alarmed = alarmed


func _draw() -> void:
	# a dithered grounding shadow, under the rig (drawn before the child)
	draw_texture(SpriteForge.shadow(20, 4), Vector2(-20, -4))
