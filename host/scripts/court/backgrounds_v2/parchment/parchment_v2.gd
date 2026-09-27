class_name ParchmentV2
extends RefCounted

## v2 of the shared parchment / illuminated-manuscript backdrop (640x360).
## Static art, painted once per variant and cached by the caller.
## Fixes v1: margin insects vary (pose, size, spacing, clustering), the border
## band carries vines, scrollwork, gold-leaf initials, rubrication marks and ink
## blots; the page has dithered water stains, foxing, a burnt edge and faint
## ruled lines. content_rect() stays plain.

const W := 640
const H := 360
const OUTER := 6
const RULE_A := 9
const RULE_B := 30
const INNER := 34

const AGE_SPOT := Color("#C7B489")
const AGE_FOX := Color("#A98F63")
const STAIN := Color("#CDB88A")
const BURN := Color("#8F7650")
const WORM := Color("#241A12")

## screen -> look. accent tints rules/leaves; alt is the secondary (berries, inner ring).
const VARIANTS := {
	"lobby": {"accent": Pal.GOLD, "alt": Pal.CRIMSON, "cap": false, "seed": 11, "grid": false, "seal": false, "blots": 5},
	"role": {"accent": Pal.ROYAL_LIGHT, "alt": Pal.GOLD, "cap": true, "seed": 23, "grid": false, "seal": false, "blots": 4},
	"prince": {"accent": Pal.CRIMSON_LIGHT, "alt": Pal.GOLD, "cap": true, "seed": 37, "grid": false, "seal": false, "blots": 6},
	"trial": {"accent": Pal.GOLD, "alt": Pal.ROYAL, "cap": true, "seed": 41, "grid": false, "seal": false, "blots": 5},
	"chronicle": {"accent": Pal.GOLD_DARK, "alt": Pal.CRIMSON, "cap": false, "seed": 53, "grid": false, "seal": false, "blots": 9},
	"lab": {"accent": Pal.ROYAL, "alt": Pal.GOLD, "cap": false, "seed": 67, "grid": true, "seal": false, "blots": 4},
	"decree": {"accent": Pal.CRIMSON, "alt": Pal.GOLD, "cap": true, "seed": 79, "grid": false, "seal": true, "blots": 7},
}


static func content_rect() -> Rect2i:
	return Rect2i(INNER, INNER, W - INNER * 2, H - INNER * 2)


static func paint(variant: String) -> PixelCanvas:
	var v: Dictionary = VARIANTS.get(variant, VARIANTS["lobby"])
	var accent: Color = v.accent
	var alt: Color = v.alt
	var rng := RandomNumberGenerator.new()
	rng.seed = int(v.seed)
	var c := PixelCanvas.new(W, H)
	c.rect(0, 0, W, H, Pal.PARCHMENT)
	_stains(c, rng)
	_ruled(c, bool(v.grid))
	_edge_burn(c, rng)
	_band_fill(c, accent, alt, rng)
	_border(c, accent)
	_corners(c, accent, alt)
	_initials(c, accent, alt, rng)
	_blots(c, rng, int(v.blots))
	_rubrics(c, rng)
	_margin_life(c, accent, rng)
	if bool(v.cap):
		_drop_cap(c, accent, alt, variant)
	if bool(v.seal):
		_wax_drip(c)
	_foxing(c, rng)
	return c


# ----------------------------------------------------------------- page --

static func _stains(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	# layered dithered blooms: darker core, lighter halo, so tone steps fake a wash
	for i in 7:
		var x := rng.randf_range(20, W - 20)
		var y := rng.randf_range(20, H - 20)
		var r := rng.randf_range(14, 30)
		for k in rng.randi_range(3, 6):
			var ox := rng.randf_range(-r, r) * 0.8
			var oy := rng.randf_range(-r, r) * 0.6
			var rr := rng.randf_range(0.35, 0.8) * r
			c.ellipse_dither(x + ox, y + oy, rr, rr * rng.randf_range(0.4, 0.9), Pal.PARCHMENT_DARK, k % 2)
			if k % 3 == 0:
				c.ellipse_dither(x + ox, y + oy, rr * 0.5, rr * 0.35, STAIN, (k + 1) % 2)
	# a couple of tide-marked cup rings
	for i in 3:
		var x := rng.randf_range(90, W - 90)
		var y := rng.randf_range(70, H - 70)
		var r := rng.randf_range(12, 22)
		var a := 0.0
		while a < TAU:
			if rng.randf() < 0.82:
				c.px(int(x + cos(a) * r), int(y + sin(a) * r * 0.9), AGE_SPOT)
			a += 0.04
		c.ellipse_dither(x, y, r - 1, r * 0.85, Pal.PARCHMENT_DARK, 1)
	for i in 34:
		var x := rng.randi_range(3, W - 4)
		var y := rng.randi_range(3, H - 4)
		var r := rng.randf_range(1.5, 5.0)
		c.ellipse_dither(x, y, r, r * rng.randf_range(0.6, 1.0), [AGE_SPOT, AGE_FOX][rng.randi() % 2], rng.randi() % 2)


static func _ruled(c: PixelCanvas, grid: bool) -> void:
	# faint dotted ruling: the scribe's pricking lines
	var y := INNER + 12
	while y < H - INNER:
		var x := INNER + 2
		while x < W - INNER - 1:
			c.px(x, y, Pal.PARCHMENT_DARK)
			x += 2
		y += 16
	if grid:
		var gx := INNER + 8
		while gx < W - INNER:
			var yy := INNER + 2
			while yy < H - INNER - 1:
				c.px(gx, yy, Pal.PARCHMENT_DARK)
				yy += 2
			gx += 16
	# vertical scribing margins
	for mx in [INNER + 4, W - INNER - 5]:
		var yy := INNER + 2
		while yy < H - INNER - 1:
			c.px(mx, yy, Pal.PARCHMENT_SHADE if (yy / 2) % 6 == 0 else Pal.PARCHMENT_DARK)
			yy += 2


static func _edge_burn(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	# dithered aging that grows toward the edge; heavier in the corners
	for y in H:
		for x in W:
			var d := mini(mini(x, W - 1 - x), mini(y, H - 1 - y))
			var cd := minf(minf(x, W - 1 - x), 40.0) + minf(minf(y, H - 1 - y), 40.0)
			var depth := 0
			if d < 3:
				depth = 3
			elif d < 6:
				depth = 2
			elif d < 12:
				depth = 1
			if cd < 26.0:
				depth += 1
			if depth <= 0:
				continue
			var chk := (x + y) % 2 == 0
			match depth:
				1:
					if chk and rng.randf() < 0.75:
						c.px(x, y, Pal.PARCHMENT_DARK)
				2:
					c.px(x, y, Pal.PARCHMENT_DARK if chk else Pal.PARCHMENT_SHADE if rng.randf() < 0.35 else Pal.PARCHMENT_DARK)
				3:
					c.px(x, y, Pal.PARCHMENT_SHADE if chk or rng.randf() < 0.4 else BURN)
				_:
					c.px(x, y, BURN if rng.randf() < 0.7 else Pal.PARCHMENT_SHADE)
	# nibbled rim
	for i in 60:
		var e := rng.randi() % 4
		var t := rng.randi_range(0, 640 if e < 2 else 360)
		var dpt := rng.randi_range(0, 2)
		match e:
			0: c.px(t % W, dpt, Pal.INK_SOFT)
			1: c.px(t % W, H - 1 - dpt, Pal.INK_SOFT)
			2: c.px(dpt, t % H, Pal.INK_SOFT)
			_: c.px(W - 1 - dpt, t % H, Pal.INK_SOFT)


static func _foxing(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	for i in 14:
		var x := rng.randi_range(OUTER + 2, W - OUTER - 3)
		var y := rng.randi_range(OUTER + 2, H - OUTER - 3)
		if _in_content(x, y):
			continue
		c.px(x, y, WORM)
		if rng.randi() % 2 == 0:
			c.px(x + 1, y, AGE_FOX)


static func _in_content(x: int, y: int) -> bool:
	return x > INNER and x < W - INNER and y > INNER and y < H - INNER


# ---------------------------------------------------------- border/band --

static func _border(c: PixelCanvas, accent: Color) -> void:
	c.frame(OUTER, OUTER, W - OUTER * 2, H - OUTER * 2, Pal.INK)
	c.frame(RULE_A, RULE_A, W - RULE_A * 2, H - RULE_A * 2, accent)
	c.frame(RULE_A + 1, RULE_A + 1, W - RULE_A * 2 - 2, H - RULE_A * 2 - 2, Pal.INK_SOFT)
	c.frame(RULE_B - 1, RULE_B - 1, W - (RULE_B - 1) * 2, H - (RULE_B - 1) * 2, Pal.INK_SOFT)
	c.frame(RULE_B, RULE_B, W - RULE_B * 2, H - RULE_B * 2, accent)
	c.frame(INNER, INNER, W - INNER * 2, H - INNER * 2, Pal.INK)
	# tiny gilt studs on the outer rule every 24 px
	for x in range(RULE_A + 40, W - RULE_A - 30, 24):
		c.px(x, RULE_A, Pal.GOLD_LIGHT)
		c.px(x, H - 1 - RULE_A, Pal.GOLD_LIGHT)
	for y in range(RULE_A + 40, H - RULE_A - 30, 24):
		c.px(RULE_A, y, Pal.GOLD_LIGHT)
		c.px(W - 1 - RULE_A, y, Pal.GOLD_LIGHT)


## The band between RULE_A and RULE_B is filled with a hand-drawn vine, built as a
## horizontal strip and rotated/flipped onto the four sides.
static func _band_fill(c: PixelCanvas, accent: Color, alt: Color, rng: RandomNumberGenerator) -> void:
	var top := _vine_strip(W - 2 * (RULE_A + 22), accent, alt, rng)
	var bot := _vine_strip(W - 2 * (RULE_A + 22), accent, alt, rng)
	bot.img.flip_y()
	var left := _vine_strip(H - 2 * (RULE_A + 22), accent, alt, rng)
	var right := _vine_strip(H - 2 * (RULE_A + 22), accent, alt, rng)
	left.img.rotate_90(COUNTERCLOCKWISE)
	right.img.rotate_90(CLOCKWISE)
	left.w = left.img.get_width()
	left.h = left.img.get_height()
	right.w = right.img.get_width()
	right.h = right.img.get_height()
	c.blit(top, RULE_A + 22, RULE_A + 1)
	c.blit(bot, RULE_A + 22, H - RULE_B)
	c.blit(left, RULE_A + 1, RULE_A + 22)
	c.blit(right, W - RULE_B, RULE_A + 22)


static func _vine_strip(length: int, accent: Color, alt: Color, rng: RandomNumberGenerator) -> PixelCanvas:
	var bh := RULE_B - RULE_A - 1   # 20 px tall
	var s := PixelCanvas.new(length, bh)
	var mid := bh / 2.0
	var ph := rng.randf_range(0.0, TAU)
	var freq := rng.randf_range(0.075, 0.1)
	var prev := Vector2(-1, mid)
	var next_leaf := 6
	var side := 1
	var next_curl := rng.randi_range(40, 70)
	for x in length:
		var y := mid + sin(x * freq + ph) * 4.2
		var cur := Vector2(x, y)
		s.line(int(prev.x), roundi(prev.y), x, roundi(y), Pal.INK_SOFT)
		prev = cur
		if x == next_leaf:
			_leaf(s, x, roundi(y), side, accent, rng)
			side = -side
			next_leaf += rng.randi_range(8, 16)
			if rng.randi() % 5 == 0:
				s.ellipse(x + 0.5, y + side * 4.0, 1.6, 1.6, alt)  # berry
				s.px(x, roundi(y + side * 4.0) - 1, Pal.INK)
		if x == next_curl:
			_curl(s, x, roundi(y), -side, accent)
			next_curl += rng.randi_range(46, 90)
	return s


static func _leaf(s: PixelCanvas, x: int, y: int, side: int, accent: Color, rng: RandomNumberGenerator) -> void:
	var l := rng.randi_range(4, 6)
	var pts := PackedVector2Array([
		Vector2(x, y), Vector2(x + 2, y + side * l * 0.6), Vector2(x + 1, y + side * (l + 2)),
		Vector2(x - 2, y + side * l * 0.6)])
	s.poly(pts, accent)
	s.poly_outline(pts, Pal.INK_SOFT)
	s.px(x, y + side * 2, Pal.GOLD_LIGHT)


static func _curl(s: PixelCanvas, x: int, y: int, side: int, accent: Color) -> void:
	var r := 5.0
	var a := 0.0
	var prev := Vector2(x, y)
	while r > 0.9:
		a += 0.35
		r -= 0.13
		var p := Vector2(x + 2 + cos(a) * r, y + side * (r + 1.0) + sin(a) * r * side * 0.9)
		s.linev(prev, p, Pal.INK_SOFT)
		prev = p
	s.px(int(prev.x), int(prev.y), accent)


static func _corners(c: PixelCanvas, accent: Color, alt: Color) -> void:
	var o := RULE_A + 13
	var spots := [Vector2i(o, o), Vector2i(W - 1 - o, o), Vector2i(o, H - 1 - o), Vector2i(W - 1 - o, H - 1 - o)]
	for i in 4:
		var p: Vector2i = spots[i]
		var sx := 1 if p.x < W / 2 else -1
		var sy := 1 if p.y < H / 2 else -1
		# clear the vine under the corner, then a filigree cross-piece
		c.rect(p.x - 12, p.y - 12, 25, 25, Pal.PARCHMENT_DARK)
		c.frame(p.x - 12, p.y - 12, 25, 25, Pal.INK_SOFT)
		c.frame(p.x - 10, p.y - 10, 21, 21, accent)
		# spirals curling out from the fleuron along the two edges
		_spiral(c, p.x + sx * 8, p.y + sy * 1, sx, sy, alt)
		_spiral(c, p.x + sx * 1, p.y + sy * 8, sy, sx, alt)
		_fleuron(c, p.x, p.y, accent)


static func _spiral(c: PixelCanvas, cx: int, cy: int, sx: int, sy: int, col: Color) -> void:
	var r := 3.6
	var a := 0.0
	var prev := Vector2(cx, cy)
	while r > 0.6:
		a += 0.5
		r -= 0.16
		var p := Vector2(cx + cos(a) * r * sx, cy + sin(a) * r * sy)
		c.linev(prev, p, Pal.INK)
		prev = p
	c.px(int(prev.x), int(prev.y), col)


static func _fleuron(c: PixelCanvas, cx: int, cy: int, accent: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(cx, cy - 8), Vector2(cx + 3, cy - 3), Vector2(cx + 8, cy),
		Vector2(cx + 3, cy + 3), Vector2(cx, cy + 8), Vector2(cx - 3, cy + 3),
		Vector2(cx - 8, cy), Vector2(cx - 3, cy - 3)])
	c.poly(pts, Pal.GOLD)
	c.poly_outline(pts, Pal.INK)
	c.ellipse(cx, cy, 3, 3, accent)
	c.ellipse(cx, cy, 1.5, 1.5, Pal.GOLD_LIGHT)
	c.px(cx - 1, cy - 1, Pal.PARCHMENT)


# -------------------------------------------------------- band ornaments --

## Small gold-leaf illuminated initials set into the band: gilt square, ink
## frame, an accent lozenge and a crimson/alt rubric dot.
static func _initials(c: PixelCanvas, accent: Color, alt: Color, rng: RandomNumberGenerator) -> void:
	var spots := []
	for i in 3:
		spots.append(Vector2i(rng.randi_range(90, W - 90), 0))
	var picks := [Vector2i(rng.randi_range(110, 260), RULE_A + 10), Vector2i(rng.randi_range(380, 520), H - RULE_A - 11),
		Vector2i(RULE_A + 10, rng.randi_range(120, 240)), Vector2i(W - RULE_A - 11, rng.randi_range(110, 250))]
	for p in picks:
		var x: int = p.x - 6
		var y: int = p.y - 6
		c.rect(x, y, 13, 13, Pal.INK)
		c.rect(x + 1, y + 1, 11, 11, Pal.GOLD)
		c.rect(x + 1, y + 1, 11, 1, Pal.GOLD_LIGHT)
		c.rect(x + 1, y + 1, 1, 11, Pal.GOLD_LIGHT)
		var d := PackedVector2Array([Vector2(x + 6.5, y + 2), Vector2(x + 11, y + 6.5), Vector2(x + 6.5, y + 11), Vector2(x + 2, y + 6.5)])
		c.poly(d, accent)
		c.poly_outline(d, Pal.INK)
		c.px(x + 6, y + 6, alt)
		c.px(x + 7, y + 6, Pal.GOLD_LIGHT)


static func _blots(c: PixelCanvas, rng: RandomNumberGenerator, n: int) -> void:
	for i in n:
		var edge := rng.randi() % 4
		var x := 0
		var y := 0
		match edge:
			0: x = rng.randi_range(60, W - 60); y = rng.randi_range(12, 27)
			1: x = rng.randi_range(60, W - 60); y = H - rng.randi_range(12, 27)
			2: x = rng.randi_range(12, 27); y = rng.randi_range(60, H - 60)
			_: x = W - rng.randi_range(12, 27); y = rng.randi_range(60, H - 60)
		var r := rng.randf_range(1.6, 3.6)
		c.ellipse(x, y, r, r * rng.randf_range(0.7, 1.0), Pal.INK)
		c.px(x - 1, y - 1, Pal.INK_SOFT)
		for k in rng.randi_range(2, 5):
			var a := rng.randf() * TAU
			var d := r + rng.randf_range(2.0, 5.0)
			c.px(int(x + cos(a) * d), int(y + sin(a) * d), Pal.INK)
		if rng.randi() % 2 == 0:  # drip / smear
			c.vline(x, y, y + rng.randi_range(2, 5), Pal.INK)


## Rubrication: little crimson pilcrows and paragraph ticks in the band.
static func _rubrics(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	for i in 9:
		var horizontal := rng.randi() % 2 == 0
		var x := rng.randi_range(60, W - 60) if horizontal else (RULE_A + 4 if rng.randi() % 2 == 0 else W - RULE_B + 3)
		var y := (RULE_A + 4 if rng.randi() % 2 == 0 else H - RULE_B + 3) if horizontal else rng.randi_range(60, H - 60)
		# pilcrow: bowl + stem
		c.rect(x, y, 3, 3, Pal.CRIMSON)
		c.px(x + 1, y + 1, Pal.PARCHMENT)
		c.vline(x + 2, y, y + 5, Pal.CRIMSON)
		c.vline(x + 3, y, y + 5, Pal.CRIMSON)
	# rubric dash-dot runs beside the ruled scribing margin
	for y in range(INNER + 10, H - INNER - 8, 34):
		c.rect(INNER + 2, y, 3, 1, Pal.CRIMSON)
		c.px(INNER + 2, y + 2, Pal.CRIMSON)


# ------------------------------------------------------------ margin life --

## Insects in the band, each different: pose, size, orientation, spacing.
static func _margin_life(c: PixelCanvas, accent: Color, rng: RandomNumberGenerator) -> void:
	var spots := []
	var x := 60.0
	while x < W - 60:
		spots.append(Vector2(x, RULE_A + 10 + rng.randi_range(-2, 2)))
		x += rng.randf_range(28.0, 96.0) * (0.45 if rng.randi() % 5 == 0 else 1.0)
	x = 56.0
	while x < W - 56:
		spots.append(Vector2(x, H - RULE_A - 11 + rng.randi_range(-2, 2)))
		x += rng.randf_range(34.0, 110.0)
	var y := 64.0
	while y < H - 64:
		spots.append(Vector2(RULE_A + 10 + rng.randi_range(-2, 2), y))
		y += rng.randf_range(38.0, 100.0)
	y = 60.0
	while y < H - 60:
		spots.append(Vector2(W - RULE_A - 11 + rng.randi_range(-2, 2), y))
		y += rng.randf_range(38.0, 100.0)
	for s in spots:
		if rng.randf() < 0.28:
			continue
		var kind := rng.randi() % 6
		var size := rng.randi_range(0, 2)
		var flip := rng.randi() % 2 == 0
		var rot := rng.randi() % 4
		_critter(c, int(s.x), int(s.y), kind, size, flip, rot, accent)


## kinds: 0 fly wings open, 1 fly wings folded, 2 crawling fly (legs mid-step, side),
## 3 gnat, 4 beetle, 5 caterpillar. `rot` 0..3 quarter turns for edge variety.
static func _critter(c: PixelCanvas, x: int, y: int, kind: int, size: int, flip: bool, rot: int, accent: Color) -> void:
	var t := PixelCanvas.new(20, 20)
	var cx := 10
	var cy := 10
	var s := 0.75 + size * 0.25
	match kind:
		0:
			t.ellipse_dither(cx - 4 * s, cy - 1, 4 * s, 2.2 * s, Pal.PARCHMENT_SHADE, 0)
			t.ellipse_dither(cx + 4 * s, cy - 1, 4 * s, 2.2 * s, Pal.PARCHMENT_SHADE, 1)
			t.ellipse(cx, cy + 1, 1.8 * s, 2.6 * s, Pal.INK_SOFT)
			t.ellipse(cx, cy - 2 * s, 1.3, 1.3, Pal.INK)
			t.px(cx - 1, cy - 3 * s, Pal.CRIMSON)
			t.px(cx + 1, cy - 3 * s, Pal.CRIMSON)
			for dx in [-1, 1]:
				t.line(cx + dx, cy, cx + dx * 4, cy + 3, Pal.INK)
		1:
			t.ellipse(cx, cy + 1, 1.6 * s, 3.6 * s, Pal.INK_SOFT)
			t.line(cx - 1, cy - 1, cx - 2, cy + 4, Pal.PARCHMENT_SHADE)
			t.line(cx + 1, cy - 1, cx + 2, cy + 4, Pal.PARCHMENT_SHADE)
			t.ellipse(cx, cy - 3 * s, 1.4, 1.4, Pal.INK)
			t.line(cx - 1, cy - 4, cx - 3, cy - 6, Pal.INK)
			t.line(cx + 1, cy - 4, cx + 3, cy - 6, Pal.INK)
		2:
			# side view, mid-crawl: alternating legs, one foreleg lifted, wing tucked
			t.ellipse(cx, cy, 4 * s, 2.2 * s, Pal.INK_SOFT)
			t.ellipse(cx + 4 * s, cy - 0.5, 1.8, 1.8, Pal.INK)
			t.px(cx + 5 * s, cy - 1, Pal.CRIMSON)
			t.ellipse_dither(cx - 1, cy - 2, 3.4 * s, 1.5, Pal.PARCHMENT_SHADE, 0)
			t.line(cx - 2, cy + 1, cx - 4, cy + 4, Pal.INK)
			t.line(cx, cy + 1, cx + 1, cy + 4, Pal.INK)
			t.line(cx + 2, cy + 1, cx + 5, cy + 3, Pal.INK)   # lifted foreleg
			t.line(cx + 7 * s, cy - 2, cx + 9, cy - 4, Pal.INK)
		3:
			t.px(cx, cy, Pal.INK)
			t.px(cx, cy + 1, Pal.INK_SOFT)
			t.px(cx - 1, cy - 1, Pal.PARCHMENT_SHADE)
			t.px(cx + 1, cy - 1, Pal.PARCHMENT_SHADE)
			t.px(cx - 2, cy - 2, Pal.PARCHMENT_SHADE)
			t.px(cx + 2, cy - 2, Pal.PARCHMENT_SHADE)
		4:
			t.ellipse(cx, cy, 3.2 * s, 4 * s, accent)
			t.vline(cx, cy - 4 * s, cy + 3 * s, Pal.INK)
			t.ellipse(cx, cy - 4 * s, 1.6, 1.4, Pal.INK)
			t.ellipse(cx - 1, cy - 1, 1, 1.4, Pal.GOLD_LIGHT)
			for dy in [-2, 0, 2]:
				t.line(cx - 3, cy + dy, cx - 5, cy + dy + 1, Pal.INK)
				t.line(cx + 3, cy + dy, cx + 5, cy + dy + 1, Pal.INK)
		_:
			for i in 5:
				var oy := int(sin(i * 1.3) * 1.5)
				t.ellipse(cx - 6 + i * 3, cy + oy, 1.8, 1.8, Pal.GOLD_DARK if i % 2 == 0 else accent)
			t.ellipse(cx + 8, cy - 1, 1.6, 1.6, Pal.INK)
			t.px(cx + 9, cy - 3, Pal.INK)
	if kind in [0, 4]:
		t.outline(Pal.INK, false)
	if flip:
		t.img.flip_x()
	for r in rot:
		t.img.rotate_90(CLOCKWISE)
	c.blit(t, x - 10, y - 10)


# --------------------------------------------------------------- variants --

## Illuminated initial frame in the content's top-left (empty inside, for a
## screen to place its own letter/crest). Style varies per screen.
static func _drop_cap(c: PixelCanvas, accent: Color, alt: Color, variant: String) -> void:
	var x := INNER + 8
	var y := INNER + 8
	var sz := 44 if variant in ["prince", "decree"] else 38
	c.rect(x - 2, y - 2, sz + 4, sz + 4, Pal.INK)
	c.rect(x - 1, y - 1, sz + 2, sz + 2, Pal.GOLD)
	c.rect(x, y, sz, sz, accent)
	# dithered ground and quartered corners
	c.dither_rect(x + 2, y + 2, sz - 4, sz - 4, Pal.ROYAL_DARK if accent != Pal.ROYAL_LIGHT else Pal.CRIMSON_DARK, 0)
	c.rect(x + 4, y + 4, sz - 8, sz - 8, Pal.PARCHMENT_DARK)
	c.frame(x + 4, y + 4, sz - 8, sz - 8, Pal.INK)
	c.frame(x + 5, y + 5, sz - 10, sz - 10, Pal.GOLD_DARK)
	for q in [Vector2i(x + 2, y + 2), Vector2i(x + sz - 4, y + 2), Vector2i(x + 2, y + sz - 4), Vector2i(x + sz - 4, y + sz - 4)]:
		c.rect(q.x, q.y, 2, 2, Pal.GOLD_LIGHT)
	_fleuron_small(c, x - 3, y - 3, alt)
	_fleuron_small(c, x + sz + 3, y + sz + 3, alt)
	# little vine tendrils climbing out of the frame's right side
	for k in 3:
		c.line(x + sz + 2, y + 6 + k * 12, x + sz + 8, y + 3 + k * 12, Pal.INK_SOFT)
		c.rect(x + sz + 8, y + 2 + k * 12, 2, 2, accent)


static func _fleuron_small(c: PixelCanvas, cx: int, cy: int, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(cx, cy - 5), Vector2(cx + 2, cy - 2), Vector2(cx + 5, cy),
		Vector2(cx + 2, cy + 2), Vector2(cx, cy + 5), Vector2(cx - 2, cy + 2), Vector2(cx - 5, cy), Vector2(cx - 2, cy - 2)])
	c.poly(pts, Pal.GOLD)
	c.poly_outline(pts, Pal.INK)
	c.px(cx, cy, col)


static func _wax_drip(c: PixelCanvas) -> void:
	# stray crimson wax specks in the lower band, for the Decree
	var pts := [Vector2i(300, H - 20), Vector2i(316, H - 18), Vector2i(340, H - 21)]
	for p in pts:
		c.ellipse(p.x, p.y, 2.2, 1.6, Pal.CRIMSON)
		c.px(p.x - 1, p.y - 1, Pal.CRIMSON_LIGHT)

