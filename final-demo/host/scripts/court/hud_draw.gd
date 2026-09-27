class_name HudDraw
extends RefCounted

## Pixel-exact drawing helpers for parchment UI: every rect lands on whole
## pixels, borders are 1 px ink with clipped corners, text sits on an integer
## baseline in a pixel font.


static func panel(ci: CanvasItem, r: Rect2i, fill: Color = Pal.PARCHMENT, border: Color = Pal.INK,
		rule: Color = Pal.GOLD, shade: Color = Pal.PARCHMENT_DARK) -> void:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	if w < 4 or h < 4:
		return
	ci.draw_rect(Rect2(x + 1, y, w - 2, 1), border)
	ci.draw_rect(Rect2(x + 1, y + h - 1, w - 2, 1), border)
	ci.draw_rect(Rect2(x, y + 1, 1, h - 2), border)
	ci.draw_rect(Rect2(x + w - 1, y + 1, 1, h - 2), border)
	ci.draw_rect(Rect2(x + 1, y + 1, w - 2, h - 2), fill)
	if shade.a > 0.0:
		ci.draw_rect(Rect2(x + 1, y + h - 2, w - 2, 1), shade)
		ci.draw_rect(Rect2(x + w - 2, y + 1, 1, h - 3), shade)
	if rule.a > 0.0 and w > 8 and h > 8:
		frame(ci, Rect2i(x + 2, y + 2, w - 4, h - 4), rule)


static func frame(ci: CanvasItem, r: Rect2i, c: Color) -> void:
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), c)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), c)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), c)
	ci.draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), c)


static func text(ci: CanvasItem, font: Font, x: int, top: int, s: String, c: Color, size: int) -> int:
	## Draws with the glyph box's top at `top`; returns the width drawn.
	var baseline := top + roundi(font.get_ascent(size))
	ci.draw_string(font, Vector2(x, baseline), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
	return PixelFonts.width(font, s, size)


static func text_center(ci: CanvasItem, font: Font, cx: int, top: int, s: String, c: Color, size: int) -> void:
	var w := PixelFonts.width(font, s, size)
	text(ci, font, cx - w / 2, top, s, c, size)


static func text_right(ci: CanvasItem, font: Font, right: int, top: int, s: String, c: Color, size: int) -> void:
	text(ci, font, right - PixelFonts.width(font, s, size), top, s, c, size)


## A text height that matches what the pixel font actually covers.
static func cap_height(font: Font, size: int) -> int:
	return roundi(font.get_ascent(size))


static func tex(ci: CanvasItem, t: Texture2D, pos: Vector2i) -> void:
	if t != null:
		ci.draw_texture(t, Vector2(pos))


static func tex_center(ci: CanvasItem, t: Texture2D, center: Vector2i) -> void:
	if t != null:
		ci.draw_texture(t, Vector2(center.x - t.get_width() / 2, center.y - t.get_height() / 2))


## Horizontal pip bar: ink frame, parchment track, filled part in `col`.
static func bar(ci: CanvasItem, r: Rect2i, fraction: float, col: Color, empty: Color = Pal.PARCHMENT_DARK) -> void:
	ci.draw_rect(Rect2(r.position, r.size), Pal.INK)
	ci.draw_rect(Rect2(r.position + Vector2i(1, 1), r.size - Vector2i(2, 2)), empty)
	var fw := roundi((r.size.x - 2) * clampf(fraction, 0.0, 1.0))
	if fw > 0:
		ci.draw_rect(Rect2(r.position.x + 1, r.position.y + 1, fw, r.size.y - 2), col)


## A tag hanging below `anchor`, pointer up.
static func tag_below(ci: CanvasItem, anchor: Vector2i, s: String, ink: Color = Pal.INK, fill: Color = Pal.PARCHMENT) -> void:
	var font := PixelFonts.bold()
	var w := PixelFonts.width(font, s, PixelFonts.LABEL_SIZE) + 8
	var h := 11
	var x := clampi(anchor.x - w / 2, 2, HallCam.W - w - 2)
	var y := anchor.y + 3
	panel(ci, Rect2i(x, y, w, h), fill, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	ci.draw_rect(Rect2(anchor.x - 2, y, 5, 1), fill)
	ci.draw_rect(Rect2(anchor.x - 1, y - 1, 3, 1), fill)
	ci.draw_rect(Rect2(anchor.x, y - 2, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x - 3, y, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x + 3, y, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x - 2, y - 1, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x + 2, y - 1, 1, 1), Pal.INK)
	text(ci, font, x + 4, y + 2, s, ink, PixelFonts.LABEL_SIZE)


## A name tag with a little pointer underneath, centred on `anchor` (the tip).
static func tag(ci: CanvasItem, anchor: Vector2i, s: String, ink: Color = Pal.INK, fill: Color = Pal.PARCHMENT) -> void:
	var font := PixelFonts.bold()
	var w := PixelFonts.width(font, s, PixelFonts.LABEL_SIZE) + 8
	var h := 11
	var x := clampi(anchor.x - w / 2, 2, HallCam.W - w - 2)
	var y := anchor.y - h - 3
	panel(ci, Rect2i(x, y, w, h), fill, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	ci.draw_rect(Rect2(anchor.x - 2, y + h - 1, 5, 1), fill)
	ci.draw_rect(Rect2(anchor.x - 1, y + h, 3, 1), fill)
	ci.draw_rect(Rect2(anchor.x, y + h + 1, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x - 3, y + h - 1, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x + 3, y + h - 1, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x - 2, y + h, 1, 1), Pal.INK)
	ci.draw_rect(Rect2(anchor.x + 2, y + h, 1, 1), Pal.INK)
	text(ci, font, x + 4, y + 2, s, ink, PixelFonts.LABEL_SIZE)
