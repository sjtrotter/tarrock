extends RegionScene

## The Cliff region scene: the tutorial plateau MQ00 plays on.
##
## Scenes call systems, never the other way round (docs/design/technical.md
## §Architecture principles (Godot), 5). This script is the whole of that call for the
## Cliff: it listens to the props' `Interactable` nodes, to the Waystation, to the
## LeapPoint and to the Waystation ambush, and forwards each one's event to
## `QuestService.raise()`. It never writes world state, never decides what an event
## means, and never asks a quest where it is - the quest's own graph
## (`res://data/quests/graphs/MQ00.tres`) owns the order the beats happen in.
##
## **What this scene stopped owning in round 10.** It used to be `run/main_scene`, so
## it also started MQ00, told the White Rose which region it was standing in, and
## carried the Fool and Pip as its own children. All three moved up to the persistent
## layer and `RegionService` (`docs/design/technical.md` §Regions and the persistent
## layer), where they belong once there is more than one region: the Fool is not the
## Cliff's, and "begin the game" is not a thing a place does. What is left is what
## only this place can say.

## The Fool reached the lip. Kept for the Cliff's own integration test, which
## predates the quest system and asserts the scene wiring on its own terms.
signal leap_point_reached

## Where the Interactables live - one subtree, so the scene's art can be rearranged
## without touching the quest wiring.
const TRIGGER_ROOT := "World/QuestTriggers"

## Where the hidden things live - one subtree, for the same reason the Interactables
## have one. `docs/quests/main/MQ00-the-leap.md` §The Old Campsites puts exactly one on
## the plateau: the patch of disturbed earth by the largest campsite, with the whittled
## wooden dog in it. It is Pip's Seek that opens it, not the interact key
## (`docs/design/combat.md` §Pip).
const SEEKABLE_ROOT := "World/Seekables"

## Pip's command wheel, on the persistent layer's dog - who is NOT a child of this
## scene: `RegionScene.pip()` is where he comes from.
const PIP_COMPANION := "PipCompanion"

## The Bindle sprite, hidden once the Fool has taken it.
const BINDLE_PROP := "World/Props/Bindle"

## The field of long grass that parts for a passing body.
const TALL_GRASS := "World/TallGrass"

## The one authored fight on the plateau: three Twos between the standing stones on
## the Waystation approach (`docs/quests/main/MQ00-the-leap.md` §The Waystation
## Approach). It lives under its own `World/Encounters` subtree so it can be moved
## along the path without touching the quest wiring - the same reason the
## Interactables have theirs.
const WAYSTATION_AMBUSH := "World/Encounters/WaystationAmbush"

## The beat the graph answers `MQ00_AMBUSH_CLEARED` from. See `_on_quest_advanced()`
## for why the scene has to know it.
const AMBUSH_ANSWERED_FROM := &"DEAD_TREE_SEEN"

## Which conversation belongs to which MQ00 beat: `quest state -> dialogue graph id`.
##
## The quest's own graph (`res://data/quests/graphs/MQ00.tres`) decides when a beat
## happens; this table only says what the Querent has to say about it, and the
## dialogue graphs decide what that is. A state with nothing to say is simply absent.
##
## `MQ00_WAYSTATION_AMBUSH` is deliberately not in this table, because it is not a
## beat: the Querent's "*(mid-fight, easy)*" line plays when the three Blanks rise,
## not when the quest moves, so it hangs on the encounter's `engaged` instead - and
## the quest is still at whatever beat it was on while the fight happens.
##
## Four of MQ00's conversations are not here either, because nothing in the scene
## reaches them yet: `MQ00_WAKE` plays over a black screen before the region loads
## (the opening cut scene, owned by the bootstrap flow), `MQ00_CAMPSITES` needs an
## area trigger on the fire-rings, `MQ00_WAYSTATION_REST_AGAIN` waits for a second rest
## to be told apart from the first, and `MQ00_LEAP_BEFORE` belongs to the cut scene
## that plays after Pip jumps and before the Fool steps off.
## Where the leap lands. `docs/design/world.md` §Layout gives the Cliff exactly one
## way off it (the graph carries the edge); this is the marker in the region it
## arrives on, and the arrival is the crossroads outside the carnival.
const LEAP_DESTINATION := RegionIds.PRESTIGE

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

var _leap_fired := false

## True once this scene has carried `MQ00_AMBUSH_CLEARED` to the quest runner from a
## beat the graph could actually answer it from. See `_on_ambush_cleared()`.
var _ambush_reported := false

## The one beat whose conversation is waiting for the current one to finish, or
## `&""` when nothing is waiting. One slot on purpose - see `_on_quest_advanced()`.
var _pending_graph_id: StringName = &""


func _ready() -> void:
	_leap_point.body_entered.connect(_on_leap_point_body_entered)
	var ambush := _ambush()
	if ambush != null:
		ambush.engaged.connect(_on_ambush_engaged)
		ambush.cleared.connect(_on_ambush_cleared)
	for node: Node in get_node(TRIGGER_ROOT).get_children():
		var trigger := node as Interactable
		if trigger != null:
			trigger.triggered.connect(_on_trigger_fired.bind(trigger))
	for node: Node in _seekables():
		var seekable := node as Seekable
		if seekable != null:
			seekable.found.connect(_on_seekable_found.bind(seekable))
	# The shrine raises its quest event exactly as a prop does; what a REST is belongs
	# to `RegionService`, and the node calls it itself (see `Waystation`).
	for waystation: Waystation in waystations():
		waystation.triggered.connect(_on_trigger_fired.bind(waystation))
	# Deferred by one call so the `Services` autoload has certainly finished building
	# when a test instances this scene by hand before the tree has stepped.
	_wire_services.call_deferred()


## Raise a prop's event on the quest runner, and do the one thing the scene owes the
## player in return: the Bindle is gone once it has been taken.
func _on_trigger_fired(event: StringName, trigger: Interactable) -> void:
	if event == QuestEvents.MQ00_BINDLE_TAKEN:
		var bindle := get_node_or_null(BINDLE_PROP) as Node2D
		if bindle != null:
			bindle.visible = false
	raise_quest_event(event, trigger)


## Pip dug something out. The scene carries the event exactly as it carries a prop's;
## the quest decides what it means, and MQ00's graph only answers the keepsake once the
## Bindle has been taken - which is why the disturbed earth is authored NOT one-shot.
## A Seek before the Bindle is a dog digging a hole, and the hole is still there after.
func _on_seekable_found(seekable: Seekable) -> void:
	if seekable.reward_event == &"":
		return
	raise_quest_event(seekable.reward_event, seekable)


## Pip's wheel wants something to run at, and only the region knows what is out here.
##
## `PipCompanion` never searches the scene (`docs/design/technical.md` §Architecture
## principles (Godot), 5): it asks, with the reach `PipRules` allows, and this answers.
## The Cliff has hidden things and, after the standing stones, enemies; it has nothing
## a dog could fetch, so Fetch goes unanswered here and `PipService` refuses it.
func _on_pip_target_requested(command: PipCommand.Id, from: Vector2, radius: float) -> void:
	var companion := _pip_companion()
	if companion == null:
		return
	var found: Node2D = null
	match command:
		PipCommand.Id.SEEK:
			found = _nearest_seekable(from, radius)
		PipCommand.Id.HARRY:
			found = _nearest_standing_blank(from, radius)
	if found != null:
		companion.provide_target(command, found)


## The nearest hidden thing still worth digging, within `radius` of `from`.
func _nearest_seekable(from: Vector2, radius: float) -> Node2D:
	var nearest: Seekable = null
	var nearest_distance := radius
	for node: Node in _seekables():
		var seekable := node as Seekable
		if seekable == null or not seekable.is_available():
			continue
		var distance := from.distance_to(seekable.global_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest = seekable
	return nearest


## The nearest Blank still on its feet, within `radius` of `from`. One encounter
## exists on the plateau, so one roster is the whole search.
func _nearest_standing_blank(from: Vector2, radius: float) -> Node2D:
	var ambush := _ambush()
	if ambush == null:
		return null
	var nearest: Blank = null
	var nearest_distance := radius
	for member: Blank in ambush.members():
		if member == null or not is_instance_valid(member):
			continue
		if not member.is_awake() or not member.is_alive():
			continue
		var distance := from.distance_to(member.global_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest = member
	return nearest


## Forward one world event to the quest runner. The only path from this scene into
## a system, and the reason nothing here touches `WorldStateService`.
func raise_quest_event(event: StringName, source: Node) -> void:
	var quests := _quests()
	if quests == null:
		return
	quests.raise(event, {"node": source})


## MQ00 moved: say whatever the Querent says about the beat it just reached, and give
## a latched ambush the chance to land now the quest can hear about it.
##
## The scene starts a conversation and does not wait for it - there is no dialogue UI
## until round 13, so a started conversation simply sits there until something advances
## it, and the beats keep happening around it. `_say()` owns what happens when two of
## them want the screen at once.
func _on_quest_advanced(quest_id: StringName, _from_state: StringName, to_state: StringName) -> void:
	if quest_id != QuestIds.MQ00:
		return
	if to_state == AMBUSH_ANSWERED_FROM:
		# MQ00's graph is linear canon order, so it only answers `MQ00_AMBUSH_CLEARED`
		# from the dead tree. A player who reaches the standing stones first - the
		# encounter is a volume in the world, not a locked door - clears a real fight
		# whose event no quest is listening for, and `QuestService.raise()` drops an
		# event nobody wants by design. So the encounter's `cleared` is a LATCH and
		# this is where it is asked again, the moment the quest is ready to hear it.
		#
		# Deferred by one call rather than raised here: this handler is inside the
		# quest runner's own signal, and the beat that lands would otherwise start its
		# conversation *before* the dead-tree line this call is about to start.
		_report_ambush_if_cleared.call_deferred()
	if not DIALOGUE_FOR_STATE.has(to_state):
		return
	_say(DIALOGUE_FOR_STATE[to_state])


## Say one thing, now or as soon as whatever is being said finishes.
##
## `DialogueService.start()` refuses while another conversation is running, which is
## half of the behaviour we want: a beat that lands mid-sentence must not interrupt
## the sentence. It must not be *lost* either, though - the Querent's line about the
## ambush is the only place the script explains where the cleared cards went - so a
## refused line is remembered and started the moment the screen is free.
##
## One slot, and the newest wins. Two lines queueing behind one conversation means the
## player is outrunning the Querent by a wide margin; replaying the older one after
## the newer would narrate the wrong moment, so the older is dropped and says so in
## the log.
func _say(graph_id: StringName) -> void:
	var dialogue := _dialogue()
	if dialogue == null:
		return
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


## The three Blanks rose out of the long grass: the Querent has something to say about
## it while the fight is on. `docs/quests/main/MQ00-the-leap.md` marks the line
## "*(mid-fight, easy)*", so it starts here rather than on a quest beat - the quest has
## not moved and will not until they are down.
func _on_ambush_engaged() -> void:
	_say(DialogueIds.MQ00_WAYSTATION_AMBUSH)


## The three Blanks are down. The scene carries the event; the quest decides what it
## means, and today it only means something from the dead tree onward.
func _on_ambush_cleared() -> void:
	_report_ambush_if_cleared()


## Carry `MQ00_AMBUSH_CLEARED` to the quest runner, if there is a cleared fight to
## report and MQ00 is somewhere it can hear about it.
##
## Called twice on purpose - once when the fight is won, once when the quest reaches
## the beat that answers it - and the guard is which one actually lands. Raising it
## twice would be harmless (no transition leaves `AMBUSH_CLEARED` on this event), but
## `_ambush_reported` keeps the scene honest about having reported it once.
func _report_ambush_if_cleared() -> void:
	if _ambush_reported:
		return
	var ambush := _ambush()
	if ambush == null or not ambush.is_cleared():
		return
	if ambush.quest_event_on_cleared == &"":
		return
	var quests := _quests()
	if quests == null or quests.state_of(QuestIds.MQ00) != AMBUSH_ANSWERED_FROM:
		return
	_ambush_reported = true
	# The event id is the ENCOUNTER's, authored on the node in the scene - the same
	# shape an `Interactable` uses. The scene carries it; it never decides it.
	raise_quest_event(ambush.quest_event_on_cleared, ambush)


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
	# The long grass parts for whoever walks through it, and who that is belongs to
	# the layer above this scene, not to the field (`GrassField.set_bodies`).
	var grass := get_node_or_null(TALL_GRASS) as GrassField
	if grass != null:
		var walkers: Array[Node2D] = []
		for walker: Node2D in [fool(), pip()]:
			if walker != null:
				walkers.append(walker)
		grass.set_bodies(walkers)
	# The encounter is a scene node, so the scene is what hands it its services -
	# exactly as it would hand them to the Fool. It never reaches for them itself.
	var ambush := _ambush()
	if ambush != null:
		ambush.attach_services(_combat(), _enemies())
	# Pip is a scene node like any other, so the scene is what hands him his service
	# and what answers when his wheel asks the region for something to run at.
	var companion := _pip_companion()
	if companion != null:
		companion.attach_service(_pip_service())
		if not companion.target_requested.is_connected(_on_pip_target_requested):
			companion.target_requested.connect(_on_pip_target_requested)


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


## The fight, looked up the same way and for the same reason.
func _combat() -> CombatService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("combat") as CombatService


## The enemy roster, looked up the same way and for the same reason.
func _enemies() -> EnemyService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("enemies") as EnemyService


## Pip's command wheel service, looked up the same way and for the same reason.
## Named for the service rather than for the dog, because `RegionScene` already holds
## the dog himself as `_pip`.
func _pip_service() -> PipService:
	var services := get_node_or_null("/root/Services")
	if services == null:
		return null
	return services.get("pip") as PipService


## Pip's wheel component, or `null` when this scene was instanced without a layer
## above it. He belongs to the persistent layer, not to the Cliff.
func _pip_companion() -> PipCompanion:
	var dog := pip()
	if dog == null:
		return null
	return dog.get_node_or_null(PIP_COMPANION) as PipCompanion


## The hidden things authored on the plateau. Empty in a scene without the subtree.
func _seekables() -> Array[Node]:
	var root_node := get_node_or_null(SEEKABLE_ROOT)
	if root_node == null:
		return []
	return root_node.get_children()


## The Waystation ambush node, or `null` in a stripped-down copy of this scene.
func _ambush() -> Encounter:
	return get_node_or_null(WAYSTATION_AMBUSH) as Encounter


func _on_leap_point_body_entered(body: Node2D) -> void:
	if body != fool() and not body.is_in_group(Interactable.FOOL_GROUP):
		return
	# The scene reports where the Fool is; the quest decides whether that means
	# anything yet. MQ00 only listens for the leap from EDGE_REACHED, so a Fool who
	# wanders onto the lip early is simply a Fool standing on a lip.
	raise_quest_event(QuestEvents.MQ00_LEAP, _leap_point)
	if not _leap_fired:
		_leap_fired = true
		leap_point_reached.emit()
	_take_the_leap()


## Step off the edge, if MQ00 says the Fool is ready to.
##
## `docs/design/world.md` §The Cliff: the plateau is "sealed from the Spread by sheer
## drop on every side... the sanctioned exit is the leap of faith", and `RegionGraph`
## carries that as the Cliff's one and only edge. The scene reports the body on the
## lip; the QUEST decides what standing there means, and only a COMPLETE MQ00 means
## the leap was taken - a Fool who wandered onto the lip at the start of the game has
## simply wandered onto a lip.
##
## The side-view sequence the leap deserves (§Side-view sequences, 1) is presentation
## nobody has built: this is the travel underneath it, and the sequence will play over
## it rather than replace it.
##
## The guard is asserted by name in `res://tests/cliff_test.gd` phase 2, which walks the
## Fool onto the lip while MQ00 is still at WAKING and checks he is still on the Cliff.
## Without that assertion the guard failing would swap the region out from under the
## suite and surface as a null or a hang three phases later.
func _take_the_leap() -> void:
	var quests := _quests()
	if quests == null or not quests.is_complete(QuestIds.MQ00):
		return
	var regions := region_service()
	if regions == null:
		return
	regions.travel_to(LEAP_DESTINATION, RegionService.LEAP_ARRIVAL)
