extends Control

## Hamlet's brain map, the main screen's top-right corner (it replaced the Seer panel). Drawn from the server's `brainMap`
## (brain/brain_map.py): a second copy of the whole-CNS model driven only by Hamlet's movement, never by the Princess or
## the Giant, so it's safe on the shared screen in every phase. Each region is a group of real neurons; its colour is
## log2(its mean rate / sober rest): dark = quieter than sober rest, gold then crimson = busier.
##
## During the drink questions (Q01-Q03) the panel grows down the right side: the regions the question is about pulse, and
## the map flips between the brain before and after one grape cordial, with the model's computed change per region.
## Every number here comes from the server; the alcohol effect is a disclosed model assumption (the Royal Decree).

const PLAY_RECT := Rect2i(482, 27, 154, 206)
const QUIZ_RECT := Rect2i(482, 28, 154, 306)
const MAP_Y := 24          # the drawing's top inside the panel
const FLIP_S := 1.8        # quiz: seconds on each side of the before/after flip

## Shapes in the drawing's own space (0..146 wide, from MAP_Y down): [region, kind, a, b, c, d]
## kind "e" = ellipse (cx, cy, rx, ry), "r" = rect (x, y, w, h). "" region = the central brain's outline (no value).
const SHAPES := [
	["eye_L", "e", 20, 34, 17, 26], ["eye_R", "e", 126, 34, 17, 26],
	["", "e", 73, 34, 33, 27],
	["memory", "e", 59, 20, 8, 6], ["memory", "e", 87, 20, 8, 6],
	["courtship", "e", 73, 15, 3, 3],
	["instinct", "e", 48, 34, 4, 5], ["instinct", "e", 98, 34, 4, 5],
	["balance", "e", 73, 33, 11, 4],
	["smell", "e", 64, 46, 5, 5], ["smell", "e", 82, 46, 5, 5],
	["taste", "e", 73, 56, 10, 4],
	["commands", "r", 68, 62, 11, 12],
	["cord", "e", 73, 98, 11, 22],
	["muscles", "r", 54, 86, 7, 3], ["muscles", "r", 53, 97, 7, 3], ["muscles", "r", 54, 108, 7, 3],
	["muscles", "r", 86, 86, 7, 3], ["muscles", "r", 87, 97, 7, 3], ["muscles", "r", 86, 108, 7, 3],
]
## Labels: [region, text, x, y, align (-1 right-aligned at x, 0 centred, 1 left-aligned), leader target x, y]
const LABELS := [
	["memory", "MEMORY", 73, -1, 0, 73, 5],
	["eye_L", "L EYE", 20, 63, 0, 20, 61],
	["eye_R", "R EYE", 126, 63, 0, 126, 61],
	["smell", "SMELL", 49, 76, -1, 61, 49],
	["balance", "BALANCE", 49, 86, -1, 64, 35],
	["instinct", "INSTINCT", 49, 96, -1, 47, 38],
	["courtship", "COURTING", 49, 106, -1, 71, 17],
	["taste", "TASTE", 95, 76, 1, 81, 57],
	["commands", "COMMANDS", 95, 86, 1, 79, 70],
	["escape", "ESCAPE", 95, 96, 1, 77, 80],
	["cord", "CORD", 95, 106, 1, 83, 100],
	["muscles", "MUSCLES", 95, 116, 1, 93, 110],
]
const NAMES := {"eye_L": "LEFT EYE", "eye_R": "RIGHT EYE", "smell": "SMELL", "memory": "MEMORY", "balance": "BALANCE",
	"instinct": "INSTINCT", "courtship": "COURTSHIP", "taste": "TASTE", "commands": "COMMANDS", "escape": "ESCAPE",
	"cord": "NERVE CORD", "muscles": "MUSCLES"}

var has_map := false
var regions := {}
var drinks := 0
var neurons := 0
var kind := ""
var gaba_pct := 0
var excite_pct := 0
var quiz: Dictionary = {}
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place()


func apply(cs: CourtState) -> void:
	var bm: Variant = cs.raw.get("brainMap", null)
	has_map = bm is Dictionary
	quiz = {}
	if has_map:
		regions = bm.get("regions", {})
		drinks = int(bm.get("drinks", 0))
		neurons = int(bm.get("neurons", 0))
		kind = str(bm.get("kind", ""))
		gaba_pct = int(bm.get("gabaPct", 0))
		excite_pct = int(bm.get("excitePct", 0))
		if bm.get("quiz") is Dictionary and cs.phase in ["comic", "question"]:
			quiz = bm["quiz"]
	_place()
	queue_redraw()


func quiz_mode() -> bool:
	return has_map and not quiz.is_empty()


func _place() -> void:
	var r := QUIZ_RECT if quiz_mode() else PLAY_RECT
	position = Vector2(r.position)
	size = Vector2(r.size)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


## Region colour for a log2 ratio: ink-blue when quieter than sober rest, parchment at rest, gold then crimson when busier.
static func heat(v: float) -> Color:
	var x := clampf(v, -1.6, 1.6)
	if x >= 0.0:
		if x < 0.6:
			return Pal.PARCHMENT_DARK.lerp(Pal.GOLD_LIGHT, x / 0.6)
		return Pal.GOLD_LIGHT.lerp(Pal.CRIMSON_LIGHT, (x - 0.6) / 1.0)
	return Pal.PARCHMENT_DARK.lerp(Pal.ROYAL_DARK, -x / 1.6)


func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	HudDraw.panel(self, Rect2i(0, 0, w, h))
	var bold := PixelFonts.bold()
	var label := PixelFonts.label()
	HudDraw.text(self, bold, 6, 5, "HAMLET'S BRAIN", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	if not has_map:
		HudDraw.text(self, label, 6, 30, "NO BRAIN DATA:", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.text(self, label, 6, 40, "PLACEHOLDER MODE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		return
	var live_on := int(_t * 2.0) % 2 == 0
	draw_rect(Rect2(w - 37, 6, 5, 5), Pal.CRIMSON_LIGHT if live_on else Pal.CRIMSON_DARK)
	HudDraw.text_right(self, bold, w - 6, 5, "LIVE", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	var sub := "%s NEURONS" % _thousands(neurons) if neurons > 0 else "MALECNS"
	if kind == "changeling":
		sub = "CHANGELING WIRING"
	HudDraw.text(self, label, 6, 14, sub, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	var shown := regions
	var focus: Array = []
	var flip_after := false
	if quiz_mode():
		focus = quiz.get("focus", [])
		flip_after = int(_t / FLIP_S) % 2 == 1
		shown = quiz.get("to", {}) if flip_after else quiz.get("from", {})
	_draw_map(shown, focus)
	if quiz_mode():
		_draw_flip_tag(flip_after)
		_draw_quiz(bold, label, w)
	else:
		_draw_footer(bold, label, w, h)


func _draw_map(values: Dictionary, focus: Array) -> void:
	var ox := 4
	var oy := MAP_Y
	var pulse := int(_t * 3.0) % 2 == 0
	var mem_col := Pal.CRIMSON if "memory" in focus else Pal.INK_SOFT
	for mx in [59, 87]:
		draw_line(Vector2(ox + 73.5, oy + 6.5), Vector2(ox + mx + 0.5, oy + 15.5), mem_col, -1.0)
	# the giant fibres run from the brain down the neck into the cord
	var esc := heat(float(values.get("escape", 0.0)))
	for s in SHAPES:
		var region: String = s[0]
		var fill := Pal.PARCHMENT_SHADE if region == "" else heat(float(values.get(region, 0.0)))
		var outline := Pal.INK
		if region in focus:
			outline = Pal.CRIMSON if pulse else Pal.CRIMSON_LIGHT
		if s[1] == "e":
			_ellipse(Vector2(ox + int(s[2]), oy + int(s[3])), int(s[4]), int(s[5]), fill, outline, region in focus)
		else:
			var r := Rect2(ox + int(s[2]), oy + int(s[3]), int(s[4]), int(s[5]))
			draw_rect(r, fill)
			draw_rect(r.grow(1), outline, false, 2.0 if region in focus else 1.0)
	for fx in [70, 76]:
		draw_rect(Rect2(ox + fx, oy + 38, 1, 44), Pal.INK)
		draw_rect(Rect2(ox + fx + 1, oy + 38, 1, 44), esc)
	if "escape" in focus:
		draw_rect(Rect2(ox + 69, oy + 38, 10, 44), Pal.CRIMSON if pulse else Pal.CRIMSON_LIGHT, false, 1.0)
	# leaders from each label to its region (thin, over the shapes)
	for l in LABELS:
		if int(l[4]) == 0:
			continue
		var tx: int = l[5]
		var ty: int = l[6]
		var lx: int = l[2]
		var ly: int = l[3] + 3
		if int(l[4]) == -1:
			lx += 2
		elif int(l[4]) == 1:
			lx -= 2
		else:
			continue
		var col := Pal.CRIMSON if str(l[0]) in focus else Pal.INK_SOFT
		draw_line(Vector2(ox + lx, oy + ly) + Vector2(0.5, 0.5), Vector2(ox + tx, oy + ty) + Vector2(0.5, 0.5), col, -1.0)
	# labels
	var font := PixelFonts.label()
	var bold := PixelFonts.bold()
	for l in LABELS:
		var f := bold if str(l[0]) in focus else font
		var col := Pal.CRIMSON if str(l[0]) in focus else Pal.INK
		var x: int = ox + int(l[2])
		var y: int = oy + int(l[3])
		match int(l[4]):
			-1:
				HudDraw.text_right(self, f, x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)
			0:
				HudDraw.text_center(self, f, x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)
			_:
				HudDraw.text(self, f, x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)


func _ellipse(c: Vector2, rx: int, ry: int, fill: Color, outline: Color, thick: bool) -> void:
	var pts := PackedVector2Array()
	var n := 28
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(roundf(c.x + rx * cos(a)), roundf(c.y + ry * sin(a))))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, outline, 2.0 if thick else 1.0)


func _draw_footer(bold: Font, label: Font, w: int, h: int) -> void:
	var y := h - 32
	draw_rect(Rect2(4, y - 3, w - 8, 1), Pal.PARCHMENT_SHADE)
	HudDraw.text(self, bold, 6, y, "CORDIALS", Pal.INK, PixelFonts.LABEL_SIZE)
	for i in 3:
		var x := 64 + i * 12
		draw_rect(Rect2(x, y - 1, 9, 9), Pal.INK)
		draw_rect(Rect2(x + 1, y, 7, 7), Pal.GRAPE if i < drinks else Pal.PARCHMENT)
	HudDraw.text_right(self, bold, w - 6, y, "%d / 3" % drinks, Pal.CRIMSON if drinks > 0 else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	# the key: a chip in each colour of the scale
	var ky := y + 12
	for i in 5:
		draw_rect(Rect2(6 + i * 7, ky, 6, 6), heat(-1.4 + i * 0.7))
	draw_rect(Rect2(5, ky - 1, 36, 8), Pal.INK, false, 1.0)
	HudDraw.text(self, label, 46, ky, "QUIET  -  BUSY", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _draw_flip_tag(after: bool) -> void:
	var before_n := int(quiz.get("before", 0))
	var after_n := int(quiz.get("after", 0))
	var n := after_n if after else before_n
	var s := "SOBER" if n == 0 else ("%d CORDIAL%s" % [n, "" if n == 1 else "S"])
	var f := PixelFonts.bold()
	var tw := PixelFonts.width(f, s, PixelFonts.LABEL_SIZE) + 8
	var r := Rect2i(4, MAP_Y + 124, tw, 12)
	HudDraw.panel(self, r, Pal.CRIMSON if after and n > 0 else Pal.ROYAL, Pal.INK, Color(0, 0, 0, 0), Pal.ROYAL_DARK)
	HudDraw.text(self, f, r.position.x + 4, r.position.y + 2, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)


func _draw_quiz(bold: Font, label: Font, w: int) -> void:
	var y := MAP_Y + 139
	draw_rect(Rect2(4, y, w - 8, 1), Pal.PARCHMENT_SHADE)
	y += 4
	var status := str(quiz.get("status", "offer"))
	var head: String = {"offer": "IF THE ANSWER IS WRONG", "drunk": "WRONG ANSWER: HE DRANK", "avoided": "RIGHT: PEAR NECTAR"}.get(status, "")
	HudDraw.text(self, bold, 6, y, head, Pal.CRIMSON if status != "avoided" else Pal.ROYAL, PixelFonts.LABEL_SIZE)
	y += 10
	var sub := "ONE GRAPE CORDIAL WOULD DO:" if status == "offer" else ("ONE CORDIAL DID THIS:" if status == "drunk" else "IT SPARED HIM THIS:")
	if bool(quiz.get("maxed", false)):
		sub = "ALREADY AT THE LIMIT (3):"
	HudDraw.text(self, label, 6, y, sub, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	y += 12
	var pct: Dictionary = quiz.get("pct", {})
	var from: Dictionary = quiz.get("from", {})
	var to: Dictionary = quiz.get("to", {})
	for key in quiz.get("focus", []):
		var p := int(pct.get(key, 0))
		HudDraw.text(self, bold, 6, y, str(NAMES.get(key, key)), Pal.INK, PixelFonts.LABEL_SIZE)
		var ps := ("%+d%%" % p) if p != 0 else "0%"
		HudDraw.text_right(self, PixelFonts.caption(), w - 6, y - 3, ps, Pal.CRIMSON if p < 0 else Pal.ROYAL, PixelFonts.CAPTION_SIZE)
		# before / after bars, on the map's scale
		var b := clampf((float(from.get(key, 0.0)) + 1.6) / 3.2, 0.0, 1.0)
		var a := clampf((float(to.get(key, 0.0)) + 1.6) / 3.2, 0.0, 1.0)
		HudDraw.bar(self, Rect2i(6, y + 10, 90, 5), b, Pal.ROYAL)
		HudDraw.bar(self, Rect2i(6, y + 16, 90, 5), a, Pal.CRIMSON)
		y += 26
	# the legend for the bars, and the assumption behind all of it
	var ly := QUIZ_RECT.size.y - 34
	draw_rect(Rect2(6, ly + 1, 6, 5), Pal.ROYAL)
	HudDraw.text(self, label, 15, ly, "BEFORE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	draw_rect(Rect2(62, ly + 1, 6, 5), Pal.CRIMSON)
	HudDraw.text(self, label, 71, ly, "AFTER", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text(self, label, 6, ly + 10, "ASSUMED, PER CORDIAL:", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text(self, label, 6, ly + 19, "GABA +%d%%  EXCITE -%d%%" % [gaba_pct, excite_pct], Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


static func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out
