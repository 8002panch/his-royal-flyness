class_name GardenBuilder
extends RefCounted

## Paints the Garden Audience background (Trial I, arena theme "garden": "Her
## Highness takes the evening air among the grapes.") through HallCam's
## current camera, the same way HallBuilder paints the Banquet Hall. `c` is a
## painter: a CanvasPainter (live, every frame, so the chase camera can move)
## or a PixelCanvas (a one-off image) -- both share the same drawing API, so
## this never needs to know which one it has.
##
## Layer names match HallLayer's enum 1:1 so a GardenLayer node can drop in
## for a HallLayer node with no other changes:
##   paint_far(c):     evening sky, moon and stars, clipped hedge walls, the
##                      back hedge with its arbor gateway and a flower wreath
##   paint_floor(c):    lawn, gravel path, a low fountain wall where the dais was
##   paint_columns(c):  wooden trellis posts wound with grapevine, lattice bays,
##                      hanging grape garlands (returns nothing, like the hall)
##   paint_props(c):    garden lanterns (posts + housings) and grape crates near
##                      the fountain; returns the lantern-glow spots so the
##                      layer node can flicker them like the feast candles
##
## Reuses the hall's own shared ground truth (HallCam's projection and world
## bounds, so actors/camera code needs no changes) and its own palette
## (Pal.WOOD, Pal.FLAME, Pal.GRAPE, Pal.STONE_* already fit a garden and
## avoid duplicating them); new garden-only colours live in garden_pal.gd.

const GRID_Z := -3.5
static var ZN := -3.5
const HEDGE_TOP_Y := 1.55       # lower than the hall's TOP_Y=3.2: open sky above
const GATE_HALF := 0.55         # half-width of the arbor gateway in the back hedge
const TRELLIS_Z := [-2.0, -0.9, 0.2, 1.3]   # same spacing as the hall's columns
const FOUNTAIN_X := 0.95
const FOUNTAIN_FRONT := 0.55
const FOUNTAIN_STEP := 0.7
const FOUNTAIN_Y1 := -1.2
const FOUNTAIN_Y2 := -1.1
const PATH_HALF := 0.42


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


## First grid line at or before ZN, so patterns are fixed to the garden.
static func _grid_start(step: float, offset: float = 0.0) -> float:
	return GRID_Z + offset + floorf((ZN - GRID_Z - offset) / step) * step


static func _quad_x(c, x: float, y0: float, y1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x, y0, z0), _p(x, y0, z1), _p(x, y1, z1), _p(x, y1, z0)])
	c.poly(q, col)
	return q


static func _quad_y(c, y: float, x0: float, x1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x0, y, z0), _p(x1, y, z0), _p(x1, y, z1), _p(x0, y, z1)])
	c.poly(q, col)
	return q


static func _quad_z(c, z: float, x0: float, x1: float, y0: float, y1: float, col: Color) -> PackedVector2Array:
	var q := _pts_z(z, x0, x1, y0, y1)
	c.poly(q, col)
	return q


## Same corners as _quad_z but never draws -- for callers that only want the
## outline or want to dither over a shape drawn some other way.
static func _pts_z(z: float, x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([_p(x0, y0, z), _p(x1, y0, z), _p(x1, y1, z), _p(x0, y1, z)])


# -------------------------------------------------------------- far layer --

static func paint_far(c) -> void:
	ZN = HallCam.near_z()
	_sky(c)
	_hedge_walls(c)
	_back_hedge(c)


static func _sky(c) -> void:
	# Flat dusk bands, top to horizon (no gradients: a dithered strip between
	# each pair of bands stands in for the blend, same trick as the floor's
	# dithered wall shade).
	var bands: Array = [
		[0, 66, GardenPal.SKY_DEEP],
		[66, 124, GardenPal.SKY_MID],
		[124, 168, GardenPal.SKY_DUSK],
		[168, 206, GardenPal.SKY_GLOW],
		[206, 360, GardenPal.SKY_GLOW_LOW],
	]
	for b in bands:
		c.rect(0, b[0], HallCam.W, b[1] - b[0], b[2])
	for i in range(bands.size() - 1):
		var y: int = bands[i][1]
		var quad := PackedVector2Array([Vector2(0, y - 5), Vector2(HallCam.W, y - 5), Vector2(HallCam.W, y + 5), Vector2(0, y + 5)])
		c.poly_dither(quad, bands[i + 1][2])

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		var y := rng.randi_range(4, 150)
		c.px(rng.randi_range(0, HallCam.W - 1), y, GardenPal.STAR if i % 4 != 0 else GardenPal.MOON_SHADE)

	_moon(c, 486.0, 58.0, 15.0)


static func _moon(c, mx: float, my: float, r: float) -> void:
	c.ellipse(mx, my, r, r, GardenPal.MOON)
	c.ellipse(mx + r * 0.42, my - r * 0.1, r * 0.82, r * 0.82, GardenPal.SKY_MID)
	for spot in [Vector2(-0.28, -0.2), Vector2(0.05, 0.3), Vector2(-0.1, 0.15)]:
		c.ellipse(mx + spot.x * r, my + spot.y * r, r * 0.16, r * 0.16, GardenPal.MOON_SHADE)
	c.poly_outline(PixelCanvas.ellipse_points(mx, my, r, r, 0.0, 20), Pal.INK)


static func _hedge_walls(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	for side in [-1.0, 1.0]:
		var x: float = side * HallCam.WALL_X
		var wall := _quad_x(c, x, fy, HEDGE_TOP_Y, ZN, bz, GardenPal.HEDGE)
		# leaf texture: alternating dithered bands, darker low, lighter high
		var row := 0
		var y := fy
		while y < HEDGE_TOP_Y:
			var y1: float = minf(y + 0.26, HEDGE_TOP_Y)
			var shade: Color = GardenPal.HEDGE_DARK if row % 2 == 0 else GardenPal.HEDGE_LIGHT
			c.poly_dither(PackedVector2Array([_p(x, y, ZN), _p(x, y, bz), _p(x, y1, bz), _p(x, y1, ZN)]), shade)
			y = y1
			row += 1
		c.poly_outline(wall, Pal.INK)
		# leaf flecks scattered over the bands, so they read as foliage and
		# not a flat striped tarp
		var speck_rng := RandomNumberGenerator.new()
		speck_rng.seed = 41 if side < 0 else 43
		for i in 140:
			var sz: float = speck_rng.randf_range(ZN, bz)
			var sy: float = speck_rng.randf_range(fy + 0.05, HEDGE_TOP_Y - 0.05)
			var sp := _p(x, sy, sz)
			c.px(roundi(sp.x), roundi(sp.y), GardenPal.HEDGE_HI if i % 3 == 0 else GardenPal.HEDGE_DARK)
		# a clipped, uneven top edge instead of a dead-flat hedge line
		var rng := RandomNumberGenerator.new()
		rng.seed = 19 if side < 0 else 23
		var z := _grid_start(0.22)
		while z < bz:
			if z >= ZN:
				var bump: float = rng.randf_range(0.0, 0.1)
				c.linev(_p(x, HEDGE_TOP_Y, z), _p(x, HEDGE_TOP_Y + bump, z + 0.1), GardenPal.HEDGE_HI)
			z += 0.22
		# lattice trellis medallions with hanging grape clusters, one per bay
		for zc in TRELLIS_Z:
			if zc - 0.22 > ZN:
				_lattice_medallion(c, x, zc)


static func _lattice_medallion(c, x: float, zc: float) -> void:
	var half := 0.2
	var top := 0.55
	var bot := 0.05
	var corners := PackedVector2Array([Vector2(zc - half, top), Vector2(zc + half, top), Vector2(zc + half, bot), Vector2(zc - half, bot)])
	c.poly_outline(_on_x(corners, x), Pal.WOOD)
	# crossed diagonals, a garden lattice
	c.linev(_p(x, top, zc - half), _p(x, bot, zc + half), Pal.WOOD)
	c.linev(_p(x, top, zc + half), _p(x, bot, zc - half), Pal.WOOD)
	c.linev(_p(x, (top + bot) / 2.0, zc - half), _p(x, (top + bot) / 2.0, zc + half), Pal.WOOD_LIGHT)
	c.linev(_p(x, top, zc), _p(x, bot, zc), Pal.WOOD_LIGHT)
	# a few grape clusters and leaves dangling from the lattice
	for spot in [Vector2(-0.08, 0.18), Vector2(0.1, 0.1), Vector2(0.0, -0.02)]:
		var gp := _p(x, bot + spot.y, zc + spot.x)
		c.ellipse(gp.x, gp.y, 2.2, 2.6, GardenPal.GRAPE_LIGHT if spot.y > 0.1 else Pal.GRAPE)
	var lp := _p(x, top - 0.05, zc)
	c.ellipse(lp.x - 3, lp.y, 3.0, 1.6, GardenPal.VINE_LEAF)
	c.ellipse(lp.x + 3, lp.y + 1, 3.0, 1.6, GardenPal.VINE_LEAF_DARK)


static func _on_x(uv: PackedVector2Array, x: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(_p(x, p.y, p.x))
	return out


static func _back_hedge(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var wx := HallCam.WALL_X
	# a further hedge glimpsed through the gateway, hinting at more garden beyond
	var far_q := _quad_z(c, bz + 0.6, -GATE_HALF * 1.3, GATE_HALF * 1.3, fy, HEDGE_TOP_Y * 0.6, GardenPal.HEDGE_DEEP)
	c.poly_outline(far_q, Pal.INK)

	for spec in [[-wx, -GATE_HALF], [GATE_HALF, wx]]:
		var x0: float = spec[0]
		var x1: float = spec[1]
		var block := _quad_z(c, bz, x0, x1, fy, HEDGE_TOP_Y, GardenPal.HEDGE)
		var row := 0
		var y := fy
		while y < HEDGE_TOP_Y:
			var y1: float = minf(y + 0.26, HEDGE_TOP_Y)
			c.poly_dither(_pts_z(bz, x0, x1, y, y1), GardenPal.HEDGE_DARK if row % 2 == 0 else GardenPal.HEDGE_LIGHT)
			y = y1
			row += 1
		c.poly_outline(block, Pal.INK)

	_arbor(c, bz)


static func _arbor(c, bz: float) -> void:
	var fy := HallCam.FLOOR_Y
	var spring := HEDGE_TOP_Y * 0.62
	var az := bz - 0.06
	var pw := 0.05
	# posts, filled and outlined so they stand out against the dark gateway
	for side in [-1.0, 1.0]:
		var x: float = side * GATE_HALF
		var post := PackedVector2Array([_p(x - pw, fy, az), _p(x + pw, fy, az), _p(x + pw, spring, az), _p(x - pw, spring, az)])
		c.poly(post, Pal.WOOD)
		c.linev(_p(x - pw * 0.3, fy, az), _p(x - pw * 0.3, spring, az), Pal.WOOD_LIGHT)
		c.poly_outline(post, Pal.INK)
	# rounded arbor top (a garden arch, distinct from the hall's gothic one)
	var steps := 14
	var ring_out := PackedVector2Array()
	var ring_in := PackedVector2Array()
	for i in range(steps + 1):
		var a: float = PI * float(i) / steps
		var ca := cos(a)
		var sa := sin(a)
		ring_out.append(Vector2(ca * (GATE_HALF + pw), spring + sa * (GATE_HALF + pw) * 1.15))
		ring_in.append(Vector2(ca * (GATE_HALF - pw), spring + sa * (GATE_HALF - pw) * 1.15))
	var band := ring_out.duplicate()
	var ring_in_rev := ring_in.duplicate()
	ring_in_rev.reverse()
	band.append_array(ring_in_rev)
	c.poly(_on_z(band, az), Pal.WOOD)
	c.poly_outline(_on_z(ring_out, az), Pal.INK)
	c.poly_outline(_on_z(ring_in, az), Pal.INK)
	# vine wound along the arch, with clusters hanging off the apex
	for i in range(ring_out.size()):
		var u: Vector2 = ring_out[i].lerp(ring_in[i], 0.5)
		var vp := _p(u.x, u.y, az)
		c.ellipse(vp.x, vp.y, 3.4, 2.6, GardenPal.VINE_LEAF if i % 2 == 0 else GardenPal.VINE_LEAF_DARK)
		if i % 3 == 0:
			c.ellipse(vp.x, vp.y + 2.5, 2.2, 2.6, Pal.GRAPE)
	var apex := _p(0.0, spring + GATE_HALF * 1.15, az)
	for spot in [Vector2(-4, 3), Vector2(3, 4), Vector2(0, 8), Vector2(-2, 10), Vector2(2, 10)]:
		c.ellipse(apex.x + spot.x, apex.y + spot.y, 2.4, 2.8, Pal.GRAPE)
	for spot in [Vector2(-1, 5), Vector2(1, 12)]:
		c.ellipse(apex.x + spot.x, apex.y + spot.y, 2.6, 2.0, GardenPal.VINE_LEAF)
	# a flower wreath medallion at the apex, standing in for the hall's rose window
	var rc := _p(0.0, spring + GATE_HALF * 0.55, az)
	var rr := 0.24 * HallCam.scale_at(az)
	c.ellipse(rc.x, rc.y, rr, rr, GardenPal.HEDGE)
	for i in 8:
		var a: float = TAU * i / 8.0
		var pc := rc + Vector2(cos(a), sin(a)) * rr * 0.7
		c.ellipse(pc.x, pc.y, rr * 0.32, rr * 0.32, Pal.CRIMSON if i % 2 == 0 else Pal.GOLD)
	c.ellipse(rc.x, rc.y, rr * 0.3, rr * 0.3, Pal.GOLD_DARK)
	c.poly_outline(PixelCanvas.ellipse_points(rc.x, rc.y, rr, rr, 0.0, 16), Pal.INK)


static func _on_z(uv: PackedVector2Array, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(_p(p.x, p.y, z))
	return out


# ------------------------------------------------------------ floor layer --

static func paint_floor(c) -> void:
	ZN = HallCam.near_z()
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var tile_x := 0.49
	var tile_z := 0.5
	var i := 0
	var x := -wx
	while x < wx - 0.001:
		var z := _grid_start(tile_z)
		while z < bz - 0.001:
			var j := roundi((z - GRID_Z) / tile_z)
			var col: Color = GardenPal.GRASS_B if (i + j) % 2 == 0 else GardenPal.GRASS_A
			if z + tile_z > ZN:
				_quad_y(c, fy, x, minf(x + tile_x, wx), maxf(z, ZN), minf(z + tile_z, bz), col)
			z += tile_z
		x += tile_x
		i += 1
	# deep-grass shade along both hedges and the back hedge
	for side in [-1.0, 1.0]:
		var a: float = side * wx
		var b: float = side * (wx - 0.3)
		c.poly_dither(PackedVector2Array([_p(a, fy, ZN), _p(a, fy, bz), _p(b, fy, bz), _p(b, fy, ZN)]), GardenPal.GRASS_DEEP)
	c.poly_dither(PackedVector2Array([_p(-wx, fy, bz - 0.25), _p(wx, fy, bz - 0.25), _p(wx, fy, bz), _p(-wx, fy, bz)]), GardenPal.GRASS_DEEP)

	_fountain(c)

	# the gravel path from the doors to the fountain, low box-hedge border
	var h := PATH_HALF
	_quad_y(c, fy, -h, h, ZN, FOUNTAIN_FRONT, GardenPal.PATH)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var dz := _grid_start(0.18)
	while dz < FOUNTAIN_FRONT:
		if dz > ZN:
			var gx: float = rng.randf_range(-h + 0.05, h - 0.05)
			var gp := _p(gx, fy, dz)
			c.px(roundi(gp.x), roundi(gp.y), GardenPal.PATH_DARK if rng.randi() % 2 == 0 else GardenPal.PATH_LIGHT)
		dz += 0.18
	for side in [-1.0, 1.0]:
		c.linev(_p(side * h, fy, ZN), _p(side * h, fy, FOUNTAIN_FRONT), GardenPal.HEDGE_DARK)
		c.linev(_p(side * (h + 0.06), fy, ZN), _p(side * (h + 0.06), fy, FOUNTAIN_FRONT), GardenPal.HEDGE)


## A low fountain where the hall's throne dais was: a ring of low stone wall,
## two shallow steps, and a dithered water basin with a small central spout.
static func _fountain(c) -> void:
	var fy := HallCam.FLOOR_Y
	var bz := HallCam.BACK_Z
	var x := FOUNTAIN_X
	_quad_y(c, FOUNTAIN_Y2, -x, x, FOUNTAIN_STEP, bz, Pal.STONE_LIGHT)
	_quad_z(c, FOUNTAIN_STEP, -x, x, FOUNTAIN_Y1, FOUNTAIN_Y2, Pal.STONE_DARK)
	_quad_y(c, FOUNTAIN_Y1, -x, x, FOUNTAIN_FRONT, FOUNTAIN_STEP, Pal.STONE_LIGHT)
	_quad_z(c, FOUNTAIN_FRONT, -x, x, fy, FOUNTAIN_Y1, Pal.STONE_DARK)
	c.linev(_p(-x, FOUNTAIN_Y2, FOUNTAIN_STEP), _p(x, FOUNTAIN_Y2, FOUNTAIN_STEP), Pal.STONE_HI)
	c.linev(_p(-x, FOUNTAIN_Y1, FOUNTAIN_FRONT), _p(x, FOUNTAIN_Y1, FOUNTAIN_FRONT), Pal.STONE_HI)
	c.linev(_p(-x, fy, FOUNTAIN_FRONT), _p(x, fy, FOUNTAIN_FRONT), Pal.INK)
	for side in [-1.0, 1.0]:
		c.linev(_p(side * x, fy, FOUNTAIN_FRONT), _p(side * x, FOUNTAIN_Y1, FOUNTAIN_FRONT), Pal.INK)
		c.linev(_p(side * x, FOUNTAIN_Y1, FOUNTAIN_STEP), _p(side * x, FOUNTAIN_Y2, FOUNTAIN_STEP), Pal.INK)

	# low wall ring around the basin, on the top step
	var basin_x := x - 0.2
	var wall_top := FOUNTAIN_Y2 + 0.22
	_quad_y(c, wall_top, -basin_x, basin_x, FOUNTAIN_STEP + 0.05, bz - 0.15, Pal.STONE_HI)
	_quad_z(c, FOUNTAIN_STEP + 0.05, -basin_x, basin_x, FOUNTAIN_Y2, wall_top, Pal.STONE)
	c.linev(_p(-basin_x, wall_top, FOUNTAIN_STEP + 0.05), _p(basin_x, wall_top, FOUNTAIN_STEP + 0.05), Pal.STONE_HI)
	c.poly_outline(_pts_z(FOUNTAIN_STEP + 0.05, -basin_x, basin_x, FOUNTAIN_Y2, wall_top), Pal.INK)

	# the water, dithered for ripples, inside the wall
	var basin := PackedVector2Array([_p(-basin_x + 0.1, wall_top, FOUNTAIN_STEP + 0.15), _p(basin_x - 0.1, wall_top, FOUNTAIN_STEP + 0.15),
		_p(basin_x - 0.1, wall_top, bz - 0.25), _p(-basin_x + 0.1, wall_top, bz - 0.25)])
	c.poly(basin, GardenPal.WATER_DEEP)
	c.poly_dither(basin, GardenPal.WATER)
	var foam := PackedVector2Array([basin[0] + Vector2(2, -1), basin[1] + Vector2(-2, -1), basin[2] + Vector2(-2, 1), basin[3] + Vector2(2, 1)])
	c.poly_dither(foam, GardenPal.WATER_FOAM)

	# a small central spout
	var sc := _p(0.0, wall_top + 0.05, (FOUNTAIN_STEP + bz) / 2.0)
	c.rect(roundi(sc.x) - 2, roundi(sc.y) - 6, 4, 6, Pal.STONE_HI)
	c.frame(roundi(sc.x) - 2, roundi(sc.y) - 6, 4, 6, Pal.INK)
	for dy in [-2, -4, -6]:
		c.px(roundi(sc.x) - 1, roundi(sc.y) + dy, GardenPal.WATER_FOAM)
		c.px(roundi(sc.x) + 1, roundi(sc.y) + dy - 1, GardenPal.WATER_LIGHT)


# ---------------------------------------------------------- trellis layer --
# (called paint_columns to match HallLayer's enum, so a GardenLayer node can
# take a HallLayer node's place with layer = "columns" unchanged)

static func paint_columns(c) -> void:
	ZN = HallCam.near_z()
	var bz := HallCam.BACK_Z
	var top := HEDGE_TOP_Y + 0.35
	for side in [-1.0, 1.0]:
		var x: float = side * HallCam.COLUMN_X
		var bays: Array = [[ZN, TRELLIS_Z[0]]]
		for k in range(TRELLIS_Z.size() - 1):
			bays.append([TRELLIS_Z[k], TRELLIS_Z[k + 1]])
		bays.append([TRELLIS_Z[TRELLIS_Z.size() - 1], bz])
		for k in bays.size():
			var z0: float = bays[k][0]
			var z1: float = bays[k][1]
			if z1 <= ZN:
				continue
			z0 = maxf(z0, ZN)
			# an open wood lattice, diamond-crossed like the hedge medallions --
			# the hedge stays visible through the gaps instead of a solid panel
			if z1 - z0 > 0.05:
				_lattice_bay(c, x, z0, z1, top)
			# a garland of leaves and grapes sagging across the bay
			if k < bays.size() - 1 and z1 - z0 > 0.05:
				_garland(c, x, z0, z1)

		for k in range(TRELLIS_Z.size() - 1, -1, -1):
			if TRELLIS_Z[k] > ZN + 0.15:
				_trellis_post(c, x, TRELLIS_Z[k])


## A sparse diamond lattice across one bay (frame + a few crossed diagonals),
## not a filled panel, so the hedge behind still reads through the gaps.
static func _lattice_bay(c, x: float, z0: float, z1: float, top: float) -> void:
	var fy := HallCam.FLOOR_Y
	c.linev(_p(x, fy, z0), _p(x, top, z0), Pal.WOOD)
	c.linev(_p(x, fy, z1), _p(x, top, z1), Pal.WOOD)
	c.linev(_p(x, top, z0), _p(x, top, z1), Pal.WOOD)
	var cells := maxi(1, roundi((z1 - z0) / 0.65))
	var step := (z1 - z0) / cells
	var yc := (fy + top) / 2.0
	for i in cells:
		var a: float = z0 + step * i
		var b: float = a + step
		c.linev(_p(x, fy, a), _p(x, top, b), Pal.WOOD_LIGHT)
		c.linev(_p(x, top, a), _p(x, fy, b), Pal.WOOD_LIGHT)


static func _garland(c, x: float, z0: float, z1: float) -> void:
	var zc := (z0 + z1) / 2.0
	var sag := 0.14
	var pts := PackedVector2Array()
	var n := 8
	for i in range(n + 1):
		var t := float(i) / n
		var zz: float = lerpf(z0 + 0.05, z1 - 0.05, t)
		var yy: float = HEDGE_TOP_Y - sag * sin(PI * t)
		pts.append(_p(x, yy, zz))
	for i in range(pts.size() - 1):
		c.linev(pts[i], pts[i + 1], GardenPal.VINE_LEAF_DARK)
	for i in range(1, pts.size() - 1, 2):
		var p := pts[i]
		c.ellipse(p.x, p.y + 2, 2.0, 2.4, Pal.GRAPE)
		c.ellipse(p.x - 2, p.y - 1, 2.2, 1.4, GardenPal.VINE_LEAF)


static func _trellis_post(c, x: float, z: float) -> void:
	var fy := HallCam.FLOOR_Y
	var top := HEDGE_TOP_Y + 0.35
	var s := HallCam.scale_at(z)
	var cx := _p(x, 0.0, z).x
	var y0 := roundi(_p(x, fy, z).y)
	var y1 := roundi(_p(x, top, z).y)
	var w := maxi(3, roundi(0.1 * s))
	c.rect(roundi(cx - w / 2.0), y1, w, y0 - y1, Pal.WOOD)
	c.vline(roundi(cx - w / 2.0), y1, y0, Pal.INK)
	c.vline(roundi(cx + w / 2.0) - 1, y1, y0, Pal.INK)
	c.vline(roundi(cx - w / 2.0) + 1, y1, y0, Pal.WOOD_LIGHT)
	# lattice cross-bracing up the post
	var seg := maxi(4, roundi((y0 - y1) / 3.0))
	var yy := y1
	while yy < y0 - 1:
		var yb: int = mini(y0, yy + seg)
		c.line(roundi(cx - w / 2.0), yy, roundi(cx + w / 2.0) - 1, yb, Pal.INK)
		c.line(roundi(cx + w / 2.0) - 1, yy, roundi(cx - w / 2.0), yb, Pal.INK)
		yy += seg
	# grapevine spiralling the post
	var vy := y0 - 2
	var side := 1
	while vy > y1 + 2:
		c.ellipse(cx + side * (w / 2.0 + 1.5), vy, 1.8, 2.0, GardenPal.VINE_LEAF if side > 0 else GardenPal.VINE_LEAF_DARK)
		if (vy / 6) % 3 == 0:
			c.ellipse(cx + side * (w / 2.0 + 1.0), vy + 2, 1.6, 1.8, Pal.GRAPE)
		vy -= 6
		side = -side
	# grounding shadow
	c.ellipse_dither(cx, y0, w * 1.6, maxf(1.5, w * 0.3), GardenPal.GRASS_DEEP)


# ------------------------------------------------------------ props layer --
# (called paint_props but exposed to GardenLayer as "feast", again so it can
## drop straight into a HallLayer node's spot with layer = "feast" unchanged)

## Returns lantern-glow spots (screen px) for the calling layer to flicker
## with SpriteForge.flame(), the same contract as HallBuilder.paint_feast.
static func paint_feast(c) -> Array:
	ZN = HallCam.near_z()
	var glows: Array = []
	for spec in [[-1.7, -1.55], [1.7, -1.1], [-1.6, 0.55], [1.6, 1.15]]:
		var lx: float = spec[0]
		var lz: float = spec[1]
		if lz <= ZN + 0.1 or lz >= HallCam.BACK_Z:
			continue
		glows.append(_lantern(c, lx, lz))
	_grape_crates(c)
	return glows


static func _lantern(c, x: float, z: float) -> Vector2i:
	var fy := HallCam.FLOOR_Y
	var s := HallCam.scale_at(z)
	var post_h := 0.55
	var base := _p(x, fy, z)
	var top := _p(x, fy + post_h, z)
	c.vline(roundi(base.x), roundi(top.y), roundi(base.y), Pal.WOOD)
	c.vline(roundi(base.x) + 1, roundi(top.y), roundi(base.y), Pal.WOOD_LIGHT)
	var hw := maxi(3, roundi(0.09 * s))
	var hh := maxi(5, roundi(0.14 * s))
	var hx := roundi(top.x) - hw / 2
	var hy := roundi(top.y) - hh
	c.rect(hx, hy, hw, hh, Pal.GOLD_DARK)
	c.rect(hx + 1, hy + 1, hw - 2, hh - 2, GardenPal.WATER_FOAM)
	c.frame(hx, hy, hw, hh, Pal.INK)
	c.rect(hx - 1, hy - 2, hw + 2, 2, Pal.GOLD)
	c.ellipse_dither(base.x, base.y, maxf(2.0, hw * 0.6), maxf(1.0, hw * 0.2), GardenPal.GRASS_DEEP)
	return Vector2i(hx + hw / 2 - 1, hy + 1)


static func _grape_crates(c) -> void:
	for spec in [[-0.75, -0.15, 0.18], [0.75, 0.35, 0.15]]:
		var x: float = spec[0]
		var z: float = spec[1]
		var scale: float = spec[2]
		if z <= ZN + 0.1:
			continue
		var fy := HallCam.FLOOR_Y
		var s := HallCam.scale_at(z)
		var base := _p(x, fy, z)
		var bw := maxi(8, roundi(scale * s * 2.2))
		var bh := maxi(6, roundi(scale * s * 1.4))
		var bx := roundi(base.x) - bw / 2
		var by := roundi(base.y) - bh
		c.rect(bx, by, bw, bh, Pal.WOOD)
		c.frame(bx, by, bw, bh, Pal.INK)
		c.hline(bx + 1, bx + bw - 2, by + bh / 2, Pal.WOOD_LIGHT)
		var grapes := SpriteForge.grapes(maxi(6, roundi(bw * 0.7)))
		c.blit(grapes, roundi(base.x) - grapes.w / 2, by - grapes.h + 2)
