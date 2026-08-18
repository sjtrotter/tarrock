extends TarrockTest

## The real, checked-in NPC data against the docs and the other catalogs it
## cross-references - the same load-bearing check `Services._build_npc()` runs at
## boot, exercised here so a bad row is a red test rather than a boot-time
## `push_error()` nobody reads.
##
## The Cliff's four bark lines are the only real content this round ships
## (`npc-system.md` §Consistency note); everything else about SELECTION behaviour has
## its own suite against synthetic catalogs (`bark_service_test.gd`). This suite is
## about the DATA: does it validate, does it cross-reference cleanly, does the one
## shipped line resolve through the translation table.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const REGION_CATALOG_PATH := "res://data/regions/catalog.tres"
const QUEST_CATALOG_PATH := "res://data/quests/catalog.tres"
const MOTIF_CATALOG_PATH := "res://data/npc/motifs/catalog.tres"
const BARK_CATALOG_PATH := "res://data/npc/barks/catalog.tres"
const PROFILE_CATALOG_PATH := "res://data/npc/profiles/catalog.tres"
const NPC_RULES_PATH := "res://data/npc/npc_rules.tres"

var _world_states: WorldStateCatalog = null
var _regions: RegionCatalog = null
var _quests: QuestCatalog = null
var _motifs: MotifCatalog = null
var _barks: BarkCatalog = null
var _profiles: NpcCatalog = null
var _rules: NpcRules = null


func before_each() -> void:
	_world_states = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	_regions = load(REGION_CATALOG_PATH) as RegionCatalog
	_quests = load(QUEST_CATALOG_PATH) as QuestCatalog
	_motifs = load(MOTIF_CATALOG_PATH) as MotifCatalog
	_barks = load(BARK_CATALOG_PATH) as BarkCatalog
	_profiles = load(PROFILE_CATALOG_PATH) as NpcCatalog
	_rules = load(NPC_RULES_PATH) as NpcRules


# --- Cross-referenced validation, exactly as the composition root runs it -------


func test_the_bark_catalog_cross_references_cleanly() -> void:
	assert_eq(
		_barks.validate(_world_states, _regions, _quests, _motifs, _profiles),
		PackedStringArray()
	)


func test_the_bark_catalog_is_honestly_marked_incomplete() -> void:
	# Only the Cliff's four Querent lines exist; the evergreen-floor-per-suit check
	# must not run against a set with no Minor bark in it at all.
	assert_false(_barks.is_complete)


func test_the_profile_catalog_cross_references_cleanly() -> void:
	assert_eq(_profiles.validate(_regions), PackedStringArray())


func test_the_npc_rules_validate_against_the_real_world_state_matrix() -> void:
	assert_eq(_rules.validate(), PackedStringArray())
	assert_eq(_rules.validate_against(_world_states), PackedStringArray())


# --- The Cliff's four lines, the round's only real content ----------------------


func test_the_cliff_pool_is_the_four_lines_mq00_writes_in_order() -> void:
	assert_eq(_barks.ids(), BarkIds.CLIFF_QUERENT_IDLE)
	for entry: BarkDefinition in _barks.entries:
		assert_eq(entry.layer, BarkLayer.GENERIC)
		assert_eq(entry.speaker_kind, BarkDefinition.SpeakerKind.QUERENT)
		assert_eq(entry.region_id, RegionIds.CLIFF)


func test_every_cliff_line_resolves_through_the_translation_table() -> void:
	# `technical.md` §Localization: the CSV is the only place the English lives. A key
	# that resolves to itself is a key with no row.
	for entry: BarkDefinition in _barks.entries:
		var line := tr(entry.text_key)
		assert_ne(line, String(entry.text_key), "%s translates" % entry.text_key)


# --- Ids: no Pip, and the sets line up -------------------------------------------


func test_the_profile_catalog_lists_exactly_the_named_ids_in_order() -> void:
	assert_eq(_profiles.ids(), NpcIds.ALL)


func test_no_named_npc_can_remember_something_outside_their_own_vocabulary() -> void:
	for profile: NpcProfile in _profiles.entries:
		for flag: StringName in NpcMemoryIds.UNIVERSAL:
			assert_true(
				profile.can_remember(flag),
				"%s should know the universal memory %s" % [profile.id, flag]
			)


func test_flicks_memory_includes_his_own_quest_outcome() -> void:
	var flick := _profiles.find(NpcIds.FLICK)
	if not assert_not_null(flick):
		return
	assert_true(flick.can_remember(NpcMemoryIds.SAW_THE_SHOW_END))


func test_no_profile_is_pip_and_none_could_be() -> void:
	# `NpcIds`' class doc says the rule is kept structurally - there is no Pip id and
	# no Pip speaker kind - and points here for the assertion, so here it is against
	# the SHIPPED catalog rather than against the constant list alone. Pip "never
	# answers, in dialogue or bark" (`characters.md` §Pip); a profile for him would be
	# a bark pool for a dog who has no lines.
	for profile: NpcProfile in _profiles.entries:
		assert_false(String(profile.id).contains("PIP"), "%s is a profile for Pip" % profile.id)
		assert_false(
			String(profile.name_key).contains("PIP"),
			"%s would put Pip's name in the crowd" % profile.id
		)


# --- The nine names, in the one place the English lives -------------------------


func test_every_named_npc_name_resolves_through_the_translation_table() -> void:
	# `technical.md` §Localization, standing decision 6: `NpcProfile.name_key` is a key
	# and `localization/npc_names.csv` is the only place the names are spelled. A key
	# that resolves to itself is a key with no row - which on screen would read as
	# `NPC_OLD_SALLOW_NAME` standing at the ferry.
	assert_eq(_profiles.entries.size(), NpcIds.ALL.size(), "all nine are here to check")
	for profile: NpcProfile in _profiles.entries:
		assert_ne(profile.name_key, &"", "%s has a name key at all" % profile.id)
		assert_ne(
			tr(profile.name_key),
			String(profile.name_key),
			"%s translates" % profile.name_key
		)


func test_the_names_are_the_ones_characters_md_makes_canon() -> void:
	# Verbatim from `characters.md` §Recurring named NPCs, including the two the
	# section spells with more than a first and last name.
	var expected: Dictionary = {
		NpcIds.FLICK: "Flick",
		NpcIds.OLD_TOMKIN: "Old Tomkin",
		NpcIds.MARIGOLD_FEN: "Marigold Fen",
		NpcIds.PERRIN_LOOM: "Perrin Loom",
		NpcIds.TANSY_QUILL: "Tansy Quill",
		NpcIds.GORRISTER_VALE: "Gorrister Vale",
		NpcIds.WIDOW_CULPEPPER: "The Widow Culpepper",
		NpcIds.CORVIN_ROOK: "Corvin \"Ninefingers\" Rook",
		NpcIds.OLD_SALLOW: "Old Sallow",
	}
	for npc_id: StringName in NpcIds.ALL:
		var profile := _profiles.find(npc_id)
		if not assert_not_null(profile, "%s has a profile" % npc_id):
			continue
		assert_eq(tr(profile.name_key), String(expected[npc_id]), "%s" % npc_id)


func test_only_stillmarsh_profiles_bow_to_pip() -> void:
	for profile: NpcProfile in _profiles.entries:
		if profile.bows_to_pip:
			assert_eq(profile.home_region, RegionIds.STILLMARSH, "%s bows outside the Stillmarsh" % profile.id)
