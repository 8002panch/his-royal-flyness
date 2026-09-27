class_name CanvasPainter
extends RefCounted

## PixelCanvas's drawing API, but drawn straight onto a CanvasItem every frame.
## HallBuilder paints through either one: into an Image once (a fixed camera),
## or live through this (the chase camera, where the hall must be redrawn from
## wherever the camera is). The court renders at 640x360 with no antialiasing,
## so these primitives still land as hard pixels.
##
## Dither fills use a 2x2 checker texture tiled in screen space, so the pattern
## stays locked to the pixel grid (the CanvasItem needs texture_repeat enabled).

var ci: CanvasItem
var w := HallCam.W
var h := HallCam.H

static var _checker: ImageTexture
static var _tex_cache := {}


func _init(item: CanvasItem) -> void:
	ci = item
	if _checker == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.set_pixel(0, 0, Color.WHITE)
		img.set_pixel(1, 1, Color.WHITE)
		_checker = ImageTexture.create_from_image(img)


func px(x: int, y: int, c: Color) -> void:
	ci.draw_rect(Rect2(x, y, 1, 1), c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	if rw > 0 and rh > 0:
		ci.draw_rect(Rect2(x, y, rw, rh), c)


func hline(x0: int, x1: int, y: int, c: Color) -> void:
	rect(mini(x0, x1), y, absi(x1 - x0) + 1, 1, c)


func vline(x: int, y0: int, y1: int, c: Color) -> void:
	rect(x, mini(y0, y1), 1, absi(y1 - y0) + 1, c)


func frame(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	hline(x, x + rw - 1, y, c)
	hline(x, x + rw - 1, y + rh - 1, c)
	vline(x, y, y + rh - 1, c)
	vline(x + rw - 1, y, y + rh - 1, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	ci.draw_line(Vector2(x0 + 0.5, y0 + 0.5), Vector2(x1 + 0.5, y1 + 0.5), c, -1.0)


func linev(a: Vector2, b: Vector2, c: Color) -> void:
	if _far(a) and _far(b):
		return
	line(roundi(a.x), roundi(a.y), roundi(b.x), roundi(b.y), c)


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	ci.draw_colored_polygon(PixelCanvas.ellipse_points(cx, cy, rx, ry, 0.0, _segments(rx, ry)), c)


func ellipse_dither(cx: float, cy: float, rx: float, ry: float, c: Color, phase: int = 0) -> void:
	if rx > 0.0 and ry > 0.0:
		poly_dither(PixelCanvas.ellipse_points(cx, cy, rx, ry, 0.0, _segments(rx, ry)), c, phase)


func poly(points: PackedVector2Array, c: Color) -> void:
	if _drawable(points):
		ci.draw_colored_polygon(points, c)


func poly_dither(points: PackedVector2Array, c: Color, _phase: int = 0) -> void:
	if not _drawable(points):
		return
	var uvs := PackedVector2Array()
	for p in points:
		uvs.append(p / 2.0)
	ci.draw_polygon(points, PackedColorArray([c]), uvs, _checker)


func poly_outline(points: PackedVector2Array, c: Color) -> void:
	if points.size() < 2:
		return
	var closed := points.duplicate()
	closed.append(points[0])
	ci.draw_polyline(closed, c, -1.0)


func blit(src: PixelCanvas, x: int, y: int) -> void:
	var key := src.get_instance_id()
	if not _tex_cache.has(key):
		_tex_cache[key] = src.texture()
	ci.draw_texture(_tex_cache[key], Vector2(x, y))


func _segments(rx: float, ry: float) -> int:
	return clampi(int(maxf(rx, ry) * 1.5), 8, 48)


func _far(p: Vector2) -> bool:
	return absf(p.x) > 20000.0 or absf(p.y) > 20000.0


## Skip slivers and anything Godot's triangulator would reject.
func _drawable(points: PackedVector2Array) -> bool:
	var n := points.size()
	if n < 3:
		return false
	var area := 0.0
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
		min_x = minf(min_x, a.x)
		max_x = maxf(max_x, a.x)
		min_y = minf(min_y, a.y)
		max_y = maxf(max_y, a.y)
	if absf(area) < 1.0 or max_x < 0.0 or min_x > w or max_y < 0.0 or min_y > h:
		return false
	if n > 3:
		return not Geometry2D.triangulate_polygon(points).is_empty()
	return true
