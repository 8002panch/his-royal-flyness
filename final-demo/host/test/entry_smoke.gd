extends SceneTree

## Run with: godot --headless --path host --script res://test/entry_smoke.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var entry: Control = load("res://scenes/Entry.tscn").instantiate()
	root.add_child(entry)
	current_scene = entry
	await process_frame
	if current_scene != entry or entry.get("_backdrop") == null:
		push_error("Entry scene failed to open")
		quit(1)
		return
	var help_key := InputEventKey.new()
	help_key.keycode = KEY_H
	help_key.pressed = true
	entry.call("_unhandled_key_input", help_key)
	if not entry.get("_help"):
		push_error("Help shortcut did not open the control guide")
		quit(1)
		return
	entry.call("_enter_court", true)
	await process_frame
	await process_frame
	if current_scene == null or current_scene.name != "Court" or current_scene.get("_demo") == null:
		push_error("Keyboard demo button did not start the court demo")
		quit(1)
		return
	print("entry smoke: title and keyboard demo opened")
	quit()
