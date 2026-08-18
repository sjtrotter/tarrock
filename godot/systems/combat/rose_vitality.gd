class_name RoseVitality
extends Vitality

## The Fool's `Vitality`: the White Rose, seen from inside a fight.
##
## An adapter rather than a base class on purpose. `WhiteRoseService` is a
## progression service - it holds world state, it saves itself, and `arcana.md`'s
## Trump effects read it - and making it extend a class out of `systems/combat/`
## would tie the trumps folder to the combat folder for one function's worth of
## forwarding. This is that function's worth of forwarding, and it lives on the
## combat side where the dependency belongs (`CombatService.register_fool()` is the
## only thing that builds one).
##
## Nothing is cached here. The Rose is the single source of the number, and a copy
## kept beside it would be the copy a Trump effect or a Waystation rest did not
## update.

var _rose: WhiteRoseService = null


## Wrap the Fool's Rose.
func _init(rose: WhiteRoseService) -> void:
	_rose = rose
	if rose == null:
		push_error("RoseVitality was built without a White Rose")


## The Rose being spoken for.
func rose() -> WhiteRoseService:
	return _rose


func quarters() -> int:
	return 0 if _rose == null else _rose.quarters()


func max_quarters() -> int:
	return 0 if _rose == null else _rose.max_quarters()


func take(amount: int) -> int:
	return 0 if _rose == null else _rose.take_damage(amount)


func give(amount: int) -> int:
	return 0 if _rose == null else _rose.heal(amount)


## `combat.md` §Defeat: the Fool wakes "White Rose regrown". A rest is exactly that,
## and it is the same call a Waystation makes - one way to fill the Rose, not two.
func fill() -> void:
	if _rose != null:
		_rose.rest()


func is_bare() -> bool:
	return _rose == null or _rose.is_bare()
