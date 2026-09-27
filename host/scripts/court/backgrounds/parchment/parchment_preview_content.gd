class_name ParchmentPreviewContent
extends Control

## Preview-only stand-in for "each screen's own content": a title, a subtitle
## in the current accent, and a placeholder panel inside
## ParchmentBackdrop.content_rect(). Nothing here ships behind a real screen;
## it exists so the parchment_preview scene shows the backdrop actually
## carrying something, the way Lobby/Chronicle will.

var accent := Pal.GOLD
var caption := "PARCHMENT BACKDROP PREVIEW"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(ParchmentBackdrop.W, ParchmentBackdrop.H)


func _draw() -> void:
	var r := ParchmentBackdrop.content_rect()
	var cx := r.position.x + r.size.x / 2
	HudDraw.text_center(self, PixelFonts.title(), cx, r.position.y + 4, "His Royal Flyness", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(self, PixelFonts.bold(), cx, r.position.y + 27, caption, accent, PixelFonts.LABEL_SIZE)
	var panel_r := Rect2i(r.position.x + 36, r.position.y + 56, r.size.x - 72, r.size.y - 96)
	HudDraw.panel(self, panel_r, Pal.PARCHMENT, Pal.INK, accent, Pal.PARCHMENT_DARK)
	HudDraw.text_center(self, PixelFonts.label(), cx, r.position.y + r.size.y / 2 - 4,
		"EACH SCREEN DRAWS ITS OWN PANEL / TITLE HERE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(self, PixelFonts.label(), cx, r.position.y + r.size.y - 22,
		"content_rect() STAYS EMPTY AND UNDECORATED", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
