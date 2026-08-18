class_name Interactable
extends Area2D

## A thing in a region scene the Fool can act on, and the quest event it raises.
##
## The whole of the scene-to-quest path, and deliberately thin: an `Interactable`
## knows *what happened*, never *what it means*. It emits `triggered` with its event
## id, and the region scene's own script forwards that to `QuestService.raise()`.
## Systems never reach into scenes and never reach for the `Services` autoload
## (docs/design/technical.md §Architecture principles (Godot), 4 and 5), so this node
## does not know the quest runner exists; the scene that owns it does.
##
## Two shapes, one node:
##
##   * **interact** (the default) - `player.gd` finds the nearest overlapping
##     `Interactable` when the `interact` action is pressed and calls `interact()`.
##   * **approach** (`on_approach`) - walking into the area is the whole gesture, for
##     beats a quest doc writes as "approach the dead tree" rather than as a thing to
##     pick up. Such a node ignores the interact key entirely, so it can never
##     swallow a press meant for something else nearby.
##
## `one_shot` (the default) makes a trigger fire once ever: picking up the Bindle
## twice is not a thing that happens.

## This node was acted on. Carries `event` so one handler can serve a whole scene.
signal triggered(event: StringName)

## The group the Fool's scene puts him in. The one place the name is written.
const FOOL_GROUP := &"fool"

## The quest event this raises, from `QuestEvents`. An empty event is an authoring
## mistake and the node refuses to trigger.
@export var event: StringName = &""

## True when this may only ever trigger once.
@export var one_shot: bool = true

## True when walking into the area is the interaction, rather than a key press.
@export var on_approach: bool = false

## True once a one-shot node has been used up.
var _spent: bool = false


func _ready() -> void:
	if on_approach:
		body_entered.connect(_on_body_entered)


## True when a key press should be offered to this node right now: an interact-shaped
## node that has not been used up. `player.gd` asks before it picks a target.
func is_interactable() -> bool:
	return not on_approach and not _spent


## Act on this node. Returns true only when **this call** triggered it.
##
## Called by `player.gd` for the Fool, and by an integration test driving the same
## path. An approach-shaped node always answers false: its trigger is the walk in.
func interact() -> bool:
	if not is_interactable():
		return false
	return _trigger()


## True once this node has fired and, being one-shot, never will again.
func is_spent() -> bool:
	return _spent


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(FOOL_GROUP):
		return
	_trigger()


## Fire once, if this node still may. The single place `triggered` is emitted.
func _trigger() -> bool:
	if _spent:
		return false
	if event == &"":
		push_error("%s has no quest event to raise" % name)
		return false
	if one_shot:
		_spent = true
	triggered.emit(event)
	return true
