class_name HallCam
extends RefCounted

## The fixed camera the Banquet Hall is drawn through. It stands at the hall's
## entrance looking down the carpet. The prince flies away from it towards
## Miranda, so he shrinks as he advances.
##
## Hall space: x = lateral, y = altitude, z = depth (towards the back wall).
## The server's fly body lives in a -1..1 cube (server/movement.py bounds).
## `from_server` stretches x a little so the hall reads wider than it is deep.
##
## render.princess / render.giant arrive relative to the fly as bearing,
## elevation and distance in cm. server/seer_adapter.py's placeholder world
## uses 220 cm per body unit; UNIT_CM mirrors that and is the only coupling.

const W := 640
const H := 360
const CX := 320.0
const HORIZON := 34.0
const F := 300.0
const CAM := Vector3(0.0, 1.9, -4.5)
const NEAR := 0.5

const SX := 1.3
const UNIT_CM := 220.0

const FLOOR_Y := -1.3
const WALL_X := 2.45
const COLUMN_X := 2.05
const BACK_Z := 1.8
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


static func scale_at(z: float) -> float:
	return F / maxf(z - CAM.z, NEAR)


static func from_server(v: Vector3) -> Vector3:
	return Vector3(v.x * SX, v.y, v.z)


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
	return Vector3(depth * tb * SX, depth * te, depth)
