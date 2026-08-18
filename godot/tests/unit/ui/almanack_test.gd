extends TarrockTest

## The Almanack: the five pages `art-audio.md` says the Fool's journal collects.
##
## `docs/design/art-audio.md` §Map, the Almanack, and UI: "The Almanack collects quest
## logs, the Bestiary of Blanks and beasts encountered, the Pocket Spread's collected
## Trumps, and any lore pages found in the world". The Reading is the sixth thing it can
## honestly show, because `world.md` §The Fool's Reading makes the ORDER of unbinding a
## fact the world remembers - and a manuscript that records the journey would record it.
##
## The Bestiary's rows are the sharp end: `combat.md` §Enemies gives a Blank no name, so
## the page must name the CARD - suit shape, printed number - and this suite fails if
## anybody ever writes an enemy display name into it.

const ALMANACK_SCENE := "res://scenes/ui/almanack.tscn"
const QUEST_CATALOG_PATH := "res://data/quests/catalog.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const ENEMY_CATALOG_PATH := "res://data/enemies/catalog.tres"
const ENEMY_RULES_PATH := "res://data/enemies/enemy_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

const FIRED_BY := &"tests/unit/ui/almanack_test.gd"

var _almanack: Almanack = null
var _world_state: WorldStateService = null
var _quests: QuestService = null
var _spread: PocketSpreadService = null
var _enemies: EnemyService = null
var _quest_catalog: QuestCatalog = null
var _trumps: TrumpCatalog = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	var rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_quest_catalog = load(QUEST_CATALOG_PATH) as QuestCatalog
	_quests = QuestService.new(_world_state, _quest_catalog)
	_trumps = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	_spread = PocketSpreadService.new(
		_world_state, _trumps, rules, FortuneService.new(rules)
	)
	_enemies = EnemyService.new(
		load(ENEMY_CATALOG_PATH) as EnemyCatalog, load(ENEMY_RULES_PATH) as EnemyRules
	)
	_almanack = (load(ALMANACK_SCENE) as PackedScene).instantiate() as Almanack
	tree().root.add_child(_almanack)


func after_each() -> void:
	if _almanack != null and is_instance_valid(_almanack):
		_almanack.get_parent().remove_child(_almanack)
		_almanack.free()
	_almanack = null


func test_an_almanack_with_no_playthrough_shows_empty_pages() -> void:
	assert_eq(_almanack.tabs().get_tab_count(), 5)
	assert_eq(_almanack.quest_title_keys().size(), 0)
	assert_eq(_almanack.reading_count(), 0)
	assert_eq(_almanack.trump_count(), 0)
	assert_eq(_almanack.bestiary_count(), 0)


func test_the_pages_are_the_ones_the_doc_names() -> void:
	var titles := PackedStringArray()
	for index: int in range(_almanack.tabs().get_tab_count()):
		titles.append(_almanack.tabs().get_tab_title(index))
	# A tab's title is its page node's name, which the `TabContainer` translates as it
	# draws it - so what is stored is the KEY, and what the player reads is the row.
	assert_eq(titles.size(), 5)
	for key: StringName in [
		UiKeys.ALMANACK_TAB_QUESTS,
		UiKeys.ALMANACK_TAB_READING,
		UiKeys.ALMANACK_TAB_TRUMPS,
		UiKeys.ALMANACK_TAB_BESTIARY,
		UiKeys.ALMANACK_TAB_LORE,
	]:
		assert_has(titles, String(key), "%s is a page" % key)
		assert_ne(
			TranslationServer.translate(key), String(key), "%s has a row to draw" % key
		)


func test_a_started_quest_is_written_in_by_its_title_key() -> void:
	_attach()
	assert_true(_quests.start(QuestIds.MQ00))
	var keys := _almanack.quest_title_keys()
	assert_has(keys, &"QUEST_MQ00_TITLE", "the quest is in hand: %s" % str(keys))
	assert_has(keys, UiKeys.ALMANACK_QUESTS_ACTIVE)
	assert_has(keys, UiKeys.ALMANACK_QUESTS_DONE)


func test_the_reading_is_the_order_the_arcana_were_unbound() -> void:
	_attach()
	assert_eq(_almanack.reading_count(), 0)
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, FIRED_BY)
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, FIRED_BY)
	assert_eq(_almanack.reading_count(), 2)
	# The order is the Fool's own, not the deck's.
	assert_eq(
		_almanack.reading_card(0).name_key(),
		_trumps.find_by_flag(WorldStateIds.WS_SUN_UNBOUND).name_key
	)
	assert_eq(
		_almanack.reading_card(1).name_key(),
		_trumps.find_by_flag(WorldStateIds.WS_MAGICIAN_UNBOUND).name_key
	)
	assert_true(_almanack.reading_card(0).is_face_up(), "a turned card stays turned")


func test_the_trumps_page_holds_what_the_spread_holds() -> void:
	_attach()
	assert_eq(_almanack.trump_count(), 0)
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, FIRED_BY)
	assert_eq(_almanack.trump_count(), _spread.held_count())
	assert_eq(_almanack.trump_count(), 1)


func test_the_bestiary_writes_up_only_what_has_been_met() -> void:
	_attach()
	assert_eq(_almanack.bestiary_count(), 0, "a Fool who has met nothing has met nothing")
	var two_of_wands := _enemies.blank(Suit.Id.WANDS, Rank.Id.TWO)
	assert_not_null(two_of_wands)
	assert_true(_enemies.mark_seen(two_of_wands.id))
	assert_false(_enemies.mark_seen(two_of_wands.id), "meeting it twice writes one entry")
	_almanack.refresh()
	assert_eq(_almanack.bestiary_count(), 1)


func test_the_bestiary_names_the_card_because_a_blank_has_no_name() -> void:
	_attach()
	var two_of_wands := _enemies.blank(Suit.Id.WANDS, Rank.Id.TWO)
	_enemies.mark_seen(two_of_wands.id)
	var king_of_cups := _enemies.blank(Suit.Id.CUPS, Rank.Id.KING)
	_enemies.mark_seen(king_of_cups.id)
	_almanack.refresh()
	assert_eq(_almanack.bestiary_count(), 2)

	var texts := _bestiary_texts()
	assert_has(texts, TranslationServer.translate(UiKeys.SUITS[Suit.Id.WANDS]))
	assert_has(texts, "2", "a pip rank prints its number")
	assert_has(
		texts,
		TranslationServer.translate(UiKeys.COURT_RANKS[Rank.court_index(Rank.Id.KING)]),
		"a Court rank prints its own rank"
	)
	assert_false(texts.has(String(two_of_wands.id)), "an enemy id is never shown")


func test_the_bestiary_survives_a_snapshot_round_trip() -> void:
	# Persisting it is the save lane's shape to change (see systems/ui/README.md);
	# the pair the save round will call is real and proved here.
	var wands := _enemies.blank(Suit.Id.WANDS, Rank.Id.TWO)
	_enemies.mark_seen(wands.id)
	var snapshot := _enemies.to_snapshot()
	assert_eq(snapshot.size(), 1)

	var fresh := EnemyService.new(
		load(ENEMY_CATALOG_PATH) as EnemyCatalog, load(ENEMY_RULES_PATH) as EnemyRules
	)
	assert_eq(fresh.restore_snapshot(snapshot).size(), 0)
	assert_true(fresh.has_seen(wands.id))
	assert_eq(fresh.restore_snapshot([&"NOT_AN_ENEMY"] as Array).size(), 1, "a bad id is reported")


func _attach() -> void:
	_almanack.attach(
		_quests, _world_state, _spread, _enemies, _quest_catalog, _trumps
	)


func _bestiary_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	_collect(_almanack, texts)
	return texts


func _collect(node: Node, into: PackedStringArray) -> void:
	var label := node as Label
	if label != null and not label.text.is_empty():
		into.append(label.atr(label.text))
	for child: Node in node.get_children():
		_collect(child, into)
