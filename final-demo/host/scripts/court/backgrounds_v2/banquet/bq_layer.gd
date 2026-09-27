extends Node2D

## One layer of the Banquet v2 background, repainted every frame through the
## current camera (bq_hall.gd / bq_feast.gd via CanvasPainter), a drop-in for the
## matching HallLayer under the chase camera. `layer` and `anim_step` are the
## same contract as HallLayer (the play shim forwards anim_step).
##   far      side walls + windows, back wall, great arch, rose window, doors
##   floor    tiles, carpet, dais, table shadows, spilled wine
##   columns  arcade, banners, columns with wall torches
##   feast    feast table, Sir Cheapdate's bare table, candelabra, barrels

const HALL := preload("res://scripts/court/backgrounds_v2/banquet/bq_hall.gd")
const FEAST := preload("res://scripts/court/backgrounds_v2/banquet/bq_feast.gd")
const SP := preload("res://scripts/court/backgrounds_v2/banquet/bq_sprites.gd")

@export_enum("far", "floor", "columns", "feast") var layer := "far"

var anim_step := 0
var _painter: CanvasPainter


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var flames: Array = []
	match layer:
		"far":
			HALL.paint_far(_painter)
		"floor":
			HALL.paint_floor(_painter)
		"columns":
			flames = HALL.paint_columns(_painter)
		"feast":
			flames = FEAST.paint_feast(_painter)
	for i in flames.size():
		var f: Vector3i = flames[i]
		var off := Vector2(1, 3) if f.z == 1 else Vector2.ZERO
		draw_texture(SP.flame_tex((anim_step + i * 2) % 3, f.z), Vector2(f.x, f.y) - off)
