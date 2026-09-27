class_name FinalArt
extends RefCounted

## Loads the team's approved hand-drawn runtime frames exported from
## assets/final/ (see tools/export_final_art.py and assets/final/README.md)
## into ImageTextures, the same "load from file bytes" pattern StoryArt uses
## so a fresh clone works before the editor has imported anything.
##
## Hamlet is currently the only character wired to these frames in-game
## (assets/final/FINAL_INTEGRATION_PROMPT.md, step 1). The other characters'
## frames are exported to assets/final/runtime/ but not yet used on screen.

const HAMLET_FRAME := "res://assets/final/runtime/hamlet/%s.png"
const HAMLET_POSES := ["hover", "wings_raised", "wings_lowered", "buzz", "bank_left", "bank_right", "hit", "victory", "rear", "front"]

static var _textures := {}
static var _checked_available := false
static var _available := false


## True if the exported Hamlet runtime frames exist in this checkout.
static func hamlet_available() -> bool:
	if not _checked_available:
		_checked_available = true
		_available = FileAccess.file_exists(HAMLET_FRAME % "hover")
	return _available


static func hamlet_frame(pose: String) -> ImageTexture:
	var key := "hamlet_%s" % pose
	if _textures.has(key):
		return _textures[key]
	var tex: ImageTexture = null
	var bytes := FileAccess.get_file_as_bytes(HAMLET_FRAME % pose)
	if not bytes.is_empty():
		var img := Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			tex = ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex
