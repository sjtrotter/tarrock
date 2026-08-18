class_name ScheduleService
extends RefCounted

## Where a named NPC stands right now: the anchor lookup behind `docs/design/
## npc-system.md` §Daily life.
##
## The doc is emphatic about what this is not: "NPCs run **anchor-point schedules**, not
## a full behavioral simulation. Explicitly not a Radiant-AI-style sim, and deliberately
## so: a full sim generates emergent noise that *fights* authored awareness - an NPC
## wandering somewhere unscripted can't be standing where their aware line lands. Light
## schedules keep every moment intentional, which is what the pillar actually needs."
## So this service is a lookup and nothing more: profile plus band plus world state, in,
## an anchor name out. It holds no positions, moves nothing, and ticks not at all.
##
## Three rules, and all three are the doc's:
##
##   * **No time of day before `WS_SUN_UNBOUND`.** NPCs move between anchors "on a
##     simple time-of-day loop **once `WS_SUN_UNBOUND` gives the world a day/night cycle
##     to schedule against**". Before that, every region answers with its tableau anchor,
##     whatever band the caller believes it is.
##   * **Bound regions are deliberately static.** "Per `art-audio.md`'s bound/unbound
##     rule (posed mid-flutter, audibly-looping ambience), bound-region NPCs hold
##     tableau-still routines - the same few anchor visits on a short, unvarying loop.
##     Stasis **is** the fiction; a bound region whose NPCs bustle naturally would
##     contradict the region's own art direction."
##   * **Unbound regions gain variety, keyed to the matrix.** Weddings, funerals,
##     markets, caravans and petty crime, each waiting on its own unbinding - see
##     `ScheduleVariant`.
##
## Whether a REGION is bound is `RegionDefinition.unbinding_flag` against the world
## state, which this service asks directly, so a caller never has to work it out.

var _rules: NpcRules = null
var _world_state: WorldStateService = null
var _regions: RegionCatalog = null


## Build the service over the tuning table, the world state and the region catalog.
##
## The region CATALOG rather than `RegionService`: the only question asked of a region
## is which flag wakes it, that is authored data, and taking the service would reach
## the save that holds the whole NPC graph (see `RumorService`'s class doc).
func _init(
	rules: NpcRules, world_state: WorldStateService = null, regions: RegionCatalog = null
) -> void:
	_rules = rules
	_world_state = world_state
	_regions = regions


## True once the world has a day and a night to schedule against.
func has_time_of_day() -> bool:
	return _world_state != null and _world_state.is_fired(WorldStateIds.WS_SUN_UNBOUND)


## True while this region is still held in its tableau.
##
## A region with no unbinding flag - the Cliff - is never bound: `world.md` §The Cliff
## is a plateau outside the Spread with no Arcana holding it, and answering "bound"
## there would freeze the one region the game opens in.
func is_region_bound(region_id: StringName) -> bool:
	if _regions == null or _world_state == null:
		return false
	var definition := _regions.find(region_id)
	if definition == null or definition.unbinding_flag == &"":
		return false
	return not _world_state.is_fired(definition.unbinding_flag)


## The band of the day it is, by the clock's reading in seconds.
##
## `TimeBand.Id.NONE` until `WS_SUN_UNBOUND`: a world with no sun has no time of day,
## and answering DAY there would be inventing one. The seconds are passed in rather than
## read off a clock so that a caller drives this explicitly - nothing here ticks.
func band_at(elapsed_seconds: float) -> TimeBand.Id:
	if not has_time_of_day() or _rules == null:
		return TimeBand.Id.NONE
	return _rules.band_at_seconds(elapsed_seconds)


## True when this kind of day can happen at all yet: its unbinding has fired.
func is_variant_active(kind: ScheduleVariant.Kind) -> bool:
	if kind == ScheduleVariant.Kind.NONE:
		return true
	if _rules == null or _world_state == null:
		return false
	var variant := _rules.variant_of(kind)
	if variant == null or variant.when_fired == &"":
		return false
	return _world_state.is_fired(variant.when_fired)


## Every kind of day the world has unlocked, in the tuning table's order.
func active_variants() -> Array[ScheduleVariant]:
	var found: Array[ScheduleVariant] = []
	if _rules == null:
		return found
	for variant: ScheduleVariant in _rules.schedule_variants:
		if variant != null and is_variant_active(variant.kind):
			found.append(variant)
	return found


## Where this NPC stands at this band of the day.
##
## The whole of §Daily life, in order: a bound region or a world without a sun answers
## with the tableau anchor and nothing else; otherwise the band's entries are read
## most-specific-first, a variant entry beating the base entry when that variant's
## unbinding has fired. An NPC with nothing filed for this band keeps their tableau
## anchor, because a person standing nowhere is not a thing a region can draw.
##
## `region_id` defaults to the profile's home region, which is where a scheduled NPC is
## by definition; it is a parameter for the NPCs a quest moves.
func anchor_for(
	profile: NpcProfile, band: TimeBand.Id, region_id: StringName = &""
) -> StringName:
	if profile == null:
		return &""
	var where := profile.home_region if region_id == &"" else region_id
	if not has_time_of_day() or is_region_bound(where) or band == TimeBand.Id.NONE:
		return profile.tableau_anchor()
	var chosen: ScheduleEntry = null
	for entry: ScheduleEntry in profile.entries_for(band):
		if entry.is_base():
			if chosen == null:
				chosen = entry
			continue
		if is_variant_active(entry.variant):
			chosen = entry
			break
	if chosen == null:
		return profile.tableau_anchor()
	return chosen.anchor
