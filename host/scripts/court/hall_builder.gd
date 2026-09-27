class_name HallBuilder
extends RefCounted

## Paints the Banquet Hall's layers through HallCam's current camera. `c` is a
## painter: a CanvasPainter (live, every frame, so the chase camera can move) or
## a PixelCanvas (a one-off image). Both share the same pixel drawing API.
##   paint_far(c):     vault, side walls with lancet windows, back wall,
##                     the great pointed arch with its rose window and cloth of estate
##   paint_floor(c):   tiled floor, red carpet, the royal-blue dais
##   paint_columns(c): arcade spandrels, hanging side banners, columns
##   paint_feast(c):   two feast tables and their food; returns the flame spots
## Grids (tiles, stone joints, carpet studs) are anchored in hall space, so they
## stay put as the camera moves; anything nearer than HallCam.near_z() is skipped.

const GRID_Z := -4.2          # hall-space origin of the floor and wall grids
static var ZN := -4.2         # nearest depth drawn this frame (HallCam.near_z())
static var _items := {}
const SPRING := 1.3           # where the arcade arches spring
const COLUMN_R := 0.17
## Repeated bays make the room read as a proper course, not a short ballroom.
## The open middle aisle between them is reserved for future obstacle nodes.
const COLUMNS_Z := [-2.7, -1.4, -0.1, 1.2, 2.5, 3.8, 5.1, 6.4, 7.7, 9.0, 10.3, 11.6,
	12.9, 14.2, 15.5, 16.8, 18.1, 19.4, 20.7, 22.0]
const TABLE_TOP := -0.88
const DAIS_X := 1.15
const DAIS_FRONT := 21.35
const DAIS_STEP := 21.5
const DAIS_Y1 := -1.18
const DAIS_Y2 := -1.06
const CARPET_HALF := 0.45
## Part 2 wall gates, in server coordinates: [z, gap x0, x1, gap y0, y1].
## Keep these values synchronized with server/main.py COURSE_WALLS (the free-flight world). In the story the server sends
## each stage's walls in `state.walls`, and court_world.gd sets `walls` from them.
const COURSE_WALLS := [
	[-0.50, -1.00, 0.25, -0.80, 0.80],
	[-0.10, -0.25, 1.00, -0.80, 0.80],
	[0.35, -0.75, 0.75, -1.00, 0.15],
	[0.75, -0.75, 0.75, -0.15, 1.00],
]
static var walls: Array = COURSE_WALLS


## First grid line at or before ZN, so patterns are fixed to the hall.
static func _grid_start(step: float, offset: float = 0.0) -> float:
	return GRID_Z + offset + floorf((ZN - GRID_Z - offset) / step) * step


static func _item(kind: String, size: int) -> Variant:
	var key := "%s_%d" % [kind, size]
	if not _items.has(key):
		match kind:
			"candelabra":
				_items[key] = SpriteForge.candelabra(size)
			"bowl":
				_items[key] = SpriteForge.fruit_bowl(size)
			"goblet":
				_items[key] = SpriteForge.goblet(size)
			"roast":
				_items[key] = SpriteForge.roast(size)
			"grapes":
				_items[key] = SpriteForge.grapes(size)
			"bread":
				_items[key] = SpriteForge.bread(size)
	return _items[key]


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


## Pointed (gothic) arch outline in 2D (u = across, v = up): from the left
## springer over the apex to the right springer. `sharp` > 1 makes it taller.
static func _arch(cu: float, half: float, spring: float, sharp: float, steps: int = 10) -> PackedVector2Array:
	var r := half * 2.0 * sharp
	var pts := PackedVector2Array()
	var apex_du := 0.0
	var apex_v := spring + sqrt(maxf(0.0, r * r - (r - half) * (r - half)))
	# left arc: centred on the right springer shifted by (r - 2*half)
	var cl := Vector2(cu - half + r, spring)
	var a0 := PI
	var a1 := atan2(apex_v - spring, cu + apex_du - cl.x)
	for i in range(steps + 1):
		var a := lerpf(a0, a1, float(i) / steps)
		pts.append(Vector2(cl.x + cos(a) * r, spring + sin(a) * r))
	var cr := Vector2(cu + half - r, spring)
	var b0 := atan2(apex_v - spring, cu - cr.x)
	for i in range(1, steps + 1):
		var a := lerpf(b0, 0.0, float(i) / steps)
		pts.append(Vector2(cr.x + cos(a) * r, spring + sin(a) * r))
	return pts


# -------------------------------------------------------------- far layer --

static func paint_far(c) -> void:
	ZN = HallCam.near_z()
	c.rect(0, 0, HallCam.W, HallCam.H, Pal.VAULT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 70:
		c.px(rng.randi_range(0, HallCam.W - 1), rng.randi_range(0, 60), Pal.GOLD if i % 3 == 0 else Pal.GOLD_DARK)

	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var ty := HallCam.TOP_Y
	for side in [-1.0, 1.0]:
		var x: float = side * wx
		_quad_x(c, x, fy, ty, ZN, bz, Pal.STONE_DARK)
		var row := 0
		var y := fy
		while y < ty:
			var y1 := y + 0.3
			c.linev(_p(x, y1, ZN), _p(x, y1, bz), Pal.STONE_DEEP)
			var z := _grid_start(0.6, 0.3 if row % 2 == 1 else 0.0)
			while z < bz:
				if z < ZN:
					z += 0.6
					continue
				c.linev(_p(x, y, z), _p(x, y1, z), Pal.STONE_DEEP)
				z += 0.6
			y = y1
			row += 1
		var zc := -2.15
		while zc < bz - 0.45:
			if zc - 0.3 > ZN:
				_lancet(c, x, zc)
			zc += 1.1

	# back wall, block by block
	var tl := _p(-wx, ty, bz)
	var br := _p(wx, fy, bz)
	c.rect(roundi(tl.x), roundi(tl.y), roundi(br.x - tl.x), roundi(br.y - tl.y), Pal.STONE)
	var row2 := 0
	var yy := fy
	while yy < ty:
		var y1 := yy + 0.28
		var a := _p(-wx, y1, bz)
		var b := _p(wx, y1, bz)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y), Pal.STONE_DARK)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y) + 1, Pal.STONE_LIGHT)
		var xx := -wx + (0.25 if row2 % 2 == 1 else 0.0)
		while xx < wx:
			var j0 := _p(xx, yy, bz)
			var j1 := _p(xx, y1, bz)
			c.vline(roundi(j0.x), roundi(j1.y) + 1, roundi(j0.y), Pal.STONE_DARK)
			xx += 0.5
		yy = y1
		row2 += 1

	_great_arch(c)


static func _lancet(c, x: float, zc: float) -> void:
	var outer := _arch(zc, 0.27, 1.15, 1.0, 8)
	outer.insert(0, Vector2(zc - 0.27, -0.25))
	outer.append(Vector2(zc + 0.27, -0.25))
	var glass := _arch(zc, 0.21, 1.15, 1.0, 8)
	glass.insert(0, Vector2(zc - 0.21, -0.18))
	glass.append(Vector2(zc + 0.21, -0.18))
	c.poly(_on_x(outer, x), Pal.STONE_HI)
	var gp := _on_x(glass, x)
	c.poly(gp, Pal.ROYAL)
	c.poly(_on_x(PackedVector2Array([Vector2(zc - 0.21, 0.35), Vector2(zc, 0.35), Vector2(zc, 0.8), Vector2(zc - 0.21, 0.8)]), x), Pal.CRIMSON)
	c.poly(_on_x(PackedVector2Array([Vector2(zc, -0.18), Vector2(zc + 0.21, -0.18), Vector2(zc + 0.21, 0.35), Vector2(zc, 0.35)]), x), Pal.ROYAL_LIGHT)
	c.poly(_on_x(_arch(zc, 0.21, 1.15, 1.0, 8), x), Pal.GOLD)
	c.linev(_p(x, -0.18, zc), _p(x, 1.5, zc), Pal.INK)
	for v in [0.35, 0.8, 1.15]:
		c.linev(_p(x, v, zc - 0.21), _p(x, v, zc + 0.21), Pal.INK)
	c.poly_outline(gp, Pal.INK)


static func _on_x(uv: PackedVector2Array, x: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(_p(x, p.y, p.x))
	return out


static func _on_z(uv: PackedVector2Array, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(_p(p.x, p.y, z))
	return out


static func _great_arch(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var spring := 0.35
	for spec in [[1.13, Pal.STONE_HI], [1.07, Pal.GOLD], [1.03, Pal.INK], [0.95, Pal.ROYAL_DARK]]:
		var half: float = spec[0]
		var ring := _arch(0.0, half, spring, 0.8, 14)
		ring.insert(0, Vector2(-half, fy))
		ring.append(Vector2(half, fy))
		c.poly(_on_z(ring, bz), spec[1])

	# cloth of estate: a crimson hanging with gold studs behind the throne dais
	var s := HallCam.scale_at(bz)
	var cl := _p(-0.82, spring, bz)
	var cr := _p(0.82, fy, bz)
	var x0 := roundi(cl.x)
	var x1 := roundi(cr.x)
	var y0 := roundi(cl.y)
	var y1 := roundi(cr.y)
	c.rect(x0, y0, x1 - x0, y1 - y0, Pal.CRIMSON)
	var fold := maxi(4, roundi(s * 0.16))
	for x in range(x0 + 2, x1 - 1, fold):
		c.vline(x, y0 + 3, y1 - 1, Pal.CRIMSON_DARK)
		c.vline(x + 1, y0 + 3, y1 - 1, Pal.CRIMSON_LIGHT)
	var row := 0
	for y in range(y0 + 8, y1 - 4, 9):
		var off := 4 if row % 2 == 1 else 0
		for x in range(x0 + 4 + off, x1 - 3, 8):
			c.px(x, y, Pal.GOLD)
			c.px(x - 1, y + 1, Pal.GOLD)
			c.px(x + 1, y + 1, Pal.GOLD)
			c.px(x, y + 2, Pal.GOLD_DARK)
		row += 1
	# valance: scalloped band with a gold edge
	c.rect(x0 - 1, y0, x1 - x0 + 2, 4, Pal.CRIMSON_DARK)
	for x in range(x0, x1, 6):
		c.rect(x + 1, y0 + 4, 4, 1, Pal.CRIMSON_DARK)
		c.rect(x + 2, y0 + 5, 2, 1, Pal.CRIMSON_DARK)
	c.hline(x0 - 1, x1, y0, Pal.GOLD)
	c.hline(x0 - 1, x1, y0 + 3, Pal.GOLD)
	c.hline(x0, x1 - 1, y1 - 2, Pal.GOLD_DARK)

	# rose window: royal glass, eight crimson/gold petals, ink tracery
	var rc := _p(0.0, 0.95, bz)
	var rr := 0.44 * s
	c.ellipse(rc.x, rc.y, rr + 3, rr + 3, Pal.STONE_HI)
	c.ellipse(rc.x, rc.y, rr + 1, rr + 1, Pal.INK)
	c.ellipse(rc.x, rc.y, rr, rr, Pal.ROYAL)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var pc := rc + Vector2(cos(a), sin(a)) * rr * 0.6
		c.poly(PixelCanvas.ellipse_points(pc.x, pc.y, rr * 0.36, rr * 0.17, a, 14), Pal.CRIMSON if i % 2 == 0 else Pal.GOLD)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0 + PI / 8.0
		c.linev(rc, rc + Vector2(cos(a), sin(a)) * rr, Pal.INK)
	c.ellipse(rc.x, rc.y, rr * 0.26, rr * 0.26, Pal.INK)
	c.ellipse(rc.x, rc.y, rr * 0.2, rr * 0.2, Pal.GOLD)
	c.ellipse(rc.x, rc.y, rr * 0.08, rr * 0.08, Pal.CRIMSON)


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
			var col := Pal.FLOOR_B if (i + j) % 2 == 0 else Pal.FLOOR_A
			if z + tile_z > ZN:
				_quad_y(c, fy, x, minf(x + tile_x, wx), maxf(z, ZN), minf(z + tile_z, bz), col)
			z += tile_z
		x += tile_x
		i += 1
	var gz := _grid_start(tile_z) + tile_z
	while gz <= bz:
		c.linev(_p(-wx, fy, gz), _p(wx, fy, gz), Pal.GROUT)
		gz += tile_z
	var gx := -wx
	while gx <= wx + 0.001:
		c.linev(_p(gx, fy, ZN), _p(gx, fy, bz), Pal.GROUT)
		gx += tile_x
	# dithered shade along both walls and the back wall
	for side in [-1.0, 1.0]:
		var a: float = side * wx
		var b: float = side * (wx - 0.3)
		c.poly_dither(PackedVector2Array([_p(a, fy, ZN), _p(a, fy, bz), _p(b, fy, bz), _p(b, fy, ZN)]), Pal.STONE_DEEP)
	c.poly_dither(PackedVector2Array([_p(-wx, fy, bz - 0.25), _p(wx, fy, bz - 0.25), _p(wx, fy, bz), _p(-wx, fy, bz)]), Pal.STONE_DEEP)

	_dais(c)

	# the red carpet runs from the doors to the dais
	var h := CARPET_HALF
	_quad_y(c, fy, -h, h, ZN, DAIS_FRONT, Pal.CRIMSON)
	var dz := _grid_start(0.5) + 0.5
	while dz < DAIS_FRONT - 0.2:
		if dz - 0.1 > ZN:
			c.poly(PackedVector2Array([_p(0, fy, dz - 0.1), _p(0.1, fy, dz), _p(0, fy, dz + 0.1), _p(-0.1, fy, dz)]), Pal.GOLD)
		dz += 0.5
	for side in [-1.0, 1.0]:
		c.linev(_p(side * (h - 0.07), fy, ZN), _p(side * (h - 0.07), fy, DAIS_FRONT), Pal.GOLD)
		c.linev(_p(side * h, fy, ZN), _p(side * h, fy, DAIS_FRONT), Pal.INK)
	# ...and up the steps
	_quad_z(c, DAIS_FRONT, -h, h, fy, DAIS_Y1, Pal.CRIMSON_DARK)
	_quad_y(c, DAIS_Y1, -h, h, DAIS_FRONT, DAIS_STEP, Pal.CRIMSON)
	_quad_z(c, DAIS_STEP, -h, h, DAIS_Y1, DAIS_Y2, Pal.CRIMSON_DARK)
	_quad_y(c, DAIS_Y2, -h, h, DAIS_STEP, 1.15, Pal.CRIMSON)
	c.linev(_p(-h, DAIS_Y2, 1.15), _p(h, DAIS_Y2, 1.15), Pal.GOLD)
	for side in [-1.0, 1.0]:
		c.linev(_p(side * h, DAIS_Y2, DAIS_STEP), _p(side * h, DAIS_Y2, 1.15), Pal.GOLD)


static func _dais(c) -> void:
	var fy := HallCam.FLOOR_Y
	var bz := HallCam.BACK_Z
	var x := DAIS_X
	_quad_y(c, DAIS_Y2, -x, x, DAIS_STEP, bz, Pal.ROYAL)
	_quad_z(c, DAIS_STEP, -x, x, DAIS_Y1, DAIS_Y2, Pal.ROYAL_DARK)
	_quad_y(c, DAIS_Y1, -x, x, DAIS_FRONT, DAIS_STEP, Pal.ROYAL)
	_quad_z(c, DAIS_FRONT, -x, x, fy, DAIS_Y1, Pal.ROYAL_DARK)
	# gold nosing on each step, ink where each step meets the one below
	c.linev(_p(-x, DAIS_Y2, DAIS_STEP), _p(x, DAIS_Y2, DAIS_STEP), Pal.GOLD)
	c.linev(_p(-x, DAIS_Y1, DAIS_FRONT), _p(x, DAIS_Y1, DAIS_FRONT), Pal.GOLD)
	c.linev(_p(-x, DAIS_Y1, DAIS_STEP), _p(x, DAIS_Y1, DAIS_STEP), Pal.INK)
	c.linev(_p(-x, fy, DAIS_FRONT), _p(x, fy, DAIS_FRONT), Pal.INK)
	# fleur studs along the top step
	var zz := DAIS_STEP + 0.25
	var xx := -x + 0.2
	while xx < x - 0.1:
		var p := _p(xx, DAIS_Y2, zz)
		c.px(roundi(p.x), roundi(p.y), Pal.GOLD)
		xx += 0.3
	for side in [-1.0, 1.0]:
		c.linev(_p(side * x, fy, DAIS_FRONT), _p(side * x, DAIS_Y1, DAIS_FRONT), Pal.INK)
		c.linev(_p(side * x, DAIS_Y1, DAIS_STEP), _p(side * x, DAIS_Y2, DAIS_STEP), Pal.INK)


# ---------------------------------------------------------- columns layer --

static func paint_columns(c) -> void:
	ZN = HallCam.near_z()
	var bz := HallCam.BACK_Z
	var ty := HallCam.TOP_Y
	for side in [-1.0, 1.0]:
		var x: float = side * HallCam.COLUMN_X
		# the arcade: spandrel walls over pointed arches between the columns
		var bays: Array = [[ZN, COLUMNS_Z[0]]]
		for k in range(COLUMNS_Z.size() - 1):
			bays.append([COLUMNS_Z[k], COLUMNS_Z[k + 1]])
		bays.append([COLUMNS_Z[COLUMNS_Z.size() - 1], bz])
		for k in bays.size():
			var z0: float = bays[k][0]
			var z1: float = bays[k][1]
			if z1 <= ZN:
				continue
			if k == 0 or z0 < ZN:
				_quad_x(c, x, SPRING, ty, maxf(z0, ZN), z1, Pal.STONE)
				continue
			var half := (z1 - z0) / 2.0 - COLUMN_R
			var arch := _arch((z0 + z1) / 2.0, half, SPRING, 0.75, 10)
			var wall := PackedVector2Array([Vector2(z0, SPRING)])
			wall.append_array(arch)
			wall.append_array(PackedVector2Array([Vector2(z1, SPRING), Vector2(z1, ty), Vector2(z0, ty)]))
			c.poly(_on_x(wall, x), Pal.STONE)
			var edge := _on_x(arch, x)
			for n in range(edge.size() - 1):
				c.linev(edge[n], edge[n + 1], Pal.INK)
				c.linev(edge[n] + Vector2(0, -1), edge[n + 1] + Vector2(0, -1), Pal.GOLD_DARK)
			# hanging banner in the bay
			if k < bays.size() - 1:
				var field := Pal.CRIMSON if (k + (1 if side > 0 else 0)) % 2 == 0 else Pal.ROYAL
				_side_banner(c, x, (z0 + z1) / 2.0, field)

		# columns, far to near
		for k in range(COLUMNS_Z.size() - 1, -1, -1):
			if COLUMNS_Z[k] - COLUMN_R > ZN + 0.2:
				_column(c, x, COLUMNS_Z[k], side < 0.0)


## Four solid course walls: alternating side openings, then low/high openings.
## They are drawn far-to-near so their overlap matches the chase camera.
static func paint_course_walls(c) -> void:
	for i in range(walls.size() - 1, -1, -1):
		var spec: Array = walls[i]
		var z := HallCam.from_server(Vector3(0.0, 0.0, float(spec[0]))).z
		if z <= ZN + 0.08:
			continue
		var gx0 := float(spec[1]) * HallCam.SX
		var gx1 := float(spec[2]) * HallCam.SX
		var gy0 := float(spec[3])
		var gy1 := float(spec[4])
		_course_wall(c, z, gx0, gx1, gy0, gy1, i)


static func _course_wall(c, z: float, gx0: float, gx1: float, gy0: float, gy1: float, index: int) -> void:
	var x0 := -HallCam.COLUMN_X + 0.12
	var x1 := HallCam.COLUMN_X - 0.12
	var y0 := HallCam.FLOOR_Y
	var y1 := HallCam.TOP_Y - 0.22
	var pieces: Array = [
		[x0, gx0, y0, y1], [gx1, x1, y0, y1],
		[gx0, gx1, y0, gy0], [gx0, gx1, gy1, y1],
	]
	for piece in pieces:
		var px0 := float(piece[0])
		var px1 := float(piece[1])
		var py0 := float(piece[2])
		var py1 := float(piece[3])
		if px1 <= px0 or py1 <= py0:
			continue
		var face := _quad_z(c, z, px0, px1, py0, py1, Pal.STONE)
		c.poly_outline(face, Pal.INK)
		# Sparse masonry joints keep the opening readable at speed.
		var yy := py0 + 0.28
		while yy < py1:
			c.linev(_p(px0, yy, z), _p(px1, yy, z), Pal.STONE_DARK)
			yy += 0.28
	# Gold and ink trim makes the safe opening unmistakable without an arrow.
	var opening := PackedVector2Array([
		_p(gx0, gy0, z), _p(gx1, gy0, z), _p(gx1, gy1, z), _p(gx0, gy1, z)])
	c.poly_outline(opening, Pal.INK)
	var inset := 0.025
	var trim := PackedVector2Array([
		_p(gx0 - inset, gy0 - inset, z), _p(gx1 + inset, gy0 - inset, z),
		_p(gx1 + inset, gy1 + inset, z), _p(gx0 - inset, gy1 + inset, z)])
	c.poly_outline(trim, Pal.GOLD if index % 2 == 0 else Pal.GOLD_DARK)


static func _side_banner(c, x: float, zc: float, field: Color) -> void:
	var hw := 0.17
	var top := SPRING + 0.2
	var bot := 0.15
	var shape := PackedVector2Array([
		Vector2(zc - hw, top), Vector2(zc + hw, top), Vector2(zc + hw, bot),
		Vector2(zc, bot + 0.22), Vector2(zc - hw, bot)])
	var pts := _on_x(shape, x)
	c.poly(pts, field)
	var inset := PackedVector2Array([
		Vector2(zc - hw + 0.04, top - 0.06), Vector2(zc + hw - 0.04, top - 0.06), Vector2(zc + hw - 0.04, bot + 0.06),
		Vector2(zc, bot + 0.26), Vector2(zc - hw + 0.04, bot + 0.06)])
	c.poly_outline(_on_x(inset, x), Pal.GOLD)
	var em := _p(x, (top + bot) / 2.0 + 0.2, zc)
	c.px(roundi(em.x), roundi(em.y) - 1, Pal.GOLD)
	c.rect(roundi(em.x) - 1, roundi(em.y), 3, 1, Pal.GOLD)
	c.px(roundi(em.x), roundi(em.y) + 1, Pal.GOLD)
	c.poly_outline(pts, Pal.INK)
	c.linev(_p(x, top + 0.03, zc - hw - 0.05), _p(x, top + 0.03, zc + hw + 0.05), Pal.GOLD)


static func _column(c, x: float, z: float, left: bool) -> void:
	var fy := HallCam.FLOOR_Y
	var s := HallCam.scale_at(z)
	var cx := _p(x, 0.0, z).x
	var y_floor := roundi(_p(x, fy, z).y)
	var y_torus := roundi(_p(x, fy + 0.14, z).y)
	var y_shaft := roundi(_p(x, fy + 0.2, z).y)
	var y_cap := roundi(_p(x, SPRING - 0.18, z).y)
	var y_abacus := roundi(_p(x, SPRING - 0.04, z).y)
	var y_top := roundi(_p(x, SPRING, z).y)
	var r := COLUMN_R * s

	# grounding shadow
	c.ellipse_dither(cx, y_floor, r * 1.9, maxf(2.0, r * 0.35), Pal.INK)
	# plinth and torus
	var pw := roundi(r * 2.7)
	c.rect(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus, Pal.STONE_LIGHT)
	c.frame(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus + 1, Pal.INK)
	var tw := roundi(r * 2.35)
	c.rect(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft, Pal.STONE_HI)
	c.frame(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft + 1, Pal.INK)
	c.hline(roundi(cx - tw / 2.0) + 1, roundi(cx + tw / 2.0) - 2, y_torus - 1, Pal.GOLD)

	# the shaft: lit on the side facing the hall's centre, fluted
	var sw := maxi(4, roundi(r * 2.0))
	var sx0 := roundi(cx - sw / 2.0)
	c.rect(sx0, y_cap, sw, y_shaft - y_cap, Pal.STONE_LIGHT)
	var band := maxi(1, roundi(sw * 0.3))
	var lit_x := sx0 + sw - band if left else sx0
	var dark_x := sx0 if left else sx0 + sw - band
	c.rect(lit_x, y_cap, band, y_shaft - y_cap, Pal.STONE_HI)
	c.rect(dark_x, y_cap, band, y_shaft - y_cap, Pal.STONE)
	var flute := maxi(3, roundi(sw / 5.0))
	for fx in range(sx0 + flute, sx0 + sw - 1, flute):
		c.vline(fx, y_cap + 1, y_shaft - 1, Pal.STONE_DARK if (fx < lit_x or not left) else Pal.STONE)
	c.vline(sx0, y_cap, y_shaft, Pal.INK)
	c.vline(sx0 + sw - 1, y_cap, y_shaft, Pal.INK)

	# capital: flared bell, a gold band and the abacus block
	var cw_top := roundi(r * 2.9)
	var cap := PackedVector2Array([
		Vector2(cx - sw / 2.0, y_cap + 0.5), Vector2(cx + sw / 2.0, y_cap + 0.5),
		Vector2(cx + cw_top / 2.0, y_abacus + 0.5), Vector2(cx - cw_top / 2.0, y_abacus + 0.5)])
	c.poly(cap, Pal.STONE_HI)
	c.poly_outline(cap, Pal.INK)
	c.hline(sx0, sx0 + sw - 1, y_cap, Pal.GOLD)
	var aw := roundi(r * 3.1)
	c.rect(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), Pal.STONE_LIGHT)
	c.frame(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), Pal.INK)
	# vaulting shaft rising into the dark
	c.vline(roundi(cx), 0, y_top - 1, Pal.GOLD_DARK)


# ------------------------------------------------------------ feast layer --

## Returns {"canvas": PixelCanvas, "flames": Array[Vector2i]}
## Returns the candle-flame spots (screen px) for the animated flames.
static func paint_feast(c) -> Array:
	ZN = HallCam.near_z()
	var flames: Array = []
	_table(c, -1.95, -1.45, -1.75, 0.35, true, flames)
	_table(c, 1.45, 1.95, -1.25, 0.85, false, flames)
	return flames


static func _table(c, x0: float, x1: float, z0: float, z1: float, left: bool, flames: Array) -> void:
	var fy := HallCam.FLOOR_Y + 0.02
	var ty := TABLE_TOP
	if z1 <= ZN + 0.05:
		return
	var z_far := z1
	z0 = maxf(z0, ZN)
	var aisle := x1 if left else x0
	var outer := x0 if left else x1
	var xc := (x0 + x1) / 2.0

	# the long side facing the aisle: tablecloth, folds, hanging crimson runner
	var side := _quad_x(c, aisle, fy, ty, z0, z1, Pal.PARCHMENT)
	var z := GRID_Z + ceilf((z0 - GRID_Z) / 0.2) * 0.2
	while z < z1:
		c.linev(_p(aisle, ty - 0.12, z), _p(aisle, fy, z), Pal.PARCHMENT_DARK)
		z += 0.2
	_quad_x(c, aisle, ty - 0.13, ty, z0, z1, Pal.CRIMSON)
	c.linev(_p(aisle, ty - 0.13, z0), _p(aisle, ty - 0.13, z1), Pal.GOLD)
	c.poly_outline(side, Pal.INK)
	# near end, in shade
	var end := _quad_z(c, z0, x0, x1, fy, ty, Pal.PARCHMENT_DARK)
	_quad_z(c, z0, xc - 0.07, xc + 0.07, ty - 0.18, ty, Pal.CRIMSON)
	c.poly_outline(end, Pal.INK)
	# top
	var top := _quad_y(c, ty, x0, x1, z0, z1, Pal.PARCHMENT)
	_quad_y(c, ty, xc - 0.07, xc + 0.07, z0, z1, Pal.CRIMSON)
	c.linev(_p(xc - 0.07, ty, z0), _p(xc - 0.07, ty, z1), Pal.GOLD_DARK)
	c.poly_outline(top, Pal.INK)
	c.linev(_p(outer, ty, z0), _p(outer, ty, z1), Pal.INK)

	# the feast, far to near so nearer dishes overlap farther ones
	var menu := ["candelabra", "bowl", "goblet", "roast", "grapes", "goblet", "bread", "bowl", "candelabra"]
	for k in menu.size():
		var zz: float = lerpf(z_far - 0.18, -1.55 if left else -1.05, float(k) / (menu.size() - 1))
		if zz < ZN + 0.25:
			continue
		var base := HallCam.project(Vector3(xc + (0.05 if k % 2 == 0 else -0.05), ty, zz))
		var s := base.z
		var bx := roundi(base.x)
		var by := roundi(base.y) + 1
		match menu[k]:
			"candelabra":
				var cd: Dictionary = _item("candelabra", roundi(0.42 * s))
				var cc: PixelCanvas = cd["canvas"]
				var ox := bx - cc.w / 2
				var oy := by - cc.h
				c.blit(cc, ox, oy)
				for f in cd["flames"]:
					flames.append(Vector2i(ox + f.x, oy + f.y))
			"bowl":
				_place(c, _item("bowl", roundi(0.26 * s)), bx, by)
			"goblet":
				_place(c, _item("goblet", roundi(0.13 * s)), bx, by)
			"roast":
				_place(c, _item("roast", roundi(0.3 * s)), bx, by)
			"grapes":
				_place(c, _item("grapes", roundi(0.14 * s)), bx, by)
			"bread":
				_place(c, _item("bread", roundi(0.2 * s)), bx, by)


static func _place(c, item: PixelCanvas, bx: int, by: int) -> void:
	c.blit(item, bx - item.w / 2, by - item.h)


## Screen rectangles for the two big frontal banners on the back wall:
## [{pos: Vector2i (top-left), w, h, field, emblem}]
static func back_banners() -> Array:
	var out: Array = []
	var bz := HallCam.BACK_Z
	for spec in [[-1.62, Pal.CRIMSON, "crown"], [1.62, Pal.ROYAL, "fly"]]:
		var tl := _p(spec[0] - 0.28, 1.75, bz)
		var br := _p(spec[0] + 0.28, -0.1, bz)
		out.append({"pos": Vector2i(roundi(tl.x), roundi(tl.y)), "w": roundi(br.x - tl.x), "h": roundi(br.y - tl.y),
			"field": spec[1], "emblem": spec[2]})
	return out
