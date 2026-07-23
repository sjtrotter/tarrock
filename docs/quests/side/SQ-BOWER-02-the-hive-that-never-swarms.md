---
id: SQ-BOWER-02
title: The Hive That Never Swarms
type: side
status: outline
arcana: none
region: The Bower
requires: []
fires: []
---

# SQ-BOWER-02 — The Hive That Never Swarms

## Introduction

Among the Bower's weeping orchards, an apiarist named Coraline Ashe keeps a hive she is
very proud of and quietly, deeply uneasy about. Her bees have not swarmed, foraged
further afield, or changed a single cell of their comb in three hundred years — perfect,
static, and faintly, unmistakably *wrong*. Rather than say aloud what she suspects, she
has built a loving little theory around them: her bees are simply *patient*. The player
can help her tend the hive and, gently, help her stop needing the theory. And if the
Empress is unbound, the quest pays off in the messiest, happiest scene the Bower has —
three centuries of held-still bees deciding, all at once, to go absolutely everywhere.

## Beats

1. **The hook.** At a sun-warmed row of skeps, Coraline Ashe (canon, `characters.md` §Regional named NPCs) welcomes the Fool with honey
   and a fond, well-worn lecture on the singular virtue of her "patient bees" — the calmest,
   most orderly colony in the whole Spread, she says, never a swarm, never a wander, not in
   living memory. She says *living memory* a little too carefully.
2. **The wrongness.** Helping her work the hive (a gentle, no-combat tending stretch,
   Pip kept respectfully clear) shows the Fool what Coraline will not name: the comb is
   identical cell to cell, the same bees on the same flowers, no brood, no growth, no
   change — a colony frozen exactly like the garden around it. It is beautiful and it is a
   held breath (theme 1). The bees are not patient. They are *stopped*.
3. **The complication.** Pressed even gently, Coraline defends the theory harder, because
   the theory is kinder than the truth: patient bees are a wonder; stopped bees are a
   grief she tends every morning with smoke and sugar-water. She has kept one experimental
   skep-box sealed for years — the one hive she has never quite dared to properly wake —
   because as long as it is closed, she never has to find out.
4. **The ache and the laugh.** The Fool can help her open the experimental box, argue her
   gently past the theory, or simply agree the bees are lovely and leave her the comfort.
   The laugh: Coraline has, over three centuries, developed extremely firm views on bee
   temperament that no living beekeeper could possibly confirm. The honest beat: she admits
   she has been afraid, all this time, that waking them would prove they were never really
   hers to keep — only the Stall's.
5. **[If WS_EMPRESS_UNBOUND] Everywhere at once.** Once the Empress is unbound and the
   Bower's abundance finally *moves*, Coraline's colony erupts into the region's giddiest
   moment — three hundred years of pent-up bees swarming, foraging, splitting, going every
   which way in a joyous chaos she chases around the orchard half-laughing, half-weeping,
   entirely undone. The garden, at last, is alive enough to be a nuisance. She has never
   been happier to be stung.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (any route, either timing) | none — NPC-level only | Coraline's future barks shift per whether the Fool woke the hive or left her the theory; post-`WS_EMPRESS_UNBOUND`, her colony becomes an ambient, busily-swarming Bower fixture. No `WS_*` flag is set; no other quest reads this outcome. |

## Consistency references

- `design/world.md` §The Bower — the overripe, unharvested garden and its faintly-wrong
  stillness; Coraline's hive is that stasis at the scale of a single colony.
- `design/world.md` §World-state matrix (`WS_EMPRESS_UNBOUND`) — harvests and the Bower's
  abundance finally moving, the event the post-unbinding swarm beat (5) rides on.
- `design/characters.md` §Regional named NPCs — Coraline Ashe (canon), the apiarist
  this quest promotes.
- `design/characters.md` §III. The Empress — the region's abundance-as-suffocation
  character (the Empress herself does not appear here).
- `design/narrative.md` §Themes (1, "endings are a mercy; a thing that cannot change
  cannot live") — the stopped hive as the Bower in miniature.
- `design/narrative.md` §Dialogue style guide — the melancholy rule (one laugh in the sad
  scene, beat 4) and Fool lines ≤ 12 words with an earnest option.

## Open questions

- Reward: leave NPC-level, or hand the Fool a jar of the ("finally real") honey as an
  Almanack curio / minor consumable? Keep to legal rewards (coins / cosmetic) — recommend
  flavor-only.
- The gentle no-combat tending stretch overlaps in feel with the Bower Farmhand Calling
  and with SQ-BOWER-01's row-work; confirm the two quests read as distinct activities at
  greybox (bees vs. wheat) rather than the same loop reskinned.
- Whether the pre-unbinding "open the experimental box" route should have any small effect,
  or is deliberately anticlimactic (the box's bees are just as stopped) until the Empress
  falls — recommend the latter, so the swarm is earned only by the unbinding.
