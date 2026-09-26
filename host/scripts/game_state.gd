extends Node

## Autoload singleton (registered in project.godot as `GameState`).
##
## Owns the connection to the game server's local WebSocket (30 Hz `state`
## messages, per docs/TECH_ARCHITECTURE.md#messages-json). Every screen reads
## game state through `GameState.latest_state` / the signals below instead of
## opening its own socket.
##
## Until server/sample_state.json exists, or whenever the real server drops,
## this replays test/sample_sequence.json on a loop at TICK_HZ so every other
## screen can be built and demoed against realistic data.

signal state_updated(state: Dictionary)
signal event_received(event: Dictionary)
signal connection_status_changed(connected: bool, using_fallback: bool)

const SERVER_URL := "ws://127.0.0.1:8765"
const FALLBACK_SEQUENCE := "res://test/sample_sequence.json"
const TICK_HZ := 30.0
const RECONNECT_INTERVAL_S := 3.0

var latest_state: Dictionary = {}

var _socket := WebSocketPeer.new()
var _connected := false
var _attempted_connect := false
var _using_fallback := false
var _reconnect_timer := 0.0

var _fallback_frames: Array = []
var _fallback_index := 0
var _fallback_timer := 0.0


func _ready() -> void:
	_try_connect()


func _process(delta: float) -> void:
	if _using_fallback:
		_advance_fallback(delta)
		_maybe_retry_real_server(delta)
		return

	_socket.poll()
	var conn_state := _socket.get_ready_state()

	if conn_state == WebSocketPeer.STATE_OPEN:
		if not _connected:
			_connected = true
			connection_status_changed.emit(true, false)
		while _socket.get_available_packet_count() > 0:
			var packet: PackedByteArray = _socket.get_packet()
			_handle_message(packet.get_string_from_utf8())
	elif conn_state == WebSocketPeer.STATE_CLOSED:
		if _connected:
			push_warning("GameState: server connection closed; switching to offline sample data")
		_connected = false
		_start_fallback()


func send_cmd(cmd: String, arg = null) -> void:
	if not _connected:
		push_warning("GameState: send_cmd(%s) dropped, not connected to the game server" % cmd)
		return
	var payload := {"t": "cmd", "cmd": cmd, "arg": arg}
	_socket.send_text(JSON.stringify(payload))


func _try_connect() -> void:
	_attempted_connect = true
	var err := _socket.connect_to_url(SERVER_URL)
	if err != OK:
		push_warning("GameState: could not start connection to %s (error %s); using offline sample data" % [SERVER_URL, err])
		_start_fallback()


func _handle_message(text: String) -> void:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_dispatch(parsed)


func _dispatch(msg: Dictionary) -> void:
	match msg.get("t", ""):
		"state":
			latest_state = msg
			state_updated.emit(msg)
		"event":
			event_received.emit(msg)


func _start_fallback() -> void:
	if _using_fallback:
		return
	_using_fallback = true
	_fallback_frames = _load_fallback_frames()
	_fallback_index = 0
	_fallback_timer = 0.0
	_reconnect_timer = 0.0
	connection_status_changed.emit(false, true)


func _load_fallback_frames() -> Array:
	if not FileAccess.file_exists(FALLBACK_SEQUENCE):
		push_warning("GameState: no fallback sequence at %s" % FALLBACK_SEQUENCE)
		return []
	var f := FileAccess.open(FALLBACK_SEQUENCE, FileAccess.READ)
	var text := f.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	push_warning("GameState: %s did not contain a JSON array" % FALLBACK_SEQUENCE)
	return []


func _advance_fallback(delta: float) -> void:
	if _fallback_frames.is_empty():
		return
	_fallback_timer += delta
	var frame_len := 1.0 / TICK_HZ
	while _fallback_timer >= frame_len:
		_fallback_timer -= frame_len
		var frame: Dictionary = _fallback_frames[_fallback_index]
		latest_state = frame
		state_updated.emit(frame)
		_fallback_index = (_fallback_index + 1) % _fallback_frames.size()


func _maybe_retry_real_server(delta: float) -> void:
	# Keep quietly retrying the real server in the background so the game
	# picks it up the moment Arnav's server comes online, with no restart.
	_reconnect_timer += delta
	if _reconnect_timer < RECONNECT_INTERVAL_S:
		return
	_reconnect_timer = 0.0
	var probe := WebSocketPeer.new()
	var err := probe.connect_to_url(SERVER_URL)
	if err == OK:
		_socket = probe
		_using_fallback = false
