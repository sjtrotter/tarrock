extends TarrockTest

## What Pip does when he is asked, and what happens when he is put to zero.
##
## `docs/design/combat.md` §Pip is the canon: three commands, and a Pip who "cannot
## die" - "if reduced to zero health he yelps, retreats out of the fight, shakes it
## off, and returns after a short cooldown". §Defeat step 2 is the other beat: the Fool
## goes down and Pip trots over, "matter-of-fact, never performing concern".
##
## The service has no tree and no nodes: every arrival here is `report_arrived()`, which
## is what `PipCompanion` calls when Pip's feet get there, and every second is a delta
## this test chose. **Nothing is compared to the wall clock.**

const RULES_PATH := "res://data/pip/pip_rules.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"

## One physics frame at 60 Hz.
const FRAME := 1.0 / 60.0

var _rules: PipRules = null
var _service: PipService = null

## Stand-ins for the item, the enemy and the hidden thing. Freed in `after_each`.
var _things: Array[Node2D] = []

## Every service this test built over a `CombatService`, so each one lets go of it
## again in `after_each` - see `PipService.detach()`. A `CombatService` that keeps a
## test's dead Pip connected is a Pip who reacts to the NEXT test's defeat.
var _attached: Array[PipService] = []


func before_each() -> void:
	_rules = (load(RULES_PATH) as PipRules).duplicate() as PipRules
	_service = PipService.new(_rules)


func after_each() -> void:
	for service: PipService in _attached:
		service.detach()
	_attached.clear()
	for thing: Node2D in _things:
		if is_instance_valid(thing):
			thing.free()
	_things.clear()


# --- Fetch -----------------------------------------------------------------------


func test_fetch_runs_out_picks_up_and_comes_back() -> void:
	var item := _thing(Vector2(300, 0))
	watch_signal(_service, &"command_issued")
	watch_signal(_service, &"fetch_delivered")
	watch_signal(_service, &"command_completed")
	assert_true(_command(PipCommand.Id.FETCH, item), "Pip takes the command")
	assert_signal_emitted(_service, &"command_issued", 1)
	assert_eq(signal_arguments(_service, &"command_issued", 0), [int(PipCommand.Id.FETCH)])
	assert_eq(_service.state(), PipService.State.FETCHING)
	assert_eq(_service.phase(), PipService.Phase.OUTBOUND, "on his way to it")
	assert_eq(_service.target(), item)
	_service.report_arrived()
	assert_eq(
		_service.phase(),
		PipService.Phase.RETURNING,
		"a pickup is a mouthful, not a job: he turns straight round"
	)
	assert_almost_eq(_service.work_seconds_left(), 0.0, 0.0001)
	_service.report_arrived()
	assert_signal_emitted(_service, &"fetch_delivered", 1)
	assert_eq(signal_arguments(_service, &"fetch_delivered", 0), [item], "and it is the item he took")
	assert_signal_emitted(_service, &"command_completed", 1)
	assert_eq(_service.state(), PipService.State.FOLLOWING, "then back to the Fool's heel")
	assert_eq(_service.active_command(), PipCommand.NONE)
	assert_null(_service.target())


# --- Seek ------------------------------------------------------------------------


func test_seek_digs_for_the_reveal_seconds_then_brings_it_back() -> void:
	var hole := _thing(Vector2(0, 200))
	watch_signal(_service, &"seek_found")
	watch_signal(_service, &"command_completed")
	assert_true(_command(PipCommand.Id.SEEK, hole))
	assert_eq(_service.state(), PipService.State.SEEKING)
	_service.report_arrived()
	assert_eq(_service.phase(), PipService.Phase.WORKING, "he digs")
	assert_almost_eq(_service.work_seconds_left(), _rules.seek_reveal_seconds, 0.0001)
	_tick_frames(_frames_in(_rules.seek_reveal_seconds) - 2)
	assert_signal_emitted(_service, &"seek_found", 0, "nothing is found before the dig is done")
	_tick_frames(4)
	assert_signal_emitted(_service, &"seek_found", 1, "then he backs out of the hole with it")
	assert_eq(signal_arguments(_service, &"seek_found", 0), [hole])
	assert_eq(_service.phase(), PipService.Phase.RETURNING, "and trots it back")
	assert_signal_emitted(_service, &"command_completed", 0, "the command is not done until he is")
	_service.report_arrived()
	assert_signal_emitted(_service, &"command_completed", 1)
	assert_eq(signal_arguments(_service, &"command_completed", 0), [int(PipCommand.Id.SEEK)])
	assert_eq(_service.state(), PipService.State.FOLLOWING)


# --- Harry -----------------------------------------------------------------------


func test_harry_pins_for_the_duration_and_then_lets_go() -> void:
	var enemy := _thing(Vector2(400, 100))
	watch_signal(_service, &"harry_started")
	watch_signal(_service, &"harry_ended")
	assert_true(_command(PipCommand.Id.HARRY, enemy))
	assert_signal_emitted(
		_service, &"harry_started", 0, "nothing is pinned while he is still running at it"
	)
	_service.report_arrived()
	assert_signal_emitted(_service, &"harry_started", 1, "he reaches it and takes its attention")
	assert_eq(signal_arguments(_service, &"harry_started", 0), [enemy])
	assert_eq(_service.phase(), PipService.Phase.WORKING)
	assert_almost_eq(_service.work_seconds_left(), _rules.harry_seconds, 0.0001)
	_tick_frames(_frames_in(_rules.harry_seconds) - 2)
	assert_signal_emitted(_service, &"harry_ended", 0, "and holds it for the whole duration")
	_tick_frames(4)
	assert_signal_emitted(_service, &"harry_ended", 1, "then lets go")
	assert_eq(_service.phase(), PipService.Phase.RETURNING)
	_service.report_arrived()
	assert_eq(_service.state(), PipService.State.FOLLOWING)


func test_a_pin_that_never_began_is_never_reported_as_ending() -> void:
	var enemy := _thing(Vector2(400, 0))
	var hole := _thing(Vector2(-400, 0))
	watch_signal(_service, &"harry_ended")
	_command(PipCommand.Id.HARRY, enemy)
	# Still running at it, so nothing has been harried yet - and a new command must
	# not tell an enemy it has been let go of.
	_command(PipCommand.Id.SEEK, hole)
	assert_signal_emitted(_service, &"harry_ended", 0)


func test_a_new_command_replaces_the_one_running() -> void:
	var item := _thing(Vector2(300, 0))
	var hole := _thing(Vector2(-300, 0))
	watch_signal(_service, &"command_completed")
	_command(PipCommand.Id.FETCH, item)
	_command(PipCommand.Id.SEEK, hole)
	assert_eq(_service.state(), PipService.State.SEEKING, "a dog obeys the newest thing said to him")
	assert_eq(_service.target(), hole)
	assert_eq(_service.phase(), PipService.Phase.OUTBOUND)
	assert_signal_emitted(
		_service, &"command_completed", 0, "and the dropped errand completes nothing"
	)


# --- Refusals ---------------------------------------------------------------------


func test_a_command_with_nothing_to_do_it_to_is_refused() -> void:
	watch_signal(_service, &"command_refused")
	assert_false(_service.command(PipCommand.Id.FETCH, {}), "nothing offered, nothing fetched")
	assert_signal_emitted(_service, &"command_refused", 1)
	assert_eq(
		signal_arguments(_service, &"command_refused", 0),
		[int(PipCommand.Id.FETCH), PipService.REASON_NO_TARGET]
	)
	assert_eq(_service.state(), PipService.State.FOLLOWING, "and he stays at the Fool's heel")


func test_an_id_that_is_not_a_command_is_refused() -> void:
	watch_signal(_service, &"command_refused")
	assert_false(_service.command(99, {}))
	assert_eq(
		signal_arguments(_service, &"command_refused", 0), [99, PipService.REASON_UNKNOWN_COMMAND]
	)


func test_an_explicit_null_target_is_refused() -> void:
	watch_signal(_service, &"command_refused")
	assert_false(
		_service.command(PipCommand.Id.FETCH, {PipService.CONTEXT_TARGET: null}),
		"a scene that answered with nothing has answered nothing"
	)
	assert_signal_emitted(_service, &"command_refused", 1)


func test_nothing_reaches_a_pip_who_is_shaking_it_off() -> void:
	var hole := _thing(Vector2(0, 200))
	_service.on_pip_health_zero(Vector2.ZERO)
	watch_signal(_service, &"command_refused")
	for command: int in PipCommand.ALL:
		assert_false(_service.is_available(command), "%d is out of reach" % command)
		assert_false(_command(command, hole))
	assert_signal_emitted(_service, &"command_refused", 3)
	assert_eq(
		signal_arguments(_service, &"command_refused", 0),
		[int(PipCommand.Id.FETCH), PipService.REASON_RETREATED]
	)


func test_nothing_reaches_a_pip_with_a_face_to_lick() -> void:
	var hole := _thing(Vector2(0, 200))
	_service.begin_defeat_beat()
	watch_signal(_service, &"command_refused")
	assert_false(_service.is_available(PipCommand.Id.SEEK))
	assert_false(_command(PipCommand.Id.SEEK, hole))
	assert_eq(
		signal_arguments(_service, &"command_refused", 0),
		[int(PipCommand.Id.SEEK), PipService.REASON_DEFEAT_BEAT]
	)


# --- The retreat, which is not a death ----------------------------------------------


func test_zero_health_is_a_retreat_a_cooldown_and_a_return() -> void:
	watch_signal(_service, &"pip_retreated")
	watch_signal(_service, &"pip_returned")
	_service.on_pip_health_zero(Vector2.ZERO)
	assert_signal_emitted(_service, &"pip_retreated", 1, "he yelps and goes")
	assert_eq(_service.state(), PipService.State.RETREATED)
	assert_eq(_service.phase(), PipService.Phase.OUTBOUND, "out of the fight first")
	_service.report_arrived()
	assert_eq(_service.phase(), PipService.Phase.WORKING, "then he shakes it off")
	assert_almost_eq(_service.work_seconds_left(), _rules.retreat_cooldown_seconds, 0.0001)
	_tick_frames(_frames_in(_rules.retreat_cooldown_seconds) - 2)
	assert_signal_emitted(_service, &"pip_returned", 0, "and stays gone for the whole cooldown")
	assert_eq(_service.state(), PipService.State.RETREATED)
	_tick_frames(4)
	assert_eq(_service.phase(), PipService.Phase.RETURNING, "then he comes back")
	_service.report_arrived()
	assert_signal_emitted(_service, &"pip_returned", 1)
	assert_eq(_service.state(), PipService.State.FOLLOWING, "back at the Fool's heel, whole")


func test_a_retreat_runs_away_from_the_nearest_enemy() -> void:
	var combat := _combat()
	var near := _combatant(Vector2(100, 0))
	var far := _combatant(Vector2(-900, 0))
	combat.enemy_engaged(near)
	combat.enemy_engaged(far)
	var service := _service_over(combat)
	service.on_pip_health_zero(Vector2.ZERO)
	var point := service.retreat_point()
	assert_almost_eq(
		point.distance_to(Vector2.ZERO), _rules.retreat_distance, 0.5, "he goes the whole way out"
	)
	assert_true(point.x < 0.0, "and directly away from the one that is on top of him")


func test_a_retreat_with_nothing_to_run_from_stays_put() -> void:
	var combat := _combat()
	var service := _service_over(combat)
	service.on_pip_health_zero(Vector2(50, 50))
	assert_eq(
		service.retreat_point(),
		Vector2(50, 50),
		"a Pip put to zero by nothing in particular shakes it off where he stands"
	)


func test_a_retreat_lets_go_of_whatever_he_was_harrying() -> void:
	var enemy := _thing(Vector2(200, 0))
	watch_signal(_service, &"harry_ended")
	_command(PipCommand.Id.HARRY, enemy)
	_service.report_arrived()
	_service.on_pip_health_zero(Vector2.ZERO)
	assert_signal_emitted(
		_service, &"harry_ended", 1, "nothing is left harried by a dog who has left"
	)
	assert_eq(_service.state(), PipService.State.RETREATED)


func test_a_second_zero_while_already_out_changes_nothing() -> void:
	watch_signal(_service, &"pip_retreated")
	_service.on_pip_health_zero(Vector2.ZERO)
	_service.report_arrived()
	_service.on_pip_health_zero(Vector2.ZERO)
	assert_signal_emitted(_service, &"pip_retreated", 1, "he only leaves once")
	assert_eq(_service.phase(), PipService.Phase.WORKING, "and his cooldown is not restarted")


# --- The defeat beat -----------------------------------------------------------------


func test_the_fool_going_down_sends_pip_over() -> void:
	var combat := _combat()
	var service := _service_over(combat)
	# `combat.md` §Defeat, 2 is invariant across the whole game, so the beat hangs on
	# the fight rather than on each region remembering to stage it.
	combat.fool_defeated.emit(1, 0)
	assert_eq(service.state(), PipService.State.DEFEAT_BEAT)
	assert_eq(service.phase(), PipService.Phase.RETURNING, "he trots to the Fool")
	service.report_arrived()
	assert_eq(service.phase(), PipService.Phase.NONE, "and stays there")
	assert_eq(service.state(), PipService.State.DEFEAT_BEAT, "the beat holds until they are up")
	combat.fool_revived.emit()
	assert_eq(service.state(), PipService.State.FOLLOWING, "then he is beside them again")


func test_the_defeat_beat_drops_whatever_pip_was_doing() -> void:
	var combat := _combat()
	var service := _service_over(combat)
	var enemy := _thing(Vector2(200, 0))
	watch_signal(service, &"harry_ended")
	service.command(PipCommand.Id.HARRY, {PipService.CONTEXT_TARGET: enemy})
	service.report_arrived()
	combat.fool_defeated.emit(1, 0)
	assert_signal_emitted(service, &"harry_ended", 1, "the pin ends when the Fool goes down")
	assert_eq(service.state(), PipService.State.DEFEAT_BEAT)
	assert_eq(service.active_command(), PipCommand.NONE)


# --- A target that stops existing mid-errand ---------------------------------------


func test_a_hidden_thing_freed_mid_dig_aborts_instead_of_emitting_it() -> void:
	# The blocking one. `seek_found` carries the node, and a scene may free it while
	# Pip has his nose in it - an enemy pool recycles, a region unloads, a prop is
	# despawned by the quest that owned it. Emitting a freed object is an engine error
	# thrown by a dog doing exactly what he was told.
	var hole := _thing(Vector2(0, 200))
	watch_signal(_service, &"seek_found")
	watch_signal(_service, &"command_aborted")
	watch_signal(_service, &"command_completed")
	# A listener that USES what it is handed, exactly as `PipCompanion._on_seek_found`
	# does. `watch_signal` alone would record a freed object quite happily and prove
	# nothing: it is the cast in here that the engine logs `Attempt to use a freed
	# object` for, and `tests/run_all.sh` fails the whole stage on that line.
	_service.seek_found.connect(_reveal_like_the_companion_does)
	_command(PipCommand.Id.SEEK, hole)
	_service.report_arrived()
	assert_eq(_service.phase(), PipService.Phase.WORKING, "he is digging")
	hole.free()
	_tick_frames(_frames_in(_rules.seek_reveal_seconds) + 4)
	assert_signal_emitted(_service, &"seek_found", 0, "nothing is found, because nothing is there")
	assert_signal_emitted(_service, &"command_aborted", 1, "the errand is called off")
	assert_eq(
		signal_arguments(_service, &"command_aborted", 0),
		[int(PipCommand.Id.SEEK)],
		"and says which command went"
	)
	assert_eq(_service.phase(), PipService.Phase.RETURNING, "and he comes home anyway")
	assert_eq(_service.active_command(), PipCommand.NONE)
	assert_null(_service.target())
	_service.report_arrived()
	assert_eq(_service.state(), PipService.State.FOLLOWING, "back at the Fool's heel")
	assert_signal_emitted(
		_service, &"command_completed", 0, "and nothing was completed, so nothing says it was"
	)


func test_an_enemy_freed_while_pip_runs_at_it_is_never_told_it_was_harried() -> void:
	var enemy := _thing(Vector2(400, 0))
	watch_signal(_service, &"harry_started")
	watch_signal(_service, &"harry_ended")
	watch_signal(_service, &"command_aborted")
	_command(PipCommand.Id.HARRY, enemy)
	enemy.free()
	_service.report_arrived()
	assert_signal_emitted(_service, &"harry_started", 0, "a freed enemy is never pinned")
	assert_signal_emitted(
		_service, &"harry_ended", 0, "and a pin that never began is never reported as ending"
	)
	assert_signal_emitted(_service, &"command_aborted", 1)
	assert_eq(_service.phase(), PipService.Phase.RETURNING)


func test_an_item_freed_on_the_way_home_is_never_delivered() -> void:
	var item := _thing(Vector2(300, 0))
	watch_signal(_service, &"fetch_delivered")
	watch_signal(_service, &"command_completed")
	watch_signal(_service, &"command_aborted")
	_command(PipCommand.Id.FETCH, item)
	_service.report_arrived()
	assert_eq(_service.phase(), PipService.Phase.RETURNING, "he has it and is trotting back")
	item.free()
	_service.report_arrived()
	assert_signal_emitted(_service, &"fetch_delivered", 0, "there is nothing to put at their feet")
	assert_signal_emitted(_service, &"command_completed", 0, "so the Fetch did not complete")
	assert_signal_emitted(_service, &"command_aborted", 1)
	assert_eq(
		signal_arguments(_service, &"command_aborted", 0),
		[int(PipCommand.Id.FETCH)],
		"it was the Fetch that went"
	)
	assert_eq(_service.state(), PipService.State.FOLLOWING, "and he is back at the heel regardless")


func test_an_arrival_that_picked_nothing_up_aborts_the_fetch() -> void:
	# `PipCompanion` passes false when `Fetchable.take()` refused: the thing the scene
	# offered was already carried, already delivered, or was never a `Fetchable` at
	# all. A dog cannot bring back what would not go in his mouth.
	var item := _thing(Vector2(300, 0))
	watch_signal(_service, &"fetch_delivered")
	watch_signal(_service, &"command_aborted")
	watch_signal(_service, &"command_completed")
	_command(PipCommand.Id.FETCH, item)
	_service.report_arrived(false)
	assert_signal_emitted(_service, &"command_aborted", 1)
	assert_eq(_service.phase(), PipService.Phase.RETURNING, "he turns round empty-mouthed")
	_service.report_arrived()
	assert_signal_emitted(_service, &"fetch_delivered", 0, "and delivers nothing at all")
	assert_signal_emitted(_service, &"command_completed", 0)
	assert_eq(_service.state(), PipService.State.FOLLOWING)


func test_a_failed_arrival_never_interrupts_the_shake_off() -> void:
	# There is no command running during a retreat, so a false arrival cannot abort
	# one: the cooldown starts exactly as it would have.
	_service.on_pip_health_zero(Vector2.ZERO)
	_service.report_arrived(false)
	assert_eq(_service.phase(), PipService.Phase.WORKING, "he shakes it off out there")
	assert_almost_eq(_service.work_seconds_left(), _rules.retreat_cooldown_seconds, 0.0001)


# --- Letting go of the fight ----------------------------------------------------------


func test_a_detached_service_no_longer_hears_the_fool_go_down() -> void:
	var combat := _combat()
	var service := _service_over(combat)
	service.detach()
	combat.fool_defeated.emit(1, 0)
	assert_eq(
		service.state(),
		PipService.State.FOLLOWING,
		"a service nobody is driving any more does not stage a defeat beat"
	)
	combat.fool_revived.emit()
	assert_eq(service.state(), PipService.State.FOLLOWING, "nor answer the waking")
	service.detach()
	assert_eq(service.state(), PipService.State.FOLLOWING, "and detaching twice is not an error")


func test_detaching_leaves_the_commands_working() -> void:
	var combat := _combat()
	var service := _service_over(combat)
	service.detach()
	var hole := _thing(Vector2(0, 200))
	assert_true(
		service.command(PipCommand.Id.SEEK, {PipService.CONTEXT_TARGET: hole}),
		"the dog still takes a command; he simply has no fight to read"
	)
	service.begin_defeat_beat()
	assert_eq(
		service.state(),
		PipService.State.DEFEAT_BEAT,
		"and a scene can still stage the beat itself"
	)


# --- Housekeeping ---------------------------------------------------------------------


func test_a_negative_delta_never_runs_a_timer_backwards() -> void:
	var hole := _thing(Vector2(0, 200))
	_command(PipCommand.Id.SEEK, hole)
	_service.report_arrived()
	var left := _service.work_seconds_left()
	_service.tick(-10.0)
	_service.tick(-1.0)
	assert_almost_eq(_service.work_seconds_left(), left, 0.0001)


func test_reset_puts_him_back_to_the_fools_heel_silently() -> void:
	var enemy := _thing(Vector2(200, 0))
	_command(PipCommand.Id.HARRY, enemy)
	_service.report_arrived()
	watch_signal(_service, &"command_completed")
	watch_signal(_service, &"pip_returned")
	_service.reset()
	assert_eq(_service.state(), PipService.State.FOLLOWING)
	assert_eq(_service.phase(), PipService.Phase.NONE)
	assert_signal_emitted(_service, &"command_completed", 0, "a reset is not a job finished")
	assert_signal_emitted(_service, &"pip_returned", 0, "nor a return from anywhere")


func test_an_arrival_with_nothing_to_arrive_at_is_ignored() -> void:
	watch_signal(_service, &"command_completed")
	_service.report_arrived()
	assert_eq(_service.state(), PipService.State.FOLLOWING)
	assert_signal_emitted(_service, &"command_completed", 0)


func test_the_radius_a_scene_is_told_comes_from_the_rules() -> void:
	assert_almost_eq(_service.command_radius(PipCommand.Id.SEEK), _rules.seek_radius, 0.0001)
	assert_almost_eq(_service.command_radius(PipCommand.Id.HARRY), _rules.command_radius, 0.0001)


# --- Helpers ---------------------------------------------------------------------------


## Give a command with `target` under the documented context key.
func _command(command: int, target: Node2D) -> bool:
	return _service.command(command, {PipService.CONTEXT_TARGET: target})


## Feed the service `frames` physics frames of in-game time at 60 Hz. Frames rather
## than seconds on purpose: a timer asserted against a float sum of deltas is a test
## that fails on the last decimal place rather than on the behaviour.
func _tick_frames(frames: int) -> void:
	for _frame: int in maxi(0, frames):
		_service.tick(FRAME)


## How many whole 60 Hz frames fit inside `seconds`.
func _frames_in(seconds: float) -> int:
	return int(floorf(seconds / FRAME))


## A bare `Node2D` standing in for an item, an enemy or a hidden thing.
func _thing(at: Vector2) -> Node2D:
	var node := Node2D.new()
	node.global_position = at
	_things.append(node)
	return node


## A `Combatant` standing in for an enemy in the fight.
func _combatant(at: Vector2) -> Combatant:
	var node := Combatant.new()
	node.faction = Faction.Id.BLANK
	node.global_position = at
	_things.append(node)
	return node


## What the companion does with `seek_found`: cast it and tell it it was found. Here so
## the freed-target test has a listener that really touches the node it is handed.
func _reveal_like_the_companion_does(target: Node2D) -> void:
	var seekable := target as Seekable
	if seekable != null:
		seekable.reveal()


## A `CombatService` with only the parts a Pip needs: the roster and the defeat loop.
func _combat() -> CombatService:
	return CombatService.new(load(COMBAT_RULES_PATH) as CombatRules, null, null, null, null)


## A service built over a fight, remembered so `after_each` detaches it again.
func _service_over(combat: CombatService) -> PipService:
	var service := PipService.new(_rules, combat)
	_attached.append(service)
	return service
