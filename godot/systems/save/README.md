# `systems/save/` — one playthrough, on disk

Owns the runtime side of
[`docs/design/technical.md`](../../../docs/design/technical.md) §Save system (Godot):
versioned JSON in `user://saves/`, explicit migrations, IDs only. The mutable state of
a playthrough lives here; the *facts* it refers to (which flags exist, what a Trump
does) live in definitions and in the docs, and are re-resolved from their ids on load.

| File | What |
|---|---|
| `save_model.gd` | `SaveModel` — the shape of one save file: ids, numbers and plain containers, nothing else |
| `save_schema.gd` | `SaveSchema` — the production migration table, and the checklist a version bump follows |
| `save_migrations.gd` | `SaveMigrations` — the version chain; a missing step is a hard failure |
| `migration_result.gd` | `MigrationResult` — what a migration attempt hands back |
| `save_service.gd` | `SaveService` — capture / apply / write / read, slots, signals |
| `save_read_result.gd` | `SaveReadResult` — a loadable model, or the reasons there isn't one |

The difficulty mode a playthrough is played at is
[`systems/core/difficulty_mode.gd`](../core/difficulty_mode.gd): it is save data, but
combat and a settings screen need it too, so it sits in `core/` with the other shared
vocabulary.

The rules this system exists to make structural rather than remembered:

- **Versioned, always.** Every file carries `schema_version`, and this build reads
  exactly one version — everything older comes up through the chain, and anything
  newer is refused outright rather than opened and written back with its unknown
  fields silently dropped.
- **A missing migration is a hard failure.** Never a best-effort walk as far as the
  steps happen to reach: half-migrated data is data whose meaning nobody wrote down.
- **IDs only.** No resource, no object, no node ever enters the file; a test asserts
  that what lands on disk contains no `res://` and no `Object(`.
- **A write is atomic, and checked before it counts.** Validate, write `<slot>.tmp`,
  read the stream's error, count the bytes that actually landed against the bytes the
  payload holds, and only then rename it over the slot. Any failure removes the temp
  file — so an interrupted save, a refused save, a full disk and a temp path something
  else is sitting on all leave the previous save whole, byte for byte. A `.tmp` is
  never mistaken for a slot.
- **A listed slot is a slot that opens.** `list_slots()` accepts only the names this
  service itself writes (`slot_<n>.json`, `n` ≥ 0, no padding), so every id it returns
  is one `read_slot()` can open. `slot_007.json`, `slot_-1.json` and `slot_.json` parse
  as integers and are not slots.
- **A load is not a reset.** `apply()` fills a world nobody has played yet and refuses
  one in play, which is the same rule `WorldStateService.restore_snapshot()` holds from
  underneath. Deleting a save file un-fires nothing: permanence is a property of a
  running world, not of the file cabinet.
- **The world lands first, and a rejected section stops the apply.** `apply()` restores
  the world state before the three progression sections, because the Pocket Spread
  derives which Trumps are held from the flags — a Spread filled before its world would
  reject every card in it. That order has a price, and it is the one thing about
  `apply()` a caller must know: all four services are checked for pristineness *before*
  anything is applied, so the ordinary "you are already playing" refusal changes
  nothing at all — but a save whose **contents** a progression section rejects stops at
  that section, with the world and the earlier sections already loaded and the later
  ones untouched. A non-empty result therefore means **rebuild the composition root
  before retrying**, not "try again": these services are partly loaded, they are no
  longer pristine, and a second `apply()` on them is refused anyway. The rebuild
  belongs to the same Regions-round machinery a title-screen load needs (below).

Bad input is data. Nothing here pushes an error or asserts on a file a player's disk
handed it: a missing file, gibberish, a save from a newer build and a save with a field
gone all come back as diagnostics the caller decides what to do with.

The exceptions are about *this build* being wired wrong, not about a player's disk.
`SaveService.capture()` with no world state pushes an error and returns null, because a
service with no world cannot describe a playthrough and a blank model returned quietly
would be written over a real save. And the engine itself may log when creating the save
directory genuinely fails: `write_slot()` only asks for the directory when it is not
already there, so the ordinary save is silent, but a failing
`make_dir_recursive_absolute()` prints from inside the engine and no caller can mute it.

Fixtures for the checked-in save files live in
[`godot/tests/fixtures/saves/`](../../tests/fixtures/saves).

## Owed by later rounds

- ~~**Loading from the title screen.**~~ **Done (round 10).** `apply()` deliberately
  cannot rescue a world that has been played, so a load builds fresh services and
  swaps the persistent layer over to them: `Services.load_game(slot)` rebuilds every
  service, reads the slot, applies it, and asks `RegionService` to place the Fool where
  the file says. `Services.save_game(slot)` is the way back out. Nothing else may
  assemble a playthrough - a caller with half-applied services is told to rebuild, and
  the composition root is where rebuilding lives.
- ~~**The fields this round holds by hand.**~~ **Done for the region ones (round 10).**
  Where the Fool is travels as one `regions` section of the file - `current_region_id`,
  `last_waystation_id` and the append-only `visited_waystations` set fast travel reads
  (`docs/design/progression.md` §Waystations). They are still fields on `SaveService`,
  written through its setters by `RegionService` and by nothing else, because the save
  model is the one home for the fact: a playthrough and its save cannot disagree about
  where the Fool was standing. The **difficulty mode** is still held by hand until
  combat/settings own it.
- **The `regions` section replaced two loose fields, inside v1.** `current_region_id`
  and `last_waystation_id` used to sit at the top level of the file. Folding them in
  (with the visited set) changed the v1 shape rather than bumping the schema, which is
  only defensible because **v1 has never shipped**: there is no save on any disk but a
  developer's, and the fixtures were rewritten with it. The next shape change after a
  build reaches a player is a v2 and a migration, per `SaveSchema`.
- ~~**`inventory`** is still written empty in v1.~~ **Done (round 11).** The
  progression economy fills it with the purse, what the Fool carries, the staff head
  on the Bindle and the Rose-grafting sources already taken — inside the same v1
  shape, needing no schema bump, exactly as the reserved field was meant to be used.
  `pocket_spread` went the same way in the Trumps round (round 6). Its keys belong to
  `EconomyService` (`SNAPSHOT_COINS` and friends), as the Rose's belong to the Rose:
  the section is opaque to `SaveModel`, so there is one place the shape is written
  down. What a shop has SOLD is not in the file — that is a fact about a shop between
  two rests, and the first rest after a load restocks it.
- **Playtime is world time.** `playtime_seconds` is the loaded save's counter plus the
  clock's seconds *since the load* — `apply()` baselines the clock, so time spent on a
  title screen before pressing Continue is not billed as play. It is still world time,
  which `Engine.time_scale` scales, so it drifts from wall-clock play during
  slow-motion. If the Almanack ever shows a play timer, it wants a real stopwatch
  (`Time.get_ticks_usec()`), not this counter.
