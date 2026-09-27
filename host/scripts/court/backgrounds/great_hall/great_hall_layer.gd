class_name GreatHallLayer
extends Node2D

## One of the Great Hall's (Trial III, night variant) static layers, repainted
## every frame through HallCam via GreatHallBuilder — the same pattern as
## hall_layer.gd, kept as its own file so the day hall script is never touched.
##   far      vault, walls, great arch, rose window
##   floor    tiles, carpet, dais, deeper dithered gloom
##   columns  back-wall banners (swaying), arcade, side banners, columns
##   feast    tables, guttering candle flames (drawn here, not SpriteForge),
##            then the Giant's looming hand-shadow across everything above

const BANNER_SWAY := [0, 1, 0, -1]

@export_enum("far", "floor", "columns", "feast") var layer := "far"

var anim_step := 0
var _painter: CanvasPainter
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)
	_rng.seed = 7


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	match layer:
		"far":
			GreatHallBuilder.paint_far(_painter)
		"floor":
			GreatHallBuilder.paint_floor(_painter)
		"columns":
			_draw_back_banners()
			GreatHallBuilder.paint_columns(_painter)
		"feast":
			var spots := GreatHallBuilder.paint_feast(_painter)
			for spot in spots:
				_draw_guttering_flame(spot["pos"], int(spot["seed"]))
			# drawn last of the four world layers so it falls across the
			# arcade, banners and tables beneath it, not just the far wall
			GreatHallBuilder.paint_loom_shadow(_painter)


func _draw_back_banners() -> void:
	var specs := GreatHallBuilder.back_banners()
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var bw := maxi(6, int(spec["w"]) / 2 * 2)
		var bh := maxi(12, int(spec["h"]) / 4 * 4)
		var sway: int = BANNER_SWAY[(anim_step / 4 + i * 2) % BANNER_SWAY.size()]
		var tex := SpriteForge.banner(bw, bh, spec["field"], spec["emblem"], sway)
		draw_texture(tex, Vector2(spec["pos"]) - Vector2(4, 0))


## A small, dim, irregular flame: low most of the time, occasionally guttering
## down almost to nothing or flaring for a beat, per-candle out of phase via
## its seed. Drawn straight into the layer (no SpriteForge texture) so it can
## be this weak without touching the day hall's flame sprite.
func _draw_guttering_flame(pos: Vector2i, seed: int) -> void:
	var phase := anim_step + seed * 5
	_rng.seed = phase * 1000 + seed
	var gutter := _rng.randf() < 0.22
	var h := 3 if gutter else (5 if (phase % 7 == 0) else 4)
	var w := 1 if gutter else 2
	var x := pos.x
	var y := pos.y
	if not gutter:
		draw_rect(Rect2(x - w - 1, y - h + 1, (w + 1) * 2 + 1, h), GHPal.FLAME_GLOW)
	draw_rect(Rect2(x - w, y - h + 2, w * 2, h - 1), GHPal.FLAME_LOW)
	draw_rect(Rect2(x - w + 1, y - h + 1, maxi(1, w * 2 - 2), h - 2), GHPal.FLAME_MID)
	if not gutter:
		draw_rect(Rect2(x, y - h, 1, 1), GHPal.FLAME_HOT)
