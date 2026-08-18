extends TarrockTest

## The seam node: how it gets its service, and how the Focus stance behaves while it is
## held.
##
## `docs/design/combat.md` §Focus: holding the focus input "locks onto a target when
## enemies are present", and movement becomes "8-direction strafing around that target".
## A stance is a live thing, not a snapshot taken when the button went down - so the
## enemy that falls is dropped, the enemy that engages mid-stance can be locked, and the
## cycle input steps between them without leaving the stance at all.
##
## **The service is injected here rather than found.** `attach_service()` is the
## contract; the `/root/Services` lookup is the fallback for a scene that composed
## nothing, and it is bounded so a fixture with no composition root stops asking.
##
## This suite presses real actions through `Input`, so `after_each` releases every one
## of them: an action left latched would be held for every test that ran afterwards.

const FOOL_SCENE_PATH := "res://scenes/fool.tscn"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## One hand-driven frame.
const STEP := 1.0 / 60.0

## Actions this suite may press, released whatever a test did.
const PRESSED_ACTIONS: Array[StringName] = [InputActions.FOCUS, InputActions.FOCUS_CYCLE]

var _fool: FoolBody = null
var _combat: FoolCombat = null
var _service: CombatService = null
var _enemies: Array[Combatant] = []


func before_each() -> void:
	var packed: PackedScene = load(FOOL_SCENE_PATH) as PackedScene
	_fool = packed.instantiate() as FoolBody
	tree().root.add_child(_fool)
	_fool.global_position = Vector2.ZERO
	_combat = _fool.get_node_or_null("FoolCombat") as FoolCombat
	_service = _build_service()
	if _combat != null:
		_combat.attach_service(_service)


func after_each() -> void:
	for action: StringName in PRESSED_ACTIONS:
		Input.action_release(action)
	for enemy: Combatant in _enemies:
		if enemy != null and is_instance_valid(enemy):
			enemy.get_parent().remove_child(enemy)
			enemy.free()
	_enemies.clear()
	if _fool != null and is_instance_valid(_fool):
		_fool.get_parent().remove_child(_fool)
		_fool.free()
	_fool = null
	_combat = null
	_service = null


# --- Getting a service ----------------------------------------------------------


func test_an_injected_service_is_the_one_the_component_reports_to() -> void:
	if not assert_not_null(_combat):
		return
	assert_true(_combat.service() == _service, "the injected service is the component's")
	assert_true(
		_service.fool() == _combat.combatant(),
		"and injecting it registered the Fool, so the defeat loop has a body to watch"
	)


# --- The Focus stance -------------------------------------------------------------


func test_focus_locks_onto_an_enemy_the_fight_knows_about() -> void:
	if not assert_not_null(_combat):
		return
	var enemy := _engage(Vector2(80.0, 0.0))
	Input.action_press(InputActions.FOCUS)
	_frame()
	assert_true(_combat.focus().target() == enemy, "combat.md: Focus locks on when enemies are present")


func test_an_enemy_that_engages_mid_stance_can_still_be_locked() -> void:
	# The stance is live. Holding Focus through the moment a second Blank walks into
	# the fight must not leave the Fool aiming at nothing until they let go and press
	# again.
	if not assert_not_null(_combat):
		return
	Input.action_press(InputActions.FOCUS)
	_frame()
	assert_null(_combat.focus().target(), "nothing to lock onto yet")
	var latecomer := _engage(Vector2(70.0, 0.0))
	_frame()
	assert_true(_combat.focus().target() == latecomer, "and the stance picks them up")


func test_a_target_that_falls_hands_the_lock_to_whoever_is_left() -> void:
	if not assert_not_null(_combat):
		return
	var near := _engage(Vector2(60.0, 0.0))
	var far := _engage(Vector2(200.0, 0.0))
	Input.action_press(InputActions.FOCUS)
	_frame()
	assert_true(_combat.focus().target() == near, "the nearer one first")
	near.take_hit(_kill_shot())
	assert_false(_service.engaged().has(near), "a fallen enemy leaves the fight by itself")
	_frame()
	assert_true(_combat.focus().target() == far, "and the lock moves to the one still standing")


func test_the_cycle_input_steps_the_lock_without_leaving_the_stance() -> void:
	if not assert_not_null(_combat):
		return
	var near := _engage(Vector2(60.0, 0.0))
	var far := _engage(Vector2(200.0, 0.0))
	Input.action_press(InputActions.FOCUS)
	_frame()
	assert_true(_combat.focus().target() == near)
	Input.action_press(InputActions.FOCUS_CYCLE)
	_frame()
	Input.action_release(InputActions.FOCUS_CYCLE)
	assert_true(_combat.focus().target() == far, "one press, one step round the candidates")
	Input.action_press(InputActions.FOCUS_CYCLE)
	_frame()
	Input.action_release(InputActions.FOCUS_CYCLE)
	assert_true(_combat.focus().target() == near, "and it wraps")


func test_letting_focus_go_releases_the_lock() -> void:
	if not assert_not_null(_combat):
		return
	_engage(Vector2(60.0, 0.0))
	Input.action_press(InputActions.FOCUS)
	_frame()
	assert_true(_combat.focus().has_target())
	Input.action_release(InputActions.FOCUS)
	_frame()
	assert_false(_combat.focus().has_target(), "the stance is optional, and so is the lock")
	assert_false(_combat.controller().has_focus_target())


# --- Helpers -----------------------------------------------------------------------


## One hand-driven physics frame of the component. Called directly rather than waited
## for: a unit test that waited on frame pacing would be testing the engine.
func _frame() -> void:
	_combat._physics_process(STEP)


## A Combatant standing at `where`, engaged in the fight.
func _engage(where: Vector2) -> Combatant:
	var enemy := Combatant.new()
	enemy.faction = Faction.Id.BLANK
	enemy.set_max_health(20)
	tree().root.add_child(enemy)
	enemy.global_position = where
	_enemies.append(enemy)
	_service.enemy_engaged(enemy)
	return enemy


## A hit big enough to empty any of this suite's enemies.
func _kill_shot() -> HitEvent:
	return HitEvent.new(
		Faction.Id.FOOL,
		HitSpec.new(HitSpec.Kind.LIGHT, 100, HitSpec.Shape.ARC, 360.0, 400.0),
		Vector2.ZERO,
		Vector2.RIGHT,
		0.0
	)


## The composition root's service, built by hand exactly as `services.gd` builds it.
func _build_service() -> CombatService:
	var spread_rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var fortune := FortuneService.new(spread_rules)
	return CombatService.new(
		(load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules,
		fortune,
		PocketSpreadService.new(
			world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, spread_rules, fortune
		),
		WhiteRoseService.new(world_state, spread_rules),
		GameClock.new()
	)
