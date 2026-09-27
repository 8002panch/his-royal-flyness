class_name StoryBanner
extends Control

## The story's play HUD (server/campaign.py): the objective and its counters under the ribbon (grapes, gates and the Stage 2
## clock, dodges and hits), steadiness after a wrong answer, the READY / FLY! count-in, the end card, and a DEMO stamp after a
## chapter jump. Every number is the server's. Nothing here shows where or when an attack will come (the Seer's secret).

const Y := 30

var phase := ""
var scene := ""
var objective := ""
var counters: Dictionary = {}
var steadiness := ""
var dizzy := 0
var ready_left := -1.0
var story_demo := false
var guide: Dictionary = {}
var ending := ""
var _row := 16   # where the next row under the objective goes
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)


func apply(cs: CourtState) -> void:
	visible = cs.scene != "" and cs.scene != "LOBBY"
	phase = cs.phase
	scene = cs.scene
	objective = cs.objective
	counters = cs.counters
	steadiness = cs.steadiness
	dizzy = cs.dizzy
	ready_left = cs.ready_left
	story_demo = cs.story_demo
	guide = cs.guide
	ending = cs.ending
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if visible and phase == "ready":
		queue_redraw()


func _draw() -> void:
	if story_demo:
		HudDraw.panel(self, Rect2i(6, 66, 42, 14), Pal.CRIMSON, Pal.INK, Color(0, 0, 0, 0), Pal.CRIMSON_DARK)
		HudDraw.text_center(self, PixelFonts.bold(), 27, 69, "DEMO", Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
	if phase == "end":
		_end_card()
		return
	if phase not in ["play", "ready"] or objective == "":
		return
	var bold := PixelFonts.bold()
	var parts: Array[String] = [objective.to_upper()]
	var status := _status()
	var w := PixelFonts.width(bold, parts[0], PixelFonts.LABEL_SIZE) + 16
	var ws := PixelFonts.width(bold, status, PixelFonts.LABEL_SIZE) + 16 if status != "" else 0
	# centred, but clear of the Reliquary (left) and the brain map (right); a long objective puts its counters on a
	# second row instead of running under the brain map
	var room := 480 - 78
	var one_row := w + ws <= room
	var x := clampi(HallCam.W / 2 - ((w + ws) if one_row else w) / 2, 78, maxi(78, 480 - ((w + ws) if one_row else w)))
	HudDraw.panel(self, Rect2i(x, Y, w, 14), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text(self, bold, x + 8, Y + 3, parts[0], Pal.INK, PixelFonts.LABEL_SIZE)
	_row = 16
	if status != "":
		var sx := x + w if one_row else clampi(HallCam.W / 2 - ws / 2, 78, 480 - ws)
		var sy := Y if one_row else Y + 16
		HudDraw.panel(self, Rect2i(sx, sy, ws, 14), Pal.ROYAL, Pal.INK, Pal.GOLD, Pal.ROYAL_DARK)
		HudDraw.text(self, bold, sx + 8, sy + 3, status, Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)
		if not one_row:
			_row = 32
	if dizzy > 0:
		var s := "STEADINESS: " + steadiness.to_upper()
		var sw := PixelFonts.width(bold, s, PixelFonts.LABEL_SIZE) + 14
		HudDraw.panel(self, Rect2i(HallCam.W / 2 - sw / 2, Y + _row, sw, 13), Pal.CRIMSON, Pal.INK, Color(0, 0, 0, 0), Pal.CRIMSON_DARK)
		HudDraw.text_center(self, bold, HallCam.W / 2, Y + _row + 3, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
		_row += 15
	if not guide.is_empty():
		_guide_row(bold)
	if phase == "ready":
		var word := "READY..." if ready_left > 0.6 else "FLY!"
		HudDraw.text_center(self, PixelFonts.title(), HallCam.W / 2 + 1, 151, word, Pal.INK, PixelFonts.TITLE_SIZE * 2)
		HudDraw.text_center(self, PixelFonts.title(), HallCam.W / 2, 150, word, Pal.GOLD_LIGHT, PixelFonts.TITLE_SIZE * 2)


## The tutorial's coaching row: each mover's push towards the grape (or the chalice), a check when lined up.
func _guide_row(bold: Font) -> void:
	var goal := str(guide.get("goal", "grape")).to_upper()
	var words := {"right": "RIGHT", "left": "LEFT", "up": "CLIMB", "down": "DIVE", "forward": "FORWARD", "back": "BRAKE"}
	var parts := [["HELMSMAN", str(guide.get("x", "ok")), Pal.ROYAL], ["LIFTMASTER", str(guide.get("y", "ok")), Pal.GOLD_DARK],
		["WINGMASTER", str(guide.get("z", "ok")), Pal.CRIMSON]]
	var text := "TO THE " + goal + ":"
	var widths: Array[int] = [PixelFonts.width(bold, text, PixelFonts.LABEL_SIZE)]
	for p in parts:
		widths.append(PixelFonts.width(bold, "%s %s" % [p[0], words.get(p[1], "OK")], PixelFonts.LABEL_SIZE))
	var total := 0
	for w in widths:
		total += w + 14
	var x := clampi(HallCam.W / 2 - total / 2, 78, maxi(78, 480 - total))
	HudDraw.panel(self, Rect2i(x - 6, Y + _row, total + 4, 13), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
	HudDraw.text(self, bold, x, Y + _row + 3, text, Pal.INK, PixelFonts.LABEL_SIZE)
	x += widths[0] + 14
	for i in parts.size():
		var p: Array = parts[i]
		var ok: bool = p[1] == "ok"
		HudDraw.text(self, bold, x, Y + _row + 3, "%s %s" % [p[0], words.get(p[1], "OK")], Pal.INK_SOFT if ok else p[2], PixelFonts.LABEL_SIZE)
		x += widths[i + 1] + 14


func _status() -> String:
	var c := counters
	if c.has("grapes"):
		return "GRAPES %d/%d%s" % [int(c["grapes"]), int(c.get("grapes_total", 4)), "  CARRYING ONE" if c.get("carrying", false) else ""]
	if c.has("dodges"):
		return "DODGES %d/%d   HITS %d/%d" % [int(c["dodges"]), int(c.get("dodges_needed", 10)), int(c.get("hits", 0)),
			int(c.get("hits_allowed", 3))]
	if c.has("gates"):
		var s := "GATES %d/%d" % [int(c["gates"]), int(c.get("gates_total", 4))]
		if c.has("clock"):
			var t := int(ceil(float(c["clock"])))
			s += "   %d:%02d" % [t / 60, t % 60]
		return s
	return ""


func _end_card() -> void:
	# over the top of the last picture (hud/end_scene.gd), leaving the couple, or Miranda's walk, in view
	var r := Rect2i(170, 14, 300, 92)
	HudDraw.panel(self, r, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text_center(self, PixelFonts.title(), 320, r.position.y + 6, "The End", Pal.INK, PixelFonts.TITLE_SIZE * 2)
	LobbyOverlay._flourish(self, 320, r.position.y + 47, 110)
	var line := "MIRANDA CHOOSES HER OWN PATH" if ending == "own_path" else "HAMLET AND MIRANDA, HAPPILY WED"
	HudDraw.text_center(self, PixelFonts.bold(), 320, r.position.y + 55, line, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(self, PixelFonts.label(), 320, r.position.y + 67, "THANK YOU FOR PLAYING", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(self, PixelFonts.label(), 320, r.position.y + 79, "F6: THE ROYAL DECREE   ENTER: A NEW STORY", Pal.INK_SOFT,
		PixelFonts.LABEL_SIZE)
