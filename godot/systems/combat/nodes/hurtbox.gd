class_name Hurtbox
extends Area2D

## The space a `Combatant` can be hit in.
##
## It is deliberately passive: it sits on `CombatLayers.HURTBOX_LAYER`, scans nothing,
## and answers two questions - whose it is, and which side it fights for. Hitboxes do
## the looking (see `CombatLayers` for why the traffic only runs one way).
##
## A hurtbox finds its Combatant by walking up its own ancestors, which is a node
## reading its own scene, not a system reaching into one: the rule in
## `docs/design/technical.md` is that SYSTEMS never `get_node` into scenes, and this
## is a component finding the thing it is part of. A hurtbox with no Combatant above
## it is an authoring mistake and says so once, loudly, rather than silently swallowing
## every hit aimed at it.

## The side this body fights for. Kept next to the Combatant's own `faction` rather
## than read off it, so a hurtbox can be authored and tested with no Combatant at all
## (`configure()` is what keeps the two honest at runtime).
@export var faction: Faction.Id = Faction.Id.BLANK

var _combatant: Combatant = null


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = CombatLayers.HURTBOX_MASK
	collision_mask = CombatLayers.NONE
	if _combatant == null:
		_combatant = _find_combatant()
	if _combatant == null:
		push_error("%s has no Combatant above it and can never be hurt" % name)
		return
	faction = _combatant.faction


## Point this hurtbox at its Combatant explicitly. Used when a component is built in
## code rather than authored in a scene.
func configure(combatant: Combatant) -> void:
	_combatant = combatant
	if combatant != null:
		faction = combatant.faction


## Whose hurtbox this is. `null` only when authoring went wrong.
func combatant() -> Combatant:
	return _combatant


## True when this hurtbox is worth hitting at all: it has a Combatant and that
## Combatant still has health. A body already at zero is not hit twice.
func is_vulnerable() -> bool:
	return _combatant != null and is_instance_valid(_combatant) and _combatant.is_alive()


## The nearest `Combatant` above this node, or `null`.
func _find_combatant() -> Combatant:
	var node := get_parent()
	while node != null:
		var found := node as Combatant
		if found != null:
			return found
		node = node.get_parent()
	return null
