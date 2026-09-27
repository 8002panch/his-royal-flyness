extends RefCounted

## Great Hall v2, feast layer (drawn above the arcade): the arena's furniture
## pushed to the walls (cloth tables, a tipped table, piles of overturned
## chairs), the few candles left burning and guttering, moonlight shafts drawn
## with dithering, and drifting dust motes.

const K := preload("gh2_pal.gd")
const P := preload("gh2_paint.gd")
const S := preload("gh2_sprites.gd")
const ST := preload("gh2_state.gd")
const WALLS := preload("gh2_walls.gd")

const TABLE_TOP := -0.88
## Floor candelabra (x, z): a few, in front of the tables.
const STANDS := [Vector2(-1.45, -0.95), Vector2(-1.45, 0.34), Vector2(1.45, -0.55), Vector2(1.45, 0.72)]


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


## -1..1 flicker for candle k; a hall on edge (alarm) gutters harder.
static func flame_level(t: float, k: int) -> float:
	return clampf(P.wob(t, float(k) * 1.9 + 0.5) - ST.alarm * 0.35, -1.0, 1.0)


static func paint(c) -> void:
	var zn := HallCam.near_z()
	HallBuilder.ZN = zn
	var fy := HallCam.FLOOR_Y
	var t := P.now()

	# objects, painted far to near
	var objs: Array = []
	objs.append({"z": -0.7, "k": "cloth", "x": -1.8, "len": 1.05, "wid": 0.4, "yaw": 3.0, "side": -1.0, "var": 0})
	objs.append({"z": 0.95, "k": "cloth", "x": -1.8, "len": 1.2, "wid": 0.4, "yaw": -6.0, "side": -1.0, "var": 1})
	objs.append({"z": -1.05, "k": "tipped", "x": 1.93, "len": 1.15, "side": 1.0})
	objs.append({"z": 0.42, "k": "cloth", "x": 1.8, "len": 1.15, "wid": 0.4, "yaw": 4.0, "side": 1.0, "var": 2})
	objs.append({"z": -1.65, "k": "pile", "x": -1.75, "w": 0.85, "var": 0})
	objs.append({"z": 0.12, "k": "pile", "x": -1.78, "w": 0.55, "var": 1})
	objs.append({"z": -0.36, "k": "pile", "x": 1.78, "w": 0.6, "var": 1})
	objs.append({"z": 1.5, "k": "pile", "x": 1.74, "w": 0.6, "var": 0})
	objs.append({"z": -0.14, "k": "chair", "x": -1.5, "h": 0.5, "ang": 100.0})
	objs.append({"z": -1.7, "k": "chair", "x": 1.55, "h": 0.5, "ang": 250.0})
	objs.append({"z": 1.15, "k": "chair", "x": 1.5, "h": 0.5, "ang": 15.0})
	for i in STANDS.size():
		objs.append({"z": STANDS[i].y, "k": "stand", "x": STANDS[i].x, "i": i})
	objs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"])

	var flames: Array = []
	var t0 := Time.get_ticks_usec()
	for o in objs:
		if o["z"] < zn + 0.35:
			continue
		match o["k"]:
			"cloth":
				_cloth_table(c, o, zn, fy, t, flames)
			"tipped":
				_tipped_table(c, o, zn, fy)
			"pile":
				var pr := HallCam.project(Vector3(o["x"], fy, o["z"]))
				var cv: PixelCanvas = S.chair_pile(roundi(o["w"] * pr.z), o["var"])
				c.blit(cv, roundi(pr.x) - cv.w / 2, roundi(pr.y) - cv.h + 3)
			"chair":
				var pr2 := HallCam.project(Vector3(o["x"], fy, o["z"]))
				var cv2: PixelCanvas = S.chair_single(roundi(o["h"] * pr2.z), o["ang"])
				c.blit(cv2, roundi(pr2.x) - cv2.w / 2, roundi(pr2.y) - cv2.h * 2 / 3)
			"stand":
				var pr3 := HallCam.project(Vector3(o["x"], fy, o["z"]))
				var cd: Dictionary = S.candelabra(roundi(0.95 * pr3.z))
				var cv3: PixelCanvas = cd["canvas"]
				var ox := roundi(pr3.x) - cv3.w / 2
				var oy := roundi(pr3.y) - cv3.h + 2
				P.dither_ellipse(c, pr3.x, pr3.y - 1, cv3.w * 0.45, 2.0, K.DEEP, 2)
				c.blit(cv3, ox, oy)
				for f in cd["flames"]:
					flames.append({"pos": Vector2i(ox + f.x, oy + f.y), "k": o["i"], "size": cv3.h})
	t0 = P.lap("e_objs", t0)
	for f in flames:
		_flame(c, f["pos"], f["k"], f["size"], t)
	t0 = P.lap("e_flames", t0)
	_shafts(c, zn, fy)
	t0 = P.lap("e_shafts", t0)
	_motes(c, zn, t)
	t0 = P.lap("e_motes", t0)


# ------------------------------------------------------------------ flames --

static func _flame(c, pos: Vector2i, k: int, size: int, t: float) -> void:
	var n := flame_level(t, k)
	var big := size >= 70
	var h := 4 + roundi((n + 1.0) * 1.6)
	var w := 2
	if big:
		h += 2
		w = 3
	if n < -0.72:
		h = 2 # guttering to almost nothing
	var lean := roundi(P.wob(t * 0.7 + 2.0, float(k) + 3.0) * (1.4 if n < 0.0 else 0.8))
	var gr := (10.0 if big else 6.0) * (0.75 + 0.25 * (n + 1.0))
	# warm light on whatever is near: sparse outer, denser inner
	P.dither_ellipse(c, pos.x, pos.y - 2, gr * 1.9, gr * 1.6, K.GLOW_A, 1)
	P.dither_ellipse(c, pos.x, pos.y - 2, gr, gr * 0.85, K.GLOW_B, 1)
	var x := pos.x
	var y := pos.y
	c.rect(x - w / 2, y - h + 1, w, h, K.F_MID)
	c.rect(x - w / 2 + lean, y - h, maxi(1, w - 1), 1, K.F_MID)
	c.rect(x - maxi(0, w / 2 - 1), y - h + 2, maxi(1, w - 2), maxi(1, h - 3), K.F_HOT)
	c.px(x - w / 2, y, K.F_LOW)
	c.px(x + w / 2, y, K.F_LOW)


static func _smoke(c, x: int, y: int, t: float) -> void:
	for k in 9:
		if k % 3 == 2:
			continue
		var dx := roundi(sin(t * 2.2 + k * 0.8) * (0.4 + k * 0.28))
		c.px(x + dx, y - k * 2, K.T_D if k < 5 else K.MID)


# ------------------------------------------------------------- box helpers --

static func _corners(cx: float, cz: float, wid: float, len: float, yaw_deg: float) -> Array:
	var a := deg_to_rad(yaw_deg)
	var out: Array = []
	for lp in [Vector2(-wid / 2, -len / 2), Vector2(wid / 2, -len / 2), Vector2(wid / 2, len / 2), Vector2(-wid / 2, len / 2)]:
		out.append(Vector2(cx + lp.x * cos(a) - lp.y * sin(a), cz + lp.x * sin(a) + lp.y * cos(a)))
	return out


static func _faces(pts: Array) -> Array:
	var cen := Vector2.ZERO
	for p in pts:
		cen += p
	cen /= pts.size()
	var cam := Vector2(HallCam.CAM.x, HallCam.CAM.z)
	var out: Array = []
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var mid := (a + b) / 2.0
		var n := (mid - cen).normalized()
		if n.dot(cam - mid) > 0.0:
			out.append({"a": a, "b": b, "n": n})
	return out


static func _quad3(a: Vector2, b: Vector2, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([_p(a.x, y0, a.y), _p(b.x, y0, b.y), _p(b.x, y1, b.y), _p(a.x, y1, a.y)])


# ------------------------------------------------------------------ tables --

static func _cloth_table(c, o: Dictionary, zn: float, fy: float, t: float, flames: Array) -> void:
	var side: float = o["side"]
	var pts := _corners(o["x"], o["z"], o["wid"], o["len"], o["yaw"])
	var ty := TABLE_TOP
	var y0 := fy + 0.02
	# shadow pooled on the floor round the table
	var big: Array = _corners(o["x"], o["z"], o["wid"] + 0.34, o["len"] + 0.34, o["yaw"])
	var sh := PackedVector2Array()
	for p in big:
		sh.append(_p(p.x, fy, maxf(p.y, zn)))
	P.dither(c, sh, K.DEEP, 2)
	var faces := _faces(pts)
	for f in faces:
		var aisle: bool = f["n"].x * side < -0.4
		var col := K.T if aisle else K.T_D
		var q := _quad3(f["a"], f["b"], y0, ty)
		c.poly(q, col)
		# folds hang from the top, a stained hem runs along the foot
		var nf := maxi(3, roundi(((f["b"] as Vector2) - (f["a"] as Vector2)).length() / 0.17))
		for k in range(1, nf):
			var u := float(k) / nf
			var pa: Vector2 = (f["a"] as Vector2).lerp(f["b"], u)
			var top := _p(pa.x, ty - 0.03, pa.y)
			var bot := _p(pa.x, y0 + 0.01 + (0.02 if k % 2 == 0 else 0.0), pa.y)
			c.linev(top, bot, K.T_D if k % 2 == 0 else K.T_L)
		var h0 := _p(f["a"].x, y0 + 0.07, f["a"].y)
		var h1 := _p(f["b"].x, y0 + 0.07, f["b"].y)
		c.linev(h0, h1, K.T_D if aisle else K.MID)
		c.poly_outline(q, K.DEEP)
	# the top, with a crimson runner along the middle
	var top_poly := PackedVector2Array()
	for p in pts:
		top_poly.append(_p(p.x, ty, p.y))
	c.poly(top_poly, K.T_L)
	var a0: Vector2 = (pts[0] as Vector2).lerp(pts[1], 0.44)
	var a1: Vector2 = (pts[0] as Vector2).lerp(pts[1], 0.56)
	var b0: Vector2 = (pts[3] as Vector2).lerp(pts[2], 0.44)
	var b1: Vector2 = (pts[3] as Vector2).lerp(pts[2], 0.56)
	c.poly(PackedVector2Array([_p(a0.x, ty, a0.y), _p(a1.x, ty, a1.y), _p(b1.x, ty, b1.y), _p(b0.x, ty, b0.y)]), K.CR)
	c.linev(_p(a0.x, ty, a0.y), _p(b0.x, ty, b0.y), K.BR_D)
	c.linev(_p(a1.x, ty, a1.y), _p(b1.x, ty, b1.y), K.BR_D)
	c.poly_outline(top_poly, K.DEEP)

	# cloth dragged off one corner and onto the floor
	if o["var"] == 1 or o["var"] == 2:
		var e: Vector2 = pts[0] if side < 0.0 else pts[3]
		var e2: Vector2 = pts[1] if side < 0.0 else pts[2]
		var toward := Vector2(-side, 0.0)
		var d1: Vector2 = e + toward * 0.5 + Vector2(0, -0.12)
		var d2: Vector2 = e2 + toward * 0.36 + Vector2(0, 0.1)
		var drape := PackedVector2Array([_p(e.x, fy + 0.02, e.y), _p(d1.x, fy + 0.01, d1.y), _p(d2.x, fy + 0.01, d2.y), _p(e2.x, fy + 0.02, e2.y)])
		c.poly(drape, K.T_D)
		c.linev(_p(e.x, fy + 0.02, e.y), _p(d1.x, fy + 0.01, d1.y), K.DEEP)
		c.linev(_p(e2.x, fy + 0.02, e2.y), _p(d2.x, fy + 0.01, d2.y), K.DEEP)
		var m0: Vector2 = e.lerp(d1, 0.6).lerp(e2.lerp(d2, 0.6), 0.5)
		c.px(roundi(_p(m0.x, fy, m0.y).x), roundi(_p(m0.x, fy, m0.y).y), K.T)

	# the meal, abandoned: a few fallen goblets and plates; one candle burning, one snuffed
	var zc: float = o["z"]
	var xc: float = o["x"]
	var pr := HallCam.project(Vector3(xc, ty, zc))
	var s := pr.z
	var slots := [-0.4, -0.1, 0.22, 0.45]
	for k in slots.size():
		var zz: float = zc + slots[k] * o["len"]
		if zz < zn + 0.3:
			continue
		var q2 := HallCam.project(Vector3(xc + (0.05 if k % 2 == 0 else -0.07), ty, zz))
		if k % 2 == 0:
			var pv: PixelCanvas = S.goblet_fallen(roundi(0.09 * q2.z))
			c.blit(pv, roundi(q2.x) - pv.w / 2, roundi(q2.y) - pv.h + 2)
		else:
			var pp: PixelCanvas = S.plate(roundi(0.2 * q2.z))
			c.blit(pp, roundi(q2.x) - pp.w / 2, roundi(q2.y) - pp.h + 2)
	var cz: float = zc + 0.05 * o["len"]
	if cz > zn + 0.3:
		var q3 := HallCam.project(Vector3(xc, ty, cz))
		var cd: Dictionary = S.candelabra(roundi(0.5 * q3.z))
		var cv: PixelCanvas = cd["canvas"]
		var ox := roundi(q3.x) - cv.w / 2
		var oy := roundi(q3.y) - cv.h + 2
		c.blit(cv, ox, oy)
		if o["var"] == 0:
			# this one has been snuffed: a thread of smoke
			for f in cd["flames"]:
				_smoke(c, ox + f.x, oy + f.y, t)
		else:
			for f in cd["flames"]:
				flames.append({"pos": Vector2i(ox + f.x, oy + f.y), "k": 10 + int(o["var"]), "size": 20})


static func _tipped_table(c, o: Dictionary, zn: float, fy: float) -> void:
	var side: float = o["side"]
	var xc: float = o["x"]
	var cz: float = o["z"]
	var len: float = o["len"]
	var pts := _corners(xc, cz, 0.11, len, 0.0)
	var top_y := fy + 0.98
	var y0 := fy
	# floor shadow
	var sh := PackedVector2Array()
	for p in _corners(xc - side * 0.3, cz, 0.7, len + 0.3, 0.0):
		sh.append(_p(p.x, fy, maxf(p.y, zn)))
	P.dither(c, sh, K.DEEP, 2)
	# legs sticking out horizontally, behind the slab face
	for zl in [cz - len / 2 + 0.1, cz + len / 2 - 0.1]:
		if zl < zn + 0.2:
			continue
		for yl in [fy + 0.14, fy + 0.84]:
			var xa: float = xc - side * 0.055
			var xb: float = xa - side * 0.74
			HallBuilder._quad_z(c, zl, minf(xa, xb), maxf(xa, xb), yl - 0.045, yl + 0.045, K.W_L)
			c.linev(_p(xa, yl + 0.045, zl), _p(xb, yl + 0.045, zl), K.W_HI)
			c.linev(_p(xa, yl - 0.045, zl), _p(xb, yl - 0.045, zl), K.W_D)
			var e := _p(xb, yl, zl)
			c.rect(roundi(e.x) - 1, roundi(e.y) - 3, 3, 6, K.W)
			c.frame(roundi(e.x) - 1, roundi(e.y) - 3, 3, 6, K.DEEP)
	for f in _faces(pts):
		var aisle: bool = f["n"].x * side < -0.4
		var q := _quad3(f["a"], f["b"], y0, top_y)
		c.poly(q, K.W if aisle else K.W_L)
		if aisle:
			# planks of the table-top, seen edge-on as long boards
			for r in range(1, 5):
				var yy := fy + r * 0.196
				c.linev(_p(f["a"].x, yy, f["a"].y), _p(f["b"].x, yy, f["b"].y), K.W_D)
			# the apron rail
			HallBuilder._quad_x(c, xc - side * 0.056, fy + 0.72, fy + 0.86, maxf(cz - len / 2 + 0.05, zn), cz + len / 2 - 0.05, K.W_D)
		c.poly_outline(q, K.DEEP)
	var tp := PackedVector2Array()
	for p in pts:
		tp.append(_p(p.x, top_y, p.y))
	c.poly(tp, K.W_HI)
	c.poly_outline(tp, K.DEEP)
	# what slid off it
	for k in 3:
		var zz: float = cz - len * 0.3 + k * len * 0.3
		if zz < zn + 0.3:
			continue
		var g := HallCam.project(Vector3(xc - side * (0.5 + 0.2 * k), fy, zz))
		if k == 1:
			var pv: PixelCanvas = S.plate(roundi(0.26 * g.z))
			c.blit(pv, roundi(g.x) - pv.w / 2, roundi(g.y) - pv.h + 1)
		else:
			var gv: PixelCanvas = S.goblet_fallen(roundi(0.15 * g.z))
			c.blit(gv, roundi(g.x) - gv.w / 2, roundi(g.y) - gv.h + 1)


# ------------------------------------------------------- light and dust --

static func _shafts(c, zn: float, fy: float) -> void:
	var moon := 1.0 - clampf(ST.loom_p * 1.2, 0.0, 1.0)
	if moon < 0.1:
		return
	var wx := HallCam.WALL_X
	var sh := 0.55
	for side in [-1.0, 1.0]:
		for zc in WALLS.LANCETS:
			if zc + sh - 0.3 < zn + 0.3:
				continue
			var xa: float = side * (wx - 0.02)
			var xb: float = side * (wx - 2.0)
			var pts := PackedVector2Array([
				_p(xa, -0.18, zc - 0.2), _p(xa, -0.18, zc + 0.2), _p(xa, 1.1, zc - 0.2), _p(xa, 1.1, zc + 0.2),
				_p(xb, fy, zc - 0.3 + sh), _p(xb, fy, zc + 0.3 + sh)])
			P.dither(c, P.hull(pts), K.MOON_A, 1)
			# a brighter core hugging the pane
			var core := PackedVector2Array([
				_p(xa, -0.18, zc - 0.14), _p(xa, -0.18, zc + 0.14), _p(xa, 0.7, zc - 0.14), _p(xa, 0.7, zc + 0.14),
				_p(side * (wx - 1.1), fy + 0.1, zc - 0.2 + sh * 0.5), _p(side * (wx - 1.1), fy + 0.1, zc + 0.2 + sh * 0.5)])
			if moon > 0.5:
				P.dither(c, P.hull(core), K.MOON_B, 1)


static func _motes(c, zn: float, t: float) -> void:
	for i in 30:
		var bx := (P.hash2(i, 1, 40) - 0.5) * 3.8
		var bz := -2.4 + P.hash2(i, 2, 40) * 4.0
		if bz < zn + 0.5:
			continue
		var ph := P.hash2(i, 3, 40)
		var yy := lerpf(-1.15, 2.4, fposmod(ph - t * 0.014, 1.0))
		var xx := bx + sin(t * 0.31 + i) * 0.16
		var zz := bz + cos(t * 0.23 + i * 1.7) * 0.14
		if P.wob(t * 0.25, float(i)) < -0.45:
			continue
		var pr := HallCam.project(Vector3(xx, yy, zz))
		if pr.z <= 0.0:
			continue
		var col := K.PALE if i % 4 == 0 else (K.GLASS_L if i % 3 == 0 else K.BR_L)
		c.px(roundi(pr.x), roundi(pr.y), col)
		if pr.z > 110.0 and i % 2 == 0:
			c.px(roundi(pr.x) + 1, roundi(pr.y), col)
