extends Node

## Play-test the Great Hall v2 (Trial III "The Giant's Shadow"): the real Court.tscn
## with its four hall layers swapped for scripts/court/backgrounds_v2/great_hall,
## a frightened cast of animation_v1 rigs at the edges, and the keyboard demo on.
##
##   godot --path host res://scenes/backgrounds_v2/great_hall_play.tscn
##   keys: WASD move, Space/Shift climb/dive, E scan, F4 camera, F3 demo on/off
##
## Test hooks (all optional, after --):
##   --shots=DIR        tour: writes DIR/preview_*.png (1280x720) from scripted Hamlet
##                      positions, camera modes and Giant timings, then quits
##   --snap=FILE        one capture:  --pos=x,y,z  --giant=T (demo giant clock, 0..2.2 falls)
##                      --wait=SECONDS  --fixed (fixed camera)
##   --bare             no cast (background only)

const LAYER_NODES := ["FarBackground", "FloorCarpet", "ColumnsBanners", "Feast"]
const PLAY_LAYER := preload("res://scenes/backgrounds/play/play_layer.gd")
const GH_LAYER := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_layer.gd")
const NPC := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_npc.gd")
const ST := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_state.gd")

## id, hall position (feet), height in hall units, mood, facing, timing offset
const CAST := [
	["count_rutabaga", Vector3(-1.56, -1.3, -0.42), 0.6, "cower", 1.0, 0.0],
	["lord_tinman", Vector3(1.6, -1.3, -0.02), 0.62, "confused", -1.0, 1.1],
	["clown_jester", Vector3(-1.5, -1.3, 1.08), 0.56, "cower", 1.0, 0.5],
	["royal_seer", Vector3(1.48, -1.3, 1.28), 0.62, "scan", -1.0, 0.0],
]

var _court: Node
var _world: CourtWorld
var _npcs: Array = []
var _indy: RivalActor
var _loom := 0.0
var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var eq := s.find("=")
		_args[s.left(eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	# run after the court's own _process so depth order is ours
	process_priority = 50
	get_window().title = "His Royal Flyness - Great Hall v2 (WASD move, Space/Shift up/down, E scan, F4 camera)"
	if _args.has("shots") or _args.has("snap"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	_court = (load("res://scenes/Court.tscn") as PackedScene).instantiate()
	for n in LAYER_NODES:
		var node: Node2D = _court.get_node("World/" + n)
		var which: String = node.layer
		node.set_script(PLAY_LAYER)
		node.layer = which
		node.theme_script = GH_LAYER
		if _args.get("theme", "") == "v1":
			node.theme_script = load("res://scripts/court/backgrounds/great_hall/great_hall_layer.gd")
		elif _args.get("theme", "") == "none":
			node.theme_script = load("res://scenes/backgrounds_v2/blank_layer.gd")
	add_child(_court)
	# the keyboard demo starts on with the court
	if _court._demo == null:
		_court._toggle_demo()
	_world = _court.get_node("World")
	_dress_court()
	if not _args.has("bare"):
		_cast()
	if _args.has("fixed"):
		HallCam.chase = false
	if _args.has("shots"):
		_tour(str(_args["shots"]))
	elif _args.has("snap"):
		_one_shot()


## Sir Indy lurks at the back; Sir Cheapdate's tipsy hiccups don't suit this hall.
func _dress_court() -> void:
	var cheap: Node = _court.get_node("World/Actors/SirCheapdate")
	_world.rivals.erase(cheap)
	cheap.queue_free()
	_indy = _court.get_node("World/Actors/SirIndy")
	_indy.hall_pos = Vector3(1.3, -1.3, 1.46)
	_indy.modulate = Color(0.66, 0.66, 0.78)


func _cast() -> void:
	var seed_i := 0
	for spec in CAST:
		var n: Node2D = NPC.new()
		n.rig_id = spec[0]
		n.hall_pos = spec[1]
		n.height_units = spec[2]
		n.mood = spec[3]
		n.facing = spec[4]
		n.seed_offset = spec[5] + seed_i * 0.37
		seed_i += 1
		_world.actors.add_child(n)
		_npcs.append(n)


func _process(delta: float) -> void:
	if _world == null:
		return
	# the Giant's descent drives the hall: the hand shadow on the back wall, the
	# moonlight, the candles, the courtiers. It fades a little after the hand lands.
	var p := _world._giant_p if _world.giant.showing else 0.0
	_loom = maxf(p, _loom - delta * 1.1)
	ST.loom_p = _loom
	ST.alarm = clampf(_loom * 1.4, 0.0, 1.0)
	if _world.giant.showing:
		ST.loom_x = 1.0 if _world._giant_target.x < 0.0 else -1.0
	for n in _npcs:
		n.tick(delta)
	# Sir Indy prowls back and forth in the gloom by the dais
	if _indy != null and is_instance_valid(_indy):
		_indy.hall_pos.x = 1.3 + sin(Time.get_ticks_msec() / 1000.0 * 0.4) * 0.1
	_sort_actors()


## Depth order for every actor including the cast (far first).
func _sort_actors() -> void:
	var actors: Node2D = _world.actors
	var keyed: Array = []
	for ch in actors.get_children():
		var z := 0.0
		if ch == _world.hamlet:
			z = HallCam.from_server(_world._fly_shown).z
		elif ch == _world.miranda:
			z = _world._princess.z
		elif ch == _world.giant:
			z = _world._giant_target.z if _world.giant.showing else -99.0
		elif ch.has_method("depth"):
			z = ch.depth()
		keyed.append([z, ch])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in keyed.size():
		var node: Node = keyed[i][1]
		if node.get_index() != i:
			actors.move_child(node, i)


# -------------------------------------------------------------- screenshots --

func _one_shot() -> void:
	var demo: Node = await _wait_demo()
	if _args.has("pos"):
		var v: PackedStringArray = str(_args["pos"]).split(",")
		demo.pos = Vector3(float(v[0]), float(v[1]), float(v[2]))
		demo.vel = Vector3.ZERO
	if _args.has("giant"):
		demo._giant_t = float(_args["giant"])
	await get_tree().create_timer(float(_args.get("wait", "2.0"))).timeout
	await _save(str(_args["snap"]))
	get_tree().quit()


func _wait_demo() -> Node:
	while _court._demo == null:
		await get_tree().process_frame
	return _court._demo


func _tour(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var demo: Node = await _wait_demo()
	# name, Hamlet position, demo giant clock, seconds to wait, chase camera
	var stops := [
		["01_idle", Vector3(0.0, -0.2, -0.95), -3.0, 2.0, true],
		["02_giant_falling", Vector3(-0.35, -0.5, -0.5), 0.0, 1.35, true],
		["03_giant_lands", Vector3(0.5, -0.3, -0.2), 1.0, 1.15, true],
		["04_left_low", Vector3(-0.9, -0.9, 0.2), -3.0, 2.0, true],
		["05_right_high", Vector3(0.85, 0.7, 0.55), -3.0, 2.0, true],
		["06_fixed_view", Vector3(0.0, -0.2, -0.95), -3.0, 1.0, false],
		["07_fixed_giant", Vector3(-0.3, -0.4, -0.2), 0.0, 1.5, false],
	]
	for st in stops:
		HallCam.chase = st[4]
		demo.pos = st[1]
		demo.vel = Vector3.ZERO
		demo._giant_t = st[2]
		await get_tree().create_timer(st[3]).timeout
		await _save("%s/preview_%s.png" % [dir, st[0]])
	print("frame ms (process): %.2f" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	get_tree().quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := img.save_png(path)
	var prof: Dictionary = GH_LAYER.prof
	if _args.has("prof"):
		var laps: Dictionary = load("res://scripts/court/backgrounds_v2/great_hall/gh2_paint.gd").laps
		var parts := PackedStringArray()
		for k in laps:
			parts.append("%s=%d" % [k, laps[k]])
		print("laps_us ", " ".join(parts))
	print("shot -> %s (%s) fps=%d proc=%.1fms paint_us far=%d floor=%d columns=%d feast=%d" % [path, error_string(err), Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, prof.get("far", 0), prof.get("floor", 0), prof.get("columns", 0), prof.get("feast", 0)])
