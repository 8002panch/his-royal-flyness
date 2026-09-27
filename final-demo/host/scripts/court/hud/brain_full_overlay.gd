extends Control

## Hamlet's brain, full size (B on the main screen opens and closes it; it pauses auto play while open). The detailed map:
## twelve groups of his real neurons from the server's `brainMap` (brain/brain_map.py), drawn twice as large as the corner
## panel's picture, with the part of each one's job in him and the part of a human brain that does the same job.
## In a drink question it explains the question instead: the fact, the part of Hamlet's brain it concerns, the part of yours
## that does that job, and what one grape cordial does to that part in our model (QUIZZES["brain"] in server/campaign.py).
## The map flips between the brain before and after that cordial. Every number comes from the server.

const PANEL := Rect2i(6, 26, 628, 290)
const MAP_AT := Vector2(22, 66)     # the map's top-left
const SCALE := 1.8                  # the map's shapes are drawn this much larger; its labels stay at the normal size
const TEXT_X := 322
const TEXT_W := 300
const FLIP_S := 1.8

## The detailed map in its own 146 x 122 space: [region, kind, a, b, c, d], "e" ellipse (cx, cy, rx, ry), "r" rect.
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
## [region, text, x, y, align (-1 right-aligned at x, 0 centred, 1 left-aligned), leader target x, y]
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
## The legend: what each part is in him, and the part of a human brain that does that job.
const ROWS := [
	["eyes", "EYES", "OPTIC LOBES", "VISUAL CORTEX"],
	["memory", "MEMORY", "MUSHROOM BODIES", "HIPPOCAMPUS"],
	["balance", "BALANCE", "CENTRAL COMPLEX", "CEREBELLUM"],
	["smell", "SMELL", "ANTENNAL LOBES", "OLFACTORY BULB"],
	["commands", "COMMANDS", "DESCENDING NEURONS", "BRAINSTEM PATHWAYS"],
	["body", "BODY", "NERVE CORD, MOTOR NEURONS", "SPINAL CORD"],
	["escape", "ESCAPE", "GIANT FIBER (DNp01)", "STARTLE REFLEX"],
]

var open := false
var has_map := false
var regions := {}
var sizes := {}
var neurons := 0
var drinks := 0
var quiz: Dictionary = {}
var question: Dictionary = {}
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	visible = false


func toggle() -> void:
	open = not open
	visible = open and has_map


func apply(cs: CourtState) -> void:
	var bm: Variant = cs.raw.get("brainMap", null)
	has_map = bm is Dictionary
	quiz = {}
	question = cs.question
	if has_map:
		regions = bm.get("regions", {})
		sizes = bm.get("sizes", {})
		neurons = int(bm.get("neurons", 0))
		drinks = int(bm.get("drinks", 0))
		if bm.get("quiz") is Dictionary and cs.phase in ["comic", "question"]:
			quiz = bm["quiz"]
	visible = open and has_map
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


static func _v(values: Dictionary, key: String) -> float:
	if values.has(key):
		return float(values[key])
	if key == "eyes":
		return (float(values.get("eye_L", 0.0)) + float(values.get("eye_R", 0.0))) * 0.5
	if key == "body":
		return (float(values.get("cord", 0.0)) + float(values.get("muscles", 0.0))) * 0.5
	return 0.0


static func heat(v: float) -> Color:
	var x := clampf(v, -1.2, 1.2)
	if x >= 0.4:
		return Pal.FLAME.lerp(Pal.FLAME_OUT, (x - 0.4) / 0.8)
	if x >= 0.0:
		return Pal.PARCHMENT_DARK.lerp(Pal.FLAME, x / 0.4)
	return Pal.PARCHMENT_DARK.lerp(Pal.ROYAL_LIGHT, -x / 1.2)


static func word(v: float) -> String:
	if v >= 0.6:
		return "VERY BUSY"
	if v >= 0.2:
		return "BUSY"
	if v <= -0.6:
		return "VERY SLOW"
	if v <= -0.2:
		return "SLOW"
	return "NORMAL"


func _draw() -> void:
	var dim := Color(Pal.INK, 0.75)
	draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), dim)
	HudDraw.panel(self, PANEL, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text(self, PixelFonts.title(), PANEL.position.x + 12, PANEL.position.y + 6, "Inside Hamlet's Brain", Pal.ROYAL,
		PixelFonts.TITLE_SIZE)
	var sub := "LIVE: ALL %s NEURONS OF A REAL MALE FRUIT FLY" % _thousands(neurons)
	HudDraw.text(self, PixelFonts.bold(), PANEL.position.x + 12, PANEL.position.y + 28, sub, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_right(self, PixelFonts.bold(), PANEL.position.x + PANEL.size.x - 12, PANEL.position.y + 8, "B: CLOSE", Pal.INK_SOFT,
		PixelFonts.LABEL_SIZE)
	draw_rect(Rect2(TEXT_X - 8, PANEL.position.y + 40, 1, PANEL.size.y - 50), Pal.PARCHMENT_SHADE)

	var focus: Array = []
	var values := regions
	var after := false
	if not quiz.is_empty():
		focus = quiz.get("focus", [])
		after = int(_t / FLIP_S) % 2 == 1
		values = quiz.get("to", {}) if after else quiz.get("from", {})
	_map(values, focus)
	if not quiz.is_empty():
		_flip_tag(after)
		_explain()
	else:
		_legend()


## The map, enlarged: every shape, then a label and a pointer for each of the twelve groups.
func _map(values: Dictionary, focus: Array) -> void:
	draw_set_transform(MAP_AT, 0.0, Vector2(SCALE, SCALE))
	var pulse := int(_t * 3.0) % 2 == 0
	var body_focus := "body" in focus
	for s in SHAPES:
		var region: String = s[0]
		var fill := Pal.PARCHMENT_SHADE if region == "" else heat(_v(values, region))
		var key := region
		if region.begins_with("eye_"):
			key = "eyes"
		elif region in ["cord", "muscles"] and body_focus:
			key = "body"
		var ring := key in focus
		var outline := (Pal.CRIMSON if pulse else Pal.CRIMSON_LIGHT) if ring else Pal.INK
		if s[1] == "e":
			var pts := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32
				pts.append(Vector2(roundf(float(s[2]) + float(s[4]) * cos(a)), roundf(float(s[3]) + float(s[5]) * sin(a))))
			draw_colored_polygon(pts, fill)
			pts.append(pts[0])
			draw_polyline(pts, outline, 1.5 if ring else 0.5)
		else:
			var r := Rect2(int(s[2]), int(s[3]), int(s[4]), int(s[5]))
			draw_rect(r.grow(0.5), outline, true)
			draw_rect(r, fill)
	var esc := heat(_v(values, "escape"))
	for fx in [70, 76]:
		draw_rect(Rect2(fx, 38, 1, 44), esc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for l in LABELS:
		var key: String = l[0]
		var fkey := "eyes" if key.begins_with("eye_") else ("body" if key in ["cord", "muscles"] and body_focus else key)
		var col := Pal.CRIMSON if fkey in focus else Pal.INK
		var x := roundi(MAP_AT.x + float(l[2]) * SCALE)
		var y := roundi(MAP_AT.y + float(l[3]) * SCALE)
		var tip := (MAP_AT + Vector2(float(l[5]), float(l[6])) * SCALE).round()
		if int(l[4]) != 0:
			var lx := x + 3 if int(l[4]) == -1 else x - 3
			draw_line(Vector2(lx, y + 4) + Vector2(0.5, 0.5), tip + Vector2(0.5, 0.5), Pal.INK_SOFT if col == Pal.INK else col, -1.0)
			draw_rect(Rect2(tip.x - 1, tip.y - 1, 3, 3), col)
		match int(l[4]):
			-1:
				HudDraw.text_right(self, PixelFonts.bold(), x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)
			0:
				HudDraw.text_center(self, PixelFonts.bold(), x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)
			_:
				HudDraw.text(self, PixelFonts.bold(), x, y, str(l[1]), col, PixelFonts.LABEL_SIZE)



func _flip_tag(after: bool) -> void:
	var n := int(quiz.get("after", 0)) if after else int(quiz.get("before", 0))
	var s := "SOBER" if n == 0 else ("AFTER %d CORDIAL%s" % [n, "" if n == 1 else "S"])
	var tw := PixelFonts.width(PixelFonts.bold(), s, PixelFonts.LABEL_SIZE) + 10
	var r := Rect2i(PANEL.position.x + 12, PANEL.position.y + PANEL.size.y - 20, tw, 12)
	HudDraw.panel(self, r, Pal.CRIMSON if after and n > 0 else Pal.ROYAL, Pal.INK, Color(0, 0, 0, 0), Pal.ROYAL_DARK)
	HudDraw.text(self, PixelFonts.bold(), r.position.x + 5, r.position.y + 2, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)


## Outside the questions: each part, what it is in him, and what does the same job in you.
func _legend() -> void:
	var y := PANEL.position.y + 44
	HudDraw.text(self, PixelFonts.bold(), TEXT_X, y, "EACH PART: IN HIM, AND IN YOU", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	y += 14
	for row in ROWS:
		var key: String = row[0]
		var v := _v(regions, key)
		draw_rect(Rect2(TEXT_X, y + 1, 8, 8), Pal.INK)
		draw_rect(Rect2(TEXT_X + 1, y + 2, 6, 6), heat(v))
		HudDraw.text(self, PixelFonts.bold(), TEXT_X + 13, y + 1, row[1], Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text_right(self, PixelFonts.bold(), TEXT_X + TEXT_W, y + 1, word(v), Pal.FLAME_OUT if v >= 0.2 else (Pal.ROYAL if v <= -0.2 else Pal.INK_SOFT),
			PixelFonts.LABEL_SIZE)
		var n := int(sizes.get(key, 0))
		var him := "HIM: %s" % row[2] + ("  (%s NEURONS)" % _thousands(n) if n > 0 else "")
		HudDraw.text(self, PixelFonts.label(), TEXT_X + 13, y + 11, him, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.text(self, PixelFonts.label(), TEXT_X + 13, y + 20, "YOU: " + str(row[3]), Pal.ROYAL, PixelFonts.LABEL_SIZE)
		y += 32


## In a drink question: the fact, then the part of his brain and the part of yours, then what one cordial does to it.
func _explain() -> void:
	var b: Dictionary = quiz.get("brain", {})
	var part := str(b.get("part", ""))
	var x := TEXT_X
	var y := PANEL.position.y + 44
	HudDraw.text(self, PixelFonts.bold(), x, y, "THIS QUESTION, IN HIS BRAIN AND YOURS", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	y += 13
	y = _wrap(str(b.get("fact", "")), x, y, TEXT_W, PixelFonts.caption(), PixelFonts.CAPTION_SIZE, 16, Pal.INK) + 6
	HudDraw.text(self, PixelFonts.bold(), x, y, "IN HAMLET", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	var n := int(sizes.get(part, 0))
	if n > 0:
		HudDraw.text_right(self, PixelFonts.label(), x + TEXT_W, y, "%s OF HIS NEURONS" % _thousands(n), Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	y = _wrap(str(b.get("fly", "")), x, y + 10, TEXT_W, PixelFonts.label(), PixelFonts.LABEL_SIZE, 9, Pal.INK) + 6
	HudDraw.text(self, PixelFonts.bold(), x, y, "IN YOU", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	y = _wrap(str(b.get("human", "")), x, y + 10, TEXT_W, PixelFonts.caption(), PixelFonts.CAPTION_SIZE, 16, Pal.ROYAL_DARK) + 6
	var pct: Dictionary = quiz.get("pct", {})
	var p := int(pct.get(part, 0))
	var name: String = {"eyes": "HIS EYES", "memory": "HIS MEMORY", "balance": "HIS BALANCE", "body": "HIS BODY"}.get(part, part.to_upper())
	HudDraw.text(self, PixelFonts.bold(), x, y, "OUR MODEL: ONE CORDIAL", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text_right(self, PixelFonts.caption(), x + TEXT_W, y - 4, "%s %+d%%" % [name, p], Pal.CRIMSON, PixelFonts.CAPTION_SIZE)
	_wrap("SOURCE: " + str(b.get("source", "")).to_upper(), x, PANEL.position.y + PANEL.size.y - 22, TEXT_W, PixelFonts.label(),
		PixelFonts.LABEL_SIZE, 9, Pal.INK_SOFT)


func _wrap(text: String, x: int, top: int, width: int, font: Font, fsize: int, step: int, col: Color) -> int:
	var lines: Array[String] = []
	var line := ""
	for w in text.split(" "):
		var next := w if line == "" else line + " " + w
		if line != "" and PixelFonts.width(font, next, fsize) > width:
			lines.append(line)
			line = w
		else:
			line = next
	if line != "":
		lines.append(line)
	for i in lines.size():
		HudDraw.text(self, font, x, top + i * step, lines[i], col, fsize)
	return top + lines.size() * step


static func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out
