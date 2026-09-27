extends RefCounted

## Great Hall v2, columns layer: the two swaying back-wall banners, the Giant's
## hand shadow creeping down the back wall (a real hand silhouette, sized by
## loom_p), then the arcade: pointed arches, hanging banners, and the columns
## with warm rim-light from the nearest candelabra and cold moon rim-light.

const K := preload("gh2_pal.gd")
const P := preload("gh2_paint.gd")
const ST := preload("gh2_state.gd")
const FEAST := preload("gh2_feast.gd")

const SPRING := HallBuilder.SPRING


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func paint(c) -> void:
	var zn := HallCam.near_z()
	HallBuilder.ZN = zn
	var t := P.now()
	var t0 := Time.get_ticks_usec()
	_back_banner(c, -1.62, K.CR, K.CR_D, K.CR_L, true, 0.0, t)
	_back_banner(c, 1.62, K.RY, K.RY_D, K.RY_L, false, 2.1, t)
	t0 = P.lap("a_banners", t0)
	_loom(c)
	t0 = P.lap("a_loom", t0)
	for side in [-1.0, 1.0]:
		_arcade(c, side, zn, t)
	t0 = P.lap("a_arcade", t0)


# ------------------------------------------------------------ back banners --

static func _crown(c, cx: int, cy: int) -> void:
	# 9x5 crown in dim brass
	var rows := ["B...B...B", "BB.BBB.BB", "BBBBBBBBB", "BBBRBBBBB", "DDDDDDDDD"]
	for y in rows.size():
		for x in 9:
			var ch: String = rows[y][x]
			if ch == "B":
				c.px(cx - 4 + x, cy - 2 + y, K.BR_L)
			elif ch == "D":
				c.px(cx - 4 + x, cy - 2 + y, K.BR_D)
			elif ch == "R":
				c.px(cx - 4 + x, cy - 2 + y, K.CR_L)


static func _heart(c, cx: int, cy: int) -> void:
	var rows := ["BB.BB", "BBBBB", "BBBBB", ".BBB.", "..B.."]
	for y in rows.size():
		for x in 5:
			if rows[y][x] == "B":
				c.px(cx - 2 + x, cy - 2 + y, K.BR_L)


static func _back_banner(c, xw: float, field: Color, dark: Color, light: Color, crown: bool, phase: float, t: float) -> void:
	var bz := HallCam.BACK_Z
	var tl := _p(xw - 0.3, 1.95, bz)
	var br := _p(xw + 0.3, 0.05, bz)
	var x0 := roundi(tl.x)
	var y0 := roundi(tl.y)
	var w := roundi(br.x - tl.x)
	var h := roundi(br.y - tl.y)
	if w < 6 or h < 20 or x0 + w < -10 or x0 > HallCam.W + 10:
		return
	var xc := x0 + w / 2
	var td := int(w * 0.55)
	# rod and finials
	c.rect(x0 - 3, y0 - 2, w + 6, 2, K.BR_L)
	c.hline(x0 - 3, x0 + w + 2, y0 - 2, K.BR_HI)
	c.rect(x0 - 4, y0 - 3, 2, 4, K.BR_D)
	c.rect(x0 + w + 2, y0 - 3, 2, 4, K.BR_D)
	var step := 1
	for y in range(0, h, step):
		var u := float(y) / h
		var sway := roundi(sin(t * 1.1 + phase) * 1.6 * u * u + sin(t * 2.3 + phase * 2.0) * 0.4 * u)
		var cut := 0
		if y > h - td:
			cut = int((float(y) - (h - td)) / td * (w / 2.0))
		var ya := y0 + y
		var xa := x0 + sway
		var xb := x0 + w + sway
		if cut > 0:
			# swallowtail: two tails, ragged on the torn one
			if not crown and cut > w / 2 - 3:
				continue
			c.hline(xa, xc + sway - cut, ya, field)
			c.hline(xc + sway + cut, xb - 1, ya, field)
			c.px(xa, ya, K.INK)
			c.px(xb - 1, ya, K.INK)
			c.px(xc + sway - cut, ya, K.INK)
			c.px(xc + sway + cut, ya, K.INK)
			continue
		c.hline(xa, xb - 1, ya, field)
		c.px(xa, ya, K.INK)
		c.px(xb - 1, ya, K.INK)
		c.px(xa + 2, ya, K.BR_D)
		c.px(xb - 3, ya, K.BR_D)
		if y % 5 != 4:
			c.px(xa + w / 3, ya, dark)
			c.px(xa + w * 2 / 3, ya, light if y % 2 == 0 else dark)
	# inner gold border line across the top and the emblem
	var sw0 := roundi(sin(t * 1.1 + phase) * 1.6 * 0.04)
	c.hline(x0 + 2 + sw0, x0 + w - 3 + sw0, y0 + 3, K.BR_D)
	var ey := y0 + int(h * 0.3)
	var esway := roundi(sin(t * 1.1 + phase) * 1.6 * 0.09)
	if crown:
		_crown(c, xc + esway, ey)
	else:
		_heart(c, xc + esway, ey)
	c.hline(x0, x0 + w - 1, y0, K.INK)
	# a rip in the hem of the blue one
	if not crown:
		c.vline(xc + 1, y0 + h - td - 6, y0 + h - td + 4, K.VOID)


# ---------------------------------------------------------------- the hand --

## The Giant's hand as a shadow on the back wall: palm, four rounded fingers,
## thumb, and the sleeve running up out of the wall. It descends and grows with
## loom_p, and leans to loom_x. Only ever above the dais, under the columns.
static func _loom(c) -> void:
	var lp := ST.loom_p
	if lp < 0.03:
		return
	var e := smoothstep(0.0, 1.0, minf(lp * 1.05, 1.0))
	var sc := lerpf(1.7, 3.1, e)
	var cxw := ST.loom_x * 0.85
	var ytop := lerpf(6.4, 1.95, e)
	var wx := HallCam.WALL_X
	var bz := HallCam.BACK_Z
	var ymin := HallBuilder.DAIS_Y2
	var ymax := HallCam.TOP_Y

	# hand-local shapes: u across (0..1 = palm width), w downwards from the palm top
	var shapes: Array = []
	shapes.append([Vector2(0.5, 0.32), Vector2(0.5, 0.5), 0.5, 0.46])
	shapes.append([Vector2(0.5, 0.0), Vector2(0.5, -3.6), 0.34, 0.4])
	var tips := [1.2, 1.5, 1.42, 1.1]
	var us := [0.135, 0.38, 0.62, 0.865]
	for k in 4:
		shapes.append([Vector2(us[k], 0.62), Vector2(us[k], tips[k]), 0.105, 0.105])
	shapes.append([Vector2(0.02, 0.55), Vector2(-0.42, 1.02), 0.15, 0.115])
	for ring in [[0.055, 1], [0.028, 2]]:
		var col := K.DEEP if ring[1] == 1 else K.VOID
		for sh in shapes:
			var poly := _hand_poly(sh, ring[0], cxw, ytop, sc, wx, ymin, ymax, bz)
			if poly.size() >= 3:
				P.dither(c, poly, col, ring[1])
	for sh in shapes:
		var poly2 := _hand_poly(sh, 0.0, cxw, ytop, sc, wx, ymin, ymax, bz)
		if poly2.size() >= 3:
			c.poly(poly2, K.VOID)


static func _hand_poly(sh: Array, grow: float, cxw: float, ytop: float, sc: float, wx: float, ymin: float, ymax: float, bz: float) -> PackedVector2Array:
	var cap := P.capsule(sh[0], sh[1], sh[2] + grow, sh[3] + grow, 8)
	var wall := PackedVector2Array()
	for q in cap:
		wall.append(Vector2(cxw + (q.x - 0.5) * sc, ytop - q.y * sc))
	wall = P.clip_box(wall, -wx, wx, ymin, ymax)
	var out := PackedVector2Array()
	for q in wall:
		out.append(_p(q.x, q.y, bz))
	return out


# ------------------------------------------------------------------ arcade --

static func _arcade(c, side: float, zn: float, t: float) -> void:
	var bz := HallCam.BACK_Z
	var ty := HallCam.TOP_Y
	var x: float = side * HallCam.COLUMN_X
	var cz := HallBuilder.COLUMNS_Z
	var bays: Array = [[zn, cz[0]]]
	for k in range(cz.size() - 1):
		bays.append([cz[k], cz[k + 1]])
	bays.append([cz[cz.size() - 1], bz])
	for k in bays.size():
		var z0: float = bays[k][0]
		var z1: float = bays[k][1]
		if z1 <= zn:
			continue
		if k == 0 or z0 < zn:
			HallBuilder._quad_x(c, x, SPRING, ty, maxf(z0, zn), z1, K.STONE)
			_joints(c, x, maxf(z0, zn), z1, SPRING + 0.1, side)
			continue
		var half := (z1 - z0) / 2.0 - HallBuilder.COLUMN_R
		var zm := (z0 + z1) / 2.0
		var arch := HallBuilder._arch(zm, half, SPRING, 0.75, 10)
		var apex_v := SPRING
		for q in arch:
			apex_v = maxf(apex_v, q.y)
		var wall := PackedVector2Array([Vector2(z0, SPRING)])
		wall.append_array(arch)
		wall.append_array(PackedVector2Array([Vector2(z1, SPRING), Vector2(z1, ty), Vector2(z0, ty)]))
		c.poly(HallBuilder._on_x(wall, x), K.STONE)
		_joints(c, x, z0, z1, apex_v + 0.05, side)
		# arch moulding: a lit ring between two lines
		var inner := HallBuilder._arch(zm, half - 0.07, SPRING, 0.75, 10)
		var ring := PackedVector2Array()
		ring.append_array(arch)
		for i in range(inner.size() - 1, -1, -1):
			ring.append(inner[i])
		c.poly(HallBuilder._on_x(ring, x), K.LIT)
		var edge := HallBuilder._on_x(arch, x)
		var iedge := HallBuilder._on_x(inner, x)
		for n in range(edge.size() - 1):
			c.linev(edge[n], edge[n + 1], K.INK)
			c.linev(iedge[n], iedge[n + 1], K.DEEP)
			c.linev(edge[n] + Vector2(0, 1), edge[n + 1] + Vector2(0, 1), K.HI)
		# keystone
		var ks := _p(x, apex_v + 0.02, zm)
		c.rect(roundi(ks.x) - 1, roundi(ks.y) - 1, 3, 5, K.HI)
		c.frame(roundi(ks.x) - 1, roundi(ks.y) - 1, 3, 5, K.INK)
		# soft dark inside the bay (the outer wall recedes)
		P.dither(c, HallBuilder._on_x(PackedVector2Array([Vector2(z0, SPRING), Vector2(z1, SPRING), Vector2(z1, SPRING + 0.02), Vector2(z0, SPRING + 0.02)]), x), K.DEEP, 1)
		if k < bays.size() - 1:
			var field := K.CR if (k + (1 if side > 0.0 else 0)) % 2 == 0 else K.RY
			_side_banner(c, x, zm, apex_v + 0.1, field, k, t, side)
	for k in range(cz.size() - 1, -1, -1):
		if cz[k] - HallBuilder.COLUMN_R > zn + 0.2:
			_column(c, x, cz[k], side < 0.0, t)


## Stone courses on the spandrel wall above the arches.
static func _joints(c, x: float, z0: float, z1: float, v0: float, side: float) -> void:
	var v := v0
	var row := 0
	while v < HallCam.TOP_Y:
		c.linev(_p(x, v, z0), _p(x, v, z1), K.MID)
		var zz := z0 + 0.2 + (0.25 if row % 2 == 1 else 0.0)
		while zz < z1 - 0.05:
			c.linev(_p(x, v, zz), _p(x, v + 0.3, zz), K.MID)
			zz += 0.5
		v += 0.3
		row += 1


static func _side_banner(c, x: float, zc: float, base_v: float, field: Color, k: int, t: float, side: float) -> void:
	var hw := 0.17
	var top := base_v + 1.15
	var bot := base_v + 0.02
	var sw := sin(t * 1.3 + k * 1.7 + side) * 0.03
	var shape := PackedVector2Array([
		Vector2(zc - hw, top), Vector2(zc + hw, top), Vector2(zc + hw + sw * 0.6, bot + 0.2 + 0.0),
		Vector2(zc + sw, bot), Vector2(zc - hw + sw * 0.6, bot + 0.2)])
	var pts := HallBuilder._on_x(shape, x)
	c.poly(pts, field)
	var dark := K.CR_D if field == K.CR else K.RY_D
	# folds and a gold inner border
	for f in [-0.07, 0.07]:
		c.linev(_p(x, top - 0.05, zc + f), _p(x, bot + 0.2, zc + f + sw * 0.5), dark)
	var inset := PackedVector2Array([
		Vector2(zc - hw + 0.035, top - 0.05), Vector2(zc + hw - 0.035, top - 0.05), Vector2(zc + hw - 0.035 + sw * 0.5, bot + 0.24),
		Vector2(zc + sw, bot + 0.08), Vector2(zc - hw + 0.035 + sw * 0.5, bot + 0.24)])
	c.poly_outline(HallBuilder._on_x(inset, x), K.BR_D)
	var em := _p(x, top - 0.35, zc)
	if k % 2 == 0:
		_crown(c, roundi(em.x), roundi(em.y))
	else:
		_heart(c, roundi(em.x), roundi(em.y))
	c.poly_outline(pts, K.INK)
	# the rod
	c.linev(_p(x, top + 0.04, zc - hw - 0.05), _p(x, top + 0.04, zc + hw + 0.05), K.BR_L)
	c.linev(_p(x, top + 0.02, zc - hw - 0.05), _p(x, top + 0.02, zc + hw + 0.05), K.BR_D)


static func _column(c, x: float, z: float, left: bool, t: float) -> void:
	var fy := HallCam.FLOOR_Y
	var s := HallCam.scale_at(z)
	var cx := _p(x, 0.0, z).x
	var y_floor := roundi(_p(x, fy, z).y)
	var y_torus := roundi(_p(x, fy + 0.14, z).y)
	var y_shaft := roundi(_p(x, fy + 0.22, z).y)
	var y_cap := roundi(_p(x, SPRING - 0.2, z).y)
	var y_abacus := roundi(_p(x, SPRING - 0.04, z).y)
	var y_top := roundi(_p(x, SPRING, z).y)
	var r := HallBuilder.COLUMN_R * s

	# grounding shadow, and the light pooled on the floor from the window side
	P.dither_ellipse(c, cx, y_floor, r * 2.3, maxf(2.0, r * 0.45), K.DEEP, 2)
	P.dither_ellipse(c, cx, y_floor, r * 1.5, maxf(1.5, r * 0.3), K.DEEP, 3)
	# plinth: a square block with a lit top edge
	var pw := roundi(r * 2.8)
	c.rect(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus, K.LIT)
	c.rect(roundi(cx - pw / 2.0), y_torus, pw, 2, K.HI)
	c.rect(roundi(cx - pw / 2.0), y_floor - 2, pw, 2, K.MID)
	c.frame(roundi(cx - pw / 2.0), y_torus, pw, y_floor - y_torus + 1, K.INK)
	# torus ring
	var tw := roundi(r * 2.4)
	c.rect(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft, K.HI)
	c.rect(roundi(cx - tw / 2.0), y_torus - 2, tw, 2, K.LIT)
	c.frame(roundi(cx - tw / 2.0), y_shaft, tw, y_torus - y_shaft + 1, K.INK)
	c.hline(roundi(cx - tw / 2.0) + 1, roundi(cx + tw / 2.0) - 2, y_shaft + 1, K.RIM)

	# shaft: three tone bands, lit on the side that faces the hall's centre
	var sw := maxi(4, roundi(r * 2.0))
	var sx0 := roundi(cx - sw / 2.0)
	c.rect(sx0, y_cap, sw, y_shaft - y_cap, K.STONE)
	var band := maxi(1, roundi(sw * 0.3))
	var lit_x := sx0 + sw - band if left else sx0
	var dark_x := sx0 if left else sx0 + sw - band
	c.rect(lit_x, y_cap, band, y_shaft - y_cap, K.LIT)
	c.rect(dark_x, y_cap, band, y_shaft - y_cap, K.MID)
	# dithered transition between the bands
	var mid_x := lit_x - 1 if left else lit_x + band
	P.dither(c, PackedVector2Array([Vector2(mid_x, y_cap), Vector2(mid_x + 1, y_cap), Vector2(mid_x + 1, y_shaft), Vector2(mid_x, y_shaft)]), K.LIT if left else K.MID, 2)
	var flute := maxi(3, roundi(sw / 4.0))
	for fx in range(sx0 + flute, sx0 + sw - 1, flute):
		c.vline(fx, y_cap + 1, y_shaft - 1, K.MID)
	c.vline(sx0, y_cap, y_shaft, K.INK)
	c.vline(sx0 + sw - 1, y_cap, y_shaft, K.INK)
	# cold moon rim on the wall-side edge
	var rim_x := sx0 + sw - 2 if not left else sx0 + 1
	c.vline(rim_x, y_cap + 2, y_shaft - 2, K.MOON_B if ST.loom_p < 0.5 else K.MOON_A)
	# old stone: stains and chips
	for k in 5:
		var sy := y_cap + 3 + int(P.hash2(int(z * 10.0), k, int(x)) * maxf(1.0, y_shaft - y_cap - 6))
		c.px(sx0 + 1 + k % maxi(1, sw - 2), sy, K.DEEP)

	# warm rim-light from the nearest candelabra on this side
	for k in FEAST.STANDS.size():
		var sp: Vector2 = FEAST.STANDS[k]
		if signf(sp.x) == signf(x) and absf(sp.y - z) < 0.6:
			var lvl := FEAST.flame_level(t, k)
			if lvl > -0.6:
				var gx := sx0 if not left else sx0 + sw - 3
				var gh := y_shaft - y_cap
				P.dither(c, PackedVector2Array([Vector2(gx, y_shaft - gh * 0.7), Vector2(gx + 3, y_shaft - gh * 0.7), Vector2(gx + 3, y_shaft), Vector2(gx, y_shaft)]), K.GLOW_B, 1)
				P.dither(c, PackedVector2Array([Vector2(gx, y_shaft - gh * 0.4), Vector2(gx + 3, y_shaft - gh * 0.4), Vector2(gx + 3, y_shaft), Vector2(gx, y_shaft)]), K.GLOW_C, 1)

	# capital: flared bell, a brass band, leaf marks, and the abacus block
	var cw_top := roundi(r * 3.0)
	var cap := PackedVector2Array([
		Vector2(cx - sw / 2.0, y_cap + 0.5), Vector2(cx + sw / 2.0, y_cap + 0.5),
		Vector2(cx + cw_top / 2.0, y_abacus + 0.5), Vector2(cx - cw_top / 2.0, y_abacus + 0.5)])
	c.poly(cap, K.HI)
	c.poly_outline(cap, K.INK)
	for lf in range(-1, 2):
		var lx := roundi(cx + lf * r * 0.8)
		c.vline(lx, y_cap + 3, y_abacus - 1, K.LIT)
		c.px(lx, y_cap + 3, K.RIM)
	c.hline(sx0, sx0 + sw - 1, y_cap, K.BR_L)
	c.hline(sx0, sx0 + sw - 1, y_cap + 1, K.BR_D)
	var aw := roundi(r * 3.2)
	c.rect(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), K.LIT)
	c.rect(roundi(cx - aw / 2.0), y_top, aw, 1, K.RIM)
	c.frame(roundi(cx - aw / 2.0), y_top, aw, maxi(2, y_abacus - y_top + 1), K.INK)
	# vaulting shaft rising into the dark
	c.vline(roundi(cx), 0, y_top - 1, K.BR_D)
