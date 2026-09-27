class_name CourtWorld
extends Node2D

## The Banquet Hall, the hero of the main screen. Independent layers, back to
## front (see scenes/Court.tscn):
##   FarBackground  vault, walls, great arch, rose window, cloth of estate
##   FloorCarpet    tiles, red carpet, royal-blue dais
##   ColumnsBanners back-wall banners (swaying) + arcade and columns
##   Feast          tables and dishes + candle flames
## The four hall layers repaint every frame through HallCam, which chases
## Hamlet: the hall moves around him (F4 switches to the fixed view).
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

@onready var layers: Array = [$FarBackground, $FloorCarpet, $ColumnsBanners, $Feast]
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

var _t := 0.0
var _anim_t := 0.0
var _anim_step := 0
var _fly_target := IDLE_FLY
var _fly_shown := IDLE_FLY
var _since_state := 0.0   # seconds since the last server state: the fly glides on at its velocity until the next one
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

## The story (server/campaign.py). Open scenes use Anshul's v4 backdrops instead of the hall; the wall courses keep the hall.
const OPEN_BACKDROPS := ["garden", "arena", "father_arena", "banquet", "window_ledge", "gate_outside"]
var story := false
var _backdrop := Sprite2D.new()
var _backdrop_id := ""
var props := StoryProps.new()
## preloaded, not by class_name: a fresh pull runs before Godot has re-imported and registered new class names
const STORY_CAST := preload("res://scripts/court/story_cast.gd")
var cast: Node = STORY_CAST.new()
const STORY_WEATHER := preload("res://scripts/court/story_weather.gd")
var weather: Node2D = STORY_WEATHER.new()
var _impact: Dictionary = {}
var _impact_left := 0.0
var _impact_target := Vector3.ZERO


func _ready() -> void:
	_rng.seed = 5
	rivals = [$Actors/SirCheapdate, $Actors/SirIndy]
	_backdrop.centered = false
	_backdrop.visible = false
	add_child(_backdrop)
	move_child(_backdrop, 0)
	props.visible = false
	actors.add_child(props)
	cast.world = self
	add_child(cast)
	var tint := CanvasModulate.new()  # the weather's colour over the whole court (the HUD is its own layer)
	add_child(tint)
	weather.tint = tint
	add_child(weather)
	move_child(weather, labels.get_index())  # over the actors and effects, under the name tags
	HallCam.follow(HallCam.from_server(_fly_shown), 0.0, true)


func apply_state(cs: CourtState) -> void:
	state = cs
	if cs.has_fly:
		_fly_target = cs.fly
		_since_state = 0.0
	if not cs.princess.is_empty():
		var off := HallCam.offset_from_cue(cs.princess)
		if off.z > 0.15:
			# on the story's stage the cue's offset is in server units, like the fly; the long hall keeps its old placement
			var est := HallCam.from_server(_fly_target) + off
			if HallCam.stage:
				est = HallCam.from_server(_fly_target + Vector3(off.x / HallCam.SX, off.y, off.z / HallCam.COURSE_SCALE))
			_princess = est if not _princess_seen else _princess.lerp(est, 0.25)
			_princess_seen = true
		_princess_visible = true
	else:
		# render.princess is null: she is not in this scene. Outside play
		# (lobby, chronicle) she stays on her dais as part of the backdrop.
		_princess_visible = cs.phase != "play" or not cs.has_fly
	_giant_cue = cs.giant
	_apply_story(cs)


## The story's scene: backdrop or hall, the stage's walls, Miranda only where the story puts her, props and impacts.
func _apply_story(cs: CourtState) -> void:
	story = cs.scene != ""
	var was_stage := HallCam.stage
	HallCam.stage = story and cs.backdrop in OPEN_BACKDROPS
	if HallCam.stage != was_stage:
		_fly_shown = _fly_target  # the mapping changed: no glide across the screen
		HallCam.follow(HallCam.from_server(_fly_shown), 0.0, true)
	for r in rivals:  # the hall's decorative rivals aren't in the story's cast (and Sir Indy isn't in it at all)
		(r as Node2D).visible = not story
	if not story:
		_backdrop.visible = false
		for l in layers:
			(l as CanvasItem).visible = true
		HallBuilder.walls = HallBuilder.COURSE_WALLS
		props.visible = false
		hamlet.carrying = false
		cast.show_set("")
		weather.set_mode("")
		return
	# Flying scenes with one of Anshul's backgrounds_v2 sets (garden, great hall, banquet) paint it through the hall layers,
	# with its cast; other open backdrops (only ever behind a comic) are his v4 paintings.
	weather.set_mode({"GIANT": "storm", "FATHER": "hellfire"}.get(cs.scene, "") if cs.phase in ["ready", "play"] else "")
	var set_name: String = STORY_CAST.set_for(cs.backdrop)
	cast.show_set(set_name)
	var open := cs.backdrop in OPEN_BACKDROPS and set_name == ""
	if open and cs.backdrop != _backdrop_id:
		_backdrop_id = cs.backdrop
		_backdrop.texture = StoryArt.backdrop(cs.backdrop)
	_backdrop.visible = open and _backdrop.texture != null
	for l in layers:
		(l as CanvasItem).visible = not _backdrop.visible
	HallBuilder.walls = cs.walls if cs.has_walls else []
	_princess_visible = not cs.princess.is_empty()
	props.set_props(cs.props)
	hamlet.carrying = cs.scene == "TUTORIAL" and bool(cs.counters.get("carrying", false))
	if not cs.impact.is_empty() and cs.impact.get("at") != _impact.get("at"):
		_impact = cs.impact
		_impact_left = 0.9
		var hp := HallCam.from_server(Vector3(float(_impact["x"]), float(_impact["y"]), float(_impact["z"])))
		_impact_target = Vector3(hp.x, _ground_y(hp.x, hp.z), hp.z)
		var sp := HallCam.project(_impact_target)
		shake(0.3, 3)
		if str(_impact.get("fight", "")) == "father":
			fx.splat(Vector2(sp.x, HallCam.project(hp).y))
		else:
			fx.puff(Vector2(sp.x, sp.y), 10)


func set_cosmetic(relic: String, on: bool) -> void:
	hamlet.set_cosmetic(relic, on)


func shake(duration: float, px: int) -> void:
	_shake_left = maxf(_shake_left, duration)
	_shake_px = maxi(_shake_px if _shake_left > 0.0 else 0, px)


## Visual reactions to server/voice events (event ids from docs/LORE.md).
func on_event(ev: Dictionary) -> void:
	var kind := str(ev.get("kind", ""))
	var id := str(ev.get("id", ""))
	if kind == "bump":  # flew into a wall: it's solid
		shake(0.15, 2)
		hamlet.play_gesture("hit", 0.3)
		fx.puff(hamlet_screen + Vector2(0, -6), 5)
		return
	if kind == "hit":  # an attack landed on him (the story server; only ever after it resolves)
		cast.startle()
		hamlet.play_gesture("hit", 0.45)
		fx.splat(hamlet_screen)
		shake(0.35, 3)
	elif kind == "dodge":
		fx.puff(hamlet_screen + Vector2(0, 10), 6)
	elif kind == "splat" or id == "H_SPLAT":
		hamlet.play_gesture("hit", 0.45)
		fx.splat(hamlet_screen)
		shake(0.35, 3)
	elif kind in ["jump", "escape"] or id == "H_JUMP":
		fx.puff(hamlet_screen + Vector2(0, 10), 8)
		shake(0.15, 1)
	elif kind in ["win", "charmed", "hearts"] or id in ["H_WIN", "P_CHARMED", "H_WEDDING", "P_WEDDING"]:
		hamlet.play_gesture("celebrate", 1.8)
		fx.hearts((hamlet_screen + miranda.position) / 2.0, 6)
		fx.hearts(miranda.position + Vector2(0, -10), 4)
	elif kind == "giant" or id == "H_WARN_GIANT":
		shake(0.2, 1)


func _process(delta: float) -> void:
	_t += delta
	# Server states come 30 times a second but not evenly (Wi-Fi, a busy laptop). Carry him on at his last velocity for up
	# to a tenth of a second, then ease onto it, so he glides instead of stepping.
	_since_state += delta
	var ahead := _fly_target
	if state.has_fly and state.phase in ["", "play"]:
		ahead += state.fly_vel * minf(_since_state, 0.1)
		ahead.z = _wall_clamp(_fly_target, ahead.z)
	_fly_shown = _fly_shown.lerp(ahead, 1.0 - exp(-delta * 20.0))
	var shadow_items: Array = []

	# --- Hamlet, and the camera chasing him (everything below projects through it)
	var hp := HallCam.from_server(_fly_shown)
	HallCam.follow(hp, delta)
	HallBuilder.passed_z = HallCam.from_server(_fly_shown).z  # walls he's through stop drawing
	var proj := HallCam.project(hp)
	# the chase camera sits right behind him: smaller there, so he never hides the wall openings ahead
	var hh := clampi(roundi(HAMLET_SIZE * (1.0 if HallCam.stage else 0.62) * proj.z / 2.0) * 2, 16, 96)
	hamlet.set_body_px(hh)
	var speed := state.fly_vel.length() if state.has_fly else 0.0
	var bob := 0.0 if speed > 0.15 else roundf(sin(_t * 3.2) * 1.2)
	hamlet.position = Vector2(roundf(proj.x), roundf(proj.y + bob))
	hamlet_screen = hamlet.position
	hamlet.set_motion(state.fly_vel if state.has_fly else Vector3.ZERO)
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
		if story:  # not in the story's cast: rival.gd would show them again every frame
			r.visible = false
			continue
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
		var h_below := below_y < 300
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
	_impact_left = maxf(0.0, _impact_left - get_process_delta_time())
	if _giant_cue.is_empty() and _impact_left > 0.0 and str(_impact.get("fight", "")) != "father":
		# the story's hand, only once it has landed: where it came down, for a moment
		giant.show_hazard(_impact_target, 1.0)
		var ip := HallCam.project(_impact_target)
		shadow_items.append({"pos": Vector2i(roundi(ip.x), roundi(ip.y)), "rx": maxi(4, roundi(ip.z * 0.4)), "ry": 3, "ring": false})
		giant_in_view = false
		return
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


## The server's walls are solid: the glide between server states never carries him through one (it would snap back).
func _wall_clamp(at: Vector3, z: float) -> float:
	if not state.has_walls:
		return z
	for w in state.walls:
		var wz := float(w[0])
		var open := at.x >= float(w[1]) + 0.1 and at.x <= float(w[2]) - 0.1 and at.y >= float(w[3]) + 0.1 and at.y <= float(w[4]) - 0.1
		if open:
			continue
		if at.z <= wz and z > wz - 0.06:
			z = minf(z, maxf(at.z, wz - 0.06))
		elif at.z >= wz and z < wz + 0.06:
			z = maxf(z, minf(at.z, wz + 0.06))
	return z


func _ground_y(x: float, z: float) -> float:
	if HallCam.stage:  # the painted backdrop's flat floor, no dais
		return HallCam.FLOOR_Y
	if absf(x) <= HallBuilder.DAIS_X:
		if z >= HallBuilder.DAIS_STEP:
			return HallBuilder.DAIS_Y2
		if z >= HallBuilder.DAIS_FRONT:
			return HallBuilder.DAIS_Y1
	return HallCam.FLOOR_Y


func _sort_actors(hamlet_z: float) -> void:
	var giant_z := _impact_target.z - 0.4 if _impact_left > 0.0 else _giant_target.z  # a landed fist covers whoever it hit
	var order: Array = [[hamlet_z, hamlet], [_princess.z, miranda], [giant_z if giant.showing else -99.0, giant], [props.depth(), props]]
	for r in rivals:
		order.append([r.depth(), r])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in order.size():
		var node: Node = order[i][1]
		if node.get_index() != i:
			actors.move_child(node, i)


func _animate_props() -> void:
	for l in layers:
		(l as HallLayer).anim_step = _anim_step
