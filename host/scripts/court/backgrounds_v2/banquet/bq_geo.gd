extends RefCounted

## Shared hall-space helpers for the Banquet v2 background (projection, quads,
## boxes, the pointed arch, a tiny deterministic hash). Same coordinate system
## as HallCam / HallBuilder: x lateral, y up, z into the hall.

const GRID_Z := -3.5
const SPRING := 1.3
const COLUMN_R := 0.17
const COLUMNS_Z := [-2.0, -0.9, 0.2, 1.3]
const TABLE_TOP := -0.88
const DAIS_X := 1.15
const DAIS_FRONT := 0.55
const DAIS_STEP := 0.7
const DAIS_Y1 := -1.18
const DAIS_Y2 := -1.06
const CARPET_HALF := 0.45

static var ZN := -3.5


static func P(x: float, y: float, z: float) -> Vector2:
	return HallCam.pt(Vector3(x, y, z))


static func grid_start(step: float, offset: float = 0.0) -> float:
	return GRID_Z + offset + floorf((ZN - GRID_Z - offset) / step) * step


## Deterministic 0..1 noise from integer cell coordinates.
static func hash(i: int, j: int, k: int = 0) -> float:
	var h: int = i * 374761393 + j * 668265263 + k * 1274126177
	h = (h ^ (h >> 13)) * 1103515245
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


static func quad_x(c, x: float, y0: float, y1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([P(x, y0, z0), P(x, y0, z1), P(x, y1, z1), P(x, y1, z0)])
	c.poly(q, col)
	return q


static func quad_y(c, y: float, x0: float, x1: float, z0: float, z1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([P(x0, y, z0), P(x1, y, z0), P(x1, y, z1), P(x0, y, z1)])
	c.poly(q, col)
	return q


static func quad_z(c, z: float, x0: float, x1: float, y0: float, y1: float, col: Color) -> PackedVector2Array:
	var q := PackedVector2Array([P(x0, y0, z), P(x1, y0, z), P(x1, y1, z), P(x0, y1, z)])
	c.poly(q, col)
	return q


static func on_x(uv: PackedVector2Array, x: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(P(x, p.y, p.x))
	return out


static func on_z(uv: PackedVector2Array, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in uv:
		out.append(P(p.x, p.y, z))
	return out


static func ln(c, a: Vector3, b: Vector3, col: Color) -> void:
	c.linev(P(a.x, a.y, a.z), P(b.x, b.y, b.z), col)


## An axis-aligned box: its top, the side facing the camera, and its near end.
static func box(c, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float,
		top: Color, side: Color, end: Color, edge: Color = Pal.INK) -> void:
	z0 = maxf(z0, ZN)
	if z1 <= z0 + 0.01:
		return
	var cam := HallCam.CAM
	if cam.x < x0:
		c.poly_outline(quad_x(c, x0, y0, y1, z0, z1, side), edge)
	elif cam.x > x1:
		c.poly_outline(quad_x(c, x1, y0, y1, z0, z1, side), edge)
	c.poly_outline(quad_z(c, z0, x0, x1, y0, y1, end), edge)
	if cam.y > y1:
		c.poly_outline(quad_y(c, y1, x0, x1, z0, z1, top), edge)


## Pointed (gothic) arch outline in 2D (u across, v up); same shape as HallBuilder._arch.
static func arch(cu: float, half: float, spring: float, sharp: float, steps: int = 10) -> PackedVector2Array:
	var r := half * 2.0 * sharp
	var pts := PackedVector2Array()
	var apex_v := spring + sqrt(maxf(0.0, r * r - (r - half) * (r - half)))
	var cl := Vector2(cu - half + r, spring)
	var a0 := PI
	var a1 := atan2(apex_v - spring, cu - cl.x)
	for i in range(steps + 1):
		var a := lerpf(a0, a1, float(i) / steps)
		pts.append(Vector2(cl.x + cos(a) * r, spring + sin(a) * r))
	var cr := Vector2(cu + half - r, spring)
	var b0 := atan2(apex_v - spring, cu - cr.x)
	for i in range(1, steps + 1):
		var a := lerpf(b0, 0.0, float(i) / steps)
		pts.append(Vector2(cr.x + cos(a) * r, spring + sin(a) * r))
	return pts


static func arch_apex(half: float, spring: float, sharp: float) -> float:
	var r := half * 2.0 * sharp
	return spring + sqrt(maxf(0.0, r * r - (r - half) * (r - half)))


## Foreshortening of a horizontal circle at height y and depth z:
## returns Vector3(screen x, screen y, ry/rx ratio) with the pixel scale in `s`.
static func flat(x: float, y: float, z: float) -> Vector4:
	var d := Vector3(x, y, z) - HallCam.CAM
	if d.z < HallCam.NEAR:
		return Vector4(0, 0, 0, -1)
	var s := HallCam.F / d.z
	return Vector4(HallCam.CX + d.x * s, HallCam.HORIZON - d.y * s, clampf(-d.y / d.z, 0.05, 1.5), s)
