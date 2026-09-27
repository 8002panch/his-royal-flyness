extends Node2D

## The garden's audience: animated cast rigs (assets/pixelart/animation_v1) standing in the
## bays as living scenery. Scenery only: no gameplay. Each rig sits at a fixed spot in hall
## space and is re-projected through HallCam every frame, so it moves with the chase camera.
## Sits between the Feast layer and the Shadows in World, so Hamlet is always drawn in front.

const RIG := "res://assets/pixelart/animation_v1/rigs/%s.scn"
## id, hall x, z, facing (+1 / -1), height in hall units, gestures it cycles through
const CAST: Array = [
	["lord_tinman",    -1.15,  0.20, -1.0, 0.72, ["talk", "talk", "point", "approve"]],
	["count_rutabaga", -2.02,  0.05,  1.0, 0.70, ["talk", "toast", "confused", "talk"]],
	["clown_jester",   -0.98,  1.20,  1.0, 0.66, ["celebrate", "sing", "wave", "bow"]],
	["royal_seer",      1.55,  0.15, -1.0, 0.72, ["scan", "point", "approve"]],
	["helmsman",       -1.55,  3.00,  1.0, 0.68, ["talk", "toast", "wave"]],
	["wingmaster",     -1.95,  2.90,  1.0, 0.68, ["toast", "talk", "approve"]],
	["liftmaster",      1.70,  3.00,  -1.0, 0.68, ["talk", "wave", "confused"]],
]

var _npcs: Array = []
var _painter: CanvasPainter
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_painter = CanvasPainter.new(self)
	_rng.seed = 11
	for spec in CAST:
		var packed: PackedScene = load(RIG % spec[0])
		var actor: Node2D = packed.instantiate()
		add_child(actor)
		var idle := "idle"
		actor.set_motion(idle, 0.4, spec[3])
		_npcs.append({"node": actor, "spec": spec, "next": _rng.randf_range(0.5, 3.5)})


func _process(delta: float) -> void:
	var order: Array = []
	for n in _npcs:
		var spec: Array = n["spec"]
		var actor: Node2D = n["node"]
		var z: float = spec[2]
		var p := HallCam.project(Vector3(spec[1], -1.3, z))
		var alive := p.z > 0.0 and z > HallCam.near_z() + 0.25
		actor.visible = alive
		if not alive:
			continue
		var hpx := clampf(float(spec[4]) * p.z, 12.0, 150.0)
		var k := roundf(hpx / 2.0) * 2.0 / 72.0
		actor.scale = Vector2(k, k)
		actor.position = Vector2(roundf(p.x), roundf(p.y))
		n["next"] -= delta
		if n["next"] <= 0.0:
			var g: Array = spec[5]
			actor.play_gesture(g[_rng.randi() % g.size()], _rng.randf_range(1.4, 2.6))
			n["next"] = _rng.randf_range(3.0, 6.5)
		order.append([z, actor])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in order.size():
		var node: Node = order[i][1]
		if node.get_index() != i:
			move_child(node, i)
	queue_redraw()


func _draw() -> void:
	for n in _npcs:
		var spec: Array = n["spec"]
		var actor: Node2D = n["node"]
		if not actor.visible:
			continue
		var rx := 0.34 * HallCam.scale_at(spec[2]) * 0.5
		if rx < 2.0:
			continue
		var pos := actor.position
		_painter.ellipse_dither(pos.x, pos.y, rx, maxf(1.5, rx * 0.3), Pal.INK)
