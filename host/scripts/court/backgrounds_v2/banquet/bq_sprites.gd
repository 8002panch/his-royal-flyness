extends RefCounted

## Banquet v2 props, drawn in code with PixelCanvas at their exact on-screen
## size (chunkier than v1 so they still read at distance) and cached per size.
## Palette only: Pal.* plus the few tints below (dark/light steps of the same hues).

const PEWTER := Color("#B5AE9C")
const PEWTER_DARK := Color("#7C7566")
const OAK := Color("#6B4426")
const OAK_DARK := Color("#43291A")
const OAK_LIGHT := Color("#8A5C34")
const HOOP := Color("#3A342C")
const HOOP_LIGHT := Color("#6A6256")
const WINE := Color("#5C1030")
const WINE_LIGHT := Color("#9B2A4A")

static var _cache := {}


static func _memo(key: String, make: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


## Gold goblet, `h` tall: cup, stem, foot, wine on top.
static func goblet(h: int) -> PixelCanvas:
	return _memo("gob%d" % h, func() -> PixelCanvas:
		var hh := maxi(8, h)
		var w := maxi(6, int(round(hh * 0.66)))
		var c := PixelCanvas.new(w + 2, hh + 2)
		var cx := (w + 2) / 2.0
		var cup_h := maxi(4, int(hh * 0.5))
		var narrow := w * 0.24
		c.poly(PackedVector2Array([Vector2(1, 1), Vector2(w + 1, 1), Vector2(w + 1 - narrow, cup_h + 1), Vector2(1 + narrow, cup_h + 1)]), Pal.GOLD)
		# shaded right side and lit left edge
		c.poly(PackedVector2Array([Vector2(w + 1 - w * 0.3, 1), Vector2(w + 1, 1), Vector2(w + 1 - narrow, cup_h + 1), Vector2(w + 1 - narrow - w * 0.24, cup_h + 1)]), Pal.GOLD_DARK)
		c.vline(2, 2, maxi(2, cup_h - 2), Pal.GOLD_LIGHT)
		# wine surface
		c.hline(1, w + 1, 1, WINE_LIGHT)
		c.hline(2, w, 2, WINE)
		# stem with a knop, then a broad foot
		var stem_w := 2 if hh >= 16 else 1
		c.rect(int(cx - stem_w / 2.0), cup_h + 1, stem_w, hh - cup_h - 1, Pal.GOLD_DARK)
		c.rect(int(cx - 1), cup_h + 1 + (hh - cup_h) / 3, 3, 1, Pal.GOLD)
		var fw := maxi(3, int(w * 0.36))
		c.hline(int(cx - fw), int(cx + fw), hh, Pal.GOLD)
		c.hline(int(cx - fw) + 1, int(cx + fw) - 1, hh - 1, Pal.GOLD_DARK)
		c.outline(Pal.INK)
		return c)


## Tall gold candelabra `h` tall (three candles). {canvas, flames:[Vector2i]}.
static func candelabra(h: int, arms: int = 3) -> Dictionary:
	return _memo("cand%d_%d" % [h, arms], func() -> Dictionary:
		var hh := maxi(12, h)
		var w := int(round(hh * 0.85))
		w += (w + 1) % 2
		var c := PixelCanvas.new(w + 4, hh + 2)
		var cx := (w + 4) / 2
		var arm_y := int(round(hh * 0.5))
		var thick := 2 if hh >= 26 else 1
		# foot, stem, knop
		c.rect(cx - 3, hh - 1, 7, 2, Pal.GOLD_DARK)
		c.rect(cx - 2, hh - 2, 5, 1, Pal.GOLD)
		c.rect(cx - thick / 2, arm_y, thick, hh - arm_y - 1, Pal.GOLD)
		c.rect(cx - 1, int(hh * 0.72), 3, 2, Pal.GOLD_LIGHT)
		# arms: a shallow U through the candle sockets
		var xs: Array = []
		if arms == 1:
			xs = [cx]
		elif arms == 3:
			xs = [cx - (w / 2 - 1), cx, cx + (w / 2 - 1)]
		else:
			xs = [cx - (w / 2 - 1), cx - (w / 4), cx + (w / 4), cx + (w / 2 - 1)]
		var flames: Array = []
		for x in xs:
			var mid: bool = (x == cx)
			var top := int(round(hh * (0.10 if mid else 0.22)))
			if arms == 1:
				top = int(round(hh * 0.15))
			var y_arm := arm_y + (0 if mid else -maxi(1, hh / 14))
			if x != cx:
				c.line(cx, arm_y + 1, x, y_arm, Pal.GOLD)
				c.px(x, y_arm + 1, Pal.GOLD_DARK)
			c.rect(x - thick / 2, top, maxi(2, thick + 1), y_arm - top + 1, Pal.PARCHMENT)
			c.px(x - thick / 2, top + 1, Pal.PARCHMENT_DARK)
			c.rect(x - 1, y_arm + 1, 3, 1, Pal.GOLD_LIGHT)
			flames.append(Vector2i(x - 1 - thick / 2 + 1, top - 5))
		c.outline(Pal.INK)
		return {"canvas": c, "flames": flames})


## Big blue-and-gold punch bowl with crimson punch and a ladle. `w` wide.
static func punch_bowl(w: int) -> PixelCanvas:
	return _memo("punch%d" % w, func() -> PixelCanvas:
		var ww := maxi(16, w)
		var hh := int(ww * 0.78)
		var c := PixelCanvas.new(ww + 2, hh + 2)
		var cx := (ww + 2) / 2.0
		var rim_y := hh * 0.34
		var rx := ww * 0.5
		# foot and stem
		c.rect(int(cx - ww * 0.18), int(hh * 0.86), int(ww * 0.36), maxi(2, int(hh * 0.12)), Pal.GOLD_DARK)
		c.rect(int(cx - ww * 0.1), int(hh * 0.72), int(ww * 0.2), int(hh * 0.16), Pal.GOLD)
		# bowl body: half ellipse below the rim
		var pts := PackedVector2Array()
		for i in range(0, 13):
			var a := PI * i / 12.0
			pts.append(Vector2(cx + cos(a) * rx * 0.98, rim_y + sin(a) * hh * 0.42))
		c.poly(pts, Pal.ROYAL)
		# lit left, shaded right
		for i in range(0, 13):
			var a := PI * i / 12.0
			if i >= 8:
				c.px(int(cx + cos(a) * rx * 0.9), int(rim_y + sin(a) * hh * 0.4), Pal.ROYAL_DARK)
		c.hline(int(cx - rx * 0.72), int(cx - rx * 0.4), int(rim_y + hh * 0.13), Pal.ROYAL_LIGHT)
		c.hline(int(cx - rx * 0.86), int(cx - rx * 0.6), int(rim_y + hh * 0.06), Pal.ROYAL_LIGHT)
		# gold band with pips
		c.hline(int(cx - rx * 0.85), int(cx + rx * 0.85), int(rim_y + hh * 0.2), Pal.GOLD_DARK)
		for k in range(-2, 3):
			c.px(int(cx + k * rx * 0.3), int(rim_y + hh * 0.29), Pal.GOLD)
		# rim ring (gold) and punch surface
		c.ellipse(cx, rim_y, rx, hh * 0.15, Pal.GOLD)
		c.ellipse(cx, rim_y + 0.5, rx * 0.86, hh * 0.115, WINE_LIGHT)
		c.ellipse(cx + rx * 0.05, rim_y + 1, rx * 0.6, hh * 0.07, Pal.CRIMSON)
		c.hline(int(cx - rx * 0.6), int(cx - rx * 0.3), int(rim_y - hh * 0.05), Pal.CRIMSON_LIGHT)
		# ladle: handle up to the right, cup in the punch
		c.line(int(cx + rx * 0.1), int(rim_y), int(cx + rx * 0.72), int(rim_y - hh * 0.32), Pal.GOLD_LIGHT)
		c.rect(int(cx + rx * 0.05), int(rim_y - 1), maxi(3, int(ww * 0.12)), 2, Pal.GOLD)
		c.outline(Pal.INK)
		return c)


## Standing pitcher/jug `h` tall.
static func jug(h: int) -> PixelCanvas:
	return _memo("jug%d" % h, func() -> PixelCanvas:
		var hh := maxi(8, h)
		var w := maxi(6, int(round(hh * 0.62)))
		var c := PixelCanvas.new(w + 4, hh + 2)
		var cx := (w + 2) / 2.0
		c.ellipse(cx, hh * 0.58, w * 0.5, hh * 0.38, Pal.ROYAL)
		c.ellipse(cx - w * 0.16, hh * 0.46, w * 0.16, hh * 0.14, Pal.ROYAL_LIGHT)
		c.rect(int(cx - w * 0.24), 1, int(w * 0.48), int(hh * 0.28), Pal.ROYAL_DARK)
		c.hline(int(cx - w * 0.3), int(cx + w * 0.3), 1, Pal.GOLD)
		c.hline(int(cx - w * 0.5), int(cx + w * 0.5), int(hh * 0.62), Pal.GOLD_DARK)
		c.line(int(cx + w * 0.44), int(hh * 0.3), int(cx + w * 0.72), int(hh * 0.5), Pal.GOLD_DARK)
		c.line(int(cx + w * 0.72), int(hh * 0.5), int(cx + w * 0.44), int(hh * 0.78), Pal.GOLD_DARK)
		c.outline(Pal.INK)
		return c)


## Footed fruit bowl, heaped. `w` wide.
static func fruit_bowl(w: int) -> PixelCanvas:
	return _memo("fruit%d" % w, func() -> PixelCanvas:
		var ww := maxi(10, w)
		var c := PixelCanvas.new(ww + 2, int(ww * 0.85) + 2)
		var cx := (ww + 2) / 2.0
		var base := c.h - 2.0
		var cols := [Pal.CRIMSON, Pal.GOLD_LIGHT, Pal.GRAPE, Pal.CRIMSON_LIGHT, Pal.AMBER]
		var spots := [Vector2(-0.24, 0.5), Vector2(0.22, 0.52), Vector2(0.0, 0.62), Vector2(-0.1, 0.34), Vector2(0.14, 0.32), Vector2(0.02, 0.18)]
		var r := maxf(2.0, ww * 0.16)
		for i in spots.size():
			var p: Vector2 = spots[i]
			c.ellipse(cx + p.x * ww, base - p.y * ww * 0.9, r, r, cols[i % cols.size()])
			c.px(int(cx + p.x * ww - r * 0.4), int(base - p.y * ww * 0.9 - r * 0.4), Pal.PARCHMENT)
		c.poly(PackedVector2Array([Vector2(cx - ww * 0.5, base - ww * 0.3), Vector2(cx + ww * 0.5, base - ww * 0.3),
			Vector2(cx + ww * 0.32, base - ww * 0.1), Vector2(cx - ww * 0.32, base - ww * 0.1)]), Pal.GOLD)
		c.hline(int(cx - ww * 0.46), int(cx + ww * 0.46), int(base - ww * 0.3), Pal.GOLD_LIGHT)
		c.rect(int(cx - ww * 0.08), int(base - ww * 0.1), maxi(2, int(ww * 0.16)), int(ww * 0.1) + 1, Pal.GOLD_DARK)
		c.rect(int(cx - ww * 0.26), int(base), int(ww * 0.52), 2, Pal.GOLD_DARK)
		c.outline(Pal.INK)
		return c)


## Roast on a pewter platter. `w` wide.
static func roast(w: int) -> PixelCanvas:
	return _memo("roast%d" % w, func() -> PixelCanvas:
		var ww := maxi(12, w)
		var c := PixelCanvas.new(ww + 2, int(ww * 0.6) + 2)
		var cx := (ww + 2) / 2.0
		var cy := c.h - ww * 0.2
		c.ellipse(cx, cy, ww * 0.5, ww * 0.17, PEWTER)
		c.ellipse(cx, cy - 0.5, ww * 0.42, ww * 0.12, PEWTER_DARK)
		# the bird
		c.ellipse(cx, cy - ww * 0.12, ww * 0.34, ww * 0.2, Pal.AMBER_DARK)
		c.ellipse(cx - ww * 0.04, cy - ww * 0.16, ww * 0.26, ww * 0.14, Pal.AMBER)
		c.ellipse(cx - ww * 0.1, cy - ww * 0.2, ww * 0.1, ww * 0.05, Pal.AMBER_LIGHT)
		# drumsticks
		c.rect(int(cx + ww * 0.3), int(cy - ww * 0.22), maxi(2, int(ww * 0.12)), maxi(2, int(ww * 0.06)), Pal.PARCHMENT)
		c.rect(int(cx - ww * 0.44), int(cy - ww * 0.2), maxi(2, int(ww * 0.12)), maxi(2, int(ww * 0.06)), Pal.PARCHMENT)
		# garnish
		c.px(int(cx - ww * 0.42), int(cy - 1), Pal.CRIMSON)
		c.px(int(cx + ww * 0.4), int(cy - 1), Pal.CRIMSON)
		c.px(int(cx + ww * 0.34), int(cy), Pal.GRAPE)
		c.outline(Pal.INK)
		return c)


static func loaf(w: int) -> PixelCanvas:
	return _memo("loaf%d" % w, func() -> PixelCanvas:
		var ww := maxi(7, w)
		var c := PixelCanvas.new(ww + 2, int(ww * 0.55) + 2)
		var cx := (ww + 2) / 2.0
		c.ellipse(cx, c.h / 2.0 + 0.5, ww * 0.48, ww * 0.23, Pal.AMBER)
		c.ellipse(cx - ww * 0.05, c.h / 2.0 - 0.5, ww * 0.3, ww * 0.1, Pal.AMBER_LIGHT)
		for k in 3:
			c.px(int(cx - ww * 0.2 + k * ww * 0.2), int(c.h / 2.0), Pal.AMBER_DARK)
		c.outline(Pal.INK)
		return c)


static func cheese(w: int) -> PixelCanvas:
	return _memo("cheese%d" % w, func() -> PixelCanvas:
		var ww := maxi(7, w)
		var c := PixelCanvas.new(ww + 2, int(ww * 0.6) + 2)
		var cx := (ww + 2) / 2.0
		var by := c.h - 2.0
		c.rect(1, int(by - ww * 0.32), ww, int(ww * 0.34) + 1, Pal.GOLD)
		c.ellipse(cx, by - ww * 0.32, ww * 0.5, ww * 0.14, Pal.GOLD_LIGHT)
		c.px(int(cx - ww * 0.15), int(by - ww * 0.32), Pal.GOLD_DARK)
		c.px(int(cx + ww * 0.2), int(by - ww * 0.3), Pal.GOLD_DARK)
		c.px(int(cx), int(by - ww * 0.1), Pal.GOLD_DARK)
		c.outline(Pal.INK)
		return c)


## Standing oak wine barrel `h` tall with iron hoops, lit rim on top and a tap.
static func barrel(h: int) -> PixelCanvas:
	return _memo("barrel%d" % h, func() -> PixelCanvas:
		var hh := maxi(14, h)
		var w := int(round(hh * 0.86))
		w += w % 2
		var c := PixelCanvas.new(w + 6, hh + 2)
		var cx := (w + 6) / 2.0
		var top := hh * 0.14
		var bot := hh - 2.0
		var pts := PackedVector2Array()
		var n := 12
		for i in range(n + 1):
			var u := float(i) / n
			pts.append(Vector2(cx + w * 0.34 + w * 0.13 * sin(u * PI), lerpf(top, bot, u)))
		for i in range(n + 1):
			var u := 1.0 - float(i) / n
			pts.append(Vector2(cx - w * 0.34 - w * 0.13 * sin(u * PI), lerpf(top, bot, u)))
		c.poly(pts, OAK)
		# staves: dark seams, shaded right third, light left strip
		var x0 := int(cx - w * 0.47)
		var x1 := int(cx + w * 0.47)
		for x in range(x0, x1 + 1):
			for y in range(int(top), int(bot) + 1):
				if not c.opaque(x, y):
					continue
				var u2 := (x - x0) / float(maxi(1, x1 - x0))
				if u2 > 0.72:
					c.px(x, y, OAK_DARK)
				elif u2 < 0.22:
					c.px(x, y, OAK_LIGHT)
		for k in range(1, 6):
			var sx := int(lerpf(x0, x1, k / 6.0))
			for y in range(int(top) + 2, int(bot) - 1):
				if c.opaque(sx, y) and (y % 3 != 0):
					c.px(sx, y, OAK_DARK)
		# hoops
		for f in [0.12, 0.34, 0.66, 0.88]:
			var ff: float = f
			var hy := int(lerpf(top, bot, ff))
			var half := w * 0.34 + w * 0.13 * sin(ff * PI)
			c.hline(int(cx - half), int(cx + half), hy, HOOP)
			c.hline(int(cx - half), int(cx + half), hy + 1, HOOP)
			c.px(int(cx - half * 0.55), hy, HOOP_LIGHT)
		# lid ellipse
		c.ellipse(cx, top, w * 0.34, maxf(2.0, hh * 0.09), OAK_LIGHT)
		c.ellipse(cx, top, w * 0.24, maxf(1.0, hh * 0.05), OAK)
		c.px(int(cx - w * 0.1), int(top), OAK_DARK)
		# spigot
		c.rect(int(cx + w * 0.02), int(hh * 0.62), 3, 2, Pal.GOLD_DARK)
		c.px(int(cx + w * 0.02) + 1, int(hh * 0.62) + 2, WINE_LIGHT)
		c.outline(Pal.INK)
		return c)


## Wall torch: bracket + oiled head. {canvas, flame: Vector2i}
static func torch(h: int) -> Dictionary:
	return _memo("torch%d" % h, func() -> Dictionary:
		var hh := maxi(10, h)
		var w := maxi(7, int(round(hh * 0.6)))
		w += 1 - w % 2
		var c := PixelCanvas.new(w + 2, hh + 2)
		var cx := (w + 2) / 2
		c.rect(cx - 1, int(hh * 0.5), 3, hh - int(hh * 0.5), HOOP)
		c.rect(cx - 2, int(hh * 0.62), 5, 2, HOOP_LIGHT)
		c.rect(cx - 2, hh - 2, 5, 3, HOOP)
		c.poly(PackedVector2Array([Vector2(cx - 3, hh * 0.24), Vector2(cx + 4, hh * 0.24), Vector2(cx + 2, hh * 0.52), Vector2(cx - 1, hh * 0.52)]), OAK_DARK)
		c.hline(cx - 2, cx + 2, int(hh * 0.26), OAK)
		c.outline(Pal.INK)
		return {"canvas": c, "flame": Vector2i(cx - 1, int(hh * 0.24) - 5)})


## Hanging lantern (chain + iron cage + candle). {canvas, flame}
static func lantern(h: int) -> Dictionary:
	return _memo("lantern%d" % h, func() -> Dictionary:
		var hh := maxi(12, h)
		var w := maxi(7, int(hh * 0.4))
		w += 1 - w % 2
		var c := PixelCanvas.new(w + 2, hh + 2)
		var cx := (w + 2) / 2
		var chain := int(hh * 0.4)
		for y in range(0, chain, 2):
			c.px(cx, y, HOOP_LIGHT)
		var top := chain
		c.rect(cx - w / 2, top, w, hh - top - 1, HOOP)
		c.rect(cx - w / 2 + 1, top + 2, w - 2, hh - top - 4, Pal.GOLD_DARK)
		c.hline(cx - w / 2, cx + w / 2, top, Pal.GOLD)
		c.hline(cx - w / 2, cx + w / 2, hh - 1, Pal.GOLD)
		c.vline(cx, top + 2, hh - 3, HOOP)
		c.outline(Pal.INK)
		return {"canvas": c, "flame": Vector2i(cx - 1, top + 1)})


## Tall banner on a tail: drawn straight into the painter instead (see builder).

## Small emblem sprites for banners: crown, star, heart, fleur. `s` = scale (1 or 2).
static func emblem(kind: String) -> PixelCanvas:
	return _memo("emb_" + kind, func() -> PixelCanvas:
		var pal := {"G": Pal.GOLD, "L": Pal.GOLD_LIGHT, "g": Pal.GOLD_DARK, "R": Pal.CRIMSON, "P": Pal.PARCHMENT}
		match kind:
			"crown":
				return PixelCanvas.from_rows(["L.L.L", "GGGGG", "GRGRG", "ggggg"], pal)
			"star":
				return PixelCanvas.from_rows(["..L..", "GGGGG", ".GGG.", "GG.GG"], pal)
			"heart":
				return PixelCanvas.from_rows([".RR.RR.", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."], pal)
			_:
				return PixelCanvas.from_rows(["..L..", ".GGG.", "GGGGG", "..G..", ".ggg."], pal)
		)


## Pewter/gilded cup lying on its side (spilled), for Sir Cheapdate's table.
static func stub_candle(h: int) -> Dictionary:
	return _memo("stub%d" % h, func() -> Dictionary:
		var hh := maxi(6, h)
		var c := PixelCanvas.new(9, hh + 3)
		c.rect(2, hh - 1, 5, 2, Pal.GOLD_DARK)
		c.rect(3, 3, 3, hh - 4, Pal.PARCHMENT)
		c.px(3, 3, Pal.PARCHMENT_DARK)
		c.px(5, 4, Pal.PARCHMENT_SHADE)
		c.outline(Pal.INK)
		return {"canvas": c, "flame": Vector2i(3, -2)})


## Animated flame textures: size 0 = candle flame (3x5), 1 = torch flame (5x8).
static func flame_tex(frame: int, size: int) -> ImageTexture:
	return _memo("flame%d_%d" % [size, frame % 3], func() -> ImageTexture:
		var rows: Array
		if size == 0:
			rows = [
				[".F.", ".F.", "FFF", "FOF", ".O."],
				["F..", ".F.", "FFF", "FOF", ".O."],
				["..F", ".F.", "FFF", "FOF", ".O."],
			][frame % 3]
		else:
			rows = [
				["..F..", "..F..", ".FFF.", "FFFFF", "FFOFF", "FOOOF", ".OOO."],
				["...F.", "..FF.", ".FFF.", "FFFFF", "FFOFF", "FOOOF", ".OOO."],
				[".F...", ".FF..", ".FFF.", "FFFFF", "FFOFF", "FOOOF", ".OOO."],
			][frame % 3]
		var pal := {"F": Pal.FLAME, "O": Pal.FLAME_OUT}
		return PixelCanvas.from_rows(rows, pal).texture())
