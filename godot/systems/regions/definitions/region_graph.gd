class_name RegionGraph
extends Resource

## Who touches whom in the Spread: the whole adjacency of the world, in one
## hand-authored resource.
##
## HAND-AUTHORED at `res://data/regions/region_graph.tres` from
## `docs/design/world.md` §Layout (adjacency) and §Hard and soft gates.
##
## **Why this is not generated.** Everything else about a region comes off a doc
## table and is generated (`RegionDefinition`). §Layout is an ASCII picture of a wheel
## with a ring inside it, and a picture does not say which neighbours touch: any
## parser that turned it into a graph would be inventing canon at generation time.
## So the edges are authored by a person, each one carrying a `notes` line saying
## which sentence of §Layout it was read from, and a reviewer checks the set against
## the diagram. `doc_ref` and `notes` here carry the readings that had to be made
## where the diagram is silent.
##
## The graph is the ONLY place adjacency lives. `RegionDefinition` deliberately holds
## no neighbour list, so a region and the graph cannot disagree.

## The answer `edges_of()` gives for a region nothing joins. A constant, so it is
## read-only for the same reason the index's own arrays are, and shared, so the empty
## case allocates nothing.
const NO_EDGES: Array[RegionEdge] = []

## The doc section this graph was authored from.
@export var doc_ref: String = ""

## The readings the author made where §Layout is a picture rather than a sentence.
## Doc text for the reviewer; never displayed, never logic.
@export var notes: String = ""

## The region the Longroad's ring-causeway is (`world.md` §Layout: "a grand circular
## causeway around the Axis"). Named here rather than typed into `validate()`, so the
## ring rule reads as data.
@export var ring_region_id: StringName = &"LONGROAD"

## The Cliff: outside the Spread, and the one region whose only way out is a leap.
@export var cliff_region_id: StringName = &"CLIFF"

## Waystations that exist, may be rested at, and are still not fast-travel
## destinations.
##
## `world.md` §Layout: "The **Cliff** touches nothing: its only exit is the one-way
## leap to the Prestige crossroads (MQ00), and it is outside the Waystation network -
## no fast travel returns there", which `progression.md` §Waystations states from the
## other end ("the Cliff's Waystation is outside the network"). It is a fact about the
## MAP, so it lives on the map: a `RegionDefinition` says nothing about the network,
## and `RegionService` reads this list rather than naming the Cliff in code.
##
## Resting there is untouched - the Cliff's shrine is still where MQ00's first rest
## happens and still where a defeat on the plateau wakes the Fool. Only the fast-travel
## network leaves it out, which is what makes the leap final.
@export var fast_travel_network_excludes: Array[StringName] = []

## Every way from anywhere to anywhere.
@export var edges: Array[RegionEdge] = []

## Lazily built `region id -> Array[RegionEdge]`. The graph is authored data and
## immutable at runtime, so the index is built once, made read-only, and never
## invalidated.
var _index: Dictionary = {}


## Every edge that touches this region.
##
## The array is the index's own and is READ-ONLY: adjacency is authored data
## (`docs/design/technical.md`: definitions are immutable at runtime), so a caller that
## tried to add a road here would be inventing canon at runtime. Handing back the
## internal array rather than a copy keeps this allocation-free for the callers that
## only ever walk it.
func edges_of(region_id: StringName) -> Array[RegionEdge]:
	if _index.is_empty():
		_build_index()
	var found: Variant = _index.get(region_id)
	if found is Array:
		return found
	return NO_EDGES


## True when this Waystation is one fast travel may arrive at (see
## `fast_travel_network_excludes`). Says nothing about resting there.
func in_fast_travel_network(waystation_id: StringName) -> bool:
	return not fast_travel_network_excludes.has(waystation_id)


## The edge that would carry the Fool from `from` to `to`, or `null` when none does.
##
## A `LEAP` only answers in its own direction, which is what makes the Cliff a
## one-way door (`world.md` §The Cliff).
func edge_between(from: StringName, to: StringName) -> RegionEdge:
	for edge: RegionEdge in edges_of(from):
		if edge != null and edge.connects(from, to):
			return edge
	return null


## True when the Fool could walk from `from` to `to` in one move, gates aside.
func is_adjacent(from: StringName, to: StringName) -> bool:
	return edge_between(from, to) != null


## Every region one move from this one, in authored order.
func neighbours_of(region_id: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for edge: RegionEdge in edges_of(region_id):
		if edge == null or not edge.connects(region_id, edge.other_end(region_id)):
			continue
		found.append(edge.other_end(region_id))
	return found


## Every region that sits ON the ring: the causeway itself and the two towns built on
## it (`world.md` §Layout: "Wheelhouse and Veil sit ON the Longroad ring, NE and SW
## respectively").
func ring_regions() -> Array[StringName]:
	var found: Array[StringName] = [ring_region_id]
	for edge: RegionEdge in edges:
		if edge == null or edge.kind != RegionEdge.Kind.LONGROAD_RING:
			continue
		for end: StringName in [edge.a, edge.b]:
			if end != ring_region_id and not found.has(end):
				found.append(end)
	return found


## Every problem with the ring, one string per problem.
##
## **This is not a closure test, and there is no `ring_is_closed()`.** The Longroad is
## a single region - the whole causeway - so the circle §Layout draws is ONE node here,
## and "you can walk the ring all the way round" is not a statement this graph can be
## asked: any check over `LONGROAD_RING` edges would only be re-reading that one node.
## What the causeway can be held to is what §Layout actually says about it -
## "Wheelhouse and Veil sit ON the Longroad ring" - so that is what this checks: both
## towns are on it, and every ring edge really touches it.
##
## The closed circle the diagram draws is the WHEEL'S RIM, which is a genuine cycle of
## fifteen road edges, and it is proved against the doc's own clockwise sequence in
## `res://tests/unit/regions/region_graph_test.gd` - the one place the doc's sentence
## is written down. The day the Longroad is split into arcs (its Waystation network
## already names four: N/E/S/W), a real cycle test belongs here too.
func ring_problems() -> PackedStringArray:
	var errors := PackedStringArray()
	var residents := ring_regions()
	if residents.size() < 2:
		errors.append("the Longroad ring carries no towns; §Layout puts two on it")
	for edge: RegionEdge in edges:
		if edge == null or edge.kind != RegionEdge.Kind.LONGROAD_RING:
			continue
		if not edge.touches(ring_region_id):
			errors.append("the %s -> %s ring edge is not on the %s" % [
				edge.a, edge.b, ring_region_id
			])
	var reached := _reachable_over(residents, [RegionEdge.Kind.LONGROAD_RING])
	for resident: StringName in residents:
		if not reached.has(resident):
			errors.append("%s sits on the ring but the causeway does not reach it" % resident)
	return errors


## Every problem with the graph, one string per problem; empty means valid.
##
## `catalog` resolves every id: an edge to a region the Spread does not have is the
## failure this check exists for. `world_states` and `trumps`, when supplied, resolve
## the gate data - a gate on a flag the matrix never defines would be a door that
## never opens, and nothing else in the game would notice.
func validate(
	catalog: RegionCatalog = null,
	world_states: WorldStateCatalog = null,
	trumps: TrumpCatalog = null
) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in edges.size():
		var edge := edges[index]
		if edge == null:
			errors.append("region graph edge %d is empty" % index)
			continue
		errors.append_array(edge.validate())
		var key := _pair_key(edge.a, edge.b)
		if seen.has(key):
			errors.append("%s and %s are joined twice" % [edge.a, edge.b])
		seen[key] = true
		if catalog != null:
			for end: StringName in [edge.a, edge.b]:
				if end != &"" and not catalog.has(end):
					errors.append("the graph names %s, which is no region" % end)
		errors.append_array(_validate_gate(edge, world_states, trumps))
	errors.append_array(ring_problems())
	errors.append_array(_validate_the_cliff())
	if catalog != null:
		errors.append_array(_validate_reaches_everywhere(catalog))
		errors.append_array(_validate_the_network(catalog))
	return errors


# --- Internals ----------------------------------------------------------------


## The Cliff's edges: exactly one, the leap, and it goes out and never back.
##
## `world.md` §The Cliff: the plateau is "sealed from the Spread by sheer drop on
## every side... the sanctioned exit is the leap of faith. An unscripted fall from any
## other edge is just a defeat". A second edge here would be a road off the tutorial
## island, and the game's opening image would stop being a leap.
func _validate_the_cliff() -> PackedStringArray:
	var errors := PackedStringArray()
	var found := edges_of(cliff_region_id)
	if found.size() != 1:
		errors.append("the Cliff has %d ways off it; §The Cliff gives it one, the leap" % found.size())
		return errors
	var edge := found[0]
	if edge.kind != RegionEdge.Kind.LEAP:
		errors.append("the Cliff's one way off it is not the leap")
	if edge.a != cliff_region_id:
		errors.append("the leap runs towards the Cliff; nobody leaps back up")
	if edge.is_gated():
		errors.append("the leap of faith is not gated; MQ00 is the whole gate")
	return errors


## The Waystations held out of the fast-travel network, resolved against the catalog.
##
## A typo here would be a shrine nobody excluded and a Cliff the Fool could fly back
## to, which is exactly the sort of silence this whole file exists to make loud.
func _validate_the_network(catalog: RegionCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	for waystation_id: StringName in fast_travel_network_excludes:
		if catalog.find_by_waystation(waystation_id) == null:
			errors.append("the network excludes %s, which is no Waystation" % waystation_id)
	return errors


## Every gate flag and Trump the edges name, resolved against the catalogs.
func _validate_gate(
	edge: RegionEdge, world_states: WorldStateCatalog, trumps: TrumpCatalog
) -> PackedStringArray:
	var errors := PackedStringArray()
	if world_states != null:
		var flags: Array[StringName] = []
		flags.append_array(edge.requires_fired)
		flags.append_array(edge.requires_any_fired)
		for flag: StringName in flags:
			if world_states.find(flag) == null:
				errors.append("the %s -> %s gate names %s, which no world-state row defines" % [
					edge.a, edge.b, flag
				])
	if trumps != null:
		for trump_id: StringName in edge.requires_any_trump_held:
			if trumps.find(trump_id) == null:
				errors.append("the %s -> %s gate names %s, which is no Trump" % [
					edge.a, edge.b, trump_id
				])
	return errors


## Every region the Cliff cannot reach, gates ignored.
##
## Gates are ignored on purpose: a gate is a thing the player opens, and a region that
## is only reachable once Death is unbound is still reachable. A region NOTHING
## reaches is an island nobody can ever stand on, and that is an authoring bug.
func _validate_reaches_everywhere(catalog: RegionCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	var reached := _reachable_over([cliff_region_id], [])
	for region_id: StringName in catalog.ids():
		if not reached.has(region_id):
			errors.append("nothing reaches %s from the Cliff" % region_id)
	return errors


## Every region reachable from `starts`, following only the given edge kinds (an
## empty `kinds` follows every kind). Directed: a `LEAP` is walked one way only.
func _reachable_over(starts: Array[StringName], kinds: Array) -> Dictionary:
	var reached: Dictionary = {}
	var frontier: Array[StringName] = []
	for start: StringName in starts:
		if not reached.has(start):
			reached[start] = true
			frontier.append(start)
	while not frontier.is_empty():
		var region_id: StringName = frontier.pop_back()
		for edge: RegionEdge in edges_of(region_id):
			if edge == null:
				continue
			if not kinds.is_empty() and not kinds.has(edge.kind):
				continue
			var other := edge.other_end(region_id)
			if other == &"" or not edge.connects(region_id, other):
				continue
			if reached.has(other):
				continue
			reached[other] = true
			frontier.append(other)
	return reached


## One key per unordered pair, so a duplicated edge is caught whichever way it was
## written down.
func _pair_key(a: StringName, b: StringName) -> String:
	if String(a) <= String(b):
		return "%s|%s" % [a, b]
	return "%s|%s" % [b, a]


func _build_index() -> void:
	_index.clear()
	for edge: RegionEdge in edges:
		if edge == null:
			continue
		for end: StringName in [edge.a, edge.b]:
			if end == &"":
				continue
			if not _index.has(end):
				var fresh: Array[RegionEdge] = []
				_index[end] = fresh
			var bucket: Array[RegionEdge] = _index[end]
			if not bucket.has(edge):
				bucket.append(edge)
	# Sealed once, at the end, because `edges_of()` hands these out: authored adjacency
	# is immutable at runtime, and a caller that appended a road here would be inventing
	# canon in the middle of a playthrough.
	for bucket: Array in _index.values():
		bucket.make_read_only()
