class_name PocketSpreadScreen
extends Control

## The Pocket Spread, dealt: Past, Present and Future as three real cards.
##
## `docs/design/art-audio.md` §UI/UX pillars: "the Pocket Spread's Past/Present/Future
## slots are rendered as an actual three-card spread, not an ability-bar reskin."
## `docs/design/progression.md` §Slot unlock pacing: a slot that has not opened yet is
## drawn FACE-DOWN with the rule that opens it lettered beneath - the pacing is content
## the player can read, not a greyed-out button.
##
## Every verb goes through `PocketSpreadService`, including the refusals: this screen
## never decides that a card may be slotted, it asks, and it shows the service's own
## reason on a chip when the answer is no. Loadouts appear only where they are allowed
## (`progression.md` §Waystations: "Full loadout saving and respec ... is available at
## Waystations only"), which the service reports through `at_waystation()`.
##
## **What a Trump DOES is not written here.** `arcana.md` owns each card's three
## effects and none has player-facing text yet, so each slot letters
## `UiKeys.TRUMP_TEXT_PENDING` under the card. Those texts are a writing request, listed
## in `res://systems/ui/README.md`.

## What the player's saved spreads are called when the screen saves one for them. The
## label is player data (`SpreadLoadout`), never a translation key; a naming field is
## an art/UX request, not this round's.
const DEFAULT_LOADOUT_LABEL := ""

## The player asked to put this page down.
signal close_requested()

var _spread: PocketSpreadService = null
var _cards: Array[CardView] = []
var _rules: Array[Label] = []
var _effects: Array[Label] = []
var _orientations: Array[Label] = []
var _hand: HFlowContainer = null
var _hand_buttons: Array[Button] = []
var _loadouts: VBoxContainer = null
var _loadout_list: VBoxContainer = null
var _chip: PromptChip = null
var _last_refusal: StringName = &""
var _selected: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


## Watch this Spread. Null detaches.
func attach(spread: PocketSpreadService) -> void:
	if _spread == spread:
		return
	_disconnect()
	_spread = spread
	_connect()
	refresh()


## The service being drawn, or null.
func spread() -> PocketSpreadService:
	return _spread


## The card drawn in one slot, or null.
func slot_card(slot: SpreadSlot.Id) -> CardView:
	if slot < 0 or slot >= _cards.size():
		return null
	return _cards[slot]


## The key of the rule lettered under a still-locked slot, or `&""` when it is open.
func slot_rule_key(slot: SpreadSlot.Id) -> StringName:
	if slot < 0 or slot >= _rules.size():
		return &""
	return &"" if not _rules[slot].visible else StringName(_rules[slot].text)


## How many Trumps are drawn in the hand below the spread.
func hand_count() -> int:
	return _hand_buttons.size()


## One card of the hand, or null.
func hand_button(index: int) -> Button:
	if index < 0 or index >= _hand_buttons.size():
		return null
	return _hand_buttons[index]


## The Trump the player has picked up out of the hand, or `&""`.
func selected_trump_id() -> StringName:
	return _selected


## Pick a Trump up out of the hand, so a slot can be tapped to lay it down.
func select(trump_id: StringName) -> void:
	_selected = trump_id


## Lay the picked-up Trump in a slot. The service decides; a refusal lands on the chip.
func assign(slot: SpreadSlot.Id, orientation: CardOrientation.Id = CardOrientation.Id.UPRIGHT) -> bool:
	if _spread == null or _selected == &"":
		return false
	return _spread.assign(slot, _selected, orientation)


## Turn the card in a slot the other way about, keeping the card.
func flip(slot: SpreadSlot.Id) -> bool:
	if _spread == null:
		return false
	var trump_id := _spread.slotted_trump_id(slot)
	if trump_id == &"":
		return false
	var turned := CardOrientation.Id.UPRIGHT
	if _spread.slotted_orientation(slot) == CardOrientation.Id.UPRIGHT:
		turned = CardOrientation.Id.REVERSED
	return _spread.assign(slot, trump_id, turned)


## Take the card in a slot back into the hand.
func clear(slot: SpreadSlot.Id) -> bool:
	return false if _spread == null else _spread.clear(slot)


## True while the loadouts panel is drawn - a Waystation, and nowhere else.
func loadouts_visible() -> bool:
	return _loadouts != null and _loadouts.visible


## How many saved spreads are listed.
func loadout_count() -> int:
	return 0 if _loadout_list == null else _loadout_list.get_child_count()


## The chip a refusal is written on.
func refusal_chip() -> PromptChip:
	return _chip


## The key of the last refusal shown, or `&""` when nothing has been refused.
func last_refusal_key() -> StringName:
	return _last_refusal


## Redraw everything from the service.
func refresh() -> void:
	_refresh_slots()
	_refresh_hand()
	_refresh_loadouts()


func _build() -> void:
	add_child(UiFrames.panel_frame())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 64)
	margin.add_theme_constant_override(&"margin_right", 64)
	margin.add_theme_constant_override(&"margin_top", 52)
	margin.add_theme_constant_override(&"margin_bottom", 52)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	margin.add_child(column)

	var close := Button.new()
	close.text = String(UiKeys.CLOSE)
	close.pressed.connect(close_requested.emit)
	column.add_child(close)
	var title := Label.new()
	title.text = String(UiKeys.SPREAD_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 24)
	column.add_child(row)
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		row.add_child(_build_slot(slot))

	var hand_title := Label.new()
	hand_title.text = String(UiKeys.SPREAD_HAND)
	column.add_child(hand_title)
	_hand = HFlowContainer.new()
	column.add_child(_hand)

	_loadouts = VBoxContainer.new()
	_loadouts.visible = false
	column.add_child(_loadouts)
	var loadout_title := Label.new()
	loadout_title.text = String(UiKeys.SPREAD_LOADOUTS)
	_loadouts.add_child(loadout_title)
	var save_button := Button.new()
	save_button.text = String(UiKeys.SPREAD_SAVE_LOADOUT)
	save_button.pressed.connect(_on_save_loadout)
	_loadouts.add_child(save_button)
	_loadout_list = VBoxContainer.new()
	_loadouts.add_child(_loadout_list)

	_chip = PromptChip.new()
	_chip.custom_minimum_size = Vector2(420.0, 0.0)
	column.add_child(_chip)


func _build_slot(slot: SpreadSlot.Id) -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	var title := Label.new()
	title.text = String(UiKeys.slot(slot))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var card := CardView.new()
	column.add_child(card)
	_cards.append(card)
	var orientation := Label.new()
	orientation.text = String(UiKeys.orientation(CardOrientation.Id.UPRIGHT))
	orientation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(orientation)
	_orientations.append(orientation)
	var effect := Label.new()
	effect.text = String(UiKeys.TRUMP_TEXT_PENDING)
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(effect)
	_effects.append(effect)
	var rule := Label.new()
	rule.text = String(UiKeys.SLOT_UNLOCK_RULES[slot])
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rule)
	_rules.append(rule)
	var flip_button := Button.new()
	flip_button.text = String(UiKeys.SPREAD_FLIP)
	flip_button.pressed.connect(flip.bind(slot))
	column.add_child(flip_button)
	var clear_button := Button.new()
	clear_button.text = String(UiKeys.SPREAD_CLEAR)
	clear_button.pressed.connect(clear.bind(slot))
	column.add_child(clear_button)
	return column


func _connect() -> void:
	if _spread == null:
		return
	_spread.slot_assigned.connect(_on_slot_assigned)
	_spread.slot_cleared.connect(_on_slot_cleared)
	_spread.slot_unlocked.connect(_on_slot_unlocked)
	_spread.trump_gained.connect(_on_trump_gained)
	_spread.assignment_refused.connect(_on_assignment_refused)
	_spread.loadout_saved.connect(_on_loadout_changed)
	_spread.loadout_applied.connect(_on_loadout_changed)
	_spread.loadout_refused.connect(_on_loadout_refused)


func _disconnect() -> void:
	if _spread == null:
		return
	_drop(_spread.slot_assigned, _on_slot_assigned)
	_drop(_spread.slot_cleared, _on_slot_cleared)
	_drop(_spread.slot_unlocked, _on_slot_unlocked)
	_drop(_spread.trump_gained, _on_trump_gained)
	_drop(_spread.assignment_refused, _on_assignment_refused)
	_drop(_spread.loadout_saved, _on_loadout_changed)
	_drop(_spread.loadout_applied, _on_loadout_changed)
	_drop(_spread.loadout_refused, _on_loadout_refused)


## Disconnect one handler if it is connected. A detach must be safe to call twice.
static func _drop(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)


func _on_slot_assigned(_slot: SpreadSlot.Id, _trump_id: StringName, _orientation: CardOrientation.Id) -> void:
	refresh()


func _on_slot_cleared(_slot: SpreadSlot.Id) -> void:
	refresh()


func _on_slot_unlocked(_slot: SpreadSlot.Id) -> void:
	refresh()


func _on_trump_gained(_trump_id: StringName) -> void:
	refresh()


func _on_assignment_refused(_slot: SpreadSlot.Id, reason: StringName) -> void:
	_show_refusal(reason)


func _on_loadout_refused(_index: int, reason: StringName) -> void:
	_show_refusal(reason)


func _on_loadout_changed(_index: int) -> void:
	refresh()


func _on_save_loadout() -> void:
	if _spread != null:
		_spread.save_loadout(DEFAULT_LOADOUT_LABEL)


func _show_refusal(reason: StringName) -> void:
	_last_refusal = UiKeys.refusal(reason)
	if _chip != null:
		_chip.show_prompt(_last_refusal)


func _refresh_slots() -> void:
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		var card := _cards[slot]
		var rule := _rules[slot]
		var effect := _effects[slot]
		var unlocked := _spread != null and _spread.is_slot_unlocked(slot)
		rule.visible = not unlocked
		effect.visible = unlocked
		_orientations[slot].visible = unlocked and _spread.slotted_trump_id(slot) != &""
		if not unlocked:
			card.set_face_up(false)
			card.set_name_key(&"")
			card.set_number(0)
			card.set_reversed(false)
			continue
		var trump_id := _spread.slotted_trump_id(slot)
		if trump_id == &"":
			card.set_face_up(true)
			card.set_name_key(UiKeys.SLOT_EMPTY)
			card.set_number(0)
			card.set_reversed(false)
			continue
		var definition := _spread.definition(trump_id)
		card.set_face_up(true)
		card.set_name_key(&"" if definition == null else definition.name_key)
		card.set_number(0 if definition == null else definition.card_number)
		var facing := _spread.slotted_orientation(slot)
		card.set_reversed(facing == CardOrientation.Id.REVERSED)
		_orientations[slot].text = String(UiKeys.orientation(facing))


func _refresh_hand() -> void:
	for button: Button in _hand_buttons:
		_hand.remove_child(button)
		button.queue_free()
	_hand_buttons.clear()
	if _spread == null:
		return
	for trump_id: StringName in _spread.held_ids():
		var definition := _spread.definition(trump_id)
		var button := Button.new()
		button.text = String(UiKeys.EMPTY if definition == null else definition.name_key)
		button.pressed.connect(select.bind(trump_id))
		_hand.add_child(button)
		_hand_buttons.append(button)


func _refresh_loadouts() -> void:
	if _loadouts == null:
		return
	_loadouts.visible = _spread != null and _spread.at_waystation()
	for child: Node in _loadout_list.get_children():
		_loadout_list.remove_child(child)
		child.queue_free()
	if _spread == null:
		return
	var saved := _spread.loadouts()
	for index: int in range(saved.size()):
		var row := HBoxContainer.new()
		var apply_button := Button.new()
		apply_button.text = String(UiKeys.SPREAD_APPLY_LOADOUT)
		apply_button.pressed.connect(_spread.apply_loadout.bind(index))
		row.add_child(apply_button)
		var delete_button := Button.new()
		delete_button.text = String(UiKeys.SPREAD_DELETE_LOADOUT)
		delete_button.pressed.connect(_spread.delete_loadout.bind(index))
		row.add_child(delete_button)
		_loadout_list.add_child(row)
