# Save fixtures

Checked-in save files, exactly as a build would have written them. They are read by
`res://tests/unit/save/save_service_test.gd` and never regenerated: a fixture's whole
job is to be a file from *before* the change under test, so editing one to make a test
pass defeats the point. When the schema version bumps, add a new `vN_*.json` beside
these (see `SaveSchema`'s class doc) - do not update the old ones.

| File | What it is |
|---|---|
| `v1_blank.json` | `SaveModel.blank()` - a playthrough that has not started. |
| `v1_played.json` | Three Arcana unbound plus a branch flag, a Reading, Renown in two suits, the Hermit's answer, one NPC's memory, two quest states, Trial difficulty — and the progression this bought: Trump I slotted upright in the Present, 40 Fortune, one Rose grafting taken and 2 of its 4 petals — and the `inventory` that bought it: 42 Coins, two bags of popcorn, the Reaching Head carried and fitted, and the grafting source already spent — and the `npc` section: MQ01's news already travelling, seeded at 100 in-game seconds. |
| `v99_future.json` | A save from a build that does not exist. Must never load. |
| `corrupt.json` | Not JSON. Must fail as data, not as a crash. |
| `v1_missing_world_state.json` | Structurally a v1 save with a required field gone. |

**The `pocket_spread` section.** Its three parts are `PocketSpreadService`,
`FortuneService` and `WhiteRoseService`'s own snapshots. The Trump id and the slot and
orientation keys are real (`res://data/trumps/`, generated from
`docs/design/arcana.md`), and the slot is legal in this world: three Arcana are unbound,
so the Fool holds three Trumps, which opens the Present and Past slots (1 and 3 held,
`docs/design/progression.md` §Slot unlock pacing). Which Trumps are HELD is deliberately
not in the file — it is derived from the world-state flags above it.

**The `inventory` section.** `EconomyService`'s own snapshot: the purse, `item id ->
count`, the staff head fitted and the grafting *sources* already taken. The item ids
are real (`res://data/progression/items/`), and the file is internally honest - the
head it fits is one the same section says the Fool is carrying, and the one grafting
source spent is the one the Rose's own section was paid a petal of capacity for. What
a SHOP has sold is deliberately not in the file: that is a fact about a shop between
two rests. Grafting *source* ids are placeholders, like the NPC memory flags below -
`progression.md` says the full list of Rose-grafting sources is a content-design pass.

**The `npc` section.** `BarkService`'s snapshot, which is `RumorService`'s: which main
quests' news is travelling and the clock reading (in-game seconds) each was completed
at - `RumorService.SNAPSHOT_RUMORS` / `_RUMOR_QUEST` / `_RUMOR_AT`. Nothing else the
NPC round can do is in the file: which bark was said and to whom is derived at request
time from world state already above it, and which lines were recently spent is
transient (`docs/design/npc-system.md` §Bark layers). `MQ01` is real
(`res://data/quests/`) and matches the `MQ01: complete` quest state above; 100 seconds
is well inside the fixture's `playtime_seconds`.

**Ids in the played fixture.** The world-state flag ids and their firing quests are
real (`res://data/world_states/`, generated from `docs/design/world.md`). The NPC
memory flags are real too, now (`NpcMemoryIds`, NPC round) - `FLICK` remembering
`MET_THE_FOOL` and `SAW_THE_SHOW_END` is exactly `FLICK.tres`'s
`memory_flags_known`. The rest are placeholders for id schemes later rounds own and no
shipped doc has minted yet - the quest *state* names (Quests round) and the
`HERMIT_ANSWER` value (its four answers are canon in `MQ09` as wording, not as ids).
Nothing validates them today; the save carries them opaquely, which is the property
these fixtures are proving. When those rounds mint their ids, this fixture is
re-authored with the real ones - as the **region and Waystation ids already were**
(round 10): `regions.current_region_id` and `regions.last_waystation_id` are
`RegionIds` tokens now, and `regions.visited_waystations` is the append-only set fast
travel reads.

**The `regions` section arrived inside v1, not as a v2.** These files used to carry
`current_region_id` and `last_waystation_id` as loose top-level fields. Rewriting a
fixture is normally forbidden - a fixture is the old build's format, frozen - and the
exception here is that v1 has never shipped: no save exists outside a developer's
`user://`, so there was nothing in the world to migrate. The next shape change after a
build reaches a player is a v2 with a migration and a *new* fixture beside these.
