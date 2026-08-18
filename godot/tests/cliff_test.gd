extends SceneTree

## The Cliff scene, end to end - and, from phase 4 on, MQ00 played through it.
##
## The quest half drives the same path a player does: the Fool is put beside a prop,
## physics is allowed to notice, and either `player.gd`'s interact verb is called or
## the walk-in is the whole gesture. Nothing here talks to `WorldStateService`, and
## nothing here tells the quest what state to be in - the scene raises events and
## `res://data/quests/graphs/MQ00.tres` decides what they mean.
##
## The one beat that cannot be played yet is the ambush: combat is a later round and
## no Blanks stand in the scene, so `MQ00_AMBUSH_CLEARED` is raised directly, exactly
## as the graph's own note says. Everything else is the Fool walking about.
##
## From round 5 the Querent talks over it. Each beat asserts that the conversation
## the scene's `DIALOGUE_FOR_STATE` table promises really started, then walks it to
## its end - which is what a dialogue UI will do for the player, and what has to
## happen here because `DialogueService.start()` refuses while another conversation
## is running. The quest never waits for any of it: the leap still completes MQ00.
##
## One beat is deliberately played the awkward way round (phases 8 and 9): the
## ambush is cleared while the dead-tree conversation is still on screen, which is
## what the scene's pending slot is for. The line waits its turn instead of
## interrupting or vanishing. Phases 13 and 14 push that slot past its one place:
## two beats behind one conversation, where the newer must win.

const ISLAND: PackedVector2Array = preload("res://scripts/cliff_ground.gd").ISLAND

## Where each beat is played, in the order MQ00 plays them, with the quest state the
## scene should have reached by the end of that beat.
const BINDLE_POSITION := Vector2(3660, 2470)
const KEEPSAKE_POSITION := Vector2(3090, 2230)
const DEAD_TREE_POSITION := Vector2(2250, 1250)
const WAYSTATION_POSITION := Vector2(1430, 1000)
const CLIFF_EDGE_POSITION := Vector2(1280, 800)
const LEAP_POSITION := Vector2(1150, 650)

## Somewhere with nothing on it, for a Fool who must be outside every trigger.
const EMPTY_MEADOW := Vector2(3820, 2560)

## Physics frames to let after a teleport before overlaps are believed. Two would
## do; five costs nothing and does not flake.
const SETTLE_FRAMES := 5

## How many lines and questions a single conversation may take before the test calls
## it a loop. MQ00's longest is the edge questions, at well under twenty.
const DIALOGUE_STEP_LIMIT := 200

var _all_passed := true
var _frame := 0
var _phase := 0
var _phase_frame := 0
var _scene: Node2D
var _fool: CharacterBody2D
var _pip: Node2D
var _leap_received := false
var _quests: QuestService
var _dialogue: DialogueService


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/the_cliff.tscn")
	_scene = packed_scene.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("World/Fool") as CharacterBody2D
	_pip = _scene.get_node_or_null("World/Pip") as Node2D
	_scene.leap_point_reached.connect(_on_leap_point_reached)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	_phase_frame += 1

	if _phase == 0:
		if _frame < 3:
			return false
		_run_initial_checks()
		if _fool != null:
			_fool.global_position = Vector2(4200, 1900)
		_advance_phase()
		return false

	if _phase == 1:
		if _fool != null:
			_fool.move(Vector2.RIGHT, 1.0 / 60.0)
		if _phase_frame < 150:
			return false
		var blocked := _fool != null and Geometry2D.is_point_in_polygon(_fool.global_position, ISLAND)
		_all_passed = check(blocked, "Island boundary blocks the Fool at a solid rim edge") and _all_passed
		if _fool != null:
			_fool.global_position = Vector2(1150, 650)
		_advance_phase()
		return false

	if _phase == 2:
		if _phase_frame < 3:
			return false
		var leap_point := _scene.get_node_or_null("LeapPoint") as Area2D
		var overlapping := leap_point != null and _fool != null and leap_point.get_overlapping_bodies().has(_fool)
		_all_passed = check(overlapping, "LeapPoint reports the Fool overlapping it") and _all_passed
		# The emitted signal is the deliverable, not just the overlap - assert it on its own.
		_all_passed = check(_leap_received, "leap_point_reached signal emitted when the Fool reaches the leap point") and _all_passed
		if _fool != null and _pip != null:
			_fool.global_position = Vector2(1150, 650)
			_pip.global_position = Vector2(2150, 650)
		_advance_phase()
		return false

	if _phase == 3:
		var followed := false
		if _fool != null and _pip != null:
			var starting_distance := _pip.global_position.distance_to(_fool.global_position)
			for index in 300:
				_pip.step_follow(1.0 / 60.0)
			var ending_distance := _pip.global_position.distance_to(_fool.global_position)
			followed = ending_distance < starting_distance and ending_distance >= 119.0 and ending_distance <= 121.0
		_all_passed = check(followed, "Pip follows and stops near FOLLOW_DISTANCE without converging to zero") and _all_passed
		_place(EMPTY_MEADOW)
		_advance_phase()
		return false

	# --- MQ00, beat by beat --------------------------------------------------

	if _phase == 4:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_quests = _quest_service()
		_all_passed = check(_quests != null, "the Services autoload built a QuestService") and _all_passed
		if _quests == null:
			_finish()
			return true
		_all_passed = check(
			_quests.is_started(QuestIds.MQ00), "the Cliff started MQ00 when it loaded"
		) and _all_passed
		_all_passed = _check_state(&"WAKING", "MQ00 begins at WAKING, beside the dead campfire")
		_dialogue = _dialogue_service()
		_all_passed = check(_dialogue != null, "the Services autoload built a DialogueService") and _all_passed
		if _dialogue == null:
			_finish()
			return true
		_all_passed = check(
			not _dialogue.is_active(),
			"nothing is being said yet - MQ00_WAKE plays over a black screen the region never sees"
		) and _all_passed
		_place(KEEPSAKE_POSITION)
		_advance_phase()
		return false

	# Regression for the KeepsakeTrigger soft-lock: digging before the Bindle is taken
	# is an event MQ00's graph only answers from BINDLE_TAKEN, so WAKING must not move -
	# and the dig site must not have spent itself, or the *real* dig (phase 7) could
	# never fire and MQ00 would be stuck in BINDLE_TAKEN forever.
	if _phase == 5:
		if _phase_frame < SETTLE_FRAMES:
			return false
		var dug_early: Interactable = _fool.try_interact()
		_all_passed = check(dug_early != null, "the interact verb finds the dig site early") and _all_passed
		_all_passed = _check_state(&"WAKING", "digging before the Bindle is taken leaves MQ00 at WAKING")
		_place(BINDLE_POSITION)
		_advance_phase()
		return false

	if _phase == 6:
		if _phase_frame < SETTLE_FRAMES:
			return false
		var taken: Interactable = _fool.try_interact()
		_all_passed = check(taken != null, "the interact verb finds the Bindle within reach") and _all_passed
		_all_passed = _check_state(&"BINDLE_TAKEN", "picking up the Bindle advances MQ00")
		var bindle := _scene.get_node_or_null("World/Props/Bindle") as Node2D
		_all_passed = check(
			bindle != null and not bindle.visible, "the Bindle is gone from the meadow once taken"
		) and _all_passed
		_all_passed = _check_dialogue(DialogueIds.MQ00_MEADOW, "taking the Bindle starts the meadow line")
		_drain_dialogue()
		_place(KEEPSAKE_POSITION)
		_advance_phase()
		return false

	if _phase == 7:
		if _phase_frame < SETTLE_FRAMES:
			return false
		var dug_again: Interactable = _fool.try_interact()
		_all_passed = check(
			dug_again != null, "the dig site still fires after an earlier, premature dig"
		) and _all_passed
		_all_passed = _check_state(&"KEEPSAKE_FOUND", "digging out the wooden dog advances MQ00")
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_KEEPSAKE_GIVEN, "the wooden dog starts the Querent's line about it"
		)
		# The script puts the choice table straight after that line; the graph says so
		# (next_graph_id), so the scene starts one conversation and gets both.
		_dialogue.advance()
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_WOODEN_DOG, "which chains into the wooden-dog choice table"
		)
		var table: DialogueView = _dialogue.current()
		_all_passed = check(
			table != null and table.is_choice() and table.options.size() == 3,
			"offering the script's three questions"
		) and _all_passed
		_drain_dialogue()
		_place(DEAD_TREE_POSITION)
		_advance_phase()
		return false

	# The ambush is cleared deliberately *while* the dead-tree conversation is still
	# on screen - the case the scene's pending slot exists for. The beat must not
	# interrupt what is being said, and must not be lost either: the Querent's line
	# about where the cleared cards went is the only place the script explains it.
	if _phase == 8:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_all_passed = _check_state(&"DEAD_TREE_SEEN", "approaching the dead tree needs no key press")
		_all_passed = _check_dialogue(DialogueIds.MQ00_DEAD_TREE, "and starts the dead-tree beat")
		# Combat is a later round: no Blanks stand on the Waystation path yet, so the
		# ambush is raised the way the graph's note says it will be until they do.
		_scene.raise_quest_event(QuestEvents.MQ00_AMBUSH_CLEARED, _scene)
		_all_passed = _check_state(&"AMBUSH_CLEARED", "clearing the three Twos advances MQ00")
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_DEAD_TREE, "and does not cut the dead-tree line short"
		)
		_drain_dialogue()
		_advance_phase()
		return false

	if _phase == 9:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_WAYSTATION_CLEARED,
			"the beat that landed mid-conversation plays once that conversation ends"
		)
		_drain_dialogue()
		_place(WAYSTATION_POSITION)
		_advance_phase()
		return false

	if _phase == 10:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_fool.try_interact()
		_all_passed = _check_state(&"RESTED", "resting at the first Waystation advances MQ00")
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_WAYSTATION_REST, "and starts the Querent on what a Waystation is"
		)
		_drain_dialogue()
		_place(CLIFF_EDGE_POSITION)
		_advance_phase()
		return false

	if _phase == 11:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_all_passed = _check_state(&"EDGE_REACHED", "reaching the cliff's edge advances MQ00")
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_EDGE_QUESTIONS, "and opens the questions at the edge"
		)
		var questions: DialogueView = _dialogue.current()
		_all_passed = check(
			questions != null and questions.is_choice() and questions.options.size() == 4,
			"offering the script's four questions"
		) and _all_passed
		_drain_dialogue()
		_place(LEAP_POSITION)
		_advance_phase()
		return false

	if _phase == 12:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_all_passed = _check_state(&"COMPLETE", "stepping off the Cliff completes MQ00")
		_all_passed = check(_quests.is_complete(QuestIds.MQ00), "MQ00 reports itself complete") and _all_passed
		_all_passed = check(
			_quests.active_quest_ids().is_empty(), "and is no longer an active quest"
		) and _all_passed
		# MQ00's own §World-state changes: no flag fires. Completing it opens the
		# world by putting the Fool in it, and changes nothing the world remembers.
		var fired: Dictionary = _world_state_snapshot().get(WorldStateService.SNAPSHOT_FIRED, {})
		_all_passed = check(fired.is_empty(), "MQ00 fired no world-state flag") and _all_passed
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_LANDING, "and the skydive over the Spread plays after it"
		)
		_drain_dialogue()
		_advance_phase()
		return false

	# --- The pending slot holds ONE beat, and the newest wins ----------------
	#
	# MQ00 has run out of real transitions by now, so the last two are staged: the
	# quest runner's own signal is emitted for two beats that both land while a
	# conversation is on screen. Replaying the older line after the newer one would
	# narrate the wrong moment, so the older is dropped - loudly, in the log, which
	# is why the engine's warnings are muted around the provocation.
	if _phase == 13:
		_dialogue.start(DialogueIds.MQ00_MEADOW)
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_MEADOW, "a conversation is on screen again"
		)
		var was_printing := Engine.print_error_messages
		Engine.print_error_messages = false
		_quests.quest_advanced.emit(QuestIds.MQ00, &"", &"DEAD_TREE_SEEN")
		_quests.quest_advanced.emit(QuestIds.MQ00, &"", &"RESTED")
		Engine.print_error_messages = was_printing
		_drain_dialogue()
		_advance_phase()
		return false

	if _phase == 14:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_all_passed = _check_dialogue(
			DialogueIds.MQ00_WAYSTATION_REST,
			"two beats behind one conversation leaves the newer one, not the older"
		)
		_drain_dialogue()
		_finish()
		return true

	return false


## Put the Fool somewhere, and let physics catch up before anything is believed.
func _place(position: Vector2) -> void:
	if _fool != null:
		_fool.global_position = position


## Assert MQ00 is where the last beat should have left it.
func _check_state(expected: StringName, description: String) -> bool:
	var actual := _quests.state_of(QuestIds.MQ00) if _quests != null else &"<no runner>"
	return check(actual == expected, "%s (state %s)" % [description, actual]) and _all_passed


## A node lookup rather than the bare `Services` global: `res://tests/run_all.sh`'s
## lint stage loads every script with `--check-only`, a pure static parse that never
## runs the SceneTree bootstrap wiring an autoload's name into the language as a
## global identifier, so `Services` is an unconditional parse error there regardless
## of whether the autoload exists (see `scripts/the_cliff.gd`'s `_quests()`, which
## keeps this same lookup for the same reason).
func _quest_service() -> QuestService:
	var services := root.get_node_or_null("Services")
	if services == null:
		return null
	return services.get("quests") as QuestService


## The conversation runner, looked up the same way `_quest_service()` is.
func _dialogue_service() -> DialogueService:
	var services := root.get_node_or_null("Services")
	if services == null:
		return null
	return services.get("dialogue") as DialogueService


## Assert the beat just played started the conversation the scene promises for it.
func _check_dialogue(expected: StringName, description: String) -> bool:
	if _dialogue == null:
		return check(false, "%s (no DialogueService)" % description) and _all_passed
	var actual := _dialogue.current_graph_id()
	return check(actual == expected, "%s (running %s)" % [description, actual]) and _all_passed


## Play whatever is being said to its end, the way a dialogue UI eventually will.
##
## Every question is asked and every line advanced past; a table with nothing left
## open is left. This has to happen between beats because `DialogueService.start()`
## refuses while another conversation is running - which is the right behaviour, and
## the reason a headless scene test has to be the player as well as the Fool.
func _drain_dialogue() -> void:
	if _dialogue == null:
		return
	var steps := 0
	while _dialogue.is_active() and steps < DIALOGUE_STEP_LIMIT:
		steps += 1
		var view := _dialogue.current()
		if view == null:
			break
		if not view.is_choice():
			_dialogue.advance()
			continue
		var picked := false
		for index: int in view.options.size():
			if not view.options[index].is_used:
				picked = _dialogue.choose(index)
				break
		if not picked:
			_dialogue.leave()
	_all_passed = check(
		not _dialogue.is_active(), "the conversation reaches an end (%d steps)" % steps
	) and _all_passed


func _world_state_snapshot() -> Dictionary:
	var services := root.get_node_or_null("Services")
	if services == null:
		return {}
	var world_state: WorldStateService = services.get("world_state")
	if world_state == null:
		return {}
	return world_state.to_snapshot()


func _run_initial_checks() -> void:
	var fool_sprite := _fool.get_node_or_null("Sprite") as Sprite2D if _fool != null else null
	var fool_valid := _fool != null and _texture_is_loaded(fool_sprite)
	_all_passed = check(fool_valid, "Fool exists with a loaded Sprite texture") and _all_passed

	var pip_sprite := _pip.get_node_or_null("Sprite") as Sprite2D if _pip != null else null
	var pip_valid := _pip != null and _texture_is_loaded(pip_sprite)
	_all_passed = check(pip_valid, "Pip exists with a loaded Sprite texture") and _all_passed

	var moved_right := false
	if _fool != null:
		var starting_x := _fool.position.x
		for index in 10:
			_fool.move(Vector2.RIGHT, 1.0 / 60.0)
		moved_right = _fool.position.x > starting_x
	_all_passed = check(moved_right, "Fool moves right from the spawn point") and _all_passed

	var boundary := _scene.find_child("IslandBoundary", true, false) as StaticBody2D
	var collision_count := 0
	if boundary != null:
		for child in boundary.get_children():
			if child is CollisionShape2D:
				collision_count += 1
	_all_passed = check(boundary != null and collision_count >= 12, "IslandBoundary exists with at least 12 collision shapes") and _all_passed

	var leap_point := _scene.get_node_or_null("LeapPoint") as Area2D
	_all_passed = check(leap_point != null and leap_point.monitoring, "LeapPoint exists and is monitoring") and _all_passed

	_all_passed = _check_quest_trigger_events() and _all_passed


## Every Interactable under World/QuestTriggers must raise an event a quest can
## actually be listening for - a typo'd event id would be ignored silently forever
## (`QuestService.raise()`'s contract), so this is the only place that would ever say so.
func _check_quest_trigger_events() -> bool:
	var root_node := _scene.get_node_or_null("World/QuestTriggers") as Node2D if _scene != null else null
	if not check(root_node != null, "World/QuestTriggers exists"):
		return false
	var found_any := false
	var all_known := true
	for node: Node in root_node.get_children():
		var trigger := node as Interactable
		if trigger == null:
			continue
		found_any = true
		if not QuestEvents.ALL.has(trigger.event):
			all_known = false
			print("FAIL: %s raises %s, which is not in QuestEvents.ALL" % [trigger.name, trigger.event])
	var has_any := check(found_any, "World/QuestTriggers holds at least one Interactable")
	var all_valid := check(all_known, "every QuestTriggers Interactable raises a QuestEvents.ALL member")
	return has_any and all_valid


func _texture_is_loaded(sprite: Sprite2D) -> bool:
	return sprite != null and sprite.texture != null and sprite.texture.get_width() > 0 and sprite.texture.get_height() > 0


func _advance_phase() -> void:
	_phase += 1
	_phase_frame = 0


func _on_leap_point_reached() -> void:
	_leap_received = true


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _finish() -> void:
	if _all_passed:
		print("CLIFF TEST: PASS")
		quit(0)
	else:
		print("CLIFF TEST: FAIL")
		quit(1)
