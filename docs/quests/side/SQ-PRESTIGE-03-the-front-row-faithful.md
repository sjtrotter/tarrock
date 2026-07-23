---
id: SQ-PRESTIGE-03
title: The Front-Row Faithful
type: side
status: outline
arcana: none
region: The Prestige
requires: []
fires: []
---

# SQ-PRESTIGE-03 — The Front-Row Faithful

## Introduction

In the grand tent's third row sits Mags Dellow, who has watched every single showing for
three hundred years from the same seat — and unlike the packed benches around her, she is
not quite stuck. She can recite Wicke's patter better than he can, corrects him under her
breath, and swears blind that she once saw the Bataleur *almost* break character, on a
Tuesday that never came round again. The player can find her before the Magician is
unbound and simply sit with her a while; the quest's real weight, though, lands after
MQ01, when the audience finally rises and disperses and Mags is the last soul still
sitting, blinking at empty benches with nowhere she has ever actually chosen to be
instead. The ache is real. So is the stubborn, funny way she eventually stands up anyway.

## Beats

1. **The hook (pre-unbinding).** Mags Dellow (canon, `characters.md` §Regional named NPCs), a sharp-eyed woman in a good coat gone soft
   with age, waves the Fool into the empty seat beside her and mouths the Bataleur's
   whole routine a half-second ahead of him, note-perfect, like scripture she has by
   heart. She is warm, dry, and unmistakably *choosing* to be here, in a tent where no one
   else chose anything.
2. **The Tuesday that never came.** Asked why this seat, Mags deflects into her one
   treasured story: the night, centuries ago, she is *certain* she caught the Bataleur
   nearly laughing — a crack in the perfect trick, a Tuesday the show never repeated.
   The laugh in the scene: she has argued herself hoarse about it with neighbours who
   cannot remember their own names. The honest beat underneath: she is afraid to ask what
   made *her* stay awake in a tent that put everyone else to sleep.
3. **The thing she won't examine.** Light optional digging (barks from the audience
   regulars, a word from Flick) establishes what Mags will not: she was not caught by the
   Stall the way the others were. Something in her chose this bench and has been guarding
   the choice ever since, because a chosen seat is a life she would then have to answer
   for. The quest never forces the answer out of her.
4. **[If WS_MAGICIAN_UNBOUND] The empty tent.** When the show ends and the crowd rises in
   its long ragged wave (MQ01), Mags does not. The Fool finds her alone on the third-row
   bench, the benches around her emptying by the hour, staring at a stage that has, for
   the first time in three centuries, nothing left to show her. This is theme 3 in one
   image: the unbinding everyone celebrates has taken the one thing she built a life on.
5. **The ache and the laugh.** The Fool can sit, or offer a hand, or simply wait; the
   quest gives Mags no fix and forces no epiphany. What it does give her is a witness. She
   grumbles that she was perfectly comfortable, thank you, that nobody *asked* her to be
   liberated — and then, complaining the whole way, she stands, knees cracking like
   everyone else's, and walks out into a Prestige she will now have to choose her way
   across. The joke and the grief are the same gesture.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (post-`WS_MAGICIAN_UNBOUND`) | none — NPC-level only | Mags leaves the tent and becomes an ambient Prestige fixture whose barks shift from reciting the old show to wryly navigating a life she now has to pick for herself. No `WS_*` flag is set; no other quest reads this outcome. |

## Consistency references

- `design/world.md` §The Prestige — the audience that cannot leave its seats; Mags is
  written as the deliberate exception to it.
- `design/world.md` §World-state matrix (`WS_MAGICIAN_UNBOUND`) — the show ending and the
  crowd dispersing "over in-game days," the event the payoff beats hang on.
- `design/characters.md` §Regional named NPCs — Mags Dellow (canon), the lifelong
  audience member this quest promotes.
- `design/characters.md` §Flick — used only as an optional corroborating voice in beat 3.
- `design/narrative.md` §Themes (3, "freedom isn't wanted by everyone; every unbinding
  hurts someone ordinary — show them, don't resolve them") — Mags is that ordinary cost,
  and the quest honors the rule by refusing to resolve her.
- `design/narrative.md` §Dialogue style guide — the melancholy rule (one laugh in the sad
  scene, beat 5) and Fool lines ≤ 12 words with an earnest option.

## Open questions

- Gating: the premise is "post-unbinding, playable pre as setup," so this outline uses
  `requires: []` with the payoff (beats 4–5) gated on `WS_MAGICIAN_UNBOUND` firing. Decide
  at script status whether to keep the pre-unbinding setup (recommended — it earns the
  ending) or hard-gate the whole quest on the flag and lose the setup.
- Mags visibly parallels Wren (the unaged girl seeded in MQ01) and Ferridge (MQ01's
  mourner). Decide whether the three should share a bark cluster or stay independent so
  the "same audience, 300 years" image isn't over-pressed.
- Whether Mags gets a small keepsake to hand the Fool on standing (a worn program, a
  ticket stub) as an Almanack curio, or stays purely NPC-level.
