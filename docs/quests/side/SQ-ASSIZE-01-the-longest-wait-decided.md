---
id: SQ-ASSIZE-01
title: The Longest Wait, Decided
type: side
status: outline
arcana: none
region: The Assize
requires: [WS_JUSTICE_UNBOUND]
fires: []
---

# SQ-ASSIZE-01 — The Longest Wait, Decided

## Introduction

Justice has been unbound; the verdicts of three centuries are finally landing across the
Assize, and the patient knitting queues are dispersing at last. This quest follows the one
petitioner nobody warned that a verdict can go against you. Goodman Otho Petts has waited
three hundred years on a small land dispute, knitting an almost architectural quantity of
scarves, certain that patience past all patience must count for *something* — and it
doesn't, because Justice is fair, and fair was never a promise that waiting makes you
right. There's no fight here, only the job the Fool learns is the whole point of being
present: sitting with someone through an ending that the waiting did nothing to earn.

## Beats

1. **The hook.** As the queues break up, Otho Petts (canon, `characters.md` §Regional named NPCs) is cheerful — his day has finally come. He is
   sure three centuries of patience have banked him something. He asks the Fool, whom he's
   watched come and go, to be there when his case is called.
2. **The complication.** Helping him ready his docket (a natural Queue-warden Calling
   task), the Fool learns from the emptying court what Otho hasn't let himself see: his
   claim is weak, has always been weak, and Justice — scrupulously fair — will rule against
   him. The scarves, the vigil, the decades bear on nothing.
3. **The rising beat.** The Fool can gently prepare Otho for the possibility, or leave him
   his hope for the hearing. Comic errand: carrying three hundred years of knitting to the
   courtroom, because the scarves will not fit through the door in one go.
4. **The verdict.** Otho's case is heard, and he loses — fair and square, precisely, the
   first true verdict rendered against him in three centuries. He stands in the emptying
   court holding a scarf longer than the room.
5. **The ache and the laugh.** Theme 3: the grief is that the wait meant nothing, and the
   quest refuses to soften it. The laugh: Otho decides the scarves, at least, are
   indisputably his, and begins draping one over every freed neighbor filing out — "won't
   be needing to knit through *another* verdict, will you." The honest beat: he asks the
   Fool, quietly, what he was even waiting for.
6. **Closing beat.** With the identity of "the man who's waiting" gone — Theme 2, the
   office that ate him dissolving with the queue — Otho casts about for what's next. He may
   stay on to usher the real hearings now (the Queue-warden's post become an usher's), a
   man learning, late, to fill a day he no longer has to wait through. No `WS_*` flag is set.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (verdict heard) | none — NPC-level only | Otho's barks shift from hopeful-waiting to a wry, unmoored afterward; he takes up ushering or drifts, per the Fool's presence; no `WS_*` flag is set. |

## Consistency references

- `world.md` §The Assize — "the accused of three centuries wait in patient queues,
  knitting"; the quest is the personal cost of the queues dispersing.
- `world.md` §World-state matrix (`WS_JUSTICE_UNBOUND`) — verdicts land, queues disperse;
  this quest is a direct downstream consequence, and requires that flag.
- `MQ11-the-adjourned.md` — Justice as scrupulously fair and unable, until unbound, to
  render a verdict; Otho's loss is Justice working *correctly*, not cruelly. (Do not
  duplicate Clerk Pettibone's mourning beat — Otho's is a distinct petitioner's grief.)
- `callings.md` §The Callings — Queue-warden ("keep the knitting queues in order; fetch
  tea"; post-MQ11 usher for real hearings); this quest gives that transition a face.
- `narrative.md` §Themes 2 and 3, §Dialogue style guide (one laugh in the sad scene; Fool
  lines ≤ 12 words with an earnest option).
- `progression.md` §Renown, cosmetic-only rule — a gifted scarf is a cosmetic keepsake;
  Renown only, no gear.

## Open questions

- The freed Justice (Prudence, `characters.md` §XI) is deliberately kept off-page — the
  verdict "lands" as world-state, not a scene. If a script-status pass wants her present,
  stage it against MQ11's aftermath beats.
- Should Otho's chosen afterward (usher vs. drift) be a player-influenced branch or a fixed
  outcome? Recommend fixed (he ushers), with the Fool's presence changing only the tone.
