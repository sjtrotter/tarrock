class_name Rank
extends RefCounted

## A Blank's rank, and the only place the thirteen are spelled.
##
## `docs/design/combat.md` §Enemies: the Blanks: "**Rank** scales *role*, not just
## stats". The doc's own table is the whole of this file's meaning:
##
##   * **Two - Ten** - mooks, and "the printed number on the Blank's back is a simple
##     visual tell of toughness: a Two folds fast, a Ten is a real fight". So the
##     printed number is not decoration, it is the stat curve's input, which is what
##     `printed_number()` exists for.
##   * **Page** - "Scout and alarm-raiser; flees to alert others rather than engaging
##     directly" - `flees_to_alert()`.
##   * **Knight** - "Elite duelist; the rank where suit identity is sharpest".
##   * **Queen** - "Commander; grants support auras to nearby Blanks (**buffs, not
##     summons**)" - `grants_aura()`. The parenthesis is load-bearing: a Queen that
##     spawned reinforcements would be a different enemy from the one in the doc.
##   * **King** - "Roaming mini-boss; a small set piece in its own right".
##
## There is no Ace and no One. The Minor suits' Aces are not enemies anywhere in the
## docs, and a rank nobody wrote down is not invented here.

## A rank, in the doc's own order: the pip ranks, then the court.
enum Id {
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	PAGE,
	KNIGHT,
	QUEEN,
	KING,
}

## Every rank, for iteration.
const ALL: Array[Id] = [
	Id.TWO,
	Id.THREE,
	Id.FOUR,
	Id.FIVE,
	Id.SIX,
	Id.SEVEN,
	Id.EIGHT,
	Id.NINE,
	Id.TEN,
	Id.PAGE,
	Id.KNIGHT,
	Id.QUEEN,
	Id.KING,
]

## The nine numbered ranks, the doc's "Two - Ten" row.
const PIPS: Array[Id] = [
	Id.TWO,
	Id.THREE,
	Id.FOUR,
	Id.FIVE,
	Id.SIX,
	Id.SEVEN,
	Id.EIGHT,
	Id.NINE,
	Id.TEN,
]

## The four court ranks, each its own row in the doc's table.
const COURT: Array[Id] = [Id.PAGE, Id.KNIGHT, Id.QUEEN, Id.KING]

## Returned by `from_name_key()` when the key names no rank.
const UNKNOWN := -1

## What a court rank's index into a four-long court array is, for a rank that is not
## a court rank at all.
const NOT_COURT := -1

## The stable key for each rank, indexed by `Id`. Ids and save data use these; a
## player-facing rank name would be a translation key, and no doc gives one yet.
const NAME_KEYS: Array[StringName] = [
	&"TWO",
	&"THREE",
	&"FOUR",
	&"FIVE",
	&"SIX",
	&"SEVEN",
	&"EIGHT",
	&"NINE",
	&"TEN",
	&"PAGE",
	&"KNIGHT",
	&"QUEEN",
	&"KING",
]

## The lowest printed number a Blank can bear.
const LOWEST_PIP := 2

## The highest.
const HIGHEST_PIP := 10


## The stable key naming a rank, or `&""` for an id out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The rank a key names, or `UNKNOWN` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## The number printed on the Blank's back, 2..10, or 0 for a court rank.
##
## `combat.md` calls it "a simple visual tell of toughness", so it is the number the
## toughness curve is solved against and the number the art draws - one fact.
static func printed_number(id: Id) -> int:
	if id < Id.TWO or id > Id.TEN:
		return 0
	return LOWEST_PIP + int(id)


## True when this is one of the doc's "Two - Ten" mooks.
static func is_pip(id: Id) -> bool:
	return id >= Id.TWO and id <= Id.TEN


## True when this is a court rank: Page, Knight, Queen or King.
static func is_court(id: Id) -> bool:
	return id >= Id.PAGE and id <= Id.KING


## This rank's index into a four-long court array, or `NOT_COURT` (-1).
static func court_index(id: Id) -> int:
	if not is_court(id):
		return NOT_COURT
	return int(id) - int(Id.PAGE)


## True when this rank runs for help instead of fighting: the Page, and only the Page
## ("flees to alert others rather than engaging directly").
static func flees_to_alert(id: Id) -> bool:
	return id == Id.PAGE


## True when this rank buffs the Blanks around it: the Queen, and only the Queen
## ("grants support auras to nearby Blanks (buffs, not summons)").
static func grants_aura(id: Id) -> bool:
	return id == Id.QUEEN


## True when this rank is a set piece rather than a mook: the King ("Roaming
## mini-boss; a small set piece in its own right, not just a bigger mook").
static func is_mini_boss(id: Id) -> bool:
	return id == Id.KING
