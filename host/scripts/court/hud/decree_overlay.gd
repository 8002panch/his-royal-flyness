class_name DecreeOverlay
extends Control

## The Royal Decree, the honesty panel (docs/GAME.md, "The Royal Decree"): one key away on the main screen (F6 opens it,
## turns the page, then closes it). TEXT is README.md's canonical Decree word for word (test/decree_smoke.gd checks), and
## the footer says which brain is running right now, so a placeholder Seer is never passed off as the real wiring.

const TEXT := "Three players steer Prince Hamlet directly: left and right, up and down, forward and back. The fourth, the Royal Seer, senses the world through his real nervous system: the MaleCNS v1.0 wiring diagram of a real male fruit fly (Berg et al., Cell, 2026; CC-BY 4.0) runs live as a simple rate model, and the Seer's cues (where the Princess is, where a Giant's hand is coming from, and how soon) are read from his descending neurons. The connection counts are real. Everything else is our assumption: how strong each connection is (derived from synapse counts under one tuned gain), whether it excites or inhibits (predicted from neurotransmitters), leaving out neuromodulators and connections under 5 synapses, and how positions in the game become activity in his eyes and antennae. Real neurons have dynamics, modulation and learning that this model doesn't. Swap in the Changeling (same neurons and connection counts, scrambled partners) and the Seer goes blind. If the hybrid fallback is used, the Seer's directions come from the game and only the confidence and warnings from the brain. The Princess, the Giants and the course are scripted. The names are real fly genes; the personalities are ours."
const PANEL := Rect2i(52, 26, 536, 304)
const TEXT_W := 500
const LINE_H := 17
const LINES_PER_PAGE := 12
const RUNNING := {
	"true": ["RUNNING NOW: TRUE PRINCE, THE REAL WIRING", Pal.ROYAL],
	"changeling": ["RUNNING NOW: THE CHANGELING, SCRAMBLED PARTNERS", Pal.CRIMSON],
	"placeholder": ["RUNNING NOW: PLACEHOLDER SEER, THE BRAIN IS NOT LOADED", Pal.CRIMSON],
	"sample": ["RUNNING NOW: OFFLINE SAMPLE, NOT THE LIVE BRAIN", Pal.CRIMSON],
	"demo": ["RUNNING NOW: KEYBOARD DEMO, NO BRAIN", Pal.CRIMSON],
}

var page := 0
var brain := ""
var _pages: Array = []
var _dither: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	var c := PixelCanvas.new(2, 2)
	c.px(0, 0, Pal.INK)
	c.px(1, 1, Pal.INK)
	_dither = c.texture()
	_pages = pages()


## The text wrapped to the panel and split into pages.
static func pages() -> Array:
	var font := PixelFonts.caption()
	var lines: Array[String] = []
	var line := ""
	for word in TEXT.split(" "):
		var next := word if line == "" else line + " " + word
		if line != "" and PixelFonts.width(font, next, PixelFonts.CAPTION_SIZE) > TEXT_W:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	var out: Array = []
	for i in range(0, lines.size(), LINES_PER_PAGE):
		out.append(lines.slice(i, i + LINES_PER_PAGE))
	return out


## F6: closed -> page 1 -> ... -> closed. Returns true when it just opened.
func advance() -> bool:
	if not visible:
		page = 0
		visible = true
		queue_redraw()
		return true
	page += 1
	if page >= _pages.size():
		visible = false
	queue_redraw()
	return false


func apply(cs: CourtState) -> void:
	var now := "demo" if cs.demo else ("sample" if cs.sample else cs.brain)
	if brain != now:
		brain = now
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(_dither, Rect2(0, 0, HallCam.W, HallCam.H), true)
	LobbyOverlay._scroll(self, PANEL)
	var cx := PANEL.position.x + PANEL.size.x / 2
	HudDraw.text_center(self, PixelFonts.title(), cx, PANEL.position.y + 9, "The Royal Decree", Pal.INK, PixelFonts.TITLE_SIZE)
	LobbyOverlay._flourish(self, cx, PANEL.position.y + 33, 150)
	var y := PANEL.position.y + 42
	if page < _pages.size():
		for line in _pages[page]:
			HudDraw.text(self, PixelFonts.caption(), cx - TEXT_W / 2, y, line, Pal.INK, PixelFonts.CAPTION_SIZE)
			y += LINE_H
	var foot := PANEL.position.y + PANEL.size.y - 30
	var running: Array = RUNNING.get(brain, ["", Pal.INK])
	if running[0] != "":
		HudDraw.text_center(self, PixelFonts.bold(), cx, foot, running[0], running[1], PixelFonts.LABEL_SIZE)
	var more := "F6: NEXT PAGE" if page + 1 < _pages.size() else "F6: CLOSE"
	HudDraw.text_center(self, PixelFonts.label(), cx, foot + 11, "PAGE %d OF %d   %s" % [page + 1, _pages.size(), more],
		Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
