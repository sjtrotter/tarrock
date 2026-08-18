extends TarrockTest

## Every string the shell actually DRAWS, read back off the built page.
##
## `docs/gauntlet-systems/PROMPT.md` row 13's "proves it by" cell is "Every visible
## string comes from a translation key", and until this suite the claim was proved by
## two lints that both look at FILES:
## `tests/unit/core/localization_lint_test.gd` reads the `.tscn` and the `.gd` text,
## and `tests/unit/ui/ui_keys_test.gd` reads `UiKeys` against the CSVs. Neither could
## see a literal that a view *assigns at runtime* - `button.text = "Resume"` inside a
## `_build()` is three words with no spaces to trip the sentence heuristic and no
## `.tscn` line to read - and every page in this folder builds its Controls in code.
## So this one BUILDS each page and reads back what it put on screen.
##
## The rule a drawn string must satisfy is the strict one, because Godot's own
## behaviour is what is being protected: a `Control` translates its `text` as it draws
## it, so the property must hold the KEY. English in that property is English on
## screen in every locale, which is exactly the failure nobody notices in English.
##
## Text that genuinely cannot be one key - a row formatted out of a key and a number,
## a device label the hardware spells - says so on the control itself
## (`UiKeys.COMPOSED_TEXT_META`), which is a claim in the scene tree a reviewer can
## check rather than a hole in the lint.

## Every page the shell can open. Read off disk rather than listed, so a page added
## without a line here is still linted.
const SCENE_DIR := "res://scenes/ui"

## The one scene under there that is not a page: the shell itself, which builds every
## page below and wires them to the live services. Each of its children is linted here
## in its own right, and instancing the shell in a unit test would attach the whole
## composition root to it.
const NOT_A_PAGE := "res://scenes/ui/ui_shell.tscn"

## Every shipped string table. A key drawn on screen must have a row in one of them.
const CSV_PATHS: Array[String] = [
	"res://localization/ui.csv",
	"res://localization/strings.csv",
	"res://localization/npc_names.csv",
	"res://localization/regions.csv",
	"res://localization/quest_titles.csv",
	"res://localization/trumps.csv",
	"res://localization/items.csv",
	"res://localization/barks_cliff.csv",
	"res://localization/dialogue_mq00.csv",
]

## A translation key: SHOUTING_SNAKE_CASE and nothing else. The same pattern
## `localization_lint_test.gd` holds the `.tscn` files to.
const KEY_PATTERN := "^[A-Z0-9_]+$"

## The properties a `Control` puts on screen as words.
const TEXT_PROPERTIES: Array[StringName] = [
	&"text",
	&"tooltip_text",
	&"placeholder_text",
]

var _keys: Dictionary = {}
var _spawned: Array[Node] = []


func before_each() -> void:
	TranslationServer.set_locale("en")
	_keys = {}
	for path: String in CSV_PATHS:
		for key: String in _keys_in(path):
			_keys[key] = path
	_spawned = []


func after_each() -> void:
	for node: Node in _spawned:
		if node != null and is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()


func test_the_string_tables_were_read() -> void:
	# Guards the suite itself: an empty table would make every assertion below pass.
	assert_true(_keys.size() > 100, "%d keys read out of the CSVs" % _keys.size())
	assert_has(_keys, "UI_RESUME")


func test_every_page_builds_with_no_services_at_all() -> void:
	var pages := _page_paths()
	assert_true(pages.size() >= 11, "%d pages under %s" % [pages.size(), SCENE_DIR])
	for path: String in pages:
		assert_not_null(_build_page(path), "%s builds with nothing attached" % path)


func test_no_page_draws_a_string_that_is_not_a_key() -> void:
	var offenders := PackedStringArray()
	for path: String in _page_paths():
		var page := _build_page(path)
		if page == null:
			continue
		_walk(page, path, offenders)
	assert_eq(
		offenders.size(),
		0,
		"a drawn string must be a translation key with a row: %s" % str(offenders)
	)


func test_the_lint_would_catch_english_written_straight_into_a_control() -> void:
	# The mutation this suite exists for, performed on purpose: the pause menu's
	# Resume row lettered with the English word instead of `UI_RESUME`.
	var page := _build_page("res://scenes/ui/pause_menu.tscn")
	if page == null:
		fail("the pause menu did not build")
		return
	var offenders := PackedStringArray()
	_walk(page, "mutant", offenders)
	assert_eq(offenders.size(), 0, "the shipped page is clean: %s" % str(offenders))

	var resume := _first_button(page)
	if resume == null:
		fail("the pause menu has no rows")
		return
	resume.text = TranslationServer.translate(UiKeys.PAUSE_RESUME)
	_walk(page, "mutant", offenders)
	assert_true(
		offenders.size() > 0,
		"a Control lettered with English rather than a key must be caught"
	)


func test_a_composed_row_says_so_and_is_still_built_out_of_keys() -> void:
	# The one sanctioned way past the rule above, and what it costs: the row carries
	# the meta, and the words in it are still the CSV's.
	var page := _build_page("res://scenes/ui/pause_menu.tscn") as PauseMenu
	if page == null:
		fail("the pause menu did not build")
		return
	var row := page.save_row(0)
	assert_not_null(row)
	assert_true(UiKeys.is_composed(row), "a formatted row declares itself")
	assert_has(
		row.text,
		TranslationServer.translate(UiKeys.SAVE_SLOT_N).format({"n": 1}),
		"and it is the CSV's own row with the number put into it"
	)
	assert_has(
		row.text,
		TranslationServer.translate(UiKeys.SAVE_SLOT_EMPTY),
		"plus the CSV's own word for a slot nothing is in"
	)


## Walk one built page, recording every string that is not a key with a row.
func _walk(node: Node, page_path: String, offenders: PackedStringArray) -> void:
	var control := node as Control
	if control != null and not UiKeys.is_composed(control):
		for property: StringName in TEXT_PROPERTIES:
			if not (String(property) in control):
				continue
			_judge(str(control.get(property)), control, property, page_path, offenders)
		for index: int in range(_tab_count(control)):
			_judge(
				_tab_title(control, index),
				control,
				&"tab_title",
				page_path,
				offenders
			)
	for child: Node in node.get_children():
		_walk(child, page_path, offenders)


## Record one drawn string if it is neither empty nor a key with a row behind it.
func _judge(
	value: String,
	control: Control,
	property: StringName,
	page_path: String,
	offenders: PackedStringArray
) -> void:
	if value.is_empty():
		return
	var regex := RegEx.new()
	regex.compile(KEY_PATTERN)
	if regex.search(value) != null and _keys.has(value):
		return
	offenders.append(
		'%s %s(%s).%s = "%s"'
		% [page_path, control.name, control.get_class(), property, value]
	)


## How many tabs this control letters, for the two that letter any.
func _tab_count(control: Control) -> int:
	var bar := control as TabBar
	if bar != null:
		return bar.tab_count
	var container := control as TabContainer
	if container != null:
		return container.get_tab_count()
	return 0


func _tab_title(control: Control, index: int) -> String:
	var bar := control as TabBar
	if bar != null:
		return bar.get_tab_title(index)
	var container := control as TabContainer
	if container != null:
		return container.get_tab_title(index)
	return ""


## Every page scene, in a stable order.
func _page_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	var dir := DirAccess.open(SCENE_DIR)
	if dir == null:
		fail("%s is missing" % SCENE_DIR)
		return paths
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := SCENE_DIR.path_join(entry)
		if entry.ends_with(".tscn") and path != NOT_A_PAGE:
			paths.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


## Instance one page and let it build itself, with nothing attached to it - which is
## what every view in this folder promises to survive.
func _build_page(path: String) -> Control:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		fail("%s did not load" % path)
		return null
	var page := packed.instantiate() as Control
	if page == null:
		fail("%s is not a Control" % path)
		return null
	tree().root.add_child(page)
	_spawned.append(page)
	return page


func _first_button(node: Node) -> Button:
	var button := node as Button
	if button != null:
		return button
	for child: Node in node.get_children():
		var found := _first_button(child)
		if found != null:
			return found
	return null


## Every key column in one CSV, header row skipped.
func _keys_in(path: String) -> PackedStringArray:
	var keys := PackedStringArray()
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	for index: int in range(1, lines.size()):
		var key := lines[index].split(",")[0].strip_edges()
		if not key.is_empty():
			keys.append(key)
	return keys
