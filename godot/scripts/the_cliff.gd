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

## The Cliff's region token, as `docs/GLOSSARY.md` yields it, and the unbinding flag
## that would mean this place is awake - which is none.
##
## The Cliff has no Arcana and no unbinding of its own (`docs/design/world.md` §The
## Cliff), so it sits outside the Spread entirely and the White Rose never regrows
## here. That is also what MQ00 wants: the Waystation rest is the first time the
## player sees petals come back, and a plateau that quietly refilled them beforehand
## would spend the lesson early. The Regions round (round 10) takes this over.
const CLIFF_REGION_ID := &"CLIFF"
const CLIFF_UNBINDING_FLAG := &""

## Which conversation belongs to which MQ00 beat: `quest state -> dialogue graph id`.
##
## The quest's own graph (`res://data/quests/graphs/MQ00.tres`) decides when a beat
## happens; this table only says what the Querent has to say about it, and the
## dialogue graphs decide what that is. A state with nothing to say is simply absent.
##
## Five of MQ00's conversations are deliberately not here, because nothing in the
## scene reaches them yet: `MQ00_WAKE` plays over a black screen before the region
## loads (the opening cut scene, owned by the bootstrap flow), `MQ00_CAMPSITES` needs
## an area trigger on the fire-rings, `MQ00_WAYSTATION_AMBUSH` and
## `MQ00_WAYSTATION_REST_AGAIN` wait for combat (round 7) and for the Waystation's
## rest verb (round 10), and `MQ00_LEAP_BEFORE` belongs to the cut scene that plays
## after Pip jumps and before the Fool steps off.
const DIALOGUE_FOR_STATE: Dictionary = {
	&"BINDLE_TAKEN": DialogueIds.MQ00_MEADOW,
	&"KEEPSAKE_FOUND": DialogueIds.MQ00_KEEPSAKE_GIVEN,
	&"DEAD_TREE_SEEN": DialogueIds.MQ00_DEAD_TREE,
	&"AMBUSH_CLEARED": DialogueIds.MQ00_WAYSTATION_CLEARED,
	&"RESTED": DialogueIds.MQ00_WAYSTATION_REST,
	&"EDGE_REACHED": DialogueIds.MQ00_EDGE_QUESTIONS,
	&"COMPLETE": DialogueIds.MQ00_LANDING,
}

@onready var _leap_point: Area2D = $LeapPoint
@onready var _fool: CharacterBody2D = $World/Fool

var _leap_fired := false

## The one beat whose conversation is waiting for the current one to finish, or
## `&""` when nothing is waiting. One slot on purpose - see `_on_quest_advanced()`.
var _pending_graph_id: StringName = &""


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
	# hand before the tree has stepped. The service connections are deferred with it,
	# for exactly the same reason.
	_wire_services.call_deferred()


## Raise a prop's event on the quest runner, and do the one thing the scene owes the
## player in return: the Bindle is gone once it has been taken.
func _on_trigger_fired(event: StringName, trigger: Interactable) -> void:
	if event == QuestEvents.MQ00_BINDLE_TAKEN:
		var bindle := get_node_or_null(BINDLE_PROP) as Node2D
		if bindle != null:
			bindle.visible = false
	if event == QuestEvents.MQ00_RESTED:
		# Resting at a Waystation fully regrows the White Rose
		# (`docs/design/progression.md` §Waystations). The scene calls the system;
		# the system never reaches back into the scene.
		var rose := _rose()
		if rose != null:
			rose.rest()
	raise_quest_event(event, trigger)


## Forward one world event to the quest runner. The only path from this scene into
## a system, and the reason nothing here touches `WorldStateService`.
func raise_quest_event(event: StringName, source: Node) -> void:
	var quests := _quests()
	if quests == null:
		return
	quests.raise(event, {"node": source})


## MQ00 moved: say whatever the Querent says about the beat it just reached.
##
## The scene starts a conversation and does not wait for it - there is no dialogue
## UI until round 13, so a started conversation simply sits there until something
## advances it, and the beats keep happening around it. `DialogueService.start()`
## refuses while another conversation is running, which is half of the behaviour we
## want: a beat that lands mid-sentence must not interrupt the sentence. It must not
## be *lost* either, though - the Querent's line about the ambush is the only place
## the script explains where the cleared cards went - so a refused beat is remembered
## and started the moment the conversation on screen is over.
##
## One slot, and the newest wins. Two beats queueing behind one conversation means
## the player is outrunning the Querent by a wide margin; replaying the older line
## after the newer one would narrate the wrong moment, so the older is dropped and
## says so in the log.
func _on_quest_advanced(quest_id: StringName, _from_state: StringName, to_state: StringName) -> void:
	if quest_id != QuestIds.MQ00:
		return
	if not DIALOGUE_FOR_STATE.has(to_state):
		return
	var dialogue := _dialogue()
	if dialogue == null:
		return
	var graph_id: StringName = DIALOGUE_FOR_STATE[to_state]
	if dialogue.start(graph_id):
		return
	if not dialogue.is_active():
		# Refused for some other reason - an id the catalog does not hold, which
		# `DialogueService.start()` has already reported. Queueing it would only
		# report it again later.
		return
	if _pending_graph_id != &"":
		push_warning("the Cliff dropped %s: %s was still waiting" % [
			_pending_graph_id, graph_id
		])
	_pending_graph_id = graph_id


## A conversation raised a domain event; the scene is what carries it to the quests,
## exactly as it carries a prop's event. Dialogue never writes world state, and never
## holds a `QuestService` to try (docs/design/technical.md §The WorldState service).
func _on_dialogue_event_raised(event: StringName) -> void:
	raise_quest_event(event, self)


## A conversation finished: the beat that landed while it was running gets its turn.
##
## Deferred rather than immediate, because a graph that chains
## (`DialogueGraph.next_graph_id`) emits `dialogue_ended` *before* it starts its
## successor - so at this instant nothing is running even though something is about
## to be. Starting the pending beat here would win that race and swallow the chained
## half of a scripted beat. By the time the deferred call runs, the chain has begun
## and `is_active()` says so; the pending beat simply waits for the next ending.
func _on_dialogue_ended(_graph_id: StringName) -> void:
	_start_pending_dialogue.call_deferred()


func _start_pending_dialogue() -> void:
	if _pending_graph_id == &"":
		return
	var dialogue := _dialogue()
	if dialogue == null or dialogue.is_active():
		return
	var graph_id := _pending_graph_id
	_pending_graph_id = &""
	dialogue.start(graph_id)


## Subscribe to the services this region listens to, then start the Fool's first
## quest. Subscribing first matters: the very first beat must not be missed.
func _wire_services() -> void:
	var quests := _quests()
	if quests != null and not quests.quest_advanced.is_connected(_on_quest_advanced):
		quests.quest_advanced.connect(_on_quest_advanced)
	var dialogue := _dialogue()
	if dialogue != null and not dialogue.event_raised.is_connected(_on_dialogue_event_raised):
		dialogue.event_raised.connect(_on_dialogue_event_raised)
	if dialogue != null and not dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
		dialogue.dialogue_ended.connect(_on_dialogue_ended)
	var rose := _rose()
	if rose != null:
		rose.set_region(CLIFF_REGION_ID, CLIFF_UNBINDING_FLAG)
	_begin_first_quest()


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


## The conversation runner, looked up the same way and for the same reason.
func _dialogue() -> DialogueService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("dialogue") as DialogueService


## The White Rose, looked up the same way and for the same reason.
func _rose() -> WhiteRoseService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("rose") as WhiteRoseService


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
