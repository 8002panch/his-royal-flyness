class_name PixelCanvas
extends RefCounted

## A tiny raster kit for drawing pixel art into an Image in code: flat fills,
## scanline polygons, pixel-centre ellipses, Bresenham lines, checker dither
## and a hard ink outline pass. No antialiasing anywhere; every sprite and
## world layer in the court is built with this and shown with nearest filtering.

var img: Image
var w: int
var h: int


func _init(width: int, height: int) -> void:
	w = maxi(1, width)
	h = maxi(1, height)
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Pal.CLEAR)


static func from_rows(rows: Array, palette: Dictionary) -> PixelCanvas:
	var height := rows.size()
	var width := 0
	for row in rows:
		width = maxi(width, String(row).length())
	var c := PixelCanvas.new(width, height)
	for y in height:
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if palette.has(key):
				c.img.set_pixel(x, y, palette[key])
	return c


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)


func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < w and y < h:
		img.set_pixel(x, y, c)


func get_px(x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < w and y < h:
		return img.get_pixel(x, y)
	return Pal.CLEAR


func opaque(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.5


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, w, h))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


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
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var guard := 0
	while guard < 4096:
		guard += 1
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func linev(a: Vector2, b: Vector2, c: Color) -> void:
	line(roundi(a.x), roundi(a.y), roundi(b.x), roundi(b.y), c)


## Filled ellipse sampled at pixel centres. (cx, cy) may be fractional.
func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var y0 := int(floor(cy - ry))
	var y1 := int(ceil(cy + ry))
	for y in range(y0, y1 + 1):
		var dy := (y + 0.5 - cy) / ry
		if absf(dy) > 1.0:
			continue
		var half := rx * sqrt(1.0 - dy * dy)
		var xa := int(round(cx - half))
		var xb := int(round(cx + half)) - 1
		if xb >= xa:
			hline(xa, xb, y, c)


## Checker-dithered ellipse: the pixel-art stand-in for a soft shadow.
func ellipse_dither(cx: float, cy: float, rx: float, ry: float, c: Color, phase: int = 0) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		var dy := (y + 0.5 - cy) / ry
		if absf(dy) > 1.0:
			continue
		var half := rx * sqrt(1.0 - dy * dy)
		for x in range(int(round(cx - half)), int(round(cx + half))):
			if (x + y + phase) % 2 == 0:
				px(x, y, c)


## Scanline polygon fill (even-odd), sampled at pixel centres.
func poly(points: PackedVector2Array, c: Color) -> void:
	var n := points.size()
	if n < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	var ya := maxi(0, int(floor(min_y)))
	var yb := mini(h - 1, int(ceil(max_y)))
	for y in range(ya, yb + 1):
		var sy := y + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := points[i]
			var b := points[(i + 1) % n]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var xa := int(ceil(xs[k] - 0.5))
			var xb := int(floor(xs[k + 1] - 0.5))
			if xb >= xa:
				hline(xa, xb, y, c)
			k += 2


## Same scanline fill, but only every other pixel (checker): pixel-art shade.
func poly_dither(points: PackedVector2Array, c: Color, phase: int = 0) -> void:
	var n := points.size()
	if n < 3:
		return
	var min_y := INF
	var max_y := -INF
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	for y in range(maxi(0, int(floor(min_y))), mini(h - 1, int(ceil(max_y))) + 1):
		var sy := y + 0.5
		var xs: Array[float] = []
		for i in n:
			var a := points[i]
			var b := points[(i + 1) % n]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			for x in range(maxi(0, int(ceil(xs[k] - 0.5))), mini(w - 1, int(floor(xs[k + 1] - 0.5))) + 1):
				if (x + y + phase) % 2 == 0:
					img.set_pixel(x, y, c)
			k += 2


func poly_outline(points: PackedVector2Array, c: Color) -> void:
	for i in points.size():
		linev(points[i], points[(i + 1) % points.size()], c)


func dither_rect(x: int, y: int, rw: int, rh: int, c: Color, phase: int = 0) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if (xx + yy + phase) % 2 == 0:
				px(xx, yy, c)


## Hard 1 px outline around every opaque shape (4-neighbour; 8 with diagonal).
func outline(c: Color, diagonal: bool = false) -> void:
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var hit := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixelv(q).a > 0.5:
					hit = true
					break
			if not hit and diagonal:
				for d in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
					var q: Vector2i = Vector2i(x, y) + d
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixelv(q).a > 0.5:
						hit = true
						break
			if hit:
				img.set_pixel(x, y, c)


## Recolours every opaque pixel that sits below/right of the shape's lit
## side: a cheap flat two-tone shading pass for round parts.
func shade_ellipse(cx: float, cy: float, rx: float, ry: float, shade: Color, light: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			var r := nx * nx + ny * ny
			if r > 1.0:
				continue
			if nx * 0.55 + ny * 0.85 > 0.45:
				px(x, y, shade)
			elif r < 0.16 and nx < -0.1 and ny < -0.2:
				px(x, y, light)


func blit(src: PixelCanvas, x: int, y: int) -> void:
	img.blend_rect(src.img, Rect2i(0, 0, src.w, src.h), Vector2i(x, y))


func flip_x() -> PixelCanvas:
	img.flip_x()
	return self


static func ellipse_points(cx: float, cy: float, rx: float, ry: float, angle: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca := cos(angle)
	var sa := sin(angle)
	for i in segments:
		var t := TAU * i / segments
		var ex := cos(t) * rx
		var ey := sin(t) * ry
		pts.append(Vector2(cx + ex * ca - ey * sa, cy + ex * sa + ey * ca))
	return pts
