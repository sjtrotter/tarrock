# World — SSOT

Owns: map layout, region descriptions, gating, traversal, the **world-state matrix**
(every permanent change and what fires it), and global state thresholds. Boss and Trump
detail lives in [`arcana.md`](arcana.md); story meaning lives in
[`narrative.md`](narrative.md).

## The Spread

The world is a single continent laid out like a dealt spread: 21 regions arranged in a
wheel around the **Axis**, with the **Cliff** hanging off the south-east rim — outside
the spread, where the undealt card waits. The map screen literally renders the world as
cards laid on a table; unbinding an Arcana turns that region's card face-up.

### Layout (adjacency)

```
                    N
        [Spire]  [Bastion]  [Assize]
   [Dim]                         [Noonlands]
[Gallowwood]    ┌─────────┐        [Prestige]
[Mirrormarsh]   │ LONGROAD │           [Bower]
   [Undervault] │ ⊙ AXIS  │       [Divide]
        [Mere]  └─────────┘   [Chantry]
     [Stillmarsh]  [Confluence]  [Maw]
                    S              [CLIFF]⇘
   (Wheelhouse and Veil sit ON the Longroad ring,
    NE and SW respectively; Hollows lies between
    the Longroad and the Axis.)
```

Reading the compass: **east is morning** (Sun, Magician, Empress — the journey's
beginnings), **west is evening** (Moon, Hermit, Hanged Man, Devil — the psyche and the
dark), **north is stone** (Emperor, Justice, Tower — law and its breaking), **south is
water** (Temperance, Star, Death — feeling and passage). The Fool enters from the
south-east: dawn-side, as it should be.

- **The Longroad** (Chariot) is a grand circular causeway around the Axis — the eternal
  procession marches it. Every region's main road eventually meets it, which makes it
  the game's traffic spine and the natural mid-game unlock (its Waystation network
  activates as fast travel after MQ07).
- **The Axis** is visible from everywhere — a still, silver eye of the world with a
  lone dancing figure at its center, too far to see clearly. Weather never touches it.
- **The Undervault** is underground, entered from the western regions; the only region
  with no sky.

## Hydrology rule (waterways must be physically possible)

Every waterway in the Spread obeys real gravity-fed logic, because players who look
closely deserve a world that survives the looking: rivers **begin** at credible sources
(the Maw's and Dim's high ground, the Spire's storm-fed heights), **flow downhill** along
the whole visible course, and **end** somewhere real (the southern sea via the
Confluence delta; lakes like the Mere with an inlet and either an outlet or a basin that
plausibly holds). No river may run level around a ring, fork uphill, or appear from
nowhere behind a hill. The Stall may *pause* water (the Confluence's eternal pour, the
Mere's held-breath stillness) — stasis is fiction — but the frozen shape must still be a
shape water could have had. Greybox passes check this rule the way they check
walkability; MQ14's delta drain must read as *correct plumbing finally finishing*.

## Intended difficulty bands (soft, never enforced)

- **Band 1 (entry):** Prestige, Bower, Divide, Chantry, Maw
- **Band 2 (developing):** Noonlands, Bastion, Assize, Longroad, Wheelhouse, Confluence,
  Gallowwood, Dim
- **Band 3 (committed):** Veil, Stillmarsh, Undervault, Spire, Mere, Mirrormarsh
- **Finale:** Hollows (gated), Axis (scaling)

Enemy stats do not scale to the player; bands are tuned fixed. A Band 3 region at hour
two should feel like Hyrule Castle at hour two: survivable by the brilliant.

## Hard and soft gates

Hard gates are few and diegetic:

| Gate | Requirement | Rationale |
|---|---|---|
| The Mirrormarsh (interior) | Any true light: Hermit's Lantern, Star's Wish, or the Sun unbound | The fog lies; without true light the region loops the player back out (the loop *is* the locked-door message). |
| The Hollows (MQ20) | Death unbound (MQ13) | Judgement cannot call souls that cannot leave. |
| The Axis inner sanctum | None — always open | BotW rule: the finale is a right, not a reward. It scales instead (see `arcana.md` §XXI). |
| The Confluence delta caves | Temperance unbound | Physically underwater until the rivers drain. |

Everything else is soft-gated by difficulty band, geography (climbable but punishing
ridges), and traversal Trumps (Chariot mount for distance, Hanged Man feather-fall for
descents, Overturn gravity-flip for specific puzzle spaces).

## Regions

One paragraph each — enough to brief a quest writer or a greybox. Full sensory /
art detail belongs to [`art-audio.md`](art-audio.md) and the quest docs.

- **The Cliff (0):** A high meadow plateau at the world's broken edge, scattered with
  the campsites of Fools long gone. Tutorial space: sealed from the Spread by sheer
  drop; exit is the leap of faith. Contains the first Waystation and the game's thesis
  in miniature — one tree here is the only thing on the plateau that visibly *dies*.
- **The Prestige (I):** A carnival that has been mid-performance for 300 years. Tents
  like cathedral naves, an audience that cannot leave its seats, popcorn older than
  nations. Warm, gaslit, uncanny. Intended first region.
- **The Veil (II):** A cloister-library in perpetual moonlit mist between two colossal
  pillars. Silent order of archivist nuns; the world's secrets shelved and sealed.
  Stealth- and riddle-flavored.
- **The Bower (III):** A garden gone glorious and wrong — orchards so heavy the boughs
  weep, wheat to the horizon that may never be cut. Overripe abundance as horror-lite.
- **The Bastion (IV):** A granite city of perfect grids where the law has not amended
  in three centuries. Citizens live to the minute; the schedule is sacred. Vertical,
  monumental, grey with precise gold.
- **The Chantry (V):** A cathedral-town where the bells have rung the same hour, the
  same hymn, since the Stall. Doctrine as weather. Choir acoustics everywhere.
- **The Divide (VI):** A canyon splitting the southern east — two towns glaring across
  it, joined by an unfinished bridge and an unsealed engagement. Every ferryman is a
  gossip. Romantic, ridiculous, quietly sad.
- **The Longroad (VII):** The great ring-causeway; a triumphal procession has circled
  it since the Stall — banners bleached, trumpets dented, glory long since curdled into
  momentum. Includes roadside inns, toll-forts, and the Waystation network.
- **The Maw (VIII):** Savage limestone highlands of beasts and hunters, centered on the
  frozen tableau of a woman holding a lion's jaws. The wilds-region: monster hunts,
  taming, vertical crags.
- **The Dim (IX):** A mountain of permanent dusk; one lantern-light moves on its far
  slopes and has never been caught. Lost travelers, hermit shacks, star-blind valleys.
- **The Wheelhouse (X):** A casino-city built on a titanic stopped wheel. The lucky
  half lives in absurd fortune, the cursed half in absurd calamity, street by street —
  and no one may move house. Economy hub; the game's densest side-quest den.
- **The Assize (XI):** Fog-grey court complexes where every trial stands adjourned;
  the accused of three centuries wait in patient queues, knitting. Kafka by way of
  Ealing comedy.
- **The Gallowwood (XII):** A forest where gravity forgot which way it was going —
  canopy paths, inverted glades, a serene figure hanging from the World-Tree's bough,
  perfectly content. Traversal playground.
- **The Stillmarsh (XIII):** Where the dying have gathered since the Stall, waiting.
  Candle-flat wetlands, ferry lanterns, the world's kindest and wariest people. Nothing
  here can end — and everyone knows exactly what the Fool's arrival means. (Keystone
  region; see narrative.md.)
- **The Confluence (XIV):** A delta city where two rivers pour eternally between two
  colossal cups and nothing may ever be finished — bridges half-built for 300 years,
  perfect tea eternally steeping. Alchemists, mixers, diplomats.
- **The Undervault (XV):** A gilded underground pit-city where every resident signed
  for their chains — comfort, appetite, debt — and will tell you they're very happy,
  thanks. Opulent, claustrophobic, the game's darkest comedy.
- **The Spire (XVI):** A lightning-struck tower frozen mid-collapse: rubble hangs in
  the air, staircases end in sky. Vertical dungeon-region climbed through suspended
  debris. The Stall's violence made visible.
- **The Mere (XVII):** Night-locked lakeland under one impossible star. Wish-wells,
  pilgrim jetties, water like held breath. The game's quiet, beautiful sanctuary
  region.
- **The Mirrormarsh (XVIII):** Fog wetlands where paths, lights, and faces lie. Its
  "monsters" are lost people wearing the fog's masks. Hard-gated on true light.
- **The Noonlands (XIX):** Golden grain country under a sun fixed at noon for 300
  years. Joyful on the surface — endless harvest festivals — with drought and sunstroke
  creeping in at the edges. The flagship world-change region.
- **The Hollows (XX):** Terraced graveyards ringing the Axis approach, tended and
  waiting. Gated behind Death. After MQ13 it fills with the newly-able-to-die and the
  long-overdue; after MQ20 it empties, blooming.
- **The Axis (XXI):** The still center. A wreath-shaped amphitheater of white stone; a
  single figure dancing, and has been, for three hundred years. Always open. The end.

## World-state matrix

SSOT for permanent changes. Quests may **require** and **fire** these states; nothing
else may mutate them. (Technical representation: see
[`technical.md`](technical.md) — one flag enum per row, saved-game versioned.)

| State ID | Fired by | Effect (mechanical / visible) |
|---|---|---|
| `WS_MAGICIAN_UNBOUND` | MQ01 | Prestige show ends; carnival packs up over in-game days; eastern roads reopen; **troupe branch** per MQ01 choice (`WS_TROUPE_TRAVELING` or `WS_TROUPE_SETTLED`). |
| `WS_PRIESTESS_UNBOUND` | MQ02 | The Veil's mist lifts world-wide: hidden doors become visible to all players (not just Trump users); NPCs begin dreaming (new bark pool everywhere). |
| `WS_EMPRESS_UNBOUND` | MQ03 | Harvests complete across the Spread; food prices halve; Bower stranglevines recede opening its interior; famine sidequests resolve. |
| `WS_EMPEROR_UNBOUND` | MQ04 | Bastion gates open; curfew barks replaced; **petty crime returns** (new ambient crime events world-wide — freedom has texture). |
| `WS_HIEROPHANT_UNBOUND` | MQ05 | The bells fall silent, then ring *new* songs; weddings/festivals resume as ambient events in every settled region. |
| `WS_LOVERS_UNBOUND` | MQ06 | The Divide is bridged; towns unite per MQ06 choice (`WS_DIVIDE_EASTMARRIED` / `WS_DIVIDE_WESTMARRIED`); ferry replaced by bridge traffic. |
| `WS_CHARIOT_UNBOUND` | MQ07 | Procession ends; **Waystation fast travel activates**; Chariot mount granted; Longroad becomes safe trade route (merchant caravans spawn). |
| `WS_STRENGTH_UNBOUND` | MQ08 | Wild beasts world-wide become neutral-until-provoked; the lion becomes a roaming friendly landmark; Maw hunts change from cull to rescue. |
| `WS_HERMIT_UNBOUND` | MQ09 | Stars return over the Dim; lost-traveler NPCs come down from the hills (sidequest chain unlocks in four regions). |
| `WS_FORTUNE_UNBOUND` | MQ10 | The Wheel turns again: Wheelhouse luck districts begin cycling on a schedule (dynamic region); world-wide drop rates gain small periodic "fortune weather." |
| `WS_JUSTICE_UNBOUND` | MQ11 | Verdicts land; Assize queues disperse; prisons empty (**including three genuinely bad actors** — each seeds a later side quest); NPC dispute events unlock (Verdict Past-slot hooks). |
| `WS_HANGEDMAN_UNBOUND` | MQ12 | Gallowwood rights itself (traversal reshuffles); world-wide, penitent/anxious NPC barks soften — his peace spreads. |
| `WS_DEATH_UNBOUND` | MQ13 | **Mortality returns.** Seasons begin cycling; NPCs can die (scripted only — no systemic aging sim); Stillmarsh empties over days; funerals appear as ambient events; Hollows unlock. Post-confession dialogue variants activate world-wide (narrative.md Act II). |
| `WS_TEMPERANCE_UNBOUND` | MQ14 | Rivers flow to sea; Confluence delta drains exposing new explorable land (map physically changes); elixir crafting unlocks at mixers. |
| `WS_DEVIL_UNBOUND` | MQ15 | Chains fall in the Undervault; freed folk return to families across the Spread — **and some walk back down** (per-NPC, permanent, unresolved on purpose). |
| `WS_TOWER_UNBOUND` | MQ16 | **The Spire finally falls** — skyline change visible from everywhere; debris opens cave routes; thunderstorms join the weather rotation. |
| `WS_STAR_UNBOUND` | MQ17 | Stars return to the whole night sky (requires night: fully visible only with `WS_SUN_UNBOUND`); wish-wells activate world-wide (coin → timed blessing). |
| `WS_MOON_UNBOUND` | MQ18 | Mirrormarsh fog lifts; its "monsters" revealed as lost people — a town un-curses; illusion-type enemies lose ambush bonuses world-wide. |
| `WS_SUN_UNBOUND` | MQ19 | **The first sunset in 300 years** (set-piece); global day/night cycle begins; nocturnal content unlocks everywhere; Noonlands cool, drought sidequests resolve. |
| `WS_JUDGEMENT_UNBOUND` | MQ20 | Ghost NPCs across the Spread say goodbyes (closes every "waiting" sidequest); Hollows bloom; ancestor shrines give final gifts. |
| `WS_WORLD_UNBOUND` | MQ21 | The Shuffle. See narrative.md §Endings. |

**Interaction rules:**

- States are permanent within a save. No unbinding is reversible.
- When two states both modify an ambient system (weather, barks, events), effects
  stack additively; quest docs must list which states they assume in
  `Consistency references`.
- Night-dependent content (`WS_STAR_UNBOUND` sky, nocturnal spawns) checks
  `WS_SUN_UNBOUND` at runtime — writers must handle both orders. **Order-independence
  is the rule for all pairs** except the two hard story gates (Death→Judgement,
  everything→World's scaling).

## Global states (act thresholds)

| State | Condition | Effect |
|---|---|---|
| `ACT_I` | 0–6 Arcana unbound | Baseline barks/quests |
| `ACT_II` | 7–14 unbound | Uneasy bark pools; Querent steers toward Stillmarsh if MQ13 undone by 14 |
| `ACT_III` | 15–21 unbound | "Last days" content: festivals, farewells, troupe's final show |
| `CONFESSED` | MQ13 complete | Post-confession dialogue variants everywhere (independent of act) |
| `READING_ORDER` | Always tracked | The ordered sequence of unbindings — **the Fool's Reading** (an ordered list in the save, not a flag). Displayed in the Almanack; read aloud in MQ21's True Shuffle; queryable by barks and quest variants. |

## The Fool's Reading (sequence reactivity)

The order of unbindings is itself content (`narrative.md` §The Fool's Reading owns the
meaning; this section owns the world's mechanical reactions). Two mechanisms, both
cheap by construction:

1. **Pair variants** — the existing `[If WS_…]` order-independence variants in quest
   docs (e.g., Star-then-Sun vs. Sun-then-Star skies) *are* sequence reactivity; write
   them as living in the Reading, not as edge-case handling.
2. **Sequence barks** — ambient bark pools may query `READING_ORDER` for notable
   motifs. Canonical starter motifs (quests and the NPC system may add more, locally):

| Motif | Example bark flavor |
|---|---|
| Sun unbound before Star | "First true night we ever had, and not one star in it. Got them later, mind." |
| Star unbound before Sun | "When the sun finally set, the stars were already waiting. Like they knew." |
| Death unbound in Act I (first 7) | The world learns what the Fool is *early*; wonder-tinged dread colors Act II barks everywhere. |
| Death unbound last of the 20 | The Stillmarsh watched every other region wake first; Old Sallow has opinions. |
| Magician not first | Flick, later: "You went and did all *that* before you ever saw a show? Backwards sort of Fool." |
