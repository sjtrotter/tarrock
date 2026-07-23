---
id: SQ-GALLOWWOOD-01
title: The World-Tree's Other Visitor
type: side
status: outline
arcana: none
region: The Gallowwood
requires: []
fires: []
---

# SQ-GALLOWWOOD-01 — The World-Tree's Other Visitor

## Introduction

At the foot of the World-Tree, where the Hanged Man hangs serene and content, the Fool
meets the one pilgrim who has spent three hundred years refusing to take the hint. Fenwick
Sorrel is convinced there is a profound teaching to be had from the figure on the bough,
and that he simply hasn't been patient enough yet to receive it — which is very nearly the
joke of the whole quest, because the lesson *is* patience, and he's spent three centuries
impatiently chasing it. This is a whimsical, gentle comedy about seeking enlightenment from
someone having an extraordinarily long and happy nap. It plays while the forest still hangs
the wrong way up; the Hanged Man appears only as he always is — unhurried, affectionate,
and in no way inclined to be profound on command.

## Beats

1. **The hook.** Camped beneath the great bough amid notebooks full of "almost-teachings,"
   Fenwick Sorrel (canon, `characters.md` §Regional named NPCs) conducts elaborate one-sided conversations upward and begs the Fool to help him
   finally get through to the Hanged Man.
2. **The attempts.** Comic escalation of what Sorrel has tried: fasting, hanging
   upside-down himself (badly, and with commentary), asking ever grander questions. The
   Hanged Man answers, if at all, with a serene near-silence or one small contented remark
   that Sorrel instantly over-reads into cosmic significance.
3. **The intercession.** Sorrel asks the Fool to put a question to the Hanged Man on his
   behalf, or to interpret the last "teaching." The Hanged Man — gentle, genuinely happy,
   no urgency whatsoever, and never once naming himself — offers something small and true
   in reply: a mild wonder at why anyone is in such a hurry to stop hurrying. (He does not
   fight, does not rise, does not perform wisdom; he is exactly as MQ12 paints him.)
4. **The turn.** Theme 1, delivered as the honest beat inside the comedy: Sorrel slowly
   works out that the teaching he chased for three centuries was never a secret and never
   his alone — it's just patience, and he has spent three hundred years being impatient
   about it. The laugh: the punchline is that the figure was, functionally, napping the
   whole time, and Sorrel's revelation is entirely self-generated. He isn't crushed; he
   laughs at himself at last, which is the first patient thing he's ever done.
5. **The resolution.** Sorrel stops striving. He doesn't leave — he doesn't want to, and
   the bough is exactly where he'd choose to be — but he finally just *sits*, content, a
   small living rehearsal of the peace `WS_HANGEDMAN_UNBOUND` will one day spread into the
   world's barks. No `WS_*` flag is set.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Sorrel's barks shift from striving to settled; he becomes a calm ambient presence beneath the bough; no `WS_*` flag is set. |

## Consistency references

- `world.md` §The Gallowwood — inverted forest with "a serene figure hanging from the
  World-Tree's bough, perfectly content"; the setting and the Hanged Man's disposition.
- `characters.md` §XII. The Hanged Man — "gentle, unhurried, genuinely happy… real
  affection and no urgency whatsoever"; the dialogue rule that a bound Arcanum never uses a
  personal name (so he is never "Wendel" here).
- `MQ12-a-change-of-perspective.md` — the Hanged Man is joined, never fought; his single
  gentle question and his contentment. This quest must not pre-empt or contradict MQ12's
  encounter (Sorrel gets no unbinding; the Fool does no fighting).
- `narrative.md` §Theme 1 (a peace worth learning; the frozen world's one contented soul)
  and §Dialogue style guide (one honest beat in the comedy; Fool lines ≤ 12 words with an
  earnest option — e.g. "He's waited three hundred years to hear you." / "Any wisdom going
  spare?").
- `progression.md` §Renown, cosmetic-only rule — light Renown and at most a pilgrim's
  keepsake (cosmetic); no gear.

## Open questions

- Tagged pre-unbinding; the quest depends on the Hanged Man still hanging. If the player
  unbinds the Gallowwood first, Sorrel's arc should resolve off-screen in the aftermath —
  his teacher gone, his lesson ironically landed at last. Confirm this fallback or write a
  short post-unbinding coda at script status.
- How much of the Hanged Man's "reply" is voiced vs. left as serene ambiguity the player
  interprets. Recommend keeping it minimal and unmistakably un-profound, so the comedy holds
  and MQ12 keeps its weight.
