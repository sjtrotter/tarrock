# `systems/enemies/` — the Blanks, the encounters, and the two other families

Built by round 8 of [`docs/gauntlet-systems/PROMPT.md`](../../../docs/gauntlet-systems/PROMPT.md).
Canon: [`docs/design/combat.md`](../../../docs/design/combat.md) §Enemies: the Blanks,
§Other enemy families, §Encounter philosophy, §Philosophy and §Difficulty modes, plus
[`docs/design/technical.md`](../../../docs/design/technical.md)'s `EnemyDefinition` row
and §Performance guardrails. **No number is spelled in this folder** — they all live in
[`data/enemies/enemy_rules.tres`](../../data/enemies/enemy_rules.tres), and every one of
them is a TBD placeholder the combat-tuning pass owns (that resource's `notes` lists
them by name). Same contract as `systems/combat/` in the round before this one.

## The shape

```
enemy_family.gd                  BLANK / BEAST / FOG_MASK, and nothing else exists
rank.gd                          Two..Ten, Page, Knight, Queen, King - and what each IS
definitions/enemy_rules.gd       every tuning number, one hand-authored resource
definitions/enemy_definition.gd  GENERATED identity: suit x rank, the doc's own cells
definitions/enemy_catalog.gd     all 54, and the proof the whole grid is there
enemy_stats.gd                   identity x rules, solved once, cached per definition
blank_perception.gd              everything a brain may know this frame; reused
blank_brain.gd                   THE BEHAVIOUR - pure, no nodes, no clock, no allocation
coins_shield.gd                  the Coins suit's `CombatDefense`
beast_brain.gd                   the Beasts' one world-state rule, and no more
fog_mask_brain.gd                the Fog-masks' one world-state rule, and no more
encounter_spawn.gd               one authored figure: which enemy, and where
enemy_service.gd                 the roster: the catalog, who is standing, what fell
blank_sprites.gd                 the shared art family, with measured pivots
nodes/blank.gd                   the body: perception in, movement and hits out
nodes/projectile.gd              a Cups lob - a `Hitbox` that travels
nodes/encounter.gd               an authored fight, and the gate it opens
nodes/enemy_pool.gd              bodies, preallocated; a fight instances nothing
```

**Dependency direction.** `BlankBrain`, `EnemyStats`, `CoinsShield`, `BeastBrain`,
`FogMaskBrain` and `EnemyService` are plain `RefCounted`s with no tree — a headless test
builds them directly and drives them frame by explicit frame. The four node classes are
the only things that touch the scene, and `Encounter` is the only one a region scene
talks to. Nothing here raises a quest event: `Encounter.quest_event_on_cleared` names one
and **the scene** raises it (`docs/design/technical.md` §Architecture principles, 5).

## What each half owns, and why

`combat.md` §Enemies is two tables of ROLE and **not one number**. So:

* an **`EnemyDefinition` holds no numbers at all** — suit, rank, family, the doc's own
  two cells verbatim, and a doc citation. It is generated from the doc by
  `godot/tools/gen_definitions.py` (52 Blanks under `data/enemies/blanks/`, plus
  `BEAST.tres` and `FOG_MASK.tres`), and a drift test fails when the two disagree;
* **`EnemyRules` holds every number**, hand-authored, all TBD;
* `EnemyDefinition.stats(rules)` multiplies the two into an `EnemyStats`, cached per
  definition so a fight solves nothing per frame.

A number in a definition would be a figure somebody invented and then found in a
resource six months later believing the doc had said it.

## The rules that are not tuning

* **Nothing reaches `ATTACK` except through `TELEGRAPH`.** §Encounter philosophy: "an
  enemy that hits without a tell is a bug, not a difficulty knob."
* **A Page never attacks, whatever happens to it.** `combat.md` gives the rank "flees to
  alert others rather than engaging directly", with no exception for a Page the Fool has
  just staggered — so a staggered Page recovers into `FLEE_TO_ALERT`, and `APPROACH`
  (the one state with a path to a telegraph) sends a Page straight back out of it.
* **`EnemyRules.MIN_TELEGRAPH_SECONDS` is a floor, not a setting.** `BlankBrain` clamps
  to it whatever difficulty, aura and duel-string multipliers stack up, and
  `EnemyRules.validate()` refuses a table whose tightest stack would need the clamp.
* **Defeat is never a death.** A Blank's pool empties, the body slumps, a timer runs, and
  `card_fluttered` says the card is free — which is the moment the body goes back to the
  pool to be raised by another card. Nothing here frees a node and nothing plays a death.
* **Difficulty is `CombatRules`'.** Trial's tightened telegraphs use
  `CombatRules.timing_window_multiplier()`, the same number that scales the Fool's
  perfect-dodge window, exactly as `systems/combat/README.md` asked. There is no
  difficulty field on this side.
* **The Queen buffs; she does not summon.** `BlankBrain.apply_aura_to()` is the whole of
  it, and `Encounter` is what walks the roster to apply it.
* **An encounter is cleared only when every member is down.** Entering the volume starts
  a fight and nothing else.

## Where the numbers came from — and where they did not

Every figure in `enemy_rules.tres` is TBD. What is **canon in shape** and enforced by
`validate()`: Cups alone are ranged and keep a stand-off range; Swords alone throw a
string and telegraph fastest; Wands out-reach the other melee suits and tag their hits;
Coins alone carry a shield and armour, are slowest and telegraph longest; the printed
number's toughness curve must rise; the Page is frailest and fastest and never attacks —
frailest **on the field**, so `validate()` refuses a table where a Page's health
multiplier is above a Two's as well as one where it is above the Knight's; the Knight
telegraphs fastest of the court; the Queen's aura is a buff; the King is tougher than any
pip rank.

## Art requests

Handed over as items **(g)–(n)** of
[`godot/art/ART-REQUESTS.md`](../../art/ART-REQUESTS.md) §Enemies (round 8 of the systems
gauntlet), which is the director's art hand-over file and where the sheet sizes, grids,
paths and acceptance tests live. The table below is the summary; that file is the brief.
(Round 7's Fool moveset states were handed over in the same pass, from
`systems/combat/README.md`.) The game-ready pack ships exactly one Blank — `frames/blank_sword_two/`, a Two of Swords with
eight facings and four **south-east-only** action rows (walk, attack, hit, defeat).
Everything below is a gap this round worked around rather than a wish.

| Gap | What exists now | What is needed |
|---|---|---|
| **Cups, Wands and Coins Blanks** | The Swords sheet, tinted per suit from `EnemyRules.suit_tints` | A sheet per suit. `combat.md` says "One base art and animation family carries every suit and rank", so this is one body with a suit mark and a suit weapon — a lobbed vessel, a polearm, a shield — not four characters. |
| **The printed number** | Nothing draws it | `combat.md`: "the printed number on the Blank's back is a simple visual tell of toughness". A Two and a Ten must be told apart across a meadow; the number is on the tabard. |
| **Page / Knight / Queen / King silhouettes** | The mook body | Four court silhouettes on the same family. The Page reads as a scout (light, running), the Knight as a duelist, the Queen as a commander, the King as a set piece. |
| **The seven other action facings** | South-east only | walk / attack / hit / defeat for the remaining seven facings, same grid and anchors as the Fool's request (a) in `ART-REQUESTS.md`. |
| **A telegraph pose** | The attack clip's first frames stand in | A held windup pose per attack, readable at a glance — this is the frame §Encounter philosophy is really about. `Stagger_Loop` and `Stagger_Recover` from `systems/combat/README.md`'s enemy list belong here too. |
| **The card flutter** | `EnemyService.card_fluttered(suit, rank, from_position)` fires and nothing draws it | `combat.md`: "the card it bore flutters free — drifting off to raise a new bearer elsewhere later... a visible, storybook-melancholy effect". MQ00 stages the pay-off: "Past the ridge line, each drifting card settles onto a new blank-faced figure rising from the grass." |
| **The Cups lob** | A `Projectile` with no sprite; the flight is a straight line | A thrown-vessel sprite and an arc. The arc is presentation only — the ground-plane line is what decides a hit. |
| **Wands' fire** | `EnemyRules.wands_fire_tag` is carried and nothing reads it | Whatever "flame-tagged attacks that punish standing still" turns out to mean is undecided in the doc; the tag is data waiting for that decision and for a hazard system to read it. |

Pivots for anything new: measure them with
`python3 godot/tools/measure_sprite_pivots.py --family <name>` and paste the tables it
prints, exactly as `blank_sprites.gd` did. Do not eyeball an offset.

## What this round deliberately did not build

* **Beast and Fog-mask bodies.** `combat.md` §Other enemy families gives each family one
  sentence, and both sentences are about a `WS_*` flag. Those two rules are built and
  tested; a stat block, a telegraph or a scene would be enemy canon invented in code.
  The Maw and the Mirrormarsh are the rounds that give one a body.
* **Enemy display names.** No doc names a Blank, so there is no `name_key` and no CSV
  row — inventing "Two of Swords" as player-facing text would be inventing canon. The
  day a health bar or a lock-on plate needs one, it is a new field and a doc decision.
* **Soft target assist outside Focus.** Logged by `systems/combat/README.md` as this
  round's, because it needed enemies to tune against. It still does: the assist is a
  feel decision that wants a playable fight in front of a human, and `FocusTargeting`
  already scores "in front of the Fool" for whoever takes it.
* **Regional skins.** `combat.md` makes them cosmetic and region-owned;
  `EnemyDefinition.sprite_family` is the field a region will override, and the Regions
  round owns the overriding.
* **Ambient encounter placement.** Exactly one encounter exists in the game, the one
  MQ00 asks for. §Encounter philosophy is emphatic that an ambient fight "exists because
  a spot in the world earns one", which is a per-region authoring decision, not a
  system.
* **What Death's Trump does to a card.** After `WS_DEATH_UNBOUND` the Trump "grants the
  means to end the *card itself*", and `combat.md` puts that mechanic in `arcana.md`.
  Nothing here reads the flag.
