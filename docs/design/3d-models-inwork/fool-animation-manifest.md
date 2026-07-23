# Fool animation manifest

*Working doc, not canon — lives in `3d-models-inwork/` on purpose, alongside
`blender-learning-guide.md`. This is a production checklist, not a design document: it
does not define new Trump effects, world-state, or dialogue, and it invents no canon.
Where it proposes a clip or a logical-state name that no owning doc has named yet
(the Bindle stow/draw pair, the light-string numbering, a defeat/"not yet" rise), that
is flagged as a production naming proposal, not a canon fact — the owning doc
(`combat.md`, `characters.md`) still governs the content if the two ever conflict.*

**Who this is for:** whoever animates the bespoke Fool — the in-house artist learning
Blender (see `blender-learning-guide.md`), a commissioned animator briefed from this
list, or whoever retargets a purchased mocap/animation pack onto the Fool's rig. The
point is that animation work happens off a list, not off vibes: every clip the Fool's
kit needs, in one place, each one already scoped against `combat.md`, `characters.md`,
`art-bible.md`, and what's actually coded today.

**Relationship to the animation contract** (`art-audio.md` §Current build rule 4):
*"gameplay addresses animations by logical state (Idle, Walk, Run, Dodge, Dig, Sit…)
through the Animator; which clip asset fills a state is an installer concern, swappable
per rig."* This manifest is the authoritative list of logical states the Fool's
Animator needs and what should occupy each one, at each stage of production. Nothing in
this doc is itself an installer or a controller — it is the brief the next installer
(bespoke-rig version) gets built from, and the checklist a swap gets reviewed against.

**The three sourcing tiers**, per `art-audio.md` §Current build: stand-in art / swap
discipline:

1. **Today — KayKit placeholder.** The `RogueKayKit.controller` built by
   `KayKitCharacterInstaller.cs` off the KayKit Adventurers "Rig_Medium" library (161
   clips across 8 source FBX files, CC0 — see `THIRD-PARTY-NOTICES.md`). Every logical
   state below lists its current stand-in clip where one exists, wired or unwired.
2. **Mid-term — retargeted packs / upper-body layering.** Before the bespoke set is
   ready, better-fitting purchased or CC0 mocap packs can be retargeted onto a
   Humanoid-compatible Fool rig, and combat verbs (attack strings, block) can ship as an
   upper-body-layer override so a placeholder lower body keeps walking under a combat
   pose. Not built yet; noted here as the expected middle step for anything KayKit's
   library doesn't already cover well (nothing in KayKit's library is Bindle-shaped —
   every combat clip below is a proxy, not a fit).
3. **Ship — bespoke set.** The final Fool rig and animation set, unique to Tarrock
   (art-bible.md's "every named character reads as itself" standard applies to the Fool
   same as any Arcanum, even though the Fool shares a build discipline with the Blanks
   in being playable and mass-produced-feeling rather than a boss). This manifest's
   logical-state names and priorities are what a bespoke animator (in-house or
   commissioned) builds against.

**How to read the tables:** *Logical state* is the Animator parameter/state name —
matched to what `Assets/_Project/Scripts/Player/*.cs` already uses wherever code
exists; a proposed name is marked *(proposed)* where no code or doc has named it yet.
*Loop* is loop vs. one-shot. *Root motion* recommends **no** by default — see
Authoring notes. *Priority*: **P0** = needed for the M1 slice (MQ00→MQ01 playable,
per `GDD.md` §Schedule); **P1** = combat vertical slice; **P2** = ship. *Stand-in*
lists the current KayKit clip, if any — "none" means the KayKit library has nothing
usable and the state is placeholder-less today (capsule/T-pose or a borrowed clip
flagged as a poor fit).

---

## Tier 1 — Locomotion & core

*13 logical states. 9 have a stand-in wired in code today (`PlayerAnimationDriver.cs`
via `KayKitCharacterInstaller.cs`); Walk and Turn-in-place are not currently
implemented as separate states (flagged below, not invented).*

| Logical state | Description | Loop | Root motion | Priority | Stand-in (KayKit) |
|---|---|---|---|---|---|
| **Idle** | `art-bible.md` §Animation: *"The Fool looks around — at everything, constantly. Wonder is the idle."* This is the single most character-defining clip in the whole manifest — per `art-bible.md`, idle reveals card/character before dialogue does. Not a neutral idle: restless, curious, head on a swivel. Bespoke tier should budget an idle **set** (2-3 variants cycled or randomized), not one loop, to sustain "constantly." | Loop | No | **P0** | `Idle_A` (fallback `Idle_B`) — wired, `Speed` = 0 on the `Locomotion` blend tree. Neutral KayKit idles; no wonder-personality read yet. |
| **Walk** | A slow, deliberate gait. **Not currently a distinct code state** — `PlayerMotor`'s comment: *"the default gait is a travel JOG (Running_A), not a walk; Shift held = sprint."* Flag: this manifest's brief asked for a Walk clip; code has none because the director explicitly tuned the default gait faster. Keep the clip on the list for dialogue-adjacent/cutscene use (a slow approach reads differently than a jog) even though the open-world locomotion blend skips it today. | Loop | No | P2 | None wired. KayKit has `Walking_A/B/C` unused in the installer — candidate if a Walk tier is ever added to the blend. |
| **Jog** | The Fool's default travel gait (per `PlayerMotor` comment, deliberately not a walk). | Loop | No | **P0** | `Running_A` (fallback `Running_B`) — wired, `Locomotion` blend tree. |
| **Sprint** | Full-speed gait, Shift/sprint-held. | Loop | No | **P0** | `Running_B` — wired, blend tree threshold `SprintThreshold` = 4.8 m/s. |
| **Sneak** (crouch-move) | Stealth crouch-walk, Ctrl-toggled. Also doubles as the **Focus stance's** move pose — see flag below. | Loop | No | **P0** | `Sneaking` (slow creep) / `Crouching` (livelier crouch-walk) — both wired, split by damped `Speed` at `CrouchMoveSpeedThreshold`; the installer's own comment calls this a two-cadence trick, not two states. |
| **Crouch idle** | Stealth-crouch idle. | Loop | No | **P0** | `CrouchIdle` state, a frozen offset of `Crouching`'s cycle — wired. |
| **Turn-in-place** | Not referenced anywhere in `PlayerMotor`/`PlayerAnimationDriver` — the character rotates by `RotateToward`'s `SmoothDampAngle`, no dedicated turn animation. Not flagged as missing so much as **confirmed out of scope** for now; note only so a bespoke animator doesn't spend budget on it unbriefed. | — | — | P2 (not currently planned) | None. |
| **Jump — hop** (short, grounded) | The normal jump: one authored launch→air→land arc, time-compressed into the airborne window so a short hop still reads the whole arc (director round note in code). Includes the **momentum jump** (running jumps clear more, same clip, just a longer/higher window) and the **grand backflip's ordinary counterpart** is separate, below. | One-shot | No | **P0** | `Jump_Full_Short`, entered at its launch-extension offset — wired as `Jump_Hop`. |
| **Jump — falling loop** | Long-fall airborne hold, reached only if the compressed hop clip plays out while still airborne (a drop off a ledge). | Loop | No | **P0** | `Jump_Idle` — wired. |
| **Jump — land** | Grounded-landing settle, feeding back into locomotion. | One-shot | No | **P0** | `Jump_Land` — wired (also the fallback chain's landing when `Jump_Full_Short` is absent, via `Jump_Start`). |
| **Falling / landing — superhero landing** | The **grand backflip's** emphatic finish (combat.md §Focus: *"a high, deliberately majestic backflip... finished with an emphatic landing"*) — a genuine drop into a deep crouch (hips near the floor) then a rise-to-stand. Code calls this out by name in a comment as "the superhero land-and-rise." | One-shot | No | **P0** | `Spawn_Air`, entered at its impact frame — wired as `GrandLanding`. (`Spawn_Ground`, a plainer landing variant, exists in the library unused — candidate for a non-backflip hard landing if one is ever wanted.) |
| **Grand backflip** (airborne) | Crouched jump = the grand backflip (combat.md §Focus): "taller than a normal jump, carrying the Fool roughly 1.5 body-widths backward." The Animator holds a readable airborne silhouette (extended launch pose, played slow) while `PlayerAnimationDriver`'s **procedural 360° tumble** (not the clip) owns the actual spin — the clip and the code-driven rotation are deliberately separate layers. Distinct from the Focus back-dodge (a quick evasive flip, below), per combat.md; this one is theater. | One-shot | No | **P0** | `Jump_Full_Short`, slowed 0.5x, entered at its launch-extension offset — wired as `GrandBackflip`. |
| **Dodge set — directional** | combat.md §Focus: in Focus, dodge input is directional — forward/neutral = roll, left/right = strafing side-hop, backward = backflip. All share i-frame rules and can trigger Fool's Chance. Code's `DodgeVariant` enum: `Roll`, `HopLeft`, `HopRight`, `Backflip`. The **roll and the backflip** get a procedural 360° head-over-heels tumble layered over the clip (same technique as the grand backflip, opposite travel-direction logic); **the two side-hops stay upright, no tumble** — they read as a quick strafing step, not a flip. | One-shot | No | **P0** | `Dodge_Forward` / `Dodge_Backward` / `Dodge_Left` / `Dodge_Right` — wired, 2D directional blend on `DodgeX`/`DodgeY`. **Flag:** KayKit's pack has no actual roll clip (per `PlayerAnimationDriver`'s own doc comment: *"the KayKit pack has no roll clip"*) — the tumble is 100% procedural, riding on top of whatever pose these four clips hold. A bespoke roll needs an authored clip; the procedural tumble is a stopgap, not the intended final technique (though it could remain a cheap layer even with a bespoke clip — a director call). |
| **Focus stance — idle/walk** | combat.md §Focus: "the Fool drops into a readable ready-crouch" when Focus is held. **Code does not implement Focus as a separate logical state** — `PlayerAnimationDriver` explicitly folds `IsFocused` into the same `Crouched` bool as the stealth crouch (comment: *"The Focus stance reuses the crouch pose... so the Focus input folds into the animator's Crouched gate alongside the Ctrl-toggled stealth crouch."*) **Flag, per task brief:** combat.md's "readable ready-crouch" reads as its own combat-ready silhouette (weight forward, staff-ready), distinct in spirit from a stealth crouch (weight low, sneaking) — but nothing in `combat.md` mandates a visually distinct pose, and code deliberately shares one today. Recommend a bespoke Focus-specific idle/walk pair once the Bindle exists to hold two-handed, since a staff-ready stance and a stealth crouch will read very differently once the weapon is on screen — but don't build it as a P0/P1 need; the shared Crouched state is a legitimate placeholder, not a bug. | Loop | No | P1 (bespoke split), currently sharing Sneak/CrouchIdle | Shares `Crouching`/`Sneaking`/`CrouchIdle` — no distinct clip. |

---

## Tier 2 — the Bindle

*9 logical states/pairs. None are implemented in code yet — no combat script exists
under `Assets/_Project/Scripts/Player/` beyond locomotion/dodge/focus; every entry
below is sourced from `combat.md` §The Bindle / §Defense only, with logical-state
names proposed here for the first time (not yet code, not yet canon-named) since no
doc had occasion to name them before this manifest. Two-handed grip throughout — per
`combat.md` §Defense, "the Fool carries no shield; the Bindle is used two-handed."*

| Logical state | Description | Loop | Root motion | Priority | Stand-in (KayKit) |
|---|---|---|---|---|---|
| **Bindle_Stow / Bindle_Draw** *(proposed names)* | `characters.md` §The Fool: the Bindle is "carried over the shoulder in the world, wielded in combat"; the brief for this manifest calls the stow↔draw transition "part of the fantasy." Two short transition clips (shoulder-carry → two-hand ready grip, and back) bridging the socket swap described in Authoring notes. | One-shot (both directions) | No | P1 | None. `PlayerRigInstaller.cs` currently disables all of KayKit's `handslot.l`/`handslot.r` attachment props (comment: *"the Fool carries the Bindle, not an armory"*) but the code comment also notes "the Bindle itself will live in a hand slot eventually" — no back/shoulder socket exists in code yet either; that needs adding alongside this pair. |
| **LightString_1 / _2 / _3** *(proposed names)* | combat.md: "Three-hit staff combo, fast and precise. The Fool's default answer to single targets and openings." Three distinct hits, not one clip looped — each should read as a beat in a combo, not identical repeats. | One-shot each | No | **P0** (M1 combat prototype touches this per `GDD.md` M1 exit criterion) | `Melee_2H_Attack_Chop`, `Melee_2H_Attack_Slice`, `Melee_2H_Attack_Stab` (KayKit two-handed set) — reasonable proxies for a 3-hit string; none are staff-specific (all read as a bladed weapon), a mid-term retarget/upper-body-layer candidate before the bespoke set. |
| **Heavy** | "Wide crowd sweep — the bundle end drags through the strike, hitting everything in an arc. Answer to groups." | One-shot | No | P1 | `Melee_2H_Attack_Spin` or `Melee_2H_Attack_Spinning` — a spin reads closer to a sweeping arc than a chop/slice; imperfect (it's a full body-spin, not a staff-drag), flagged as a proxy only. |
| **ChargedHeavy_Charge / _Release** *(proposed names)* | "Held heavy attack; releases into a launcher that pops enemies airborne, opening aerial follow-up." Needs a held/charging loop plus a distinct release. | Charge: loop; Release: one-shot | No | P1 | None good. No KayKit clip reads as a held wind-up into a launcher; `Melee_2H_Attack_Slice` is the least-bad placeholder for the release beat only, with no charge-loop stand-in at all. |
| **RunningAttack** | "A forward lunge strike, closes distance and interrupts." | One-shot | No | P1 | `Melee_1H_Attack_Jump_Chop` — closest available "forward-committing" lunge shape in the library, but it's a one-handed jump-chop, not a grounded two-handed lunge; flagged as a weak proxy. |
| **AerialAttack** | "Available after a launcher or a fall/jump; keeps combat readable in vertical spaces." | One-shot | No | P1 | None. Nothing in the KayKit library is an airborne attack pose; this state is effectively unplaceholdered today. |
| **HitReact** | Player-side hit reaction (impact flinch). Not to be confused with the Blanks' own defeat/fade (combat.md §Enemies: the Blanks — that's an enemy VFX/animation concern, out of scope here). | One-shot | No | P1 | `Hit_A` / `Hit_B` — exist in KayKit's General library, unused by any installer today. |
| **Stagger** | A heavier, longer knockback reaction distinct from a light hit-react (implied by any real difficulty curve; not explicitly separately named in `combat.md` — flagged as inferred, not quoted canon). | One-shot | No | P2 | None distinct — `Hit_B` reused as the heavier of the two hit-reacts is the only candidate; flagged as a placeholder overlap, not a real second pose. |
| **FoolsChanceFlourish** *(proposed name)* | combat.md §Defense: Fool's Chance is "the skill-expression centerpiece of combat" — a perfectly-timed dodge triggering ~1.5s slow motion and a free Present cast. The brief for this manifest calls out a dedicated "slow-time dodge flourish," i.e. a visually distinguished version of the dodge for this moment, not just the normal roll played at reduced timescale under the global slow-mo. **Flag:** `combat.md` does not currently specify a visually distinct Fool's Chance pose — this is a production ask this manifest is surfacing, not existing canon; whether Fool's Chance gets its own clip or stays "the normal dodge, but everything else is slow" is a director call, not decided here. | One-shot | No | P1 | None — no stand-in attempted; the current build (no combat layer yet) doesn't trigger this at all. |
| **Defeat_Collapse / Defeat_NotYetRise** *(proposed names)* | combat.md §Pip establishes the canon mechanism for Pip specifically ("cannot die... yelps, retreats, shakes it off, returns... nothing in the Spread can truly end before `WS_DEATH_UNBOUND`"). **Flag, do not invent canon:** combat.md is silent on what happens when the *Fool's* health reaches zero — no doc states whether the Fool has a fail state at all, and if so whether it mirrors Pip's "can't truly end" rule or is a conventional game-over/reload. This manifest proposes two clips (a collapse, and a "not yet" rise consistent with the world's own can't-truly-end rule, per the brief) as a *production placeholder pairing* on the reasonable-but-unconfirmed assumption that the Fool's defeat state will lean on the same canon Pip already demonstrates — this needs a design decision in `combat.md` before it is treated as settled, not just an animation. | One-shot each | No | P2 | None. |

---

## Tier 3 — interactions

*11 logical states, drawn from MQ00, MQ07, MQ08, MQ12, MQ16, MQ17 (per the read-through
required for this manifest) plus `arcana.md`'s Trump IX. `art-audio.md`'s own animation
contract example (§Current build rule 4) names "Dig" and "Sit" directly among its
canonical logical-state examples — both land here.*

| Logical state | Description | Loop | Root motion | Priority | Stand-in (KayKit) |
|---|---|---|---|---|---|
| **CrouchInspect** ("dig-assist") | MQ00: Pip digs up the whittled wooden dog; the Fool's own action at the same beat is approaching/crouching to receive it, and separately "interact with a fire-ring to inspect it" (environmental-only, no dialogue). Note: **Pip is the one who physically digs** in every quest reference found (MQ00 only); no quest has the Fool digging directly. This state covers the Fool's crouch/kneel-to-inspect beat, not a dig animation for the Fool — a true "Dig" clip belongs to a **future companion (Pip) manifest**, out of scope here per the task brief. | One-shot / held | No | **P0** (MQ00, M1) | `Interact` (general) — exists, unused by any installer today. |
| **Sit — ground** | MQ17 (the Mere, Star): the long, un-timed "sit-with-Pip" vigil beat — "The only prompt offered is: sit." Also implied by MQ00's "sit up" wake beat (distinct pose — waking, not settling) and MQ07's Corporal Pike inviting the Fool to sit at the toll-fort (an NPC seat, not necessarily animated for the Fool depending on staging — flagged as a case that may or may not need this state, a staging call). | Loop (settle + idle-in-seat) | No | P1 | `Sit_Floor_Down` → `Sit_Floor_Idle` → `Sit_Floor_StandUp` — full three-part cycle exists in KayKit's Simulation library, unused. |
| **Sit — edge / jetty** | MQ17: the shoreline jetty is a specific seated posture (legs over an edge) distinct from a flat-ground sit; the brief calls this out by name. No quest text describes the leg position explicitly enough to confirm it's mechanically different from Sit — ground, but the location (an edge, over water) suggests it should be. | Loop | No | P1 | None distinct — `Sit_Floor_*` reused as a placeholder; a true edge-sit (legs hanging) isn't in the library. |
| **Kneel** | No quest scene puts the *Fool* kneeling on-screen in the docs read for this manifest (MQ08's kneeling figure is Maud, the tableau NPC, not the Fool; MQ17's kneeling is the Warden). Included per the brief's ask, flagged as **currently unconfirmed by any quest beat** — likely needed for a Waystation-rest gesture (progression.md: Waystations are "the game's rest points"; MQ00's tutorial prompt is "rest at the Waystation," staging unspecified) or a future dialogue/cutscene beat not yet scripted. | One-shot / held | No | P2 | None. |
| **CarryObject** | Not found as an explicit Fool verb in the quests read for this manifest. Included per the brief's ask as a generic kit action (item-carry poses are common utility clips); flagged as **unconfirmed by any quest** — no doc currently calls for the Fool visibly carrying a held object outside combat/the Bindle. | Loop (locomotion overlay) | No | P2 | `Holding_A/B/C` (KayKit Tools library, generic held-object idles) — unused, imperfect fit for a moving carry. |
| **PickUp** | MQ00: "pick up the Bindle" (the game's opening gesture — the Fool's first action after waking). Also generic item pickups implied throughout an open world with the Bindle as inventory. | One-shot | No | **P0** (MQ00, M1) | `PickUp` — exists, unused by any installer today; also `Use_Item` (General library) as an adjacent unused candidate for consumable-use, not itself a pickup. |
| **Hang** | MQ12 (Gallowwood, Hanged Man): "leap and grab the low bough. The Fool hangs from it... the camera settles into the hang." A held, static hang — "This is the ordeal's whole motion in miniature." | Loop | No | P1 (MQ12 is a mid-game main quest, not M1) | None. |
| **TraverseHang** | MQ12: the canopy circuit — "The Fool climbs across to the stranded traveler" while hanging/traversing inverted terrain; distinct from the static **Hang** above by being a locomotion cycle, not a held pose. | Loop | No | P1 | None. |
| **Mantle / Climb** | MQ16 (the Spire, the Tower): "mantle a handhold — grip-marked ledges the eye can read"; also "take the rope" to bridge a sheared staircase, and the ascent's "climb on its offbeats" against the Warden's telegraphed rubble shifts (a traversal-combat hybrid, not pure platforming). MQ07 also uses climbing verbs (gate-arm, banner rigging) during the Chariot chase — same underlying state, different dressing. | One-shot (mantle) / Loop (rope-climb) | No | P1 (MQ16/MQ07 are not M1) | None. |
| **LanternRaise** | `arcana.md` Trump IX (the Hermit, Ellery): Present-slot effect is *"Raise the lantern: reveal hidden paths, rout shadow-Blanks, counts as true light (Mirrormarsh gate)."* This is a core, repeatable **gameplay** action once Trump IX is held (not a one-off), so it belongs in the core kit tier despite being Trump-gated content. | One-shot (raise) + loop (held/active) | No | P2 (gated behind MQ09, later than M1/combat-vertical) | None. |
| **Emote — LookAroundWonder / Wave / WarmYourHands** | Generic emote set. `LookAroundWonder` is the *amplified, player-triggerable* cousin of the base Idle's wonder-read (art-bible.md's idle-is-personality principle) — for barks/cutscenes where the ambient idle isn't enough emphasis. `Wave` and `WarmYourHands` (a cold-weather/campfire gesture) are generic social/ambience emotes not tied to a specific quest beat found in this read-through; included per the brief as baseline emote-wheel content. | One-shot each | No | P2 | `Waving` (KayKit Simulation library) covers Wave directly; no stand-in for LookAroundWonder (arguably just Idle re-triggered) or WarmYourHands. |

---

## Tier 4 — setpiece one-offs (quest-owned, build-when-scheduled)

*3 logical states. Each belongs to, and is scoped entirely by, the quest that uses it —
this manifest lists them so they're not lost, not so this doc governs their content.
If the quest script and this manifest ever disagree on the beat's staging, the quest
script wins (per `docs/README.md` "quests cite canon," not the reverse — though in this
direction it's really "the animation manifest cites the quest," a checklist referencing
scenework it doesn't own).*

| Logical state | Description | Loop | Root motion | Priority | Stand-in (KayKit) | Quest |
|---|---|---|---|---|---|---|
| **LeapOfFaith** *(proposed name)* | MQ00's closing beat: "The Fool steps out into nothing, and falls" — the game's real opening move, transitioning into the cutscene skydive over the Spread. Likely partly/wholly cutscene-baked rather than a real-time Animator state (the fall becomes a "long, held breath of a skydive," clearly a camera-driven cinematic beat) — flagged so a bespoke animator doesn't assume this needs to be a re-enterable gameplay state. **Despite Tier-4 placement (quest-owned, one-off), this is P0**: MQ00 is the M1 exit criterion (`GDD.md` §Schedule) — tier here organizes by kit-scope (is this reusable across quests, or owned by one scene), not by schedule. | One-shot (likely cutscene) | No | **P0** (MQ00 is the M1 exit criterion, despite Tier-4 kit-scope) | None; not attempted by any installer. |
| **GrappleHold / GrappleBreakAway** *(proposed names)* | MQ08 (the Maw, Strength): "The encounter, exactly per `arcana.md` §VIII. This is a grapple-duel, not a fight... the only verbs are grapple-hold, break-away, and the gentleness prompts." A sustained stamina-wrestling loop plus a release. Full mechanical detail owned by `arcana.md` §VIII — this manifest only lists the animation need. | Hold: loop; break-away: one-shot | No | P2 (MQ08 is not M1/combat-vertical) | None. |
| **TakeTheReinsPull** *(proposed name)* | MQ07 (the Longroad, the Chariot): "a sustained grab-and-pull — the Fool's grip closing over the Charioteer's, both of them straining against the train's gathered momentum... Escalating pull. The Fool wins it by inches." Note: MQ07's own Open Questions flag the input rig for this beat as undecided ("does the 'take the reins' tug-of-war need its own bespoke input rig, or can it reuse an existing QTE/grapple system") — the animation need tracks that same uncertainty; a final clip count depends on how many escalating pull-stages the eventual input rig has. | Loop (sustained pull) + one-shot (win) | No | P2 (MQ07 is not M1/combat-vertical) | None. |

---

## Authoring notes

- **Humanoid rig requirement.** `art-bible.md` §Production standards: keep rigs
  "Humanoid-compatible... so animation survives the decision" (the pending
  character-art direction pass on proportions/stylization). Build and export the
  bespoke Fool as a Unity **Humanoid** rig even before final proportions are locked —
  this is what makes mid-term retargeting (Tier 2 sourcing) possible at all, and what
  lets any purchased pack in the interim be tried against the Fool without a rebuild.
- **Scale.** 1 unit = 1 meter, in Blender and Unity alike (`art-bible.md` §Production
  standards). Note the *separate* stand-in-only scale contract in `art-audio.md`
  (player as a ~0.7 m "game-piece miniature" against a 4 m hex) — that governs the
  current diorama build, not the bespoke character's own modeling scale; do not build
  the Fool "small," build at 1:1 human scale and let the scene-level scale contract
  handle the miniature read, exactly as `art-audio.md` rule 1 requires ("no content may
  depend on stand-in geometry").
- **Root motion: recommend NO**, project-wide, for the Fool. Every current animation
  driver (`PlayerAnimationDriver.cs`) is explicitly read-only and never touches the
  `CharacterController`; `PlayerMotor.cs` is the single owner of all movement, driven
  by code (speed, dodge velocity, jump arcs, the grand backflip's procedural drift) —
  the existing KayKit clips are themselves authored with root motion baked in but are
  used **in-place only** (a code comment on the grand backflip pose selection notes
  "both clips are in-place — root motion baked — so the pose, not the clip's own
  travel, is all that matters here"). Author and export bespoke clips in place, and
  let code keep owning displacement, unless a specific future state (the sustained
  Tier 4 pulls, maybe) makes a documented, deliberate case for root motion — flag that
  case explicitly if it comes up, don't default into it.
- **The Bindle is a separate prop**, socketed hand ↔ back. `characters.md` §The Fool:
  carried over the shoulder in the world, wielded two-handed in combat. Mechanically
  this means: model/rig the Bindle as its own asset with (at minimum) two sockets — a
  back/shoulder carry point and a two-hand combat grip — and the **Bindle_Stow /
  Bindle_Draw** pair (Tier 2) is mostly a socket-swap plus a short bridging transition,
  not a full-body re-animation. `PlayerRigInstaller.cs` already understands KayKit's
  `handslot.l`/`handslot.r` convention for a combat-grip socket; a back/shoulder socket
  does not exist yet in code and needs adding alongside the Bindle asset itself.
- **Export conventions**: see `blender-learning-guide.md` §Part 4 ("the export-to-Unity
  recipe") — not restated here to avoid a second copy of the same facts drifting out of
  sync.

## Open questions

- **Exertion vocalizations** (grunts, breath, effort sounds on attacks/dodges/landings)
  are TBD, owned by `art-audio.md`'s VO plan, not this doc — flagged here only so an
  animator doesn't accidentally block on audio-sync decisions that belong elsewhere.
- **Exact light-string count and timing** is pending combat tuning
  (`combat.md` marks i-frame/timing values as "tuning values... expected to move
  throughout production"); this manifest's three `LightString_*` clips assume the
  three-hit count `combat.md` currently states, but the *feel* of each hit (speed,
  reach, recovery) is not locked.
- **Fool's own defeat/death behavior is undecided in canon** (see the
  `Defeat_Collapse`/`Defeat_NotYetRise` row, Tier 2) — this needs a `combat.md`
  decision, not an animation decision, before those two clips are treated as more than
  a production placeholder guess.
- **Focus stance's visual distinctness from the stealth crouch** (see the Focus row,
  Tier 1) is a director call this manifest surfaces but does not resolve.
- **Fool's Chance's "flourish"** (see Tier 2) — whether it gets a dedicated pose at all,
  versus just being the existing dodge under global slow-motion, is undecided.
- **A companion (Pip) animation manifest** is explicitly out of scope here per the task
  brief (`characters.md` §Pip is combat.md/characters.md's territory, not this doc's) —
  noted as future work. Pip's own dig, sit, seek-point, and command-response clips are
  not covered by this document.
