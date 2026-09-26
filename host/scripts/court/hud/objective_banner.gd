class_name ObjectiveBanner
extends Control

## One line under the ribbon that says what to do next. Turns crimson and
## blinks while the Giant's hand is visible in the hall.

const Y := 27

var hazard := false
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, 40)


func set_hazard(on: bool) -> void:
	if on != hazard:
		hazard = on
		queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if hazard:
		queue_redraw()


func _draw() -> void:
	var bold := PixelFonts.bold()
	if hazard:
		var s := "THE GIANT'S HAND! DODGE IT!"
		var w := PixelFonts.width(bold, s, PixelFonts.LABEL_SIZE) + 14
		var x := HallCam.W / 2 - w / 2
		var flash := int(_t * 6.0) % 2 == 0
		HudDraw.panel(self, Rect2i(x, Y, w, 13), Pal.CRIMSON if flash else Pal.CRIMSON_DARK, Pal.INK, Color(0, 0, 0, 0), Pal.CRIMSON_DARK)
		HudDraw.text(self, bold, x + 7, Y + 3, s, Pal.PARCHMENT, PixelFonts.LABEL_SIZE)
		return
	var a := "FLY HAMLET TO MIRANDA"
	var b := "DODGE THE GIANT'S HAND"
	var wa := PixelFonts.width(bold, a, PixelFonts.LABEL_SIZE)
	var wb := PixelFonts.width(bold, b, PixelFonts.LABEL_SIZE)
	var w := wa + wb + 34
	var x := HallCam.W / 2 - w / 2
	HudDraw.panel(self, Rect2i(x, Y, w, 13), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	HudDraw.text(self, bold, x + 7, Y + 3, a, Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.tex(self, SpriteForge.heart(), Vector2i(x + 7 + wa + 5, Y + 2))
	HudDraw.text(self, bold, x + 7 + wa + 20, Y + 3, b, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
