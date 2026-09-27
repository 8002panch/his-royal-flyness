class_name LobbyOverlay
extends Control

## Lobby: a parchment scroll over the dimmed hall with the room code on a wax
## seal and the four Privy Council seats. Reads `room` and `players`
## ([{name, role}]); both are provisional (no real message defines them yet),
## so an empty code shows as "----" and every seat as open.

const HINTS := {"helmsman": "LEFT / RIGHT", "liftmaster": "CLIMB / DIVE", "wingmaster": "FORTH / BRAKE", "seer": "HOLD TO SCAN"}

var room := ""
var seats := {}
var sample := false
var qr: Array = []          # the join link as QR rows ("1" = dark), from the story server's lobby state
var story := false          # the story server is waiting for Enter
var _dither: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var c := PixelCanvas.new(2, 2)
	c.px(0, 0, Pal.INK)
	c.px(1, 1, Pal.INK)
	_dither = c.texture()


func apply(cs: CourtState) -> void:
	room = cs.room
	sample = cs.sample
	qr = cs.join_qr
	story = cs.scene == "LOBBY"
	seats = {}
	for p in cs.players:
		if p is Dictionary:
			seats[str(p.get("role", ""))] = str(p.get("name", ""))
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_dither, Rect2(0, 0, HallCam.W, HallCam.H), true)
	var r := Rect2i(100, 34, 440, 282)
	_scroll(self, r)
	var cx := 320
	HudDraw.text_center(self, PixelFonts.title(), cx, 42, "His Royal Flyness", Pal.INK, PixelFonts.TITLE_SIZE)
	HudDraw.text_center(self, PixelFonts.bold(), cx, 66, "THE ROYAL BALL OF THE FRUIT BOWL", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	_flourish(self, cx, 80, 150)

	# the seal
	var code := room if room != "" else "----"
	HudDraw.text_center(self, PixelFonts.bold(), 204, 90, "PRESENT YOUR SEAL", Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.tex_center(self, SpriteForge.wax_seal(30), Vector2i(204, 132))
	HudDraw.text_center(self, PixelFonts.bold(), 204, 124, code, Pal.PARCHMENT, 16)
	HudDraw.text_center(self, PixelFonts.label(), 204, 170, "ROOM CODE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	# how to join
	var x := 280
	HudDraw.text(self, PixelFonts.bold(), x, 96, "JOIN ON YOUR PHONE", Pal.ROYAL, PixelFonts.LABEL_SIZE)
	var steps := ["OPEN THE CONTROLLER PAGE", "ENTER THE SEAL  " + code, "PICK A SEAT BELOW"]
	if not qr.is_empty():
		steps = ["SCAN THE CODE", "OR ENTER THE SEAL  " + code, "PICK A SEAT BELOW"]
		_draw_qr(Rect2i(438, 88, 92, 92))
	for i in steps.size():
		var y := 112 + i * 16
		draw_rect(Rect2(x, y - 1, 11, 11), Pal.INK)
		draw_rect(Rect2(x + 1, y, 9, 9), Pal.GOLD)
		HudDraw.text(self, PixelFonts.bold(), x + 3, y + 1, str(i + 1), Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text(self, PixelFonts.label(), x + 16, y + 1, steps[i], Pal.INK, PixelFonts.LABEL_SIZE)

	# the four seats
	var taken := 0
	for i in Pal.ROLE_ORDER.size():
		var role: String = Pal.ROLE_ORDER[i]
		var bx := 112 + i * 106
		var by := 188
		var filled := seats.has(role)
		if filled:
			taken += 1
		HudDraw.panel(self, Rect2i(bx, by, 100, 64), Pal.PARCHMENT if filled else Pal.PARCHMENT_DARK, Pal.INK,
			Pal.GOLD if filled else Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		HudDraw.tex_center(self, SpriteForge.role_icon(role, filled), Vector2i(bx + 50, by + 14))
		HudDraw.text_center(self, PixelFonts.bold(), bx + 50, by + 26, Pal.role_title(role), Pal.role_color(role) if filled else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		var who: String = seats[role].to_upper().left(12) if filled else "OPEN SEAT"
		HudDraw.text_center(self, PixelFonts.label(), bx + 50, by + 38, who, Pal.INK if filled else Pal.PARCHMENT_SHADE, PixelFonts.LABEL_SIZE)
		HudDraw.text_center(self, PixelFonts.label(), bx + 50, by + 50, HINTS[role], Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	HudDraw.text_center(self, PixelFonts.label(), cx, 262, "%d OF 4 SEATS TAKEN" % taken, Pal.INK, PixelFonts.LABEL_SIZE)
	HudDraw.text_center(self, PixelFonts.label(), cx, 276, "THE SEER'S CUES GO ONLY TO THE SEER'S PHONE", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	if story:
		var bw := PixelFonts.width(PixelFonts.bold(), "PRESS ENTER TO BEGIN THE STORY", PixelFonts.LABEL_SIZE) + 20
		HudDraw.panel(self, Rect2i(cx - bw / 2, 290, bw, 16), Pal.ROYAL, Pal.INK, Pal.GOLD, Pal.ROYAL_DARK)
		HudDraw.text_center(self, PixelFonts.bold(), cx, 294, "PRESS ENTER TO BEGIN THE STORY", Pal.GOLD_LIGHT, PixelFonts.LABEL_SIZE)
	if sample:
		_stamp(self, Vector2i(r.position.x + r.size.x - 84, r.position.y + r.size.y - 26))


## The join QR, whole modules only (nearest pixels), on white with a quiet border so phone cameras read it.
func _draw_qr(box: Rect2i) -> void:
	var n := qr.size()
	var cell := maxi(1, (box.size.x - 8) / n)
	var side := cell * n + 8
	var ox := box.position.x + (box.size.x - side) / 2
	var oy := box.position.y + (box.size.y - side) / 2
	draw_rect(Rect2(ox - 1, oy - 1, side + 2, side + 2), Pal.INK)
	draw_rect(Rect2(ox, oy, side, side), Color.WHITE)
	for y in n:
		var row := str(qr[y])
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(ox + 4 + x * cell, oy + 4 + y * cell, cell, cell), Color.BLACK)


static func _scroll(ci: CanvasItem, r: Rect2i) -> void:
	HudDraw.panel(ci, r)
	HudDraw.frame(ci, Rect2i(r.position.x + 4, r.position.y + 8, r.size.x - 8, r.size.y - 16), Pal.PARCHMENT_DARK)
	for ry in [r.position.y - 3, r.position.y + r.size.y - 5]:
		ci.draw_rect(Rect2(r.position.x - 8, ry, r.size.x + 16, 8), Pal.INK)
		ci.draw_rect(Rect2(r.position.x - 7, ry + 1, r.size.x + 14, 6), Pal.WOOD)
		ci.draw_rect(Rect2(r.position.x - 7, ry + 1, r.size.x + 14, 1), Pal.WOOD_LIGHT)
		for ex in [r.position.x - 11, r.position.x + r.size.x + 5]:
			ci.draw_rect(Rect2(ex, ry - 1, 6, 10), Pal.INK)
			ci.draw_rect(Rect2(ex + 1, ry, 4, 8), Pal.GOLD)
			ci.draw_rect(Rect2(ex + 1, ry, 1, 8), Pal.GOLD_LIGHT)


static func _flourish(ci: CanvasItem, cx: int, y: int, half: int) -> void:
	ci.draw_rect(Rect2(cx - half, y, half * 2, 1), Pal.GOLD)
	ci.draw_rect(Rect2(cx - 2, y - 2, 5, 5), Pal.INK)
	ci.draw_rect(Rect2(cx - 1, y - 1, 3, 3), Pal.CRIMSON)
	ci.draw_rect(Rect2(cx - half - 2, y - 1, 3, 3), Pal.GOLD)
	ci.draw_rect(Rect2(cx + half, y - 1, 3, 3), Pal.GOLD)


static func _stamp(ci: CanvasItem, at: Vector2i) -> void:
	var s := "OFFLINE SAMPLE"
	var w := PixelFonts.width(PixelFonts.bold(), s, PixelFonts.LABEL_SIZE) + 8
	HudDraw.frame(ci, Rect2i(at.x, at.y, w, 13), Pal.CRIMSON)
	HudDraw.frame(ci, Rect2i(at.x + 1, at.y + 1, w - 2, 11), Pal.CRIMSON)
	HudDraw.text(ci, PixelFonts.bold(), at.x + 4, at.y + 2, s, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
