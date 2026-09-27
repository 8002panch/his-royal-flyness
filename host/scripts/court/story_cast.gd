extends Node

## The story's open scenes use Anshul's backgrounds_v2 sets with their casts of animated rigs (animation_v1), the same
## setup as his launchers in scenes/backgrounds_v2: the garden and its courtiers for the tutorial, the Great Hall and its
## frightened courtiers for the Giant, the Banquet and its feast for Prospero's fight. Scenery only: every rig stands where
## the set puts it and never reacts to anything before the server has resolved it (no warning of an attack, ever).
## Runs after CourtWorld each frame, so its depth order of the actors wins.

const GARDEN_LAYER := preload("res://scripts/court/backgrounds_v2/garden/garden2_layer.gd")
const GARDEN_SCENERY := preload("res://scripts/court/backgrounds_v2/garden/garden2_scenery.gd")
const GH_LAYER := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_layer.gd")
const GH_NPC := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_npc.gd")
const GH_STATE := preload("res://scripts/court/backgrounds_v2/great_hall/gh2_state.gd")
const BQ_LAYER := preload("res://scripts/court/backgrounds_v2/banquet/bq_layer.gd")
const BQ_NPC := preload("res://scripts/court/backgrounds_v2/banquet/bq_npc.gd")
const BQ_GEO := preload("res://scripts/court/backgrounds_v2/banquet/bq_geo.gd")

## backdrop id (server/campaign.py) -> the v2 set drawn while flying there
const SETS := {"garden": "garden", "arena": "great_hall", "father_arena": "banquet"}
## Great Hall courtiers (scenes/backgrounds_v2/great_hall_play.gd): id, feet, height, mood, facing, timing
const GH_CAST := [
	["count_rutabaga", Vector3(-1.56, -1.3, -0.42), 0.6, "cower", 1.0, 0.0],
	["lord_tinman", Vector3(1.6, -1.3, -0.02), 0.62, "confused", -1.0, 1.1],
	["clown_jester", Vector3(-1.5, -1.3, 1.08), 0.56, "cower", 1.0, 0.5],
	["royal_seer", Vector3(1.48, -1.3, 1.28), 0.62, "scan", -1.0, 0.0],
]

var world: Node2D
var current := ""
var _scenery: Node = null
var _npcs: Array = []


func _ready() -> void:
	process_priority = 100


## The set for this backdrop ("" = the hall: the lobby, comics' world and the wall courses).
static func set_for(backdrop: String) -> String:
	return SETS.get(backdrop, "")


func show_set(name: String) -> void:
	if name == current:
		return
	_clear()
	current = name
	match name:
		"garden":
			HallLayer.theme = GARDEN_LAYER
			_scenery = GARDEN_SCENERY.new()
			world.add_child(_scenery)
			world.move_child(_scenery, world.get_node("Feast").get_index() + 1)
		"great_hall":
			HallLayer.theme = GH_LAYER
			GH_STATE.loom_p = 0.0
			GH_STATE.alarm = 0.0
			var i := 0
			for spec in GH_CAST:
				var n: Node2D = GH_NPC.new()
				n.rig_id = spec[0]
				n.hall_pos = spec[1]
				n.height_units = spec[2]
				n.mood = spec[3]
				n.facing = spec[4]
				n.seed_offset = spec[5] + i * 0.37
				i += 1
				world.actors.add_child(n)
				_npcs.append(n)
		"banquet":
			HallLayer.theme = BQ_LAYER
			var fy := HallCam.FLOOR_Y
			_bq("sir_cheapdate", Vector3(-1.0, fy, -0.3), 0.7, 1.0, [["confused", 2.4, 0.6], ["toast", 2.0, 1.2], ["talk", 1.6, 0.8]], 0.5, 0.05)
			_bq("clown_jester", Vector3(-0.75, fy, 0.32), 0.7, 1.0, [["sing", 2.4, 0.4], ["celebrate", 1.4, 1.2], ["wave", 1.4, 0.6]], 1.2, 0.0, [-0.95, -0.62, 7.0])
			_bq("count_rutabaga", Vector3(0.9, fy, -0.68), 0.72, -1.0, [["toast", 2.0, 0.8], ["talk", 2.6, 0.6], ["approve", 1.4, 1.4]], 0.9)
			_bq("lord_tinman", Vector3(0.8, fy, 0.14), 0.72, -1.0, [["talk", 2.4, 0.6], ["point", 1.6, 1.0], ["toast", 1.8, 0.6]], 2.0)
		_:
			HallLayer.theme = null


func _bq(id: String, pos: Vector3, h: float, face: float, beats: Array, delay: float, sway := 0.0, pace: Array = []) -> void:
	var n: Node2D = BQ_NPC.new()
	world.actors.add_child(n)
	n.setup(id, pos, h, face, beats, delay)
	n.sway = sway
	n.pace = pace
	_npcs.append(n)


func _clear() -> void:
	HallLayer.theme = null
	if _scenery != null:
		_scenery.queue_free()
		_scenery = null
	for n in _npcs:
		(n as Node).queue_free()
	_npcs.clear()
	current = ""


## A landed hit shakes the Great Hall's courtiers (only after the server has resolved it).
func startle() -> void:
	if current == "great_hall":
		GH_STATE.alarm = 1.0


func _process(delta: float) -> void:
	if world == null or current == "":
		return
	if current == "great_hall":
		GH_STATE.alarm = maxf(0.0, GH_STATE.alarm - delta * 0.6)
	for n in _npcs:
		n.tick(delta)
	if _npcs.is_empty():
		return
	var order: Array = []
	for ch in world.actors.get_children():
		var d := -50.0
		if ch in _npcs:
			d = ch.depth()
		elif ch == world.hamlet:
			d = HallCam.from_server(world._fly_shown).z
		elif ch == world.miranda:
			d = world._princess.z
		elif ch == world.giant:
			d = world._impact_target.z - 0.4 if world._impact_left > 0.0 else -99.0
		elif ch == world.props:
			d = world.props.depth()
		order.append([d, ch])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in order.size():
		if (order[i][1] as Node).get_index() != i:
			world.actors.move_child(order[i][1], i)
