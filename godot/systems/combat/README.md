# `systems/combat/` — the Bindle, Focus, the dodges, Fool's Chance, the defeat loop

Built by round 7 of [`docs/gauntlet-systems/PROMPT.md`](../../../docs/gauntlet-systems/PROMPT.md).
Canon: [`docs/design/combat.md`](../../../docs/design/combat.md) (the whole doc, as
amended for 2D) and [`docs/design/progression.md`](../../../docs/design/progression.md)
§Fortune / §The White Rose for what a fight earns and spends. **No number is spelled in
this folder** — they all live in [`data/combat/combat_rules.tres`](../../data/combat/combat_rules.tres),
and almost all of them are TBD placeholders the combat-tuning pass owns (that resource's
`notes` lists every one by name).

## The shape

```
combat_rules.gd (definitions/)   every tuning number, one resource
moveset_controller.gd            THE MOVESET - pure, no nodes, no Input, no Engine
combat_input.gd                  one frame of intent, reused not reallocated
hit_spec.gd / hit_event.gd       the static half and the moving half of a hit
hit_result.gd / faction.gd       what became of a hit; who fights whom
focus_targeting.gd               lock-on: candidates supplied, choice deterministic
combat_defense.gd                what a Combatant asks before it takes a hit
fool_defense.gd                  the Fool's answer: i-frames, guard, Fool's Chance
vitality.gd                      a pool of life that lives outside the Combatant
rose_vitality.gd                 the Fool's: the White Rose, seen from inside a fight
combat_layers.gd                 the physics layers, so no .tscn carries a bit index
combat_service.gd               what a fight IS: slow-mo, Fortune, the Rose, defeat
nodes/combatant.gd               a health pool and the hit rule
nodes/hurtbox.gd                 the space a body can be hit in
nodes/hitbox.gd                  the space one swing covers while its window is open
nodes/fool_combat.gd             the seam: buttons -> moveset -> body -> services
```

## The Fool's health is the White Rose

The director's ruling on issue #11: **the petals ARE the health.** There is no second
pool, no `fool_max_health`, and no heal button — a hit tears quarter petals off
`WhiteRoseService` and the only healing in the game is the Rose growing back (slowly in
an unbound region, whole at a Waystation, never in a bound one).

Mechanically that is one seam, in three files. `Vitality` is a pool of life that lives
outside a `Combatant`; `RoseVitality` is the adapter over the Rose;
`CombatService.register_fool()` is the single place one is fitted. A `Combatant` with a
`vitality` forwards every health question to it and is otherwise unchanged — the hit
rule, the defence, the stagger and `died` at zero all read exactly as they did. Enemies
have no `vitality` and keep their own field.

Two consequences a reader should have in front of them:

- **The Fool's health is counted in quarter petals** (`WhiteRoseService.QUARTERS_PER_PETAL`),
  because three petals is far too coarse a bar for Story's halved damage or a Blank rank
  curve to survive. Enemy damage is therefore authored in quarter petals
  (`data/enemies/enemy_rules.tres`); the Fool's own swings are still priced against enemy
  pools, which are still in their own points.
- **A landed hit always costs at least one quarter** (`Combatant.MIN_LANDED_DAMAGE`).
  With a twelve-quarter pool a multiplier can round a real swing down to nothing, and an
  enemy the player can stand still in front of is not a difficulty setting. A spec that
  deals zero damage on purpose still lands for nothing.

`systems/core/hold_or_toggle.gd` belongs to this round too: it is the accessibility
layer under every held input, and it sits in `core/` because sprint (which is
`scripts/player.gd`'s) needs it as much as Focus does. `FoolCombat.set_hold_mode()` is
the one door a settings screen knocks on for all four inputs — Focus, block-step,
charged heavy and sprint — and it forwards sprint to the body that owns that latch.

**Dependency direction.** `MovesetController`, `FocusTargeting`, `CombatService`,
`HitSpec` and friends are plain `RefCounted`s with no tree — a headless test builds them
directly and drives them frame by explicit frame. The three node components are the only
things that touch the scene, and `FoolCombat` is the only thing that reads `Input`.
`CombatService` is the only thing in the game that writes `Engine.time_scale`.

## Art requests — the animation states the moveset needs

The moveset is complete and runs headlessly today; **nothing is wired to a clip yet**.
`scripts/player.gd`'s animator keeps doing what it already does (eight facings, one
walk cycle), and `FoolCombat` only tells the body which way to face. Wiring one clip per
state is a one-function change the day the art lands.

This is the list for the art lane (see [`godot/art/ART-REQUESTS.md`](../../art/ART-REQUESTS.md)
for how a gap is handed over). Every state below is a `MovesetController.State` or a
beat `combat.md` names; the direction column says how many facings the state needs in
the oblique top-down grammar.

| State | Clip | Facings | Loops | Notes from canon |
|---|---|---|---|---|
| `LIGHT_1` | `Bindle_Light_1` | 8 | no | Windup / active / recovery must be readable as three beats — `combat.md` §Philosophy. |
| `LIGHT_2` | `Bindle_Light_2` | 8 | no | Reads as a continuation, not a repeat. |
| `LIGHT_3` | `Bindle_Light_3` | 8 | no | The longest recovery in the string: this is where the commitment is felt. |
| `HEAVY` | `Bindle_Heavy_Sweep` | 8 | no | "the bundle end drags through the strike, hitting everything in an arc". |
| `CHARGING` | `Bindle_Charge_Hold` | 8 | **yes** | A held ready pose; needs an obvious "full" tell at `charge_seconds`. |
| `CHARGED_HEAVY` | `Bindle_Launcher` | 8 | no | The stagger launcher — the target is lifted off its feet. |
| `RUNNING_ATTACK` | `Bindle_Lunge` | 8 | no | A forward lunge that closes distance and interrupts. |
| `DODGE_ROLL` | `Dodge_Roll` | 8 | no | The travel dodge, and the Focus forward/neutral dodge. |
| `SIDE_HOP` | `Focus_Side_Hop` | 8 (or L/R × 8 strafe) | no | The Focus left/right strafing hop. |
| `BACKFLIP` | `Grand_Backflip` | 8 | no | "high, deliberately *majestic*… finished with an emphatic landing". Theater as much as evasion. |
| `BLOCK_STEP` | `Block_Step` | 8 | no | A hop-guard, not a shield: the Bindle is held two-handed. |
| `IDLE` in Focus | `Focus_Ready` | 8 | **yes** | The "readable ready-crouch" Focus drops the Fool into. |
| walking in Focus | `Focus_Strafe` | 8 | **yes** | 8-direction strafing that keeps the Fool facing the lock. |
| — (hit reaction) | `Hit_React` | 8 | no | Played on `Combatant.damaged`; short, never a stagger. |
| — (defeat) | `Defeat_Collapse` | 1–8 | no | Already named in `combat.md` §Defeat: "stumbles, goes to one knee, and folds down". No ragdoll, no death sting. |
| — (waking) | `Defeat_Rise` | 1–8 | no | The wake-up rise at the Waystation, also named in §Defeat. |
| — (Fool's Chance) | `Fools_Chance_Flourish` | — | no | OPTIONAL: a one-off flourish or VFX on the trigger. The screen-flash/shake toggles for it are the UI round's. |

Enemy-side states (`Stagger_Loop`, `Stagger_Recover`, the telegraph poses) belong to
round 8 with the Blanks, not here.

## What this round deliberately did not build

- **Enemies.** `TrainingDummy` under `tests/fixtures/scenes/` is a test fixture with no
  AI, no suit and no rank; round 8 owns the Blanks, the Beasts and the Fog-masks.
- **Pip.** Round 9 (`combat.md` §Pip: the command wheel, and he cannot die).
- **Trump effects.** `PocketSpreadService.present_cast` announces a cast and this round
  pays for it; running the effect is still unbuilt, and **Overturn's gravity bubble
  outside side-view spaces stays TBD in the doc** and must not be resolved in code.
- **Presentation of the defeat loop.** `CombatService` emits `fool_defeated` and
  `revive_at_waystation()` restores the state; the fall, Pip's lick, the fade and the
  teleport to the last Waystation are the scene's, and "the last Waystation" is a fact
  the Regions round (10) owns.
- **Pooling.** `technical.md` §Performance guardrails asks for pooling of Blanks and
  repeated VFX; there is nothing yet to pool. What this round does hold to is the other
  half of that rule: no per-frame allocation anywhere in the combat loop.
- **Soft target assist outside Focus.** `combat.md` §Philosophy: "Lock-on is available
  but optional — outside Focus the game assists target tracking without forcing a
  hard-lock." Only the hard lock is built. The assist — nudging a swing's facing toward
  the nearest hostile when the player is not in Focus — needs enemies to tune against
  and belongs with them, in round 8. `FocusTargeting` already scores candidates for
  "in front of the Fool", which is the piece the assist will reuse.
- **Trial's tightened telegraphs.** `CombatRules.timing_window_multiplier` exists and
  every window the player has to hit is scaled by it, but the only window in the game so
  far is the perfect-dodge one. Enemy telegraph lengths are round 8's, and tightening
  them on Trial is that round's job, against the same multiplier.
- **An input buffer.** Deliberate, and it is a design decision rather than a gap: no
  press is queued during a committed state. `combat.md` §Philosophy asks for "recovery
  the player can feel" and "no button-mash reward loop", and a buffer that replayed a
  press the moment recovery ended would give the mash back its reward. The light
  string's combo window is the one concession, and it is not a buffer — the press must
  arrive inside the window, and it chains rather than queues. If playtesting says the
  moveset feels deaf, the fix is a shorter recovery in `combat_rules.tres`, not a queue.
