class_name NameTags
extends Node2D

## Parchment name tags over Hamlet and Miranda, so a newcomer can tell who is
## who at a glance. Drawn above everything else in the world.

var tags: Array = []


func set_tags(list: Array) -> void:
	tags = list
	queue_redraw()


func _draw() -> void:
	for t in tags:
		if t.get("below", false):
			HudDraw.tag_below(self, t["anchor"], t["text"], t.get("ink", Pal.INK))
		else:
			HudDraw.tag(self, t["anchor"], t["text"], t.get("ink", Pal.INK))
