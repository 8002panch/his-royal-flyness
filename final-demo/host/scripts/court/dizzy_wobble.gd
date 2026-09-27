extends CanvasLayer

## The dizzy screen: a full-screen swirl-and-wave distortion of the court (shaders/dizzy_wobble.gdshader), between the
## world and the HUD, so the banner, the Seer's panel and the comics stay readable. Strength follows the server's
## `dizzy` (0 to 3) while flying, eased in and out. Cosmetic: the handling change itself is the server's (campaign.steer).

const SHADER := preload("res://shaders/dizzy_wobble.gdshader")

var target := 0.0
var _rect := ColorRect.new()
var _mat := ShaderMaterial.new()
var _now := 0.0


func _ready() -> void:
	layer = 1
	_mat.shader = SHADER
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.position = Vector2.ZERO
	_rect.size = Vector2(HallCam.W, HallCam.H)
	_rect.visible = false
	add_child(_rect)


func apply(dizzy: int, phase: String) -> void:
	target = clampf(dizzy / 3.0, 0.0, 1.0) if phase in ["play", "ready"] else 0.0


func _process(delta: float) -> void:
	_now = move_toward(_now, target, delta * 0.8)
	_rect.visible = _now > 0.01
	_mat.set_shader_parameter("strength", _now)
