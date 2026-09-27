extends Control

## Hamlet's brain map, the main screen's top-right corner (it replaced the Seer panel). Drawn from the server's `brainMap`
## (brain/brain_map.py): a second copy of the whole-CNS model driven only by Hamlet's movement, never by the Princess or
## the Giant, so it's safe on the shared screen in every phase.
##
## Made for someone seeing it for the first time: six regions with plain names, a line that says in words what his brain
## is doing right now, busy regions that glow, sluggish ones that doze ("z"), signals that visibly run from his eyes down
## to his wings and legs while he flies, and a colour key. Each region's colour is log2(its mean rate / sober rest).
##
## During the drink questions (Q01-Q03) the panel grows down the right side: the regions the question is about pulse, and
## the map flips between the brain before and after one grape cordial, with the model's computed change per region.
## Every number comes from the server; the alcohol effect is a disclosed model assumption (the Royal Decree).

const PLAY_RECT := Rect2i(482, 27, 154, 216)
const QUIZ_RECT := Rect2i(482, 28, 154, 306)
const MAP_Y := 46          # the drawing's top inside the panel
const FLIP_S := 1.8        # quiz: seconds on each side of the before/after flip

## Shapes in the drawing's own space (0..146 wide, from MAP_Y down): [region, kind, a, b, c, d]
## kind "e" = ellipse (cx, cy, rx, ry), "r" = rect (x, y, w, h). "" region = the central brain's outline (no value).
const SHAPES := [
	["eye_L", "e", 21, 34, 18, 27], ["eye_R", "e", 125, 34, 18, 27],
	["", "e", 73, 34, 34, 28],
	["memory", "e", 59, 21, 10, 7], ["memory", "e", 87, 21, 10, 7],
	["balance", "e", 73, 35, 14, 5],
	["smell", "e", 64, 50, 6, 5], ["smell", "e", 82, 50, 6, 5],
	["commands", "r", 67, 62, 13, 13],
	["body", "r", 52, 84, 9, 3], ["body", "r", 51, 95, 9, 3], ["body", "r", 52, 106, 9, 3],
	["body", "r", 86, 84, 9, 3], ["body", "r", 87, 95, 9, 3], ["body", "r", 86, 106, 9, 3],
	["body", "e", 73, 97, 13, 21],
]
## Side labels: [region, lines, x, y, align (-1 right-aligned at x, 1 left-aligned), point the line at x, y]
const LABELS := [
	["balance", ["BALANCE"], 46, 78, -1, 62, 37],
	["smell", ["SMELL"], 46, 96, -1, 60, 52],
	["commands", ["ORDERS"], 97, 78, 1, 80, 68],
	["body", ["WINGS", "& LEGS"], 97, 96, 1, 87, 99],
]
const NAMES := {"eyes": "EYES", "memory": "MEMORY", "balance": "BALANCE", "smell": "SMELL", "commands": "FLIGHT ORDERS",
	"body": "WINGS & LEGS"}
## What a region doing more (or less) than usual means, in words, for the line under the title
const BUSY := {"eyes": "EYES TRACKING MOTION", "commands": "SENDING FLIGHT ORDERS", "body": "WINGS & LEGS AT WORK",
	"memory": "MEMORY BUSY", "balance": "BALANCE WORKING", "smell": "SMELLING HARD"}
const SLOW := {"eyes": "EYES DULLED", "commands": "ORDERS SLOWED", "body": "WINGS & LEGS SLUGGISH",
	"memory": "MEMORY FOGGED", "balance": "BALANCE SLIPPING", "smell": "SMELL DULLED"}
## Where a dozing region shows its "z z" (drawing space)
const DOZE_AT := {"memory": Vector2(97, 9), "balance": Vector2(89, 28), "smell": Vector2(91, 45),
	"commands": Vector2(82, 58), "body": Vector2(88, 76), "eyes": Vector2(135, 4)}
## The signals' path, eye to brain to neck to body (drawing space)
const PATH_L := [Vector2(21, 34), Vector2(56, 36), Vector2(73, 60), Vector2(73, 82), Vector2(73, 112)]
const PATH_R := [Vector2(125, 34), Vector2(90, 36), Vector2(73, 60), Vector2(73, 82), Vector2(73, 112)]

var has_map := false
var regions := {}
var drinks := 0
var neurons := 0
var kind := ""
var gaba_pct := 0
var excite_pct := 0
var quiz: Dictionary = {}
var _t := 0.0
var _flow := 0.0


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
	# the signals run faster the busier his eyes and flight orders are
	var drive := clampf(maxf(_v(regions, "eyes"), 0.0) * 0.8 + maxf(_v(regions, "commands"), 0.0) * 1.2, 0.0, 1.5)
	_flow += delta * (0.12 + 0.55 * drive)
	if visible:
		queue_redraw()


## A region's value; "eyes" and "body" fall back to their parts for older servers.
static func _v(values: Dictionary, key: String) -> float:
	if values.has(key):
		return float(values[key])
	if key == "eyes":
		return (float(values.get("eye_L", 0.0)) + float(values.get("eye_R", 0.0))) * 0.5
	if key == "body":
		return (float(values.get("cord", 0.0)) + float(values.get("muscles", 0.0))) * 0.5
	return 0.0


## Region colour for a log2 ratio: blue when sluggish, parchment at rest, glowing yellow then orange when busy.
static func heat(v: float) -> Color:
	var x := clampf(v, -1.6, 1.6)
	if x >= 0.0:
		if x < 0.5:
			return Pal.PARCHMENT_DARK.lerp(Pal.FLAME, x / 0.5)
		return Pal.FLAME.lerp(Pal.FLAME_OUT, minf(1.0, (x - 0.5) / 0.9))
	return Pal.PARCHMENT_DARK.lerp(Pal.ROYAL_LIGHT, minf(1.0, -x / 1.0))


func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	HudDraw.panel(self, Rect2i(0, 0, w, h))
	var bold := PixelFonts.bold()
	var label := PixelFonts.label()
	# a royal header band: what this is
	draw_rect(Rect2(3, 3, w - 6, 15), Pal.ROYAL)
	draw_rect(Rect2(3, 18, w - 6, 1), Pal.INK)
	HudDraw.text(self, bold, 7, 7, "HAMLET'S BRAIN", Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
	if not has_map:
		HudDraw.text(self, label, 6, 30, "NO BRAIN DATA:", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.text(self, label, 6, 40, "PLACEHOLDER MODE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		return
	var live_on := int(_t * 2.0) % 2 == 0
	draw_rect(Rect2(w - 36, 8, 5, 5), Pal.CRIMSON_LIGHT if live_on else Pal.CRIMSON_DARK)
	HudDraw.text_right(self, bold, w - 7, 7, "LIVE", Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)

	var shown := regions
	var focus: Array = []
	var flip_after := false
	if quiz_mode():
		focus = quiz.get("focus", [])
		flip_after = int(_t / FLIP_S) % 2 == 1
		shown = quiz.get("to", {}) if flip_after else quiz.get("from", {})
		HudDraw.text_center(self, bold, w / 2, 23, "WHAT ALCOHOL DOES", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
		HudDraw.text_center(self, label, w / 2, 31, "TO HIS BRAIN (IN OUR MODEL)", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	else:
		_draw_status(bold, w)
	_draw_map(shown, focus, not quiz_mode())
	if quiz_mode():
		_draw_flip_tag(flip_after)
		_draw_quiz(bold, label, w)
	else:
		_draw_footer(bold, label, w)


## One line, in words, about what his brain is doing now (read from the values; nothing made up).
func _draw_status(bold: Font, w: int) -> void:
	var best := ""
	var best_v := 0.0
	for key in ["eyes", "commands", "body", "memory", "balance", "smell"]:
		var v := _v(regions, key)
		if absf(v) > absf(best_v):
			best_v = v
			best = key
	var s := "FLY, AND WATCH IT LIGHT UP"
	var col := Pal.INK_SOFT
	if best != "" and absf(best_v) >= 0.25:
		s = str(BUSY[best]) if best_v > 0.0 else str(SLOW[best])
		col = Pal.GOLD_DARK if best_v > 0.0 else Pal.ROYAL
	HudDraw.text_center(self, bold, w / 2, 23, s, col, PixelFonts.LABEL_SIZE)
	var sub := ("%s REAL NEURONS" % _thousands(neurons)) if neurons > 0 else "REAL NEURONS"
	if kind == "changeling":
		sub = "CHANGELING: SCRAMBLED WIRING"
	HudDraw.text_center(self, PixelFonts.label(), w / 2, 31, sub, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _draw_map(values: Dictionary, focus: Array, flowing: bool) -> void:
	var ox := 4
	var oy := MAP_Y
	var pulse := int(_t * 3.0) % 2 == 0
	var halo_on := int(_t * 4.0) % 2 == 0
	# glow first, under the shapes: busy regions get a warm halo
	for s in SHAPES:
		var region: String = s[0]
		if region == "" or s[1] != "e":
			continue
		var v := _v(values, region)
		if v >= 0.3:
			var grow := 3 if halo_on and v >= 0.6 else 2
			_ellipse(Vector2(ox + int(s[2]), oy + int(s[3])), int(s[4]) + grow, int(s[5]) + grow, Pal.GOLD_LIGHT, Pal.GOLD_LIGHT, false)
	for s in SHAPES:
		var region: String = s[0]
		var fill := Pal.PARCHMENT_SHADE if region == "" else heat(_v(values, region))
		var key := "eyes" if region.begins_with("eye_") else region
		var thick := key in focus
		var outline := (Pal.CRIMSON if pulse else Pal.CRIMSON_LIGHT) if thick else Pal.INK
		if s[1] == "e":
			_ellipse(Vector2(ox + int(s[2]), oy + int(s[3])), int(s[4]), int(s[5]), fill, outline, thick)
		else:
			var r := Rect2(ox + int(s[2]), oy + int(s[3]), int(s[4]), int(s[5]))
			draw_rect(r.grow(1), outline, true)
			draw_rect(r, fill)
	# compound-eye facets, so the eyes read as eyes
	for c in [Vector2(21, 34), Vector2(125, 34)]:
		for row in range(-3, 4):
			for col in range(-2, 3):
				var p: Vector2 = c + Vector2(col * 7 + (3 if row % 2 != 0 else 0), row * 7)
				if pow((p.x - c.x) / 15.0, 2) + pow((p.y - c.y) / 24.0, 2) < 1.0:
					draw_rect(Rect2(ox + p.x, oy + p.y, 1, 1), Color(Pal.INK, 0.35))
	# signals running from the eyes to the wings and legs while he flies
	if flowing:
		var n := 3 + int(clampf(_v(values, "eyes") + _v(values, "commands"), 0.0, 1.5) * 3.0)
		for path in [PATH_L, PATH_R]:
			for k in n:
				var p := _along(path, fposmod(_flow + float(k) / n, 1.0))
				draw_rect(Rect2(ox + p.x - 1, oy + p.y - 1, 3, 3), Pal.INK)
				draw_rect(Rect2(ox + p.x, oy + p.y, 1, 1), Pal.GOLD_LIGHT)
	# sluggish regions doze
	for key in DOZE_AT:
		if _v(values, key) <= -0.35:
			var at: Vector2 = DOZE_AT[key]
			var bob := roundf(sin(_t * 2.5 + at.x) * 1.5)
			HudDraw.text(self, PixelFonts.bold(), ox + int(at.x), oy + int(at.y + bob), "z", Pal.ROYAL, PixelFonts.LABEL_SIZE)
			HudDraw.text(self, PixelFonts.label(), ox + int(at.x) + 5, oy + int(at.y + bob) - 5, "z", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	# names: tags on the eyes and memory, side labels with a pointer line for the rest
	HudDraw.tag_below(self, Vector2i(ox + 21, oy + 61), "EYES", Pal.CRIMSON if "eyes" in focus else Pal.INK)
	HudDraw.tag_below(self, Vector2i(ox + 125, oy + 61), "EYES", Pal.CRIMSON if "eyes" in focus else Pal.INK)
	HudDraw.tag(self, Vector2i(ox + 73, oy + 14), "MEMORY", Pal.CRIMSON if "memory" in focus else Pal.INK)
	var bold := PixelFonts.bold()
	for l in LABELS:
		var key: String = l[0]
		var col := Pal.CRIMSON if key in focus else Pal.INK
		var lines: Array = l[1]
		var x: int = ox + int(l[2])
		var y: int = oy + int(l[3])
		var right: bool = int(l[4]) == -1
		var lx := x + 2 if right else x - 2
		var tip := Vector2(ox + int(l[5]), oy + int(l[6]))
		draw_line(Vector2(lx, y + 3) + Vector2(0.5, 0.5), tip + Vector2(0.5, 0.5), Pal.CRIMSON if key in focus else Pal.INK_SOFT, -1.0)
		draw_rect(Rect2(tip.x - 1, tip.y - 1, 3, 3), col)
		for i in lines.size():
			if right:
				HudDraw.text_right(self, bold, x, y + i * 9, str(lines[i]), col, PixelFonts.LABEL_SIZE)
			else:
				HudDraw.text(self, bold, x, y + i * 9, str(lines[i]), col, PixelFonts.LABEL_SIZE)


func _along(path: Array, f: float) -> Vector2:
	var total := 0.0
	for i in path.size() - 1:
		total += (path[i + 1] as Vector2).distance_to(path[i])
	var d := f * total
	for i in path.size() - 1:
		var seg := (path[i + 1] as Vector2).distance_to(path[i])
		if d <= seg:
			return (path[i] as Vector2).lerp(path[i + 1], d / maxf(seg, 0.001)).round()
		d -= seg
	return path[path.size() - 1]


func _ellipse(c: Vector2, rx: int, ry: int, fill: Color, outline: Color, thick: bool) -> void:
	var pts := PackedVector2Array()
	var n := 32
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(roundf(c.x + rx * cos(a)), roundf(c.y + ry * sin(a))))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, outline, 2.0 if thick else 1.0)


func _draw_footer(bold: Font, label: Font, w: int) -> void:
	var y := MAP_Y + 124
	draw_rect(Rect2(4, y, w - 8, 1), Pal.PARCHMENT_SHADE)
	# the key, as a strip from dozy to busy
	y += 4
	for i in 7:
		draw_rect(Rect2(8 + i * 10, y, 10, 7), heat(-1.2 + i * 0.4))
	draw_rect(Rect2(7, y - 1, 72, 9), Pal.INK, false, 1.0)
	HudDraw.text(self, label, 83, y, "DOZY", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	HudDraw.text_right(self, bold, w - 6, y, "BUSY", Pal.FLAME_OUT, PixelFonts.LABEL_SIZE)
	# cordials drunk: goblets, filled purple
	y += 13
	HudDraw.text(self, bold, 6, y, "CORDIALS DRUNK", Pal.INK, PixelFonts.LABEL_SIZE)
	for i in 3:
		_goblet(Vector2i(w - 40 + i * 12, y - 1), i < drinks)
	# the one line a first-time player needs about the quiz
	y += 12
	HudDraw.text_center(self, label, w / 2, y, "WRONG ANSWER = 1 CORDIAL", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _goblet(at: Vector2i, full: bool) -> void:
	# a tiny cup: bowl, stem, foot
	draw_rect(Rect2(at.x, at.y, 9, 5), Pal.INK)
	draw_rect(Rect2(at.x + 1, at.y, 7, 4), Pal.GRAPE if full else Pal.PARCHMENT)
	draw_rect(Rect2(at.x + 4, at.y + 5, 1, 3), Pal.INK)
	draw_rect(Rect2(at.x + 2, at.y + 8, 5, 1), Pal.INK)


func _draw_flip_tag(after: bool) -> void:
	var before_n := int(quiz.get("before", 0))
	var after_n := int(quiz.get("after", 0))
	var n := after_n if after else before_n
	var s := "SOBER" if n == 0 else ("AFTER %d CORDIAL%s" % [n, "" if n == 1 else "S"])
	var f := PixelFonts.bold()
	var tw := PixelFonts.width(f, s, PixelFonts.LABEL_SIZE) + 10
	var r := Rect2i(int(size.x) / 2 - tw / 2, MAP_Y + 123, tw, 12)
	HudDraw.panel(self, r, Pal.CRIMSON if after and n > 0 else Pal.ROYAL, Pal.INK, Color(0, 0, 0, 0), Pal.ROYAL_DARK)
	HudDraw.text(self, f, r.position.x + 5, r.position.y + 2, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)


func _draw_quiz(bold: Font, label: Font, w: int) -> void:
	var y := MAP_Y + 139
	draw_rect(Rect2(4, y, w - 8, 1), Pal.PARCHMENT_SHADE)
	y += 4
	var status := str(quiz.get("status", "offer"))
	var head: String = {"offer": "IF WRONG, 1 CORDIAL:", "drunk": "HE DRANK 1 CORDIAL:", "avoided": "PEAR NECTAR SAVED:"}.get(status, "")
	if bool(quiz.get("maxed", false)):
		head = "ALREADY AT THE LIMIT (3)"
	HudDraw.text(self, bold, 6, y, head, Pal.CRIMSON if status != "avoided" else Pal.ROYAL, PixelFonts.LABEL_SIZE)
	y += 13
	var pct: Dictionary = quiz.get("pct", {})
	var from: Dictionary = quiz.get("from", {})
	var to: Dictionary = quiz.get("to", {})
	for key in quiz.get("focus", []):
		var p := int(pct.get(key, 0))
		HudDraw.text(self, bold, 6, y, str(NAMES.get(key, str(key).to_upper())), Pal.INK, PixelFonts.LABEL_SIZE)
		var ps := ("%+d%%" % p) if p != 0 else "0%"
		HudDraw.text_right(self, PixelFonts.caption(), w - 6, y - 3, ps, Pal.CRIMSON if p < 0 else Pal.ROYAL, PixelFonts.CAPTION_SIZE)
		# before / after bars, on the map's scale
		var b := clampf((_v(from, key) + 1.6) / 3.2, 0.0, 1.0)
		var a := clampf((_v(to, key) + 1.6) / 3.2, 0.0, 1.0)
		HudDraw.bar(self, Rect2i(6, y + 9, 90, 5), b, Pal.ROYAL)
		HudDraw.bar(self, Rect2i(6, y + 14, 90, 5), a, Pal.CRIMSON)
		y += 23
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
