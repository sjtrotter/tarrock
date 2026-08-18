class_name Hud
extends Control

## The heads-up display: petals, Fortune, a prompt when there is one, and nothing else.
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
const EDGE_MARGIN := 24

## The name of the container every HUD element hangs inside, so a test can ask for it
## by something other than a literal.
const SAFE_AREA_NAME := &"SafeArea"

var _rose_meter: RoseMeter = null
var _health_meter: HealthMeter = null
var _fortune_meter: FortuneMeter = null
var _prompt_chip: PromptChip = null
var _vignette: FoolsChanceVignette = null
var _corner: HBoxContainer = null
var _safe: MarginContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette = FoolsChanceVignette.new()
	add_child(_vignette)

	_safe = MarginContainer.new()
	var safe := _safe
	safe.name = SAFE_AREA_NAME
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(safe)
	apply_safe_area(safe)

	var corner_anchor := VBoxContainer.new()
	corner_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_anchor.alignment = BoxContainer.ALIGNMENT_END
	safe.add_child(corner_anchor)

	_corner = HBoxContainer.new()
	_corner.name = &"Meters"
	_corner.add_theme_constant_override(&"separation", 12)
	_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_anchor.add_child(_corner)

	_health_meter = HealthMeter.new()
	_corner.add_child(_health_meter)
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
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var left := EDGE_MARGIN
	var top := EDGE_MARGIN
	var right := EDGE_MARGIN
	var bottom := EDGE_MARGIN
	if screen.x > 0 and screen.y > 0 and safe.size.x > 0 and safe.size.y > 0:
		left = maxi(left, safe.position.x)
		top = maxi(top, safe.position.y)
		right = maxi(right, screen.x - (safe.position.x + safe.size.x))
		bottom = maxi(bottom, screen.y - (safe.position.y + safe.size.y))
	container.add_theme_constant_override(&"margin_left", left)
	container.add_theme_constant_override(&"margin_top", top)
	container.add_theme_constant_override(&"margin_right", right)
	container.add_theme_constant_override(&"margin_bottom", bottom)


## Hand the HUD the playthrough it is drawing. Every argument may be null - a HUD with
## no services draws an empty frame rather than erroring, which is what it does for the
## instant between a rebuild and the re-attach.
func attach(rose: WhiteRoseService, fortune: FortuneService, combat: CombatService) -> void:
	if _rose_meter != null:
		_rose_meter.attach(rose)
	if _fortune_meter != null:
		_fortune_meter.attach(fortune)
	if _vignette != null:
		_vignette.attach(combat)
	if _health_meter != null:
		_health_meter.attach(null if combat == null else combat.fool())


## The petals.
func rose_meter() -> RoseMeter:
	return _rose_meter


## The bloom above them (TBD, issue #11 - see `HealthMeter`).
func health_meter() -> HealthMeter:
	return _health_meter


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
