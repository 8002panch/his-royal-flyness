extends Node

## Autoload singleton (registered in project.godot as `GameState`).
##
## Reads the game server's 30 Hz `state` message. Built against the real,
## live interfaces the team has actually agreed on so far (Sat 17:00+):
##   - Movement roles are direct control, no brain involved: Helmsman (x:
##     left/right), Liftmaster (y: up/down), Wingmaster (z: forward/back).
##     See relay/PROTOCOL.md.
##   - The Seer's cues come from the real MaleCNS brain (brain/seer.py) and
##     are shared with Anshul's HUD in the exact shape team/README.md#proposed-formats
##     gives (`cues`): princess side/bearing/confidence/distance, giant
##     warning/side/eta_s, and `activity` z-scores for the HUD's nervous-
##     system bars (vision/flight/reaction/song — the grouping team/README.md
##     proposed to Anshul directly, accepted here since nobody overrode it).
##
## `state.controls` (each axis's current x/y/z value + momentum, for the
## Helmsman/Liftmaster/Wingmaster HUD bars) is NOT yet a field any of Neil/
## Arnav/Ved have defined — Arnav hasn't built the movement/arena step yet
## (server/ only has chronicler.py so far). Reading it here is provisional;
## it just renders as neutral/zero until Arnav's server sends it, same
## graceful-degradation approach as the offline fallback below.
##
## Until a real server is up, or whenever it drops, this loops
## test/sample_sequence.json (built in this same proposed shape) at TICK_HZ.

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


func _try_connect() -> void:
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
	_reconnect_timer += delta
	if _reconnect_timer < RECONNECT_INTERVAL_S:
		return
	_reconnect_timer = 0.0
	var probe := WebSocketPeer.new()
	var err := probe.connect_to_url(SERVER_URL)
	if err == OK:
		_socket = probe
		_using_fallback = false
