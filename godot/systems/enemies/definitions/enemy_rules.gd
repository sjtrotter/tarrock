class_name EnemyRules
extends TarrockDefinition

## Every number the Blanks, the Beasts and the Fog-masks run on.
##
## HAND-AUTHORED at `res://data/enemies/enemy_rules.tres`, from
## `docs/design/combat.md` (§Enemies: the Blanks, §Other enemy families, §Encounter
## philosophy, §Philosophy). Nothing under `systems/enemies/` spells a number: it asks
## this resource. Same contract as `CombatRules` in the round before this one, and for
## the same reason - a designer retunes the whole roster by editing one `.tres`, and a
## test proves a rule is really read from data by retuning it in-test.
##
## **The definitions hold no numbers at all.** `combat.md` gives the Blanks a
## behaviour table and a role table and not one figure, so an `EnemyDefinition` is
## identity (suit, rank, family, the doc's own words) and this is the one tuning
## place. `EnemyDefinition.stats(rules)` is where the two meet.
##
## **What is canon and what is a placeholder.** Canon here is entirely SHAPE:
##
##   * Cups are "fluid skirmishers and ranged lobbers... harass at range and
##     reposition" - so Cups alone have a projectile and a stand-off range.
##   * Swords are "fast, precise duelists - tight strings" - so Swords alone throw
##     more than one hit per commitment, and Swords are the shortest telegraph.
##   * Wands are "reach and fire - polearm-length pokes" - so Wands out-reach the
##     other melee suits and carry a fire tag.
##   * Coins are "heavy shielded bruisers - slow, armored, built to be broken through
##     rather than out-traded" - so Coins alone have a shield and damage reduction,
##     and Coins are the slowest and the longest telegraph.
##   * "A Two folds fast, a Ten is a real fight" - so the rank curve rises with the
##     printed number, and `validate()` refuses a curve that does not.
##   * "an enemy that hits without a tell is a bug, not a difficulty knob"
##     (§Encounter philosophy) - so `MIN_TELEGRAPH_SECONDS` is a floor under every
##     telegraph in the game, and `validate()` enforces it against the tightest
##     stack of multipliers the roster can produce.
##
## EVERY ACTUAL NUMBER IS A TBD PLACEHOLDER owned by the combat-tuning pass. `notes`
## lists them all by name.
##
## **Difficulty is not here.** Trial "tightens telegraphs" (§Difficulty modes), and
## the multiplier that does it is `CombatRules.timing_window_multiplier()` - the same
## number that scales the Fool's perfect-dodge window, exactly as
## `systems/combat/README.md` asks ("Enemy telegraph lengths are round 8's, and
## tightening them on Trial is that round's job, against the same multiplier"). A
## second copy here would be two sources for one fact.

## The shortest telegraph any enemy in Tarrock may ever run, whatever the suit, the
## rank, the difficulty and the buffs stacked on it.
##
## Not a tuning number - a floor under the tuning, and the mechanical form of
## `combat.md` §Encounter philosophy's "an enemy that hits without a tell is a bug,
## not a difficulty knob". Twelve physics frames at 60 Hz: long enough that a player
## watching can see the windup and answer it. `BlankBrain` clamps to it at runtime so
## no combination of multipliers can get under it, and `validate()` refuses a rules
## table whose tightest stack would need the clamp.
const MIN_TELEGRAPH_SECONDS := 0.20

## How many suits every per-suit array must have an entry for.
const SUIT_COUNT := 4

## How many court ranks every per-court array must have an entry for.
const COURT_COUNT := 4

# --- Per suit (indexed by `Suit.Id`: CUPS, SWORDS, WANDS, COINS) ---------------

## Base health, before the rank curve. TBD.
@export var suit_health: PackedInt32Array = PackedInt32Array([26, 24, 30, 44])

## Base damage per hit, before the rank curve. TBD.
@export var suit_damage: PackedInt32Array = PackedInt32Array([8, 9, 11, 14])

## Movement speed in pixels per second. The Fool walks at 200 (`scripts/player.gd`),
## so every suit is slower than a walking Fool and Coins is much slower. TBD in size;
## CANON in order - Cups and Swords are the mobile suits, Coins is "slow". TBD.
@export var suit_move_speed: PackedFloat32Array = PackedFloat32Array([150.0, 170.0, 130.0, 100.0])

## Telegraph length in seconds: the readable tell before the hit. CANON in order
## (Swords fastest, Coins slowest), TBD in size.
@export var suit_telegraph_seconds: PackedFloat32Array = PackedFloat32Array([0.60, 0.48, 0.75, 0.90])

## How long the hit window stays open. TBD.
@export var suit_active_seconds: PackedFloat32Array = PackedFloat32Array([0.10, 0.08, 0.12, 0.16])

## How long the enemy is committed to its recovery afterwards. TBD.
@export var suit_recovery_seconds: PackedFloat32Array = PackedFloat32Array([0.45, 0.30, 0.55, 0.70])

## The attack's arc in degrees, centred on the facing. TBD.
@export var suit_attack_arc_degrees: PackedFloat32Array = PackedFloat32Array(
	[40.0, 70.0, 55.0, 110.0]
)

## The attack's reach in pixels. Cups' is the lob's flight range rather than a
## swing; Wands out-reaches the other two melee suits, which is the whole of "polearm
## length". CANON in order (Wands > Swords, Cups is ranged), TBD in size.
@export var suit_attack_radius: PackedFloat32Array = PackedFloat32Array(
	[420.0, 90.0, 140.0, 110.0]
)

## How many hits one commitment throws. CANON at 1 for everybody but Swords, whose
## "tight strings" are the suit's identity; TBD in length.
@export var suit_string_length: PackedInt32Array = PackedInt32Array([1, 3, 1, 1])

## The tint each suit's sprite is modulated by while its own art is missing. The
## Swords Two is the only Blank drawn so far, so the other three suits borrow its
## sheet and are told apart by colour until the art lands (see
## `systems/enemies/README.md` §Art requests). Presentation, not a rule.
@export var suit_tints: PackedColorArray = PackedColorArray(
	[
		Color(0.62, 0.78, 1.00),  # Cups: water
		Color(1.00, 1.00, 1.00),  # Swords: the drawn one, untinted
		Color(1.00, 0.78, 0.48),  # Wands: flame
		Color(0.96, 0.86, 0.44),  # Coins: gold
	]
)

# --- Cups: the ranged lobber --------------------------------------------------

## How far a Cups Blank tries to stay from its target: closer than this and it backs
## off, which is the "harass at range and reposition" half of the suit. TBD.
@export var cups_preferred_range: float = 260.0

## How fast the lobbed projectile travels, in pixels per second. TBD.
@export var cups_projectile_speed: float = 320.0

## How close the lob's centre has to come to a body's centre to count as a hit.
##
## It is deliberately ONE number doing two jobs: it sizes the `Projectile`'s detector
## (the broad phase) and it is the radius of the `HitSpec` the lob carries (the narrow
## phase), so the two can never disagree about what the lob covers. That makes it
## bigger than the drawn vessel will be - a body's own hurtbox has a radius too, and a
## lob that had to reach the exact centre of the Fool would sail through anybody it
## merely struck. TBD.
@export var cups_projectile_radius: float = 48.0

## How long a lob may stay in the air before it gives up, in seconds. A bound on the
## pool rather than a design fact: derived from the reach and the speed by
## `EnemyStats`, this is the safety margin on top. TBD.
@export var cups_projectile_extra_life_seconds: float = 0.5

# --- Swords: the duelist ------------------------------------------------------

## What the telegraph of the SECOND and later hits of a duel string is multiplied by.
## A string reads as one commitment, so its follow-ups tell faster than its opener -
## but never below `MIN_TELEGRAPH_SECONDS`. TBD.
@export var swords_followup_telegraph_multiplier: float = 0.75

# --- Wands: reach and fire ----------------------------------------------------

## The tag a Wands hit carries. `combat.md`: "flame-tagged attacks that punish
## standing still". NOTHING CONSUMES THIS YET - the burning ground it implies is a
## hazard/VFX system no round has built, and inventing what it does would be
## inventing combat canon. It is data so the day that system exists it reads a tag
## rather than a suit check.
@export var wands_fire_tag: StringName = &"FIRE"

## How long the flame a Wands hit leaves is meant to linger, in seconds. TBD, and
## unconsumed - see `wands_fire_tag`.
@export var wands_fire_lingering_seconds: float = 2.0

# --- Coins: the shield --------------------------------------------------------

## The full angle of the shield, centred on the way the Coins Blank faces. A hit
## arriving from inside this wedge meets the shield; one from outside it does not,
## which is what "broken through rather than out-traded" means for a player who
## walks around the back. TBD.
@export var coins_block_arc_degrees: float = 150.0

## How often a hit inside the arc is actually stopped, 0..1. At 1.0 the shield is
## deterministic and no random number is drawn at all (see `CoinsShield`). TBD.
@export var coins_block_chance: float = 1.0

## What a hit that gets past the shield is multiplied by: the "armored" half of the
## suit. TBD.
@export var coins_armour_multiplier: float = 0.75

# --- The rank curve -----------------------------------------------------------

## Health multiplier at printed number `n` is `rank_health_base + rank_health_per_pip
## * n`. A Two lands at 0.8 and a Ten at 1.6, which is `combat.md`'s "a Two folds
## fast, a Ten is a real fight" as a number. TBD in size, CANON in direction.
@export var rank_health_base: float = 0.6

## The health the printed number adds per pip. Must be positive: a curve that did not
## rise would make the number on the Blank's back a lie. TBD.
@export var rank_health_per_pip: float = 0.1

## Damage multiplier at printed number `n` is `rank_damage_base + rank_damage_per_pip
## * n`. Flatter than the health curve on purpose: the printed number reads as
## TOUGHNESS in the doc, not as threat. TBD.
@export var rank_damage_base: float = 0.8

## The damage the printed number adds per pip. TBD.
@export var rank_damage_per_pip: float = 0.04

## Health multipliers for the court, indexed PAGE, KNIGHT, QUEEN, KING. The Page is
## the frailest thing on the field because it is a scout; the King is a mini-boss.
## TBD in size, CANON in role.
##
## The Page's figure has to clear a bar the others do not: `combat.md` calls the rank a
## scout and an alarm-raiser, and this file's own `notes` call it "the frailest", so it
## must not out-live the frailest pip rank either. At `rank_health_base` 0.6 and
## `rank_health_per_pip` 0.1 a Two multiplies health by 0.8, so 0.9 made the "frailest"
## claim false against every Two on the field; 0.7 (TBD, like every number here) is
## under it, and `validate()` now refuses any table where it is not.
@export var court_health_multipliers: PackedFloat32Array = PackedFloat32Array(
	[0.7, 2.0, 1.8, 3.5]
)

## Damage multipliers for the court, same order. TBD.
@export var court_damage_multipliers: PackedFloat32Array = PackedFloat32Array(
	[0.7, 1.6, 1.2, 2.2]
)

## Telegraph multipliers for the court, same order. The Knight tells fastest ("the
## rank where suit identity is sharpest"); the King tells slowest, because a set
## piece is meant to be read. TBD.
@export var court_telegraph_multipliers: PackedFloat32Array = PackedFloat32Array(
	[1.00, 0.90, 1.00, 1.10]
)

## Movement-speed multipliers for the court, same order. The Page is the fastest
## thing in the roster because its whole job is getting away. TBD.
@export var court_speed_multipliers: PackedFloat32Array = PackedFloat32Array(
	[1.30, 1.15, 0.95, 1.00]
)

# --- Awareness and the encounter ----------------------------------------------

## How close the Fool has to come before an idle enemy notices, in pixels. TBD.
@export var aggro_radius: float = 320.0

## How far the Fool has to get before an engaged enemy gives up, in pixels. Must be
## larger than `aggro_radius` or an enemy would flicker in and out of the fight on
## one step. TBD in size, structural in direction.
@export var disengage_radius: float = 720.0

## How long the noticing beat lasts before the enemy starts closing, in seconds. It
## is a tell in its own right: the moment the Fool can see they have been seen. TBD.
@export var aware_seconds: float = 0.30

# --- The Page's alarm ---------------------------------------------------------

## How far a Page's alarm carries, in pixels: every idle Blank inside it wakes.
## `combat.md`: "flees to alert others". TBD.
@export var page_alert_radius: float = 480.0

## How long the Page runs before the alarm goes up, in seconds. A window in which a
## fast player can catch the scout, which is the point of the rank. TBD.
@export var page_alert_seconds: float = 0.80

# --- The Queen's command aura -------------------------------------------------

## How far the Queen's support aura reaches, in pixels. TBD.
@export var queen_aura_radius: float = 260.0

## What an allied Blank inside the aura multiplies its damage by. `combat.md`:
## "buffs, not summons". TBD.
@export var queen_aura_damage_multiplier: float = 1.20

## What an allied Blank inside the aura multiplies its telegraph by - below 1, so the
## buff makes allies quicker off the mark. Never below `MIN_TELEGRAPH_SECONDS` in the
## end, whatever it stacks with. TBD.
@export var queen_aura_telegraph_multiplier: float = 0.90

# --- Defeat, and the card ------------------------------------------------------

## How long the card takes to flutter free after a Blank slumps, in seconds.
## `combat.md`: a defeated Blank "slumps and fades while the card it bore flutters
## free - drifting off to raise a new bearer elsewhere later". Presentation only: the
## body is out of the fight the instant its pool empties. TBD.
@export var card_flutter_seconds: float = 1.40

# --- Pooling -------------------------------------------------------------------

## How many Blank instances an encounter's pool preallocates.
## `docs/design/technical.md` §Performance guardrails: "Pooling for Blanks... never
## instance/free on the hot path". TBD; big enough for the largest encounter any
## round has authored.
@export var pool_size: int = 8

# --- Provenance ----------------------------------------------------------------

## The doc sections these rules were authored from.
@export var doc_ref: String = ""

## Authoring notes: which of these numbers are canon in shape and which are TBD
## placeholders, by name. Read by reviewers and by the drift test, never displayed.
@export var notes: String = ""


# --- Reading: per suit --------------------------------------------------------


## Base health for a suit.
func health_for_suit(suit: Suit.Id) -> int:
	return _int_at(suit_health, int(suit))


## Base damage for a suit.
func damage_for_suit(suit: Suit.Id) -> int:
	return _int_at(suit_damage, int(suit))


## Movement speed for a suit, in pixels per second.
func move_speed_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_move_speed, int(suit))


## Base telegraph seconds for a suit, before rank, difficulty and buffs.
func telegraph_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_telegraph_seconds, int(suit))


## Active (hit-window) seconds for a suit.
func active_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_active_seconds, int(suit))


## Recovery seconds for a suit.
func recovery_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_recovery_seconds, int(suit))


## Attack arc in degrees for a suit.
func attack_arc_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_attack_arc_degrees, int(suit))


## Attack reach in pixels for a suit.
func attack_radius_for_suit(suit: Suit.Id) -> float:
	return _float_at(suit_attack_radius, int(suit))


## How many hits one commitment throws, for a suit. At least 1.
func string_length_for_suit(suit: Suit.Id) -> int:
	return maxi(1, _int_at(suit_string_length, int(suit)))


## The tint a suit's borrowed sprite is modulated by while its own art is missing.
func tint_for_suit(suit: Suit.Id) -> Color:
	var index := int(suit)
	if index < 0 or index >= suit_tints.size():
		return Color.WHITE
	return suit_tints[index]


## True when this suit fights at range rather than in reach: Cups, and only Cups.
func is_ranged_suit(suit: Suit.Id) -> bool:
	return suit == Suit.Id.CUPS


## True when this suit carries a shield: Coins, and only Coins.
func is_shielded_suit(suit: Suit.Id) -> bool:
	return suit == Suit.Id.COINS


## The tag this suit's hits carry, or `&""` for a suit that tags nothing. Only Wands
## tag anything today, and nothing consumes it - see `wands_fire_tag`.
func tag_for_suit(suit: Suit.Id) -> StringName:
	return wands_fire_tag if suit == Suit.Id.WANDS else &""


# --- Reading: the rank curve --------------------------------------------------


## What a rank multiplies base health by.
func health_multiplier_for_rank(rank: Rank.Id) -> float:
	if Rank.is_court(rank):
		return _float_at(court_health_multipliers, Rank.court_index(rank))
	return rank_health_base + rank_health_per_pip * float(Rank.printed_number(rank))


## What a rank multiplies base damage by.
func damage_multiplier_for_rank(rank: Rank.Id) -> float:
	if Rank.is_court(rank):
		return _float_at(court_damage_multipliers, Rank.court_index(rank))
	return rank_damage_base + rank_damage_per_pip * float(Rank.printed_number(rank))


## What a rank multiplies the telegraph by. The pip ranks all tell at their suit's
## own pace: a Ten is tougher than a Two, not sneakier.
func telegraph_multiplier_for_rank(rank: Rank.Id) -> float:
	if Rank.is_court(rank):
		return _float_at(court_telegraph_multipliers, Rank.court_index(rank))
	return 1.0


## What a rank multiplies movement speed by.
func speed_multiplier_for_rank(rank: Rank.Id) -> float:
	if Rank.is_court(rank):
		return _float_at(court_speed_multipliers, Rank.court_index(rank))
	return 1.0


# --- Validation ---------------------------------------------------------------


## Every problem with these rules; empty means the numbers are usable. The telegraph
## floor is checked at Journey - `validate_against()` is the call that checks it on
## every difficulty.
func validate() -> PackedStringArray:
	return validate_against(null)


## Every problem with these rules, difficulty included.
##
## `combat_rules` is only needed for the one check that cannot be made without it:
## the telegraph floor has to hold on the TIGHTEST difficulty too, and the difficulty
## multiplier lives in `CombatRules` (see the class doc for why it is not duplicated
## here). A separate entry point rather than an optional argument on `validate()`,
## because `TarrockDefinition.validate()`'s signature is the one every drift test
## calls through.
func validate_against(combat_rules: CombatRules) -> PackedStringArray:
	var errors := super.validate()
	_check_suit_array(errors, suit_health.size(), &"suit_health")
	_check_suit_array(errors, suit_damage.size(), &"suit_damage")
	_check_suit_array(errors, suit_move_speed.size(), &"suit_move_speed")
	_check_suit_array(errors, suit_telegraph_seconds.size(), &"suit_telegraph_seconds")
	_check_suit_array(errors, suit_active_seconds.size(), &"suit_active_seconds")
	_check_suit_array(errors, suit_recovery_seconds.size(), &"suit_recovery_seconds")
	_check_suit_array(errors, suit_attack_arc_degrees.size(), &"suit_attack_arc_degrees")
	_check_suit_array(errors, suit_attack_radius.size(), &"suit_attack_radius")
	_check_suit_array(errors, suit_string_length.size(), &"suit_string_length")
	_check_suit_array(errors, suit_tints.size(), &"suit_tints")
	_check_court_array(errors, court_health_multipliers.size(), &"court_health_multipliers")
	_check_court_array(errors, court_damage_multipliers.size(), &"court_damage_multipliers")
	_check_court_array(errors, court_telegraph_multipliers.size(), &"court_telegraph_multipliers")
	_check_court_array(errors, court_speed_multipliers.size(), &"court_speed_multipliers")
	for suit: Suit.Id in Suit.ALL:
		var suit_name := Suit.name_key(suit)
		if health_for_suit(suit) <= 0:
			errors.append("%s gives %s Blanks no health" % [_describe(), suit_name])
		if damage_for_suit(suit) <= 0:
			errors.append("%s gives %s Blanks nothing to hit with" % [_describe(), suit_name])
		if move_speed_for_suit(suit) <= 0.0:
			errors.append("%s leaves %s Blanks unable to move" % [_describe(), suit_name])
		if active_for_suit(suit) <= 0.0:
			errors.append("%s opens no hit window for %s Blanks" % [_describe(), suit_name])
		if recovery_for_suit(suit) <= 0.0:
			errors.append("%s lets a %s Blank swing with no recovery to punish" % [
				_describe(), suit_name
			])
		if attack_radius_for_suit(suit) <= 0.0:
			errors.append("%s gives %s Blanks no reach" % [_describe(), suit_name])
		if attack_arc_for_suit(suit) <= 0.0:
			errors.append("%s gives %s Blanks an attack of no width" % [_describe(), suit_name])
	# `combat.md` §Enemies is explicit about the four suits' shapes; a rules table that
	# lost one of them would be a roster where every suit fights the same.
	if not (
		telegraph_for_suit(Suit.Id.SWORDS)
		< telegraph_for_suit(Suit.Id.CUPS)
		and telegraph_for_suit(Suit.Id.CUPS) < telegraph_for_suit(Suit.Id.WANDS)
		and telegraph_for_suit(Suit.Id.WANDS) < telegraph_for_suit(Suit.Id.COINS)
	):
		errors.append("%s does not keep Swords the fastest telegraph and Coins the slowest" % [
			_describe()
		])
	if move_speed_for_suit(Suit.Id.COINS) >= move_speed_for_suit(Suit.Id.SWORDS):
		errors.append("%s makes Coins no slower than Swords, which combat.md calls slow" % _describe())
	if attack_radius_for_suit(Suit.Id.WANDS) <= attack_radius_for_suit(Suit.Id.SWORDS):
		errors.append("%s gives Wands no more reach than Swords, so the polearm is not one" % _describe())
	if health_for_suit(Suit.Id.COINS) <= health_for_suit(Suit.Id.SWORDS):
		errors.append("%s makes Coins no tougher than Swords, which is not a bruiser" % _describe())
	if string_length_for_suit(Suit.Id.SWORDS) < 2:
		errors.append("%s gives Swords no string, which is the suit's whole identity" % _describe())
	for suit: Suit.Id in [Suit.Id.CUPS, Suit.Id.WANDS, Suit.Id.COINS]:
		if string_length_for_suit(suit) != 1:
			errors.append("%s gives %s a duel string, which combat.md gives only to Swords" % [
				_describe(), Suit.name_key(suit)
			])
	if attack_radius_for_suit(Suit.Id.CUPS) <= cups_preferred_range:
		errors.append("%s asks Cups to stand off at %.0f and throw only %.0f, never reaching" % [
			_describe(), cups_preferred_range, attack_radius_for_suit(Suit.Id.CUPS)
		])
	if cups_projectile_speed <= 0.0 or cups_projectile_radius <= 0.0:
		errors.append("%s gives the Cups lob no speed or no size" % _describe())
	if swords_followup_telegraph_multiplier <= 0.0 or swords_followup_telegraph_multiplier > 1.0:
		errors.append("%s scales a follow-up telegraph by %.2f, which is not a tightening" % [
			_describe(), swords_followup_telegraph_multiplier
		])
	if coins_block_arc_degrees <= 0.0 or coins_block_arc_degrees >= 360.0:
		errors.append("%s gives the Coins shield a %.0f degree arc, never walkable around" % [
			_describe(), coins_block_arc_degrees
		])
	if coins_block_chance <= 0.0 or coins_block_chance > 1.0:
		errors.append("%s makes the Coins shield block %.2f of the time" % [
			_describe(), coins_block_chance
		])
	if coins_armour_multiplier <= 0.0 or coins_armour_multiplier > 1.0:
		errors.append("%s armours Coins by %.2f, which is not armour" % [
			_describe(), coins_armour_multiplier
		])
	if rank_health_per_pip <= 0.0:
		errors.append("%s does not make a Ten tougher than a Two: the number is a lie" % [
			_describe()
		])
	if rank_damage_per_pip < 0.0:
		errors.append("%s makes a Ten hit softer than a Two" % _describe())
	if health_multiplier_for_rank(Rank.Id.TWO) <= 0.0:
		errors.append("%s leaves a Two with no health at all" % _describe())
	if health_multiplier_for_rank(Rank.Id.KING) <= health_multiplier_for_rank(Rank.Id.TEN):
		errors.append("%s makes the King no tougher than a Ten, which is not a mini-boss" % _describe())
	if health_multiplier_for_rank(Rank.Id.PAGE) >= health_multiplier_for_rank(Rank.Id.KNIGHT):
		errors.append("%s makes the Page no frailer than the Knight" % _describe())
	# "The frailest thing on the field" is a claim about the WHOLE field, not about the
	# court: a Page that out-lived a Two would make this file's own notes - and
	# `systems/enemies/README.md` - wrong.
	if health_multiplier_for_rank(Rank.Id.PAGE) > health_multiplier_for_rank(Rank.Id.TWO):
		errors.append("%s gives the Page more health than a Two, so it is not the frailest" % [
			_describe()
		])
	if aggro_radius <= 0.0:
		errors.append("%s lets nothing notice the Fool" % _describe())
	if disengage_radius <= aggro_radius:
		errors.append("%s disengages at %.0f and aggros at %.0f, flickering on one step" % [
			_describe(), disengage_radius, aggro_radius
		])
	if aware_seconds < 0.0:
		errors.append("%s notices the Fool before the Fool arrives" % _describe())
	if page_alert_radius <= 0.0 or page_alert_seconds <= 0.0:
		errors.append("%s gives the Page an alarm nobody can hear" % _describe())
	if queen_aura_radius <= 0.0:
		errors.append("%s gives the Queen an aura of no reach" % _describe())
	if queen_aura_damage_multiplier <= 1.0:
		errors.append("%s makes the Queen's aura a debuff" % _describe())
	if queen_aura_telegraph_multiplier <= 0.0 or queen_aura_telegraph_multiplier > 1.0:
		errors.append("%s makes the Queen's aura slow her own allies down" % [_describe()])
	if card_flutter_seconds <= 0.0:
		errors.append("%s gives the card no time to flutter free, which is visible" % [
			_describe()
		])
	if pool_size <= 0:
		errors.append("%s preallocates no Blanks at all" % _describe())
	_check_telegraph_floor(errors, combat_rules)
	return errors


## The tightest telegraph this table can produce for a suit, with every multiplier in
## the roster stacked on it: the sharpest court, a duel string's follow-up, a Queen's
## aura, and the tightest difficulty mode.
##
## This is the number `MIN_TELEGRAPH_SECONDS` is defended against, and it is public
## so a test can prove the defence rather than trust it.
func tightest_telegraph_for_suit(suit: Suit.Id, combat_rules: CombatRules = null) -> float:
	var seconds := telegraph_for_suit(suit)
	var court := 1.0
	for rank: Rank.Id in Rank.COURT:
		court = minf(court, telegraph_multiplier_for_rank(rank))
	seconds *= court
	if string_length_for_suit(suit) > 1:
		seconds *= swords_followup_telegraph_multiplier
	seconds *= queen_aura_telegraph_multiplier
	if combat_rules != null:
		var tightest := 1.0
		for mode: DifficultyMode.Id in DifficultyMode.ALL:
			tightest = minf(tightest, combat_rules.timing_window_multiplier(mode))
		seconds *= tightest
	return seconds


# --- Internals -----------------------------------------------------------------


## Every suit must be able to answer every question, or a Blank of that suit is a
## body with a hole in it.
func _check_suit_array(errors: PackedStringArray, size: int, field: StringName) -> void:
	if size == SUIT_COUNT:
		return
	errors.append("%s has %d entries in %s, not %d" % [_describe(), size, field, SUIT_COUNT])


## Same for the four court ranks.
func _check_court_array(errors: PackedStringArray, size: int, field: StringName) -> void:
	if size == COURT_COUNT:
		return
	errors.append("%s has %d entries in %s, not %d" % [_describe(), size, field, COURT_COUNT])


## No suit may need the runtime clamp to keep its tell readable.
func _check_telegraph_floor(errors: PackedStringArray, combat_rules: CombatRules) -> void:
	for suit: Suit.Id in Suit.ALL:
		var tightest := tightest_telegraph_for_suit(suit, combat_rules)
		if tightest >= MIN_TELEGRAPH_SECONDS:
			continue
		errors.append("%s leaves %s Blanks %.3f s of telegraph, under the %.3f s floor" % [
			_describe(), Suit.name_key(suit), tightest, MIN_TELEGRAPH_SECONDS
		])


## One entry of a float array, or 0 for an index off the end.
func _float_at(values: PackedFloat32Array, index: int) -> float:
	if index < 0 or index >= values.size():
		return 0.0
	return values[index]


## One entry of an int array, or 0 for an index off the end.
func _int_at(values: PackedInt32Array, index: int) -> int:
	if index < 0 or index >= values.size():
		return 0
	return values[index]
