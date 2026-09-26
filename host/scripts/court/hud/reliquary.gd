class_name Reliquary
extends Control

## Hamlet's Reliquary: three purely cosmetic relics toggled on this laptop only
## (click a slot, or press 1 / 2 / 3). Nothing is sent to the relay or the
## server. The choice is remembered in user://reliquary.cfg.

signal toggled(relic: String, on: bool)

const RELICS := [["mantle", "ROYAL MANTLE"], ["halo", "SUN HALO"], ["filigree", "WING FILIGREE"]]
const SAVE_PATH := "user://reliquary.cfg"
const SLOT := 18
const PANEL := Vector2i(72, 36)

var on := {"mantle": false, "halo": false, "filigree": false}
var persist := true
var _note := ""
var _note_left := 0.0


func _ready() -> void:
	size = Vector2(PANEL.x, PANEL.y + 14)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for r in RELICS:
			on[r[0]] = bool(cfg.get_value("relics", r[0], false))


## Screenshot mode: start from nothing and never touch the saved choice.
func reset_unsaved() -> void:
	persist = false
	for r in RELICS:
		on[r[0]] = false
	announce()


## Tell listeners about the saved choice once everything is connected.
func announce() -> void:
	for r in RELICS:
		toggled.emit(r[0], on[r[0]])
	queue_redraw()


func toggle_index(i: int) -> void:
	if i < 0 or i >= RELICS.size():
		return
	var relic: String = RELICS[i][0]
	on[relic] = not on[relic]
	_note = "%s %s" % [RELICS[i][1], "ON" if on[relic] else "OFF"]
	_note_left = 2.0
	toggled.emit(relic, on[relic])
	if not persist:
		queue_redraw()
		return
	var cfg := ConfigFile.new()
	for r in RELICS:
		cfg.set_value("relics", r[0], on[r[0]])
	cfg.save(SAVE_PATH)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = mb.position
		for i in RELICS.size():
			if Rect2(_slot_pos(i), Vector2(SLOT, SLOT)).has_point(p):
				toggle_index(i)
				accept_event()


func _process(delta: float) -> void:
	if _note_left > 0.0:
		_note_left -= delta
		if _note_left <= 0.0:
			_note = ""
		queue_redraw()


func _slot_pos(i: int) -> Vector2:
	return Vector2(5 + i * (SLOT + 4), 14)


func _draw() -> void:
	HudDraw.panel(self, Rect2i(0, 0, PANEL.x, PANEL.y))
	HudDraw.text_center(self, PixelFonts.bold(), PANEL.x / 2, 4, "RELIQUARY", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	for i in RELICS.size():
		var relic: String = RELICS[i][0]
		var p := Vector2i(_slot_pos(i))
		var lit: bool = on[relic]
		draw_rect(Rect2(p, Vector2(SLOT, SLOT)), Pal.INK)
		draw_rect(Rect2(p + Vector2i(1, 1), Vector2(SLOT - 2, SLOT - 2)), Pal.GOLD if lit else Pal.PARCHMENT_DARK)
		draw_rect(Rect2(p + Vector2i(2, 2), Vector2(SLOT - 4, SLOT - 4)), Pal.PARCHMENT if lit else Pal.PARCHMENT_DARK)
		HudDraw.tex(self, SpriteForge.relic_icon(relic, lit), p + Vector2i(2, 2))
		# key hint in the corner
		draw_rect(Rect2(p.x + SLOT - 5, p.y + SLOT - 6, 5, 6), Pal.INK)
		HudDraw.text(self, PixelFonts.label(), p.x + SLOT - 4, p.y + SLOT - 7, str(i + 1), Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
	if _note != "":
		var w := PixelFonts.width(PixelFonts.bold(), _note, PixelFonts.LABEL_SIZE) + 8
		HudDraw.panel(self, Rect2i(0, PANEL.y + 2, w, 12), Pal.INK, Pal.INK, Color(0, 0, 0, 0), Pal.INK)
		HudDraw.text(self, PixelFonts.bold(), 4, PANEL.y + 4, _note, Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)
