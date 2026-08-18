# `systems/quests/` — the quest state machines, and the one writer of world state

Owns the runtime side of [`docs/quests/`](../../../docs/quests) — the frontmatter schema
[`docs/quests/README.md`](../../../docs/quests/README.md) defines and the state machines
[`docs/design/technical.md`](../../../docs/design/technical.md) §Quests at runtime (Godot)
specifies. The docs are the source of truth; nothing here re-decides them.

| File | What |
|---|---|
| `quest_service.gd` | `QuestService` — the runner, and the **only** caller of `WorldStateService.fire()` / `set_quest_state()` / `set_quest_choice()` |
| `quest_ids.gd` | `QuestIds` — **generated** constants, the one place a quest id is written in code |
| `quest_events.gd` | `QuestEvents` — **hand-authored** constants for the events graphs listen for |
| `definitions/quest_definition.gd` | one quest's frontmatter as data, linking its graph |
| `definitions/quest_catalog.gd` | every quest the game knows, in one resource |
| `definitions/quest_graph.gd` | one quest's hand-authored state machine |
| `definitions/quest_state.gd` | one named state, with the slugline it came from |
| `definitions/quest_transition.gd` | one event-gated, world-state-gated edge |
| `definitions/quest_branch_group.gd` | one mutually exclusive set of branch flags |

## Generated metadata, hand-authored graphs

A quest is deliberately two halves:

- **Metadata is generated.** [`godot/tools/gen_definitions.py`](../../tools/gen_definitions.py)
  reads every `docs/quests/**/*.md` frontmatter block and writes
  `godot/data/quests/<ID>.tres`, `catalog.tres`, `quest_ids.gd`, and
  `godot/localization/quest_titles.csv`. A drift test fails when the docs and the data
  disagree.
- **The state graph is hand-authored**, at `godot/data/quests/graphs/<ID>.tres`, lifted
  from the quest doc's GAMEPLAY blocks (each state's `notes` cites its slugline). The
  generator links a graph when the file exists and **never writes into `graphs/`**, so
  regenerating after a frontmatter edit can never clobber authored work. A quest with no
  graph yet is known to the game and simply not playable.

```bash
python3 godot/tools/gen_definitions.py --write    # regenerate
python3 godot/tools/gen_definitions.py --check    # what the drift test runs
```

Authoring a quest, therefore, is: write the doc, regenerate, write the graph.

## Four rules this system exists to make structural

- **Nothing commits mid-quest.** `fire()` is called from one private method, reached only
  when a quest actually completes. A quest abandoned halfway has changed nothing.
- **Exactly one branch per group.** A quest with `branches` cannot complete until every
  group has a recorded choice; the attempt is refused (`quest_completion_refused`, reason
  `REFUSED_BRANCH_UNCHOSEN`) and the quest stays where it was. The choice itself is
  set-once in `WorldStateService`, so the other half can never be taken afterwards.
- **Scenes call systems.** A scene raises an event (`QuestService.raise()`); it never
  writes world state and never asks a quest where it is. `Interactable`
  (`systems/core/interactable.gd`) is the whole scene-side vocabulary: it emits its event
  and the region script forwards it.
- **Determinism, and no per-frame work.** Quests are considered in catalog order and a
  quest's edges in authoring order; `QuestGraph.validate()` rejects two edges answering
  one (state, event) pair the same way. Everything happens inside `raise()` or `start()`;
  subscribers connect to the signals, and polling is forbidden.

## Where the state lives

Quest state and branch choices live in [`WorldStateService`](../world_state), because they
are save data and because barks and dialogue read them. Restoring a save therefore resumes
mid-quest with no extra plumbing: build a fresh `WorldStateService`, restore the snapshot
into it, build a `QuestService` over it.

## Owed by later rounds

- **`Interactable.one_shot` spends itself on interaction, not on consumption.** An
  interact-shaped trigger a quest graph is not yet listening for (the Fool digs before
  taking the Bindle, so MQ00 is still in `WAKING` when `MQ00_KEEPSAKE_FOUND` fires) burns
  its one shot for nothing: the graph never moves and the trigger can never fire again,
  soft-locking the quest once the player does the two prompts out of order. `the_cliff.tscn`
  works around it today by making `KeepsakeTrigger` not one-shot; the principled fix is an
  `Interactable` that only spends itself when a quest actually consumes its event (or a
  scene-level "was this raise believed" signal back from `QuestService.raise()`), owed to
  whichever round next touches `systems/core/interactable.gd`.
- **Who starts the first quest.** `scripts/the_cliff.gd` starts MQ00 when the region loads.
  The bootstrap / new-game flow owns that once the Regions round (10) owns the persistent
  layer.
- **Events nothing raises yet.** `MQ00_AMBUSH_CLEARED` waits for combat (round 7) to put
  Blanks on the Waystation path; `MQ00_KEEPSAKE_FOUND` is an interaction on the disturbed
  earth until Pip's Seek command (round 9) makes it his. Both are noted in MQ00's graph.
- **Dialogue.** No quest transition is driven by a conversation yet; the dialogue round (5)
  raises its own events here.
- **`scripts/the_cliff.gd` reaches `Services` through `get_node_or_null("/root/Services")`,
  not the bare autoload identifier.** The typed global (`Services.quests`) works once the
  game is actually running, but `res://tests/run_all.sh`'s lint stage loads every `.gd` with
  `--check-only` - a pure static parse that never runs the `SceneTree` bootstrap that wires
  an autoload's name into the language as a global identifier - so `Services` is an
  unconditional "Identifier not found" parse error under `--check-only`, autoload present or
  not. Fixing this for real is outside `systems/quests/`: either `--check-only`'s handling of
  autoload globals, or a `class_name` on `systems/core/services.gd` paired with a
  typed-but-still-looked-up accessor. Owed to whichever round next touches
  `systems/core/services.gd` or the lint stage in `tests/run_all.sh`.
