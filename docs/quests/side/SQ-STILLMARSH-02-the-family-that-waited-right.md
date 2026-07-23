---
id: SQ-STILLMARSH-02
title: The Family That Waited Right
type: side
status: outline
arcana: none
region: The Stillmarsh
requires: [WS_DEATH_UNBOUND]
fires: []
---

# SQ-STILLMARSH-02 — The Family That Waited Right

## Introduction

A post-unbinding grief piece, available only once the Fool has returned mortality to the
world (`WS_DEATH_UNBOUND`). One Stillmarsh family, the Hallows, have kept vigil over
their deathless great-grandmother for generations, taking shifts, sure their patient
presence somehow eased her endless "nearly dying." Now she can finally die — and does,
gently, exactly as everyone always said she would. The quest makes no attempt to soften
what follows. It only makes sure the Fool is present for it, which Old Sallow insists is
the whole job. It deliberately echoes the register of MQ13's Bettony Marsh beat with a
different family and a different weight — an echo, not a retread.

## Beats

1. **The turn.** With mortality returned, the Stillmarsh is quietly emptying (`world.md`
   §World-state matrix). At the Hallows' waterside house, the family's great-grandmother
   — vigil-kept for three centuries by a rota that has outlived four generations of the
   people keeping it — dies in her sleep the very night the Fool comes to call.
2. **The prepared and the unprepared.** The Hallows have rehearsed this loss for 300
   years. They discover, to their own astonishment, that no amount of preparation makes
   the actual grief any smaller — the rehearsal was never for this, only for the waiting.
3. **The Fool's part.** There is nothing to fix and nothing to fetch. Old Sallow, poling
   past, says it plainest: being here is the whole job, and the Fool is already doing it
   by not leaving. The Fool's dialogue stays small and earnest (≤12 words, one earnest
   option) — presence, not counsel.
4. **The laugh in the sad scene.** One Hallow confesses, mortified and half-laughing
   through it, that the family always privately suspected the old woman was drawing out
   her "nearly dying" on purpose, to keep them all coming round. And true to form she has
   left instructions for a funeral tea so fussily specific it can only be spite from
   beyond — steeped just so, served in the third-best cups, on the good side of the
   house. The tone bar's laugh, delivered posthumously.
5. **The vigil becomes a wake.** The shifts the family kept for centuries fold, without
   anyone deciding it, into a wake — the same room, the same rota, a different purpose.
   They do not need the Fool to stay, and are grateful the Fool came.
6. **Closing beat.** The Fool leaves them to it. The quest resolves none of their grief;
   it refuses, on purpose, to let relief and loss settle into one clean feeling. It only
   witnessed — and per the Stillmarsh's whole character, witnessing kindly is enough.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | The Hallow house shifts from vigil to wake barks; the family become recurring mourners then settled residents; no `WS_*` flag is set and no other quest reads this outcome. |

## Consistency references

- `world.md` §The Stillmarsh; §World-state matrix (`WS_DEATH_UNBOUND`: mortality returns,
  scripted-only deaths, funerals as ambient events, Stillmarsh empties over days).
- `characters.md` §Recurring named NPCs (Old Sallow — "being present is the whole job"
  is his register from MQ13); §Pip (constancy; the family's grief never touches Pip).
- `quests/main/MQ13-an-ending.md` §Beats 7, 17 & §Mourning — the Bettony Marsh / Gaffer
  Corlin beat this quest echoes; reviewer confirms this reads as a companion, not a copy
  (distinct family, generational vigil, the funeral-tea laugh in place of the note).
- `narrative.md` §Themes 1 & 3 (endings are a mercy; freedom hurts someone ordinary —
  shown, not resolved); §Dialogue style guide (melancholy rule; Fool's ≤12-word rule).

## Open questions

- The great-grandmother is intentionally left unnamed (an unnamed walk-on within the
  named Hallow family) to avoid coining a new named NPC beyond the slate's. Confirm she
  stays a kinship-only figure, or promote her with a given name in `characters.md` if the
  funeral beat wants one to carry it.
- Reward: recommend none material — a keepsake cosmetic (a Hallow mourning-ribbon) at
  most, per `progression.md`. The witnessing is the point; confirm.
- Trigger timing: fixed number of in-game days after `WS_DEATH_UNBOUND`, or fired on the
  Fool's next visit to the Stillmarsh? (Mirrors MQ13's own open question about Gaffer
  Corlin's death — resolve both the same way for consistency.)
