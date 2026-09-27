extends SceneTree

## Run with: godot --headless --path host --script res://test/music_smoke.gd
## Checks scripts/music_player.gd against audio/music/manifest.json: every track loads, and each part of the story gets its tune.

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var m: Node = load("res://scripts/music_player.gd").new()
	root.add_child(m)
	await process_frame
	if m.tracks.size() != 9:
		_fails.append("9 tracks in the manifest, got %d" % m.tracks.size())
	for id in m.tracks:
		if m._stream(id) == null:
			_fails.append("track %s loads" % id)
	var expect := [["", "lobby", "", "PROMENADE"], ["INTRO", "intro", "", "PROMENADE"], ["TUTORIAL", "play", "", "HEDGE"],
		["C01", "comic", "", "WOBBLE"], ["Q01", "question", "", "GOBLET"], ["STAGE1", "play", "", "DEPTHS"],
		["STAGE2", "ready", "", "SIEGE"], ["GIANT", "play", "", "STORM"], ["FATHER", "play", "", "SCOURGE"],
		["E01", "comic", "", "UNION"], ["E02", "comic", "", "PROMENADE"], ["END", "end", "wedding", "UNION"],
		["END", "end", "own_path", "PROMENADE"]]
	for e in expect:
		m.play_for(e[0], e[1], e[2])
		if m.current != e[3]:
			_fails.append("%s/%s plays %s, not %s" % [e[0], e[1], m.current, e[3]])
	m.play_for("C02", "comic", "")
	m.play_for("C02", "comic", "")
	if m.history.count("music:WOBBLE") != 2:  # C01 once, C02 again only after other tracks; the same scene never restarts it
		_fails.append("a repeated scene restarts its track")
	print("music smoke: " + ("PASS (%d tracks)" % m.tracks.size() if _fails.is_empty() else "FAIL " + str(_fails)))
	quit(0 if _fails.is_empty() else 1)
