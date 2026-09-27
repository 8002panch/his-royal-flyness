extends Node

## Play-test a background with the keyboard demo, without touching Court.tscn:
## instances the real court, swaps its four hall layers for the chosen theme,
## and starts in the WASD demo.
##
##   godot --path host res://scenes/backgrounds/play/play_bg.tscn -- --bg=garden --demo
##   --bg = garden | banquet | great_hall | hall (the unchanged day hall)

const LAYER_NODES := ["FarBackground", "FloorCarpet", "ColumnsBanners", "Feast"]
const THEMES := {
	"garden": "res://scripts/court/backgrounds/garden/garden_layer.gd",
	"banquet": "res://scripts/court/backgrounds/banquet/banquet_hall_layer.gd",
	"great_hall": "res://scripts/court/backgrounds/great_hall/great_hall_layer.gd",
}
const PLAY_LAYER := preload("res://scenes/backgrounds/play/play_layer.gd")

var _bg := "hall"
var _world: CourtWorld


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bg="):
			_bg = a.substr(5)
	get_window().title = "His Royal Flyness - %s (WASD move, Space/Shift up/down, E scan, F4 camera)" % _bg
	var court: Node = load("res://scenes/Court.tscn").instantiate()
	if THEMES.has(_bg):
		var theme: Script = load(THEMES[_bg])
		for n in LAYER_NODES:
			var node: Node2D = court.get_node("World/" + n)
			var which: String = node.layer
			node.set_script(PLAY_LAYER)
			node.layer = which
			node.theme_script = theme
	add_child(court)
	_world = court.get_node("World")


func _process(_delta: float) -> void:
	if _bg == "great_hall":
		# drive the looming wall shadow from the Giant's descent
		GreatHallBuilder.loom_p = _world._giant_p
		GreatHallBuilder.loom_x = 0.35 if _world._giant_target.x < 0.0 else -0.35
