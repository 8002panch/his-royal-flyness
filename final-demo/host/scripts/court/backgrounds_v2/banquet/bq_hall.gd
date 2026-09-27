extends RefCounted

## Banquet v2: the hall shell. paint_far / paint_floor / paint_columns, painted
## through a CanvasPainter every frame so the chase camera can move around it.
## Everything is flat fills + checker dither in the game palette (Pal.*).
## Flame spots come back as Vector3i(x, y, size) for the layer to animate.

const G := preload("res://scripts/court/backgrounds_v2/banquet/bq_geo.gd")
const SP := preload("res://scripts/court/backgrounds_v2/banquet/bq_sprites.gd")

const GLOW := Color("#6E5636")
const GLOW_SOFT := Color("#4A2A12")
const STONE_WARM := Color("#5E4A34")
const FLOOR_C := Color("#5F4F40")
const CRIMSON_DEEP := Color("#7A1616")


# -------------------------------------------------------------- far layer --

static func paint_far(c) -> Array:
	G.ZN = HallCam.near_z()
	var zn: float = G.ZN
	c.rect(0, 0, HallCam.W, HallCam.H, Pal.VAULT)
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var ty := HallCam.TOP_Y
	var out: Array = []

	# ---- the two side walls, seen through the arcade
	for side in [-1.0, 1.0]:
		var x: float = side * wx
		G.quad_x(c, x, fy, ty, zn, bz, Pal.STONE_DARK)
		var row := 0
		var y := fy
		while y < 2.3:
			var y1 := y + 0.3
			c.linev(G.P(x, y1, zn), G.P(x, y1, bz), Pal.STONE_DEEP)
			var z: float = G.grid_start(0.6, 0.3 if row % 2 == 1 else 0.0)
			while z < bz:
				if z + 0.6 > zn:
					var hsh := G.hash(row, roundi((z - G.GRID_Z) / 0.3), int(side))
					if hsh < 0.2:
						G.quad_x(c, x, y + 0.02, y1 - 0.02, maxf(z + 0.02, zn), minf(z + 0.58, bz), Pal.STONE)
					elif hsh > 0.9:
						G.quad_x(c, x, y + 0.02, y1 - 0.02, maxf(z + 0.02, zn), minf(z + 0.58, bz), Pal.STONE_DEEP)
					if z > zn:
						c.linev(G.P(x, y, z), G.P(x, y1, z), Pal.STONE_DEEP)
				z += 0.6
			y = y1
			row += 1
		# a moulded plinth course along the foot of the wall
		G.quad_x(c, x, fy, fy + 0.26, zn, bz, Pal.STONE_DEEP)
		c.linev(G.P(x, fy + 0.26, zn), G.P(x, fy + 0.26, bz), Pal.STONE_LIGHT)
		c.linev(G.P(x, fy + 0.29, zn), G.P(x, fy + 0.29, bz), Pal.STONE_DEEP)
		# a shadow band under the arcade
		c.poly_dither(PackedVector2Array([G.P(x, 1.0, zn), G.P(x, 1.0, bz), G.P(x, 1.7, bz), G.P(x, 1.7, zn)]), Pal.STONE_DEEP)
		for zc in [-1.45, -0.35, 0.75]:
			if zc - 0.3 > zn:
				_lancet(c, x, zc, side)

	# ---- the back wall, block by block
	var tl := G.P(-wx, ty, bz)
	var br := G.P(wx, fy, bz)
	c.rect(roundi(tl.x), roundi(tl.y), roundi(br.x - tl.x), roundi(br.y - tl.y), Pal.STONE)
	var row2 := 0
	var yy := fy
	while yy < 3.0:
		var y1 := yy + 0.28
		var a := G.P(-wx, y1, bz)
		var b := G.P(wx, y1, bz)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y), Pal.STONE_DARK)
		c.hline(roundi(a.x), roundi(b.x) - 1, roundi(a.y) + 1, Pal.STONE_LIGHT)
		var xx := -wx + (0.25 if row2 % 2 == 1 else 0.0)
		while xx < wx:
			var j0 := G.P(xx, yy, bz)
			var j1 := G.P(xx, y1, bz)
			var hsh2 := G.hash(row2, roundi(xx * 4.0), 7)
			if hsh2 < 0.18:
				c.rect(roundi(j0.x) + 1, roundi(j1.y) + 2, roundi(G.P(xx + 0.5, yy, bz).x - j0.x) - 1, roundi(j0.y - j1.y) - 2, Pal.STONE_LIGHT)
			elif hsh2 > 0.86:
				c.rect(roundi(j0.x) + 1, roundi(j1.y) + 2, roundi(G.P(xx + 0.5, yy, bz).x - j0.x) - 1, roundi(j0.y - j1.y) - 2, Pal.STONE_DARK)
			c.vline(roundi(j0.x), roundi(j1.y) + 1, roundi(j0.y), Pal.STONE_DARK)
			xx += 0.5
		yy = y1
		row2 += 1

	_great_arch(c)
	return out


static func _lancet(c, x: float, zc: float, side: float) -> void:
	var half := 0.35
	var gh := 0.29
	var sill := -0.22
	# warm halo on the wall around the lit glass
	var hc := G.P(x, 0.55, zc)
	var s := HallCam.scale_at(zc)
	pass
	var outer := G.arch(zc, half, 1.15, 1.0, 8)
	outer.insert(0, Vector2(zc - half, sill - 0.05))
	outer.append(Vector2(zc + half, sill - 0.05))
	c.poly(G.on_x(outer, x), Pal.STONE_HI)
	c.poly_outline(G.on_x(outer, x), Pal.INK)
	var glass := G.arch(zc, gh, 1.15, 1.0, 8)
	glass.insert(0, Vector2(zc - gh, sill))
	glass.append(Vector2(zc + gh, sill))
	c.poly(G.on_x(glass, x), Pal.GOLD)
	# leaded panes: royal and crimson diamonds' worth of colour, gold between
	var rows := [[sill, 0.25], [0.25, 0.65], [0.65, 1.0], [1.0, 1.15]]
	for r in rows.size():
		for k in 2:
			var z0: float = zc - gh + k * gh
			var z1: float = z0 + gh
			var pick := (r + k) % 2 == 0
			var col: Color = Pal.ROYAL if pick else Pal.GOLD
			if r == 1 and k == 1:
				col = Pal.CRIMSON
			if col != Pal.GOLD:
				G.quad_x(c, x, rows[r][0] + 0.03, rows[r][1] - 0.03, z0 + 0.025, z1 - 0.025, col)
				# a lighter facet on the lit pane corner
				var lp := G.P(x, rows[r][1] - 0.06, z0 + 0.05)
				c.px(roundi(lp.x), roundi(lp.y), Pal.ROYAL_LIGHT if col == Pal.ROYAL else Pal.CRIMSON_LIGHT)
			else:
				var cp := G.P(x, (rows[r][0] + rows[r][1]) * 0.5, (z0 + z1) * 0.5)
				c.px(roundi(cp.x), roundi(cp.y), Pal.GOLD_LIGHT)
	# arch head: gold with a royal roundel
	var rp := G.P(x, 1.36, zc)
	c.ellipse(rp.x, rp.y, 0.06 * s, 0.06 * s, Pal.ROYAL)
	c.px(roundi(rp.x), roundi(rp.y), Pal.GOLD_LIGHT)
	c.linev(G.P(x, sill, zc), G.P(x, 1.5, zc), Pal.INK)
	for v in [0.25, 0.65, 1.0, 1.15]:
		c.linev(G.P(x, v, zc - gh), G.P(x, v, zc + gh), Pal.INK)
	c.poly_outline(G.on_x(glass, x), Pal.INK)
	# stone sill
	G.quad_x(c, x, sill - 0.09, sill - 0.03, zc - half - 0.05, zc + half + 0.05, Pal.STONE_HI)
	c.linev(G.P(x, sill - 0.09, zc - half - 0.05), G.P(x, sill - 0.09, zc + half + 0.05), Pal.INK)


static func _great_arch(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var spring := 0.35
	for spec in [[1.19, Pal.STONE_LIGHT], [1.13, Pal.STONE_HI], [1.08, Pal.GOLD_DARK], [1.04, Pal.INK], [0.99, Pal.GOLD_DARK], [0.91, Pal.GOLD]]:
		var half: float = spec[0]
		var ring := G.arch(0.0, half, spring, 0.8, 14)
		ring.insert(0, Vector2(-half, fy))
		ring.append(Vector2(half, fy))
		c.poly(G.on_z(ring, bz), spec[1])
	var s := HallCam.scale_at(bz)
	# voussoirs: tick marks around the stone ring
	var ring2 := G.arch(0.0, 1.16, spring, 0.8, 14)
	for i in range(1, ring2.size() - 1):
		var a := G.P(ring2[i].x, ring2[i].y, bz)
		var dir := (a - G.P(0, 0.4, bz)).normalized()
		c.linev(a - dir * 2.0, a + dir * 2.0, Pal.STONE_DARK)

	# door glow: dithered light bleeding into the gold niche
	var rc := G.P(0.0, 1.18, bz)
	var rr := 0.42 * s
	c.ellipse_dither(rc.x, rc.y, rr * 1.75, rr * 1.9, Pal.GOLD_LIGHT)
	c.ellipse_dither(rc.x, rc.y, rr * 1.35, rr * 1.45, Pal.GOLD_LIGHT, 1)

	# the great double door, crimson, gold studs and straps
	var dl := G.P(-0.8, 0.42, bz)
	var dr := G.P(0.8, fy, bz)
	var x0 := roundi(dl.x)
	var x1 := roundi(dr.x)
	var y0 := roundi(dl.y)
	var y1 := roundi(dr.y)
	c.rect(x0 - 2, y0 - 3, x1 - x0 + 4, y1 - y0 + 3, Pal.INK)
	c.rect(x0, y0, x1 - x0, y1 - y0, Pal.CRIMSON)
	var plank := maxi(4, roundi(s * 0.16))
	for xp in range(x0 + plank, x1, plank):
		c.vline(xp, y0 + 1, y1 - 1, CRIMSON_DEEP)
		c.vline(xp + 1, y0 + 1, y1 - 1, Pal.CRIMSON_LIGHT)
	c.rect(x0, y0, x1 - x0, 3, Pal.CRIMSON_DARK)
	var mid := (x0 + x1) / 2
	c.vline(mid - 1, y0, y1, Pal.INK)
	c.vline(mid, y0, y1, Pal.GOLD_DARK)
	c.vline(mid + 1, y0, y1, Pal.INK)
	var rowi := 0
	for yst in range(y0 + 8, y1 - 3, 9):
		var off := plank / 2 if rowi % 2 == 1 else 0
		for xs in range(x0 + plank / 2 + off, x1 - 2, plank):
			if absi(xs - mid) < 3:
				continue
			c.px(xs, yst, Pal.GOLD)
			c.px(xs - 1, yst + 1, Pal.GOLD)
			c.px(xs + 1, yst + 1, Pal.GOLD)
			c.px(xs, yst + 2, Pal.GOLD_DARK)
		rowi += 1
	# iron straps
	for f in [0.22, 0.7]:
		var sy := roundi(lerpf(y0, y1, f))
		c.hline(x0, x1 - 1, sy, Pal.INK)
		c.hline(x0, x1 - 1, sy + 1, Pal.GOLD_DARK)
	c.hline(x0 - 2, x1 + 1, y0 - 3, Pal.GOLD)
	# rings on the doors
	c.ellipse(mid - 5, (y0 + y1) * 0.5 + 6, 3, 3, Pal.GOLD)
	c.ellipse(mid + 6, (y0 + y1) * 0.5 + 6, 3, 3, Pal.GOLD)
	c.ellipse(mid - 5, (y0 + y1) * 0.5 + 6, 1.5, 1.5, Pal.INK)
	c.ellipse(mid + 6, (y0 + y1) * 0.5 + 6, 1.5, 1.5, Pal.INK)

	# rose window: stone ring, royal glass, four crimson petals, four small gold
	c.ellipse(rc.x, rc.y, rr + 4, rr + 4, Pal.STONE_HI)
	c.ellipse(rc.x, rc.y, rr + 2, rr + 2, Pal.INK)
	c.ellipse(rc.x, rc.y, rr + 1, rr + 1, Pal.GOLD_DARK)
	c.ellipse(rc.x, rc.y, rr, rr, Pal.ROYAL)
	for i in 4:
		var a := TAU * i / 4.0 - PI / 2.0
		var pc := rc + Vector2(cos(a), sin(a)) * rr * 0.52
		c.poly(PixelCanvas.ellipse_points(pc.x, pc.y, rr * 0.5, rr * 0.2, a, 16), Pal.CRIMSON)
		c.poly(PixelCanvas.ellipse_points(pc.x + cos(a) * rr * 0.06, pc.y + sin(a) * rr * 0.06, rr * 0.26, rr * 0.08, a, 12), Pal.CRIMSON_LIGHT)
	for i in 4:
		var a := TAU * i / 4.0 - PI / 4.0
		var pc := rc + Vector2(cos(a), sin(a)) * rr * 0.55
		c.poly(PixelCanvas.ellipse_points(pc.x, pc.y, rr * 0.2, rr * 0.09, a, 10), Pal.GOLD)
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		c.linev(rc + Vector2(cos(a), sin(a)) * rr * 0.72, rc + Vector2(cos(a), sin(a)) * rr, Pal.INK)
	c.ellipse(rc.x, rc.y, rr * 0.2, rr * 0.2, Pal.GOLD_DARK)
	c.ellipse(rc.x, rc.y, rr * 0.15, rr * 0.15, Pal.GOLD)
	c.px(roundi(rc.x - rr * 0.06), roundi(rc.y - rr * 0.06), Pal.GOLD_LIGHT)


# ------------------------------------------------------------ floor layer --

static func paint_floor(c) -> Array:
	G.ZN = HallCam.near_z()
	var zn: float = G.ZN
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var tile_x := 0.49
	var tile_z := 0.5
	var i := 0
	var x := -wx
	while x < wx - 0.001:
		var z: float = G.grid_start(tile_z)
		while z < bz - 0.001:
			var j := roundi((z - G.GRID_Z) / tile_z)
			var col := Pal.FLOOR_B if (i + j) % 2 == 0 else Pal.FLOOR_A
			var hsh := G.hash(i, j)
			if hsh > 0.9:
				col = FLOOR_C
			elif hsh < 0.1:
				col = Pal.GROUT.lerp(Pal.FLOOR_A, 0.6)
			if z + tile_z > zn:
				G.quad_y(c, fy, x, minf(x + tile_x, wx), maxf(z, zn), minf(z + tile_z, bz), col)
				# hairline cracks and chips on a few tiles
				if hsh > 0.78 and hsh <= 0.9 and z > zn:
					var a := G.P(x + 0.1, fy, z + 0.1)
					c.linev(a, G.P(x + 0.2 + hsh * 0.1, fy, z + 0.22), Pal.GROUT)
					c.linev(G.P(x + 0.2 + hsh * 0.1, fy, z + 0.22), G.P(x + 0.28, fy, z + 0.32), Pal.GROUT)
			z += tile_z
		x += tile_x
		i += 1
	var gz: float = G.grid_start(tile_z) + tile_z
	while gz <= bz:
		c.linev(G.P(-wx, fy, gz), G.P(wx, fy, gz), Pal.GROUT)
		gz += tile_z
	var gx := -wx
	while gx <= wx + 0.001:
		c.linev(G.P(gx, fy, zn), G.P(gx, fy, bz), Pal.GROUT)
		gx += tile_x
	# dithered shade along the walls and under the back wall
	for side in [-1.0, 1.0]:
		var a: float = side * wx
		var b: float = side * (wx - 0.32)
		c.poly_dither(PackedVector2Array([G.P(a, fy, zn), G.P(a, fy, bz), G.P(b, fy, bz), G.P(b, fy, zn)]), Pal.STONE_DEEP)
	c.poly_dither(PackedVector2Array([G.P(-wx, fy, bz - 0.25), G.P(wx, fy, bz - 0.25), G.P(wx, fy, bz), G.P(-wx, fy, bz)]), Pal.STONE_DEEP)

	# shadows pooled under the two tables (footprints match bq_feast.gd)
	for foot in [[1.3, 2.02, -4.0, 1.12], [-2.02, -1.3, -1.55, -0.05]]:
		var f0 := maxf(foot[2], zn)
		if foot[3] > zn:
			c.poly_dither(PackedVector2Array([G.P(foot[0], fy, f0), G.P(foot[1], fy, f0), G.P(foot[1], fy, foot[3]), G.P(foot[0], fy, foot[3])]), Pal.INK)
	# spilled wine and dropped food by the feast (right side only)
	_floor_mess(c, fy, zn)

	_dais(c)
	_carpet(c, fy, zn)
	return []


static func _floor_mess(c, fy: float, zn: float) -> void:
	for spec in [[1.0, -1.5, 0.08, "wine"], [0.9, -0.3, 0.06, "wine"]]:
		if spec[1] < zn + 0.3:
			continue
		var f := G.flat(spec[0], fy, spec[1])
		if f.w < 0.0:
			continue
		var rx: float = spec[2] * f.w
		c.ellipse(f.x, f.y, rx, rx * f.z, SP.WINE)
		c.ellipse_dither(f.x, f.y, rx * 1.4, rx * f.z * 1.4, SP.WINE)
		c.px(roundi(f.x - rx * 0.3), roundi(f.y - 1), Pal.CRIMSON_LIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for k in 26:
		var xx := rng.randf_range(0.95, 1.28)
		var zz := rng.randf_range(maxf(-3.0, zn), 1.0)
		var f := G.flat(xx, fy, zz)
		if f.w < 0.0:
			continue
		var pick := k % 4
		var col: Color = [Pal.PARCHMENT_DARK, Pal.AMBER_DARK, Pal.CRIMSON, Pal.PARCHMENT_SHADE][pick]
		c.px(roundi(f.x), roundi(f.y), col)
		if pick == 0 and f.w > 0.0 and f.x > 0:
			c.px(roundi(f.x) + 1, roundi(f.y), col)


static func _carpet(c, fy: float, zn: float) -> void:
	var h := G.CARPET_HALF
	G.quad_y(c, fy, -h, h, zn, G.DAIS_FRONT, Pal.CRIMSON)
	# wear and weave: a darker dithered runnel down each side, soft pile in the middle
	for side in [-1.0, 1.0]:
		c.poly_dither(PackedVector2Array([G.P(side * (h - 0.02), fy, zn), G.P(side * (h - 0.02), fy, G.DAIS_FRONT),
			G.P(side * (h - 0.14), fy, G.DAIS_FRONT), G.P(side * (h - 0.14), fy, zn)]), CRIMSON_DEEP)
	var dz: float = G.grid_start(0.5) + 0.5
	while dz < G.DAIS_FRONT - 0.2:
		if dz - 0.1 > zn:
			c.poly(PackedVector2Array([G.P(0, fy, dz - 0.1), G.P(0.1, fy, dz), G.P(0, fy, dz + 0.1), G.P(-0.1, fy, dz)]), Pal.GOLD)
			c.px(roundi(G.P(0, fy, dz).x), roundi(G.P(0, fy, dz).y), Pal.GOLD_LIGHT)
			for sx in [-0.26, 0.26]:
				var q := G.P(sx, fy, dz)
				c.px(roundi(q.x), roundi(q.y), Pal.GOLD_DARK)
		dz += 0.5
	for side in [-1.0, 1.0]:
		c.linev(G.P(side * (h - 0.07), fy, zn), G.P(side * (h - 0.07), fy, G.DAIS_FRONT), Pal.GOLD)
		c.linev(G.P(side * (h - 0.1), fy, zn), G.P(side * (h - 0.1), fy, G.DAIS_FRONT), Pal.GOLD_DARK)
		c.linev(G.P(side * h, fy, zn), G.P(side * h, fy, G.DAIS_FRONT), Pal.INK)
	# up the steps
	G.quad_z(c, G.DAIS_FRONT, -h, h, fy, G.DAIS_Y1, Pal.CRIMSON_DARK)
	G.quad_y(c, G.DAIS_Y1, -h, h, G.DAIS_FRONT, G.DAIS_STEP, Pal.CRIMSON)
	G.quad_z(c, G.DAIS_STEP, -h, h, G.DAIS_Y1, G.DAIS_Y2, Pal.CRIMSON_DARK)
	G.quad_y(c, G.DAIS_Y2, -h, h, G.DAIS_STEP, 1.15, Pal.CRIMSON)
	c.linev(G.P(-h, G.DAIS_Y2, 1.15), G.P(h, G.DAIS_Y2, 1.15), Pal.GOLD)
	for side in [-1.0, 1.0]:
		c.linev(G.P(side * h, G.DAIS_Y2, G.DAIS_STEP), G.P(side * h, G.DAIS_Y2, 1.15), Pal.GOLD)
		c.linev(G.P(side * h, G.DAIS_Y1, G.DAIS_FRONT), G.P(side * h, G.DAIS_Y1, G.DAIS_STEP), Pal.GOLD)


static func _dais(c) -> void:
	var fy := HallCam.FLOOR_Y
	var bz := HallCam.BACK_Z
	var x := G.DAIS_X
	G.quad_y(c, G.DAIS_Y2, -x, x, G.DAIS_STEP, bz, Pal.ROYAL)
	G.quad_z(c, G.DAIS_STEP, -x, x, G.DAIS_Y1, G.DAIS_Y2, Pal.ROYAL_DARK)
	G.quad_y(c, G.DAIS_Y1, -x, x, G.DAIS_FRONT, G.DAIS_STEP, Pal.ROYAL)
	G.quad_z(c, G.DAIS_FRONT, -x, x, fy, G.DAIS_Y1, Pal.ROYAL_DARK)
	# shade where the back wall falls across the dais, and a lit hem on each tread
	c.poly_dither(PackedVector2Array([G.P(-x, G.DAIS_Y2, bz - 0.3), G.P(x, G.DAIS_Y2, bz - 0.3), G.P(x, G.DAIS_Y2, bz), G.P(-x, G.DAIS_Y2, bz)]), Pal.ROYAL_DARK)
	c.poly_dither(PackedVector2Array([G.P(-x, G.DAIS_Y2, G.DAIS_STEP), G.P(x, G.DAIS_Y2, G.DAIS_STEP), G.P(x, G.DAIS_Y2, G.DAIS_STEP + 0.12), G.P(-x, G.DAIS_Y2, G.DAIS_STEP + 0.12)]), Pal.ROYAL_LIGHT)
	c.poly_dither(PackedVector2Array([G.P(-x, G.DAIS_Y1, G.DAIS_FRONT), G.P(x, G.DAIS_Y1, G.DAIS_FRONT), G.P(x, G.DAIS_Y1, G.DAIS_FRONT + 0.1), G.P(-x, G.DAIS_Y1, G.DAIS_FRONT + 0.1)]), Pal.ROYAL_LIGHT)
	# gold nosing (two rows) on each step, ink where each step meets the one below
	for spec in [[G.DAIS_Y2, G.DAIS_STEP], [G.DAIS_Y1, G.DAIS_FRONT]]:
		var ny: float = spec[0]
		var nz: float = spec[1]
		c.linev(G.P(-x, ny, nz), G.P(x, ny, nz), Pal.GOLD_LIGHT)
		c.linev(G.P(-x, ny - 0.03, nz), G.P(x, ny - 0.03, nz), Pal.GOLD)
		c.linev(G.P(-x, ny - 0.06, nz), G.P(x, ny - 0.06, nz), Pal.GOLD_DARK)
	c.linev(G.P(-x, G.DAIS_Y1, G.DAIS_STEP), G.P(x, G.DAIS_Y1, G.DAIS_STEP), Pal.INK)
	c.linev(G.P(-x, fy, G.DAIS_FRONT), G.P(x, fy, G.DAIS_FRONT), Pal.INK)
	# inlaid gold border and fleur studs along the top step
	var bi := 0.18
	c.poly_outline(PackedVector2Array([G.P(-x + bi, G.DAIS_Y2, G.DAIS_STEP + bi), G.P(x - bi, G.DAIS_Y2, G.DAIS_STEP + bi),
		G.P(x - bi, G.DAIS_Y2, bz - bi), G.P(-x + bi, G.DAIS_Y2, bz - bi)]), Pal.GOLD_DARK)
	var xx := -x + 0.3
	while xx < x - 0.2:
		var p := G.P(xx, G.DAIS_Y2, G.DAIS_STEP + bi)
		c.px(roundi(p.x), roundi(p.y), Pal.GOLD)
		c.px(roundi(p.x), roundi(p.y) - 1, Pal.GOLD_LIGHT)
		xx += 0.3
	for side in [-1.0, 1.0]:
		c.linev(G.P(side * x, fy, G.DAIS_FRONT), G.P(side * x, G.DAIS_Y1, G.DAIS_FRONT), Pal.INK)
		c.linev(G.P(side * x, G.DAIS_Y1, G.DAIS_STEP), G.P(side * x, G.DAIS_Y2, G.DAIS_STEP), Pal.INK)
		c.linev(G.P(side * x, G.DAIS_Y1, G.DAIS_FRONT), G.P(side * x, G.DAIS_Y1, G.DAIS_STEP), Pal.INK)
		c.linev(G.P(side * x, G.DAIS_Y2, G.DAIS_STEP), G.P(side * x, G.DAIS_Y2, bz), Pal.INK)


# ---------------------------------------------------------- columns layer --

static func paint_columns(c) -> Array:
	G.ZN = HallCam.near_z()
	var zn: float = G.ZN
	var bz := HallCam.BACK_Z
	var ty := HallCam.TOP_Y
	var flames: Array = []
	for side in [-1.0, 1.0]:
		var x: float = side * HallCam.COLUMN_X
		var bays: Array = [[zn, G.COLUMNS_Z[0]]]
		for k in range(G.COLUMNS_Z.size() - 1):
			bays.append([G.COLUMNS_Z[k], G.COLUMNS_Z[k + 1]])
		bays.append([G.COLUMNS_Z[G.COLUMNS_Z.size() - 1], bz])
		for k in bays.size():
			var z0: float = bays[k][0]
			var z1: float = bays[k][1]
			if z1 <= zn:
				continue
			if k == 0 or z0 < zn:
				G.quad_x(c, x, G.SPRING, ty, maxf(z0, zn), z1, Pal.STONE)
				_courses(c, x, G.SPRING, ty, maxf(z0, zn), z1, k)
				continue
			var half := (z1 - z0) / 2.0 - G.COLUMN_R
			var arch := G.arch((z0 + z1) / 2.0, half, G.SPRING, 0.75, 10)
			var wall := PackedVector2Array([Vector2(z0, G.SPRING)])
			wall.append_array(arch)
			wall.append_array(PackedVector2Array([Vector2(z1, G.SPRING), Vector2(z1, ty), Vector2(z0, ty)]))
			c.poly(G.on_x(wall, x), Pal.STONE)
			var apex: float = G.arch_apex(half, G.SPRING, 0.75)
			_courses(c, x, apex + 0.04, ty, z0, z1, k)
			var edge := G.on_x(arch, x)
			for n in range(edge.size() - 1):
				c.linev(edge[n], edge[n + 1], Pal.INK)
				c.linev(edge[n] + Vector2(0, -1), edge[n + 1] + Vector2(0, -1), Pal.GOLD_DARK)
				c.linev(edge[n] + Vector2(0, 1), edge[n + 1] + Vector2(0, 1), Pal.STONE_DEEP)
			# voussoir ticks and a gold boss at the crown
			var ctr := G.P(x, G.SPRING + 0.1, (z0 + z1) / 2.0)
			for n in range(1, edge.size() - 1, 2):
				var dir := (edge[n] - ctr).normalized()
				c.linev(edge[n] + dir * 1.0, edge[n] + dir * 4.0, Pal.STONE_DARK)
			var boss := G.P(x, apex + 0.06, (z0 + z1) / 2.0)
			c.ellipse(boss.x, boss.y, 2.5, 2.5, Pal.GOLD_DARK)
			c.px(roundi(boss.x), roundi(boss.y) - 1, Pal.GOLD_LIGHT)
			if k < bays.size() - 1:
				var idx := k + (1 if side > 0 else 0)
				var kinds := ["crown", "star", "heart", "fleur"]
				_side_banner(c, x, (z0 + z1) / 2.0, Pal.CRIMSON if idx % 2 == 0 else Pal.ROYAL, kinds[(k + (2 if side > 0 else 0)) % 4], apex)

		for k in range(G.COLUMNS_Z.size() - 1, -1, -1):
			if G.COLUMNS_Z[k] - G.COLUMN_R > zn + 0.2:
				_column(c, x, G.COLUMNS_Z[k], side < 0.0, flames)
	return flames


## Mortar courses on the flat spandrel wall above the arches.
static func _courses(c, x: float, y_lo: float, y_hi: float, z0: float, z1: float, seed: int) -> void:
	var y := y_lo
	var row := 0
	while y < y_hi:
		var y1 := minf(y + 0.32, y_hi)
		c.linev(G.P(x, y1, z0), G.P(x, y1, z1), Pal.STONE_DARK)
		var z := z0 + (0.35 if row % 2 == 1 else 0.0)
		while z < z1:
			c.linev(G.P(x, y, z), G.P(x, y1, z), Pal.STONE_DARK)
			z += 0.7
		y = y1
		row += 1


static func _side_banner(c, x: float, zc: float, field: Color, kind: String, apex: float) -> void:
	var hw := 0.17
	var top := apex + 0.12
	var bot := 0.05
	var sway := 0.02 * sin(Time.get_ticks_msec() / 900.0 + zc * 3.0)
	var dark := Pal.CRIMSON_DARK if field == Pal.CRIMSON else Pal.ROYAL_DARK
	var light := Pal.CRIMSON_LIGHT if field == Pal.CRIMSON else Pal.ROYAL_LIGHT
	var shape := PackedVector2Array([
		Vector2(zc - hw, top), Vector2(zc + hw, top), Vector2(zc + hw + sway * 0.6, bot),
		Vector2(zc + sway, bot + 0.24), Vector2(zc - hw + sway * 0.6, bot)])
	var pts := G.on_x(shape, x)
	c.poly(pts, field)
	# a shaded fold and a lit fold
	c.linev(G.P(x, top - 0.05, zc - hw * 0.45), G.P(x, bot + 0.06, zc - hw * 0.45 + sway * 0.6), light)
	c.linev(G.P(x, top - 0.05, zc + hw * 0.4), G.P(x, bot + 0.1, zc + hw * 0.4 + sway * 0.6), dark)
	var inset := PackedVector2Array([
		Vector2(zc - hw + 0.035, top - 0.05), Vector2(zc + hw - 0.035, top - 0.05), Vector2(zc + hw - 0.035 + sway * 0.6, bot + 0.05),
		Vector2(zc + sway, bot + 0.27), Vector2(zc - hw + 0.035 + sway * 0.6, bot + 0.05)])
	c.poly_outline(G.on_x(inset, x), Pal.GOLD)
	var em: PixelCanvas = SP.emblem(kind)
	var ep := G.P(x, (top + bot) * 0.5 + 0.22, zc)
	c.blit(em, roundi(ep.x) - em.w / 2, roundi(ep.y) - em.h / 2)
	c.poly_outline(pts, Pal.INK)
	c.rect(roundi(G.P(x, top + 0.03, zc - hw - 0.05).x), roundi(G.P(x, top + 0.03, zc).y) - 1,
		roundi(G.P(x, top, zc + hw + 0.05).x - G.P(x, top, zc - hw - 0.05).x), 2, Pal.GOLD)


static func _column(c, x: float, z: float, left: bool, flames: Array) -> void:
	var fy := HallCam.FLOOR_Y
	var s := HallCam.scale_at(z)
	var cx := G.P(x, 0.0, z).x
	var y_floor := roundi(G.P(x, fy, z).y)
	var y_torus := roundi(G.P(x, fy + 0.16, z).y)
	var y_shaft := roundi(G.P(x, fy + 0.24, z).y)
	var y_cap := roundi(G.P(x, G.SPRING - 0.2, z).y)
	var y_abacus := roundi(G.P(x, G.SPRING - 0.05, z).y)
	var y_top := roundi(G.P(x, G.SPRING + 0.03, z).y)
	var r := G.COLUMN_R * s

	c.ellipse_dither(cx, y_floor, r * 2.1, maxf(2.0, r * 0.4), Pal.INK)
	# plinth: two stone blocks with a joint
	var pw := roundi(r * 2.8)
	var px0 := roundi(cx - pw / 2.0)
	c.rect(px0, y_torus, pw, y_floor - y_torus + 1, Pal.STONE_LIGHT)
	c.hline(px0, px0 + pw - 1, y_torus + 1, Pal.STONE_HI)
	c.hline(px0, px0 + pw - 1, (y_torus + y_floor) / 2, Pal.STONE)
	c.vline(px0 + pw / 2, y_torus, (y_torus + y_floor) / 2, Pal.STONE)
	c.rect(px0 + pw - maxi(2, pw / 6), y_torus, maxi(2, pw / 6), y_floor - y_torus + 1, Pal.STONE)
	c.frame(px0, y_torus, pw, y_floor - y_torus + 1, Pal.INK)
	var tw := roundi(r * 2.35)
	c.rect(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft, Pal.STONE_HI)
	c.frame(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft + 1, Pal.INK)
	c.hline(roundi(cx - tw / 2.0) + 1, roundi(cx + tw / 2.0) - 2, y_torus - 1, Pal.GOLD_DARK)

	# shaft: base tone, lit band facing the hall's middle, shaded band, dither, flutes
	var sw := maxi(4, roundi(r * 2.0))
	var sx0 := roundi(cx - sw / 2.0)
	c.rect(sx0, y_cap, sw, y_shaft - y_cap, Pal.STONE_LIGHT)
	var band := maxi(1, roundi(sw * 0.3))
	var lit_x := sx0 + sw - band if left else sx0
	var dark_x := sx0 if left else sx0 + sw - band
	c.rect(lit_x, y_cap, band, y_shaft - y_cap, Pal.STONE_HI)
	c.rect(dark_x, y_cap, band, y_shaft - y_cap, Pal.STONE)
	c.poly_dither(PackedVector2Array([Vector2(dark_x, y_cap), Vector2(dark_x + maxi(2, band / 2) + (band if false else 0), y_cap),
		Vector2(dark_x + maxi(2, band / 2), y_shaft), Vector2(dark_x, y_shaft)]), Pal.STONE_DARK)
	var flute := maxi(3, roundi(sw / 5.0))
	for fx in range(sx0 + flute, sx0 + sw - 1, flute):
		c.vline(fx, y_cap + 1, y_shaft - 1, Pal.STONE_DARK if (fx < lit_x or not left) else Pal.STONE)
	c.vline(sx0, y_cap, y_shaft, Pal.INK)
	c.vline(sx0 + sw - 1, y_cap, y_shaft, Pal.INK)

	# capital: flared bell, gold band, abacus block
	var cw_top := roundi(r * 2.9)
	var cap := PackedVector2Array([
		Vector2(cx - sw / 2.0, y_cap + 0.5), Vector2(cx + sw / 2.0, y_cap + 0.5),
		Vector2(cx + cw_top / 2.0, y_abacus + 0.5), Vector2(cx - cw_top / 2.0, y_abacus + 0.5)])
	c.poly(cap, Pal.STONE_HI)
	c.poly_outline(cap, Pal.INK)
	c.hline(sx0, sx0 + sw - 1, y_cap, Pal.GOLD)
	c.hline(sx0, sx0 + sw - 1, y_cap + 1, Pal.GOLD_DARK)
	var aw := roundi(r * 3.2)
	c.rect(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), Pal.STONE_LIGHT)
	c.hline(roundi(cx - aw / 2.0), roundi(cx + aw / 2.0) - 1, y_top, Pal.STONE_HI)
	c.frame(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), Pal.INK)
	c.hline(roundi(cx - aw / 2.0) + 1, roundi(cx + aw / 2.0) - 2, y_abacus, Pal.GOLD_DARK)
	c.vline(roundi(cx) - 1, 0, y_top - 1, Pal.STONE)
	c.vline(roundi(cx), 0, y_top - 1, Pal.STONE_HI)
	c.vline(roundi(cx) + 1, 0, y_top - 1, Pal.STONE_DARK)

	# a wall torch on the lit face, with its glow dithered onto the stone
	if z - G.ZN > 0.5:
		var th := clampi(roundi(0.34 * s), 10, 36)
		var td: Dictionary = SP.torch(th)
		var tc: PixelCanvas = td["canvas"]
		var tx := (lit_x + (band if left else 0)) if left else lit_x
		var ty2 := roundi(G.P(x, 0.28, z).y)
		var ox := (sx0 + sw) if left else (sx0 - tc.w)
		var oy := ty2 - tc.h
		var glow_x := float(ox + tc.w / 2)
		var gr := minf(0.22 * s, 18.0)
		c.ellipse_dither(glow_x, oy + 2, gr, gr * 0.9, GLOW)
		c.ellipse(glow_x, oy + 3, gr * 0.45, gr * 0.4, GLOW)
		c.blit(tc, ox, oy)
		var f: Vector2i = td["flame"]
		flames.append(Vector3i(ox + f.x, oy + f.y, 1))

