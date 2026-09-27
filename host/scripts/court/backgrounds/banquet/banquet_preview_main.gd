extends Node

## Standalone preview/screenshot harness for the Trial II Banquet background,
## scenes/backgrounds/banquet_preview.tscn. Renders only the four
## BanquetHallLayer nodes (no actors, no HUD) through the fixed door camera,
## at the project's normal 640x360 -> 1280x720 stretch (project.godot, shared
## with scenes/Court.tscn and not edited here).
##
## Run it:
##   godot --path host scenes/backgrounds/banquet_preview.tscn
##   godot --path host scenes/backgrounds/banquet_preview.tscn -- --shot=host/scripts/court/backgrounds/banquet/preview.png
## `--shot` windows never take keyboard focus, same convention as
## scripts/court/court_main.gd, and the PNG is saved at 1280x720.

@onready var layers: Array = [$Far, $Floor, $Columns, $Feast]

var _anim_t := 0.0
var _anim_step := 0


func _ready() -> void:
	HallCam.chase = false
	HallCam.follow(Vector3.ZERO, 0.0, true)
	var args := _args()
	if args.has("camx") or args.has("camy") or args.has("camz"):
		HallCam.CAM = Vector3(float(args.get("camx", "0")), float(args.get("camy", "1.9")), float(args.get("camz", "-4.5")))
		HallCam.HORIZON = float(args.get("horizon", "34"))
	if args.has("shot"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)
		_run_shot(str(args["shot"]))


func _process(delta: float) -> void:
	_anim_t += delta
	if _anim_t >= 0.12:
		_anim_t = 0.0
		_anim_step += 1
		for l in layers:
			(l as BanquetHallLayer).anim_step = _anim_step


func _run_shot(path: String) -> void:
	# a few frames so every prop texture is cached and the first real
	# draw (not a black startup frame) is what gets saved
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := img.save_png(path)
	print("banquet shot -> %s (%s)" % [path, error_string(err)])
	get_tree().quit()


func _args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var eq := s.find("=")
		if eq >= 0:
			out[s.left(eq)] = s.substr(eq + 1)
		else:
			out[s] = "1"
	return out
