extends RefCounted

## Garden v2: "Her Highness takes the evening air among the grapes".
## Painted through HallCam's live camera by a CanvasPainter, like HallBuilder.
## Layers keep HallLayer's names:
##   far      dusk sky, palace wall (pointed doorway, rose window, banners), towers,
##            the tall hedge walls with cypress spires
##   floor    lawn, flagstone path, the round plaza, steps, dithered lantern light
##   columns  (far -> near) pillars with pergola + grape vines, clipped hedge
##            planters, topiary, the toasting table, palace plinths + candelabra
##   feast    hanging lanterns (glow + flames), fireflies, drifting leaves
## World: x lateral, y up, z into the scene. Floor y = -1.3, palace wall z = 1.8.

const PAL := preload("res://scripts/court/backgrounds_v2/garden/garden2_pal.gd")

const FY := -1.3                 # floor
const PZ := 3.4                  # palace wall plane
const WALL_X := 2.45
const WALL_TOP := 1.9            # palace parapet
const PW := 5.6                  # palace wall half width (wider than the garden)
const SW_END := 3.0              # where the hedge walls stop (forecourt beyond)
const PATH_HALF := 1.05
const PLAZA_Z := 1.15
const PLAZA_R := 0.98
const PX := 1.45                 # pillar centre x
const ZS := [-6.4, -4.9, -3.4, -1.9, -0.4, 1.1, 2.6]     # pillar stations
const BEAM_Y := 1.4
const HEDGE_TOP := -0.82

static var ZN := -3.5
static var T := 0.0


static func _p(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func _tick() -> void:
	ZN = HallCam.near_z()
	T = Time.get_ticks_msec() / 1000.0


static func _h(i: int, j: int, s: int) -> float:
	var n: int = (i * 73856093) ^ (j * 19349663) ^ (s * 83492791)
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7FFFFFFF
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


static func _quad_x(c, x: float, y0: float, y1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x, y0, z0), _p(x, y0, z1), _p(x, y1, z1), _p(x, y1, z0)])
	_fill(c, q, col)
	return q


static func _quad_y(c, y: float, x0: float, x1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x0, y, z0), _p(x1, y, z0), _p(x1, y, z1), _p(x0, y, z1)])
	_fill(c, q, col)
	return q


static func _quad_z(c, z: float, x0: float, x1: float, y0: float, y1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([_p(x0, y0, z), _p(x1, y0, z), _p(x1, y1, z), _p(x0, y1, z)])
	_fill(c, q, col)
	return q


## Solid box, only the faces the camera can see. Colours: front (z0 face), top, side, bottom.
static func _box(c, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, cf: Color, ct: Color, cs: Color, outline := true) -> void:
	var clipped := z0 < ZN
	z0 = maxf(z0, ZN)
	if z1 <= z0 + 0.01:
		return
	var cam := HallCam.CAM
	var outs: Array = []
	if cam.x < x0:
		outs.append(_quad_x(c, x0, y0, y1, z0, z1, cs))
	elif cam.x > x1:
		outs.append(_quad_x(c, x1, y0, y1, z0, z1, cs))
	if cam.y > y1:
		outs.append(_quad_y(c, y1, x0, x1, z0, z1, ct))
	elif cam.y < y0:
		outs.append(_quad_y(c, y0, x0, x1, z0, z1, cs.darkened(0.25)))
	if not clipped:
		outs.append(_quad_z(c, z0, x0, x1, y0, y1, cf))
	if outline:
		for q in outs:
			c.poly_outline(q, Pal.INK)


## Cheap polygon fills that skip CanvasPainter's per-call triangulation check.
static func _fill(c, pts: PackedVector2Array, col: Color) -> void:
	var n := pts.size()
	if n < 3:
		return
	var area := 0.0
	var mnx := INF
	var mxx := -INF
	var mny := INF
	var mxy := -INF
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
		mnx = minf(mnx, a.x)
		mxx = maxf(mxx, a.x)
		mny = minf(mny, a.y)
		mxy = maxf(mxy, a.y)
	if absf(area) < 1.0 or mxx < 0.0 or mnx > 640.0 or mxy < 0.0 or mny > 360.0 or mxx - mnx > 4000.0:
		return
	c.ci.draw_colored_polygon(pts, col)


static func _dither(c, pts: PackedVector2Array, col: Color) -> void:
	var n := pts.size()
	if n < 3:
		return
	var area := 0.0
	var mnx := INF
	var mxx := -INF
	var mny := INF
	var mxy := -INF
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
		mnx = minf(mnx, a.x)
		mxx = maxf(mxx, a.x)
		mny = minf(mny, a.y)
		mxy = maxf(mxy, a.y)
	if absf(area) < 1.0 or mxx < 0.0 or mnx > 640.0 or mxy < 0.0 or mny > 360.0 or mxx - mnx > 4000.0:
		return
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / 2.0)
	c.ci.draw_polygon(pts, PackedColorArray([col]), uvs, CanvasPainter._checker)


static var _tiles := {}


static func _frect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	# fill with wrap-around so the tile repeats seamlessly
	var W := img.get_width()
	var H := img.get_height()
	for oy in [0, -H]:
		for ox in [0, -W]:
			var r := Rect2i(x + ox, y + oy, w, h).intersection(Rect2i(0, 0, W, H))
			if r.size.x > 0 and r.size.y > 0:
				img.fill_rect(r, col)


## A seamless, world-locked tile of leaf blobs (transparent background).
static func _leaf_tile(cell: float, variant: int, cols: Array, bias: float, density: float) -> ImageTexture:
	var key := "L%d_%d_%s_%d_%.2f_%.2f" % [roundi(cell * 1000.0), variant, cols[0].to_html(), cols.size(), bias, density]
	if _tiles.has(key):
		return _tiles[key]
	var size := cell * 40.0
	var texels := 88
	var T := texels / size
	var img := Image.create(texels, texels, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var n := cols.size()
	var cells := 40
	for ia in cells:
		for ib in cells:
			if _h(ia, ib, variant * 7 + 3) > density:
				continue
			var lx := roundi((ia + 0.15 + _h(ia, ib, variant * 7 + 11) * 0.7) * cell * T)
			var ly := roundi((ib + 0.15 + _h(ia, ib, variant * 7 + 23) * 0.7) * cell * T)
			var w := maxi(2, roundi(cell * T * 1.35))
			var hh := maxi(2, roundi(cell * T * 1.05))
			var sh := pow(_h(ia, ib, variant * 7 + 53), 1.5)
			var idx := clampi(int((0.15 + sh * 0.6 + bias + float(ib) / cells * 0.2) * n), 0, n - 1)
			if w <= 2 or hh <= 2:
				_frect(img, lx, ly, w, hh, cols[idx])
			else:
				_frect(img, lx + 1, ly, w - 2, hh, cols[idx])
				_frect(img, lx, ly + 1, w, hh - 2, cols[idx])
				_frect(img, lx + 1, ly, w - 2, 1, cols[mini(idx + 1, n - 1)])
				if idx > 0:
					_frect(img, lx + 1, ly + hh - 1, w - 2, 1, cols[idx - 1])
	var tex := ImageTexture.create_from_image(img)
	_tiles[key] = tex
	return tex


## Foliage over a plane, from a baked tile. kind 0: plane z=k (a=x, b=y)  1: plane x=k (a=z, b=y)
## 2: plane y=k (a=x, b=z). Same arguments as the old per-leaf version; `sway` is ignored.
static func _leaf_plane(c, kind: int, k: float, a0: float, a1: float, b0: float, b1: float, cell: float, seed: int, cols: Array, bias := 0.0, density := 1.0, _sway := 0.0) -> void:
	if kind == 0:
		if k < ZN + 0.7:
			return
	elif kind == 1:
		a0 = maxf(a0, ZN + 0.2)
	else:
		b0 = maxf(b0, ZN + 0.2)
	if a1 <= a0 or b1 <= b0:
		return
	var tex := _leaf_tile(cell, seed % 4, cols, bias, density)
	var size := cell * 40.0
	var ou := _h(seed, 1, 77)
	var ov := _h(seed, 2, 77)
	# subdivide along depth so the affine texture mapping stays close to perspective
	var nseg := 1
	if kind == 1:
		nseg = clampi(ceili((a1 - a0) / 0.5), 1, 24)
	elif kind == 2:
		nseg = clampi(ceili((b1 - b0) / 0.5), 1, 24)
	var white := PackedColorArray([Color.WHITE])
	for i in nseg:
		var sa0 := a0
		var sa1 := a1
		var sb0 := b0
		var sb1 := b1
		if kind == 1:
			sa0 = lerpf(a0, a1, float(i) / nseg)
			sa1 = lerpf(a0, a1, float(i + 1) / nseg)
		elif kind == 2:
			sb0 = lerpf(b0, b1, float(i) / nseg)
			sb1 = lerpf(b0, b1, float(i + 1) / nseg)
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for corner in [[sa0, sb0], [sa1, sb0], [sa1, sb1], [sa0, sb1]]:
			var a: float = corner[0]
			var b: float = corner[1]
			if kind == 0:
				pts.append(_p(a, b, k))
			elif kind == 1:
				pts.append(_p(k, b, a))
			else:
				pts.append(_p(a, k, b))
			uvs.append(Vector2(a / size + ou, -b / size + ov))
		var mnx := minf(minf(pts[0].x, pts[1].x), minf(pts[2].x, pts[3].x))
		var mxx := maxf(maxf(pts[0].x, pts[1].x), maxf(pts[2].x, pts[3].x))
		var mny := minf(minf(pts[0].y, pts[1].y), minf(pts[2].y, pts[3].y))
		var mxy := maxf(maxf(pts[0].y, pts[1].y), maxf(pts[2].y, pts[3].y))
		if mxx < 0.0 or mnx > 640.0 or mxy < 0.0 or mny > 360.0 or mxx - mnx > 4000.0 or mxy - mny > 4000.0:
			continue
		c.ci.draw_polygon(pts, white, uvs, tex)


## A bunch of grapes hanging from (x,y,z): stem, a leaf, then rows of 3-2-1 berries.
static func _grapes(c, x: float, y: float, z: float, size: float) -> void:
	var d := z - HallCam.CAM.z
	if d < 0.8:
		return
	var s := HallCam.F / d
	var pt := _p(x, y, z)
	if pt.x < -10 or pt.x > 650 or pt.y < -10 or pt.y > 370:
		return
	var r := clampi(roundi(size * s * 0.5), 1, 3)
	var px := roundi(pt.x)
	var py := roundi(pt.y)
	c.vline(px, py - r - 2, py, PAL.STEM)
	c.rect(px + 1, py - r - 2, r + 1, 1, PAL.VINE[3])
	var rows := [[-1.0, 0.0, 1.0], [-0.5, 0.5], [0.0]]
	var yy := py
	for row in rows:
		for off in row:
			var bx := roundi(px + off * r * 2.0) - r
			c.rect(bx, yy, r * 2, r * 2, PAL.GRAPE_M)
			c.rect(bx, yy + r * 2 - 1, r * 2, 1, PAL.GRAPE_D)
			c.px(bx, yy, PAL.GRAPE_L)
			if r >= 2:
				c.px(bx + 1, yy, PAL.GRAPE_L)
		yy += r * 2 - 1


## Points of a pointed arch (world x,y on plane z) from bottom-left up and over to bottom-right.
static func _arch(cx: float, half: float, yb: float, ys: float, ya: float, z: float, n := 9) -> PackedVector2Array:
	var ha := ya - ys
	var R := (half * half + ha * ha) / (2.0 * half)
	var th_a := atan2(ha, half - R)
	var out := PackedVector2Array()
	out.append(_p(cx - half, yb, z))
	out.append(_p(cx - half, ys, z))
	var xc := cx - half + R
	for i in range(1, n + 1):
		var th := lerpf(PI, th_a, float(i) / n)
		out.append(_p(xc + R * cos(th), ys + R * sin(th), z))
	var xc2 := cx + half - R
	for i in range(n - 1, -1, -1):
		var th := lerpf(0.0, PI - th_a, float(i) / n)
		out.append(_p(xc2 + R * cos(th), ys + R * sin(th), z))
	out.append(_p(cx + half, yb, z))
	return out


static func _sky_col(y: float, wt: float) -> Color:
	var r := wt - y
	if r < 9:
		return PAL.SKY_6
	if r < 20:
		return PAL.SKY_5
	if r < 36:
		return PAL.SKY_4
	if r < 60:
		return PAL.SKY_3
	if r < 92:
		return PAL.SKY_2
	return PAL.SKY_1


# ======================================================================= far

static func _pt(name: String, t0: int) -> void:
	var d := Time.get_ticks_usec() - t0
	LAYER_PROF[name] = LAYER_PROF.get(name, 0) + d

static var LAYER_PROF := {}

static func paint_far(c) -> void:
	_tick()
	var wt := _p(0.0, WALL_TOP, PZ).y
	var t0 := Time.get_ticks_usec()
	_sky(c, wt)
	_pt("sky", t0); t0 = Time.get_ticks_usec()
	_palace(c)
	_pt("palace", t0); t0 = Time.get_ticks_usec()
	_towers(c)
	_pt("towers", t0); t0 = Time.get_ticks_usec()
	_side_walls(c)
	_pt("sidewalls", t0)


static func _sky(c, wt: float) -> void:
	c.rect(0, 0, 640, 360, PAL.SKY_1)
	var bounds: Array = [92.0, 60.0, 36.0, 20.0, 9.0]
	var cols: Array = [PAL.SKY_2, PAL.SKY_3, PAL.SKY_4, PAL.SKY_5, PAL.SKY_6]
	for i in bounds.size():
		var y := int(wt - bounds[i])
		c.rect(0, y, 640, 400, cols[i])
		# dithered seam into the band above
		var above: Color = PAL.SKY_1 if i == 0 else cols[i - 1]
		var quad := PackedVector2Array([Vector2(0, y), Vector2(640, y), Vector2(640, y + 4), Vector2(0, y + 4)])
		_dither(c, quad, above)
	# stars in the deep bands
	for i in 60:
		var sy := int(_h(i, 1, 5) * maxf(wt - 70.0, 1.0)) + 2
		var sx := int(_h(i, 2, 5) * 640.0)
		if sy < wt - 62:
			var tw := sin(T * 1.3 + i) > 0.6
			c.px(sx, sy, PAL.SKY_3 if tw else Pal.PARCHMENT)
	# flat dusk clouds drifting
	for i in 5:
		var cy := wt - 24.0 - _h(i, 3, 9) * 30.0
		var cx := fposmod(_h(i, 4, 9) * 700.0 + T * (1.2 + _h(i, 5, 9)), 720.0) - 40.0
		var cw := 26.0 + _h(i, 6, 9) * 24.0
		c.ellipse(cx, cy, cw, 3.0, PAL.CLOUD)
		c.ellipse(cx - cw * 0.2, cy - 2, cw * 0.55, 2.5, PAL.CLOUD)
		c.hline(int(cx - cw * 0.7), int(cx + cw * 0.7), int(cy + 2), PAL.CLOUD_LIT)
	# crescent moon (kept above the roofline, never behind a post)
	var my := maxf(wt - 64.0, 14.0)
	var mx := 470.0
	c.ellipse(mx, my, 9.0, 9.0, Pal.PARCHMENT)
	c.ellipse(mx + 4.0, my - 2.0, 8.0, 8.0, _sky_col(my, wt))
	# swallows
	for i in 3:
		var bx := fposmod(T * (9.0 + i * 3.0) + i * 210.0, 700.0) - 30.0
		var by := wt - 14.0 - i * 9.0 + sin(T * 2.0 + i) * 2.0
		var flap := int(T * 6.0 + i) % 2
		c.px(int(bx), int(by), Pal.INK)
		c.px(int(bx) - 1, int(by) - flap, Pal.INK)
		c.px(int(bx) + 1, int(by) - flap, Pal.INK)
		c.px(int(bx) - 2, int(by) - 1 + flap, Pal.INK)
		c.px(int(bx) + 2, int(by) - 1 + flap, Pal.INK)


static func _palace(c) -> void:
	var z := PZ
	# only the stretch of wall that can be on screen
	var half := 350.0 / HallCam.scale_at(z) + 0.4
	var xl := maxf(-PW, HallCam.CAM.x - half)
	var xr := minf(PW, HallCam.CAM.x + half)
	var body := _quad_z(c, z, xl, xr, FY, WALL_TOP, Pal.STONE)
	# brick courses: one baked, repeating tile (1.6 x 0.96 world units)
	var bt := _brick_tile()
	var wpts := PackedVector2Array([_p(xl, FY, z), _p(xr, FY, z), _p(xr, WALL_TOP, z), _p(xl, WALL_TOP, z)])
	var wuv := PackedVector2Array([Vector2(xl / 1.6, -FY / 0.96), Vector2(xr / 1.6, -FY / 0.96), Vector2(xr / 1.6, -WALL_TOP / 0.96), Vector2(xl / 1.6, -WALL_TOP / 0.96)])
	c.ci.draw_polygon(wpts, PackedColorArray([Color.WHITE]), wuv, bt)
	# dusk-lit upper wall: dither light from the west sky
	var lit := PackedVector2Array([_p(xl, 0.9, z), _p(xr, 0.9, z), _p(xr, WALL_TOP, z), _p(xl, WALL_TOP, z)])
	_dither(c, lit, Pal.STONE_LIGHT)
	c.poly_outline(body, Pal.INK)
	# cornice + crenellations
	_quad_z(c, z, xl, xr, WALL_TOP - 0.17, WALL_TOP, Pal.STONE_LIGHT)
	c.linev(_p(xl, WALL_TOP - 0.17, z), _p(xr, WALL_TOP - 0.17, z), Pal.INK)
	var mx := floorf(xl / 0.5) * 0.5
	while mx < xr:
		_quad_z(c, z, mx + 0.08, mx + 0.36, WALL_TOP, WALL_TOP + 0.26, Pal.STONE_LIGHT)
		c.poly_outline(PackedVector2Array([_p(mx + 0.08, WALL_TOP, z), _p(mx + 0.08, WALL_TOP + 0.26, z), _p(mx + 0.36, WALL_TOP + 0.26, z), _p(mx + 0.36, WALL_TOP, z)]), Pal.INK)
		mx += 0.5

	# the great pointed arch, recessed, with a gold thread
	var arch_out := _arch(0.0, 0.86, FY, 0.95, 2.5, z)
	_fill(c, arch_out, Pal.STONE_HI)
	var arch_in := _arch(0.0, 0.74, FY, 0.95, 2.36, z)
	_fill(c, arch_in, Pal.STONE_DARK)
	var arch_gold := _arch(0.0, 0.70, FY, 0.95, 2.30, z)
	c.poly_outline(arch_gold, Pal.GOLD)
	c.poly_outline(arch_out, Pal.INK)
	c.poly_outline(arch_in, Pal.INK)
	# brick shading in the recess
	_dither(c, arch_in, Pal.STONE_DEEP)

	# rose window
	var rc := _p(0.0, 1.55, z)
	var rr := 0.34 * HallCam.scale_at(z)
	c.ellipse(rc.x, rc.y, rr + 2, rr + 2, Pal.GOLD_DARK)
	c.ellipse(rc.x, rc.y, rr, rr, Pal.ROYAL)
	for k in 8:
		var ang := TAU * k / 8.0 + PI / 8.0
		var lc := Vector2(rc.x + cos(ang) * rr * 0.55, rc.y + sin(ang) * rr * 0.55)
		var petal := PixelCanvas.ellipse_points(lc.x, lc.y, rr * 0.30, rr * 0.19, ang, 10)
		_fill(c, petal, Pal.CRIMSON if k % 2 == 0 else Pal.ROYAL_LIGHT)
	c.ellipse(rc.x, rc.y, rr * 0.22, rr * 0.22, Pal.GOLD)
	c.poly_outline(PixelCanvas.ellipse_points(rc.x, rc.y, rr, rr, 0.0, 28), Pal.INK)
	for k in 8:
		var ang := TAU * k / 8.0
		c.line(roundi(rc.x), roundi(rc.y), roundi(rc.x + cos(ang) * rr), roundi(rc.y + sin(ang) * rr), Pal.INK)
	c.ellipse(rc.x, rc.y, rr * 0.16, rr * 0.16, Pal.GOLD_LIGHT)

	# the doorway
	var door_out := _arch(0.0, 0.46, FY, 0.10, 0.92, z)
	_fill(c, door_out, Pal.STONE_HI)
	var door_in := _arch(0.0, 0.38, FY, 0.10, 0.82, z)
	_fill(c, door_in, Pal.ROYAL_DARK)
	var glow := _arch(0.0, 0.38, FY, 0.10, 0.82, z)
	# two door leaves, panelled, warm light in the crack
	var d0 := _p(0.0, FY, z)
	var d1 := _p(0.0, 0.82, z)
	c.line(roundi(d0.x), roundi(d0.y), roundi(d1.x), roundi(d1.y), Pal.INK)
	c.line(roundi(d0.x) + 1, roundi(d0.y), roundi(d1.x) + 1, roundi(d1.y), PAL.WARM if fmod(T, 2.0) < 1.6 else PAL.SKY_5)
	for sgn in [-1.0, 1.0]:
		for py in [0.0, 0.42]:
			var pn := PackedVector2Array([_p(sgn * 0.05 if sgn > 0 else sgn * 0.33, FY + 0.15 + py * 0.6, z), _p(sgn * 0.33 if sgn > 0 else sgn * 0.05, FY + 0.15 + py * 0.6, z), _p(sgn * 0.33 if sgn > 0 else sgn * 0.05, FY + 0.58 + py * 0.6, z), _p(sgn * 0.05 if sgn > 0 else sgn * 0.33, FY + 0.58 + py * 0.6, z)])
			_fill(c, pn, Pal.ROYAL)
			c.poly_outline(pn, Pal.GOLD)
	var dc := _p(0.0, -0.5, z)
	c.rect(roundi(dc.x) - 3, roundi(dc.y), 2, 2, Pal.GOLD_LIGHT)
	c.rect(roundi(dc.x) + 2, roundi(dc.y), 2, 2, Pal.GOLD_LIGHT)
	c.poly_outline(door_out, Pal.INK)
	c.poly_outline(door_in, Pal.GOLD_DARK)
	var lint := _p(0.0, 0.98, z)
	c.rect(roundi(lint.x) - 1, roundi(lint.y) - 1, 3, 3, Pal.GOLD)

	# framing pilasters with gold caps
	for sd in [-1.0, 1.0]:
		for px in [0.98, 1.9, 3.0, 4.2]:
			var xx: float = sd * px
			var x0: float = xx - 0.13
			var x1: float = xx + 0.13
			_quad_z(c, z - 0.02, x0, x1, FY, 1.68, Pal.STONE_LIGHT)
			_dither(c, PackedVector2Array([_p(x0, FY, z), _p(xx, FY, z), _p(xx, 1.68, z), _p(x0, 1.68, z)]), Pal.STONE_HI)
			c.poly_outline(PackedVector2Array([_p(x0, FY, z), _p(x1, FY, z), _p(x1, 1.68, z), _p(x0, 1.68, z)]), Pal.INK)
			_quad_z(c, z - 0.02, x0 - 0.04, x1 + 0.04, 1.58, 1.7, Pal.GOLD)
			_quad_z(c, z - 0.02, x0 - 0.04, x1 + 0.04, FY, FY + 0.12, Pal.STONE_HI)

	# lancet windows, lit gold with blue tracery
	for sd in [-1.0, 1.0]:
		var wx: float = sd * 1.44
		var frame := _arch(wx, 0.24, -0.05, 1.05, 1.6, z)
		_fill(c, frame, Pal.STONE_HI)
		var glass := _arch(wx, 0.18, 0.0, 1.05, 1.5, z)
		_fill(c, glass, Pal.GOLD)
		_dither(c, glass, Pal.GOLD_LIGHT)
		var g0 := _p(wx, 0.0, z)
		var g1 := _p(wx, 1.5, z)
		c.line(roundi(g0.x), roundi(g0.y), roundi(g1.x), roundi(g1.y), Pal.ROYAL)
		for gy in [0.35, 0.7, 1.05]:
			var l0 := _p(wx - 0.18, gy, z)
			var l1 := _p(wx + 0.18, gy, z)
			c.line(roundi(l0.x), roundi(l0.y), roundi(l1.x), roundi(l1.y), Pal.ROYAL)
		var pane := _arch(wx, 0.08, 0.5, 1.05, 1.22, z)
		_fill(c, pane, Pal.ROYAL)
		c.poly_outline(frame, Pal.INK)
		c.poly_outline(glass, Pal.GOLD_DARK)
		_quad_z(c, z - 0.02, wx - 0.3, wx + 0.3, -0.13, -0.05, Pal.STONE_LIGHT)

	# banners (sway a little)
	var specs: Array = [[-0.62, Pal.CRIMSON, Pal.CRIMSON_DARK], [0.62, Pal.GOLD, Pal.GOLD_DARK], [-2.05, Pal.ROYAL, Pal.ROYAL_DARK], [2.05, Pal.CRIMSON, Pal.CRIMSON_DARK], [-3.6, Pal.CRIMSON, Pal.CRIMSON_DARK], [3.6, Pal.ROYAL, Pal.ROYAL_DARK]]
	# (inner two hang inside the arch flanks, outer two on the wall ends)
	for s in specs.size():
		var sp: Array = specs[s]
		_banner(c, float(sp[0]), 1.6, 0.34, 1.15, sp[1], sp[2], z - 0.03, s)
	for sd in [-1.0, 1.0]:
		var sc: float = sd * 1.0
		_banner(c, sd * 1.72, 1.6, 0.24, 0.9, Pal.ROYAL if sd < 0 else Pal.CRIMSON, Pal.ROYAL_DARK if sd < 0 else Pal.CRIMSON_DARK, z - 0.03, 5 + int(sd))
	# ivy creeping up the wall base
	for sd in [-1.0, 1.0]:
		_leaf_plane(c, 0, z - 0.04, minf(sd * 0.98, sd * 2.4), maxf(sd * 0.98, sd * 2.4), FY, -0.35, 0.06, 61 if sd < 0 else 62, PAL.VINE, 0.05, 0.75, 0.15)


static func _banner(c, cx: float, ytop: float, w: float, len: float, col: Color, dark: Color, z: float, phase: int) -> void:
	var sway := sin(T * 1.4 + phase * 1.3) * 0.02
	var x0 := cx - w * 0.5
	var x1 := cx + w * 0.5
	var yb := ytop - len
	var pts := PackedVector2Array([
		_p(x0, ytop, z), _p(x1, ytop, z), _p(x1 + sway, yb, z),
		_p(cx + sway * 1.6, yb + w * 0.55, z), _p(x0 + sway, yb, z)])
	_fill(c, pts, col)
	_dither(c, PackedVector2Array([_p(cx, ytop, z), _p(x1, ytop, z), _p(x1 + sway, yb, z), _p(cx + sway * 1.6, yb + w * 0.55, z)]), dark)
	c.poly_outline(pts, Pal.INK)
	var top0 := _p(x0 - 0.03, ytop + 0.02, z)
	var top1 := _p(x1 + 0.03, ytop + 0.02, z)
	c.rect(roundi(top0.x), roundi(top0.y) - 1, roundi(top1.x - top0.x), 2, Pal.WOOD_LIGHT)
	var ec := _p(cx + sway * 0.5, ytop - len * 0.35, z)
	var er := maxi(2, roundi(w * 0.22 * HallCam.scale_at(z)))
	c.rect(roundi(ec.x) - er, roundi(ec.y) - er, er * 2, er * 2, Pal.GOLD)
	c.rect(roundi(ec.x) - er + 1, roundi(ec.y) - er + 1, maxi(1, er * 2 - 2), maxi(1, er * 2 - 2), col if col != Pal.GOLD else Pal.ROYAL)
	c.px(roundi(ec.x), roundi(ec.y), Pal.GOLD_LIGHT)


static func _side_walls(c) -> void:
	for sd in [-1.0, 1.0]:
		var x: float = sd * WALL_X
		var top := 1.5
		_quad_x(c, x, FY, top, ZN, SW_END, PAL.WALL[1])
		_leaf_plane(c, 1, x, ZN, SW_END, FY, top, 0.1, 71 if sd < 0 else 72, PAL.WALL, 0.0, 0.85)
		# cypress spires in front of the hedge wall
		var zc := -6.9
		var idx := 0
		while zc < SW_END:
			if zc + 0.7 > ZN:
				_cypress(c, x - sd * 0.12, zc, 0.56, 2.5 + _h(idx, int(sd), 3) * 0.9, idx + (0 if sd < 0 else 40), sd)
			zc += 1.32
			idx += 1


static func _cypress(c, x: float, zc: float, hw: float, ytop: float, seed: int, sd: float) -> void:
	var pts_l := PackedVector2Array()
	var pts_r := PackedVector2Array()
	var y0 := FY
	var n := 12
	for i in n + 1:
		var t := float(i) / n
		var y := lerpf(y0, ytop, t)
		var w := hw * (1.0 - pow(t, 1.7)) * (0.88 + 0.12 * sin(t * 11.0 + seed))
		pts_l.append(_p(x, y, zc - w))
		pts_r.append(_p(x, y, zc + w))
	var poly := PackedVector2Array()
	for p in pts_l:
		poly.append(p)
	for i in range(pts_r.size() - 1, -1, -1):
		poly.append(pts_r[i])
	_fill(c, poly, PAL.CYPRESS[1])
	# lit flank towards the palace glow, dithered
	var lit := PackedVector2Array()
	for i in n - 1:
		var t := float(i) / n
		var y := lerpf(y0, ytop, t)
		var w := hw * (1.0 - pow(t, 1.7))
		lit.append(_p(x, y, zc + w * 0.1))
	for i in range(n - 2, -1, -1):
		var t2 := float(i) / n
		var y2 := lerpf(y0, ytop, t2)
		var w2 := hw * (1.0 - pow(t2, 1.7))
		lit.append(_p(x, y2, zc + w2 * 0.95))
	_dither(c, lit, PAL.CYPRESS[3])
	c.poly_outline(poly, PAL.CYPRESS[0])
	# leaf flicks
	var cell := 0.15
	var m := 0
	for i in 26:
		var u := _h(i, seed, 81)
		var t := _h(i, seed, 82) * 0.9
		var y := lerpf(y0, ytop, t)
		var w := hw * (1.0 - pow(t, 1.7)) * 0.85
		var p := _p(x, y, zc + (u * 2.0 - 1.0) * w)
		var wpx := maxi(2, roundi(cell * HallCam.scale_at(zc) * 1.2))
		c.rect(roundi(p.x), roundi(p.y), wpx, maxi(1, wpx / 2), PAL.CYPRESS[2] if u > 0.5 else PAL.CYPRESS[0])


static func _towers(c) -> void:
	for sd in [-1.0, 1.0]:
		var xa: float = minf(sd * 2.85, sd * 3.75)
		var xb: float = maxf(sd * 2.85, sd * 3.75)
		var z0 := PZ - 0.8
		_box(c, xa, xb, FY, 2.7, z0, PZ, Pal.STONE, Pal.STONE_LIGHT, Pal.STONE_DARK)
		# tower front detail: slit window + brick lines
		var wy := 1.4
		var sl := _pts_z(z0, sd * 3.3 - 0.05, sd * 3.3 + 0.05, wy, wy + 0.5)
		_fill(c, sl, Pal.INK)
		var y := FY + 0.2
		while y < 2.65:
			c.linev(_p(xa, y, z0), _p(xb, y, z0), Pal.GROUT)
			y += 0.2
		# roof
		var mid := (xa + xb) * 0.5
		var apex := _p(mid, 3.5, (z0 + PZ) * 0.5)
		var front := PackedVector2Array([_p(xa - 0.06, 2.7, z0 - 0.06), _p(xb + 0.06, 2.7, z0 - 0.06), apex])
		_fill(c, front, Pal.CRIMSON)
		_dither(c, front, Pal.CRIMSON_DARK)
		c.poly_outline(front, Pal.INK)
		var pole := _p(mid, 3.5, (z0 + PZ) * 0.5)
		c.vline(roundi(pole.x), roundi(pole.y) - 6, roundi(pole.y), Pal.INK)
		c.rect(roundi(pole.x) + 1, roundi(pole.y) - 6, 4, 2, Pal.GOLD)


static func _pts_z(z: float, x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([_p(x0, y0, z), _p(x1, y0, z), _p(x1, y1, z), _p(x0, y1, z)])


# ===================================================================== floor

static func paint_floor(c) -> void:
	_tick()
	var t0 := Time.get_ticks_usec()
	_lawn(c)
	_pt("lawn", t0); t0 = Time.get_ticks_usec()
	_path(c)
	_pt("path", t0); t0 = Time.get_ticks_usec()
	_plaza(c)
	_pt("plaza", t0); t0 = Time.get_ticks_usec()
	_light_pools(c)
	_pt("pools", t0)
	_steps(c)


static func _lawn(c) -> void:
	_quad_y(c, FY, -PW, PW, ZN, PZ, PAL.GRASS_A)
	# mown stripes
	var z := floorf(ZN / 0.9) * 0.9
	var i := 0
	while z < PZ:
		if i % 2 == 0:
			var za := maxf(z, ZN)
			var zb := minf(z + 0.9, PZ)
			if zb > za:
				_quad_y(c, FY, -PW, PW, za, zb, PAL.GRASS_B)
		z += 0.9
		i += 1
	_leaf_plane(c, 2, FY, -6.0, 6.0, maxf(ZN, -8.0), PZ, 0.13, 91, PAL.GRASS, 0.0, 0.6)
	# soil strips under the hedge planters
	for sd in [-1.0, 1.0]:
		_quad_y(c, FY, minf(sd * 1.1, sd * 1.9), maxf(sd * 1.1, sd * 1.9), ZN, PZ, PAL.SOIL)
		_leaf_plane(c, 2, FY, minf(sd * 1.1, sd * 1.9), maxf(sd * 1.1, sd * 1.9), maxf(ZN, -8.0), PZ, 0.12, 92, PAL.GRASS, 0.0, 0.35)


static func _path(c) -> void:
	var z0 := ZN
	_quad_y(c, FY, -PATH_HALF, PATH_HALF, z0, PZ, Pal.GROUT)
	var tones: Array = [PAL.PAVE_A, PAL.PAVE_B, PAL.PAVE_C]
	var row_d := 0.55
	var col_w := 0.42
	var zr := floorf(z0 / row_d) * row_d
	var r := int(floorf(z0 / row_d))
	while zr < PZ:
		var za := maxf(zr + 0.02, z0)
		var zb := minf(zr + row_d - 0.02, PZ)
		if zb > za:
			var shift := 0.21 if r % 2 != 0 else 0.0
			var x := -PATH_HALF - col_w + shift
			var ci := 0
			while x < PATH_HALF:
				var xa := maxf(x + 0.02, -PATH_HALF)
				var xb := minf(x + col_w - 0.02, PATH_HALF)
				if xb > xa:
					var hv := _h(ci + int(shift * 100), r, 17)
					var col: Color = tones[int(hv * 3.0) % 3]
					_quad_y(c, FY, xa, xb, za, zb, col)
					# chipped lighter edge on the far side of the slab (lit by the palace glow)
					if hv > 0.55:
						c.linev(_p(xa, FY, zb), _p(xb, FY, zb), PAL.PAVE_HI)
					if hv < 0.25:
						var pq := PackedVector2Array([_p(xa, FY, za), _p(xb, FY, za), _p(xb, FY, zb), _p(xa, FY, zb)])
						_dither(c, pq, PAL.PAVE_C)
				x += col_w
				ci += 1
		zr += row_d
		r += 1
	# kerb
	for sd in [-1.0, 1.0]:
		var ka: float = minf(sd * PATH_HALF, sd * (PATH_HALF + 0.14))
		var kb: float = maxf(sd * PATH_HALF, sd * (PATH_HALF + 0.14))
		_box(c, ka, kb, FY, FY + 0.07, ZN, PZ, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)


static func _ring_pts(cx: float, cz: float, r: float, a0: float, a1: float, n: int) -> Array:
	var out: Array = []
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(_p(cx + cos(a) * r, FY, cz + sin(a) * r))
	return out


static func _wedge(c, r0: float, r1: float, a0: float, a1: float, col: Color) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in _ring_pts(0.0, PLAZA_Z, r1, a0, a1, 3):
		pts.append(p)
	var inner := _ring_pts(0.0, PLAZA_Z, r0, a0, a1, 3)
	for i in range(inner.size() - 1, -1, -1):
		pts.append(inner[i])
	_fill(c, pts, col)
	return pts


static func _plaza(c) -> void:
	if PLAZA_Z + PLAZA_R < ZN:
		return
	# apron shadow ring + raised lip
	var apron := PackedVector2Array(_ring_pts(0.0, PLAZA_Z, PLAZA_R + 0.05, 0.0, TAU - 0.001, 40))
	_fill(c, apron, Pal.GROUT)
	var n_out := 26
	for i in n_out:
		var a0 := TAU * i / n_out + 0.012
		var a1 := TAU * (i + 1) / n_out - 0.012
		var col: Color = PAL.PLAZA_OUT if i % 2 == 0 else PAL.PLAZA_OUT2
		var w := _wedge(c, 0.80, PLAZA_R, a0, a1, col)
		if _h(i, 3, 44) > 0.6:
			_dither(c, w, PAL.PLAZA_OUT2 if i % 2 == 0 else PAL.PLAZA_OUT)
	var n_mid := 18
	for i in n_mid:
		var a0 := TAU * (i + 0.5) / n_mid + 0.015
		var a1 := TAU * (i + 1.5) / n_mid - 0.015
		var col: Color = PAL.PLAZA_MID if i % 2 == 0 else PAL.PLAZA_MID2
		_wedge(c, 0.50, 0.77, a0, a1, col)
	var disc := PackedVector2Array(_ring_pts(0.0, PLAZA_Z, 0.47, 0.0, TAU - 0.001, 32))
	_fill(c, disc, PAL.PLAZA_IN)
	# compass star in the centre: eight thin spokes, a gold pin
	var cc := _p(0.0, FY, PLAZA_Z)
	for k in 8:
		var a := TAU * k / 8.0
		c.linev(cc, _p(cos(a) * 0.44, FY, PLAZA_Z + sin(a) * 0.44), PAL.PLAZA_MID2)
	_dither(c, disc, PAL.PLAZA_MID)
	c.poly_outline(disc, Pal.STONE_DEEP)
	c.poly_outline(PackedVector2Array(_ring_pts(0.0, PLAZA_Z, 0.79, 0.0, TAU - 0.001, 40)), Pal.STONE_DEEP)
	c.poly_outline(PackedVector2Array(_ring_pts(0.0, PLAZA_Z, PLAZA_R, 0.0, TAU - 0.001, 40)), Pal.INK)
	# moss and cracks
	_leaf_plane(c, 2, FY, -PLAZA_R, PLAZA_R, PLAZA_Z - PLAZA_R, PLAZA_Z + PLAZA_R, 0.16, 96, [PAL.PAVE_C, PAL.GRASS[1], PAL.GRASS[2]], 0.0, 0.09)


static func _light_pools(c) -> void:
	# warm dithered pools under each hanging lantern and in front of the palace door
	for sd in [-1.0, 1.0]:
		for zs in ZS:
			var zc: float = zs
			if zc < ZN - 0.3 or zc > 3.0:
				continue
			_pool(c, sd * 0.92, zc, 0.6, PAL.LIGHT_POOL)
	_pool(c, 0.0, PZ - 1.0, 1.0, PAL.LIGHT_POOL)


static func _pool(c, cx: float, cz: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(_p(cx + cos(a) * r, FY, cz + sin(a) * r * 0.9))
	_dither(c, pts, col)


static func _steps(c) -> void:
	_box(c, -0.62, 0.62, FY, FY + 0.10, PZ - 0.55, PZ, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
	_box(c, -0.52, 0.52, FY + 0.10, FY + 0.20, PZ - 0.30, PZ, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)


# =================================================================== columns

static func paint_columns(c) -> void:
	_tick()
	var items: Array = []
	for sd in [-1.0, 1.0]:
		for k in ZS.size():
			items.append({"z": ZS[k], "kind": "pillar", "sd": sd, "k": k})
			if k < ZS.size() - 1:
				items.append({"z": (ZS[k] + ZS[k + 1]) * 0.5, "kind": "bay", "sd": sd, "k": k})
	items.append({"z": 1.55, "kind": "plinths", "sd": 1.0, "k": 0})
	items.append({"z": 0.3, "kind": "table", "sd": -1.0, "k": 0})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z"] > b["z"])
	for it in items:
		var z: float = it["z"]
		if z + 1.0 < ZN:
			continue
		match it["kind"]:
			"pillar":
				var t1 := Time.get_ticks_usec()
				_pillar(c, it["sd"], ZS[it["k"]], it["k"])
				_pt("pillar", t1)
			"bay":
				var t2 := Time.get_ticks_usec()
				_bay(c, it["sd"], it["k"])
				_pt("bay", t2)
			"plinths":
				_plinths(c)
			"table":
				_table(c)


static func _is_open_bay(sd: float, k: int) -> bool:
	return k == 4


static func _pillar(c, sd: float, zc: float, k: int) -> void:
	if zc + 0.3 < ZN:
		return
	var xa: float = minf(sd * (PX - 0.13), sd * (PX + 0.13))
	var xb: float = maxf(sd * (PX - 0.13), sd * (PX + 0.13))
	var za := zc - 0.13
	var zb := zc + 0.13
	# plinth, shaft, capital
	_box(c, minf(sd * (PX - 0.2), sd * (PX + 0.2)), maxf(sd * (PX - 0.2), sd * (PX + 0.2)), FY, FY + 0.28, zc - 0.2, zc + 0.2, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
	_box(c, xa, xb, FY + 0.28, BEAM_Y - 0.12, za, zb, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
	_pillar_shading(c, sd, zc)
	_box(c, minf(sd * (PX - 0.19), sd * (PX + 0.19)), maxf(sd * (PX - 0.19), sd * (PX + 0.19)), BEAM_Y - 0.12, BEAM_Y, zc - 0.19, zc + 0.19, Pal.STONE_HI, Pal.STONE_HI, Pal.STONE_LIGHT)
	# cross beam out to the hedge wall, then hanging vines and a banner
	var bx0: float = minf(sd * (PX - 0.12), sd * WALL_X)
	var bx1: float = maxf(sd * (PX - 0.12), sd * WALL_X)
	_box(c, bx0, bx1, BEAM_Y, BEAM_Y + 0.13, zc - 0.07, zc + 0.07, Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.WOOD)
	# vine wrapped up the shaft
	var vxa: float = minf(sd * (PX - 0.14), sd * (PX + 0.14))
	var vxb: float = maxf(sd * (PX - 0.14), sd * (PX + 0.14))
	var side_x: float = vxa if HallCam.CAM.x < vxa else vxb
	_leaf_plane(c, 1, side_x, zc - 0.13, zc + 0.13, FY + 0.3, BEAM_Y - 0.12, 0.05, 121 + k + (0 if sd < 0 else 30), PAL.VINE, 0.05, 0.55, 0.12)
	_leaf_plane(c, 0, zc - 0.13, minf(sd * (PX - 0.13), sd * (PX + 0.13)), maxf(sd * (PX - 0.13), sd * (PX + 0.13)), FY + 0.3, BEAM_Y - 0.12, 0.05, 141 + k + (0 if sd < 0 else 30), PAL.VINE, 0.05, 0.5, 0.12)
	# hanging banner on alternate pillars
	if false:
		var bxs: float = sd * (PX - 0.36)
		var bz := zc - 0.15
		_pend_banner(c, bxs, BEAM_Y - 0.1, 0.3, 0.95, Pal.CRIMSON if sd < 0 else Pal.ROYAL, Pal.CRIMSON_DARK if sd < 0 else Pal.ROYAL_DARK, bz, k)


static func _pillar_shading(c, sd: float, zc: float) -> void:
	var cam := HallCam.CAM
	var xa: float = minf(sd * (PX - 0.13), sd * (PX + 0.13))
	var xb: float = maxf(sd * (PX - 0.13), sd * (PX + 0.13))
	# a dithered dark half down the side face + fluting line
	var fx: float = xa if cam.x < xa else xb
	var q := PackedVector2Array([_p(fx, FY + 0.28, zc - 0.13), _p(fx, FY + 0.28, zc + 0.13), _p(fx, BEAM_Y - 0.12, zc + 0.13), _p(fx, BEAM_Y - 0.12, zc - 0.13)])
	_dither(c, q, Pal.STONE_DARK)
	var m0 := _p(fx, FY + 0.3, zc)
	var m1 := _p(fx, BEAM_Y - 0.14, zc)
	c.linev(m0, m1, Pal.STONE_DARK)


static func _pend_banner(c, cx: float, ytop: float, w: float, len: float, col: Color, dark: Color, z: float, phase: int) -> void:
	# a banner hanging from a pergola beam: drawn flat on the z plane at the pillar
	_banner(c, cx, ytop, w, len, col, dark, z, phase)


static func _bay(c, sd: float, k: int) -> void:
	var z0: float = ZS[k]
	var z1: float = ZS[k + 1]
	if z1 < ZN:
		return
	var open := _is_open_bay(sd, k)
	var seed := k * 7 + (0 if sd < 0 else 3)
	if not open:
		_hedge(c, sd, z0 + 0.24, z1 - 0.24, seed)
	else:
		_open_bay(c, sd, z0, z1, seed)
	_pergola(c, sd, z0, z1, seed)


static func _hedge(c, sd: float, za: float, zb: float, seed: int) -> void:
	var xa: float = minf(sd * 1.18, sd * 1.86)
	var xb: float = maxf(sd * 1.18, sd * 1.86)
	# stone planter base
	_box(c, xa - 0.04 if sd > 0 else xa - 0.04, xb + 0.04, FY, FY + 0.16, za - 0.03, zb + 0.03, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
	var y0 := FY + 0.16
	var y1 := HEDGE_TOP + (0.12 if seed % 3 == 0 else 0.0)
	_box(c, xa, xb, y0, y1, za, zb, PAL.HEDGE[1], PAL.HEDGE[2], PAL.HEDGE[0], false)
	# leaf textures: front (z), path-facing side (x), top (y)
	var cam := HallCam.CAM
	var side_x: float = xa if cam.x < xa else xb
	if za >= ZN:
		_leaf_plane(c, 0, za, xa, xb, y0, y1 + 0.03, 0.045, 201 + seed, PAL.HEDGE, 0.0)
	_leaf_plane(c, 1, side_x, maxf(za, ZN), zb, y0, y1 + 0.03, 0.045, 231 + seed, PAL.HEDGE, -0.14)
	if cam.y > y1:
		_leaf_plane(c, 2, y1, xa, xb, maxf(za, ZN), zb, 0.045, 261 + seed, PAL.HEDGE, 0.05)
		# sunlit tips + a few blossoms
		for i in 5:
			var fxp := lerpf(xa + 0.1, xb - 0.1, _h(i, seed, 55))
			var fzp := lerpf(za + 0.1, zb - 0.1, _h(i, seed, 56))
			if fzp < ZN + 0.3:
				continue
			var fp := _p(fxp, y1, fzp)
			var col: Color = Pal.PARCHMENT if i % 3 == 0 else (Pal.CRIMSON_LIGHT if i % 3 == 1 else Pal.GOLD_LIGHT)
			c.px(roundi(fp.x), roundi(fp.y), col)
			c.px(roundi(fp.x) + 1, roundi(fp.y), col)
	# outline the visible faces with the darkest green (softer than ink on foliage)
	var front := _pts_z(za, xa, xb, y0, y1)
	if za >= ZN:
		c.poly_outline(front, PAL.HEDGE[0])
	var sq := PackedVector2Array([_p(side_x, y0, maxf(za, ZN)), _p(side_x, y0, zb), _p(side_x, y1, zb), _p(side_x, y1, maxf(za, ZN))])
	c.poly_outline(sq, PAL.HEDGE[0])
	# topiary ball at the near end
	if seed % 2 == 0 and za > ZN:
		_topiary(c, (xa + xb) * 0.5, y1, za + 0.02, seed)


static func _topiary(c, x: float, y: float, z: float, seed: int) -> void:
	var s := HallCam.scale_at(z)
	var base := _p(x, y, z)
	var r := 0.19 * s
	c.rect(roundi(base.x) - roundi(r * 0.4), roundi(base.y) - 1, maxi(2, roundi(r * 0.8)), 3, Pal.STONE_HI)
	var cc := Vector2(base.x, base.y - r * 1.05)
	c.ellipse(cc.x, cc.y, r, r, PAL.HEDGE[2])
	c.ellipse(cc.x - r * 0.25, cc.y - r * 0.25, r * 0.6, r * 0.6, PAL.HEDGE[3])
	c.poly_outline(PixelCanvas.ellipse_points(cc.x, cc.y, r, r, 0.0, 14), PAL.HEDGE[0])
	for i in 8:
		var a := _h(i, seed, 71) * TAU
		var rad := _h(i, seed, 72) * r * 0.75
		c.px(roundi(cc.x + cos(a) * rad), roundi(cc.y + sin(a) * rad), PAL.HEDGE[4])


static func _open_bay(c, sd: float, z0: float, z1: float, seed: int) -> void:
	# a grassy alcove: a low stone bench against the hedge wall and two flower tubs
	var xa: float = minf(sd * 1.9, sd * 2.25)
	var xb: float = maxf(sd * 1.9, sd * 2.25)
	var zc := (z0 + z1) * 0.5
	_box(c, xa, xb, FY, FY + 0.34, zc - 0.55, zc + 0.55, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
	for sg in [-0.7, 0.7]:
		var tx := sd * 1.55
		var tz: float = zc + sg
		_box(c, tx - 0.15, tx + 0.15, FY, FY + 0.26, tz - 0.15, tz + 0.15, Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.WOOD)
		_leaf_plane(c, 2, FY + 0.27, tx - 0.15, tx + 0.15, tz - 0.15, tz + 0.15, 0.04, 301 + seed, PAL.HEDGE, 0.3, 1.0)
		for i in 6:
			var fp := _p(tx - 0.12 + _h(i, seed, 91) * 0.24, FY + 0.33, tz - 0.12 + _h(i, seed, 92) * 0.24)
			c.px(roundi(fp.x), roundi(fp.y), Pal.CRIMSON_LIGHT if i % 2 == 0 else Pal.PARCHMENT)


static func _pergola(c, sd: float, z0: float, z1: float, seed: int) -> void:
	var cam := HallCam.CAM
	var za := maxf(z0, ZN)
	if z1 <= za:
		return
	# long beam along the path edge
	var bx: float = sd * (PX - 0.1)
	_box(c, minf(bx - 0.06, bx + 0.06), maxf(bx - 0.06, bx + 0.06), BEAM_Y, BEAM_Y + 0.13, za, z1, Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.WOOD)
	# canopy of leaves roofing the bay, seen from below or above
	var xa: float = minf(sd * (PX - 0.1), sd * WALL_X)
	var xb: float = maxf(sd * (PX - 0.1), sd * WALL_X)
	_leaf_plane(c, 2, BEAM_Y + 0.12, xa, xb, za, z1, 0.06, 401 + seed, PAL.VINE, 0.1, 0.3, 0.1)
	# valance of vine hanging from the path-edge beam
	var vx: float = sd * (PX - 0.14)
	var drop := 0.32
	_leaf_plane(c, 1, vx, za, z1, BEAM_Y - drop, BEAM_Y + 0.05, 0.05, 431 + seed, PAL.VINE, 0.0, 0.7, 0.16)
	# ragged tendrils below the valance + grape bunches
	var zz := floorf(za / 0.22) * 0.22
	var i := 0
	while zz < z1:
		if zz > ZN + 0.15:
			var len := 0.04 + _h(i, seed, 411) * 0.16
			var top := _p(vx, BEAM_Y - drop, zz)
			var bot := _p(vx, BEAM_Y - drop - len, zz)
			c.linev(top, bot, PAL.VINE[1])
			if _h(i, seed, 412) > 0.45:
				_grapes(c, vx, BEAM_Y - drop - len, zz, 0.035 + _h(i, seed, 413) * 0.015)
			elif _h(i, seed, 414) > 0.5:
				c.rect(roundi(bot.x) - 1, roundi(bot.y), 3, 2, PAL.VINE[3])
		zz += 0.22
		i += 1


static func _plinths(c) -> void:
	# stone plinths flanking the palace door, each with a candelabra
	for sd in [-1.0, 1.0]:
		var x: float = sd * 0.86
		_box(c, x - 0.19, x + 0.19, FY, -0.62, PZ - 0.5, PZ - 0.12, Pal.STONE_LIGHT, Pal.STONE_HI, Pal.STONE)
		_box(c, x - 0.24, x + 0.24, -0.62, -0.52, PZ - 0.54, PZ - 0.08, Pal.STONE_HI, Pal.STONE_HI, Pal.STONE_LIGHT)
		# small dark hedge blocks beside them (like the concept)
		var hx: float = sd * 1.16
		_box(c, hx - 0.17, hx + 0.17, FY, -0.86, PZ - 0.55, PZ - 0.1, PAL.HEDGE[1], PAL.HEDGE[2], PAL.HEDGE[0], false)
		_leaf_plane(c, 0, PZ - 0.55, hx - 0.17, hx + 0.17, FY, -0.84, 0.045, 501, PAL.HEDGE, 0.0)
		_leaf_plane(c, 2, -0.86, hx - 0.17, hx + 0.17, PZ - 0.55, PZ - 0.1, 0.045, 502, PAL.HEDGE, 0.05)
		# candelabra: gold stem, arms, flames (flames are animated in the feast layer)
		var top := _p(x, -0.52, PZ - 0.3)
		var s := HallCam.scale_at(PZ - 0.3)
		var hpx := roundi(0.55 * s)
		var tx := roundi(top.x)
		var ty := roundi(top.y)
		c.rect(tx - 2, ty - 2, 5, 2, Pal.GOLD_DARK)
		c.vline(tx, ty - hpx, ty - 2, Pal.GOLD)
		c.hline(tx - hpx / 3, tx + hpx / 3, ty - hpx * 2 / 3, Pal.GOLD)
		for fx in [-hpx / 3, 0, hpx / 3]:
			c.vline(tx + fx, ty - hpx * 2 / 3 - 3, ty - hpx * 2 / 3, Pal.PARCHMENT)


static func candle_spots() -> Array:
	var out: Array = []
	for sd in [-1.0, 1.0]:
		var x: float = sd * 0.86
		var top := _p(x, -0.52, PZ - 0.3)
		var s := HallCam.scale_at(PZ - 0.3)
		var hpx := roundi(0.55 * s)
		for fx in [-hpx / 3, 0, hpx / 3]:
			out.append(Vector2(roundi(top.x) + fx - 1, roundi(top.y) - hpx * 2 / 3 - 8))
	return out


static func _table(c) -> void:
	# little round table with a cloth, goblets and a bowl of grapes: the toast
	var tx := -1.62
	var tz := 0.3
	if tz < ZN + 0.5:
		return
	var s := HallCam.scale_at(tz)
	var base := _p(tx, FY, tz)
	var top_y := FY + 0.52
	var top := _p(tx, top_y, tz)
	var rx := 0.34 * s
	var ry := rx * 0.42
	# leg + foot
	c.rect(roundi(base.x) - 1, roundi(top.y), 3, roundi(base.y - top.y), Pal.WOOD)
	c.ellipse(base.x, base.y, rx * 0.5, ry * 0.4, Pal.WOOD)
	# top with cloth
	c.ellipse(top.x, top.y + 2, rx, ry, PAL.CLOTH.darkened(0.35))
	c.ellipse(top.x, top.y, rx, ry, Pal.CRIMSON)
	_dither(c, PixelCanvas.ellipse_points(top.x, top.y, rx, ry, 0.0, 20), Pal.CRIMSON_DARK)
	c.poly_outline(PixelCanvas.ellipse_points(top.x, top.y, rx, ry, 0.0, 20), Pal.INK)
	c.hline(roundi(top.x - rx * 0.7), roundi(top.x + rx * 0.7), roundi(top.y), Pal.GOLD)
	# goblets
	for gx in [-0.55, 0.15]:
		var gp := Vector2(top.x + rx * gx, top.y - 1)
		c.rect(roundi(gp.x) - 1, roundi(gp.y) - 5, 3, 3, Pal.GOLD)
		c.vline(roundi(gp.x), roundi(gp.y) - 2, roundi(gp.y), Pal.GOLD_DARK)
		c.px(roundi(gp.x), roundi(gp.y) - 4, Pal.CRIMSON_LIGHT)
	# grape bowl
	var bp := Vector2(top.x + rx * 0.5, top.y)
	c.ellipse(bp.x, bp.y - 2, rx * 0.28, ry * 0.5, Pal.GOLD_DARK)
	for i in 5:
		c.rect(roundi(bp.x) - 3 + i * 1 + (i % 2), roundi(bp.y) - 6 - (i % 3), 2, 2, PAL.GRAPE_M if i % 2 == 0 else PAL.GRAPE_L)


# ==================================================================== feast

## Draws lanterns; returns the flame spots (Vector2i) for the animated flame textures.
static func paint_feast(c) -> Array:
	_tick()
	var flames: Array = []
	for sd in [-1.0, 1.0]:
		for k in ZS.size():
			var zc: float = ZS[k] - 0.16
			if zc < ZN + 0.5:
				continue
			var x: float = sd * (PX - 0.45)
			var y := BEAM_Y - 0.72
			var top := _p(x, BEAM_Y - 0.04, zc)
			var ctr := _p(x, y, zc)
			var s := HallCam.scale_at(zc)
			var lw := maxi(3, roundi(0.06 * s))
			var lh := maxi(4, roundi(0.10 * s))
			# chain
			c.vline(roundi(ctr.x), roundi(top.y), roundi(ctr.y) - lh / 2, Pal.INK_SOFT)
			# halo: warm dither, then the lantern body
			c.ellipse_dither(ctr.x, ctr.y, lw * 1.7, lw * 1.5, PAL.WARM)
			c.rect(roundi(ctr.x) - lw / 2, roundi(ctr.y) - lh / 2, lw, lh, Pal.GOLD_DARK)
			c.rect(roundi(ctr.x) - lw / 2 + 1, roundi(ctr.y) - lh / 2 + 1, maxi(1, lw - 2), maxi(1, lh - 2), Pal.GOLD_LIGHT)
			c.rect(roundi(ctr.x) - lw / 2 - 1, roundi(ctr.y) - lh / 2 - 1, lw + 2, 1, Pal.INK)
			c.rect(roundi(ctr.x) - lw / 2 - 1, roundi(ctr.y) + lh / 2, lw + 2, 1, Pal.INK)
			flames.append(Vector2(roundi(ctr.x) - 1, roundi(ctr.y) - 2))
	for spot in candle_spots():
		flames.append(spot)
	_fireflies(c)
	_petals(c)
	return flames


static func _fireflies(c) -> void:
	for i in 16:
		var ph := T * (0.25 + _h(i, 1, 200) * 0.25) + i * 3.1
		var x := -1.9 + _h(i, 2, 200) * 3.8 + sin(ph * 1.3) * 0.25
		var y := FY + 0.15 + _h(i, 3, 200) * 1.7 + sin(ph * 1.9) * 0.12
		var z := ZN + 0.9 + _h(i, 4, 200) * 4.0 + cos(ph) * 0.25
		if z > PZ - 0.2:
			continue
		var p := _p(x, y, z)
		var on := sin(T * 2.2 + i * 1.7) > -0.15
		if on:
			c.px(roundi(p.x), roundi(p.y), Pal.GOLD_LIGHT)
			if sin(T * 2.2 + i * 1.7) > 0.6:
				c.px(roundi(p.x) + 1, roundi(p.y), PAL.WARM)
				c.px(roundi(p.x) - 1, roundi(p.y), PAL.WARM)
				c.px(roundi(p.x), roundi(p.y) - 1, PAL.WARM)
				c.px(roundi(p.x), roundi(p.y) + 1, PAL.WARM)


static func _petals(c) -> void:
	for i in 10:
		var ph := fposmod(T * (0.22 + _h(i, 1, 210) * 0.15) + _h(i, 2, 210), 1.0)
		var x := -2.0 + _h(i, 3, 210) * 4.0 + sin(T * 0.9 + i) * 0.3
		var y := lerpf(2.4, FY + 0.05, ph)
		var z := ZN + 0.7 + _h(i, 4, 210) * 3.6
		var p := _p(x, y, z)
		c.rect(roundi(p.x), roundi(p.y), 2, 1, PAL.VINE[3] if i % 2 == 0 else Pal.CRIMSON_LIGHT)


static func _brick_tile() -> ImageTexture:
	if _tiles.has("brick"):
		return _tiles["brick"]
	var img := Image.create(80, 48, false, Image.FORMAT_RGBA8)
	img.fill(Pal.STONE)
	for r in 6:
		var y0 := r * 8
		var off := 10 if r % 2 == 0 else 0
		for i in 5:
			var x0 := off + i * 20 - 20
			var hv := _h(i, r, 31)
			var tone := Pal.STONE
			if hv > 0.9:
				tone = Pal.STONE_LIGHT
			elif hv > 0.78:
				tone = Pal.STONE_DARK
			_frect(img, x0 + 1, y0 + 1, 19, 6, tone)
			if hv < 0.3:
				_frect(img, x0 + 1, y0 + 1, 19, 1, Pal.STONE_LIGHT)
		_frect(img, 0, y0, 80, 1, Pal.GROUT)
		for i in 5:
			_frect(img, off + i * 20 - 20, y0, 1, 8, Pal.GROUT)
	var tex := ImageTexture.create_from_image(img)
	_tiles["brick"] = tex
	return tex
