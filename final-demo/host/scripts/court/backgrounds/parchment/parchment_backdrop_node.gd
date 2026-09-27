class_name ParchmentBackdropNode
extends Control

## Drop-in Control for ParchmentBackdrop.paint(): sizes itself to the full
## 640x360 court viewport, builds the backdrop once and caches the texture
## (keyed on accent + drop_cap, shared across every instance), then just
## blits it every _draw() — cheap even though the art itself never changes.
##
## Usage (suggested, not applied — see the parchment README/report for exact
## wiring): add one of these as the first child under each screen's overlay,
## behind whatever that screen already draws (e.g. LobbyOverlay's own scroll
## panel), instead of that overlay's flat `_dither` wash.

@export var accent: Color = Pal.GOLD
@export var drop_cap: bool = false

static var _cache := {}

var _tex: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(ParchmentBackdrop.W, ParchmentBackdrop.H)
	_build()


## Call to change the look (e.g. a screen that wants Pal.CRIMSON instead of
## the default gold, or the drop-cap variant); rebuilds only if that exact
## combination hasn't been painted yet.
func configure(new_accent: Color, new_drop_cap: bool = false) -> void:
	accent = new_accent
	drop_cap = new_drop_cap
	_build()
	queue_redraw()


func _build() -> void:
	var key := "%s|%s" % [accent.to_html(false), drop_cap]
	if not _cache.has(key):
		_cache[key] = ParchmentBackdrop.paint(accent, drop_cap).texture()
	_tex = _cache[key]


func _draw() -> void:
	if _tex != null:
		draw_texture(_tex, Vector2.ZERO)
