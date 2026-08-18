class_name PipCompanion
extends Node

## The seam: buttons -> the wheel -> `PipService` -> Pip's feet.
##
## Exactly the shape `FoolCombat` has for the Fool and `Blank` has for an enemy. It is
## the only thing in `systems/pip/` that reads `Input`, the only thing that touches the
## tree, and the only thing that knows Pip is a node at all - `PipService`, `PipWheel`
## and `PipRules` are all plain objects a headless test builds directly.
##
## It lives beside `scripts/pip_follower.gd` in `scenes/pip.tscn` and drives Pip
## through that script rather than round his back: `set_follow_suspended()` while a
## command is running, `step_toward()` for every pixel. One file owns Pip's legs, and
## it is not this one.
##
## **Scenes call systems, systems never search scenes.** Fetch needs an item, Harry an
## enemy and Seek a hidden thing, and finding one in a region is the region's business.
## So the gesture is: the wheel confirms a command, this node emits `target_requested`
## with Pip's position and the reach `PipRules` allows, and the SCENE answers
## synchronously by calling `provide_target()`. A scene that has nothing to offer says
## nothing, and the command is refused with `PipService.REASON_NO_TARGET` - which is
## the Cliff's answer to Fetch and Harry today, and the right one.
##
## The one reach across a system boundary is Harry: a harried enemy has to be TOLD, and
## the only bodies in the game with a brain to tell are `Blank`s (round 8's
## `Blank.set_distraction()`). It is a deliberate, one-way dependency on a sibling
## system's node type, taken here rather than pushed into every region scene's wiring;
## the day the Beasts and the Fog-masks get bodies, they get the same hook and this
## stays one cast wide.

## Pip needs something to run at, and only the scene knows what. Carries the command,
## where Pip is standing, and how far away a candidate may be. A listener answers by
## calling `provide_target()` before the emission returns.
signal target_requested(command: PipCommand.Id, from: Vector2, radius: float)

## Pip reached the fallen Fool and licked their face - `docs/design/combat.md` §Defeat,
## step 2, "a dog solving a practical problem, exactly as unbothered as ever". The
## presentation hook the UI round hangs the defeat screen on; there is no sound, no
## clip and no fade here, because none of those are this round's.
signal licked()

## The composition root's node path, resolved defensively: `--check-only` does not know
## autoloads (see `FoolCombat.SERVICES_PATH`, same reason, same shape).
const SERVICES_PATH := "/root/Services"

## How many physics frames this node looks for the composition root before giving up
## and saying so once. Three seconds at 60 Hz.
const SERVICE_LOOKUP_FRAMES := 180

## The child of Pip that holds his health pool.
const COMBATANT_NODE := "Combatant"

var _service: PipService = null
var _wheel: PipWheel = null
var _view: PipWheelView = PipWheelView.new()

## Pip's own body, and the script that owns his legs.
var _follower: PipFollower = null

## His health pool. `null` in a stripped-down Pip that cannot be hurt at all.
var _combatant: Combatant = null

## What the scene answered `target_requested` with, for the length of one call.
var _offered_target: Node2D = null

## Which command is being asked about while `target_requested` is out. `PipCommand.NONE`
## the rest of the time, so a late `provide_target()` cannot arm the next command.
var _asking_for: int = PipCommand.NONE

## The item in his teeth, or `null`.
var _carried: Fetchable = null

## The enemy Pip currently has by the ankle, or `null`. Kept rather than re-read off
## the service when the pin ends, so the enemy that is released is always the enemy
## that was told, whatever else happened in between.
var _harried: Blank = null

## Reused for every `PipService.command()` call, so issuing a command allocates nothing.
var _context: Dictionary = {}

var _service_lookup_frames: int = 0
var _service_lookup_gave_up: bool = false


func _ready() -> void:
	_follower = get_parent() as PipFollower
	if _follower == null:
		push_error("%s is not a child of Pip's body and cannot walk him" % name)
		return
	_combatant = _follower.get_node_or_null(COMBATANT_NODE) as Combatant
	if _combatant != null and not _combatant.died.is_connected(_on_health_zero):
		# `Combatant.died` is round 7's name for a pool reaching zero, and its own doc
		# is emphatic that it is not a death: "a Blank slumps and fades, the Fool wakes
		# at a Waystation, Pip retreats and comes back". This is Pip's half of that
		# sentence, and nothing on this side of the wiring is called dying.
		_combatant.died.connect(_on_health_zero)


func _physics_process(delta: float) -> void:
	if _service == null:
		_look_for_service()
		if _service == null:
			return
	_read_wheel(delta)
	_service.tick(delta)
	_walk(delta)
	_carry()
	_view.refresh(_wheel, _service)


# --- Wiring ---------------------------------------------------------------------


## Hand this node the service it runs on. **The preferred wiring**, exactly as
## `FoolCombat.attach_service()` and `Blank.attach_service()` are: the scene injects
## it, so the whole thing is testable with no autoload layer at all.
func attach_service(service: PipService) -> void:
	if service == null or _service == service:
		return
	_disconnect_service()
	_service = service
	_service_lookup_gave_up = true
	var rules := service.rules()
	var dead_zone := PipRules.MIN_WHEEL_DEAD_ZONE
	if rules != null:
		dead_zone = rules.wheel_dead_zone
	_wheel = PipWheel.new(dead_zone)
	service.seek_found.connect(_on_seek_found)
	service.fetch_delivered.connect(_on_fetch_delivered)
	service.command_aborted.connect(_on_command_aborted)
	service.harry_started.connect(_on_harry_started)
	service.harry_ended.connect(_on_harry_ended)
	service.pip_returned.connect(_on_pip_returned)
	if rules != null and _combatant != null:
		_combatant.set_max_health(rules.max_health)


## Answer a `target_requested`: this is what Pip should run at.
##
## Called by the region scene from inside its `target_requested` handler. A second
## answer for the same request wins, so a scene may narrow its own choice; an answer
## for a command nobody asked about is ignored.
func provide_target(command: PipCommand.Id, node: Node2D) -> void:
	if command != _asking_for:
		return
	_offered_target = node


## Give Pip a command, target and all. The door the wheel goes through, and the door a
## UI button, a tutorial prompt or a test uses instead of faking a keypress.
##
## Returns true only when he set off; every refusal is reported by
## `PipService.command_refused` with a reason.
func issue(command: PipCommand.Id) -> bool:
	if _service == null:
		return false
	_asking_for = command
	_offered_target = null
	target_requested.emit(command, _position(), _service.command_radius(command))
	_asking_for = PipCommand.NONE
	_context.clear()
	_context[PipService.CONTEXT_TARGET] = _offered_target
	var issued := _service.command(command, _context)
	_offered_target = null
	return issued


## Play `combat.md` §Defeat's second beat on demand, for a scene that stages a defeat
## rather than losing one.
##
## In an ordinary defeat nothing has to call this: `PipService` hears
## `CombatService.fool_defeated` itself, because the beat is invariant across the whole
## game and a region that forgot to stage it would be a region where the defeat screen
## is missing. There is no position argument on purpose - Pip already knows where the
## Fool is, and a second copy of that fact could be wrong.
func play_defeat_beat() -> void:
	if _service == null:
		return
	_service.begin_defeat_beat()


# --- Reading ---------------------------------------------------------------------


## The service this node drives, or `null` before it was attached.
func service() -> PipService:
	return _service


## The wheel, for a test that wants to drive the gesture directly.
func wheel() -> PipWheel:
	return _wheel


## This frame of the wheel, as the UI round will read it. Refreshed every physics
## frame; never a new object.
func wheel_view() -> PipWheelView:
	return _view


## The item in Pip's teeth, or `null`.
func carried() -> Fetchable:
	return _carried


# --- The frame ---------------------------------------------------------------------


## Read the wheel gesture and issue whatever it confirms.
func _read_wheel(delta: float) -> void:
	if _wheel == null:
		return
	var move := Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_UP,
		InputActions.MOVE_DOWN
	)
	var confirmed := _wheel.update(Input.is_action_pressed(InputActions.PIP_WHEEL), move, delta)
	if confirmed != PipCommand.NONE:
		issue(confirmed)


## Walk Pip wherever the mode and the phase say, and report an arrival when he is
## there. Every step goes through `PipFollower`, which is what owns his legs.
func _walk(delta: float) -> void:
	if _follower == null:
		return
	var state := _service.state()
	if state == PipService.State.FOLLOWING:
		_follower.set_follow_suspended(false)
		return
	_follower.set_follow_suspended(true)
	var phase := _service.phase()
	if phase == PipService.Phase.NONE:
		_follower.hold_still(delta)
		return
	if phase == PipService.Phase.WORKING:
		# At the hole, on the enemy, or out of the fight shaking it off.
		_follower.hold_still(delta)
		return
	var destination := _destination(state, phase)
	var rules := _service.rules()
	var speed := 0.0 if rules == null else rules.command_speed
	var reach := 0.0 if rules == null else rules.command_reach
	if not _follower.step_toward(destination, speed, reach, delta):
		return
	var picked_it_up := true
	if state == PipService.State.FETCHING and phase == PipService.Phase.OUTBOUND:
		# A dog who gets there and cannot pick the thing up has finished the errand,
		# not started it: the item was taken while he ran, or what the scene offered
		# was never a `Fetchable` at all. The service is told so, and aborts.
		picked_it_up = _take(_service.target() as Fetchable)
	var arrived_at_the_fool := state == PipService.State.DEFEAT_BEAT
	_service.report_arrived(picked_it_up)
	if arrived_at_the_fool and _service.phase() == PipService.Phase.NONE:
		licked.emit()
	if _service.state() == PipService.State.FOLLOWING:
		# The errand ended on THIS arrival, so the follow comes back on this frame and
		# not on the next one: a dog who stood still for a frame after every command
		# would be a dog with a stutter.
		_follower.set_follow_suspended(false)


## Where Pip is heading this frame.
func _destination(state: PipService.State, phase: PipService.Phase) -> Vector2:
	if state == PipService.State.RETREATED and phase == PipService.Phase.OUTBOUND:
		return _service.retreat_point()
	if phase == PipService.Phase.OUTBOUND:
		var target := _service.target()
		if target != null and is_instance_valid(target):
			return target.global_position
		return _position()
	return _fool_position()


## Keep a carried item where Pip is. See `Fetchable`'s note on why this is not a
## reparent.
func _carry() -> void:
	if _carried == null or not is_instance_valid(_carried):
		return
	_carried.global_position = _position()


# --- The service's signals ------------------------------------------------------


## The dig finished. `Seekable` is what decides whether a thing may be found twice.
func _on_seek_found(target: Node2D) -> void:
	var seekable := target as Seekable
	if seekable != null:
		seekable.reveal()


## The item is at the Fool's feet.
func _on_fetch_delivered(item: Node2D) -> void:
	var fetchable := item as Fetchable
	_carried = null
	if fetchable != null:
		fetchable.deliver(_fool_position())


## The errand ended because the thing it was about is gone. Whatever Pip thought he
## had, he has not: dropping the reference here is what keeps `_carry()` from writing
## a position onto a freed node for the rest of the scene.
func _on_command_aborted(_command: PipCommand.Id) -> void:
	_carried = null


## Pip has the enemy: tell it so. The one cast across a system boundary - see the
## class doc.
func _on_harry_started(target: Node2D) -> void:
	var blank := target as Blank
	var rules := _service.rules()
	if blank == null or rules == null:
		return
	_harried = blank
	blank.set_distraction(_follower, rules.harry_seconds, rules.harry_telegraph_multiplier)


## The pin is over, however it ended.
func _on_harry_ended() -> void:
	if _harried != null and is_instance_valid(_harried):
		_harried.clear_distraction()
	_harried = null


## The cooldown is up. `combat.md` §Pip: he shook it off, so he is whole again.
func _on_pip_returned() -> void:
	if _combatant != null:
		_combatant.restore_full_health()


## Pip's pool emptied. NOT a death - `combat.md` §Pip is explicit, and this is the one
## line of code that would be a death if the doc said so and does not.
func _on_health_zero() -> void:
	if _service == null:
		return
	_service.on_pip_health_zero(_position())


# --- Internals ---------------------------------------------------------------------


func _position() -> Vector2:
	return Vector2.ZERO if _follower == null else _follower.global_position


## Where the Fool is - from the follower, which already had to know.
func _fool_position() -> Vector2:
	if _follower == null:
		return Vector2.ZERO
	var fool := _follower.target_node()
	if fool == null or not is_instance_valid(fool):
		return _follower.global_position
	return fool.global_position


## Pip has it in his teeth. False when there was nothing to take: not a `Fetchable`,
## already carried, already delivered.
func _take(item: Fetchable) -> bool:
	if item == null or not item.take():
		return false
	_carried = item
	return true


func _disconnect_service() -> void:
	if _service == null:
		return
	_service.seek_found.disconnect(_on_seek_found)
	_service.fetch_delivered.disconnect(_on_fetch_delivered)
	_service.command_aborted.disconnect(_on_command_aborted)
	_service.harry_started.disconnect(_on_harry_started)
	_service.harry_ended.disconnect(_on_harry_ended)
	_service.pip_returned.disconnect(_on_pip_returned)
	_service = null


## Look for the composition root, for a scene that injected nothing. The fallback, not
## the contract - see `attach_service()` and `Blank._look_for_service()`.
func _look_for_service() -> void:
	if _service != null or _service_lookup_gave_up:
		return
	_service_lookup_frames += 1
	var root := get_node_or_null(SERVICES_PATH)
	var found: PipService = null if root == null else root.get(&"pip") as PipService
	if found != null:
		attach_service(found)
		return
	if _service_lookup_frames < SERVICE_LOOKUP_FRAMES:
		return
	_service_lookup_gave_up = true
	push_warning("%s found no PipService in %d frames" % [name, SERVICE_LOOKUP_FRAMES])
