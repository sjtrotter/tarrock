# `systems/npc` — bark layers, named-NPC memory, rumour propagation, light schedules

Owns the runtime side of
[`docs/design/npc-system.md`](../../../docs/design/npc-system.md): the seven-layer bark
selector, the named/ambient split and named-NPC memory gating, rumour propagation
(`WS_*`-flag-fired news spreading on a delay), and the anchor-point schedule lookup.
Also reads [`docs/design/world.md`](../../../docs/design/world.md) §The Fool's Reading
(the sequence-bark motifs and §Layout's adjacency), §World-state matrix and §Global
states; [`docs/design/progression.md`](../../../docs/design/progression.md) §Renown;
[`docs/design/characters.md`](../../../docs/design/characters.md) §The Minors, §The
Courts, §Recurring named NPCs, §Pip; and
[`docs/design/technical.md`](../../../docs/design/technical.md)'s `BarkDefinition` /
`NPCProfile` rows. *Who* NPCs are belongs to `characters.md`; this system owns *how*
the population behaves and talks.

## The pillar, made structural

`npc-system.md` §The pillar: "an aware line is a bug if it ignores the world" — a
canned line that ignores a transformed world is treated exactly as a broken quest
trigger would be. Three places carry that structurally rather than by review:

- **`BarkDefinition.validate()`** refuses a line filed in a layer it does not actually
  fit (a layer-3 bark with no `WS_*` condition, a layer-7 line with any condition at
  all) — see its `_validate_layer_fit()`.
- **`BarkCatalog.validate()`** refuses a *complete* catalog missing a layer-7 baseline
  for any suit — the evergreen floor the fall-through depends on (below).
- **There is no Pip speaker, structurally.** `BarkDefinition.SpeakerKind` has three
  members and none of them is Pip; `NpcIds` has no Pip id. Pip "never answers, in
  dialogue or bark" (`characters.md` §Pip) because there is no field to put him in, not
  because something remembers to check.

## The evergreen floor, stated exactly

§Bark layers promises that a request can never come back empty: "A pool with zero
unspent, non-decayed lines falls through immediately — there is no stall or default
silence line; the next layer down always has content, because layer 7 is mandatory and
evergreen." Four rules hold that up, and none of them is a review convention:

1. **A floor is an UNCONDITIONED AMBIENT LINE WITH A SUIT.** `BarkDefinition.
   is_suit_baseline()` is the definition: layer 7, `AMBIENT_MINOR`, a real suit, `ANY`
   rank, no region, no flag, no act, no Renown, no quest, no memory, no motif, no
   rumour, no sky, and not `about_pip`. Anything that can be filtered out is a line the
   floor can lose, so it does not count as one — `BarkCatalog.suits_without_baseline()`
   counts only these, and `validate()` refuses a *complete* catalog missing one for any
   suit.
2. **Layer 7 is per suit, never per person and never per rank.** `_validate_generic()`
   refuses a `NAMED` speaker (a floor for one NPC is no floor for their suit) and any
   Court rank (a baseline for Knights leaves the Pages with nothing).
3. **A named NPC draws their suit's baseline.** `BarkService._is_the_speakers_baseline()`
   is the one cross-kind match in the selector: at layer 7 — and only there, and only
   after every more specific layer has declined — a `NAMED` context matches the
   `AMBIENT_MINOR` baseline of the suit on their `NpcProfile`.
4. **A speaker with no suit is refused at the door.** `BarkContext.ambient()` pushes an
   error and returns `null` for `Suit.UNKNOWN`, because a suitless Minor could match no
   floor at all. A *named* NPC whose profile has no canon suit (six of the nine today)
   is the one remaining gap, and it is audible rather than silent: the request comes
   back empty and `bark_missing` fires.

The Querent sits outside all of this by the doc's own logic: the Querent has no suit and
speaks over one region, so a Querent baseline is keyed by region instead (the Cliff's
four idle lines) and is never a suit's floor.

## Writers' rules the code cannot lint

- **§Reactivity guardrail: awareness never lectures.** "A bark that could be mistaken
  for a tooltip has failed, regardless of how 'aware' it is" — an aware line references
  the change *sideways, in-character*, never as a status readout. No check here can tell
  a sideways line from a patch note, so this one is enforced in review against
  `narrative.md`'s tone bar, and the conditions on a `BarkDefinition` only decide *when*
  a line may be said, never whether it earns saying.

## The shape of it

```
BarkService.request(context: BarkContext) -> BarkPick
    walks BarkLayer.DESCENDING (1..7, most specific first)
    within a layer: filters by every BarkDefinition condition, excludes the
    recently-spent ring for this pool key, picks with a seeded RNG
    falls through an exhausted layer; layer 7 always yields for a complete catalog
  |
  +-- RumorService   "has this region heard the news of quest X yet" (layer 3 condition)
  +-- ScheduleService "where does this NPC stand at this time of day" (§Daily life)
```

`BarkContext` carries the SPEAKER (who, where, whether Pip is near, the caller's belief
about the sky); `BarkService` reads everything about the WORLD itself
(`WorldStateService`) at request time, so a caller can never hand in a stale world and
get a line that ignores it.

## Files

| File | What |
|---|---|
| `bark_layer.gd` | `BarkLayer` — the seven layer numbers and their evaluation order |
| `bark_context.gd` | `BarkContext` — a bark request: speaker, region, Pip proximity, advisory sky |
| `bark_pick.gd` | `BarkPick` — a request's answer, reused across calls |
| `bark_ids.gd` | `BarkIds` — every shipped bark id (today: the Cliff's four) |
| `motif_ids.gd` | `MotifIds` — **generated** from `world.md` §The Fool's Reading |
| `npc_ids.gd` | `NpcIds` — every named NPC id, hand-authored from `characters.md` |
| `npc_memory_ids.gd` | `NpcMemoryIds` — the universal memory-flag vocabulary |
| `npc_rank.gd` | `NpcRank` — Court rank as an NPC IDENTITY (not the enemy `Rank`) |
| `time_band.gd` | `TimeBand` — DAWN/DAY/DUSK/NIGHT, `NONE` before `WS_SUN_UNBOUND` |
| `weather.gd` | `Weather` — STORM only, `NONE` before `WS_TOWER_UNBOUND` |
| `bark_service.gd` | `BarkService` — the selector itself |
| `rumor_service.gd` | `RumorService` — news travelling; held by `BarkService` |
| `schedule_service.gd` | `ScheduleService` — anchor lookup; held by `BarkService` |
| `definitions/bark_definition.gd` | `BarkDefinition extends TarrockDefinition` |
| `definitions/bark_catalog.gd` | `BarkCatalog` |
| `definitions/reading_motif.gd` | `ReadingMotif extends TarrockDefinition` |
| `definitions/motif_catalog.gd` | `MotifCatalog` |
| `definitions/npc_profile.gd` | `NpcProfile extends TarrockDefinition` |
| `definitions/npc_catalog.gd` | `NpcCatalog` |
| `definitions/schedule_entry.gd` | `ScheduleEntry` — one time band, one anchor |
| `definitions/schedule_variant.gd` | `ScheduleVariant` — a kind of day (wedding, funeral, …) |
| `definitions/npc_rules.gd` | `NpcRules` — the one tuning table |

## Generated vs. hand-authored

| What | Where | How |
|---|---|---|
| The five starter motifs of §The Fool's Reading | `data/npc/motifs/*.tres` + `catalog.tres`, `systems/npc/motif_ids.gd` | **generated** by `tools/gen_definitions.py`, hand-mapped rule per row (`MOTIFS_BY_ROW`); drift-tested |
| The Cliff's four Querent idle barks | `data/npc/barks/*.tres` + `catalog.tres`, `localization/barks_cliff.csv` | **hand-authored**, lifted verbatim from `MQ00-the-leap.md` §BARKS — The Cliff |
| The nine recurring named NPCs | `data/npc/profiles/*.tres` + `catalog.tres`, `systems/npc/npc_ids.gd` | **hand-authored** from `characters.md` §Recurring named NPCs (prose bullets, not a table — see `NpcIds`'s class doc for why this is not generated) |
| The nine names themselves | `localization/npc_names.csv` | **hand-authored**, verbatim from the same bullets; each profile's `name_key` resolves through it and `npc_data_test.gd` checks all nine |
| The five schedule-variant kinds | `data/npc/npc_rules.tres`'s `schedule_variants` | **hand-authored** from §Daily life's third bullet (prose, two kinds sharing one flag — see `ScheduleVariant`'s class doc) |
| Every tuning number (recent-pick memory, rumour delays, time bands, pool-size targets) | `data/npc/npc_rules.tres` | **hand-authored placeholders** — `npc-system.md` calls every one of them TBD in its own text; see `NpcRules`'s class doc |

## Rules worth not re-deriving

- **No weighting, no randomness across layers.** The highest layer with an eligible,
  unspent line wins outright; a seeded RNG only breaks ties *within* one layer's
  eligible set, never decides between layers.
- **Layer 6 is not evaluable, not merely empty, before its unbindings.** Before
  `WS_SUN_UNBOUND` / `WS_TOWER_UNBOUND` the whole layer is skipped, whatever a caller's
  `BarkContext.time_band` / `.weather` say — those fields are advisory and ignored
  until then.
- **Repeats decay per pool key, and the memory is transient.** `BarkContext.pool_key()`
  is the granularity (a named NPC by id; ambient Minors sharing suit + rank + region;
  the Querent by region) and it is never saved — `npc-system.md` §Bark layers makes
  repeat decay a fact about the last few picks, not the playthrough.
- **Rumours are a layer-3 delta, not a layer.** `RumorService.has_reached(quest_id,
  region_id)` is one more `BarkDefinition` condition (`rumor_of_quest`); it holds no
  lines and picks nothing.
- **Schedules are a lookup, never a sim.** `ScheduleService` ticks nothing and moves
  nothing; it answers "which anchor, right now" from a profile, a time band, and
  whether the region is still bound.
- **`RegionGraph` / `RegionCatalog` / `QuestCatalog` are held, never `RegionService` /
  `QuestService`.** `RumorService`'s class doc: a service reference back to something
  the save also captures would close a `RefCounted` cycle nothing collects. Both
  services are held **weakly** where they must be reached at all (`QuestService`, for
  the `quest_completed` subscription — see `attach_quests()`).
- **`BarkPick`, the candidate buffer and the pool key are reused, never allocated per
  request.** `request()` runs whenever an NPC is about to speak — several times a second
  in a populated square. `BarkContext.pool_key()` is built once per context and rebuilt
  only when a field it is made of moves; a pool key that has spent nothing shares one
  read-only empty ring; and the Fool's Reading (which `WorldStateService.reading_order()`
  hands back as a *duplicate*) is read lazily, only by a request that actually weighs a
  layer-2 line naming a motif.

## The save's `npc` section

`BarkService.to_snapshot()` / `.restore_snapshot()` delegate straight to
`RumorService`: **only the rumour seeds** — `{quest_id, completed_at_seconds}` per
completed main quest — land in the file. Everything else derives from world state
already in the save (which barks are eligible) or is deliberately transient (recently
spent lines). See `systems/save/README.md` for the section's place in `apply()`'s
order and `tests/fixtures/saves/README.md` for the fixture.

## Owed to later rounds

- **Real bark content per region.** Today the only shipped pool is the Cliff's four
  Querent idle lines; `BarkCatalog.is_complete = false` says so structurally, and the
  layer-7-per-suit evergreen-floor check does not run against it. `data/npc/barks/`
  grows a region at a time as quest/region docs' BARKS sections are lifted, per
  `npc-system.md` §Consistency note.
- **Anchors that resolve to real markers.** `ScheduleEntry.anchor` and
  `NpcProfile.home_anchor` / `work_anchor` / `gathering_anchor` are marker NAMES; no
  region scene has authored one yet, and nothing here moves a body to one — that is
  whoever builds a populated region scene's round.
- **Every tuning number in `npc_rules.tres`.** `npc-system.md` calls the rumour delays
  and the pool-size targets tuning targets explicitly, not docs-phase decisions; a
  balance pass owns them once a region is greyboxed.
- **Suit, Court rank and anchors for six of the nine named NPCs.** Only Flick's suit
  and rank are canon outright ("a Page of Wands"); the Troupe's four and the three
  freed prisoners are marked TBD in their own profiles rather than guessed — see each
  `.tres`'s `notes`.
