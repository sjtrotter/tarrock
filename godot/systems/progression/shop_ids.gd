class_name ShopIds
extends RefCounted

## Every shop id, as a constant.
##
## HAND-AUTHORED beside the `.tres` files under `res://data/progression/shops/`, for
## the same reason `ItemIds` is: `docs/design/progression.md` puts a shop in "every
## settled region" and `world.md` §Regions never says which regions those are, so
## there is no table to generate from. The set grows a region at a time as regions
## are greyboxed.
##
## The scheme is `SHOP_<REGION>` and `SHOP_<REGION>_<N>` for the second shop in a
## region. Code never types a shop id: it names one of these, or reads one off a
## `ShopDefinition`.

## The Prestige's stall. The proof slice's one real shop
## (`docs/final-claude-2d.md` §10 is the Cliff -> Prestige slice), and the only shop
## authored today. Its keeper has no name in any doc - see the resource's `notes`.
const SHOP_PRESTIGE := &"SHOP_PRESTIGE"

## Every shop authored today, in catalog order.
const ALL: Array[StringName] = [
	SHOP_PRESTIGE,
]
