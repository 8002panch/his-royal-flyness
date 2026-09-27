class_name StoryArt
extends RefCounted

## Anshul's story art for the campaign: the v4 backdrops (assets/pixelart/v4/backdrops, 1920x1080, scaled to the 640x360
## screen) and the animated cast rigs (assets/pixelart/animation_v1/rigs). Loaded from the files' bytes, like PixelFonts, so
## a fresh clone works before the editor has imported them. All motion is cosmetic: story outcomes come from the server.

const BACKDROPS := "res://assets/pixelart/v4/backdrops/bg_%s.png"
const RIGS := "res://assets/pixelart/animation_v1/rigs/%s.scn"
const RIG_FOR := {"hamlet": "hamlet", "miranda": "miranda", "tinman": "lord_tinman", "cheapdate": "sir_cheapdate",
	"rutabaga": "count_rutabaga", "clown": "clown_jester"}
## Prospero is cross after the garden and when the Giant wins; kind once it's beaten or he's heard Miranda out.
const PROSPERO_NICE := ["C03", "E01"]

static var _backdrops := {}
static var _rigs := {}


## The backdrop at screen size (640x360, nearest), or null if the file is missing.
static func backdrop(id: String) -> ImageTexture:
	if id == "":
		return null
	if _backdrops.has(id):
		return _backdrops[id]
	var tex: ImageTexture = null
	var bytes := FileAccess.get_file_as_bytes(BACKDROPS % id)
	if not bytes.is_empty():
		var img := Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			img.resize(HallCam.W, HallCam.H, Image.INTERPOLATE_NEAREST)
			tex = ImageTexture.create_from_image(img)
	_backdrops[id] = tex
	return tex


static func rig_name(speaker: String, scene: String) -> String:
	if speaker == "prospero":
		return "prospero_nice" if scene in PROSPERO_NICE else "prospero_mad"
	return RIG_FOR.get(speaker, "")


## A new rig node for this speaker (null if there's none). The caller owns placement and scale.
static func rig(speaker: String, scene: String) -> Node2D:
	var name := rig_name(speaker, scene)
	if name == "":
		return null
	if not _rigs.has(name):
		_rigs[name] = load(RIGS % name) if ResourceLoader.exists(RIGS % name) else null
	var packed: PackedScene = _rigs[name]
	return packed.instantiate() as Node2D if packed != null else null


const CLOWN_ART := "res://assets/pixelart/v3/npcs/clown_jester.png"
static var _clown_head: ImageTexture = null


## The Clown's head from Anshul's v3 jester (hat, bells and grin), for his captions: 64x52, nearest.
static func clown_head() -> ImageTexture:
	if _clown_head != null:
		return _clown_head
	var bytes := FileAccess.get_file_as_bytes(CLOWN_ART)
	if bytes.is_empty():
		return null
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK:
		return null
	img = img.get_region(Rect2i(230, 320, 640, 520))
	img.resize(64, 52, Image.INTERPOLATE_NEAREST)
	_clown_head = ImageTexture.create_from_image(img)
	return _clown_head


## Load every cast rig, backdrop and the Clown's head up front (the court's first frames), so no character pops in late
## or stalls the screen the first time a scene needs it.
static func warm() -> void:
	for name in ["hamlet", "miranda", "prospero_nice", "prospero_mad", "lord_tinman", "sir_cheapdate", "count_rutabaga",
			"clown_jester", "royal_seer", "helmsman", "liftmaster", "wingmaster", "giant"]:
		if not _rigs.has(name) and ResourceLoader.exists(RIGS % name):
			_rigs[name] = load(RIGS % name)
	for id in ["garden", "banquet", "basement", "inner_passage", "arena", "father_arena", "window_ledge", "gate_outside"]:
		backdrop(id)
	clown_head()
