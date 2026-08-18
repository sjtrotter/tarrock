class_name ItemCategory
extends RefCounted

## What kind of thing an item is, and the only place those kinds are spelled.
##
## `docs/design/progression.md` §Philosophy fixes the shape of the list: growth is
## Trumps, **staff heads** and **Rose graftings**, and nothing else - "there is no
## armor system and no charm system", and outfits are "cosmetic only". So the
## categories are not a shopkeeper's shelf plan, they are the doc's own scope cut
## written down: two of them grow the Fool, one of them is explicitly forbidden to,
## and the rest are things that get carried, eaten or handed in.
##
## A category is also what a world-state price rule reads: §Currency, shops, and
## gear-lite prices FOOD Spread-wide off `WS_EMPRESS_UNBOUND`, so "food" has to be a
## fact about an item rather than a name somebody matched on.

## A kind of item.
enum Id {
	## Eaten, and the one category canon prices off a world-state
	## (`WS_EMPRESS_UNBOUND` halves food Spread-wide).
	FOOD,
	## A trinket: carried, sold, given. No effect on how the Fool plays.
	CURIO,
	## The game's only "gear" - a small distinct twist on the Bindle's moveset,
	## never a numeric upgrade (§Currency, shops, and gear-lite).
	STAFF_HEAD,
	## A cutting that raises the White Rose's maximum petals (§The White Rose).
	ROSE_GRAFTING,
	## Clothes. COSMETIC ONLY, by the doc, and enforced in `ItemDefinition.validate()`.
	OUTFIT,
	## Carried because a quest says so; never bought, never sold.
	QUEST,
}

## Every category, for iteration.
const ALL: Array[Id] = [
	Id.FOOD,
	Id.CURIO,
	Id.STAFF_HEAD,
	Id.ROSE_GRAFTING,
	Id.OUTFIT,
	Id.QUEST,
]

## Returned by `from_name_key()` when the key names no category.
const UNKNOWN := -1

## The stable key naming each category, indexed by `Id`. Saves and price rules read
## these; nothing here is player-facing.
const NAME_KEYS: Array[StringName] = [
	&"FOOD",
	&"CURIO",
	&"STAFF_HEAD",
	&"ROSE_GRAFTING",
	&"OUTFIT",
	&"QUEST",
]


## The stable key naming a category, e.g. `&"STAFF_HEAD"`.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The category a key names, or `UNKNOWN` (-1) when it names none. Returns an `int`
## rather than an `Id` precisely so the failure case is representable.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## True when this category is one the doc forbids to change how the Fool plays.
## Today that is exactly OUTFIT (§Philosophy: "cosmetic only ... never how the Fool
## plays"), and `ItemDefinition.validate()` refuses an item that disagrees.
static func is_cosmetic_only(id: Id) -> bool:
	return id == Id.OUTFIT
