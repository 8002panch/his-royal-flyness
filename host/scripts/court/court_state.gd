class_name CourtState
extends RefCounted

## Read-only view of one `state` message, with neutral defaults for anything
## missing. It never writes back, and GameState's parsing is untouched.
##
## Real fields (server/main.py GameSession.godot_state, Phase 3 on main):
##   phase, time
##   fly {x, y, z, vx, vy, vz}            body in the -1..1 cube
##   render.princess {bearing_deg, elevation_deg, distance_cm} | null
##   render.giant {bearing_deg, elevation_deg, distance_cm, approach_cm_s, size_cm} | null
##   roles {helmsman, liftmaster, wingmaster, seer}   true while that role's input is non-zero
##                                                    (for the Seer: while scanning)
## Provisional (no owner has defined these yet; each one reads as absent until sent):
##   trial ("I"/"II"/"III"), brain or cues.source ("true"/"changeling"/"placeholder"),
##   meters.candle (0..1), brainActivity {key: z-score} (team/anshul/README.md contract;
##   activity and cues.activity are accepted as fallbacks),
##   controls {x, y, z} (held intent), room, players [{name, role}], chronicle {...},
##   offline_sample (GameState tags every fallback frame with it) or sample: fixture data,
##   stamped OFFLINE SAMPLE on screen; frame (fixture frame index)
##
## Privacy: Seer cues (Princess bearing, Giant direction/ETA) are never read
## here for display. render.* is world geometry for drawing the hall, and only
## `seer_scanning` reaches the shared HUD.

var raw: Dictionary = {}
var phase := "play"
var time := 0.0
var frame := -1
var sample := false
var demo := false

var fly := Vector3.ZERO
var fly_vel := Vector3.ZERO
var has_fly := false

var princess: Dictionary = {}   # render.princess, or empty when not in the scene
var giant: Dictionary = {}      # render.giant, or empty when there is none

var roles_active := {"helmsman": false, "liftmaster": false, "wingmaster": false, "seer": false}
var controls := Vector3.ZERO
var has_controls := false
var seer_scanning := false

var trial := ""
var brain := ""
var candle := -1.0
var activity: Dictionary = {}

var room := ""
var players: Array = []
var chronicle: Dictionary = {}


static func read(msg: Dictionary) -> CourtState:
	var s := CourtState.new()
	s.raw = msg
	s.phase = str(msg.get("phase", "play"))
	s.time = _f(msg.get("time", 0.0))
	s.frame = int(_f(msg.get("frame", -1)))
	s.demo = bool(msg.get("demo", false))
	s.sample = bool(msg.get("offline_sample", false)) or bool(msg.get("sample", false))

	var fly_msg: Variant = msg.get("fly", null)
	if fly_msg is Dictionary:
		s.has_fly = true
		s.fly = Vector3(_f(fly_msg.get("x")), _f(fly_msg.get("y")), _f(fly_msg.get("z")))
		s.fly_vel = Vector3(_f(fly_msg.get("vx")), _f(fly_msg.get("vy")), _f(fly_msg.get("vz")))

	var render: Variant = msg.get("render", null)
	if render is Dictionary:
		if render.get("princess") is Dictionary:
			s.princess = render["princess"]
		if render.get("giant") is Dictionary:
			s.giant = render["giant"]

	var roles: Variant = msg.get("roles", null)
	if roles is Dictionary:
		for role in s.roles_active:
			s.roles_active[role] = bool(roles.get(role, false))
	var ctrl: Variant = msg.get("controls", null)
	if ctrl is Dictionary:
		s.has_controls = true
		s.controls = Vector3(_f(ctrl.get("x")), _f(ctrl.get("y")), _f(ctrl.get("z")))
	var seer: Variant = msg.get("seer", null)
	s.seer_scanning = s.roles_active["seer"]
	if seer is Dictionary and _f(seer.get("scan", 0)) > 0.0:
		s.seer_scanning = true

	s.trial = str(msg.get("trial", ""))
	var cues: Variant = msg.get("cues", null)
	s.brain = str(msg.get("brain", ""))
	if s.brain == "" and cues is Dictionary:
		s.brain = str(cues.get("source", ""))
	var meters: Variant = msg.get("meters", null)
	if meters is Dictionary and meters.has("candle"):
		s.candle = clampf(_f(meters["candle"]), 0.0, 1.0)

	var act: Variant = msg.get("brainActivity", null)
	if not act is Dictionary:
		act = msg.get("activity", null)
	if not act is Dictionary and cues is Dictionary:
		act = cues.get("activity", null)
	if act is Dictionary:
		for key in act:
			if act[key] is float or act[key] is int:
				s.activity[str(key)] = float(act[key])

	s.room = str(msg.get("room", ""))
	if msg.get("players") is Array:
		s.players = msg["players"]
	elif msg.get("players") is Dictionary:
		# docs/TECH.md's example shows {role: name}; server/main.py sends [{name, role}]. Accept both.
		for role in msg["players"]:
			s.players.append({"role": str(role), "name": str(msg["players"][role])})
	if msg.get("chronicle") is Dictionary:
		s.chronicle = msg["chronicle"]
	return s


static func _f(v: Variant) -> float:
	if v is float or v is int:
		return float(v)
	if v is bool:
		return 1.0 if v else 0.0
	return 0.0


## Magnitude only (0..1), so no bar can hint at a side. vision = her_L + her_R,
## flight = steer, reaction = looming + escape, song = song: the grouping in
## team/README.md#proposed-formats.
## The brain's side-free HUD signals (brain/seer.py `activity`): `vision` (the Princess detectors, LC10a/d), `looming`
## (LC4, LPLC2) and `escape` (the Giant Fiber, DNp01). Older fixtures' her_L/her_R still fill `vision`, magnitude only.
func activity_level(group: String) -> float:
	var keys: Array = [group]
	if group == "vision" and not activity.has("vision"):
		keys = ["her_L", "her_R"]
	var total := 0.0
	var n := 0
	for k in keys:
		if activity.has(k):
			total += absf(float(activity[k]))
			n += 1
	if n == 0:
		return -1.0
	return clampf(total / n / 3.0, 0.0, 1.0)


func has_activity() -> bool:
	return not activity.is_empty()


## Held intent per axis, -1..1. Uses `controls` if a server ever sends it,
## otherwise the sign of the authoritative velocity while the role is pressed.
func intent(axis: String) -> int:
	var role := {"x": "helmsman", "y": "liftmaster", "z": "wingmaster"}.get(axis, "") as String
	if has_controls:
		var v: float = controls[{"x": 0, "y": 1, "z": 2}[axis]]
		return signi(roundi(v))
	if not roles_active.get(role, false):
		return 0
	var vel: float = fly_vel[{"x": 0, "y": 1, "z": 2}[axis]]
	if absf(vel) < 0.02:
		return 0
	return 1 if vel > 0.0 else -1
