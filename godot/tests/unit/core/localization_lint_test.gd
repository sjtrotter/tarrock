extends TarrockTest

## Localization from day one (docs/gauntlet-systems/PROMPT.md, standing decision 6).
##
## Two halves: the translation table actually loads and answers, and nothing in the
## project ships a player-facing literal where a translation key belongs.
##
## The lint half walks all three places content can hide, exactly as the docs
## promise:
##
##   * `.tscn` under `res://scenes` and `res://systems` - a displayed property on a
##     Control- or Window-derived node must hold a KEY, not a sentence.
##   * `.gd` under `res://systems` - a string literal that reads like a sentence
##     (three words or more) is a line someone forgot to wrap in `tr()`, unless it
##     goes to a diagnostic sink (see `DIAGNOSTIC_CALLS`).
##   * `.tres` under `res://data` - authored definitions carry ids and doc
##     citations; a sentence in any other property is display text in disguise.
##
## The lint is deliberately textual (no scene or resource instantiation): it must
## fail on content nobody loaded yet, and it must not need the offending scene to
## be constructible.

const TABLE_PATH := "res://localization/strings.en.translation"
const CSV_PATH := "res://localization/strings.csv"

## Where scenes live: game scenes, plus any UI a system ships with itself.
const SCENE_ROOTS: Array[String] = ["res://scenes", "res://systems"]

## Where game code lives. `res://scripts` is legacy presentation, migrated into
## `res://systems` a folder at a time (PROMPT.md, standing decision 10); it joins
## this list as it moves.
const SCRIPT_ROOTS: Array[String] = ["res://systems"]

## Where authored definitions live.
const DATA_ROOTS: Array[String] = ["res://data"]

## A translation key: SHOUTING_SNAKE_CASE and nothing else.
const KEY_PATTERN := "^[A-Z0-9_]+$"

## A `.tscn`/`.tres` property assignment, e.g. `text = "..."` or
## `popup/item_0/text = "..."`. Group 1 is the property path, group 2 the value.
const PROPERTY_PATTERN := "^([A-Za-z0-9_/]+) = \"(.*)\"$"

## Properties whose value is rendered to the player. The last segment of the
## property path is matched, so OptionButton's `popup/item_0/text` and ItemList's
## `item_0/text` are covered by `text`.
const TRANSLATED_PROPERTIES: Array[String] = [
	"text",  # Label, Button, RichTextLabel, LineEdit, ItemList/OptionButton items
	"tooltip_text",  # every Control
	"placeholder_text",  # LineEdit, TextEdit
	"dialog_text",  # AcceptDialog and friends (Window-derived, not Control)
	"title",  # Window
]

## Calls whose string arguments are developer diagnostics and never reach a player,
## so a sentence inside one is not a missing `tr()`. Each entry earns its place:
const DIAGNOSTIC_CALLS: Array[String] = [
	"print(",  # console
	"prints(",  # console
	"printt(",  # console
	"printerr(",  # stderr
	"print_debug(",  # console, debug builds only
	"push_error(",  # engine error log
	"push_warning(",  # engine warning log
	"assert(",  # stripped from release builds entirely
	"fail(",  # TarrockTest's failure recorder
	"errors.append(",  # TarrockDefinition.validate()'s problem list: read by the
	# data-drift tests and printed to a console, never displayed in game
	# (see res://systems/core/definitions/definition.gd).
]

## `.tres` properties that legitimately hold prose: they cite or summarise the doc a
## definition came from, for a human reading the resource or a drift test comparing
## it to `docs/`. None of them is ever displayed, so none needs a key.
const DOC_ONLY_PROPERTIES: Array[String] = [
	"effect_summary",  # one-line paraphrase of a Trump's doc entry, for reviewers
	"notes",  # authoring notes left by whoever lifted the content out of docs/
	"doc_ref",  # path/anchor of the owning doc section
	"source_ref",  # the exact line or table row this definition was generated from
	"description_doc",  # the doc's own description text, kept for drift comparison
	"past_summary",  # a Trump's Past cell in arcana.md, verbatim, for drift checks
	"present_summary",  # the same for its Present cell
	"future_summary",  # the same for its Future cell
	"burden_name",  # the italicised name of a Trump's reversed burden, from the doc
	"burden_summary",  # the doc's whole "Reversed burden" paragraph, verbatim
]
# NOTE on the two burden entries: they are doc text for reviewers and for the drift
# tests, and NOTHING may draw them. The day a screen shows the player which burden a
# reversed card is carrying, that name is a translation key - a `burden_name_key`
# resolved through the CSV, exactly as `TrumpDefinition.name_key` already is - and it
# is a NEW field, not this one taken off the list. Deleting an entry here to make a
# player-facing string lint clean is the failure mode this note exists to name.

## A literal needs this many spaces (three words) before it counts as a sentence
## somebody meant a player to read.
const SENTENCE_MIN_SPACES := 2


func test_the_translation_table_is_configured() -> void:
	var configured: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray()
	)
	assert_has(configured, TABLE_PATH, "project.godot must load the imported translation")


func test_the_imported_translation_exists() -> void:
	# `godot --headless --import` regenerates this from the CSV; if it is missing
	# the import step was skipped.
	assert_true(ResourceLoader.exists(TABLE_PATH), "%s is missing - run --import" % TABLE_PATH)


func test_keys_translate_to_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(TranslationServer.translate(&"UI_PAUSE"), "Paused")
	assert_eq(TranslationServer.translate(&"UI_RESUME"), "Resume")


func test_an_unknown_key_returns_itself() -> void:
	# Godot's fallback: a missing key shows as the key, which is exactly how a
	# lint failure should look on screen - loud, not blank.
	assert_eq(TranslationServer.translate(&"UI_NOT_A_REAL_KEY"), "UI_NOT_A_REAL_KEY")


func test_every_csv_key_is_a_valid_key_name() -> void:
	var regex := RegEx.new()
	regex.compile(KEY_PATTERN)
	var lines := FileAccess.get_file_as_string(CSV_PATH).split("\n", false)
	assert_true(lines.size() > 1, "the string table is not empty")
	for index: int in range(1, lines.size()):
		var key := lines[index].split(",")[0].strip_edges()
		if key.is_empty():
			continue
		assert_not_null(
			regex.search(key), "'%s' in strings.csv is not a SHOUTING_SNAKE_CASE key" % key
		)


func test_no_scene_ships_a_player_facing_literal() -> void:
	var offenders := PackedStringArray()
	for root: String in SCENE_ROOTS:
		for path: String in _files_under(root, ".tscn"):
			offenders.append_array(_scene_offenders(path))
	assert_eq(
		offenders.size(),
		0,
		"scene text must be a translation key: %s" % str(offenders)
	)


func test_no_system_script_ships_a_player_facing_literal() -> void:
	var offenders := PackedStringArray()
	for root: String in SCRIPT_ROOTS:
		for path: String in _files_under(root, ".gd"):
			offenders.append_array(_script_offenders(path))
	assert_eq(
		offenders.size(),
		0,
		"code must call tr() with a key instead of a sentence: %s" % str(offenders)
	)


func test_no_definition_resource_ships_a_player_facing_literal() -> void:
	var offenders := PackedStringArray()
	for root: String in DATA_ROOTS:
		for path: String in _files_under(root, ".tres"):
			offenders.append_array(_resource_offenders(path))
	assert_eq(
		offenders.size(),
		0,
		"definition text must be a translation key: %s" % str(offenders)
	)


## Every displayed property in one `.tscn` that holds something other than a key.
func _scene_offenders(path: String) -> PackedStringArray:
	var offenders := PackedStringArray()
	var key_regex := RegEx.new()
	key_regex.compile(KEY_PATTERN)
	var property_regex := RegEx.new()
	property_regex.compile(PROPERTY_PATTERN)
	var current_type := ""
	var current_name := ""
	var line_number := 0
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		line_number += 1
		var trimmed := line.strip_edges()
		if trimmed.begins_with("[node "):
			current_type = _quoted_field(trimmed, "type=")
			current_name = _quoted_field(trimmed, "name=")
			continue
		if not _shows_text(current_type):
			continue
		var found := property_regex.search(trimmed)
		if found == null:
			continue
		if not TRANSLATED_PROPERTIES.has(found.get_string(1).get_file()):
			continue
		var value := found.get_string(2)
		if value.is_empty() or key_regex.search(value) != null:
			continue
		offenders.append(
			'%s:%d %s(%s).%s = "%s"'
			% [path, line_number, current_name, current_type, found.get_string(1), value]
		)
	return offenders


## True when a node of this type can put a property on screen: every Control, and
## the Window family (AcceptDialog's `dialog_text`, a Window's `title`). An empty or
## script-only type (an inherited node, an instanced scene) is not judged here - the
## scene that declares the node is where its literals get linted.
func _shows_text(type_name: String) -> bool:
	if type_name.is_empty() or not ClassDB.class_exists(type_name):
		return false
	return (
		ClassDB.is_parent_class(type_name, "Control")
		or ClassDB.is_parent_class(type_name, "Window")
	)


## Every sentence-shaped string literal in one `.gd` that is not a diagnostic.
func _script_offenders(path: String) -> PackedStringArray:
	var offenders := PackedStringArray()
	var line_number := 0
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		line_number += 1
		var code := _strip_comment(line)
		if code.strip_edges().is_empty():
			continue
		if _is_diagnostic_line(code):
			continue
		for literal: String in _string_literals(code):
			if not _is_displayable(literal):
				continue
			offenders.append('%s:%d "%s"' % [path, line_number, literal])
	return offenders


## Every property in one `.tres` holding prose that is not a sanctioned doc citation.
func _resource_offenders(path: String) -> PackedStringArray:
	var offenders := PackedStringArray()
	var property_regex := RegEx.new()
	property_regex.compile(PROPERTY_PATTERN)
	var line_number := 0
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		line_number += 1
		var found := property_regex.search(line.strip_edges())
		if found == null:
			continue
		var property := found.get_string(1)
		if DOC_ONLY_PROPERTIES.has(property.get_file()):
			continue
		var value := found.get_string(2)
		if not _is_displayable(value):
			continue
		offenders.append('%s:%d %s = "%s"' % [path, line_number, property, value])
	return offenders


## A string a player could read: three words or more, and not a resource path.
func _is_displayable(literal: String) -> bool:
	if literal.begins_with("res://") or literal.begins_with("user://"):
		return false
	return literal.count(" ") >= SENTENCE_MIN_SPACES


## True when this line hands its strings to a diagnostic sink (see DIAGNOSTIC_CALLS).
## `assert_*` covers TarrockTest's whole assertion family in one rule.
func _is_diagnostic_line(code: String) -> bool:
	for call_name: String in DIAGNOSTIC_CALLS:
		if code.contains(call_name):
			return true
	return code.contains("assert_")


## The line with any trailing `#` comment removed. Approximate on purpose: it tracks
## quoting so a `#` inside a string survives, and it does not need to parse GDScript.
func _strip_comment(line: String) -> String:
	var quote := ""
	var index := 0
	while index < line.length():
		var character := line[index]
		if character == "\\" and not quote.is_empty():
			index += 2
			continue
		if quote.is_empty():
			if character == "\"" or character == "'":
				quote = character
			elif character == "#":
				return line.substr(0, index)
		elif character == quote:
			quote = ""
		index += 1
	return line


## Every string literal in one line of code, StringNames (`&"x"`) excluded: those are
## ids and signal names by construction, never display text.
func _string_literals(code: String) -> PackedStringArray:
	var literals := PackedStringArray()
	var index := 0
	while index < code.length():
		var character := code[index]
		if character != "\"" and character != "'":
			index += 1
			continue
		var is_string_name := index > 0 and code[index - 1] == "&"
		var quote := character
		var start := index + 1
		index = start
		var value := ""
		while index < code.length():
			if code[index] == "\\":
				value += code.substr(index, 2)
				index += 2
				continue
			if code[index] == quote:
				break
			value += code[index]
			index += 1
		index += 1
		if not is_string_name:
			literals.append(value)
	return literals


func _quoted_field(line: String, field: String) -> String:
	var at := line.find(field)
	if at < 0:
		return ""
	var rest := line.substr(at + field.length())
	if not rest.begins_with("\""):
		return ""
	var end := rest.find("\"", 1)
	if end < 0:
		return ""
	return rest.substr(1, end - 1)


## Every file under `dir_path` with this suffix, recursively. A missing directory is
## not an error: `res://data` is empty until a round authors its first definition.
func _files_under(dir_path: String, suffix: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child := dir_path.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_files_under(child, suffix))
		elif entry.ends_with(suffix):
			found.append(child)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
