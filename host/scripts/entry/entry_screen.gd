extends Control

## The 640x360 title screen. Everything is drawn on native pixels and the
## project scales it with nearest filtering. No server message is invented here.
## The stage on the right is Anshul's art: the v4 banquet backdrop with the animated
## Hamlet and Miranda cast rigs (animation_v1), the same ones the game uses.

const COURT := "res://scenes/Court.tscn"
const BUTTONS := [Rect2i(36, 214, 240, 28), Rect2i(36, 248, 240, 26), Rect2i(36, 280, 240, 22)]
const DEVELOPERS := ["NEIL", "ARNAV", "VED", "ANSHUL"]

var _backdrop: ImageTexture
var _hover := -1
var _busy := false
var _wing_frame := 0
var _wing_clock := 0.0
var _help := false
var _credits := false
var _stage: ImageTexture
var _hamlet: Node2D
var _miranda: Node2D
var _t := 0.0
var _wave_t := 2.5

const STAGE := Rect2i(309, 7, 324, 346)
const HAMLET_AT := Vector2(440, 246)


func _ready() -> void:
	_backdrop = _build_backdrop().texture()
	_stage = StoryArt.backdrop("banquet")
	_hamlet = StoryArt.rig("hamlet", "")
	_miranda = StoryArt.rig("miranda", "")
	if _hamlet != null:
		add_child(_hamlet)
		_hamlet.scale = Vector2(1.9, 1.9)
		_hamlet.position = HAMLET_AT
		_hamlet.set_motion("fly", 0.6, 1.0)
	if _miranda != null:
		add_child(_miranda)
		_miranda.scale = Vector2(1.6, 1.6)
		_miranda.position = Vector2(566, 300)
		_miranda.set_motion("idle", 0.0, -1.0)
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	# Preserve existing screenshot, dashboard and keyboard-demo CLI entry points.
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if str(arg).begins_with("--shot=") or str(arg).begins_with("--live_shot=") or str(arg) in ["--demo", "--dashboard"]:
			get_tree().change_scene_to_file.call_deferred(COURT)
			return
	queue_redraw()
	_credits = "--credits" in args  # screenshots of the Credits card
	for arg in args:
		if str(arg).begins_with("--entry-shot="):
			_save_shot.call_deferred(str(arg).trim_prefix("--entry-shot="))


func _process(delta: float) -> void:
	_t += delta
	for rig in [_hamlet, _miranda]:  # the How to Play and Credits cards cover the stage
		if rig != null:
			(rig as Node2D).visible = not (_help or _credits)
	if _hamlet != null:  # he hovers in place, drifting a little
		_hamlet.position = HAMLET_AT + Vector2(roundf(sin(_t * 0.9) * 6.0), roundf(sin(_t * 2.2) * 4.0))
	_wave_t -= delta
	if _wave_t <= 0.0:
		_wave_t = 5.0
		if _miranda != null:
			_miranda.play_gesture("wave", 1.4)
		if _hamlet != null:
			_hamlet.play_gesture("bow", 1.2)
	_wing_clock += delta
	if _wing_clock >= 0.075:
		_wing_clock = 0.0
		_wing_frame = (_wing_frame + 1) % 8
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseMotion:
		var next := _button_at(event.position)
		if next != _hover:
			_hover = next
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if next >= 0 else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _help or _credits:
			_help = false
			_credits = false
			queue_redraw()
			return
		var index := _button_at(event.position)
		if index == 2:
			_credits = true
			queue_redraw()
		elif index >= 0:
			_enter_court(index == 1)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _busy or key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_enter_court(false)
		KEY_D:
			_enter_court(true)
		KEY_H, KEY_F1:
			_help = not _help
			_credits = false
			queue_redraw()
		KEY_C:
			_credits = not _credits
			_help = false
			queue_redraw()
		KEY_ESCAPE:
			_help = false
			_credits = false
			queue_redraw()


func _button_at(pos: Vector2) -> int:
	for i in BUTTONS.size():
		if BUTTONS[i].has_point(Vector2i(pos)):
			return i
	return -1


func _enter_court(keyboard_demo: bool) -> void:
	_busy = true
	if keyboard_demo:
		GameState.set_meta("entry_keyboard_demo", true)
	var err := get_tree().change_scene_to_file(COURT)
	if err != OK:
		_busy = false
		if keyboard_demo:
			GameState.remove_meta("entry_keyboard_demo")
		push_error("Entry: could not open the court (%s)" % error_string(err))


func _draw() -> void:
	draw_texture(_backdrop, Vector2.ZERO)
	# An illuminated page on the left; the hall is a small stage on the right.
	HudDraw.panel(self, Rect2i(17, 16, 278, 328), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.frame(self, Rect2i(23, 22, 266, 316), Pal.GOLD_DARK)
	HudDraw.tex_center(self, SpriteForge.crown(), Vector2i(156, 48))
	HudDraw.text_center(self, PixelFonts.bold(), 156, 69, "A COURTSHIP BY COMMITTEE", Pal.CRIMSON, 8)
	HudDraw.text_center(self, PixelFonts.title(), 156, 91, "His Royal", Pal.INK, 25)
	HudDraw.text_center(self, PixelFonts.title(), 156, 120, "Flyness", Pal.INK, 34)
	_flourish(156, 169)
	HudDraw.text_center(self, PixelFonts.caption(), 156, 181, "Four minds. One tiny prince.", Pal.INK_SOFT, 13)
	HudDraw.text_center(self, PixelFonts.label(), 156, 201, "REACH PRINCESS MIRANDA", Pal.ROYAL, 8)
	_button(0, "ENTER THE COURT", "LIVE / LOBBY")
	_button(1, "PLAY KEYBOARD DEMO", "SOLO")
	_button(2, "CREDITS", "C")
	HudDraw.text_center(self, PixelFonts.label(), 156, 311, "ENTER LIVE   D DEMO   H HOW TO PLAY   C CREDITS", Pal.INK_SOFT, 7)
	HudDraw.text_center(self, PixelFonts.label(), 156, 326, "HACKUMBC 2026", Pal.GOLD_DARK, 7)

	# The stage: the banquet backdrop, cropped to the frame at native pixels, under the gold margin.
	if _stage != null:
		draw_texture_rect_region(_stage, Rect2(STAGE), Rect2(158, 7, STAGE.size.x, STAGE.size.y))
	else:
		_draw_old_hero()
	HudDraw.frame(self, Rect2i(309, 7, 324, 346), Pal.GOLD)
	HudDraw.frame(self, Rect2i(312, 10, 318, 340), Pal.GOLD_DARK)
	HudDraw.panel(self, Rect2i(394, 318, 154, 28), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.text_center(self, PixelFonts.bold(), 471, 322, "PRINCE HAMLET", Pal.INK, 8)
	HudDraw.text_center(self, PixelFonts.label(), 471, 334, "THE COURT AWAITS", Pal.CRIMSON, 8)
	if _help:
		_draw_help()
	elif _credits:
		_draw_credits()


## Only if the backdrop is missing: the old drawn hall stage and rear-view sprite.
func _draw_old_hero() -> void:
	var body := SpriteForge.hamlet_body(82)
	var wings := SpriteForge.hamlet_wings(82, _wing_frame)
	var at := Vector2i(460 - body.get_width() / 2, 144 - body.get_height() / 2)
	HudDraw.tex(self, wings, at)
	HudDraw.tex(self, body, at)


func _button(index: int, title: String, suffix: String) -> void:
	var r: Rect2i = BUTTONS[index]
	var active := _hover == index
	HudDraw.panel(self, r, Pal.GOLD if active else Pal.ROYAL_DARK, Pal.INK, Pal.GOLD, Pal.GOLD_DARK if active else Pal.ROYAL)
	HudDraw.text(self, PixelFonts.bold(), r.position.x + 12, r.position.y + (r.size.y - 9) / 2, title, Pal.INK if active else Pal.PARCHMENT, 8)
	HudDraw.text_right(self, PixelFonts.label(), r.end.x - 10, r.position.y + (r.size.y - 9) / 2, suffix, Pal.INK_SOFT if active else Pal.GOLD, 7)


func _flourish(cx: int, y: int) -> void:
	draw_rect(Rect2(cx - 79, y, 158, 1), Pal.GOLD_DARK)
	draw_rect(Rect2(cx - 3, y - 3, 7, 7), Pal.INK)
	draw_rect(Rect2(cx - 2, y - 2, 5, 5), Pal.CRIMSON)
	for x in [cx - 83, cx + 80]:
		draw_rect(Rect2(x, y - 2, 4, 5), Pal.GOLD)


## The team, on a parchment card over the stage (C or the Credits button; click or Esc closes it).
func _draw_credits() -> void:
	HudDraw.panel(self, Rect2i(319, 26, 302, 308), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.text_center(self, PixelFonts.title(), 470, 40, "Credits", Pal.INK, 22)
	HudDraw.text_center(self, PixelFonts.label(), 470, 77, "HIS ROYAL FLYNESS WAS MADE BY", Pal.CRIMSON, 8)
	for i in DEVELOPERS.size():
		var y := 100 + i * 42
		HudDraw.frame(self, Rect2i(336, y, 268, 35), Pal.GOLD_DARK)
		HudDraw.text_center(self, PixelFonts.bold(), 470, y + 10, DEVELOPERS[i], Pal.ROYAL, 16)
	HudDraw.text_center(self, PixelFonts.label(), 470, 284, "HACKUMBC 2026", Pal.INK, 8)
	HudDraw.text_center(self, PixelFonts.label(), 470, 308, "CLICK OR ESC TO CLOSE", Pal.GOLD_DARK, 8)


func _draw_help() -> void:
	HudDraw.panel(self, Rect2i(319, 26, 302, 308), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.text_center(self, PixelFonts.title(), 470, 40, "How to Play", Pal.INK, 22)
	HudDraw.text_center(self, PixelFonts.label(), 470, 77, "THE PRIVY COUNCIL SPLITS THE FLIGHT", Pal.CRIMSON, 8)
	var rows := [
		["HELMSMAN", "A / D", "STEER LEFT / RIGHT"],
		["LIFTMASTER", "SPACE / SHIFT", "CLIMB / DIVE"],
		["WINGMASTER", "W / S", "FLY FORWARD / BRAKE"],
		["ROYAL SEER", "HOLD E", "SCAN FOR CUES"],
	]
	for i in rows.size():
		var y := 100 + i * 42
		HudDraw.frame(self, Rect2i(336, y, 268, 35), Pal.GOLD_DARK)
		HudDraw.text(self, PixelFonts.bold(), 344, y + 5, rows[i][0], Pal.ROYAL, 8)
		HudDraw.text_right(self, PixelFonts.label(), 596, y + 5, rows[i][1], Pal.CRIMSON, 8)
		HudDraw.text(self, PixelFonts.label(), 344, y + 19, rows[i][2], Pal.INK_SOFT, 8)
	HudDraw.text_center(self, PixelFonts.label(), 470, 284, "PHONES CONTROL THE LIVE GAME", Pal.INK, 8)
	HudDraw.text_center(self, PixelFonts.label(), 470, 308, "CLICK OR ESC TO CLOSE", Pal.GOLD_DARK, 8)


func _build_backdrop() -> PixelCanvas:
	var c := PixelCanvas.new(640, 360)
	c.rect(0, 0, 640, 360, Pal.STONE_DEEP)
	c.rect(307, 0, 333, 360, Pal.STONE_DARK)
	# A dark blue Gothic vault with a flat gold arcade.
	c.poly(PackedVector2Array([Vector2(337, 237), Vector2(337, 80), Vector2(346, 45), Vector2(386, 17), Vector2(465, 0), Vector2(544, 17), Vector2(585, 45), Vector2(593, 80), Vector2(593, 237)]), Pal.GOLD_DARK)
	c.poly(PackedVector2Array([Vector2(341, 237), Vector2(341, 82), Vector2(350, 48), Vector2(389, 21), Vector2(465, 5), Vector2(541, 21), Vector2(581, 48), Vector2(589, 82), Vector2(589, 237)]), Pal.VAULT)
	for x in [359, 571]:
		c.rect(x, 78, 10, 166, Pal.STONE)
		c.rect(x + 2, 78, 2, 166, Pal.STONE_HI)
		c.rect(x - 5, 77, 20, 5, Pal.GOLD_DARK)
		c.rect(x - 5, 240, 20, 6, Pal.GOLD_DARK)
	# Far rose window and side banners.
	c.ellipse(465, 75, 31, 31, Pal.GOLD)
	c.ellipse(465, 75, 27, 27, Pal.ROYAL)
	c.ellipse(465, 75, 9, 9, Pal.CRIMSON)
	for p in [Vector2i(465, 51), Vector2i(465, 99), Vector2i(441, 75), Vector2i(489, 75)]:
		c.ellipse(p.x, p.y, 4, 4, Pal.GOLD)
	for x in [376, 544]:
		c.rect(x, 92, 30, 75, Pal.GOLD_DARK)
		c.rect(x + 2, 94, 26, 67, Pal.CRIMSON if x == 376 else Pal.ROYAL)
		c.poly(PackedVector2Array([Vector2(x + 2, 161), Vector2(x + 15, 174), Vector2(x + 28, 161)]), Pal.GOLD_DARK)
		c.ellipse(x + 15, 118, 6, 6, Pal.GOLD)
	# Empty court and carpet; each tile is one flat colour.
	c.poly(PackedVector2Array([Vector2(337, 234), Vector2(593, 234), Vector2(640, 360), Vector2(307, 360)]), Pal.GROUT)
	for row in range(7):
		var ya := 236 + row * row * 3
		var yb := mini(360, 236 + (row + 1) * (row + 1) * 3)
		var left := 337 - row * 6
		var width := 256 + row * 12
		for col in range(8):
			var tx := left + col * width / 8
			c.rect(tx + 1, ya + 1, width / 8 - 2, yb - ya - 1, Pal.FLOOR_A if (row + col) % 2 == 0 else Pal.FLOOR_B)
	c.poly(PackedVector2Array([Vector2(454, 235), Vector2(475, 235), Vector2(530, 360), Vector2(400, 360)]), Pal.GOLD_DARK)
	c.poly(PackedVector2Array([Vector2(456, 235), Vector2(473, 235), Vector2(526, 360), Vector2(404, 360)]), Pal.CRIMSON_DARK)
	# Manuscript margin frame around the stage.
	c.frame(309, 7, 324, 346, Pal.GOLD)
	c.frame(312, 10, 318, 340, Pal.GOLD_DARK)
	for p in [Vector2i(314, 12), Vector2i(625, 12), Vector2i(314, 345), Vector2i(625, 345)]:
		c.ellipse(p.x, p.y, 3, 3, Pal.GOLD)
	return c


func _save_shot(path: String) -> void:
	_hover = -1
	queue_redraw()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	print("entry shot -> %s (%s)" % [path, error_string(image.save_png(path))])
	get_tree().quit()
