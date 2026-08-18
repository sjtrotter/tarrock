class_name Almanack
extends Control

## The Fool's journal, as a hand-annotated manuscript rather than a database screen.
##
## `docs/design/art-audio.md` §Map, the Almanack, and UI: "The player's journal is
## called **the Almanack** ... The Almanack collects quest logs, the Bestiary of Blanks
## and beasts encountered, the Pocket Spread's collected Trumps, and any lore pages
## found in the world, styled as a hand-annotated manuscript rather than a database
## screen." Five tabs, in that order plus the Reading.
##
## **A Blank has no name.** `docs/design/combat.md` §Enemies gives none and
## `systems/enemies/README.md` says so outright, so the Bestiary names the CARD: the
## suit's shape and the rank's printed number, which is also the colourblind-safe read
## `art-audio.md` §Accessibility notes demands ("shape and card-rank pip count are
## always the primary read, color is secondary").
##
## The Reading is `WorldStateService.reading_order()` - the order the Fool unbound the
## Arcana - drawn as the row of cards it is.

## The player asked to put this page down.
signal close_requested()

var _quests: QuestService = null
var _world_state: WorldStateService = null
var _spread: PocketSpreadService = null
var _enemies: EnemyService = null
var _quest_catalog: QuestCatalog = null
var _trump_catalog: TrumpCatalog = null

var _tabs: TabContainer = null
var _quest_list: VBoxContainer = null
var _reading_row: HBoxContainer = null
var _trump_row: HFlowContainer = null
var _bestiary_list: VBoxContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


## Hand the Almanack a playthrough to read. Every argument may be null.
func attach(
	quests: QuestService,
	world_state: WorldStateService,
	spread: PocketSpreadService,
	enemies: EnemyService,
	quest_catalog: QuestCatalog,
	trump_catalog: TrumpCatalog
) -> void:
	_disconnect()
	_quests = quests
	_world_state = world_state
	_spread = spread
	_enemies = enemies
	_quest_catalog = quest_catalog
	_trump_catalog = trump_catalog
	_connect()
	refresh()


## The tab strip.
func tabs() -> TabContainer:
	return _tabs


## The quest title keys listed, in the order they are written.
func quest_title_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for child: Node in _quest_list.get_children():
		var label := child as Label
		if label != null:
			keys.append(StringName(label.text))
	return keys


## How many cards the Reading row has turned.
func reading_count() -> int:
	return _reading_row.get_child_count()


## The Reading's cards, in the order the Fool unbound them.
func reading_card(index: int) -> CardView:
	if index < 0 or index >= _reading_row.get_child_count():
		return null
	return _reading_row.get_child(index) as CardView


## How many Trumps the collection page shows.
func trump_count() -> int:
	return _trump_row.get_child_count()


## How many creatures the Bestiary has written up.
func bestiary_count() -> int:
	return _bestiary_list.get_child_count()


## Redraw every page.
func refresh() -> void:
	_refresh_quests()
	_refresh_reading()
	_refresh_trumps()
	_refresh_bestiary()


func _build() -> void:
	add_child(UiFrames.panel_frame())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 64)
	margin.add_theme_constant_override(&"margin_right", 64)
	margin.add_theme_constant_override(&"margin_top", 52)
	margin.add_theme_constant_override(&"margin_bottom", 52)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var close := Button.new()
	close.text = String(UiKeys.CLOSE)
	close.pressed.connect(close_requested.emit)
	column.add_child(close)
	var title := Label.new()
	title.text = String(UiKeys.ALMANACK_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)

	_quest_list = VBoxContainer.new()
	_quest_list.name = String(UiKeys.ALMANACK_TAB_QUESTS)
	_tabs.add_child(_quest_list)

	var reading_page := VBoxContainer.new()
	reading_page.name = String(UiKeys.ALMANACK_TAB_READING)
	_tabs.add_child(reading_page)
	_reading_row = HBoxContainer.new()
	reading_page.add_child(_reading_row)

	var trump_page := VBoxContainer.new()
	trump_page.name = String(UiKeys.ALMANACK_TAB_TRUMPS)
	_tabs.add_child(trump_page)
	_trump_row = HFlowContainer.new()
	trump_page.add_child(_trump_row)

	_bestiary_list = VBoxContainer.new()
	_bestiary_list.name = String(UiKeys.ALMANACK_TAB_BESTIARY)
	_tabs.add_child(_bestiary_list)

	var lore_page := VBoxContainer.new()
	lore_page.name = String(UiKeys.ALMANACK_TAB_LORE)
	_tabs.add_child(lore_page)
	var lore_empty := Label.new()
	# Nothing in the world drops a lore page yet; the page exists because the doc says
	# the Almanack collects them, and an empty page says so honestly.
	lore_empty.text = String(UiKeys.ALMANACK_EMPTY)
	lore_page.add_child(lore_empty)


func _connect() -> void:
	if _quests != null:
		_quests.quest_started.connect(_on_quest_changed)
		_quests.quest_completed.connect(_on_quest_changed)
	if _world_state != null:
		_world_state.reading_appended.connect(_on_reading_appended)
	if _spread != null:
		_spread.trump_gained.connect(_on_quest_changed)


func _disconnect() -> void:
	if _quests != null:
		_drop(_quests.quest_started, _on_quest_changed)
		_drop(_quests.quest_completed, _on_quest_changed)
	if _world_state != null:
		_drop(_world_state.reading_appended, _on_reading_appended)
	if _spread != null:
		_drop(_spread.trump_gained, _on_quest_changed)


## Disconnect one handler if it is connected.
static func _drop(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)


func _on_quest_changed(_id: StringName) -> void:
	refresh()


func _on_reading_appended(_flag_id: StringName, _index: int) -> void:
	refresh()


func _refresh_quests() -> void:
	_clear(_quest_list)
	if _quests == null or _quest_catalog == null:
		return
	var active := Label.new()
	active.text = String(UiKeys.ALMANACK_QUESTS_ACTIVE)
	_quest_list.add_child(active)
	for quest_id: StringName in _quests.active_quest_ids():
		_add_quest_row(quest_id)
	var done := Label.new()
	done.text = String(UiKeys.ALMANACK_QUESTS_DONE)
	_quest_list.add_child(done)
	for definition: QuestDefinition in _quest_catalog.entries:
		if definition != null and _quests.is_complete(definition.id):
			_add_quest_row(definition.id)


func _add_quest_row(quest_id: StringName) -> void:
	var definition := _quest_catalog.find(quest_id)
	if definition == null:
		return
	var row := Label.new()
	row.text = String(definition.title_key)
	_quest_list.add_child(row)


func _refresh_reading() -> void:
	_clear(_reading_row)
	if _world_state == null:
		return
	for flag_id: StringName in _world_state.reading_order():
		var card := CardView.new()
		card.set_face_up(true)
		var trump: TrumpDefinition = null
		if _trump_catalog != null:
			trump = _trump_catalog.find_by_flag(flag_id)
		card.set_name_key(&"" if trump == null else trump.name_key)
		card.set_number(0 if trump == null else trump.card_number)
		_reading_row.add_child(card)


func _refresh_trumps() -> void:
	_clear(_trump_row)
	if _spread == null:
		return
	for trump_id: StringName in _spread.held_ids():
		var definition := _spread.definition(trump_id)
		var card := CardView.new()
		card.set_face_up(true)
		card.set_name_key(&"" if definition == null else definition.name_key)
		card.set_number(0 if definition == null else definition.card_number)
		_trump_row.add_child(card)


func _refresh_bestiary() -> void:
	_clear(_bestiary_list)
	if _enemies == null:
		return
	for definition: EnemyDefinition in _enemies.seen_definitions():
		_bestiary_list.add_child(_bestiary_row(definition))


## One creature, named the only way canon allows: its suit's shape, and its rank's
## printed number (or the Court rank's own name, which a court card prints instead).
func _bestiary_row(definition: EnemyDefinition) -> Control:
	var row := HBoxContainer.new()
	var mark := TextureRect.new()
	mark.texture = UiFrames.suit_texture(definition.suit)
	mark.custom_minimum_size = Vector2(24.0, 24.0)
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(mark)
	var suit_label := Label.new()
	suit_label.text = String(UiKeys.suit(definition.suit))
	row.add_child(suit_label)
	var rank_label := Label.new()
	# A pip rank prints its number and a Court rank prints its key: the first is a
	# numeral, so the row declares itself composed (`UiKeys.COMPOSED_TEXT_META`).
	UiKeys.mark_composed(rank_label, UiKeys.COMPOSED_NUMBER)
	var printed := definition.printed_number()
	if printed > 0:
		rank_label.text = str(printed)
	else:
		rank_label.text = String(UiKeys.court_rank(definition.rank))
	row.add_child(rank_label)
	return row


static func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
