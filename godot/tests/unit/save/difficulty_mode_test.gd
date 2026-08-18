extends TarrockTest

## `DifficultyMode`: the three modes of `docs/design/combat.md` §Difficulty modes.
##
## It lives under `systems/core/` because the save model, the combat round and a
## settings screen all need it; its test lives here because round 3 (the save system)
## is what introduced it, and the save file is the reason it has a stable name key at
## all. Move it to `tests/unit/core/` the day a core round touches it.


func test_the_three_modes_are_the_doc_s_three_modes() -> void:
	assert_eq(DifficultyMode.ALL.size(), 3, "Story, Journey, Trial - and no fourth")
	assert_eq(DifficultyMode.ALL, [DifficultyMode.Id.STORY, DifficultyMode.Id.JOURNEY, DifficultyMode.Id.TRIAL])


func test_journey_is_the_default() -> void:
	# combat.md marks Journey "(default)" - "the tuned experience".
	assert_eq(DifficultyMode.DEFAULT, DifficultyMode.Id.JOURNEY)


func test_name_keys_are_stable_shouting_snake_case() -> void:
	assert_eq(DifficultyMode.name_key(DifficultyMode.Id.STORY), &"STORY")
	assert_eq(DifficultyMode.name_key(DifficultyMode.Id.JOURNEY), &"JOURNEY")
	assert_eq(DifficultyMode.name_key(DifficultyMode.Id.TRIAL), &"TRIAL")


func test_a_key_round_trips_to_its_mode() -> void:
	for mode: DifficultyMode.Id in DifficultyMode.ALL:
		assert_eq(DifficultyMode.from_name_key(DifficultyMode.name_key(mode)), mode)


func test_an_unknown_key_is_unknown_and_not_the_default() -> void:
	# The failure case must be representable: reading an unknown mode as Journey would
	# silently downgrade a save written by a build that had a fourth mode.
	assert_eq(DifficultyMode.from_name_key(&"NIGHTMARE"), DifficultyMode.UNKNOWN)
	assert_eq(DifficultyMode.from_name_key(&""), DifficultyMode.UNKNOWN)
	assert_ne(DifficultyMode.UNKNOWN, DifficultyMode.DEFAULT)


func test_an_id_out_of_range_has_no_name_key() -> void:
	assert_eq(DifficultyMode.name_key(-1 as DifficultyMode.Id), &"")
	assert_eq(DifficultyMode.name_key(9 as DifficultyMode.Id), &"")


func test_ordinals_are_never_what_a_save_stores() -> void:
	# A mode inserted in the middle later must not re-point every existing save; the
	# key is what is written (see SaveModel.to_dictionary), so the ordinals are free
	# to move. This test exists to state that, and to fail if someone writes an int.
	var model := SaveModel.blank()
	model.difficulty_mode = DifficultyMode.Id.TRIAL
	assert_eq(model.to_dictionary()[SaveModel.FIELD_DIFFICULTY_MODE], "TRIAL")
