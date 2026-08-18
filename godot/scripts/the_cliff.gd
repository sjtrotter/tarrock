extends Node2D

## The Cliff region scene: the tutorial plateau MQ00 plays on.
##
## Scenes call systems, never the other way round (docs/design/technical.md
## §Architecture principles (Godot), 5). This script is the whole of that call for the
## Cliff: it starts MQ00, listens to the props' `Interactable` nodes and to the
## LeapPoint, and forwards each one's event to `QuestService.raise()`. It never
## writes world state, never decides what an event means, and never asks a quest
## where it is - the quest's own graph
## (`res://data/quests/graphs/MQ00.tres`) owns the order the beats happen in.

## The Fool reached the lip. Kept for the Cliff's own integration test, which
## predates the quest system and asserts the scene wiring on its own terms.
signal leap_point_reached

## Where the Interactables live - one subtree, so the scene's art can be rearranged
## without touching the quest wiring.
const TRIGGER_ROOT := "World/QuestTriggers"

## The Bindle sprite, hidden once the Fool has taken it.
const BINDLE_PROP := "World/Props/Bindle"

@onready var _leap_point: Area2D = $LeapPoint
@onready var _fool: CharacterBody2D = $World/Fool

var _leap_fired := false


func _ready() -> void:
	_leap_point.body_entered.connect(_on_leap_point_body_entered)
	for node: Node in get_node(TRIGGER_ROOT).get_children():
		var trigger := node as Interactable
		if trigger != null:
			trigger.triggered.connect(_on_trigger_fired.bind(trigger))
	# The bootstrap / new-game flow owns starting the Fool's first quest once it
	# exists (the Regions round owns the persistent layer and who loads what).
	# Until then the region does it itself, deferred by one call so the `Services`
	# autoload has certainly finished building when a test instances this scene by
	# hand before the tree has stepped.
	_begin_first_quest.call_deferred()


## Raise a prop's event on the quest runner, and do the one thing the scene owes the
## player in return: the Bindle is gone once it has been taken.
func _on_trigger_fired(event: StringName, trigger: Interactable) -> void:
	if event == QuestEvents.MQ00_BINDLE_TAKEN:
		var bindle := get_node_or_null(BINDLE_PROP) as Node2D
		if bindle != null:
			bindle.visible = false
	raise_quest_event(event, trigger)


## Forward one world event to the quest runner. The only path from this scene into
## a system, and the reason nothing here touches `WorldStateService`.
func raise_quest_event(event: StringName, source: Node) -> void:
	var quests := _quests()
	if quests == null:
		return
	quests.raise(event, {"node": source})


func _begin_first_quest() -> void:
	var quests := _quests()
	if quests == null:
		return
	if not quests.is_started(QuestIds.MQ00):
		quests.start(QuestIds.MQ00)


## The bare autoload identifier `Services.quests` would read cleaner, and works fine
## once the game is actually running - but `res://tests/run_all.sh`'s lint stage
## loads every script with `--check-only`, a pure static parse that never runs the
## SceneTree bootstrap that wires an autoload's name into the language as a global
## identifier. Under `--check-only` `Services` is an unconditional
## "Identifier not found" parse error, autoload present or not, so this script keeps
## the node lookup instead. `systems/core/services.gd` is outside this round's owned
## paths (and lint would still catch it); noted in `systems/quests/README.md` as
## owed to whoever revisits `--check-only`'s autoload handling.
func _quests() -> QuestService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("quests") as QuestService


func _on_leap_point_body_entered(body: Node2D) -> void:
	if body != _fool and not body.is_in_group(Interactable.FOOL_GROUP):
		return
	# The scene reports where the Fool is; the quest decides whether that means
	# anything yet. MQ00 only listens for the leap from EDGE_REACHED, so a Fool who
	# wanders onto the lip early is simply a Fool standing on a lip.
	raise_quest_event(QuestEvents.MQ00_LEAP, _leap_point)
	if _leap_fired:
		return
	_leap_fired = true
	leap_point_reached.emit()
