class_name FoolCombat
extends Node

## The Fool's combat component: the one place buttons, the moveset, the body and the
## services meet.
##
## Everything under it is pure. `MovesetController` has no nodes, `CombatService` has
## no nodes, `FocusTargeting` is handed its candidates. This node is the seam, and it
## is deliberately thin - it reads `InputActions`, fills one reused `CombatInput`,
## drives the controller, swings the `Hitbox` the controller opens, and pushes the
## body around through the small API `scripts/player.gd` exposes. Nothing here decides
## a combat rule.
##
## **Accessibility lives here** (`docs/design/combat.md` §Accessibility): each held
## input - Focus, block-step, the charged heavy, sprint - goes through its own
## `HoldOrToggle`, so the moveset below never learns whether the player is on hold or
## toggle. Remapping needs nothing at all: every action is an `InputActions` constant
## and the bindings live in the InputMap.
##
## **Fool's Chance compensation** is the one clever thing in the file, and it has two
## halves because the Fool has two: while the world is slowed, this node advances the
## MOVESET by `delta / Engine.time_scale`, and hands the BODY the same factor through
## `FoolBody.set_time_compensation()` so its walking and its walk cycle run on the same
## seconds. Compensating only the moveset would give a Fool who rolls at full speed and
## then wades. Together they are "the Fool moves at normal speed relative to a slowed
## world" (`combat.md` §Defense) - and neither the moveset nor the body ever learns
## that slow motion exists.
##
## **Animation is not wired here.** The states the moveset needs clips for are listed
## in `systems/combat/README.md` as an art request; until they land, `player.gd`'s
## animator keeps doing what it already does and this node only tells it which way to
## face. Wiring one animation state per moveset state is a one-function change the day
## the clips exist.
##
## It runs BEFORE the body it belongs to (`process_physics_priority`), so the movement
## multiplier and the dodge displacement it computes apply on the frame they are
## decided rather than the frame after.

## Where the rules live when there is no composition root to ask (a fixture scene run
## on its own, a scene opened in the editor).
const RULES_PATH := "res://data/combat/combat_rules.tres"

## The composition root's node path. Read once, in `_ready`, and never held onto as a
## path: `--check-only` does not know autoloads, so it is resolved defensively.
const SERVICES_PATH := "/root/Services"

## Sorts this node ahead of the `CharacterBody2D` it hangs under.
const PHYSICS_PRIORITY := -10

## How many physics frames the component will look for the composition root before it
## gives up and says so once. Three seconds at 60 Hz: long enough for any autoload
## order, short enough that a fixture scene with no `Services` in it does not spend the
## rest of its life asking. A scene that has no service on purpose (an art capture, a
## spike) is a legitimate case, which is why this is a warning and not an error.
const SERVICE_LOOKUP_FRAMES := 180

## The Fool acquired a Focus target.
signal focus_engaged(target: Node2D)

## Focus was released, or lost its target.
signal focus_released()

var _service: CombatService = null
var _rules: CombatRules = null
var _controller: MovesetController = null
var _focus: FocusTargeting = null
var _defense: FoolDefense = null

var _player: FoolBody = null
var _combatant: Combatant = null
var _hitbox: Hitbox = null
var _hurtbox: Hurtbox = null

## The one input struct, refilled every frame (see `CombatInput`).
var _input: CombatInput = CombatInput.new()

## One per held action (`combat.md` §Accessibility).
var _focus_mode: HoldOrToggle = HoldOrToggle.new()
var _block_mode: HoldOrToggle = HoldOrToggle.new()
var _heavy_mode: HoldOrToggle = HoldOrToggle.new()

## Reused so tapping Focus does not allocate a candidate array every time.
var _candidate_buffer: Array[Node2D] = []

## Whether Focus was engaged last frame, so the edge can be caught without polling.
var _was_focused: bool = false

## Physics frames spent looking for the composition root, and whether the give-up
## warning has already been printed. See `SERVICE_LOOKUP_FRAMES`.
var _service_lookup_frames: int = 0
var _service_lookup_gave_up: bool = false


func _ready() -> void:
	process_physics_priority = PHYSICS_PRIORITY
	_player = get_parent() as FoolBody
	_combatant = _find_combatant()
	_rules = load(RULES_PATH) as CombatRules
	_controller = MovesetController.new(_rules)
	_defense = FoolDefense.new(_controller, null)
	_focus = FocusTargeting.new(_rules.focus_max_range, _rules.focus_cone_weight)
	_wire_body()
	_controller.hit_window_opened.connect(_on_hit_window_opened)
	_controller.hit_window_closed.connect(_on_hit_window_closed)
	_look_for_service()


func _physics_process(delta: float) -> void:
	if _controller == null:
		return
	if _service == null:
		_look_for_service()
	_gather_input()
	_controller.update(_input, delta * _time_compensation())
	_apply_focus()
	_apply_body()


# --- Wiring ------------------------------------------------------------------


## The moveset, for a scene or a test that wants to read what the Fool is doing.
func controller() -> MovesetController:
	return _controller


## The service this component reports to.
func service() -> CombatService:
	return _service


## The Fool's Focus targeting.
func focus() -> FocusTargeting:
	return _focus


## The Fool's own `Combatant`.
func combatant() -> Combatant:
	return _combatant


## Put one held input on hold or on toggle (`combat.md` §Accessibility). The action
## is an `InputActions` constant; anything else is ignored.
func set_hold_mode(action: StringName, mode: HoldOrToggle.Mode) -> void:
	match action:
		InputActions.FOCUS:
			_focus_mode.set_mode(mode)
		InputActions.BLOCK_STEP:
			_block_mode.set_mode(mode)
		InputActions.ATTACK_HEAVY:
			_heavy_mode.set_mode(mode)
		InputActions.SPRINT:
			# Sprint is read by the body, not by this component, so its latch lives
			# there - but a settings screen must not have to know that. It asks this
			# one function for every held input `combat.md` §Accessibility names.
			if _player != null:
				_player.set_sprint_hold_mode(mode)


## The mode a held input is in.
func hold_mode(action: StringName) -> HoldOrToggle.Mode:
	match action:
		InputActions.BLOCK_STEP:
			return _block_mode.mode()
		InputActions.ATTACK_HEAVY:
			return _heavy_mode.mode()
		InputActions.SPRINT:
			return HoldOrToggle.Mode.HOLD if _player == null else _player.sprint_hold_mode()
	return _focus_mode.mode()


# --- The frame ---------------------------------------------------------------


## Fill the reused input struct from the InputMap. The only place this component
## reads a button.
func _gather_input() -> void:
	_input.clear()
	_input.move = Input.get_vector(
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_UP,
		InputActions.MOVE_DOWN
	)
	_input.light_pressed = Input.is_action_just_pressed(InputActions.ATTACK_LIGHT)
	var heavy_down := Input.is_action_pressed(InputActions.ATTACK_HEAVY)
	var heavy_was_held := _heavy_mode.is_held()
	_input.heavy_held = _heavy_mode.update(heavy_down)
	_input.heavy_pressed = _input.heavy_held and not heavy_was_held
	_input.heavy_released = heavy_was_held and not _input.heavy_held
	_input.dodge_pressed = Input.is_action_just_pressed(InputActions.DODGE)
	var block_was_held := _block_mode.is_held()
	_input.block_pressed = _block_mode.update(Input.is_action_pressed(InputActions.BLOCK_STEP)) \
		and not block_was_held
	_input.focus_held = _focus_mode.update(Input.is_action_pressed(InputActions.FOCUS))
	_input.focus_cycle_pressed = Input.is_action_just_pressed(InputActions.FOCUS_CYCLE)
	_input.run_speed_fraction = _speed_fraction()


## What this frame's delta is multiplied by for everything that is the Fool's own.
##
## `combat.md` §Defense: during Fool's Chance "the Fool moves at normal speed relative
## to a slowed world". The engine has already scaled this frame's delta down by
## `Engine.time_scale`, so dividing it back out gives the Fool real seconds while
## everything else in the scene keeps the slowed ones. 1.0 whenever the service says
## the window is shut - which is the only authority on that, so a `time_scale` some
## other system set (a cutscene, a debug key) is NOT compensated for: the Fool is fast
## during Fool's Chance and at no other time.
func _time_compensation() -> float:
	if _service == null or not _service.is_fools_chance_active():
		return 1.0
	return 1.0 / maxf(Engine.time_scale, CombatService.MIN_TIME_SCALE)


## Acquire, hold, cycle and release the Focus lock, and tell the moveset which way the
## target lies so the Fool strafes facing it.
##
## The stance is LIVE, not a snapshot taken when the button went down: the candidate
## list is refreshed on every frame Focus is held, so an enemy that falls or walks out
## of the fight is dropped and the lock moves to whoever is left, and an enemy that
## engages mid-stance can be locked without letting go of Focus first. A player holding
## Focus through a two-Blank fight would otherwise be left aiming at a corpse.
##
## It costs nothing per frame: the refresh walks the service's own engaged array into a
## buffer this node owns and never reallocates, and `FocusTargeting` scores what it is
## given (`technical.md` §Performance guardrails - no per-frame allocation in the
## combat loop).
func _apply_focus() -> void:
	if _focus == null or _player == null:
		return
	if not _input.focus_held and _was_focused:
		_focus.release()
		_controller.clear_focus_target()
		focus_released.emit()
	_was_focused = _input.focus_held
	if not _input.focus_held:
		return
	_refresh_candidates()
	var previous := _focus.target()
	var acquired: Node2D = null
	if _input.focus_cycle_pressed:
		acquired = _focus.cycle(_player.global_position, _controller.facing())
	elif previous == null:
		acquired = _focus.acquire(_player.global_position, _controller.facing())
	# Announced only when the lock really moved: cycling with one enemy left stays put
	# (`FocusTargeting.cycle`), and a stance that re-announced the same target every
	# press would have any listener flashing a fresh lock-on tell for nothing.
	if acquired != null and acquired != previous:
		focus_engaged.emit(acquired)
	var direction := _focus.direction_to_target(_player.global_position)
	if direction.is_zero_approx():
		_controller.clear_focus_target()
		return
	_controller.set_focus_target_dir(direction)


## Push the body around: the Fool's own time, the movement multiplier, the dodge
## displacement, and the facing the Fool should be drawn at.
func _apply_body() -> void:
	if _player == null:
		return
	_player.set_time_compensation(_time_compensation())
	_player.set_movement_multiplier(_controller.movement_multiplier())
	var step := _controller.frame_displacement()
	if not step.is_zero_approx():
		_player.displace(step)
	if _controller.has_focus_target():
		_player.face_direction(_controller.strafe_facing())
	else:
		_controller.set_facing(_player.facing_vector())


## How fast the Fool is already moving, as a fraction of top speed.
func _speed_fraction() -> float:
	return 0.0 if _player == null else _player.speed_fraction()


## Refill the Focus candidate buffer from the enemies the service knows are engaged.
##
## The buffer is reused rather than rebuilt, and this runs on the frame Focus is
## pressed - not every frame - so tapping the stance costs nothing per frame at all.
## Note what is NOT here: any search of the scene. A system never reaches into a
## scene (`docs/design/technical.md`); the enemies announced themselves to
## `CombatService.enemy_engaged()`, and that list is what Focus may lock onto.
func _refresh_candidates() -> void:
	_candidate_buffer.clear()
	if _service == null:
		return
	for enemy: Combatant in _service.engaged():
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive():
			_candidate_buffer.append(enemy)
	_focus.set_candidates(_candidate_buffer)


# --- Swinging ----------------------------------------------------------------


## The moveset opened a hit window: put the real hitbox where the spec says and
## switch it on.
func _on_hit_window_opened(spec: HitSpec) -> void:
	if _hitbox == null:
		return
	_hitbox.activate(spec, _controller.strafe_facing())


## The window closed.
func _on_hit_window_closed() -> void:
	if _hitbox != null:
		_hitbox.deactivate()


## A swing connected. Fortune is earned for a hit that actually landed and not for
## one the target answered (`combat.md` §Fortune in combat: the trickle rewards
## staying in the fight, not swinging at a guard).
func _on_hit_landed(hurtbox: Hurtbox, spec: HitSpec, result: HitResult.Id) -> void:
	if _service == null or not HitResult.was_landed(result):
		return
	_service.on_fool_hit_landed(spec, null if hurtbox == null else hurtbox.combatant())


# --- Setup -------------------------------------------------------------------


## Hand this component the service it reports to. **The preferred wiring**: a scene
## that composes the Fool, and every test that drives one, injects the service rather
## than leaving the component to find it, which is what makes the whole thing testable
## without an autoload layer at all.
func attach_service(service: CombatService) -> void:
	if service == null or _service == service:
		return
	_service = service
	_service_lookup_gave_up = true
	if _defense != null:
		_defense.set_service(service)
	if _combatant != null:
		service.register_fool(_combatant)


## Look for the composition root's `CombatService`, for a scene that injected nothing.
##
## The fallback, not the contract: `attach_service()` is. It is retried from
## `_physics_process` rather than demanded in `_ready`, because a scene's `_ready` can
## run before the autoload layer is up - the same reason `scripts/the_cliff.gd` defers
## its own service lookup by a frame - and the retry is BOUNDED, because a scene with
## no composition root (a fixture, an art capture) would otherwise search the tree
## every frame it ever runs for a node that is never coming. After
## `SERVICE_LOOKUP_FRAMES` it says so once and stops asking.
##
## A private service is deliberately NOT built as a fallback: a second `CombatService`
## that nothing ticks would run Fool's Chance forever and leave the engine slowed.
func _look_for_service() -> void:
	if _service != null or _service_lookup_gave_up:
		return
	_service_lookup_frames += 1
	var root := get_node_or_null(SERVICES_PATH)
	var found: CombatService = null if root == null else root.get(&"combat") as CombatService
	if found != null:
		attach_service(found)
		return
	if _service_lookup_frames < SERVICE_LOOKUP_FRAMES:
		return
	_service_lookup_gave_up = true
	# Said once, then never again: with no service the Fool still swings, dodges and
	# moves, and simply has no fight, no Fortune and no Fool's Chance around them.
	push_warning("%s found no CombatService in %d frames" % [name, SERVICE_LOOKUP_FRAMES])


## Find the Combatant this component belongs to, among the parent's children.
func _find_combatant() -> Combatant:
	if _player == null:
		return null
	for child: Node in _player.get_children():
		var found := child as Combatant
		if found != null:
			return found
	return null


## Hook the body's boxes up: size the hitbox to the widest swing in the rules, point
## both boxes at the Fool's faction, and register the Fool with the service.
func _wire_body() -> void:
	if _combatant == null:
		push_error("FoolCombat found no Combatant beside it; the Fool cannot fight")
		return
	_combatant.faction = Faction.Id.FOOL
	_combatant.defense = _defense
	# Nothing sizes a pool here: the Fool's health is the White Rose's petals (issue
	# #11), and `CombatService.register_fool()` is what points the body at them. Until
	# the service is found, the `max_health` authored on `scenes/fool.tscn` stands in -
	# three petals' worth of quarters, so a fixture scene with no services in it is a
	# Fool of the right size rather than an invincible one.
	for child: Node in _combatant.get_children():
		var hitbox := child as Hitbox
		if hitbox != null:
			_hitbox = hitbox
			continue
		var hurtbox := child as Hurtbox
		if hurtbox != null:
			_hurtbox = hurtbox
	if _hurtbox != null:
		_hurtbox.configure(_combatant)
	if _hitbox == null:
		return
	_hitbox.configure(Faction.Id.FOOL, _widest_reach())
	_hitbox.deactivate()
	if not _hitbox.hit_landed.is_connected(_on_hit_landed):
		_hitbox.hit_landed.connect(_on_hit_landed)


## The farthest any of the Fool's swings reaches, which is what the hitbox detector
## is sized to once and for all (see `Hitbox`).
func _widest_reach() -> float:
	if _rules == null:
		return 1.0
	return maxf(
		maxf(_rules.light_radius, _rules.heavy_radius),
		maxf(_rules.charged_heavy_radius, _rules.running_attack_box_size.y)
	)
