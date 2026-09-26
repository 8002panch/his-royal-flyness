extends Control

## Root of scenes/Main.tscn. Reads GameState (see scripts/game_state.gd) and
## drives placeholder shapes for now — Codex's sprites replace the ColorRects
## under TrialView/HallArea and the crest icons under BottomBar/Crests without
## touching this script's logic; positions/colors are all it sets.

const ARENA_W_MM := 600.0
const ARENA_H_MM := 400.0

const CREST_OFF := Color(0.42, 0.39, 0.33, 1)
const CREST_ON := Color(0.788235, 0.635294, 0.152941, 1)

@onready var trial_view: Control = $TrialView
@onready var lobby: Control = $Lobby

@onready var trial_label: Label = $TrialView/TopBar/TrialLabel
@onready var candle_bar: ProgressBar = $TrialView/TopBar/CandleBar

@onready var hall_area: Control = $TrialView/HallArea
@onready var prince: ColorRect = $TrialView/HallArea/Prince
@onready var princess: ColorRect = $TrialView/HallArea/Princess
@onready var giant: ColorRect = $TrialView/HallArea/Giant
@onready var rivals_container: Node2D = $TrialView/HallArea/Rivals

@onready var input_bars: VBoxContainer = $TrialView/ChartPanel/InputBars
@onready var output_bars: VBoxContainer = $TrialView/ChartPanel/OutputBars

@onready var caption_label: Label = $TrialView/BottomBar/CaptionLabel
@onready var crest_lookout: ColorRect = $TrialView/BottomBar/Crests/Lookout
@onready var crest_perfumer: ColorRect = $TrialView/BottomBar/Crests/Perfumer
@onready var crest_taster: ColorRect = $TrialView/BottomBar/Crests/Taster
@onready var crest_spymaster: ColorRect = $TrialView/BottomBar/Crests/Spymaster

@onready var badge_label: Label = $TrialView/Badge

@onready var lobby_code_label: Label = $Lobby/CodeLabel

var _rival_nodes: Dictionary = {}


func _ready() -> void:
	GameState.state_updated.connect(_on_state_updated)
	GameState.event_received.connect(_on_event_received)
	_show_lobby()


func _on_state_updated(state: Dictionary) -> void:
	var phase: String = state.get("phase", "lobby")
	if phase == "lobby":
		_show_lobby()
		# NOTE: the documented state message has no room-code field yet.
		# Placeholder until Ved/Arnav confirm how the wax-seal code reaches
		# Godot (relay -> server -> here, or Godot generates it itself).
		lobby_code_label.text = state.get("room", "----")
		return

	_show_trial()
	_update_actor(prince, state.get("prince", {}))
	_update_actor(princess, state.get("princess", {}))
	_update_giant(state.get("giant", {}))
	_update_rivals(state.get("rivals", []))
	_update_chart(state.get("inputs", {}), state.get("outputs", {}))
	_update_crests(state.get("senses", {}))
	_update_meta(state)


func _on_event_received(event: Dictionary) -> void:
	if event.get("kind", "") in ["voice", "voice_live"]:
		caption_label.text = event.get("caption", "")


func _show_lobby() -> void:
	lobby.visible = true
	trial_view.visible = false


func _show_trial() -> void:
	lobby.visible = false
	trial_view.visible = true


func _update_actor(node: Control, actor: Dictionary) -> void:
	if node == null or actor.is_empty():
		return
	node.position = _to_screen(actor.get("x", 0.0), actor.get("y", 0.0))
	node.rotation_degrees = actor.get("h", 0.0)


func _update_giant(g: Dictionary) -> void:
	giant.visible = g.get("active", false)
	if not giant.visible:
		return
	giant.position = _to_screen(g.get("x", 0.0), g.get("y", 0.0))
	var size: float = g.get("size", 0.2)
	giant.scale = Vector2.ONE * lerpf(0.5, 2.5, clampf(size, 0.0, 1.0))
	var alpha := 0.85 if not g.get("fake", false) else 0.35
	giant.color = Color(0.168627, 0.129412, 0.090196, alpha)


func _update_rivals(rivals: Array) -> void:
	var seen := {}
	for rival in rivals:
		var rname: String = rival.get("name", "rival")
		seen[rname] = true
		if not _rival_nodes.has(rname):
			var node := ColorRect.new()
			node.size = Vector2(24, 24)
			node.color = Color(0.611765, 0.109804, 0.109804, 1)
			rivals_container.add_child(node)
			_rival_nodes[rname] = node
		var node2: ColorRect = _rival_nodes[rname]
		node2.position = _to_screen(rival.get("x", 0.0), rival.get("y", 0.0))
		node2.rotation_degrees = rival.get("h", 0.0)
	for rname in _rival_nodes.keys():
		if not seen.has(rname):
			_rival_nodes[rname].queue_free()
			_rival_nodes.erase(rname)


func _to_screen(x_mm: float, y_mm: float) -> Vector2:
	var size: Vector2 = hall_area.size
	var px: float = (x_mm / ARENA_W_MM) * size.x
	var py: float = (y_mm / ARENA_H_MM) * size.y
	return Vector2(px, py)


func _update_chart(inputs: Dictionary, outputs: Dictionary) -> void:
	_update_bar_group(input_bars, inputs)
	_update_bar_group(output_bars, outputs)


func _update_bar_group(container: VBoxContainer, values: Dictionary) -> void:
	for key in values.keys():
		var bar: ProgressBar = container.get_node_or_null(key)
		if bar == null:
			bar = _make_bar_row(container, key)
		bar.value = float(values[key])


func _make_bar_row(container: VBoxContainer, key: String) -> ProgressBar:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = key
	lbl.custom_minimum_size = Vector2(96, 0)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.name = key
	bar.min_value = 0.0
	bar.max_value = 2.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	container.add_child(row)
	return bar


func _update_crests(senses: Dictionary) -> void:
	_set_crest_lit(crest_lookout, _sense_active(senses.get("lookout", {})))
	_set_crest_lit(crest_perfumer, _sense_active(senses.get("perfumer", {})))
	_set_crest_lit(crest_taster, senses.get("taster", {}).get("tapping", false))
	_set_crest_lit(crest_spymaster, senses.get("spymaster", {}).get("listen", 0) > 0)


func _sense_active(d: Dictionary) -> bool:
	for v in d.values():
		if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and v > 0:
			return true
	return false


func _set_crest_lit(node: ColorRect, lit: bool) -> void:
	node.color = CREST_ON if lit else CREST_OFF


func _update_meta(state: Dictionary) -> void:
	trial_label.text = "Trial " + str(state.get("trial", ""))
	var meters: Dictionary = state.get("meters", {})
	candle_bar.value = float(meters.get("candle", 0.0)) * 100.0
	badge_label.text = "TRUE PRINCE" if state.get("brain", "true") == "true" else "CHANGELING"
