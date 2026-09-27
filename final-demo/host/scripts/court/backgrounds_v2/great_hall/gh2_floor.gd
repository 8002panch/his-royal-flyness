extends RefCounted

## Great Hall v2, floor layer: the wide open tiled floor of the arena (no aisle
## carpet: the middle is kept clear and calm), moon patches thrown by the
## lancets with the mullion shadows in them, candle pools, floor debris, and the
## steps up to the door with a short crimson runner.

const K := preload("gh2_pal.gd")
const P := preload("gh2_paint.gd")
const S := preload("gh2_sprites.gd")
const ST := preload("gh2_state.gd")
const FEAST := preload("gh2_feast.gd")
const WALLS := preload("gh2_walls.gd")

const TILE_X := 0.49
const TILE_Z := 0.5


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func paint(c) -> void:
	var zn := HallCam.near_z()
	HallBuilder.ZN = zn
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var t := P.now()

	var t0 := Time.get_ticks_usec()
	# --- tiles: two close browns, worn and mottled, never high contrast
	var i := 0
	var x := -wx
	while x < wx - 0.001:
		var z := HallBuilder._grid_start(TILE_Z)
		while z < bz - 0.001:
			var j := roundi((z - HallBuilder.GRID_Z) / TILE_Z)
			if z + TILE_Z > zn:
				var hv := P.hash2(i, j, 1)
				var light := (i + j) % 2 == 0
				var col := K.FB if light else K.FA
				if light and hv < 0.16:
					col = K.FB2
				elif not light and hv > 0.88:
					col = K.FA2
				var x1 := minf(x + TILE_X, wx)
				var z0 := maxf(z, zn)
				var z1 := minf(z + TILE_Z, bz)
				HallBuilder._quad_y(c, fy, x, x1, z0, z1, col)
				_tile_detail(c, i, j, x, x1, z, fy, zn, light)
			z += TILE_Z
		x += TILE_X
		i += 1

	t0 = P.lap("f_tiles", t0)
	# --- moonlight thrown through the lancets (dimmed as the hand blocks the moon)
	var moon := 1.0 - clampf(ST.loom_p * 1.4, 0.0, 1.0)
	if moon > 0.05:
		for side in [-1.0, 1.0]:
			for zc in WALLS.LANCETS:
				_moon_patch(c, side, zc, fy, zn, moon)
	t0 = P.lap("f_moon", t0)

	# --- grout, with a lit lip on the near edge of each tile row
	var gz := HallBuilder._grid_start(TILE_Z) + TILE_Z
	while gz <= bz:
		c.linev(_p(-wx, fy, gz), _p(wx, fy, gz), K.GROUT)
		gz += TILE_Z
	var gx := -wx
	while gx <= wx + 0.001:
		c.linev(_p(gx, fy, zn), _p(gx, fy, bz), K.GROUT)
		gx += TILE_X

	t0 = P.lap("f_grout", t0)
	# --- shade: dark along the walls and the back wall, deeper towards the corners
	for side in [-1.0, 1.0]:
		var a: float = side * wx
		var b: float = side * (wx - 0.5)
		var b2: float = side * (wx - 0.2)
		P.dither(c, PackedVector2Array([_p(a, fy, zn), _p(a, fy, bz), _p(b, fy, bz), _p(b, fy, zn)]), K.DEEP, 1)
		P.dither(c, PackedVector2Array([_p(a, fy, zn), _p(a, fy, bz), _p(b2, fy, bz), _p(b2, fy, zn)]), K.DEEP, 2)
	P.dither(c, PackedVector2Array([_p(-wx, fy, bz - 0.7), _p(wx, fy, bz - 0.7), _p(wx, fy, bz), _p(-wx, fy, bz)]), K.DEEP, 1)
	P.dither(c, PackedVector2Array([_p(-wx, fy, bz - 0.25), _p(wx, fy, bz - 0.25), _p(wx, fy, bz), _p(-wx, fy, bz)]), K.DEEP, 2)

	# --- warm pools round the floor candelabra, breathing with the flames
	for k in FEAST.STANDS.size():
		var sp: Vector2 = FEAST.STANDS[k]
		if sp.y < zn + 0.3:
			continue
		var pr := HallCam.project(Vector3(sp.x, fy, sp.y))
		var fl := FEAST.flame_level(t, k)
		var r := (0.5 + 0.09 * fl) * pr.z
		P.dither_ellipse(c, pr.x, pr.y, r, r * 0.3, K.GLOW_A, 2)
		P.dither_ellipse(c, pr.x, pr.y, r * 0.55, r * 0.17, K.GLOW_B, 1)

	t0 = P.lap("f_shade", t0)

	# --- debris on the floor at the edges
	_debris(c, zn, fy)
	t0 = P.lap("f_debris", t0)

	# --- the dais and the runner
	_dais(c)
	t0 = P.lap("f_dais", t0)


static func _tile_detail(c, i: int, j: int, x0: float, x1: float, z: float, fy: float, zn: float, light: bool) -> void:
	var hv := P.hash2(i, j, 2)
	# a scuff or two
	if hv > 0.4:
		var u := x0 + (x1 - x0) * P.hash2(i, j, 3)
		var v := z + TILE_Z * P.hash2(i, j, 4)
		if v > zn + 0.05:
			var q := _p(u, fy, v)
			c.px(roundi(q.x), roundi(q.y), K.SCUFF if light else K.FB)
			if hv > 0.7:
				c.px(roundi(q.x) + 1, roundi(q.y), K.SCUFF if light else K.FB)
	# a hairline crack
	if hv < 0.12:
		var p0 := Vector2(x0 + (x1 - x0) * 0.15, z + TILE_Z * P.hash2(i, j, 5))
		var pts: Array = [p0]
		for s in 3:
			var prev: Vector2 = pts[s]
			pts.append(Vector2(prev.x + (x1 - x0) * 0.25, prev.y + (P.hash2(i, j, 6 + s) - 0.5) * 0.22))
		for s in 3:
			if pts[s].y > zn and pts[s + 1].y > zn:
				c.linev(_p(pts[s].x, fy, pts[s].y), _p(pts[s + 1].x, fy, pts[s + 1].y), K.CRACK)


static func _moon_patch(c, side: float, zc: float, fy: float, zn: float, moon: float) -> void:
	var wx := HallCam.WALL_X
	var sh := 0.55
	var xa: float = side * (wx - 0.12)
	var xb: float = side * (wx - 2.0)
	if zc + sh - 0.3 < zn:
		return
	var quad := PackedVector2Array([_p(xa, fy, zc - 0.26), _p(xa, fy, zc + 0.26), _p(xb, fy, zc + 0.32 + sh), _p(xb, fy, zc - 0.32 + sh)])
	P.dither(c, quad, K.MOON_B, 1)
	var q2 := PackedVector2Array([_p(xa, fy, zc - 0.2), _p(xa, fy, zc + 0.2), _p(side * (wx - 1.55), fy, zc + 0.24 + sh * 0.8), _p(side * (wx - 1.55), fy, zc - 0.24 + sh * 0.8)])
	if moon > 0.4:
		P.dither(c, q2, K.MOON_A, 2)
	# the leaded mullions cast their shadows across the patch
	for u in [-0.073, 0.073]:
		c.linev(_p(xa, fy, zc + u), _p(xb, fy, zc + u * 1.25 + sh), K.GROUT)
	for f in [0.33, 0.66]:
		var xf: float = lerpf(xa, xb, f)
		var zf: float = sh * f
		c.linev(_p(xf, fy, zc - 0.3 + zf), _p(xf, fy, zc + 0.3 + zf), K.GROUT)


static func _debris(c, zn: float, fy: float) -> void:
	# name, x, z, size (hall units), flip
	var items := [
		["goblet", -1.62, -1.5, 0.16, false],
		["plate", -1.35, -0.3, 0.3, false],
		["goblet", 1.5, -1.2, 0.16, true],
		["plate", 1.62, 0.05, 0.28, false],
		["goblet", -1.5, 1.05, 0.16, true],
		["plate", 1.42, 1.15, 0.26, false],
	]
	for it in items:
		if it[2] < zn + 0.3:
			continue
		var pr := HallCam.project(Vector3(it[1], fy, it[2]))
		var sz: float = it[3]
		var px := roundi(sz * pr.z)
		if it[0] == "goblet":
			var cv: PixelCanvas = S.goblet_fallen(px)
			c.blit(cv, roundi(pr.x) - cv.w / 2, roundi(pr.y) - cv.h + 1)
		else:
			var cv: PixelCanvas = S.plate(px)
			c.blit(cv, roundi(pr.x) - cv.w / 2, roundi(pr.y) - cv.h + 1)


# ------------------------------------------------------------------- dais --

static func _dais(c) -> void:
	var fy := HallCam.FLOOR_Y
	var bz := HallCam.BACK_Z
	var dx := HallBuilder.DAIS_X
	var f := HallBuilder.DAIS_FRONT
	var st := HallBuilder.DAIS_STEP
	var y1 := HallBuilder.DAIS_Y1
	var y2 := HallBuilder.DAIS_Y2
	# risers in shade, treads in stone
	HallBuilder._quad_y(c, y2, -dx, dx, st, bz, K.STONE)
	HallBuilder._quad_z(c, st, -dx, dx, y1, y2, K.MID)
	HallBuilder._quad_y(c, y1, -dx, dx, f, st, K.STONE)
	HallBuilder._quad_z(c, f, -dx, dx, fy, y1, K.MID)
	# royal-blue inlay along the two side edges of each tread, with gold nosing
	for side in [-1.0, 1.0]:
		var xa: float = side * dx
		var xb: float = side * (dx - 0.22)
		HallBuilder._quad_y(c, y2, xa, xb, st, bz, K.RY)
		HallBuilder._quad_y(c, y1, xa, xb, f, st, K.RY)
		c.linev(_p(xb, y2, st), _p(xb, y2, bz), K.BR)
		c.linev(_p(xb, y1, f), _p(xb, y1, st), K.BR)
	c.linev(_p(-dx, y2, st), _p(dx, y2, st), K.BR_L)
	c.linev(_p(-dx, y1, f), _p(dx, y1, f), K.BR_L)
	c.linev(_p(-dx, y1, st), _p(dx, y1, st), K.INK)
	c.linev(_p(-dx, fy, f), _p(dx, fy, f), K.INK)
	for side in [-1.0, 1.0]:
		c.linev(_p(side * dx, fy, f), _p(side * dx, y1, f), K.INK)
		c.linev(_p(side * dx, y1, st), _p(side * dx, y2, st), K.INK)
		c.linev(_p(side * dx, y2, st), _p(side * dx, y2, bz), K.INK)
		c.linev(_p(side * dx, y1, f), _p(side * dx, y1, st), K.INK)
	# shadow pooled under the first riser
	P.dither(c, PackedVector2Array([_p(-dx, fy, f - 0.22), _p(dx, fy, f - 0.22), _p(dx, fy, f), _p(-dx, fy, f)]), K.DEEP, 1)
	# the short runner: from a little way out on the floor, up both steps to the door
	var h := HallBuilder.CARPET_HALF - 0.05
	var zn := HallBuilder.ZN
	HallBuilder._quad_y(c, fy, -h, h, maxf(f - 0.4, zn), f, K.CR)
	HallBuilder._quad_z(c, f, -h, h, fy, y1, K.CR_D)
	HallBuilder._quad_y(c, y1, -h, h, f, st, K.CR)
	HallBuilder._quad_z(c, st, -h, h, y1, y2, K.CR_D)
	HallBuilder._quad_y(c, y2, -h, h, st, bz, K.CR)
	for side in [-1.0, 1.0]:
		var xs: float = side * h
		var xi: float = side * (h - 0.06)
		c.linev(_p(xi, fy, maxf(f - 0.4, zn)), _p(xi, fy, f), K.BR)
		c.linev(_p(xi, y1, f), _p(xi, y1, st), K.BR)
		c.linev(_p(xi, y2, st), _p(xi, y2, bz), K.BR)
		c.linev(_p(xs, fy, maxf(f - 0.4, zn)), _p(xs, fy, f), K.INK)
		c.linev(_p(xs, y1, f), _p(xs, y1, st), K.INK)
		c.linev(_p(xs, y2, st), _p(xs, y2, bz), K.INK)
	# a worn patch on the runner
	P.dither(c, PackedVector2Array([_p(-0.2, y2, 1.0), _p(0.28, y2, 1.0), _p(0.24, y2, 1.4), _p(-0.14, y2, 1.4)]), K.CR_D, 1)
