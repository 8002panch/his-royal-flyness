extends Node2D
## A standalone local audition room. No scripted motion is brain output.
const ROOT := "res://assets/pixelart/animation_v1/"
const IDS := ["hamlet", "miranda", "prospero_nice", "prospero_mad", "helmsman", "liftmaster", "wingmaster", "royal_seer", "lord_tinman", "sir_cheapdate", "count_rutabaga", "clown_jester", "giant"]
const LABELS := ["HAMLET", "MIRANDA", "PROSPERO / KIND", "PROSPERO / MAD", "HELMSMAN", "LIFTMASTER", "WINGMASTER", "ROYAL SEER", "LORD TINMAN", "SIR CHEAPDATE", "COUNT RUTABAGA", "COURT JESTER", "GIANT FIST"]
const CUES := ["wave", "point", "bow", "talk", "approve", "angry", "celebrate", "toast", "confused", "scan", "sing", "hit"]
var actors: Array = []
var back_hamlet: HamletActor
var mode := "fly"
var cue_index := 0
var paused := false
var slow := false
var elapsed := 0.0
var poses := 0
var cpu_usec := 0
var _args := {}
var _shot_started := false
var _tour_step := -1
var director: Node
var _record_frame := 0
var _record_pending := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("f3e9d2"))
	# Audition scene is independent from network and voice processing.
	GameState.set_process(false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var bits := arg.substr(2).split("=",true,1)
			_args[bits[0]] = bits[1] if bits.size() > 1 else "true"
	mode = str(_args.get("mode", "fly"))
	if _args.has("record"):
		DirAccess.make_dir_recursive_absolute(str(_args.record))
	for i in IDS.size():
		var packed: PackedScene = load(ROOT + "rigs/" + IDS[i] + ".scn")
		var actor = packed.instantiate()
		actor.autoplay = false
		add_child(actor)
		var row := i / 7
		var col := i % 7
		actor.position = Vector2(48 + col * 90, 144 + row * 132)
		actor.set_motion(mode, 0.65)
		actors.append(actor)
	back_hamlet = HamletActor.new()
	add_child(back_hamlet)
	back_hamlet.position = Vector2(590,236)
	back_hamlet.set_body_px(48)
	back_hamlet.set_cosmetic("mantle",true)
	if _args.has("cue"): trigger(str(_args.cue))
	if _args.has("timeline"):
		director = load("res://scripts/animation/cue_director.gd").new()
		add_child(director)
		director.set_process(false)
		for actor in actors: director.register_actor(actor.character_id,actor)
		if director.load_cues(ROOT + "example_cues.json"): director.play()
	queue_redraw()

func trigger(cue: String) -> void:
	for actor in actors:
		actor.play_gesture("slam" if actor.giant else cue, 2.2)
	back_hamlet.play_gesture(cue,2.2)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_1: set_mode("idle")
		KEY_2: set_mode("walk")
		KEY_3: set_mode("fly")
		KEY_4: set_mode("land")
		KEY_G:
			trigger(CUES[cue_index])
			cue_index = (cue_index + 1) % CUES.size()
		KEY_SPACE: paused = not paused
		KEY_S: slow = not slow
		KEY_R:
			for actor in actors: actor.motion_scale = 0.35 if actor.motion_scale > 0.5 else 1.0
	queue_redraw()

func set_mode(value: String) -> void:
	mode = value
	for actor in actors: actor.set_motion(mode, 0.65)
	queue_redraw()

func _process(delta: float) -> void:
	if paused: return
	var dt := delta * (0.2 if slow else 1.0)
	elapsed += dt
	if director != null: director.advance(dt)
	if _args.has("tour"):
		var stage := int(elapsed / 3.0) % 4
		if stage != _tour_step:
			_tour_step = stage
			set_mode(["idle","walk","fly","fly"][stage])
			if stage == 3: trigger("wave")
	var start := Time.get_ticks_usec()
	for actor in actors: actor._process(dt)
	back_hamlet.set_motion(Vector3(sin(elapsed * 0.7) * 0.65,0,0.5))
	back_hamlet.tick(dt,24.0,true)
	cpu_usec += Time.get_ticks_usec() - start
	poses += 1
	if _args.has("record") and not _record_pending:
		_record_pending = true
		record_frame()
	if _args.has("shot") and elapsed >= float(_args.get("at","1.0")) and not _shot_started:
		_shot_started = true
		capture()
	if _args.has("bench") and elapsed >= 8.0:
		print("ANIMATION_CPU_US_PER_FRAME=", float(cpu_usec)/maxi(1,poses), " FPS=",Engine.get_frames_per_second()," DRAW_CALLS=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		get_tree().quit()

func capture() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var result := img.save_png(str(_args.shot))
	print("ANIMATION_SCREENSHOT ",result," ",_args.shot)
	get_tree().quit()

func record_frame() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	assert(img.save_png(str(_args.record).path_join("frame_%04d.png" % _record_frame)) == OK)
	_record_frame += 1
	_record_pending = false
	if _record_frame >= int(_args.get("record-frames", "360")):
		_record_pending = true
		print("RECORDED_PNG_FRAMES=",_record_frame," SIZE=",img.get_size())
		get_tree().quit()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0,0,640,360),Color("f3e9d2"))
	draw_rect(Rect2(0,0,640,39),Color("1f3a8a"))
	draw_string(font,Vector2(14,25),"HIS ROYAL FLYNESS / CAST IN MOTION",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f3e9d2"))
	for i in 14:
		var col := i % 7
		var row := i / 7
		var r := Rect2(7+col*90,49+row*132,86,123)
		draw_rect(r,Color("e5d5b7"))
		draw_rect(r,Color("c9a227"),false,1.0)
		draw_line(Vector2(r.position.x+8,r.end.y-26),Vector2(r.end.x-8,r.end.y-26),Color("bcaa88"))
		var label: String = LABELS[i] if i < LABELS.size() else "CHASE HAMLET"
		draw_string(font,Vector2(r.position.x+3,r.end.y-8),label,HORIZONTAL_ALIGNMENT_LEFT,82,8,Color("2b2118"))
	draw_string(font,Vector2(12,326),"1 Idle   2 Walk   3 Fly   4 Land   G Gesture   S Slow   SPACE Pause   R Reduced motion",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("2b2118"))
	draw_string(font,Vector2(12,346),"POSE: " + mode.to_upper() + "    LOCAL ANIMATION PREVIEW / NO BRAIN OUTPUT",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("9b1c1c"))
