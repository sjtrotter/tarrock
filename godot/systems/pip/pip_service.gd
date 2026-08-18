class_name PipService
extends RefCounted

## What Pip is doing, and the one rule that matters: **Pip cannot die.**
##
## `docs/design/combat.md` §Pip - "If reduced to zero health he yelps, retreats out of
## the fight, shakes it off, and returns after a short cooldown. This is not a
## difficulty concession - it is canon". So there is no method here that ends him, no
## signal here that says he ended, and `on_pip_health_zero()` is a *departure*: it
## starts a retreat, a cooldown and a return, and `tests/unit/pip/pip_no_death_test.gd`
## reflects over this whole folder to prove no word for dying ever appears in it.
##
## It is the MODE, not the movement. Following the Fool is `scripts/pip_follower.gd`'s
## and always was; running an errand is a destination and a phase, and `PipCompanion`
## is what walks Pip to it. This service holds:
##
##   * which command is running (`State`), and how far through it Pip is (`Phase`);
##   * the timers - the dig, the pin, the shake-off - counted in in-game seconds;
##   * the refusals, so a command that cannot happen says why instead of half-happening.
##
## **Phases are the same three for every command**, which is what keeps the companion
## simple: `OUTBOUND` (run to the thing), `WORKING` (do the thing, for as long as
## `PipRules.work_seconds_for()` says), `RETURNING` (come back to the Fool). Fetch's
## work is nothing at all - a pickup is a mouthful, not a job - so it goes straight
## from arriving to carrying.
##
## **A target can stop existing mid-errand**, and that is ordinary rather than
## exceptional: the enemy Pip was sent at is defeated and goes back to its pool, the
## item is picked up by something else, the region unloads around him. Every signal
## here that carries the target checks `is_instance_valid` first and the errand is
## ABORTED instead - `command_aborted`, then the trot home - because a freed node
## handed to a listener is an engine error thrown by a dog doing his job.
##
## It has no tree and no nodes of its own: a headless test builds it with
## `PipService.new(rules, combat)` and drives it frame by explicit frame, exactly as
## `CombatService` and `BlankBrain` are driven.

## Pip's mode. `FOLLOWING` is the whole of ordinary life; everything else is
## temporary, and everything else comes back to `FOLLOWING`.
enum State {
	## At the Fool's heel. `pip_follower.gd` owns what that looks like.
	FOLLOWING,
	## Running an item down and bringing it back.
	FETCHING,
	## Pinning one enemy: holding its attention off the Fool.
	HARRYING,
	## Working at something hidden nearby.
	SEEKING,
	## Put to zero and out of the fight, until the cooldown is up. NOT a death.
	RETREATED,
	## The Fool is down and Pip is going over to sort it out (`combat.md` §Defeat, 2).
	DEFEAT_BEAT,
}

## How far through the job Pip is.
enum Phase {
	## Nothing to do, or the job is finished.
	NONE,
	## On the way to the thing.
	OUTBOUND,
	## At the thing, doing it.
	WORKING,
	## On the way back to the Fool.
	RETURNING,
}

## Pip was asked to do something and has set off. Carries the command.
signal command_issued(command: PipCommand.Id)

## He has done it and is back. Carries the command.
signal command_completed(command: PipCommand.Id)

## The errand ended because the thing it was about stopped existing while Pip was
## mid-job: the item was picked up by something else and freed, the enemy was defeated
## and returned to its pool, the hidden thing's region was unloaded around him.
##
## Pip turns round and comes home, and `command_completed` deliberately never arrives -
## nothing was completed. A listener that is counting errands wants both signals; one
## that is waiting for a delivery wants only the completion.
signal command_aborted(command: PipCommand.Id)

## He was asked and did not go, with the reason - one of the `REASON_*` constants.
signal command_refused(command: PipCommand.Id, reason: StringName)

## He was put to zero and has left the fight. `combat.md` §Pip: a yelp and a retreat.
## The presentation hook for the yelp, and never a death.
signal pip_retreated()

## The cooldown is up and he is back beside the Fool, shaken off and whole again.
signal pip_returned()

## The hidden thing has been found. Emitted at the hole, the moment the dig finishes -
## Pip trots it back afterwards, which is `command_completed` a few seconds later.
signal seek_found(target: Node2D)

## The fetched item is at the Fool's feet.
signal fetch_delivered(item: Node2D)

## Pip has reached the enemy and taken its attention. What the enemy's brain is told
## about, so it looks at the dog instead of the Fool.
signal harry_started(target: Node2D)

## The pin is over, however it ended: the timer, a new command, or a retreat. Always
## emitted before Pip stops harrying, so nothing is left harried by a dog who left.
signal harry_ended()

## Pip's mode changed.
signal state_changed(from: State, to: State)

## Refused because Pip is out of the fight shaking it off. The one refusal `combat.md`
## really states: he is gone until the cooldown is up.
const REASON_RETREATED := &"RETREATED"

## Refused because the Fool is down and Pip has a face to lick (`combat.md` §Defeat).
const REASON_DEFEAT_BEAT := &"DEFEAT_BEAT"

## Refused because nothing was offered to Fetch, Harry or Seek: no item within reach,
## no enemy locked, no hidden thing near enough.
const REASON_NO_TARGET := &"NO_TARGET"

## Refused because the id was not one of the three commands.
const REASON_UNKNOWN_COMMAND := &"UNKNOWN_COMMAND"

## The key the caller of `command()` puts the target under.
const CONTEXT_TARGET := &"target"

## The numbers. Never null after a successful `_init`.
var _rules: PipRules = null

## The fight, for the two things Pip's mode really does depend on: which enemies are
## engaged (so a retreat runs away from one rather than in a random direction), and
## whether the Fool is down (so the defeat beat is invariant across the whole game
## rather than something each region scene remembers to stage).
var _combat: CombatService = null

var _state: State = State.FOLLOWING
var _phase: Phase = Phase.NONE
var _state_seconds: float = 0.0

## The command being carried out, or `PipCommand.NONE`.
var _command: int = PipCommand.NONE

## What it is being carried out on: the item, the enemy, the hidden thing.
var _target: Node2D = null

## Seconds left of the `WORKING` phase.
var _work_left: float = 0.0

## Where Pip is heading when he leaves a fight, solved once when he is put to zero.
var _retreat_point: Vector2 = Vector2.ZERO

## True only between `harry_started` and `harry_ended`, so a pin that never began
## cannot be reported as ending - a Harry dropped while Pip was still running at the
## enemy told nobody anything, and must not now.
var _harry_active: bool = false


## Build the service over the tuning table and the fight.
##
## `combat` may be null for a scene with no fighting in it: everything here still
## works, a retreat simply has nothing to run away from and the defeat beat has
## nothing to trigger it.
func _init(rules: PipRules, combat: CombatService = null) -> void:
	_rules = rules
	if rules == null:
		push_error("PipService was built without a rules table")
	_combat = combat
	if combat == null:
		return
	combat.fool_defeated.connect(_on_fool_defeated)
	combat.fool_revived.connect(_on_fool_revived)


# --- Reading ------------------------------------------------------------------


## The numbers Pip runs on.
func rules() -> PipRules:
	return _rules


## What Pip is doing.
func state() -> State:
	return _state


## How long he has been doing it, in in-game seconds.
func state_seconds() -> float:
	return _state_seconds


## How far through the job he is.
func phase() -> Phase:
	return _phase


## The command running, or `PipCommand.NONE`.
func active_command() -> int:
	return _command


## What the running command is being carried out on, or `null`.
func target() -> Node2D:
	return _target


## Seconds left of the current `WORKING` phase; 0 in every other phase.
func work_seconds_left() -> float:
	return _work_left


## Where Pip runs to when he leaves a fight. Only meaningful while `RETREATED`.
func retreat_point() -> Vector2:
	return _retreat_point


## True when `command` could be given right now.
##
## `combat.md` §Pip puts the one bar here: a Pip who has been put to zero is out of
## the fight until his cooldown is up, and nothing reaches him out there. The defeat
## beat is the other: the Fool is on the ground and Pip has one job.
func is_available(command: int) -> bool:
	if not PipCommand.is_valid(command):
		return false
	return _state != State.RETREATED and _state != State.DEFEAT_BEAT


## How far away a target for `command` may be, from the rules table. What the scene
## searching for one is told, so the range rule lives here and the search does not.
func command_radius(command: int) -> float:
	if _rules == null:
		return 0.0
	return _rules.radius_for(command)


# --- Being driven ---------------------------------------------------------------


## Ask Pip for something. Returns true only when he set off.
##
## `context` carries the thing the command is about under `CONTEXT_TARGET`: the item
## for Fetch, the enemy for Harry, the hidden thing for Seek. Finding it is the
## SCENE's job - systems never search a scene (`docs/design/technical.md`
## §Architecture principles (Godot), 5) - and `PipCompanion.target_requested` is how
## the scene is asked.
##
## A command given while another is running replaces it: a dog obeys the newest thing
## said to him, and the old errand is simply dropped (its `command_completed` never
## arrives, which is the honest report of what happened).
func command(command_id: int, context: Dictionary) -> bool:
	if not PipCommand.is_valid(command_id):
		command_refused.emit(command_id, REASON_UNKNOWN_COMMAND)
		return false
	if _state == State.RETREATED:
		command_refused.emit(command_id, REASON_RETREATED)
		return false
	if _state == State.DEFEAT_BEAT:
		command_refused.emit(command_id, REASON_DEFEAT_BEAT)
		return false
	var wanted: Node2D = null
	if context.has(CONTEXT_TARGET):
		wanted = context[CONTEXT_TARGET] as Node2D
	if wanted == null or not is_instance_valid(wanted):
		command_refused.emit(command_id, REASON_NO_TARGET)
		return false
	_release_harry()
	_command = command_id
	_target = wanted
	_work_left = 0.0
	_enter(_state_for(command_id), Phase.OUTBOUND)
	command_issued.emit(command_id)
	return true


## Pip has reached whatever the current phase was walking him to.
##
## `PipCompanion` is what decides that - it is the thing that knows where Pip's feet
## are - and this is what the arrival MEANS. Ignored when there is nothing to arrive
## at.
##
## `reached_the_thing` is false when Pip got there and there was nothing to do it to:
## the item would not go in his mouth, because something else already has it or
## because what the scene offered was never a `Fetchable` at all. The errand is
## aborted rather than half-run - see `command_aborted`.
func report_arrived(reached_the_thing: bool = true) -> void:
	if _state == State.DEFEAT_BEAT:
		# He has reached the Fool. The lick is `PipCompanion`'s to play; the mode holds
		# until the Fool is back on their feet (`combat.md` §Defeat, 3).
		_phase = Phase.NONE
		return
	match _phase:
		Phase.OUTBOUND:
			if not reached_the_thing and PipCommand.is_valid(_command):
				_abort()
				return
			_begin_work()
		Phase.RETURNING:
			_finish()
		_:
			pass


## Run one frame. `delta` is in-game seconds, so a slowed world (Fool's Chance) slows
## Pip's dig and his cooldown with everything else in it.
func tick(delta: float) -> void:
	var step := maxf(0.0, delta)
	_state_seconds += step
	if _phase != Phase.WORKING:
		return
	_work_left -= step
	if _work_left > 0.0:
		return
	_work_left = 0.0
	_end_work()


## Pip's health pool emptied. He yelps, leaves the fight, and comes back.
##
## `at` is where he was standing, so the retreat is really *away* from the nearest
## enemy rather than in whatever direction the code happened to pick. NOT a death,
## and there is deliberately no method here that is one.
func on_pip_health_zero(at: Vector2 = Vector2.ZERO) -> void:
	if _state == State.RETREATED:
		return
	_release_harry()
	_command = PipCommand.NONE
	_target = null
	_retreat_point = _solve_retreat_point(at)
	_work_left = 0.0
	_enter(State.RETREATED, Phase.OUTBOUND)
	pip_retreated.emit()


## Start `combat.md` §Defeat's second beat: Pip goes over to the fallen Fool.
##
## Called by this service when `CombatService` reports the Fool down, and callable by
## a scene that STAGES a defeat rather than losing one (`PipCompanion.play_defeat_beat`).
## Whatever Pip was doing is dropped: a dog with a job and a Fool on the ground picks
## the Fool.
func begin_defeat_beat() -> void:
	if _state == State.DEFEAT_BEAT:
		return
	_release_harry()
	_command = PipCommand.NONE
	_target = null
	_work_left = 0.0
	_enter(State.DEFEAT_BEAT, Phase.RETURNING)


## Let go of the fight this service was built over.
##
## `_init` connects to `CombatService.fool_defeated` and `fool_revived`, and a
## `CombatService` outlives any one Pip: a scene torn down, a test that built its own
## service, a region swapped out. Without this the connections keep the dead service
## alive and a later defeat drives a Pip nobody is drawing any more - two Pips reacting
## to one Fool going down, and only one of them on screen.
##
## The service still works afterwards; it simply has no fight to read. A retreat has
## nothing to run away from and the defeat beat has to be staged by the scene
## (`begin_defeat_beat()`), which is exactly the `combat == null` case `_init`
## documents.
func detach() -> void:
	if _combat == null:
		return
	if _combat.fool_defeated.is_connected(_on_fool_defeated):
		_combat.fool_defeated.disconnect(_on_fool_defeated)
	if _combat.fool_revived.is_connected(_on_fool_revived):
		_combat.fool_revived.disconnect(_on_fool_revived)
	_combat = null


## Put Pip back to ordinary life, wherever he was: what a region change and a fresh
## save both want. Emits nothing - it is not a return from anywhere, it is a reset.
func reset() -> void:
	_release_harry()
	_command = PipCommand.NONE
	_target = null
	_work_left = 0.0
	_harry_active = false
	_retreat_point = Vector2.ZERO
	_state = State.FOLLOWING
	_phase = Phase.NONE
	_state_seconds = 0.0


# --- Internals -------------------------------------------------------------------


## Which mode a command puts Pip in.
func _state_for(command_id: int) -> State:
	match command_id:
		PipCommand.Id.FETCH:
			return State.FETCHING
		PipCommand.Id.HARRY:
			return State.HARRYING
	return State.SEEKING


## Pip is at the thing. Fetch has no work to do; the rest start their timer.
func _begin_work() -> void:
	if _state == State.RETREATED:
		_work_left = 0.0 if _rules == null else _rules.retreat_cooldown_seconds
		_phase = Phase.WORKING
		return
	if not _target_is_there():
		# It went while he was running at it. Nothing to dig, nothing to pin, nothing
		# to pick up - and nothing may be told about a thing that is not there.
		_abort()
		return
	var seconds := 0.0 if _rules == null else _rules.work_seconds_for(_command)
	if seconds <= 0.0:
		_phase = Phase.RETURNING
		return
	_work_left = seconds
	_phase = Phase.WORKING
	if _state == State.HARRYING:
		_harry_active = true
		harry_started.emit(_target)


## The timer ran out on whatever Pip was doing at the thing.
func _end_work() -> void:
	if _state == State.SEEKING:
		if not _target_is_there():
			# The hole stopped existing under him. There is no `seek_found(null)` to
			# emit: a listener would dereference it and the engine would log an error
			# for something that is simply an errand that ended.
			_abort()
			return
		seek_found.emit(_target)
	elif _state == State.HARRYING:
		_release_harry()
	_phase = Phase.RETURNING


## Pip is back at the Fool with the job behind him.
func _finish() -> void:
	var finished := _command
	var carried := _target
	_command = PipCommand.NONE
	_target = null
	_work_left = 0.0
	var was := _state
	_enter(State.FOLLOWING, Phase.NONE)
	if was == State.RETREATED:
		pip_returned.emit()
		return
	if was == State.FETCHING and not (carried != null and is_instance_valid(carried)):
		# Whatever was in his teeth stopped existing on the way home. He is back and
		# empty-mouthed: that is an abort, not a delivery, and nothing is handed a
		# freed item to put at the Fool's feet.
		if PipCommand.is_valid(finished):
			command_aborted.emit(finished)
		return
	if was == State.FETCHING:
		fetch_delivered.emit(carried)
	if PipCommand.is_valid(finished):
		command_completed.emit(finished)


## Give up on the errand and come home, because the thing it was about is not there
## any more.
##
## The MODE is kept - he is still the dog who was sent for something - so `RETURNING`
## walks him back exactly as a finished errand does, and `_finish()` then reports
## nothing, because `_command` is already `NONE` by the time he arrives.
## `command_aborted` is the one announcement, and it carries the command that went.
func _abort() -> void:
	var dropped := _command
	_release_harry()
	_command = PipCommand.NONE
	_target = null
	_work_left = 0.0
	_phase = Phase.RETURNING
	if PipCommand.is_valid(dropped):
		command_aborted.emit(dropped)


## True when there is still something to carry the command out on.
##
## A `Node2D` that has been freed is not null - it is a dangling reference that reads
## as one only through `is_instance_valid`, and emitting it would hand every listener
## a freed object. Every signal here that carries a target goes through this first.
func _target_is_there() -> bool:
	return _target != null and is_instance_valid(_target)


## Stop harrying, once, whatever the reason. Nothing may be left harried by a dog who
## has gone somewhere else.
func _release_harry() -> void:
	if not _harry_active:
		return
	_harry_active = false
	harry_ended.emit()


## Directly away from the nearest enemy in the fight, `retreat_distance` out.
##
## With nothing engaged there is nothing to retreat from, and Pip shakes it off where
## he stands - which is the right answer for a Pip put to zero by a trap or by a
## fight that ended around him.
func _solve_retreat_point(from: Vector2) -> Vector2:
	if _rules == null or _combat == null:
		return from
	var nearest_distance := INF
	var nearest_position := Vector2.ZERO
	var found := false
	for enemy: Combatant in _combat.engaged():
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := from.distance_to(enemy.global_position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_position = enemy.global_position
		found = true
	if not found:
		return from
	var away := from - nearest_position
	if away.is_zero_approx():
		away = Vector2.RIGHT
	return from + away.normalized() * _rules.retreat_distance


## The Fool went down. `combat.md` §Defeat, 2: Pip trots over, matter-of-fact, and
## licks the Fool's face - "This is the defeat screen". It is invariant across the
## whole game, so it hangs on the fight rather than on any one region remembering to
## stage it.
func _on_fool_defeated(_defeat_count: int, _at_seconds: int) -> void:
	begin_defeat_beat()


## The Fool woke at the Waystation, "Pip already beside them" (§Defeat, 3).
func _on_fool_revived() -> void:
	if _state != State.DEFEAT_BEAT:
		return
	_enter(State.FOLLOWING, Phase.NONE)


## Move to a mode, resetting its clock and announcing the move.
func _enter(next: State, next_phase: Phase) -> void:
	_phase = next_phase
	_state_seconds = 0.0
	if _state == next:
		return
	var previous := _state
	_state = next
	state_changed.emit(previous, next)
