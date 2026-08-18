class_name MapPlacement
extends Resource

## Where one region's card lies on the table, as a fraction of the map's own size.
##
## Fractions rather than pixels, because `docs/design/technical.md` §Port-readiness
## rules (Godot), 2 forbids a fixed pixel offset that assumes 1280x720: the map
## screen multiplies these by whatever size it was actually given.

## The region this card is (`RegionIds`).
@export var region_id: StringName = &""

## Where its centre sits, 0..1 across and down the table. `world.md` §Layout's
## diagram read as a compass: x is east, y is south.
@export var position: Vector2 = Vector2(0.5, 0.5)


## Every problem with this placement; empty means valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if region_id == &"":
		errors.append("a map placement has no region id")
	if position.x < 0.0 or position.x > 1.0 or position.y < 0.0 or position.y > 1.0:
		errors.append("%s sits off the table at %s" % [region_id, position])
	return errors
