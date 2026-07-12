# NPC System — SSOT

Owns: the system that makes the ambient population feel lively, dialogue-rich, and
aware — bark layering, named-NPC memory, rumor propagation, and daily-life scheduling.
`characters.md` owns *who* NPCs are (the Fool, Pip, the Arcana, suit-cultures, Courts,
recurring named NPCs); this document owns *how* the population behaves and talks around
them. World-state facts, the world-state matrix, `READING_ORDER`, and act thresholds are
owned by [`world.md`](world.md); act tone and the Fool's Reading's meaning by
[`narrative.md`](narrative.md); Renown's tiers and deed-reactions by
[`progression.md`](progression.md); the bound/unbound art-direction rule and the VO plan
(barks as text + cardspeak murmur) by [`art-audio.md`](art-audio.md); runtime data shapes
by [`technical.md`](technical.md).

## The pillar

**NPCs are aware.** A director-level pillar: wherever possible, an NPC line should
reflect the current state of the world — what has been unbound, in what order, what the
player chose, who the player is to this suit. A canned line that ignores a transformed
world (a Bower farmer still lamenting a famine `WS_EMPRESS_UNBOUND` already ended, a
Bastion guard still enforcing a curfew that lifted three unbindings ago) is a **bug**,
not flavor — treat it exactly as a broken quest trigger would be treated.

This doc exists to make that pillar affordable: a layered bark system that lets writers
aim specificity at the moments that earn it, and fall back gracefully everywhere else,
rather than hand-authoring bespoke lines for every NPC × world-state combination.

## Bark layers

A bark request (an NPC about to greet, comment, or idle-chatter near the Fool) is
resolved against seven pools, evaluated **most-specific-first**. The highest layer that
still has an unspent line for this NPC/context wins; if it's exhausted, evaluation falls
through to the next layer down. This is the entire selection algorithm — no weighting,
no randomness across layers, so writers can always predict which layer a given moment
will draw from.

| Layer | Pool | Queries | Owned/authored by |
|---|---|---|---|
| 1 (most specific) | **Quest-scripted lines** | Active quest state, dialogue graph node | The owning quest doc |
| 2 | **Sequence barks** | `READING_ORDER` (the Fool's Reading) for notable motifs | Region/quest docs, seeded with `world.md` §The Fool's Reading's starter motifs |
| 3 | **World-state barks** | `WS_*` flag combinations local to the region | Each region's quest/side-quest docs, keyed to `world.md`'s world-state matrix rows |
| 4 | **Act-state pools** | `ACT_I` / `ACT_II` / `ACT_III`, `CONFESSED` | Region docs, per `narrative.md` §Act structure |
| 5 | **Renown / suit-culture greetings** | Renown tier for the Fool's standing suit, suit-culture speech habits | `progression.md` §Renown tiers, `characters.md` suit-culture table |
| 6 | **Time/weather ambient** | Day/night, storms | Region docs — pool only exists where `WS_SUN_UNBOUND` (day/night) or `WS_TOWER_UNBOUND` (storm rotation) has fired |
| 7 (fallback) | **Generic suit-culture baseline** | Suit only | Authored once per suit, always available |

Notes on the ordering:

- Layers 1–4 are all forms of "does this line know something specific just happened or
  is specifically true right now"; layers 5–7 are forms of "who is this NPC, in
  general." The pillar is enforced by putting world-awareness *above* identity in
  priority — a world-state bark should interrupt a generic greeting, never the reverse.
- Layer 6 is **not evaluable at all** until its prerequisite unbinding fires — before
  `WS_SUN_UNBOUND`, there is no day/night, so there is nothing for a time-of-day pool to
  query; before `WS_TOWER_UNBOUND`, no storm rotation exists. Region docs omit layer 6
  entirely until then rather than authoring dead pools.
- **Repeats decay.** Each pool tracks recently-spent lines per NPC (or per ambient
  context, for Minors sharing a pool — see below) and excludes them from the next few
  picks. An NPC should not say the same "aware" line twice in a row; a deep-enough pool
  (see Dialogue volume, below) makes this cheap rather than requiring bespoke
  no-repeat logic per line.
- A pool with zero unspent, non-decayed lines falls through immediately — there is no
  stall or default silence line; the next layer down always has content, because layer 7
  is mandatory and evergreen.

## Named vs. ambient NPCs

| | Named NPCs | Ambient Minors |
|---|---|---|
| Who | `characters.md` recurring cast + quest-promoted NPCs (an ambient Minor a quest gives a name and arc to) | The rest of the population |
| Memory | Persistent, per-NPC: a small flag set recording notable dealings with the Fool (helped/wronged them, quest outcomes that touched them, whether they've met the Fool at all) | None per-individual; share suit/region pools |
| Dialogue | Full interactive choice-dialogue, quest template format (`quests/TEMPLATE.md`'s Choice Dialog blocks) | Bark-only — no dialogue trees |
| Identity read | By name and characterization | By **visible suit + Court rank** (dress, insignia, bearing per `characters.md`'s suit-culture and Courts tables) — the crowd reads as a structured society, not palette-swapped extras, even with no name attached |

A named NPC's memory flags feed layer 1–2 barks the same way quest state does: "you're
the one who [did the thing]" is a layer-1-adjacent line gated on the NPC's own flag set,
not on global world-state. This is the one place the bark system reads state narrower
than the world-state matrix — scoped deliberately, since it's per-NPC save data, not a
`WS_*` flag (see `technical.md` §Save system).

## "The world talks about you": rumor propagation

Deeds don't announce themselves only where they happened. Completing a main quest seeds
a rumor bark pool that spreads outward on a delay, so news reads as *traveling* rather
than teleporting:

1. **Adjacent regions first** — per `world.md` §Layout's adjacency, the regions bordering
   the quest's home region gain rumor barks after a short in-game-time delay (hours, not
   seconds — long enough that a player who fast-travels immediately still beats the
   news).
2. **World-wide after a longer delay** — every region's generic rumor layer picks up a
   version of the same event once enough in-game time has passed, phrased through that
   region's own suit-culture voice (a Coins town hears it as a transaction footnote; a
   Cups town hears it as an emotional retelling).
3. Rumor lines slot into **layer 3** (they are a `WS_*`-fired pool like any other) —
   they are not a separate layer, just a delayed-activation delta on the same mechanism.

## Daily life: light schedules, not a sim

NPCs run **anchor-point schedules**, not a full behavioral simulation. Explicitly not a
Radiant-AI-style sim, and deliberately so: a full sim generates emergent noise that
*fights* authored awareness — an NPC wandering somewhere unscripted can't be standing
where their aware line lands. Light schedules keep every moment intentional, which is
what the pillar actually needs:

- Every scheduled NPC has a small set of anchor points — **home**, **work**, **a
  gathering place** (market, tavern, chapel, whatever fits the region) — and moves
  between them on a simple time-of-day loop once `WS_SUN_UNBOUND` gives the world a
  day/night cycle to schedule against.
- **Bound regions are deliberately static.** Per `art-audio.md`'s bound/unbound rule
  (posed mid-flutter, audibly-looping ambience), bound-region NPCs hold tableau-still
  routines — the same few anchor visits on a short, unvarying loop. Stasis **is** the
  fiction; a bound region whose NPCs bustle naturally would contradict the region's own
  art direction.
- **Unbound regions gain schedule variety**, keyed to the world-state matrix: festivals
  (`WS_HIEROPHANT_UNBOUND` weddings, Act III "last days" content per `narrative.md`),
  funerals (`WS_DEATH_UNBOUND` onward), markets and caravans (`WS_CHARIOT_UNBOUND` trade
  traffic), petty-crime events (`WS_EMPEROR_UNBOUND`). Each is an anchor-schedule
  variant plus its bark pool delta, not a new simulation layer.
- Schedules are content data (see `technical.md`'s `NPCProfile`), authored per region
  alongside that region's bark pools — this doc fixes the *shape* (anchors + time bands),
  not the per-region content.

## Dialogue volume and pool-size targets

Every **named** NPC gets full interactive choice-dialogue per the quest script template
(`quests/TEMPLATE.md`). Every **ambient** NPC is bark-only, but the pools must run deep:
the target is that a player standing in a town square for five minutes hears no exact
repeat. Proposed pool sizes below are **tuning targets**, not locked numbers — set for
real once a region is greyboxed and its NPC density is known.

| Layer | Target unique lines (per region, per suit present) | Tuning note |
|---|---|---|
| 1. Quest-scripted | As needed by the quest | Owned entirely by quest docs; not sized here |
| 2. Sequence (READING_ORDER) | 3–6 motif lines per region | Most regions won't hit every motif; a handful covers the likely ones |
| 3. World-state deltas | 4–8 lines per relevant `WS_*` flag | Scales with how many flags plausibly touch that region |
| 4. Act-state | 6–10 lines per act (×4 for `ACT_I/II/III` + `CONFESSED`) | The steady backbone of variety — largest deliberate investment |
| 5. Renown/suit greeting | 3–5 lines per Renown tier (×5 tiers) | Per suit present in the region |
| 6. Time/weather | 4–6 lines per time band / weather state | Only once its prerequisite unbinding fires |
| 7. Generic suit baseline | 10+ lines, authored once per suit, reused everywhere | The evergreen floor; never region-specific |

At a rough town-square encounter rate, layers 3–5 alone comfortably clear a five-minute
no-repeat target once a region has two or three unbound world-states active; layer 4's
volume is what carries early-game regions before much world-state has fired.

## Aware-of-Pip

Per `characters.md` §Pip: the Stillmarsh's NPCs bow to Pip on sight, instinctively and
without explanation — this is canon and scripted, not a bark. Elsewhere, ambient pools
may carry occasional Pip-directed lines (a Court NPC greeting the dog before the Fool, a
child NPC begging to pet him) as texture, scattered lightly rather than universally —
Pip is a recurring wonder, not a second protagonist NPCs address by default. NPCs may
speak to or about Pip in any bark layer; **Pip never answers**, in dialogue or bark —
that silence is the character rule (`characters.md` §Pip) and the bark system must never
manufacture a line that breaks it.

## Reactivity guardrail: awareness never lectures

An "aware" line is never exposition and never a status readout. It references what's
changed **sideways, in-character** — the way a person actually talks about their own
transformed world, not the way a patch-notes summary would. See `world.md` §The Fool's
Reading for the register ("first true night we ever had, and not one star in it. Got
them later, mind." — not "Sun unbound before Star detected"). Per `narrative.md`'s tone
bar: dry, warm, storybook-British, never the game winking through an NPC's mouth. A bark
that could be mistaken for a tooltip has failed, regardless of how "aware" it is.

## Consistency note

This document owns the **system**: the seven layers, their evaluation order, the
named/ambient split, rumor propagation, and schedule shape. It owns **no line of
dialogue and no specific pool**. Bark content is authored per-region in each region's
quest and side-quest docs (as bark-set sections, per `quests/TEMPLATE.md`), and,
eventually, in a dedicated `barks/` content folder once volume outgrows quest docs.
Writers adding a bark pool cite this doc's layer number and the `world.md` /
`narrative.md` / `progression.md` facts the pool depends on, the same way quests cite
`Consistency references`.

## Open questions (TBD)

- Exact in-game-time delay windows for rumor propagation (adjacent-region vs.
  world-wide) — a pacing number to tune once a real playthrough timeline exists, not a
  docs-phase decision.
- Whether named-NPC memory flags ever surface in the Almanack directly (a "people you've
  met" page) or stay purely internal to dialogue/bark gating — an UI-scope question for
  `art-audio.md`, not this doc.
- Final per-region pool-size numbers (table above) — tuning targets only until regions
  are greyboxed.
