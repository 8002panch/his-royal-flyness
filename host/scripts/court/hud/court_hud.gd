class_name CourtHud
extends CanvasLayer

## Parchment-and-gold UI over the hall. Kept to the edges so the hall stays
## the hero: ribbon on top, one objective line, the Reliquary (top-left), Hamlet's
## live brain map (top-right; it grows down the side during the drink questions),
## a caption scroll and the four role cards along the bottom.

const CARD_Y := 318

var ribbon := TopRibbon.new()
var objective := ObjectiveBanner.new()
var reliquary := Reliquary.new()
## preloaded, not by class_name, so a fresh pull runs before Godot has registered the new class
const BRAIN_MAP := preload("res://scripts/court/hud/brain_map_panel.gd")
var brain_map: Control = BRAIN_MAP.new()
const BRAIN_FULL := preload("res://scripts/court/hud/brain_full_overlay.gd")
var brain_full: Control = BRAIN_FULL.new()
const INTRO := preload("res://scripts/court/hud/intro_overlay.gd")
var intro: Control = INTRO.new()
var caption := CaptionScroll.new()
var cards: Array = []
var lobby := LobbyOverlay.new()
var chronicle := ChronicleOverlay.new()
var debug := DebugOverlay.new()
var decree := DecreeOverlay.new()
var story := StoryBanner.new()
var comic := ComicOverlay.new()
const END_SCENE := preload("res://scripts/court/hud/end_scene.gd")
var end_scene: Control = END_SCENE.new()

var _play_nodes: Array = []


func _ready() -> void:
	layer = 5
	add_child(ribbon)
	add_child(objective)
	reliquary.position = Vector2(4, 27)
	add_child(reliquary)
	add_child(brain_map)
	add_child(caption)
	for i in Pal.ROLE_ORDER.size():
		var card := RoleCard.new()
		card.setup(Pal.ROLE_ORDER[i], Vector2i(6 + i * 158, CARD_Y))
		add_child(card)
		cards.append(card)
	add_child(lobby)
	add_child(chronicle)
	debug.visible = false
	add_child(debug)
	add_child(end_scene)  # the last picture, under the end card
	add_child(story)
	comic.visible = false
	add_child(comic)
	intro.visible = false
	add_child(intro)
	move_child(brain_map, -1)  # over the comic, so it stays in view through the drink questions
	add_child(brain_full)  # B: the full-size brain, over everything but the Decree
	move_child(ribbon, -1)
	decree.visible = false
	add_child(decree)  # over everything, the ribbon included
	_play_nodes = [objective, reliquary, brain_map, caption]
	_play_nodes.append_array(cards)
	set_phase("play")


func set_phase(phase: String) -> void:
	var play := phase != "lobby" and phase != "chronicle"
	for n in _play_nodes:
		(n as CanvasItem).visible = play
	lobby.visible = phase == "lobby"
	chronicle.visible = phase == "chronicle"


func apply_state(cs: CourtState, hazard_in_view: bool) -> void:
	set_phase(cs.phase)
	ribbon.apply(cs)
	objective.set_hazard(hazard_in_view)
	objective.set_demo(cs.demo)
	objective.visible = objective.visible and cs.scene == ""  # the story has its own banner
	end_scene.apply(cs)
	story.apply(cs)
	brain_map.apply(cs)
	comic.narrow = brain_map.quiz_mode()  # the comic makes room for the map during the drink questions
	comic.apply(cs)
	intro.apply(cs)
	# the brain map is for flying; in the story it steps aside, except in the drink questions (where it has its own column)
	brain_map.visible = brain_map.visible and (cs.phase in ["play", "ready"] or brain_map.quiz_mode())
	brain_full.apply(cs)
	for c in cards:
		(c as RoleCard).apply(cs)
	if lobby.visible:
		lobby.apply(cs)
	if chronicle.visible:
		chronicle.apply(cs)
	debug.apply(cs)
	decree.apply(cs)


func on_event(ev: Dictionary) -> void:
	var kind := str(ev.get("kind", ""))
	if kind in ["voice", "voice_live"]:
		var text := str(ev.get("caption", ev.get("text", "")))
		if text != "":
			caption.show_caption(str(ev.get("speaker", "")), text)


func toggle_full_brain() -> void:
	brain_full.toggle()


func full_brain_open() -> bool:
	return brain_full.visible


func toggle_debug() -> void:
	debug.visible = not debug.visible
	debug.queue_redraw()
