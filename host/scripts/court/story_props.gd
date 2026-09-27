class_name StoryProps
extends Node2D

## The tutorial's props from the server's `props`: the Royal Harvest Chalice (a gold cup on a low stand) and the grape to
## fetch next. Both are ordinary visible objects (docs/GAME.md, "Tutorial"); nothing private is drawn here.

var chalice := Vector3.ZERO
var grape := Vector3.ZERO
var has_chalice := false
var has_grape := false
var _t := 0.0


func set_props(props: Dictionary) -> void:
	has_chalice = props.get("chalice") is Array
	has_grape = props.get("grape") is Array
	if has_chalice:
		chalice = HallCam.from_server(_v(props["chalice"]))
	if has_grape:
		grape = HallCam.from_server(_v(props["grape"]))
	visible = has_chalice or has_grape


func depth() -> float:
	return chalice.z if has_chalice else grape.z


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if has_chalice:
		_draw_chalice(chalice)
	if has_grape:
		_draw_grape(grape + Vector3(0, sin(_t * 2.4) * 0.03, 0))


func _draw_chalice(p: Vector3) -> void:
	var s := HallCam.project(p)
	if s.z <= 0:
		return
	var u := clampf(s.z * 0.3, 8.0, 44.0)  # pixels per chalice unit
	var c := Vector2(roundf(s.x), roundf(s.y))
	var cup := PackedVector2Array([c + Vector2(-u, -u * 1.6), c + Vector2(u, -u * 1.6), c + Vector2(u * 0.55, -u * 0.5),
		c + Vector2(-u * 0.55, -u * 0.5)])
	draw_colored_polygon(cup, Pal.GOLD)
	draw_polyline(cup + PackedVector2Array([cup[0]]), Pal.INK, 1.0)
	draw_rect(Rect2(c.x - u * 0.15, c.y - u * 0.5, u * 0.3, u * 0.7), Pal.GOLD_DARK)
	draw_rect(Rect2(c.x - u * 0.6, c.y + u * 0.2, u * 1.2, u * 0.25), Pal.GOLD)
	draw_rect(Rect2(c.x - u * 0.6, c.y + u * 0.2, u * 1.2, u * 0.25), Pal.INK, false, 1.0)
	draw_rect(Rect2(c.x - u * 0.8, c.y - u * 1.6, u * 1.6, maxf(1.0, u * 0.15)), Pal.GOLD_LIGHT)
	draw_circle(c + Vector2(0, -u * 1.05), maxf(1.0, u * 0.18), Pal.CRIMSON)  # Prospero's crest


func _draw_grape(p: Vector3) -> void:
	var s := HallCam.project(p)
	if s.z <= 0:
		return
	var r := clampf(s.z * 0.1, 4.0, 16.0)
	draw_arc(Vector2(roundf(s.x), roundf(s.y)), r * 2.6 + sin(_t * 4.0) * 1.5, 0.0, TAU, 24, Pal.GOLD_LIGHT, 1.0)  # "fetch me"
	var c := Vector2(roundf(s.x), roundf(s.y))
	for off in [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0.2), Vector2(-0.5, 1.1), Vector2(0.5, 1.1)]:
		draw_circle(c + off * r, r * 0.95, Pal.INK)
		draw_circle(c + off * r, r * 0.8, Color("#5B2A6E"))
		draw_circle(c + off * r + Vector2(-r * 0.25, -r * 0.25), maxf(1.0, r * 0.22), Color("#9A6BB0"))
	draw_line(c + Vector2(0, -r * 1.6), c + Vector2(r * 0.4, -r * 2.4), Pal.WOOD, maxf(1.0, r * 0.25))


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
