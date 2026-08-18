class_name Blank
extends CharacterBody2D

## A Blank's body: the seam between `BlankBrain` (which decides) and the scene (which
## moves, draws and hits).
##
## `docs/design/combat.md` §Enemies: the Blanks - "a humanoid soldier-figure with a
## blank oval face... each *bears* a card whose face went blank". The card is the
## definition; this is the vessel it raised, and the vessel is reused: a `Blank` is
## pooled (`EnemyPool`), so the same body is a Two of Swords on the Waystation path
## and a Nine of Coins in the Bastion an hour later. That is not only a performance
## rule - it is exactly what the doc says happens, from the card's point of view.
##
## The division of labour is the same one round 7 drew for the Fool:
##
##   * `BlankBrain` decides, with no nodes and no tree.
##   * `Combatant`, `Hurtbox` and `Hitbox` do what they already do; none of them
##     learns what a suit is.
##   * **This** fills a `BlankPerception` from the scene, moves the body, opens the
##     hitbox the brain asked for, throws the lobs, and draws the thing.
##
## It never reaches for a service: `attach_service()` is the contract, exactly as
## `FoolCombat.attach_service()` is, with the same bounded fallback for a fixture
## scene that has no composition root.
##
## **Defeat is not death** (`combat.md`): the pool empties, the body slumps and fades
## while the card flutters free, and `card_fluttered` is what the encounter waits for
## before the body goes back to the pool to be raised by another card. Nothing here
## frees anything and nothing here plays a death.

## The pool emptied and this Blank is out of the fight. Emitted the moment it goes
## down, not when the card leaves: an encounter counts this.
signal defeated(blank: Blank)

## The card has fluttered free of the body. `combat.md`: it drifts "off to raise a new
## bearer elsewhere later". The body may now go back to the pool.
signal card_fluttered(definition: EnemyDefinition, from_position: Vector2)

## This Blank joined the fight.
signal engaged(blank: Blank)

## It lost the Fool and went back to the grass.
signal disengaged(blank: Blank)

## A Page's alarm went up from here.
signal alert_raised(from_position: Vector2)

## The composition root's node path, resolved defensively: `--check-only` does not
## know autoloads (see `FoolCombat.SERVICES_PATH`, same reason, same shape).
const SERVICES_PATH := "/root/Services"

## How many physics frames this body looks for the composition root before giving up
## and saying so once. Three seconds at 60 Hz.
const SERVICE_LOOKUP_FRAMES := 180

## How many lobs one Cups Blank may have in the air at once. Preallocated in `_ready`
## and reused forever; a fourth request while three are flying is simply refused,
## which is a throttle rather than a bug (`EnemyRules` gives Cups a recovery long
## enough that it never comes up).
const PROJECTILES_PER_BLANK := 3

## How long the hit reaction plays after a hit that did not stagger, in seconds. The
## `hit` row is four frames at 8 fps, so this is the clip's own length rather than a
## number anybody chose.
const HIT_REACTION_SECONDS := 0.5

## What this Blank is, or `null` before `configure()`.
var _definition: EnemyDefinition = null

## Its solved numbers.
var _stats: EnemyStats = null

## The state machine that decides everything.
var _brain: BlankBrain = null

## The shield, for a Coins Blank; `null` for everybody else.
var _shield: CoinsShield = null

## The one perception, refilled every physics frame and never reallocated.
var _perception: BlankPerception = BlankPerception.new()

var _combatant: Combatant = null
var _hurtbox: Hurtbox = null
var _hitbox: Hitbox = null
var _sprite: Sprite2D = null
var _animator: CharacterAnimator = null

## The Fool. Set by whoever spawned this Blank; never searched for.
var _target: Node2D = null

## The other Blanks in this encounter, as an array the ENCOUNTER owns. Held by
## reference so counting allies allocates nothing per frame.
var _allies: Array[Blank] = []

var _service: CombatService = null
var _service_lookup_frames: int = 0
var _service_lookup_gave_up: bool = false

## The lobs, preallocated. Empty for a Blank that is not a Cups.
var _projectiles: Array[Projectile] = []

## True while this body is out in the world rather than asleep in a pool.
var _awake: bool = false

## True once this Blank has announced itself to the `CombatService`, so it is
## announced once and withdrawn once.
var _announced: bool = false

## Seconds of hit reaction left.
var _hit_reaction_left: float = 0.0

## The body's own collision layer and mask, kept so sleeping can zero them and waking
## can put them back exactly as the scene authored them.
var _layer_awake: int = 0
var _mask_awake: int = 0


func _ready() -> void:
	_layer_awake = collision_layer
	_mask_awake = collision_mask
	_combatant = get_node_or_null("Combatant") as Combatant
	_sprite = get_node_or_null("Sprite") as Sprite2D
	if _combatant == null:
		push_error("%s has no Combatant, so it cannot be fought" % name)
		return
	_hurtbox = _combatant.get_node_or_null("Hurtbox") as Hurtbox
	_hitbox = _combatant.get_node_or_null("Hitbox") as Hitbox
	if _hurtbox != null:
		_hurtbox.configure(_combatant)
	if _hitbox != null:
		_hitbox.deactivate()
	if not _combatant.died.is_connected(_on_died):
		_combatant.died.connect(_on_died)
	if not _combatant.damaged.is_connected(_on_damaged):
		_combatant.damaged.connect(_on_damaged)
	_ensure_animator()
	_build_projectiles()
	sleep()


func _physics_process(delta: float) -> void:
	if not _awake or _brain == null:
		return
	if _service == null:
		_look_for_service()
	_fill_perception()
	_brain.update(_perception, delta)
	_aim_shield()
	_apply_movement(delta)
	_animate(delta)


# --- Wiring ---------------------------------------------------------------------


## Make this body a particular enemy. Called by the pool on every acquire, so one
## body is a different Blank each time it is raised.
func configure(definition: EnemyDefinition, rules: EnemyRules) -> void:
	if definition == null or rules == null:
		push_error("%s was configured without a definition or without rules" % name)
		return
	_definition = definition
	_stats = definition.stats(rules)
	if _stats == null:
		push_error("%s cannot be a %s: it has no stat block" % [name, definition.id])
		return
	_build_brain()
	if _combatant != null:
		_combatant.faction = definition.faction()
		_combatant.set_max_health(_stats.max_health)
		_combatant.defense = _shield if _shield != null else CombatDefense.new()
	if _hurtbox != null:
		_hurtbox.configure(_combatant)
	if _hitbox != null:
		_hitbox.configure(definition.faction(), _stats.reach())
		_hitbox.deactivate()
	if _sprite != null:
		_sprite.modulate = rules.tint_for_suit(definition.suit_id())
	_configure_projectiles()
	_apply_difficulty()


## Hand this body the service it reports to. **The preferred wiring**, exactly as
## `FoolCombat.attach_service()` is: the encounter that spawned it injects the
## service, so the whole thing is testable with no autoload layer at all.
func attach_service(service: CombatService) -> void:
	if service == null or _service == service:
		return
	_service = service
	_service_lookup_gave_up = true
	_apply_difficulty()


## Point this Blank at the Fool. Set by whoever spawned it; a Blank never searches a
## scene for a target (`docs/design/technical.md` §Architecture principles).
func set_target(target: Node2D) -> void:
	_target = target


## Hand this Blank the array of its fellows. Held by reference and owned by the
## caller, so counting allies costs no allocation per frame.
func set_allies(allies: Array[Blank]) -> void:
	_allies = allies


## Raise this Blank into the world: place it, point it, wake it, engage it.
##
## `docs/quests/main/MQ00-the-leap.md`: "three figures rise from the long grass on
## either side of the path". This is that.
func rise(at: Vector2, facing: Vector2, target: Node2D) -> void:
	global_position = at
	_target = target
	wake()
	if _brain == null:
		return
	_brain.place(at, facing)
	_brain.engage()


## Wake the body without engaging it: visible, colliding, processing, at full health.
func wake() -> void:
	if _combatant != null:
		_combatant.restore_full_health()
	if _brain != null:
		_brain.reset()
	_hit_reaction_left = 0.0
	_awake = true
	_announced = false
	visible = true
	collision_layer = _layer_awake
	collision_mask = _mask_awake
	process_mode = Node.PROCESS_MODE_INHERIT
	# Deferred, always: waking can happen inside a physics callback (an encounter's
	# trigger volume is an `Area2D` signal), and Godot refuses to retune an area's
	# monitoring flags while it is in the middle of reporting an overlap.
	if _hurtbox != null:
		_hurtbox.set_deferred("monitorable", true)
	if _hitbox != null:
		_hitbox.set_deferred("monitoring", true)
		_hitbox.deactivate()


## Put the body to sleep for the pool: nothing drawn, nothing colliding, nothing
## processing, nothing in the air. Idempotent.
func sleep() -> void:
	_withdraw_from_fight()
	_awake = false
	visible = false
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	process_mode = Node.PROCESS_MODE_DISABLED
	if _hurtbox != null:
		_hurtbox.set_deferred("monitorable", false)
	if _hitbox != null:
		_hitbox.deactivate()
		_hitbox.set_deferred("monitoring", false)
	for lob: Projectile in _projectiles:
		lob.sleep()
	if _brain != null:
		_brain.reset()


# --- Reading ---------------------------------------------------------------------


## What this Blank currently is, or `null` before it was configured.
func definition() -> EnemyDefinition:
	return _definition


## Its solved numbers.
func stats() -> EnemyStats:
	return _stats


## Its state machine, for a scene or a test that wants to read what it is doing.
func brain() -> BlankBrain:
	return _brain


## Its health pool.
func combatant() -> Combatant:
	return _combatant


## Its shield, or `null` for a Blank that is not a Coins.
func shield() -> CoinsShield:
	return _shield


## The lobs this body owns. Every Blank has them (see `_build_projectiles()` for why),
## and only a Cups ever throws one. Handed out so a VFX pass can dress them and a test
## can watch what one hits.
func projectiles() -> Array[Projectile]:
	return _projectiles


## True while it is out in the world rather than asleep in a pool.
func is_awake() -> bool:
	return _awake


## True while it still has health.
func is_alive() -> bool:
	return _combatant != null and _combatant.is_alive()


## Seconds until this Blank's hit lands, `INF` when nothing is winding up. What a test
## times a dodge against - never a clock.
func time_until_hit() -> float:
	return INF if _brain == null else _brain.time_until_hit()


## True once the card has fluttered free, so the pool may have the body back.
func has_fluttered() -> bool:
	return _brain != null and _brain.has_fluttered()


# --- The frame -------------------------------------------------------------------


## Refill the one perception from the scene. Nothing is allocated here.
func _fill_perception() -> void:
	_perception.clear()
	_perception.self_position = global_position
	_perception.self_facing = _brain.facing()
	_perception.staggered = _combatant != null and _combatant.is_staggered()
	_perception.health_fraction = 0.0 if _combatant == null else _combatant.health_fraction()
	if _target != null and is_instance_valid(_target):
		_perception.see_target(_target.global_position)
	_fill_allies()


## Count the allies the brain is entitled to know about. Only the two ranks that use
## the answer pay for the scan - a Two of Swords never walks the array at all.
func _fill_allies() -> void:
	if _stats == null or (not _stats.grants_aura and not _stats.flees_to_alert):
		return
	var radius := _stats.aura_radius if _stats.grants_aura else _stats.alert_radius
	var nearest := INF
	for ally: Blank in _allies:
		if ally == null or ally == self or not is_instance_valid(ally):
			continue
		if not ally.is_awake() or not ally.is_alive():
			continue
		var distance := global_position.distance_to(ally.global_position)
		if distance <= radius:
			_perception.allies_nearby += 1
		if distance >= nearest:
			continue
		nearest = distance
		_perception.nearest_ally_position = ally.global_position
		_perception.has_nearest_ally = true


## Tell the shield which way it is being held and what it is being held against.
##
## **The threat is `_target`, and `_target` is the Fool.** So the shield guards the
## bearing the Fool stands on and nothing else: a hit arriving from any other direction
## - another Blank's stray lob, a hazard, whatever a later round adds - goes through it
## even if the wedge would have covered it. That is right today, because the Fool is the
## only thing in the game that throws a hit at a Blank - `Faction.is_hostile()` makes
## the Fool the only side hostile to one - and it keeps the shield honest about the one
## duel it is for. The day
## something else can hurt a Blank, this is the line that has to change: the threat
## becomes the source of the hit being resolved, which means `CombatDefense.is_blocking()`
## has to be handed the hit - a round-7 contract, and not this round's to change.
func _aim_shield() -> void:
	if _shield == null:
		return
	_shield.set_raised(_brain.is_shield_raised())
	var offset := Vector2.ZERO
	if _target != null and is_instance_valid(_target):
		offset = _target.global_position - global_position
	_shield.aim(_brain.facing(), offset)


## Walk where the brain wants to walk. `move_and_slide()` rather than
## `move_and_collide()` so a Blank rounds the scenery on its way in rather than
## stopping dead against a standing stone.
func _apply_movement(_delta: float) -> void:
	velocity = _brain.movement_intent()
	if velocity.is_zero_approx():
		velocity = Vector2.ZERO
		return
	move_and_slide()


## Draw it. The action rows are one facing deep, so seven of the eight facings fall
## back to their static frame - `CharacterAnimator` is what makes that invisible to
## everything above it.
func _animate(delta: float) -> void:
	if _animator == null:
		return
	if _hit_reaction_left > 0.0:
		_hit_reaction_left -= delta
	_animator.set_state(BlankSprites.facing_name(_brain.facing()), _action_for_state())
	_animator.advance(delta)


## Which animation row this Blank's state reads as.
func _action_for_state() -> String:
	match _brain.state():
		BlankBrain.State.DEFEATED:
			return BlankSprites.ACTION_DEFEAT
		BlankBrain.State.STAGGERED:
			return BlankSprites.ACTION_HIT
		BlankBrain.State.TELEGRAPH, BlankBrain.State.ATTACK, BlankBrain.State.RECOVER:
			# The whole rota is one clip: its first frames ARE the windup, which is
			# what makes the tell readable with the art that exists.
			return BlankSprites.ACTION_ATTACK
	if _hit_reaction_left > 0.0:
		return BlankSprites.ACTION_HIT
	if not _brain.movement_intent().is_zero_approx():
		return BlankSprites.ACTION_WALK
	return BlankSprites.ACTION_STATIC


# --- The brain's signals ----------------------------------------------------------


## The brain joined the fight: tell the service, so Focus can lock onto this Blank and
## the Pocket Spread locks with the fight (`progression.md`).
func _on_brain_engaged() -> void:
	engaged.emit(self)
	if _service == null or _combatant == null or _announced:
		return
	_announced = true
	_service.enemy_engaged(_combatant)


func _on_brain_disengaged() -> void:
	disengaged.emit(self)
	_withdraw_from_fight()


## The window opened: swing, or throw.
func _on_attack_started(spec: HitSpec) -> void:
	if _stats != null and _stats.is_ranged:
		_throw(spec)
		return
	if _hitbox != null:
		_hitbox.activate(spec, _brain.facing())


func _on_attack_ended() -> void:
	if _hitbox != null:
		_hitbox.deactivate()


func _on_alert_raised(from_position: Vector2) -> void:
	alert_raised.emit(from_position)


func _on_card_fluttered() -> void:
	card_fluttered.emit(_definition, global_position)


# --- The body's signals -----------------------------------------------------------


func _on_damaged(_amount: int, _remaining: int) -> void:
	_hit_reaction_left = HIT_REACTION_SECONDS


## The pool emptied. `combat.md`: the body slumps, the card flutters free, and nothing
## about it is a death - so the brain starts a timer and this says so once.
func _on_died() -> void:
	if _brain != null:
		_brain.defeat()
	if _hitbox != null:
		_hitbox.deactivate()
	_withdraw_from_fight()
	defeated.emit(self)


# --- Setup -------------------------------------------------------------------------


## Build the brain for the definition this body now is, and hook every signal.
func _build_brain() -> void:
	_brain = BlankBrain.new(_stats)
	_shield = CoinsShield.new(_stats) if _stats.has_shield else null
	_brain.engaged.connect(_on_brain_engaged)
	_brain.disengaged.connect(_on_brain_disengaged)
	_brain.attack_started.connect(_on_attack_started)
	_brain.attack_ended.connect(_on_attack_ended)
	_brain.alert_raised.connect(_on_alert_raised)
	_brain.card_fluttered.connect(_on_card_fluttered)


## Build this Blank's lobs, once, in `_ready`.
##
## Every Blank gets them whether or not it is a Cups today, and the reason is the
## pool: a body is raised by a different card each time, so a Swords Two that becomes
## a Cups Nine an hour later must not add nodes to the tree to do it. `_ready` is also
## the only safe place - an `Area2D` refuses to set its monitoring flags while the
## physics server is in the middle of reporting an overlap, and an encounter's trigger
## volume is exactly such a moment.
func _build_projectiles() -> void:
	while _projectiles.size() < PROJECTILES_PER_BLANK:
		var lob := Projectile.new()
		lob.name = "Lob%d" % _projectiles.size()
		# World space: a lob that stayed parented to its thrower's transform would
		# follow the thrower as it repositioned, which is not how a thrown thing works.
		lob.top_level = true
		add_child(lob)
		_projectiles.append(lob)


## Point this Blank's lobs at the side it now fights for, and put them all away.
func _configure_projectiles() -> void:
	for lob: Projectile in _projectiles:
		if _stats != null and _stats.is_ranged:
			lob.configure(_definition.faction(), _stats.projectile_radius)
		lob.sleep()


## Throw one lob, if there is one free. See `PROJECTILES_PER_BLANK`.
func _throw(spec: HitSpec) -> void:
	for lob: Projectile in _projectiles:
		if lob.is_in_flight():
			continue
		lob.launch(
			spec,
			global_position,
			_brain.facing(),
			_stats.projectile_speed,
			_stats.projectile_life_seconds
		)
		return


## Tell the brain what difficulty is doing to telegraphs. `combat.md` §Difficulty
## modes: Trial has "tightened timing windows and telegraphs", and the multiplier is
## `CombatRules`' - the same one the Fool's perfect window is scaled by, never a copy.
func _apply_difficulty() -> void:
	if _brain == null or _service == null:
		return
	var rules := _service.rules()
	if rules == null:
		return
	_brain.set_difficulty_multiplier(rules.timing_window_multiplier(_service.difficulty()))


## Leave the fight, once, whatever the reason.
func _withdraw_from_fight() -> void:
	if not _announced:
		return
	_announced = false
	if _service != null and _combatant != null:
		_service.enemy_disengaged(_combatant)


## Look for the composition root, for a scene that injected nothing. The fallback, not
## the contract - see `attach_service()` and `FoolCombat._look_for_service()`.
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
	push_warning("%s found no CombatService in %d frames" % [name, SERVICE_LOOKUP_FRAMES])


func _ensure_animator() -> void:
	if _animator != null or _sprite == null:
		return
	_animator = CharacterAnimator.new()
	_animator.configure(_sprite, BlankSprites.build_animation_table())
