---
id: SQ-GALLOWWOOD-03
title: The Reversible Knot
type: side
status: outline
arcana: none
region: The Gallowwood
requires: []
fires: []
---

# SQ-GALLOWWOOD-03 — The Reversible Knot

## Introduction

An exacting master rope-checker is drilling an apprentice in the one law of Gallowwood
ropework: tie only knots that come undone in a single pull. "A knot you can't reverse
isn't a knot," Corbenic Yew will tell anyone within earshot, "it's a mistake with rope in
it." The Fool gets roped in — literally — as a second pair of hands, and the lesson turns
out to be the Hanged Man's whole philosophy worn completely lightly: surrender you can come
back from, letting go that isn't death. It's a small traversal-teaching quest that doubles
as the Gallowwood's clearest statement of its own thesis, and it plays whether the forest
still hangs upside-down or has already been set right — the maxim outlives the orientation.

## Beats

1. **The hook.** On the canopy lines, Corbenic Yew (canon, `characters.md` §Regional named NPCs) is running an apprentice (unnamed walk-on)
   through the knots, rejecting each with dry severity — they keep tying holds too well to
   undo. Yew presses the Fool into service as an extra hand and an extra student.
2. **The teaching, as traversal.** A set of canopy challenges where the Fool must tie,
   climb, and — crucially — *release* reversible knots to progress; a knot that won't undo
   strands you and forces a reset. The loop teaches the same trust-the-let-go motion the
   region is built around.
3. **The philosophy surfaces.** Yew's maxim is, unmistakably, the Hanged Man's — but Yew
   would be mortified to be called a philosopher; he just knows rope. Worn lightly and never
   spelled out; the player is trusted to feel the rhyme.
4. **The apprentice's fumble.** The comic beat: the apprentice finally ties a flawless
   reversible knot entirely by accident, while distracted, and can't believe it. Yew
   expresses his pride as the smallest possible grunt.
5. **The honest beat.** Theme 1: Yew explains where the rule came from — a knot that
   wouldn't undo cost a friend a fall, long ago and long before the Stall, and every
   reversible knot since has been a small refusal of endings you can't take back. Which is,
   quietly, the Gallowwood's whole thesis: the endings worth trusting are the ones you
   choose and can let go of cleanly.
6. **The resolution.** The Fool graduates. Yew, honoring the only way he knows, offers to
   name a knot after the Fool (a comic dignity) and hands over a rope-checker's token. If
   the Fool takes up the Rope-checker Calling, Yew's workplace-memory lines unlock.

## Variant notes (order-independent)

- **[If not yet unbound]** The drills run through inverted glades and feather-fall
  descents; the "single pull" release reads as the same let-go the Cliff's leap taught and
  MQ12 will later ask at the bough — a deliberate rehearsal of the Hanged Man's ordeal.
- **[If WS_HANGEDMAN_UNBOUND]** The forest is right-way-up; the traversal reorients to
  ordinary gravity and ordinary climbing. Yew notes, wry, that the maxim outlived the
  upside-down wood — a reversible knot is just as true right-way-up. His pride: the craft
  was never about the flip, it was always about letting go without leaving a mess behind.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (graduated) | none — NPC-level only | Yew greets the Fool as a passed student; Rope-checker Calling workplace lines unlock; the apprentice's barks gain confidence; no `WS_*` flag is set. |

## Consistency references

- `world.md` §The Gallowwood — "traversal playground"; §World-state matrix
  (`WS_HANGEDMAN_UNBOUND`) — the righting that the `[If WS_HANGEDMAN_UNBOUND]` variant
  handles; requires `[]` so the quest plays in either order.
- `callings.md` §The Callings — Rope-checker ("inspect and re-knot canopy lines"); this
  quest is the craft's teaching piece and its named master.
- `characters.md` §XII. The Hanged Man — "suspension, surrender, new perspective through
  letting go"; Yew's maxim is that philosophy in a working tradesman's mouth (the Hanged
  Man himself does not appear — he is at the bough — so no bound-name issue arises).
- `MQ12-a-change-of-perspective.md` — the "let go" motion and its deliberate rhyme with the
  Cliff's leap of faith; the `[If not yet unbound]` variant leans on that rehearsal.
- `narrative.md` §Theme 1 (the good ending is the one you can choose and release) and
  §Dialogue style guide (one honest beat in the comedy; Fool lines ≤ 12 words with an
  earnest option).
- `progression.md` §Renown, cosmetic-only rule — reward is a rope-checker's rig / token
  (cosmetic) and light Renown; explicitly not a staff head (those are found/bought, ~8–10
  total) and not a Trump.

## Open questions

- The knot-tie/release traversal wants a concrete interaction. Decide whether it reuses a
  general Gallowwood rope-traversal mechanic or is bespoke to this quest; recommend tying it
  to the Rope-checker Calling's core loop so the two reinforce each other.
- Confirm the comic "knot named after the Fool" is a purely narrative honor (no mechanical
  hook), to keep rewards within the cosmetic/Renown/coins allowance.
