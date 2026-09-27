extends Node

## Play-test the Banquet v2 background with the keyboard demo: instances the
## real Court.tscn, swaps its four hall layers for the v2 layers, replaces the
## v1 rivals with the animated cast, and starts the WASD demo.
##
##   godot --path host res://scenes/backgrounds_v2/banquet_play.tscn -- --demo
##
## Screenshot/test options (all optional, `--` user args):
##   --live_shot=PATH --after=SEC   court's own screenshot mode (see court_main.gd)
##   --hx= --hy= --hz=              start Hamlet at this fly position (-1..1 each)
##   --nogiant                      never drop the Giant's hand (clean shots)
##   --nohud                        hide the HUD (background-only shots)
##   --fixed                        the fixed door camera instead of the chase cam

const LAYER_NODES := ["FarBackground", "FloorCarpet", "ColumnsBanners", "Feast"]
const THEME := preload("res://scripts/court/backgrounds_v2/banquet/bq_layer.gd")
const PLAY_LAYER := preload("res://scenes/backgrounds/play/play_layer.gd")
const CAST := preload("res://scripts/court/backgrounds_v2/banquet/bq_cast.gd")

var _args := {}
var _court: Node
var _demo: DemoDriver


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var eq := s.find("=")
		_args[s.left(eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	get_window().title = "His Royal Flyness - The Banquet v2 (WASD move, Space/Shift up/down, E scan, F4 camera)"
	_court = load("res://scenes/Court.tscn").instantiate()
	for n in LAYER_NODES:
		var node: Node2D = _court.get_node("World/" + n)
		var which: String = node.layer
		node.set_script(PLAY_LAYER)
		node.layer = which
		node.theme_script = load("res://scripts/court/backgrounds/banquet/banquet_hall_layer.gd") if _args.has("v1") else THEME
	add_child(_court)
	var cast: Node = CAST.new()
	add_child(cast)
	if not _args.has("v1"):
		cast.attach(_court)
	if _args.has("nohud"):
		_court.get_node("Hud").visible = false
	if _args.has("fixed"):
		HallCam.chase = false
	for ch in _court.get_children():
		if ch is DemoDriver:
			_demo = ch
	if _demo != null:
		if _args.has("hx") or _args.has("hy") or _args.has("hz"):
			_demo.pos = Vector3(float(_args.get("hx", "0")), float(_args.get("hy", "-0.2")), float(_args.get("hz", "-0.95")))
		if _args.has("nogiant"):
			_demo._giant_t = -100000.0


# ---- optional scripted flight, for movement tests: --play=W:1.5,D:1.0,SPACE:0.8
# holds each key for the given seconds, one after another, then lets go.
var _play: Array = []
var _play_t := 0.0
var _held: Key = KEY_NONE
var _frames := 0


func _process(delta: float) -> void:
	_frames += 1
	if _args.has("fps") and _frames % 120 == 0:
		print("fps ", Engine.get_frames_per_second())
	if not _args.has("play"):
		return
	if _play.is_empty() and _play_t == 0.0:
		for seg in str(_args["play"]).split(","):
			var bits := seg.split(":")
			_play.append([bits[0].to_upper(), float(bits[1])])
	_play_t += delta
	var acc := 0.0
	var want: Key = KEY_NONE
	for seg in _play:
		acc += float(seg[1])
		if _play_t < acc:
			want = {"W": KEY_W, "A": KEY_A, "S": KEY_S, "D": KEY_D, "SPACE": KEY_SPACE, "SHIFT": KEY_SHIFT}.get(seg[0], KEY_NONE)
			break
	if want != _held:
		if _held != KEY_NONE:
			_key(_held, false)
		if want != KEY_NONE:
			_key(want, true)
		_held = want


func _key(k: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = k
	ev.keycode = k
	ev.pressed = down
	Input.parse_input_event(ev)
