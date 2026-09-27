extends RefCounted

## Small pixel-art helpers shared by the Great Hall v2 painters: density dither
## (25 / 50 / 75 % screen-locked patterns, no alpha), hashing, polygon clipping,
## capsules and convex hulls. Everything paints through a CanvasPainter `c`.

static var _tex := {}


static func pattern(density: int) -> ImageTexture:
	if not _tex.has(density):
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		match density:
			1:
				img.set_pixel(0, 0, Color.WHITE)
			3:
				img.set_pixel(0, 0, Color.WHITE)
				img.set_pixel(1, 1, Color.WHITE)
				img.set_pixel(0, 1, Color.WHITE)
			_:
				img.set_pixel(0, 0, Color.WHITE)
				img.set_pixel(1, 1, Color.WHITE)
		_tex[density] = ImageTexture.create_from_image(img)
	return _tex[density]


## density 1 = 25 %, 2 = 50 % (checker), 3 = 75 % of the pixels.
static func dither(c, pts: PackedVector2Array, col: Color, density: int = 2) -> void:
	if not c._drawable(pts):
		return
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / 2.0)
	c.ci.draw_polygon(pts, PackedColorArray([col]), uvs, pattern(density))


static func dither_ellipse(c, cx: float, cy: float, rx: float, ry: float, col: Color, density: int = 2) -> void:
	if rx < 1.0 or ry < 0.5:
		return
	dither(c, PixelCanvas.ellipse_points(cx, cy, rx, ry, 0.0, clampi(int(maxf(rx, ry) * 1.5), 8, 40)), col, density)


static func hash2(i: int, j: int, s: int = 0) -> float:
	var n: int = (i * 73856093) ^ (j * 19349663) ^ (s * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


## Dev profiler: P.lap("name", t0) accumulates a smoothed cost (microseconds) and
## returns the new timestamp. Read P.laps from the launcher's log.
static var laps := {}


static func lap(name: String, t0: int) -> int:
	var t1 := Time.get_ticks_usec()
	laps[name] = lerpf(laps.get(name, 0.0), float(t1 - t0), 0.05)
	return t1


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Smooth-ish 1D noise in -1..1 (sum of sines), for candles and drifting motes.
static func wob(t: float, seed: float) -> float:
	return sin(t * 9.1 + seed * 3.7) * 0.5 + sin(t * 15.7 + seed * 1.3) * 0.3 + sin(t * 3.3 + seed) * 0.2


static func clip_half(poly: PackedVector2Array, axis: int, val: float, keep_greater: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var ain := a[axis] >= val if keep_greater else a[axis] <= val
		var bin := b[axis] >= val if keep_greater else b[axis] <= val
		if ain:
			out.append(a)
		if ain != bin:
			var t := (val - a[axis]) / (b[axis] - a[axis])
			out.append(a.lerp(b, t))
	return out


static func clip_box(poly: PackedVector2Array, x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	var p := clip_half(poly, 0, x0, true)
	if p.size() < 3:
		return PackedVector2Array()
	p = clip_half(p, 0, x1, false)
	if p.size() < 3:
		return PackedVector2Array()
	p = clip_half(p, 1, y0, true)
	if p.size() < 3:
		return PackedVector2Array()
	p = clip_half(p, 1, y1, false)
	return p


## Rounded bar from p0 (radius r0) to p1 (radius r1): finger, arm, thumb.
static func capsule(p0: Vector2, p1: Vector2, r0: float, r1: float, seg: int = 8) -> PackedVector2Array:
	var ang := (p1 - p0).angle()
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a := ang - PI / 2.0 + PI * float(i) / seg
		pts.append(p1 + Vector2(cos(a), sin(a)) * r1)
	for i in range(seg + 1):
		var a := ang + PI / 2.0 + PI * float(i) / seg
		pts.append(p0 + Vector2(cos(a), sin(a)) * r0)
	return pts


static func hull(points: PackedVector2Array) -> PackedVector2Array:
	var pts: Array = Array(points)
	pts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	var lower: Array = []
	for p in pts:
		while lower.size() >= 2 and _cross(lower[lower.size() - 2], lower[lower.size() - 1], p) <= 0.0:
			lower.pop_back()
		lower.append(p)
	var upper: Array = []
	for i in range(pts.size() - 1, -1, -1):
		var p: Vector2 = pts[i]
		while upper.size() >= 2 and _cross(upper[upper.size() - 2], upper[upper.size() - 1], p) <= 0.0:
			upper.pop_back()
		upper.append(p)
	lower.pop_back()
	upper.pop_back()
	var out := PackedVector2Array()
	for p in lower:
		out.append(p)
	for p in upper:
		out.append(p)
	return out


static func _cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


static func lerp_col(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))
