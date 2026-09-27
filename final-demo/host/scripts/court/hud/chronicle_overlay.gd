class_name ChronicleOverlay
extends Control

## The Chronicle, drawn from server/chronicler.py's result JSON exactly as it
## comes (under `state.chronicle`, provisional): players[name].roles/share/events,
## knight, blunder {player, kind, tick}, note. Every number shown is computed
## from that JSON: percent = round(share * 100); seconds = tick * 0.02
## (the Chronicler records one tick per 20 ms).

const TICK_S := 0.02

var data: Dictionary = {}
var sample := false
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
	data = cs.chronicle
	sample = cs.sample
	queue_redraw()


func _draw() -> void:
	draw_texture_rect(_dither, Rect2(0, 0, HallCam.W, HallCam.H), true)
	var r := Rect2i(76, 32, 488, 288)
	LobbyOverlay._scroll(self, r)
	var cx := 320
	HudDraw.text_center(self, PixelFonts.title(), cx, 40, "The Chronicle", Pal.INK, PixelFonts.TITLE_SIZE)
	var brain := str(data.get("brain", ""))
	var sub := str(data.get("chapter", "")).to_upper().replace("_", " ")
	if brain != "":
		sub += ("  -  " if sub != "" else "") + ("TRUE PRINCE" if brain == "true" else brain.to_upper())
	HudDraw.text_center(self, PixelFonts.bold(), cx, 63, sub, Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	LobbyOverlay._flourish(self, cx, 76, 170)

	var players: Dictionary = data.get("players", {}) if data.get("players") is Dictionary else {}
	if players.is_empty():
		HudDraw.text_center(self, PixelFonts.bold(), cx, 160, "THE CHRONICLER HAS NOT SPOKEN YET", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		return

	# who moved the Prince: one row per player, sorted by overall share
	var names: Array = players.keys()
	names.sort_custom(func(a: Variant, b: Variant) -> bool: return _overall(players[a]) > _overall(players[b]))
	var y := 88
	for n in names:
		var info: Dictionary = players[n]
		var role := _main_role(info)
		var share := _overall(info)
		HudDraw.tex(self, SpriteForge.role_icon(role, true), Vector2i(92, y + 2))
		HudDraw.text(self, PixelFonts.bold(), 114, y + 1, str(n).to_upper().left(12), Pal.INK, PixelFonts.LABEL_SIZE)
		HudDraw.text(self, PixelFonts.label(), 114, y + 11, Pal.role_title(role) if role != "" else "COUNCIL", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
		HudDraw.bar(self, Rect2i(200, y + 3, 120, 8), share, Pal.role_color(role) if role != "" else Pal.GOLD_DARK)
		HudDraw.text(self, PixelFonts.bold(), 326, y + 3, "%d%%" % roundi(share * 100.0), Pal.INK, PixelFonts.LABEL_SIZE)
		var events: Array = info.get("events", []) if info.get("events") is Array else []
		if not events.is_empty():
			HudDraw.text(self, PixelFonts.label(), 200, y + 14, str(events[0]).to_upper().left(34), Pal.ROYAL, PixelFonts.LABEL_SIZE)
		y += 34
		if y > 250:
			break

	# Knight of the Realm
	var knight := str(data.get("knight", "")) if data.get("knight") != null else ""
	HudDraw.panel(self, Rect2i(392, 88, 156, 70), Pal.PARCHMENT, Pal.INK, Pal.GOLD, Pal.PARCHMENT_DARK)
	HudDraw.frame(self, Rect2i(393, 89, 154, 68), Pal.GOLD)
	HudDraw.tex(self, SpriteForge.crown(), Vector2i(400, 96))
	HudDraw.text(self, PixelFonts.bold(), 414, 97, "KNIGHT OF THE REALM", Pal.GOLD_DARK, PixelFonts.LABEL_SIZE)
	if knight != "":
		HudDraw.text_center(self, PixelFonts.title(), 470, 108, knight, Pal.INK, PixelFonts.TITLE_SIZE)
		if players.has(knight):
			HudDraw.text_center(self, PixelFonts.label(), 470, 140, "%d%% OF THE CREDIT" % roundi(_overall(players[knight]) * 100.0), Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	else:
		HudDraw.text_center(self, PixelFonts.label(), 470, 120, "NONE THIS TIME", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	# Blunder of the round
	HudDraw.panel(self, Rect2i(392, 166, 156, 66), Pal.PARCHMENT, Pal.INK, Pal.CRIMSON, Pal.PARCHMENT_DARK)
	var blot := SpriteForge.splat(4)
	HudDraw.tex(self, blot, Vector2i(398, 170))
	HudDraw.text(self, PixelFonts.bold(), 418, 175, "THE BLUNDER", Pal.CRIMSON, PixelFonts.LABEL_SIZE)
	var blunder: Variant = data.get("blunder", null)
	if blunder is Dictionary:
		HudDraw.text_center(self, PixelFonts.title(), 470, 186, str(blunder.get("player", "?")), Pal.INK, PixelFonts.TITLE_SIZE)
		var kind := str(blunder.get("kind", "?")).to_upper()
		var secs := float(blunder.get("tick", 0)) * TICK_S
		HudDraw.text_center(self, PixelFonts.label(), 470, 216, "%s AT %.1f S" % [kind, secs], Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	else:
		HudDraw.text_center(self, PixelFonts.label(), 470, 198, "NO BLUNDERS. SUSPICIOUS.", Pal.INK_SOFT, PixelFonts.LABEL_SIZE)

	var note := str(data.get("note", ""))
	if note != "":
		HudDraw.text_center(self, PixelFonts.label(), cx, 282, note.to_upper().left(80), Pal.INK_SOFT, PixelFonts.LABEL_SIZE)
	if sample:
		LobbyOverlay._stamp(self, Vector2i(r.position.x + 12, r.position.y + r.size.y - 26))


static func _overall(info: Variant) -> float:
	if info is Dictionary and info.get("share") is Dictionary:
		return clampf(float(info["share"].get("overall", 0.0)), 0.0, 1.0)
	return 0.0


static func _main_role(info: Dictionary) -> String:
	var roles: Variant = info.get("roles", [])
	if roles is Array:
		for r in roles:
			if str(r) in Pal.ROLE_ORDER:
				return str(r)
	return ""
