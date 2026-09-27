extends SceneTree

## Run with: godot --headless --path host --script res://test/story_smoke.gd
## The story screens against states shaped like server/campaign.py's: the lobby QR, a cutscene with the cast's rigs, a quiz
## card, the play banner's counters, the landed fist in the v2 Great Hall, and the backdrops loading from Anshul's v4 art.

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _state(extra: Dictionary) -> Dictionary:
	var s := {"t": "state", "time": 1.0, "room": "BZKT", "brain": "true", "fly": {"x": 0, "y": 0, "z": -0.3, "vx": 0, "vy": 0, "vz": 0},
		"render": {"princess": null}, "roles": {}, "players": []}
	s.merge(extra, true)
	return s


func _run() -> void:
	var court: Node = load("res://scenes/Court.tscn").instantiate()
	root.add_child(court)
	await process_frame
	var gs := root.get_node_or_null("GameState")
	if gs != null and gs.state_updated.is_connected(Callable(court, "_on_live_state")):
		gs.state_updated.disconnect(Callable(court, "_on_live_state"))  # only this test's states, not the offline sample
	var hud: CourtHud = court.get_node("Hud")
	var world: CourtWorld = court.get_node("World")

	for id in ["garden", "banquet", "basement", "inner_passage", "arena", "father_arena", "window_ledge", "gate_outside"]:
		_check(StoryArt.backdrop(id) != null, "backdrop " + id)

	court.call("_on_state", _state({"phase": "lobby", "scene": "LOBBY", "joinQr": ["111", "101", "111"]}))
	await process_frame
	_check(hud.lobby.visible and hud.lobby.story and hud.lobby.qr.size() == 3, "lobby with QR and the start prompt")

	var beat := {"id": "Q01_P1_TINMAN", "speaker": "tinman", "name": "Lord Tinman", "caption": "Bold entrance, Hamlet.",
		"panel": "p1.1", "gesture": "approve", "index": 1, "count": 12, "cast": ["tinman", "hamlet"]}
	court.call("_on_state", _state({"phase": "comic", "scene": "Q01", "backdrop": "window_ledge", "beat": beat}))
	await process_frame
	_check(hud.comic.visible and hud.comic._rigs.size() == 2, "cutscene with two rigs")

	var q := {"id": "Q01", "text": "Alcohol can make balance and coordination...", "a": "Worse", "b": "More precise",
		"chosen": null, "correct": null}
	beat["panel"] = "question"
	court.call("_on_state", _state({"phase": "question", "scene": "Q01", "backdrop": "window_ledge", "beat": beat, "question": q}))
	await process_frame
	_check(hud.comic.visible and hud.comic.waiting, "quiz waits for the Seer")

	court.call("_on_state", _state({"phase": "play", "scene": "GIANT", "backdrop": "arena", "objective": "Outlast the Giant",
		"counters": {"dodges": 3, "hits": 1, "dodges_needed": 10, "hits_allowed": 3}, "storyDemo": true,
		"impact": {"x": 0.1, "y": 0.0, "z": -0.3, "hit": true, "at": 5.0, "fight": "giant"}}))
	await process_frame
	await process_frame
	_check(not hud.comic.visible and hud.story.visible, "play banner, no cutscene")
	_check(hud.story._status() == "DODGES 3/10   HITS 1/3", "fight counters: " + hud.story._status())
	_check(world.cast.current == "great_hall" and HallLayer.theme != null and world.giant.showing,
		"the Giant fights in Anshul's v2 Great Hall, and the landed fist shows")
	for r in world.rivals:
		_check(not (r as Node2D).visible, "no rivals outside the story's cast")

	court.call("_on_state", _state({"phase": "play", "scene": "STAGE1", "backdrop": "basement", "objective": "Walls",
		"counters": {"gates": 1, "gates_total": 4}, "walls": [[-0.5, -1.0, -0.2, -0.8, 0.8]]}))
	await process_frame
	_check(not world._backdrop.visible and HallLayer.theme == null and HallBuilder.walls.size() == 1,
		"the course uses the hall and the server's walls")

	root.remove_child(court)
	court.free()
	await process_frame
	if _fails.is_empty():
		print("story smoke: PASS")
		quit(0)
	else:
		for f in _fails:
			push_error("story smoke FAIL: " + f)
		quit(1)
