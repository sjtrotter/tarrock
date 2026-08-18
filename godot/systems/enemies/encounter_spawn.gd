class_name EncounterSpawn
extends Resource

## One enemy in an authored encounter: which one, and where it stands.
##
## A whole encounter is a handful of these on an `Encounter` node, which is what lets
## `docs/quests/main/MQ00-the-leap.md`'s "three figures rise from the long grass on
## either side of the path... one Cups, one Swords, one Wands" be authored in the
## scene rather than written in a script.
##
## `offset` is relative to the `Encounter` node, so the whole ambush can be dragged
## along the path in one move and the three keep their formation.

## The `EnemyIds` constant naming which enemy rises here.
@export var enemy_id: StringName = &""

## Where it stands, relative to the encounter's own position.
@export var offset: Vector2 = Vector2.ZERO

## Which way it faces when it rises, or `Vector2.ZERO` to face the Fool. Authored
## facing matters for an ambush: `docs/quests/main/MQ00-the-leap.md` has the three
## figures "advance without a word, because they have no mouths to say one with", and a
## Blank that spawns already looking the wrong way reads as asleep.
@export var facing: Vector2 = Vector2.ZERO


## Every problem with this spawn; empty means it can be placed.
func validate(catalog: EnemyCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id == &"":
		errors.append("an encounter spawn names no enemy")
		return errors
	if catalog != null and not catalog.has(enemy_id):
		errors.append("an encounter spawns %s, which the enemy catalog does not list" % enemy_id)
	return errors
