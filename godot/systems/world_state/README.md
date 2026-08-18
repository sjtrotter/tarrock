# `systems/world_state/` — what the world permanently remembers

Owns the runtime side of [`docs/design/world.md`](../../../docs/design/world.md)
§World-state matrix, §Global states and §The Fool's Reading, plus the Renown ladder from
[`docs/design/progression.md`](../../../docs/design/progression.md) §Renown. The docs are
the source of truth; nothing here re-decides them.

| File | What |
|---|---|
| `world_state_service.gd` | `WorldStateService` — the **only** mutation path for `WS_*` flags, Renown, the Reading, the Hermit's answer, named-NPC memory, quest state and quest branch choices |
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

Writers are quest state-machine transitions and nobody else (round 4), with one reviewed
exception: `systems/progression/economy_service.gd`'s `record_deed()` is Renown's second
writer (`docs/design/technical.md` §The WorldState service (Godot)). Everything else
reads and connects to the signals — polling is forbidden.

## Branch-group exclusivity (delivered in round 4)

The matrix's branch flags come in mutually exclusive pairs (the troupe's fate, which
side of the Divide marries in), and exactly one member of a group is ever fired. The
enforcement is split, deliberately, between this service and the quest runner:

- `set_quest_choice(quest, group, flag)` records **which** branch was taken, set-once
  per `(quest, group)`: a second call is refused, so the other half can never be
  chosen afterwards. It is **not a fire** — nothing about the world becomes true here.
  `quest_choice(quest, group)` reads it back, and it rides in the snapshot under
  `SNAPSHOT_QUEST_CHOICES`.
- [`systems/quests/`](../quests) fires the chosen flag, and only at completion, and
  refuses to complete a quest that still owes a group its choice
  (`QuestService.REFUSED_BRANCH_UNCHOSEN`). The choice is the quest's, so the quest
  state machine is the only thing allowed to make it or to cash it in.

`fire()` itself is deliberately unchanged: it still knows nothing about groups. The
group is data (`WorldStateCatalog.branch_group_members(group)`, and every branch
definition's `branch_group`), and the runner is what enforces it.

**Known TBD:** the Renown tier *thresholds* (`[0, 10, 25, 50, 100]`) are placeholders.
`progression.md` §Renown owns the five tiers by name; the numbers are tuning and no doc
has set them. The generated resource says so in its `notes` field.
