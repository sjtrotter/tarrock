class_name RegionService
extends RefCounted

## Where the Fool is, where they may go, and everything a Waystation does.
##
## `docs/design/technical.md` §Regions and the persistent layer is the contract:
## **this service is the only thing in the game allowed to load or free a region
## scene**, it does it through a `RegionSwapper` the persistent layer registers, and
## every other service survives a switch untouched. `docs/design/world.md` §Layout
## owns who touches whom (hand-authored into `RegionGraph`), §Hard and soft gates owns
## what a door asks for (data on a `RegionEdge`), and
## `docs/design/progression.md` §Waystations owns what resting, respeccing and fast
## travel mean.
##
## What lives here and what does not:
##
##   * **Adjacency and gates are data**, read off the graph. There is no `match` on a
##     region id anywhere in this file, and a new gate is an edge edit, not a patch.
##   * **The Fool's position across a session is SAVE state**, not a field here: the
##     current region, the last Waystation rested at and the Waystations visited all
##     live in `SaveService`, and this service drives them through its setters. One
##     home for the fact, so a save and a playthrough cannot disagree about where the
##     Fool was standing.
##   * **Nothing here runs per frame.** A region change is an event; the White Rose's
##     regrowth clock and the enemies' brains tick elsewhere.
##
## The defeat loop closes here (`docs/design/combat.md` §Defeat): the service listens
## for `CombatService.fool_defeated` and walks the Fool back to the last Waystation
## rested at. The fall, Pip's lick and the fade are presentation nobody has built yet,
## so `hold_defeat_return()` is the seam that will hold the return until the beat has
## played - unheld, as it is headless, the return is immediate.

## The Fool is about to leave a region: last chance to save anything scene-bound.
signal region_will_change(from_region_id: StringName, to_region_id: StringName)

## The Fool is now in a new region, standing on `arrival`.
signal region_changed(from_region_id: StringName, to_region_id: StringName, arrival: StringName)

## A travel was refused, and why. Developer diagnostics: a refusal a PLAYER should
## understand is a locked door drawn in the world, not this signal.
signal travel_refused(to_region_id: StringName, reason: StringName)

## The Fool rested at a Waystation: the Rose is whole and the ambient dead are back.
signal rested(waystation_id: StringName)

## The Fool stepped into a Waystation's circle - where the Pocket Spread may be
## respecced (`progression.md` §Waystations).
signal waystation_entered(waystation_id: StringName)

## The Fool stepped out of it.
signal waystation_left(waystation_id: StringName)

## The Fool travelled the Spread by Waystation, once the Chariot allowed it.
signal fast_travelled(from_region_id: StringName, waystation_id: StringName)

## No region carries that id.
const REASON_NO_SUCH_REGION := &"NO_SUCH_REGION"

## The region exists but nobody has built its scene yet. A developer diagnostic: by
## the time a player can walk there, this is a bug and not a locked door.
const REASON_NO_SCENE := &"NO_SCENE"

## There is no way from here to there in one move (`world.md` §Layout).
const REASON_NOT_ADJACENT := &"NOT_ADJACENT"

## The way is there and shut: a hard gate on the edge (`world.md` §Hard and soft
## gates).
const REASON_GATE_CLOSED := &"GATE_CLOSED"

## The Fool is already standing there.
const REASON_ALREADY_THERE := &"ALREADY_THERE"

## Nobody registered a swapper, so no scene can be loaded. A wiring bug.
const REASON_NO_SWAPPER := &"NO_SWAPPER"

## That id names no Waystation.
const REASON_NO_SUCH_WAYSTATION := &"NO_SUCH_WAYSTATION"

## The Fool is not standing at a Waystation, and fast travel starts at one
## (`progression.md` §Waystations).
const REASON_NOT_AT_WAYSTATION := &"NOT_AT_WAYSTATION"

## Fast travel is not unlocked: the Chariot is still bound (`progression.md`
## §Waystations, `world.md` §World-state matrix).
const REASON_NO_FAST_TRAVEL := &"NO_FAST_TRAVEL"

## The Fool has never stood at that Waystation, so it is not a place to travel to.
const REASON_NOT_VISITED := &"NOT_VISITED"

## That Waystation is not in the region the Fool is standing in.
const REASON_NOT_HERE := &"NOT_HERE"

## That Waystation is real, and rested at, and still not somewhere fast travel goes.
##
## `world.md` §Layout: the Cliff "is outside the Waystation network - no fast travel
## returns there"; `progression.md` §Waystations says the same from the other end. It
## is deliberately NOT `REASON_NOT_VISITED`: the Fool has slept at the Cliff's shrine,
## MQ00 says so, and telling them they never found it would be a lie the map would have
## to keep. The list lives on the graph (`RegionGraph.fast_travel_network_excludes`),
## because which places the network reaches is a fact about the map.
const REASON_OUTSIDE_NETWORK := &"OUTSIDE_NETWORK"

## The marker a region scene puts the Fool on when nothing else is named: its own
## spawn point. Every region scene authors one.
const DEFAULT_ARRIVAL := &"DEFAULT"

## Where the leap off the Cliff lands (`world.md` §Side-view sequences, MQ00). The
## receiving region scene authors the marker; the Cliff names it.
const LEAP_ARRIVAL := &"LEAP_ARRIVAL"

## The id a StringName field carries when nothing has been set. Referenced rather
## than restated, so there is one empty id in the project.
const UNSET := WorldStateService.UNSET

## The flag that turns the Waystation network into a fast-travel network
## (`progression.md` §Waystations: "once `WS_CHARIOT_UNBOUND` fires... before that
## they are rest-only, keeping early traversal grounded in the physical world").
const FAST_TRAVEL_FLAG := WorldStateIds.WS_CHARIOT_UNBOUND

var _catalog: RegionCatalog = null
var _graph: RegionGraph = null
var _world_state: WorldStateService = null
var _save: SaveService = null
var _rose: WhiteRoseService = null
var _spread: PocketSpreadService = null
var _combat: CombatService = null
var _swapper: RegionSwapper = null

## The Waystation whose circle the Fool is standing in, or `UNSET`.
var _at_waystation: StringName = UNSET

## True while a presentation layer wants the defeat beat to finish before the Fool is
## walked back to the Waystation.
var _defeat_return_held: bool = false

## True when a defeat happened while the return was held.
var _defeat_return_owed: bool = false


## Build the service over the catalog, the graph and the services a region change
## touches.
##
## Everything but the catalog and the graph is optional so a test can build a service
## over the parts it is testing - but the composition root passes all of them, and a
## service with no `SaveService` cannot remember where the Fool is standing between
## sessions (see the class doc: the save IS the memory).
func _init(
	catalog: RegionCatalog,
	graph: RegionGraph,
	world_state: WorldStateService = null,
	save: SaveService = null,
	rose: WhiteRoseService = null,
	spread: PocketSpreadService = null,
	combat: CombatService = null
) -> void:
	_catalog = catalog
	_graph = graph
	_world_state = world_state
	_save = save
	_rose = rose
	_spread = spread
	_combat = combat
	if _combat != null and not _combat.fool_defeated.is_connected(_on_fool_defeated):
		_combat.fool_defeated.connect(_on_fool_defeated)


# --- Reading -------------------------------------------------------------------


## The regions the game knows.
func catalog() -> RegionCatalog:
	return _catalog


## Who touches whom.
func graph() -> RegionGraph:
	return _graph


## The region the Fool is standing in, or `UNSET` before the first travel.
func current_region_id() -> StringName:
	if _save == null:
		return UNSET
	return _save.current_region_id()


## The definition of the region the Fool is standing in, or `null`.
func current_region() -> RegionDefinition:
	return definition(current_region_id())


## The definition with this id, or `null`.
func definition(region_id: StringName) -> RegionDefinition:
	if _catalog == null:
		return null
	return _catalog.find(region_id)


## True when the Fool could walk from one to the other in a single move, gates aside.
func is_adjacent(from_region_id: StringName, to_region_id: StringName) -> bool:
	if _graph == null:
		return false
	return _graph.is_adjacent(from_region_id, to_region_id)


## Why travelling there right now would be refused, or `UNSET` when it would not.
##
## The whole refusal rule in one readable place, in the order a player would meet it:
## is that a region, is the Fool already there, is it built, can you get there from
## here, and is the way open. `fast` skips the adjacency question and nothing else -
## fast travel crosses the Spread, it does not open doors (`progression.md`
## §Waystations).
##
## **`ALREADY_THERE` is asked before `NO_SCENE` on purpose.** `has_scene()` hits the
## filesystem (`ResourceLoader.exists`), and "you are standing in it" is both the
## cheaper answer and the truer one: a region the Fool is already in is one the game
## has evidently drawn, so a filesystem answer could only be more confusing than the
## question.
func travel_refusal(to_region_id: StringName, fast: bool = false) -> StringName:
	var target := definition(to_region_id)
	if target == null:
		return REASON_NO_SUCH_REGION
	var from := current_region_id()
	if from == to_region_id:
		return REASON_ALREADY_THERE
	if not target.has_scene():
		return REASON_NO_SCENE
	if _swapper == null:
		return REASON_NO_SWAPPER
	if from == UNSET:
		# The first placement of a playthrough: a new game onto the Cliff, or a load
		# onto wherever the save says. Nobody walked there, so nothing is adjacent to
		# it, and the graph has nothing to say about it.
		return UNSET
	if fast:
		# Fast travel does not read the map. `progression.md` §Waystations makes the
		# network "world-wide", and its own condition is stricter than any road: the
		# Fool has already slept at the shrine they are going to, which means they
		# already walked there and already opened whatever was in the way. Asking the
		# gate again would refuse a journey the player has demonstrably earned - and
		# would refuse it only for a NEARBY Waystation, since a distant one has no
		# edge to consult, which is the sort of rule nobody could explain.
		return UNSET
	if _graph == null:
		return REASON_NOT_ADJACENT
	var edge := _graph.edge_between(from, to_region_id)
	if edge == null:
		return REASON_NOT_ADJACENT
	if not edge.is_open(to_region_id, _world_state, _spread):
		return REASON_GATE_CLOSED
	return UNSET


## True when travelling there right now would be allowed.
func can_travel(to_region_id: StringName, fast: bool = false) -> bool:
	return travel_refusal(to_region_id, fast) == UNSET


## The Waystation the Fool is standing in the circle of, or `UNSET`.
func at_waystation_id() -> StringName:
	return _at_waystation


## The Waystation the Fool last rested at - where a defeat wakes them
## (`combat.md` §Defeat). `UNSET` before the first rest of a playthrough.
func last_waystation_id() -> StringName:
	if _save == null:
		return UNSET
	return _save.last_waystation_id()


## Every Waystation the Fool has ever rested at, in the order they were first used.
func visited_waystations() -> Array[StringName]:
	if _save == null:
		return []
	return _save.visited_waystations()


## True when the Fool has rested at this Waystation at least once.
func has_visited(waystation_id: StringName) -> bool:
	if _save == null:
		return false
	return _save.has_visited_waystation(waystation_id)


## True once the Waystation network is a fast-travel network.
func fast_travel_unlocked() -> bool:
	return _world_state != null and _world_state.is_fired(FAST_TRAVEL_FLAG)


## The region that authors this Waystation, or `UNSET`.
func region_of_waystation(waystation_id: StringName) -> StringName:
	if _catalog == null:
		return UNSET
	var owner := _catalog.find_by_waystation(waystation_id)
	if owner == null:
		return UNSET
	return owner.id


# --- The swap ------------------------------------------------------------------


## Register the persistent layer's swapper. Called once, by the layer, on the way up.
##
## Kept across a `Services` rebuild by the composition root, because the layer is not
## rebuilt when the services under it are (`Services.rebuild()`).
func set_swapper(swapper: RegionSwapper) -> void:
	_swapper = swapper


## The registered swapper, or `null`.
func swapper() -> RegionSwapper:
	return _swapper


## Take the Fool to a region, arriving on the named marker. True when they went.
##
## The order matters and is the invariant this service exists to hold:
##
##   1. refuse, or **ask the layer for the scene** - and refuse if it will not take it;
##   2. announce `region_will_change`;
##   3. the bookkeeping - where the Fool is, which Waystation circle they left;
##   4. **the world's own state** - the White Rose is told which region it is standing
##      in (and therefore whether it may regrow at all), and the fight is emptied so
##      no enemy from the old scene is still "engaged" in the new one;
##   5. `region_changed`.
##
## **The request comes first, and its answer is believed.** A swapper answers whether
## it accepted the request, not whether the nodes have moved - it does the node work a
## frame later (see `RegionSwapper`) - so asking first costs nothing and buys the one
## thing that matters: a layer that cannot load the scene refuses BEFORE the save has
## been told the Fool is somewhere they never arrived. Everything the swap needs done
## before the nodes change still happens before the nodes change, which is the whole
## reason the old order existed: the Rose and the fight are updated in this same frame,
## and a `CombatService` still holding a freed Blank next frame would be a fight nobody
## can win.
func travel_to(to_region_id: StringName, arrival: StringName = DEFAULT_ARRIVAL) -> bool:
	return _travel(to_region_id, arrival, false)


## Put the Fool somewhere without their having walked there: a new game, or a load.
##
## Not a journey and not fast travel - a PLACEMENT. `Services.load_game()` applies the
## save first, which is what tells this service where the Fool was standing, and
## `travel_to()` would then refuse the journey as "you are already there" and leave
## the region scene unloaded and the Fool nowhere. So a placement clears where the
## save thinks the Fool is and puts them there properly, scene and all.
func place_at(region_id: StringName, arrival: StringName = DEFAULT_ARRIVAL) -> bool:
	var reason := travel_refusal(region_id, true)
	if reason != UNSET and reason != REASON_ALREADY_THERE:
		travel_refused.emit(region_id, reason)
		return false
	if _save != null:
		_save.set_current_region(UNSET)
	return _travel(region_id, arrival, true)


## Cross the Spread by Waystation. True when the Fool went.
##
## `progression.md` §Waystations: Waystations "become fast-travel points world-wide
## once `WS_CHARIOT_UNBOUND` fires... before that they are rest-only". Three things
## have to hold, and each has its own refusal: the Chariot is unbound, the Fool is
## standing at a Waystation to leave from, and the Waystation they are going to is one
## they have rested at before.
func fast_travel_to(waystation_id: StringName) -> bool:
	var reason := fast_travel_refusal(waystation_id)
	if reason != UNSET:
		travel_refused.emit(region_of_waystation(waystation_id), reason)
		return false
	var from := current_region_id()
	var destination := region_of_waystation(waystation_id)
	if destination == from:
		# Already in the right region: no scene need be thrown away to walk across it.
		if not _re_anchor(waystation_id):
			return false
		enter_waystation(waystation_id)
		fast_travelled.emit(from, waystation_id)
		return true
	if not _travel(destination, waystation_id, true):
		return false
	fast_travelled.emit(from, waystation_id)
	return true


## Why fast travel to that Waystation would be refused, or `UNSET`.
##
## The network question is asked FIRST, ahead of the Chariot and ahead of the Fool's
## own travels, because it is the only permanent one: a shrine outside the network is
## outside it in every playthrough and at every hour, and answering "the Chariot is
## still bound" about the Cliff would be an answer that stops being true without the
## refusal ever going away.
func fast_travel_refusal(waystation_id: StringName) -> StringName:
	var destination := region_of_waystation(waystation_id)
	if destination == UNSET:
		return REASON_NO_SUCH_WAYSTATION
	if _graph != null and not _graph.in_fast_travel_network(waystation_id):
		return REASON_OUTSIDE_NETWORK
	if not fast_travel_unlocked():
		return REASON_NO_FAST_TRAVEL
	if _at_waystation == UNSET:
		return REASON_NOT_AT_WAYSTATION
	if not has_visited(waystation_id):
		return REASON_NOT_VISITED
	if destination == current_region_id():
		return UNSET
	return travel_refusal(destination, true)


# --- Waystations ----------------------------------------------------------------


## The Fool stepped into a Waystation's circle. Idempotent.
##
## `progression.md` §Waystations: this is where the Pocket Spread may be respecced,
## which is a rule `PocketSpreadService` already owns and only needs telling about.
func enter_waystation(waystation_id: StringName) -> bool:
	if region_of_waystation(waystation_id) == UNSET:
		return false
	if _at_waystation == waystation_id:
		return true
	_at_waystation = waystation_id
	if _spread != null:
		_spread.set_at_waystation(true)
	waystation_entered.emit(waystation_id)
	return true


## The Fool stepped out of it. Idempotent.
func leave_waystation() -> void:
	if _at_waystation == UNSET:
		return
	var left := _at_waystation
	_at_waystation = UNSET
	if _spread != null:
		_spread.set_at_waystation(false)
	waystation_left.emit(left)


## Rest. The whole of `progression.md` §Waystations' first bullet, in one call.
##
## "**Rest** - fully regrow the White Rose and respawn ambient (non-boss) enemies."
## Both halves happen here: the Rose is filled, and the layer is asked to put back
## every encounter that answers to a rest - which is NOT every encounter. A fight a
## quest hangs on stays won (`Encounter.respawns_on_rest`), because a player who has
## cleared the Waystation ambush and then rests beside it must not find it standing
## again.
##
## Resting is also what makes a Waystation a place the Fool can come back to: it is
## recorded as the one a defeat wakes them at (`combat.md` §Defeat) and marked
## visited, which is the condition fast travel reads.
func rest_at(waystation_id: StringName) -> bool:
	var owner := region_of_waystation(waystation_id)
	if owner == UNSET:
		travel_refused.emit(UNSET, REASON_NO_SUCH_WAYSTATION)
		return false
	if owner != current_region_id():
		travel_refused.emit(owner, REASON_NOT_HERE)
		return false
	enter_waystation(waystation_id)
	if _rose != null:
		_rose.rest()
	if _save != null:
		_save.set_last_waystation(waystation_id)
		_save.mark_waystation_visited(waystation_id)
	if _swapper != null:
		_swapper.respawn_ambient()
	rested.emit(waystation_id)
	return true


# --- The defeat loop -------------------------------------------------------------


## Hold the walk back until the defeat beat has played, or let it happen at once.
##
## `combat.md` §Defeat is a sequence - the fall, Pip's lick, the fade - and only after
## the fade does the Fool "wake at the last Waystation rested at". Nothing draws any
## of that yet, so by default the return is immediate and the loop is whole; a UI that
## takes the beat over holds the return while it plays and releases it after the fade.
func hold_defeat_return(held: bool) -> void:
	_defeat_return_held = held
	if not held:
		_release_owed_return()


## True while the walk back is being held for a defeat beat.
func defeat_return_held() -> bool:
	return _defeat_return_held


## Wake the Fool at the last Waystation rested at. True when they were moved.
##
## The invariant loop of `combat.md` §Defeat: "the Fool wakes at the last Waystation
## rested at, White Rose regrown, Pip already beside them. No currency loss, no corpse
## run, no penalty beyond the walk back". The Rose and the health are
## `CombatService.revive_at_waystation()`'s, and are restored last, once the Fool is
## somewhere to wake up.
##
## **Before the first rest of a playthrough there is nowhere to wake up** - a Fool can
## be put down on the Cliff before ever reaching the Waystation - so the fallback is
## this region's own Waystation, and failing that its spawn marker. Waking at the
## start of the region you fell in is the gentlest reading of "no penalty beyond the
## walk back" that does not need a Waystation nobody has visited.
##
## **And the walk back itself can fail.** The shrine the Fool slept at is in a region
## the game has to be able to draw, and today twenty of the twenty-two have no scene:
## a save carried across a build that dropped one, or a layer that will not take the
## swap, would otherwise leave the Fool lying in a region nobody walked back from, with
## no revive and no way up - a soft-lock out of the one loop `combat.md` §Defeat
## promises always closes. So a failed journey falls through to waking HERE, loudly
## (`push_warning`): a wrong place to wake up is a bug worth a log line, and never
## waking up at all is a bug worth a lost playthrough.
func return_to_last_waystation() -> bool:
	var waystation_id := last_waystation_id()
	var here := current_region_id()
	if waystation_id == UNSET or region_of_waystation(waystation_id) == UNSET:
		var region := current_region()
		waystation_id = UNSET if region == null else region.first_waystation_id()
	var destination := region_of_waystation(waystation_id)
	var arrival := waystation_id if waystation_id != UNSET else DEFAULT_ARRIVAL
	var moved := false
	if destination != UNSET and destination != here:
		moved = _travel(destination, arrival, true)
		if not moved:
			push_warning("no way back to %s: waking the Fool where they fell" % waystation_id)
			moved = _wake_where_they_fell()
	else:
		moved = _re_anchor(arrival)
		if moved and waystation_id != UNSET:
			enter_waystation(waystation_id)
	if not moved:
		# Nowhere to wake up: no persistent layer registered a swapper, which is a
		# headless fixture (an arena test) rather than a playthrough. The Fool stays
		# down, because "the Fool wakes at the last Waystation" is one event and half
		# of it - full health, in the spot they fell - is not a gentler version of it.
		return false
	if _combat != null:
		_combat.revive_at_waystation()
	return true


# --- Internals -------------------------------------------------------------------


## The one travel path; `forced` skips the adjacency question (fast travel, and the
## walk back from a defeat, which is not travel at all).
func _travel(to_region_id: StringName, arrival: StringName, forced: bool) -> bool:
	var reason := travel_refusal(to_region_id, forced)
	if reason != UNSET:
		travel_refused.emit(to_region_id, reason)
		return false
	var target := definition(to_region_id)
	var from := current_region_id()
	if not _swapper.swap(target.scene_path, arrival):
		# The layer looked at the scene and would not take it. Nothing has moved yet,
		# which is the point of asking first.
		travel_refused.emit(to_region_id, REASON_NO_SCENE)
		return false
	region_will_change.emit(from, to_region_id)
	leave_waystation()
	if _save != null:
		_save.set_current_region(to_region_id)
	if _rose != null:
		_rose.set_region(to_region_id, target.unbinding_flag)
	if _combat != null:
		_combat.clear_engagements()
	if target.has_waystation(arrival):
		enter_waystation(arrival)
	region_changed.emit(from, to_region_id, arrival)
	return true


## Move the Fool within the region already loaded.
func _re_anchor(arrival: StringName) -> bool:
	if _swapper == null:
		return false
	return _swapper.re_anchor(arrival)


## The defeat loop's last resort: stand the Fool up in the region they are already in,
## at its own shrine when it has one and on its spawn marker when it does not.
##
## Not a journey - nothing is loaded and nothing is freed, because the region under
## their feet is the only one this call is sure of. See `return_to_last_waystation()`
## for when it is reached and why it is louder than it is graceful.
func _wake_where_they_fell() -> bool:
	var region := current_region()
	var shrine := UNSET if region == null else region.first_waystation_id()
	var arrival := shrine if shrine != UNSET else DEFAULT_ARRIVAL
	if not _re_anchor(arrival):
		return false
	if shrine != UNSET:
		enter_waystation(shrine)
	return true


## The Fool went down. `PipService` is already playing its half of the beat; this is
## the return leg (see `hold_defeat_return()`).
func _on_fool_defeated(_defeat_count: int, _at_seconds: int) -> void:
	if _defeat_return_held:
		_defeat_return_owed = true
		return
	return_to_last_waystation()


func _release_owed_return() -> void:
	if not _defeat_return_owed:
		return
	_defeat_return_owed = false
	return_to_last_waystation()
