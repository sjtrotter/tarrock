class_name ShopCatalog
extends Resource

## Every shop in the Spread, in one loadable resource.
##
## Hand-authored at `res://data/progression/shops/catalog.tres` and loaded once by
## `EconomyService`, which refuses to price or sell anything at a shop this catalog
## does not list. Nothing mutates it at runtime.
##
## The set is deliberately NOT closed the way the region catalog's is: `world.md`
## §Regions never says which regions are settled, so "one shop per settled region" is
## not a count anything here can prove. One shop is authored today (the Prestige) and
## the rest are content design; `EconomyRules.settled_region_ids` is where the
## expectation lives.

## Every shop definition, in authoring order.
@export var entries: Array[ShopDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The shop with this id, or `null` when the catalog does not list it.
func find(shop_id: StringName) -> ShopDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(shop_id, null) as ShopDefinition


## True when this id is a shop the game knows.
func has(shop_id: StringName) -> bool:
	return find(shop_id) != null


## Every shop standing in one region, in catalog order.
func in_region(region_id: StringName) -> Array[ShopDefinition]:
	var found: Array[ShopDefinition] = []
	for entry: ShopDefinition in entries:
		if entry != null and entry.region_id == region_id:
			found.append(entry)
	return found


## Every shop id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: ShopDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every problem with the catalog as a whole, one string per problem.
func validate_against(
	items: ItemCatalog,
	rules: EconomyRules,
	regions: RegionCatalog,
	world_states: WorldStateCatalog,
	trumps: TrumpCatalog
) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("shop catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate_against(items, rules, regions, world_states, trumps))
		if seen.has(entry.id):
			errors.append("shop catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: ShopDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
