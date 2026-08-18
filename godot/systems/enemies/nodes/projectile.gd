class_name Projectile
extends Hitbox

## A Cups Blank's lob: a `Hitbox` that travels.
##
## `docs/design/combat.md` §Enemies gives Cups "arcing, evasive, harass at range and
## reposition", so the suit needs a hit that leaves the thrower. Everything about
## delivering that hit - the faction filter, one hurtbox per activation, the reused
## `HitEvent`, the two-phase detection - is already `Hitbox`'s job and is not written
## twice here. A projectile is a hitbox with a velocity and a lifetime, and that is
## the whole class.
##
## **A lob is spent on the first thing it hits**, which is why `hit_landed` puts it
## away: `Hitbox` would otherwise keep the window open and the same lob would sail on
## through a second target.
##
## **A moving hitbox has to keep asking.** `Hitbox` answers `area_entered`, which fires
## on the frame two shapes first touch - and touching is not the same question as
## `HitSpec.covers()`, which measures centre to centre. For a swing that never moves the
## two agree closely enough; for a lob crossing a target at several hundred pixels a
## second they do not, and a hit tested only on the touching frame is a lob that sails
## through the Fool because its centres were still 70 px apart when the circles kissed.
## So the flight re-runs `Hitbox`'s own overlap sweep every frame it is in the air. It
## is the same call `activate()` makes once, `_already_hit` still keeps it to one hit
## per target, and the cost is one engine-allocated array per lob per frame - which is
## the one place in this round that `docs/design/technical.md` §Performance guardrails'
## "no per-frame allocation" is paid rather than avoided. It is bounded by lobs in the
## air (three per Cups Blank, and only while flying), and the alternative - a spec that
## claimed to cover more than it does so the entry frame could never reject it - would
## be a lie in the data rather than a cost in the loop.
##
## **The non-allocating version, owed rather than built.** The array comes from asking
## the physics server who overlaps, every frame. It can be avoided without lying about
## the spec: keep a small set of the hurtboxes currently touching this lob, maintained
## by `area_entered` / `area_exited` (which allocate nothing and fire only on change),
## and re-test `HitSpec.covers()` against that set each frame instead of re-querying.
## The set is owned by the lob, cleared in `sleep()`, and bounded by how many hurtboxes
## a 48 px circle can touch at once. It is not built today because it moves the hit
## rule out of `Hitbox._sweep()` - the one place every hit in the game is decided - and
## a second path through that rule is a worse thing to own than one engine-allocated
## array per flying lob. Build it if a profile of a real fight asks for it; do not
## build it to satisfy the guardrail on paper.
##
## **Nothing is instanced to throw one.** A `Blank` preallocates its own handful in
## `_ready` and hands the same bodies out for its whole life, so a Cups Blank
## harassing from range for a minute allocates nothing
## (`docs/design/technical.md` §Performance guardrails).
##
## The arc in "arcing" is presentation and is not here: the flight is a straight line
## against the ground plane, which is what decides whether it hits. Drawing the hop is
## the art lane's, and is listed as a request in `systems/enemies/README.md`.

## The lob is finished - it hit something, or it ran out of air.
signal spent()

## Where it is going, in pixels per second.
var _velocity: Vector2 = Vector2.ZERO

## Seconds of flight left, or 0 when it is not flying.
var _life_left: float = 0.0


func _ready() -> void:
	super()
	sleep()
	if not hit_landed.is_connected(_on_hit_landed):
		hit_landed.connect(_on_hit_landed)


func _physics_process(delta: float) -> void:
	if not is_active():
		return
	global_position += _velocity * delta
	# Re-ask, now that it has moved. See the class doc for why entry alone is not
	# enough, and `Hitbox._sweep()` for what it does (a subclass calling its own
	# inherited method, not a system reaching into one).
	_sweep()
	if not is_active():
		# It hit something on the way through and put itself away.
		return
	_life_left -= delta
	if _life_left > 0.0:
		return
	sleep()
	spent.emit()


## Throw it. The spec is the thrower's, built once by its brain and shared, exactly as
## a melee swing's is.
func launch(
	spec: HitSpec,
	from: Vector2,
	direction: Vector2,
	speed: float,
	life_seconds: float,
	at_time: float = 0.0
) -> void:
	if spec == null or life_seconds <= 0.0:
		return
	var heading := direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	global_position = from
	_velocity = heading * speed
	_life_left = life_seconds
	visible = true
	monitoring = true
	activate(spec, heading, at_time)


## True while it is in the air.
func is_in_flight() -> bool:
	return is_active()


## Seconds of flight left.
func life_left() -> float:
	return _life_left


## Put it away: no window, no velocity, nothing to look at. Also what a `Blank` going
## back to the pool calls on every lob it still has in the air.
func sleep() -> void:
	deactivate()
	monitoring = false
	visible = false
	_velocity = Vector2.ZERO
	_life_left = 0.0


func _on_hit_landed(_hurtbox: Hurtbox, _spec: HitSpec, _result: HitResult.Id) -> void:
	sleep()
	spent.emit()
