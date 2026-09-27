class_name CaptionScroll
extends Control

## Captions for voice lines on a small parchment scroll above the role cards.
## Fed by `event` messages ({"kind": "voice"|"voice_live", "caption"|"text", "speaker"}),
## the same events the old dashboard captioned. Long lines wrap onto two rows.

const HOLD_S := 4.5
const BOTTOM := 315
const MAX_W := 560
const ROW := 13

var speaker := ""
var rows: Array = []
var _left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)


func show_caption(who: String, text: String) -> void:
	speaker = (who.to_upper() + ": ") if who != "" else ""
	rows = _wrap(text)
	_left = HOLD_S
	queue_redraw()


func _process(delta: float) -> void:
	if _left > 0.0:
		if speaker == "CLOWN: ":
			queue_redraw()  # his head bobs while he talks
		_left -= delta
		if _left <= 0.0:
			rows = []
			queue_redraw()


func _wrap(text: String) -> Array:
	var font := PixelFonts.caption()
	var size_px := PixelFonts.CAPTION_SIZE
	var first_w := MAX_W - PixelFonts.width(PixelFonts.bold(), speaker, PixelFonts.LABEL_SIZE)
	var out: Array = [""]
	for word in text.split(" ", false):
		var cur: String = out[out.size() - 1]
		var trial := word if cur == "" else cur + " " + word
		var limit := first_w if out.size() == 1 else MAX_W
		if PixelFonts.width(font, trial, size_px) <= limit or cur == "":
			out[out.size() - 1] = trial
		elif out.size() < 2:
			out.append(word)
		else:
			out[1] = cur.left(maxi(0, cur.length() - 3)) + "..."
			break
	return out


func _draw() -> void:
	if rows.is_empty():
		return
	var font := PixelFonts.caption()
	var size_px := PixelFonts.CAPTION_SIZE
	var who_w := PixelFonts.width(PixelFonts.bold(), speaker, PixelFonts.LABEL_SIZE) if speaker != "" else 0
	var tw := 0
	for i in rows.size():
		tw = maxi(tw, PixelFonts.width(font, rows[i], size_px) + (who_w if i == 0 else 0))
	var w := tw + 20
	var h := 7 + ROW * rows.size()
	var x := HallCam.W / 2 - w / 2
	var y := BOTTOM - h
	HudDraw.panel(self, Rect2i(x, y, w, h), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	# rolled ends of the scroll
	for ex in [x - 4, x + w - 1]:
		draw_rect(Rect2(ex, y - 2, 5, h + 4), Pal.INK)
		draw_rect(Rect2(ex + 1, y - 1, 3, h + 2), Pal.PARCHMENT_DARK)
		draw_rect(Rect2(ex + 1, y - 1, 1, h + 2), Pal.PARCHMENT)
	var cx := x + 10
	if speaker == "CLOWN: ":
		var head := StoryArt.clown_head()
		if head != null:
			var bob := roundf(sin(Time.get_ticks_msec() / 90.0) * 1.0)
			draw_texture(head, Vector2(maxf(2.0, x - 58), y + h - 50 + bob))
	if speaker != "":
		HudDraw.text(self, PixelFonts.bold(), cx, y + 6, speaker, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	for i in rows.size():
		HudDraw.text(self, font, cx + (who_w if i == 0 else 0), y + 1 + i * ROW, rows[i], Pal.INK, size_px)
