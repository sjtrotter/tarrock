extends TarrockTest

## `BarkDefinition.validate()`: the pillar made structural.
##
## `docs/design/npc-system.md` §The pillar says an aware line that ignores the world
## is a bug; `_validate_layer_fit()` is where a definition is refused for being filed
## in a layer it does not actually query. This suite proves each layer's own rule, and
## the one rule the whole class exists to make impossible: there is no Pip speaker.


# --- There is no Pip speaker, structurally ------------------------------------


func test_speaker_kind_has_no_pip_member() -> void:
	# Reflection, the same style `world_state_service_test.gd` proves fire-once with:
	# three kinds, and none of them is Pip.
	var kinds := BarkDefinition.SpeakerKind
	assert_eq(kinds.size(), 3, "AMBIENT_MINOR, NAMED, QUERENT - and nothing else")
	assert_false(kinds.keys().has("PIP"), "no enum member could carry a Pip speaker")


func test_no_named_npc_id_is_pip() -> void:
	for npc_id: StringName in NpcIds.ALL:
		assert_false(
			String(npc_id).contains("PIP"), "%s would let a bark name Pip as a speaker" % npc_id
		)


# --- Layer fit: a line is refused when it does not query its own layer's thing ----


func test_a_layer_three_bark_needs_a_world_state_condition() -> void:
	var bark := _bark(BarkLayer.WORLD_STATE)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = Suit.Id.CUPS
	var errors := bark.validate()
	assert_true(_contains(errors, "waits on no world state"), str(errors))
	bark.requires_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	assert_eq(bark.validate(), PackedStringArray())


func test_a_layer_seven_bark_may_carry_no_condition_at_all() -> void:
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = Suit.Id.CUPS
	assert_eq(bark.validate(), PackedStringArray())
	bark.act = WorldStateService.Act.ACT_II
	var errors := bark.validate()
	assert_true(_contains(errors, "waits on an act"), str(errors))


func test_a_layer_six_bark_needs_a_time_band_or_weather() -> void:
	var bark := _bark(BarkLayer.TIME_WEATHER)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = Suit.Id.CUPS
	var errors := bark.validate()
	assert_true(_contains(errors, "names neither"), str(errors))
	bark.time_band = TimeBand.Id.DAWN
	assert_eq(bark.validate(), PackedStringArray())


func test_a_layer_two_bark_needs_a_motif() -> void:
	var bark := _bark(BarkLayer.SEQUENCE)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = Suit.Id.CUPS
	var errors := bark.validate()
	assert_true(_contains(errors, "names no motif"), str(errors))
	bark.motif = MotifIds.MOTIF_SUN_BEFORE_STAR
	assert_eq(bark.validate(), PackedStringArray())


func test_a_layer_one_bark_needs_a_quest_or_a_memory() -> void:
	var bark := _bark(BarkLayer.QUEST_SCRIPTED)
	bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	bark.speaker_id = NpcIds.FLICK
	var errors := bark.validate()
	assert_true(_contains(errors, "waits on no quest and no memory"), str(errors))
	bark.npc_memory_flag = NpcMemoryIds.MET_THE_FOOL
	assert_eq(bark.validate(), PackedStringArray())


func test_a_layer_seven_line_may_not_wait_on_a_court_rank() -> void:
	# §Bark layers' Queries column for layer 7 is "Suit only". A baseline authored for
	# the Knights of Swords is not a floor for Swords: it leaves every Page, Queen and
	# King of that suit with nothing underneath them.
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = Suit.Id.SWORDS
	assert_eq(bark.validate(), PackedStringArray(), "suit alone is the whole of the key")
	bark.npc_rank = NpcRank.Id.KNIGHT
	assert_true(_contains(bark.validate(), "waits on a Court rank"), str(bark.validate()))


func test_a_layer_seven_line_may_not_be_authored_for_one_person() -> void:
	# Layer 7 is "authored once per suit", which is a pool a whole suit shares. A
	# named speaker's own baseline would be an evergreen floor that exists for exactly
	# one NPC - and a named NPC needs none, because they draw their suit's
	# (`BarkService._is_the_speakers_baseline()`).
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	bark.speaker_id = NpcIds.FLICK
	bark.suit = Suit.Id.WANDS
	assert_true(_contains(bark.validate(), "is a baseline for one person"), str(bark.validate()))


# --- Cross-referenced: a bark against the profiles it names ---------------------


func test_a_named_barks_suit_must_be_the_speakers_own() -> void:
	# A named speaker's suit is their profile's (§Named vs. ambient NPCs reads a named
	# NPC "by name and characterization"), so a bark that files Flick under Cups is
	# not a Cups line - it is a disagreement about who Flick is.
	var profiles := NpcCatalog.new()
	profiles.entries = [_flick()]
	var bark := _bark(BarkLayer.QUEST_SCRIPTED)
	bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	bark.speaker_id = NpcIds.FLICK
	bark.npc_memory_flag = NpcMemoryIds.MET_THE_FOOL
	bark.suit = Suit.Id.WANDS
	assert_eq(
		bark.validate_against(null, null, null, null, profiles),
		PackedStringArray(),
		"a Page of Wands may be filed under Wands"
	)
	bark.suit = Suit.Id.CUPS
	assert_true(
		_contains(bark.validate_against(null, null, null, null, profiles), "their profile says"),
		str(bark.validate_against(null, null, null, null, profiles))
	)


func test_a_bark_may_name_a_suit_a_profile_has_no_opinion_about() -> void:
	# Six of the nine profiles leave `suit` unset rather than guess. An unset suit is
	# not a contradiction, so a quest that DOES know may say so.
	var sallow := NpcProfile.new()
	sallow.id = NpcIds.OLD_SALLOW
	sallow.name_key = &"NPC_OLD_SALLOW_NAME"
	sallow.memory_flags_known = [NpcMemoryIds.MET_THE_FOOL]
	var profiles := NpcCatalog.new()
	profiles.entries = [sallow]
	var bark := _bark(BarkLayer.QUEST_SCRIPTED)
	bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	bark.speaker_id = NpcIds.OLD_SALLOW
	bark.npc_memory_flag = NpcMemoryIds.MET_THE_FOOL
	bark.suit = Suit.Id.CUPS
	assert_eq(
		bark.validate_against(null, null, null, null, profiles), PackedStringArray()
	)


# --- Speaker-shape rules -------------------------------------------------------


func test_a_named_bark_must_name_its_speaker() -> void:
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	bark.speaker_id = &""
	assert_true(_contains(bark.validate(), "with no id"))


func test_an_ambient_bark_must_not_name_a_speaker() -> void:
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.speaker_id = NpcIds.FLICK
	bark.suit = Suit.Id.CUPS
	assert_true(_contains(bark.validate(), "is an ambient line"))


func test_the_querent_carries_no_suit_and_no_rank() -> void:
	var bark := _bark(BarkLayer.GENERIC)
	bark.speaker_kind = BarkDefinition.SpeakerKind.QUERENT
	bark.region_id = RegionIds.CLIFF
	assert_eq(bark.validate(), PackedStringArray())
	bark.suit = Suit.Id.CUPS
	assert_true(_contains(bark.validate(), "no Minor"))


# --- Internals ---------------------------------------------------------------


## Flick, as `data/npc/profiles/FLICK.tres` has him: the one profile whose suit and
## rank are canon rather than a reading.
func _flick() -> NpcProfile:
	var profile := NpcProfile.new()
	profile.id = NpcIds.FLICK
	profile.name_key = &"NPC_FLICK_NAME"
	profile.suit = Suit.Id.WANDS
	profile.npc_rank = NpcRank.Id.PAGE
	profile.memory_flags_known = [NpcMemoryIds.MET_THE_FOOL]
	return profile


## A minimal, otherwise-generic bark at `layer`, with the fields every layer needs
## regardless of what it queries.
func _bark(layer: int) -> BarkDefinition:
	var bark := BarkDefinition.new()
	bark.id = &"BARK_TEST"
	bark.layer = layer
	bark.text_key = &"BARK_TEST_KEY"
	return bark


func _contains(errors: PackedStringArray, needle: String) -> bool:
	for error: String in errors:
		if error.contains(needle):
			return true
	return false
