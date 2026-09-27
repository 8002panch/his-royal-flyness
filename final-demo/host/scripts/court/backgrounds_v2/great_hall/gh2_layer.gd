extends Node2D

## One of the four world layers of the Great Hall v2 (Trial III "The Giant's
## Shadow"), repainted every frame through HallCam with the same layer API as
## HallLayer (far / floor / columns / feast) so the chase camera, the Giant's hand,
## shadows and actors all keep working. Host it in the court with the play
## launcher's layer shim (scenes/backgrounds/play/play_layer.gd), which sets
## `layer` before adding it and forwards `anim_step`.

const WALLS := preload("gh2_walls.gd")
const FLOOR := preload("gh2_floor.gd")
const ARCADE := preload("gh2_arcade.gd")
const FEAST := preload("gh2_feast.gd")

@export_enum("far", "floor", "columns", "feast") var layer := "far"

var anim_step := 0
var _painter: CanvasPainter


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)


func _process(_delta: float) -> void:
	queue_redraw()


## Smoothed paint cost per layer in microseconds (read by the play launcher's log).
static var prof := {}


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_paint()
	prof[layer] = lerpf(prof.get(layer, 0.0), float(Time.get_ticks_usec() - t0), 0.05)


func _paint() -> void:
	match layer:
		"far":
			WALLS.paint(_painter)
		"floor":
			FLOOR.paint(_painter)
		"columns":
			ARCADE.paint(_painter)
		"feast":
			FEAST.paint(_painter)
