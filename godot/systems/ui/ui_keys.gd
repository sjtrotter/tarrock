class_name UiKeys
extends RefCounted

## Every translation key the UI shell resolves, as a constant.
##
## `docs/design/technical.md` §Coding conventions: no magic strings. A view never
## types a key - it names one of these, and `res://tests/unit/ui/ui_keys_test.gd`
## proves both directions: every constant here has a row in a shipped CSV, and every
## row of `res://localization/ui.csv` is named by a constant here. A key nobody uses
## and a key nobody wrote are both failures.
##
## The tutorial rows live in `strings.csv` rather than `ui.csv` because they are
## quest content lifted verbatim from `docs/quests/main/MQ00-the-leap.md`'s
## `[Tutorial prompt: …]` brackets, not chrome (see `res://systems/ui/README.md` for
## what was trimmed off each bracket and why).

# --- Chrome ------------------------------------------------------------------------

const CLOSE := &"UI_CLOSE"
const BACK := &"UI_BACK"
const EMPTY := &"UI_EMPTY"
const GLYPH_UNBOUND := &"UI_GLYPH_UNBOUND"

# --- The HUD -----------------------------------------------------------------------

const FORTUNE := &"UI_FORTUNE"
const ROSE := &"UI_ROSE"
const HEALTH := &"UI_HEALTH"

# --- Dialogue ----------------------------------------------------------------------

const DIALOGUE_LEAVE := &"UI_DIALOGUE_LEAVE"

# --- The Pocket Spread -------------------------------------------------------------

const SPREAD_TITLE := &"UI_SPREAD_TITLE"
const SLOT_EMPTY := &"UI_SLOT_EMPTY"
const SPREAD_HAND := &"UI_SPREAD_HAND"
const SPREAD_LOADOUTS := &"UI_SPREAD_LOADOUTS"
const SPREAD_SAVE_LOADOUT := &"UI_SPREAD_SAVE_LOADOUT"
const SPREAD_APPLY_LOADOUT := &"UI_SPREAD_APPLY_LOADOUT"
const SPREAD_DELETE_LOADOUT := &"UI_SPREAD_DELETE_LOADOUT"
const SPREAD_FLIP := &"UI_SPREAD_FLIP"
const SPREAD_CLEAR := &"UI_SPREAD_CLEAR"
const TRUMP_TEXT_PENDING := &"UI_TRUMP_TEXT_PENDING"

## The three slot names, indexed by `SpreadSlot.Id`.
const SLOT_TITLES: Array[StringName] = [
	&"UI_SLOT_PAST",
	&"UI_SLOT_PRESENT",
	&"UI_SLOT_FUTURE",
]

## Why each slot is still face-down, indexed by `SpreadSlot.Id`
## (`docs/design/progression.md` §Slot unlock pacing: 1 / 3 / 7 Trumps held).
const SLOT_UNLOCK_RULES: Array[StringName] = [
	&"UI_SLOT_UNLOCK_PAST",
	&"UI_SLOT_UNLOCK_PRESENT",
	&"UI_SLOT_UNLOCK_FUTURE",
]

## Upright / reversed, indexed by `CardOrientation.Id`.
const ORIENTATIONS: Array[StringName] = [
	&"UI_ORIENTATION_UPRIGHT",
	&"UI_ORIENTATION_REVERSED",
]

# --- The Almanack ------------------------------------------------------------------

const ALMANACK_TITLE := &"UI_ALMANACK_TITLE"
const ALMANACK_TAB_QUESTS := &"UI_ALMANACK_TAB_QUESTS"
const ALMANACK_TAB_READING := &"UI_ALMANACK_TAB_READING"
const ALMANACK_TAB_TRUMPS := &"UI_ALMANACK_TAB_TRUMPS"
const ALMANACK_TAB_BESTIARY := &"UI_ALMANACK_TAB_BESTIARY"
const ALMANACK_TAB_LORE := &"UI_ALMANACK_TAB_LORE"
const ALMANACK_QUESTS_ACTIVE := &"UI_ALMANACK_QUESTS_ACTIVE"
const ALMANACK_QUESTS_DONE := &"UI_ALMANACK_QUESTS_DONE"
const ALMANACK_EMPTY := &"UI_ALMANACK_EMPTY"

## The four suits, indexed by `Suit.Id`. A Blank has no name - `combat.md` §Enemies
## gives none - so the Bestiary names the CARD: its suit and its printed number.
const SUITS: Array[StringName] = [
	&"UI_SUIT_CUPS",
	&"UI_SUIT_SWORDS",
	&"UI_SUIT_WANDS",
	&"UI_SUIT_COINS",
]

## The four Court ranks, indexed by `Rank.court_index()`. Pip ranks print a number
## instead and need no key.
const COURT_RANKS: Array[StringName] = [
	&"UI_RANK_PAGE",
	&"UI_RANK_KNIGHT",
	&"UI_RANK_QUEEN",
	&"UI_RANK_KING",
]

# --- The map -----------------------------------------------------------------------

const MAP_TITLE := &"UI_MAP_TITLE"
const MAP_HERE := &"UI_MAP_HERE"
const MAP_FAST_TRAVEL := &"UI_MAP_FAST_TRAVEL"

# --- Pip ---------------------------------------------------------------------------

const PIP_WHEEL_TITLE := &"UI_PIP_WHEEL_TITLE"

# --- Pause and settings ------------------------------------------------------------

const PAUSE_TITLE := &"UI_PAUSE"
const PAUSE_RESUME := &"UI_RESUME"
const PAUSE_SAVE := &"UI_PAUSE_SAVE"
const PAUSE_LOAD := &"UI_PAUSE_LOAD"
const PAUSE_SETTINGS := &"UI_PAUSE_SETTINGS"
const PAUSE_QUIT := &"UI_PAUSE_QUIT"
## One save slot's row: "Slot {n}", numbered from 1 because a player counts from 1.
## The number is formatted in, not concatenated, so a language that puts it first can
## (`docs/design/technical.md` §Localization).
const SAVE_SLOT_N := &"UI_SLOT_N"
const SAVE_SLOT_EMPTY := &"UI_SAVE_SLOT_EMPTY"

const SETTINGS_TITLE := &"SETTINGS_TITLE"
const SETTINGS_DIFFICULTY := &"SETTINGS_DIFFICULTY"
const SETTINGS_FOOLS_CHANCE_WINDOW := &"SETTINGS_FOOLS_CHANCE_WINDOW"
const SETTINGS_HOLD_TOGGLE := &"SETTINGS_HOLD_TOGGLE"
const SETTINGS_SCREEN_SHAKE := &"SETTINGS_SCREEN_SHAKE"
const SETTINGS_SCREEN_FLASH := &"SETTINGS_SCREEN_FLASH"
const SETTINGS_TEXT_SCALE := &"SETTINGS_TEXT_SCALE"
const SETTINGS_QUEST_MARKERS := &"SETTINGS_QUEST_MARKERS"
const SETTINGS_REBIND := &"SETTINGS_REBIND"
const SETTINGS_REBIND_PRESS := &"SETTINGS_REBIND_PRESS"
const SETTINGS_RESET_DEFAULTS := &"SETTINGS_RESET_DEFAULTS"

## The three difficulty modes, indexed by `DifficultyMode.Id`.
const DIFFICULTIES: Array[StringName] = [
	&"SETTINGS_DIFFICULTY_STORY",
	&"SETTINGS_DIFFICULTY_JOURNEY",
	&"SETTINGS_DIFFICULTY_TRIAL",
]

## Hold or toggle, indexed by `HoldOrToggle.Mode`.
const HOLD_MODES: Array[StringName] = [
	&"SETTINGS_HOLD",
	&"SETTINGS_TOGGLE",
]

# --- Refusals ----------------------------------------------------------------------

## Shown when a service refuses with a reason this table does not name.
const REFUSED_UNKNOWN := &"UI_REFUSED_UNKNOWN"

## Prefix + the service's own reason id: every `REASON_*` on `PocketSpreadService`,
## `RegionService` and `EconomyService` is a `UI_REFUSED_<REASON>` row.
const REFUSED_PREFIX := "UI_REFUSED_"

## Every refusal this table can explain, spelled out.
##
## `refusal()` decides membership against THIS list and never against the translation
## server: a build that has not loaded its translations yet - a headless tool, a test
## that set no locale, the frames before the table is ready - would otherwise find
## every key untranslated and answer `REFUSED_UNKNOWN` for refusals that are perfectly
## well explained. The rows behind these keys are proved by
## `res://tests/unit/ui/ui_keys_test.gd`, in both directions, exactly as every other
## key here is.
const REFUSALS: Array[StringName] = [
	# PocketSpreadService
	&"UI_REFUSED_UNKNOWN_TRUMP",
	&"UI_REFUSED_NOT_HELD",
	&"UI_REFUSED_SLOT_LOCKED",
	&"UI_REFUSED_ALREADY_SLOTTED",
	&"UI_REFUSED_IN_COMBAT",
	&"UI_REFUSED_NOT_AT_WAYSTATION",
	&"UI_REFUSED_NO_SUCH_LOADOUT",
	&"UI_REFUSED_EMPTY_SLOT",
	&"UI_REFUSED_NO_EFFECTS",
	&"UI_REFUSED_NOT_IMPLEMENTED",
	&"UI_REFUSED_NO_FORTUNE",
	&"UI_REFUSED_CANNOT_AFFORD",
	# RegionService
	&"UI_REFUSED_NO_SUCH_REGION",
	&"UI_REFUSED_NO_SCENE",
	&"UI_REFUSED_NOT_ADJACENT",
	&"UI_REFUSED_GATE_CLOSED",
	&"UI_REFUSED_ALREADY_THERE",
	&"UI_REFUSED_NO_SWAPPER",
	&"UI_REFUSED_NO_SUCH_WAYSTATION",
	&"UI_REFUSED_NO_FAST_TRAVEL",
	&"UI_REFUSED_NOT_VISITED",
	&"UI_REFUSED_NOT_HERE",
	&"UI_REFUSED_OUTSIDE_NETWORK",
	# EconomyService
	&"UI_REFUSED_NO_SUCH_SHOP",
	&"UI_REFUSED_NO_SUCH_ITEM",
	&"UI_REFUSED_NOT_STOCKED",
	&"UI_REFUSED_OUT_OF_STOCK",
	&"UI_REFUSED_NOT_FOR_SALE",
]

# --- Tutorial prompts (MQ00) -------------------------------------------------------

const TUTORIAL_MQ00_BINDLE := &"TUTORIAL_MQ00_BINDLE"
const TUTORIAL_MQ00_MOVE := &"TUTORIAL_MQ00_MOVE"
const TUTORIAL_MQ00_CAMPSITE := &"TUTORIAL_MQ00_CAMPSITE"
const TUTORIAL_MQ00_SEEK := &"TUTORIAL_MQ00_SEEK"
const TUTORIAL_MQ00_DEAD_TREE := &"TUTORIAL_MQ00_DEAD_TREE"
const TUTORIAL_MQ00_LIGHT_STRING := &"TUTORIAL_MQ00_LIGHT_STRING"
const TUTORIAL_MQ00_DODGE := &"TUTORIAL_MQ00_DODGE"
const TUTORIAL_MQ00_REST := &"TUTORIAL_MQ00_REST"
const TUTORIAL_MQ00_EDGE := &"TUTORIAL_MQ00_EDGE"
const TUTORIAL_MQ00_EDGE_AGAIN := &"TUTORIAL_MQ00_EDGE_AGAIN"
const TUTORIAL_MQ00_LEAP := &"TUTORIAL_MQ00_LEAP"

## Every MQ00 tutorial prompt, in the order the quest plays them.
const TUTORIAL_MQ00: Array[StringName] = [
	TUTORIAL_MQ00_BINDLE,
	TUTORIAL_MQ00_MOVE,
	TUTORIAL_MQ00_CAMPSITE,
	TUTORIAL_MQ00_SEEK,
	TUTORIAL_MQ00_DEAD_TREE,
	TUTORIAL_MQ00_LIGHT_STRING,
	TUTORIAL_MQ00_DODGE,
	TUTORIAL_MQ00_REST,
	TUTORIAL_MQ00_EDGE,
	TUTORIAL_MQ00_EDGE_AGAIN,
	TUTORIAL_MQ00_LEAP,
]

# --- Text nothing can spell as one key ----------------------------------------------

## The meta a `Control` carries when what it draws is NOT one translation key.
##
## Two kinds of text cannot be: a row FORMATTED out of a key and a number ("Slot 1"),
## and a DEVICE LABEL the hardware spells and no translator owns ("Space", "LB" - see
## `InputGlyphs`' class doc). Both are built through `tr()` or through Godot's own
## `OS.get_keycode_string()`, and neither is a literal somebody forgot to wrap.
##
## `res://tests/unit/ui/ui_strings_test.gd` builds every page and reads every string
## it drew; this meta is how a view says "this one is composed, and here is why",
## which is a claim a reviewer can check rather than a hole in the lint. Nothing else
## may carry it: a plain label with a sentence in it is the failure the suite exists
## to catch.
## (A `String`, not a `StringName`: everything spelled as a StringName in this class
## is a translation key, and `res://tests/unit/ui/ui_keys_test.gd` holds it to that.)
const COMPOSED_TEXT_META := "composed_text"


## Mark a control whose text is composed rather than a single key. `reason` is for
## whoever reads the scene tree or the failure; it is never displayed.
static func mark_composed(control: Control, reason: String) -> void:
	if control != null:
		control.set_meta(COMPOSED_TEXT_META, reason)


## True when this control was marked as drawing composed text.
static func is_composed(control: Control) -> bool:
	return control != null and control.has_meta(COMPOSED_TEXT_META)


# --- Reasons a control's text is composed --------------------------------------------

## A row formatted out of a key and a number (`UI_SLOT_N` and the slot's number).
const COMPOSED_FORMATTED := "FORMATTED"

## A device label: what is printed on the key or the pad button (`InputGlyphs`).
const COMPOSED_GLYPH := "GLYPH"

## A name that comes out of a definition's own `name_key`, resolved at draw time.
const COMPOSED_DEFINITION_NAME := "DEFINITION_NAME"

## A number the world counted - a card's printed rank, a price, a count.
const COMPOSED_NUMBER := "NUMBER"


# --- Input actions -----------------------------------------------------------------

## What each InputMap action is called on the rebinding list, keyed by the action.
## Built from `InputActions.ALL` so an action with no name is a test failure rather
## than a blank row.
const ACTION_PREFIX := "ACTION_"


## The key naming an InputMap action on the rebinding list, e.g. `&"ACTION_DODGE"`.
static func action(action_name: StringName) -> StringName:
	return StringName(ACTION_PREFIX + String(action_name).to_upper())


## The key explaining a service's refusal reason, or `REFUSED_UNKNOWN` for a reason
## this table does not name. See `REFUSALS` for why the answer is not asked of the
## translation server.
static func refusal(reason: StringName) -> StringName:
	if reason == &"":
		return REFUSED_UNKNOWN
	var key := StringName(REFUSED_PREFIX + String(reason).to_upper())
	return key if REFUSALS.has(key) else REFUSED_UNKNOWN


## The key naming a spread slot, e.g. `&"UI_SLOT_PRESENT"`.
static func slot(slot_id: int) -> StringName:
	if slot_id < 0 or slot_id >= SLOT_TITLES.size():
		return EMPTY
	return SLOT_TITLES[slot_id]


## The key naming a card's orientation.
static func orientation(orientation_id: int) -> StringName:
	if orientation_id < 0 or orientation_id >= ORIENTATIONS.size():
		return EMPTY
	return ORIENTATIONS[orientation_id]


## The key naming a suit, e.g. `&"UI_SUIT_WANDS"`.
static func suit(suit_id: int) -> StringName:
	if suit_id < 0 or suit_id >= SUITS.size():
		return EMPTY
	return SUITS[suit_id]


## The key naming a Court rank, or `EMPTY` for a pip rank (which prints its number).
static func court_rank(rank_id: int) -> StringName:
	var index := Rank.court_index(rank_id as Rank.Id)
	if index < 0 or index >= COURT_RANKS.size():
		return EMPTY
	return COURT_RANKS[index]


## The key naming a difficulty mode.
static func difficulty(mode: int) -> StringName:
	if mode < 0 or mode >= DIFFICULTIES.size():
		return EMPTY
	return DIFFICULTIES[mode]


## The key naming a hold-or-toggle mode.
static func hold_mode(mode: int) -> StringName:
	if mode < 0 or mode >= HOLD_MODES.size():
		return EMPTY
	return HOLD_MODES[mode]
