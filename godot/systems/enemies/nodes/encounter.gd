class_name Encounter
extends Node2D

## One authored fight standing in the world: which enemies, where, and what it means
## when they are down.
##
## `docs/design/combat.md` §Encounter philosophy is the whole brief: "**Few but
## meaningful ambient encounters.** Tarrock does not fill the map with a Blank camp
## every fifty meters; open-world padding is treated as a cost, not content. An
## ambient encounter exists because a spot in the world earns one". So an encounter is
## an authored node with authored spawns, never a spawner with a density.
##
## **Clearing it is a real gate.** Walking into the volume starts the fight and
## nothing else; `cleared` waits for every member's pool to be empty. That is the
## MQ00 lesson from the round before this one, written into the class: a trigger that
## fires on entry would let a player run past three Blanks and be told they had
## beaten them. A Page that flees is still not down, so a Page still holds the gate
## open - which is exactly the pressure `combat.md` gives the rank.
##
## **The scene forwards, the encounter does not.** `quest_event_on_cleared` names a
## `QuestEvents` id, and the region scene that owns this node is what calls
## `QuestService.raise()` with it - systems never reach into scenes, and scenes are
## what carry an event from one to the other (`docs/design/technical.md`
## §Architecture principles (Godot), 5). `is_cleared()` is a LATCH so a scene can ask
## later and re-raise: a quest that was not ready to hear about the ambush when it
## was cleared must not lose it.

## The fight has begun: the Fool walked in and the Blanks have risen.
signal engaged()

## Every member is down. The gate.
signal cleared()

## One member went down. `remaining` counts the ones still standing.
signal member_defeated(blank: Blank, remaining: int)

## The Fool's group, as `Interactable` spells it - one place, one name.
const FOOL_GROUP := Interactable.FOOL_GROUP

## The composition root, resolved defensively (`--check-only` does not know autoloads).
const SERVICES_PATH := "/root/Services"

## How many physics frames this node looks for the composition root before giving up.
const SERVICE_LOOKUP_FRAMES := 180

## Who rises here, and where. Authored in the scene, one entry per figure.
@export var spawns: Array[EncounterSpawn] = []

## How close the Fool has to come for the fight to start, in pixels.
@export var trigger_radius: float = 220.0

## The `QuestEvents` id the owning scene raises when this is cleared, or `&""` when
## clearing it means nothing to any quest. Never raised from here: see the class doc.
@export var quest_event_on_cleared: StringName = &""

## How many bodies the pool preallocates. 0 means "as many as `EnemyRules` says".
@export var pool_size: int = 0

var _pool: EnemyPool = null
var _trigger: Area2D = null

## The enemies currently standing in this fight. Owned here and handed to each member
## by reference, so counting allies costs nothing per frame.
var _members: Array[Blank] = []

## The Fool, learned from whoever walked into the trigger.
var _target: Node2D = null

var _combat: CombatService = null
var _enemies: EnemyService = null
var _service_lookup_frames: int = 0
var _service_lookup_gave_up: bool = false

## True once the fight has started, so it starts once.
var _engaged: bool = false

## The latch. True once every member has gone down, and never false again.
var _cleared: bool = false

## How many members are still standing.
var _standing: int = 0


func _ready() -> void:
	_build_pool()
	_build_trigger()
	_look_for_services()


func _physics_process(_delta: float) -> void:
	_look_for_services()
	if _engaged:
		_command_auras()


# --- Wiring ----------------------------------------------------------------------


## Hand this encounter the services it needs. **The preferred wiring**: the region
## scene that owns the node injects them, exactly as it does for the Fool.
func attach_services(combat: CombatService, enemies: EnemyService) -> void:
	if combat != null:
		_combat = combat
	if enemies != null:
		_enemies = enemies
	if _combat != null and _enemies != null:
		_service_lookup_gave_up = true
		_fill_pool()
	for member: Blank in _members:
		member.attach_service(_combat)


## True once every member is down. A latch: it never goes false again, so a scene can
## ask later and re-raise an event a quest was not ready to hear the first time.
func is_cleared() -> bool:
	return _cleared


## True once the fight has started.
func is_engaged() -> bool:
	return _engaged


## The enemies standing in this fight right now.
func members() -> Array[Blank]:
	return _members


## How many are still standing.
func standing_count() -> int:
	return _standing


## The pool this encounter draws bodies from, for a test that wants to prove nothing
## was instanced mid-fight.
func pool() -> EnemyPool:
	return _pool


## Start the fight by hand, for a scene or a test that does not want to walk a body
## through the trigger. Returns true only when **this call** started it.
func begin(target: Node2D) -> bool:
	if _engaged or _cleared:
		return false
	if spawns.is_empty():
		push_error("%s has nothing to spawn" % name)
		return false
	_target = target
	_engaged = true
	_members.clear()
	_standing = 0
	for spawn: EncounterSpawn in spawns:
		var member := _raise(spawn)
		if member != null:
			_members.append(member)
			_standing += 1
	for member: Blank in _members:
		member.set_allies(_members)
	if _trigger != null:
		# Deferred for the same reason `Blank.wake()` is: this usually runs inside the
		# trigger's own `body_entered`, and an area cannot stop monitoring while it is
		# reporting an overlap.
		_trigger.set_deferred("monitoring", false)
	engaged.emit()
	return true


## Put the whole fight away: every member back to the pool, every engagement dropped.
## What a scene unload calls. Does NOT clear the latch - a fight that was won stays
## won.
func shut_down() -> void:
	# Over a copy: `_release()` erases from `_members`, and walking a list while it is
	# being emptied would skip every other member.
	for member: Blank in _members.duplicate():
		if member != null and is_instance_valid(member):
			_release(member)
	_members.clear()
	_standing = 0


# --- The fight --------------------------------------------------------------------


## The Fool walked in.
func _on_body_entered(body: Node2D) -> void:
	if _engaged or _cleared:
		return
	if not body.is_in_group(FOOL_GROUP):
		return
	begin(body)


## One member went down. The card is still in the air: the body goes back to the pool
## when `card_fluttered` says so, not now.
func _on_member_defeated(member: Blank) -> void:
	_standing = maxi(0, _standing - 1)
	member_defeated.emit(member, _standing)
	if _enemies != null:
		_enemies.report_defeat(member)
	if _standing > 0 or _cleared:
		return
	_cleared = true
	cleared.emit()


## The card is free. `combat.md`: it drifts "off to raise a new bearer elsewhere
## later" - so the body it left is somebody else's now, which is what the pool is, and
## THIS is the moment it goes back. Not the moment the Blank went down: the slump and
## the fade are on screen until the card is away.
func _on_member_card_fluttered(
	definition: EnemyDefinition, from_position: Vector2, member: Blank
) -> void:
	if _enemies != null:
		_enemies.report_card_fluttered(definition, from_position)
	_release(member)


## A Page's alarm went up: every idle member within earshot joins the fight.
##
## `combat.md`: the Page "flees to alert others rather than engaging directly". The
## radius is the Page's own, off its stat block, so a rules retune moves it.
func _on_member_alert_raised(from_position: Vector2, radius: float) -> void:
	for member: Blank in _members:
		if member == null or not is_instance_valid(member) or not member.is_awake():
			continue
		var brain := member.brain()
		if brain != null:
			brain.hear_alert(from_position, radius)


## Project every commanding Queen's aura onto the allies it reaches.
##
## Walked here rather than in a brain because a brain has no way to see its fellows -
## which is deliberate: the encounter owns the roster, and `BlankBrain.apply_aura_to()`
## owns the rule. Bounded by the encounter's own member count and allocates nothing.
func _command_auras() -> void:
	if _members.size() < 2:
		return
	for commander: Blank in _members:
		if commander == null or not is_instance_valid(commander):
			continue
		var commander_brain := commander.brain()
		if commander_brain == null or commander_brain.stats() == null:
			continue
		if not commander_brain.stats().grants_aura:
			continue
		for ally: Blank in _members:
			if ally == null or ally == commander or not is_instance_valid(ally):
				continue
			var ally_brain := ally.brain()
			if ally_brain != null:
				commander_brain.apply_aura_to(ally_brain, ally.global_position)


# --- Setup ------------------------------------------------------------------------


## Raise one authored figure out of the pool.
func _raise(spawn: EncounterSpawn) -> Blank:
	if spawn == null or _pool == null or _enemies == null:
		return null
	var definition := _enemies.definition(spawn.enemy_id)
	if definition == null:
		push_error("%s spawns %s, which no enemy definition matches" % [name, spawn.enemy_id])
		return null
	var member := _pool.acquire(definition, _enemies.rules())
	if member == null:
		return null
	member.attach_service(_combat)
	if not member.defeated.is_connected(_on_member_defeated):
		member.defeated.connect(_on_member_defeated)
	var fluttered := _on_member_card_fluttered.bind(member)
	if not member.card_fluttered.is_connected(fluttered):
		member.card_fluttered.connect(fluttered)
	var stats := member.stats()
	var alert_radius := 0.0 if stats == null else stats.alert_radius
	var bound := _on_member_alert_raised.bind(alert_radius)
	if not member.alert_raised.is_connected(bound):
		member.alert_raised.connect(bound)
	if _enemies != null:
		_enemies.register(member)
	member.rise(global_position + spawn.offset, spawn.facing, _target)
	return member


## Put one body back, once the card has gone.
##
## A body OUTLIVES the fight it stood in - that is what the pool is - so letting go of
## it means letting go of its signals and of the roster slot it held. An encounter that
## kept both would hear the NEXT life of that body: the Two of Swords raised by another
## encounter an hour later would report its defeat here, past a `cleared` latch that is
## already set, against a `_standing` count that no longer includes it.
func _release(member: Blank) -> void:
	_disconnect_member(member)
	_members.erase(member)
	if _enemies != null:
		_enemies.unregister(member)
	if _pool != null:
		_pool.release(member)


## Drop every connection `_raise()` made to one member. The two bound callables are
## rebuilt exactly as they were bound, which is what `Callable.bind()` equality is for -
## the same reconstruction `_raise()` already relies on to connect each of them once.
func _disconnect_member(member: Blank) -> void:
	if member == null or not is_instance_valid(member):
		return
	if member.defeated.is_connected(_on_member_defeated):
		member.defeated.disconnect(_on_member_defeated)
	var fluttered := _on_member_card_fluttered.bind(member)
	if member.card_fluttered.is_connected(fluttered):
		member.card_fluttered.disconnect(fluttered)
	var stats := member.stats()
	var alert_radius := 0.0 if stats == null else stats.alert_radius
	var bound := _on_member_alert_raised.bind(alert_radius)
	if member.alert_raised.is_connected(bound):
		member.alert_raised.disconnect(bound)


## The pool this encounter draws from. Owned here for now; the persistent layer the
## Regions round builds is where a shared one will live.
func _build_pool() -> void:
	if _pool != null:
		return
	_pool = EnemyPool.new()
	_pool.name = "Pool"
	add_child(_pool)


## The volume that starts the fight, built in code so the scene stays authored content
## rather than collision plumbing - the same way `scripts/player.gd` builds its reach.
func _build_trigger() -> void:
	if _trigger != null:
		return
	var shape := CircleShape2D.new()
	shape.radius = maxf(trigger_radius, 1.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	_trigger = Area2D.new()
	_trigger.name = "Trigger"
	# It looks for bodies and nothing looks for it: an encounter volume is not a
	# hitbox and must never be found by one.
	_trigger.monitoring = true
	_trigger.monitorable = false
	_trigger.add_child(collision)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_body_entered)


## Look for the composition root, for a scene that injected nothing. The fallback, not
## the contract - see `attach_services()`.
func _look_for_services() -> void:
	if _service_lookup_gave_up:
		return
	_service_lookup_frames += 1
	var root := get_node_or_null(SERVICES_PATH)
	if root != null:
		var combat := root.get(&"combat") as CombatService
		var enemies := root.get(&"enemies") as EnemyService
		if combat != null and enemies != null:
			attach_services(combat, enemies)
			_fill_pool()
			return
	if _service_lookup_frames < SERVICE_LOOKUP_FRAMES:
		return
	_service_lookup_gave_up = true
	push_warning("%s found no enemy services in %d frames" % [name, SERVICE_LOOKUP_FRAMES])


## Preallocate the bodies, once the rules are known.
func _fill_pool() -> void:
	if _pool == null or _enemies == null:
		return
	var rules := _enemies.rules()
	var size := pool_size
	if size <= 0:
		size = maxi(spawns.size(), 0 if rules == null else rules.pool_size)
	_pool.configure(size)
