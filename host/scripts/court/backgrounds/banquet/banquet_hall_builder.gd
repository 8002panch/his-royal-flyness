class_name BanquetHallBuilder
extends RefCounted

## A distinct, richer Banquet Hall variant for Trial II (arena theme
## "banquet"): the same layer structure as HallBuilder (paint_far / paint_floor
## / paint_columns / paint_feast, painted through a CanvasPainter or
## PixelCanvas `c`, same as hall_builder.gd) so it can later replace the
## HallLayer nodes under the chase camera. It calls HallBuilder's public,
## read-only paint_* functions for the shared stone/arcade/dais structure (so
## geometry stays pixel-identical to the rest of the game) and then layers
## banquet-only dressing on top: torch sconces, garland swags, straw and a
## warm rug. paint_feast is entirely new: one lavish, long banquet table with
## wine barrels and fermenting fruit crates concentrated at the upper-right of
## the hall (the feast scent source in docs/GAME_FLOW.md sits at x=48,y=32 of
## a 60x40 arena, i.e. the far right corner), and a single meagre plate on the
## left for Sir Cheapdate. Never edits hall_builder.gd, pal.gd or sprite_forge.gd.

const TABLE_TOP := -0.88   # matches HallBuilder.TABLE_TOP so props sit flush
static var ZN := -3.5

# The feast: one long table along the right wall, deep toward the back.
const FEAST_X0 := 1.35
const FEAST_X1 := 2.05
const FEAST_Z0 := -1.95
const FEAST_Z1 := 1.5

# Sir Cheapdate's plate: a small, sparse table on the left.
const MEAGRE_X0 := -2.05
const MEAGRE_X1 := -1.65
const MEAGRE_Z0 := -1.55
const MEAGRE_Z1 := -1.05


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func _quad_x(c, x: float, y0: float, y1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x, y0, z0), _p(x, y0, z1), _p(x, y1, z1), _p(x, y1, z0)])
	c.poly(q, col)
	return q


static func _quad_y(c, y: float, x0: float, x1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x0, y, z0), _p(x1, y, z0), _p(x1, y, z1), _p(x0, y, z1)])
	c.poly(q, col)
	return q


static func _quad_z(c, z: float, x0: float, x1: float, y0: float, y1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x0, y0, z), _p(x1, y0, z), _p(x1, y1, z), _p(x0, y1, z)])
	c.poly(q, col)
	return q


## A garland of bay leaves and berries strung between (x, y0, z0) and
## (x, y0, z1), sagging by `sag` at the middle. Drawn dot by dot in world
## space (like the dais's gold studs in hall_builder.gd) so it reads
## correctly whichever way it runs on screen, unlike a flat raster sprite.
static func _garland(c, x: float, y0: float, z0: float, z1: float, sag: float) -> void:
	var n := 16
	for i in range(n + 1):
		var u := float(i) / n
		var z := lerpf(z0, z1, u)
		if z < ZN:
			continue
		var y := y0 - sin(u * PI) * sag
		var sp := HallCam.project(Vector3(x, y, z))
		if sp.z <= 0.0:
			continue
		var r := clampf(0.028 * sp.z, 1.2, 3.2)
		if i % 3 == 0:
			c.ellipse(sp.x, sp.y, r, r * 0.8, BanquetPal.BERRY)
			c.px(roundi(sp.x - r * 0.4), roundi(sp.y - r * 0.4), BanquetPal.BERRY_LIGHT)
		else:
			c.ellipse(sp.x, sp.y, r * 1.15, r * 0.85, BanquetPal.LEAF)
			c.px(roundi(sp.x), roundi(sp.y - r * 0.4), BanquetPal.LEAF_DARK)


# -------------------------------------------------------------- far layer --

## Base vault/walls/great arch (HallBuilder, unmodified) plus a warm torch
## wash and lit sconces up the right-hand wall, where the feast is.
static func paint_far(c) -> void:
	HallBuilder.paint_far(c)
	ZN = HallCam.near_z()
	var wx := HallCam.WALL_X
	var fy := HallCam.FLOOR_Y
	var x := wx
	# a warm glow low on the feast-side wall, checker-dithered like the game's
	# other soft shading (poly_dither), never a gradient
	var glow_top := fy + 1.6
	c.poly_dither(PackedVector2Array([
		_p(x, fy, maxf(ZN, -2.0)), _p(x, fy, FEAST_Z1 + 0.2),
		_p(x, glow_top, FEAST_Z1 + 0.2), _p(x, glow_top, maxf(ZN, -2.0))]), BanquetPal.TORCH_GLOW)
	for zc in [-1.6, -0.7, 0.2, 1.1]:
		if zc - 0.1 <= ZN:
			continue
		var sp := HallCam.project(Vector3(x, 1.55, zc))
		var s: float = sp.z
		var d: Dictionary = BanquetSprites.torch_sconce(clampi(roundi(0.5 * s), 10, 48))
		var canvas: PixelCanvas = d["canvas"]
		var ox := roundi(sp.x) - canvas.w + 3
		var oy := roundi(sp.y) - canvas.h + 2
		c.blit(canvas, ox, oy)


# ------------------------------------------------------------ floor layer --

## Base tiles/carpet/dais (HallBuilder, unmodified) plus a warm rug and
## scattered rushes under the feast table.
static func paint_floor(c) -> void:
	HallBuilder.paint_floor(c)
	ZN = HallCam.near_z()
	var fy := HallCam.FLOOR_Y + 0.005
	var rug := _quad_y(c, fy, FEAST_X0 - 0.1, FEAST_X1 + 0.35, maxf(FEAST_Z0 - 0.15, ZN), FEAST_Z1 + 0.15, BanquetPal.RUG)
	c.poly_outline(rug, BanquetPal.RUG_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 26:
		var zz := rng.randf_range(maxf(FEAST_Z0 - 0.1, ZN), FEAST_Z1 + 0.1)
		var xx := rng.randf_range(FEAST_X0 - 0.05, FEAST_X1 + 0.3)
		var sp := HallCam.project(Vector3(xx, HallCam.FLOOR_Y, zz))
		if sp.z <= 0.0:
			continue
		c.px(roundi(sp.x + rng.randf_range(-2, 2)), roundi(sp.y), BanquetPal.STRAW if i % 3 != 0 else BanquetPal.STRAW_DARK)


# ---------------------------------------------------------- columns layer --

## Base arcade/columns/side banners (HallBuilder, unmodified) plus garland
## swags strung along the feast-side bays.
static func paint_columns(c) -> void:
	HallBuilder.paint_columns(c)
	ZN = HallCam.near_z()
	var spring := 1.3   # matches HallBuilder.SPRING
	var bays := [-1.45, -0.35, 0.75]
	for side in [-1.0, 1.0]:
		var x: float = side * HallCam.COLUMN_X - side * 0.05   # just inside the arcade, in the bay's shadow
		for zc in bays:
			if zc + 0.55 <= ZN:
				continue
			_garland(c, x, spring + 0.02, zc - 0.42, zc + 0.42, 0.16)


# ------------------------------------------------------------ feast layer --

## Returns the candle/torch flame spots (screen px) for the animated flames,
## same contract as HallBuilder.paint_feast.
static func paint_feast(c) -> Array:
	ZN = HallCam.near_z()
	var flames: Array = []
	_feast_table(c, flames)
	_barrels(c)
	_meagre_table(c, flames)
	return flames


static func _feast_table(c, flames: Array) -> void:
	var x0 := FEAST_X0
	var x1 := FEAST_X1
	var z0 := maxf(FEAST_Z0, ZN)
	var z1 := FEAST_Z1
	if z1 <= ZN + 0.05:
		return
	var fy := HallCam.FLOOR_Y + 0.02
	var ty := TABLE_TOP
	var xc := (x0 + x1) / 2.0
	var aisle := x0   # the edge facing the hall's centre, where the aisle side shows
	var outer := x1

	# tablecloth: long aisle-facing side with a hanging gold-trimmed crimson
	# runner (richer than the base hall's single runner line)
	var side := _quad_x(c, aisle, fy, ty, z0, z1, Pal.PARCHMENT)
	var z := z0
	while z < z1:
		c.linev(_p(aisle, ty - 0.14, z), _p(aisle, fy, z), Pal.PARCHMENT_DARK)
		z += 0.22
	_quad_x(c, aisle, ty - 0.16, ty, z0, z1, BanquetPal.WINE)
	c.linev(_p(aisle, ty - 0.16, z0), _p(aisle, ty - 0.16, z1), Pal.GOLD)
	c.linev(_p(aisle, ty - 0.03, z0), _p(aisle, ty - 0.03, z1), Pal.GOLD_DARK)
	c.poly_outline(side, Pal.INK)
	# near end (in shade, facing the doors)
	var end := _quad_z(c, z0, x0, x1, fy, ty, Pal.PARCHMENT_DARK)
	_quad_z(c, z0, xc - 0.08, xc + 0.08, ty - 0.2, ty, BanquetPal.WINE)
	c.poly_outline(end, Pal.INK)
	# top, with the runner
	var top := _quad_y(c, ty, x0, x1, z0, z1, Pal.PARCHMENT)
	_quad_y(c, ty, xc - 0.08, xc + 0.08, z0, z1, BanquetPal.WINE)
	c.linev(_p(xc - 0.08, ty, z0), _p(xc - 0.08, ty, z1), Pal.GOLD_DARK)
	c.poly_outline(top, Pal.INK)
	c.linev(_p(outer, ty, z0), _p(outer, ty, z1), Pal.INK)
	_garland(c, aisle - 0.01, ty + 0.05, z0 + 0.08, z1 - 0.08, 0.09)

	# the feast: a long, dense menu, far to near so nearer dishes overlap
	# farther ones, twice the length of the base hall's table
	var menu := ["candelabra", "jug", "bowl", "roast", "grapes", "jug", "bread", "bowl",
		"candelabra", "grapes", "jug", "crate", "bowl", "candelabra"]
	for k in menu.size():
		var zz: float = lerpf(z1 - 0.15, z0 + 0.15, float(k) / (menu.size() - 1))
		if zz < ZN + 0.2:
			continue
		var side_off := 0.06 if k % 2 == 0 else -0.06
		var base := HallCam.project(Vector3(xc + side_off, ty, zz))
		var s := base.z
		var bx := roundi(base.x)
		var by := roundi(base.y) + 1
		match menu[k]:
			"candelabra":
				var cd: Dictionary = _candelabra(roundi(0.46 * s))
				var cc: PixelCanvas = cd["canvas"]
				var ox := bx - cc.w / 2
				var oy := by - cc.h
				c.blit(cc, ox, oy)
				for f in cd["flames"]:
					flames.append(Vector2i(ox + f.x, oy + f.y))
			"jug":
				_place(c, BanquetSprites.wine_jug(roundi(0.18 * s)), bx, by)
			"bowl":
				_place(c, _fruit_bowl(roundi(0.27 * s)), bx, by)
			"roast":
				_place(c, _roast(roundi(0.34 * s)), bx, by)
			"grapes":
				_place(c, _grapes(roundi(0.16 * s)), bx, by)
			"bread":
				_place(c, _bread(roundi(0.22 * s)), bx, by)
			"crate":
				_place(c, BanquetSprites.fermenting_crate(roundi(0.3 * s)), bx, by)


static func _barrels(c) -> void:
	var wx := HallCam.WALL_X
	var fy := HallCam.FLOOR_Y
	for zc in [-1.55, -0.5, 0.55, 1.4]:
		if zc + 0.3 <= ZN:
			continue
		var x := wx - 0.28
		var base := HallCam.project(Vector3(x, fy, zc))
		if base.z <= 0.0:
			continue
		var bc := BanquetSprites.wine_barrel(roundi(0.5 * base.z))
		c.blit(bc, roundi(base.x) - bc.w / 2, roundi(base.y) - bc.h + 2)


static func _meagre_table(c, flames: Array) -> void:
	var x0 := MEAGRE_X0
	var x1 := MEAGRE_X1
	var z0 := maxf(MEAGRE_Z0, ZN)
	var z1 := MEAGRE_Z1
	if z1 <= ZN + 0.05:
		return
	var fy := HallCam.FLOOR_Y + 0.02
	var ty := TABLE_TOP
	var xc := (x0 + x1) / 2.0
	var side := _quad_x(c, x1, fy, ty, z0, z1, Pal.PARCHMENT_DARK)
	c.poly_outline(side, Pal.INK)
	var end := _quad_z(c, z0, x0, x1, fy, ty, Pal.PARCHMENT_SHADE)
	c.poly_outline(end, Pal.INK)
	var top := _quad_y(c, ty, x0, x1, z0, z1, Pal.PARCHMENT_DARK)
	c.poly_outline(top, Pal.INK)
	# a single guttering candle, one crust of bread, one empty goblet: Sir
	# Cheapdate's fare, deliberately sparse next to the feast across the hall
	var base := HallCam.project(Vector3(xc, ty, (z0 + z1) / 2.0))
	if base.z > 0.0:
		var s := base.z
		var cd: Dictionary = _candelabra(roundi(0.3 * s))
		var cc: PixelCanvas = cd["canvas"]
		var ox := roundi(base.x) - cc.w / 2
		var oy := roundi(base.y) + 1 - cc.h
		c.blit(cc, ox, oy)
		for f in cd["flames"]:
			flames.append(Vector2i(ox + f.x, oy + f.y))
		_place(c, _bread(roundi(0.16 * s)), roundi(base.x) - roundi(0.12 * s), roundi(base.y) + 1)
		_place(c, _goblet(roundi(0.1 * s)), roundi(base.x) + roundi(0.12 * s), roundi(base.y) + 1)


static func _place(c, item: PixelCanvas, bx: int, by: int) -> void:
	c.blit(item, bx - item.w / 2, by - item.h)


# --- thin wrappers over SpriteForge's props, cached under our own keys so a
# banquet-only render never has to touch sprite_forge.gd's cache.

static func _candelabra(size: int) -> Dictionary:
	return SpriteForge.candelabra(size)


static func _fruit_bowl(size: int) -> PixelCanvas:
	return SpriteForge.fruit_bowl(size)


static func _goblet(size: int) -> PixelCanvas:
	return SpriteForge.goblet(size)


static func _roast(size: int) -> PixelCanvas:
	return SpriteForge.roast(size)


static func _grapes(size: int) -> PixelCanvas:
	return SpriteForge.grapes(size)


static func _bread(size: int) -> PixelCanvas:
	return SpriteForge.bread(size)
