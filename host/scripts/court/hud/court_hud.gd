class_name CourtHud
extends CanvasLayer

## Parchment-and-gold UI over the hall. Kept to the edges so the hall stays
## the hero: ribbon on top, one objective line, the Reliquary (top-left), the
## Seer's panel (top-right), a caption scroll and the four role cards along the bottom.

const CARD_Y := 318

var ribbon := TopRibbon.new()
var objective := ObjectiveBanner.new()
var reliquary := Reliquary.new()
var seer := SeerPanel.new()
var caption := CaptionScroll.new()
var cards: Array = []
var lobby := LobbyOverlay.new()
var chronicle := ChronicleOverlay.new()
var debug := DebugOverlay.new()

var _play_nodes: Array = []


func _ready() -> void:
	layer = 5
	add_child(ribbon)
	add_child(objective)
	reliquary.position = Vector2(4, 27)
	add_child(reliquary)
	seer.position = Vector2(HallCam.W - SeerPanel.PANEL.x - 4, 27)
	add_child(seer)
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
	move_child(ribbon, -1)
	_play_nodes = [objective, reliquary, seer, caption]
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
	seer.apply(cs, hazard_in_view)
	for c in cards:
		(c as RoleCard).apply(cs)
	if lobby.visible:
		lobby.apply(cs)
	if chronicle.visible:
		chronicle.apply(cs)
	debug.apply(cs)


func on_event(ev: Dictionary) -> void:
	var kind := str(ev.get("kind", ""))
	if kind in ["voice", "voice_live"]:
		var text := str(ev.get("caption", ev.get("text", "")))
		if text != "":
			caption.show_caption(str(ev.get("speaker", "")), text)


func toggle_debug() -> void:
	debug.visible = not debug.visible
	debug.queue_redraw()
