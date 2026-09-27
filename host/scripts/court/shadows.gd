class_name ShadowLayer
extends Node2D

## Dithered floor shadows (pixel art has no soft alpha), drawn above the floor
## and tables and below every actor.

var items: Array = []


func set_items(list: Array) -> void:
	items = list
	queue_redraw()


func _draw() -> void:
	for it in items:
		var pos: Vector2i = it["pos"]
		var rx: int = it["rx"]
		var ry: int = it["ry"]
		draw_texture(SpriteForge.shadow(rx, ry), Vector2(pos.x - rx, pos.y - ry))
