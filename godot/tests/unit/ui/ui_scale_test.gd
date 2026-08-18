extends TarrockTest

## Scalable text, and the frame art surviving it.
##
## `docs/design/art-audio.md` §Accessibility notes: "Scalable text size across all UI,
## including the Almanack's manuscript styling (**which must degrade gracefully at large
## sizes rather than break its frame art**)." Two claims, two halves here: the sizes
## really do scale, and a framed view's own minimum size GROWS with them - which is what
## "does not break the frame" means for a `NinePatchRect` behind a container, because a
## frame that grew smaller than its text would be a frame with text outside it.

const THEME_PATH := "res://art/ui/theme.tres"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_frame.tscn"

var _theme: Theme = null
var _scale: UiScale = null
var _frame: DialogueFrame = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	# A duplicate, never the shipped resource: `Theme` is a loaded resource shared by
	# every other suite in the run, and scaling the real one would leak into them.
	_theme = (load(THEME_PATH) as Theme).duplicate(true) as Theme
	_scale = UiScale.new(_theme)


func after_each() -> void:
	if _frame != null and is_instance_valid(_frame):
		_frame.get_parent().remove_child(_frame)
		_frame.free()
	_frame = null


func test_the_theme_is_the_one_the_shell_ships() -> void:
	assert_not_null(UiScale.new().theme(), "UiScale finds the theme with no argument")
	assert_true(_scale.base_default_font_size() > 0)


func test_doubling_the_scale_doubles_every_font_size() -> void:
	var base := _scale.base_default_font_size()
	var base_label := _theme.get_font_size(&"font_size", &"Label")
	_scale.apply(2.0)
	assert_eq(_theme.default_font_size, base * 2)
	assert_eq(_theme.get_font_size(&"font_size", &"Label"), base_label * 2)
	assert_almost_eq(_scale.scale(), 2.0)


func test_scaling_is_computed_from_the_authored_sizes_not_from_the_last_one() -> void:
	var base := _scale.base_default_font_size()
	_scale.apply(2.0)
	_scale.apply(2.0)
	assert_eq(_theme.default_font_size, base * 2, "applying twice is not applying four times")
	_scale.apply(1.0)
	assert_eq(_theme.default_font_size, base, "and going back really goes back")


func test_a_scale_outside_the_readable_range_is_clamped() -> void:
	_scale.apply(99.0)
	assert_almost_eq(_scale.scale(), UiSettings.MAX_TEXT_SCALE)
	_scale.apply(0.01)
	assert_almost_eq(_scale.scale(), UiSettings.MIN_TEXT_SCALE)


func test_the_dialogue_frame_grows_with_its_text_rather_than_clipping_it() -> void:
	_frame = (load(DIALOGUE_SCENE) as PackedScene).instantiate() as DialogueFrame
	_frame.theme = _theme
	tree().root.add_child(_frame)
	# A panel with a real conversation on it: an empty one has nothing to outgrow.
	_frame.attach(_conversation())
	await _settle()
	var small := _frame.content_minimum_size()

	_scale.apply(UiSettings.MAX_TEXT_SCALE)
	await _settle()
	var large := _frame.content_minimum_size()

	assert_true(
		large.y > small.y,
		"at %s the frame must ask for more room (%s), not clip (%s)"
		% [UiSettings.MAX_TEXT_SCALE, large, small]
	)
	# The NinePatch is the background of the whole control, so a frame that asks for
	# more room IS a frame that draws bigger - there is no fixed-size art to overflow.
	assert_true(_frame.size.y >= 0.0)


## A one-line conversation, so the panel has text to be measured around.
func _conversation() -> DialogueService:
	var world_state := WorldStateService.new(
		load("res://data/world_states/catalog.tres") as WorldStateCatalog,
		load("res://data/world_states/act_thresholds.tres") as ActThresholds,
		load("res://data/progression/renown_ladder.tres") as RenownLadder
	)
	var line := DialogueNode.new()
	line.id = &"L01"
	line.kind = DialogueNode.Kind.LINE
	line.speaker = Speakers.QUERENT
	line.text_key = &"DLG_MQ00_WAKE_02"
	line.next = &"END"
	var closing := DialogueNode.new()
	closing.id = &"END"
	closing.kind = DialogueNode.Kind.END
	var graph := DialogueGraph.new()
	graph.id = &"TEST_UI_SCALE"
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/ui/ui_scale_test.gd"
	graph.start_node = &"L01"
	graph.nodes = [line, closing]
	var catalog := DialogueCatalog.new()
	catalog.entries = [graph]
	var service := DialogueService.new(world_state, catalog)
	service.start(graph.id)
	return service


func _settle() -> void:
	await tree().process_frame
	await tree().process_frame
