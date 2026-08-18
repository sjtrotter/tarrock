# Tarrock in 2D — final synthesized report

**Status:** synthesis / proposal — NOT canon. Adoption requires the GDD amendment PR in §9.
**Provenance:** reconciles two independently written reports — `docs/codex-2d.md`
(Codex, creative/experiential) and `docs/claude-2d.md` (Claude, canon audit) — each
produced without reading the other. On adoption (or rejection) of a direction, this file
supersedes both; neither source report should be cited as canon.
**Date:** 2026-08-10

---

## 1. The verdict, and why it can be trusted

Both reports, working blind to each other from the same canon, reached the same
conclusion:

> **Tarrock can ship its v1 as a complete 2D game — all 22 regions, all 21 Arcana, all
> three endings — in the oblique top-down family, with regions shrunk to 2D scale, and
> be a definitive telling rather than a lesser one.**

Independent convergence is the strongest evidence this process can produce. The
agreement extends well past the headline; both reports independently concluded:

- The game's identity — the stalled Reading, the twist, the 21 people inside offices,
  the Fool's Reading, the bound→unbound transformations — does not depend on a camera.
  Claude's audit quantifies it: **zero of 21 boss mechanics and zero of 20 Trumps are
  intrinsically 3D**; only five items in the whole canon genuinely need 3D space, none
  of them combat (§6).
- **The top-down family wins as the primary form.** Route freedom, inhabited
  settlements, region revisiting, crowd/society legibility, and the map-as-dealt-spread
  all live there; a side-scrolling platformer emphasizes forward momentum and staged
  linearity, which fights the open Reading (and, per Claude's audit, drifts toward
  Metroidvania ability-gating against the "courage, never walls" rule).
- **Side-view belongs as punctuation, not grammar** — a small list of canon-designated
  set-pieces where the viewpoint changes for a dramatic reason (§4).
- **The complete game, not an Act-I slice.** The GDD's own scope valve ("reduce region
  size, never boss count or quality — the 21 Arcana are the product") is exactly the
  shape of a 2D release. An unlabeled five-region v1 teaches players the game is a
  charming tarot boss hunt and withholds the idea that makes it exceptional.
- **2D is not cheaper 3D.** The work moves into illustration, animation, composition,
  writing, and the changed-state version of every important place — Tarrock's strongest
  areas, but not free. Choose 2D because it is a compelling form, not because
  completeness becomes automatic.
- Playtime compresses to roughly **12–20 hours**; the GDD's 20–30h figure is a target,
  not a pillar.

## 2. What each report contributes to this synthesis

**Adopted from Codex** (the creative frame):

- **The living tarot book.** The visual premise: *the player walks through the
  illustrated deck in which the Reading is taking place.* Card borders, painted margins,
  suit patterns, flattened storybook space, framed tableaux — the form born from the
  premise, with the fiction staying real (no paper-cutout winking).
- **Telling and retelling**, not prototype and replacement (§8). This resolves Claude's
  "v1 defines the identity / the 3D game reads as a remake" risk cleanly: the 2D game is
  the first complete telling; a later 3D Tarrock is an expanded retelling players return
  to for reinterpretation, not graphics. The 2D world must be fully real on its own
  terms — never end it with a teaser implying it was a sketch of the "real" Spread.
- **The region completeness checklist** (§5) — the correct measure of "smaller regions,
  not abbreviated ideas."
- **The reduce / do-not-reduce lists** (§5, merged with Claude's system notes).
- **The honest fallback**: if a smaller release is ever forced, it ships as a *named
  prologue* ("a first deal") ending on a question — never as plain "Tarrock v1."
- **The proof slice** and its five experiential questions (§10).
- **Isometric as composition, not grid.** Codex's warning is right: a rigid isometric
  contract can make exploration feel like navigating exhibits and shrink characters into
  emotional distance. This refines Claude's "isometric base" into §3's final form.

**Adopted from Claude** (the audit and the engineering of the claim):

- The quantified perspective audit and the **five genuine 3D dependencies with their 2D
  substitutions** (§6) — the concrete backing for "the identity survives."
- **The Overturn constraint** — the one hard projection fact in the canon, which the
  Codex report does not address at all (§4). Any adopted direction must carry this
  answer, or the Hanged Man's declared "traversal headline" silently breaks.
- The **combat translation notes**: Focus → lock-strafe, heavy sweep → radial arc,
  launcher/aerial → knockback-juggle redesign, climb-lite's open TBD *resolved* by 2D
  (it dissolves into level design), Sun's shadow-read as the most projection-sensitive
  fight (top-down native), Anti-Fool as a costume-system requirement (mirrored sprite +
  current Pocket Spread).
- The **shared data layer**: technical.md already mandates data-driven definitions,
  quest state machines, the WorldState service, and the save model. These are engine
  systems the 2D and 3D games share outright — the 2D v1 is a full-scale integration
  test of the design, not a detour.
- The **strategic case**: 2D unblocks the actual bottleneck (per-Arcana character art
  and animation, named by the GDD as "the big cost," currently CC0 stand-ins); the
  shape-language table and model sheets drive 2D character art directly; a top-down 2D
  game is the friendliest shape for the GDD's nothing-may-preclude-mobile clause.
- The **SSOT findings and amendment list** (§9), including the pre-existing GDD
  "both endings" error.

## 3. The form (reconciled)

**An oblique top-down storybook adventure in the ALttP tradition — one dependable
primary language — enriched by isometric composition where a card's meaning calls for
it, with side-view sequences as punctuation.**

- **Primary grammar:** low oblique top-down. Not clinically overhead: painterly depth,
  tall silhouettes, foreground framing, occasional scale shifts — "an illuminated
  storybook page the Fool can walk through," not a tile map.
- **Elevation stays readable.** Claude's requirement survives the reconciliation:
  terraces, ledges, and drops must read on the ground plane (the *Tunic* / *Death's
  Door* solution), because the terrain grammar ("elevation signposts the path") and
  Overturn's feather-fall reinterpretation depend on it.
- **Isometric staging as flavor, per region:** the Bastion's severe grids, the
  Wheelhouse's concentric luck, the Confluence's unfinished spans, the Spire's suspended
  debris, the white wreath of the Axis. Composition serves each card; no rigid
  world-wide angle contract.
- **Suit-culture and card iconography carry into the interface**: the Pocket Spread
  rendered as a literal small reading, Trump effects drawn in their home region's
  visual motifs, the map as the dealt spread that gathers into the Fool's Reading — the
  player's biography visible at a glance.

## 4. Side-view punctuation, and the Overturn answer

Merged set-piece list — each is canon's own designated drama, and the viewpoint change
is the reward:

1. **MQ00 — the leap from the Cliff** (the game's opening image).
2. **MQ01 — the Magician's proscenium**, including the canon mid-fight flip to the
   under-stage ("as above, so below" — a literal vertical cross-section).
3. **MQ04 — the Emperor colossus climb** (limb targets as a side-view ascent).
4. **MQ07 — the Chariot's carriage roofs** (profile chase, 2D-native).
5. **MQ12 — the inverted Gallowwood** (ceiling-walks and the "camera honestly
   inverted" beat, solved for free by a screen flip).
6. **MQ16 — the Spire ascent and the ride down** (vertical scroller, then the fall).
7. *Framing moment, not a sequence:* the Fool's silhouette against the first sunset
   (MQ19's set-piece wants a horizon; give it one).
8. *Optional:* the Undervault's descent framed as a cross-section reveal on entry.

**Overturn (Trump XII), the one hard constraint:** gravity-axis mechanics are semantically
void in pure top-down. The reconciled answer:

- **Upright feather-fall** in the base game = no fall damage anywhere, ledge-float, and
  drift-crossing of marked gaps (elevation-readable oblique makes this legible).
- **Full literal strength inside side-view sequences** (Gallowwood is where the card
  lives; the gravity bubble is native there).
- **The gravity bubble outside side-view spaces remains this proposal's one honest
  redesign TBD** — resolve it in the combat.md amendment, not silently in code.

## 5. Release shape: complete, compact, dense

**Ship the complete Tarrock.** Every region passes Codex's completeness checklist rather
than an acreage test:

> one unforgettable establishing image · one ordinary community under the card's stasis
> · one central predicament · one person who wants change · one person who will mourn it
> · one distinctive journey or encounter · one changed version worth returning to.

**Reduce:** region acreage; repeated road combat; incidental interiors; traversal for
its own sake; exhaustive order-reaction coverage (keep the canonical sequence motifs —
Sun-before-Star, Death-in-Act-I, etc. — not a combinatorial matrix); side-quest count at
first release (the 68 outlines are a menu, not an obligation — but every region keeps
its mourner story, per the do-not-reduce list); Callings ship as the 5–6-loop subset
callings.md already anticipates; minor NPCs who carry no before/after story.

**Do not reduce:** the 21 Arcana's number or individuality; free choice of order;
unbinding-not-killing; the ordinary mourner of every liberation; visible, revisitable
world changes (treat the bound→unbound contrast as a principal visual reward — in 2D the
player *sees* the cut rows and the finished bridge on one screen); the tonal turn at
Death and the confession; Fool/Pip/Querent (Pip stays silent, never a hostage — the MQ18
exception stands alone); the three-position Pocket Spread with upright/reversed burdens;
the Reading read back in the true ending; all three endings; the warmth, wit, and
melancholy of the writing.

**Fallback, only if forced:** a *named* prologue — the Cliff, the Prestige, and four or
five early regions, ending when the player first understands that each liberation is
also an ending, closing on a question. Marketed as a first deal, never as Tarrock v1.
The weak option — five regions under the plain title — is rejected by both reports.

## 6. The five genuine 3D dependencies (and their substitutions)

The complete list of things in canon that intrinsically need 3D space — none are
mechanics, one is already deferred:

| Dependency | 2D substitution |
|---|---|
| The Axis visible from everywhere | Painted horizon/parallax presence in every region's backdrop; the map carries the continuity. Weaker as ambient pressure; workable. |
| The Spire's fall as a global skyline change | Two-state backdrops per region — a painting swap, already the shape of the bound/unbound art strategy. |
| The Cliff's late-game vantage | Already deferred, not current canon. Drop, or a full-page plate. |
| Scale reveals (Emperor colossus, Wheelhouse's titanic wheel, Confluence's cups) | Full-page illuminated-manuscript establishing plates at reveal moments — a 3D weakness turned 2D signature, and the Emperor's is a side-view sequence anyway. |
| The leap of faith | Side-view sequence #1; native and excellent there. |

Everything else tagged "3D" in the docs (Unity Terrain, rigs, unit scale, greybox
milestones, camera-distance benchmarks) is pipeline, not design.

## 7. What the 2D v1 buys

1. **Unblocks the bottleneck** — per-Arcana character art/animation moves to the medium
   where the project's illustration-first identity (RWS woodcut, Kells/Wolfwalkers on
   the art bible's own reference shelf) actually lives.
2. **Validates every load-bearing system with real players while change is cheap** —
   order-independence, the world-state matrix, bark layers, the Fool's Reading, the
   Anti-Fool mirror, the Pocket Spread economy — on the same data-driven definitions the
   3D game will use.
3. **The docs are already the content bible** — 22 main quests at script status, region
   color scripts, a Calling per region. The distance from docs to shippable game is far
   shorter through 2D.
4. **Mobile stays possible** without designing for it, per the GDD clause.

## 8. Relationship to the 3D game: telling and retelling

The 2D game is the first complete telling — an illuminated deck the player enters. A
later 3D Tarrock is the retelling that lets players bodily inhabit it: see the Axis from
distant roads, climb the Emperor, feel the long distances between lives. Character
identities, music, dialogue, motifs, and transformations developed for 2D remain part of
Tarrock's permanent language; the 3D version expands rather than replaces, and the 2D
ending is never retconned into a dream or a sketch.

## 9. Canon amendments required (one PR, on adoption)

1. **GDD**: genre statement ("third-person open-world" → the §3 form), scope/build-order
   language, and — independent of this proposal — fix M4's "both endings" to *all three*
   (narrative.md is the SSOT and owns three: True Shuffle / Early Shuffle / Refusal).
2. **combat.md rule 6** ("all combat is real-time third-person action") → real-time
   action in the primary 2D grammar; resolve the Overturn-bubble TBD and the
   launcher/aerial redesign here.
3. **arcana.md rule 7 / GDD Iteration clause** ("unique model, rig, and animation set")
   → reinterpret the spirit into 2D terms: unique design, silhouette, and animation set
   per Arcana. Bespoke quality stays non-negotiable; the medium changes.
4. **art-audio §Current build + art-bible production standards** → 2D production
   sections (the silhouette-first philosophy, fill-black test, shape-language table,
   materials/costume rules all transfer intact; only the benchmark procedures change).
5. Mark `codex-2d.md` and `claude-2d.md` as superseded by this file; the decision itself
   lives in the GDD, not in any report.

## 10. Proof before commitment

The existing Cliff-to-Prestige slice, rebuilt in the §3 form, answers six questions
before the full release is committed:

1. Does the leap from the Cliff feel like entering a dealt world?
2. Is the Prestige delightful, uncanny, and a little sad before the player acts?
3. Does Wicke feel like a person trapped in performance, not a boss waiting on a stage?
4. Does the first Trump feel like inheriting meaning, not acquiring an attack?
5. Is returning to the changed Prestige as rewarding as defeating the Magician?
6. Does one small side story — an ordinary person who preferred the endless show — land
   its mourning without resolving it?

If those six work, the direction has demonstrated Tarrock's whole rhythm in miniature.
This maps onto the existing M1/M2 milestone shape; the timebox question stays where the
GDD leaves it.

## 11. Decisions owed by the director

1. Adopt or reject the 2D-v1 direction.
2. If adopted: confirm the §3 form (oblique top-down, isometric composition as flavor,
   side-view punctuation per §4).
3. Approve the §9 amendment PR scope.
4. Name the thing: is the 2D release *Tarrock*, or does the eventual 3D retelling need
   the distinguishing subtitle? (Both reports agree the 2D game gets to be real; the
   naming is the one identity question neither can settle for you.)
