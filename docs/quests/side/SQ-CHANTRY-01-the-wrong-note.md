---
id: SQ-CHANTRY-01
title: The Wrong Note
type: side
status: outline
arcana: none
region: The Chantry
requires: []
fires: []
---

# SQ-CHANTRY-01 — The Wrong Note

## Introduction

In a cathedral-town where a single hymn has rung the same hour since the Stall, chorister
Sister Perpetua Vane has sung one note flat for three hundred years — and no one has ever
noticed but her. The Fool, with a newcomer's ear, is the first person in three centuries
to hear it, and so the first person she has ever been able to tell. It is a very funny
quest about one wrong note inside a supposed perfection, and then it is not funny at all,
because that flat note is the only proof left that time ever passed before the Stall
caught her mid-breath.

## Beats

1. **The hook.** Attending the endless service, the Fool — hearing the hymn fresh where
   every local hears only "the hymn" — catches it: one voice, third row of the choir, a
   hair flat on a single sustained note. Afterward Sister Perpetua Vane (characters.md
   §Regional named NPCs) finds the Fool, ashen. Someone finally *heard*.
2. **The confession.** Three centuries of private horror poured out at once. In a place
   built entirely on getting it right, her one flat note has been a secret shame — she was
   mid-breath, reaching for it, when the Stall froze her, and she has held it a hair wrong
   ever since, unable to fix it, unable to stop singing it.
3. **The comedy.** Elaborate, doctrine-heavy schemes to correct one note inside a hymn
   that cannot change — different breathing, different posture, prayer, penance. The Fool
   can help her attempt a "correction" that of course cannot take, because nothing in the
   Chantry is allowed to be finished or fixed. The harder she tries, the flatter it sits.
4. **The turn (theme 1).** The Fool, or Perpetua herself, realizes the flat note is the
   one honest thing in a town pretending nothing ever broke — proof she was a living woman
   mid-breath when the world stopped, not a carving of one. The imperfection isn't the
   flaw in the perfection; it is the only mercy inside it.
5. **The gentleness.** The Fool can reassure her the note is hers to keep, or help her
   make peace with never fixing it. Either way she stops fighting it. What changes is not
   the note but her relationship to it.
6. **Closing.** Perpetua begins to sing her flat note *on purpose* — the smallest
   rebellion in the Chantry, and the first thing she has ever chosen to do with her own
   voice. [If WS_HIEROPHANT_UNBOUND: with hymns free to change, her note is no longer a
   flaw against a fixed perfection — just her voice — and she can sing it true if she
   wishes, or keep it flat because it's *hers*. She chooses, and the choosing is the whole
   point.]

Rewards, if any: a small rise in the local suit's Renown; optionally a cosmetic choir
token — nothing gated.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (either state) | none — NPC-level only | Perpetua's barks warm; she sings her note by choice. No `WS_*` flag is set; no other quest reads this outcome. |

## Consistency references

- `world.md` §The Chantry — the eternal single hour, doctrine-as-weather, choir acoustics
  carrying from every stone surface.
- `world.md` §World-state matrix (`WS_HIEROPHANT_UNBOUND`) — the post-unbinding variant
  only; this quest fires nothing.
- `docs/quests/main/MQ05-the-same-old-song.md` — the eternal hymn and its unbinding; this
  quest's flat note must sit inside MQ05's hymn without pre-empting the fight. Chorister
  Linnet there is a distinct singer from Perpetua.
- `characters.md` §Regional named NPCs — Sister Perpetua Vane (promoted in the parallel
  change).
- `narrative.md` §Themes (1, endings as mercy — the mistake as the proof of life),
  §Dialogue style guide (one laugh in the sad turn; Fool lines ≤ 12 words).

## Open questions

- Should Perpetua's flat note be the *same* hymn motif MQ05 uses, so a player who met her
  here recognizes the note during the boss approach (audio callback)? Recommend yes.
- Is the flat note diegetically audible to the player (an audio-design ask and an
  accessibility consideration), or established purely through dialogue?
