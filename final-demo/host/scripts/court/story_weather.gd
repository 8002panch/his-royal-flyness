extends Node2D

## The fights' weather over the court (drawn above the actors, under the name tags):
##   storm     the Giant's fight: a dark, blue-grey hall, slanting rain, and lightning at random moments; every flash is
##             followed by its thunder (close strikes crack at once, far ones roll in a second or two later)
##   hellfire  Prospero's fight: the hall burns red, flames lick along the floor, embers rise
## Lightning runs on its own random clock and knows nothing about attacks (the screen can't know them), so the storm can
## never tip anyone off about a hand: that stays the Seer's.

signal thunder(id: String)

var mode := ""
var tint: CanvasModulate

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _drops: Array = []     # Vector3(x, y, speed)
var _embers: Array = []    # Vector4(x, y, speed, life)
var _next_flash := 2.5
var _flash := 0.0
var _reflash := -1.0
var _bolt := PackedVector2Array()
var _bolt_left := 0.0
var _pending: Array = []   # [seconds left, thunder id]


func _ready() -> void:
	_rng.seed = 23
	visible = false


func set_mode(m: String) -> void:
	if m == mode:
		return
	mode = m
	_drops.clear()
	_embers.clear()
	_pending.clear()
	_flash = 0.0
	_bolt_left = 0.0
	_next_flash = _rng.randf_range(2.0, 4.0)
	if mode == "storm":
		for i in 170:
			_drops.append(Vector3(_rng.randf_range(-40, HallCam.W), _rng.randf_range(0, HallCam.H), _rng.randf_range(260, 380)))
	elif mode == "hellfire":
		for i in 70:
			_embers.append(_new_ember(true))
	visible = mode != ""


func _new_ember(anywhere: bool) -> Vector4:
	return Vector4(_rng.randf_range(0, HallCam.W), _rng.randf_range(40, HallCam.H) if anywhere else HallCam.H + 4,
		_rng.randf_range(18, 55), _rng.randf_range(2.0, 6.0))


func _process(delta: float) -> void:
	_t += delta
	for p in _pending:
		p[0] -= delta
	while not _pending.is_empty() and _pending[0][0] <= 0.0:
		thunder.emit(str(_pending.pop_front()[1]))
	if tint != null:
		var want := Color.WHITE
		if mode == "storm":
			want = Color(0.58, 0.62, 0.8).lerp(Color.WHITE, clampf(_flash * 1.2, 0.0, 1.0))
		elif mode == "hellfire":
			var f := 0.93 + 0.07 * sin(_t * 7.0) * sin(_t * 2.3)
			want = Color(1.0 * f, 0.5 * f, 0.4 * f)
		tint.color = want if mode == "storm" else tint.color.lerp(want, 1.0 - exp(-delta * 4.0))
	if mode == "":
		return
	if mode == "storm":
		for i in _drops.size():
			var d: Vector3 = _drops[i]
			d.y += d.z * delta
			d.x += d.z * 0.22 * delta
			if d.y > HallCam.H:
				d = Vector3(_rng.randf_range(-60, HallCam.W), _rng.randf_range(-20, 0), d.z)
			_drops[i] = d
		_next_flash -= delta
		if _next_flash <= 0.0:
			_strike()
		if _reflash > 0.0:
			_reflash -= delta
			if _reflash <= 0.0:
				_flash = maxf(_flash, 0.8)  # lightning flickers twice
		_flash = maxf(0.0, _flash - delta * 3.2)
		_bolt_left = maxf(0.0, _bolt_left - delta)
	elif mode == "hellfire":
		for i in _embers.size():
			var e: Vector4 = _embers[i]
			e.y -= e.z * delta
			e.x += sin(_t * 2.0 + i) * 8.0 * delta
			e.w -= delta
			_embers[i] = e if e.w > 0.0 and e.y > 20 else _new_ember(false)
	queue_redraw()


func _strike() -> void:
	var close := _rng.randf() < 0.4
	_flash = 1.0 if close else 0.6
	_reflash = 0.11 if close else -1.0
	if close:  # a jagged bolt from the sky down behind the hall
		var x := _rng.randf_range(80, HallCam.W - 80)
		_bolt = PackedVector2Array([Vector2(x, 0)])
		var y := 0.0
		while y < 170.0:
			y += _rng.randf_range(12, 26)
			x += _rng.randf_range(-18, 18)
			_bolt.append(Vector2(x, y))
		_bolt_left = 0.22
	# sound travels slower than light: a close crack right away, a distant roll a second or two later
	var delay := _rng.randf_range(0.12, 0.3) if close else _rng.randf_range(0.9, 2.0)
	var id := "THUNDER_CLOSE" if close else ("THUNDER_ROLL" if _rng.randf() < 0.6 else "THUNDER_FAR")
	_pending.append([delay, id])
	_pending.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_next_flash = _rng.randf_range(4.0, 9.0)


func _draw() -> void:
	if mode == "storm":
		draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), Color(0.02, 0.03, 0.09, 0.22))
		for d in _drops:
			var v: Vector3 = d
			var len := v.z * 0.03
			draw_line(Vector2(v.x, v.y), Vector2(v.x + len * 0.22, v.y + len), Color(0.75, 0.82, 0.95, 0.55), 1.0)
		if _bolt_left > 0.0 and _bolt.size() > 1:
			draw_polyline(_bolt, Color(0.6, 0.7, 1.0, 0.5), 5.0)
			draw_polyline(_bolt, Color(1, 1, 1, 0.95), 2.0)
		if _flash > 0.0:
			draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), Color(0.9, 0.93, 1.0, _flash * 0.45))
	elif mode == "hellfire":
		draw_rect(Rect2(0, 0, HallCam.W, HallCam.H), Color(0.45, 0.02, 0.0, 0.12 + 0.04 * sin(_t * 3.0)))
		for i in 42:  # flames licking along the bottom of the screen
			var x := i * 16.0 - 4.0
			var h := 26.0 + 14.0 * sin(_t * 8.0 + i * 1.7) + 8.0 * sin(_t * 13.0 + i * 0.6)
			var base := HallCam.H - 40.0  # just above the council's role cards
			draw_colored_polygon(PackedVector2Array([Vector2(x - 12, base), Vector2(x + 12, base), Vector2(x + 2, base - h)]),
				Color(0.85, 0.12, 0.02, 0.55))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 6, base), Vector2(x + 7, base), Vector2(x + 1, base - h * 0.6)]),
				Color(1.0, 0.6, 0.1, 0.6))
		for e in _embers:
			var v: Vector4 = e
			var a := clampf(v.w / 2.0, 0.0, 1.0)
			draw_rect(Rect2(roundf(v.x), roundf(v.y), 2, 2), Color(1.0, 0.75 if int(v.x) % 3 == 0 else 0.45, 0.1, a))
