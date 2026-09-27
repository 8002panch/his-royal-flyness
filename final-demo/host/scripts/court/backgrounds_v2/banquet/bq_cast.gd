extends Node

## Places the Banquet's scenery cast into the court's Actors layer and keeps
## them depth-sorted against Hamlet, Miranda and the Giant's hand. Runs after
## CourtWorld each frame (process_priority) so its ordering wins.
##   Sir Cheapdate  tipsy, toasting and confused by his bare table (left)
##   Clown jester   pacing and singing before the dais
##   Count Rutabaga and Lord Tinman feasting and gesturing at the laden table (right)
##   Prospero       on the dais, holding forth

const NPC := preload("res://scripts/court/backgrounds_v2/banquet/bq_npc.gd")
const G := preload("res://scripts/court/backgrounds_v2/banquet/bq_geo.gd")

var world: CourtWorld
var actors: Node2D
var npcs: Array = []


func _ready() -> void:
	process_priority = 100


func attach(court: Node) -> void:
	world = court.get_node("World")
	actors = world.get_node("Actors")
	# the v1 rivals are replaced by the animated cast
	for r in world.rivals:
		(r as Node).queue_free()
	world.rivals.clear()
	var fy := HallCam.FLOOR_Y
	_add("sir_cheapdate", Vector3(-1.0, fy, -0.3), 0.7, 1.0, [["confused", 2.4, 0.6], ["toast", 2.0, 1.2], ["talk", 1.6, 0.8], ["toast", 1.6, 1.5]], 0.5, 0.05)
	_add("clown_jester", Vector3(-0.75, fy, 0.32), 0.7, 1.0, [["sing", 2.4, 0.4], ["celebrate", 1.4, 1.2], ["wave", 1.4, 0.6]], 1.2, 0.0, [-0.95, -0.62, 7.0])
	_add("count_rutabaga", Vector3(0.9, fy, -0.68), 0.72, -1.0, [["toast", 2.0, 0.8], ["talk", 2.6, 0.6], ["approve", 1.4, 1.4]], 0.9)
	_add("lord_tinman", Vector3(0.8, fy, 0.14), 0.72, -1.0, [["talk", 2.4, 0.6], ["point", 1.6, 1.0], ["angry", 1.2, 1.6], ["toast", 1.8, 0.6]], 2.0)
	_add("prospero_nice", Vector3(-0.55, G.DAIS_Y2, 1.28), 0.95, 1.0, [["talk", 3.2, 0.4], ["point", 1.6, 0.6], ["talk", 2.6, 0.6], ["approve", 1.4, 1.2]], 1.6)


func _add(id: String, pos: Vector3, h: float, face: float, beats: Array, delay: float, sway := 0.0, pace: Array = []) -> void:
	var n: Node2D = NPC.new()
	actors.add_child(n)
	n.setup(id, pos, h, face, beats, delay)
	n.sway = sway
	n.pace = pace
	npcs.append(n)


func _process(delta: float) -> void:
	if world == null:
		return
	for n in npcs:
		n.tick(delta)
	var order: Array = []
	for ch in actors.get_children():
		var d := -50.0
		if ch in npcs:
			d = ch.depth()
		elif ch == world.hamlet:
			d = HallCam.from_server(world._fly_shown).z
		elif ch == world.miranda:
			d = world._princess.z
		elif ch == world.giant:
			d = world._giant_target.z if world.giant.showing else -99.0
		order.append([d, ch])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in order.size():
		if (order[i][1] as Node).get_index() != i:
			actors.move_child(order[i][1], i)
