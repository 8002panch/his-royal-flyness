extends Node2D

## Interactive screen-flow preview for the shared parchment backdrop v2.
## Keys 1-7 (or Left/Right) switch: Lobby, Role Reveal, Prince Intro, Trial
## Intro, Chronicle, Level Lab, Royal Decree. Each is drawn over its own
## ParchmentV2 variant with the real animation_v1 rigs idling/gesturing.
##
##   godot --path host res://scenes/backgrounds_v2/parchment_play.tscn
##   ... -- --screen=5                     start on screen 5
##   ... -- --shotdir=C:/tmp/shots         write shot_1..7.png (1280x720) and quit
##   ... -- --shot=C:/tmp/a.png --screen=3 single shot

const RIGS := "res://assets/pixelart/animation_v1/rigs/"
const SCREENS := ["lobby", "role", "prince", "trial", "chronicle", "lab", "decree"]
const TITLES := ["Lobby", "Role Reveal", "Prince Intro", "Trial Intro", "Chronicle", "Level Lab", "Royal Decree"]

var idx := 0
var _tex := {}
var _panels: Node2D
var _actors: Node2D
var _live: Node2D
var _actor_list: Array = []
var _t := 0.0
var _args := {}
var _gesture_clock := 0.0
var _role_i := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a).trim_prefix("--")
		var eq := s.find("=")
		_args[s.left(eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	if _args.has("shot") or _args.has("shotdir"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	if GameState:
		GameState.set_process(false)
	RenderingServer.set_default_clear_color(Pal.INK)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_panels = Node2D.new()
	_actors = Node2D.new()
	_live = Node2D.new()
	add_child(_panels)
	add_child(_actors)
	add_child(_live)
	_panels.draw.connect(_draw_screen.bind(_panels))
	_live.draw.connect(_draw_live.bind(_live))
	idx = clampi(int(_args.get("screen", "1")) - 1, 0, 6)
	_switch(idx)
	get_window().title = "His Royal Flyness - parchment v2 (1-7 / Left / Right)"
	if _args.has("shotdir"):
		_shot_all()
	elif _args.has("shot"):
		await _settle(1.4)
		_save(str(_args.shot))
		get_tree().quit()


func _settle(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot_all() -> void:
	DirAccess.make_dir_recursive_absolute(str(_args.shotdir))
	for i in 7:
		_switch(i)
		await _settle(1.6)
		_save("%s/shot_%d_%s.png" % [_args.shotdir, i + 1, SCREENS[i]])
	get_tree().quit()


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	print("shot -> ", path, " ", error_string(img.save_png(path)))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode >= KEY_1 and e.keycode <= KEY_7:
			_switch(e.keycode - KEY_1)
		elif e.keycode == KEY_RIGHT:
			_switch((idx + 1) % 7)
		elif e.keycode == KEY_LEFT:
			_switch((idx + 6) % 7)


func _switch(i: int) -> void:
	idx = i
	var v: String = SCREENS[i]
	if not _tex.has(v):
		_tex[v] = ParchmentV2.paint(v).texture()
	for a in _actor_list:
		a.queue_free()
	_actor_list.clear()
	_role_i = 0
	_spawn_for(v)
	queue_redraw()
	_panels.queue_redraw()


func _draw() -> void:
	draw_texture(_tex[SCREENS[idx]], Vector2.ZERO)


func _process(delta: float) -> void:
	_t += delta
	_gesture_clock += delta
	if _gesture_clock > 2.6:
		_gesture_clock = 0.0
		_cycle_gestures()
	_panels.queue_redraw()
	_live.queue_redraw()


# --------------------------------------------------------------- actors --

func _rig(id: String, pos: Vector2, s: float, facing := 1.0, mode := "idle") -> Node2D:
	var a: Node2D = (load(RIGS + id + ".scn") as PackedScene).instantiate()
	_actors.add_child(a)
	a.position = pos
	a.scale = Vector2(s, s)
	a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	a.set_motion(mode, 0.5, facing)
	_actor_list.append(a)
	return a


func _spawn_for(v: String) -> void:
	match v:
		"lobby":
			var roles := ["helmsman", "liftmaster", "wingmaster", "royal_seer"]
			for i in 4:
				_rig(roles[i], Vector2(162 + i * 106, 226), 0.5)
		"role":
			_role_i = 0
			_rig("helmsman", Vector2(320, 212), 1.5)
		"prince":
			_rig("hamlet", Vector2(190, 286), 1.5)
		"trial":
			var roles := ["helmsman", "liftmaster", "wingmaster", "royal_seer"]
			for i in 4:
				_rig(roles[i], Vector2(170 + i * 100, 302), 0.55, 1.0 if i < 2 else -1.0)
		"chronicle":
			_rig("clown_jester", Vector2(486, 282), 0.62, -1.0)
		"lab":
			_rig("miranda", Vector2(536, 312), 0.62, -1.0)
			_rig("lord_tinman", Vector2(112, 314), 0.5)
		"decree":
			_rig("prospero_nice", Vector2(118, 300), 1.2)
			_rig("count_rutabaga", Vector2(526, 310), 0.5, -1.0)


func _cycle_gestures() -> void:
	var cues := {
		"lobby": ["wave", "talk", "approve", "toast"], "role": ["wave", "celebrate", "approve", "bow"],
		"prince": ["point", "talk", "wave", "confused"], "trial": ["celebrate", "toast", "approve", "sing"],
		"chronicle": ["bow", "point", "sing", "confused"], "lab": ["point", "scan", "talk", "approve"],
		"decree": ["talk", "point", "angry", "bow"]}
	var v: String = SCREENS[idx]
	var list: Array = cues[v]
	var n := 0
	for a in _actor_list:
		var cue: String = list[(int(_t / 2.6) + n) % list.size()]
		if v == "lobby" or v == "trial":
			if (int(_t / 2.6) + n) % 2 == 0:
				a.play_gesture(cue, 1.6)
		else:
			a.play_gesture(cue, 1.8)
		n += 1
	if v == "role":
		_role_i = (_role_i + 1) % 4
		var ids := ["helmsman", "liftmaster", "wingmaster", "royal_seer"]
		var old: Node2D = _actor_list[0]
		_actor_list.clear()
		old.queue_free()
		_rig(ids[_role_i], Vector2(320, 212), 1.5)


# --------------------------------------------------------------- drawing --

func _draw_screen(ci: Node2D) -> void:
	match SCREENS[idx]:
		"lobby": _s_lobby(ci)
		"role": _s_role(ci)
		"prince": _s_prince(ci)
		"trial": _s_trial(ci)
		"chronicle": _s_chronicle(ci)
		"lab": _s_lab(ci)
		"decree": _s_decree(ci)


func _title(ci: Node2D, y: int, s: String, sub: String, sub_col: Color = Pal.CRIMSON) -> void:
	HudDraw.text_center(ci, PixelFonts.title(), 320, y, s, Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, y + 24, sub, sub_col, PixelFonts.LABEL_SIZE)
	LobbyOverlay._flourish(ci, 320, y + 38, 150)


func _s_lobby(ci: Node2D) -> void:
	var r := Rect2i(100, 34, 440, 282)
	LobbyOverlay._scroll(ci, r)
	_title(ci, 42, "His Royal Flyness", "THE ROYAL BALL OF THE FRUIT BOWL")
	HudDraw.text_center(ci, PixelFonts.bold(), 170, 90, "PRESENT YOUR SEAL", Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.tex_center(ci, SpriteForge.wax_seal(30), Vector2i(170, 132))
	HudDraw.text_center(ci, PixelFonts.bold(), 170, 124, "K7QP", Pal.PARCHMENT, 16)
	HudDraw.text_center(ci, PixelFonts.label(), 170, 166, "ROOM CODE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	var x := 250
	HudDraw.text(ci, PixelFonts.bold(), x, 96, "JOIN ON YOUR PHONE", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	var steps := ["OPEN THE CONTROLLER PAGE", "ENTER THE SEAL  K7QP", "PICK A SEAT BELOW"]
	for i in 3:
		var y := 112 + i * 16
		ci.draw_rect(Rect2(x, y - 1, 11, 11), Pal.INK)
		ci.draw_rect(Rect2(x + 1, y, 9, 9), Pal.GOLD)
		HudDraw.text(ci, PixelFonts.bold(), x + 3, y + 1, str(i + 1), Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text(ci, PixelFonts.label(), x + 16, y + 1, steps[i], Pal.INK, PixelFonts.LABEL_SIZE)
	_qr(ci, Vector2i(452, 90), 64)
	var names := ["ADA", "BO", "", "DI"]
	var roles: Array = Pal.ROLE_ORDER
	var hints := ["LEFT / RIGHT", "CLIMB / DIVE", "FORTH / BRAKE", "HOLD TO SCAN"]
	for i in 4:
		var bx := 112 + i * 106
		var by := 184
		var filled: bool = names[i] != ""
		HudDraw.panel(ci, Rect2i(bx, by, 100, 82), Pal.PARCHMENT if filled else Pal.PARCHMENT_DARK, Pal.INK,
			Pal.GOLD if filled else Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		# crest ledge under the rig's feet
		ci.draw_rect(Rect2(bx + 20, by + 42, 60, 2), Pal.INK)
		ci.draw_rect(Rect2(bx + 21, by + 43, 58, 1), Pal.GOLD if filled else Pal.PARCHMENT_SHADE)
		HudDraw.text_center(ci, PixelFonts.bold(), bx + 50, by + 48, Pal.role_title(roles[i]), Pal.role_color(roles[i]) if filled else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.text_center(ci, PixelFonts.label(), bx + 50, by + 59, names[i] if filled else "OPEN SEAT", Pal.INK if filled else Pal.PARCHMENT_SHADE, PixelFonts.LABEL_SIZE)
		HudDraw.text_center(ci, PixelFonts.label(), bx + 50, by + 68, hints[i], Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 272, "3 OF 4 SEATS TAKEN", Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 287, "THE SEER'S CUES GO ONLY TO THE SEER'S PHONE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	# the fourth (empty) seat's rig stays dim until someone sits
	if _actor_list.size() > 2:
		_actor_list[2].modulate = Color(1, 1, 1, 0.45)


static func _qr(ci: CanvasItem, at: Vector2i, sz: int) -> void:
	ci.draw_rect(Rect2(at.x - 3, at.y - 3, sz + 6, sz + 6), Pal.INK)
	ci.draw_rect(Rect2(at.x - 2, at.y - 2, sz + 4, sz + 4), Pal.PARCHMENT)
	var n := 16
	var cell := sz / n
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for gy in n:
		for gx in n:
			var finder := (gx < 5 and gy < 5) or (gx > n - 6 and gy < 5) or (gx < 5 and gy > n - 6)
			var on := rng.randf() < 0.48
			if finder:
				var fx := gx % (n - 5) if gx > n - 6 else gx
				var fy := gy - (n - 5) if gy > n - 6 else gy
				on = fx == 0 or fx == 4 or fy == 0 or fy == 4 or (fx == 2 and fy == 2)
			if on:
				ci.draw_rect(Rect2(at.x + gx * cell, at.y + gy * cell, cell, cell), Pal.INK)
	HudDraw.text_center(ci, PixelFonts.label(), at.x + sz / 2, at.y + sz + 6, "SCAN ME", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _s_role(ci: Node2D) -> void:
	var ids := ["helmsman", "liftmaster", "wingmaster", "seer"]
	var role: String = ids[_role_i]
	HudDraw.tex_center(ci, SpriteForge.role_icon(role, true), Vector2i(62, 62))
	var duty := {"helmsman": "STEER THE PRINCE LEFT AND RIGHT", "liftmaster": "CLIMB AND DIVE ON THE BEAT",
		"wingmaster": "FORTH TO FLY, BRAKE TO STOP", "seer": "HOLD TO SCAN; TELL ONLY YOUR COUNCIL"}
	var r := Rect2i(200, 34, 240, 282)
	LobbyOverlay._scroll(ci, r)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, 44, "YOUR ROLE IN THE COUNCIL", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	LobbyOverlay._flourish(ci, 320, 58, 90)
	# card platform
	HudDraw.panel(ci, Rect2i(240, 66, 160, 160), Pal.PARCHMENT, Pal.INK, Pal.role_color(role), Pal.PARCHMENT_DARK)
	HudDraw.frame(ci, Rect2i(244, 70, 152, 152), Pal.GOLD)
	ci.draw_rect(Rect2(268, 216, 104, 2), Pal.INK)
	HudDraw.text_center(ci, PixelFonts.title(), 320, 232, Pal.role_title(role), Pal.role_color(role), PixelFonts.TITLE_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 258, duty[role].left(30), Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 272, "ROLES ROTATE EVERY TRIAL", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	for i in 4:
		var on := i == _role_i
		var cx := 268 + i * 35
		ci.draw_rect(Rect2(cx, 296, 9, 9), Pal.INK)
		ci.draw_rect(Rect2(cx + 1, 297, 7, 7), Pal.GOLD if on else Pal.PARCHMENT_DARK)


func _s_prince(ci: Node2D) -> void:
	var r := Rect2i(104, 44, 480, 262)
	LobbyOverlay._scroll(ci, r)
	HudDraw.text(ci, PixelFonts.title(), 272, 60, "Meet the Prince", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text(ci, PixelFonts.bold(), 272, 84, "HIS ROYAL FLYNESS, HAMLET THE FIRST", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	LobbyOverlay._flourish(ci, 402, 98, 120)
	HudDraw.tex_center(ci, SpriteForge.crown(), Vector2i(66, 66))
	var lines := ["HE MUST REACH THE COURT BEFORE THE FEAST ENDS.", "YOU ARE HIS COUNCIL. HE CANNOT STEER HIMSELF.", "ONE OF YOU SEES THE ROUTE. THE REST OBEY."]
	for i in 3:
		HudDraw.text(ci, PixelFonts.label(), 272, 112 + i * 15, lines[i], Pal.INK, PixelFonts.LABEL_SIZE)
	_chart(ci, Rect2i(300, 168, 240, 108))
	# Hamlet's platform: a rolled rug
	ci.draw_rect(Rect2(110, 286, 160, 6), Pal.INK)
	ci.draw_rect(Rect2(111, 287, 158, 4), Pal.CRIMSON)
	ci.draw_rect(Rect2(111, 287, 158, 1), Pal.CRIMSON_LIGHT)


func _chart(ci: Node2D, r: Rect2i) -> void:
	ci.draw_rect(Rect2(r.position.x - 3, r.position.y - 3, r.size.x + 6, r.size.y + 6), Pal.INK)
	ci.draw_rect(Rect2(r.position.x - 2, r.position.y - 2, r.size.x + 4, r.size.y + 4), Pal.WOOD_LIGHT)
	ci.draw_rect(Rect2(r), Pal.PARCHMENT_DARK)
	for i in 6:
		ci.draw_rect(Rect2(r.position.x + 4 + i * 40, r.position.y + 4, 1, r.size.y - 8), Pal.PARCHMENT_SHADE)
	for i in 4:
		ci.draw_rect(Rect2(r.position.x + 4, r.position.y + 6 + i * 26, r.size.x - 8, 1), Pal.PARCHMENT_SHADE)
	# generic flourish map, no real route: coastline blobs and a compass
	for b in [Vector2(40, 40), Vector2(120, 70), Vector2(190, 30)]:
		ci.draw_circle(Vector2(r.position) + b, 17, Pal.PARCHMENT_SHADE)
		ci.draw_circle(Vector2(r.position) + b + Vector2(-1, -1), 14, Pal.GOLD_DARK.lerp(Pal.PARCHMENT_DARK, 0.6))
	HudDraw.tex_center(ci, SpriteForge.compass_rose(28), Vector2i(r.position.x + r.size.x - 26, r.position.y + 26))
	HudDraw.tex_center(ci, SpriteForge.crown(), Vector2i(r.position.x + 30, r.position.y + r.size.y - 22))
	HudDraw.text_center(ci, PixelFonts.label(), r.position.x + r.size.x / 2, r.position.y + r.size.y - 14, "THE KINGDOM (NOT TO SCALE)", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _s_trial(ci: Node2D) -> void:
	HudDraw.tex_center(ci, SpriteForge.crown(), Vector2i(62, 62))
	var trial := ["THE FIRST TRIAL", "THE JOURNEY TO THE COURT"]
	ci.draw_rect(Rect2(150, 96, 340, 148), Pal.INK)
	ci.draw_rect(Rect2(152, 98, 336, 144), Pal.PARCHMENT)
	ci.draw_rect(Rect2(156, 102, 328, 136), Pal.PARCHMENT_DARK)
	HudDraw.frame(ci, Rect2i(158, 104, 324, 132), Pal.GOLD)
	HudDraw.frame(ci, Rect2i(160, 106, 320, 128), Pal.INK)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, 116, "TRIAL  I", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.title(), 320, 136, trial[0], Pal.INK, PixelFonts.TITLE_SIZE)
	LobbyOverlay._flourish(ci, 320, 162, 100)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, 174, trial[1], Pal.ROYAL, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 194, "GET THE PRINCE THROUGH THE BASEMENT ALIVE", Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 208, "TIME LIMIT  02:30", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	for i in 4:
		var cx := 170 + i * 100
		ci.draw_rect(Rect2(cx - 24, 302, 48, 2), Pal.INK)
		ci.draw_rect(Rect2(cx - 23, 303, 46, 1), Pal.GOLD)


func _s_chronicle(ci: Node2D) -> void:
	var r := Rect2i(76, 32, 488, 288)
	LobbyOverlay._scroll(ci, r)
	HudDraw.text_center(ci, PixelFonts.title(), 320, 40, "The Chronicle", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, 63, "TRIAL ONE  -  TRUE PRINCE", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	LobbyOverlay._flourish(ci, 320, 76, 170)
	var rows := [["ADA", "helmsman", 0.46, "STEERED CLEAR OF SPIKES 3 TIMES"], ["BO", "liftmaster", 0.31, "CLIMBED AT THE LAST SECOND"], ["DI", "seer", 0.23, "SCANNED THE BRIDGE"]]
	var y := 88
	for row in rows:
		HudDraw.tex(ci, SpriteForge.role_icon(row[1] if row[1] != "seer" else "seer", true), Vector2i(92, y + 2))
		HudDraw.text(ci, PixelFonts.bold(), 114, y + 1, row[0], Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text(ci, PixelFonts.label(), 114, y + 11, Pal.role_title(row[1]), Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.bar(ci, Rect2i(200, y + 3, 120, 8), row[2], Pal.role_color(row[1]))
		HudDraw.text(ci, PixelFonts.bold(), 326, y + 3, "%d%%" % roundi(row[2] * 100.0), Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text(ci, PixelFonts.label(), 200, y + 14, row[3], Pal.ROYAL, PixelFonts.LABEL_SIZE)
		y += 34
	HudDraw.panel(ci, Rect2i(392, 88, 156, 70), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.frame(ci, Rect2i(393, 89, 154, 68), Pal.GOLD)
	HudDraw.tex(ci, SpriteForge.crown(), Vector2i(400, 96))
	HudDraw.text(ci, PixelFonts.bold(), 414, 97, "KNIGHT OF THE REALM", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.title(), 470, 108, "Ada", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 470, 140, "46% OF THE CREDIT", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.panel(ci, Rect2i(392, 166, 156, 66), Pal.PARCHMENT, Pal.INK, Pal.CRIMSON, Pal.PARCHMENT_DARK)
	HudDraw.tex(ci, SpriteForge.splat(4), Vector2i(398, 170))
	HudDraw.text(ci, PixelFonts.bold(), 418, 175, "THE BLUNDER", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.title(), 470, 186, "Bo", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 470, 216, "DIVED INTO A SOUP AT 41.2 S", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text(ci, PixelFonts.label(), 100, 282, "THE CHRONICLER NOTES THE SOUP WAS, IN FACT, OUTSTANDING.", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _s_lab(ci: Node2D) -> void:
	var r := Rect2i(76, 34, 488, 282)
	LobbyOverlay._scroll(ci, r)
	_title(ci, 42, "The Level Lab", "PICK A TRIAL TO TEST-FLY")
	var cards := ["1  BASEMENT", "2  PASSAGE", "3  BANQUET", "4  GIANT", "5  GARDEN", "6  PROSPERO"]
	var sel := int(_t / 1.5) % 6
	for i in 6:
		var bx := 98 + (i % 3) * 98
		var by := 100 + (i / 3) * 78
		var on := i == sel
		HudDraw.panel(ci, Rect2i(bx, by, 92, 68), Pal.PARCHMENT if on else Pal.PARCHMENT_DARK, Pal.INK, Pal.ROYAL if on else Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		ci.draw_rect(Rect2(bx + 8, by + 8, 76, 34), Pal.STONE_DARK if i % 2 == 0 else Pal.VAULT)
		ci.draw_rect(Rect2(bx + 8, by + 30, 76, 12), Pal.FLOOR_A)
		ci.draw_rect(Rect2(bx + 8, by + 8, 76, 2), Pal.GOLD if on else Pal.STONE_LIGHT)
		HudDraw.text_center(ci, PixelFonts.bold(), bx + 46, by + 50, cards[i], Pal.ROYAL if on else Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.text(ci, PixelFonts.bold(), 410, 102, "TEST OPTIONS", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	var opts := ["CAMERA  CHASE", "SEER CUES  ON", "GIANT  HARD", "SEED  1337"]
	for i in 4:
		ci.draw_rect(Rect2(410, 118 + i * 16, 9, 9), Pal.INK)
		ci.draw_rect(Rect2(411, 119 + i * 16, 7, 7), Pal.GOLD if i != 2 else Pal.PARCHMENT_DARK)
		HudDraw.text(ci, PixelFonts.label(), 424, 118 + i * 16, opts[i], Pal.INK, PixelFonts.LABEL_SIZE)


func _s_decree(ci: Node2D) -> void:
	HudDraw.tex_center(ci, SpriteForge.wax_seal(14), Vector2i(66, 66))
	var r := Rect2i(190, 40, 260, 262)
	LobbyOverlay._scroll(ci, r)
	HudDraw.text_center(ci, PixelFonts.bold(), 320, 52, "BY ORDER OF THE KING", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.title(), 320, 68, "Royal Decree", Pal.INK, PixelFonts.TITLE_SIZE)
	LobbyOverlay._flourish(ci, 320, 94, 90)
	var lines := ["THE COUNCIL HAS SERVED THE CROWN", "WITH BUZZING AND BLUNDER ALIKE.", "THE PRINCE IS HEREBY RETURNED,", "MOSTLY WHOLE, TO THE FRUIT BOWL.", "LET THE FEAST COMMENCE."]
	for i in lines.size():
		HudDraw.text_center(ci, PixelFonts.label(), 320, 108 + i * 15, lines[i], Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.tex_center(ci, SpriteForge.wax_seal(20), Vector2i(320, 232))
	HudDraw.tex_center(ci, SpriteForge.crown(), Vector2i(320, 232))
	HudDraw.text_center(ci, PixelFonts.label(), 320, 262, "SEALED  &  SIGNED", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(ci, PixelFonts.label(), 320, 276, "PROSPERO, KING", Pal.CRIMSON, PixelFonts.LABEL_SIZE)


# ------------------------------------------------------------ live bits --

## Crawling margin insects and a ink-well glint, drawn per frame.
func _draw_live(ci: Node2D) -> void:
	for k in 4:
		var u := fposmod(_t * (4.0 + k * 1.3) + k * 130.0, 2.0 * (W_ - 90) + 2.0 * (H_ - 90))
		var p := _perimeter(u, 19.0 + (k % 2) * 3.0)
		var step := int(_t * 6.0 + k) % 2
		# a paused crawler every so often
		var moving := int(_t * 0.5 + k * 3) % 3 != 0
		if not moving:
			p = _perimeter(fposmod(_t * 0.0 + k * 200.0, 2.0 * (W_ - 90) + 2.0 * (H_ - 90)), 19.0)
			step = 0
		ci.draw_rect(Rect2(p.x - 2, p.y - 1, 5, 3), Pal.INK)
		ci.draw_rect(Rect2(p.x - 1, p.y, 3, 1), Pal.INK_SOFT)
		ci.draw_rect(Rect2(p.x - 1, p.y + 2 + step, 1, 1), Pal.INK)
		ci.draw_rect(Rect2(p.x + 1, p.y + 2 + (1 - step), 1, 1), Pal.INK)
		ci.draw_rect(Rect2(p.x - 1, p.y - 2, 3, 1), Pal.PARCHMENT_SHADE)

const W_ := 640
const H_ := 360


func _perimeter(u: float, inset: float) -> Vector2:
	var w := W_ - 90.0
	var h := H_ - 90.0
	if u < w:
		return Vector2(45 + u, inset)
	u -= w
	if u < h:
		return Vector2(W_ - inset, 45 + u)
	u -= h
	if u < w:
		return Vector2(W_ - 45 - u, H_ - inset)
	u -= w
	return Vector2(inset, H_ - 45 - u)



