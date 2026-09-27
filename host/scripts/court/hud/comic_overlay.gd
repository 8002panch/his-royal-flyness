class_name ComicOverlay
extends Control

## The story's comic cutscenes and quiz cards (docs/GAME.md, "Comic-strip popup format"), drawn over the frozen, dimmed
## game from the server's `beat` and `question`: the scene's v4 backdrop in a gold frame, the panel's cast as Anshul's
## animated rigs (the speaker gestures from the line's audio tag), and a speech bubble (the Clown narrates in a caption box).
## The presenter moves on with Space / Page Down / Right, back with Left, and S skips; the Seer answers on their phone.
## With auto on (the default; A toggles it, court_main.gd) each line moves on by itself once it has been spoken and read.
## Text always stays at the big caption size: a long line makes its bubble taller (and the picture shorter), never smaller.
## In the drink questions two chalices stand in the picture: the pear nectar and the grape cordial.

const WIDE_PANEL := Rect2i(26, 28, 588, 306)
const WIDE_ART := Rect2i(34, 36, 572, 206)
const WIDE_BUBBLE := Rect2i(38, 256, 564, 58)
## During the drink questions the brain map takes the right-hand column (hud/brain_map_panel.gd), so the comic moves left.
const NARROW_PANEL := Rect2i(4, 28, 474, 306)
const NARROW_ART := Rect2i(12, 36, 458, 206)
const NARROW_BUBBLE := Rect2i(16, 256, 450, 58)
var PANEL := WIDE_PANEL
var ART := WIDE_ART
var BUBBLE := WIDE_BUBBLE
var narrow := false:
	set(v):
		if v != narrow:
			narrow = v
			PANEL = NARROW_PANEL if v else WIDE_PANEL
			ART = NARROW_ART if v else WIDE_ART
			BUBBLE = NARROW_BUBBLE if v else WIDE_BUBBLE
			_cast_key = ""  # re-place the rigs across the new width
var _feet_y := 238
var auto := true          # set by court_main.gd: cutscenes move on by themselves
const QUIZ_SCENES := ["Q01", "Q02", "Q03"]
const RIG_SCALE := 1.6
const INK_FOR := {"hamlet": Pal.ROYAL, "miranda": Pal.ROYAL_LIGHT, "prospero": Pal.CRIMSON_DARK, "tinman": Pal.STONE,
	"cheapdate": Pal.CRIMSON, "rutabaga": Pal.GOLD_DARK}

var beat: Dictionary = {}
var question: Dictionary = {}
var scene := ""
var backdrop := ""
var waiting := false
var _dither: ImageTexture
var _rigs := {}          # speaker -> rig node
var _cast_key := ""
var _beat_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(HallCam.W, HallCam.H)
	var c := PixelCanvas.new(2, 2)
	c.px(0, 0, Pal.INK)
	c.px(1, 1, Pal.INK)
	_dither = c.texture()


func apply(cs: CourtState) -> void:
	var on := cs.phase in ["comic", "question"] and not cs.beat.is_empty()
	visible = on
	if not on:
		_clear_rigs()
		_beat_id = ""
		return
	beat = cs.beat
	question = cs.question
	scene = cs.scene
	backdrop = cs.backdrop
	waiting = cs.phase == "question"
	_layout()
	var cast: Array = beat.get("cast", [])
	var key := scene + ":" + ",".join(cast)
	if key != _cast_key:
		_cast_key = key
		_build_rigs(cast)
	var id := str(beat.get("id", ""))
	if id != _beat_id:
		_beat_id = id
		var who: Variant = _rigs.get(str(beat.get("speaker", "")))
		if who != null and who.has_method("play_gesture"):
			who.play_gesture(str(beat.get("gesture", "talk")), 1.6)
	queue_redraw()


## Size the bubble to its words at the big caption size, and give the picture whatever height is left.
func _layout() -> void:
	var base_art := NARROW_ART if narrow else WIDE_ART
	var base_bubble := NARROW_BUBBLE if narrow else WIDE_BUBBLE
	var speaker := str(beat.get("speaker", ""))
	var prev: Variant = beat.get("prev")
	var show_q := not question.is_empty() and str(beat.get("panel", "")) in ["question", "explanation"]
	var text := str(beat.get("caption", ""))
	var width := base_bubble.size.x - 20
	if speaker == "clown" and prev is Dictionary and not show_q:
		text = str(prev.get("caption", ""))
	elif speaker == "clown":
		width = base_bubble.size.x - 64
	var n := maxi(2, _lines(text, width).size())
	var h := 24 + n * 17
	var bottom := PANEL.position.y + PANEL.size.y - 20
	BUBBLE = Rect2i(base_bubble.position.x, bottom - h, base_bubble.size.x, h)
	ART = Rect2i(base_art.position.x, base_art.position.y, base_art.size.x, BUBBLE.position.y - 14 - base_art.position.y)
	var feet := ART.position.y + ART.size.y - 4
	if feet != _feet_y:
		_feet_y = feet
		for r in _rigs.values():
			(r as Node2D).position.y = _feet_y


func _clear_rigs() -> void:
	for r in _rigs.values():
		(r as Node).queue_free()
	_rigs = {}
	_cast_key = ""


func _build_rigs(cast: Array) -> void:
	_clear_rigs()
	_cast_key = scene + ":" + ",".join(cast)
	var n := cast.size()
	for i in n:
		var rig := StoryArt.rig(str(cast[i]), scene)
		if rig == null:
			continue
		add_child(rig)
		var x := ART.position.x + ART.size.x * (i + 1) / (n + 1)
		rig.position = Vector2(x, _feet_y)
		rig.scale = Vector2(RIG_SCALE, RIG_SCALE)
		if rig.has_method("set_motion"):
			rig.set_motion("idle", 0.0, 1.0 if x < HallCam.W / 2 else -1.0)
		_rigs[str(cast[i])] = rig


func _draw() -> void:
	draw_texture_rect(_dither, Rect2(0, 0, HallCam.W, HallCam.H), true)
	HudDraw.panel(self, PANEL, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	var tex := StoryArt.backdrop(backdrop)
	if tex != null:
		# the middle band of the backdrop, at the frame's shape
		var src_h := HallCam.W * ART.size.y / ART.size.x
		draw_texture_rect_region(tex, Rect2(ART), Rect2(0, (HallCam.H - src_h) * 0.55, HallCam.W, src_h))
	else:
		draw_rect(Rect2(ART), Pal.PARCHMENT_DARK)
	HudDraw.frame(self, ART.grow(1), Pal.INK)

	var speaker := str(beat.get("speaker", ""))
	var name := str(beat.get("name", "")).to_upper()
	var caption := str(beat.get("caption", ""))
	var show_q := not question.is_empty() and str(beat.get("panel", "")) in ["question", "explanation"]
	var prev: Variant = beat.get("prev")
	if speaker == "clown" and prev is Dictionary and not show_q:
		_bubble(str(prev.get("name", "")).to_upper(), str(prev.get("caption", "")), INK_FOR.get(str(prev.get("speaker", "")), Pal.CRIMSON),
			false, str(prev.get("speaker", "")))
		_caption_box(name, caption, false, true)
	elif speaker == "clown":
		_caption_box(name, caption, true)
	else:
		_bubble(name, caption, INK_FOR.get(speaker, Pal.CRIMSON))
	if scene in QUIZ_SCENES:
		_chalices()
	if show_q:
		_question_card()
	_footer()


## The two drinks on offer, at the foot of the picture: pear nectar (the right answer's) and the grape cordial. Once the
## Seer has answered, the one Hamlet gets is lifted and lit.
func _chalices() -> void:
	var chosen := str(question.get("chosen", "")) if question.get("chosen") != null else ""
	var correct := str(question.get("correct", "")) if question.get("correct") != null else ""
	var got := "" if chosen == "" else ("pear" if chosen == correct else "cordial")
	var y := ART.position.y + ART.size.y - 8
	var u := 14.0
	var drinks := [["pear", "PEAR NECTAR", Color("#E8D873"), ART.position.x + 58],
		["cordial", "GRAPE CORDIAL", Color("#6B2F7E"), ART.position.x + ART.size.x - 58]]
	for d in drinks:
		var lift := 5.0 if got == d[0] else 0.0
		var c := Vector2(float(d[3]), y - 22 - lift)
		if got == d[0]:
			draw_circle(c + Vector2(0, -u), u * 2.2, Color(Pal.GOLD_LIGHT, 0.55))
		var cup := PackedVector2Array([c + Vector2(-u, -u * 1.6), c + Vector2(u, -u * 1.6), c + Vector2(u * 0.55, -u * 0.5),
			c + Vector2(-u * 0.55, -u * 0.5)])
		draw_colored_polygon(cup, Pal.GOLD)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-u * 0.85, -u * 1.45), c + Vector2(u * 0.85, -u * 1.45),
			c + Vector2(u * 0.7, -u * 1.05), c + Vector2(-u * 0.7, -u * 1.05)]), d[2])
		draw_polyline(cup + PackedVector2Array([cup[0]]), Pal.INK, 1.0)
		draw_rect(Rect2(c.x - 2, c.y - u * 0.5, 4, u * 0.9), Pal.GOLD_DARK)
		draw_rect(Rect2(c.x - u * 0.6, c.y + u * 0.35, u * 1.2, 3), Pal.GOLD)
		draw_rect(Rect2(c.x - u * 0.6, c.y + u * 0.35, u * 1.2, 3), Pal.INK, false, 1.0)
		var tw := PixelFonts.width(PixelFonts.bold(), d[1], PixelFonts.LABEL_SIZE) + 8
		var tag := Rect2i(int(c.x) - tw / 2, int(y) - 7, tw, 11)
		HudDraw.panel(self, tag, Pal.PARCHMENT, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		HudDraw.text(self, PixelFonts.bold(), tag.position.x + 4, tag.position.y + 2, d[1],
			Pal.CRIMSON if d[0] == "cordial" else Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)


## The Clown narrates in a rectangular caption box (the comic's narrator), under the question card when there is one.
func _caption_box(name: String, caption: String, at_bottom: bool, on_top: bool = false) -> void:
	var r := Rect2i(BUBBLE.position.x, BUBBLE.position.y, BUBBLE.size.x, BUBBLE.size.y)
	if on_top:
		r = Rect2i(ART.position.x + 8, ART.position.y + 8, ART.size.x - 16,
			24 + maxi(1, _lines(caption, ART.size.x - 16 - 64).size()) * 17)
	HudDraw.panel(self, r, Pal.GOLD_LIGHT, Pal.INK, Pal.GOLD, Pal.GOLD)
	# his head beside his words, bobbing as he talks
	var head := StoryArt.clown_head()
	var indent := 8
	if head != null:
		var hs := Vector2(48, 39)
		var bob := roundf(sin(Time.get_ticks_msec() / 90.0) * 1.0)
		draw_texture_rect(head, Rect2(r.position.x + 4, r.position.y + r.size.y - hs.y - 2 + bob, hs.x, hs.y), false)
		indent = 56
	HudDraw.text(self, PixelFonts.bold(), r.position.x + indent, r.position.y + 5, name, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	_wrapped(caption, r.position.x + indent, r.position.y + 16, r.size.x - indent - 8)


func _bubble(name: String, caption: String, ink: Color, empty: bool = false, speaker: String = "") -> void:
	if empty:
		HudDraw.panel(self, BUBBLE, Pal.PARCHMENT_DARK, Pal.INK, Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		return
	HudDraw.panel(self, BUBBLE, Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_SHADE)
	# the tail points up at the speaker's rig
	var who: Variant = _rigs.get(speaker if speaker != "" else str(beat.get("speaker", "")))
	var tx := int((who as Node2D).position.x) if who != null else BUBBLE.position.x + 40
	draw_colored_polygon(PackedVector2Array([Vector2(tx - 6, BUBBLE.position.y + 1), Vector2(tx + 6, BUBBLE.position.y + 1),
		Vector2(tx, BUBBLE.position.y - 9)]), Pal.PARCHMENT)
	draw_polyline(PackedVector2Array([Vector2(tx - 7, BUBBLE.position.y), Vector2(tx, BUBBLE.position.y - 10),
		Vector2(tx + 7, BUBBLE.position.y)]), Pal.INK, 1.0)
	HudDraw.text(self, PixelFonts.bold(), BUBBLE.position.x + 10, BUBBLE.position.y + 6, name, ink, PixelFonts.LABEL_SIZE)
	_wrapped(caption, BUBBLE.position.x + 10, BUBBLE.position.y + 17, BUBBLE.size.x - 20)


func _question_card() -> void:
	var qn := _lines(str(question.get("text", "")), ART.size.x - 36).size()
	var qh := (qn - 1) * 17
	var r := Rect2i(ART.position.x + 8, ART.position.y + 8, ART.size.x - 16, 84 + qh)
	HudDraw.panel(self, r, Pal.PARCHMENT, Pal.INK, Pal.ROYAL, Pal.PARCHMENT_SHADE)
	_wrapped(str(question.get("text", "")), r.position.x + 10, r.position.y + 6, r.size.x - 20)
	var chosen := str(question.get("chosen", "")) if question.get("chosen") != null else ""
	var correct := str(question.get("correct", "")) if question.get("correct") != null else ""
	for i in 2:
		var key := "A" if i == 0 else "B"
		var box := Rect2i(r.position.x + 10 + i * (r.size.x - 20) / 2, r.position.y + 28 + qh, (r.size.x - 30) / 2, 26)
		var fill := Pal.PARCHMENT_DARK
		if correct == key:
			fill = Pal.GOLD_LIGHT
		elif chosen == key:
			fill = Pal.CRIMSON_LIGHT
		HudDraw.panel(self, box, fill, Pal.INK, Pal.GOLD if chosen == key else Color(0, 0, 0, 0), Pal.PARCHMENT_SHADE)
		HudDraw.text(self, PixelFonts.title(), box.position.x + 8, box.position.y + 3, key, Pal.ROYAL, PixelFonts.TITLE_SIZE)
		HudDraw.text(self, PixelFonts.caption(), box.position.x + 30, box.position.y + 5, str(question.get(key.to_lower(), "")),
			Pal.INK, PixelFonts.CAPTION_SIZE)
	var status := "THE ROYAL SEER ANSWERS ON THEIR PHONE"
	if chosen != "":
		status = ("CORRECT: PEAR NECTAR" if chosen == correct else "WRONG: THE GRAPE CORDIAL. STEADINESS DOWN")
	HudDraw.text_center(self, PixelFonts.bold(), r.position.x + r.size.x / 2, r.position.y + 62 + qh, status,
		Pal.ROYAL if chosen == "" or chosen == correct else Pal.CRIMSON, PixelFonts.LABEL_SIZE)


func _footer() -> void:
	var y := PANEL.position.y + PANEL.size.y - 14
	var p := str(beat.get("panel", "")).trim_prefix("p")
	var where := ("PAGE %s  PANEL %s   " % [p.get_slice(".", 0), p.get_slice(".", 1)]) if p.contains(".") else ""
	var left := where + "LINE %d OF %d" % [int(beat.get("index", 1)), int(beat.get("count", 1))]
	HudDraw.text(self, PixelFonts.label(), PANEL.position.x + 10, y, left, Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	var right := "WAITING FOR THE SEER'S ANSWER" if waiting else (
		"AUTO PLAY   A: MANUAL   SPACE: SKIP AHEAD" if auto else "SPACE: NEXT   LEFT: BACK   S: SKIP   A: AUTO")
	HudDraw.text_right(self, PixelFonts.bold() if waiting else PixelFonts.label(), PANEL.position.x + PANEL.size.x - 10, y, right,
		Pal.CRIMSON if waiting else Pal.INK_SOFT, PixelFonts.LABEL_SIZE)


## Caption words broken into lines that fit `width` at the big caption size.
func _lines(text: String, width: int) -> Array[String]:
	var font := PixelFonts.caption()
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" "):
		var next := word if line == "" else line + " " + word
		if line != "" and PixelFonts.width(font, next, PixelFonts.CAPTION_SIZE) > width:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	return lines


## Caption text wrapped to `width`, always at the big caption size (the boxes grow to fit it).
func _wrapped(text: String, x: int, top: int, width: int) -> void:
	var lines := _lines(text, width)
	for i in lines.size():
		HudDraw.text(self, PixelFonts.caption(), x, top + i * 17, lines[i], Pal.INK, PixelFonts.CAPTION_SIZE)
