---
id: SQ-PRESTIGE-02
title: The Barker's Bet
type: side
status: outline
arcana: none
region: The Prestige
requires: []
fires: []
---

# SQ-PRESTIGE-02 — The Barker's Bet

## Introduction

Somewhere off the main midway, past Flick's rope line, a second barker is working a
crowd that never leaves — and he is emphatically *not* Flick. Old Cutter Voss has spent
three hundred years insisting that his strongman sideshow, not the grand tent, is the
Prestige's real main event, and he will challenge any passerby to prove otherwise at his
own game. A stranger with a dog will do nicely. The catch the player uncovers is that
Voss's signature feat is rigged, and Voss has long since forgotten how he rigged it — so
winning the bet *honestly* means working out the gimmick first, all while Flick heckles
from the sidelines and refuses, on principle, to shut up. It is a small, silly,
decades-deep grudge match with real affection underneath it. Playable before or after
MQ01 ("The Greatest Trick"); if the Magician is already unbound, the whole carnival is
coming down around the contest, and the wager quietly changes shape.

## Beats

1. **The hook.** Old Cutter Voss (canon, `characters.md` §Regional named NPCs), a barrel-chested rival barker in a coat even louder than
   Flick's, plants himself in the Fool's path beside a brass test-your-might rig and a
   platform of prop weights. He bets the Fool cannot out-showman him at his own signature
   feat — the Unliftable Anvil, which no volunteer has budged in three centuries. Flick
   drifts over to spectate the instant a wager is mentioned, delighted.
2. **The complication.** The feat is gimmicked, and Voss genuinely cannot remember how —
   three hundred years of running the same rig has worn the how of it clean out of his
   head, leaving only the certainty that it works. Winning by brute force is impossible
   by design; winning *honestly* means finding the trick. Pip noses at the platform's
   base and whines at a seam, exactly as he does anywhere the world is hiding a join.
3. **The gimmick.** A small mechanical puzzle under the platform — a foot-pedal catch, a
   counterweight run, a pin that seats the anvil to the boards — echoes MQ01's
   under-stage reveal in miniature without repeating it. Solving it lets the Fool beat
   the feat cleanly, throw the match on purpose, or spring the rig in front of the crowd.
4. **The ache and the laugh.** Between rounds, Voss and Flick trade three hundred years
   of the same barbs, and it lands slowly that the rivalry is the closest friendship
   either man has. The honest beat inside the comedy: pressed, neither can quite recall
   what he was, or did, before he was the other one's rival. The bit *is* the life.
5. **Resolution (pre-unbinding).** However the Fool settles the bet — win, throw it, or
   expose the rig — the outcome is barks-level: Voss's greetings warm or sulk, Flick
   crows regardless, and a modest purse changes hands per the wager. Nothing about the
   grudge is settled, which is exactly how both of them want it.
6. **[If WS_MAGICIAN_UNBOUND]** Packing his stall into crates, Voss admits the thing he
   never would over three centuries of showtime: he never once beat Flick honestly
   either — the whole rivalry was theatre too, a bit they kept running because it gave
   the endless days a shape. He hands the wager over as a keepsake rather than a prize,
   and the two part, at last, as the friends they always were.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Bet settled (any route) | none — NPC-level only | Voss's and Flick's future barks shift per the route taken; a modest coin purse and/or a scrap of Wands Renown change hands (carnival spectacle is Wands-flavored, `progression.md`). No `WS_*` flag is set and no other quest reads this outcome. |

## Consistency references

- `design/world.md` §The Prestige — the perpetual-showtime carnival and its captive
  crowd, the staging the whole grudge plays out against.
- `design/world.md` §World-state matrix (`WS_MAGICIAN_UNBOUND`) — the "carnival packs
  up over in-game days" timeline the post-unbinding variant (beat 6) rides on.
- `design/characters.md` §Flick — his established barker's patter and role as the Fool's
  first friendly Prestige face, used here as heckling scene-partner, not quest-giver.
- `design/characters.md` §Regional named NPCs — Old Cutter Voss (canon), the rival
  barker whose feat and friendship this quest promotes.
- `design/callings.md` §The Callings (Stagehand) — Voss's rig is a natural doorway to the
  Stagehand Calling (props, ropes, cues) without duplicating that loop.
- `design/narrative.md` §Dialogue style guide — the melancholy rule (one honest beat in
  the comedy, beat 4) and Fool lines kept ≤ 12 words with an earnest option.
- `design/progression.md` §Renown, §Currency — reward kept to legal coins / Renown.

## Open questions

- Exact reward: a coin purse, a scrap of Wands Renown, or a cosmetic barker's sash
  (cosmetic-only per `progression.md`) — pick one at the content pass; recommend coins
  plus a token Wands bump so the "spectacle" theme reads without a stat trap.
- Should Voss recur alongside the Troupe in both MQ01 branches (touring vendor under
  `WS_TROUPE_TRAVELING`, market fixture under `WS_TROUPE_SETTLED`), given how tightly
  his arc is bound to Flick's?
- Is the under-platform puzzle better as an observation read (spot the seam, like the
  House of Mirrors) or a small physical linkage puzzle? Recommend the latter to avoid
  re-teaching MQ01's tell.
