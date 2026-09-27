extends Node2D

const BUILDER := preload("res://scripts/court/backgrounds_v2/garden/garden2_builder.gd")

var layer := "far"
var anim_step := 0
var _painter: CanvasPainter
static var prof := {}
static var frames := 0


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	match layer:
		"far":
			BUILDER.paint_far(_painter)
		"floor":
			BUILDER.paint_floor(_painter)
		"columns":
			BUILDER.paint_columns(_painter)
		"feast":
			var flames: Array = BUILDER.paint_feast(_painter)
			for i in flames.size():
				draw_texture(SpriteForge.flame((anim_step + i * 2) % 3), Vector2(flames[i]))
	prof[layer] = prof.get(layer, 0) + Time.get_ticks_usec() - t0
	if layer == "far":
		frames += 1
		if frames % 20 == 0:
			var s := ""
			for k in prof:
				s += "%s=%.1fms " % [k, prof[k] / 20000.0]
			for k in BUILDER.LAYER_PROF:
				s += "| %s=%.1f " % [k, BUILDER.LAYER_PROF[k] / 20000.0]
			BUILDER.LAYER_PROF.clear()
			print("PROF ", s)
			prof.clear()
