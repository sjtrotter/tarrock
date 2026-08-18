# `systems/world_state/` — what the world permanently remembers

Owns the runtime side of [`docs/design/world.md`](../../../docs/design/world.md)
§World-state matrix, §Global states and §The Fool's Reading, plus the Renown ladder from
[`docs/design/progression.md`](../../../docs/design/progression.md) §Renown. The docs are
the source of truth; nothing here re-decides them.

| File | What |
|---|---|
| `world_state_service.gd` | `WorldStateService` — the **only** mutation path for `WS_*` flags, Renown, the Reading, the Hermit's answer, named-NPC memory and quest state |
| `world_state_ids.gd` | `WorldStateIds` — **generated** constants, the one place a `WS_*` string is written in code |
| `suit.gd` | `Suit` — the four Minor suits and the one place their names are spelled |
| `definitions/world_state_definition.gd` | one matrix row (or one branch flag) as data |
| `definitions/world_state_catalog.gd` | every flag the game knows, in one resource |
| `definitions/act_thresholds.gd` | where Act II and Act III begin, by unbound count |
| `definitions/renown_ladder.gd` | the five-tier standing ladder every suit shares |

The `.tres` data lives under [`godot/data/world_states/`](../../data/world_states) and
[`godot/data/progression/`](../../data/progression) and is **generated** from the docs by
[`godot/tools/gen_definitions.py`](../../tools/gen_definitions.py) — including
`world_state_ids.gd`. Edit the doc, then run:

```bash
python3 godot/tools/gen_definitions.py --write    # regenerate
python3 godot/tools/gen_definitions.py --check    # what the drift test runs
```

Four rules this system exists to make structural, rather than remembered:

- **No un-fire.** `fire()` is the only way a flag moves, and it moves one way.
  Nothing named `unfire`/`clear`/`reset`/`remove` exists on the service, and a test
  proves it by reflection over the script's own method list.
- **Order-independence.** Queries are per-flag booleans, never an ordered log. The
  Reading sits alongside them for content that wants the *sequence*; it never gates a
  query.
- **Loading is not an event.** `restore_snapshot()` emits nothing, so a subscriber
  cannot hear three hundred years of world change arrive in one frame.
- **A load is not a reset.** `restore_snapshot()` only fills a service nothing has
  happened to yet (`is_pristine()`), and it commits all of a snapshot or none of it —
  so no public call can blank a world in play, and no half-read save can leave the
  flags and the Reading disagreeing about what the Fool has done.

Writers are quest state-machine transitions and nobody else (round 4). Everything else
reads and connects to the signals — polling is forbidden.

## Owed by later rounds

- **Branch-group exclusivity.** The matrix's branch flags come in mutually exclusive
  pairs (the troupe's fate, which side of the Divide marries in), and exactly one
  member of a group is ever fired. Nothing enforces that yet: `fire()` would accept
  both halves of a choice. It belongs to the **quest runner in round 4** — the choice
  is the quest's, so the quest state machine is the only place that knows which branch
  was taken and is the only writer allowed to fire either. The data it needs is
  already here: `WorldStateCatalog.branch_group_members(group)` returns a group's
  members, and every branch definition carries its `branch_group`.

**Known TBD:** the Renown tier *thresholds* (`[0, 10, 25, 50, 100]`) are placeholders.
`progression.md` §Renown owns the five tiers by name; the numbers are tuning and no doc
has set them. The generated resource says so in its `notes` field.
