class_name BanquetHallLayer
extends Node2D

## One layer of the Trial II Banquet background, repainted every frame
## through the current camera (BanquetHallBuilder + CanvasPainter), exactly
## like scripts/court/hall_layer.gd (which this file leaves untouched) so it
## can be swapped in as a drop-in replacement for the matching HallLayer node
## under the chase camera.
##   far      base vault/walls/arch + torch sconces on the feast-side wall
##   floor    base tiles/carpet/dais + a warm rug and scattered rushes
##   columns  base arcade/columns/banners + garland swags between the bays
##   feast    the banquet table, wine barrels, fermenting crates, then the
##            flickering candle and torch flames

@export_enum("far", "floor", "columns", "feast") var layer := "far"

var anim_step := 0
var _painter: CanvasPainter


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match layer:
		"far":
			BanquetHallBuilder.paint_far(_painter)
		"floor":
			BanquetHallBuilder.paint_floor(_painter)
		"columns":
			BanquetHallBuilder.paint_columns(_painter)
		"feast":
			var flames := BanquetHallBuilder.paint_feast(_painter)
			for i in flames.size():
				draw_texture(SpriteForge.flame((anim_step + i * 2) % 3), Vector2(flames[i]))
