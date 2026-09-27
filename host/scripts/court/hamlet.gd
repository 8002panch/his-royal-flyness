class_name HamletActor
extends Node2D

## Prince Hamlet in flight: Anshul's animated cast rig (assets/pixelart/animation_v1/rigs/hamlet.scn) in its fly pose,
## scaled to his size on screen, facing the way he drifts and banking with his motion. The node's origin is his thorax.
## The older drawn rear view (the Sprite2D parts) stays only as a fallback if the rig can't load; the Reliquary halo is
## still drawn over the rig.

const WING_CYCLE := [0, 1, 2, 3, 4, 5, 6, 7]

var halo := Sprite2D.new()
var wings := Sprite2D.new()
var filigree := Sprite2D.new()
var body := Sprite2D.new()
var mantle := Sprite2D.new()

var body_px := 0
var cosmetics := {"mantle": false, "halo": false, "filigree": false}
var buzzing := false

var _wing_t := 0.0
var _frame := 0
var _motion := Vector3.ZERO
var _t := 0.0
var _cue := ""
var _cue_left := 0.0
var _cue_duration := 1.0
var rig: Node2D = null
var _facing := 1.0
var _rig_mode := ""
var _rig_speed := -1.0
var _grape := GrapeBunch.new()
var carrying := false:  # the tutorial's grape, held under him while he carries it
	set(v):
		carrying = v
		_grape.visible = v

func set_motion(velocity: Vector3) -> void:
	_motion = velocity.limit_length(1.7)

func play_gesture(cue: String, seconds := 1.2) -> void:
	_cue = cue
	_cue_duration = maxf(0.15, seconds)
	_cue_left = _cue_duration
	if rig != null and rig.has_method("play_gesture"):
		rig.play_gesture(cue, seconds)


func _tick_rig() -> void:
	if absf(_motion.x) > 0.12:
		_facing = signf(_motion.x)
	var spd := snappedf(clampf(_motion.length(), 0.0, 1.0), 0.1)
	if _rig_mode != "fly" or spd != _rig_speed or _facing != rig.get("facing"):
		_rig_mode = "fly"
		_rig_speed = spd
		rig.set_motion("fly", maxf(0.35, spd), _facing)


func _ready() -> void:
	for s in [halo, wings, filigree, body, mantle]:
		var spr: Sprite2D = s
		spr.centered = false
		add_child(spr)
	rig = StoryArt.rig("hamlet", "")
	if rig != null:
		add_child(rig)
		move_child(rig, 0)
	_grape.visible = false
	add_child(_grape)
	set_body_px(56)
	_apply_cosmetics()


func set_body_px(hh: int) -> void:
	if hh == body_px:
		return
	body_px = hh
	var anchor := SpriteForge.hamlet_anchor(hh)
	for s in [halo, wings, filigree, body, mantle]:
		var spr: Sprite2D = s
		spr.offset = -anchor
	body.texture = SpriteForge.hamlet_body(hh)
	mantle.texture = SpriteForge.hamlet_mantle(hh)
	halo.texture = SpriteForge.hamlet_halo(hh)
	_update_wings()
	if rig != null:
		# the rig's origin is at its feet, 72 px below the top of its antennae; his thorax sits about 30 px up
		var k := hh * 1.3 / 72.0
		rig.scale = Vector2(k, k)
		rig.position = Vector2(0, roundf(30.0 * k))
	_grape.r = clampf(hh * 0.09, 3.0, 9.0)
	_grape.position = Vector2(roundf(hh * 0.25), roundf(hh * 0.45))


func tick(delta: float, rate: float, fast: bool) -> void:
	_t += delta
	# Cap at 40 frame changes/s: five complete beats, legible on a 60 Hz laptop.
	_wing_t += delta * clampf(rate * 1.7, 24.0, 40.0)
	var f: int = WING_CYCLE[int(_wing_t) % WING_CYCLE.size()]
	if f != _frame:
		_frame = f
		_update_wings()
	if fast != buzzing:
		buzzing = fast
	var target_bank := clampf(_motion.x * 0.09, -0.10, 0.10)
	rotation = lerpf(rotation, target_bank, 1.0 - exp(-delta * 7.0))
	var pitch := clampf(_motion.y * 0.035, -0.04, 0.04)
	body.scale.y = 1.0 - pitch
	mantle.scale.y = body.scale.y
	mantle.position.x = roundf(sin(_t * 4.0 - 0.8) * (1.0 if fast else 0.5))
	if rig != null:
		_tick_rig()
	if _cue_left > 0.0:
		_cue_left = maxf(0.0, _cue_left - delta)
		var u := 1.0 - _cue_left / _cue_duration
		var envelope := sin(u * PI)
		if _cue == "hit": rotation += sin(_t * 32.0) * 0.06 * envelope
		elif _cue == "celebrate": rotation += sin(_t * 5.0) * 0.09 * envelope
		elif _cue == "bow": body.scale.y *= 1.0 - 0.10 * envelope
	queue_redraw()


func set_cosmetic(relic: String, on: bool) -> void:
	cosmetics[relic] = on
	_apply_cosmetics()


func _apply_cosmetics() -> void:
	halo.visible = cosmetics["halo"]
	var drawn := rig == null  # the rear-view parts only when the rig is missing
	body.visible = drawn
	wings.visible = drawn
	mantle.visible = drawn and cosmetics["mantle"]
	filigree.visible = drawn and cosmetics["filigree"]


func _update_wings() -> void:
	wings.texture = SpriteForge.hamlet_wings(body_px, _frame)
	filigree.texture = SpriteForge.hamlet_filigree(body_px, _frame)


## Wing-buzz ticks at the wingtips while he is moving fast (drawn behind the sprites).
func _draw() -> void:
	if rig != null or not buzzing or _frame == 1:
		return
	var span := roundi(body_px * 0.62)
	var up := roundi(body_px * 0.32)
	for side in [-1, 1]:
		var x: int = side * span
		var y := -up + (2 if _frame == 2 else -2)
		draw_rect(Rect2(x, y, 2, 1), Pal.PARCHMENT)
		draw_rect(Rect2(x + side * 3, y + 2, 2, 1), Pal.PARCHMENT)
		draw_rect(Rect2(x + side * 1, y - 3, 1, 2), Pal.PARCHMENT)


## A small bunch of grapes, drawn in front of the rig.
class GrapeBunch extends Node2D:
	var r := 5.0:
		set(v):
			r = v
			queue_redraw()

	func _draw() -> void:
		draw_line(Vector2(0, -r * 1.6), Vector2(r * 0.4, -r * 2.4), Pal.WOOD, maxf(1.0, r * 0.25))
		for off in [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0.2), Vector2(-0.5, 1.1), Vector2(0.5, 1.1)]:
			draw_circle(off * r, r * 0.95, Pal.INK)
			draw_circle(off * r, r * 0.8, Color("#5B2A6E"))
			draw_circle(off * r + Vector2(-r * 0.25, -r * 0.25), maxf(1.0, r * 0.22), Color("#9A6BB0"))
