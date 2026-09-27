class_name PixelFonts
extends RefCounted

## Pixel fonts (SIL OFL, see assets/fonts/OFL-*.txt), read straight from the
## .ttf bytes so they work without an editor import step. Antialiasing is off:
## each font is only used at a size that lands on its pixel grid.
##   Jacquarda Bastarda 9: blackletter titles, 18 px (2x its 9 px grid)
##   Silkscreen: labels, 8 px (1x)
##   Pixelify Sans: captions, 16 px

const DIR := "res://assets/fonts/"

const TITLE_SIZE := 18
const LABEL_SIZE := 8
const CAPTION_SIZE := 16

static var _cache := {}


static func _load(file: String) -> Font:
	if _cache.has(file):
		return _cache[file]
	var font := FontFile.new()
	var bytes := FileAccess.get_file_as_bytes(DIR + file)
	if bytes.is_empty():
		push_warning("PixelFonts: missing %s, using the default font" % file)
		var fallback := ThemeDB.fallback_font
		_cache[file] = fallback
		return fallback
	font.data = bytes
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	font.multichannel_signed_distance_field = false
	_cache[file] = font
	return font


static func title() -> Font:
	return _load("JacquardaBastarda9-Regular.ttf")


static func label() -> Font:
	return _load("Silkscreen-Regular.ttf")


static func bold() -> Font:
	return _load("Silkscreen-Bold.ttf")


static func caption() -> Font:
	return _load("PixelifySans-Variable.ttf")


static func width(font: Font, text: String, size: int) -> int:
	return int(ceil(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x))
