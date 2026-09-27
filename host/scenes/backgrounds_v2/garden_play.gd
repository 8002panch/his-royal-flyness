extends Node

## Play-test the Garden v2 background with the real court and the keyboard demo.
##   godot --path host res://scenes/backgrounds_v2/garden_play.tscn -- --demo
##   screenshots: add  --live_shot=C:/tmp/g.png --after=6   (do not use --headless)
##   optional:  --hx=0.5 --hy=0 --hz=0.2   start Hamlet elsewhere (demo driver pos)
## Instances the real Court.tscn, swaps its four hall layers for the v2 garden
## layers, and adds a Scenery node (animated NPC rigs) just behind the actors.

const LAYER_NODES := ["FarBackground", "FloorCarpet", "ColumnsBanners", "Feast"]
const THEME := preload("res://scripts/court/backgrounds_v2/garden/garden2_layer.gd")
const PLAY_LAYER := preload("res://scenes/backgrounds/play/play_layer.gd")
const SCENERY := preload("res://scripts/court/backgrounds_v2/garden/garden2_scenery.gd")

var _court: Node


func _ready() -> void:
	if "--fixed" in OS.get_cmdline_user_args():
		HallCam.chase = false
	get_window().title = "His Royal Flyness - Garden v2 (WASD move, Space/Shift up/down, E scan, F4 camera)"
	_court = load("res://scenes/Court.tscn").instantiate()
	for n in LAYER_NODES:
		var node: Node2D = _court.get_node("World/" + n)
		var which: String = node.layer
		node.set_script(PLAY_LAYER)
		node.layer = which
		node.theme_script = THEME
	# the two rival suitors were perched on feast tables; stand them on the lawn instead
	var cheap: Node2D = _court.get_node("World/Actors/SirCheapdate")
	cheap.hall_pos = Vector3(-1.75, -1.3, 0.75)
	var indy: Node2D = _court.get_node("World/Actors/SirIndy")
	indy.hall_pos = Vector3(2.0, -1.3, 0.75)
	var world: Node2D = _court.get_node("World")
	var scenery := SCENERY.new()
	scenery.name = "Scenery"
	world.add_child(scenery)
	world.move_child(scenery, world.get_node("Feast").get_index() + 1)
	add_child(_court)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hx=") or a.begins_with("--hy=") or a.begins_with("--hz="):
			_apply_start.call_deferred()
			break


func _apply_start() -> void:
	# demo driver is created by court_main when --demo is given; nudge its position
	await get_tree().process_frame
	await get_tree().process_frame
	var demo: Node = _court._demo
	if demo == null:
		return
	var p: Vector3 = demo.pos
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hx="):
			p.x = float(a.substr(5))
		elif a.begins_with("--hy="):
			p.y = float(a.substr(5))
		elif a.begins_with("--hz="):
			p.z = float(a.substr(5))
	demo.pos = p


var _fps_t := 0.0


func _process(delta: float) -> void:
	# `--fps` prints the frame rate once a second (perf check)
	if "--fps" in OS.get_cmdline_user_args():
		_fps_t += delta
		if _fps_t >= 1.0:
			_fps_t = 0.0
			print("FPS ", Engine.get_frames_per_second())
