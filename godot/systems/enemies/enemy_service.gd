class_name EnemyService
extends RefCounted

## What the game knows about its enemies: the catalog, the tuning table, who is
## standing right now, and the two things that happen when one goes down.
##
## It is deliberately small. `CombatService` already owns what a FIGHT is (who is
## engaged, the slow-motion, the Fortune, the defeat loop) and this does not
## duplicate a word of it: an enemy announces itself to `CombatService` through its
## own `Blank`, and this service is the ROSTER - the place a quest, a bark or a
## Renown rule asks "what just fell, and what was it" - never "what just died", because
## `combat.md` §Enemies is emphatic that a Blank does not die.
##
## Two signals earn it a place in the composition root rather than being a loose
## catalog:
##
##   * `enemy_defeated` - what a later round hangs a quest event, a Renown adjustment
##     or a Querent bark on. Nothing listens yet, and it is here rather than invented
##     later so the listeners have one door.
##   * `card_fluttered` - `docs/design/combat.md` §Enemies: "A defeated Blank slumps
##     and fades while the card it bore flutters free - drifting off to raise a new
##     bearer elsewhere later... presented as a visible, storybook-melancholy effect".
##     MQ00 stages that: "Past the ridge line, each drifting card settles onto a new
##     blank-faced figure rising from the grass". Nothing plays it yet - the effect
##     belongs to the art and UI rounds - but the event it will play on is real, and
##     it carries the suit and the rank of the card that went, because the figure that
##     rises is meant to be bearing THAT card.
##
## `WS_DEATH_UNBOUND` is not read here. After it fires, Death's Trump "grants the
## means to end the *card itself*", and `combat.md` puts the mechanical detail of that
## Trump in `arcana.md` - so it is the Trump's rule and not this service's, and
## writing a guess here would be inventing Arcana canon.

## An enemy's pool emptied. `enemy_id` is its definition's id, so a listener never
## holds a node.
signal enemy_defeated(enemy_id: StringName, at_position: Vector2)

## The card that Blank bore is free and drifting. `suit` and `rank` are `Suit.Id` and
## `Rank.Id`; both are -1 for a family that has neither.
signal card_fluttered(suit: int, rank: int, from_position: Vector2)

var _catalog: EnemyCatalog = null
var _rules: EnemyRules = null

## Every enemy standing in the world right now. Appended to and erased from; never
## replaced, so the array itself is stable for anything holding it.
var _live: Array[Blank] = []

## Every enemy definition the Fool has actually MET, by id - what the Almanack's
## Bestiary lists (`docs/design/art-audio.md` §Map, the Almanack, and UI: the Almanack
## collects "the Bestiary of Blanks and beasts encountered"). Append-only: a card seen
## once is known, and nothing here un-knows it.
##
## **It is not in the save file yet.** Persisting it is a `bestiary` section, which is
## `SaveService`'s shape to change and not the UI round's; `to_snapshot()` /
## `restore_snapshot()` below are the pair that round wires up, and until it does the
## Bestiary remembers a session. Listed as owed in `res://systems/ui/README.md`.
var _seen: Dictionary = {}


## Build the service over the generated catalog and the hand-authored tuning table.
func _init(catalog: EnemyCatalog, rules: EnemyRules) -> void:
	_catalog = catalog
	_rules = rules
	if catalog == null:
		push_error("EnemyService was built without a catalog")
	if rules == null:
		push_error("EnemyService was built without its rules")


## The generated catalog: every suit x rank, plus the two family stubs.
func catalog() -> EnemyCatalog:
	return _catalog


## The one tuning table every enemy number comes out of.
func rules() -> EnemyRules:
	return _rules


## The definition with this id, or `null`. The only way anything gets one: no caller
## loads a `.tres` by path.
func definition(enemy_id: StringName) -> EnemyDefinition:
	if _catalog == null:
		return null
	return _catalog.find(enemy_id)


## The Blank of this suit and rank, or `null`.
func blank(suit: Suit.Id, rank: Rank.Id) -> EnemyDefinition:
	if _catalog == null:
		return null
	return _catalog.find_blank(suit, rank)


## The solved numbers for one enemy, or `null` when the catalog does not list it.
func stats(enemy_id: StringName) -> EnemyStats:
	var found := definition(enemy_id)
	return null if found == null else found.stats(_rules)


## A Beast's stance rule, built over the world state. The calming flag comes off the
## definition, which was generated from the doc.
func beast_brain(world_state: WorldStateService) -> BeastBrain:
	var found := definition(EnemyFamily.name_key(EnemyFamily.Id.BEAST))
	return BeastBrain.new(world_state, &"" if found == null else found.calming_flag)


## A Fog-mask's reveal rule, built the same way.
func fog_mask_brain(world_state: WorldStateService) -> FogMaskBrain:
	var found := definition(EnemyFamily.name_key(EnemyFamily.Id.FOG_MASK))
	return FogMaskBrain.new(world_state, &"" if found == null else found.reveal_flag)


# --- The roster -------------------------------------------------------------------


## An enemy is standing in the world. Idempotent.
##
## Standing in front of the Fool is what counts as met, so this is also where the
## Bestiary learns a card.
func register(enemy: Blank) -> void:
	if enemy == null or not is_instance_valid(enemy) or _live.has(enemy):
		return
	_live.append(enemy)
	var found := enemy.definition()
	if found != null:
		mark_seen(found.id)


## It is not any more - defeated, despawned, or the scene it stood in went away.
func unregister(enemy: Blank) -> void:
	var index := _live.find(enemy)
	if index >= 0:
		_live.remove_at(index)


## How many enemies are standing and still have health.
func alive_count() -> int:
	var count := 0
	for enemy: Blank in _live:
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive():
			count += 1
	return count


## How many enemies are in the world at all, alive or slumping.
func live_count() -> int:
	return _live.size()


## The enemies in the world. The service's own array, handed out read-only by
## convention.
func live_enemies() -> Array[Blank]:
	return _live


## Everybody goes home. Used when a scene unloads.
func clear() -> void:
	_live.clear()


# --- What an encounter reports ----------------------------------------------------


## One enemy's pool emptied. Called by whoever owns the fight, never by the enemy.
func report_defeat(enemy: Blank) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var found := enemy.definition()
	if found == null:
		return
	enemy_defeated.emit(found.id, enemy.global_position)


## The card it bore has fluttered free. See the class doc for what this is for.
func report_card_fluttered(found: EnemyDefinition, from_position: Vector2) -> void:
	if found == null:
		return
	card_fluttered.emit(found.suit, found.rank, from_position)


# --- What the Fool has met --------------------------------------------------------


## Remember that this definition has been met. True the first time only.
func mark_seen(enemy_id: StringName) -> bool:
	if enemy_id == &"" or _seen.has(enemy_id):
		return false
	if _catalog != null and not _catalog.has(enemy_id):
		return false
	_seen[enemy_id] = true
	return true


## True when the Fool has met this one.
func has_seen(enemy_id: StringName) -> bool:
	return _seen.has(enemy_id)


## Every definition met, in catalog order so the Bestiary reads as a deck rather than
## as an encounter log.
func seen_definitions() -> Array[EnemyDefinition]:
	var found: Array[EnemyDefinition] = []
	if _catalog == null:
		return found
	for entry: EnemyDefinition in _catalog.entries:
		if entry != null and _seen.has(entry.id):
			found.append(entry)
	return found


## How many definitions have been met.
func seen_count() -> int:
	return _seen.size()


## The Bestiary, for a save file: the ids met, sorted so the file is stable.
func to_snapshot() -> Array[StringName]:
	var ids: Array[StringName] = []
	for enemy_id: StringName in _seen:
		ids.append(enemy_id)
	ids.sort()
	return ids


## Put a saved Bestiary back. Every problem is returned; ids the catalog does not
## know are reported and skipped rather than trusted.
func restore_snapshot(ids: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	_seen.clear()
	for entry: Variant in ids:
		var enemy_id := StringName(entry)
		if _catalog != null and not _catalog.has(enemy_id):
			errors.append("the bestiary names %s, which is no enemy" % enemy_id)
			continue
		_seen[enemy_id] = true
	return errors
