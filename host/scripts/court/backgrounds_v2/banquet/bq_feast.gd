extends RefCounted

## Banquet v2 feast layer: the laden right-hand table (the feast scent source is
## up the right of the arena), Sir Cheapdate's bare table on the left, the
## floor-standing candelabra by the dais and the wine barrels on the FLOOR beside
## the feast. Returns flame spots as Vector3i(x, y, size).

const G := preload("res://scripts/court/backgrounds_v2/banquet/bq_geo.gd")
const SP := preload("res://scripts/court/backgrounds_v2/banquet/bq_sprites.gd")

const GLOW := Color("#6E5636")
const CLOTH_SHADE := Color("#C9B98F")
const RIGHT := {"x0": 1.38, "x1": 1.92, "z0": -4.0, "z1": 1.1}
const LEFT := {"x0": -1.92, "x1": -1.38, "z0": -1.4, "z1": -0.05}

static var _fly_t := 0.0


static func paint_feast(c) -> Array:
	G.ZN = HallCam.near_z()
	var flames: Array = []
	_stand(c, flames, -1.35, 1.32, 4)
	_stand(c, flames, 1.35, 1.32, 4)
	_barrels(c)
	_table(c, flames, 1)
	_table(c, flames, -1)
	_life(c)
	return flames


# ------------------------------------------------------------- the tables --

static func _table(c, flames: Array, side: int) -> void:
	var right := side > 0
	var d: Dictionary = RIGHT if right else LEFT
	var x0: float = d["x0"]
	var x1: float = d["x1"]
	var z0: float = maxf(d["z0"], G.ZN)
	var z1: float = d["z1"]
	if z1 <= G.ZN + 0.05:
		return
	var fy := HallCam.FLOOR_Y + 0.02
	var ty := G.TABLE_TOP
	var hem := fy + 0.2
	var xc := (x0 + x1) / 2.0
	var aisle := x0 if right else x1
	var cloth := Pal.PARCHMENT if right else Pal.PARCHMENT_DARK
	var fold := Pal.PARCHMENT_DARK if right else Pal.PARCHMENT_SHADE
	var cam_x := HallCam.CAM.x

	# shade under the cloth and the trestle legs showing through the gap
	G.quad_x(c, aisle, fy, hem, z0, z1, Pal.STONE_DEEP)
	var lz: float = G.grid_start(1.3) + 1.3
	while lz < z1:
		if lz > z0:
			G.quad_x(c, aisle, fy, hem + 0.02, lz - 0.05, lz + 0.05, Pal.WOOD)
			c.linev(G.P(aisle, fy, lz - 0.05), G.P(aisle, hem, lz - 0.05), Pal.INK)
		lz += 1.3
	# the hanging cloth on the aisle side, with folds and a shaded lower third
	var side_face := G.quad_x(c, aisle, hem, ty, z0, z1, cloth)
	c.poly_dither(PackedVector2Array([G.P(aisle, hem, z0), G.P(aisle, hem, z1), G.P(aisle, hem + 0.2, z1), G.P(aisle, hem + 0.2, z0)]), fold)
	var z: float = G.grid_start(0.24) + 0.24
	var n := 0
	while z < z1:
		if z > z0:
			var bottom := hem + (0.02 if G.hash(n, side) > 0.5 else 0.06)
			c.linev(G.P(aisle, ty - 0.07, z), G.P(aisle, bottom, z), fold)
			c.linev(G.P(aisle, ty - 0.07, z + 0.02), G.P(aisle, bottom + 0.1, z + 0.02), cloth.lerp(Pal.PARCHMENT, 0.5))
		z += 0.24
		n += 1
	if right:
		# crimson band under the edge with a gold line: the feast table is dressed
		G.quad_x(c, aisle, ty - 0.13, ty, z0, z1, Pal.CRIMSON)
		c.linev(G.P(aisle, ty - 0.13, z0), G.P(aisle, ty - 0.13, z1), Pal.GOLD)
		c.linev(G.P(aisle, ty - 0.16, z0), G.P(aisle, ty - 0.16, z1), Pal.GOLD_DARK)
	else:
		# a darn, a stain, a moth-eaten hem: the bare table
		var sp := G.P(aisle, ty - 0.3, -0.85)
		c.ellipse(sp.x, sp.y, 4, 2, Pal.PARCHMENT_SHADE)
		c.linev(G.P(aisle, hem + 0.02, z0), G.P(aisle, hem + 0.02, z1), Pal.PARCHMENT_SHADE)
	c.poly_outline(side_face, Pal.INK)
	# near end
	if float(d["z0"]) > G.ZN:
		var end := G.quad_z(c, z0, x0, x1, hem, ty, cloth.lerp(Pal.PARCHMENT_SHADE, 0.35))
		if right:
			_runner_end(c, xc, z0, ty, hem)
		c.poly_outline(end, Pal.INK)
	# top
	var top := G.quad_y(c, ty, x0, x1, z0, z1, Pal.PARCHMENT if right else Pal.PARCHMENT_DARK)
	if right:
		G.quad_y(c, ty, xc - 0.1, xc + 0.1, z0, z1, Pal.CRIMSON)
		c.linev(G.P(xc - 0.1, ty, z0), G.P(xc - 0.1, ty, z1), Pal.GOLD)
		c.linev(G.P(xc + 0.1, ty, z0), G.P(xc + 0.1, ty, z1), Pal.GOLD_DARK)
		# a light cloth crease each side of the runner
		c.linev(G.P(x0 + 0.05, ty, z0), G.P(x0 + 0.05, ty, z1), Pal.PARCHMENT_DARK)
	c.poly_outline(top, Pal.INK)

	if right:
		_dress_feast(c, flames, x0, x1, ty, z0, z1)
	else:
		_dress_bare(c, flames, x0, x1, ty, z0, z1)

	# the bench on the aisle side, in front of the cloth
	var bx0 := aisle - 0.2 * side if right else aisle + 0.04
	var bx1 := aisle - 0.04 * side if right else aisle + 0.2
	var lo := minf(bx0, bx1)
	var hi := maxf(bx0, bx1)
	var leg_z: float = G.grid_start(1.0) + 1.0
	var legs: Array = [z0 + 0.06, z1 - 0.16]
	while leg_z < z1 - 0.3:
		if leg_z > z0 + 0.3:
			legs.append(leg_z)
		leg_z += 1.0
	legs.sort()
	for lg in legs:
		G.box(c, lo + 0.02, hi - 0.02, fy, fy + 0.15, lg, lg + 0.08, Pal.WOOD_LIGHT, Pal.WOOD, Pal.WOOD)
	G.box(c, lo, hi, fy + 0.15, fy + 0.25, z0, z1 - 0.02, Pal.WOOD_LIGHT, Pal.WOOD, Pal.WOOD)
	c.linev(G.P(lo if cam_x < lo else hi, fy + 0.2, z0), G.P(lo if cam_x < lo else hi, fy + 0.2, z1), Pal.INK)


static func _runner_end(c, xc: float, z: float, ty: float, hem: float) -> void:
	var hw := 0.1
	var tail := 0.12
	var pts := PackedVector2Array([G.P(xc - hw, ty, z), G.P(xc + hw, ty, z), G.P(xc + hw, hem + 0.02, z), G.P(xc, hem - 0.1, z), G.P(xc - hw, hem + 0.02, z)])
	c.poly(pts, Pal.CRIMSON)
	c.poly_outline(pts, Pal.CRIMSON_DARK)
	var em: PixelCanvas = SP.emblem("crown")
	var ep := G.P(xc, (ty + hem) * 0.5, z)
	c.blit(em, roundi(ep.x) - em.w / 2, roundi(ep.y) - em.h / 2)


# --------------------------------------------------- what's on the table --

static func _plate(c, x: float, y: float, z: float, rad: float, food: Color) -> void:
	var f := G.flat(x, y, z)
	if f.w < 0.0:
		return
	var rx: float = rad * f.w
	var ry: float = maxf(1.3, rx * f.z)
	if rx < 2.5:
		c.px(roundi(f.x), roundi(f.y), Pal.ROYAL)
		return
	c.ellipse(f.x, f.y, rx + 1.0, ry + 1.0, Pal.INK)
	c.ellipse(f.x, f.y, rx, ry, Pal.ROYAL)
	c.ellipse(f.x, f.y, rx * 0.74, ry * 0.72, Pal.PARCHMENT)
	if rx >= 4.0:
		c.ellipse(f.x - rx * 0.08, f.y - ry * 0.12, rx * 0.36, maxf(1.0, ry * 0.36), food)
		c.px(roundi(f.x - rx * 0.3), roundi(f.y - ry * 0.3), Pal.PARCHMENT)
		c.px(roundi(f.x + rx * 0.62), roundi(f.y), Pal.GOLD)


static func _place(c, item: PixelCanvas, bx: int, by: int) -> void:
	c.blit(item, bx - item.w / 2, by - item.h)


static func _sprite_at(c, kind: String, x: float, y: float, z: float, flames: Array, glow: bool = true) -> void:
	var b := HallCam.project(Vector3(x, y, z))
	if b.z <= 0.0:
		return
	var s := b.z
	var bx := roundi(b.x)
	var by := roundi(b.y) + 1
	match kind:
		"cand":
			var cd: Dictionary = SP.candelabra(maxi(16, roundi(0.66 * s)), 3)
			var cc: PixelCanvas = cd["canvas"]
			var ox := bx - cc.w / 2
			var oy := by - cc.h
			if glow:
				c.ellipse_dither(bx, oy + 3, 0.34 * s, 0.3 * s, GLOW)
			c.blit(cc, ox, oy)
			for f in cd["flames"]:
				flames.append(Vector3i(ox + f.x, oy + f.y, 0))
		"jug":
			_place(c, SP.jug(maxi(9, roundi(0.34 * s))), bx, by)
		"fruit":
			_place(c, SP.fruit_bowl(maxi(11, roundi(0.4 * s))), bx, by)
		"roast":
			_place(c, SP.roast(maxi(14, roundi(0.52 * s))), bx, by)
		"loaf":
			_place(c, SP.loaf(maxi(9, roundi(0.3 * s))), bx, by)
		"cheese":
			_place(c, SP.cheese(maxi(9, roundi(0.3 * s))), bx, by)
		"punch":
			_place(c, SP.punch_bowl(maxi(20, roundi(0.72 * s))), bx, by)
		"goblet":
			_place(c, SP.goblet(maxi(8, roundi(0.26 * s))), bx, by)
		"stub":
			var sd: Dictionary = SP.stub_candle(maxi(7, roundi(0.24 * s)))
			var sc: PixelCanvas = sd["canvas"]
			c.blit(sc, bx - sc.w / 2, by - sc.h)
			var sf: Vector2i = sd["flame"]
			flames.append(Vector3i(bx - sc.w / 2 + sf.x, by - sc.h + sf.y, 0))


static func _dress_feast(c, flames: Array, x0: float, x1: float, ty: float, z0: float, z1: float) -> void:
	var xc := (x0 + x1) / 2.0
	# place settings: two plates and two goblets per seat, every 0.6
	var seats: Array = []
	var zs := -3.7
	while zs < z1 - 0.2:
		if zs > z0 + 0.1:
			seats.append(zs)
		zs += 0.6
	var items: Array = []   # [z, kind, x, y]
	for k in seats.size():
		var sz: float = seats[k]
		var foods := [Pal.CRIMSON, Pal.AMBER, Pal.GOLD_LIGHT, Pal.GRAPE]
		_plate(c, xc - 0.165, ty, sz, 0.105, foods[(k * 3) % 4])
		_plate(c, xc + 0.165, ty, sz + 0.14, 0.105, foods[(k * 3 + 1) % 4])
		items.append([sz + 0.24, "goblet", xc - 0.2, ty])
		items.append([sz + 0.33, "goblet", xc + 0.2, ty])
	var menu := [
		[-3.1, "cand"], [-2.6, "jug"], [-2.15, "fruit"], [-1.7, "roast"], [-1.25, "cand"], [-0.85, "loaf"],
		[-0.5, "punch"], [0.1, "cand"], [0.45, "roast"], [0.75, "jug"], [0.92, "fruit"],
	]
	for m in menu:
		var jitter := 0.03 if int(absf(m[0]) * 10) % 2 == 0 else -0.03
		items.append([m[0], m[1], xc + jitter, ty])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for it in items:
		if it[0] < G.ZN + 0.25 or it[0] > z1 - 0.03:
			continue
		_sprite_at(c, it[1], it[2], it[3], it[0], flames, false)


static func _dress_bare(c, flames: Array, x0: float, x1: float, ty: float, z0: float, z1: float) -> void:
	var xc := (x0 + x1) / 2.0
	# stains, a darned patch and a crumb trail on the threadbare cloth
	for st in [[xc - 0.1, -1.15, 0.09], [xc + 0.12, -0.5, 0.07], [xc - 0.05, -0.15, 0.06]]:
		var f := G.flat(st[0], ty, st[1])
		if f.w > 0.0 and st[1] > G.ZN + 0.2:
			c.ellipse(f.x, f.y, st[2] * f.w, maxf(1.2, st[2] * f.w * f.z), Pal.PARCHMENT_SHADE)
	var dp := G.flat(xc + 0.1, ty, -1.05)
	if dp.w > 0.0 and z0 < -1.0:
		c.rect(roundi(dp.x) - 3, roundi(dp.y) - 1, 7, 3, Pal.ROYAL_DARK)
		c.frame(roundi(dp.x) - 3, roundi(dp.y) - 1, 7, 3, Pal.GOLD_DARK)
	for k in 5:
		var cf := G.flat(xc - 0.12 + k * 0.05, ty, -0.7 + k * 0.03)
		if cf.w > 0.0:
			c.px(roundi(cf.x), roundi(cf.y), Pal.AMBER_DARK)
	# one chipped plate with a crust, one empty goblet, a guttering candle stub
	_plate(c, xc, ty, -0.78, 0.115, Pal.AMBER_DARK)
	var items: Array = [[-0.32, "stub", xc + 0.02, ty], [-0.6, "goblet", xc - 0.16, ty], [-0.98, "loaf", xc + 0.12, ty]]
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for it in items:
		if it[0] > G.ZN + 0.25:
			_sprite_at(c, it[1], it[2], it[3], it[0], flames, false)


# ---------------------------------------------------- stands and barrels --

## A floor-standing candelabra on a stone plinth (flanking the dais).
static func _stand(c, flames: Array, x: float, z: float, arms: int) -> void:
	if z <= G.ZN + 0.3:
		return
	var fy := HallCam.FLOOR_Y
	var b := HallCam.project(Vector3(x, fy, z))
	if b.z <= 0.0:
		return
	var s := b.z
	G.box(c, x - 0.17, x + 0.17, fy, fy + 0.5, z - 0.17, z + 0.17, Pal.STONE_HI, Pal.STONE_LIGHT, Pal.STONE)
	c.linev(G.P(x - 0.19, fy + 0.5, z - 0.19), G.P(x + 0.19, fy + 0.5, z - 0.19), Pal.GOLD_DARK)
	var top := HallCam.project(Vector3(x, fy + 0.5, z))
	var cd: Dictionary = SP.candelabra(maxi(18, roundi(0.85 * s)), arms)
	var cc: PixelCanvas = cd["canvas"]
	var ox := roundi(top.x) - cc.w / 2
	var oy := roundi(top.y) - cc.h + 2
	c.ellipse_dither(top.x, oy + 4, 0.3 * s, 0.26 * s, GLOW)
	c.blit(cc, ox, oy)
	for f in cd["flames"]:
		flames.append(Vector3i(ox + f.x, oy + f.y, 0))


static func _barrels(c) -> void:
	var fy := HallCam.FLOOR_Y
	# floor level, beside and behind the feast table: never on the cloth
	var spots := [[1.42, 1.62], [1.76, 1.6], [1.6, 1.4], [1.0, 0.36]]
	for sp in spots:
		if sp[1] <= G.ZN + 0.3:
			continue
		var b := HallCam.project(Vector3(sp[0], fy, sp[1]))
		if b.z <= 0.0:
			continue
		var bc: PixelCanvas = SP.barrel(maxi(16, roundi(0.66 * b.z)))
		c.ellipse_dither(b.x, b.y, bc.w * 0.6, bc.w * 0.16, Pal.INK)
		c.blit(bc, roundi(b.x) - bc.w / 2, roundi(b.y) - bc.h + 1)
	# a puddle where one leaks
	var f := G.flat(1.5, fy, 1.18)
	if f.w > 0.0:
		c.ellipse(f.x, f.y, 0.2 * f.w, 0.2 * f.w * f.z, SP.WINE)
		c.px(roundi(f.x - 0.06 * f.w), roundi(f.y), Pal.CRIMSON_LIGHT)


# ------------------------------------------------------------ life: bits --

## Animated flourishes: flies over the punch and barrels, steam off the roasts,
## dust motes drifting through the lit air. Time-based, not frame-locked.
static func _life(c) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# flies circle the punch bowl / fruit / barrels at the feast end
	for k in 4:
		var cxw := 1.62 if k < 2 else 1.6
		var czw := -0.5 if k < 2 else 1.4
		var cyw := -0.5 if k < 2 else -0.7
		var ang := t * (2.6 + k * 0.7) + k * 1.9
		var p := HallCam.project(Vector3(cxw + cos(ang) * 0.22, cyw + sin(ang * 1.7) * 0.06 + 0.15, czw + sin(ang) * 0.14))
		if p.z > 0.0 and czw > G.ZN + 0.4:
			c.px(roundi(p.x), roundi(p.y), Pal.INK)
	# steam rising off the two roasts
	for rz in [-1.7, 0.45]:
		if rz < G.ZN + 0.4:
			continue
		for k in 3:
			var u := fmod(t * 0.5 + k * 0.33, 1.0)
			var p2 := HallCam.project(Vector3(1.65 + sin(u * 6.0 + k) * 0.03, G.TABLE_TOP + 0.16 + u * 0.4, rz))
			if p2.z > 0.0:
				c.px(roundi(p2.x), roundi(p2.y), Pal.PARCHMENT_DARK if u < 0.7 else Pal.PARCHMENT_SHADE)
	# dust motes in the window light, mostly high near the sides
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for k in 18:
		var mx := rng.randf_range(-2.0, 2.0)
		var my := rng.randf_range(0.2, 1.9)
		var mz := rng.randf_range(-2.5, 1.6)
		var ph := rng.randf_range(0.0, TAU)
		var q := HallCam.project(Vector3(mx + sin(t * 0.25 + ph) * 0.12, my + fmod(t * 0.06 + ph, 0.5), mz + cos(t * 0.2 + ph) * 0.1))
		if q.z > 0.0 and mz > G.ZN + 0.5:
			c.px(roundi(q.x), roundi(q.y), Pal.GOLD_LIGHT if k % 3 == 0 else Pal.PARCHMENT_DARK)
