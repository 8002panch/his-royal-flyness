class_name HallLayer
extends Node2D

## One of the hall's static layers, repainted every frame through the current
## camera (HallBuilder + CanvasPainter), so the hall moves around Hamlet.
##   far      vault, walls, great arch, rose window
##   floor    tiles, carpet, dais
##   columns  back banners, arcade, columns, and the Part 2 wall course
##   feast    tables and dishes, then the flickering candle flames

const BANNER_SWAY := [0, 1, 0, -1]

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
			HallBuilder.paint_far(_painter)
		"floor":
			HallBuilder.paint_floor(_painter)
		"columns":
			_draw_back_banners()
			HallBuilder.paint_columns(_painter)
			HallBuilder.paint_course_walls(_painter)
		"feast":
			var flames := HallBuilder.paint_feast(_painter)
			for i in flames.size():
				draw_texture(SpriteForge.flame((anim_step + i * 2) % 3), Vector2(flames[i]))


func _draw_back_banners() -> void:
	var specs := HallBuilder.back_banners()
	for i in specs.size():
		var spec: Dictionary = specs[i]
		# sizes snap to a few pixels so the per-size sprite cache stays small
		var bw := maxi(6, int(spec["w"]) / 2 * 2)
		var bh := maxi(12, int(spec["h"]) / 4 * 4)
		var sway: int = BANNER_SWAY[(anim_step / 4 + i * 2) % BANNER_SWAY.size()]
		var tex := SpriteForge.banner(bw, bh, spec["field"], spec["emblem"], sway)
		draw_texture(tex, Vector2(spec["pos"]) - Vector2(4, 0))
