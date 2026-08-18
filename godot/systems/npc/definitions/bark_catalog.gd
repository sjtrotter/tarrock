class_name BarkCatalog
extends Resource

## Every bark the game can say, in one loadable resource, indexed by layer.
##
## HAND-AUTHORED at `res://data/npc/barks/catalog.tres`, one entry per `.tres` beside
## it. `docs/design/npc-system.md` §Consistency note keeps content in the docs; this is
## where the lifted lines land.
##
## **The layer index is the selection algorithm's only data structure.** §Bark layers
## resolves a request against seven pools "evaluated most-specific-first", so the
## catalog is bucketed by layer once at load and `BarkService` walks seven small arrays
## rather than the whole set seven times.
##
## **`validate()` enforces the evergreen floor.** §Bark layers: "layer 7 is mandatory
## and evergreen", and "A pool with zero unspent, non-decayed lines falls through
## immediately - there is no stall or default silence line; the next layer down always
## has content, because layer 7 is mandatory and evergreen." That promise is only true
## if every suit HAS an unconditioned layer-7 line, so a catalog missing one for any
## suit present in the game is refused here rather than falling silent three hours in -
## see `suits_without_baseline()` for what does and does not count as a floor.

## The answer `of_layer()` gives for a layer nothing is filed at. A constant, so the
## empty case allocates nothing and is read-only for the same reason the buckets are.
const NO_BARKS: Array[BarkDefinition] = []


## Every bark, in authoring order.
@export var entries: Array[BarkDefinition] = []

## True when this catalog is a complete shipping set and must carry a layer-7 baseline
## for every suit. False for a partial content drop - the Cliff's four Querent lines
## are the whole of `res://data/npc/barks/` today and there is not a Minor among them.
##
## A field rather than an assumption, because "is this all the barks there are" is not
## a question a catalog can answer about itself, and a check that fired on every
## partial catalog would be a check somebody turned off.
@export var is_complete: bool = false

## The doc this set was lifted from.
@export var doc_ref: String = ""

## Lazily built `id -> bark` index.
var _index: Dictionary = {}

## Lazily built `layer -> Array[BarkDefinition]`, indexed by layer number so a layer
## indexes it directly. Index 0 is unused padding.
var _by_layer: Array = []


## The bark with this id, or `null` when the catalog does not list it.
func find(bark_id: StringName) -> BarkDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(bark_id, null) as BarkDefinition


## True when this id is a bark the game knows.
func has(bark_id: StringName) -> bool:
	return find(bark_id) != null


## Every bark id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: BarkDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every bark filed at this layer, in catalog order.
##
## The array is the index's own and is READ-ONLY: a catalog is authored data
## (`TarrockDefinition`: definitions are immutable at runtime), and handing back the
## internal array rather than a copy is what keeps `BarkService.request()` from
## allocating one per layer per request.
func of_layer(layer: int) -> Array[BarkDefinition]:
	if _index.size() != entries.size():
		_build_index()
	if layer < 0 or layer >= _by_layer.size():
		return NO_BARKS
	var bucket: Array[BarkDefinition] = _by_layer[layer]
	return bucket


## Every suit with no layer-7 baseline, in `Suit.ALL`'s order. The check behind the
## evergreen floor; empty means the fall-through can always land.
##
## Only an UNCONDITIONED AMBIENT line counts (`BarkDefinition.is_suit_baseline()`), and
## the word doing the work is *evergreen*: a layer-7 line gated on a Court rank, a
## region, a flag or a nearby dog is a line that can be filtered out, so a suit whose
## only "baseline" is one of those still has nothing to fall back on. A Querent line is
## not a suit's floor either (the Querent has no suit), and neither is a named NPC's -
## `BarkDefinition.validate()` refuses both shapes outright, and this counts the same
## way so that a catalog nobody validated still gets an honest answer.
func suits_without_baseline() -> Array[Suit.Id]:
	var missing: Array[Suit.Id] = []
	for suit: Suit.Id in Suit.ALL:
		var found := false
		for entry: BarkDefinition in of_layer(BarkLayer.GENERIC):
			if entry.suit == suit and entry.is_suit_baseline():
				found = true
				break
		if not found:
			missing.append(suit)
	return missing


## Every problem with the catalog as a whole, one string per problem.
##
## Each bark, then the facts only the whole set can prove: no id twice, and - for a
## complete catalog - a layer-7 baseline for every suit.
func validate(
	world_states: WorldStateCatalog = null,
	regions: RegionCatalog = null,
	quests: QuestCatalog = null,
	motifs: MotifCatalog = null,
	profiles: NpcCatalog = null
) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("bark catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		errors.append_array(entry.validate_against(world_states, regions, quests, motifs, profiles))
		if seen.has(entry.id):
			errors.append("bark catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	if is_complete:
		for suit: Suit.Id in suits_without_baseline():
			errors.append("no %s speaker has a %s line to fall back on" % [
				Suit.name_key(suit), BarkLayer.describe(BarkLayer.GENERIC)
			])
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	_by_layer = []
	for layer: int in range(0, BarkLayer.LAST + 1):
		var bucket: Array[BarkDefinition] = []
		_by_layer.append(bucket)
	for entry: BarkDefinition in entries:
		if entry == null:
			continue
		_index[entry.id] = entry
		if BarkLayer.is_layer(entry.layer):
			var bucket: Array[BarkDefinition] = _by_layer[entry.layer]
			bucket.append(entry)
	# Sealed once, at the end, because `of_layer()` hands these out: a caller that
	# appended a line here would be authoring content in the middle of a playthrough.
	for bucket: Array in _by_layer:
		bucket.make_read_only()
