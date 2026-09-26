class_name TopRibbon
extends Control

## The parchment ribbon across the top: trial title in blackletter, the candle
## timer (meters.candle, provisional), the TRUE PRINCE / CHANGELING badge and a
## OFFLINE SAMPLE stamp whenever the state came from a host/test fixture.

const TRIALS := {"I": "The Garden Audience", "II": "The Banquet", "III": "The Giant's Shadow"}

var trial := ""
var candle := -1.0
var brain := ""
var sample := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, 26)


func apply(cs: CourtState) -> void:
	trial = cs.trial
	candle = cs.candle
	brain = cs.brain
	sample = cs.sample
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if candle > 0.0:
		queue_redraw()


func _draw() -> void:
	var w := HallCam.W
	draw_rect(Rect2(0, 0, w, 23), Pal.PARCHMENT)
	draw_rect(Rect2(0, 21, w, 1), Pal.PARCHMENT_DARK)
	draw_rect(Rect2(0, 22, w, 1), Pal.GOLD)
	draw_rect(Rect2(0, 23, w, 1), Pal.INK)
	for x in range(0, w, 2):
		draw_rect(Rect2(x, 24, 1, 1), Pal.INK)
	# crimson bookmark ends
	for bx in [6, w - 12]:
		draw_rect(Rect2(bx, 0, 6, 25), Pal.INK)
		draw_rect(Rect2(bx + 1, 0, 4, 24), Pal.CRIMSON)
		draw_rect(Rect2(bx + 2, 25, 2, 1), Pal.INK)

	# trial title
	var x := 18
	var roman := trial if trial != "" else ""
	if roman != "":
		x += HudDraw.text(self, PixelFonts.bold(), x, 8, "TRIAL %s" % roman, Pal.CRIMSON, PixelFonts.LABEL_SIZE) + 6
	var title: String = TRIALS.get(trial, "The Royal Ball")
	HudDraw.text(self, PixelFonts.title(), x, 0, title, Pal.INK, PixelFonts.TITLE_SIZE)

	_draw_candle(Rect2i(254, 7, 132, 9))

	# brain badge + sample stamp, right-aligned
	var right := w - 18
	var badge := ""
	var fill := Pal.ROYAL
	var ink := Pal.GOLD_LIGHT
	match brain:
		"true":
			badge = "TRUE PRINCE"
		"changeling":
			badge = "CHANGELING"
			fill = Pal.CRIMSON
			ink = Pal.PARCHMENT
		"placeholder":
			badge = "PLACEHOLDER SEER"
			fill = Pal.PARCHMENT_DARK
			ink = Pal.INK
	if badge != "":
		var bw := PixelFonts.width(PixelFonts.bold(), badge, PixelFonts.LABEL_SIZE) + 12
		var bx := right - bw
		HudDraw.panel(self, Rect2i(bx, 4, bw, 15), fill, Pal.INK, Pal.GOLD if brain == "true" else Color(0, 0, 0, 0), fill.darkened(0.25))
		HudDraw.text(self, PixelFonts.bold(), bx + 6, 7, badge, ink, PixelFonts.LABEL_SIZE)
		right = bx - 6
	if sample:
		var s := "OFFLINE SAMPLE"
		var sw := PixelFonts.width(PixelFonts.bold(), s, PixelFonts.LABEL_SIZE) + 8
		HudDraw.frame(self, Rect2i(right - sw, 5, sw, 13), Pal.CRIMSON)
		HudDraw.frame(self, Rect2i(right - sw + 1, 6, sw - 2, 11), Pal.CRIMSON)
		HudDraw.text(self, PixelFonts.bold(), right - sw + 4, 7, s, Pal.CRIMSON, PixelFonts.LABEL_SIZE)


## A wax candle lying on its side, burning from the right. Without a timer in
## the state it stays whole and unlit.
func _draw_candle(r: Rect2i) -> void:
	var lit := candle >= 0.0
	var frac := candle if lit else 1.0
	var wax_w := maxi(0, roundi((r.size.x - 10) * frac))
	# holder
	draw_rect(Rect2(r.position.x - 1, r.position.y - 2, 9, r.size.y + 4), Pal.INK)
	draw_rect(Rect2(r.position.x, r.position.y - 1, 7, r.size.y + 2), Pal.GOLD)
	draw_rect(Rect2(r.position.x, r.position.y - 1, 7, 1), Pal.GOLD_LIGHT)
	# burnt track
	var track_x := r.position.x + 8
	draw_rect(Rect2(track_x, r.position.y + 3, r.size.x - 10, 3), Pal.PARCHMENT_DARK)
	for tx in range(track_x, track_x + r.size.x - 10, 4):
		draw_rect(Rect2(tx, r.position.y + 4, 2, 1), Pal.PARCHMENT_SHADE)
	if wax_w > 0:
		draw_rect(Rect2(track_x, r.position.y, wax_w, r.size.y), Pal.INK)
		draw_rect(Rect2(track_x, r.position.y + 1, wax_w - 1, r.size.y - 2), Pal.PARCHMENT)
		draw_rect(Rect2(track_x, r.position.y + r.size.y - 3, wax_w - 1, 2), Pal.PARCHMENT_DARK)
		for dx in range(6, wax_w - 3, 17):
			draw_rect(Rect2(track_x + dx, r.position.y + r.size.y - 1, 1, 2), Pal.PARCHMENT_DARK)
	var tip := track_x + wax_w
	draw_rect(Rect2(tip, r.position.y + 4, 2, 1), Pal.INK)
	if lit and candle > 0.0:
		var flick := int(_t * 8.0) % 3
		var fx := tip + 2
		var fy := r.position.y + 4
		draw_rect(Rect2(fx, fy - 2, 5 + flick, 5), Pal.INK)
		draw_rect(Rect2(fx + 1, fy - 1, 3 + flick, 3), Pal.FLAME_OUT)
		draw_rect(Rect2(fx + 2, fy, 2 + flick, 1), Pal.FLAME)
