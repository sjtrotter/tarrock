class_name DifficultyMode
extends RefCounted

## The three difficulty modes, and the only place their names are spelled.
##
## `docs/design/combat.md` §Difficulty modes is canon: Story (combat as a vehicle for
## the story), Journey (the tuned experience, and the default), Trial (tightened
## windows, no damage reduction). What each mode *does* to combat numbers belongs to
## the combat round; what a mode is *called* belongs here, so a save file, a settings
## screen and a tuning table cannot disagree about it.
##
## The mode is save data (`SaveModel.difficulty_mode`), written as its `name_key`
## rather than as an enum ordinal: an ordinal would silently re-point at a different
## mode the day a fourth one is inserted in the middle.
##
## Player-facing mode names are translation keys resolved elsewhere; these keys are
## stable ids and are never displayed.

## A difficulty mode, in the doc's own order.
enum Id {
	STORY,
	JOURNEY,
	TRIAL,
}

## Every mode, for iteration.
const ALL: Array[Id] = [Id.STORY, Id.JOURNEY, Id.TRIAL]

## The mode a new game starts in (`combat.md` marks Journey "(default)").
const DEFAULT := Id.JOURNEY

## Returned by `from_name_key()` when the key names no mode. An `int`, not an `Id`,
## precisely so the failure case is representable and a caller has to look at it -
## the same shape `Suit.UNKNOWN` uses.
const UNKNOWN := -1

## The stable key for each mode, indexed by `Id`.
const NAME_KEYS: Array[StringName] = [&"STORY", &"JOURNEY", &"TRIAL"]


## The stable key naming a mode, e.g. `&"TRIAL"`. `&""` for an id out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The mode a key names, or `UNKNOWN` (-1) when it names none.
##
## An unknown key is NOT quietly read as the default: a save written by a build that
## had a mode this one does not is a save this build cannot honestly load, and the
## caller - `SaveModel.validate_dictionary()` - reports it rather than guessing.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)
