extends Node

## Root of scenes/Court.tscn, the pixel-art main screen (640x360, scaled 2x
## to 1280x720 with nearest-neighbour filtering; see project.godot).
##
## Data in: GameState's `state_updated` / `event_received` signals, unchanged.
## This scene only reads them (through CourtState) and never sends anything.
##
## Keys: 1/2/3 toggle Hamlet's Reliquary relics (cosmetic, local only),
##       F1 debug waveforms, F2 the old dashboard (scenes/Main.tscn), F11 fullscreen.
##       F3 keyboard demo (WASD, no server or phones; see demo_driver.gd),
##       F4 chase camera (default) / fixed view from the doors.
##       F6 the Royal Decree (the honesty panel): opens, turns the page, closes.
## Story (server/campaign.py; the presenter's controls, never an answer): Enter starts from the lobby or the end card, and
##       otherwise moves on, like Space, Right and Page Down (a clicker); Left or Page Up rereads; S skips a comic (it stops at an
##       unanswered question); R restarts a stage; Ctrl+1..9 jumps to a chapter for judging (marked DEMO).
##       `-- --debug` opens with the F1 overlay showing; `-- --demo` starts in the keyboard demo.
##
## Screenshot mode renders one screen from the host/test fixtures and quits:
##   godot --path host -- --screen=trial --frame=180 --shot=C:/tmp/trial.png
##   --screen = lobby | trial | chronicle; --frame picks the fixture frame (trial);
##   --relics=123 wears relics 1-3; --event=splat|jump|win fires one FX event; --decree=1|2 opens the Decree at that page.
##   The PNG is saved at 1280x720. Shot windows never take keyboard focus.
##   `-- --live_shot=C:/tmp/live.png --after=6` captures the normal GameState
##   pipeline (live server or fallback) instead. `-- --dashboard` opens the old dashboard.

const DASHBOARD := "res://scenes/Main.tscn"
const VOICE_PLAYER := "res://scripts/voice_player.gd"
const SEQUENCE := "res://test/sample_sequence.json"
const EVENTS := "res://test/sample_events.json"
const LOBBY := "res://test/sample_lobby.json"
const CHRONICLE := "res://test/sample_chronicle.json"

@onready var world: CourtWorld = $World
@onready var hud: CourtHud = $Hud

var _sample_events: Array = []
var _demo: DemoDriver = null
var _voice: Node = null
var _last_frame := -1
var _phase := ""
const JUMPS := ["TUTORIAL", "Q01", "STAGE1", "Q02", "STAGE2", "Q03", "C02", "GIANT", "FATHER"]


func _ready() -> void:
	var args := _args()
	if args.has("shot") or args.has("live_shot"):
		get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	if args.has("dashboard"):
		_open_dashboard.call_deferred()
		return
	hud.reliquary.toggled.connect(world.set_cosmetic)
	hud.reliquary.announce()
	if args.has("debug"):
		hud.toggle_debug()
	_sample_events = _load_json(EVENTS) if FileAccess.file_exists(EVENTS) else []
	if args.has("shot"):
		_run_shot(args)
		return
	# Same audio hook as the dashboard: voice lines play from GameState's events.
	if ResourceLoader.exists(VOICE_PLAYER):
		_voice = load(VOICE_PLAYER).new()
		add_child(_voice)
	GameState.state_updated.connect(_on_live_state)
	GameState.event_received.connect(_on_event)
	if not GameState.latest_state.is_empty():
		_on_state(GameState.latest_state)
	if args.has("demo"):
		_toggle_demo()
	elif GameState.has_meta("entry_keyboard_demo"):
		GameState.remove_meta("entry_keyboard_demo")
		_toggle_demo()
	if args.has("live_shot"):
		# the normal GameState pipeline, captured after a few seconds
		await get_tree().create_timer(float(args.get("after", "6"))).timeout
		_save_shot(str(args["live_shot"]), "live")


func _on_state(msg: Dictionary) -> void:
	var cs := CourtState.read(msg)
	_phase = cs.phase
	world.apply_state(cs)
	hud.apply_state(cs, world.giant_in_view)
	world.show_tags = cs.phase != "lobby" and cs.phase != "chronicle"
	if _voice != null and _voice.has_method("on_state"):
		_voice.call("on_state", msg)  # flight buzz and the host-side lines (roles, the Changeling swap)
	if cs.sample:
		_play_sample_events(cs.frame)


## GameState's feed is set aside while the keyboard demo runs.
func _on_live_state(msg: Dictionary) -> void:
	if _demo == null:
		_on_state(msg)


func _toggle_demo() -> void:
	if _demo == null:
		_demo = DemoDriver.new()
		_demo.state_ready.connect(_on_state)
		_demo.event_ready.connect(_on_demo_event)
		add_child(_demo)
	else:
		_demo.queue_free()
		_demo = null


func _on_demo_event(ev: Dictionary) -> void:
	_on_event(ev)
	if _voice != null and _voice.has_method("_on_event"):
		_voice.call("_on_event", ev)


func _on_event(ev: Dictionary) -> void:
	world.on_event(ev)
	hud.on_event(ev)


## The offline fixture has no event stream, so its captions and FX cues ride
## along by frame number (test/sample_events.json). Live servers send events.
func _play_sample_events(frame: int) -> void:
	if frame < 0 or frame == _last_frame:
		return
	var from := _last_frame
	_last_frame = frame
	for ev in _sample_events:
		var f := int(ev.get("frame", -1))
		if (from < frame and f > from and f <= frame) or (from > frame and f <= frame):
			_on_event(ev)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if _story_key(key):
		get_viewport().set_input_as_handled()
		return
	match key.keycode:
		KEY_1, KEY_KP_1:
			hud.reliquary.toggle_index(0)
		KEY_2, KEY_KP_2:
			hud.reliquary.toggle_index(1)
		KEY_3, KEY_KP_3:
			hud.reliquary.toggle_index(2)
		KEY_F1:
			hud.toggle_debug()
		KEY_F2:
			_open_dashboard()
		KEY_F3:
			_toggle_demo()
		KEY_F4:
			HallCam.chase = not HallCam.chase
		KEY_F6:
			if hud.decree.advance() and _voice != null and _voice.has_method("say"):
				_voice.call("say", "H_DECREE")
		KEY_F11:
			var win := get_window()
			win.mode = Window.MODE_WINDOWED if win.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


## The presenter's story controls, sent to the game server (it ignores them without a story running).
func _story_key(key: InputEventKey) -> bool:
	var cmd := {}
	if key.ctrl_pressed and key.keycode >= KEY_1 and key.keycode <= KEY_9:
		cmd = {"command": "jump", "scene": JUMPS[key.keycode - KEY_1]}
	else:
		match key.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				cmd = {"command": "start" if _phase in ["lobby", "end"] else "next"}
			KEY_SPACE, KEY_RIGHT, KEY_PAGEDOWN:
				cmd = {"command": "next"}
			KEY_LEFT, KEY_PAGEUP:
				cmd = {"command": "back"}
			KEY_S:
				cmd = {"command": "skip"}
			KEY_R:
				cmd = {"command": "restart"}
	if cmd.is_empty() or _demo != null:
		return false
	return GameState.send_command(cmd)


## The old dashboard was laid out for an unscaled window, so drop the 640x360
## pixel-art stretch before switching to it.
func _open_dashboard() -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().change_scene_to_file(DASHBOARD)


# ------------------------------------------------------------ screenshots --

func _run_shot(args: Dictionary) -> void:
	var screen := str(args.get("screen", "trial"))
	var path := str(args["shot"])
	var relics := str(args.get("relics", ""))
	hud.reliquary.reset_unsaved()
	for i in 3:
		if relics.contains(str(i + 1)):
			hud.reliquary.toggle_index(i)
	if args.has("state"):  # --state=file.json: one saved server state (the story's cutscenes, props, impacts)
		var saved: Dictionary = _load_json(str(args["state"]))
		for i in int(args.get("frames", "45")):
			_on_state(saved)
			await get_tree().process_frame
		for i in int(args.get("decree", "0")):
			hud.decree.advance()
			await get_tree().process_frame
		_save_shot(path, "state")
		return
	match screen:
		"lobby", "chronicle":
			var msg: Dictionary = _load_json(LOBBY if screen == "lobby" else CHRONICLE)
			msg["offline_sample"] = true
			for i in 40:
				_on_state(msg)
				await get_tree().process_frame
		_:
			var frames: Array = _load_json(SEQUENCE)
			var target := clampi(int(args.get("frame", "150")), 0, frames.size() - 1)
			var start := maxi(0, target - 60)
			_last_frame = start - 1
			for f in range(start, target + 1):
				var frame: Dictionary = (frames[f] as Dictionary).duplicate()
				frame["offline_sample"] = true  # as GameState's fallback tags it
				_on_state(frame)
				await get_tree().create_timer(1.0 / 30.0).timeout
			if args.has("event"):
				_on_event({"t": "event", "kind": str(args["event"])})
				for i in 6:
					await get_tree().process_frame
	for i in int(args.get("decree", "0")):  # --decree=1 or 2: the Decree open at that page
		hud.decree.advance()
		await get_tree().process_frame
	_save_shot(path, screen)


func _save_shot(path: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := img.save_png(path)
	print("court shot %s -> %s (%s)" % [label, path, error_string(err)])
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


func _load_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Court: cannot open %s" % path)
		return {}
	return JSON.parse_string(f.get_as_text())
