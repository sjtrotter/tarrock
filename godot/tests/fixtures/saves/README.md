# Save fixtures

Checked-in save files, exactly as a build would have written them. They are read by
`res://tests/unit/save/save_service_test.gd` and never regenerated: a fixture's whole
job is to be a file from *before* the change under test, so editing one to make a test
pass defeats the point. When the schema version bumps, add a new `vN_*.json` beside
these (see `SaveSchema`'s class doc) - do not update the old ones.

| File | What it is |
|---|---|
| `v1_blank.json` | `SaveModel.blank()` - a playthrough that has not started. |
| `v1_played.json` | Three Arcana unbound plus a branch flag, a Reading, Renown in two suits, the Hermit's answer, one NPC's memory, two quest states, Trial difficulty. |
| `v99_future.json` | A save from a build that does not exist. Must never load. |
| `corrupt.json` | Not JSON. Must fail as data, not as a crash. |
| `v1_missing_world_state.json` | Structurally a v1 save with a required field gone. |

**Ids in the played fixture.** The world-state flag ids and their firing quests are
real (`res://data/world_states/`, generated from `docs/design/world.md`). The rest are
placeholders for id schemes later rounds own and no shipped doc has minted yet - the
region and Waystation ids (Regions round), the quest *state* names (Quests round), the
`HERMIT_ANSWER` value (its four answers are canon in `MQ09` as wording, not as ids),
and the NPC memory flags (NPC round). Nothing validates them today; the save carries
them opaquely, which is the property these fixtures are proving. When those rounds mint
their ids, this fixture is re-authored with the real ones.
