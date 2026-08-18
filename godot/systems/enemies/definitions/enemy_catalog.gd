class_name EnemyCatalog
extends Resource

## Every enemy the game knows about, in one loadable resource.
##
## Generated from `docs/design/combat.md` by `godot/tools/gen_definitions.py` and
## loaded once by `EnemyService`, which refuses to spawn anything this catalog does
## not list. Nothing mutates it at runtime: a definition is authored data (see
## `TarrockDefinition`).
##
## The set is closed and the doc closes it: four suits x thirteen ranks of Blank, plus
## the two other families §Other enemy families names. `validate()` proves the whole
## grid is present exactly once, which is what stops a suit quietly losing its Nine.

## Every enemy definition: the Blanks in suit-then-rank order, then the other
## families in the order the doc lists them.
@export var entries: Array[EnemyDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The enemy with this id, or `null` when the catalog does not list it.
func find(enemy_id: StringName) -> EnemyDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(enemy_id, null) as EnemyDefinition


## True when this id is an enemy the game knows.
func has(enemy_id: StringName) -> bool:
	return find(enemy_id) != null


## The Blank of this suit and rank, or `null` when the catalog has none.
func find_blank(suit: Suit.Id, rank: Rank.Id) -> EnemyDefinition:
	for entry: EnemyDefinition in entries:
		if entry == null or not entry.has_suit_and_rank():
			continue
		if entry.suit == int(suit) and entry.rank == int(rank):
			return entry
	return null


## Every enemy of one family, in catalog order.
func of_family(family: EnemyFamily.Id) -> Array[EnemyDefinition]:
	var found: Array[EnemyDefinition] = []
	for entry: EnemyDefinition in entries:
		if entry != null and entry.family == family:
			found.append(entry)
	return found


## Every enemy id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: EnemyDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each definition, then the facts only the whole set can prove: no id twice,
## every suit x rank present exactly once, and exactly one of each other family. When
## `world_states` is supplied it also resolves the two world-state flags §Other enemy
## families names - a Beast calmed by a flag the matrix does not define would be a
## Beast nothing ever calms, and nothing else in the game would notice.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var grid: Dictionary = {}
	var family_counts: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("enemy catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("enemy catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
		family_counts[entry.family] = int(family_counts.get(entry.family, 0)) + 1
		if entry.has_suit_and_rank():
			var key := "%d:%d" % [entry.suit, entry.rank]
			if grid.has(key):
				errors.append("%s and %s are the same suit and rank" % [grid[key], entry.id])
			grid[key] = entry.id
		errors.append_array(_validate_flags(entry, world_states))
	for suit: Suit.Id in Suit.ALL:
		for rank: Rank.Id in Rank.ALL:
			if not grid.has("%d:%d" % [int(suit), int(rank)]):
				errors.append("no Blank carries the %s of %s" % [
					Rank.name_key(rank), Suit.name_key(suit)
				])
	for family: EnemyFamily.Id in [EnemyFamily.Id.BEAST, EnemyFamily.Id.FOG_MASK]:
		var count := int(family_counts.get(family, 0))
		if count != 1:
			errors.append("the catalog holds %d %s definitions, not one" % [
				count, EnemyFamily.name_key(family)
			])
	return errors


# --- Internals ----------------------------------------------------------------


## The two world-state flags §Other enemy families names, resolved against the matrix.
func _validate_flags(
	entry: EnemyDefinition, world_states: WorldStateCatalog
) -> PackedStringArray:
	var errors := PackedStringArray()
	if world_states == null:
		return errors
	for flag: StringName in [entry.calming_flag, entry.reveal_flag]:
		if flag == &"":
			continue
		if world_states.find(flag) == null:
			errors.append("%s names %s, which no world-state row defines" % [entry.id, flag])
	return errors


func _build_index() -> void:
	_index.clear()
	for entry: EnemyDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
