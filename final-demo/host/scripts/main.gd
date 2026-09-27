extends Control

## Root of scenes/Main.tscn.
##
## Built against the real, live interfaces (Sat 17:00+, see brain/README.md,
## relay/PROTOCOL.md, team/README.md#proposed-formats):
##   - Movement is direct control (no brain): Helmsman/Liftmaster/Wingmaster.
##   - The Seer's cues come from the real MaleCNS brain and arrive in the
##     exact `cues` shape team/README.md proposed to Ved (seer_view) and to
##     Anshul (this HUD).
##   - The nervous-system bar grouping (vision/flight/reaction/song) is the
##     literal proposal team/README.md addressed to Anshul, accepted here
##     since nobody overrode it before this was built.
##
## `state.controls` (each axis's live value, for the Helmsman/Liftmaster/
## Wingmaster bars) has no owner or format yet — Arnav hasn't built the
## movement/arena step. Reading it here is provisional and degrades to 0
## until that exists; see game_state.gd's header comment.

@onready var trial_view: Control = $TrialView
@onready var lobby: Control = $Lobby

@onready var trial_label: Label = $TrialView/TopBar/TrialLabel
@onready var candle_bar: ProgressBar = $TrialView/TopBar/CandleBar
@onready var badge_label: Label = $TrialView/TopBar/Badge

@onready var hall_area: Control = $TrialView/HallBackdrop/HallArea
@onready var prince: ColorRect = $TrialView/HallBackdrop/HallArea/Prince
@onready var princess: ColorRect = $TrialView/HallBackdrop/HallArea/Princess
@onready var giant: ColorRect = $TrialView/HallBackdrop/HallArea/Giant

@onready var helmsman_bar: ProgressBar = $TrialView/LeftPanel/HelmsmanCard/HelmsmanBox/HelmsmanBar
@onready var liftmaster_bar: ProgressBar = $TrialView/LeftPanel/LiftmasterCard/LiftmasterBox/LiftmasterBar
@onready var wingmaster_bar: ProgressBar = $TrialView/LeftPanel/WingmasterCard/WingmasterBox/WingmasterBar

@onready var compass_label: Label = $TrialView/RightPanel/CompassCard/CompassBox/CompassLabel
@onready var compass_needle: ColorRect = $TrialView/RightPanel/CompassCard/CompassBox/CompassArrow/Needle
@onready var hazard_value: Label = $TrialView/RightPanel/HazardCard/HazardBox/HazardValue
@onready var hazard_bar: ProgressBar = $TrialView/RightPanel/HazardCard/HazardBox/HazardBar
@onready var activity_rows: VBoxContainer = $TrialView/RightPanel/NervousCard/NervousBox/ActivityRows

@onready var nervous_title: Label = $TrialView/RightPanel/NervousCard/NervousBox/NervousTitle
@onready var caption_label: Label = $TrialView/CaptionLabel

@onready var lobby_code_label: Label = $Lobby/Center/CodeLabel

# Brain-activity bars are generic: one per key of state.brainActivity, key name as label,
# no fixed key list (Neil's set today: her_L, her_R, looming, escape, steer, song).
# Values are z-scores; bars clamp to +/- ACTIVITY_RANGE and the raw number is shown.
const ACTIVITY_RANGE := 6.0

const SIDE_TO_DEG := {"left": -60.0, "ahead": 0.0, "right": 60.0}


func _ready() -> void:
	add_child(preload("res://scripts/voice_player.gd").new())
	GameState.state_updated.connect(_on_state_updated)
	GameState.event_received.connect(_on_event_received)
	_show_lobby()


func _on_state_updated(state: Dictionary) -> void:
	var phase: String = state.get("phase", "lobby")
	if phase == "lobby":
		_show_lobby()
		# NOTE: no room-code field is defined yet in any real message either;
		# same placeholder-until-confirmed situation as before.
		lobby_code_label.text = state.get("room", "----")
		return

	_show_trial()
	_update_actor(prince, state.get("prince", {}))
	_update_actor(princess, state.get("princess", {}))
	_update_giant(state.get("giant", {}))
	_update_controls(state.get("controls", {}))
	var cues: Dictionary = state.get("cues", {})
	_update_seer(cues)
	_update_brain_activity(state.get("brainActivity", cues.get("activity", {})), state.get("offline_sample", false))
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


func _to_screen(x_cm: float, y_cm: float) -> Vector2:
	# Arena scale TBD by Arnav; 600x400 cm is a placeholder matching the
	# original hall's proportions.
	var size: Vector2 = hall_area.size
	var px: float = (x_cm / 600.0) * size.x
	var py: float = (y_cm / 400.0) * size.y
	return Vector2(px, py)


func _update_controls(controls: Dictionary) -> void:
	helmsman_bar.value = float(controls.get("x", 0.0))
	liftmaster_bar.value = float(controls.get("y", 0.0))
	wingmaster_bar.value = float(controls.get("z", 0.0))


func _update_seer(cues: Dictionary) -> void:
	var princess_cue: Variant = cues.get("princess", null)
	if princess_cue == null:
		compass_label.text = "Princess: unseen"
		compass_needle.visible = false
	else:
		var p: Dictionary = princess_cue
		compass_needle.visible = true
		var bearing: float = p.get("bearing_deg", SIDE_TO_DEG.get(p.get("side", "ahead"), 0.0))
		compass_needle.rotation_degrees = bearing
		compass_needle.pivot_offset = compass_needle.size * 0.5
		compass_label.text = "Princess: %s, %s (%.0f%%)" % [p.get("side", "?"), p.get("distance", "?"), float(p.get("confidence", 0.0)) * 100.0]

	var giant_cue: Dictionary = cues.get("giant", {})
	var warning: float = giant_cue.get("warning", 0.0)
	hazard_bar.value = warning
	if warning <= 0.01:
		hazard_value.text = "clear"
	else:
		var side: Variant = giant_cue.get("side", null)
		var eta: Variant = giant_cue.get("eta_s", null)
		if eta != null:
			hazard_value.text = "%s, %.1fs" % [str(side).to_upper(), float(eta)]
		else:
			hazard_value.text = str(side).to_upper() if side != null else "INCOMING"


func _update_brain_activity(activity: Dictionary, offline_sample: bool) -> void:
	nervous_title.text = "FLY NERVOUS SYSTEM"
	if offline_sample:
		nervous_title.text += " (OFFLINE SAMPLE, not brain output)"
	var seen := {}
	for key in activity.keys():
		var name := str(key)
		seen[name] = true
		var value: float = float(activity[key]) if typeof(activity[key]) in [TYPE_INT, TYPE_FLOAT] else 0.0
		_update_activity_row(name, value)
	# drop rows for keys that disappeared (e.g. {} or a smaller key set)
	for row in activity_rows.get_children():
		if not seen.has(row.name):
			row.queue_free()


func _update_activity_row(key: String, value: float) -> void:
	var row: HBoxContainer = activity_rows.get_node_or_null(key)
	if row == null:
		row = HBoxContainer.new()
		row.name = key
		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = key
		lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(lbl)
		var bar := ProgressBar.new()
		bar.name = "Bar"
		bar.min_value = -ACTIVITY_RANGE
		bar.max_value = ACTIVITY_RANGE
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)
		var num := Label.new()
		num.name = "Value"
		num.custom_minimum_size = Vector2(48, 0)
		row.add_child(num)
		activity_rows.add_child(row)
	(row.get_node("Bar") as ProgressBar).value = clampf(value, -ACTIVITY_RANGE, ACTIVITY_RANGE)
	(row.get_node("Value") as Label).text = "%.1f" % value


func _update_meta(state: Dictionary) -> void:
	trial_label.text = "Trial " + str(state.get("trial", ""))
	var meters: Dictionary = state.get("meters", {})
	candle_bar.value = float(meters.get("candle", 0.0)) * 100.0
	var source: String = state.get("cues", {}).get("source", state.get("brain", "true"))
	if state.get("offline_sample", false):
		badge_label.text = "OFFLINE SAMPLE"
	else:
		badge_label.text = "TRUE PRINCE" if source == "true" else "CHANGELING"
