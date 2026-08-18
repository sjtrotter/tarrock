extends SceneTree

## The persistent layer, end to end: a new game, a region switch, a rest, and a load.
##
## `docs/design/technical.md` §Regions and the persistent layer asks for exactly the
## things this walks through, and §Testing asks for "one integration test per region
## scene, asserting the scene instances under the persistent layer, its
## `RegionDefinition` resolves, its Waystation (if any) is reachable, and every service
## survives the switch". Both region scenes that exist - the Cliff and the greybox
## Prestige - are covered here; `res://tests/cliff_test.gd` is where the Cliff's own
## contents are played through.
##
## The identity assert is the point of the whole round: after the Fool leaps off the
## Cliff, the objects holding the world state, the fight, the White Rose and the quest
## machinery are the SAME objects. A region change frees a scene; it does not restart
## a playthrough. The load flow proves the other half - that starting one deliberately
## does throw them away, because a save cannot be loaded into a world that has already
## been played (`SaveService.apply()`).

## A slot number no playthrough uses, written and deleted by this test.
const SLOT := 9

## Where this test's saves are written. NOT the player's `user://saves`: this suite
## writes a real file to a real slot, and a test that did that in the shipping
## directory would be one crash away from standing on somebody's playthrough. The whole
## composition root is pointed here (`Services.set_saves_dir()`), because the save the
## layer writes is the one the layer's own `SaveService` decides the path of.
const SAVES_DIR := "user://test_regions_saves"

## Physics frames to let pass after a travel before the nodes are believed. The layer
## performs the swap when the frame's message queue flushes, so one frame is enough
## and three costs nothing.
const SETTLE_FRAMES := 3

## How close to an arrival marker the Fool has to land to count as standing on it.
## Pip lands a step to the side on purpose (`PersistentLayer.PIP_OFFSET`), so his own
## tolerance is that offset plus this.
const ARRIVAL_TOLERANCE := 1.0

var _all_passed := true
var _frame := 0
var _phase := 0
var _phase_frame := 0

var _layer: PersistentLayer
var _cliff: RegionScene

## The service objects as they were before the leap, for the identity assert.
var _services_before: Array = []

## The petals the Fool had before resting at the Prestige.
var _spent_petals := 0

## How many times the composition root has built its services since this test began.
var _builds := 0

## The count as it stood the instant before the new game was started, so the new game's
## own builds are the difference (see `_check_boot_built_once()`).
var _builds_before_boot := 0


## The layer is instanced here but NOT allowed to boot itself.
##
## `_initialize()` runs before the `Services` autoload's own `_ready()`, so there is no
## moment here at which the composition root can be pointed at this test's scratch save
## directory - and this suite writes a real file to a real slot, which must never be the
## player's. So the boot is taken over (`PersistentLayer.boot_new_game_on_ready`,
## documented for exactly this), and phase 0 sets the directory and starts the game on
## the first frame, once every `_ready()` in the tree has run. The layer booting itself
## is `res://tests/cliff_test.gd`'s to cover, and it does.
func _initialize() -> void:
	var services := root.get_node_or_null("Services")
	if services != null:
		# Connected before the autoload's own `_ready()`, so every build of the run is
		# counted, this test's included.
		services.connect(&"rebuilt", _on_services_rebuilt)
	var packed: PackedScene = load("res://scenes/persistent_layer.tscn")
	_layer = packed.instantiate() as PersistentLayer
	_layer.boot_new_game_on_ready = false
	root.add_child(_layer)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	_phase_frame += 1

	# --- Point the saves at a scratch directory, then start the game -------
	if _phase == 0:
		var services := root.get_node_or_null("Services")
		if not check(services != null, "the Services autoload is up"):
			return _fail()
		services.call(&"set_saves_dir", SAVES_DIR)
		_builds_before_boot = _builds
		_check(_layer.new_game(), "a new game starts")
		_advance()
		return false

	# --- A new game opens on the Cliff -------------------------------------
	if _phase == 1:
		if _phase_frame < SETTLE_FRAMES:
			return false
		if not check(_layer != null and _layer.region() != null, "the layer booted a region"):
			return _fail()
		_cliff = _layer.region()
		_check(_cliff.region_id == RegionIds.CLIFF, "and a new game opens on the Cliff")
		_check(
			_regions().current_region_id() == RegionIds.CLIFF,
			"which is where the region service says the Fool is"
		)
		_check(
			_quests().is_started(QuestIds.MQ00),
			"MQ00 is running - the boot starts it, not the region"
		)
		_check(
			_dialogue().current_graph_id() == DialogueIds.MQ00_WAKE,
			"and the Querent is waking the Fool over the black screen"
		)
		_check_on_marker(_cliff, RegionService.DEFAULT_ARRIVAL, "the Fool spawns on the Cliff's own marker")
		_check(
			_cliff.get_node_or_null("World/Fool") == null,
			"the region scene does not carry a Fool of its own"
		)
		_check(_layer.camera() != null, "the camera lives in the layer, above the region")
		_check(
			_layer.camera().limit_right == 4900,
			"and takes the Cliff's own bounds while it is looking at the Cliff"
		)
		_check_region_integration(_cliff, RegionIds.CLIFF, RegionIds.WAYSTATION_CLIFF)
		_check_boot_built_once()
		_services_before = _service_objects()
		_advance()
		return false

	# --- The leap: the region is swapped, the services are not -------------
	if _phase == 2:
		_check(
			_regions().travel_to(RegionIds.PRESTIGE, RegionService.LEAP_ARRIVAL),
			"the Fool travels the Cliff's one edge, the leap to the Prestige"
		)
		_advance()
		return false

	if _phase == 3:
		if _phase_frame < SETTLE_FRAMES:
			return false
		var prestige := _layer.region()
		if not check(prestige != null, "a region is standing under the layer"):
			return _fail()
		_check(prestige.region_id == RegionIds.PRESTIGE, "and it is the Prestige")
		_check(
			not is_instance_valid(_cliff),
			"the Cliff was freed, not left running behind the new region"
		)
		_check(
			_layer.region_root().get_child_count() == 1,
			"exactly one region is instanced at a time"
		)
		# The assert this whole round exists for.
		_check(
			_service_objects() == _services_before,
			"every service survived the switch: the same objects, not new ones"
		)
		_check_on_marker(prestige, RegionService.LEAP_ARRIVAL, "the Fool lands on the crossroads marker")
		_check(
			_layer.camera().limit_right != 4900,
			"and the camera let go of the Cliff's bounds on the way"
		)
		_check_region_integration(prestige, RegionIds.PRESTIGE, RegionIds.WAYSTATION_PRESTIGE)
		_advance()
		return false

	# --- A rest at the Prestige's Waystation --------------------------------
	if _phase == 4:
		var rose := _rose()
		rose.use_petal()
		_spent_petals = rose.petals()
		var waystation := _waystation_of(_layer.region())
		if not check(waystation != null, "the Prestige has a Waystation node"):
			return _fail()
		_check(waystation.rest(), "and the Fool can rest at it")
		_check(
			rose.petals() == rose.max_petals() and _spent_petals < rose.max_petals(),
			"which regrows the White Rose whole (%d -> %d)" % [_spent_petals, rose.petals()]
		)
		_check(
			_regions().last_waystation_id() == RegionIds.WAYSTATION_PRESTIGE,
			"and is where a defeat would wake them"
		)
		# Write the playthrough out, so the load flow has something real to read.
		# Through the layer, which is how a save menu will do it - and deliberately
		# NOT by capturing a `SaveModel` here: a `SceneTree` script that so much as
		# names that class leaks its GDScript at engine exit in Godot 4.7, which
		# `run_all.sh` reports as an error line (see `res://tests/README.md`).
		_check(_layer.save_game(SLOT), "the playthrough writes to a slot")
		_advance()
		return false

	# --- Loading it back ----------------------------------------------------
	if _phase == 5:
		_check(_layer.load_game(SLOT), "the slot loads")
		_advance()
		return false

	if _phase == 6:
		if _phase_frame < SETTLE_FRAMES:
			return false
		_check(
			_regions().current_region_id() == RegionIds.PRESTIGE,
			"a load puts the Fool back in the region the file names"
		)
		_check(
			_regions().last_waystation_id() == RegionIds.WAYSTATION_PRESTIGE,
			"and remembers the Waystation they slept at"
		)
		_check(
			_regions().has_visited(RegionIds.WAYSTATION_PRESTIGE),
			"and the Waystations they had found"
		)
		var region := _layer.region()
		_check(
			region != null and region.region_id == RegionIds.PRESTIGE,
			"the region scene is standing under the layer again"
		)
		if region != null:
			_check_on_marker(
				region, RegionIds.WAYSTATION_PRESTIGE, "with the Fool at the shrine they woke at"
			)
		# The other half of the identity rule: a LOAD is a new set of services on
		# purpose, because a save cannot be applied to a world already played.
		_check(
			_service_objects() != _services_before,
			"and the load built a fresh world rather than reusing the played one"
		)
		_check(
			_builds == _builds_before_boot + 1,
			"which is the ONE rebuild of the run: a played world cannot be loaded into"
		)
		_check(
			_layer.fool() != null and is_instance_valid(_layer.fool()),
			"while the Fool himself was never rebuilt"
		)
		# THE REATTACH LIST (`Services`): the Fool and Pip outlive the services, so
		# their components have to be handed the new ones, or the Fool would go on
		# reporting his swings into the playthrough he just left.
		var fool_combat := _layer.get_node_or_null(PersistentLayer.FOOL_COMBAT) as FoolCombat
		_check(
			fool_combat != null and fool_combat.service() == _service(&"combat"),
			"and his fight is the new CombatService, not the one the load threw away"
		)
		var companion := _layer.get_node_or_null(PersistentLayer.PIP_COMPANION) as PipCompanion
		_check(
			companion != null and companion.service() == _service(&"pip"),
			"and Pip's wheel is the new PipService"
		)
		_save().delete_slot(SLOT)
		_remove_saves_dir()
		_finish()
		return true

	return false


# --- Assertions ------------------------------------------------------------------


## Starting a playthrough loads and validates the generated catalogs NO times.
##
## `Services._ready()` builds them once, at boot. `new_game()` used to build them all
## over again and drop that first set a millisecond later - every catalog in
## `res://data` loaded and validated twice for nothing, on every single boot. It now
## reuses a world nobody has played (`Services.rebuild_if_played()`), so the new game
## adds no build at all to the count. The identity assert further down proves the reuse
## was real: those same service objects are the ones the playthrough is played in.
func _check_boot_built_once() -> void:
	_check(
		_builds == _builds_before_boot,
		"the new game reused the services already built, rather than rebuilding them"
	)
	_check(
		_save() != null and _save().saves_dir() == SAVES_DIR,
		"and this test is writing to its own scratch directory, not the player's saves"
	)


# --- Assertions, continued ---------------------------------------------------------


## One integration test per region scene (`technical.md` §Testing): it is instanced
## under the layer, its definition resolves, and its Waystation is reachable.
func _check_region_integration(
	region: RegionScene, region_id: StringName, waystation_id: StringName
) -> void:
	_check(
		region.get_parent() == _layer.region_root(),
		"%s is instanced under the layer's RegionRoot" % region_id
	)
	var definition := region.definition()
	_check(definition != null and definition.id == region_id, "%s resolves its definition" % region_id)
	if definition != null:
		_check(
			definition.scene_path == region.scene_file_path,
			"%s is the scene its definition names" % region_id
		)
	var waystation := _waystation_of(region)
	_check(waystation != null, "%s has a Waystation node" % region_id)
	if waystation == null:
		return
	_check(
		waystation.waystation_id == waystation_id,
		"named with the id its definition lists (%s)" % waystation.waystation_id
	)
	_check(
		definition != null and definition.has_waystation(waystation.waystation_id),
		"which the region's own definition knows about"
	)
	_check(
		region.marker(waystation.waystation_id) == waystation,
		"and which doubles as the arrival marker for coming back to it"
	)


## The Fool stands on a marker, and Pip a step to the side of it.
func _check_on_marker(region: RegionScene, arrival: StringName, description: String) -> void:
	var marker := region.marker(arrival)
	if marker == null:
		_check(false, "%s (the region has no %s marker)" % [description, arrival])
		return
	var fool := _layer.fool()
	var pip := _layer.pip()
	var distance := 0.0 if fool == null else fool.global_position.distance_to(marker.global_position)
	_check(distance <= ARRIVAL_TOLERANCE, "%s (%.1f px off)" % [description, distance])
	var pip_distance := (
		0.0 if pip == null else pip.global_position.distance_to(marker.global_position)
	)
	_check(
		pip_distance <= PersistentLayer.PIP_OFFSET.length() + ARRIVAL_TOLERANCE,
		"and Pip is already beside them (%.1f px)" % pip_distance
	)


# --- Services -----------------------------------------------------------------------


## Every service object, by instance id, for the identity assert. A node lookup rather
## than the bare `Services` global, for the reason every scene script uses one (see
## `RegionScene.SERVICES_PATH`).
func _service_objects() -> Array:
	var services := root.get_node_or_null("Services")
	if services == null:
		return []
	var found: Array = []
	for field: String in [
		"clock", "world_state", "fortune", "spread", "rose", "combat", "enemies", "pip",
		"save", "quests", "dialogue", "regions",
	]:
		var service: Object = services.get(field)
		found.append(0 if service == null else service.get_instance_id())
	return found


func _regions() -> RegionService:
	return _service(&"regions") as RegionService


func _quests() -> QuestService:
	return _service(&"quests") as QuestService


func _dialogue() -> DialogueService:
	return _service(&"dialogue") as DialogueService


func _rose() -> WhiteRoseService:
	return _service(&"rose") as WhiteRoseService


func _save() -> SaveService:
	return _service(&"save") as SaveService


func _service(field: StringName) -> Object:
	var services := root.get_node_or_null("Services")
	if services == null:
		return null
	return services.get(field)


## The region's first Waystation node, or `null`.
func _waystation_of(region: RegionScene) -> Waystation:
	if region == null:
		return null
	var found := region.waystations()
	if found.is_empty():
		return null
	return found[0]


# --- Plumbing -------------------------------------------------------------------------


func _on_services_rebuilt() -> void:
	_builds += 1


## Take the scratch save directory away again. The slot file is deleted first (see the
## caller); this is the empty directory it lived in.
func _remove_saves_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.remove_absolute(SAVES_DIR)


func _advance() -> void:
	_phase += 1
	_phase_frame = 0


func _check(condition: bool, description: String) -> void:
	_all_passed = check(condition, description) and _all_passed


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _fail() -> bool:
	_all_passed = false
	_finish()
	return true


func _finish() -> void:
	if _all_passed:
		print("REGIONS TEST: PASS")
		quit(0)
	else:
		print("REGIONS TEST: FAIL")
		quit(1)
