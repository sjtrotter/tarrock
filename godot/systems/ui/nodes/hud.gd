class_name Hud
extends Control

## The heads-up display: petals, Fortune, a prompt when there is one, and nothing else.
##
## The petals ARE the health (director ruling, issue #11), so `RoseMeter` is the whole
## of the health readout and there is no second bar beside it. `art-audio.md`'s pillar
## reads literally now: "health (White Rose petals) and Fortune are always visible".
##
## `docs/design/art-audio.md` §UI/UX pillars: "**HUD restraint:** health (White Rose
## petals) and Fortune are always visible; everything else (minimap, prompts) fades to
## unobtrusive when not in use." And §Map: the map screen "is the game's primary
## progress-at-a-glance UI and should need no HUD counter duplicating it" - so there is
## deliberately NO unbound-count, NO quest tracker and NO minimap here, and adding one
## is a canon change, not a feature.
##
## Everything is anchored and containered, and the root honours the display's safe area
## (`docs/design/technical.md` §Port-readiness rules (Godot), 2), so the same HUD sits
## correctly on a notched phone and a 4K monitor without a pixel being typed.

## How far in from the safe area the corners sit, in the base 1280x720 viewport.
## A safe-area inset can never eat more than this much of a screen edge; a notch is
## a sliver, and a bad reading (global coordinates, a stale monitor) must not hide the HUD.
const MAX_SAFE_AREA_FRACTION := 0.12
const EDGE_MARGIN := 24

## The name of the container every HUD element hangs inside, so a test can ask for it
## by something other than a literal.
const SAFE_AREA_NAME := &"SafeArea"

var _rose_meter: RoseMeter = null
var _fortune_meter: FortuneMeter = null
var _prompt_chip: PromptChip = null
var _vignette: FoolsChanceVignette = null
var _corner: HBoxContainer = null
var _safe: MarginContainer = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette = FoolsChanceVignette.new()
	add_child(_vignette)

	_safe = MarginContainer.new()
	var safe := _safe
	safe.name = SAFE_AREA_NAME
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	apply_safe_area(safe)

	var corner_anchor := VBoxContainer.new()
	corner_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_anchor.alignment = BoxContainer.ALIGNMENT_BEGIN
	safe.add_child(corner_anchor)

	_corner = HBoxContainer.new()
	_corner.name = &"Meters"
	_corner.add_theme_constant_override(&"separation", 12)
	_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_anchor.add_child(_corner)

	_rose_meter = RoseMeter.new()
	_corner.add_child(_rose_meter)
	_fortune_meter = FortuneMeter.new()
	_fortune_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_corner.add_child(_fortune_meter)

	var chip_row := HBoxContainer.new()
	chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_anchor.add_child(chip_row)
	_prompt_chip = PromptChip.new()
	_prompt_chip.custom_minimum_size = Vector2(420.0, 0.0)
	chip_row.add_child(_prompt_chip)


## Give a container the display's safe-area insets, floored at the design margin.
## A desktop reports the whole window, so the margin is what is actually seen there.
static func apply_safe_area(container: MarginContainer) -> void:
	# `get_display_safe_area()` answers in GLOBAL screen coordinates, so on a two-monitor
	# desk whose primary screen sits at y = 1082 the safe area starts at y = 1146 - read
	# as an inset, that pushed the whole HUD off the bottom of a 720 px window (found on
	# the first playtest). Insets are the safe area relative to ITS screen's origin, and
	# only ever a small fraction of the window: a desktop screen has no notch.
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var origin := DisplayServer.screen_get_position()
	var left := EDGE_MARGIN
	var top := EDGE_MARGIN
	var right := EDGE_MARGIN
	var bottom := EDGE_MARGIN
	if screen.x > 0 and screen.y > 0 and safe.size.x > 0 and safe.size.y > 0:
		var inset_left := safe.position.x - origin.x
		var inset_top := safe.position.y - origin.y
		var inset_right := screen.x - (inset_left + safe.size.x)
		var inset_bottom := screen.y - (inset_top + safe.size.y)
		var cap_x := int(screen.x * MAX_SAFE_AREA_FRACTION)
		var cap_y := int(screen.y * MAX_SAFE_AREA_FRACTION)
		left = maxi(left, clampi(inset_left, 0, cap_x))
		top = maxi(top, clampi(inset_top, 0, cap_y))
		right = maxi(right, clampi(inset_right, 0, cap_x))
		bottom = maxi(bottom, clampi(inset_bottom, 0, cap_y))
	container.add_theme_constant_override(&"margin_left", left)
	container.add_theme_constant_override(&"margin_top", top)
	container.add_theme_constant_override(&"margin_right", right)
	container.add_theme_constant_override(&"margin_bottom", bottom)


## Hand the HUD the playthrough it is drawing. Every argument may be null - a HUD with
## no services draws an empty frame rather than erroring, which is what it does for the
## instant between a rebuild and the re-attach. `combat` is here for the Fool's Chance
## wash only; the Fool's health arrives with the Rose.
func attach(rose: WhiteRoseService, fortune: FortuneService, combat: CombatService) -> void:
	if _rose_meter != null:
		_rose_meter.attach(rose)
	if _fortune_meter != null:
		_fortune_meter.attach(fortune)
	if _vignette != null:
		_vignette.attach(combat)


## The petals - which are the Fool's health, and the only readout of it.
func rose_meter() -> RoseMeter:
	return _rose_meter


## The Fortune band.
func fortune_meter() -> FortuneMeter:
	return _fortune_meter


## The prompt slip.
func prompt_chip() -> PromptChip:
	return _prompt_chip


## The Fool's Chance wash.
func vignette() -> FoolsChanceVignette:
	return _vignette


## The container holding the display's safe-area insets - everything the HUD draws is
## inside it (`technical.md` §Port-readiness rules (Godot), 2).
func safe_area() -> MarginContainer:
	return _safe
