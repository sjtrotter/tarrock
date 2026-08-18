extends TarrockTest

## The HUD: what it always shows, what it never shows, and what fades.
##
## `docs/design/art-audio.md` §UI/UX pillars: "**HUD restraint:** health (White Rose
## petals) and Fortune are always visible; everything else (minimap, prompts) fades to
## unobtrusive when not in use", and §Map: the map screen "should need no HUD counter
## duplicating it". Both are asserted, the second one negatively - a later round that
## adds a progress counter to the HUD fails this suite, which is the point.

const HUD_SCENE := "res://scenes/ui/hud.tscn"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## How many idle frames the fade is given before it counts as stuck. `PromptChip`'s
## fade is 0.18 seconds of real time and a headless frame is very short, so this is a
## generous ceiling on a loop that exits the moment the chip is gone - not a
## measurement of how long anything took.
const FADE_FRAME_LIMIT := 4000

var _hud: Hud = null
var _rules: SpreadRules = null
var _world_state: WorldStateService = null
var _fortune: FortuneService = null
var _rose: WhiteRoseService = null
var _combat: CombatService = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	_rules = (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_fortune = FortuneService.new(_rules)
	var spread := PocketSpreadService.new(
		_world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, _rules, _fortune
	)
	_rose = WhiteRoseService.new(_world_state, _rules)
	_combat = CombatService.new(
		(load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules,
		_fortune,
		spread,
		_rose,
		GameClock.new()
	)
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as Hud
	tree().root.add_child(_hud)


func after_each() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.get_parent().remove_child(_hud)
		_hud.free()
	_hud = null


# --- With nothing attached ---------------------------------------------------------


func test_a_hud_with_no_playthrough_draws_an_empty_frame_rather_than_erroring() -> void:
	assert_eq(_hud.rose_meter().icon_count(), 0)
	assert_almost_eq(_hud.fortune_meter().fill_ratio(), 0.0)
	assert_false(_hud.prompt_chip().is_showing())
	assert_false(_hud.vignette().is_washing())


func test_the_hud_carries_no_progress_counter() -> void:
	# `art-audio.md` §Map: the map screen is the progress UI and "should need no HUD
	# counter duplicating it". If a later round adds one, this fails on purpose.
	var forbidden := PackedStringArray()
	_collect_labels(_hud, forbidden)
	for text: String in forbidden:
		assert_false(
			text.contains("UNBOUND") or text.contains("QUEST") or text.contains("MAP"),
			"the HUD draws %s, which duplicates the map screen" % text
		)


# --- The safe area -----------------------------------------------------------------


func test_everything_the_hud_draws_hangs_inside_the_display_safe_area() -> void:
	# `technical.md` §Port-readiness rules (Godot), 2: the HUD honours the display's
	# safe area, so the same corners sit correctly on a notched phone and a 4K
	# monitor. The insets are applied at build; a HUD that skipped the call would have
	# no overrides at all, which is what these assertions can tell apart.
	var safe := _hud.safe_area()
	assert_not_null(safe, "the HUD has a safe area to hang things in")
	assert_eq(safe.name, Hud.SAFE_AREA_NAME)
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		assert_true(
			safe.has_theme_constant_override(side),
			"%s was never applied - apply_safe_area was not called at build" % side
		)
		assert_true(
			safe.get_theme_constant(side) >= Hud.EDGE_MARGIN,
			"%s is %d, inside the design margin of %d"
			% [side, safe.get_theme_constant(side), Hud.EDGE_MARGIN]
		)
	# And the meters really are under it, rather than beside it on the root.
	assert_eq(_hud.rose_meter().get_parent().get_parent().get_parent(), safe)
	assert_eq(_hud.prompt_chip().get_parent().get_parent().get_parent(), safe)


func test_a_notched_display_pushes_the_margins_in_further_than_the_design_margin() -> void:
	# The rule with a notch in it, proved without a notched display: the same static
	# call, handed a container of its own, must never answer less than the design
	# margin and must grow with the inset the display reports.
	var container := MarginContainer.new()
	Hud.apply_safe_area(container)
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var expected_left := Hud.EDGE_MARGIN
	if screen.x > 0 and screen.y > 0 and safe.size.x > 0 and safe.size.y > 0:
		expected_left = maxi(expected_left, safe.position.x)
	assert_eq(container.get_theme_constant(&"margin_left"), expected_left)
	assert_true(container.get_theme_constant(&"margin_top") >= Hud.EDGE_MARGIN)
	container.free()


# --- The White Rose, which is the health -------------------------------------------


func test_the_petal_row_is_the_roses_capacity_and_the_petals_left_are_lit() -> void:
	_hud.attach(_rose, _fortune, _combat)
	assert_eq(_hud.rose_meter().icon_count(), _rose.max_petals())
	assert_eq(_hud.rose_meter().lit_count(), _rose.petals())
	assert_eq(_hud.rose_meter().icon_count(), 3, "progression.md: starting capacity 3")


func test_the_hud_draws_the_fools_health_once_and_only_as_petals() -> void:
	# Issue #11: the petals ARE the health, so there is no second readout beside them.
	# `art-audio.md` §UI/UX pillars asks for restraint; two health bars would be the
	# wrong answer to a ruling that says there is one pool.
	assert_false(_hud.has_method("health_meter"), "no bloom, no bar, no numerals")


func test_a_petal_torn_by_quarters_fades_a_step_at_a_time() -> void:
	_hud.attach(_rose, _fortune, _combat)
	var meter := _hud.rose_meter()
	var before := meter.icon_count()
	var whole := meter.icon(before - 1).modulate.a

	_rose.take_damage(1)
	assert_eq(meter.icon_count(), before, "the row is the capacity, not the health")
	assert_eq(meter.quarter_fill(before - 1), 3, "the last petal is three quarters on")
	assert_eq(meter.lit_count(), _rose.petals(), "and it is still a petal on the flower")
	var nicked := meter.icon(before - 1).modulate.a
	assert_true(nicked < whole, "a torn petal is drawn dimmer than a whole one")
	assert_true(nicked > UiFrames.SPENT_ALPHA, "and brighter than a spent one")

	_rose.take_damage(3)
	assert_eq(meter.quarter_fill(before - 1), 0)
	assert_eq(meter.icon_count(), before, "a spent petal goes faint rather than away")
	assert_almost_eq(
		meter.icon(before - 1).modulate.a,
		UiFrames.SPENT_ALPHA,
		0.0001,
		"it comes back - progression.md regrows it"
	)
	assert_eq(meter.lit_count(), 2)


func test_a_grafting_adds_a_petal_to_the_row() -> void:
	_hud.attach(_rose, _fortune, _combat)
	var before := _hud.rose_meter().icon_count()
	assert_true(_rose.add_grafting())
	assert_eq(_hud.rose_meter().icon_count(), before + 1)


# --- Fortune -----------------------------------------------------------------------


func test_the_band_fills_to_the_cap_and_the_favor_overfills_past_it() -> void:
	_hud.attach(_rose, _fortune, _combat)
	var meter := _hud.fortune_meter()
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, _fortune.max_value())
	meter.settle()
	assert_almost_eq(meter.fill_ratio(), 1.0)
	assert_almost_eq(meter.overfill_ratio(), 0.0, 0.0001, "at the cap nothing spills past it")

	# Fool's Chance opens the Favor window, which is the only way past the cap.
	_fortune.on_fools_chance()
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, _fortune.ceiling())
	meter.settle()
	assert_true(_fortune.value() > _fortune.max_value(), "the Favor is open")
	assert_true(meter.overfill_ratio() > 0.0, "and it is drawn past the cap")
	assert_almost_eq(meter.fill_ratio(), 1.0, 0.0001, "the band itself is still just full")


func test_the_free_cast_mark_follows_the_service() -> void:
	_hud.attach(_rose, _fortune, _combat)
	assert_false(_hud.fortune_meter().free_cast_visible())
	_fortune.on_fools_chance()
	assert_true(_fortune.has_free_cast())
	assert_true(_hud.fortune_meter().free_cast_visible())


func test_the_band_eases_toward_the_meter_rather_than_snapping() -> void:
	_hud.attach(_rose, _fortune, _combat)
	var meter := _hud.fortune_meter()
	meter.settle()
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, _fortune.max_value())
	assert_almost_eq(meter.displayed_value(), 0.0, 0.0001, "the bar has not moved yet")
	meter._process(1.0 / 60.0)
	assert_true(meter.displayed_value() > 0.0, "and now it is on its way")
	assert_true(
		meter.displayed_value() < float(_fortune.value()), "but it has not arrived in one frame"
	)


# --- The prompt chip ---------------------------------------------------------------


func test_the_chip_shows_a_key_and_the_glyph_for_the_action() -> void:
	var chip := _hud.prompt_chip()
	chip.show_prompt(UiKeys.TUTORIAL_MQ00_BINDLE, InputActions.INTERACT)
	chip.settle()
	assert_true(chip.is_showing())
	assert_eq(chip.text_key(), UiKeys.TUTORIAL_MQ00_BINDLE)
	assert_eq(chip.prompt_text(), TranslationServer.translate(UiKeys.TUTORIAL_MQ00_BINDLE))
	assert_ne(chip.prompt_text(), String(UiKeys.TUTORIAL_MQ00_BINDLE), "the key has a row")
	assert_eq(chip.glyph_text(), InputGlyphs.keyboard(InputActions.INTERACT))
	assert_true(chip.visible)


func test_the_chip_fades_out_over_frames_rather_than_blinking_away() -> void:
	# `art-audio.md` §UI/UX pillars, HUD restraint: a prompt "fades to unobtrusive
	# when not in use". `settle()` skips the fade for the tests that do not care -
	# this is the one that does, so it drives frames and watches the alpha fall.
	var chip := _hud.prompt_chip()
	chip.show_prompt(UiKeys.TUTORIAL_MQ00_MOVE, InputActions.MOVE_LEFT)
	chip.settle()
	assert_true(chip.visible)
	assert_almost_eq(chip.modulate.a, 1.0)

	chip.clear_prompt()
	assert_false(chip.is_showing(), "the prompt is gone as far as the game is concerned")
	assert_true(chip.visible, "but the slip is still on screen, on its way out")
	assert_true(chip.modulate.a > 0.0)

	var frames := 0
	while chip.visible and frames < FADE_FRAME_LIMIT:
		await tree().process_frame
		frames += 1
	assert_false(chip.visible, "the chip faded out inside %d frames" % FADE_FRAME_LIMIT)
	assert_almost_eq(chip.modulate.a, 0.0, 0.001)
	assert_true(frames > 1, "and it took more than the one frame a blink would take")


func test_the_chip_has_no_idle_state() -> void:
	var chip := _hud.prompt_chip()
	chip.show_prompt(UiKeys.TUTORIAL_MQ00_MOVE)
	chip.settle()
	assert_true(chip.visible)
	assert_eq(chip.glyph_text(), "", "a prompt naming no action draws no glyph")
	chip.clear_prompt()
	chip.settle()
	assert_false(chip.is_showing())
	assert_false(chip.visible, "everything that is not petals or Fortune fades away")


# --- Fool's Chance -----------------------------------------------------------------


func test_the_wash_follows_the_fight_and_obeys_the_flash_toggle() -> void:
	_hud.attach(_rose, _fortune, _combat)
	var wash := _hud.vignette()
	_combat.trigger_fools_chance()
	assert_true(_combat.is_fools_chance_active())
	assert_true(wash.is_washing())

	# `combat.md` §Accessibility: a screen-flash toggle, because this feedback is
	# central. With flash off the slow motion carries the beat by itself.
	wash.set_flash_allowed(false)
	assert_false(wash.is_washing())
	wash.set_flash_allowed(true)
	assert_true(wash.is_washing())
	_combat.end_fools_chance()
	assert_false(wash.is_washing())


## Every `Label` text under a node, for the negative assertions above.
func _collect_labels(node: Node, into: PackedStringArray) -> void:
	var label := node as Label
	if label != null:
		into.append(label.text)
	for child: Node in node.get_children():
		_collect_labels(child, into)
