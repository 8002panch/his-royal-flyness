class_name RivalActor
extends Node2D

## A rival suitor from docs/LORE.md, standing on a feast table. Scenery only:
## no server field drives them and they never affect the game.

@export var style_name := "cheapdate"
@export var hall_pos := Vector3(-1.62, -0.88, -0.2)

var body := Sprite2D.new()
var body_px := 0
var bubble := ""
var _t := 0.0
var _base := Vector2.ZERO


func _ready() -> void:
	body.centered = false
	add_child(body)
	var p := HallCam.project(hall_pos)
	body_px = clampi(roundi(0.5 * p.z / 2.0) * 2, 16, 64)
	body.texture = SpriteForge.fly_front(body_px, style_name, _style())
	var feet := SpriteForge.front_feet(body_px)
	body.offset = -feet
	_base = Vector2(roundi(p.x), roundi(p.y))
	position = _base
	_t = 1.7 if style_name == "indy" else 0.0


func depth() -> float:
	return hall_pos.z


func _style() -> Dictionary:
	match style_name:
		"cheapdate":
			return {"tabard": Pal.CRIMSON, "charge": Pal.GOLD, "cap": Pal.CRIMSON_DARK, "goblet": true, "cheeks": true}
		"indy":
			return {"tabard": Pal.ROYAL, "charge": Pal.PARCHMENT, "bandage": true, "cane": true}
	return {"tabard": Pal.INK_SOFT}


func tick(delta: float) -> void:
	_t += delta
	var sway := 0
	if style_name == "cheapdate":
		# tipsy: a slow one-pixel lean and a hiccup hop every few seconds
		sway = 1 if fmod(_t, 2.4) < 1.2 else 0
		var hic := fmod(_t, 4.5)
		position = _base + Vector2(sway, -2 if hic < 0.12 else 0)
		bubble = "HIC!" if hic < 0.9 else ""
	else:
		position = _base + Vector2(0, -1 if fmod(_t, 1.6) < 0.2 else 0)
		bubble = ""
	queue_redraw()


func _draw() -> void:
	if bubble == "":
		return
	var font := PixelFonts.bold()
	var w := PixelFonts.width(font, bubble, PixelFonts.LABEL_SIZE) + 6
	var top := -body_px - 14
	HudDraw.panel(self, Rect2i(4, top, w, 11), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	draw_rect(Rect2(5, top + 11, 2, 1), Pal.INK)
	draw_rect(Rect2(3, top + 12, 2, 1), Pal.INK)
	HudDraw.text(self, font, 7, top + 2, bubble, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
