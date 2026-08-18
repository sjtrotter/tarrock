class_name RegionEdge
extends Resource

## One way of getting from one region of the Spread to another, and what it costs to
## be allowed through.
##
## HAND-AUTHORED, in `res://data/regions/region_graph.tres`, from
## `docs/design/world.md` §Layout (adjacency) - the ASCII wheel - and §Hard and soft
## gates. It is not generated, and cannot be: a diagram is a picture, and turning a
## picture into a graph is a reading. `RegionGraph`'s `notes` records the readings
## that were made, so a reviewer can check them against the diagram.
##
## An edge is **undirected** except for `Kind.LEAP`, which runs `a` -> `b` only:
## `world.md` §The Cliff - the plateau is "sealed from the Spread by sheer drop on
## every side... the sanctioned exit is the leap of faith", and nobody leaps back up.
##
## A **gate is data on the edge**, never a branch in code, so `world.md`'s hard-gate
## table can be checked against this file row by row. `gates_entry_to` is what makes
## a gate a door rather than a wall: the Mirrormarsh's fog stops the Fool getting IN
## without a true light, and getting lost back OUT is the thing the fog does for a
## living.

## How this edge is travelled. The kind is documentation and map-drawing material -
## `RegionService` refuses or allows on the gate fields, never on the kind - except
## for `LEAP`, which is the one kind that is one-way.
enum Kind {
	## An overland road between two regions that touch on the wheel.
	ROAD,
	## A stretch of the Longroad itself - the great ring-causeway (`world.md` §Layout).
	LONGROAD_RING,
	## A way underground: the Undervault "is underground, entered from the western
	## regions; the only region with no sky" (`world.md` §Layout).
	UNDERGROUND,
	## The leap of faith off the Cliff. One-way, `a` -> `b`, and the only way off the
	## plateau that is not a defeat (`world.md` §The Cliff, `combat.md` §Defeat).
	LEAP,
}

## One end of the edge. For a `LEAP`, the end it is travelled FROM.
@export var a: StringName = &""

## The other end. For a `LEAP`, the end it is travelled TO.
@export var b: StringName = &""

## What kind of way this is.
@export var kind: Kind = Kind.ROAD

## `WS_*` flags that must ALL have fired before this edge may be used.
## `world.md` §Hard and soft gates: the Hollows needs Death unbound.
@export var requires_fired: Array[StringName] = []

## `WS_*` flags of which ANY ONE is enough. Satisfied together with
## `requires_any_trump_held` - the two lists are one "or".
@export var requires_any_fired: Array[StringName] = []

## Trump ids of which ANY ONE, held in the Pocket Spread, is enough.
## `world.md` §Hard and soft gates: the Mirrormarsh honors "any true light: Hermit's
## Lantern, Star's Wish, or the Sun unbound".
@export var requires_any_trump_held: Array[StringName] = []

## Which end this edge's gate protects, or `&""` when it bars both directions.
## The Hollows' gate and the Mirrormarsh's both name the region being ENTERED: a
## place that is hard to get into is not thereby hard to leave.
@export var gates_entry_to: StringName = &""

## Why this edge is here, in one line, for the reviewer checking it against §Layout.
## Doc text; never displayed.
@export var notes: String = ""


## True when this edge joins these two regions in the direction `from` -> `to`.
func connects(from: StringName, to: StringName) -> bool:
	if a == from and b == to:
		return true
	if kind == Kind.LEAP:
		return false
	return a == to and b == from


## True when either end is this region.
func touches(region_id: StringName) -> bool:
	return a == region_id or b == region_id


## The other end of this edge, or `&""` when it does not touch `region_id`.
func other_end(region_id: StringName) -> StringName:
	if a == region_id:
		return b
	if b == region_id:
		return a
	return &""


## True when this edge asks for anything at all before it may be used.
func is_gated() -> bool:
	return (
		not requires_fired.is_empty()
		or not requires_any_fired.is_empty()
		or not requires_any_trump_held.is_empty()
	)


## True when this edge's gate applies to a crossing that ends at `to`.
##
## A gate with no `gates_entry_to` applies in both directions; one that names an end
## applies only to arriving there.
func gate_applies_to(to: StringName) -> bool:
	if not is_gated():
		return false
	return gates_entry_to == &"" or gates_entry_to == to


## True when the gate on this edge is open for a crossing that ends at `to`.
##
## The rule, spelled once: every `requires_fired` flag must have fired, AND - when
## either "any" list holds anything - at least one of the two must be satisfied. The
## two "any" lists are deliberately ONE choice between them, because `world.md`'s own
## sentence is one: "any true light: Hermit's Lantern, Star's Wish, or the Sun
## unbound" mixes two Trumps and a flag in a single or.
func is_open(
	to: StringName, world_state: WorldStateService, spread: PocketSpreadService
) -> bool:
	if not gate_applies_to(to):
		return true
	for flag: StringName in requires_fired:
		if world_state == null or not world_state.is_fired(flag):
			return false
	if requires_any_fired.is_empty() and requires_any_trump_held.is_empty():
		return true
	for flag: StringName in requires_any_fired:
		if world_state != null and world_state.is_fired(flag):
			return true
	for trump_id: StringName in requires_any_trump_held:
		if spread != null and spread.is_held(trump_id):
			return true
	return false


## Every problem with this edge, one string per problem.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if a == &"" or b == &"":
		errors.append("a region edge is missing an end (%s -> %s)" % [a, b])
	elif a == b:
		errors.append("%s cannot be adjacent to itself" % a)
	if gates_entry_to != &"" and gates_entry_to != a and gates_entry_to != b:
		errors.append("the %s -> %s gate protects %s, which is not on it" % [
			a, b, gates_entry_to
		])
	if not is_gated() and gates_entry_to != &"":
		errors.append("the %s -> %s edge names a gated end but has no gate" % [a, b])
	if notes == "":
		errors.append("the %s -> %s edge does not say what §Layout it was read from" % [a, b])
	return errors
