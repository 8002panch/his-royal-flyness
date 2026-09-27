class_name HallCam
extends RefCounted

## The camera the Banquet Hall is drawn through. By default it is a chase
## camera: it follows Hamlet from behind and above (with a little lag), so the
## hall moves past him while he stays near the same spot on screen. `chase =
## false` gives the original fixed view from the doors (F4 in the court).
##
## Hall space: x = lateral, y = altitude, z = depth (towards the back wall).
## The server's fly body currently lives in a -1..1 cube. `from_server`
## maps that short authoritative range across the long visual course below;
## this is presentation only until the server's course bounds and collisions
## are expanded too. The spare central stretch is deliberately reserved for
## future obstacles.
##
## render.princess arrives relative to the fly as bearing, elevation and
## distance in cm. server/seer_adapter.py's placeholder world
## uses 220 cm per body unit; UNIT_CM mirrors that and is the only coupling.

const W := 640
const H := 360
const CX := 320.0
const F := 300.0
const NEAR := 0.5

## Course geometry in hall units. Keep obstacle placement inside the marked
## stretch so the entry, Queen's dais, and camera breathing room stay clear.
const COURSE_START_Z := -3.0
const COURSE_END_Z := 21.5
const OBSTACLE_START_Z := -1.5
const OBSTACLE_END_Z := 20.0
const COURSE_SCALE := (COURSE_END_Z - COURSE_START_Z) / 2.0

## Fixed view (the doors) and the chase offset from Hamlet, in hall units.
const FIXED_CAM := Vector3(0.0, 1.9, -5.5)
const FIXED_HORIZON := 34.0
const CHASE_OFFSET := Vector3(0.0, 1.7, -2.9)
const CHASE_HORIZON := 60.0
const CHASE_FOLLOW_X := 0.85
const CHASE_LAG := 5.0   # 1/s; higher = tighter follow

static var chase := true

## The story's open scenes (the garden and the fight arenas) are Anshul's painted backdrops, which don't move. There the
## camera stands still, matched to the painting's floor, and the server's -1..1 cube maps onto the stage in front of it
## (not onto the long course), so everything in the scene stays in view.
static var stage := false
const STAGE_CAM := Vector3(0.0, 2.2, -4.2)
const STAGE_HORIZON := 64.0
const STAGE_SX := 1.6   # keeps his -1..1 inside the garden path and the halls' aisles
const STAGE_DEPTH := 3.0   # hall units per server unit of depth
static var CAM := FIXED_CAM
static var HORIZON := FIXED_HORIZON

const SX := 1.3
const UNIT_CM := 220.0

const FLOOR_Y := -1.3
const WALL_X := 2.45
const COLUMN_X := 2.05
const BACK_Z := 23.0
const TOP_Y := 3.2


static func project(p: Vector3) -> Vector3:
	## (screen x, screen y, pixels per hall unit). z <= 0 means behind the camera.
	var d := p - CAM
	if d.z < NEAR:
		return Vector3(0, 0, -1)
	var s := F / d.z
	return Vector3(CX + d.x * s, HORIZON - d.y * s, s)


static func pt(p: Vector3) -> Vector2:
	var d := p - CAM
	var dz := maxf(d.z, NEAR)
	var s := F / dz
	return Vector2(CX + d.x * s, HORIZON - d.y * s)


## Move the camera towards its place behind `target` (Hamlet, hall space).
## `snap` jumps straight there (first frame, or after a reset).
static func follow(target: Vector3, delta: float, snap: bool = false) -> void:
	if stage:
		CAM = STAGE_CAM
		HORIZON = STAGE_HORIZON
		return
	if not chase:
		CAM = FIXED_CAM
		HORIZON = FIXED_HORIZON
		return
	var want := Vector3(target.x * CHASE_FOLLOW_X, target.y * 0.6, target.z) + CHASE_OFFSET
	CAM = want if snap else CAM.lerp(want, 1.0 - exp(-delta * CHASE_LAG))
	HORIZON = CHASE_HORIZON


## The nearest depth worth drawing: anything closer is behind or inside the lens.
static func near_z() -> float:
	return CAM.z + NEAR + 0.05


static func scale_at(z: float) -> float:
	return F / maxf(z - CAM.z, NEAR)


static func from_server(v: Vector3) -> Vector3:
	if stage:
		return Vector3(v.x * STAGE_SX, v.y, (v.z + 1.0) * STAGE_DEPTH)
	return Vector3(v.x * SX, v.y, lerpf(COURSE_START_Z, COURSE_END_Z, (v.z + 1.0) * 0.5))


## Converts a bearing/elevation/distance stimulus into a hall-space offset from
## the fly. Matches server/seer_adapter.py: bearing = atan2(dx, depth),
## elevation = atan2(dy, depth), distance = |(dx, dy, depth)| * UNIT_CM.
static func offset_from_cue(cue: Dictionary) -> Vector3:
	var b := deg_to_rad(float(cue.get("bearing_deg", 0.0)))
	var e := deg_to_rad(float(cue.get("elevation_deg", 0.0)))
	var d := float(cue.get("distance_cm", 0.0)) / UNIT_CM
	var tb := tan(clampf(b, -1.45, 1.45))
	var te := tan(clampf(e, -1.45, 1.45))
	var depth := d / sqrt(1.0 + tb * tb + te * te)
	return Vector3(depth * tb * SX, depth * te, depth * COURSE_SCALE)
