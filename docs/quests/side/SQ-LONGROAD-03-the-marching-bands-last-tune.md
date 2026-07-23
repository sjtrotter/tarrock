---
id: SQ-LONGROAD-03
title: The Marching Band's Last Tune
type: side
status: outline
arcana: none
region: The Longroad
requires: []
fires: []
---

# SQ-LONGROAD-03 — The Marching Band's Last Tune

## Introduction

Fitch Yarrow has drummed the same triumphal march for three hundred years, and every
night, when the fort lamps are low, he composes new music he is terrified to be caught
wanting. The procession does not allow wanting; it only allows marching. The player can
meet Fitch before the Chariot is unbound — a man hiding a secret so gentle it embarrasses
him — or after, when the march has finally stopped and Fitch stands at a newly-quiet
Waystation with a drum, a tune of his own, and no permission left to refuse him. Either
way the quest is about the smallest, most enormous act of freedom in the game: playing
one thing nobody ordered you to play.

## Beats

1. **The hook.** Fitch Yarrow (`characters.md` §Regional named NPCs — promoted in the
   parallel slate change), procession drummer, keeps a battered second drum and a sheaf
   of scratched-out staves he'll deny are his if asked directly. He is a marvelous
   musician trapped inside a single cadence.
2. **The complication.** The march is not just habit — it is the only music the
   procession's rhythm will tolerate, and Fitch has spent three centuries convinced that
   wanting more is a kind of desertion. He'll play the Fool a bar of the new thing, once,
   quiet, then stop as if scalded.
   - `[If not WS_CHARIOT_UNBOUND]` The procession still marches; Fitch composes only at
     the fort at night, and the quest is coaxing him to admit the tune exists at all —
     to *one* listener, off the road, where the cadence can't hear him.
   - `[If WS_CHARIOT_UNBOUND]` The march has halted; Fitch stands among the dispersing
     musicians holding a freedom he doesn't know how to spend, and the quest is coaxing
     him to actually play the new tune out loud, now that nothing forbids it.
3. **The engineered moment.** The Fool arranges a first audience — before unbinding, a
   single trusted fort-mate in the dark; after, the strangers arriving at a now-active
   Waystation (`callings.md`, Waystation keeper), who have nowhere to march to and all
   the time in the world to listen.
   - Fool (earnest): "Play the one you're afraid of." / (foolish): "Louder. Wake the
     banners."
4. **The performance.** Fitch plays it. It is nervous, off-tempo, and — after three
   hundred years of one cadence — completely, gloriously his own. `[If WS_CHARIOT_UNBOUND]`
   it is the first new music heard on the Longroad since the Stall.
5. **The ache and the laugh.** He apologizes for the wrong notes; the Fool (or a listener)
   points out there's no right ones anymore, no march to be wrong against — which lands as
   the biggest relief and the biggest loss of his life at once, and he laughs at himself
   for weeping over a drum.
6. **Closing beat.** Fitch keeps composing, out loud now. His barks shift from the rote
   cadence-count to trying out new phrases on anyone who'll pause; `[If WS_CHARIOT_UNBOUND]`
   he becomes the small, off-tempo, triumphant sound of a Waystation that used to be
   silent.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (either state) | none — NPC-level only | Fitch's barks change from the fixed march-cadence to newly-composed phrases; a cosmetic reward (a drummer's sash / Wands Renown for finishing a creative work) may land. No `WS_*` flag is set. |

## Consistency references

- `characters.md` §Regional named NPCs — Fitch Yarrow, procession drummer (promoted in
  the parallel slate change); his premise is the whole brief.
- `world.md` §The Longroad and §World-state matrix (`WS_CHARIOT_UNBOUND`) — the halting
  procession and the Waystation network the post-unbinding variant relies on; the pre-
  unbinding variant assumes the march still runs.
- `callings.md` — Waystation keeper (post-MQ07 "fast-travel arrivals to welcome"), the
  audience Fitch finally plays to.
- `narrative.md` §Themes (1 — a thing that cannot change cannot live, worn as one drummer's
  fear) and §Dialogue style guide (one laugh in the sad scene; Fool lines ≤ 12 words).
- `progression.md` §Renown — Wands standing for finishing a creative work; the outfit
  reward is cosmetic-only.

## Open questions

- Resolved: MQ07's soldier was renamed **Corporal Pike** at the characters.md promotion,
  clearing the clash with this quest's drummer Fitch Yarrow.
- Should the pre- and post-unbinding versions be one quest with a `[If WS_…]` fork (as
  written) or two separate hooks? Recommend one forked quest — the emotional shape is the
  same and the fork keeps it order-independent.
- Is the reward a cosmetic drummer's sash, plain Renown, or both? Defer to content-pass.
