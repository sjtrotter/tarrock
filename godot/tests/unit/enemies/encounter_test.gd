extends TarrockTest

## `Encounter`, and what it does with a body it has finished with.
##
## The one rule under test is the one pooling makes load-bearing: **a released member
## is no longer this encounter's**. A `Blank` outlives the fight it stood in - the card
## flutters free, the body goes back to the pool, and another encounter raises it an
## hour later (`combat.md` §Enemies) - so an encounter that kept a defeated member's
## signals connected would hear that body's NEXT life and count it against a fight that
## is already over.
##
## This is one of the few unit tests that needs the tree: an `Encounter` owns a pool,
## and a pool owns scene instances. Everything it adds to the root is freed in
## `after_each()`.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const RULES_PATH := "res://data/enemies/enemy_rules.tres"

## How many bodies the encounter's pool preallocates, so nothing under test grows it.
const POOL_SIZE := 4

var _catalog: EnemyCatalog = null
var _rules: EnemyRules = null
var _service: EnemyService = null
var _encounter: Encounter = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_rules = load(RULES_PATH) as EnemyRules
	if _catalog != null:
		for entry: EnemyDefinition in _catalog.entries:
			if entry != null:
				entry.clear_stats_cache()
	_service = EnemyService.new(_catalog, _rules)
	_encounter = Encounter.new()
	_encounter.name = "TestEncounter"
	var spawns: Array[EncounterSpawn] = []
	spawns.append(_spawn(EnemyIds.BLANK_SWORDS_TWO, Vector2(120.0, 0.0)))
	spawns.append(_spawn(EnemyIds.BLANK_WANDS_TWO, Vector2(-120.0, 0.0)))
	_encounter.spawns = spawns
	tree().root.add_child(_encounter)
	# No `CombatService`: this test is about what an encounter holds on to, and a Blank
	# with no service simply announces itself to nobody.
	_encounter.attach_services(null, _service)
	var pool := _encounter.pool()
	if pool != null:
		pool.configure(POOL_SIZE)


func after_each() -> void:
	if _encounter != null and is_instance_valid(_encounter):
		tree().root.remove_child(_encounter)
		_encounter.queue_free()
	_encounter = null
	_service = null


func test_a_released_members_later_signals_never_reach_the_encounter() -> void:
	# The pooling bug, written as a sequence: raise two, let one card flutter free, and
	# then make that body do everything a Blank can announce. None of it is this
	# encounter's business any more.
	if not _begin():
		return
	var members := _encounter.members()
	if not assert_eq(members.size(), 2, "two figures rose"):
		return
	var released := members[0]
	var kept := members[1]
	watch_signal(_encounter, &"member_defeated")
	watch_signal(_service, &"enemy_defeated")
	watch_signal(_service, &"card_fluttered")
	# The card goes: the real path, through the signal the body really emits.
	released.card_fluttered.emit(released.definition(), released.global_position)
	assert_signal_emitted(_service, &"card_fluttered", 1, "the roster hears the card once")
	assert_false(
		_encounter.members().has(released), "and the body is no longer a member of this fight"
	)
	assert_true(_encounter.members().has(kept), "while the one still standing is")
	assert_eq(_encounter.standing_count(), 2, "nobody was counted down: no defeat happened")
	# Now the body's next life, as the pool would hand it out: everything it can say.
	released.defeated.emit(released)
	released.card_fluttered.emit(released.definition(), released.global_position)
	released.alert_raised.emit(released.global_position)
	assert_signal_emitted(
		_encounter, &"member_defeated", 0, "a released body's defeat is not this fight's"
	)
	assert_signal_emitted(
		_service, &"enemy_defeated", 0, "and is not reported to the roster twice"
	)
	assert_signal_emitted(
		_service, &"card_fluttered", 1, "nor is a second card counted off one body"
	)
	assert_eq(_encounter.standing_count(), 2, "and the count is still what it was")
	assert_false(_encounter.is_cleared(), "so the gate stays shut")


func test_the_signals_are_disconnected_rather_than_merely_ignored() -> void:
	# The structural half: nothing is left hanging off the released body. A connection
	# that survived would still be a connection into a freed encounter the day a region
	# unloads one.
	if not _begin():
		return
	var released := _encounter.members()[0]
	# Asserted before as well as after, so "none left" is a change rather than a
	# reading a bound `Callable` was always going to give.
	assert_eq(
		_connections_to_encounter(released.defeated), 1, "a raised member's defeat is heard"
	)
	assert_eq(
		_connections_to_encounter(released.card_fluttered), 1, "its card is heard"
	)
	assert_eq(
		_connections_to_encounter(released.alert_raised), 1, "and so is its alarm"
	)
	released.card_fluttered.emit(released.definition(), released.global_position)
	assert_eq(
		_connections_to_encounter(released.defeated), 0, "no defeat connection is left"
	)
	assert_eq(
		_connections_to_encounter(released.card_fluttered), 0, "no card-flutter connection"
	)
	assert_eq(
		_connections_to_encounter(released.alert_raised), 0, "and no alarm connection"
	)
	var kept := _encounter.members()[0]
	assert_eq(
		_connections_to_encounter(kept.defeated), 1, "and the member still standing keeps its"
	)


func test_shutting_down_lets_go_of_every_member() -> void:
	# A region unload. `shut_down()` walks the roster while `_release()` empties it, so
	# this is also the assertion that the walk does not skip every other body.
	if not _begin():
		return
	var raised: Array[Blank] = _encounter.members().duplicate()
	_encounter.shut_down()
	assert_eq(_encounter.members().size(), 0, "nothing is left standing in the fight")
	assert_eq(_encounter.standing_count(), 0)
	assert_eq(_encounter.pool().live_count(), 0, "and every body went back to the pool")
	watch_signal(_encounter, &"member_defeated")
	for member: Blank in raised:
		member.defeated.emit(member)
		assert_eq(
			_connections_to_encounter(member.defeated), 0, "with nothing still listening to it"
		)
	assert_signal_emitted(
		_encounter, &"member_defeated", 0, "a shut-down fight hears none of them"
	)


func test_a_rest_puts_an_ambient_fight_back_on_its_feet() -> void:
	# `docs/design/progression.md` §Waystations: a rest "respawn[s] ambient (non-boss)
	# enemies". `RegionService.rest_at()` asks the layer, the layer asks every
	# encounter in the region, and this is the encounter's own half of that.
	if not _begin():
		return
	assert_true(_encounter.is_engaged())
	assert_true(_encounter.respawns_on_rest, "ambient is the default; most fights are")
	assert_true(_encounter.reset_for_rest(), "the fight is put back")
	assert_false(_encounter.is_engaged(), "so walking in raises it again, as the first time")
	assert_eq(_encounter.members().size(), 0, "with every body back in the pool")
	assert_eq(_encounter.pool().live_count(), 0)
	assert_true(_begin(), "and the fight really can start over")


func test_a_rest_inside_the_trigger_does_not_raise_the_fight_on_the_sleeping_fool() -> void:
	# `progression.md` §Waystations puts a shrine in every region and `combat.md`
	# §Encounter philosophy puts a fight wherever "a spot in the world earns one", so
	# the two are allowed to overlap - MQ00's ambush already stands twenty paces from
	# the Cliff's Waystation. An `Area2D` whose monitoring comes back on reports every
	# body already inside it as having just entered, so a rest taken standing in the
	# volume would start the fight again on a Fool who had just lain down. He has to
	# walk out and walk back in.
	# The trigger's own handler is called directly throughout: a unit test steps no
	# physics frames, so the `Area2D` never reports anything, and what is under test is
	# what the encounter DOES with an entry rather than how it hears about one.
	var fool := _a_fool_standing_at(_encounter.global_position)
	if not _begin():
		return
	assert_true(_encounter.reset_for_rest(), "the ambient fight is put back on its feet")
	assert_false(_encounter.is_armed(), "but the trigger is waiting for him to leave")
	_encounter._on_body_entered(fool)
	assert_false(
		_encounter.is_engaged(),
		"so the physics server noticing where he already lay does not raise the fight"
	)
	# He walks out, and the trigger is a trigger again.
	_encounter._on_body_exited(fool)
	assert_true(_encounter.is_armed(), "leaving arms it")
	_encounter._on_body_entered(fool)
	assert_true(_encounter.is_engaged(), "and walking back in is the entry it was waiting for")
	fool.free()


func test_a_rest_taken_away_from_the_fight_arms_it_at_once() -> void:
	# The ordinary case, and the one the guard above must not cost anything: a Fool who
	# rests at a shrine outside the volume walks into a fight that is already watching.
	var fool := _a_fool_standing_at(
		_encounter.global_position + Vector2(_encounter.trigger_radius * 4.0, 0.0)
	)
	if not _begin():
		return
	assert_true(_encounter.reset_for_rest())
	assert_true(_encounter.is_armed(), "nobody was standing in it, so it is armed")
	_encounter._on_body_entered(fool)
	assert_true(_encounter.is_engaged(), "and the first entry raises the fight")
	fool.free()


func test_a_rest_leaves_a_quest_gate_cleared() -> void:
	# The other half of the same sentence, and the reason the flag exists: the MQ00
	# ambush between the standing stones is twenty paces from the Cliff's Waystation.
	# A player who clears it and then rests must not turn round to find three Twos
	# standing again and a beat they have already played still owed.
	_encounter.respawns_on_rest = false
	if not _begin():
		return
	assert_false(_encounter.reset_for_rest(), "a quest gate does not answer to a rest")
	assert_true(_encounter.is_engaged(), "and nothing about the fight changed")
	assert_eq(_encounter.members().size(), 2, "the figures raised are still the ones standing")


# --- Helpers -----------------------------------------------------------------------


## Start the fight, with no Fool to fight: this test is about the roster, and a Blank
## with no target simply stands there.
func _begin() -> bool:
	if _catalog == null or _rules == null:
		fail("the enemy data did not load")
		return false
	return assert_true(_encounter.begin(null), "the fight starts")


## A body the encounter will accept as the Fool, standing where it is put. Freed by
## the test that made it; nothing adds it to the tree, because the guard under test is
## measured off positions rather than off the physics server (see
## `Encounter._fool_is_in_the_trigger()`).
func _a_fool_standing_at(position: Vector2) -> Node2D:
	var fool := Node2D.new()
	fool.name = "TestFool"
	fool.add_to_group(Interactable.FOOL_GROUP)
	tree().root.add_child(fool)
	fool.global_position = position
	return fool


func _spawn(enemy_id: StringName, offset: Vector2) -> EncounterSpawn:
	var spawn := EncounterSpawn.new()
	spawn.enemy_id = enemy_id
	spawn.offset = offset
	return spawn


## How many of `subject`'s connections land on the encounter under test.
func _connections_to_encounter(subject: Signal) -> int:
	var count := 0
	for connection: Dictionary in subject.get_connections():
		var callable: Callable = connection.get("callable")
		if callable.get_object() == _encounter:
			count += 1
	return count
