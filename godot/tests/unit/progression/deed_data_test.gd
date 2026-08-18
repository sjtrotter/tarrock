extends TarrockTest

## The generated deeds, against the table they were generated from.
##
## `docs/design/progression.md` §Renown's deed table is canon, and `DeedDefinition`
## resources are generated from it by `godot/tools/gen_definitions.py`. That tool has
## its own `--check` mode, which proves the files on disk are what the tool would
## write TODAY; this suite proves something the tool cannot prove about itself - that
## what it wrote is what the DOC says, re-read here by a second reader
## (`Reaction.from_doc_text()`) that shares no code with the generator's Python.
##
## The rule the whole table exists to keep: **Renown is not a morality meter.** The
## same deed moves four suits four different ways, and nothing anywhere sums them.

const DEED_CATALOG_PATH := "res://data/progression/deeds/catalog.tres"
const PROGRESSION_DOC_RELATIVE := "../docs/design/progression.md"

## The heading whose two tables are the deeds and the tier ladder.
const RENOWN_HEADING := "## Renown"

## A deed row: the deed, then one reaction per suit.
const DEED_ROW_CELLS := 5

var _catalog: DeedCatalog = null
var _doc: String = ""


func before_each() -> void:
	_catalog = load(DEED_CATALOG_PATH) as DeedCatalog
	_doc = FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://").path_join(PROGRESSION_DOC_RELATIVE).simplify_path()
	)


func test_the_doc_is_where_this_test_thinks_it_is() -> void:
	assert_true(_doc.length() > 1000, "progression.md was read")


func test_the_doc_has_four_deeds_and_so_does_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	var rows := _deed_rows()
	assert_eq(rows.size(), 4, "progression.md §Renown lists four example deeds")
	assert_eq(_catalog.entries.size(), rows.size(), "one definition per row, no more")


func test_every_deed_reacts_exactly_as_the_doc_table_says() -> void:
	if not assert_not_null(_catalog):
		return
	var rows := _deed_rows()
	if not assert_eq(rows.size(), _catalog.entries.size(), "the row count must match first"):
		return
	for index: int in rows.size():
		var cells: PackedStringArray = rows[index]
		var deed := _catalog.entries[index]
		if not assert_not_null(deed, "deed %d is missing" % index):
			continue
		assert_eq(deed.deed_summary, cells[0], "the deed text is the doc's cell, verbatim")
		for suit: Suit.Id in Suit.ALL:
			var cell := cells[suit + 1]
			assert_eq(
				deed.reaction_for(suit),
				Reaction.from_doc_text(cell),
				"%s / %s must read as the doc's %s" % [deed.id, Suit.name_key(suit), cell]
			)
			assert_eq(
				deed.reaction_note_for(suit),
				Reaction.note_from_doc_text(cell),
				"%s / %s keeps the doc's own reason" % [deed.id, Suit.name_key(suit)]
			)


func test_the_deed_ids_are_the_catalog_in_doc_order() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(_catalog.ids(), DeedIds.ALL)
	for deed_id: StringName in DeedIds.ALL:
		assert_true(_catalog.has(deed_id), "%s must be an authored deed" % deed_id)


func test_no_deed_leaves_every_suit_unmoved() -> void:
	if not assert_not_null(_catalog):
		return
	for deed: DeedDefinition in _catalog.entries:
		if deed != null:
			assert_true(deed.moves_anyone(), "%s moves nobody" % deed.id)


func test_the_deed_table_is_not_a_morality_axis() -> void:
	# The doc's own point, checkable: at least one deed raises one culture while it
	# costs the Fool with another. A table where every reaction pointed the same way
	# would be a good/evil meter wearing four hats.
	if not assert_not_null(_catalog):
		return
	var split := false
	for deed: DeedDefinition in _catalog.entries:
		if deed == null:
			continue
		var up := false
		var down := false
		for suit: Suit.Id in Suit.ALL:
			var reaction := deed.reaction_for(suit)
			up = up or reaction == Reaction.Id.UP or reaction == Reaction.Id.SLIGHT_UP
			down = down or reaction == Reaction.Id.DOWN or reaction == Reaction.Id.SLIGHT_DOWN
		split = split or (up and down)
	assert_true(split, "some deed must please one culture and cost another")


func test_an_unknown_reaction_word_reads_as_unknown() -> void:
	assert_eq(Reaction.from_doc_text("Renown sideways"), Reaction.UNKNOWN)
	assert_eq(Reaction.from_doc_text("Slight up (spectacle)"), Reaction.Id.SLIGHT_UP)
	assert_eq(Reaction.note_from_doc_text("Slight up (spectacle)"), "spectacle")
	assert_eq(Reaction.note_from_doc_text("Neutral"), "")


# --- Reading the doc ----------------------------------------------------------


## Every deed row of §Renown, as its stripped cells.
##
## The section holds two tables - the deeds and the tier ladder - and they are told
## apart by width, exactly as the generator tells them apart from the other side.
func _deed_rows() -> Array:
	var rows: Array = []
	var seen_separator := false
	var in_section := false
	for line: String in _doc.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed == RENOWN_HEADING:
			in_section = true
			continue
		if not in_section:
			continue
		if trimmed.begins_with("## "):
			break
		if not trimmed.begins_with("|"):
			seen_separator = false
			continue
		var cells := _cells(trimmed)
		if _is_separator(cells):
			seen_separator = true
			continue
		if not seen_separator or cells.size() != DEED_ROW_CELLS:
			continue
		rows.append(cells)
	return rows


func _cells(row: String) -> PackedStringArray:
	var found := PackedStringArray()
	for cell: String in row.trim_prefix("|").trim_suffix("|").split("|"):
		found.append(cell.strip_edges().replace("`", "").replace("**", ""))
	return found


func _is_separator(cells: PackedStringArray) -> bool:
	for cell: String in cells:
		if cell.is_empty() or cell.lstrip("-:") != "":
			return false
	return true
