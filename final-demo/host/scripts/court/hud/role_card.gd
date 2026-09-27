class_name RoleCard
extends Control

## One of the four Privy Council roles along the bottom, in parchment. The
## bindings are unchanged: Helmsman = x (left/right), Liftmaster = y (climb/dive),
## Wingmaster = z (forward/brake), Seer = hold to scan. A card lights up gold
## while its role is pressing (state.roles) and its arrow shows which way; the
## small gauge is the server's authoritative fly position on that axis.

const CARD_SIZE := Vector2i(154, 40)

var role := "helmsman"
var active := false
var intent := 0
var axis_value := 0.0
var has_value := false
var scanning := false
var player := ""
var _t := 0.0


func setup(r: String, pos: Vector2i) -> void:
	role = r
	position = Vector2(pos)
	size = Vector2(CARD_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func apply(cs: CourtState) -> void:
	active = bool(cs.roles_active.get(role, false))
	scanning = cs.seer_scanning
	has_value = cs.has_fly
	player = ""
	for p in cs.players:
		if p is Dictionary and str(p.get("role", "")) == role:
			player = str(p.get("name", ""))
	match role:
		"helmsman":
			intent = cs.intent("x")
			axis_value = cs.fly.x
		"liftmaster":
			intent = cs.intent("y")
			axis_value = cs.fly.y
		"wingmaster":
			intent = cs.intent("z")
			axis_value = cs.fly.z
		"seer":
			active = scanning
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if active:
		queue_redraw()


func _draw() -> void:
	var w := CARD_SIZE.x
	var h := CARD_SIZE.y
	var col := Pal.role_color(role)
	if active:
		HudDraw.panel(self, Rect2i(0, 0, w, h), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
		HudDraw.frame(self, Rect2i(1, 1, w - 2, h - 2), Pal.GOLD)
		HudDraw.frame(self, Rect2i(2, 2, w - 4, h - 4), Pal.GOLD_LIGHT)
	else:
		HudDraw.panel(self, Rect2i(0, 0, w, h), Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_DARK)
	# role colour stripe on the left edge
	draw_rect(Rect2(1, 4, 2, h - 8), col)

	var hop := -1 if active and int(_t * 6.0) % 2 == 0 else 0
	HudDraw.tex(self, SpriteForge.role_icon(role, true), Vector2i(6, 11 + hop))
	var bold := PixelFonts.bold()
	var label := PixelFonts.label()
	HudDraw.text(self, bold, 27, 5, Pal.role_title(role), col if role != "liftmaster" else Pal.INK, PixelFonts.LABEL_SIZE)
	if player != "":
		HudDraw.text_right(self, label, w - 6, 5, player.to_upper().left(8), Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	match role:
		"helmsman":
			_hint(["left", "LEFT", "RIGHT", "right"])
			_gauge_h(Rect2i(102, 26, 46, 7), axis_value)
		"liftmaster":
			_hint(["up", "CLIMB", "DIVE", "down"])
			_gauge_v(Rect2i(140, 5, 7, 30), axis_value)
		"wingmaster":
			_hint(["up", "FORTH", "BRAKE", "down"])
			_gauge_h(Rect2i(102, 26, 46, 7), axis_value)
		"seer":
			HudDraw.text(self, label, 27, 16, "HOLD TO SCAN", Pal.INK, PixelFonts.LABEL_SIZE)
			var on := scanning and int(_t * 4.0) % 2 == 0
			draw_rect(Rect2(27, 28, 7, 7), Pal.INK)
			draw_rect(Rect2(28, 29, 5, 5), Pal.GOLD if on else (Pal.GOLD_DARK if scanning else Pal.PARCHMENT_SHADE))
			HudDraw.text(self, bold, 38, 28, "SCANNING" if scanning else "RESTING", Pal.ROYAL if scanning else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


## "[<] LEFT  RIGHT [>]": the arrow in the held direction fills with colour.
func _hint(parts: Array) -> void:
	var label := PixelFonts.label()
	var col := Pal.role_color(role)
	var neg_on := intent < 0
	var pos_on := intent > 0
	# for x the positive direction is right; for y and z it is up/forward
	var first_on := neg_on if role == "helmsman" else pos_on
	var second_on := pos_on if role == "helmsman" else neg_on
	var x := 27
	HudDraw.tex(self, SpriteForge.arrow(parts[0], first_on, col), Vector2i(x, 15))
	x += 11
	x += HudDraw.text(self, label, x, 16, parts[1], Pal.INK if first_on or not active else Pal.INK_SOFT, PixelFonts.LABEL_SIZE) + 5
	x += HudDraw.text(self, label, x, 16, parts[2], Pal.INK if second_on or not active else Pal.INK_SOFT, PixelFonts.LABEL_SIZE) + 2
	HudDraw.tex(self, SpriteForge.arrow(parts[3], second_on, col), Vector2i(x, 15))
	# second line: what it does, in plain words
	var what: String = {"helmsman": "STEER", "liftmaster": "ALTITUDE", "wingmaster": "SPEED"}.get(role, "")
	HudDraw.text(self, label, 27, 27, what, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


func _gauge_h(r: Rect2i, v: float) -> void:
	draw_rect(Rect2(r.position, r.size), Pal.INK)
	draw_rect(Rect2(r.position + Vector2i(1, 1), r.size - Vector2i(2, 2)), Pal.PARCHMENT_DARK)
	var mid := r.position.x + r.size.x / 2
	draw_rect(Rect2(mid, r.position.y + 1, 1, r.size.y - 2), Pal.PARCHMENT_SHADE)
	var kx := mid + roundi(clampf(v, -1.0, 1.0) * (r.size.x / 2 - 3))
	var col := Pal.role_color(role) if has_value else Pal.PARCHMENT_SHADE
	draw_rect(Rect2(kx - 2, r.position.y - 1, 5, r.size.y + 2), Pal.INK)
	draw_rect(Rect2(kx - 1, r.position.y, 3, r.size.y), col)


func _gauge_v(r: Rect2i, v: float) -> void:
	draw_rect(Rect2(r.position, r.size), Pal.INK)
	draw_rect(Rect2(r.position + Vector2i(1, 1), r.size - Vector2i(2, 2)), Pal.PARCHMENT_DARK)
	var mid := r.position.y + r.size.y / 2
	draw_rect(Rect2(r.position.x + 1, mid, r.size.x - 2, 1), Pal.PARCHMENT_SHADE)
	var ky := mid - roundi(clampf(v, -1.0, 1.0) * (r.size.y / 2 - 3))
	var col := Pal.GOLD if has_value else Pal.PARCHMENT_SHADE
	draw_rect(Rect2(r.position.x - 1, ky - 2, r.size.x + 2, 5), Pal.INK)
	draw_rect(Rect2(r.position.x, ky - 1, r.size.x, 3), col)
