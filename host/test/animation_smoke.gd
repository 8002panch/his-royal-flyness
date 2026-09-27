extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var path := "res://assets/pixelart/animation_v1/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path + "manifest.json"))
	assert(manifest.characters.size() == 13)
	var director = load("res://scripts/animation/cue_director.gd").new()
	root.add_child(director)
	director.set_process(false)
	var roster: Array = []
	for entry in manifest.characters:
		var rig = load(path + entry.scene).instantiate()
		rig.autoplay = false
		root.add_child(rig)
		roster.append(rig)
		director.register_actor(entry.id,rig)
		assert(rig.get_node("Pivot").get_child_count() == int(entry.parts))
		for mode in ["idle","walk","takeoff","fly","land"]:
			rig.set_motion(mode,0.7)
			for frame in 40:
				rig._process(1.0/30.0)
				for part in rig.get_node("Pivot").get_children():
					assert(part.transform.is_finite())
			assert(rig.position == Vector2.ZERO,"Animation must not move gameplay root")
		assert(rig.locomotion == "idle","Landing must settle")
		var cues: Array = ["slam","hit"] if rig.giant else rig.GESTURES.filter(func(c): return c != "slam")
		for cue in cues:
			assert(rig.play_gesture(cue,0.5))
			for frame in 20: rig._process(1.0/30.0)
			assert(rig._gesture == "","Gesture must complete")
		assert(not rig.play_gesture("unknown_cue"))
		if not rig.giant:
			rig.set_motion("fly",0.5)
			rig.pose_at(0.02)
			var initial: Transform2D = rig.get_node("Pivot/WingR").transform
			rig.pose_at(0.07)
			assert(initial != rig.get_node("Pivot/WingR").transform,"Flight must actually move the wings")
	assert(director.load_cues(path + "example_cues.json"))
	director.play()
	for frame in 420:
		director.advance(1.0/30.0)
		for rig in roster: rig._process(1.0/30.0)
	assert(not director.running)
	assert(director.cursor == director.cues.size())
	print("PASS: 13 rigs; 5 motion states; all supported gestures; wing transforms; finite transforms; root stability; timeline completion")
	for rig in roster: rig.free()
	director.free()
	quit()
