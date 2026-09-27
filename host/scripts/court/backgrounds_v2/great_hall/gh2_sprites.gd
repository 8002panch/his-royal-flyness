extends RefCounted

## Great Hall v2 props drawn in code with PixelCanvas at their exact on-screen
## size (no scaling, hard ink outline, flat dim colours) and cached by size:
## floor candelabra, piles of overturned chairs, fallen goblets, plates.

const K := preload("gh2_pal.gd")
const P := preload("gh2_paint.gd")

static var _cache := {}


static func _snap(v: int, step: int) -> int:
	return maxi(step, int(round(float(v) / step)) * step)


## thick 1-2 px line; the second pixel goes on the short axis
static func _tline(c: PixelCanvas, a: Vector2, b: Vector2, col: Color, thick: int = 2) -> void:
	c.line(roundi(a.x), roundi(a.y), roundi(b.x), roundi(b.y), col)
	if thick >= 2:
		if absf(b.x - a.x) > absf(b.y - a.y):
			c.line(roundi(a.x), roundi(a.y) + 1, roundi(b.x), roundi(b.y) + 1, col)
		else:
			c.line(roundi(a.x) + 1, roundi(a.y), roundi(b.x) + 1, roundi(b.y), col)


# ----------------------------------------------------------------- goblet --

static func goblet_fallen(px: int) -> PixelCanvas:
	px = clampi(_snap(px, 2), 4, 40)
	var key := "gob_%d" % px
	if _cache.has(key):
		return _cache[key]
	var w := int(px * 2.0) + 4
	var h := int(px * 0.9) + 4
	var c := PixelCanvas.new(w, h)
	var base := h - 2.0
	# spilled wine, dark and glossy
	c.ellipse(w * 0.4, base - 0.5, w * 0.4, maxf(1.5, h * 0.16), K.CR_D)
	c.ellipse(w * 0.3, base - 0.5, w * 0.16, maxf(1.0, h * 0.08), K.CR)
	var cup := PackedVector2Array([Vector2(w * 0.14, base - h * 0.55), Vector2(w * 0.5, base - h * 0.36), Vector2(w * 0.5, base - h * 0.1), Vector2(w * 0.14, base - h * 0.08)])
	c.poly(cup, K.BR)
	c.hline(int(w * 0.16), int(w * 0.48), int(base - h * 0.5), K.BR_L)
	c.hline(int(w * 0.16), int(w * 0.48), int(base - h * 0.11), K.BR_D)
	c.line(int(w * 0.5), int(base - h * 0.23), int(w * 0.72), int(base - h * 0.23), K.BR_D)
	c.ellipse(w * 0.76, base - h * 0.23, maxf(1.0, h * 0.07), h * 0.28, K.BR)
	c.px(int(w * 0.75), int(base - h * 0.4), K.BR_L)
	c.outline(K.INK)
	_cache[key] = c
	return c


static func plate(px: int) -> PixelCanvas:
	px = clampi(_snap(px, 2), 6, 50)
	var key := "plate_%d" % px
	if _cache.has(key):
		return _cache[key]
	var w := px + 4
	var h := maxi(4, int(px * 0.34)) + 3
	var c := PixelCanvas.new(w, h)
	c.ellipse(w / 2.0, h / 2.0 + 0.5, w / 2.0 - 1.5, (h - 3) / 2.0 + 0.5, K.T_D)
	c.ellipse(w / 2.0, h / 2.0, w / 2.0 - 3.0, maxf(1.0, (h - 5) / 2.0), K.T)
	c.px(w / 2 - 2, h / 2 - 1, K.T_L)
	c.px(w / 2 - 1, h / 2 - 1, K.T_L)
	# a crust and a crumb or two
	c.px(w / 2 + 2, h / 2, K.W_L)
	c.px(w / 2 + 3, h / 2, K.W_L)
	c.outline(K.INK)
	_cache[key] = c
	return c


# ------------------------------------------------------------ candelabra --

## Floor stand, `hpx` tall. Returns {canvas, flames: [Vector2i spots for the flame tips]}.
static func candelabra(hpx: int) -> Dictionary:
	hpx = clampi(_snap(hpx, 4), 16, 160)
	var key := "cand_%d" % hpx
	if _cache.has(key):
		return _cache[key]
	var w := int(hpx * 0.6)
	w += 1 - w % 2
	var c := PixelCanvas.new(w + 4, hpx + 2)
	var cx := (w + 4) / 2
	var stem_w := maxi(2, int(hpx * 0.045))
	var base_y := hpx - 1
	# tripod foot
	c.ellipse(cx + 0.5, base_y - 1.0, w * 0.3, maxf(2.0, hpx * 0.035), K.BR_D)
	c.ellipse(cx + 0.5, base_y - 1.5, w * 0.2, maxf(1.5, hpx * 0.028), K.BR)
	c.hline(cx - int(w * 0.16), cx + int(w * 0.16), base_y - 3, K.BR_L)
	# stem with two knots
	var y_top := int(hpx * 0.4)
	c.rect(cx - stem_w / 2, y_top, stem_w, base_y - 3 - y_top, K.BR)
	c.vline(cx - stem_w / 2, y_top, base_y - 3, K.BR_L)
	c.vline(cx - stem_w / 2 + stem_w - 1, y_top, base_y - 3, K.BR_D)
	for ky in [0.78, 0.56]:
		var kk := int(hpx * ky)
		c.ellipse(cx + 0.5, kk, stem_w * 1.1 + 1.0, stem_w * 0.7 + 1.0, K.BR)
		c.px(cx - stem_w, kk - 1, K.BR_L)
	# three arms: a shallow U for the outer pair, a straight post for the middle one
	var flames: Array = []
	var arm_y := int(hpx * 0.42)
	var reach := int(w * 0.46)
	var candle_w := maxi(2, int(hpx * 0.05))
	var candle_h := maxi(4, int(hpx * 0.14))
	for side in [-1, 1]:
		var ex: int = cx + side * reach
		var ey := arm_y - int(hpx * 0.07)
		var prev := Vector2(cx, arm_y + 2)
		for s in range(1, 9):
			var t := float(s) / 8.0
			var pt := Vector2(lerpf(cx, ex, t), lerpf(arm_y + 2, ey, t * t) + sin(t * PI) * hpx * 0.05)
			_tline(c, prev, pt, K.BR, 1 if hpx < 40 else 2)
			prev = pt
		_socket_candle(c, ex, ey, candle_w, candle_h, flames)
	c.rect(cx - stem_w / 2 - 1, arm_y - 1, stem_w + 2, 3, K.BR_L)
	_socket_candle(c, cx, arm_y - int(hpx * 0.13), candle_w, candle_h + 1, flames)
	c.vline(cx, arm_y - int(hpx * 0.13), arm_y, K.BR)
	c.outline(K.INK)
	var out := {"canvas": c, "flames": flames}
	_cache[key] = out
	return out


static func _socket_candle(c: PixelCanvas, x: int, y: int, cw: int, ch: int, flames: Array) -> void:
	c.rect(x - cw, y, cw * 2 + 1, 2, K.BR_L)
	c.rect(x - cw + 1, y + 2, maxi(1, cw * 2 - 1), 1, K.BR_D)
	var top := y - ch
	c.rect(x - cw / 2, top, maxi(2, cw), ch, K.T_L)
	c.vline(x - cw / 2, top, y - 1, K.T_HI)
	c.vline(x - cw / 2 + maxi(2, cw) - 1, top, y - 1, K.T)
	c.px(x, top - 1, K.INK)
	# a wax drip
	c.px(x - cw / 2, top + ch / 2, K.T_HI)
	flames.append(Vector2i(x, top - 1))


# ---------------------------------------------------------------- chairs --

## One chair line-drawn at angle `ang` (radians, 0 = upright) with seat width
## `sc` px. u is across the seat, v is up. Overturned chairs are just rotated.
static func _chair(c: PixelCanvas, cx: float, cy: float, sc: float, ang: float, tone: int) -> void:
	var col: Color = [K.W_L, K.W, K.W_HI][tone % 3]
	var dark: Color = K.W_D
	var f := func(u: float, v: float) -> Vector2:
		return Vector2(cx, cy) + Vector2(u, -v).rotated(ang) * sc
	var th := 2 if sc > 12.0 else 1
	# far legs and back post first (darker), then the near ones over them
	_tline(c, f.call(-0.28, 0.02), f.call(-0.34, -0.95), dark, th)
	_tline(c, f.call(0.28, 0.02), f.call(0.34, -0.95), dark, th)
	# seat slab
	var seat := PackedVector2Array([f.call(-0.52, 0.03), f.call(0.52, 0.03), f.call(0.46, -0.13), f.call(-0.46, -0.13)])
	c.poly(seat, K.W_L)
	c.poly_outline(seat, dark)
	# back: two posts, a top rail and slats
	_tline(c, f.call(-0.46, 0.0), f.call(-0.43, 1.2), col, th)
	_tline(c, f.call(0.46, 0.0), f.call(0.43, 1.2), col, th)
	_tline(c, f.call(-0.45, 1.16), f.call(0.45, 1.16), K.W_HI, th)
	_tline(c, f.call(-0.44, 0.55), f.call(0.44, 0.55), col, 1)
	for u in [-0.2, 0.0, 0.2]:
		c.line(roundi(f.call(u, 0.56).x), roundi(f.call(u, 0.56).y), roundi(f.call(u, 1.14).x), roundi(f.call(u, 1.14).y), dark)
	# front legs with a stretcher
	_tline(c, f.call(-0.48, -0.1), f.call(-0.56, -1.05), col, th)
	_tline(c, f.call(0.48, -0.1), f.call(0.56, -1.05), col, th)
	c.line(roundi(f.call(-0.52, -0.6).x), roundi(f.call(-0.52, -0.6).y), roundi(f.call(0.52, -0.6).x), roundi(f.call(0.52, -0.6).y), dark)


## A tangle of overturned chairs, `wpx` wide. Variant picks the arrangement.
static func chair_pile(wpx: int, variant: int) -> PixelCanvas:
	wpx = clampi(_snap(wpx, 4), 16, 140)
	var key := "pile_%d_%d" % [wpx, variant]
	if _cache.has(key):
		return _cache[key]
	var w := wpx + 8
	var h := int(wpx * 0.95) + 6
	var c := PixelCanvas.new(w, h)
	var sc := wpx * 0.3
	var gy := h - 3.0
	var arrange: Array
	if variant == 0:
		# [x frac, y frac from floor, degrees, scale, tone]
		arrange = [[0.36, 0.12, 180.0, 1.0, 1], [0.7, 0.14, 168.0, 0.95, 0], [0.5, 0.5, 120.0, 0.95, 2], [0.24, 0.58, 205.0, 0.9, 0], [0.62, 0.86, 158.0, 0.9, 1]]
	else:
		arrange = [[0.32, 0.16, 190.0, 1.0, 0], [0.66, 0.12, 110.0, 0.95, 1], [0.5, 0.56, 168.0, 0.95, 2], [0.72, 0.62, 235.0, 0.85, 0]]
	# dark contact shadow
	c.ellipse_dither(w / 2.0, gy, w * 0.46, maxf(2.0, h * 0.06), K.DEEP)
	for a in arrange:
		var ang := deg_to_rad(a[2])
		# seat centre of the chair, in canvas px; y grows down
		_chair(c, 4.0 + a[0] * (w - 8), gy - a[1] * (h - 8) - sc * 0.4, sc * a[3], ang, a[4])
	c.outline(K.INK)
	_cache[key] = c
	return c


static func chair_single(hpx: int, ang_deg: float) -> PixelCanvas:
	hpx = clampi(_snap(hpx, 2), 8, 90)
	var key := "chair_%d_%d" % [hpx, int(ang_deg)]
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(int(hpx * 1.5) + 6, int(hpx * 1.4) + 6)
	_chair(c, c.w / 2.0, c.h * 0.55, hpx * 0.5, deg_to_rad(ang_deg), 1)
	c.outline(K.INK)
	_cache[key] = c
	return c
