class_name ParchmentBackdrop
extends RefCounted

## The shared parchment / illuminated-manuscript backdrop for every non-play
## screen: Lobby, Role Reveal, Prince Intro, Trial Intro, Chronicle, Level Lab
## and Royal Decree (docs/GAME_FLOW.md section 2; look defined in
## docs/GAME_DESIGN.md "Look"). Painted once into a 640x360 PixelCanvas
## (HallCam.W x HallCam.H) with the project's own dither/flat-color/hard-ink
## conventions: no gradients, no blur, no imported art.
##
## paint() draws:
##   - an aged parchment page (dithered age spots + a worn, speckled edge)
##   - a double-ruled illuminated border in `accent` with 4 gold-leaf fleuron
##     corners
##   - doodled flies in the margin band, the illuminated-manuscript-insects
##     joke the design doc calls for
##   - optionally (`drop_cap`) an empty illuminated initial-letter frame in
##     the top-left of the content area
## content_rect() is the plain, undecorated rectangle left for a screen's own
## panel/title/etc.
##
## Static art: call paint() once and cache the resulting texture (see
## ParchmentBackdropNode), never redraw it per frame.

const W := 640
const H := 360

## Tones for aging/gilding only, scoped to this file (pal.gd is untouched).
const AGE_SPOT := Color("#C7B489")
const AGE_FOX := Color("#A98F63")
const WORM_HOLE := Color("#241A12")

const OUTER_INSET := 6   # outer hard ink frame
const RULE_INSET := 9    # outer accent rule
const RULE_INNER := 30   # inner accent rule
const INNER_INSET := 34  # inner hard ink frame; content_rect() starts here
const CORNER_MARGIN := 13  # fleuron center offset from the page edge, along each axis from RULE_INSET


static func content_rect() -> Rect2i:
	return Rect2i(INNER_INSET, INNER_INSET, W - INNER_INSET * 2, H - INNER_INSET * 2)


## `accent` tints the rule lines, fleurons and drop-cap frame so screens can
## vary the shared look (e.g. Pal.GOLD for most screens, Pal.CRIMSON for a
## warning-flavoured one). `seed` keeps the aging/bug placement reproducible.
static func paint(accent: Color = Pal.GOLD, drop_cap: bool = false, seed: int = 1337) -> PixelCanvas:
	var c := PixelCanvas.new(W, H)
	c.rect(0, 0, W, H, Pal.PARCHMENT)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_age_spots(c, rng)
	_edge_wear(c, rng)
	_border(c, accent)
	_corners(c, accent)
	_margin_bugs(c, rng)
	if drop_cap:
		_drop_cap_frame(c, accent)
	return c


# --------------------------------------------------------------- aging --

static func _age_spots(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	for i in 50:
		var x := rng.randi_range(3, W - 4)
		var y := rng.randi_range(3, H - 4)
		var r := rng.randf_range(2.5, 8.0)
		var tones := [Pal.PARCHMENT_DARK, AGE_SPOT, AGE_FOX]
		var tone: Color = tones[rng.randi_range(0, 2)]
		c.ellipse_dither(x, y, r, r * rng.randf_range(0.55, 1.0), tone, rng.randi_range(0, 1))
	# a handful of small dark foxing flecks / worm holes
	for i in 10:
		var x := rng.randi_range(OUTER_INSET, W - OUTER_INSET - 1)
		var y := rng.randi_range(OUTER_INSET, H - OUTER_INSET - 1)
		c.px(x, y, WORM_HOLE)
		if rng.randi_range(0, 1) == 1:
			c.px(x + 1, y, WORM_HOLE)


static func _edge_wear(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	## Random speckling whose odds fall off away from the very edge: a
	## pixel-art stand-in for a worn, foxed page edge (deliberately irregular,
	## not a neat checker ring, so it doesn't read as a woven trim).
	for ring in range(OUTER_INSET):
		var density := 0.9 - (float(ring) / float(OUTER_INSET)) * 0.75
		var col := Pal.PARCHMENT_SHADE if ring < 3 else Pal.PARCHMENT_DARK
		for x in range(ring, W - ring):
			if rng.randf() < density:
				c.px(x, ring, col)
			if rng.randf() < density:
				c.px(x, H - 1 - ring, col)
		for y in range(ring, H - ring):
			if rng.randf() < density:
				c.px(ring, y, col)
			if rng.randf() < density:
				c.px(W - 1 - ring, y, col)
	for i in 26:
		var edge := rng.randi_range(0, 3)
		match edge:
			0:
				c.px(rng.randi_range(0, W - 1), rng.randi_range(0, 2), Pal.INK_SOFT)
			1:
				c.px(rng.randi_range(0, W - 1), H - 1 - rng.randi_range(0, 2), Pal.INK_SOFT)
			2:
				c.px(rng.randi_range(0, 2), rng.randi_range(0, H - 1), Pal.INK_SOFT)
			_:
				c.px(W - 1 - rng.randi_range(0, 2), rng.randi_range(0, H - 1), Pal.INK_SOFT)


# ---------------------------------------------------------- border/frame --

static func _border(c: PixelCanvas, accent: Color) -> void:
	c.frame(OUTER_INSET, OUTER_INSET, W - OUTER_INSET * 2, H - OUTER_INSET * 2, Pal.INK)
	c.frame(RULE_INSET, RULE_INSET, W - RULE_INSET * 2, H - RULE_INSET * 2, accent)
	c.frame(RULE_INNER, RULE_INNER, W - RULE_INNER * 2, H - RULE_INNER * 2, accent)
	c.frame(INNER_INSET, INNER_INSET, W - INNER_INSET * 2, H - INNER_INSET * 2, Pal.INK)


static func _corners(c: PixelCanvas, accent: Color) -> void:
	var o := RULE_INSET + CORNER_MARGIN
	for p in [Vector2i(o, o), Vector2i(W - o, o), Vector2i(o, H - o), Vector2i(W - o, H - o)]:
		_fleuron(c, p.x, p.y, accent)


## An 8-point gold-leaf fleuron: flat accent fill, hard ink outline, a single
## light dot for the leaf's highlight. Echoes the diamond ties in
## LobbyOverlay._flourish so both read as the same manuscript hand.
static func _fleuron(c: PixelCanvas, cx: int, cy: int, accent: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(cx, cy - 7), Vector2(cx + 3, cy - 3), Vector2(cx + 7, cy),
		Vector2(cx + 3, cy + 3), Vector2(cx, cy + 7), Vector2(cx - 3, cy + 3),
		Vector2(cx - 7, cy), Vector2(cx - 3, cy - 3),
	])
	c.poly(pts, accent)
	c.poly_outline(pts, Pal.INK)
	c.ellipse(cx, cy, 2, 2, Pal.GOLD_LIGHT)
	c.px(cx, cy, Pal.INK)


# ------------------------------------------------------------- margin bugs --

## Small doodled flies along the margin band (between the outer and inner
## rules), the "medieval manuscripts really are full of insects in the
## margins" joke from docs/GAME_DESIGN.md.
static func _margin_bugs(c: PixelCanvas, rng: RandomNumberGenerator) -> void:
	var band_top := (RULE_INSET + RULE_INNER) / 2
	var band_bottom := H - band_top
	var band_left := (RULE_INSET + RULE_INNER) / 2
	var band_right := W - band_left
	var skip := RULE_INSET + CORNER_MARGIN + 16
	var x := skip
	while x < W - skip:
		_bug(c, x, band_top + rng.randi_range(-3, 3), rng)
		_bug(c, x + 24, band_bottom + rng.randi_range(-3, 3), rng)
		x += 52
	var y := skip
	while y < H - skip:
		_bug(c, band_left + rng.randi_range(-3, 3), y, rng)
		_bug(c, band_right + rng.randi_range(-3, 3), y + 22, rng)
		y += 52


## A tiny fly doodle, ~9x8 px: dithered wings, an ink-soft body, ink antennae
## and hind legs. Flat color only, so it reads as a pen sketch, not a sprite.
static func _bug(c: PixelCanvas, x: int, y: int, rng: RandomNumberGenerator) -> void:
	c.ellipse_dither(x - 3, y, 4, 2, Pal.PARCHMENT_DARK, 0)
	c.ellipse_dither(x + 3, y, 4, 2, Pal.PARCHMENT_DARK, 1)
	c.ellipse(x, y + 1, 2, 1.7, Pal.INK_SOFT)
	c.ellipse(x, y - 1, 1.3, 1.3, Pal.INK)
	c.line(x - 1, y - 2, x - 2, y - 4, Pal.INK)
	c.line(x + 1, y - 2, x + 2, y - 4, Pal.INK)
	c.line(x - 1, y + 3, x - 3, y + 5, Pal.INK)
	c.line(x + 1, y + 3, x + 3, y + 5, Pal.INK)


# --------------------------------------------------------------- variant --

## An empty illuminated-initial frame in the top-left of the content area:
## just the frame and its two fleurons, ready for a screen to draw its own
## drop-cap letter or crest on top.
static func _drop_cap_frame(c: PixelCanvas, accent: Color) -> void:
	var x := INNER_INSET + 6
	var y := INNER_INSET + 6
	var size := 40
	c.rect(x, y, size, size, Pal.PARCHMENT_DARK)
	c.frame(x, y, size, size, Pal.INK)
	c.frame(x + 2, y + 2, size - 4, size - 4, accent)
	_fleuron(c, x - 3, y - 3, accent)
	_fleuron(c, x + size + 3, y - 3, accent)
