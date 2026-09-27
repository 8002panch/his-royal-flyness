extends Control

## The character introduction before the tutorial (server/campaign.py INTRO_CARDS): "Dramatis Personae", one card at a
## time. The current character stands large on the left, animated, with their part in the story and the real fly gene
## behind the name; the whole cast waits in a row along the bottom. The presenter moves on with Space / Right / Page Down,
## back with Left, and S skips to the garden. The last card is the council: the four phone roles.

const PANEL := Rect2i(26, 28, 588, 306)
const STAGE := Rect2i(38, 64, 214, 172)
const TEXT_X := 268
const TEXT_W := 334
const STRIP_Y := 296        # the cast row's feet
const RIGS := "res://assets/pixelart/animation_v1/rigs/%s.scn"
const COUNCIL := ["helmsman", "liftmaster", "wingmaster", "royal_seer"]
const COUNCIL_NAMES := ["HELMSMAN", "LIFTMASTER", "WINGMASTER", "ROYAL SEER"]

var auto := true          # auto play (court_main.gd): the cards move on by themselves
var card: Dictionary = {}
var index := 0
var count := 0
var cast: Array = []
var _dither: ImageTexture
var _stage_rigs: Array = []
var _strip_rigs: Array = []
var _stage_key := ""
var _strip_key := ""
var _t := 0.0
var _packed := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	var c := PixelCanvas.new(2, 2)
	c.px(0, 0, Pal.INK)
	c.px(1, 1, Pal.INK)
	_dither = c.texture()


func apply(cs: CourtState) -> void:
	var intro: Variant = cs.raw.get("intro", null)
	var on := cs.phase == "intro" and intro is Dictionary
	visible = on
	if not on:
		_clear(_stage_rigs)
		_clear(_strip_rigs)
		_stage_key = ""
		_strip_key = ""
		return
	card = intro.get("card", {})
	index = int(intro.get("index", 0))
	count = int(intro.get("count", 0))
	cast = intro.get("cast", [])
	var sk := ",".join(cast)
	if sk != _strip_key:
		_strip_key = sk
		_build_strip()
	var key := str(card.get("rig", ""))
	if key != _stage_key:
		_stage_key = key
		_build_stage(key)
	for i in _strip_rigs.size():
		var r: Node2D = _strip_rigs[i]
		if r != null:
			r.modulate = Color(1, 1, 1, 1) if i == index else Color(0.45, 0.42, 0.4, 1)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _rig(name: String) -> Node2D:
	if not _packed.has(name):
		_packed[name] = load(RIGS % name) if ResourceLoader.exists(RIGS % name) else null
	var p: PackedScene = _packed[name]
	return p.instantiate() as Node2D if p != null else null


func _clear(list: Array) -> void:
	for r in list:
		if r != null:
			(r as Node).queue_free()
	list.clear()


func _build_stage(key: String) -> void:
	_clear(_stage_rigs)
	if key == "giant":
		return  # the Giant is drawn as the fights draw its hand (SpriteForge.giant_hand), in _draw
	var names: Array = COUNCIL if key == "council" else [key]
	var n := names.size()
	var sc := 0.8 if n > 1 else 1.55
	for i in n:
		var r := _rig(str(names[i]))
		if r == null:
			continue
		add_child(r)
		r.position = Vector2(STAGE.position.x + STAGE.size.x * (i + 1) / (n + 1), STAGE.position.y + STAGE.size.y - 12)
		r.scale = Vector2(sc, sc)
		if r.has_method("set_motion"):
			r.set_motion("idle", 0.0, 1.0)
		if r.has_method("play_gesture"):
			r.play_gesture("wave" if n == 1 else "celebrate", 1.6)
		_stage_rigs.append(r)


func _build_strip() -> void:
	_clear(_strip_rigs)
	var n := cast.size()
	for i in n:
		var name := str(cast[i])
		var r: Node2D = null if name == "giant" else _rig("royal_seer" if name == "council" else name)
		if r != null:
			add_child(r)
			r.position = Vector2(PANEL.position.x + 20 + (PANEL.size.x - 40) * (i + 0.5) / n, STRIP_Y)
			r.scale = Vector2(0.55, 0.55)
			if r.has_method("set_motion"):
				r.set_motion("idle", 0.0, 1.0)
		_strip_rigs.append(r)


func _draw() -> void:
	draw_texture_rect(_dither, Rect2(0, 0, HallCam.W, HallCam.H), true)
	HudDraw.panel(self, PANEL, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	HudDraw.text_center(self, PixelFonts.title(), HallCam.W / 2, PANEL.position.y + 5, "Dramatis Personae", Pal.INK,
		PixelFonts.TITLE_SIZE)
	HudDraw.text_center(self, PixelFonts.bold(), HallCam.W / 2, PANEL.position.y + 25, "THE COURT OF THE FRUIT BOWL",
		Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	# the stage: a slice of the banquet hall behind the character
	var tex := StoryArt.backdrop("banquet")
	if tex != null:
		var src_w := HallCam.H * STAGE.size.x / STAGE.size.y
		draw_texture_rect_region(tex, Rect2(STAGE), Rect2((HallCam.W - src_w) * 0.5, 0, src_w, HallCam.H))
	else:
		draw_rect(Rect2(STAGE), Pal.PARCHMENT_DARK)
	if str(card.get("rig", "")) == "giant":
		_hand(Vector2(STAGE.position.x + STAGE.size.x / 2, STAGE.position.y + STAGE.size.y - 30), 56, STAGE.position.y)
	HudDraw.frame(self, STAGE.grow(1), Pal.INK)
	HudDraw.frame(self, STAGE.grow(2), Pal.GOLD)

	# who they are
	var y := STAGE.position.y + 2
	HudDraw.text(self, PixelFonts.title(), TEXT_X, y, str(card.get("name", "")), Pal.ROYAL, PixelFonts.TITLE_SIZE)
	y += 24
	y = _wrapped(str(card.get("title", "")), TEXT_X, y, TEXT_W, Pal.INK, PixelFonts.CAPTION_SIZE, 17) + 8
	draw_rect(Rect2(TEXT_X, y, TEXT_W, 1), Pal.PARCHMENT_SHADE)
	y += 6
	if str(card.get("rig", "")) == "council":
		for i in COUNCIL.size():
			var col := Pal.role_color(["helmsman", "liftmaster", "wingmaster", "seer"][i])
			HudDraw.text(self, PixelFonts.bold(), TEXT_X, y + 1, COUNCIL_NAMES[i], col, PixelFonts.LABEL_SIZE)
			y += 11
		y += 4
		HudDraw.text(self, PixelFonts.bold(), TEXT_X, y, "HOW THEY SPLIT HIM", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	else:
		HudDraw.text(self, PixelFonts.bold(), TEXT_X, y, "THE REAL FLY GENE", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	y += 12
	_wrapped(str(card.get("fact", "")), TEXT_X, y, TEXT_W, Pal.INK_SOFT, 8, 11 if str(card.get("rig", "")) == "council" else 10,
		PixelFonts.label())

	# the cast row: the current one lit, a gold marker under them (the Giant is its hand, as in the fights)
	var n := cast.size()
	var gi := cast.find("giant")
	if gi >= 0:
		var gx := PANEL.position.x + 20 + (PANEL.size.x - 40) * (gi + 0.5) / n
		_hand(Vector2(gx, STRIP_Y - 4), 20, STRIP_Y - 44, gi != index)
	if n > 0:
		var cx := PANEL.position.x + 20 + (PANEL.size.x - 40) * (index + 0.5) / n
		var bob := roundf(sin(_t * 6.0))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, STRIP_Y + 3 + bob), Vector2(cx + 4, STRIP_Y + 3 + bob),
			Vector2(cx, STRIP_Y - 1 + bob)]), Pal.GOLD)
	draw_rect(Rect2(PANEL.position.x + 8, STAGE.position.y + STAGE.size.y + 6, PANEL.size.x - 16, 1), Pal.PARCHMENT_SHADE)

	var fy := PANEL.position.y + PANEL.size.y - 14
	HudDraw.text(self, PixelFonts.label(), PANEL.position.x + 10, fy, "CARD %d OF %d" % [index + 1, count], Pal.INK_SOFT,
		PixelFonts.LABEL_SIZE)
	var right := "SPACE: NEXT   LEFT: BACK   S: SKIP TO THE GARDEN" if index + 1 < count else "SPACE: TO THE GARDEN"
	if auto:
		right = "AUTO PLAY   A: MANUAL   S: SKIP TO THE GARDEN"
	HudDraw.text_right(self, PixelFonts.bold(), PANEL.position.x + PANEL.size.x - 10, fy, right, Pal.CRIMSON, PixelFonts.LABEL_SIZE)


## Text wrapped to `width`; returns the y under the last line.
func _wrapped(text: String, x: int, top: int, width: int, col: Color, size: int, step: int, font: Font = null) -> int:
	if font == null:
		font = PixelFonts.caption()
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" "):
		var next := word if line == "" else line + " " + word
		if line != "" and PixelFonts.width(font, next, size) > width:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	for i in lines.size():
		HudDraw.text(self, font, x, top + i * step, lines[i], col, size)
	return top + lines.size() * step


## The Giant's hand exactly as the fights draw it (SpriteForge.giant_hand and GiantHand's sleeve): fingertips at `tip`, the
## sleeve running up to `top`.
func _hand(tip: Vector2, palm: int, top: float, dim: bool = false) -> void:
	var tex := SpriteForge.giant_hand(palm)
	var sz := SpriteForge.hand_size(palm)
	var at := Vector2(roundf(tip.x - sz.x / 2), roundf(tip.y - sz.y + 2))
	var ox := at.x + 2 + roundi(0.2 * palm) - roundi(0.08 * palm)
	var w := roundi(1.16 * palm)
	var h := at.y - top
	var mod := Color(0.45, 0.42, 0.4, 1) if dim else Color(1, 1, 1, 1)
	if h > 0:
		draw_rect(Rect2(ox - 1, top, w + 2, h + 1), Pal.INK * mod)
		draw_rect(Rect2(ox, top, w, h + 1), Pal.ROYAL_DARK * mod)
		for k in 3:
			draw_rect(Rect2(ox + roundi((0.28 + 0.3 * k) * palm), top, 1, h + 1), Pal.ROYAL * mod)
	draw_texture(tex, at, mod)
