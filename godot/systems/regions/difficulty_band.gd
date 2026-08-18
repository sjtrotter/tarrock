class_name DifficultyBand
extends RefCounted

## Which band of the Spread a region belongs to, and the only place the four are
## spelled.
##
## `docs/design/world.md` §Intended difficulty bands (soft, never enforced) is the
## whole of this file's meaning, and the parenthesis in its heading is load-bearing:
## "Enemy stats do not scale to the player; bands are tuned fixed. A Band 3 region at
## hour two should feel like Hyrule Castle at hour two: survivable by the brilliant."
##
## So a band is **never** a gate. Nothing in `RegionService` refuses travel because a
## band is high, and nothing anywhere may start doing so: the doc's own hard gates are
## few, diegetic and listed in §Hard and soft gates, and they are data on a
## `RegionEdge`. A band is a tuning label a designer reads and an encounter table will
## one day take its numbers from.

## The bands, in the doc's order. `NONE` is the Cliff, which the doc's list leaves
## out because it is outside the Spread entirely (`world.md` §The Spread).
enum Id {
	NONE,
	ENTRY,
	DEVELOPING,
	COMMITTED,
	FINALE,
}

## Every band, for iteration.
const ALL: Array[Id] = [
	Id.NONE,
	Id.ENTRY,
	Id.DEVELOPING,
	Id.COMMITTED,
	Id.FINALE,
]

## The bands the doc's own list names, in its order. `NONE` is not one of them.
const BANDED: Array[Id] = [
	Id.ENTRY,
	Id.DEVELOPING,
	Id.COMMITTED,
	Id.FINALE,
]


## A band's stable key. NOT player-facing: the map screen names regions, never bands,
## and the day a designer tool shows one it resolves a translation key of its own.
static func key(band: Id) -> StringName:
	match band:
		Id.ENTRY:
			return &"ENTRY"
		Id.DEVELOPING:
			return &"DEVELOPING"
		Id.COMMITTED:
			return &"COMMITTED"
		Id.FINALE:
			return &"FINALE"
		_:
			return &"NONE"


## The band a key names, or `NONE` for anything else.
static func from_key(band_key: StringName) -> Id:
	for band: Id in ALL:
		if key(band) == band_key:
			return band
	return Id.NONE


## True when this is a band `world.md`'s list actually gives a region.
static func is_banded(band: Id) -> bool:
	return BANDED.has(band)
