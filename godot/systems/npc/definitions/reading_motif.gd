class_name ReadingMotif
extends TarrockDefinition

## One notable shape the Fool's Reading can take, and the rule that recognises it.
##
## GENERATED from `docs/design/world.md` §The Fool's Reading's starter-motif table by
## `godot/tools/gen_definitions.py`; a drift test fails when this and the doc disagree.
## The doc's two cells - the motif and its example bark flavor - are carried verbatim
## as `motif_summary` and `bark_flavor`, which are DOC TEXT FOR REVIEWERS and never
## displayed. The flavor cell in particular is not a line: §The Fool's Reading calls it
## "example bark flavor", and shipping it as a bark would be shipping a sketch.
##
## The `rule` is the half a table cannot state. "Sun unbound before Star" is a sentence
## about an ordered list, and the generator hand-maps each row to one of four rules
## over `WorldStateService.reading_order()` with a `notes` line saying which row it read
## and why. That mapping is the only invented thing here and it is deliberately tiny,
## because the alternative - a bark condition that re-implements "before" per pool -
## would put the same sentence in twenty places.
##
## `npc-system.md` §Bark layers puts these at layer 2: "ambient bark pools may query
## `READING_ORDER` for notable motifs", seeded with this doc's starter motifs, and
## "quests and the NPC system may add more, locally".

## How a motif reads the Reading. Four rules cover every starter motif in the doc, and
## a fifth is a doc change before it is a code change.
enum Rule {
	## `flag_a` was unbound before `flag_b`. Both must have fired: an order between one
	## thing and nothing is not an order. ("Sun unbound before Star.")
	BEFORE,
	## `flag_a` was unbound within the first `count` unbindings. ("Death unbound in
	## Act I (first 7)" - and 7 is `world.md` §Global states' own Act I ceiling.)
	IN_FIRST_N,
	## `flag_a` was the `count`-th unbinding - the last of that many. ("Death unbound
	## last of the 20.")
	LAST_OF,
	## `flag_a` fired, and something else fired first. ("Magician not first.")
	NOT_FIRST,
}

## The layer a motif's barks live at. Always layer 2 - `npc-system.md` gives sequence
## barks one layer and no other - so it is a fact about the system, not a field.
const LAYER := BarkLayer.SEQUENCE

## The unbinding this motif is about.
@export var flag_a: StringName = &""

## The unbinding it is measured against. `BEFORE` only; `&""` for the other rules.
@export var flag_b: StringName = &""

## Which shape of the Reading this motif is.
@export var rule: Rule = Rule.BEFORE

## How many unbindings `IN_FIRST_N` and `LAST_OF` count. 0 for the other rules.
@export var count: int = 0

## The doc's own Motif cell, verbatim. Doc text for the drift test and the reviewer;
## NOTHING draws it.
@export var motif_summary: String = ""

## The doc's own "Example bark flavor" cell, verbatim. Doc text, and explicitly NOT a
## line: see the class doc. NOTHING draws it, and a writer authoring this motif's real
## pool writes new lines against it rather than shipping it.
@export var bark_flavor: String = ""

## The doc section and row this motif was generated from.
@export var doc_ref: String = ""

## Why the generator mapped this row to this rule with these parameters.
@export var notes: String = ""


## True when the Fool's Reading, as it stands, has this shape.
##
## `reading` is `WorldStateService.reading_order()`: the unbinding flags in the order
## they fired, and nothing else. An unfired flag is simply not in it, which is what
## makes every rule here total - there is no "not yet" case to handle separately.
func matches(reading: Array[StringName]) -> bool:
	var index_a := reading.find(flag_a)
	if index_a < 0:
		return false
	match rule:
		Rule.BEFORE:
			var index_b := reading.find(flag_b)
			return index_b >= 0 and index_a < index_b
		Rule.IN_FIRST_N:
			return index_a < count
		Rule.LAST_OF:
			return index_a == count - 1
		Rule.NOT_FIRST:
			return index_a > 0
	return false


## Every problem with this motif, one string per problem.
func validate() -> PackedStringArray:
	var errors := super()
	if flag_a == &"":
		errors.append("%s names no unbinding" % id)
	if rule == Rule.BEFORE and flag_b == &"":
		errors.append("%s is a BEFORE motif with nothing to be before" % id)
	if rule != Rule.BEFORE and flag_b != &"":
		errors.append("%s is not a BEFORE motif but names a second flag" % id)
	if rule == Rule.BEFORE and flag_a == flag_b:
		errors.append("%s puts an unbinding before itself" % id)
	var counts := rule == Rule.IN_FIRST_N or rule == Rule.LAST_OF
	if counts and count <= 0:
		errors.append("%s counts %d unbindings" % [id, count])
	if not counts and count != 0:
		errors.append("%s carries a count its rule never reads" % id)
	if motif_summary == "":
		errors.append("%s carries no motif cell from the doc" % id)
	return errors


## Every problem only the world-state matrix can find: a motif about an unbinding the
## matrix does not define is a bark pool that could never open, and a motif about a
## BRANCH flag is a motif about something the Reading never records.
func validate_against(world_states: WorldStateCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	if world_states == null:
		return errors
	for flag: StringName in [flag_a, flag_b]:
		if flag == &"":
			continue
		var definition := world_states.find(flag)
		if definition == null:
			errors.append("%s names %s, which no world-state row defines" % [id, flag])
		elif not definition.is_unbinding():
			errors.append("%s names %s, a branch flag the Reading never records" % [id, flag])
	return errors
