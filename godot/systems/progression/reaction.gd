class_name Reaction
extends RefCounted

## How one suit-culture takes one deed, and the only place those words are spelled.
##
## `docs/design/progression.md` §Renown is canon and its deed table is the whole
## vocabulary: a cell reads "Renown up", "Slight up", "Neutral" or "Slight down".
## `DOWN` exists because the ladder is symmetric and a future row will want it - the
## table has no such cell today, and `from_doc_text()` will read one the day it does.
##
## Renown is NOT a morality meter (§Renown): a reaction is one culture's opinion of
## one deed, and the same deed moves four suits four different ways. There is no
## overall sign anywhere in this enum, deliberately.
##
## **The magnitudes are not here.** How many points "Renown up" is worth is tuning,
## not canon - the doc names no number at all - so it lives in `EconomyRules`
## (`renown_delta_for()`), which is the one place it can be turned.

## A suit-culture's reaction to a deed.
enum Id {
	## "Renown up" - this culture prizes the deed.
	UP,
	## "Slight up" - it approves, mildly.
	SLIGHT_UP,
	## "Neutral" - it does not care.
	NEUTRAL,
	## "Slight down" - it disapproves, mildly.
	SLIGHT_DOWN,
	## "Renown down" - it holds the deed against the Fool. No doc row uses it yet.
	DOWN,
}

## Every reaction, for iteration.
const ALL: Array[Id] = [Id.UP, Id.SLIGHT_UP, Id.NEUTRAL, Id.SLIGHT_DOWN, Id.DOWN]

## Returned by `from_doc_text()` when the text is not one of the doc's words.
const UNKNOWN := -1

## The stable key naming each reaction, indexed by `Id`. Never displayed.
const NAME_KEYS: Array[StringName] = [
	&"UP",
	&"SLIGHT_UP",
	&"NEUTRAL",
	&"SLIGHT_DOWN",
	&"DOWN",
]

## The doc's own wording for each reaction, lowercased, indexed by `Id`. This is what
## `from_doc_text()` matches, and it is why the drift test in
## `tests/unit/progression/deed_data_test.gd` can re-read §Renown's table and check
## the generated definitions against it without a second parser.
const DOC_TEXTS: Array[String] = [
	"renown up",
	"slight up",
	"neutral",
	"slight down",
	"renown down",
]


## The stable key naming a reaction, e.g. `&"SLIGHT_UP"`.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The reaction a stable key names, or `UNKNOWN` (-1).
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## The reaction one cell of §Renown's deed table states, or `UNKNOWN` (-1).
##
## The parenthetical is the culture's *reason* ("hospitality prized"), not part of
## the reaction, so it is cut here and kept on the definition as a doc-only note.
## Case and surrounding space are forgiven; a word the doc does not use is not.
static func from_doc_text(cell: String) -> int:
	var text := cell.strip_edges()
	var bracket := text.find("(")
	if bracket >= 0:
		text = text.substr(0, bracket)
	return DOC_TEXTS.find(text.strip_edges().to_lower())


## The reason cell `cell` gives in brackets, or `""` when it gives none.
static func note_from_doc_text(cell: String) -> String:
	var text := cell.strip_edges()
	var open_bracket := text.find("(")
	var close_bracket := text.rfind(")")
	if open_bracket < 0 or close_bracket <= open_bracket:
		return ""
	return text.substr(open_bracket + 1, close_bracket - open_bracket - 1).strip_edges()
