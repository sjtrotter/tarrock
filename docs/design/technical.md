# Technical — SSOT

Owns: engine and pipeline choices, project structure, architecture principles, the
runtime data model, the save system, and coding conventions. This is the canonical
version of the conventions — `CLAUDE.md` at the repository root will mirror a short
summary of this doc once code begins, but if the two ever disagree, this doc wins.
Content facts (what a Trump does, what a world-state fires) live in
[`arcana.md`](arcana.md) and [`world.md`](world.md); this doc owns only how those facts
are represented and enforced in code.

No code exists yet. This document defines the architecture and conventions code must
follow once it does.

## Engine and pipeline

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

### Port-readiness rules (non-negotiable, checked at every system's design time)

1. **Input abstraction.** All gameplay code reads from Input System actions, never raw
   device state. Action maps are authored device-agnostically (a "Dodge" action, not a
   "spacebar").
2. **UI scaling.** UI Toolkit / Canvas layouts use anchors and safe-area insets from day
   one; no UI element is authored at a fixed pixel position assuming a specific
   resolution or aspect ratio.
3. **No platform-specific hacks in gameplay/UI code.** Platform differences (achievements,
   save-cloud, storefront overlays) are isolated behind a thin platform-services
   interface, never `#if UNITY_PS5`-style branches scattered through gameplay code.

## Architecture principles

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

## Project structure

### Assembly definitions

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

### Assets/ folder tree

The Unity project root is the repository's `Tarrock/` subfolder (already created: Unity
6, URP template with PC + Mobile renderer assets, Input System package installed). The
tree below applies under `Tarrock/Assets/`.

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

## The runtime data model

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

## The WorldState service

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

## World streaming

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

## Save system

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

## Quests at runtime

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

## Headless validation workflow

All agent/CI validation uses **one Unity launch, not three**:
`Unity -batchmode -nographics -projectPath Tarrock -executeMethod Tarrock.Editor.Ci.FullValidate -logFile <log>`
(no `-quit` — the session exits itself: 0 = setup + all EditMode tests green, 1 = test
failures, 2 = setup threw). `Ci.TestsOnly` skips the setup chain. Editor performance
settings (parallel out-of-process import, async shader compilation) are applied by
`Tarrock/Setup/Apply Editor Performance Settings` and live in ProjectSettings.

## Localization

Unity Localization package, string tables, from day one. **No player-facing string
literal ever appears in code** — every piece of UI text, dialogue line, item name, and
quest title is a string-table reference resolved at runtime. This is non-negotiable
even before a second locale is planned: retrofitting localization after strings are
scattered through code is far more expensive than authoring against tables from the
start, and it keeps `DialogueGraph` assets (which already need to swap text by
world-state branch) uniform with everything else.

## Testing

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

## Coding conventions

- **File-scoped namespaces** (`namespace Tarrock.Combat;`), not block-scoped.
  Unity 6000.5 defaults its compiler to C# 9, which rejects these; the project
  therefore carries `Tarrock/Assets/csc.rsp` containing `-langversion:10.0`
  (verified compiling on 6000.5.3f1). That file is load-bearing — deleting it
  breaks the whole codebase's compile.
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

## Performance guardrails

- **No per-frame allocations in gameplay loops** (combat, AI, WorldState queries) —
  avoid LINQ and boxing in `Update`/`FixedUpdate` paths; prefer pooled collections.
- **Object pooling** for Blanks (spawned/despawned constantly across 22 regions) and for
  VFX (Trump effects, combat hits) — never instantiate/destroy on the hot path.
- **Profile before optimizing.** No speculative optimization; the Unity Profiler decides
  where budget actually goes.
- **Hard budget targets (frame time, draw calls, memory) are TBD** — set at milestone M1
  once a real greybox scene (Cliff + Prestige, per the GDD scope ladder) exists to
  profile against. Setting numeric targets before any content exists would be guessing.

## Open questions (TBD)

- Hard performance budget targets (frame time / draw calls / memory) — deferred to M1
  greybox, per **Performance guardrails** above.
- The Spin table's 8 fixed entries (Wheel of Fortune's Present effect) — flagged as TBD
  in `arcana.md` itself; affects `TrumpDefinition` effect-asset count for that Trump
  only, not the data model shape.
- Exact Addressable grouping strategy (per-region vs. per-asset-type groups) — a build
  performance tuning decision, deferred until region count and asset volume are known
  from the Act I milestone (`GDD.md` M3).
