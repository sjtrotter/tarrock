# `scenes/regions/` — one scene per region

`docs/design/world.md` §Regions lists twenty-two places (the Cliff plus the twenty-one
Arcana's regions) and `docs/design/technical.md` §Regions and the persistent layer asks
for one scene each, instanced under `scenes/persistent_layer.tscn` by `RegionService`
and by nothing else.

The generated `RegionDefinition` for each region already names the file it expects:

| Region | Scene | State |
|---|---|---|
| The Cliff | `res://scenes/the_cliff.tscn` (**not** in this folder) | real |
| The Prestige | `res://scenes/regions/prestige.tscn` | **greybox placeholder** |
| every other region | `res://scenes/regions/<token>.tscn` | does not exist yet |

A region whose scene does not exist is not a bug: `RegionDefinition.has_scene()` is
false and `RegionService` refuses to travel there with `REASON_NO_SCENE`. Adding a
region is dropping its scene in here under the name the definition already gives it.

**The Cliff keeps its old path** (`res://scenes/the_cliff.tscn`). The art lane knows
that file by name (`godot/art/ART-REQUESTS.md`), and moving it to buy a tidier
convention would cost more than the convention is worth.

## `prestige.tscn` is a PLACEHOLDER

It is a flat coloured rectangle, three markers and a Waystation node. It exists so the
Cliff → Prestige transition — the proof slice of `docs/final-claude-2d.md` §10 — is a
real scene swap with a real arrival and a real place to rest, and for **no** other
reason. Nothing about it is a design statement: `world.md` §The Prestige is "a carnival
that has been mid-performance for 300 years. Tents like cathedral naves, an audience
that cannot leave its seats, popcorn older than nations. Warm, gaslit, uncanny", and
none of that is in this file. It is owed to the art lane, and to a greybox pass that
walks it. Overwrite it without ceremony.

## What every region scene owes

- Its root extends **`RegionScene`** (`systems/regions/nodes/region_scene.gd`) and sets
  `region_id` to its `RegionIds` token. A region scene never contains the Fool or Pip:
  they live in the persistent layer and are re-anchored on arrival.
- A **`Markers`** child holding, at least, `DEFAULT` — where the Fool stands when
  nothing else is named. Any other child of `Markers` is an arrival by its node name
  (`LEAP_ARRIVAL` is where the leap off the Cliff lands).
- Its **`Waystation`** node(s), under `Markers`, named for their `RegionIds`
  `WAYSTATION_*` id, which is what lets a Waystation double as an arrival marker.
  `docs/design/progression.md` §Waystations: one per region, several along the
  Longroad.
- `camera_limits`, when the place has an edge the camera should not cross. An empty
  rect means unbounded, which is what a greybox wants.
- An integration test in `res://tests/regions_test.gd`: the scene instances under the
  layer, its definition resolves, and its Waystation is reachable
  (`docs/design/technical.md` §Testing).
