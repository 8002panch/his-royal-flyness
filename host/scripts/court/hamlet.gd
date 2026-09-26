class_name HamletActor
extends Node2D

## Prince Hamlet, seen from behind as he flies away from the camera. Each part
## is its own Sprite2D (halo, wings, gold filigree, body, mantle) so wing
## frames and the Reliquary cosmetics swap without redrawing him. The node's
## origin is his thorax.

const WING_CYCLE := [0, 1, 2, 1]

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


func _ready() -> void:
	for s in [halo, wings, filigree, body, mantle]:
		var spr: Sprite2D = s
		spr.centered = false
		add_child(spr)
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


func tick(delta: float, rate: float, fast: bool) -> void:
	_wing_t += delta * rate
	var f: int = WING_CYCLE[int(_wing_t) % WING_CYCLE.size()]
	if f != _frame:
		_frame = f
		_update_wings()
	if fast != buzzing:
		buzzing = fast
	queue_redraw()


func set_cosmetic(relic: String, on: bool) -> void:
	cosmetics[relic] = on
	_apply_cosmetics()


func _apply_cosmetics() -> void:
	halo.visible = cosmetics["halo"]
	mantle.visible = cosmetics["mantle"]
	filigree.visible = cosmetics["filigree"]


func _update_wings() -> void:
	wings.texture = SpriteForge.hamlet_wings(body_px, _frame)
	filigree.texture = SpriteForge.hamlet_filigree(body_px, _frame)


## Wing-buzz ticks at the wingtips while he is moving fast (drawn behind the sprites).
func _draw() -> void:
	if not buzzing or _frame == 1:
		return
	var span := roundi(body_px * 0.62)
	var up := roundi(body_px * 0.32)
	for side in [-1, 1]:
		var x: int = side * span
		var y := -up + (2 if _frame == 2 else -2)
		draw_rect(Rect2(x, y, 2, 1), Pal.PARCHMENT)
		draw_rect(Rect2(x + side * 3, y + 2, 2, 1), Pal.PARCHMENT)
		draw_rect(Rect2(x + side * 1, y - 3, 1, 2), Pal.PARCHMENT)
