extends TarrockTest

## The two-way localization lint the round is judged by: no key without a row, and no
## row without a key.
##
## `docs/gauntlet-systems/PROMPT.md` row 13's "proves it by" cell is "Every visible
## string comes from a translation key", and `tests/unit/core/localization_lint_test.gd`
## already proves one half of that (nothing ships a literal). It cannot prove the other
## half: a key spelled in code with no CSV row behind it lints clean and shows on screen
## as `UI_SPREAD_TITLE`. So this suite closes the loop, in both directions, over the one
## place the shell spells a key (`UiKeys`).
##
## It also proves the two GENERATED families really are complete, because those are the
## ones that rot silently: a service that adds a `REASON_*` and a `technical.md` §Input
## actions list that gains an action both need a row here, and neither would ever be
## noticed by a lint that only reads code.

const UI_CSV := "res://localization/ui.csv"
const STRINGS_CSV := "res://localization/strings.csv"
const DIALOGUE_CSV := "res://localization/dialogue_mq00.csv"
const UI_KEYS_SCRIPT := "res://systems/ui/ui_keys.gd"

## The services whose refusal reasons the shell must be able to explain. Each is read
## for its `REASON_*` constants, so a service that adds one fails this suite until the
## CSV has a row for it.
const REFUSING_SERVICES: Array[String] = [
	"res://systems/trumps/pocket_spread_service.gd",
	"res://systems/regions/region_service.gd",
	"res://systems/progression/economy_service.gd",
]

## Prefixes whose rows are generated rather than named one by one.
const GENERATED_PREFIXES: Array[String] = ["UI_REFUSED_", "ACTION_"]

var _rows: Dictionary = {}


func before_each() -> void:
	TranslationServer.set_locale("en")
	_rows = {}
	for path: String in [UI_CSV, STRINGS_CSV, DIALOGUE_CSV]:
		for key: String in _keys_in(path):
			_rows[key] = path


func test_every_key_the_shell_spells_has_a_row() -> void:
	var missing := PackedStringArray()
	for key: StringName in _declared_keys():
		if not _rows.has(String(key)):
			missing.append(String(key))
	assert_eq(missing.size(), 0, "UiKeys names keys no CSV has: %s" % str(missing))


func test_every_row_of_ui_csv_is_named_by_a_constant() -> void:
	var declared: Dictionary = {}
	for key: StringName in _declared_keys():
		declared[String(key)] = true
	var orphans := PackedStringArray()
	for key: String in _keys_in(UI_CSV):
		if declared.has(key) or _is_generated(key):
			continue
		orphans.append(key)
	assert_eq(orphans.size(), 0, "ui.csv has rows nothing names: %s" % str(orphans))


func test_every_service_refusal_can_be_explained() -> void:
	var unexplained := PackedStringArray()
	for path: String in REFUSING_SERVICES:
		var script: GDScript = load(path) as GDScript
		if script == null:
			fail("%s did not load" % path)
			continue
		for constant_name: String in script.get_script_constant_map():
			if not constant_name.begins_with("REASON_"):
				continue
			var reason: StringName = script.get_script_constant_map()[constant_name]
			if UiKeys.refusal(reason) == UiKeys.REFUSED_UNKNOWN:
				unexplained.append("%s.%s" % [path.get_file(), constant_name])
	assert_eq(
		unexplained.size(), 0, "these refusals have no UI_REFUSED_ row: %s" % str(unexplained)
	)


func test_every_input_action_has_a_name_on_the_rebinding_list() -> void:
	var unnamed := PackedStringArray()
	for action_name: StringName in InputActions.ALL:
		var key := UiKeys.action(action_name)
		if not _rows.has(String(key)):
			unnamed.append(String(key))
	assert_eq(unnamed.size(), 0, "these actions have no ACTION_ row: %s" % str(unnamed))


func test_every_mq00_tutorial_prompt_has_a_row_and_translates() -> void:
	# `docs/quests/main/MQ00-the-leap.md` writes eleven prompts a player reads (the
	# twelfth bracket says "none"). See res://systems/ui/README.md for the table.
	assert_eq(UiKeys.TUTORIAL_MQ00.size(), 11)
	for key: StringName in UiKeys.TUTORIAL_MQ00:
		assert_has(_rows, String(key), "%s has no row" % key)
		assert_ne(
			TranslationServer.translate(key), String(key), "%s translates to itself" % key
		)


func test_the_keys_other_rounds_left_for_the_ui_all_have_rows() -> void:
	# The "owed to the UI round" list from the other systems' READMEs, closed off:
	# Pip's three commands, the five Renown tiers, and the Querent's own name.
	for key: StringName in PipCommand.NAME_KEYS:
		assert_has(_rows, String(key), "%s has no row" % key)
	var ladder: RenownLadder = load("res://data/progression/renown_ladder.tres") as RenownLadder
	var world_state := WorldStateService.new(
		load("res://data/world_states/catalog.tres") as WorldStateCatalog,
		load("res://data/world_states/act_thresholds.tres") as ActThresholds,
		ladder
	)
	for suit: Suit.Id in Suit.ALL:
		var key := world_state.renown_tier_name_key(suit)
		assert_has(_rows, String(key), "the Renown tier key %s has no row" % key)
	for speaker: StringName in Speakers.ALL:
		var name_key := StringName(Speakers.NAME_KEY_PREFIX + String(speaker))
		assert_has(_rows, String(name_key), "%s has no row" % name_key)


func test_a_refusal_nobody_wrote_a_row_for_falls_back_rather_than_showing_a_key() -> void:
	assert_eq(UiKeys.refusal(&"NOT_A_REAL_REASON"), UiKeys.REFUSED_UNKNOWN)
	assert_eq(UiKeys.refusal(&""), UiKeys.REFUSED_UNKNOWN)


func test_the_indexed_tables_line_up_with_the_enums_they_index() -> void:
	assert_eq(UiKeys.SLOT_TITLES.size(), SpreadSlot.ALL.size())
	assert_eq(UiKeys.SLOT_UNLOCK_RULES.size(), SpreadSlot.ALL.size())
	assert_eq(UiKeys.ORIENTATIONS.size(), CardOrientation.ALL.size())
	assert_eq(UiKeys.SUITS.size(), Suit.ALL.size())
	assert_eq(UiKeys.COURT_RANKS.size(), Rank.COURT.size())
	assert_eq(UiKeys.DIFFICULTIES.size(), DifficultyMode.ALL.size())
	assert_eq(UiKeys.HOLD_MODES.size(), HoldOrToggle.ALL_MODES.size())
	assert_eq(UiKeys.slot(SpreadSlot.Id.PRESENT), &"UI_SLOT_PRESENT")
	assert_eq(UiKeys.suit(Suit.Id.WANDS), &"UI_SUIT_WANDS")
	assert_eq(UiKeys.court_rank(Rank.Id.QUEEN), &"UI_RANK_QUEEN")
	assert_eq(UiKeys.court_rank(Rank.Id.TWO), UiKeys.EMPTY, "a pip rank prints a number")


## Every key `UiKeys` spells: its plain constants and every entry of its tables.
func _declared_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	var script: GDScript = load(UI_KEYS_SCRIPT) as GDScript
	if script == null:
		fail("UiKeys did not load")
		return keys
	for constant_name: String in script.get_script_constant_map():
		var value: Variant = script.get_script_constant_map()[constant_name]
		if value is StringName:
			keys.append(value as StringName)
		elif value is Array:
			for entry: Variant in value as Array:
				if entry is StringName:
					keys.append(entry as StringName)
	return keys


## True for a row one of the generated families owns.
func _is_generated(key: String) -> bool:
	for prefix: String in GENERATED_PREFIXES:
		if key.begins_with(prefix):
			return true
	return false


## Every key column in one CSV, header row skipped.
func _keys_in(path: String) -> PackedStringArray:
	var keys := PackedStringArray()
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	for index: int in range(1, lines.size()):
		var key := lines[index].split(",")[0].strip_edges()
		if not key.is_empty():
			keys.append(key)
	return keys
