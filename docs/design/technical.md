# Technical — SSOT

Owns: engine and pipeline choices, project structure, architecture principles, the
runtime data model, the save system, and coding conventions. This is the canonical
version of the conventions — `CLAUDE.md` at the repository root will mirror a short
summary of this doc once code begins, but if the two ever disagree, this doc wins.
Content facts (what a Trump does, what a world-state fires) live in
[`arcana.md`](arcana.md) and [`world.md`](world.md); this doc owns only how those facts
are represented and enforced in code.

Code exists now: the shipping 2D game in `godot/` (Godot 4.7.1, GDScript) and the
historical 3D telling in `unity/` (Unity 6, C#). Read **Engine status** next, then work
from the section for the engine you are in.

## Engine status (2026-08-17)

**Tarrock v1 ships as a complete 2D game** — oblique top-down in the *A Link to the Past*
tradition, isometric composition as flavor, side-view sequences as punctuation (the form
itself is stated in [`GDD.md`](../GDD.md) §Theme / Setting / Genre; the record of the
decision and its reasoning is [`final-claude-2d.md`](../final-claude-2d.md)) — built in
**Godot 4.7.1**, in `godot/`. The **Unity project in `unity/` is the historical / 3D
telling**: it is not deleted and it is not the build target for v1; a 3D Tarrock is a
possible later retelling (`final-claude-2d.md` §8), not a parallel branch of this one.

This document therefore has two bodies:

- **[Godot 2D — the shipping architecture](#godot-2d--the-shipping-architecture)** — the
  conventions all game code is written against from now on.
- **[Unity / 3D telling (historical)](#unity--3d-telling-historical)** — retained because
  the architecture reasoning (data-driven definitions, the single world-state mutation
  contract, the save model, quest state machines) is engine-independent; the Godot section
  is a translation of it, not a repudiation of it.

**Where the two disagree about the 2D game, the Godot section wins.** `shared/` holds
`Tarrock.Shared`, an engine-agnostic C# library seeded before the 2D decision; it stays a
seed — not expanded, and not consumed by the Godot systems (one language, one toolchain).

## Godot 2D — the shipping architecture

Owns the conventions **all Tarrock game code is written against from 2026-08-17 onward**.
It is a translation of the engine-independent architecture reasoning kept in the Unity
body below — same contracts, Godot vocabulary. Where the two disagree about the 2D game,
this section wins. Content facts still live in their owning docs
([`arcana.md`](arcana.md), [`world.md`](world.md), [`combat.md`](combat.md),
[`progression.md`](progression.md)); this section owns only how they are represented and
enforced in code.

### Engine and pipeline (Godot)

| Choice | Decision | Rationale |
|---|---|---|
| Engine | **Godot 4.7.1**, project at `godot/` (headless: `godot --headless --path godot …`) | 2D-native scene/node model, a fast headless loop that makes tests the default instrument, and no per-seat cost for an AI dev team. The existing Godot code and the art lane already live here. |
| Language | **GDScript, statically typed everywhere** | One language and one toolchain across systems, scenes, tools, and tests — the director's scene/art work and the systems work stay in the same project. C# / godot-mono is **not** used for game systems; `shared/Tarrock.Shared` stays the seed it is (see **Engine status**). |
| Render method | `gl_compatibility` (desktop and mobile) | A 2D storybook needs no clustered/deferred features; the widest hardware reach keeps the GDD's "nothing may preclude mobile" clause open. |
| Presentation | 2D, oblique top-down; `canvas_items` stretch, 1280×720 base viewport | The form stated in `GDD.md` §Theme / Setting / Genre. `canvas_items` scales world and UI together and keeps painterly art readable at arbitrary window sizes. |
| Camera | One `Camera2D` on the persistent layer, driven by a follow/framing service | The 2D counterpart of the Unity body's Cinemachine row: framing states (travel, Focus, boss arena, side-view sequence) are service-driven, never hand-rolled per scene. |
| Input | Godot **InputMap** actions only | Rebindable and device-abstracted; required by the port-readiness rules below. |
| Localization | Godot translation CSV under `godot/localization/`, resolved with `tr()` | Same day-one rule as the Unity body; see **Localization (Godot)**. |
| Content delivery | **Scene switching beneath a persistent autoload layer** — no Addressables analog | Regions are discrete authored `.tscn` files (`world.md` §Regions), loaded and freed one at a time while the persistent layer keeps services alive. Packing/streaming strategy is a build-time question, deferred (see **Open questions**). |
| Primary platform | PC / Steam | Unchanged from `GDD.md` §Target Platforms; development and tuning baseline. |
| Port posture | Console/mobile must never be *blocked* | Unchanged, restated for Godot below. |

#### Port-readiness rules (Godot)

1. **Input abstraction.** Gameplay code reads named InputMap actions through the one
   constants surface (`Input.is_action_pressed(InputActions.DODGE)`), never raw keycodes,
   `Input.is_key_pressed`, or a literal action string.
   Actions are authored device-agnostically and are rebindable at runtime.
2. **UI scaling.** Every `Control` uses anchors and container layout; nothing is placed at
   a fixed pixel offset that assumes 1280×720; the HUD root honours safe-area insets.
3. **No platform-specific hacks in gameplay/UI code.** Achievements, cloud saves, and
   storefront overlays sit behind one thin platform-services interface — never
   `OS.get_name()` branches scattered through gameplay.

### Architecture principles (Godot)

1. **SSOT carried into code.** Data flows **docs → `.tres` Resource assets → runtime**.
   A fact — a Trump's Present-slot effect, a world-state's firing quest, a region's
   adjacency — is authored once, as one resource. Code reads that resource; it never
   hardcodes a second copy. If a canon doc changes, exactly one resource changes.
2. **Data-driven core.** Trumps, Arcana, quests, world states, regions, dialogue, barks,
   and enemies are authored as `Resource` subclasses saved to `.tres`, not as code, so
   content authoring touches data and docs rather than engine code.
3. **Decoupling over convenience.** Systems talk through **typed signals declared on the
   service that owns the fact** and through read-only queries — never direct references
   to each other's nodes. There is **no global event bus** (an event bus is a God object
   with a nicer name); a subscriber connects to the owning service's signal.
4. **One autoload, and it is a composition root.** `Services`
   (`godot/systems/core/services.gd`) is the **only** entry in `project.godot`'s autoload
   list. It constructs and holds the long-lived services (world state, save, quests,
   dialogue, audio, localization) and hands them out. Every service is a plain
   `RefCounted` object **constructible without a scene tree**, so a headless test builds
   one directly (`WorldStateService.new()`) with no autoload, no scene, and no `SceneTree`
   in the way. Services never reach for `Services` themselves — dependencies are passed
   into their constructors.
5. **Scenes call systems; systems never reach into scenes.** No system does
   `get_node("/root/…")` or holds a `NodePath` into a region scene. A scene script obtains
   the services it needs, calls their methods, and connects to their signals; the flow of
   control into a scene is always a signal or a call the scene itself initiated.
6. **The persistent layer survives region switches.** The autoload layer plus the Fool,
   Pip, the camera, and the UI root are never freed when a region scene is swapped, so
   world state, save state, and UI outlive every transition (see **Regions and the
   persistent layer**).

### Project layout (`godot/`)

One folder per feature under `godot/systems/` — the direct analog of the Unity body's
one-asmdef-per-feature rule, matching the SSOT doc that owns each feature's content.
Boundaries are enforced by review and by the dependency direction below, not by the
engine; a system that needs a sibling's type takes that dependency deliberately, and
cycles are a review failure.

```
godot/
  project.godot                    # one autoload (Services); InputMap; warnings-as-errors
  systems/
    core/                          # Services composition root, base Definition resource,
                                   #   shared utilities; depends on nothing project-specific
    world_state/                   # world.md matrix, global states, Renown  (see below)
    save/                          # versioned save model + migration chain
    quests/                        # quest state machines; the only writer of world state
    dialogue/                      # dialogue graphs, choice tables, style lints
    trumps/                        # arcana.md Trump tables, progression.md Pocket Spread
    combat/                        # combat.md player kit, Focus, Fortune in combat
    enemies/                       # combat.md Blanks, Beasts, Fog-masks
    pip/                           # combat.md §Pip command wheel
    regions/                       # world.md regions, scene switching, Waystations
    progression/                   # progression.md economy, Renown, White Rose, Fortune
    npc/                           # npc-system.md barks, schedules, rumor, memory
    ui/                            # art-audio.md UI, HUD, Almanack, map-as-spread
    <feature>/definitions/         # EVERY feature: its Resource subclasses,
                                   #   one class per file, snake_case filenames
  data/<feature>/                  # .tres definition assets (generated or hand-authored)
  localization/strings.csv         # translation table(s); the only home of player text
  scenes/                          # region, character, and UI scenes (.tscn)
  scripts/                         # existing presentation scripts (player, Pip follower,
                                   #   animators); migrate under systems/ only when a
                                   #   round actually touches them
  art/                             # art packs and ART-REQUESTS.md (the director's lane)
  tests/
    run_all.sh                     # THE command; exit 0 = green
    runner.gd                      # headless entry point
    lib/tarrock_test.gd            # assertion helpers
    unit/*_test.gd                 # system tests (no scene tree required)
    *_test.gd                      # legacy scene-tree tests, still run by run_all.sh
  tools/                           # gen_definitions.py (arrives with the WorldState
                                   #   round), capture tools
```

Dependency direction: `core` ← everything; `world_state` ← `quests`, and everything else
reads world state through queries and signals; `quests` writes world state and nothing
else does. `ui` depends on the rest only through queries and signals, never the reverse.

### The runtime data model (Godot)

Definitions are **immutable at runtime** — authored data, loaded once, never written to
during play. This is enforced by convention *and* by a test asserting that no system
mutates a loaded definition (owed by the first round that ships a definition a system
reads — WorldState). All mutable state lives in the save model (below).

| Resource (`class_name`) | Mirrors | Key fields |
|---|---|---|
| `TrumpDefinition` | [`arcana.md`](arcana.md) per-Trump tables | Stable ID, display-name key, card number, **six effect references** — one per slot (`Past`, `Present`, `Future`) × orientation (upright/reversed) — plus the reversed burden. |
| `ArcanaDefinition` | [`arcana.md`](arcana.md) index + per-Arcana sections | ID, region reference, quest reference, encounter type/tier, gate condition, the `TrumpDefinition` it yields. |
| `QuestDefinition` | `../quests/` scripts | ID (`MQ##` / `SQ-<REGION>-##`), title key, arcana and region references, required/fired world states, branch groups, its state machine. |
| `WorldStateDefinition` | [`world.md`](world.md) §World-state matrix, one asset per row | The `WS_*` ID (character-identical to the matrix), firing quest reference, human-readable effect summary (doc text, not logic — logic lives in whoever subscribes). |
| `RegionDefinition` | [`world.md`](world.md) §Regions, §Layout | ID, display-name key, scene path, difficulty band, adjacency list, Waystation references. |
| `DialogueGraph` | [`narrative.md`](narrative.md) style, per-quest dialogue | Node graph resource; branch conditions are WorldState queries, never hardcoded booleans; every line is a translation key. |
| `EnemyDefinition` | [`combat.md`](combat.md) §Enemies | Suit × rank composition, stat block, telegraph timings, shared sprite/animation family reference — one asset per suit/rank combination. |
| `BarkDefinition` | [`npc-system.md`](npc-system.md) bark layers | A line key plus its conditions: layer, required `WS_*` combination, act/`CONFESSED` state, Renown tier, `READING_ORDER` motif query, region, suit. |
| `NPCProfile` | [`npc-system.md`](npc-system.md) + [`characters.md`](characters.md) | Identity fields: suit, Court rank, region, home/work/gathering anchors, schedule entries; for named NPCs, the per-NPC memory flag set. |

All of them extend one small base resource in `systems/core/` carrying the stable ID and
its validation, so "has a stable ID" is structural rather than a habit.

**Six-expression rule in data:** a `TrumpDefinition` never stores "one effect plus
modifiers" — it stores six explicit effect references, so `arcana.md` design rule 5 is
structurally impossible to under-implement. The reversed burden is data on the Trump,
applied by whichever slot the reversed card currently occupies.

**Generated vs. hand-authored.** Where a doc is already a table or frontmatter, the
`.tres` assets are **generated** from the doc by `godot/tools/gen_definitions.py` (built
in the WorldState round of `docs/gauntlet-systems/`; each later round extends it), and a
**drift test** fails whenever the docs and the generated data disagree — the doc stays the
source, and a canon edit cannot silently fail to reach the game:

| Generated from | Produces |
|---|---|
| [`world.md`](world.md) §World-state matrix | one `WorldStateDefinition` per row |
| [`world.md`](world.md) §Global states (act thresholds) | the act-threshold table |
| [`world.md`](world.md) §Regions (the list) | `RegionDefinition` set (adjacency is a diagram, so `RegionGraph` is hand-authored data citing §Layout's adjacency table) |
| `../quests/` YAML frontmatter | `QuestDefinition` metadata (see **Quests at runtime**) |
| [`progression.md`](progression.md) §Renown | the Renown ladder thresholds |

Everything whose canon is prose is **hand-authored**, and each asset records the doc
section it was authored from (`source_ref`, e.g. `arcana.md §XII. The Hanged Man`) so a
reviewer can check it against canon without guessing: Trump effects and burdens,
`ArcanaDefinition` encounter data, dialogue graphs, barks, enemy behavior, NPC profiles.

### The WorldState service (Godot)

`WorldStateService` is **the only mutation path** for world-state flags, Renown, and quest
state. No other system reads or writes a flag by any other route. Same contract as the
Unity body, in Godot terms:

- **Reads:** any system may query the service at any time — `is_fired(id) -> bool`,
  Renown per suit, current act — including from `DialogueGraph` branch conditions and UI.
  Queries are **plain per-flag booleans**, never an ordered log, so a check like "Sun
  unbound AND Star unbound" is correct regardless of unbind order (`world.md`'s
  order-independence rule).
- **Writes:** only quest state-machine transitions fire flags, set quest state, or record
  branch choices. Combat, dialogue, UI, and NPCs never write state; they raise domain
  events, and a quest transition responds and, if its conditions hold, calls the service.
  **One reviewed exception, for Renown only:** `progression.md` says Renown "moves in
  response to deeds and quest choices", and most deeds are not quests — so the
  progression economy's `record_deed(deed)` is the second (and last) writer of Renown,
  applying the deed table's per-suit reactions; it can never touch a flag, the Reading, or
  quest state.
- **Signals:** every successful mutation emits a typed signal on the service —
  `world_state_fired(id: StringName)`, `renown_changed(suit: Suit.Id, old: int, new: int)`
  (plus `renown_tier_changed` when the ladder tier moves), `act_changed(old: int, new: int)`,
  `reading_appended(arcana_id: StringName, index: int)`, and the equivalents for quest
  state, the Hermit answer, and named-NPC memory. Interested systems connect; **polling
  is forbidden**. Restoring a save does not emit — loading is not an event.
- **Permanence by construction:** there is **no un-fire method**. `fire(id)` exists;
  nothing named `unfire`, `clear`, or `set(id, false)` exists anywhere in the service's or
  the save container's surface, so "no unbinding is reversible" (`world.md`) is not a bug
  class to guard against — it is a call that cannot be written.
- **`READING_ORDER` is append-only:** the service itself appends an Arcana when its
  unbinding flag fires (branch flags never append); there is no public reorder, removal,
  or manual append — the Reading cannot drift from the flags.
- **`HERMIT_ANSWER` is set-once:** a second write is an error, not an overwrite.
- **Per-named-NPC memory** is held keyed by NPC ID alongside quest and Renown state.

This is the docs' own "nothing else may mutate the matrix" rule, compiled.

### Regions and the persistent layer

- **Persistent layer:** the `Services` autoload plus the Fool, Pip, the `Camera2D`, and
  the UI root live above the swapped scene and are never freed by a region change.
- **One scene per region**, matching `world.md` §Regions one-to-one, with adjacency read
  from the `RegionGraph` data (hand-authored from `world.md` §Layout's adjacency table,
  every edge citing its sentence; gates are data on edges) — never hardcoded in a scene.
- **`RegionService` is the only system allowed to load or free a region scene.** A
  transition frees the outgoing scene, instances the incoming one under the persistent
  layer, and re-anchors the Fool and Pip at the arrival Waystation or edge marker; every
  service survives untouched, and a test asserts service identity across a switch.
- **Waystations** (rest, respec, Rose regrowth, and fast travel once
  `WS_CHARIOT_UNBOUND` has fired) are region-owned nodes referenced by
  `RegionDefinition`; their rules belong to [`progression.md`](progression.md) §Waystations.

### Save system (Godot)

- **Format:** versioned JSON under `user://saves/`. Every file embeds `schema_version`
  (int).
- **Migrations:** each version bump ships an explicit `migrate_v3_to_v4`-style function,
  run in sequence on load until the save reaches the current version. A missing
  intermediate migration is a **hard failure**, never a best-effort guess, and each
  migration is tested against a checked-in fixture save.
- **IDs only:** the save never serializes a definition resource. It stores stable string
  IDs (`WS_SUN_UNBOUND`, `MQ13`, Trump IDs) and the mutable data attached to them (quest
  state, Pocket Spread slot assignments and orientations, Renown, inventory counts);
  definitions are re-resolved from ID at load.
- **Append-only containers:** the fired-flag set exposes `add(id)` and nothing else; the
  `READING_ORDER` list exposes `append(id)` and nothing else. Per-named-NPC memory is
  stored keyed by NPC ID.

### Quests at runtime (Godot)

`QuestDefinition` is a small state machine: named states, and transitions gated by events
(combat, dialogue, region triggers) and/or WorldState conditions. Reaching a terminal
`complete` state is the only thing that permits the quest's `fires` world states to be
committed — a quest that is abandoned mid-way commits nothing.

Quest docs' YAML frontmatter maps 1:1 onto `QuestDefinition` fields. The frontmatter
**schema itself is owned by [`quests/README.md`](../quests/README.md)** and is not
restated here; the mapping is:

| Frontmatter key | `QuestDefinition` field | Notes |
|---|---|---|
| `id` | `id` | `MQ##` / `SQ-<REGION>-##`, per `GLOSSARY.md`. |
| `title` | `title_key` | Translation key (`QUEST_<ID>_TITLE`, generated into `localization/quest_titles.csv`), never a literal. |
| `arcana` | `arcana_number` | The card number (0 = none, 1–21), parsed from the roman numeral at generation time — the same key `WorldStateDefinition` uses; an `ArcanaDefinition` lookup by number arrives with the Trumps round. |
| `region` | `region_id` | The region token (`CLIFF`, `PRESTIGE`, … — the same token side-quest ids use; GLOSSARY names with "The" dropped, uppercase); resolved to a `RegionDefinition` once the Regions round ships them. |
| `requires` | `required_states` | `WS_*` and/or quest IDs; all must hold before the opening state is reachable. |
| `fires` | `fired_states` | Committed through `WorldStateService` at completion only. |
| `branches` | `branch_groups` | Mutually exclusive `WS_*` sets; the runtime enforces exactly one per group at completion. |
| `type` | `type` | Main / Side; drives Almanack categorization. |
| `status` | — | Doc-workflow field, not imported; validation may warn when it disagrees with what shipped. |

A quest doc's beats inform the authored transition graph but are not part of this
mapping — the frontmatter is metadata for cross-referencing and validation (the
generator's drift check and the catalog's boot validation check that every `requires` ID
exists as a `WorldStateDefinition` or a quest). The graph itself is a hand-authored
`QuestGraph` resource (`data/quests/graphs/<ID>.tres`) that the generated definition links
to when it exists; scenes, combat, and dialogue **raise events** (`QuestEvents`) on the
`QuestService`, whose transitions are the only writers of world state, and a quest's
`fires` (plus exactly one chosen flag per branch group) commit only on reaching a
complete state.

### Localization (Godot)

Godot translation CSVs under `godot/localization/`, resolved with `tr()`, from day one
(the CSV is the authored source; Godot's imported `.translation` files are build
artifacts, registered in `project.godot`'s `locale/translations`).
**No player-facing string literal ever appears in code or in a data resource** — UI text,
dialogue lines, item names, and quest titles are translation keys. A lint test walks
`.tscn` files under `scenes/` and `systems/`, `.gd` files under `systems/`, and `.tres`
files under `data/` (doc-citation fields such as `effect_summary`/`source_ref` exempted)
and fails on a displayable literal, so the rule is enforced rather than remembered. Keys are stable IDs; the CSV is the only place English
text lives.

### Input actions

The InputMap action list gameplay code may read (device-agnostic, all rebindable):

`move_left`, `move_right`, `move_up`, `move_down`, `sprint`, `interact`, `attack_light`,
`attack_heavy`, `dodge`, `block_step`, `focus`, `focus_cycle`, `rose`, `pip_wheel`, `spread`,
`almanack`, `pause`.

Godot's built-in `ui_*` actions are for menu navigation only; gameplay code never reads
them (`godot/scripts/player.gd`'s current `ui_*` use is migrated). Verbs map to
[`combat.md`](combat.md): `focus` holds the Focus stance (`focus_cycle` steps the lock to the next target), `dodge`
is the roll and its directional variants inside Focus, `block_step` is the hop-guard, `sprint` is held (or
toggled, per §Accessibility); there is deliberately **no jump action** in the top-down
grammar.

### Testing (Godot)

**One command runs everything: `bash godot/tests/run_all.sh` — exit 0 is green, and any
failing test fails the command.** It runs the headless unit suite and the legacy
scene-tree tests together; a test that only passes when run alone does not count.

| Surface | Type | Why mandatory |
|---|---|---|
| World-state transitions | headless unit | The fire/query/permanence contract is the game's single mutation path; a regression here corrupts every save. |
| Quest state machines | headless unit | Quest logic is pure data plus transitions, and quests are the only writer of world state. |
| Save migrations | headless unit | Every migration is verified against a fixture save; a silent migration bug corrupts existing players' saves. |
| Definition drift | headless unit | Generated `.tres` assets must still match the docs they came from (see **Generated vs. hand-authored**). |
| Localization lint | headless unit | Catches a player-facing literal the day it is written. |

Additionally (from the Regions round onward): **one integration test per region scene**, asserting the scene instances
under the persistent layer, its `RegionDefinition` resolves, its Waystation (if any) is
reachable, and every service survives the switch.

Services are plain objects, so unit tests construct them directly; a test that needs a
`SceneTree` is an integration test and says so by living in the integration set.

### Coding conventions (GDScript)

- **Static typing everywhere.** Every variable, parameter, and return is typed;
  `debug/gdscript/warnings/untyped_declaration` is set to **error** in `project.godot`, so
  an untyped declaration fails the build rather than a review.
- **One class per file**, file named for the class: `snake_case` filenames,
  `PascalCase` `class_name` (`world_state_service.gd` → `class_name WorldStateService`).
- **Naming:** `snake_case` for functions and variables, `PascalCase` for classes and
  enums, `SCREAMING_SNAKE_CASE` for constants, a `_leading_underscore` for private members
  (privates are private by review, not by the language — treat the underscore as binding).
- **`##` doc comments** on every public class and public method, saying what the caller
  gets, not how it works.
- **Typed signals** (`signal world_state_fired(id: StringName)`), declared on the service
  that owns the fact. No global event bus.
- **No magic strings.** `WS_*`, quest, Trump, and region IDs are read from the definitions
  that own them or from a generated constants surface — never typed as literals in logic.
- **No `get_node` string paths from a system into a scene** (architecture principle 5).
- **No per-frame allocations in combat and AI loops** — no array/dictionary construction
  in `_process`/`_physics_process` hot paths; pool instead.
- **`await` for sequencing**; timers and tweens are for presentation, not for game logic
  whose result something else depends on.

### Performance guardrails (Godot)

- **No per-frame allocations in gameplay loops** (combat, AI, WorldState queries).
- **Pooling** for Blanks and for repeated VFX (Trump effects, hit sparks) — never
  instance/free on the hot path.
- **Profile before optimizing.** No speculative optimization; Godot's profiler decides.
- **Hard budget targets (frame time, draw calls, memory) are TBD** — set once the
  Cliff → Prestige proof slice exists to profile against, per the Unity body's same rule.

### Open questions (TBD) — Godot 2D

- **Hard performance budget targets** — deferred to the proof slice, as above.
- **Export/packing strategy** for region content (single PCK vs. per-region packs) — a
  build-size and load-time decision, deferred until region count and art volume are real.
- ~~Rebinding UI and the settings save~~ — **decided (UI round, 2026-08-18):** rebinds and
  all settings (difficulty mirror, accessibility, text scale, hold/toggle) live in
  `user://settings.cfg` via `ConfigFile`, never in the save file; the save keeps only the
  difficulty mode itself.
- **Whether `shared/Tarrock.Shared` is ever revived** for a 3D retelling — out of scope
  for the 2D game, which does not consume it.

## Unity / 3D telling (historical)

Everything below describes the Unity 6 / C# project in `unity/`, written before the 2D
decision. It stays canonical **for that project** and for a future 3D retelling; it is
**not** the spec for `godot/`, and nothing in it may be cited to justify a choice in the
shipping 2D game. Read it for the reasoning behind a contract, not for the API.

### Engine and pipeline

| Choice | Decision | Rationale |
|---|---|---|
| Engine | Unity 6 LTS | Long support window for a multi-year project run by one human director plus an AI dev team (`GDD.md` §Iteration clause); mature URP and Addressables by this version. |
| Render pipeline | URP, stylized | The storybook-medieval art direction ([`art-audio.md`](art-audio.md)) needs a toon/painterly stylized look, not photoreal fidelity; URP is also the more efficient craft choice to keep 22 open regions performant — efficiency as craft, buying iteration time, per `GDD.md` §Iteration clause, not a budget shortfall. |
| Language | C# | Unity's native language; no alternative considered. |
| Input | Input System package | Rebindable, device-abstracted input is required to keep console/mobile ports non-blocking (see below); the legacy Input Manager does not support this cleanly. |
| Camera | Cinemachine | Third-person action-adventure needs state-driven cameras (combat lock, exploration follow, boss-arena framing) without hand-rolled camera code. |
| Content delivery | Addressables | Enables the region-streaming model (below) and keeps the eventual build size manageable; also the only sane path to any future DLC (GDD's paid-story-DLC possibility). |
| Primary platform | PC / Steam | Matches GDD target platforms; development and tuning baseline. |
| Port posture | Console/mobile must never be *blocked* | Nothing in the architecture may assume mouse+keyboard, a fixed resolution, or unlimited storage. See **Port-readiness rules** below. |

#### Port-readiness rules (non-negotiable, checked at every system's design time)

1. **Input abstraction.** All gameplay code reads from Input System actions, never raw
   device state. Action maps are authored device-agnostically (a "Dodge" action, not a
   "spacebar").
2. **UI scaling.** UI Toolkit / Canvas layouts use anchors and safe-area insets from day
   one; no UI element is authored at a fixed pixel position assuming a specific
   resolution or aspect ratio.
3. **No platform-specific hacks in gameplay/UI code.** Platform differences (achievements,
   save-cloud, storefront overlays) are isolated behind a thin platform-services
   interface, never `#if UNITY_PS5`-style branches scattered through gameplay code.

### Architecture principles

1. **SSOT carried into code.** The design docs are the source of truth; data flows
   **docs → ScriptableObject assets → runtime**. A fact — a Trump's Present-slot effect,
   a world-state's fired-by quest, a region's adjacency — is authored once, as data, in
   one asset. Code reads that asset; it never hardcodes a second copy of the fact. If a
   canon doc changes, exactly one asset changes to match it — never a scattering of
   constants across scripts.
2. **Data-driven core.** Gameplay content (Trumps, Arcana, quests, world states, regions,
   dialogue, enemies) is authored as ScriptableObject assets, not as code. Designed so
   that AI-assisted content authoring (writing a new quest, tuning a Trump) touches data
   assets and docs, not engine code.
3. **Decoupling over convenience.** Systems talk through ScriptableObject event channels
   and the WorldState service (below), not direct references to each other's
   `MonoBehaviour`s. No God objects — no single manager class that knows about combat,
   quests, dialogue, *and* UI.
4. **No static singletons**, with exactly one sanctioned exception: a composition-root /
   bootstrap scene that constructs and wires long-lived services at startup (the WorldState
   service, save service, audio service, etc.). Those services themselves are plain C#
   objects handed out through the bootstrap, not `static` accessors sprinkled through the
   codebase — this keeps them testable in EditMode without a running scene.
5. **Scene-independent services survive region streaming.** Services live in the
   persistent core scene (or as `DontDestroyOnLoad`-managed objects created by the
   bootstrap) so that additive region scenes can load and unload freely without tearing
   down world state, save state, or UI.

### Project structure

#### Assembly definitions

One asmdef per feature, matching the SSOT doc that owns its content, plus Editor and
Tests variants so EditMode tests can reference feature logic without pulling in engine
Editor code:

| Assembly | Corresponds to | Notes |
|---|---|---|
| `Tarrock.Core` | Bootstrap, shared utilities, event-channel base types | Everything else depends on this; this depends on nothing project-specific. |
| `Tarrock.WorldState` | [`world.md`](world.md) world-state matrix, global act states | The single mutation path for all flags/Renown/quest state (see below). |
| `Tarrock.Quests` | [`world.md`](world.md) requires/fires, `../quests/` scripts | Depends on `Tarrock.WorldState`. |
| `Tarrock.Combat` | [`combat.md`](combat.md) | Depends on `Tarrock.Core`; talks to `Tarrock.Trumps` only via event channels. |
| `Tarrock.Trumps` | [`arcana.md`](arcana.md) Trump tables, [`progression.md`](progression.md) Pocket Spread rules | Depends on `Tarrock.WorldState` (Trump effects can read/query state) and `Tarrock.Core`. |
| `Tarrock.Dialogue` | [`narrative.md`](narrative.md) style, dialogue graphs | Depends on `Tarrock.WorldState` (branch on flags), `Tarrock.Quests`. |
| `Tarrock.UI` | [`art-audio.md`](art-audio.md) UI, the Almanack | Depends on the above only through event channels/read-only queries, never direct references. |
| `Tarrock.Regions` | [`world.md`](world.md) regions, streaming | Owns the additive-scene loader and region-local composition. |

Each ships an `.Editor` asmdef (custom inspectors, validation tools) and a `.Tests`
asmdef (EditMode tests referencing only the runtime asmdef, not `.Editor`).

#### Assets/ folder tree

The Unity project root is the repo's **`unity/` subfolder** (Unity 6, URP template with
PC + Mobile renderer assets, Input System package installed) — open `unity/` in Unity
Hub. The tree below applies under `unity/Assets/`.

```
Assets/
  _Project/
    Scenes/
      Bootstrap.unity              # composition root; loads Core additively then a region
      Core.unity                   # persistent scene: WorldState, save, audio, UI root
      Regions/
        Cliff.unity
        Prestige.unity
        ...                        # one additive scene per world.md region
    Scripts/
      Core/
      WorldState/
      Quests/
      Combat/
      Trumps/
      Dialogue/
      UI/
      Regions/
    Data/                          # ScriptableObject assets — the SSOT-in-data layer
      Arcana/
      Trumps/
      Quests/
      WorldStates/                 # one asset per world.md matrix row, WS_* named
      Regions/
      Enemies/
      Dialogue/
    Localization/                  # Unity Localization string tables
    Addressables/                  # Addressable group definitions, region content
    Art/
    Audio/
  Plugins/
  Tests/
    EditMode/
    PlayMode/
```

### The runtime data model

Definitions are **immutable at runtime** — they are authored data, loaded once, and
never written to during play. All mutable state lives in the save model (below). This
mirrors the docs' own SSOT rule: a `TrumpDefinition` asset is to runtime code what
`arcana.md` is to a quest doc — cited, never duplicated.

| ScriptableObject | Mirrors | Key fields |
|---|---|---|
| `TrumpDefinition` | [`arcana.md`](arcana.md) per-Trump tables | Stable ID, display name/card number, **six effect references** — one per slot (`Past`, `Present`, `Future`) × orientation (upright/reversed) — plus the reversed burden description. |
| `ArcanaDefinition` | [`arcana.md`](arcana.md) index + per-Arcana sections | ID, region reference, quest reference, encounter type/tier, gate condition, reference to the `TrumpDefinition` it yields. |
| `QuestDefinition` | `../quests/` scripts | ID (`MQ##` / `SQ-<REGION>-##`), title, arcana reference, region reference, required world states, fired world states, its state machine (below). |
| `WorldStateDefinition` | [`world.md`](world.md) world-state matrix, one asset per row | The `WS_*` ID (identical string to the matrix), firing quest reference, human-readable effect summary (doc text, not logic — logic lives in the systems that subscribe). |
| `RegionDefinition` | [`world.md`](world.md) §Regions | ID, display name, Addressable scene reference, difficulty band, adjacency list, Waystation references. |
| `DialogueGraph` | [`narrative.md`](narrative.md) style, per-quest dialogue | Node graph asset; branches read WorldState queries, never hardcoded booleans. |
| `EnemyDefinition` | [`combat.md`](combat.md) Blanks | Suit × rank composition (Cups/Swords/Wands/Coins × the four ranks), stat block, shared rig reference — one definition asset per suit/rank combination, one shared rig family, per the GDD's asset-sharing mandate. |
| `BarkDefinition` | [`design/npc-system.md`](npc-system.md) bark layers | A line plus its conditions: layer (1–7), required `WS_*` combination, act/`CONFESSED` state, Renown tier, `READING_ORDER` motif query, region reference, suit reference. |
| `NPCProfile` | [`design/npc-system.md`](npc-system.md) named/ambient NPCs + [`characters.md`](characters.md) | Identity fields: suit, Court rank, region, home/work/gathering-place anchor references, schedule entries; for named NPCs, the per-NPC memory flag set. |

**Six-expression rule in data:** a `TrumpDefinition` never stores "one effect plus
modifiers" — it stores six explicit effect references so that arcana.md's "one card,
six expressions" rule is structurally impossible to under-implement. Each reference
points to a small effect asset/strategy object; the reversed burden is data on the
Trump, applied by whichever slot the reversed card currently occupies.

### The WorldState service

A single runtime service is **the only mutation path** for world-state flags, Renown,
and quest state. No other system reads or writes a flag by any other route.

- **Reads:** any system may query the WorldState service (`IsFired(WorldStateId)`,
  current Renown per suit, current act) at any time, including from `DialogueGraph`
  branch conditions and UI.
- **Writes:** only quest state-machine transitions (via `Tarrock.Quests`) call the
  service's fire/adjust methods. Combat, dialogue, and UI never write state directly —
  they raise domain events; a quest's transition responds to the event and, if its
  conditions are met, calls the service.
- **Events:** every successful mutation fires a ScriptableObject event channel
  (`OnWorldStateFired`, `OnRenownChanged`, ...). Systems that care (ambient bark
  pools, shop pricing, region dressing) subscribe; they never poll.
- **Order-independence:** per `world.md`'s interaction rules, the service exposes plain
  boolean queries per flag rather than an ordered log, so any system checking "is the Sun
  unbound AND is the Star unbound" behaves correctly regardless of unbind order.

This is deliberately the same shape as the docs' own rule that "nothing else may mutate"
the world-state matrix (`world.md` §World-state matrix) — the service is that rule,
compiled.

### World streaming

- **Persistent core scene** holds the bootstrap-wired services (WorldState, save,
  audio, UI root, Fool/Pip) and is never unloaded.
- **One additive scene per region**, matching `world.md`'s region list one-to-one; the
  Longroad's ring structure and each region's adjacency (`world.md` §Layout) determine
  which neighboring region scenes preload near a boundary.
- **Addressables** deliver region scene content and region-scoped data assets, so a
  region's art/audio/data footprint is only resident in memory while the player is near
  it — required both for PC performance targets and to keep a console/mobile port
  plausible.
- `Tarrock.Regions` owns the streaming loader; it queries `RegionDefinition` assets for
  Addressable keys and adjacency, and it is the only system allowed to load/unload
  region scenes.

### Save system

- **Format:** versioned JSON. Every save file embeds a schema version integer.
- **Migrations:** each version bump ships an explicit migration function
  (`MigrateV3ToV4`, etc.) run in sequence on load until the save reaches the current
  version. No "best effort" or implicit migration — a missing migration function for an
  intermediate version is a build error, not a runtime guess.
- **Separation from definitions:** the save model never serializes a `TrumpDefinition`,
  `QuestDefinition`, etc. wholesale. It stores only **stable string IDs** (the same IDs
  authored in the ScriptableObject assets — `WS_SUN_UNBOUND`, `MQ13`, Trump card IDs) and
  the mutable data attached to them (quest state, Pocket Spread slot assignments, Renown
  values, inventory counts). Definitions are re-resolved from ID at load time. This keeps
  saves stable across content patches that don't remove an ID, and keeps the definitions
  themselves free of save-only concerns.
- **World-state permanence, enforced by construction:** per `world.md`, a fired `WS_*`
  flag is permanent within a save — "no unbinding is reversible" is a hard rule, not a
  convention. The save layer represents fired states as an **append-only set**: the only
  operation the save model's world-state container exposes is `Add(id)`; there is no
  `Remove` or `Set(false)` method anywhere in its public surface, so un-firing a flag is
  not a runtime bug to guard against — it is a method that does not exist to call.
- **`READING_ORDER`:** per `world.md` §Global states, the save also records the ordered
  list of unbound Arcana — the Fool's Reading — as it happens, not just the unordered
  `WS_*` set. Same immutability guarantee as world-state flags: the container is
  **append-only** (`Append(id)`, no reorder, no remove), since a card once turned cannot
  un-turn or change position in the Reading. Consumed by the Almanack display, MQ21's
  True Shuffle read-back, and `npc-system.md`'s sequence-bark layer.
- **Per-named-NPC memory:** each named NPC (`characters.md` recurring cast + quest
  promotions) has its own small flag set recording notable dealings with the Fool,
  stored keyed by NPC ID alongside quest/Renown state. See
  [`design/npc-system.md`](npc-system.md) §Named vs. ambient NPCs.

### Quests at runtime

`QuestDefinition` is a small state machine: a set of named states, and transitions
between them gated by events (combat, dialogue, region triggers) and/or WorldState
conditions. Reaching a terminal "complete" state is what allows the quest's `fires`
world states to be committed through the WorldState service.

Quest docs in `../quests/` (see [`quests/README.md`](../quests/README.md) for the full
ID scheme and script template — **that file owns the frontmatter schema itself**; this
table is the runtime mapping only) carry YAML frontmatter that maps 1:1 to
`QuestDefinition` fields:

| Frontmatter key | QuestDefinition field | Notes |
|---|---|---|
| `id` | `Id` | `MQ##` or `SQ-<REGION>-##`, per `GLOSSARY.md` naming conventions. |
| `title` | `Title` | Display string; routed through localization, never hardcoded per-locale. |
| `arcana` | `Arcana` (reference) | Resolved to an `ArcanaDefinition` asset by ID at import/authoring time. |
| `region` | `Region` (reference) | Resolved to a `RegionDefinition` asset by ID. |
| `requires` | `RequiredStates` (list) | `WS_*` IDs and/or quest IDs; all must be satisfied before the quest's opening state is reachable. |
| `fires` | `FiredStates` (list) | List of `WS_*` IDs; committed via the WorldState service when the quest reaches completion. |
| `branches` | `BranchGroups` (list of lists) | Mutually exclusive `WS_*` flags set by player choice; the runtime enforces exactly-one-per-group on completion. |
| `type` | `Type` (enum: Main, Side) | Drives Almanack categorization. |
| `status` | — (not imported) | Doc-workflow field only (`outline`/`script`/`implemented`); validation tooling may warn when an implemented quest's doc status disagrees. |

A quest doc's own internal states/beats (its script) inform the authored transition
graph but are not part of the frontmatter mapping above — the frontmatter is metadata
for cross-referencing and validation (e.g., a tool that checks every `requires` ID
exists as a `WorldStateDefinition` asset), not the full state machine.

### Headless validation workflow

All agent/CI validation uses **one Unity launch, not three**:
`Unity -batchmode -nographics -projectPath <repo>/unity -executeMethod Tarrock.Editor.Ci.FullValidate -logFile <log>`
(no `-quit` — the session exits itself: 0 = setup + all EditMode tests green, 1 = test
failures, 2 = setup threw). `Ci.TestsOnly` skips the setup chain. Editor performance
settings (parallel out-of-process import, async shader compilation) are applied by
`Tarrock/Setup/Apply Editor Performance Settings` and live in ProjectSettings.

### Localization

Unity Localization package, string tables, from day one. **No player-facing string
literal ever appears in code** — every piece of UI text, dialogue line, item name, and
quest title is a string-table reference resolved at runtime. This is non-negotiable
even before a second locale is planned: retrofitting localization after strings are
scattered through code is far more expensive than authoring against tables from the
start, and it keeps `DialogueGraph` assets (which already need to swap text by
world-state branch) uniform with everything else.

### Testing

| Surface | Type | Why mandatory |
|---|---|---|
| World-state transitions | EditMode | The WorldState service's fire/query/permanence guarantees are the game's single mutation contract (see above); a regression here corrupts every save. |
| Quest state machines | EditMode | Quest logic is pure data + transitions — testable without a scene, and quests are the only path that writes world state. |
| Save migrations | EditMode | Each version's migration function must be independently verified against a fixture save; a silent migration bug corrupts existing players' saves. |

Additionally: **one PlayMode smoke test per region**, verifying the region's additive
scene loads, its `RegionDefinition` resolves, and its Waystation (if any) is reachable —
catches streaming/Addressables breakage without needing full gameplay coverage.

**CI:** GitHub Actions, once the repository is hosted on GitHub — running the EditMode
suite (and PlayMode smoke tests where CI runners support it) on every push. Not yet
wired up during the docs phase.

### Coding conventions

- **Block-scoped namespaces** (`namespace Tarrock.Combat { … }`), **never file-scoped**.
  Hard-learned rule: Unity 6000.5 can be forced to *compile* C# 10 file-scoped
  namespaces via a `csc.rsp` langversion override, but the editor's **script-class
  binder cannot parse them** — MonoBehaviours compile and even `AddComponent` in
  memory, then get **silently dropped from scenes at save** ("referenced script
  (Unknown) is missing"), and the Add Component menu reports "script class cannot
  be found." The project stays on Unity's stock C# 9, no `csc.rsp`. A guard test
  (`SceneScriptReferenceTests`) pins required components' presence in the Cliff
  scene so a regression of this class fails CI.
- **One public type per file**, file named for the type.
- **Naming:** `PascalCase` for public members; `_camelCase` for private fields.
- **`[SerializeField] private`** over public fields — Unity Inspector exposure without
  breaking encapsulation.
- **No magic strings.** IDs (`WS_*`, quest IDs, Trump card IDs) are never typed as raw
  string literals in logic — they are read from the definition assets that own them, or
  from a generated/validated constants surface if a compile-time reference is needed.
- **`async`/`await`** for logic flow (loading, save I/O, sequencing gameplay logic).
  Coroutines are acceptable **only** for purely visual sequencing (camera moves, VFX
  timing) where Unity's coroutine/animation tooling is the natural fit.
- **Assembly definitions per feature** — see the asmdef table above; a script that
  needs a type from a sibling feature asmdef takes that as a dependency deliberately,
  not by accident (no cyclic asmdef references).

### Performance guardrails

- **No per-frame allocations in gameplay loops** (combat, AI, WorldState queries) —
  avoid LINQ and boxing in `Update`/`FixedUpdate` paths; prefer pooled collections.
- **Object pooling** for Blanks (spawned/despawned constantly across 22 regions) and for
  VFX (Trump effects, combat hits) — never instantiate/destroy on the hot path.
- **Profile before optimizing.** No speculative optimization; the Unity Profiler decides
  where budget actually goes.
- **Hard budget targets (frame time, draw calls, memory) are TBD** — set at milestone M1
  once a real greybox scene (Cliff + Prestige, per the GDD scope ladder) exists to
  profile against. Setting numeric targets before any content exists would be guessing.

### Open questions (TBD)

- Hard performance budget targets (frame time / draw calls / memory) — deferred to M1
  greybox, per **Performance guardrails** above.
- The Spin table's 8 fixed entries (Wheel of Fortune's Present effect) — flagged as TBD
  in `arcana.md` itself; affects `TrumpDefinition` effect-asset count for that Trump
  only, not the data model shape.
- Exact Addressable grouping strategy (per-region vs. per-asset-type groups) — a build
  performance tuning decision, deferred until region count and asset volume are known
  from the Act I milestone (`GDD.md` M3).
