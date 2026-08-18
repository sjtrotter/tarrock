class_name QuestDefinition
extends TarrockDefinition

## One quest, as data: everything `docs/quests/<file>.md`'s YAML frontmatter says,
## plus the hand-authored state machine that plays it.
##
## The metadata half is **generated** by `godot/tools/gen_definitions.py` from the
## frontmatter schema `docs/quests/README.md` owns, mapped exactly as
## `docs/design/technical.md` §Quests at runtime (Godot) tabulates it. The `graph`
## half is hand-authored (`QuestGraph`) and merely linked here, so regenerating the
## metadata after a frontmatter edit can never clobber an authored graph, and a quest
## whose graph nobody has written yet is a definition with a null `graph` - known to
## the game, listed in the Almanack, not yet playable.
##
## Nothing here is logic. `QuestService` reads it: `required_states` decides
## availability, `fired_states` and `branch_groups` are what completion commits
## through `WorldStateService`, and `graph` is what events move.

## Main or side, per the frontmatter's `type` (`docs/quests/README.md` §ID scheme).
enum Type {
	## `MQ##` - the 22 main quests, one per card plus the prologue.
	MAIN,
	## `SQ-<REGION|SUIT>-##` - regional, suit-culture and Spread-wide side quests.
	SIDE,
}

## The two id shapes `docs/quests/README.md` allows.
const ID_PATTERN := "^(MQ[0-9]{2}|SQ-[A-Z]+-[0-9]{2})$"

## A translation key: SHOUTING_SNAKE_CASE and nothing else.
const TITLE_KEY_PATTERN := "^[A-Z0-9_]+$"

## Card numbers a quest may carry. `0` means the frontmatter said `arcana: none`.
const NO_ARCANA := 0
const FIRST_ARCANA := 1
const LAST_ARCANA := 21

static var _id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)
static var _title_key_regex: RegEx = RegEx.create_from_string(TITLE_KEY_PATTERN)

## The quest's display title as a translation key, e.g. `&"QUEST_MQ00_TITLE"`. The
## English is in `res://localization/quest_titles.csv`; no title is ever a literal.
@export var title_key: StringName = &""

## Main or side.
@export var type: Type = Type.MAIN

## The card this quest belongs to, 1..21, or `0` for `arcana: none`.
@export var arcana_number: int = NO_ARCANA

## The home region as an uppercase token with no article, e.g. `&"CLIFF"`,
## `&"PRESTIGE"`, `&"SPREAD"` for the world-spanning quests. The region names
## themselves are `docs/GLOSSARY.md` §The world.
@export var region_id: StringName = &""

## `WS_*` flag ids and/or quest ids that must all hold before this quest is
## available (the frontmatter's `requires`).
@export var required_states: Array[StringName] = []

## `WS_*` flag ids this quest fires **on completion only** (the frontmatter's
## `fires`).
@export var fired_states: Array[StringName] = []

## The mutually exclusive flag sets this quest's choices pick between (the
## frontmatter's `branches`). Exactly one member of each is fired at completion.
@export var branch_groups: Array[QuestBranchGroup] = []

## The hand-authored state machine, or `null` when nobody has written one yet.
@export var graph: QuestGraph = null

## The quest doc this definition was generated from, e.g.
## `docs/quests/main/MQ00-the-leap.md`. Documentation for reviewers and drift tests;
## never displayed.
@export var doc_path: String = ""


## Every problem with this quest definition, one string per problem.
##
## Whether the ids it names exist needs the world-state catalog and the rest of the
## quest catalog, so `QuestCatalog.validate()` asks that; this is the shape check.
func validate() -> PackedStringArray:
	var errors := super()
	if id != &"" and _id_regex.search(String(id)) == null:
		errors.append("%s has an id no quest scheme allows: %s" % [_describe(), id])
	if title_key == &"":
		errors.append("%s has no title key" % _describe())
	elif _title_key_regex.search(String(title_key)) == null:
		errors.append("%s has a title key that is not a key: %s" % [_describe(), title_key])
	if arcana_number != NO_ARCANA and (arcana_number < FIRST_ARCANA or arcana_number > LAST_ARCANA):
		errors.append("%s carries card number %d, outside %d..%d" % [
			_describe(), arcana_number, FIRST_ARCANA, LAST_ARCANA
		])
	if region_id == &"":
		errors.append("%s names no home region" % _describe())
	if doc_path.is_empty():
		errors.append("%s cites no quest doc" % _describe())
	var group_ids: Dictionary = {}
	for group: QuestBranchGroup in branch_groups:
		if group == null:
			errors.append("%s has an empty branch group slot" % _describe())
			continue
		errors.append_array(group.validate())
		if group_ids.has(group.group_id):
			errors.append("%s lists branch group %s twice" % [_describe(), group.group_id])
		group_ids[group.group_id] = true
	if graph != null:
		if graph.quest_id != id:
			errors.append("%s links the graph of %s" % [_describe(), graph.quest_id])
		errors.append_array(graph.validate())
	return errors


## True for a main quest (`MQ##`).
func is_main() -> bool:
	return type == Type.MAIN


## True when this quest has a state machine and can therefore be played.
func is_playable() -> bool:
	return graph != null


## The branch group `flag` belongs to, or `null` when this quest does not choose it.
func branch_group_for(flag: StringName) -> QuestBranchGroup:
	for group: QuestBranchGroup in branch_groups:
		if group != null and group.has_flag(flag):
			return group
	return null


## Every branch group id this quest owes a choice to, in doc order.
func branch_group_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for group: QuestBranchGroup in branch_groups:
		if group != null and group.group_id != &"":
			ids.append(group.group_id)
	return ids
