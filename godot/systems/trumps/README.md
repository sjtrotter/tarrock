# `systems/trumps/` — the Trumps, the Pocket Spread, Fortune and the White Rose

Owns the runtime side of [`docs/design/progression.md`](../../../docs/design/progression.md)
(§The Pocket Spread, §Fortune, §The White Rose, §Waystations) and of the Trump half of
[`docs/design/arcana.md`](../../../docs/design/arcana.md) (design rule 5, "one card, six
expressions", and every per-Trump table). The docs are the source of truth; nothing here
re-decides them.

| File | What |
|---|---|
| `pocket_spread_service.gd` | `PocketSpreadService` — held Trumps (derived), slots, one-copy rule, loadouts, casting the Present |
| `fortune_service.gd` | `FortuneService` — the meter, the earn table, Fortune's Favor, the free cast |
| `white_rose_service.gd` | `WhiteRoseService` — petals, graftings, rest, regrowth by region |
| `spread_slot.gd` | `SpreadSlot` — Past / Present / Future, and their stable save keys |
| `card_orientation.gd` | `CardOrientation` — upright / reversed, and their stable save keys |
| `slot_assignment.gd` | `SlotAssignment` — one slot's contents, handed out as a copy |
| `spread_loadout.gd` | `SpreadLoadout` — one saved, player-named configuration |
| `trump_ids.gd` | `TrumpIds` — **generated** constants, the one place a Trump id is written in code |
| `definitions/trump_definition.gd` | one Trump as data: card number, name key, granting flag, the doc's prose, its effects |
| `definitions/trump_catalog.gd` | every Trump the game knows, in one resource |
| `definitions/trump_effects.gd` | one Trump's **six explicit** expressions plus its burden |
| `definitions/trump_effect.gd` | one expression: a strategy key, its params, its Fortune cost |
| `definitions/trump_burden.gd` | the one drawback a reversed card attaches |
| `definitions/spread_rules.gd` | every number the three services run on, canon and TBD alike |

## Generated identity, hand-authored effects

Same split as the quests: `gen_definitions.py` lifts each `**Trump N — Name.**` block out
of `arcana.md` into `res://data/trumps/TRUMP_NN.tres` — the card number, the name key, the
unbinding flag that hands it over, and the doc's own cells verbatim for review and drift —
and a definition **links** `res://data/trumps/effects/TRUMP_NN.tres` when a person has
authored one. The generator never writes into `effects/`. There are exactly twenty:
`arcana.md` §XXI, "the World's card is not carried. It is turned."

`res://data/progression/spread_rules.tres` is hand-authored for the same reason a Trump's
effects are — the numbers come from prose, not a table — and it lives inside a generated
directory, so the generator names it in `HAND_AUTHORED_PATHS` and never sweeps it.

## Four properties worth knowing before changing anything here

- **Held Trumps are derived, never stored.** A Trump is held exactly when its
  `granted_by_flag` has fired, and `WorldStateService` cannot un-fire one. There is no
  second list of owned cards to disagree with the world — which is also why a save
  restores the world state *before* the Spread that reads it.
- **Every number comes from `SpreadRules`.** A threshold, a cost or a regrowth rate
  spelled in code would pass the ordinary tests and fail the retuning ones
  (`tests/unit/trumps/`), which is the point.
- **The read paths allocate nothing.** `slotted(slot)` hands out a *copy* of a
  `SlotAssignment`, so nobody can change what is slotted without going through
  `assign()` — but the queries a HUD polls every frame (`can_cast_present()`,
  `present_cost()`, `slotted_burden()`) read the slot through `slotted_trump_id()` /
  `slotted_orientation()` instead, and `held_count()` is cached against
  `WorldStateService.unbound_count()` rather than recounted from twenty flags. The
  suite asserts the internal path by counting `slotted()` calls through a subclass; if
  a new hot path reaches for `slotted()`, that test is what says so.
- **Most of those numbers are TBD.** `progression.md` fixes the 1/3/7 pacing, the ~100
  meter, the 20–50 cost band, and 3-to-8 petals; it fixes no earn amount, no overfill, no
  regrowth rate, and `arcana.md` fixes no per-Trump cost. `SpreadRules.notes` lists every
  placeholder by name.

## Owed to later rounds

- **Round 7 (combat) runs the effects.** `PocketSpreadService.cast_present()` pays for a
  cast and emits `present_cast(trump_id, orientation)`; nothing executes an effect yet, and
  `slotted_burden(slot)` names the burden a reversed card is carrying without applying it.
  A Trump whose `effects` nobody has authored can still be held and slotted — only casting
  it refuses, with `REASON_NO_EFFECTS` / `REASON_NOT_IMPLEMENTED`. Only Trump I is authored
  today. Combat also owns `set_in_combat()`, `FortuneService.on_fools_chance()` and the
  per-frame `tick()` calls.
- **Round 10 (regions) owns place.** `set_at_waystation()` gates all three loadout
  verbs (saving, applying and deleting a build are equally out-of-combat Waystation
  work) and nothing calls it yet, so no loadout can be saved in the shipping build; `WhiteRoseService`
  regrows only where `set_region()` says the world is awake, and the Cliff scene makes that
  call itself for now, passing `&""` as the Cliff's unbinding flag because the Cliff has no
  Arcana ([`world.md`](../../../docs/design/world.md) §The Cliff) — so nothing grows there.
  The Cliff also calls `rest()` on MQ00's Waystation beat; the Waystation's own rest verb
  is that round's.
