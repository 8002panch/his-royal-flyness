class_name FxLayer
extends Node2D

## Cheap, readable pixel effects: dust puffs, rising hearts, gold sparkles
## and the ink SPLAT. Each is a small sprite that moves in whole pixels.

var parts: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 42


func puff(at: Vector2, n: int = 6) -> void:
	for i in n:
		var ang := PI + PI * float(i) / maxf(1.0, n - 1.0)
		parts.append({"kind": "puff", "pos": at, "vel": Vector2(cos(ang) * _rng.randf_range(25, 45), sin(ang) * 10.0 - 6.0),
			"life": 0.0, "max": _rng.randf_range(0.45, 0.6)})


func hearts(at: Vector2, n: int = 5) -> void:
	for i in n:
		parts.append({"kind": "heart", "pos": at + Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-4, 6)),
			"vel": Vector2(0, -_rng.randf_range(18, 30)), "life": -0.15 * i, "max": 1.6, "phase": _rng.randf() * TAU})


func sparkle(at: Vector2) -> void:
	parts.append({"kind": "sparkle", "pos": at, "vel": Vector2.ZERO, "life": 0.0, "max": 0.45})


func splat(at: Vector2) -> void:
	parts.append({"kind": "splat", "pos": at, "vel": Vector2.ZERO, "life": 0.0, "max": 1.8})


func _process(delta: float) -> void:
	if parts.is_empty():
		return
	var keep: Array = []
	for p in parts:
		p["life"] += delta
		if p["life"] >= p["max"]:
			continue
		if p["life"] >= 0.0:
			p["pos"] += p["vel"] * delta
			if p["kind"] == "puff":
				p["vel"] *= 0.9
		keep.append(p)
	parts = keep
	queue_redraw()


func _draw() -> void:
	for p in parts:
		var life: float = p["life"]
		if life < 0.0:
			continue
		var u: float = life / float(p["max"])
		var pos: Vector2 = p["pos"]
		match p["kind"]:
			"puff":
				var r := 1 + int(u * 4.0)
				var t := SpriteForge.puff(r)
				draw_texture(t, Vector2(roundi(pos.x) - r - 1, roundi(pos.y) - r - 1))
			"heart":
				var t := SpriteForge.heart()
				var wob := roundi(sin(life * 6.0 + float(p["phase"])) * 2.0)
				# blink out over the last quarter instead of fading (no alpha)
				var blink := u > 0.75 and int(life * 12.0) % 2 == 0
				if not blink:
					draw_texture(t, Vector2(roundi(pos.x) - 4 + wob, roundi(pos.y) - 4))
			"sparkle":
				if int(life * 16.0) % 2 == 0:
					draw_texture(SpriteForge.sparkle(), Vector2(roundi(pos.x) - 2, roundi(pos.y) - 2))
			"splat":
				var t := SpriteForge.splat(24)
				draw_texture(t, Vector2(roundi(pos.x) - t.get_width() / 2, roundi(pos.y) - t.get_height() / 2))
				if u < 0.85 or int(life * 12.0) % 2 == 1:
					var font := PixelFonts.title()
					var w := PixelFonts.width(font, "Splat!", PixelFonts.TITLE_SIZE)
					var tx := roundi(pos.x) - w / 2
					var ty := roundi(pos.y) - 40
					# inked outline so it reads over anything
					for d in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, -2), Vector2i(2, 2), Vector2i(-2, 2), Vector2i(2, -2)]:
						HudDraw.text(self, font, tx + d.x, ty + d.y, "Splat!", Pal.INK, PixelFonts.TITLE_SIZE)
					HudDraw.text(self, font, tx, ty, "Splat!", Pal.CRIMSON_LIGHT, PixelFonts.TITLE_SIZE)
