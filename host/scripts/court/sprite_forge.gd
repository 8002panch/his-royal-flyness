class_name SpriteForge
extends RefCounted

## Every sprite in the court, drawn in code with PixelCanvas at its exact
## on-screen size (no scaling, so pixels stay square) and cached. Placeholder
## art until the team's final sprites exist; nothing here is imported.

static var _cache := {}


static func _cached(key: String, make: Callable) -> ImageTexture:
	if not _cache.has(key):
		var c: PixelCanvas = make.call()
		_cache[key] = c.texture()
	return _cache[key]


static func _ink_pal() -> Dictionary:
	return {
		"K": Pal.INK, "k": Pal.INK_SOFT, "P": Pal.PARCHMENT, "D": Pal.PARCHMENT_DARK, "d": Pal.PARCHMENT_SHADE,
		"G": Pal.GOLD, "g": Pal.GOLD_DARK, "L": Pal.GOLD_LIGHT, "R": Pal.CRIMSON, "r": Pal.CRIMSON_DARK,
		"H": Pal.CRIMSON_LIGHT, "B": Pal.ROYAL, "b": Pal.ROYAL_DARK, "C": Pal.ROYAL_LIGHT, "W": Pal.WING,
		"A": Pal.AMBER, "a": Pal.AMBER_DARK, "E": Pal.EYE, "F": Pal.FLAME, "O": Pal.FLAME_OUT, "V": Pal.GRAPE,
		"S": Pal.STONE_LIGHT, "N": Pal.WOOD,
	}


# ---------------------------------------------------------------- Hamlet --
# Seen from behind while he flies away from the camera. `hh` is his body
# height in px. Every Hamlet texture shares one canvas so the parts line up;
# hamlet_anchor() is the thorax centre inside that canvas.

static func _hg(hh: int) -> Dictionary:
	var w := int(round(hh * 1.8))
	w += w % 2
	var ch := int(round(hh * 1.24))
	return {"w": w, "h": ch, "cx": w / 2.0, "t": float(ch - hh)}


static func hamlet_anchor(hh: int) -> Vector2:
	var g := _hg(hh)
	return Vector2(round(g.cx), round(g.t + 0.47 * hh))


static func hamlet_body(hh: int) -> ImageTexture:
	return _cached("hamlet_body_%d" % hh, func() -> PixelCanvas: return _hamlet_body(hh))


static func _hamlet_body(hh: int) -> PixelCanvas:
	var g := _hg(hh)
	var cx: float = g.cx
	var t: float = g.t
	var out := PixelCanvas.new(g.w, g.h)
	var thick := hh >= 48

	# legs, tucked under the body
	for side in [-1.0, 1.0]:
		out.linev(Vector2(cx + side * 0.10 * hh, t + 0.55 * hh), Vector2(cx + side * 0.21 * hh, t + 0.66 * hh), Pal.INK)
		out.linev(Vector2(cx + side * 0.08 * hh, t + 0.60 * hh), Vector2(cx + side * 0.16 * hh, t + 0.80 * hh), Pal.INK)
		if thick:
			out.linev(Vector2(cx + side * 0.10 * hh + 1, t + 0.55 * hh), Vector2(cx + side * 0.21 * hh + 1, t + 0.66 * hh), Pal.INK)

	# abdomen with its dark bands
	var ab := PixelCanvas.new(g.w, g.h)
	var ay := t + 0.70 * hh
	var arx := 0.165 * hh
	var ary := 0.215 * hh
	ab.ellipse(cx, ay, arx, ary, Pal.AMBER)
	ab.shade_ellipse(cx, ay, arx, ary, Pal.AMBER_DARK, Pal.AMBER_LIGHT)
	var band := maxi(1, int(round(0.035 * hh)))
	for k in 3:
		var sy := int(round(t + (0.64 + 0.085 * k) * hh))
		for y in range(sy, sy + band):
			for x in range(int(cx - arx) - 1, int(cx + arx) + 2):
				if ab.opaque(x, y):
					ab.px(x, y, Pal.STRIPE)
	ab.outline(Pal.INK)
	out.blit(ab, 0, 0)

	# thorax
	var th := PixelCanvas.new(g.w, g.h)
	var ty := t + 0.47 * hh
	th.ellipse(cx, ty, 0.19 * hh, 0.14 * hh, Pal.AMBER)
	th.shade_ellipse(cx, ty, 0.19 * hh, 0.14 * hh, Pal.AMBER_DARK, Pal.AMBER_LIGHT)
	for side in [-1.0, 1.0]:
		th.vline(int(round(cx + side * 0.06 * hh)), int(round(ty - 0.08 * hh)), int(round(ty + 0.05 * hh)), Pal.AMBER_DARK)
	th.outline(Pal.INK)
	out.blit(th, 0, 0)

	# back of the head
	var hd := PixelCanvas.new(g.w, g.h)
	var hy := t + 0.29 * hh
	hd.ellipse(cx, hy, 0.15 * hh, 0.115 * hh, Pal.AMBER_DARK)
	hd.ellipse(cx - 0.02 * hh, hy - 0.035 * hh, 0.08 * hh, 0.05 * hh, Pal.AMBER)
	hd.outline(Pal.INK)
	out.blit(hd, 0, 0)

	# the big red eyes bulge out at the sides
	var ey := PixelCanvas.new(g.w, g.h)
	for side in [-1.0, 1.0]:
		var ex: float = cx + side * 0.14 * hh
		ey.ellipse(ex, t + 0.295 * hh, 0.08 * hh, 0.10 * hh, Pal.EYE)
		ey.ellipse(ex + side * 0.025 * hh, t + 0.33 * hh, 0.05 * hh, 0.055 * hh, Pal.EYE_DARK)
		ey.px(int(round(ex - side * 0.02 * hh)), int(round(t + 0.25 * hh)), Pal.PARCHMENT)
		if thick:
			ey.px(int(round(ex - side * 0.02 * hh)), int(round(t + 0.25 * hh)) + 1, Pal.PARCHMENT)
	ey.outline(Pal.INK)
	out.blit(ey, 0, 0)

	out.blit(_crown(g.w, g.h, cx, t, hh), 0, 0)
	return out


static func _crown(w: int, h: int, cx: float, t: float, hh: int) -> PixelCanvas:
	var cr := PixelCanvas.new(w, h)
	var bw := 0.14 * hh
	var by0 := t + 0.15 * hh
	var by1 := t + 0.215 * hh
	cr.rect(int(round(cx - bw)), int(round(by0)), int(round(2 * bw)), maxi(3, int(round(by1 - by0))), Pal.GOLD)
	for spec in [[-0.105, 0.035], [0.0, 0.0], [0.105, 0.035]]:
		var px0: float = cx + spec[0] * hh
		var apex: float = t + spec[1] * hh
		var half := 0.04 * hh
		cr.poly(PackedVector2Array([Vector2(px0 - half - 0.5, by0 + 0.5), Vector2(px0 + half + 0.5, by0 + 0.5), Vector2(px0, apex)]), Pal.GOLD)
		cr.px(int(round(px0 - 0.5)), int(round(apex)), Pal.GOLD_LIGHT)
	var bottom := int(round(by0)) + maxi(3, int(round(by1 - by0))) - 1
	cr.hline(int(round(cx - bw)), int(round(cx + bw)) - 1, bottom, Pal.GOLD_DARK)
	cr.hline(int(round(cx - bw)), int(round(cx - bw)) + 1, int(round(by0)), Pal.GOLD_LIGHT)
	var jy := int(round((by0 + by1) / 2.0)) - 1
	cr.rect(int(round(cx)) - 1, jy, 2, 2, Pal.CRIMSON)
	cr.px(int(round(cx - bw * 0.6)), jy, Pal.ROYAL_LIGHT)
	cr.px(int(round(cx + bw * 0.6)) - 1, jy, Pal.ROYAL_LIGHT)
	cr.outline(Pal.INK)
	return cr


static func _wing_angle(frame: int) -> float:
	# Wide power stroke followed by a foreshortened recovery stroke.
	return [0.88, 0.48, 0.05, -0.32, -0.58, -0.20, 0.26, 0.66][frame % 8]


static func hamlet_wings(hh: int, frame: int) -> ImageTexture:
	return _cached("hamlet_wings_%d_%d" % [hh, frame], func() -> PixelCanvas: return _hamlet_wings(hh, frame, false))


static func hamlet_filigree(hh: int, frame: int) -> ImageTexture:
	return _cached("hamlet_fil_%d_%d" % [hh, frame], func() -> PixelCanvas: return _hamlet_wings(hh, frame, true))


static func _hamlet_wings(hh: int, frame: int, filigree: bool) -> PixelCanvas:
	var g := _hg(hh)
	var cx: float = g.cx
	var t: float = g.t
	var c := PixelCanvas.new(g.w, g.h)
	var a := _wing_angle(frame)
	var length := 0.50 * hh
	var width: float = [0.10, 0.125, 0.14, 0.11, 0.075, 0.028, 0.035, 0.065][frame % 8] * hh
	for side in [-1.0, 1.0]:
		var attach := Vector2(cx + side * 0.10 * hh, t + 0.43 * hh)
		var dir := Vector2(side * cos(a), -sin(a))
		var mid := attach + dir * (length * 0.5)
		var ang := atan2(dir.y, dir.x)
		if filigree:
			var tip := attach + dir * (length * 0.92)
			var nrm := Vector2(-dir.y, dir.x)
			c.linev(attach + nrm * (width * 0.35), tip + nrm * (width * 0.25), Pal.GOLD)
			c.linev(attach - nrm * (width * 0.2), tip - nrm * (width * 0.45), Pal.GOLD)
			c.linev(attach + dir * (length * 0.55), attach + dir * (length * 0.55) + nrm * (width * 0.9), Pal.GOLD)
			c.px(roundi(tip.x), roundi(tip.y), Pal.GOLD_LIGHT)
			var dot := attach + dir * (length * 0.75)
			c.px(roundi(dot.x), roundi(dot.y), Pal.GOLD_LIGHT)
		else:
			c.poly(PixelCanvas.ellipse_points(mid.x, mid.y, length * 0.5, width, ang, 28), Pal.WING)
			var nrm := Vector2(-dir.y, dir.x)
			var tip := attach + dir * (length * 0.9)
			c.linev(attach + nrm * (width * 0.3), tip + nrm * (width * 0.2), Pal.WING_VEIN)
			c.linev(attach - nrm * (width * 0.2), tip - nrm * (width * 0.4), Pal.WING_VEIN)
	if not filigree:
		c.outline(Pal.INK)
	return c


static func hamlet_mantle(hh: int) -> ImageTexture:
	return _cached("hamlet_mantle_%d" % hh, func() -> PixelCanvas: return _hamlet_mantle(hh))


static func _hamlet_mantle(hh: int) -> PixelCanvas:
	var g := _hg(hh)
	var cx: float = g.cx
	var t: float = g.t
	var c := PixelCanvas.new(g.w, g.h)
	var top := t + 0.40 * hh
	var bot := t + 0.93 * hh
	var pts := PackedVector2Array([Vector2(cx - 0.17 * hh, top), Vector2(cx + 0.17 * hh, top)])
	var n := 7
	for i in range(n + 1):
		var u := float(i) / n
		var x := cx + 0.26 * hh - u * 0.52 * hh
		var y := bot - (0.03 * hh if i % 2 == 1 else 0.0)
		pts.append(Vector2(x, y))
	c.poly(pts, Pal.ROYAL)
	for side in [-1.0, 1.0]:
		c.linev(Vector2(cx + side * 0.05 * hh, top + 0.05 * hh), Vector2(cx + side * 0.10 * hh, bot - 0.04 * hh), Pal.ROYAL_DARK)
		c.linev(Vector2(cx + side * 0.15 * hh, top + 0.08 * hh), Vector2(cx + side * 0.21 * hh, bot - 0.05 * hh), Pal.ROYAL_LIGHT)
	var stud := maxi(4, int(round(0.1 * hh)))
	for y in range(int(top + 0.12 * hh), int(bot - 0.06 * hh), stud):
		for x in range(int(cx - 0.2 * hh), int(cx + 0.2 * hh) + 1, stud):
			if c.get_px(x, y) == Pal.ROYAL:
				c.px(x, y, Pal.GOLD)
	c.poly_outline(pts, Pal.GOLD)
	# ermine collar
	c.ellipse(cx, top + 0.01 * hh, 0.21 * hh, 0.065 * hh, Pal.PARCHMENT)
	var step := maxi(3, int(round(0.07 * hh)))
	var y0 := int(round(top))
	for x in range(int(cx - 0.17 * hh), int(cx + 0.17 * hh), step):
		c.px(x, y0, Pal.INK)
	c.outline(Pal.INK)
	return c


static func hamlet_halo(hh: int) -> ImageTexture:
	return _cached("hamlet_halo_%d" % hh, func() -> PixelCanvas: return _hamlet_halo(hh))


static func _hamlet_halo(hh: int) -> PixelCanvas:
	var g := _hg(hh)
	var cx: float = g.cx
	var cy: float = g.t + 0.14 * hh
	var r := 0.25 * hh
	var c := PixelCanvas.new(g.w, g.h)
	for i in 16:
		var ang := TAU * i / 16.0
		var d := Vector2(cos(ang), sin(ang))
		var reach := 1.3 if i % 2 == 0 else 1.16
		c.linev(Vector2(cx, cy) + d * r, Vector2(cx, cy) + d * r * reach, Pal.GOLD)
	c.ellipse(cx, cy, r, r, Pal.GOLD)
	c.ellipse(cx, cy, r - 2.0, r - 2.0, Pal.PARCHMENT)
	for i in 12:
		var ang := TAU * i / 12.0
		c.px(roundi(cx + cos(ang) * (r - 3.0)), roundi(cy + sin(ang) * (r - 3.0)), Pal.GOLD_LIGHT)
	c.outline(Pal.INK)
	return c


# ------------------------------------------------- Miranda and the rivals --
# Front view. `hh` = body height in px; anchor = thorax centre.

static func _fg(hh: int) -> Dictionary:
	var w := int(round(hh * 1.5))
	w += w % 2
	var ch := int(round(hh * 1.16))
	return {"w": w, "h": ch, "cx": w / 2.0, "t": float(ch - hh)}


static func front_anchor(hh: int) -> Vector2:
	var g := _fg(hh)
	return Vector2(round(g.cx), round(g.t + 0.50 * hh))


static func front_feet(hh: int) -> Vector2:
	var g := _fg(hh)
	return Vector2(round(g.cx), float(g.h - 1))


## style keys: gown (Color), tabard (Color), charge (Color), tiara, cap (Color),
## bandage, goblet, cane, cheeks, lashes
static func fly_front(hh: int, style_name: String, style: Dictionary) -> ImageTexture:
	return _cached("front_%s_%d" % [style_name, hh], func() -> PixelCanvas: return _fly_front(hh, style))


static func _fly_front(hh: int, style: Dictionary) -> PixelCanvas:
	var g := _fg(hh)
	var cx: float = g.cx
	var t: float = g.t
	var out := PixelCanvas.new(g.w, g.h)

	# folded wings behind
	var wc := PixelCanvas.new(g.w, g.h)
	for side in [-1.0, 1.0]:
		var attach := Vector2(cx + side * 0.07 * hh, t + 0.46 * hh)
		var dir := Vector2(side * cos(0.95), sin(0.95))
		var mid := attach + dir * (0.23 * hh)
		wc.poly(PixelCanvas.ellipse_points(mid.x, mid.y, 0.25 * hh, 0.10 * hh, atan2(dir.y, dir.x), 24), Pal.WING)
		wc.linev(attach, attach + dir * (0.42 * hh), Pal.WING_VEIN)
	wc.outline(Pal.INK)
	out.blit(wc, 0, 0)

	# legs
	for side in [-1.0, 1.0]:
		out.linev(Vector2(cx + side * 0.07 * hh, t + 0.86 * hh), Vector2(cx + side * 0.13 * hh, float(g.h - 1)), Pal.INK)
		out.linev(Vector2(cx + side * 0.12 * hh, t + 0.80 * hh), Vector2(cx + side * 0.23 * hh, float(g.h - 1)), Pal.INK)

	if style.get("cane", false):
		var kx := int(round(cx - 0.30 * hh))
		out.vline(kx, int(round(t + 0.58 * hh)), g.h - 1, Pal.WOOD)
		out.vline(kx + 1, int(round(t + 0.58 * hh)), g.h - 1, Pal.INK)
		out.rect(kx - 1, int(round(t + 0.56 * hh)), 3, 2, Pal.GOLD)

	# abdomen
	var ab := PixelCanvas.new(g.w, g.h)
	ab.ellipse(cx, t + 0.74 * hh, 0.15 * hh, 0.20 * hh, Pal.AMBER)
	ab.shade_ellipse(cx, t + 0.74 * hh, 0.15 * hh, 0.20 * hh, Pal.AMBER_DARK, Pal.AMBER_LIGHT)
	for k in 3:
		var sy := int(round(t + (0.68 + 0.08 * k) * hh))
		for x in range(int(cx - 0.16 * hh), int(cx + 0.16 * hh) + 1):
			if ab.opaque(x, sy):
				ab.px(x, sy, Pal.STRIPE)
	ab.outline(Pal.INK)
	out.blit(ab, 0, 0)

	# thorax
	var th := PixelCanvas.new(g.w, g.h)
	th.ellipse(cx, t + 0.50 * hh, 0.15 * hh, 0.11 * hh, Pal.AMBER)
	th.shade_ellipse(cx, t + 0.50 * hh, 0.15 * hh, 0.11 * hh, Pal.AMBER_DARK, Pal.AMBER_LIGHT)
	th.outline(Pal.INK)
	out.blit(th, 0, 0)

	if style.has("gown"):
		var gown: Color = style["gown"]
		var gc := PixelCanvas.new(g.w, g.h)
		var top := t + 0.53 * hh
		var bot := t + 0.94 * hh
		var pts := PackedVector2Array([Vector2(cx - 0.11 * hh, top), Vector2(cx + 0.11 * hh, top)])
		for i in range(9):
			var u := float(i) / 8.0
			pts.append(Vector2(cx + 0.27 * hh - u * 0.54 * hh, bot - sin(u * PI) * 0.03 * hh))
		gc.poly(pts, gown)
		for side in [-1.0, 1.0]:
			gc.linev(Vector2(cx + side * 0.05 * hh, top + 2), Vector2(cx + side * 0.13 * hh, bot - 2), Pal.ROYAL_DARK)
		gc.vline(int(round(cx)), int(round(top)) + 1, int(round(bot)) - 1, Pal.GOLD)
		gc.hline(int(round(cx - 0.25 * hh)), int(round(cx + 0.25 * hh)), int(round(bot)) - 1, Pal.GOLD)
		gc.hline(int(round(cx - 0.11 * hh)), int(round(cx + 0.11 * hh)), int(round(top)), Pal.GOLD)
		gc.outline(Pal.INK)
		out.blit(gc, 0, 0)

	if style.has("tabard"):
		var tab: Color = style["tabard"]
		var tc := PixelCanvas.new(g.w, g.h)
		var top := t + 0.47 * hh
		var bot := t + 0.86 * hh
		var pts := PackedVector2Array([
			Vector2(cx - 0.15 * hh, top), Vector2(cx + 0.15 * hh, top),
			Vector2(cx + 0.15 * hh, bot - 0.07 * hh), Vector2(cx, bot), Vector2(cx - 0.15 * hh, bot - 0.07 * hh)])
		tc.poly(pts, tab)
		var charge: Color = style.get("charge", Pal.GOLD)
		var mid := t + 0.64 * hh
		tc.linev(Vector2(cx - 0.12 * hh, mid + 0.08 * hh), Vector2(cx, mid - 0.02 * hh), charge)
		tc.linev(Vector2(cx, mid - 0.02 * hh), Vector2(cx + 0.12 * hh, mid + 0.08 * hh), charge)
		tc.linev(Vector2(cx - 0.12 * hh, mid + 0.08 * hh + 1), Vector2(cx, mid - 0.02 * hh + 1), charge)
		tc.linev(Vector2(cx, mid - 0.02 * hh + 1), Vector2(cx + 0.12 * hh, mid + 0.08 * hh + 1), charge)
		tc.outline(Pal.INK)
		out.blit(tc, 0, 0)

	# head (a face this time) and the big eyes
	var hd := PixelCanvas.new(g.w, g.h)
	var hy := t + 0.28 * hh
	hd.ellipse(cx, hy, 0.17 * hh, 0.135 * hh, Pal.AMBER_LIGHT)
	hd.shade_ellipse(cx, hy, 0.17 * hh, 0.135 * hh, Pal.AMBER, Pal.AMBER_LIGHT)
	hd.outline(Pal.INK)
	out.blit(hd, 0, 0)
	var ey := PixelCanvas.new(g.w, g.h)
	for side in [-1.0, 1.0]:
		var ex: float = cx + side * 0.115 * hh
		ey.ellipse(ex, t + 0.27 * hh, 0.078 * hh, 0.10 * hh, Pal.EYE)
		ey.ellipse(ex + side * 0.02 * hh, t + 0.30 * hh, 0.05 * hh, 0.05 * hh, Pal.EYE_DARK)
		var hx := int(round(ex - side * 0.025 * hh))
		var hyy := int(round(t + 0.235 * hh))
		ey.px(hx, hyy, Pal.PARCHMENT)
		if hh >= 34:
			ey.px(hx, hyy + 1, Pal.PARCHMENT)
	ey.outline(Pal.INK)
	out.blit(ey, 0, 0)
	if style.get("lashes", false):
		for side in [-1.0, 1.0]:
			var lx := int(round(cx + side * 0.19 * hh))
			var ly := int(round(t + 0.18 * hh))
			out.px(lx, ly, Pal.INK)
			out.px(lx + int(side), ly - 1, Pal.INK)
	if style.get("cheeks", false):
		for side in [-1.0, 1.0]:
			out.rect(int(round(cx + side * 0.06 * hh)) - 1, int(round(t + 0.36 * hh)), 2, 1, Pal.CRIMSON_LIGHT)

	# antennae
	if not style.has("cap"):
		for side in [-1.0, 1.0]:
			var a0 := Vector2(cx + side * 0.03 * hh, t + 0.16 * hh)
			var a1 := Vector2(cx + side * 0.09 * hh, t + 0.06 * hh)
			out.linev(a0, a1, Pal.INK)

	if style.get("tiara", false):
		var tc := PixelCanvas.new(g.w, g.h)
		var by := t + 0.155 * hh
		tc.rect(int(round(cx - 0.12 * hh)), int(round(by)), int(round(0.24 * hh)), maxi(2, int(round(0.035 * hh))), Pal.GOLD)
		for spec in [[-0.08, 0.10], [0.0, 0.06], [0.08, 0.10]]:
			var x0: float = cx + spec[0] * hh
			tc.poly(PackedVector2Array([Vector2(x0 - 0.035 * hh, by + 0.5), Vector2(x0 + 0.035 * hh, by + 0.5), Vector2(x0, t + spec[1] * hh)]), Pal.GOLD)
		tc.rect(int(round(cx)) - 1, int(round(by)) - 1, 2, 2, Pal.ROYAL_LIGHT)
		tc.outline(Pal.INK)
		out.blit(tc, 0, 0)

	if style.has("cap"):
		var cap: Color = style["cap"]
		var kc := PixelCanvas.new(g.w, g.h)
		kc.ellipse(cx + 0.03 * hh, t + 0.12 * hh, 0.17 * hh, 0.08 * hh, cap)
		kc.rect(int(round(cx - 0.15 * hh)), int(round(t + 0.15 * hh)), int(round(0.30 * hh)), maxi(2, int(round(0.04 * hh))), Pal.GOLD)
		kc.outline(Pal.INK)
		out.blit(kc, 0, 0)

	if style.get("bandage", false):
		var bc := PixelCanvas.new(g.w, g.h)
		var p0 := Vector2(cx - 0.17 * hh, t + 0.22 * hh)
		var p1 := Vector2(cx + 0.14 * hh, t + 0.14 * hh)
		for k in maxi(2, int(round(0.05 * hh))):
			bc.linev(p0 + Vector2(0, k), p1 + Vector2(0, k), Pal.PARCHMENT)
		bc.outline(Pal.INK)
		var mid := (p0 + p1) / 2.0
		bc.px(roundi(mid.x), roundi(mid.y) + 1, Pal.CRIMSON)
		out.blit(bc, 0, 0)

	if style.get("goblet", false):
		var gx := int(round(cx + 0.24 * hh))
		var gy := int(round(t + 0.55 * hh))
		var gob := PixelCanvas.from_rows(["GGGG", "LGGg", ".Gg.", ".g..", "GGg."], _ink_pal())
		gob.outline(Pal.INK)
		out.linev(Vector2(cx + 0.12 * hh, t + 0.60 * hh), Vector2(gx, gy + 3), Pal.INK)
		out.blit(gob, gx - 1, gy - 1)
	return out


# ------------------------------------------------------- the Giant's hand --
# Hanging down out of the sky, palm to the camera. `s` = palm width in px.

static func giant_hand(s: int) -> ImageTexture:
	return _cached("hand_%d" % s, func() -> PixelCanvas: return _giant_hand(s))


static func hand_size(s: int) -> Vector2i:
	return Vector2i(int(round(s * 1.4)) + 4, int(round(s * 1.95)) + 4)


static func _giant_hand(s: int) -> PixelCanvas:
	var sz := hand_size(s)
	var c := PixelCanvas.new(sz.x, sz.y)
	var ox := 2.0 + 0.2 * s
	var sf := float(s)
	# sleeve and lace cuff
	c.rect(int(ox - 0.08 * sf), 0, int(1.16 * sf), int(0.30 * sf), Pal.ROYAL_DARK)
	for k in 3:
		c.vline(int(ox + (0.2 + 0.3 * k) * sf), 0, int(0.28 * sf), Pal.ROYAL)
	c.rect(int(ox - 0.10 * sf), int(0.28 * sf), int(1.2 * sf), int(0.11 * sf), Pal.PARCHMENT)
	for x in range(int(ox - 0.10 * sf), int(ox + 1.1 * sf), 3):
		c.px(x, int(0.39 * sf) - 1, Pal.PARCHMENT_DARK)
	# palm
	var palm := PixelCanvas.new(sz.x, sz.y)
	palm.rect(int(ox), int(0.38 * sf), int(sf), int(0.64 * sf), Pal.FLESH)
	# thumb, angled down and out to the left
	var t0 := Vector2(ox + 0.12 * sf, 0.62 * sf)
	var t1 := Vector2(ox - 0.14 * sf, 1.06 * sf)
	palm.poly(PixelCanvas.ellipse_points((t0.x + t1.x) / 2.0, (t0.y + t1.y) / 2.0, t0.distance_to(t1) / 2.0 + 0.04 * sf, 0.11 * sf, (t1 - t0).angle(), 20), Pal.FLESH)
	# four fingers
	var lengths := [0.66, 0.74, 0.68, 0.52]
	var fw := 0.22 * sf
	for i in 4:
		var fx0 := ox + (0.02 + i * 0.25) * sf
		var flen: float = lengths[i] * sf
		var top := 0.9 * sf
		palm.rect(int(fx0), int(top), int(fw), int(flen - fw * 0.5), Pal.FLESH)
		palm.ellipse(fx0 + fw / 2.0, top + flen - fw * 0.5, fw / 2.0, fw / 2.0, Pal.FLESH)
	# shading, creases, pads
	for i in 4:
		var fx0 := ox + (0.02 + i * 0.25) * sf
		var flen: float = lengths[i] * sf
		var top := 0.9 * sf
		for y in range(int(top), int(top + flen)):
			for k in maxi(1, int(0.05 * sf)):
				var x := int(fx0 + fw) - 1 - k
				if palm.opaque(x, y):
					palm.px(x, y, Pal.FLESH_DARK)
		for f in [0.38, 0.68]:
			var cy := int(top + flen * f)
			palm.hline(int(fx0) + 1, int(fx0 + fw) - 2, cy, Pal.FLESH_DARK)
		palm.rect(int(fx0 + fw * 0.3), int(top + flen - fw * 0.55), maxi(1, int(fw * 0.3)), maxi(1, int(fw * 0.25)), Pal.FLESH_LIGHT)
	palm.linev(Vector2(ox + 0.2 * sf, 0.55 * sf), Vector2(ox + 0.75 * sf, 0.72 * sf), Pal.FLESH_DARK)
	palm.linev(Vector2(ox + 0.3 * sf, 0.85 * sf), Vector2(ox + 0.85 * sf, 0.62 * sf), Pal.FLESH_DARK)
	palm.rect(int(ox + 0.93 * sf), int(0.4 * sf), maxi(1, int(0.06 * sf)), int(0.5 * sf), Pal.FLESH_DARK)
	c.blit(palm, 0, 0)
	c.outline(Pal.INK)
	if s >= 56:
		c.outline(Pal.INK)
	return c


# ---------------------------------------------------------------- banners --

static func banner(bw: int, bh: int, field: Color, emblem: String, sway: int) -> ImageTexture:
	return _cached("banner_%d_%d_%s_%s_%d" % [bw, bh, field.to_html(), emblem, sway], func() -> PixelCanvas: return _banner(bw, bh, field, emblem, sway))


static func _banner(bw: int, bh: int, field: Color, emblem: String, sway: int) -> PixelCanvas:
	var pad := 4
	var flat := PixelCanvas.new(bw + pad * 2, bh + 2)
	var x0 := pad
	var cloth_top := 3
	var tail := int(round(bw * 0.45))
	var pts := PackedVector2Array([
		Vector2(x0, cloth_top), Vector2(x0 + bw, cloth_top), Vector2(x0 + bw, bh),
		Vector2(x0 + bw / 2.0, bh - tail), Vector2(x0, bh)])
	flat.poly(pts, field)
	var dark := Pal.CRIMSON_DARK if field == Pal.CRIMSON else Pal.ROYAL_DARK
	var light := Pal.CRIMSON_LIGHT if field == Pal.CRIMSON else Pal.ROYAL_LIGHT
	for fx in [0.28, 0.72]:
		var xx := int(round(x0 + bw * fx))
		for y in range(cloth_top + 1, bh - int(tail * 0.4)):
			if flat.opaque(xx, y):
				flat.px(xx, y, dark)
			if flat.opaque(xx + 1, y) and fx < 0.5:
				flat.px(xx + 1, y, light)
	# gold border just inside the edge
	var inner := PackedVector2Array([
		Vector2(x0 + 2, cloth_top + 2), Vector2(x0 + bw - 2, cloth_top + 2), Vector2(x0 + bw - 2, bh - 4),
		Vector2(x0 + bw / 2.0, bh - tail - 3), Vector2(x0 + 2, bh - 4)])
	flat.poly_outline(inner, Pal.GOLD)
	var ec := int(round(x0 + bw / 2.0))
	var ey := cloth_top + int(round(bh * 0.28))
	var icon: PixelCanvas = crown_canvas() if emblem == "crown" else fly_emblem_canvas()
	flat.blit(icon, ec - icon.w / 2, ey - icon.h / 2)
	flat.outline(Pal.INK)
	# the rod and finials
	flat.rect(x0 - 3, 1, bw + 6, 2, Pal.GOLD)
	flat.hline(x0 - 3, x0 + bw + 2, 1, Pal.GOLD_LIGHT)
	flat.rect(x0 - 4, 0, 2, 4, Pal.GOLD_DARK)
	flat.rect(x0 + bw + 2, 0, 2, 4, Pal.GOLD_DARK)
	if sway == 0:
		return flat
	# sway: shift lower rows sideways, more towards the tail
	var out := PixelCanvas.new(flat.w, flat.h)
	for y in flat.h:
		var u := clampf(float(y - bh * 0.35) / (bh * 0.65), 0.0, 1.0)
		var off := int(round(sway * u * u * 1.6))
		for x in flat.w:
			var col := flat.get_px(x - off, y)
			if col.a > 0.5:
				out.px(x, y, col)
	return out


static func crown_canvas() -> PixelCanvas:
	var c := PixelCanvas.from_rows([
		"L...L...L",
		"G..GGG..G",
		"GG.GGG.GG",
		"GGGGRGGGG",
		"GGGGGGGGG",
		"ggggggggg",
	], _ink_pal())
	c.outline(Pal.INK)
	return c


static func crown() -> ImageTexture:
	if _cache.has("crown"):
		return _cache["crown"]
	return _put("crown", crown_canvas())


static func fly_emblem_canvas() -> PixelCanvas:
	var c := PixelCanvas.from_rows([
		"..L.L..",
		"LL.G.LL",
		"LLGGGLL",
		".LGGGL.",
		"..GGG..",
		"...G...",
	], _ink_pal())
	c.outline(Pal.INK)
	return c


# ----------------------------------------------------------------- props --

static func flame(frame: int) -> ImageTexture:
	var rows: Array = [
		[".F.", ".F.", "FFF", "FOF", ".O."],
		["F..", ".F.", "FFF", "FOF", ".O."],
		["..F", ".F.", "FFF", "FOF", ".O."],
	][frame % 3]
	return _cached("flame_%d" % (frame % 3), func() -> PixelCanvas: return PixelCanvas.from_rows(rows, _ink_pal()))


## Returns {canvas, flames: [Vector2i]} for a gold candelabra `hpx` tall.
static func candelabra(hpx: int) -> Dictionary:
	var hh := maxi(10, hpx)
	var w := int(round(hh * 0.8))
	w += (w + 1) % 2
	var c := PixelCanvas.new(w + 2, hh + 2)
	var cx := (w + 2) / 2
	var arm_y := int(round(hh * 0.45))
	c.rect(cx - 2, hh - 1, 5, 2, Pal.GOLD_DARK)
	c.vline(cx, arm_y, hh - 1, Pal.GOLD)
	c.hline(2, w - 1, arm_y, Pal.GOLD)
	var flames: Array = []
	for x in [2, cx, w - 1]:
		var top := int(round(hh * 0.18)) if x == cx else int(round(hh * 0.25))
		c.vline(x, top, arm_y, Pal.PARCHMENT)
		c.px(x, arm_y, Pal.GOLD_LIGHT)
		flames.append(Vector2i(x - 1, top - 5))
	c.outline(Pal.INK)
	return {"canvas": c, "flames": flames}


static func fruit_bowl(wpx: int) -> PixelCanvas:
	var w := maxi(7, wpx)
	var c := PixelCanvas.new(w + 2, int(w * 0.8) + 2)
	var cx := (w + 2) / 2.0
	var base := c.h - 2.0
	c.ellipse(cx - w * 0.2, base - w * 0.42, w * 0.16, w * 0.16, Pal.CRIMSON)
	c.ellipse(cx + w * 0.18, base - w * 0.44, w * 0.15, w * 0.17, Pal.GOLD)
	c.ellipse(cx, base - w * 0.55, w * 0.14, w * 0.14, Pal.GRAPE)
	c.px(int(cx - w * 0.24), int(base - w * 0.5), Pal.CRIMSON_LIGHT)
	c.poly(PackedVector2Array([Vector2(cx - w * 0.5, base - w * 0.32), Vector2(cx + w * 0.5, base - w * 0.32),
		Vector2(cx + w * 0.3, base - 1), Vector2(cx - w * 0.3, base - 1)]), Pal.GOLD)
	c.hline(int(cx - w * 0.45), int(cx + w * 0.45), int(base - w * 0.32), Pal.GOLD_LIGHT)
	c.rect(int(cx - w * 0.15), int(base - 1), int(w * 0.3), 2, Pal.GOLD_DARK)
	c.outline(Pal.INK)
	return c


static func goblet(hpx: int) -> PixelCanvas:
	var hh := maxi(5, hpx)
	var w := maxi(4, int(round(hh * 0.7)))
	var c := PixelCanvas.new(w + 2, hh + 2)
	var cx := (w + 2) / 2
	c.rect(1, 1, w, maxi(2, hh / 2), Pal.GOLD)
	c.vline(1, 1, maxi(2, hh / 2), Pal.GOLD_LIGHT)
	c.hline(1, w, 1, Pal.CRIMSON)
	c.vline(cx, 1 + hh / 2, hh - 1, Pal.GOLD_DARK)
	c.hline(cx - w / 3, cx + w / 3, hh, Pal.GOLD)
	c.outline(Pal.INK)
	return c


static func roast(wpx: int) -> PixelCanvas:
	var w := maxi(8, wpx)
	var c := PixelCanvas.new(w + 2, int(w * 0.55) + 2)
	var cx := (w + 2) / 2.0
	var cy := c.h / 2.0 + 1
	c.ellipse(cx, cy + w * 0.08, w * 0.5, w * 0.16, Pal.PARCHMENT_DARK)
	c.ellipse(cx, cy - w * 0.04, w * 0.33, w * 0.18, Pal.AMBER_DARK)
	c.ellipse(cx - w * 0.06, cy - w * 0.1, w * 0.18, w * 0.08, Pal.AMBER)
	c.hline(int(cx + w * 0.25), int(cx + w * 0.42), int(cy - w * 0.12), Pal.PARCHMENT)
	c.outline(Pal.INK)
	return c


static func grapes(wpx: int) -> PixelCanvas:
	var w := maxi(5, wpx)
	var c := PixelCanvas.new(w + 2, w + 3)
	var r := maxf(1.0, w * 0.18)
	var cx := (w + 2) / 2.0
	for p in [Vector2(-0.25, 0.3), Vector2(0.25, 0.3), Vector2(0.0, 0.3), Vector2(-0.12, 0.55), Vector2(0.12, 0.55), Vector2(0.0, 0.78)]:
		c.ellipse(cx + p.x * w, 1 + p.y * w, r, r, Pal.GRAPE)
	c.px(int(cx) - 1, 1 + int(0.25 * w), Pal.ROYAL_LIGHT)
	c.vline(int(cx), 0, 1, Pal.GOLD_DARK)
	c.outline(Pal.INK)
	return c


static func bread(wpx: int) -> PixelCanvas:
	var w := maxi(6, wpx)
	var c := PixelCanvas.new(w + 2, int(w * 0.5) + 2)
	var cx := (w + 2) / 2.0
	c.ellipse(cx, c.h / 2.0 + 0.5, w * 0.48, w * 0.22, Pal.AMBER)
	c.ellipse(cx - w * 0.05, c.h / 2.0 - 0.5, w * 0.3, w * 0.1, Pal.AMBER_LIGHT)
	for k in 3:
		c.px(int(cx - w * 0.2 + k * w * 0.2), int(c.h / 2.0), Pal.AMBER_DARK)
	c.outline(Pal.INK)
	return c


# -------------------------------------------------------------------- FX --

static func _put(key: String, c: PixelCanvas) -> ImageTexture:
	_cache[key] = c.texture()
	return _cache[key]


static func heart() -> ImageTexture:
	if _cache.has("heart"):
		return _cache["heart"]
	var c := PixelCanvas.from_rows([
		".RR.RR.",
		"RHRRRRR",
		"RRRRRRR",
		".RRRRr.",
		"..RRr..",
		"...r...",
	], _ink_pal())
	var out := PixelCanvas.new(9, 8)
	out.blit(c, 1, 1)
	out.outline(Pal.INK)
	return _put("heart", out)


static func sparkle() -> ImageTexture:
	if _cache.has("sparkle"):
		return _cache["sparkle"]
	return _put("sparkle", PixelCanvas.from_rows(["..L..", "..G..", "LGLGL", "..G..", "..L.."], _ink_pal()))


static func puff(r: int) -> ImageTexture:
	var key := "puff_%d" % r
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(r * 2 + 3, r * 2 + 3)
	c.ellipse(r + 1.5, r + 1.5, r, r, Pal.PARCHMENT_DARK)
	c.ellipse(r + 1.5, r + 2.2, r * 0.8, r * 0.55, Pal.PARCHMENT_SHADE)
	c.px(r, r, Pal.PARCHMENT)
	c.outline(Pal.INK_SOFT)
	return _put(key, c)


static func splat(r: int) -> ImageTexture:
	var key := "splat_%d" % r
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1606
	var size := r * 4
	var c := PixelCanvas.new(size, size)
	var cx := size / 2.0
	c.ellipse(cx, cx, r, r * 0.85, Pal.INK)
	for i in 14:
		var ang := rng.randf() * TAU
		var d := r * rng.randf_range(0.7, 1.7)
		var rr := r * rng.randf_range(0.08, 0.28)
		c.ellipse(cx + cos(ang) * d, cx + sin(ang) * d * 0.85, rr, rr, Pal.INK)
		if d < r * 1.1:
			c.linev(Vector2(cx, cx), Vector2(cx + cos(ang) * d, cx + sin(ang) * d * 0.85), Pal.INK)
	for i in 4:
		var dx := rng.randf_range(-0.6, 0.6) * r
		var drip := rng.randf_range(0.5, 1.2) * r
		c.rect(int(cx + dx), int(cx), maxi(1, r / 6), int(r * 0.6 + drip), Pal.INK)
		c.ellipse(cx + dx + r / 12.0, cx + r * 0.6 + drip, maxf(1.0, r / 8.0), maxf(1.0, r / 8.0), Pal.INK)
	c.ellipse(cx - r * 0.3, cx - r * 0.3, r * 0.18, r * 0.1, Pal.INK_SOFT)
	return _put(key, c)


static func shadow(rx: int, ry: int) -> ImageTexture:
	var key := "shadow_%d_%d" % [rx, ry]
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(rx * 2 + 1, ry * 2 + 1)
	c.ellipse_dither(rx + 0.5, ry + 0.5, rx, ry, Pal.INK)
	c.ellipse(rx + 0.5, ry + 0.5, rx * 0.5, ry * 0.5, Pal.INK)
	return _put(key, c)


static func target_ring(rx: int, ry: int, col: Color) -> ImageTexture:
	var key := "ring_%d_%d_%s" % [rx, ry, col.to_html()]
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(rx * 2 + 3, ry * 2 + 3)
	c.ellipse(rx + 1.5, ry + 1.5, rx + 1, ry + 1, col)
	var hole := PixelCanvas.new(rx * 2 + 3, ry * 2 + 3)
	hole.ellipse(rx + 1.5, ry + 1.5, rx - 1, ry - 1, col)
	for y in c.h:
		for x in c.w:
			if hole.opaque(x, y):
				c.px(x, y, Pal.CLEAR)
	var out := PixelCanvas.new(c.w + 2, c.h + 2)
	out.blit(c, 1, 1)
	out.outline(Pal.INK)
	return _put(key, out)


# ------------------------------------------------------------------ icons --

static func role_icon(role: String, lit: bool) -> ImageTexture:
	var key := "role_%s_%s" % [role, lit]
	if _cache.has(key):
		return _cache[key]
	return _put(key, _role_icon(role, lit))


static func _role_icon(role: String, lit: bool) -> PixelCanvas:
	var c := PixelCanvas.new(17, 17)
	var metal := Pal.GOLD if lit else Pal.PARCHMENT_SHADE
	var metal_hi := Pal.GOLD_LIGHT if lit else Pal.PARCHMENT_DARK
	var field := Pal.role_color(role) if lit else Pal.INK_SOFT
	c.ellipse(8.5, 8.5, 8, 8, metal)
	c.ellipse(8.5, 8.5, 6.5, 6.5, field)
	c.px(4, 3, metal_hi)
	c.px(3, 4, metal_hi)
	var glyph := PixelCanvas.new(17, 17)
	var ink := Pal.PARCHMENT if lit else Pal.PARCHMENT_DARK
	match role:
		"helmsman":
			glyph.poly(PackedVector2Array([Vector2(3.5, 8.5), Vector2(7.5, 4.5), Vector2(7.5, 12.5)]), ink)
			glyph.poly(PackedVector2Array([Vector2(13.5, 8.5), Vector2(9.5, 4.5), Vector2(9.5, 12.5)]), ink)
		"liftmaster":
			glyph.poly(PackedVector2Array([Vector2(8.5, 3.0), Vector2(4.5, 7.5), Vector2(12.5, 7.5)]), ink)
			glyph.poly(PackedVector2Array([Vector2(8.5, 14.0), Vector2(4.5, 9.5), Vector2(12.5, 9.5)]), ink)
		"wingmaster":
			glyph.poly(PixelCanvas.ellipse_points(9.5, 7.5, 5.0, 2.4, -0.6, 16), ink)
			glyph.linev(Vector2(5, 12), Vector2(12, 5), field)
			glyph.px(5, 12, ink)
			glyph.px(4, 13, ink)
		"seer":
			glyph.ellipse(8.5, 8.5, 5.5, 3.2, ink)
			glyph.ellipse(8.5, 8.5, 2.2, 2.2, Pal.GOLD if lit else Pal.PARCHMENT_SHADE)
			glyph.rect(8, 8, 1, 1, Pal.INK)
	c.blit(glyph, 0, 0)
	c.outline(Pal.INK)
	return c


static func activity_icon(group: String) -> ImageTexture:
	var key := "act_%s" % group
	if _cache.has(key):
		return _cache[key]
	var rows: Array = []
	match group:
		"vision":
			rows = ["..KKKKK..", ".KPPKPPK.", "KPPKGKPPK", ".KPPKPPK.", "..KKKKK.."]
		"flight":
			rows = ["......KK.", "....KKWK.", "..KKWWWK.", ".KWWWWK..", "KWWKKK...", "KKK......"]
		"reaction":
			rows = ["...KKK", "..KGGK", ".KGGK.", "KGGGGK", ".KGGK.", "KGK...", "KK...."]
		"song":
			rows = ["..KKKK", "..KGGK", "..KK.K", "..K..K", "KKK.KK", "KGK.KK", "KKK..."]
	return _put(key, PixelCanvas.from_rows(rows, _ink_pal()))


static func relic_icon(relic: String, on: bool) -> ImageTexture:
	var key := "relic_%s_%s" % [relic, on]
	if _cache.has(key):
		return _cache[key]
	return _put(key, _relic_icon(relic, on))


static func _relic_icon(relic: String, on: bool) -> PixelCanvas:
	var c := PixelCanvas.new(14, 14)
	var dim := not on
	match relic:
		"mantle":
			var body := Pal.PARCHMENT_SHADE if dim else Pal.ROYAL
			var fold := Pal.PARCHMENT_DARK if dim else Pal.ROYAL_DARK
			c.poly(PackedVector2Array([Vector2(4, 3), Vector2(10, 3), Vector2(12.5, 12.5), Vector2(1.5, 12.5)]), body)
			c.vline(6, 5, 11, fold)
			c.vline(8, 5, 11, fold)
			c.hline(2, 11, 12, Pal.PARCHMENT_DARK if dim else Pal.GOLD)
			c.rect(3, 2, 8, 2, Pal.PARCHMENT)
			c.px(5, 2, Pal.INK)
			c.px(8, 3, Pal.INK)
		"halo":
			var g := Pal.PARCHMENT_SHADE if dim else Pal.GOLD
			for i in 8:
				var a := TAU * i / 8.0
				c.linev(Vector2(7 + cos(a) * 4, 7 + sin(a) * 4), Vector2(7 + cos(a) * 6, 7 + sin(a) * 6), g)
			c.ellipse(7.0, 7.0, 4, 4, g)
			c.ellipse(7.0, 7.0, 2, 2, Pal.PARCHMENT_DARK if dim else Pal.GOLD_LIGHT)
		"filigree":
			c.poly(PixelCanvas.ellipse_points(8.0, 6.0, 5.5, 2.6, -0.6, 16), Pal.WING)
			var g2 := Pal.PARCHMENT_SHADE if dim else Pal.GOLD
			c.linev(Vector2(3, 11), Vector2(11, 3), g2)
			c.linev(Vector2(5, 10), Vector2(12, 6), g2)
			c.px(3, 11, Pal.INK)
			c.px(2, 12, Pal.INK)
	c.outline(Pal.INK)
	return c


static func arrow(dir: String, filled: bool, col: Color) -> ImageTexture:
	var key := "arrow_%s_%s_%s" % [dir, filled, col.to_html()]
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(9, 9)
	var pts := PackedVector2Array()
	match dir:
		"left":
			pts = PackedVector2Array([Vector2(1.5, 4.5), Vector2(6.5, 0.5), Vector2(6.5, 8.5)])
		"right":
			pts = PackedVector2Array([Vector2(7.5, 4.5), Vector2(2.5, 0.5), Vector2(2.5, 8.5)])
		"up":
			pts = PackedVector2Array([Vector2(4.5, 1.5), Vector2(0.5, 6.5), Vector2(8.5, 6.5)])
		"down":
			pts = PackedVector2Array([Vector2(4.5, 7.5), Vector2(0.5, 2.5), Vector2(8.5, 2.5)])
	c.poly(pts, col if filled else Pal.PARCHMENT)
	c.poly_outline(pts, Pal.INK)
	return _put(key, c)


static func compass_rose(size: int) -> ImageTexture:
	var key := "compass_%d" % size
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(size, size)
	var r := size / 2.0 - 1.0
	var m := size / 2.0
	c.ellipse(m, m, r, r, Pal.GOLD)
	c.ellipse(m, m, r - 2, r - 2, Pal.PARCHMENT)
	for i in 8:
		var a := TAU * i / 8.0
		var inner := r - 5 if i % 2 == 0 else r - 3
		c.linev(Vector2(m + cos(a) * inner, m + sin(a) * inner), Vector2(m + cos(a) * (r - 2), m + sin(a) * (r - 2)), Pal.INK_SOFT)
	c.outline(Pal.INK)
	return _put(key, c)


static func needle(size: int, step: int, lit: bool) -> ImageTexture:
	var key := "needle_%d_%d_%s" % [size, step, lit]
	if _cache.has(key):
		return _cache[key]
	var c := PixelCanvas.new(size, size)
	var m := size / 2.0
	var a := -PI / 2.0 + TAU * step / 8.0
	var tip := Vector2(m + cos(a) * (m - 4), m + sin(a) * (m - 4))
	var tail := Vector2(m - cos(a) * (m - 7), m - sin(a) * (m - 7))
	c.linev(Vector2(m - 0.5, m - 0.5), tip, Pal.CRIMSON if lit else Pal.INK_SOFT)
	c.linev(Vector2(m - 0.5, m - 0.5), tail, Pal.INK_SOFT)
	c.rect(int(m) - 1, int(m) - 1, 2, 2, Pal.GOLD if lit else Pal.INK_SOFT)
	return _put(key, c)


static func lock_icon() -> ImageTexture:
	if _cache.has("lock"):
		return _cache["lock"]
	return _put("lock", PixelCanvas.from_rows([".KKK.", "K...K", "K...K", "KKKKK", "KGGGK", "KGKGK", "KGGGK", "KKKKK"], _ink_pal()))


static func wax_seal(r: int) -> ImageTexture:
	var key := "seal_%d" % r
	if _cache.has(key):
		return _cache[key]
	var size := r * 2 + 6
	var c := PixelCanvas.new(size, size)
	var m := size / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var rr := r + (1.5 if i % 2 == 0 else -0.5) + rng.randf_range(-0.5, 0.5)
		pts.append(Vector2(m + cos(a) * rr, m + sin(a) * rr))
	c.poly(pts, Pal.CRIMSON)
	c.ellipse(m, m, r - 4, r - 4, Pal.CRIMSON_DARK)
	c.ellipse(m, m, r - 6, r - 6, Pal.CRIMSON)
	c.ellipse(m - r * 0.35, m - r * 0.4, r * 0.18, r * 0.1, Pal.CRIMSON_LIGHT)
	c.outline(Pal.INK)
	return _put(key, c)
