# Combat — SSOT

Owns: the player combat kit, enemy design (the Blanks and other families), encounter and
boss-fight philosophy, difficulty modes, and accessibility. Trump power *content* (what
each Arcana's Present/Past/Future effects actually do) belongs to
[`arcana.md`](arcana.md) — this doc only covers how Fortune is earned and spent in a
fight. The equip system (staff heads, Rose graftings, respec) belongs to
[`progression.md`](progression.md) — mentioned here only where it touches the moveset.

## Philosophy

Tarrock is **real-time, third-person action combat — never turn-based** — readable and
deliberate: Fable's rhythm, not a character-action mash. (Boss docs sometimes describe
an enemy's "rota," "beat," or "bell" — those are telegraphed real-time attack rhythms
the player reads and answers live, not turn-taking.) Every enemy telegraphs before it commits; every player action
has a clear windup, a clear active frame, and recovery the player can feel. There is no
combo-counter, no style meter, and no button-mash reward loop: pressing more buttons
faster never beats pressing the right button at the right time. Lock-on is available but
optional — the camera assists tracking without forcing a hard-lock, so fights against
multiple Blanks stay legible without feeling like a rail shooter.

The measure of a good Tarrock fight: a player who has never played it before can *watch*
a skilled player fight and understand what happened. Nothing is hidden in numbers.

## The Bindle: player moveset

The Fool's only weapon is **the Bindle** — a traveler's bundle lashed to a quarterstaff,
unfolded into a fighting staff. One weapon for the whole game keeps the moveset legible
and lets every new Trump and staff head read as a variation on a form the player already
knows, rather than a new weapon to relearn.

| Action | Description |
|---|---|
| **Light string** | Three-hit staff combo, fast and precise. The Fool's default answer to single targets and openings. |
| **Heavy** | Wide crowd sweep — the bundle end drags through the strike, hitting everything in an arc. Answer to groups. |
| **Charged heavy** | Held heavy attack; releases into a launcher that pops enemies airborne, opening aerial follow-up. |
| **Running attack** | A forward lunge strike, closes distance and interrupts. |
| **Aerial attack** | Available after a launcher or a fall/jump; keeps combat readable in vertical spaces without becoming a second moveset. |

**Staff heads**, found or bought across the Spread, swap onto the Bindle and lightly
retune this moveset (reach, a different heavy shape, an elemental tag) rather than
replacing it — full detail, list, and acquisition is owned by
[`progression.md`](progression.md).

## Defense

- **Dodge roll** — short-range roll with invincibility frames (i-frames) covering the
  commit window. The default escape and reposition tool.
- **Block-step** — a short hop-guard rather than a shield block (the Fool carries no
  shield; the Bindle is used two-handed). Absorbs a hit and repositions slightly, at the
  cost of no counter-window of its own.
- **Fool's Chance** — the skill-expression centerpiece of combat. A dodge timed to the
  final instant before a hit lands triggers Fool's Chance: roughly a 1.5-second
  slow-motion window, during which the Fool moves at normal speed relative to a slowed
  world, **and** the next Present-slot Trump cast is free (no Fortune cost). It rewards
  reading an enemy's telegraph precisely rather than dodging early and often, and it is
  the mechanical bridge between combat and the Pocket Spread — see
  [`progression.md`](progression.md) for what a free Present cast can do at each slot.

Exact i-frame duration and the width of the "perfect" timing window are tuning values,
not design facts, and are expected to move throughout production and post-launch
balance passes.

## Pip

Pip, the Fool's dog, fights alongside the player via a **radial command wheel**:

| Command | Effect |
|---|---|
| **Fetch** | Pip retrieves a dropped or thrown item (a lobbed weapon, a quest object, ammunition) and brings it back to the Fool. |
| **Harry** | Pip pins or distracts one target enemy, holding its attention and briefly reducing its aggression toward the Fool. |
| **Seek** | Pip points toward something hidden nearby — a trap, a secret, a fog-hidden path. Traversal/discovery utility more than a combat command, but shares the wheel. |

Pip cannot die. If reduced to zero health he yelps, retreats out of the fight, shakes it
off, and returns after a short cooldown. This is not a difficulty concession — it is
canon: nothing in the Spread can truly end before `WS_DEATH_UNBOUND` (see
[`world.md`](world.md) §World-state matrix), and Pip is no exception. Pip's
invulnerability needs no in-fiction excuse after that state fires either; he is simply
the one creature the Reading never intended to lose.

## Fortune in combat

Fortune is the single resource spent by Present-slot Trump powers; its meter size, exact
costs, and out-of-combat earn sources (discovery, daring) are owned by
[`progression.md`](progression.md). In combat specifically, Fortune is earned by:

- **Landing hits** — the baseline trickle, rewarding staying in the fight rather than
  turtling.
- **Fool's Chance** — a disproportionate reward per trigger, since it also grants a free
  cast; this is deliberate, so mastering the parry-dodge is the fastest route to power,
  not a side benefit of playing safe.
- **Discovery mid-encounter** — spotting an ambush before it lands, finding an
  environmental advantage — folded into the same combat-adjacent earn rate rather than
  treated separately.

The combat-side design intent is that a competent player should reach one Present cast
roughly once per sustained fight against a real threat (a Knight, a King, a boss phase),
never so often that casting becomes the whole fight, never so rarely that the Pocket
Spread feels irrelevant in combat.

## Enemies: the Blanks

The standard enemy is the **Blank** — a faceless card-soldier, one of the casualties of
the Stall. One base rig family carries every suit and rank, keeping the whole game's
enemy roster simple and legible by design, not by budget necessity (see
[`GDD.md`](../GDD.md) §Iteration clause).

**Suit flavors** shape *behavior*:

| Suit | Combat role |
|---|---|
| **Cups** | Fluid skirmishers and ranged lobbers — arcing, evasive, harass at range and reposition. |
| **Swords** | Fast, precise duelists — tight strings, quick punishes, the suit that tests the light string and dodge timing hardest. |
| **Wands** | Reach and fire — polearm-length pokes and flame-tagged attacks that punish standing still. |
| **Coins** | Heavy shielded bruisers — slow, armored, built to be broken through rather than out-traded. |

**Rank** scales *role*, not just stats:

| Rank | Role |
|---|---|
| Two – Ten | Mooks; the printed number on the Blank's back is a simple visual tell of toughness — a Two folds fast, a Ten is a real fight. |
| Page | Scout and alarm-raiser; flees to alert others rather than engaging directly. |
| Knight | Elite duelist; the rank where suit identity is sharpest. |
| Queen | Commander; grants support auras to nearby Blanks (buffs, not summons). |
| King | Roaming mini-boss; a small set piece in its own right, not just a bigger mook. |

Regional skins dress Blanks to match the region they're found in (Bastion Blanks read as
guardsmen, Wheelhouse Blanks read as croupiers, and so on) — cosmetic only; suit and rank
still govern behavior. See [`world.md`](world.md) §Regions for region flavor.

**Defeated Blanks scatter into drifting playing cards and reassemble elsewhere later** —
consistent with the rule that nothing truly ends before `WS_DEATH_UNBOUND`. This is
presented as a visible, storybook-cute effect (the cards flutter off, not a death
animation), not hidden. After `WS_DEATH_UNBOUND` fires, Death's Trump grants the means to
end a Blank permanently; the mechanical detail of that Trump is owned by
[`arcana.md`](arcana.md).

## Other enemy families

Two smaller enemy families exist outside the Blanks, both tied to specific regions and
world-states — see [`world.md`](world.md) for the regions themselves:

- **Beasts** — the wildlife of the Maw and other wild spaces. Hostile by default; calmed
  to neutral-until-provoked world-wide once `WS_STRENGTH_UNBOUND` fires.
- **Fog-masks** — the "monsters" of the Mirrormarsh. Revealed as lost people wearing the
  fog's illusions once `WS_MOON_UNBOUND` fires, at which point they lose their ambush
  advantage world-wide. Before that state, they read and fight as their masks, not as
  the people beneath — the reveal is a world-state event, not a combat-time twist.

Both families are intentionally small rosters — one or two rigs each, reskinned by
region — for the same reason as the Blanks: craft and legibility, not budget (see
[`GDD.md`](../GDD.md) §Iteration clause).

## Boss philosophy

Every one of the 21 Arcana fights is a handcrafted set piece built on **arena + gimmick +
character**: a bespoke space that itself expresses the card's meaning, one central
mechanical idea unique to that fight, and a boss who is a person (or the ghost of an
office) rather than a stat block. Some Arcana are not "fights" in the conventional sense
at all — a chase, an ordeal, a choice that can only be "won" by choosing correctly. Which
of these each Arcana is, and the full breakdown of arena/gimmick/character per card, is
owned by [`arcana.md`](arcana.md).

**Why this philosophy (it's craft, not economy):** arena + gimmick + character moves a
fight's identity from *animation quantity* to *idea quality* — the fights players
remember from any era are remembered for their one idea, not their move-count. Every
Arcana is a fully bespoke character (unique model, rig, and animation set — see
[`GDD.md`](../GDD.md) §Iteration clause and `arcana.md` design rule 7); the discipline
of one central mechanical idea per fight is what keeps 21 bespoke bosses *coherent* and
gives each one room to be iterated to polish. "Some Arcana are not fights" is likewise
a design position, not a cost dodge: a card whose meaning is patience or perspective is
betrayed by a health bar. The 21 Arcana are the product; this philosophy is how each of
them gets to be somebody's favorite.

## Encounter philosophy

- **Fixed difficulty bands, no level scaling.** Regions are tuned to a fixed band (see
  [`world.md`](world.md) §Intended difficulty bands); the player's own skill and Pocket
  Spread carry them into "too-early" regions, not a level number.
- **Readable telegraphs everywhere**, mooks and bosses alike — an enemy that hits without
  a tell is a bug, not a difficulty knob.
- **Few but meaningful ambient encounters.** Tarrock does not fill the map with a
  Blank camp every fifty meters; open-world padding is treated as a cost, not content.
  An ambient encounter exists because a spot in the world earns one (a toll-fort, a
  hunting ground, a haunted crossing), not to fill space between quest markers.

## Difficulty modes

| Mode | Intent |
|---|---|
| **Story** | Combat is a vehicle for narrative; reduced damage taken, generous timing windows, Fortune earns faster. For players here for the world and the story. |
| **Journey** (default) | The tuned experience — readable, deliberate, occasionally punishing against Knights, Kings, and bosses. |
| **Trial** | Tightened timing windows and telegraphs, reduced Fortune income, no damage reduction. For players who want the Fool's Chance mastery curve at its sharpest. |

Whether Trial adds any mechanic beyond tighter numbers (a permadeath option, a
scoring/rank layer) is **TBD** — a decision for closer to the combat-prototype milestone
(M1), not the docs phase.

## Accessibility

- Full input remapping.
- Hold/toggle options for held inputs (block-step, charged heavy, sprint).
- A **Fool's Chance timing-window slider**, independent of difficulty mode — a player on
  Story or Journey can widen the perfect-dodge window without changing anything else
  about combat balance.
- Screen-shake and screen-flash toggles, given how central slow-motion and flash-forward
  feedback (Fool's Chance, charged-heavy releases) are to combat feel.

Further accessibility scope (colorblind palettes for enemy tells, subtitle/caption
detail for combat barks) is owned jointly with [`art-audio.md`](art-audio.md) once that
doc exists — not restated here.
