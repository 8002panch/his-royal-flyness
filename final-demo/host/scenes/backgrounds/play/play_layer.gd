extends HallLayer

## Play-test shim: stands in for a HallLayer inside Court.tscn (court_world.gd
## casts its layers to HallLayer) but draws nothing itself. It hosts one layer
## of a themed background (GardenLayer, BanquetHallLayer, GreatHallLayer) as a
## child and forwards the prop animation step to it.

var theme_script: Script
var _inner: Node2D


func _ready() -> void:
	super()
	_inner = theme_script.new()
	_inner.layer = layer
	add_child(_inner)


func _process(_delta: float) -> void:
	_inner.anim_step = anim_step


func _draw() -> void:
	pass
