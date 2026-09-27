class_name SeerPanel
extends Control

## The Royal Seer's panel. Seer cues are private (docs/WEBAPP_ARCHITECTURE.md:
## only the Seer's phone gets Princess bearing),
## so this shared screen shows only:
##   - scanning / resting (the compass sweeps while scanning; it never points at anything)
##   - four brain-activity rows (vision, flight, reaction, song), magnitude only,
##     so no bar can give away a side. Empty until a server sends `activity`.

const GROUPS := [["vision", "VISION"], ["flight", "FLIGHT"], ["reaction", "REACT"], ["song", "SONG"]]
const PANEL := Vector2i(104, 122)

var scanning := false
var levels := {}
var has_activity := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(PANEL)


func apply(cs: CourtState) -> void:
	scanning = cs.seer_scanning
	has_activity = cs.has_activity()
	for g in GROUPS:
		levels[g[0]] = cs.activity_level(g[0])
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if scanning:
		queue_redraw()


func _draw() -> void:
	var w := PANEL.x
	HudDraw.panel(self, Rect2i(0, 0, w, PANEL.y))
	var bold := PixelFonts.bold()
	var label := PixelFonts.label()
	HudDraw.text_center(self, bold, w / 2, 5, "ROYAL SEER", Pal.ROYAL, PixelFonts.LABEL_SIZE)

	# compass: sweeps while scanning, rests pointing up otherwise
	var cs := 26
	HudDraw.tex(self, SpriteForge.compass_rose(cs), Vector2i(5, 15))
	var step := int(_t * 10.0) % 8 if scanning else 0
	HudDraw.tex(self, SpriteForge.needle(cs, step, scanning), Vector2i(5, 15))
	HudDraw.text(self, bold, 36, 18, "SCANNING" if scanning else "RESTING", Pal.ROYAL if scanning else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.tex(self, SpriteForge.lock_icon(), Vector2i(36, 30))
	HudDraw.text(self, label, 44, 31, "PRIVATE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	draw_rect(Rect2(4, 45, w - 8, 1), Pal.PARCHMENT_SHADE)

	draw_rect(Rect2(4, 49, w - 8, 1), Pal.PARCHMENT_SHADE)
	HudDraw.text(self, label, 6, 54, "FLY BRAIN", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	var y := 67
	for g in GROUPS:
		var key: String = g[0]
		var lvl: float = levels.get(key, -1.0)
		HudDraw.tex(self, SpriteForge.activity_icon(key), Vector2i(5, y))
		HudDraw.text(self, label, 16, y, g[1], Pal.INK if lvl >= 0.0 else Pal.PARCHMENT_SHADE, PixelFonts.LABEL_SIZE)
		HudDraw.bar(self, Rect2i(56, y + 1, 42, 6), maxf(lvl, 0.0), Pal.ROYAL if key != "reaction" else Pal.CRIMSON)
		y += 10
