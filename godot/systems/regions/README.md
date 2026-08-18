# `systems/regions` — the Spread, the persistent layer, and Waystations

Owns where the Fool is, where they may go, what stops them, and everything a Waystation
does. Canon: [`docs/design/world.md`](../../../docs/design/world.md) §The Spread,
§Layout (adjacency), §Intended difficulty bands, §Hard and soft gates, §Regions;
[`docs/design/progression.md`](../../../docs/design/progression.md) §Waystations and
§The White Rose; [`docs/design/combat.md`](../../../docs/design/combat.md) §Defeat;
[`docs/design/technical.md`](../../../docs/design/technical.md) §Regions and the
persistent layer.

## The shape of it

```
scenes/persistent_layer.tscn        run/main_scene — never freed
  Fool (fool.tscn) + Camera2D       the Fool and the eye that follows him
  Pip  (pip.tscn)
  RegionRoot                        <- exactly one region scene lives here
  UIRoot (CanvasLayer)              empty; the UI round fills it
```

- **`RegionService`** is the only thing in the game allowed to load or free a region
  scene. It is a plain `RefCounted` with no tree, so it does the loading through a
  **`RegionSwapper`** — three `Callable`s the layer registers over its own methods.
  That is what keeps both rules true at once: one owner of scene loading, and no system
  reaching into a scene.
- **`PersistentLayer`** does the node work, and does it **deferred by one message-queue
  flush**: a swap is usually asked for from inside a physics callback (a LeapPoint's
  `body_entered`, a Waystation's interact), and Godot cannot free a scene full of
  `Area2D`s while the physics server is flushing queries.
- **`RegionScene`** is the base class of every region root. It holds the region's id,
  its camera bounds, its `Markers`, and the accessors (`fool()`, `pip()`,
  `region_service()`) the layer fills in before the scene enters the tree.
- **`Waystation`** is an `Interactable` under a region's `Markers`, named for its
  Waystation id, so one node is the shrine, the rest verb, the respec circle **and** the
  arrival marker a defeat wakes the Fool on.

## Generated vs. hand-authored

| What | Where | How |
|---|---|---|
| The twenty-two regions | `data/regions/<TOKEN>.tres`, `catalog.tres` | **generated** from `world.md` §Regions + §Intended difficulty bands by `tools/gen_definitions.py`; drift-tested |
| `RegionIds`, `localization/regions.csv` | `systems/regions/region_ids.gd`, `localization/` | **generated** from the same rows |
| **The adjacency** | `data/regions/region_graph.tres` | **hand-authored** from §Layout, one `notes` line per edge citing the sentence it was read from |

§Layout is an ASCII picture of a wheel, and a picture has to be *read*. A parser turning
it into a graph would be inventing canon at generation time, so the edges are authored by
a person and reviewed against the diagram; `RegionGraph.notes` records the readings the
diagram does not spell out. A `RegionDefinition` deliberately carries **no** neighbour
list, so a region and the graph cannot disagree.

## Rules worth not re-deriving

- **Gates are data on an edge**, never a branch in code (`RegionEdge.requires_fired`,
  `requires_any_fired`, `requires_any_trump_held`, `gates_entry_to`), so `world.md`
  §Hard and soft gates can be checked against the file row by row. `gates_entry_to` is
  what makes a gate a door rather than a wall: the Mirrormarsh's fog stops the Fool
  getting *in*; getting lost back *out* is what the fog does for a living.
- **A difficulty band is never a gate.** §Intended difficulty bands is headed "soft,
  never enforced"; nothing here refuses a journey for a band, and a test asserts that no
  refusal reason is a band name.
- **Fast travel does not read the map.** `progression.md` §Waystations makes the network
  world-wide once `WS_CHARIOT_UNBOUND` fires, and its own condition is stricter than any
  road: the Fool has already slept at the shrine they are going to, which means they
  already walked there and already opened whatever was in the way.
- **The Cliff is outside the network.** `world.md` §Layout: "it is outside the Waystation
  network — no fast travel returns there", and `progression.md` §Waystations says it from
  the other end. Carried as `RegionGraph.fast_travel_network_excludes` (a fact about the
  map, so it lives on the map) and refused as `REASON_OUTSIDE_NETWORK` — deliberately not
  `NOT_VISITED`, because the Fool *has* slept at that shrine and MQ00 says so. Resting
  there and waking there after a defeat are untouched; only the network leaves it out,
  which is what makes the leap final.
- **Where the Fool is, is save state.** The current region, the last Waystation rested at
  and the Waystations visited live in `SaveService` (the `regions` section of the file);
  this service drives them through its setters and keeps no second copy.
- **The defeat loop closes here.** `RegionService` listens for
  `CombatService.fool_defeated` and walks the Fool back to the last Waystation rested at,
  then lets `CombatService.revive_at_waystation()` restore them — and *only* then: a
  Fool who could not be moved (a headless arena with no layer) stays down, because half
  of "wakes at the Waystation" is not a gentler version of it.
  `hold_defeat_return()` is the seam a defeat-beat presentation will hold the return with.
  A walk back that cannot happen — the shrine is in a region with no scene, or the layer
  will not take the swap — falls through to waking the Fool in the region they fell in,
  loudly (`push_warning`): a wrong place to wake up costs a log line, never waking up
  costs the playthrough.
- **A swapper's answer is believed.** `RegionService` asks the layer for the scene
  *before* it touches the save, the Rose or the fight, so a layer that cannot load a
  region refuses the journey instead of leaving the Fool recorded somewhere they never
  arrived.
- **The composition root builds once at boot.** `Services._ready()` constructs the
  services; the first `new_game()` finds a world nobody has played and reuses it rather
  than loading and validating every generated catalog a second time
  (`Services.rebuild_if_played()`, which asks `WorldStateService.is_pristine()` — the same
  question `SaveService.apply()` asks). Every later new game or load is a fresh world.

## Owed / TBD

- **`prestige.tscn` is a greybox placeholder** — see `scenes/regions/README.md`. Twenty
  regions have no scene at all; `RegionDefinition.has_scene()` is what makes that a
  refusal with a reason instead of a black screen.
- **The Longroad's Waystation network** is four placeholder ids (`_N/_E/_S/_W`). How many
  there are and where they stand is content design; the doc fixes no number.
- **The causeway is one node, so it has no closure to test**: `RegionGraph.ring_problems()`
  holds it to what §Layout actually says about it (both towns sit on it). The closed
  circle the diagram draws is the wheel's **rim**, a genuine fifteen-edge cycle, and it is
  proved against §Layout's own clockwise sequence in
  `tests/unit/regions/region_graph_test.gd`. The day the Longroad is split into arcs, a
  real cycle test belongs on the graph too.
- **The Confluence delta caves' Temperance gate** (§Hard and soft gates) is a sub-area of
  a region, not a region; it belongs to the Confluence scene when that scene exists.
- **The side-view leap** (§Side-view sequences, 1) is presentation nobody has built: the
  Cliff's LeapPoint performs the travel underneath it, and the sequence will play over
  it rather than replace it.
