class_name BanquetSprites
extends RefCounted

## Extra props for Trial II's Banquet background only, drawn in code with
## PixelCanvas exactly like scripts/court/sprite_forge.gd (which this file
## leaves untouched): wine barrels, garland swags, a fermenting fruit crate,
## a wall torch, and a wine jug. Cached per exact pixel size, same pattern as
## SpriteForge._cached.

static var _cache := {}


static func _cached(key: String, make: Callable) -> PixelCanvas:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


## A standing wine barrel, `hpx` tall, iron-hooped oak.
static func wine_barrel(hpx: int) -> PixelCanvas:
	return _cached("barrel_%d" % hpx, func() -> PixelCanvas: return _wine_barrel(hpx))


static func _wine_barrel(hpx: int) -> PixelCanvas:
	var hh := maxi(10, hpx)
	var w := int(round(hh * 0.78))
	w += w % 2
	var c := PixelCanvas.new(w + 2, hh + 2)
	var cx := (w + 2) / 2.0
	var top := 1.0
	var bot := float(hh)
	# barrel body: wider at the belly than at top/bottom
	var pts := PackedVector2Array()
	var n := 10
	for i in range(n + 1):
		var u := float(i) / n
		var y := lerpf(top, bot, u)
		var bulge := sin(u * PI)
		var hw := (w * 0.32) + (w * 0.18) * bulge
		pts.append(Vector2(cx + hw, y))
	for i in range(n + 1):
		var u := 1.0 - float(i) / n
		var y := lerpf(top, bot, u)
		var bulge := sin(u * PI)
		var hw := (w * 0.32) + (w * 0.18) * bulge
		pts.append(Vector2(cx - hw, y))
	c.poly(pts, BanquetPal.OAK)
	# stave shading: a dark seam every couple of px, a light band on the left
	for x in range(int(cx - w * 0.42), int(cx + w * 0.42), maxi(2, int(w * 0.12))):
		if x < cx:
			continue
		for y in range(int(top) + 1, int(bot)):
			if c.opaque(x, y):
				c.px(x, y, BanquetPal.OAK_DARK)
	for y in range(int(top) + 1, int(bot)):
		if c.opaque(int(cx - w * 0.34), y):
			c.px(int(cx - w * 0.34), y, BanquetPal.OAK_LIGHT)
	# three iron hoops
	for f in [0.16, 0.5, 0.84]:
		var ff: float = f
		var hy := int(round(lerpf(top, bot, ff)))
		var u2: float = absf(ff - 0.5) * 2.0
		var hw2: float = (w * 0.32) + (w * 0.19) * (1.0 - u2 * u2)
		c.hline(int(round(cx - hw2)) - 1, int(round(cx + hw2)) + 1, hy, BanquetPal.HOOP)
		c.hline(int(round(cx - hw2)) - 1, int(round(cx + hw2)) + 1, hy + 1, BanquetPal.HOOP)
		c.px(int(round(cx - hw2 * 0.4)), hy, BanquetPal.HOOP_LIGHT)
	c.outline(Pal.INK)
	return c


## A crate of overripe, fermenting fruit with a couple of flies over it.
static func fermenting_crate(wpx: int) -> PixelCanvas:
	return _cached("crate_%d" % wpx, func() -> PixelCanvas: return _fermenting_crate(wpx))


static func _fermenting_crate(wpx: int) -> PixelCanvas:
	var w := maxi(10, wpx)
	var h := int(round(w * 0.85))
	var c := PixelCanvas.new(w + 2, h + 2)
	var cx := (w + 2) / 2.0
	var base := float(h)
	# slatted crate
	c.rect(1, int(base * 0.55), w, int(base * 0.42), BanquetPal.OAK)
	for x in range(1, w + 1, maxi(2, w / 5)):
		c.vline(x, int(base * 0.55), int(base), BanquetPal.OAK_DARK)
	c.hline(1, w, int(base * 0.55), BanquetPal.OAK_LIGHT)
	c.hline(1, w, int(base), BanquetPal.OAK_DARK)
	# overripe fruit heaped above the rim, spilling a little over the edge
	var rng := RandomNumberGenerator.new()
	rng.seed = w * 7 + 3
	for i in 6:
		var fx := cx + rng.randf_range(-w * 0.4, w * 0.4)
		var fy := base * 0.5 - rng.randf_range(0.0, w * 0.22)
		var r := w * rng.randf_range(0.1, 0.16)
		c.ellipse(fx, fy, r, r * 0.9, BanquetPal.FERMENT if i % 2 == 0 else Pal.CRIMSON)
		c.px(roundi(fx - r * 0.3), roundi(fy - r * 0.3), BanquetPal.FERMENT_DARK if i % 2 == 0 else Pal.CRIMSON_DARK)
	c.outline(Pal.INK)
	# a couple of flies hovering over the pile (drawn after outline: not part of the shape)
	for p in [Vector2(cx - w * 0.2, base * 0.18), Vector2(cx + w * 0.28, base * 0.28), Vector2(cx + w * 0.02, base * 0.08)]:
		c.px(roundi(p.x), roundi(p.y), BanquetPal.FLY)
	return c


## A wall-mounted torch. Returns {canvas, flame: Vector2i} (flame spot local
## to the canvas, screen-space offset added by the caller).
static func torch_sconce(hpx: int) -> Dictionary:
	var hh := maxi(8, hpx)
	var w := int(round(hh * 0.6))
	w += w % 2 + 1
	var c := PixelCanvas.new(w + 2, hh + 2)
	var cx := (w + 2) / 2
	# iron bracket against the wall
	c.rect(cx - 1, hh - 3, 3, 3, BanquetPal.HOOP)
	c.vline(cx, int(hh * 0.35), hh - 3, BanquetPal.HOOP)
	c.rect(cx - 2, int(hh * 0.3), 4, 2, BanquetPal.HOOP_LIGHT)
	# torch head: bound rags soaked in oil
	c.ellipse(cx, hh * 0.22, w * 0.32, hh * 0.16, BanquetPal.OAK_DARK)
	c.hline(cx - int(w * 0.28), cx + int(w * 0.28), int(hh * 0.2), BanquetPal.OAK)
	c.outline(Pal.INK)
	return {"canvas": c, "flame": Vector2i(cx, int(hh * 0.02))}


## A tall wine jug (as opposed to SpriteForge's shorter goblet).
static func wine_jug(hpx: int) -> PixelCanvas:
	return _cached("jug_%d" % hpx, func() -> PixelCanvas: return _wine_jug(hpx))


static func _wine_jug(hpx: int) -> PixelCanvas:
	var hh := maxi(6, hpx)
	var w := maxi(4, int(round(hh * 0.62)))
	var c := PixelCanvas.new(w + 3, hh + 2)
	var cx := (w + 3) / 2.0
	c.ellipse(cx, hh * 0.42, w * 0.5, hh * 0.4, BanquetPal.WINE)
	c.ellipse(cx - w * 0.14, hh * 0.3, w * 0.18, hh * 0.14, BanquetPal.WINE_LIGHT)
	c.rect(int(cx - w * 0.22), 1, int(w * 0.44), int(hh * 0.2), Pal.GOLD_DARK)
	c.hline(int(cx - w * 0.22), int(cx + w * 0.22), 1, Pal.GOLD)
	# handle
	c.linev(Vector2(cx + w * 0.42, hh * 0.2), Vector2(cx + w * 0.62, hh * 0.5), BanquetPal.WINE)
	c.linev(Vector2(cx + w * 0.62, hh * 0.5), Vector2(cx + w * 0.42, hh * 0.72), BanquetPal.WINE)
	c.outline(Pal.INK)
	return c
