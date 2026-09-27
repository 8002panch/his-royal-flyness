extends Node2D

## Standalone headless preview for the Garden Audience background (Trial I).
## Renders the four GardenLayer layers through the hall's fixed camera and
## saves a 1280x720 PNG, then quits -- same --shot pattern as
## scripts/court/court_main.gd, copied here so this stays a self-contained
## new file and court_main.gd is untouched. Windows opened this way never
## take keyboard focus.
##
## Run (from the his-royal-flyness repo root):
##   Godot-4.3\godot4.3.exe --path host scenes/backgrounds/garden_test.tscn -- --shot=scripts/court/backgrounds/garden/preview.png
##
## Omit --shot to save to that same default path.

const DEFAULT_SHOT := "res://scripts/court/backgrounds/garden/preview.png"


func _ready() -> void:
	var args := _args()
	get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	# match CourtWorld's default: the chase camera, snapped in behind
	# Hamlet's idle position (fixed view is HallCam.chase = false / F4).
	HallCam.chase = not args.has("fixed")
	HallCam.follow(HallCam.from_server(Vector3(0.0, -0.1, -1.0)), 0.0, true)
	# a couple of frames so every layer has painted at least once
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_save_shot(str(args.get("shot", DEFAULT_SHOT)))


func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var out_path := path
	if path.begins_with("res://"):
		out_path = ProjectSettings.globalize_path(path)
	var err := img.save_png(out_path)
	print("garden preview -> %s (%s)" % [out_path, error_string(err)])
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
