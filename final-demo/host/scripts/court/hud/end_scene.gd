extends Control

## The story's last picture, under the end card (server `ending`):
##   wedding   E01: Hamlet and Miranda wed in the Royal Garden under a flower arch, Prospero (kind again) officiating,
##             the court and the Privy Council cheering, petals falling and hearts rising
##   own_path  E02: Miranda walks to the castle gate on her own path while Hamlet bows and the suitors stand confused
## Anshul's v4 backdrops and animation_v1 rigs; all of it cosmetic, after the story is decided.

const RIGS := "res://assets/pixelart/animation_v1/rigs/%s.scn"
## rig, feet position, scale, facing, gestures it cycles through
const WEDDING := [
	["prospero_nice", Vector2(321, 300), 0.95, 1.0, ["talk", "approve", "talk"]],
	["royal_seer", Vector2(70, 300), 0.85, 1.0, ["celebrate", "wave"]],
	["wingmaster", Vector2(572, 300), 0.85, -1.0, ["celebrate", "toast"]],
	["tinman", Vector2(142, 312), 0.95, 1.0, ["approve", "toast"]],
	["rutabaga", Vector2(500, 312), 0.95, -1.0, ["toast", "celebrate"]],
	["helmsman", Vector2(200, 296), 0.8, 1.0, ["wave", "celebrate"]],
	["liftmaster", Vector2(442, 296), 0.8, -1.0, ["celebrate", "wave"]],
	["clown_jester", Vector2(104, 340), 1.15, 1.0, ["celebrate", "sing", "bow"]],
	["sir_cheapdate", Vector2(540, 340), 1.15, -1.0, ["toast", "celebrate"]],
	["hamlet", Vector2(298, 338), 1.3, 1.0, ["bow", "celebrate", "wave"]],
	["miranda", Vector2(344, 338), 1.25, -1.0, ["celebrate", "wave", "bow"]],
]
const OWN_PATH := [
	["hamlet", Vector2(226, 336), 1.3, 1.0, ["bow", "wave"]],
	["lord_tinman", Vector2(118, 322), 1.0, 1.0, ["confused", "angry"]],
	["count_rutabaga", Vector2(62, 338), 1.1, 1.0, ["confused", "talk"]],
	["sir_cheapdate", Vector2(164, 344), 1.15, 1.0, ["confused", "toast"]],
	["clown_jester", Vector2(566, 336), 1.1, -1.0, ["sing", "bow", "approve"]],
]
const ALIAS := {"tinman": "lord_tinman", "rutabaga": "count_rutabaga"}

var ending := ""
var _bg: ImageTexture
var _actors: Array = []   # [node, gestures, next gesture time]
var _miranda: Node2D = null
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _petals: Array = []   # Vector4(x, y, speed, sway phase)
var _hearts: Array = []   # Vector3(x, y, life)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	visible = false
	_rng.seed = 41


func apply(cs: CourtState) -> void:
	var want := cs.ending if cs.phase == "end" else ""
	if want == "" and cs.phase == "end":
		want = "wedding"
	if want == ending:
		return
	ending = want
	_clear()
	visible = ending != ""
	if ending == "":
		return
	_t = 0.0
	_bg = StoryArt.backdrop("garden" if ending == "wedding" else "gate_outside")
	for spec in (WEDDING if ending == "wedding" else OWN_PATH):
		_add(spec)
	if ending == "own_path":  # Miranda sets off towards the gate
		_miranda = _rig("miranda")
		if _miranda != null:
			add_child(_miranda)
			_miranda.set_motion("walk", 0.5, 1.0)
	_petals.clear()
	for i in (70 if ending == "wedding" else 36):
		_petals.append(Vector4(_rng.randf_range(0, HallCam.W), _rng.randf_range(-HallCam.H, HallCam.H), _rng.randf_range(14, 32), _rng.randf() * TAU))


func _rig(name: String) -> Node2D:
	var path: String = RIGS % ALIAS.get(name, name)
	if not ResourceLoader.exists(path):
		return null
	return (load(path) as PackedScene).instantiate() as Node2D


func _add(spec: Array) -> void:
	var rig := _rig(str(spec[0]))
	if rig == null:
		return
	add_child(rig)
	rig.position = spec[1]
	rig.scale = Vector2(spec[2], spec[2])
	rig.set_motion("idle", 0.0, spec[3])
	_actors.append([rig, spec[4], _rng.randf_range(0.3, 2.0)])


func _clear() -> void:
	for a in _actors:
		(a[0] as Node).queue_free()
	_actors.clear()
	if _miranda != null:
		_miranda.queue_free()
		_miranda = null
	_hearts.clear()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for a in _actors:
		a[2] -= delta
		if a[2] <= 0.0:
			var g: Array = a[1]
			a[0].play_gesture(g[_rng.randi() % g.size()], _rng.randf_range(1.4, 2.4))
			a[2] = _rng.randf_range(2.5, 4.5)
	if _miranda != null:  # she walks away up to the gate, then turns and waves goodbye
		var u := clampf(_t / 7.0, 0.0, 1.0)
		var k := lerpf(1.25, 0.62, u)
		_miranda.scale = Vector2(k, k)
		_miranda.position = Vector2(lerpf(360, 322, u), lerpf(338, 268, u))
		if u >= 1.0 and _miranda.get("locomotion") == "walk":
			_miranda.set_motion("idle", 0.0, -1.0)
		if u >= 1.0 and fmod(_t, 4.0) < delta:
			_miranda.play_gesture("wave", 1.6)
	for i in _petals.size():
		var p: Vector4 = _petals[i]
		p.y += p.z * delta
		p.x += sin(_t * 1.5 + p.w) * 10.0 * delta
		if p.y > HallCam.H:
			p = Vector4(_rng.randf_range(0, HallCam.W), -6, p.z, p.w)
		_petals[i] = p
	if ending == "wedding" and _rng.randf() < delta * 2.2:
		_hearts.append(Vector3(_rng.randf_range(290, 350), 250, 1.8))
	for i in range(_hearts.size() - 1, -1, -1):
		var h: Vector3 = _hearts[i]
		h.y -= 26.0 * delta
		h.z -= delta
		if h.z <= 0.0:
			_hearts.remove_at(i)
		else:
			_hearts[i] = h
	queue_redraw()


func _draw() -> void:
	if _bg != null:
		draw_texture(_bg, Vector2.ZERO)
	if ending == "wedding":
		draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), Color(1.0, 0.85, 0.6, 0.12))  # golden hour
		_arch()
	else:
		draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), Color(0.35, 0.25, 0.5, 0.18))  # dusk
	for p in _petals:
		var v: Vector4 = p
		var c := Color(1.0, 0.78, 0.86) if ending == "wedding" else Color(0.85, 0.55, 0.2)  # petals, or falling leaves
		draw_rect(Rect2(roundf(v.x), roundf(v.y), 2, 2), c)
	for h in _hearts:
		var v: Vector3 = h
		var tex := SpriteForge.heart()
		draw_texture(tex, Vector2(roundf(v.x), roundf(v.y)), Color(1, 1, 1, clampf(v.z, 0.0, 1.0)))


## A flower arch over the couple: two gilded posts and a garland of roses and leaves.
func _arch() -> void:
	var cx := 321.0
	var base := 332.0
	var top := 150.0
	var half := 74.0
	for sx in [-1.0, 1.0]:
		draw_rect(Rect2(cx + sx * half - 3, top + 40, 6, base - top - 40), Pal.GOLD_DARK)
		draw_rect(Rect2(cx + sx * half - 2, top + 40, 2, base - top - 40), Pal.GOLD)
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		pts.append(Vector2(cx - cos(a) * half, top + 40 - sin(a) * 50))
	draw_polyline(pts, Pal.GOLD_DARK, 6.0)
	draw_polyline(pts, Pal.GOLD, 2.0)
	for i in pts.size():
		var p := pts[i]
		draw_circle(p + Vector2(0, 2), 4.0, Color(0.25, 0.5, 0.2))
		draw_circle(p, 3.0, Color(0.95, 0.35, 0.45) if i % 2 == 0 else Color(1.0, 0.95, 0.9))
	for sx in [-1.0, 1.0]:  # roses climbing the posts
		for y in range(int(top + 50), int(base), 14):
			draw_circle(Vector2(cx + sx * half, y), 3.0, Color(0.95, 0.35, 0.45) if (y / 14) % 2 == 0 else Color(1.0, 0.95, 0.9))
