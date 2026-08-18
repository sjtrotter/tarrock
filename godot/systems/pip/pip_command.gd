class_name PipCommand
extends RefCounted

## The three things the Fool can ask Pip to do, and nothing else.
##
## `docs/design/combat.md` §Pip gives the radial command wheel exactly three entries -
## **Fetch**, **Harry** and **Seek** - and this is the one place they are written down.
## A fourth would be new combat canon and belongs in the doc first.
##
## The wheel's own geometry is `PipWheel`'s; what a command DOES is `PipService`'s.
## This class is only the vocabulary the two share, so neither spells an integer.

## Which command. The order is the doc's own table order.
enum Id {
	## Retrieve a dropped or thrown item and bring it back to the Fool.
	FETCH,
	## Pin or distract one target enemy, holding its attention.
	HARRY,
	## Point at something hidden nearby - a trap, a secret, a fog-hidden path.
	SEEK,
}

## No command: what a wheel that has settled on nothing answers, and what an idle
## `PipService` reports. A named constant so no caller writes a bare -1.
const NONE := -1

## Every command, for iteration.
const ALL: Array[Id] = [Id.FETCH, Id.HARRY, Id.SEEK]

## The translation key naming each command, indexed by `Id`.
##
## The doc names all three in player-facing words, so unlike a Blank they really do
## have display names. The rows behind these keys are in
## `res://localization/strings.csv` - the English is the doc's own three words, and it
## lives there rather than here, because no player-facing string may be spelled in
## code. Nothing draws the wheel yet (round 13 of `docs/gauntlet-systems/PROMPT.md`),
## but a key with no row shows on screen as PIP_COMMAND_FETCH, so the row is part of
## the contract and `tests/unit/pip/pip_rules_test.gd` holds it to it.
const NAME_KEYS: Array[StringName] = [
	&"PIP_COMMAND_FETCH",
	&"PIP_COMMAND_HARRY",
	&"PIP_COMMAND_SEEK",
]


## True when `id` names one of the three commands. Counted from `ALL`, which is the
## list of commands; `NAME_KEYS` is a parallel table and counting from it would make
## "how many commands are there" a fact about the UI's labels.
static func is_valid(id: int) -> bool:
	return id >= 0 and id < ALL.size()


## The translation key naming a command, or `&""` for an id out of range.
static func name_key(id: int) -> StringName:
	if not is_valid(id):
		return &""
	return NAME_KEYS[id]
