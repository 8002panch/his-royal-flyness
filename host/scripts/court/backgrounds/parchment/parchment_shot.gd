extends Node2D

## Standalone preview/screenshot harness for the parchment backdrop only.
## Independent from GameState, Court.tscn and every other screen; touches
## nothing outside this folder. Shot windows never take keyboard focus
## (host/README.md's pattern).
##
## Run it:
##   godot --path host res://scenes/backgrounds/parchment_preview.tscn
##   godot --path host res://scenes/backgrounds/parchment_preview.tscn -- --shot=C:/tmp/parchment.png
##   -- --accent=gold|crimson|royal   which Pal color tints the border/fleurons/drop-cap (default gold)
##   -- --dropcap                     show the illuminated drop-cap frame variant
##   -- --plain                       hide the sample title/panel, backdrop only
## The PNG is saved at 1280x720, matching every other court screenshot.

var _args := {}
var backdrop: ParchmentBackdropNode
var content: ParchmentPreviewContent


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var s := str(arg).trim_prefix("--")
		var eq := s.find("=")
		if eq >= 0:
			_args[s.left(eq)] = s.substr(eq + 1)
		else:
			_args[s] = "1"
	if _args.has("shot"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	RenderingServer.set_default_clear_color(Pal.INK)

	var accent := _accent_from(str(_args.get("accent", "gold")))
	var drop_cap := _args.has("dropcap")

	backdrop = ParchmentBackdropNode.new()
	backdrop.accent = accent
	backdrop.drop_cap = drop_cap
	add_child(backdrop)

	if not _args.has("plain"):
		content = ParchmentPreviewContent.new()
		content.accent = accent
		content.caption = "accent=%s  drop_cap=%s" % [str(_args.get("accent", "gold")).to_upper(), drop_cap]
		add_child(content)

	if _args.has("shot"):
		await get_tree().process_frame
		await get_tree().process_frame
		_save_shot(str(_args["shot"]))


func _accent_from(name: String) -> Color:
	match name:
		"crimson":
			return Pal.CRIMSON
		"royal":
			return Pal.ROYAL
		_:
			return Pal.GOLD


func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := img.save_png(path)
	print("parchment shot -> %s (%s)" % [path, error_string(err)])
	get_tree().quit()
