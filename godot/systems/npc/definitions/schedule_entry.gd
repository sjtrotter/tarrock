class_name ScheduleEntry
extends Resource

## Where one NPC stands during one band of the day.
##
## HAND-AUTHORED, inside an `NpcProfile`. `docs/design/npc-system.md` §Daily life fixes
## the shape and says so: "Schedules are content data... authored per region alongside
## that region's bark pools - this doc fixes the *shape* (anchors + time bands), not the
## per-region content." So an entry is a time band and an anchor, and nothing else.
##
## The anchor is a MARKER NAME in the region scene, not a position: §Daily life is
## explicit that this is "anchor-point schedules, not a full behavioral simulation...
## Explicitly not a Radiant-AI-style sim, and deliberately so: a full sim generates
## emergent noise that *fights* authored awareness - an NPC wandering somewhere
## unscripted can't be standing where their aware line lands." A name resolves to
## wherever the level authored it; a coordinate here would be the level's business
## living in the NPC's data.
##
## **Nothing walks this round.** Round 12 owns the DATA and the lookup
## (`ScheduleService.anchor_for()`); the mover that reads an anchor name and puts a
## body there belongs to whoever builds a populated region scene.

## The band of the day this entry covers. `TimeBand.Id.NONE` is the tableau entry - the
## one a bound region loops on, and the one a world without `WS_SUN_UNBOUND` has.
@export var time_band: TimeBand.Id = TimeBand.Id.NONE

## The marker this NPC stands at during that band.
@export var anchor: StringName = &""

## The kind of day this entry belongs to (`ScheduleVariant.Kind`). `NONE` is the base
## loop; anything else applies only once that variant's unbinding has fired.
@export var variant: ScheduleVariant.Kind = ScheduleVariant.Kind.NONE


## True when this entry is part of the ordinary loop rather than a variant day.
func is_base() -> bool:
	return variant == ScheduleVariant.Kind.NONE


## Every problem with this entry, one string per problem.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if anchor == &"":
		errors.append("a schedule entry stands nowhere")
	return errors
