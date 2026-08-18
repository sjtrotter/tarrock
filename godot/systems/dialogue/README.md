# `systems/dialogue/` — conversations as data

Owns the runtime side of the quest scripts' dialogue: the graph resources, the runner
that walks them, and the two style-guide rules a machine can check. Canon lives in
[`docs/design/narrative.md`](../../../docs/design/narrative.md) §The Querent and
§Dialogue style guide, [`docs/quests/TEMPLATE.md`](../../../docs/quests/TEMPLATE.md)
(the script format this compiles), and
[`docs/design/technical.md`](../../../docs/design/technical.md)'s `DialogueGraph` row —
"branch conditions are WorldState queries, never hardcoded booleans; every line is a
translation key". Nothing here re-decides any of it.

| File | What |
|---|---|
| `dialogue_service.gd` | `DialogueService` — the runner: start, advance, choose, leave |
| `dialogue_view.gd` | `DialogueView` — a read-only copy of what is on screen |
| `dialogue_option_view.gd` | `DialogueOptionView` — one row of a table, as the UI sees it |
| `dialogue_style.gd` | `DialogueStyle` — the ≤ 12-word rule and the earnest-option rule |
| `dialogue_ids.gd` | `DialogueIds` — hand-authored graph-id constants |
| `speakers.gd` | `Speakers` — who may say a line, and their display-name keys |
| `definitions/dialogue_graph.gd` | one authored conversation |
| `definitions/dialogue_node.gd` | one node: `LINE`, `CHOICE`, `BRANCH`, `EVENT`, `POOL`, `END` |
| `definitions/dialogue_option.gd` | one row of a choice table |
| `definitions/dialogue_catalog.gd` | every conversation the game knows |

## The script format, compiled

One graph is one beat of a quest script. The kinds map onto `TEMPLATE.md` one for one:

| In the script | In the graph |
|---|---|
| `**THE QUERENT**` / `**THE FOOL**` block | `LINE` (speaker + text key + next) |
| `### CHOICE DIALOG — … *(all questions may be exhausted)*` | `CHOICE`, `mode = EXHAUST_ALL` |
| `### CHOICE OPTIONS — … *(first pick commits)*` | `CHOICE`, `mode = FIRST_PICK_COMMITS` |
| `**If the Fool asked …**` | the option's `next` — a thread ending in `END` |
| `[All versions pick up here:]` | the table's `after_all` |
| `[If WS_…]` / `[If CONFESSED:]` variants | `BRANCH` (`WS_*` ids, CONFESSED, act floor) |
| `**… Random Lines**` | `POOL` |
| a beat that runs straight into the next | the graph's `next_graph_id` |

An `EXHAUST_ALL` table pushes itself onto a return stack when a row is taken, so the
row's thread runs to its `END` and comes **back** to the table with that row spent;
when every row is spent — or the Fool leaves — the table falls through to `after_all`.
That stack is what lets a follow-up table sit inside a thread, which MQ00's edge
questions need twice. A `FIRST_PICK_COMMITS` table pushes nothing: the chosen thread
simply continues on.

## Three rules this system exists to make structural

- **No line is ever a literal.** A node carries a translation key; the English lives in
  `res://localization/dialogue_<quest>.csv` and nowhere else, registered in
  `project.godot`. `dialogue_data_test.gd` fails on a key with no English behind it and
  on English no graph can show.
- **Branches are world-state queries.** A `BRANCH` node has nowhere to put a boolean —
  it holds `WS_*` ids, a CONFESSED state and an act floor, and asks
  `WorldStateService`. Order-independence comes free: they are per-flag booleans.
- **Dialogue never writes world state.** The only path from a conversation to a
  permanent change is an `EVENT` node, emitted on `event_raised` for the **scene** to
  forward to `QuestService.raise()`. This service never holds a `QuestService`.

## Authoring a conversation

1. Add the id to `DialogueIds`, in script order.
2. Write `godot/data/dialogue/<ID>.tres`, citing the script section in `source_ref` and
   the slugline each node came from in `notes`.
3. Add its lines to the quest's localization CSV. Keys are `DLG_<GRAPH_ID>_<SUFFIX>`:
   `_01`, `_02`, … for plain lines, `_Q<n>` for a table's rows, `_A<n>` for their
   answers, `_A<n>_<nn>` when an answer is a thread of several lines, and
   `_Q<n>_F<m>` / `_A<n>_F<m>` for a follow-up table inside a thread.
4. Add the graph to `godot/data/dialogue/catalog.tres`.
5. Run `bash godot/tests/run_all.sh`. Anything the script said and the data does not
   is a failing test, not a review comment.

## What MQ00 ships

Thirteen graphs, one per **scripted beat** of `docs/quests/main/MQ00-the-leap.md`: every
Querent line from the opening cut scene through the landing, in the cut scenes, choice
tables and Random Lines the script writes as beats. The one part of the script not here
is `### BARKS — The Cliff *(idle exploration)*` — four idle lines that belong to whatever
round gives the world ambient barks, since nothing in a beat-driven runner triggers them.
`MQ00_KEEPSAKE_GIVEN` chains into `MQ00_WOODEN_DOG`; `MQ00_EDGE_QUESTIONS` carries the
four questions, each row's own answer, all four threads (including the two follow-up
tables) and the closing line. `scripts/the_cliff.gd` maps seven MQ00 states onto graphs
and starts them; the rest wait for the rounds that reach them.

## Owed by later rounds

- **No UI, so nothing presents a conversation.** The scene starts one and does not wait
  for it; `DialogueService.start()` refuses while another is running, so a beat landing
  mid-sentence never interrupts one. The scene holds the refused beat in a one-slot
  pending queue (`the_cliff.gd`) and starts it when the conversation ends, so the line is
  late rather than lost; a second beat arriving while one waits replaces it and warns.
  The UI round (13) renders `DialogueView` and makes conversations modal, at which point
  that stops being a trade-off and starts being the design.
- **Five of MQ00's beats have nothing to start them yet.** `MQ00_WAKE` plays over a
  black screen before the region loads (owned by the bootstrap / opening cut scene),
  `MQ00_CAMPSITES` needs an area trigger on the fire-rings, `MQ00_WAYSTATION_AMBUSH`
  waits for combat (round 7), `MQ00_WAYSTATION_REST_AGAIN` waits for the Waystation's
  rest verb (round 10), and `MQ00_LEAP_BEFORE` belongs to the cut scene after Pip jumps.
  All five are authored, validated and tested; only the trigger is missing.
- **Speaker display names live in `dialogue_mq00.csv`.** `SPEAKER_QUERENT`,
  `SPEAKER_FOOL` and `SPEAKER_FLICK` are not MQ00's property; they move to a shared
  table the round a second quest's dialogue lands.
- **No cycle detection *inside* a graph.** `DialogueGraph.validate()` does not attempt
  it — a loop *through* a choice table is exactly what an exhaustible table is, and
  separating that from a genuine loop needs a reachability analysis worth more than it
  saves at this size. `DialogueService.MAX_WALK_STEPS` bounds the walk instead, so a bad
  graph fails loudly rather than hangs. Worth revisiting when a graph is authored with
  real `BRANCH` chains in it. Rings of `next_graph_id` *between* graphs are a different
  question and are caught: `DialogueCatalog.validate()` follows each chain to its end,
  because a ring there is an endless conversation with no bound on it at all.
- **`next_graph_id` is this round's answer to "the line, then the table".** The script
  writes them as one beat; the alternative was scene code sequencing two `start()`
  calls, which would have put script order in a `.gd` file instead of in the data. If a
  later round finds a beat that needs to chain *conditionally*, that is a `BRANCH` into
  an `EVENT` the scene answers, not a second chaining field.
