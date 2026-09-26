class_name MirandaActor
extends Node2D

## Princess Miranda, the destination. Front view in a royal-blue gown and gold
## tiara, standing on a gilded perch (render.princess puts her in mid-air) with
## a bobbing heart above her. The node's origin is her thorax.

const STYLE := {"gown": Pal.ROYAL, "tiara": true, "lashes": true}

var body := Sprite2D.new()
var heart := Sprite2D.new()
var body_px := 0
var perch_drop := 0   # px from her feet down to the dais/floor
var heart_anchor := Vector2i.ZERO   # where name tags point, in world space

var _t := 0.0


func _ready() -> void:
	body.centered = false
	heart.centered = false
	heart.texture = SpriteForge.heart()
	add_child(body)
	add_child(heart)
	set_body_px(36)


func set_body_px(hh: int) -> void:
	if hh == body_px:
		return
	body_px = hh
	body.texture = SpriteForge.fly_front(hh, "miranda", STYLE)
	body.offset = -SpriteForge.front_anchor(hh)
	queue_redraw()


func set_perch(drop: int) -> void:
	if drop != perch_drop:
		perch_drop = drop
		queue_redraw()


func tick(delta: float) -> void:
	_t += delta
	var bob := roundi(sin(_t * 3.0) * 1.5)
	var hy := -roundi(body_px * 0.62) - 10 + bob
	heart.position = Vector2(-4, hy)
	heart_anchor = Vector2i(roundi(position.x), roundi(position.y) + hy - 1)


func feet_y() -> int:
	var feet := SpriteForge.front_feet(body_px) - SpriteForge.front_anchor(body_px)
	return roundi(feet.y)


## The gilded perch: a crimson cushion on a gold pole down to the dais.
func _draw() -> void:
	var fy := feet_y()
	if perch_drop <= 2:
		return
	var cw := roundi(body_px * 0.7)
	var pole := 3
	draw_rect(Rect2(-pole / 2 - 1, fy + 3, pole + 2, perch_drop - 3), Pal.INK)
	draw_rect(Rect2(-pole / 2, fy + 3, pole, perch_drop - 4), Pal.GOLD)
	draw_rect(Rect2(-pole / 2, fy + 3, 1, perch_drop - 4), Pal.GOLD_LIGHT)
	var knot := fy + 3 + (perch_drop - 3) / 2
	draw_rect(Rect2(-pole / 2 - 2, knot, pole + 4, 3), Pal.INK)
	draw_rect(Rect2(-pole / 2 - 1, knot + 1, pole + 2, 1), Pal.GOLD)
	var base := fy + perch_drop
	draw_rect(Rect2(-6, base - 2, 13, 3), Pal.INK)
	draw_rect(Rect2(-5, base - 1, 11, 1), Pal.GOLD_DARK)
	# cushion
	draw_rect(Rect2(-cw / 2, fy - 1, cw, 5), Pal.INK)
	draw_rect(Rect2(-cw / 2 + 1, fy, cw - 2, 3), Pal.CRIMSON)
	draw_rect(Rect2(-cw / 2 + 1, fy, cw - 2, 1), Pal.CRIMSON_LIGHT)
	draw_rect(Rect2(-cw / 2 - 1, fy + 1, 2, 3), Pal.GOLD)
	draw_rect(Rect2(cw / 2 - 1, fy + 1, 2, 3), Pal.GOLD)
