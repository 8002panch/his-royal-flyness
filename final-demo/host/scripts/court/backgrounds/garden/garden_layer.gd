class_name GardenLayer
extends Node2D

## One of the Garden Audience's static layers, repainted every frame through
## the current camera (GardenBuilder + CanvasPainter), exactly like
## scripts/court/hall_layer.gd -- so the garden moves around Hamlet the same
## way the hall does. Layer names match HallLayer's enum on purpose: a node
## can swap a HallLayer for a GardenLayer with its `layer` value unchanged.
##   far      evening sky, moon, clipped hedge walls, the back hedge + arbor
##   floor    lawn, gravel path, the low fountain wall
##   columns  wooden trellis posts, lattice bays, hanging grape garlands
##   feast    garden lanterns (then their flickering glow) and grape crates

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
			GardenBuilder.paint_far(_painter)
		"floor":
			GardenBuilder.paint_floor(_painter)
		"columns":
			GardenBuilder.paint_columns(_painter)
		"feast":
			var glows := GardenBuilder.paint_feast(_painter)
			for i in glows.size():
				draw_texture(SpriteForge.flame((anim_step + i * 2) % 3), Vector2(glows[i]))
