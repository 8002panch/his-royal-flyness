class_name ObjectiveBanner
extends Control

## One line under the ribbon that says what to do next.

const Y := 27

var demo := false
var environment := "hall"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, 40)


func set_demo(on: bool) -> void:
	if on != demo:
		demo = on
		queue_redraw()


func set_environment(value: String) -> void:
	if value != environment:
		environment = value
		queue_redraw()


func _draw() -> void:
	var bold := PixelFonts.bold()
	if demo:
		var k := "A/D STEER   W/S FLY / BRAKE   SPACE/SHIFT CLIMB / DIVE   E SCAN"
		var kw := PixelFonts.width(PixelFonts.label(), k, PixelFonts.LABEL_SIZE) + 12
		var kx := HallCam.W / 2 - kw / 2
		HudDraw.panel(self, Rect2i(kx, Y + 15, kw, 12), Pal.INK, Pal.INK, Color(0, 0, 0, 0), Pal.INK)
		HudDraw.text(self, PixelFonts.label(), kx + 6, Y + 17, k, Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)
	var a := "FLY HAMLET THROUGH THE GARDEN TO MIRANDA" if environment == "garden" else "FLY HAMLET THROUGH THE WALLS TO MIRANDA"
	var wa := PixelFonts.width(bold, a, PixelFonts.LABEL_SIZE)
	var w := wa + 14
	var x := HallCam.W / 2 - w / 2
	HudDraw.panel(self, Rect2i(x, Y, w, 13), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	HudDraw.text(self, bold, x + 7, Y + 3, a, Pal.INK, PixelFonts.LABEL_SIZE)
