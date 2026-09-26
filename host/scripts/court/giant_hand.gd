class_name GiantHand
extends Node2D

## The Giant's hand: comes down out of the dark above the hall onto a spot on
## the floor. Its shadow and target ring are drawn by the Shadows layer. The
## node's origin is the fingertips; the sleeve runs up off the top of the screen.

var hand := Sprite2D.new()
var palm_px := 0
var progress := 0.0
var showing := false


func _ready() -> void:
	hand.centered = false
	add_child(hand)
	visible = false


func show_hazard(target: Vector3, p: float) -> void:
	progress = p
	var s := HallCam.scale_at(target.z)
	var palm := clampi(roundi(0.85 * s / 4.0) * 4, 24, 128)
	if palm != palm_px:
		palm_px = palm
		hand.texture = SpriteForge.giant_hand(palm)
		var sz := SpriteForge.hand_size(palm)
		hand.offset = Vector2(-sz.x / 2, -sz.y + 2)
	# high above while far away, down to just over the floor when it lands
	var lift := pow(1.0 - p, 1.4) * 4.2
	var tip := HallCam.project(Vector3(target.x, target.y + 0.18 + lift, target.z))
	position = Vector2(roundf(tip.x), roundf(tip.y))
	showing = true
	visible = position.y > 0.0
	queue_redraw()


func hide_hazard() -> void:
	showing = false
	visible = false
	progress = 0.0


## The sleeve continues straight up to the top of the screen.
func _draw() -> void:
	if palm_px == 0:
		return
	var sz := SpriteForge.hand_size(palm_px)
	var top := -sz.y + 2
	if position.y + top <= 0:
		return
	var ox := -sz.x / 2 + 2 + roundi(0.2 * palm_px)
	var x0 := ox - roundi(0.08 * palm_px)
	var w := roundi(1.16 * palm_px)
	var h := roundi(position.y + top) + 2
	draw_rect(Rect2(x0 - 1, top - h, w + 2, h + 1), Pal.INK)
	draw_rect(Rect2(x0, top - h, w, h + 1), Pal.ROYAL_DARK)
	for k in 3:
		draw_rect(Rect2(x0 + roundi((0.28 + 0.3 * k) * palm_px), top - h, 1, h + 1), Pal.ROYAL)
