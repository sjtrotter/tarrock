class_name MapLayout
extends TarrockDefinition

## The whole world as cards dealt on a table: where each of the 22 lies.
##
## `docs/design/art-audio.md` §Map, the Almanack, and UI: "The map screen renders the
## world as cards dealt face-down on a table; unbinding an Arcanum turns that region's
## card face-up. This is the game's primary progress-at-a-glance UI and should need no
## HUD counter duplicating it." WHERE each card lies is this resource, hand-authored
## from `docs/design/world.md` §Layout's diagram - the wheel of regions around the
## Axis, with the Cliff hanging off the south-east rim.
##
## It is a LAYOUT, not adjacency: which regions touch is
## `res://data/regions/region_graph.tres`, and nothing here may disagree with it,
## because nothing here is asked. The map draws cards; the graph decides travel.

## One card's place per region.
@export var placements: Array[MapPlacement] = []

## The doc section this layout was read off.
@export var doc_ref: String = ""


## Where a region's card lies, or `Vector2(-1, -1)` for a region with no placement.
func placement_of(region_id: StringName) -> Vector2:
	for placement: MapPlacement in placements:
		if placement != null and placement.region_id == region_id:
			return placement.position
	return Vector2(-1.0, -1.0)


## True when this layout places that region.
func has(region_id: StringName) -> bool:
	return placement_of(region_id).x >= 0.0


## Every region id placed, in the order they were authored.
func region_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for placement: MapPlacement in placements:
		if placement != null:
			ids.append(placement.region_id)
	return ids


## Every problem with this layout: a bad placement, a region placed twice, a region
## `RegionIds` knows that nothing places, or a card nobody's region owns.
func validate() -> PackedStringArray:
	var errors := super()
	var seen: Dictionary = {}
	for placement: MapPlacement in placements:
		if placement == null:
			errors.append("%s holds an empty placement" % _describe())
			continue
		errors.append_array(placement.validate())
		if seen.has(placement.region_id):
			errors.append("%s places %s twice" % [_describe(), placement.region_id])
		seen[placement.region_id] = true
	for region_id: StringName in RegionIds.ALL:
		if not seen.has(region_id):
			errors.append("%s never places %s" % [_describe(), region_id])
	for region_id: StringName in seen:
		if not RegionIds.ALL.has(region_id):
			errors.append("%s places %s, which is no region" % [_describe(), region_id])
	return errors
