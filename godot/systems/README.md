# `godot/systems/` — the game's systems

One folder per system, in the dependency order of
[`docs/gauntlet-systems/PROMPT.md`](../../docs/gauntlet-systems/PROMPT.md). This is the
Godot answer to Unity's "asmdef per feature" in
[`docs/design/technical.md`](../../docs/design/technical.md).

- Systems are plain `RefCounted` services, constructible with no scene tree, so tests
  build them directly. `systems/core/services.gd` is the single autoload that
  constructs them in dependency order and holds them as typed fields.
- **Scenes call systems; systems never reach into scenes** — no `get_node` string paths
  out of a system, no `find_child`. Systems report through typed signals.
- `<system>/definitions/` holds the `Resource` subclasses that type the authored `.tres`
  content under [`godot/data/`](../data/README.md).
- Presentation scripts still live under `godot/scripts/`; a script moves under
  `systems/` only when a round has reason to touch it.

`core/` is the foundation everything else may depend on and which depends on nothing:
the composition root, the input-action names, the definition base class, the clock.

## The systems map

Thirteen folders, in the dependency order `systems/core/services.gd` builds them in
(which is [`docs/gauntlet-systems/PROMPT.md`](../../docs/gauntlet-systems/PROMPT.md)'s
round order). One row per system: the service the composition root holds, the authored
content it is built over, where its tests are, and the README that owns its rules and
its debts.

| # | System | Service(s) on `Services` | Data it is built over | Tests | README |
|---|---|---|---|---|---|
| 0 | [`core/`](core) | `Services` (the composition root), `GameClock` | — (`InputActions`, `Interactable`, `HoldOrToggle`, `DifficultyMode`, `TarrockDefinition` live here) | [`tests/unit/core/`](../tests/unit) | — (this file) |
| 2 | [`world_state/`](world_state) | `world_state: WorldStateService` | [`data/world_states/`](../data/world_states), `data/progression/renown_ladder.tres` | [`tests/unit/world_state/`](../tests/unit) | [README](world_state/README.md) |
| 3 | [`save/`](save) | `save: SaveService` (`SaveModel`, `SaveSchema`, `SaveMigrations`) | — (fixtures in [`tests/fixtures/`](../tests/fixtures)) | [`tests/unit/save/`](../tests/unit) | [README](save/README.md) |
| 4 | [`quests/`](quests) | `quests: QuestService` | [`data/quests/`](../data/quests) (generated + hand-authored graphs) | [`tests/unit/quests/`](../tests/unit), [`tests/cliff_test.gd`](../tests/cliff_test.gd) | [README](quests/README.md) |
| 5 | [`dialogue/`](dialogue) | `dialogue: DialogueService` | [`data/dialogue/`](../data/dialogue) | [`tests/unit/dialogue/`](../tests/unit) | [README](dialogue/README.md) |
| 6 | [`trumps/`](trumps) | `spread: PocketSpreadService`, `fortune: FortuneService`, `rose: WhiteRoseService` | [`data/trumps/`](../data/trumps), `data/progression/spread_rules.tres` | [`tests/unit/trumps/`](../tests/unit) | [README](trumps/README.md) |
| 7 | [`combat/`](combat) | `combat: CombatService` | [`data/combat/`](../data/combat) | [`tests/unit/combat/`](../tests/unit), [`tests/combat_test.gd`](../tests/combat_test.gd) | [README](combat/README.md) |
| 8 | [`enemies/`](enemies) | `enemies: EnemyService` | [`data/enemies/`](../data/enemies) | [`tests/unit/enemies/`](../tests/unit), [`tests/enemies_test.gd`](../tests/enemies_test.gd) | [README](enemies/README.md) |
| 9 | [`pip/`](pip) | `pip: PipService` | [`data/pip/`](../data/pip) | [`tests/unit/pip/`](../tests/unit), [`tests/pip_test.gd`](../tests/pip_test.gd) | [README](pip/README.md) |
| 10 | [`regions/`](regions) | `regions: RegionService` (+ `PersistentLayer`, `RegionScene`, `Waystation`) | [`data/regions/`](../data/regions) | [`tests/unit/regions/`](../tests/unit), [`tests/regions_test.gd`](../tests/regions_test.gd) | [README](regions/README.md) |
| 11 | [`progression/`](progression) | `economy: EconomyService` | [`data/progression/`](../data/progression) | [`tests/unit/progression/`](../tests/unit) | [README](progression/README.md) |
| 12 | [`npc/`](npc) | `npc: BarkService` (holds `RumorService`, `ScheduleService`) | [`data/npc/`](../data/npc) | [`tests/unit/npc/`](../tests/unit) | [README](npc/README.md) |
| 13 | [`ui/`](ui) | — nodes, not a service: `UiShell` under the persistent layer | [`data/ui/`](../data/ui), the localization CSVs | [`tests/unit/ui/`](../tests/unit), [`tests/ui_test.gd`](../tests/ui_test.gd) | [README](ui/README.md) |

Round 1 is not a row: it was the docs-and-foundation round, and what it built is
`core/` plus the test harness.

**Across all thirteen: [`tests/playthrough_test.gd`](../tests/playthrough_test.gd)**, the
proof slice — MQ00 from the black screen to a purchase in the Prestige and back out of a
save file, driven through the InputMap actions. It is the regression gate for the seams
*between* the rows above, which no single row's tests can cover; see
[`tests/README.md`](../tests/README.md) §The proof slice.

### What each system owes

Every README above carries a section naming what its round deliberately did not build.
`python3 godot/tools/rollup_owed.py` gathers all of them — plus every `.tres` `notes`
field that names a TBD — into one markdown page, deterministically, quoting and deciding
nothing. That page is what goes into a hand-off document; the owning README stays the
place an item is argued and struck out.
