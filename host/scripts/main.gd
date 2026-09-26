extends Control

## Root of scenes/Main.tscn.
##
## Built against the PROPOSED "Royal Navigator" mechanic (3 flight-axis
## players + 1 navigator), logged in docs/DECISIONS.md#O5 — not yet
## confirmed/implemented server-side. Reads state.controls / state.navigator
## when present; degrades to all-neutral (centered bars, "clear" hazard) when
## a real server without those fields is connected, so this never crashes,
## it just shows nothing exciting until Arnav wires them up.
##
## Codex's art drops in as: a texture on TrialView/HallBackdrop (replacing
## the flat color fill) and sprites swapped onto the Prince/Princess/Giant/
## Rivals ColorRects (or textures on TextureRects in their place) — none of
## that changes this script.

const ARENA_W_MM := 600.0
const ARENA_H_MM := 400.0

# Best-effort grouping of the real MaleCNS neuron names (state.inputs /
# state.outputs) into the 4 HUD categories the reference UI shows. Provisional
# — revisit once Neil confirms which neurons the Navigator role actually
# reads from (docs/DECISIONS.md#O5).
const NEURON_GROUPS := {
	"vision": ["LC10a", "LPLC2", "LC4"],
	"flight": ["DNa02", "MDN", "DNp01"],
	"balance": ["JO"],
}

@onready var trial_view: Control = $TrialView
@onready var lobby: Control = $Lobby

@onready var trial_label: Label = $TrialView/TopBar/TrialLabel
@onready var candle_bar: ProgressBar = $TrialView/TopBar/CandleBar
@onready var badge_label: Label = $TrialView/TopBar/Badge

@onready var hall_area: Control = $TrialView/HallBackdrop/HallArea
@onready var prince: ColorRect = $TrialView/HallBackdrop/HallArea/Prince
@onready var princess: ColorRect = $TrialView/HallBackdrop/HallArea/Princess
@onready var giant: ColorRect = $TrialView/HallBackdrop/HallArea/Giant
@onready var rivals_container: Node2D = $TrialView/HallBackdrop/HallArea/Rivals

@onready var lr_bar: ProgressBar = $TrialView/LeftPanel/LRCard/LRBox/LRBar
@onready var ud_bar: ProgressBar = $TrialView/LeftPanel/UDCard/UDBox/UDBar
@onready var fb_bar: ProgressBar = $TrialView/LeftPanel/FBCard/FBBox/FBBar

@onready var compass_needle: ColorRect = $TrialView/RightPanel/CompassCard/CompassBox/CompassArrow/Needle
@onready var hazard_value: Label = $TrialView/RightPanel/HazardCard/HazardBox/HazardValue
@onready var hazard_bar: ProgressBar = $TrialView/RightPanel/HazardCard/HazardBox/HazardBar
@onready var group_bars: VBoxContainer = $TrialView/RightPanel/NervousCard/NervousBox/GroupBars

@onready var caption_label: Label = $TrialView/CaptionLabel

@onready var lobby_code_label: Label = $Lobby/Center/CodeLabel

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
	_update_controls(state.get("controls", {}))
	_update_navigator(state.get("navigator", {}))
	_update_nervous_system(state.get("inputs", {}), state.get("outputs", {}))
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


func _update_controls(controls: Dictionary) -> void:
	lr_bar.value = float(controls.get("lr", 0.0))
	ud_bar.value = float(controls.get("ud", 0.0))
	fb_bar.value = float(controls.get("fb", 0.0))


func _update_navigator(nav: Dictionary) -> void:
	var bearing: float = nav.get("bearing_deg", 0.0)
	compass_needle.rotation_degrees = bearing
	compass_needle.pivot_offset = compass_needle.size * 0.5

	var hazard: Dictionary = nav.get("hazard", {})
	var level: float = hazard.get("level", 0.0)
	hazard_bar.value = level
	if level <= 0.01:
		hazard_value.text = "clear"
	else:
		var eta: int = hazard.get("eta_swats", 0)
		hazard_value.text = ("%d SWATS AWAY" % eta) if eta > 0 else "INCOMING"


func _update_nervous_system(inputs: Dictionary, outputs: Dictionary) -> void:
	var totals := {"vision": 0.0, "flight": 0.0, "balance": 0.0, "reaction": 0.0}
	var counts := {"vision": 0, "flight": 0, "balance": 0, "reaction": 0}
	var all_values := {}
	all_values.merge(inputs)
	all_values.merge(outputs)

	for key in all_values.keys():
		var group := _classify_neuron(key)
		totals[group] += float(all_values[key])
		counts[group] += 1

	for group in ["vision", "flight", "balance", "reaction"]:
		var avg: float = (totals[group] / counts[group]) if counts[group] > 0 else 0.0
		_update_group_bar(group, avg)


func _classify_neuron(key: String) -> String:
	for group in NEURON_GROUPS.keys():
		for prefix in NEURON_GROUPS[group]:
			if key.begins_with(prefix):
				return group
	return "reaction"


func _update_group_bar(group: String, value: float) -> void:
	var bar: ProgressBar = group_bars.get_node_or_null(group)
	if bar == null:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = group.capitalize()
		lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(lbl)

		bar = ProgressBar.new()
		bar.name = group
		bar.min_value = 0.0
		bar.max_value = 2.0
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)

		group_bars.add_child(row)
	bar.value = value


func _update_meta(state: Dictionary) -> void:
	trial_label.text = "Trial " + str(state.get("trial", ""))
	var meters: Dictionary = state.get("meters", {})
	candle_bar.value = float(meters.get("candle", 0.0)) * 100.0
	badge_label.text = "TRUE PRINCE" if state.get("brain", "true") == "true" else "CHANGELING"
