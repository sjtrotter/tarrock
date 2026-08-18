class_name FoolDefense
extends CombatDefense

## The Fool's answer to an incoming hit: i-frames, the hop-guard, and Fool's Chance.
##
## It is the join between the pure `MovesetController` (which knows the Fool is 0.1 s
## into a backflip and nothing else) and `CombatService` (which knows the difficulty,
## the accessibility slider, and what a perfectly-timed dodge is worth). The
## `Combatant` on the Fool holds one of these and asks it before every hit.
##
## The rule it encodes is `docs/design/combat.md` §Defense, in three lines:
##
##   * i-frames up          -> the hit is dodged;
##   * i-frames up AND the dodge began inside the perfect window -> Fool's Chance;
##   * the hop-guard up     -> the hit is absorbed for nothing, and the guard is
##                             spent: the block-step absorbs A hit, not every hit
##                             that arrives inside its window.
##
## The perfect window is asked of the service, not the rules, every time - because it
## is the rules' number scaled by the difficulty mode and widened by the accessibility
## slider, and either can change between one hit and the next.

var _controller: MovesetController = null
var _service: CombatService = null


## Build the Fool's defence over the moveset it reads and the service it reports to.
func _init(controller: MovesetController, service: CombatService) -> void:
	_controller = controller
	_service = service
	if controller == null:
		push_error("FoolDefense was built without a moveset controller")


## Hand the defence its service, once the composition root exists to be asked.
##
## `FoolCombat` builds the Fool's defence in `_ready`, and a scene's `_ready` can run
## before the autoload layer is up (which is why `the_cliff.gd` defers its own
## service lookup). Until the service arrives this defence still knows about i-frames
## and the guard - it just has no difficulty multiplier and no Fool's Chance to report
## to, which is the honest answer rather than a guessed one.
func set_service(service: CombatService) -> void:
	_service = service


## I-frames, and only from a dodge: the block-step absorbs rather than evades.
func is_invulnerable() -> bool:
	return _controller != null and _controller.is_invulnerable()


## The hop-guard's absorbing window.
func is_blocking() -> bool:
	return _controller != null and _controller.is_blocking()


## True when the dodge that is protecting the Fool right now began inside the perfect
## window - "a dodge timed to the final instant before a hit lands".
func is_perfect_dodge() -> bool:
	if _controller == null or _service == null:
		return false
	return _controller.perfect_dodge_started_within(_service.perfect_window_seconds())


## The difficulty mode's damage-taken multiplier.
func damage_multiplier() -> float:
	return 1.0 if _service == null else _service.damage_taken_multiplier()


## Report what became of the hit, and spend what the answer cost.
##
## Two things happen here, in this order, and the order matters:
##
##   * **A block-step's guard is spent on the first hit it absorbs**, service or no
##     service. `combat.md` §Defense gives the hop-guard "absorbs a hit" - one - and
##     a guard that ate every swing arriving inside its window would be a free
##     panic button against a pair of enemies. The Fool stays committed to the rest
##     of the hop with no guard left, which is the commitment the move is priced at.
##   * **A perfect dodge is reported to the service**, which is what triggers Fool's
##     Chance and arms the free Present cast. A plain dodge is reported too, and the
##     service pays nothing for it on purpose - see
##     `CombatService.on_incoming_hit_dodged()`.
func on_hit_resolved(result: HitResult.Id, _event: HitEvent) -> void:
	if result == HitResult.Id.BLOCKED and _controller != null:
		_controller.consume_guard()
	if _service == null:
		return
	if result == HitResult.Id.DODGED_PERFECT:
		_service.on_incoming_hit_dodged(true)
	elif result == HitResult.Id.DODGED:
		_service.on_incoming_hit_dodged(false)
