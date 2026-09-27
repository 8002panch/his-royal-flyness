extends Node2D

## Dev only: an empty stand-in layer, to measure the court's own frame cost
## (great_hall_play.tscn -- --theme=none).

@export_enum("far", "floor", "columns", "feast") var layer := "far"
var anim_step := 0
