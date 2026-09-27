class_name GreatHallBuilder
extends RefCounted

## Trial III "The Giant's Shadow" variant of the Banquet Hall: same architecture
## as HallBuilder (same arch geometry, same dais/columns/tables layout, same
## HallCam projection) but recoloured for night and dread, with guttering
## candles instead of steady flames and a looming shadow across the back wall.
##
## Reuses HallBuilder's pure-geometry static helpers directly (arch curves,
## quads, grid alignment, prop cache) since those carry no palette baked in;
## every draw call that touches colour is rewritten here against GHPal so the
## day hall (hall_builder.gd) is never edited. Paint order and public shape
## match HallBuilder exactly: paint_far / paint_floor / paint_columns /
## paint_feast, plus back_banners() and the shared layout constants.

const GRID_Z := HallBuilder.GRID_Z
const SPRING := HallBuilder.SPRING
const COLUMN_R := HallBuilder.COLUMN_R
const COLUMNS_Z := HallBuilder.COLUMNS_Z
const TABLE_TOP := HallBuilder.TABLE_TOP
const DAIS_X := HallBuilder.DAIS_X
const DAIS_FRONT := HallBuilder.DAIS_FRONT
const DAIS_STEP := HallBuilder.DAIS_STEP
const DAIS_Y1 := HallBuilder.DAIS_Y1
const DAIS_Y2 := HallBuilder.DAIS_Y2
const CARPET_HALF := HallBuilder.CARPET_HALF

static var ZN := -3.5

## The looming hand-shadow thrown on the back wall: 0 = not visible, 1 = fully
## loomed in (the Giant close). Set by whoever drives the scene (the court, or
## our own test scene) so the background reacts to the same hazard progress
## the Shadows/GiantHand layers already show.
static var loom_p := 0.0
static var loom_x := 0.35


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallBuilder._p(x, y, z)


# -------------------------------------------------------------- far layer --

static func paint_far(c) -> void:
	ZN = HallCam.near_z()
	c.rect(0, 0, HallCam.W, HallCam.H, GHPal.VAULT_NIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# far fewer, dimmer "stars" of gilding catching what little light remains
	for i in 22:
		c.px(rng.randi_range(0, HallCam.W - 1), rng.randi_range(0, 50), GHPal.BRASS_DIM if i % 4 == 0 else GHPal.BRASS_DARK)

	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var ty := HallCam.TOP_Y
	for side in [-1.0, 1.0]:
		var x: float = side * wx
		HallBuilder._quad_x(c, x, fy, ty, ZN, bz, GHPal.STONE_DARK_NIGHT)
		var row := 0
		var y := fy
		while y < ty:
			var y1 := y + 0.3
			c.linev(_p(x, y1, ZN), _p(x, y1, bz), GHPal.STONE_DEEP_NIGHT)
			var z := HallBuilder._grid_start(0.6, 0.3 if row % 2 == 1 else 0.0)
			while z < bz:
				if z < ZN:
					z += 0.6
					continue
				c.linev(_p(x, y, z), _p(x, y1, z), GHPal.STONE_DEEP_NIGHT)
				z += 0.6
			y = y1
			row += 1
		for zc in [-1.45, -0.35, 0.75]:
			if zc - 0.3 > ZN:
				_lancet(c, x, zc)

	# back wall, block by block
	var tl := _p(-wx, ty, bz)
	var br := _p(wx, fy, bz)
	c.rect(roundi(tl.x), roundi(tl.y), roundi(br.x - tl.x), roundi(br.y - tl.y), GHPal.STONE_NIGHT)
	var row2 := 0
	var yy := fy
	while yy < ty:
		var y1 := yy + 0.28
		var a := _p(-wx, y1, bz)
		var b := _p(wx, y1, bz)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y), GHPal.STONE_DARK_NIGHT)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y) + 1, GHPal.STONE_LIGHT_NIGHT)
		var xx := -wx + (0.25 if row2 % 2 == 1 else 0.0)
		while xx < wx:
			var j0 := _p(xx, yy, bz)
			var j1 := _p(xx, y1, bz)
			c.vline(roundi(j0.x), roundi(j1.y) + 1, roundi(j0.y), GHPal.STONE_DARK_NIGHT)
			xx += 0.5
		yy = y1
		row2 += 1

	_great_arch(c)


## Night sky through the lancet: cold moon-glass instead of the day's royal
## blue, no crimson/gold partitions, a pale moon-sliver instead of a bright pane.
static func _lancet(c, x: float, zc: float) -> void:
	var outer := HallBuilder._arch(zc, 0.27, 1.15, 1.0, 8)
	outer.insert(0, Vector2(zc - 0.27, -0.25))
	outer.append(Vector2(zc + 0.27, -0.25))
	var glass := HallBuilder._arch(zc, 0.21, 1.15, 1.0, 8)
	glass.insert(0, Vector2(zc - 0.21, -0.18))
	glass.append(Vector2(zc + 0.21, -0.18))
	c.poly(HallBuilder._on_x(outer, x), GHPal.STONE_HI_NIGHT)
	var gp := HallBuilder._on_x(glass, x)
	c.poly(gp, GHPal.MOON_GLASS_DARK)
	# a cold sliver of moonlight down one side of the pane
	c.poly(HallBuilder._on_x(PackedVector2Array([Vector2(zc, -0.18), Vector2(zc + 0.09, -0.18), Vector2(zc + 0.09, 0.9), Vector2(zc, 0.9)]), x), GHPal.MOON_GLASS)
	c.poly(HallBuilder._on_x(PackedVector2Array([Vector2(zc + 0.03, -0.1), Vector2(zc + 0.07, -0.1), Vector2(zc + 0.07, 0.55), Vector2(zc + 0.03, 0.55)]), x), GHPal.MOON_GLASS_LIGHT)
	c.poly_outline(HallBuilder._on_x(HallBuilder._arch(zc, 0.21, 1.15, 1.0, 8), x), GHPal.MOON_TRACERY)
	c.linev(_p(x, -0.18, zc), _p(x, 1.5, zc), Pal.INK)
	for v in [0.35, 0.8, 1.15]:
		c.linev(_p(x, v, zc - 0.21), _p(x, v, zc + 0.21), Pal.INK)
	c.poly_outline(gp, Pal.INK)


static func _great_arch(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var spring := 0.35
	for spec in [[1.13, GHPal.STONE_HI_NIGHT], [1.07, GHPal.BRASS_DIM], [1.03, Pal.INK], [0.95, GHPal.ROYAL_NIGHT_DARK]]:
		var half: float = spec[0]
		var ring := HallBuilder._arch(0.0, half, spring, 0.8, 14)
		ring.insert(0, Vector2(-half, fy))
		ring.append(Vector2(half, fy))
		c.poly(HallBuilder._on_z(ring, bz), spec[1])

	# cloth of estate, dimmed almost to black-crimson
	var s := HallCam.scale_at(bz)
	var cl := _p(-0.82, spring, bz)
	var cr := _p(0.82, fy, bz)
	var x0 := roundi(cl.x)
	var x1 := roundi(cr.x)
	var y0 := roundi(cl.y)
	var y1 := roundi(cr.y)
	c.rect(x0, y0, x1 - x0, y1 - y0, GHPal.CRIMSON_NIGHT)
	var fold := maxi(4, roundi(s * 0.16))
	for x in range(x0 + 2, x1 - 1, fold):
		c.vline(x, y0 + 3, y1 - 1, GHPal.CRIMSON_NIGHT_DARK)
		c.vline(x + 1, y0 + 3, y1 - 1, GHPal.CRIMSON_NIGHT)
	var row := 0
	for y in range(y0 + 8, y1 - 4, 9):
		var off := 4 if row % 2 == 1 else 0
		for x in range(x0 + 4 + off, x1 - 3, 8):
			c.px(x, y, GHPal.BRASS_DIM)
			c.px(x - 1, y + 1, GHPal.BRASS_DIM)
			c.px(x + 1, y + 1, GHPal.BRASS_DIM)
			c.px(x, y + 2, GHPal.BRASS_DARK)
		row += 1
	c.rect(x0 - 1, y0, x1 - x0 + 2, 4, GHPal.CRIMSON_NIGHT_DARK)
	for x in range(x0, x1, 6):
		c.rect(x + 1, y0 + 4, 4, 1, GHPal.CRIMSON_NIGHT_DARK)
		c.rect(x + 2, y0 + 5, 2, 1, GHPal.CRIMSON_NIGHT_DARK)
	c.hline(x0 - 1, x1, y0, GHPal.BRASS_DIM)
	c.hline(x0 - 1, x1, y0 + 3, GHPal.BRASS_DIM)
	c.hline(x0, x1 - 1, y1 - 2, GHPal.BRASS_DARK)

	# rose window: now the hall's one cold light source, moon-glass with a
	# pale halo bleeding into the dark stone around it
	var rc := _p(0.0, 0.95, bz)
	var rr := 0.44 * s
	c.ellipse_dither(rc.x, rc.y, rr + 8, rr + 8, GHPal.MOON_GLASS_DARK)
	c.ellipse(rc.x, rc.y, rr + 3, rr + 3, GHPal.STONE_HI_NIGHT)
	c.ellipse(rc.x, rc.y, rr + 1, rr + 1, GHPal.MOON_TRACERY)
	c.ellipse(rc.x, rc.y, rr, rr, GHPal.MOON_GLASS)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var pc := rc + Vector2(cos(a), sin(a)) * rr * 0.6
		c.poly(PixelCanvas.ellipse_points(pc.x, pc.y, rr * 0.36, rr * 0.17, a, 14), GHPal.CRIMSON_NIGHT if i % 2 == 0 else GHPal.BRASS_DIM)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0 + PI / 8.0
		c.linev(rc, rc + Vector2(cos(a), sin(a)) * rr, GHPal.MOON_TRACERY)
	c.ellipse(rc.x, rc.y, rr * 0.26, rr * 0.26, GHPal.MOON_TRACERY)
	c.ellipse(rc.x, rc.y, rr * 0.2, rr * 0.2, GHPal.MOON_PALE)
	c.ellipse(rc.x, rc.y, rr * 0.08, rr * 0.08, GHPal.MOON_GLASS_LIGHT)


## The Giant's hand cast huge and dark across the arcade and back wall, off to
## one side of the rose window, reaching down from the vault as `loom_p`
## (0..1) rises. Authored directly in screen pixels (this is a flat shadow
## painted over whatever is behind it, not a 3D prop) so the shape stays
## legible regardless of camera state and isn't hidden behind the arcade
## spandrels; called last, after the columns/feast paint, so it falls across
## them. Dithered at its edges so it reads as a soft, oversized shadow, not a
## hard cutout. Fingers point down the wall towards the floor, palm nearest
## the vault.
static func paint_loom_shadow(c) -> void:
	if loom_p <= 0.01:
		return
	var ox := HallCam.CX + loom_x * HallCam.W * 0.5
	var oy := HallCam.H * 0.06
	var span: float = lerpf(HallCam.H * 0.22, HallCam.H * 0.62, loom_p)
	var palm_w := span * 0.66
	var palm_h := span * 0.5
	var palm := PackedVector2Array([
		Vector2(ox - palm_w * 0.5, oy),
		Vector2(ox + palm_w * 0.5, oy),
		Vector2(ox + palm_w * 0.42, oy + palm_h),
		Vector2(ox - palm_w * 0.42, oy + palm_h)])
	c.poly_dither(palm, GHPal.LOOM_SHADOW)
	var fingers := 4
	for i in fingers:
		var t := (float(i) / (fingers - 1) - 0.5) * 2.0
		var fx := ox + t * palm_w * 0.42
		var fy0 := oy + palm_h * 0.92
		var flen := span * (0.62 + 0.16 * (1.0 - absf(t)))
		var fw := span * 0.1
		var finger := PackedVector2Array([
			Vector2(fx - fw, fy0),
			Vector2(fx + fw, fy0),
			Vector2(fx + fw * 0.55, fy0 + flen),
			Vector2(fx - fw * 0.55, fy0 + flen)])
		c.poly_dither(finger, GHPal.LOOM_SHADOW)
	# thumb, splayed off to one side, a little shorter
	var tx := ox - palm_w * 0.58
	var ty0 := oy + palm_h * 0.3
	var thumb := PackedVector2Array([
		Vector2(tx - span * 0.05, ty0),
		Vector2(tx + span * 0.14, ty0 - span * 0.04),
		Vector2(tx + span * 0.2, ty0 + span * 0.42),
		Vector2(tx + span * 0.02, ty0 + span * 0.5)])
	c.poly_dither(thumb, GHPal.LOOM_SHADOW)


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
		var z := HallBuilder._grid_start(tile_z)
		while z < bz - 0.001:
			var j := roundi((z - GRID_Z) / tile_z)
			var col := GHPal.FLOOR_B_NIGHT if (i + j) % 2 == 0 else GHPal.FLOOR_A_NIGHT
			if z + tile_z > ZN:
				HallBuilder._quad_y(c, fy, x, minf(x + tile_x, wx), maxf(z, ZN), minf(z + tile_z, bz), col)
			z += tile_z
		x += tile_x
		i += 1
	var gz := HallBuilder._grid_start(tile_z) + tile_z
	while gz <= bz:
		c.linev(_p(-wx, fy, gz), _p(wx, fy, gz), GHPal.GROUT_NIGHT)
		gz += tile_z
	var gx := -wx
	while gx <= wx + 0.001:
		c.linev(_p(gx, fy, ZN), _p(gx, fy, bz), GHPal.GROUT_NIGHT)
		gx += tile_x
	# deeper dithered shadow along both walls and the back wall: wider bands
	# than the day hall, and a second darker pass nearer the walls
	for side in [-1.0, 1.0]:
		var a: float = side * wx
		var b: float = side * (wx - 0.42)
		var b2: float = side * (wx - 0.16)
		c.poly_dither(PackedVector2Array([_p(a, fy, ZN), _p(a, fy, bz), _p(b, fy, bz), _p(b, fy, ZN)]), GHPal.STONE_DEEP_NIGHT)
		c.poly_dither(PackedVector2Array([_p(a, fy, ZN), _p(a, fy, bz), _p(b2, fy, bz), _p(b2, fy, ZN)]), Pal.INK)
	c.poly_dither(PackedVector2Array([_p(-wx, fy, bz - 0.35), _p(wx, fy, bz - 0.35), _p(wx, fy, bz), _p(-wx, fy, bz)]), GHPal.STONE_DEEP_NIGHT)
	c.poly_dither(PackedVector2Array([_p(-wx, fy, bz - 0.12), _p(wx, fy, bz - 0.12), _p(wx, fy, bz), _p(-wx, fy, bz)]), Pal.INK)

	_dais(c)

	# the red carpet, gone almost to black in the gloom
	var h := CARPET_HALF
	HallBuilder._quad_y(c, fy, -h, h, ZN, DAIS_FRONT, GHPal.CRIMSON_NIGHT)
	var dz := HallBuilder._grid_start(0.5) + 0.5
	while dz < DAIS_FRONT - 0.2:
		if dz - 0.1 > ZN:
			c.poly(PackedVector2Array([_p(0, fy, dz - 0.1), _p(0.1, fy, dz), _p(0, fy, dz + 0.1), _p(-0.1, fy, dz)]), GHPal.BRASS_DIM)
		dz += 0.5
	for side in [-1.0, 1.0]:
		c.linev(_p(side * (h - 0.07), fy, ZN), _p(side * (h - 0.07), fy, DAIS_FRONT), GHPal.BRASS_DIM)
		c.linev(_p(side * h, fy, ZN), _p(side * h, fy, DAIS_FRONT), Pal.INK)
	HallBuilder._quad_z(c, DAIS_FRONT, -h, h, fy, DAIS_Y1, GHPal.CRIMSON_NIGHT_DARK)
	HallBuilder._quad_y(c, DAIS_Y1, -h, h, DAIS_FRONT, DAIS_STEP, GHPal.CRIMSON_NIGHT)
	HallBuilder._quad_z(c, DAIS_STEP, -h, h, DAIS_Y1, DAIS_Y2, GHPal.CRIMSON_NIGHT_DARK)
	HallBuilder._quad_y(c, DAIS_Y2, -h, h, DAIS_STEP, 1.15, GHPal.CRIMSON_NIGHT)
	c.linev(_p(-h, DAIS_Y2, 1.15), _p(h, DAIS_Y2, 1.15), GHPal.BRASS_DIM)
	for side in [-1.0, 1.0]:
		c.linev(_p(side * h, DAIS_Y2, DAIS_STEP), _p(side * h, DAIS_Y2, 1.15), GHPal.BRASS_DIM)


static func _dais(c) -> void:
	var fy := HallCam.FLOOR_Y
	var bz := HallCam.BACK_Z
	var x := DAIS_X
	HallBuilder._quad_y(c, DAIS_Y2, -x, x, DAIS_STEP, bz, GHPal.ROYAL_NIGHT)
	HallBuilder._quad_z(c, DAIS_STEP, -x, x, DAIS_Y1, DAIS_Y2, GHPal.ROYAL_NIGHT_DARK)
	HallBuilder._quad_y(c, DAIS_Y1, -x, x, DAIS_FRONT, DAIS_STEP, GHPal.ROYAL_NIGHT)
	HallBuilder._quad_z(c, DAIS_FRONT, -x, x, fy, DAIS_Y1, GHPal.ROYAL_NIGHT_DARK)
	c.linev(_p(-x, DAIS_Y2, DAIS_STEP), _p(x, DAIS_Y2, DAIS_STEP), GHPal.BRASS_DIM)
	c.linev(_p(-x, DAIS_Y1, DAIS_FRONT), _p(x, DAIS_Y1, DAIS_FRONT), GHPal.BRASS_DIM)
	c.linev(_p(-x, DAIS_Y1, DAIS_STEP), _p(x, DAIS_Y1, DAIS_STEP), Pal.INK)
	c.linev(_p(-x, fy, DAIS_FRONT), _p(x, fy, DAIS_FRONT), Pal.INK)
	var zz := DAIS_STEP + 0.25
	var xx := -x + 0.2
	while xx < x - 0.1:
		var p := _p(xx, DAIS_Y2, zz)
		c.px(roundi(p.x), roundi(p.y), GHPal.BRASS_DIM)
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
				HallBuilder._quad_x(c, x, SPRING, ty, maxf(z0, ZN), z1, GHPal.STONE_NIGHT)
				continue
			var half := (z1 - z0) / 2.0 - COLUMN_R
			var arch := HallBuilder._arch((z0 + z1) / 2.0, half, SPRING, 0.75, 10)
			var wall := PackedVector2Array([Vector2(z0, SPRING)])
			wall.append_array(arch)
			wall.append_array(PackedVector2Array([Vector2(z1, SPRING), Vector2(z1, ty), Vector2(z0, ty)]))
			c.poly(HallBuilder._on_x(wall, x), GHPal.STONE_NIGHT)
			var edge := HallBuilder._on_x(arch, x)
			for n in range(edge.size() - 1):
				c.linev(edge[n], edge[n + 1], Pal.INK)
				c.linev(edge[n] + Vector2(0, -1), edge[n + 1] + Vector2(0, -1), GHPal.BRASS_DARK)
			if k < bays.size() - 1:
				var field := GHPal.CRIMSON_NIGHT if (k + (1 if side > 0 else 0)) % 2 == 0 else GHPal.ROYAL_NIGHT
				_side_banner(c, x, (z0 + z1) / 2.0, field)

		for k in range(COLUMNS_Z.size() - 1, -1, -1):
			if COLUMNS_Z[k] - COLUMN_R > ZN + 0.2:
				_column(c, x, COLUMNS_Z[k], side < 0.0)


static func _side_banner(c, x: float, zc: float, field: Color) -> void:
	var hw := 0.17
	var top := SPRING + 0.2
	var bot := 0.15
	var shape := PackedVector2Array([
		Vector2(zc - hw, top), Vector2(zc + hw, top), Vector2(zc + hw, bot),
		Vector2(zc, bot + 0.22), Vector2(zc - hw, bot)])
	var pts := HallBuilder._on_x(shape, x)
	c.poly(pts, field)
	var inset := PackedVector2Array([
		Vector2(zc - hw + 0.04, top - 0.06), Vector2(zc + hw - 0.04, top - 0.06), Vector2(zc + hw - 0.04, bot + 0.06),
		Vector2(zc, bot + 0.26), Vector2(zc - hw + 0.04, bot + 0.06)])
	c.poly_outline(HallBuilder._on_x(inset, x), GHPal.BRASS_DIM)
	var em := _p(x, (top + bot) / 2.0 + 0.2, zc)
	c.px(roundi(em.x), roundi(em.y) - 1, GHPal.BRASS_DIM)
	c.rect(roundi(em.x) - 1, roundi(em.y), 3, 1, GHPal.BRASS_DIM)
	c.px(roundi(em.x), roundi(em.y) + 1, GHPal.BRASS_DIM)
	c.poly_outline(pts, Pal.INK)
	c.linev(_p(x, top + 0.03, zc - hw - 0.05), _p(x, top + 0.03, zc + hw + 0.05), GHPal.BRASS_DIM)


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

	c.ellipse_dither(cx, y_floor, r * 1.9, maxf(2.0, r * 0.35), Pal.INK)
	var pw := roundi(r * 2.7)
	c.rect(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus, GHPal.STONE_LIGHT_NIGHT)
	c.frame(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus + 1, Pal.INK)
	var tw := roundi(r * 2.35)
	c.rect(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft, GHPal.STONE_HI_NIGHT)
	c.frame(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft + 1, Pal.INK)
	c.hline(roundi(cx - tw / 2.0) + 1, roundi(cx + tw / 2.0) - 2, y_torus - 1, GHPal.BRASS_DIM)

	var sw := maxi(4, roundi(r * 2.0))
	var sx0 := roundi(cx - sw / 2.0)
	c.rect(sx0, y_cap, sw, y_shaft - y_cap, GHPal.STONE_LIGHT_NIGHT)
	var band := maxi(1, roundi(sw * 0.3))
	var lit_x := sx0 + sw - band if left else sx0
	var dark_x := sx0 if left else sx0 + sw - band
	c.rect(lit_x, y_cap, band, y_shaft - y_cap, GHPal.STONE_HI_NIGHT)
	c.rect(dark_x, y_cap, band, y_shaft - y_cap, GHPal.STONE_NIGHT)
	var flute := maxi(3, roundi(sw / 5.0))
	for fx in range(sx0 + flute, sx0 + sw - 1, flute):
		c.vline(fx, y_cap + 1, y_shaft - 1, GHPal.STONE_DARK_NIGHT if (fx < lit_x or not left) else GHPal.STONE_NIGHT)
	c.vline(sx0, y_cap, y_shaft, Pal.INK)
	c.vline(sx0 + sw - 1, y_cap, y_shaft, Pal.INK)

	var cw_top := roundi(r * 2.9)
	var cap := PackedVector2Array([
		Vector2(cx - sw / 2.0, y_cap + 0.5), Vector2(cx + sw / 2.0, y_cap + 0.5),
		Vector2(cx + cw_top / 2.0, y_abacus + 0.5), Vector2(cx - cw_top / 2.0, y_abacus + 0.5)])
	c.poly(cap, GHPal.STONE_HI_NIGHT)
	c.poly_outline(cap, Pal.INK)
	c.hline(sx0, sx0 + sw - 1, y_cap, GHPal.BRASS_DIM)
	var aw := roundi(r * 3.1)
	c.rect(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), GHPal.STONE_LIGHT_NIGHT)
	c.frame(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), Pal.INK)
	c.vline(roundi(cx), 0, y_top - 1, GHPal.BRASS_DARK)


# ------------------------------------------------------------ feast layer --

## Returns {"pos": Vector2i, "seed": int} spots for the guttering-candle pass
## drawn by GreatHallLayer (not SpriteForge.flame, so the flicker can be dimmed
## and irregular instead of the day hall's steady three-frame cycle).
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

	var side := HallBuilder._quad_x(c, aisle, fy, ty, z0, z1, GHPal.STONE_LIGHT_NIGHT)
	var z := GRID_Z + ceilf((z0 - GRID_Z) / 0.2) * 0.2
	while z < z1:
		c.linev(_p(aisle, ty - 0.12, z), _p(aisle, fy, z), GHPal.STONE_NIGHT)
		z += 0.2
	HallBuilder._quad_x(c, aisle, ty - 0.13, ty, z0, z1, GHPal.CRIMSON_NIGHT)
	c.linev(_p(aisle, ty - 0.13, z0), _p(aisle, ty - 0.13, z1), GHPal.BRASS_DIM)
	c.poly_outline(side, Pal.INK)
	var end := HallBuilder._quad_z(c, z0, x0, x1, fy, ty, GHPal.STONE_NIGHT)
	HallBuilder._quad_z(c, z0, xc - 0.07, xc + 0.07, ty - 0.18, ty, GHPal.CRIMSON_NIGHT)
	c.poly_outline(end, Pal.INK)
	var top := HallBuilder._quad_y(c, ty, x0, x1, z0, z1, GHPal.STONE_LIGHT_NIGHT)
	HallBuilder._quad_y(c, ty, xc - 0.07, xc + 0.07, z0, z1, GHPal.CRIMSON_NIGHT)
	c.linev(_p(xc - 0.07, ty, z0), _p(xc - 0.07, ty, z1), GHPal.BRASS_DARK)
	c.poly_outline(top, Pal.INK)
	c.linev(_p(outer, ty, z0), _p(outer, ty, z1), Pal.INK)

	# same dish layout as the day hall, but only the candelabra spots matter
	# here: the rest sit dim and half-guessed in the dark (drawn as flat blocks)
	var menu := ["candelabra", "bowl", "goblet", "roast", "grapes", "goblet", "bread", "bowl", "candelabra"]
	for k in menu.size():
		var zz: float = lerpf(z_far - 0.18, -1.55 if left else -1.05, float(k) / (menu.size() - 1))
		if zz < ZN + 0.25:
			continue
		var base := HallCam.project(Vector3(xc + (0.05 if k % 2 == 0 else -0.05), ty, zz))
		var s := base.z
		var bx := roundi(base.x)
		var by := roundi(base.y) + 1
		if menu[k] == "candelabra":
			var cw := maxi(2, roundi(0.1 * s))
			var chh := maxi(4, roundi(0.42 * s))
			c.rect(bx - cw, by - chh, cw * 2, chh, GHPal.STONE_DARK_NIGHT)
			c.rect(bx - cw - 1, by - 2, cw * 2 + 2, 2, GHPal.STONE_NIGHT)
			flames.append({"pos": Vector2i(bx, by - chh), "seed": k})
		else:
			var bw := maxi(2, roundi(0.18 * s))
			var bh := maxi(2, roundi(0.12 * s))
			c.ellipse(bx, by - bh / 2.0, bw, bh, GHPal.STONE_NIGHT)


## Screen rectangles for the two back-wall banners, dimmed fields.
static func back_banners() -> Array:
	var out: Array = []
	var bz := HallCam.BACK_Z
	for spec in [[-1.62, GHPal.CRIMSON_NIGHT, "crown"], [1.62, GHPal.ROYAL_NIGHT, "fly"]]:
		var tl := _p(spec[0] - 0.28, 1.75, bz)
		var br := _p(spec[0] + 0.28, -0.1, bz)
		out.append({"pos": Vector2i(roundi(tl.x), roundi(tl.y)), "w": roundi(br.x - tl.x), "h": roundi(br.y - tl.y),
			"field": spec[1], "emblem": spec[2]})
	return out
