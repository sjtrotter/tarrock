---
id: SQ-GALLOWWOOD-02
title: The House That Faced the Wrong Way
type: side
status: outline
arcana: none
region: The Gallowwood
requires: [WS_HANGEDMAN_UNBOUND]
fires: []
---

# SQ-GALLOWWOOD-02 — The House That Faced the Wrong Way

## Introduction

The Gallowwood has righted itself. Gravity remembers which way it was going, the canopy
paths hang the right way down, and one canopy-dweller stands in the middle of a home that
is now, by the world's new rules, entirely upside-down. Wick Alder built her house and her
whole rope-checking trade oriented to the old inverted gravity — floor overhead, door
underfoot, a lifetime's competence learned sideways to everyone else's — and now she must
decide whether to rebuild it "correctly" and join the righted world, or love it exactly as
it was. There's no fixing this one for her; the quest is helping her find out which loss
she can live with.

## Beats

1. **The hook.** Post-`WS_HANGEDMAN_UNBOUND`, the wood is right-way-up and Wick Alder
   (canon, `characters.md` §Regional named NPCs) is the
   last inverted thing in it — her home a curiosity, well-meaning neighbors already offering
   to help "put it right." Her competence, built for a forest that no longer exists, is
   suddenly the odd one out.
2. **The complication.** Theme 2: her whole self is *the rope-checker who reads the flipped
   canopy* — an expertise, like Bracken Loft's in MQ12, in something that stopped existing
   overnight. Righting the house means unlearning the only "up" she ever mastered.
3. **The survey.** The Fool helps her walk the house (Rope-checker Calling tasks — re-rigging
   lines, testing anchors). Comedy of a home where everything is where it shouldn't be: the
   kettle hangs from what's now the ceiling; the front step sits above the door; her bed is a
   loft that used to be a cellar.
4. **The choice.** Help Wick rebuild it to the new orientation — a fresh start, joining the
   world's new down — or help her keep it exactly as it was, a livable, glorious monument to
   the life she knew. Theme 3: the freedom that righted the forest is the same freedom that
   unmade what she was good at, and no answer erases that. The Fool helps; the Fool does not
   decide.
5. **The ache and the laugh.** The ache: she is grieving not the house but the person who
   knew, in her hands, how to live in it. The laugh: whichever way she chooses, she declares
   the ceiling-kettle stays exactly where it is, purely to unsettle visitors. The honest
   beat: she admits she isn't sure she wants to learn a whole new "up" this late in a very
   long life.
6. **Closing beat.** The house stands corrected or gloriously wrong per the choice; Wick's
   barks shift accordingly, and — like Bracken Loft — she becomes one of the Gallowwood's
   living keepers of "how it used to hang." No `WS_*` flag is set.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (rebuild or preserve) | none — NPC-level only | Wick's house and barks reflect the chosen route; she settles into the role of remembering the old orientation; no `WS_*` flag is set. |

## Consistency references

- `world.md` §The Gallowwood; §World-state matrix (`WS_HANGEDMAN_UNBOUND`) — "Gallowwood
  rights itself (traversal reshuffles)"; requires that flag, and the reshuffle is the
  quest's whole premise.
- `MQ12-a-change-of-perspective.md` — Bracken Loft's mourning (an expert in reading the
  flipped terrain, made useless overnight). Wick is a *distinct* NPC and a distinct home;
  this quest deliberately rhymes with Loft's beat without duplicating him.
- `callings.md` §The Callings — Rope-checker ("inspect and re-knot canopy lines"; post-MQ12
  right-way-up trail warden); Wick embodies the pre-to-post transition of that trade.
- `characters.md` §The Minors: suit-cultures — Wands (woods; craft, competence of the hands)
  informs Wick's voice and her grief over a lost skill.
- `narrative.md` §Themes 2 and 3, §Dialogue style guide (one laugh in the sad scene; Fool
  lines ≤ 12 words with an earnest option).
- `progression.md` §Renown, cosmetic-only rule — reward is a rope-checker's keepsake / a
  topsy-turvy trinket (cosmetic) plus light Renown; no gear.

## Open questions

- Should the rebuild-vs-preserve choice be readable by later Gallowwood ambient content (a
  landmark the player passes), or stay local? Recommend making the house a visible landmark
  either way — it's a strong, cheap piece of environmental storytelling.
- Confirm Wick and Bracken Loft are kept clearly separate at script status (two keepers of
  the old wood), or whether one should be folded into the other to avoid redundancy.
  Recommend keeping both — a private grief (a home) beside a public one (a trade).
