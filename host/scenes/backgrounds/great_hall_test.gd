extends Node2D

## Standalone preview/screenshot rig for the Trial III "Great Hall" background
## (host/scripts/court/backgrounds/great_hall/). Not part of the real game
## scene tree: it builds its own small slice (hall layers + shadows + a few
## actors) so the reskin can be judged for readability without touching
## Court.tscn or any file it owns.
##
## Run it:
##   godot --path host res://scenes/backgrounds/great_hall_test.tscn -- --shot=C:/tmp/gh.png
##   godot --path host res://scenes/backgrounds/great_hall_test.tscn        (interactive, animates live)
##
## --shot windows never take keyboard focus (same pattern as court_main.gd).
## --loom=0..1 sets how far the Giant's shadow has loomed in on the back wall
## (default 0.8); --frames=N lets the flicker/sway settle for N ticks first.

@onready var far := $FarBackground
@onready var floor_carpet := $FloorCarpet
@onready var columns := $ColumnsBanners
@onready var feast := $Feast
@onready var shadows: ShadowLayer = $Shadows
@onready var hamlet: HamletActor = $Actors/Hamlet
@onready var rival: RivalActor = $Actors/SirCheapdate
@onready var giant: GiantHand = $Actors/Giant

var _anim_t := 0.0
var _anim_step := 0
## Hamlet mid-hall, camera settled behind him (chase snap): keeps him and the
## feast tables inside the 640x360 frame. The Giant's hand comes down off to
## one side so it does not simply sit on top of him.
var _hamlet_hall := Vector3(0.0, 0.0, -0.6)
var _giant_target := Vector3(0.55, HallCam.FLOOR_Y, 0.5)


func _ready() -> void:
	var args := _args()
	if args.has("shot"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)

	HallCam.chase = true
	HallCam.follow(_hamlet_hall, 0.0, true)

	GreatHallBuilder.loom_p = clampf(float(args.get("loom", "0.8")), 0.0, 1.0)
	GreatHallBuilder.loom_x = 0.55 if _giant_target.x < 0.0 else -0.7

	var hproj := HallCam.project(_hamlet_hall)
	var hh := clampi(roundi(0.78 * hproj.z / 2.0) * 2, 16, 96)
	hamlet.set_body_px(hh)
	hamlet.position = Vector2(roundf(hproj.x), roundf(hproj.y))
	hamlet.set_motion(Vector3(0.2, 0.0, 0.6))

	giant.show_hazard(_giant_target, 0.85)

	var frames := int(args.get("frames", "24"))
	for i in frames:
		_tick(1.0 / 30.0)
		await get_tree().process_frame

	if args.has("shot"):
		_save_shot(str(args["shot"]))


func _process(delta: float) -> void:
	_tick(delta)


func _tick(delta: float) -> void:
	hamlet.tick(delta, 22.0, true)
	rival.tick(delta)

	var gsp := HallCam.project(Vector3(_giant_target.x, HallCam.FLOOR_Y, _giant_target.z))
	var grx := maxi(4, roundi(0.55 * gsp.z * 0.55))
	var hsp := HallCam.project(Vector3(_hamlet_hall.x, HallCam.FLOOR_Y, _hamlet_hall.z))
	shadows.set_items([
		{"pos": Vector2i(roundi(hsp.x), roundi(hsp.y)), "rx": maxi(3, roundi(hamlet.body_px * 0.42)), "ry": 3},
		{"pos": Vector2i(roundi(gsp.x), roundi(gsp.y)), "rx": grx, "ry": maxi(2, roundi(grx * 0.3)), "ring": true},
	])

	_anim_t += delta
	if _anim_t >= 0.12:
		_anim_t = 0.0
		_anim_step += 1
		for l in [far, floor_carpet, columns, feast]:
			(l as GreatHallLayer).anim_step = _anim_step


func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := img.save_png(path)
	print("great_hall shot -> %s (%s)" % [path, error_string(err)])
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
