extends TarrockTest

## The hand-authored adjacency, against `docs/design/world.md` §Layout.
##
## `RegionGraph` is the one file in the project that is a READING of a doc rather than
## a transcription of one - §Layout is an ASCII wheel, and a picture has to be
## interpreted. So this suite does two different jobs, and they are worth telling
## apart:
##
##   * **Structure**, which is mechanical: every id is a region, nothing is joined
##     twice, the causeway carries its towns, every gate flag exists, nothing is
##     unreachable, and nothing hands out an edge list a caller could edit.
##   * **The whole adjacency table**, which is §Layout's "Adjacency, read from the
##     diagram" paragraph written down as data - the clockwise rim and its closure, the
##     spokes, the two towns on the causeway, the three descents, the inner edges and
##     their gates, and the Cliff's one-way leap - ending with the assertion that the
##     graph holds no edge that paragraph did not put there.
##   * **The readings**, which are canon: the Cliff has exactly one way off it and it
##     is the leap; the Longroad touches every region on the wheel; the Axis is
##     reachable without the Death-gated Hollows. Each of those is a sentence of the
##     doc, quoted where it is asserted, and each is the sort of thing a well-meaning
##     edit could quietly break.

const CATALOG_PATH := "res://data/regions/catalog.tres"
const GRAPH_PATH := "res://data/regions/region_graph.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## The doc sentence every assertion below answers to.
const RIM_DOC_REF := "docs/design/world.md §Layout, \"Adjacency, read from the diagram\""

## The wheel's rim, clockwise from the north, transcribed from that sentence:
##
##   "Clockwise around the rim from the north: Bastion - Assize - Noonlands - Prestige
##   - Bower - Divide - Chantry - Maw - Confluence - Stillmarsh - Mere - Mirrormarsh -
##   Gallowwood - Dim - Spire - (Bastion)."
##
## The doc's own bracketed return to the Bastion is the closure, so it is left off the
## list and asserted as the wrap instead: fifteen regions, fifteen edges, one circle.
const RIM: Array[StringName] = [
	RegionIds.BASTION,
	RegionIds.ASSIZE,
	RegionIds.NOONLANDS,
	RegionIds.PRESTIGE,
	RegionIds.BOWER,
	RegionIds.DIVIDE,
	RegionIds.CHANTRY,
	RegionIds.MAW,
	RegionIds.CONFLUENCE,
	RegionIds.STILLMARSH,
	RegionIds.MERE,
	RegionIds.MIRRORMARSH,
	RegionIds.GALLOWWOOD,
	RegionIds.DIM,
	RegionIds.SPIRE,
]

## The two towns built ON the causeway: "Wheelhouse and Veil sit ON the Longroad ring,
## NE and SW respectively".
const RING_TOWNS: Array[StringName] = [RegionIds.WHEELHOUSE, RegionIds.VEIL]

## "The Undervault is off the surface rim: three descents, from the Mirrormarsh, the
## Gallowwood, and the Dim."
const DESCENTS: Array[StringName] = [
	RegionIds.MIRRORMARSH, RegionIds.GALLOWWOOD, RegionIds.DIM
]

## How many edges the table above adds up to: 15 rim + 15 spokes + 2 causeway towns
## + 3 descents + 3 inner (Longroad-Hollows, Hollows-Axis, Longroad-Axis) + 1 leap.
const TABLE_SIZE := 39

var _catalog: RegionCatalog = null
var _graph: RegionGraph = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as RegionCatalog
	_graph = load(GRAPH_PATH) as RegionGraph


# --- Structure --------------------------------------------------------------------


func test_the_graph_loads_and_validates() -> void:
	if not assert_not_null(_graph, "%s loads" % GRAPH_PATH):
		return
	var world_states := load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	var trumps := load(TRUMP_CATALOG_PATH) as TrumpCatalog
	assert_eq(
		_graph.validate(_catalog, world_states, trumps),
		PackedStringArray(),
		"every id is a region, every gate names something real, nothing is stranded"
	)


func test_every_edge_says_where_it_was_read_from() -> void:
	if not assert_not_null(_graph):
		return
	# The whole reason a human can review this file: an edge with no note is an edge
	# somebody added without saying which sentence of §Layout put it there.
	for edge: RegionEdge in _graph.edges:
		assert_ne(edge.notes, "", "the %s - %s edge cites the doc" % [edge.a, edge.b])


func test_adjacency_is_symmetrical_except_the_leap() -> void:
	if not assert_not_null(_graph):
		return
	for edge: RegionEdge in _graph.edges:
		assert_true(_graph.is_adjacent(edge.a, edge.b), "%s reaches %s" % [edge.a, edge.b])
		if edge.kind == RegionEdge.Kind.LEAP:
			assert_false(
				_graph.is_adjacent(edge.b, edge.a), "nobody leaps back up onto the Cliff"
			)
		else:
			assert_true(_graph.is_adjacent(edge.b, edge.a), "%s reaches %s" % [edge.b, edge.a])


func test_the_causeway_carries_both_its_towns() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §Layout: "Wheelhouse and Veil sit ON the Longroad ring, NE and SW
	# respectively" - so the causeway carries both towns and reaches both of them. It
	# is NOT the closure test: the Longroad is one region, so the circle the diagram
	# draws is one node here, and the closed circle is the RIM (below).
	assert_eq(_graph.ring_problems(), PackedStringArray())
	var residents := _graph.ring_regions()
	assert_has(residents, RegionIds.LONGROAD)
	for town: StringName in RING_TOWNS:
		assert_has(residents, town)


func test_the_edges_handed_out_cannot_be_edited() -> void:
	if not assert_not_null(_graph):
		return
	# Authored adjacency is immutable at runtime (`technical.md`: definitions are
	# authored data), and `edges_of()` hands out the index's own array - so the array
	# it hands out is sealed. A caller that could append here would be laying a road
	# in the middle of a playthrough.
	assert_true(_graph.edges_of(RegionIds.PRESTIGE).is_read_only(), "a region's edges")
	assert_true(_graph.edges_of(&"NOWHERE").is_read_only(), "and the empty answer too")


# --- The whole adjacency table ------------------------------------------------------
#
# `world.md` §Layout's "Adjacency, read from the diagram (the SSOT for which regions
# touch; the picture above stays the picture)" is a paragraph of prose, and this is
# where it is written down as data the graph can be held to. Every assertion below
# quotes the sentence it answers to; between them they cover the whole paragraph, and
# the last one proves the graph holds nothing the paragraph did not put there.


func test_the_rim_is_the_doc_s_clockwise_wheel() -> void:
	if not assert_not_null(_graph):
		return
	# "Clockwise around the rim from the north: Bastion - Assize - ... - Spire -
	# (Bastion). Regions touch by *road* unless marked."
	assert_eq(RIM.size(), 15, "%s names fifteen regions on the rim" % RIM_DOC_REF)
	for index: int in RIM.size():
		# The wrap is the doc's own "(Bastion)": walking the last one on lands back at
		# the first, which is what makes the rim a wheel and not a line of towns.
		var here := RIM[index]
		var next := RIM[(index + 1) % RIM.size()]
		var edge := _graph.edge_between(here, next)
		if not assert_not_null(edge, "%s - %s is a road on the rim" % [here, next]):
			continue
		assert_eq(edge.kind, RegionEdge.Kind.ROAD, "%s - %s is a road" % [here, next])
		assert_true(_graph.is_adjacent(next, here), "and it is walked both ways")


func test_the_rim_closes_and_no_region_has_a_sixteenth_neighbour() -> void:
	if not assert_not_null(_graph):
		return
	# The other half of "clockwise around the rim": a region with three rim neighbours
	# would be a shortcut across the wheel that the doc's sequence does not draw, and
	# the sequence would stop being the reading it claims to be.
	for region_id: StringName in RIM:
		var on_the_rim: Array[StringName] = []
		for neighbour: StringName in _graph.neighbours_of(region_id):
			if RIM.has(neighbour):
				on_the_rim.append(neighbour)
		assert_eq(
			on_the_rim.size(),
			2,
			"%s touches exactly two rim regions (%s)" % [region_id, on_the_rim]
		)
	# And the circle is one circle: following rim neighbours from the north comes home
	# having stood in every one of them, rather than in two separate loops.
	var walked: Array[StringName] = [RIM[0]]
	var previous := RIM[0]
	var current := RIM[1]
	while current != RIM[0] and walked.size() <= RIM.size():
		walked.append(current)
		var step := &""
		for neighbour: StringName in _graph.neighbours_of(current):
			if RIM.has(neighbour) and neighbour != previous:
				step = neighbour
		previous = current
		current = step
	assert_eq(walked.size(), RIM.size(), "the rim is one closed wheel, not two loops")
	assert_eq(current, RIM[0], "and it comes back to the Bastion in the north")


func test_every_rim_region_has_its_own_spoke_onto_the_longroad() -> void:
	if not assert_not_null(_graph):
		return
	# "Every rim region's main road also meets the **Longroad** (a spoke each)", which
	# §The Longroad states outright: "Every region's main road eventually meets it".
	var spokes := 0
	for region_id: StringName in RIM:
		var edge := _graph.edge_between(region_id, RegionIds.LONGROAD)
		if not assert_not_null(edge, "%s's road meets the ring" % region_id):
			continue
		assert_eq(edge.kind, RegionEdge.Kind.ROAD, "%s's spoke is a road" % region_id)
		spokes += 1
	assert_eq(spokes, RIM.size(), "a spoke each, and no more than one each")


func test_the_two_towns_on_the_causeway_are_reached_only_along_it() -> void:
	if not assert_not_null(_graph):
		return
	# "The **Wheelhouse** and the **Veil** sit *on* the causeway and are reached along
	# it (whether they also touch their nearest rim neighbours: **TBD**)." Until that
	# TBD is answered, the causeway is their only way in - and the day it is answered,
	# this is the assertion that has to be edited on purpose.
	for town: StringName in RING_TOWNS:
		assert_eq(
			_graph.neighbours_of(town),
			[RegionIds.LONGROAD] as Array[StringName],
			"%s is reached along the Longroad and nowhere else" % town
		)
		var edge := _graph.edge_between(town, RegionIds.LONGROAD)
		if edge != null:
			assert_eq(edge.kind, RegionEdge.Kind.LONGROAD_RING, "%s is ON the ring" % town)


func test_the_undervault_hangs_off_three_descents() -> void:
	if not assert_not_null(_graph):
		return
	# "The **Undervault** is off the surface rim: three descents, from the Mirrormarsh,
	# the Gallowwood, and the Dim." No spoke, no rim edge: it is underground.
	var neighbours := _graph.neighbours_of(RegionIds.UNDERVAULT)
	assert_eq(neighbours.size(), DESCENTS.size(), "three descents, no roads")
	for west: StringName in DESCENTS:
		assert_has(neighbours, west)
		var edge := _graph.edge_between(RegionIds.UNDERVAULT, west)
		if edge != null:
			assert_eq(edge.kind, RegionEdge.Kind.UNDERGROUND, "%s is a way down" % west)
	assert_false(
		_graph.is_adjacent(RegionIds.UNDERVAULT, RegionIds.LONGROAD),
		"and the region with no sky has no spoke onto the causeway"
	)


func test_the_inner_edges_are_the_three_the_doc_names() -> void:
	if not assert_not_null(_graph):
		return
	# "Inner: Longroad - Hollows (gated: Death unbound, per §Hard and soft gates),
	# Hollows - Axis, and an ungated road Longroad - Axis (the finale is always open)."
	var into_the_hollows := _graph.edge_between(RegionIds.LONGROAD, RegionIds.HOLLOWS)
	if assert_not_null(into_the_hollows, "the ring reaches the Hollows"):
		assert_has(into_the_hollows.requires_fired, WorldStateIds.WS_DEATH_UNBOUND)
		assert_eq(into_the_hollows.gates_entry_to, RegionIds.HOLLOWS)
	var approach := _graph.edge_between(RegionIds.HOLLOWS, RegionIds.AXIS)
	if assert_not_null(approach, "the terraces reach the Axis"):
		assert_false(approach.is_gated(), "the way on from the Hollows asks nothing more")
	var always_open := _graph.edge_between(RegionIds.LONGROAD, RegionIds.AXIS)
	if assert_not_null(always_open, "and the ring reaches the Axis directly"):
		assert_false(always_open.is_gated(), "the finale is always open")
	assert_eq(
		_graph.neighbours_of(RegionIds.HOLLOWS).size(), 2, "the Hollows lie between the two"
	)
	assert_eq(
		_graph.neighbours_of(RegionIds.AXIS).size(), 2, "and the Axis is reached those two ways"
	)


func test_the_cliff_touches_nothing_but_the_leap() -> void:
	if not assert_not_null(_graph):
		return
	# "The **Cliff** touches nothing: its only exit is the one-way leap to the Prestige
	# crossroads (MQ00), and it is outside the Waystation network - no fast travel
	# returns there."
	var edges := _graph.edges_of(RegionIds.CLIFF)
	assert_eq(edges.size(), 1, "one way off the plateau")
	assert_false(_graph.is_adjacent(RegionIds.PRESTIGE, RegionIds.CLIFF), "and none back")
	assert_false(
		_graph.in_fast_travel_network(RegionIds.WAYSTATION_CLIFF),
		"and no shrine in the network answers to the Cliff either"
	)


func test_the_table_holds_nothing_the_doc_did_not_write() -> void:
	if not assert_not_null(_graph):
		return
	# The assertion that makes the ones above a TABLE rather than a sample: every edge
	# in the file belongs to one of the six groups §Layout names, and the groups add up
	# to the file. An edge nobody wrote down would otherwise sit in the graph unread.
	assert_eq(_graph.edges.size(), TABLE_SIZE, "15 rim + 15 spokes + 2 + 3 + 3 + 1")
	for edge: RegionEdge in _graph.edges:
		assert_ne(
			_group_of(edge),
			"",
			"the %s - %s edge is one §Layout wrote down" % [edge.a, edge.b]
		)


# --- The readings -----------------------------------------------------------------


func test_the_cliffs_only_way_off_is_the_leap_to_the_prestige() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §The Cliff: the plateau is "sealed from the Spread by sheer drop on
	# every side... the sanctioned exit is the leap of faith. An unscripted fall from
	# any other edge is just a defeat". A road off the tutorial island would take the
	# game's opening image away.
	var edges := _graph.edges_of(RegionIds.CLIFF)
	assert_eq(edges.size(), 1, "one way off, and it is not a road")
	if edges.is_empty():
		return
	var leap := edges[0]
	assert_eq(leap.kind, RegionEdge.Kind.LEAP)
	assert_eq(leap.a, RegionIds.CLIFF)
	assert_eq(leap.b, RegionIds.PRESTIGE, "the intended first region")
	assert_false(leap.is_gated(), "MQ00 is the whole gate; the edge asks for nothing")


func test_every_regions_road_meets_the_longroad() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §The Longroad: "Every region's main road eventually meets it, which
	# makes it the game's traffic spine". Three regions are exempt and each is a
	# sentence of the doc: the Cliff is outside the Spread, the Undervault is
	# underground with no sky, and the Longroad cannot meet itself.
	var exempt: Array[StringName] = [
		RegionIds.CLIFF, RegionIds.UNDERVAULT, RegionIds.LONGROAD
	]
	for region_id: StringName in RegionIds.ALL:
		if exempt.has(region_id):
			continue
		assert_true(
			_graph.is_adjacent(region_id, RegionIds.LONGROAD),
			"%s's road meets the ring" % region_id
		)


func test_the_axis_is_reachable_without_the_hollows() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §Hard and soft gates: "The Axis inner sanctum | None - always open |
	# BotW rule: the finale is a right, not a reward." The Hollows ARE gated (Death
	# unbound), so if the terraces were the only approach the finale would inherit
	# that gate and the doc's promise would be broken by the map.
	var approach := _graph.edge_between(RegionIds.LONGROAD, RegionIds.AXIS)
	if not assert_not_null(approach, "the ring reaches the Axis"):
		return
	assert_false(approach.is_gated(), "and nothing is asked of the Fool to walk it")
	var through_the_hollows := _graph.edge_between(RegionIds.HOLLOWS, RegionIds.AXIS)
	assert_not_null(through_the_hollows, "the Hollows approach exists too")


func test_the_hollows_are_gated_on_death_unbound() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §Hard and soft gates: "The Hollows (MQ20) | Death unbound (MQ13) |
	# Judgement cannot call souls that cannot leave."
	var edge := _graph.edge_between(RegionIds.LONGROAD, RegionIds.HOLLOWS)
	if not assert_not_null(edge):
		return
	assert_has(edge.requires_fired, WorldStateIds.WS_DEATH_UNBOUND)
	assert_eq(edge.gates_entry_to, RegionIds.HOLLOWS, "the gate is a door, not a wall")
	assert_true(edge.gate_applies_to(RegionIds.HOLLOWS))
	assert_false(
		edge.gate_applies_to(RegionIds.LONGROAD),
		"a Fool already in the terraces is never sealed in"
	)


func test_the_mirrormarsh_wants_a_true_light() -> void:
	if not assert_not_null(_graph):
		return
	# `world.md` §Hard and soft gates: "The Mirrormarsh (interior) | Any true light:
	# Hermit's Lantern, Star's Wish, or the Sun unbound". `arcana.md`: "Lantern / Wish
	# / Daybreak: the three 'true lights' - Mirrormarsh honors any."
	var ways_in := 0
	for edge: RegionEdge in _graph.edges_of(RegionIds.MIRRORMARSH):
		ways_in += 1
		assert_eq(
			edge.gates_entry_to,
			RegionIds.MIRRORMARSH,
			"the fog stops the Fool getting in, not getting out"
		)
		assert_has(edge.requires_any_trump_held, TrumpIds.TRUMP_09)
		assert_has(edge.requires_any_trump_held, TrumpIds.TRUMP_17)
		assert_has(edge.requires_any_fired, WorldStateIds.WS_SUN_UNBOUND)
		assert_true(edge.requires_fired.is_empty(), "any one light is enough, not all")
	assert_true(ways_in > 0, "the Mirrormarsh is on the map at all")


func test_nothing_is_stranded() -> void:
	if not assert_not_null(_graph) or not assert_not_null(_catalog):
		return
	# Gates ignored: a region only reachable once Death is unbound is still reachable.
	# A region NOTHING reaches is a place nobody can ever stand in.
	for region_id: StringName in RegionIds.ALL:
		if region_id == RegionIds.CLIFF:
			continue
		assert_false(
			_graph.edges_of(region_id).is_empty(), "%s is joined to the world" % region_id
		)


# --- The gate rule itself ---------------------------------------------------------


func test_an_open_gate_needs_all_of_the_musts_and_one_of_the_anys() -> void:
	# The rule spelled in `RegionEdge.is_open()`, tested on a synthetic edge so the
	# authored data cannot make it accidentally pass.
	var world_state := _world_state()
	var edge := RegionEdge.new()
	edge.a = RegionIds.LONGROAD
	edge.b = RegionIds.HOLLOWS
	edge.gates_entry_to = RegionIds.HOLLOWS
	edge.requires_fired = [WorldStateIds.WS_DEATH_UNBOUND]
	edge.requires_any_fired = [WorldStateIds.WS_SUN_UNBOUND]
	assert_false(edge.is_open(RegionIds.HOLLOWS, world_state, null), "neither has fired")
	assert_true(
		edge.is_open(RegionIds.LONGROAD, world_state, null),
		"and the way out was never shut"
	)
	world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, QuestIds.MQ13)
	assert_false(edge.is_open(RegionIds.HOLLOWS, world_state, null), "the must is not enough")
	world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	assert_true(edge.is_open(RegionIds.HOLLOWS, world_state, null), "now both are satisfied")


func test_an_ungated_edge_is_open_to_a_world_that_has_done_nothing() -> void:
	var edge := RegionEdge.new()
	edge.a = RegionIds.PRESTIGE
	edge.b = RegionIds.BOWER
	assert_false(edge.is_gated())
	assert_true(edge.is_open(RegionIds.BOWER, _world_state(), null))


# --- Helpers -------------------------------------------------------------------------


## Which group of `world.md` §Layout's adjacency paragraph this edge belongs to, or
## `""` when it belongs to none - which is the whole point of asking.
func _group_of(edge: RegionEdge) -> String:
	if edge == null:
		return ""
	var ends: Array[StringName] = [edge.a, edge.b]
	if RIM.has(edge.a) and RIM.has(edge.b):
		var index := RIM.find(edge.a)
		var before := RIM[(index + RIM.size() - 1) % RIM.size()]
		var after := RIM[(index + 1) % RIM.size()]
		return "rim" if edge.b == before or edge.b == after else ""
	if ends.has(RegionIds.LONGROAD):
		var other := edge.other_end(RegionIds.LONGROAD)
		if RIM.has(other):
			return "spoke"
		if RING_TOWNS.has(other):
			return "causeway town"
		if other == RegionIds.HOLLOWS or other == RegionIds.AXIS:
			return "inner"
		return ""
	if ends.has(RegionIds.UNDERVAULT):
		return "descent" if DESCENTS.has(edge.other_end(RegionIds.UNDERVAULT)) else ""
	if edge.a == RegionIds.HOLLOWS and edge.b == RegionIds.AXIS:
		return "inner"
	if edge.a == RegionIds.CLIFF and edge.kind == RegionEdge.Kind.LEAP:
		return "the leap"
	return ""


func _world_state() -> WorldStateService:
	return WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load("res://data/world_states/act_thresholds.tres") as ActThresholds,
		load("res://data/progression/renown_ladder.tres") as RenownLadder
	)
