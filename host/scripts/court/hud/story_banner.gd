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
	var x := HallCam.W / 2 - (w + ws) / 2
	HudDraw.panel(self, Rect2i(x, Y, w, 14), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text(self, bold, x + 8, Y + 3, parts[0], Pal.INK, PixelFonts.LABEL_SIZE)
	if status != "":
		HudDraw.panel(self, Rect2i(x + w, Y, ws, 14), Pal.ROYAL, Pal.INK, Pal.GOLD, Pal.ROYAL_DARK)
		HudDraw.text(self, bold, x + w + 8, Y + 3, status, Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)
	if dizzy > 0:
		var s := "STEADINESS: " + steadiness.to_upper()
		var sw := PixelFonts.width(bold, s, PixelFonts.LABEL_SIZE) + 14
		HudDraw.panel(self, Rect2i(HallCam.W / 2 - sw / 2, Y + 16, sw, 13), Pal.CRIMSON, Pal.INK, Color(0, 0, 0, 0), Pal.CRIMSON_DARK)
		HudDraw.text_center(self, bold, HallCam.W / 2, Y + 19, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
	if phase == "ready":
		var word := "READY..." if ready_left > 0.6 else "FLY!"
		HudDraw.text_center(self, PixelFonts.title(), HallCam.W / 2 + 1, 151, word, Pal.INK, PixelFonts.TITLE_SIZE * 2)
		HudDraw.text_center(self, PixelFonts.title(), HallCam.W / 2, 150, word, Pal.GOLD_LIGHT, PixelFonts.TITLE_SIZE * 2)


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
	var r := Rect2i(170, 110, 300, 120)
	HudDraw.panel(self, r, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text_center(self, PixelFonts.title(), 320, r.position.y + 14, "The End", Pal.INK, PixelFonts.TITLE_SIZE * 2)
	LobbyOverlay._flourish(self, 320, r.position.y + 58, 110)
	HudDraw.text_center(self, PixelFonts.bold(), 320, r.position.y + 72, "THANK YOU FOR PLAYING", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(self, PixelFonts.label(), 320, r.position.y + 88, "F6: THE ROYAL DECREE   ENTER: A NEW STORY", Pal.INK_SOFT,
		PixelFonts.LABEL_SIZE)
