class_name ScheduleVariant
extends Resource

## One kind of day an unbound region gets that a bound one does not, and the unbinding
## that brings it.
##
## HAND-AUTHORED in `res://data/npc/npc_rules.tres`, from `docs/design/npc-system.md`
## §Daily life's third bullet: "**Unbound regions gain schedule variety**, keyed to the
## world-state matrix: festivals (`WS_HIEROPHANT_UNBOUND` weddings, Act III 'last days'
## content per `narrative.md`), funerals (`WS_DEATH_UNBOUND` onward), markets and
## caravans (`WS_CHARIOT_UNBOUND` trade traffic), petty-crime events
## (`WS_EMPEROR_UNBOUND`). Each is an anchor-schedule variant plus its bark pool delta,
## not a new simulation layer."
##
## **NOT GENERATED, and the sentence above is why.** It is one prose bullet, not a
## table: two of its five kinds share one flag ("markets and caravans" on
## `WS_CHARIOT_UNBOUND`), one carries a second condition in an aside (Act III "last
## days"), and the flags sit inside parentheses beside the English word. A parser over
## that would be guessing at the shape of a sentence rather than reading a table, so
## these five are authored by hand with a `doc_ref` each and a reviewer checks them
## against the bullet. The day §Daily life becomes a table, this becomes generated.

## The five kinds the bullet names, in the order it names them.
enum Kind {
	## The base loop: no variant, the routine an NPC runs on an ordinary day.
	NONE,
	WEDDING,
	FUNERAL,
	MARKET,
	CARAVAN,
	PETTY_CRIME,
}

## The stable key for each kind, indexed by `Kind`.
const NAME_KEYS: Array[StringName] = [
	&"NONE", &"WEDDING", &"FUNERAL", &"MARKET", &"CARAVAN", &"PETTY_CRIME",
]

## Which kind of day this is.
@export var kind: Kind = Kind.NONE

## The unbinding that makes this kind of day possible at all.
@export var when_fired: StringName = &""

## The doc sentence this row was read from.
@export var doc_ref: String = ""

## The reading that had to be made where the bullet is prose. Doc text; never displayed.
@export var notes: String = ""


## The stable key naming a kind, e.g. `&"FUNERAL"`, or `&""` for no such kind.
static func name_key(kind_id: Kind) -> StringName:
	if kind_id < 0 or kind_id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[kind_id]


## Every problem with this variant, one string per problem.
##
## `world_states`, when supplied, resolves the flag: a kind of day waiting on an
## unbinding the matrix does not define is a festival that never happens.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if kind == Kind.NONE:
		errors.append("a schedule variant is the base loop, which is not a variant")
	if when_fired == &"":
		errors.append("the %s variant waits on no unbinding" % name_key(kind))
	elif world_states != null and world_states.find(when_fired) == null:
		errors.append("the %s variant waits on %s, which no world-state row defines" % [
			name_key(kind), when_fired
		])
	return errors
