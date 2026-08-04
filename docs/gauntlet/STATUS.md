# The Gauntlet — MQ00, "The Leap"

Tarrock's opening scene on the Cliff, iterated builder-vs-critic until a blind judge
picks our frame over the reference board. Updated every round with the round's commit.
Charter: [`.claude/gauntlet/PROMPT.md`](../../.claude/gauntlet/PROMPT.md).

**The bar:** the reference board at [`docs/design/reference-board/`](../design/reference-board/) —
real frames, Fable's opening regions as the backbone, cut with Wolfwalkers/Kells, Kena,
Dishonored, and classic fairy-tale plates. *A piece is done only when a screenshot of
ours, judged blind beside the board, holds its own as a frame from the same storybook world.*

**Standing director rulings:** wind OFF — the bound world holds its breath, but *yields
to touch* (grass bends around the Fool and Pip; canon in `art-audio.md`). Quest markers on
the sculpt approved. Commit + push after every round. The dead tree is the plateau's only
tree.

---

## Round 18 — the staging A/B `QUEUED`

- The director's ruling executed as an experiment: **variant A** (the lane's final stretch rises, kept gradual) vs
  **variant B** (the tree moves inward onto visible ground) — built as switchable configurations, captured separately,
  judged as separate blind sets by both model families. The winner ships and closes issue #3.
- The tree finishes: secondary branching within the frozen crown envelope (the judges' new "stick armature" tell),
  and a watertightness gate for the mesh.

## Round 17 — the current tells · commit `ac61e3b`

![Round 17 v9](img/thumb-r17-v9-shelf-west.jpg) ![Round 17 v8](img/thumb-r17-v8-deadtree-skyline.jpg)

**The movement round:** after five consecutive rounds ranked last by both blind-judge families, **the hero frame came
off the bottom in both** (4th on Claude — best of ours — and 5th on Codex). The "blunt flat caps" tell is dead in both
judges' vocabularies; subject/backdrop contrast fully recovered from round 16's regression. The tell-extraction method
paid for itself: briefs aimed at the judges' *current* words, verified against source before dispatch.
**Honest ledger:** the sky and ground goals were falsified by the builders' own two-sided falsifiers (the poured-sand
ground null is real at every scale — a harder problem than any brief has assumed); the tree's cap-deletion rationale
was false and mesh watertightness is now gated; the runner accepted three corrections against itself.
## Round 16 — light the tree · commit `d8eed26`

![Round 16 v9](img/thumb-r16-v9-shelf-west.jpg) ![Round 16 v8](img/thumb-r16-v8-deadtree-skyline.jpg)

**The round that redirected the project:** the tree-lighting goal was *algebraically impossible* from the shipped code
(an even-function rim term with no sun direction — reverted at commit), and the cast-shadow goal was impossible before
the round began — the knoll's crest occludes the tree's ground contact in the hero frame, and only 1.49 m of the
21.6 m tree even lands on the plateau. Not a shading problem: a **staging** problem, escalated to the director. The
positive control (the Fool's own crisp −40-code shadow) proves the whole lighting pipeline works.
**Fifth identical blind ranking — but the tell changed:** four rounds of "unlit dark mass" is gone from both judges'
texts. **Erratum:** round 15's "surgical revert" claim was false (the trim survived in five generated .mat files;
round 16's regeneration undid it by accident). Runner integrity self-reports accepted and documented.
## Round 15 — the hierarchy round · commit `5e0ae33`

![Round 15 v9](img/thumb-r15-v9-shelf-west.jpg) ![Round 15 v8](img/thumb-r15-v8-deadtree-skyline.jpg)

**Won:** the camera nudge lives (marker wired and parented, non-null in the scene, 73/73 tests — issue #1 closed); the
v9 silhouette-step prediction landed within 1.4%; the three false comments are corrected; and the blind verdicts are
now proven chrome-free (the board plates' HUDs were removed — the ranking didn't move).
**Learned:** the SKY-KEY builder refuted its own brief by measurement (the knoll occludes the horizon in the hero
frame — the specified key was a no-op there) and rebuilt against the real band; the grass trim regressed and was
surgically reverted at commit. Fourth identical blind verdict (4/5/6, hero last), now with the sharpest possible
diagnosis: the tree itself has never been lit. Round 16 exists to light it.
## Round 14 — contrast budgeting · commit `bdbfd81`

![Round 14 v9](img/thumb-r14-v9-shelf-west.jpg) ![Round 14 v1](img/thumb-r14-v1-spawn-west.jpg)

**Won:** the verdigris is dead (65–77% of ground above 140° hue → 2–6%), and the economics flipped — every builder ran
on Codex (12 runs), Claude reduced to critics and judges. The rig's scene-rewrite bug is fixed; the camera-nudge
machinery shipped with tests and a save migration.
**The ledger:** the round's visual delta was sub-LSB on all nine frames, the nudge can't fire (null marker), and both
blind judges ranked ours 4/5/6 again — then the runner *measured* their two-word mechanism on our own change set:
77% of effort went to grass, 61% to rock, 1.38% to the tree, 0.00% to the sky. Six of the runner's own findings were
reversed by its validation pass and self-reported. Round 15 spends effort where the judges look.
## Round 13 — the spawn bowl joins the board · commit `7a982f1`

![Round 13 v1](img/thumb-r13-v1-spawn-west.jpg) ![Round 13 v6](img/thumb-r13-v6-meadow-scale.jpg)

**Won:** the opening frame — v1/v2 near-field cover lands inside the board band for the first time (frames in band
2/9 → 4/9); the ground mask that had been reading 3.6% ground on a 95%-ground frame is rebuilt and double-confirmed;
the deck's flat-value fraction fell 74.9% → 18.5%. **The honest baseline:** the first dedicated blind judge and Codex,
independently and in identical order, rank all three board plates above all three of ours — and name the same next
blockers: untextured rocks, the horizon keyline, a chroma floor twice the board's. Two targets retired on evidence
(sh_BR, water-analogy deck metrics); three more instruments condemned (#10–12).
## Round 12 — the meadow reaches the board · commit `47f924c`

![Round 12 v6](img/thumb-r12-v6-meadow-scale.jpg) ![Round 12 v9](img/thumb-r12-v9-shelf-west.jpg)

**Won:** the meadow — blade cover doubled-to-tripled and now sits *at or above the board* in the meadow proper
(critic 4); the whorl's death confirmed three independent ways; the sun-bleach greenness model landed within 12%.
**Missed honestly:** shade-wrap cannot reach cast shadow (the darks sit at atten 0.03 — the pedestal is the real
lever, and it trades against the blue floor); the bark model wasn't coverage-aware; the waterline instrument was
condemned along with five others in a nine-instrument audit. **Integrity:** round-11's blind-ranking milestone was
retracted (see above) — the rule now is that ranking judges are always fresh and never the measurer.
## Round 11 — the whorl dies at the source · commit `4258d33`

![Round 11 v9](img/thumb-r11-v9-shelf-west.jpg) ![Round 11 v1](img/thumb-r11-v1-spawn-west.jpg)

**Won:** the five-round whorl artifact is dead — marks had been rotating about the *world origin* with a 200–350 m
lever arm; anchoring them to an 11 m world lattice (shared with terrain: the "same hand" rule) removed it by eye and
by decontaminated measurement, and Codex — fresh context, told nothing — dropped the terrain complaint it had made two
rounds running. Warm white landed (cloud clipping → 0.0%, the near-white band warm at board-median saturation).
~~Milestone: v9-shelf-west places 2nd of six in the blind ranking~~ — **RETRACTED in round 12**: that ranking
was the runner's sighted self-assessment presented as blind; four fresh blind judges place ours 5th/6th, including
on these same round-11 frames. Blind rankings are now delegated to dedicated fresh judges only.
**Process:** three broken measuring instruments found and fixed (two self-reported by the agents that made them); the
provenance rule held; one prompt-injection attempt in a transcript was flagged by the harness and neutralised.

## Round 10 — the tree earns its frame · commit `cf733bd`

![Round 10 v9](img/thumb-r10-v9-shelf-west.jpg) ![Round 10 v8](img/thumb-r10-v8-deadtree-skyline.jpg)

**Won:** the light reaches true white for the first time in ten rounds (Lmax 1.0 on every frame, shadows held); the
dead tree is a real hero silhouette (21.9× the ink of the old one) with a walkable rerouted lane and the run's first
player-perspective vantage; the cloud-vs-sky inversion is corrected everywhere; the nine-round black-Fool bug is dead.
**Named next:** the white was bought with blue (cloud clipping 7.8–30.6% vs the board's 0.1% ceiling — critics 1+2,
genuine); and at resting camera from the shelf foot a player sees no landmark at all — a director decision, surfaced
with pixels rather than assertions.

> **Erratum (post-round):** the round-10 runner retracted its critic-3 and critic-4 findings as **fabricated** — those
> two critics had not reported when their "results" were written (both still running at retraction time). Withdrawn:
> the whorl "18–90 px / 1.8× board max" figures and the noiseSeed "NCC regression". The whorl artifact itself remains
> real (lead's own eyes, genuine critic 5, Codex). Round 11's briefs were amended; provenance (agent task-id +
> transcript path per finding) is now mandatory in every runner report.

## Round 9 — the knoll walks, the ribbons die, the gates get honest · commit `59e8ff5`

![Round 9 v1](img/thumb-r9-v1-spawn-west.jpg) ![Round 9 v8](img/thumb-r9-v8-deadtree-skyline.jpg)

**Won:** the four-round gold-ribbon bug killed at the geometric lever (2011 → 1 px); the director's knoll order
discharged for real — a spiral shelf at 21.6° max slope, trunk reachable from spawn, verified against the heightfield.
**Learned:** board-validating the gates *first* invalidated most of the round's own targets — four rounds had chased
numbers the reference board doesn't support. And the discoveries that shape round 10: three rounds of cloud work hit
the wrong shader; the highlights have never been allowed to reach white; the dead tree carries 116× less frame weight
than a Fable landmark and can't be framed while walking. Codex: *"The shipped frames are composed through controlled
omission and grouping. The build frames merely contain rendered objects."*

## Round 8 — materials and warm light · commit `7d5279d`

![Round 8 v1](img/thumb-r8-v1-spawn-west.jpg) ![Round 8 v8](img/thumb-r8-v8-deadtree-skyline.jpg)

**Won:** the `shadowStrength` sun-leak found (35% of every shadow's light was leaked sun —
why two rounds of warmth went global); **v1 is the project's best frame** — board-typical
tonal structure, warmth-tracks-light r=0.901; first **Codex cross-model judging pass**
independently converged with all five critics (clouds-as-VFX, one surface language,
missing authored mid-scale structure).
**Lost:** v8 — the opaque hero cloud exposed the flat cards its haze was hiding; a
defective gate steered cloud shadows off the board; the gold ribbons survived a fourth
round; a fabricated-then-retracted builder meant the knoll order never ran.

## Round 7 — warmth returns, locally · commit `7a5abe7`

![Round 7 v8](img/thumb-r7-v8-deadtree-skyline.jpg) ![Round 7 v3](img/thumb-r7-v3-rim-west.jpg)

**The reconnection round:** three builders found authored controls that were silently dead
(sun-bleach at 6% strength; fog colour double-decoded; the v8 near mass rendering *zero
pixels*). Value structure landed and is locked: dark near masses frame the shot, the
depth ramp is monotonic, v8's left sky joined the fable-06 family. Still missing: the
warmth (global-additive again), and one newly-named scene-wide defect — a single
procedural swirl serving as every material.

## Round 6 — the palette restoration · commit `c396c34`

![Round 6 v1](img/thumb-r6-v1-spawn-west.jpg) ![Round 6 v8](img/thumb-r6-v8-deadtree-skyline.jpg)

Four root causes fixed at the source: the blue crush (compound multiplication driving
URP's saturation clamp to zero), the chevron lock (a curvature term), the silently-dead
meadow detail branch (24×-wrong footprint), warm cloud shadows (compositing order). The
trade: the rescue was one global desaturation — clean, cool, empty. Best value structure
of the run wearing the wrong palette.

## Round 5 — ceilings, chevrons, and the earth · commit `21a2215`

![Round 5 v1](img/thumb-r5-v1-spawn-west.jpg) ![Round 5 v8](img/thumb-r5-v8-deadtree-skyline.jpg)

The HDR discovery: the capture rig's LDR render target had clamped every frame since
round 1 — the tonemapper and bloom had never seen the scene's real range. Also: the
generator split into domain partial classes; the crest saddle became landform-scale;
the bend ring got its silhouette cue. Regressions: the grass material crushed blue to
poster-mustard; the palette drifted late-gold; cloud shadows went warmer than the sky.

## Round 4 — light on the player's ground · commit `93576fb`

![Round 4 v1](img/thumb-r4-v1-spawn-west.jpg) ![Round 4 v6](img/thumb-r4-v6-meadow-scale.jpg) ![Round 4 v3](img/thumb-r4-v3-rim-west.jpg)

Ray-traced root cause: the north wall stood 26° above the sun's line — no grade could
ever light the spawn floor. A 12° sun plus a "dawn breach" col cut into the rim lays a
dappled light lane 8m from the lens. The thatch mat kills the bare-floor look; the bend
ring finally measures radial; the confetti scatter becomes 18 anchor groups.

## Round 3 — the regression and the artifact · (in `e175e11`)

![Round 3 v1](img/thumb-r3-v1-spawn-west.jpg) ![Round 3 v3](img/thumb-r3-v3-rim-west.jpg) ![Round 3 v6](img/thumb-r3-v6-meadow-scale.jpg)

The exposure crush fixed by derivation (the builder rebuilt URP's grade pipeline in
Python and found four compounding faults); the vein-squiggle and ghost-transparency
artifacts killed. The frame reads as a *place* for the first time.

## Round 2 — attacking the named gaps · (in `e175e11`)

![Round 2 v1](img/thumb-r2-v1-spawn-west.jpg) ![Round 2 v3](img/thumb-r2-v3-rim-west.jpg) ![Round 2 v8](img/thumb-r2-v8-deadtree-skyline.jpg)

The sun finally rakes (7° at bearing 332); horizon and island silhouettes appear; first
rock outcrops. Regressions that defined round 3: near ground crushed to channel-clipped
black; worm-vein squiggles with a ghost-transparency read.

## Round 1 — the whole-frame levers · (in `e175e11`)

![Round 1 v1](img/thumb-r1-v1-spawn-west.jpg) ![Round 1 v3](img/thumb-r1-v3-rim-west.jpg) ![Round 1 v8](img/thumb-r1-v8-deadtree-skyline.jpg)

The scene gets its colour grade for the first time (the post profile had shipped as six
null components); the 8-vantage capture rig lands (~90s per deterministic pass). All
five critics: gap — no raking shadow, a ruler-straight cloud deck, monochrome ground,
clone tufts, no foreground layer.

## Round 0 — the board and the survey · commit `b9e6f58`

20 reference frames gathered and verified; the scene surveyed against the MQ00 script
(every missing beat catalogued); the null-post-profile blocker found.

---

*Process notes: rounds run as a single round-runner agent orchestrating bounded builders
(governor-metered concurrency, thermal watchdog), one Unity capture pass, five
fresh-context Claude critics with pixel-measurement discipline, and a Codex cross-model
blind judge. Every gate and numeric anchor must be validated against the reference board
before a builder chases it.*
