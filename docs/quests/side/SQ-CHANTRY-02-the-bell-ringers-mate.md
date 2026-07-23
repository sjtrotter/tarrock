---
id: SQ-CHANTRY-02
title: The Bell-Ringer's Mate
type: side
status: outline
arcana: none
region: The Chantry
requires: [WS_HIEROPHANT_UNBOUND]
fires: []
---

# SQ-CHANTRY-02 — The Bell-Ringer's Mate

## Introduction

When the Hierophant is unbound, the Chantry's bells learn new peals and the whole town
rejoices — except old Rennick Coombe, whose hands know only the one rhythm that has held
his entire life together, and shake trying to learn another. This is a quiet quest about
the cost of a good thing to the one person it was never good for. Sitting with him through
a single bad practice, without trying to fix him, turns out to be most of what actually
helps.

## Beats

1. **The hook.** With the bells free to change, the tower rings new songs — badly,
   joyfully, the town's shared delight. In the ringing-chamber, Rennick Coombe
   (characters.md §Regional named NPCs), the bell-ringer's mate whose hands know the old
   rope-changes better than his own name, cannot make them do the new peal. His hands keep
   defaulting to the three-hundred-year rhythm, the only thing his body has ever been sure
   of.
2. **Offices eat people (theme 2).** Rennick is the old hour made flesh — his whole self
   is that one rhythm. Asked who he is apart from it, he has no answer. The bell wore the
   man down to a pair of hands and a count.
3. **Freedom isn't wanted (theme 3).** Everyone treats the new peals as pure gift. To
   Rennick they are a small bereavement: the loss of the one certainty his body owned. He
   doesn't begrudge the town its joy — he simply cannot feel it, and is ashamed of that.
4. **The unhelpful help.** The Fool can drill him, correct him, push — and it only makes
   it worse, his hands seizing under the attention. The gentle comedy of everyone's
   well-meant advice making an old man's hands shake harder.
5. **The honest beat (and the actual help).** What works is not teaching but *staying* —
   sitting through one whole clumsy practice without fixing anything, letting Rennick be
   wrong and unwatched until his hands stop being afraid of it. The Fool's best line here
   is offered quietly; the earnest option is presence, not instruction (≤ 12 words).
6. **Closing.** Rennick rings the new peal — still rough, half a beat behind — but rings
   it. He keeps the old rhythm too, for himself, at dusk: both hands, both songs. [If
   CONFESSED: knowing what's coming, he says he'd sooner learn one new song badly than
   ring the old one perfectly into the end.]

Rewards, if any: modest coins; a small rise in the local suit's Renown.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Rennick rings the new peals (roughly); his barks shift from grief to tentative pride. No `WS_*` flag is set. |

## Consistency references

- `world.md` §The Chantry — cathedral-town, choir acoustics, doctrine-as-weather.
- `world.md` §World-state matrix (`WS_HIEROPHANT_UNBOUND`) — required; "the bells fall
  silent, then ring *new* songs" is the exact condition this quest lives inside.
- `docs/quests/main/MQ05-the-same-old-song.md` — the unbinding this follows; note MQ05's
  mourner Brother Tolliver grieves the same lost fixity from the choir side (see Open
  questions).
- `characters.md` §Regional named NPCs — Rennick Coombe (canon).
- `callings.md` — Bell-ringer's mate (post-MQ05: "learn *new* peals" — the change this
  quest dramatizes).
- `narrative.md` §Themes (2, 3), §Act II (`CONFESSED` variant), §Dialogue style guide
  (melancholy rule; presence over instruction; Fool lines ≤ 12 words).

## Open questions

- **Differentiate from MQ05's mourner.** Brother Tolliver (MQ05) and Rennick Coombe both
  grieve the lost certainty of the fixed hour. Recommend keeping them distinct: Tolliver
  grieves the lost certainty of *faith*, Rennick the lost certainty of the *body*
  (muscle-memory). Confirm they are two griefs, not one beat split across two quests.
- Should the new peal Rennick learns be the same composed motif as MQ05's aftermath
  (audio callback), so the town's "new song" is a single recognizable tune?
