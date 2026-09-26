class_name CourtWorld
extends Node2D

## The Banquet Hall, the hero of the main screen. Independent layers, back to
## front (see scenes/Court.tscn):
##   FarBackground  vault, walls, great arch, rose window, cloth of estate (baked)
##   FloorCarpet    tiles, red carpet, royal-blue dais (baked)
##   ColumnsBanners back-wall banners (animated sprites) + arcade and columns (baked)
##   Feast          tables and dishes (baked) + candle flames (animated sprites)
##   Shadows        dithered floor shadows and the Giant's target ring
##   Actors         Hamlet, Miranda, Sir Cheapdate, Sir Indy, the Giant's hand
##   FX             dust, hearts, sparkles, the ink SPLAT
##   Labels         name tags
## It only draws the latest `state`. It never decides an outcome.

const HAMLET_SIZE := 0.78
const MIRANDA_SIZE := 0.62
## server/seer_adapter.py's placeholder Princess (server space); used only
## until render.princess has been seen, and as the lobby backdrop.
const DEFAULT_PRINCESS := Vector3(0.25, 0.18, 0.85)
const IDLE_FLY := Vector3(0.0, -0.1, -1.0)
const BANNER_SWAY := [0, 1, 0, -1]

@onready var far: Sprite2D = $FarBackground
@onready var floor_carpet: Sprite2D = $FloorCarpet
@onready var columns_banners: Node2D = $ColumnsBanners
@onready var columns: Sprite2D = $ColumnsBanners/Columns
@onready var feast: Node2D = $Feast
@onready var tables: Sprite2D = $Feast/Tables
@onready var shadows: ShadowLayer = $Shadows
@onready var actors: Node2D = $Actors
@onready var hamlet: HamletActor = $Actors/Hamlet
@onready var miranda: MirandaActor = $Actors/Miranda
@onready var giant: GiantHand = $Actors/Giant
@onready var fx: FxLayer = $FX
@onready var labels: NameTags = $Labels

var rivals: Array = []
var state := CourtState.new()
var giant_in_view := false
var show_tags := true
var hamlet_screen := Vector2.ZERO

var _banners: Array = []
var _flames: Array = []
var _t := 0.0
var _anim_t := 0.0
var _anim_step := 0
var _fly_target := IDLE_FLY
var _fly_shown := IDLE_FLY
var _princess := HallCam.from_server(DEFAULT_PRINCESS)
var _princess_seen := false
var _princess_visible := true
var _giant_cue: Dictionary = {}
var _giant_target := Vector3.ZERO
var _giant_tracking := false
var _giant_p := 0.0
var _shake_left := 0.0
var _shake_px := 0
var _was_low := false
var _sparkle_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 5
	for s in [far, floor_carpet, columns, tables]:
		var spr: Sprite2D = s
		spr.centered = false
	far.texture = HallBuilder.far_background().texture()
	floor_carpet.texture = HallBuilder.floor_layer().texture()
	columns.texture = HallBuilder.columns_layer().texture()
	var fe := HallBuilder.feast_layer()
	tables.texture = (fe["canvas"] as PixelCanvas).texture()
	for spot in fe["flames"]:
		var f := Sprite2D.new()
		f.centered = false
		f.position = Vector2(spot)
		feast.add_child(f)
		_flames.append(f)
	for spec in HallBuilder.back_banners():
		var b := Sprite2D.new()
		b.centered = false
		b.position = Vector2(spec["pos"]) - Vector2(4, 0)
		columns_banners.add_child(b)
		columns_banners.move_child(b, 0)
		_banners.append({"sprite": b, "spec": spec})
	rivals = [$Actors/SirCheapdate, $Actors/SirIndy]
	_animate_props()


func apply_state(cs: CourtState) -> void:
	state = cs
	if cs.has_fly:
		_fly_target = cs.fly
	if not cs.princess.is_empty():
		var off := HallCam.offset_from_cue(cs.princess)
		if off.z > 0.15:
			var est := HallCam.from_server(_fly_target) + off
			_princess = est if not _princess_seen else _princess.lerp(est, 0.25)
			_princess_seen = true
		_princess_visible = true
	else:
		# render.princess is null: she is not in this scene. Outside play
		# (lobby, chronicle) she stays on her dais as part of the backdrop.
		_princess_visible = cs.phase != "play" or not cs.has_fly
	_giant_cue = cs.giant


func set_cosmetic(relic: String, on: bool) -> void:
	hamlet.set_cosmetic(relic, on)


func shake(duration: float, px: int) -> void:
	_shake_left = maxf(_shake_left, duration)
	_shake_px = maxi(_shake_px if _shake_left > 0.0 else 0, px)


## Visual reactions to server/voice events (event ids from docs/LORE.md).
func on_event(ev: Dictionary) -> void:
	var kind := str(ev.get("kind", ""))
	var id := str(ev.get("id", ""))
	if kind == "splat" or id == "H_SPLAT":
		fx.splat(hamlet_screen)
		shake(0.35, 3)
	elif kind in ["jump", "escape"] or id == "H_JUMP":
		fx.puff(hamlet_screen + Vector2(0, 10), 8)
		shake(0.15, 1)
	elif kind in ["win", "charmed", "hearts"] or id in ["H_WIN", "P_CHARMED", "H_WEDDING", "P_WEDDING"]:
		fx.hearts((hamlet_screen + miranda.position) / 2.0, 6)
		fx.hearts(miranda.position + Vector2(0, -10), 4)
	elif kind == "giant" or id == "H_WARN_GIANT":
		shake(0.2, 1)


func _process(delta: float) -> void:
	_t += delta
	_fly_shown = _fly_shown.lerp(_fly_target, 1.0 - exp(-delta * 12.0))
	var shadow_items: Array = []

	# --- Hamlet
	var hp := HallCam.from_server(_fly_shown)
	var proj := HallCam.project(hp)
	var hh := clampi(roundi(HAMLET_SIZE * proj.z / 2.0) * 2, 16, 96)
	hamlet.set_body_px(hh)
	var speed := state.fly_vel.length() if state.has_fly else 0.0
	var bob := 0.0 if speed > 0.15 else roundf(sin(_t * 3.2) * 1.2)
	hamlet.position = Vector2(roundf(proj.x), roundf(proj.y + bob))
	hamlet_screen = hamlet.position
	hamlet.tick(delta, 14.0 + speed * 16.0, speed > 0.35)
	var ground := _ground_y(hp.x, hp.z)
	var gp := HallCam.project(Vector3(hp.x, ground, hp.z))
	var alt := clampf((hp.y - ground) / 2.6, 0.0, 1.0)
	var srx := maxi(3, roundi(hh * (0.46 - 0.22 * alt) / 2.0) * 2)
	shadow_items.append({"pos": Vector2i(roundi(gp.x), roundi(gp.y)), "rx": srx, "ry": maxi(1, roundi(srx * 0.28))})
	# dust when the Liftmaster drives him down onto the floor bound
	var low := state.has_fly and _fly_target.y <= -0.97
	if low and not _was_low:
		fx.puff(Vector2(gp.x, gp.y), 7)
	_was_low = low

	# --- Miranda on her perch
	miranda.visible = _princess_visible
	if _princess_visible:
		var mp := HallCam.project(_princess)
		var mh := clampi(roundi(MIRANDA_SIZE * mp.z / 2.0) * 2, 16, 80)
		miranda.set_body_px(mh)
		miranda.position = Vector2(roundf(mp.x), roundf(mp.y))
		var mg := _ground_y(_princess.x, _princess.z)
		var base := HallCam.project(Vector3(_princess.x, mg, _princess.z))
		miranda.set_perch(maxi(0, roundi(base.y) - roundi(mp.y) - miranda.feet_y()))
		miranda.tick(delta)
		shadow_items.append({"pos": Vector2i(roundi(base.x), roundi(base.y)), "rx": 8, "ry": 2})
		_sparkle_t += delta
		if _sparkle_t > 0.7:
			_sparkle_t = 0.0
			fx.sparkle(miranda.position + Vector2(_rng.randi_range(-mh / 2, mh / 2), _rng.randi_range(-mh, 0)))

	for r in rivals:
		r.tick(delta)
		shadow_items.append({"pos": Vector2i(roundi(r.position.x), roundi(r.position.y)), "rx": 6, "ry": 1})

	_update_giant(shadow_items)
	shadows.set_items(shadow_items)
	_sort_actors(hp.z)

	_anim_t += delta
	if _anim_t >= 0.12:
		_anim_t = 0.0
		_anim_step += 1
		_animate_props()

	var tags: Array = []
	if show_tags:
		# under him while there is floor to spare, above him when he dives low
		var below_y := roundi(hamlet.position.y + hh * 0.55)
		var h_below := below_y < 280
		var h_anchor := Vector2i(roundi(hamlet.position.x), below_y if h_below else roundi(hamlet.position.y - hh * 0.8))
		tags.append({"anchor": h_anchor, "text": "PRINCE HAMLET", "below": h_below})
		if miranda.visible:
			var m_anchor := miranda.heart_anchor + Vector2i(0, -1)
			# when he is right in front of her, lift her tag clear of his
			if not h_below and absi(m_anchor.x - h_anchor.x) < 70 and absi(m_anchor.y - h_anchor.y) < 16:
				m_anchor.y = mini(m_anchor.y, h_anchor.y) - 16
			tags.append({"anchor": m_anchor, "text": "MIRANDA", "ink": Pal.CRIMSON})
	labels.set_tags(tags)

	if _shake_left > 0.0:
		_shake_left -= delta
		position = Vector2(_rng.randi_range(-_shake_px, _shake_px), _rng.randi_range(-_shake_px, _shake_px))
	else:
		position = Vector2.ZERO


func _update_giant(shadow_items: Array) -> void:
	if _giant_cue.is_empty():
		_giant_p = 0.0
		_giant_tracking = false
		giant.hide_hazard()
		giant_in_view = false
		return
	var off := HallCam.offset_from_cue(_giant_cue)
	var est := HallCam.from_server(_fly_target) + Vector3(off.x, 0.0, off.z)
	est.x = clampf(est.x, -HallCam.WALL_X + 0.4, HallCam.WALL_X - 0.4)
	est.z = clampf(est.z, -1.9, HallCam.BACK_Z - 0.35)
	# a world object should stay put: latch the first estimate, then drift slowly
	_giant_target = est if not _giant_tracking else _giant_target.lerp(est, 0.08)
	_giant_tracking = true
	var dist := float(_giant_cue.get("distance_cm", 300.0))
	var p := clampf(1.0 - (dist - 15.0) / 285.0, 0.0, 1.0)
	var ground := _ground_y(_giant_target.x, _giant_target.z)
	var target := Vector3(_giant_target.x, ground, _giant_target.z)
	var sp := HallCam.project(target)
	if p > 0.92 and _giant_p <= 0.92:
		shake(0.3, 3)
		fx.puff(Vector2(sp.x, sp.y), 10)
	_giant_p = p
	giant.show_hazard(target, p)
	var rx := maxi(4, roundi((0.25 + 0.55 * p) * sp.z * 0.55))
	shadow_items.append({"pos": Vector2i(roundi(sp.x), roundi(sp.y)), "rx": rx, "ry": maxi(2, roundi(rx * 0.3)), "ring": p > 0.3})
	giant_in_view = p > 0.2 and sp.x > -rx and sp.x < HallCam.W + rx


func _ground_y(x: float, z: float) -> float:
	if absf(x) <= HallBuilder.DAIS_X:
		if z >= HallBuilder.DAIS_STEP:
			return HallBuilder.DAIS_Y2
		if z >= HallBuilder.DAIS_FRONT:
			return HallBuilder.DAIS_Y1
	return HallCam.FLOOR_Y


func _sort_actors(hamlet_z: float) -> void:
	var order: Array = [[hamlet_z, hamlet], [_princess.z, miranda], [_giant_target.z if giant.showing else -99.0, giant]]
	for r in rivals:
		order.append([r.depth(), r])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in order.size():
		var node: Node = order[i][1]
		if node.get_index() != i:
			actors.move_child(node, i)


func _animate_props() -> void:
	for i in _flames.size():
		var f: Sprite2D = _flames[i]
		f.texture = SpriteForge.flame((_anim_step + i * 2) % 3)
	if _anim_step % 4 == 0:
		for i in _banners.size():
			var b: Dictionary = _banners[i]
			var spec: Dictionary = b["spec"]
			var sway: int = BANNER_SWAY[(_anim_step / 4 + i * 2) % BANNER_SWAY.size()]
			(b["sprite"] as Sprite2D).texture = SpriteForge.banner(spec["w"], spec["h"], spec["field"], spec["emblem"], sway)
