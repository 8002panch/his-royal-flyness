extends Node

## Plays the game's spoken lines. Add one instance to any scene (`add_child(preload("res://scripts/voice_player.gd").new())`).
##
## Listens to GameState.event_received:
##   {"t":"event","kind":"voice","id":"H_WIN",...}          -> audio/out/H_WIN.mp3 (made by audio/gen_audio.py)
##   {"t":"event","kind":"voice_live","mp3_b64":"...",...}  -> the live Chronicle line, decoded from base64
## A missing file or empty payload plays nothing (the caption still shows in the scene).

var _player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_player)
	GameState.event_received.connect(_on_event)


func _on_event(event: Dictionary) -> void:
	var stream: AudioStreamMP3 = null
	match event.get("kind", ""):
		"voice":
			var path: String = ProjectSettings.globalize_path("res://").path_join("../audio/out/%s.mp3" % event.get("id", ""))
			if FileAccess.file_exists(path):
				stream = _mp3(FileAccess.get_file_as_bytes(path))
		"voice_live":
			stream = _mp3(Marshalls.base64_to_raw(str(event.get("mp3_b64", ""))))
	if stream == null:
		return
	_player.stream = stream
	_player.play()


func _mp3(bytes: PackedByteArray) -> AudioStreamMP3:
	if bytes.is_empty():
		return null
	var stream := AudioStreamMP3.new()
	stream.data = bytes
	return stream
