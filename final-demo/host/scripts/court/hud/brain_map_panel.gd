extends Control

## Hamlet's brain map, the main screen's top-right corner (it replaced the Seer panel). Drawn from the server's `brainMap`
## (brain/brain_map.py): a second copy of the whole-CNS model driven only by Hamlet's movement, never by the Princess or
## the Giant, so it's safe on the shared screen in every phase.
##
## Kept simple on purpose, so a first-time player gets it at a glance: a small picture of his brain with four parts
## (eyes, memory, balance, body), and under it one big row per part saying in words how it's doing (BUSY, NORMAL, SLOW)
## in the colour it has in the picture. Only the story's drink questions change it: the parts the question is about are
## ringed, and each shows, big, how much one grape cordial changes it in the model.
## Words come from each part's log2(mean rate / sober rest); every number comes from the server; the alcohol effect is a
## disclosed model assumption (the Royal Decree).

const PLAY_RECT := Rect2i(482, 27, 154, 216)
const QUIZ_RECT := Rect2i(482, 28, 154, 306)
const PARTS := [["eyes", "Eyes"], ["memory", "Memory"], ["balance", "Balance"], ["body", "Body"]]
const ROW_Y := 94          # first row, in both modes
const ROW_H := 19

var has_map := false
var regions := {}
var drinks := 0
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
	if visible and quiz_mode():
		queue_redraw()  # the ringed parts pulse


## A part's value; "eyes" and "body" fall back to their pieces for older servers.
static func _v(values: Dictionary, key: String) -> float:
	if values.has(key):
		return float(values[key])
	if key == "eyes":
		return (float(values.get("eye_L", 0.0)) + float(values.get("eye_R", 0.0))) * 0.5
	if key == "body":
		return (float(values.get("cord", 0.0)) + float(values.get("muscles", 0.0))) * 0.5
	return 0.0


## Busier is warmer (gold, then orange), quieter is bluer; normal is plain parchment.
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


static func word_color(v: float) -> Color:
	if v >= 0.2:
		return Pal.FLAME_OUT
	if v <= -0.2:
		return Pal.ROYAL
	return Pal.INK_SOFT


func _draw() -> void:
	var w := int(size.x)
	HudDraw.panel(self, Rect2i(0, 0, w, int(size.y)))
	draw_rect(Rect2(3, 3, w - 6, 15), Pal.ROYAL)
	draw_rect(Rect2(3, 18, w - 6, 1), Pal.INK)
	HudDraw.text(self, PixelFonts.bold(), 7, 7, "HAMLET'S BRAIN", Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
	if not has_map:
		HudDraw.text(self, PixelFonts.caption(), 8, 28, "Not loaded", Pal.INK_SOFT, PixelFonts.CAPTION_SIZE)
		return
	HudDraw.text_right(self, PixelFonts.bold(), w - 7, 7, "SCRAMBLED" if kind == "changeling" else "LIVE", Pal.GOLD_LIGHT,
		PixelFonts.LABEL_SIZE)
	if quiz_mode():
		_draw_quiz(w)
	else:
		_picture(regions, [])
		_rows(w)
		_footer(w)


## The picture: two eyes, the brain (memory on top, balance below) and the nerve cord to his body.
func _picture(values: Dictionary, ring: Array) -> void:
	var pulse := int(_t * 3.0) % 2 == 0
	var ring_col := Pal.CRIMSON if pulse else Pal.CRIMSON_LIGHT
	for cx in [27, 127]:
		_ellipse(Vector2(cx, 48), 17, 22, heat(_v(values, "eyes")), ring_col if "eyes" in ring else Pal.INK, "eyes" in ring)
	_ellipse(Vector2(77, 48), 33, 24, Pal.PARCHMENT_SHADE, Pal.INK, false)
	_ellipse(Vector2(77, 39), 24, 10, heat(_v(values, "memory")), ring_col if "memory" in ring else Pal.INK, "memory" in ring)
	_ellipse(Vector2(77, 58), 22, 7, heat(_v(values, "balance")), ring_col if "balance" in ring else Pal.INK, "balance" in ring)
	var body := heat(_v(values, "body"))
	draw_rect(Rect2(73, 71, 9, 5), Pal.INK)
	draw_rect(Rect2(74, 71, 7, 5), body)
	_ellipse(Vector2(77, 82), 8, 8, body, ring_col if "body" in ring else Pal.INK, "body" in ring)


## One big row per part: its colour, its name, and in a word how it's doing.
func _rows(w: int) -> void:
	for i in PARTS.size():
		var key: String = PARTS[i][0]
		var v := _v(regions, key)
		var y := ROW_Y + i * ROW_H
		draw_rect(Rect2(7, y + 3, 10, 10), Pal.INK)
		draw_rect(Rect2(8, y + 4, 8, 8), heat(v))
		HudDraw.text(self, PixelFonts.caption(), 22, y, PARTS[i][1], Pal.INK, PixelFonts.CAPTION_SIZE)
		HudDraw.text_right(self, PixelFonts.bold(), w - 7, y + 4, word(v), word_color(v), PixelFonts.LABEL_SIZE)


func _footer(w: int) -> void:
	var y := ROW_Y + PARTS.size() * ROW_H + 3
	draw_rect(Rect2(4, y, w - 8, 1), Pal.PARCHMENT_SHADE)
	y += 5
	HudDraw.text(self, PixelFonts.caption(), 8, y - 2, "Cordials", Pal.INK, PixelFonts.CAPTION_SIZE)
	for i in 3:
		_goblet(Vector2i(w - 44 + i * 13, y + 2), i < drinks)
	HudDraw.text_center(self, PixelFonts.bold(), w / 2, y + 17, "B: SEE THE FULL BRAIN", Pal.ROYAL, PixelFonts.LABEL_SIZE)


func _draw_quiz(w: int) -> void:
	var focus: Array = quiz.get("focus", [])
	_picture(quiz.get("to", {}), focus)
	var status := str(quiz.get("status", "offer"))
	var y := ROW_Y
	var head: String = {"offer": "If the answer", "drunk": "He drank one", "avoided": "Pear nectar!"}.get(status, "")
	var head2: String = {"offer": "is wrong:", "drunk": "cordial:", "avoided": "It spared him:"}.get(status, "")
	if bool(quiz.get("maxed", false)):
		head = "Already at"
		head2 = "the limit (3):"
	var hc := Pal.CRIMSON if status != "avoided" else Pal.ROYAL
	HudDraw.text(self, PixelFonts.caption(), 8, y, head, hc, PixelFonts.CAPTION_SIZE)
	HudDraw.text(self, PixelFonts.caption(), 8, y + 16, head2, hc, PixelFonts.CAPTION_SIZE)
	y += 40
	var pct: Dictionary = quiz.get("pct", {})
	for p in PARTS:
		if not p[0] in focus:
			continue
		var n := int(pct.get(p[0], 0))
		HudDraw.text(self, PixelFonts.caption(), 8, y, p[1], Pal.INK, PixelFonts.CAPTION_SIZE)
		HudDraw.text_right(self, PixelFonts.caption(), w - 8, y, ("%+d%%" % n) if n != 0 else "0%",
			Pal.CRIMSON if n < 0 else Pal.ROYAL, PixelFonts.CAPTION_SIZE)
		HudDraw.text(self, PixelFonts.bold(), 8, y + 16, "SLOWER" if n < 0 else ("BUSIER" if n > 0 else "NO CHANGE"), Pal.INK_SOFT,
			PixelFonts.LABEL_SIZE)
		y += 32
	HudDraw.text_center(self, PixelFonts.bold(), w / 2, int(size.y) - 50, "B: SEE THE FULL BRAIN", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	var ly := int(size.y) - 36
	draw_rect(Rect2(4, ly - 4, w - 8, 1), Pal.PARCHMENT_SHADE)
	HudDraw.text(self, PixelFonts.label(), 8, ly, "IN OUR BRAIN MODEL, EACH", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text(self, PixelFonts.label(), 8, ly + 9, "CORDIAL = GABA +%d%%," % gaba_pct, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text(self, PixelFonts.label(), 8, ly + 18, "EXCITATION -%d%%" % excite_pct, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _goblet(at: Vector2i, full: bool) -> void:
	draw_rect(Rect2(at.x, at.y, 10, 6), Pal.INK)
	draw_rect(Rect2(at.x + 1, at.y, 8, 5), Pal.GRAPE if full else Pal.PARCHMENT)
	draw_rect(Rect2(at.x + 4, at.y + 6, 2, 3), Pal.INK)
	draw_rect(Rect2(at.x + 2, at.y + 9, 6, 1), Pal.INK)


func _ellipse(c: Vector2, rx: int, ry: int, fill: Color, outline: Color, thick: bool) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		pts.append(Vector2(roundf(c.x + rx * cos(a)), roundf(c.y + ry * sin(a))))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, outline, 2.0 if thick else 1.0)
