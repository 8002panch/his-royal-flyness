extends SceneTree

## Run with: godot --headless --path host --script res://test/voice_smoke.gd
## Checks scripts/voice_player.gd against the real audio/ manifests: lines play after their cue, warnings stay silent,
## fight shouts come from the right pool, and host-side lines follow the live feed but never the offline sample.

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _run() -> void:
	var vp: Node = load("res://scripts/voice_player.gd").new()
	root.add_child(vp)
	await process_frame
	vp.rng.seed = 7
	_check(vp.audio_dir != "", "found audio/")
	_check(vp.lines.size() >= 140 and vp.sounds.size() >= 15, "loaded both manifests")

	# a line with no cue starts at once; a line with a cue waits for it
	vp._on_event({"kind": "voice", "id": "C01_P4_PROSPERO"})
	_check(vp.history.back() == "line:C01_P4_PROSPERO", "plain line plays")
	vp._on_event({"kind": "voice", "id": "C02_P1_CLOWN"})
	_check(vp.history.back() == "sound:GIANT_GROWL", "cue plays first")
	vp._process(1.0)
	_check(vp.history.back() == "line:C02_P1_CLOWN", "line follows its cue")

	# warnings are silent: the Seer's secret
	var before: int = vp.history.size()
	vp._on_event({"kind": "giant"})
	vp._on_event({"kind": "voice", "id": "H_WARN_GIANT", "caption": "The Giant stirs!"})
	_check(vp.history.size() == before, "warnings play nothing")

	# a resolved attack: its sound, and a milestone always speaks from its own pool
	vp._process(30.0)
	vp._on_event({"kind": "dodge", "fight": "giant", "n": 5})
	_check(vp.history.back() == "sound:COURT_CHEER" and vp.history[vp.history.size() - 2] == "sound:GIANT_SWAT",
		"dodge 5: swat, then the cheer cue")
	vp._process(1.0)
	_check(vp.history.back() in ["line:G_HALF_MIRANDA", "line:G_HALF_CLOWN"], "dodge 5 shout")
	vp._process(30.0)
	vp._on_event({"kind": "hit", "fight": "giant", "n": 2})
	vp._process(1.0)
	_check(vp.history.back() in ["line:G_LAST_HIT_MIRANDA", "line:G_LAST_HIT_CLOWN"], "hit 2 shout")
	# no shout talks over a line
	vp._on_event({"kind": "voice", "id": "C03_P2_PROSPERO"})
	before = vp.history.size()
	vp._on_event({"kind": "dodge", "fight": "giant", "n": 9})
	_check(vp.history.size() == before + 1 and vp.history.back() == "sound:GIANT_SWAT", "busy: sound only, no shout")

	# the father fight: dodge 4 is a pair, Miranda then Prospero's reply
	vp._process(30.0)
	vp._on_event({"kind": "dodge", "fight": "father", "n": 4})
	vp._process(1.0)
	_check(vp.history.back() == "line:F_FOUR_MIRANDA", "father dodge 4")
	for i in 20:
		vp._process(0.5)
	_check("line:F_FOUR_PROSPERO" in vp.history, "Prospero replies")

	# host-side lines follow the live feed, one role at a time, and the Changeling swap
	vp._process(30.0)
	vp.on_state({"room": "BZKT", "brain": "true", "players": [{"role": "helmsman", "name": "A"}]})
	vp.on_state({"room": "BZKT", "brain": "true", "players": [{"role": "helmsman", "name": "A"}, {"role": "seer", "name": "B"}]})
	_check(vp.history.back() == "line:H_ROLE_SEER", "a new Seer is announced")
	# a phone screen turning off and on: silent; gone for good: one fainted line after a while, and no second welcome
	vp._process(30.0)
	var quiet: int = vp.history.size()
	var two := [{"role": "helmsman", "name": "A"}, {"role": "seer", "name": "B"}]
	vp.on_state({"room": "BZKT", "brain": "true", "players": [{"role": "helmsman", "name": "A"}]})
	vp._process(3.0)
	vp.on_state({"room": "BZKT", "brain": "true", "players": two})
	vp._process(30.0)
	_check(vp.history.size() == quiet, "a screen blinking off and on says nothing")
	vp.on_state({"room": "BZKT", "brain": "true", "players": [{"role": "helmsman", "name": "A"}]})
	for i in 12:
		vp._process(1.0)
		vp.on_state({"room": "BZKT", "brain": "true", "players": [{"role": "helmsman", "name": "A"}]})
	_check(vp.history.count("line:H_FAINTED_SEER") == 1, "a seat empty for 10 s is called fainted, once")
	vp._process(30.0)
	vp.on_state({"room": "BZKT", "brain": "true", "players": two})
	vp._process(30.0)
	_check(vp.history.count("line:H_ROLE_SEER") == 1, "a returning Seer isn't welcomed twice")
	vp._process(30.0)
	vp.on_state({"room": "BZKT", "brain": "changeling", "players": [{"role": "helmsman", "name": "A"}, {"role": "seer", "name": "B"}]})
	_check(vp.history.back() == "line:H_CHANGELING", "the Changeling swap is announced")
	vp._process(30.0)
	before = vp.history.size()
	vp.on_state({"room": "BZKT", "brain": "changeling", "players": []})  # a relay reconnect drops everyone at once
	vp.on_state({"room": "QXWP", "brain": "true", "players": [{"role": "seer", "name": "C"}]})  # a new room
	vp.on_state({"offline_sample": true, "brain": "true", "players": [{"role": "wingmaster", "name": "S"}]})
	vp._process(30.0)
	_check(vp.history.size() == before, "no lines for bulk changes, new rooms or sample frames")

	var played: int = vp.history.size()
	var log := str(vp.history)
	root.remove_child(vp)
	vp.free()
	await process_frame
	await process_frame
	if _fails.is_empty():
		print("voice smoke: PASS (%d sounds and lines played)" % played)
		quit(0)
	else:
		for f in _fails:
			push_error("voice smoke FAIL: " + f)
		print(log)
		quit(1)
