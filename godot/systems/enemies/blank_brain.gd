class_name BlankBrain
extends RefCounted

## A Blank's whole behaviour, as a pure state machine.
##
## No nodes, no tree, no physics, no clock: it is handed a `BlankPerception` and a
## delta and answers with a state, a movement intent and a few signals. That is what
## makes `docs/design/combat.md` §Enemies testable rather than merely implemented - a
## headless test drives a Knight of Swords frame by explicit frame and asserts the
## exact telegraph it ran.
##
## **The rota is the canon.** §Philosophy: "every player action has a clear windup, a
## clear active frame, and recovery the player can feel", and §Encounter philosophy:
## "Readable telegraphs everywhere, mooks and bosses alike - an enemy that hits
## without a tell is a bug, not a difficulty knob". So there is no path from any state
## to `ATTACK` that does not pass through `TELEGRAPH`, and `TELEGRAPH` can never be
## shorter than `EnemyRules.MIN_TELEGRAPH_SECONDS` whatever multiplies it.
##
## **Suit shapes the behaviour, rank shapes the role** - the doc's own division:
##
##   * Cups keep `preferred_range` and lob (`APPROACH` walks *away* from a Fool who
##     has closed inside it).
##   * Swords throw a string: `ATTACK` returns to `TELEGRAPH` up to
##     `string_length` times before `RECOVER`, each follow-up telling faster.
##   * Wands reach further and tag their hit (nothing consumes the tag yet - see
##     `EnemyRules.wands_fire_tag`).
##   * Coins hold a shield up through `APPROACH` and `TELEGRAPH` (`CoinsShield`).
##   * A Page never attacks at all: it goes to `FLEE_TO_ALERT` and raises the alarm -
##     including out of a stagger, and including out of `APPROACH` if anything ever
##     puts it there, because "never" is a role and not a default.
##   * A Queen holds `COMMAND_AURA` while allies stand in her radius, buffing them -
##     "buffs, not summons", so nothing here spawns anything.
##   * A King is a mook's rota with a mini-boss's numbers; its set-piece is the
##     encounter's, not the brain's.
##
## **Nothing is allocated per update.** The `HitSpec` is built once in `_init` and the
## same instance is handed back every frame of an active window; a buffed one is built
## at most once per distinct buff. Movement is a `Vector2` return, which is a value.

## What a Blank is doing.
enum State {
	## Standing in the long grass, unaware.
	IDLE,
	## It has seen the Fool and is taking the beat to react. A tell in its own right.
	AWARE,
	## Closing (or, for Cups, opening) to the range it wants to fight at.
	APPROACH,
	## The readable windup. The whole of the answer the player is being offered.
	TELEGRAPH,
	## The hit window is open.
	ATTACK,
	## The commitment's tail: what a player punishes.
	RECOVER,
	## Helpless in the charged heavy's window (`combat.md` §The Bindle).
	STAGGERED,
	## The Page's job: running from the Fool toward help.
	FLEE_TO_ALERT,
	## The Queen's stance: holding position while her aura covers her allies.
	COMMAND_AURA,
	## The pool is empty. The body slumps while the card flutters free.
	DEFEATED,
}

## Every state, for iteration and for a test that wants to name them all.
const ALL_STATES: Array[State] = [
	State.IDLE,
	State.AWARE,
	State.APPROACH,
	State.TELEGRAPH,
	State.ATTACK,
	State.RECOVER,
	State.STAGGERED,
	State.FLEE_TO_ALERT,
	State.COMMAND_AURA,
	State.DEFEATED,
]

## The state changed. `from` and `to` are `State` values.
signal state_changed(from: State, to: State)

## This Blank has joined the fight. The scene answers by calling
## `CombatService.enemy_engaged()`; the brain never touches a service itself.
signal engaged()

## It has lost the Fool and gone back to the grass.
signal disengaged()

## The readable tell began, and will run for `seconds`. What a telegraph VFX hangs on.
signal telegraph_started(seconds: float)

## The hit window opened, with this spec. The node puts its `Hitbox` where the spec
## says, or throws a projectile carrying it.
signal attack_started(spec: HitSpec)

## The hit window closed.
signal attack_ended()

## The Page's alarm went up, from where it was standing. Idle Blanks within
## `EnemyStats.alert_radius` are woken by the encounter that hears this.
signal alert_raised(from_position: Vector2)

## The Queen began commanding: every ally in her radius carries these multipliers.
signal aura_applied(damage_multiplier: float, telegraph_multiplier: float)

## The Queen stopped commanding.
signal aura_lifted()

## The card has fluttered free and the body is done: the encounter releases it to the
## pool. `combat.md`: "the card it bore flutters free - drifting off to raise a new
## bearer elsewhere later". Never a death.
signal card_fluttered()

## The stat block this brain runs on. Never null after a successful `_init`.
var _stats: EnemyStats = null

var _state: State = State.IDLE
var _state_time: float = 0.0

## Where this Blank stands, kept between updates so an idle brain can be asked
## whether it is within earshot of a Page's alarm.
var _position: Vector2 = Vector2.ZERO

## Which way it faces, as a unit vector: the direction its swing and its shield point.
var _facing: Vector2 = Vector2.RIGHT

## What it wants to do with its feet this frame, in pixels per second.
var _movement: Vector2 = Vector2.ZERO

## Which hit of a duel string is being thrown, 0-based.
var _string_index: int = 0

## How long the telegraph now running was decided to be. Read by `time_until_hit()`,
## which is how a test times a dodge without ever looking at a clock.
var _telegraph_length: float = 0.0

## What difficulty multiplies every telegraph by, from
## `CombatRules.timing_window_multiplier()` - see the class doc of `EnemyRules` for
## why that number is not duplicated on this side.
var _difficulty_multiplier: float = 1.0

## What a commanding Queen's aura multiplies this Blank's damage and telegraph by.
var _aura_damage_multiplier: float = 1.0
var _aura_telegraph_multiplier: float = 1.0

## True while this brain is itself projecting an aura.
var _commanding: bool = false

## Seconds left of a distraction, or 0. See `set_distraction()`.
var _distraction_left: float = 0.0

## What a distraction multiplies this Blank's telegraphs by while it holds.
var _distraction_telegraph_multiplier: float = 1.0

## True once a Page's alarm has gone up this engagement.
var _alert_raised: bool = false

## Seconds left of the card flutter, or 0.
var _flutter_left: float = 0.0

## True once `card_fluttered` has been emitted for this defeat.
var _fluttered: bool = false

## The hit thrown every swing, built once (see the class doc).
var _hit_spec: HitSpec = null

## The same hit under a Queen's aura, built at most once per distinct buff.
var _buffed_hit_spec: HitSpec = null
var _buffed_for_multiplier: float = 0.0


## Build a brain over a solved stat block. A brain with no stats refuses to do
## anything at all rather than inventing numbers.
func _init(stats: EnemyStats) -> void:
	_stats = stats
	if stats == null:
		push_error("BlankBrain was built without a stat block")
		return
	_hit_spec = _build_spec(stats.damage)


# --- Reading -------------------------------------------------------------------


## What this Blank is doing.
func state() -> State:
	return _state


## How long it has been doing it, in seconds.
func state_seconds() -> float:
	return _state_time


## The stat block this brain runs on.
func stats() -> EnemyStats:
	return _stats


## Where the brain believes it is standing.
func position() -> Vector2:
	return _position


## Which way it faces.
func facing() -> Vector2:
	return _facing


## What it wants to do with its feet this frame, in pixels per second. The `Blank`
## node is what actually moves and what collides.
func movement_intent() -> Vector2:
	return _movement


## True while this Blank is in the fight: it has noticed the Fool and has not been
## defeated or lost them again.
func is_engaged() -> bool:
	return _state != State.IDLE and _state != State.DEFEATED


## True once the pool is empty.
func is_defeated() -> bool:
	return _state == State.DEFEATED


## True once the card has fluttered free, so the body may go back to the pool.
func has_fluttered() -> bool:
	return _fluttered


## True while the shield is up: a Coins Blank that is closing or winding up, and not
## staggered, defeated or mid-swing. Nothing else in the roster has one.
func is_shield_raised() -> bool:
	if _stats == null or not _stats.has_shield:
		return false
	return _state == State.APPROACH or _state == State.TELEGRAPH or _state == State.AWARE


## The spec currently being swung, or `null` when the window is shut. The SAME
## instance every frame of one window - which is the guarantee
## `docs/design/technical.md` §Performance guardrails asks for, and which a test
## checks by instance id.
func active_hit() -> HitSpec:
	if _state != State.ATTACK:
		return null
	return _current_spec()


## Seconds until the hit lands, `INF` when nothing is winding up and 0 once the
## window is open. What a test times a dodge against - never a clock.
func time_until_hit() -> float:
	if _state == State.TELEGRAPH:
		return maxf(0.0, _telegraph_length - _state_time)
	if _state == State.ATTACK:
		return 0.0
	return INF


## How long the next telegraph will run, with difficulty and any aura already in it
## and the floor already applied. Public so a test can assert the floor holds rather
## than trust it.
func telegraph_seconds() -> float:
	return _telegraph_for(_string_index)


## What this Blank's hits cost right now, aura included.
func damage() -> int:
	if _stats == null:
		return 0
	return _buffed_damage()


# --- Being driven ---------------------------------------------------------------


## Tell the brain where its body is standing, without running a frame. Used when an
## encounter places a Blank before the fight starts, so an idle brain already knows
## whether it is within earshot of an alarm.
func place(at: Vector2, facing_direction: Vector2 = Vector2.ZERO) -> void:
	_position = at
	if not facing_direction.is_zero_approx():
		_facing = facing_direction.normalized()


## What every telegraph is multiplied by, from `CombatRules.timing_window_multiplier()`
## for the difficulty being played. Trial "tightens telegraphs"; Story lengthens them.
func set_difficulty_multiplier(multiplier: float) -> void:
	_difficulty_multiplier = maxf(0.01, multiplier)


## What difficulty is currently multiplying telegraphs by.
func difficulty_multiplier() -> float:
	return _difficulty_multiplier


## Carry a commanding Queen's buff. Called by whoever owns the encounter, out of
## `apply_aura_to()`; a Blank never reaches for its own commander.
func set_aura_buff(damage_multiplier: float, telegraph_multiplier: float) -> void:
	_aura_damage_multiplier = maxf(0.01, damage_multiplier)
	_aura_telegraph_multiplier = maxf(0.01, telegraph_multiplier)


## Drop the buff.
func clear_aura_buff() -> void:
	_aura_damage_multiplier = 1.0
	_aura_telegraph_multiplier = 1.0


## What this Blank's damage is currently multiplied by by an aura. 1.0 unbuffed.
func aura_damage_multiplier() -> float:
	return _aura_damage_multiplier


## What its telegraph is currently multiplied by by an aura. 1.0 unbuffed.
func aura_telegraph_multiplier() -> float:
	return _aura_telegraph_multiplier


## Take this Blank's attention off the Fool for `seconds`.
##
## THE HARRY HOOK, and the whole of round 9's reach into this system.
## `docs/design/combat.md` §Pip: Harry "pins or distracts one target enemy, holding
## its attention and briefly reducing its aggression toward the Fool". The two halves
## are split exactly the way this system is split:
##
##   * **holding its attention** is the body's, because a target is a position and a
##     position is a scene fact - `Blank.set_distraction()` fills the perception from
##     the distractor instead of the Fool, and this brain never learns who either of
##     them is;
##   * **reducing its aggression** is the brain's, and it is spent in the one currency
##     the brain has: every telegraph is multiplied by `telegraph_multiplier` while the
##     distraction holds, so the Fool gets more room in every window this Blank opens.
##     `PipRules.harry_telegraph_multiplier` is above 1.0 by definition, and
##     `EnemyRules.MIN_TELEGRAPH_SECONDS` is still the floor underneath.
##
## The countdown here is a SAFETY NET, not the authority: Pip is what starts and ends
## a pin (`PipService.harry_started` / `harry_ended`), and this expiry only means that
## a dog who was removed, retreated or reloaded mid-pin cannot leave an enemy staring
## at nothing forever.
func set_distraction(seconds: float, telegraph_multiplier: float) -> void:
	if seconds <= 0.0:
		clear_distraction()
		return
	_distraction_left = seconds
	# A harry can only ever LENGTHEN a tell. `combat.md` §Pip has Harry "briefly
	# reducing its aggression toward the Fool", so a multiplier under 1.0 would spend
	# the command backwards and make the harried enemy the sharper one - the floor is
	# here as well as in `PipRules.validate()`, because a table is not the only way in.
	_distraction_telegraph_multiplier = maxf(1.0, telegraph_multiplier)


## Put this Blank's attention back on the Fool at once.
func clear_distraction() -> void:
	_distraction_left = 0.0
	_distraction_telegraph_multiplier = 1.0


## True while something other than the Fool has this Blank's attention.
func is_distracted() -> bool:
	return _distraction_left > 0.0


## Seconds left of the distraction, or 0.
func distraction_seconds_left() -> float:
	return _distraction_left


## Project this commander's aura onto one ally, if it reaches.
##
## Returns true when the buff was applied. A commander that is not commanding - an
## idle Queen, a defeated one, or any rank that is not a Queen at all - clears the
## ally's buff and answers false, so an ally never keeps a dead commander's aura.
## `combat.md`: "grants support auras to nearby Blanks (buffs, not summons)".
func apply_aura_to(ally: BlankBrain, ally_position: Vector2) -> bool:
	if ally == null or ally == self:
		return false
	if _stats == null or not _stats.grants_aura or not is_engaged():
		ally.clear_aura_buff()
		return false
	if _position.distance_to(ally_position) > _stats.aura_radius:
		ally.clear_aura_buff()
		return false
	ally.set_aura_buff(_stats.aura_damage_multiplier, _stats.aura_telegraph_multiplier)
	return true


## Wake this Blank into the fight without waiting for it to notice by itself. What an
## encounter's trigger volume and a Page's alarm both do. Returns true only when
## **this call** engaged it.
func engage() -> bool:
	if _state != State.IDLE:
		return false
	_alert_raised = false
	_enter(State.AWARE)
	engaged.emit()
	return true


## Hear a Page's alarm. An idle Blank within `radius` of where it went up joins the
## fight; anything else ignores it. Returns true only when this call woke it.
##
## `combat.md`: the Page "flees to alert others rather than engaging directly" - this
## is the other half of that sentence, and the reason a Page is worth catching.
func hear_alert(from_position: Vector2, radius: float) -> bool:
	if _state != State.IDLE:
		return false
	if _position.distance_to(from_position) > radius:
		return false
	return engage()


## The pool emptied. `combat.md`: a defeated Blank "slumps and fades while the card it
## bore flutters free" - so this is not a death, it starts a timer, and
## `card_fluttered` is what the encounter waits for before the body goes back to the
## pool. Ignored if it has already happened.
func defeat() -> void:
	if _state == State.DEFEATED:
		return
	_end_attack()
	_flutter_left = 0.0 if _stats == null else _stats.card_flutter_seconds
	_fluttered = false
	_stop_commanding()
	_enter(State.DEFEATED)


## Put this brain back to how it started, for a body going back to the pool. Every
## timer, buff, string and alarm is cleared: a Blank raised by a new card is a new
## Blank.
func reset() -> void:
	_end_attack()
	_stop_commanding()
	clear_aura_buff()
	_state = State.IDLE
	_state_time = 0.0
	_movement = Vector2.ZERO
	_string_index = 0
	_telegraph_length = 0.0
	_alert_raised = false
	_flutter_left = 0.0
	_fluttered = false
	clear_distraction()


## Run one frame.
##
## `perception` is refilled by the caller and read here; nothing in it is kept. The
## delta is in-game seconds, so a slowed world (Fool's Chance) really does slow the
## enemy down - which is the whole point of `combat.md` §Defense's "the Fool moves at
## normal speed relative to a slowed world".
func update(perception: BlankPerception, delta: float) -> void:
	if _stats == null or perception == null:
		return
	_position = perception.self_position
	_state_time += maxf(0.0, delta)
	_tick_distraction(delta)
	if _state == State.DEFEATED:
		_tick_flutter(delta)
		_movement = Vector2.ZERO
		return
	if perception.staggered:
		if _state != State.STAGGERED:
			_end_attack()
			_stop_commanding()
			_enter(State.STAGGERED)
		_movement = Vector2.ZERO
		return
	match _state:
		State.STAGGERED:
			_enter(_state_after_stagger())
			_movement = Vector2.ZERO
		State.IDLE:
			_update_idle(perception)
		State.AWARE:
			_update_aware(perception)
		State.APPROACH:
			_update_approach(perception)
		State.COMMAND_AURA:
			_update_command_aura(perception)
		State.TELEGRAPH:
			_update_telegraph(perception)
		State.ATTACK:
			_update_attack()
		State.RECOVER:
			_update_recover()
		State.FLEE_TO_ALERT:
			_update_flee(perception)


# --- The states ------------------------------------------------------------------


## Standing in the grass until the Fool comes close enough to be noticed.
func _update_idle(perception: BlankPerception) -> void:
	_movement = Vector2.ZERO
	if not _can_see_target(perception):
		return
	if perception.distance_to_target > _stats.aggro_radius:
		return
	engage()


## The beat between seeing and moving. `combat.md` asks for readable everything; this
## is the moment the player can see they have been seen.
func _update_aware(perception: BlankPerception) -> void:
	_movement = Vector2.ZERO
	_face_target(perception)
	if _lost_target(perception):
		return
	if _state_time < _stats.aware_seconds:
		return
	if _stats.flees_to_alert:
		_enter(State.FLEE_TO_ALERT)
		return
	_enter(State.APPROACH)


## Closing to the range this suit fights at - or opening it, for Cups.
func _update_approach(perception: BlankPerception) -> void:
	_movement = Vector2.ZERO
	if _lost_target(perception):
		return
	_face_target(perception)
	if _stats.flees_to_alert:
		# A Page has no business here at all: `combat.md` gives the rank "flees to
		# alert others rather than engaging directly", and APPROACH is the one state
		# with a path to a telegraph. Anything that lands a Page in it - coming out of
		# a stagger, or a state added later - is routed back to the only thing it
		# does. Belt and braces over `_state_after_stagger()`, on purpose: the rule is
		# that a Page never attacks, so it is enforced at the door as well.
		_enter(State.FLEE_TO_ALERT)
		return
	if _should_command(perception):
		_start_commanding()
		return
	var direction := perception.direction_to_target()
	var distance := perception.distance_to_target
	if _stats.is_ranged and distance < _stats.preferred_range:
		# "harass at range and reposition": a Cups Blank backs off rather than trading.
		_movement = -direction * _stats.move_speed
		return
	if distance > _stats.attack_radius:
		_movement = direction * _stats.move_speed
		return
	_begin_telegraph(0)


## The Queen's stance. She holds her ground while her aura covers allies, and answers
## a Fool who walks into her reach like any other Blank.
func _update_command_aura(perception: BlankPerception) -> void:
	_movement = Vector2.ZERO
	if _lost_target(perception):
		return
	_face_target(perception)
	if not _should_command(perception):
		_stop_commanding()
		_enter(State.APPROACH)
		return
	if perception.distance_to_target <= _stats.attack_radius:
		_begin_telegraph(0)


## The tell. Nothing interrupts it but a stagger or a defeat: it is a commitment on
## the enemy's side exactly as the Fool's windup is on theirs.
func _update_telegraph(_perception: BlankPerception) -> void:
	_movement = Vector2.ZERO
	if _state_time < _telegraph_length:
		return
	_enter(State.ATTACK)
	attack_started.emit(_current_spec())


## The window is open for `active_seconds`, then the string decides what happens next.
func _update_attack() -> void:
	_movement = Vector2.ZERO
	if _state_time < _stats.active_seconds:
		return
	_end_attack()
	if _string_index + 1 < _stats.string_length:
		_begin_telegraph(_string_index + 1)
		return
	_enter(State.RECOVER)


## The tail of the commitment: what a player punishes.
func _update_recover() -> void:
	_movement = Vector2.ZERO
	if _state_time < _stats.recovery_seconds:
		return
	_string_index = 0
	_enter(State.APPROACH)


## The Page's whole behaviour: away from the Fool, toward help, then the alarm.
func _update_flee(perception: BlankPerception) -> void:
	if not perception.has_target:
		_disengage()
		return
	var away := -perception.direction_to_target()
	if perception.has_nearest_ally:
		var toward_ally := perception.nearest_ally_position - _position
		if not toward_ally.is_zero_approx():
			# Away from the Fool AND toward help: a scout runs somewhere, not just off.
			away = (away + toward_ally.normalized()).normalized()
	_movement = away * _stats.move_speed
	if not away.is_zero_approx():
		_facing = away
	if _alert_raised or _state_time < _stats.alert_seconds:
		return
	_alert_raised = true
	alert_raised.emit(_position)


# --- Internals -------------------------------------------------------------------


## What a Blank comes to as, out of the charged heavy's helpless window.
##
## Role, not suit: a Page is a Page again. `combat.md` gives the rank "Scout and
## alarm-raiser; flees to alert others rather than engaging directly", with no
## exception for one that has just been knocked off its feet - so a staggered Page
## recovers into its run, never into the state that leads to a swing.
func _state_after_stagger() -> State:
	if _stats != null and _stats.flees_to_alert:
		return State.FLEE_TO_ALERT
	return State.APPROACH


## Start a telegraph for hit `index` of the string.
func _begin_telegraph(index: int) -> void:
	_string_index = index
	_telegraph_length = _telegraph_for(index)
	_enter(State.TELEGRAPH)
	telegraph_started.emit(_telegraph_length)


## How long hit `index`'s telegraph runs, with every multiplier applied and the floor
## enforced. The floor is not a tuning number: see `EnemyRules.MIN_TELEGRAPH_SECONDS`.
func _telegraph_for(index: int) -> float:
	if _stats == null:
		return EnemyRules.MIN_TELEGRAPH_SECONDS
	var seconds := _stats.telegraph_seconds
	if index > 0:
		seconds *= _stats.followup_telegraph_multiplier
	seconds *= _aura_telegraph_multiplier
	seconds *= _difficulty_multiplier
	seconds *= _distraction_telegraph_multiplier
	return maxf(seconds, EnemyRules.MIN_TELEGRAPH_SECONDS)


## Close the hit window if it is open, and say so once.
func _end_attack() -> void:
	if _state != State.ATTACK:
		return
	attack_ended.emit()


## The spec this Blank is swinging: the plain one, or the buffed one under an aura.
## Built at most once per distinct buff, never per frame.
func _current_spec() -> HitSpec:
	if is_equal_approx(_aura_damage_multiplier, 1.0):
		return _hit_spec
	if _buffed_hit_spec == null or not is_equal_approx(_buffed_for_multiplier, _aura_damage_multiplier):
		_buffed_hit_spec = _build_spec(_buffed_damage())
		_buffed_for_multiplier = _aura_damage_multiplier
	return _buffed_hit_spec


## This Blank's damage with any aura in it.
func _buffed_damage() -> int:
	return maxi(1, int(roundf(float(_stats.damage) * _aura_damage_multiplier)))


## One `HitSpec` for this Blank's swing. Enemies do not stagger the Fool: the stagger
## launcher is the Fool's own move (`combat.md` §The Bindle), and giving a mook one
## would be inventing a mechanic the doc does not have.
func _build_spec(hit_damage: int) -> HitSpec:
	if _stats == null:
		return null
	if _stats.is_ranged:
		# The lob's own body is what hits, so its shape is the projectile, not a wedge
		# swung from the thrower.
		return HitSpec.new(
			HitSpec.Kind.ENEMY_ATTACK,
			hit_damage,
			HitSpec.Shape.ARC,
			360.0,
			_stats.projectile_radius
		)
	return HitSpec.new(
		HitSpec.Kind.ENEMY_ATTACK,
		hit_damage,
		HitSpec.Shape.ARC,
		_stats.attack_arc_degrees,
		_stats.attack_radius
	)


## True when the Fool is there to be perceived at all.
func _can_see_target(perception: BlankPerception) -> bool:
	return perception.has_target and perception.target_visible


## True when the Fool is gone or far enough away to give up on, having dropped this
## brain back to `IDLE` if so.
func _lost_target(perception: BlankPerception) -> bool:
	if _can_see_target(perception) and perception.distance_to_target <= _stats.disengage_radius:
		return false
	_disengage()
	return true


## Back to the grass.
func _disengage() -> void:
	_stop_commanding()
	_string_index = 0
	_movement = Vector2.ZERO
	if _state == State.IDLE:
		return
	_enter(State.IDLE)
	disengaged.emit()


## True when this rank commands and there is somebody in range to command.
func _should_command(perception: BlankPerception) -> bool:
	return _stats.grants_aura and perception.allies_nearby > 0


func _start_commanding() -> void:
	_enter(State.COMMAND_AURA)
	if _commanding:
		return
	_commanding = true
	aura_applied.emit(_stats.aura_damage_multiplier, _stats.aura_telegraph_multiplier)


func _stop_commanding() -> void:
	if not _commanding:
		return
	_commanding = false
	aura_lifted.emit()


## Turn toward the Fool. A Blank's facing is what its swing and its shield point at.
func _face_target(perception: BlankPerception) -> void:
	var direction := perception.direction_to_target()
	if not direction.is_zero_approx():
		_facing = direction


## Count a distraction down, and put the attention back when it runs out.
func _tick_distraction(delta: float) -> void:
	if _distraction_left <= 0.0:
		return
	_distraction_left -= maxf(0.0, delta)
	if _distraction_left > 0.0:
		return
	clear_distraction()


## Count the card free, once.
func _tick_flutter(delta: float) -> void:
	if _fluttered:
		return
	_flutter_left -= maxf(0.0, delta)
	if _flutter_left > 0.0:
		return
	_flutter_left = 0.0
	_fluttered = true
	card_fluttered.emit()


## Move to a state, resetting its clock and announcing the move.
func _enter(next: State) -> void:
	if _state == next:
		_state_time = 0.0
		return
	var previous := _state
	_state = next
	_state_time = 0.0
	state_changed.emit(previous, next)
