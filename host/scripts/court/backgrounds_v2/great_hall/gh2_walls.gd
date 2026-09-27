extends RefCounted

## Great Hall v2, far layer: the two side walls with moon-lit lancets and the
## back wall with the pointed great arch, rose window and the studded double
## door (as in the concept art). All geometry goes through HallCam so the chase
## camera can move; grids are anchored in hall space.

const K := preload("gh2_pal.gd")
const P := preload("gh2_paint.gd")

const SPRING := 0.35
const LANCETS := [-1.45, -0.35, 0.75]
const DOOR_HALF := 0.66
const DOOR_TOP := 0.62


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func paint(c) -> void:
	var zn := HallCam.near_z()
	HallBuilder.ZN = zn
	var t0 := Time.get_ticks_usec()
	c.rect(0, 0, HallCam.W, HallCam.H, K.VOID)
	for side in [-1.0, 1.0]:
		_side_wall(c, side, zn)
	t0 = P.lap("w_side", t0)
	_back_wall(c)
	t0 = P.lap("w_back", t0)
	_great_arch(c)
	t0 = P.lap("w_arch", t0)
	_door(c)
	t0 = P.lap("w_door", t0)
	_rose(c)
	t0 = P.lap("w_rose", t0)


# ------------------------------------------------------------- side walls --

static func _side_wall(c, side: float, zn: float) -> void:
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var ty := HallCam.TOP_Y
	var x := side * wx
	HallBuilder._quad_x(c, x, fy, ty, zn, bz, K.WALL)
	var row := 0
	var y := fy
	while y < ty:
		var y1 := y + 0.3
		var a := _p(x, y, zn)
		var b := _p(x, y, bz)
		var a2 := _p(x, y1, zn)
		var b2 := _p(x, y1, bz)
		if maxf(a.y, b.y) < -4.0 or minf(a2.y, b2.y) > HallCam.H + 4:
			y = y1
			row += 1
			continue
		var z := HallBuilder._grid_start(0.6, 0.3 if row % 2 == 1 else 0.0)
		while z < bz:
			var z0 := maxf(z, zn)
			var z1 := minf(z + 0.6, bz)
			if z1 > z0 + 0.01:
				var hv := P.hash2(roundi((z - HallBuilder.GRID_Z) / 0.3), row, 3 + int(side))
				if hv < 0.2:
					HallBuilder._quad_x(c, x, y, y1, z0, z1, K.DARK)
				elif hv > 0.8:
					HallBuilder._quad_x(c, x, y, y1, z0, z1, K.MID)
			z += 0.6
		c.linev(_p(x, y1, zn), _p(x, y1, bz), K.DEEP)
		z = HallBuilder._grid_start(0.6, 0.3 if row % 2 == 1 else 0.0)
		while z < bz:
			if z >= zn:
				c.linev(_p(x, y, z), _p(x, y1, z), K.DEEP)
			z += 0.6
		y = y1
		row += 1

	# plinth and string course
	HallBuilder._quad_x(c, x, fy, fy + 0.26, zn, bz, K.DARK)
	c.linev(_p(x, fy + 0.26, zn), _p(x, fy + 0.26, bz), K.STONE)
	HallBuilder._quad_x(c, x, -0.66, -0.58, zn, bz, K.LIT)
	c.linev(_p(x, -0.66, zn), _p(x, -0.66, bz), K.DEEP)
	c.linev(_p(x, -0.58, zn), _p(x, -0.58, bz), K.HI)

	var tl0 := Time.get_ticks_usec()
	var t := P.now()
	for k in LANCETS.size():
		var zc: float = LANCETS[k]
		if zc - 0.45 > zn:
			_lancet(c, x, zc, k, side, t)
			# damp streaks running down from the sill
			var w0 := zc + 0.02
			P.dither(c, PackedVector2Array([_p(x, -0.28, w0 - 0.07), _p(x, -0.28, w0 + 0.07), _p(x, fy + 0.3, w0 + 0.12), _p(x, fy + 0.3, w0 - 0.1)]), K.DEEP, 1)
	_cracks(c, x, side, zn)


static func _cracks(c, x: float, side: float, zn: float) -> void:
	for i in 5:
		var z0 := -1.9 + P.hash2(i, 7, int(side) + 5) * 3.6
		if z0 < zn + 0.3:
			continue
		var y0 := -0.4 + P.hash2(i, 9, int(side) + 5) * 2.3
		var pts: Array = [Vector2(z0, y0)]
		for s in 4:
			var pz: float = pts[s].x + (P.hash2(i, s, 11) - 0.5) * 0.14
			var py: float = pts[s].y - 0.1 - P.hash2(i, s, 13) * 0.12
			pts.append(Vector2(pz, py))
		for s in 4:
			c.linev(_p(x, pts[s].y, pts[s].x), _p(x, pts[s + 1].y, pts[s + 1].x), K.DEEP)


static func _lancet(c, x: float, zc: float, k: int, side: float, t: float) -> void:
	var sp := 1.15
	# cold glow spilling onto the wall around the pane
	var glow := HallBuilder._arch(zc, 0.42, sp + 0.03, 1.0, 8)
	glow.insert(0, Vector2(zc - 0.42, -0.4))
	glow.append(Vector2(zc + 0.42, -0.4))
	P.dither(c, HallBuilder._on_x(glow, x), K.GLASS_D, 1)
	var outer := HallBuilder._arch(zc, 0.29, sp, 1.0, 8)
	outer.insert(0, Vector2(zc - 0.29, -0.26))
	outer.append(Vector2(zc + 0.29, -0.26))
	c.poly(HallBuilder._on_x(outer, x), K.LIT)
	c.poly_outline(HallBuilder._on_x(outer, x), K.STONE)
	var g_uv := HallBuilder._arch(zc, 0.22, sp, 1.0, 8)
	g_uv.insert(0, Vector2(zc - 0.22, -0.18))
	g_uv.append(Vector2(zc + 0.22, -0.18))
	var gp := HallBuilder._on_x(g_uv, x)
	c.poly(gp, K.GLASS_D)
	# sky in flat bands, joined by dither
	var u0 := zc - 1.0
	var u1 := zc + 1.0
	c.poly(HallBuilder._on_x(P.clip_box(g_uv, u0, u1, 0.4, 0.85), x), K.GLASS)
	P.dither(c, HallBuilder._on_x(P.clip_box(g_uv, u0, u1, 0.85, 1.0), x), K.GLASS, 2)
	c.poly(HallBuilder._on_x(P.clip_box(g_uv, u0, u1, -0.2, 0.15), x), K.GLASS_M)
	P.dither(c, HallBuilder._on_x(P.clip_box(g_uv, u0, u1, 0.15, 0.4), x), K.GLASS_M, 2)
	# a few brighter panes, and the moon in one window per wall
	for r in 6:
		for col in 3:
			if P.hash2(col + k * 3, r, 21 + int(side)) > 0.8:
				var pu := zc - 0.22 + col * 0.147
				var pv := -0.18 + r * 0.166
				c.poly(HallBuilder._on_x(PackedVector2Array([Vector2(pu, pv), Vector2(pu + 0.147, pv), Vector2(pu + 0.147, pv + 0.166), Vector2(pu, pv + 0.166)]), x), K.GLASS_M)
	if k == (1 if side < 0.0 else 0):
		var mp := PixelCanvas.ellipse_points(zc + 0.02, 0.62, 0.075, 0.075, 0.0, 14)
		c.poly(HallBuilder._on_x(mp, x), K.PALE)
		P.dither(c, HallBuilder._on_x(PixelCanvas.ellipse_points(zc + 0.02, 0.62, 0.13, 0.13, 0.0, 16), x), K.GLASS_L, 1)
	# leading
	for u in [-0.073, 0.073]:
		c.linev(_p(x, -0.18, zc + u), _p(x, sp, zc + u), K.TRACE)
	for v in [0.1, 0.27, 0.44, 0.61, 0.78, 0.95, 1.12]:
		c.linev(_p(x, v, zc - 0.22), _p(x, v, zc + 0.22), K.TRACE)
	c.linev(_p(x, sp, zc), _p(x, sp + 0.34, zc), K.TRACE)
	c.poly_outline(gp, K.INK)
	c.linev(_p(x, -0.26, zc - 0.34), _p(x, -0.26, zc + 0.34), K.HI)
	c.linev(_p(x, -0.28, zc - 0.34), _p(x, -0.28, zc + 0.34), K.DEEP)


# -------------------------------------------------------------- back wall --

static func _back_wall(c) -> void:
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	var ty := HallCam.TOP_Y
	var tl := _p(-wx, ty, bz)
	var br := _p(wx, fy, bz)
	c.rect(roundi(tl.x), roundi(tl.y), roundi(br.x - tl.x), roundi(br.y - tl.y), K.STONE)
	var row := 0
	var yy := fy
	while yy < ty:
		var y1 := yy + 0.28
		var a := _p(-wx, y1, bz)
		var b := _p(wx, yy, bz)
		if a.y > HallCam.H + 2 or b.y < -2:
			yy = y1
			row += 1
			continue
		var xx := -wx + (0.25 if row % 2 == 1 else 0.0)
		var ytop := roundi(a.y)
		var ybot := roundi(b.y)
		while xx < wx:
			var xa := roundi(_p(xx, yy, bz).x)
			var xb := roundi(_p(minf(xx + 0.5, wx), yy, bz).x)
			var hv := P.hash2(roundi(xx * 8.0), row, 5)
			var col := K.STONE
			if hv < 0.25:
				col = K.WALL
			elif hv < 0.42:
				col = K.MID
			elif hv > 0.86:
				col = K.LIT
			if col != K.STONE:
				c.rect(xa, ytop, xb - xa, ybot - ytop, col)
			# chips and pits
			var hv2 := P.hash2(roundi(xx * 8.0), row, 8)
			if hv2 > 0.55:
				c.px(xa + 2 + int(hv2 * 10.0) % maxi(3, xb - xa - 4), ytop + 2 + int(hv * 9.0) % maxi(2, ybot - ytop - 3), K.DARK if hv2 > 0.8 else K.LIT)
			c.vline(xa, ytop, ybot, K.DEEP)
			xx += 0.5
		c.hline(roundi(_p(-wx, yy, bz).x), roundi(_p(wx, yy, bz).x), ybot, K.DEEP)
		c.hline(roundi(_p(-wx, yy, bz).x), roundi(_p(wx, yy, bz).x), ybot - 1, K.LIT if row > 0 else K.DARK)
		yy = y1
		row += 1
	# skirting: the bottom course is darker
	var sk := _p(-wx, fy + 0.28, bz)
	P.dither(c, PackedVector2Array([Vector2(tl.x, sk.y), Vector2(br.x, sk.y), Vector2(br.x, br.y), Vector2(tl.x, br.y)]), K.DEEP, 2)


static func _great_arch(c) -> void:
	var bz := HallCam.BACK_Z
	var fy := HallCam.FLOOR_Y
	for spec in [[1.22, K.MID], [1.15, K.HI], [1.09, K.INK], [1.05, K.LIT], [0.96, K.DARK]]:
		var half: float = spec[0]
		var ring := HallBuilder._arch(0.0, half, SPRING, 0.8, 14)
		ring.insert(0, Vector2(-half, fy))
		ring.append(Vector2(half, fy))
		c.poly(HallBuilder._on_z(ring, bz), spec[1])
	# voussoir joints and the keystone
	var oa := HallBuilder._arch(0.0, 1.15, SPRING, 0.8, 14)
	var ob := HallBuilder._arch(0.0, 0.96, SPRING, 0.8, 14)
	for i in range(1, oa.size() - 1, 2):
		c.linev(_p(oa[i].x, oa[i].y, bz), _p(ob[i].x, ob[i].y, bz), K.DEEP)
	var apex := oa[oa.size() / 2]
	var ap := _p(apex.x, apex.y, bz)
	c.rect(roundi(ap.x) - 3, roundi(ap.y) - 1, 7, 6, K.HI)
	c.frame(roundi(ap.x) - 3, roundi(ap.y) - 1, 7, 6, K.INK)
	c.px(roundi(ap.x), roundi(ap.y) + 1, K.BR_L)
	# the recess is lit only by the rose window: dither rings, dark towards the base
	var rc := _p(0.0, 1.22, bz)
	var s := HallCam.scale_at(bz)
	P.dither_ellipse(c, rc.x, rc.y, 0.86 * s, 0.9 * s, K.MID, 1)
	P.dither_ellipse(c, rc.x, rc.y, 0.6 * s, 0.62 * s, K.MID, 2)


static func _door(c) -> void:
	var bz := HallCam.BACK_Z
	var dbot := HallBuilder.DAIS_Y2
	var tl := _p(-DOOR_HALF, DOOR_TOP, bz)
	var br := _p(DOOR_HALF, dbot, bz)
	var x0 := roundi(tl.x)
	var x1 := roundi(br.x)
	var y0 := roundi(tl.y)
	var y1 := roundi(br.y)
	var w := x1 - x0
	var h := y1 - y0
	var s := HallCam.scale_at(bz)
	# stone door frame with lintel and corbels
	var fw := maxi(3, roundi(0.09 * s))
	c.rect(x0 - fw, y0 - fw - 2, w + fw * 2, h + fw + 2, K.LIT)
	c.rect(x0 - fw, y0 - fw - 2, w + fw * 2, 2, K.HI)
	c.frame(x0 - fw, y0 - fw - 2, w + fw * 2, h + fw + 2, K.INK)
	c.rect(x0 - fw - 2, y0 - fw - 5, w + fw * 2 + 4, 3, K.HI)
	c.frame(x0 - fw - 2, y0 - fw - 5, w + fw * 2 + 4, 3, K.INK)
	# door leaves: vertical planks, alternating tones
	c.rect(x0, y0, w, h, K.W_D)
	var planks := 12
	for i in planks:
		var px0 := x0 + int(float(i) * w / planks)
		var px1 := x0 + int(float(i + 1) * w / planks)
		c.rect(px0, y0, px1 - px0, h, K.W if i % 2 == 0 else K.W_D)
		c.vline(px0, y0, y1 - 1, K.IR)
		# wood grain flecks
		for g in 3:
			var gy := y0 + 4 + int(P.hash2(i, g, 31) * (h - 10))
			c.px(px0 + 2, gy, K.W_L)
			c.px(px0 + 2, gy + 1, K.W_L)
	# iron straps with brass studs
	for fr in [0.16, 0.5, 0.84]:
		var sy := y0 + roundi(h * fr)
		var sh := maxi(3, roundi(0.06 * s))
		c.rect(x0, sy - sh / 2, w, sh, K.IR)
		c.hline(x0, x1 - 1, sy - sh / 2, K.IR_L)
		var sx := x0 + 3
		while sx < x1 - 2:
			c.px(sx, sy, K.BR_L)
			c.px(sx, sy + 1, K.BR_D)
			sx += 5
	# stud grid on the planks between the straps
	for r in 3:
		var ry := y0 + roundi(h * (0.26 + r * 0.19))
		var sx2 := x0 + 6
		while sx2 < x1 - 3:
			if absi(sx2 - (x0 + w / 2)) > 3:
				c.px(sx2, ry, K.BR)
			sx2 += 7
	# centre seam, ring pulls, the crown plaque
	var cx := x0 + w / 2
	c.vline(cx - 1, y0, y1 - 1, K.IR)
	c.vline(cx, y0, y1 - 1, K.DEEP)
	c.vline(cx + 1, y0, y1 - 1, K.IR)
	for sgn in [-1, 1]:
		var rx: int = cx + sgn * roundi(0.09 * s)
		var ry2 := y0 + roundi(h * 0.55)
		c.ellipse(rx, ry2, 3.0, 3.0, K.BR)
		c.ellipse(rx, ry2, 1.5, 1.5, K.W_D)
		c.px(rx - 2, ry2 - 2, K.BR_L)
	var py := y0 + roundi(h * 0.34)
	c.poly(PackedVector2Array([Vector2(cx, py - 6), Vector2(cx + 5, py), Vector2(cx, py + 6), Vector2(cx - 5, py)]), K.BR_D)
	c.poly_outline(PackedVector2Array([Vector2(cx, py - 6), Vector2(cx + 5, py), Vector2(cx, py + 6), Vector2(cx - 5, py)]), K.INK)
	c.hline(cx - 2, cx + 2, py, K.BR_HI)
	c.px(cx - 2, py - 1, K.BR_HI)
	c.px(cx, py - 2, K.BR_HI)
	c.px(cx + 2, py - 1, K.BR_HI)
	# shading down the door: dither at the top, darker on the far leaf edges
	P.dither(c, PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y0 + h * 0.3), Vector2(x0, y0 + h * 0.3)]), K.DEEP, 1)
	# a thread of candlelight under the door, guttering
	var t := P.now()
	if P.wob(t, 2.0) > -0.15:
		c.hline(x0 + 1, x1 - 2, y1 - 1, K.F_LOW)
		if P.wob(t, 5.0) > 0.25:
			c.hline(cx - 6, cx + 6, y1 - 1, K.F_MID)


static func _rose(c) -> void:
	var bz := HallCam.BACK_Z
	var s := HallCam.scale_at(bz)
	var rc := _p(0.0, 1.22, bz)
	var rr := 0.34 * s
	c.ellipse(rc.x, rc.y, rr + 3, rr + 3, K.HI)
	c.ellipse(rc.x, rc.y, rr + 1.5, rr + 1.5, K.INK)
	c.ellipse(rc.x, rc.y, rr, rr, K.GLASS_M)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var pc: Vector2 = rc + Vector2(cos(a), sin(a)) * rr * 0.6
		c.poly(PixelCanvas.ellipse_points(pc.x, pc.y, rr * 0.36, rr * 0.17, a, 14), K.CR_L if i % 2 == 0 else K.RY_L)
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0 + PI / 8.0
		c.linev(rc, rc + Vector2(cos(a), sin(a)) * rr, K.TRACE)
	c.ellipse(rc.x, rc.y, rr * 0.27, rr * 0.27, K.TRACE)
	c.ellipse(rc.x, rc.y, rr * 0.2, rr * 0.2, K.PALE)
	c.ellipse(rc.x, rc.y, rr * 0.09, rr * 0.09, K.GLASS_L)
	c.ellipse(rc.x - rr * 0.35, rc.y - rr * 0.4, 1.5, 1.5, K.PALE)
