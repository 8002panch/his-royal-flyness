class_name ShadowLayer
extends Node2D

## Dithered floor shadows (pixel art has no soft alpha) and the Giant's
## crimson target ring. Drawn above the floor and tables, below every actor.

var items: Array = []
var _t := 0.0


func set_items(list: Array) -> void:
	items = list
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta


func _draw() -> void:
	for it in items:
		var pos: Vector2i = it["pos"]
		var rx: int = it["rx"]
		var ry: int = it["ry"]
		draw_texture(SpriteForge.shadow(rx, ry), Vector2(pos.x - rx, pos.y - ry))
		if it.get("ring", false):
			var beat := int(_t * 6.0) % 3
			var rrx := rx + 3 + 2 * beat
			var rry := ry + 1 + beat
			var col := Pal.PARCHMENT if beat == 0 else Pal.CRIMSON_LIGHT
			draw_texture(SpriteForge.target_ring(rrx, rry, col), Vector2(pos.x - rrx - 2, pos.y - rry - 2))
