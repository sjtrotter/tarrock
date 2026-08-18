class_name ActThresholds
extends TarrockDefinition

## Where the acts begin, counted in Arcana unbound.
##
## Generated from `docs/design/world.md` §Global states: Act I is 0-6 unbound,
## Act II 7-14, Act III 15-21. `WorldStateService.act()` reads these numbers rather
## than spelling them, so a canon retune reaches the game through the doc.

## The unbound count at which Act II begins.
@export var act_ii_min: int = 7

## The unbound count at which Act III begins.
@export var act_iii_min: int = 15

## The doc section these numbers were generated from.
@export var doc_ref: String = ""


## Every problem with the thresholds; empty means they describe three real acts.
func validate() -> PackedStringArray:
	var errors := super()
	if act_ii_min < 1:
		errors.append("%s starts Act II at %d, so Act I never happens" % [_describe(), act_ii_min])
	if act_iii_min <= act_ii_min:
		errors.append("%s starts Act III at %d, not after Act II at %d" % [
			_describe(), act_iii_min, act_ii_min
		])
	if act_iii_min > WorldStateDefinition.LAST_ARCANA:
		errors.append("%s starts Act III at %d, past the last card" % [
			_describe(), act_iii_min
		])
	return errors
