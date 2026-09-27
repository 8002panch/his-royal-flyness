class_name DebugOverlay
extends Control

## F1: raw state and one waveform per brainActivity key, whatever keys arrive.
## Debug only; the waveforms are deliberately not part of the normal main screen.

const HISTORY := 150
const COLORS := [Pal.ROYAL_LIGHT, Pal.ROYAL, Pal.CRIMSON_LIGHT, Pal.CRIMSON, Pal.GOLD, Pal.GOLD_LIGHT, Pal.PARCHMENT, Pal.GOLD_DARK]

var history := {}
var lines: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(100, 150)
	size = Vector2(300, 150)


func apply(cs: CourtState) -> void:
	for k in cs.activity:
		if not history.has(k):
			history[k] = []
	for k in history:
		var h: Array = history[k]
		h.append(float(cs.activity.get(k, 0.0)))
		if h.size() > HISTORY:
			h.pop_front()
	lines = [
		"PHASE %s  T %.2f  FRAME %d  SAMPLE %s" % [cs.phase, cs.time, cs.frame, cs.sample],
		"FLY %.2f %.2f %.2f  V %.2f %.2f %.2f" % [cs.fly.x, cs.fly.y, cs.fly.z, cs.fly_vel.x, cs.fly_vel.y, cs.fly_vel.z],
		"PRINCESS %s" % [JSON.stringify(cs.princess)],
		"ROLES %s" % [JSON.stringify(cs.roles_active)],
	]
	if visible:
		queue_redraw()


func _draw() -> void:
	HudDraw.panel(self, Rect2i(0, 0, int(size.x), int(size.y)), Pal.INK, Pal.GOLD, Color(0, 0, 0, 0), Pal.INK)
	var y := 4
	for s in lines:
		HudDraw.text(self, PixelFonts.label(), 5, y, str(s).left(56), Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
		y += 10
	var top := y + 4
	var h := int(size.y) - top - 6
	var mid := top + h / 2
	draw_rect(Rect2(5, mid, size.x - 10, 1), Pal.INK_SOFT)
	var keys: Array = history.keys()
	for i in keys.size():
		var vals: Array = history[keys[i]]
		var pts := PackedVector2Array()
		for j in vals.size():
			var v := clampf(float(vals[j]) / 6.0, -1.0, 1.0)
			pts.append(Vector2(5 + j * (size.x - 10) / HISTORY, roundf(mid - v * (h / 2 - 1))))
		if pts.size() > 1:
			draw_polyline(pts, COLORS[i % COLORS.size()], -1.0)
