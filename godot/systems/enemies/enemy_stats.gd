class_name EnemyStats
extends RefCounted

## One enemy's numbers, solved once: what an `EnemyDefinition` (identity) and an
## `EnemyRules` (tuning) come to when multiplied together.
##
## It exists because neither half can hold them. `combat.md` gives the Blanks a
## behaviour table and a role table and **no figures at all**, so a definition holds
## no numbers (it would be inventing them) and the rules hold no identity (there is
## one table for fifty-two Blanks). This is the product, and `EnemyDefinition.stats()`
## caches one per definition so a fight solves nothing per frame
## (`docs/design/technical.md` §Performance guardrails).
##
## Everything here is a plain field: it is built once, read from a brain's hot loop,
## and never edited afterwards. The one number NOT here is the difficulty's telegraph
## multiplier - it changes when the player changes a setting, so it is applied at the
## brain, from `CombatRules.timing_window_multiplier()`.

## The pool this enemy fights with.
var max_health: int = 1

## What one of its hits costs, before the target's own defence.
var damage: int = 0

## Travel speed in pixels per second.
var move_speed: float = 0.0

## The readable tell before a hit, in seconds, at Journey and with no buffs on.
var telegraph_seconds: float = 0.0

## How long the hit window stays open.
var active_seconds: float = 0.0

## How long the commitment costs afterwards.
var recovery_seconds: float = 0.0

## The attack's arc in degrees, centred on the facing.
var attack_arc_degrees: float = 0.0

## The attack's reach in pixels. For Cups this is how far the lob flies.
var attack_radius: float = 0.0

## How many hits one commitment throws - Swords' "tight strings" are the only thing
## in the roster above 1.
var string_length: int = 1

## What the telegraph of a string's second and later hits is multiplied by.
var followup_telegraph_multiplier: float = 1.0

## True for Cups: it lobs rather than swings.
var is_ranged: bool = false

## How fast the lob travels, `is_ranged` only.
var projectile_speed: float = 0.0

## How close the lob has to come to a body to hit it, `is_ranged` only. It sizes both
## the projectile's detector and its `HitSpec`, so the broad and narrow phases agree -
## see `EnemyRules.cups_projectile_radius`.
var projectile_radius: float = 0.0

## How long a lob may stay in the air before it gives up, `is_ranged` only.
var projectile_life_seconds: float = 0.0

## How far a ranged enemy tries to stay from its target, `is_ranged` only.
var preferred_range: float = 0.0

## True for Coins: it advances behind a shield.
var has_shield: bool = false

## The shield's full angle in degrees, `has_shield` only.
var block_arc_degrees: float = 0.0

## How often a hit inside the arc is stopped, 0..1, `has_shield` only.
var block_chance: float = 0.0

## What a hit that gets past the shield is multiplied by. 1.0 for everything unarmoured.
var armour_multiplier: float = 1.0

## The tag this enemy's hits carry, or `&""`. Only Wands tags anything, and nothing
## consumes it yet (see `EnemyRules.wands_fire_tag`).
var hit_tag: StringName = &""

## How long the tag is meant to linger, in seconds. Unconsumed, like the tag.
var hit_tag_seconds: float = 0.0

## How close the Fool has to come to be noticed.
var aggro_radius: float = 0.0

## How far the Fool has to get before this enemy gives up.
var disengage_radius: float = 0.0

## How long the noticing beat lasts.
var aware_seconds: float = 0.0

## True for the Page: it runs for help rather than engaging.
var flees_to_alert: bool = false

## How far the Page's alarm carries, `flees_to_alert` only.
var alert_radius: float = 0.0

## How long the Page runs before the alarm goes up, `flees_to_alert` only.
var alert_seconds: float = 0.0

## True for the Queen: it buffs the Blanks around it.
var grants_aura: bool = false

## How far the aura reaches, `grants_aura` only.
var aura_radius: float = 0.0

## What an ally in the aura multiplies its damage by, `grants_aura` only.
var aura_damage_multiplier: float = 1.0

## What an ally in the aura multiplies its telegraph by, `grants_aura` only.
var aura_telegraph_multiplier: float = 1.0

## How long the card takes to flutter free after this enemy slumps.
var card_flutter_seconds: float = 0.0


## The farthest this enemy's own hit can reach, whatever shape it is. What a `Hitbox`
## detector is sized to, once.
func reach() -> float:
	return maxf(attack_radius, projectile_radius)
