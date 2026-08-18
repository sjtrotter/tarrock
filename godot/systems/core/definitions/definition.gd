class_name TarrockDefinition
extends Resource

## Base class for every content definition in Tarrock.
##
## A definition is authored content lifted out of `docs/` - a world-state flag, a
## quest, a region, an enemy, a Trump - saved as a `.tres` under
## `res://data/<feature>/` and typed by a subclass under
## `res://systems/<feature>/definitions/`. It is the Godot answer to Unity's
## ScriptableObject (docs/design/technical.md).
##
## Two rules, both from technical.md:
##   * Definitions are IMMUTABLE at runtime. Nothing writes to one during play;
##     all mutable state lives in the save model.
##   * Definitions carry stable string `id`s, and everything else refers to
##     content by that id - never by resource path, never by display name.
##
## Subclasses override `validate()` and call `super()` first, so a data-drift test
## can load every `.tres` and fail on the whole set at once.

## Stable content id, e.g. `&"WS_EMPRESS_UNBOUND"`, `&"MQ00"`, `&"the_cliff"`.
@export var id: StringName = &""


## Every problem with this definition, one string per problem; empty means valid.
## Subclasses override, call `super()`, and append their own findings.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("%s has an empty id" % _describe())
	return errors


## True when `validate()` finds nothing.
func is_valid() -> bool:
	return validate().is_empty()


## How this definition names itself in an error message: its file if it has one,
## otherwise its class. `get_class()` reports the *engine* base ("Resource") for a
## script class, so the `class_name` has to come off the script itself.
func _describe() -> String:
	if not resource_path.is_empty():
		return resource_path
	return "<unsaved %s>" % _class_name()


func _class_name() -> String:
	var script := get_script() as Script
	if script != null:
		var global_name := script.get_global_name()
		if global_name != &"":
			return String(global_name)
	return get_class()
