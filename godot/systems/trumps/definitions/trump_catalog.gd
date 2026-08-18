class_name TrumpCatalog
extends Resource

## Every Trump the game knows about, in one loadable resource.
##
## Generated from `docs/design/arcana.md` by `godot/tools/gen_definitions.py` and
## loaded once by `PocketSpreadService`, which refuses to slot anything this catalog
## does not list. Nothing mutates it at runtime: a definition is authored data (see
## `TarrockDefinition`).

## The doc's twenty Trumps, in card order (I first, XX last).
@export var entries: Array[TrumpDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The Trump with this id, or `null` when the catalog does not list it.
func find(trump_id: StringName) -> TrumpDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(trump_id, null) as TrumpDefinition


## True when this id is a Trump the game knows.
func has(trump_id: StringName) -> bool:
	return find(trump_id) != null


## The Trump with this card number, or `null` when none carries it.
func find_by_card(card_number: int) -> TrumpDefinition:
	for entry: TrumpDefinition in entries:
		if entry != null and entry.card_number == card_number:
			return entry
	return null


## The Trump an unbinding flag hands over, or `null` when that flag grants none.
func find_by_flag(flag_id: StringName) -> TrumpDefinition:
	for entry: TrumpDefinition in entries:
		if entry != null and entry.granted_by_flag == flag_id:
			return entry
	return null


## Every Trump id, in card order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: TrumpDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each Trump, then the facts only the whole set can prove: no id twice, no
## card number twice, every number 1..20 used once, and - when `world_states` is
## supplied - that each `granted_by_flag` really is the UNBINDING flag of the same
## card. That last check is the one that would otherwise rot silently: a Trump
## pointing at the wrong Arcana's flag is a card the Fool is handed by the wrong
## person, and nothing else in the game would notice.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var by_card: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("trump catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("trump catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
		if by_card.has(entry.card_number):
			errors.append("card number %d is claimed by %s and %s" % [
				entry.card_number, by_card[entry.card_number], entry.id
			])
		by_card[entry.card_number] = entry.id
		if world_states == null:
			continue
		var flag := world_states.find(entry.granted_by_flag)
		if flag == null:
			errors.append("%s is granted by %s, which no world-state row defines" % [
				entry.id, entry.granted_by_flag
			])
			continue
		if not flag.is_unbinding():
			errors.append("%s is granted by %s, which is a branch flag" % [
				entry.id, entry.granted_by_flag
			])
		elif flag.arcana_number != entry.card_number:
			errors.append("%s is card %d but is granted by %s, card %d" % [
				entry.id, entry.card_number, flag.id, flag.arcana_number
			])
	for number: int in range(TrumpDefinition.FIRST_TRUMP, TrumpDefinition.LAST_TRUMP + 1):
		if not by_card.has(number):
			errors.append("no Trump carries card number %d" % number)
	return errors


func _build_index() -> void:
	_index.clear()
	for entry: TrumpDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
