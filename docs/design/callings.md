# Callings — SSOT

Owns: the Callings system — the repeatable, mundane roles the world offers the Fool.
Region facts live in [`world.md`](world.md); bark machinery in
[`npc-system.md`](npc-system.md); Renown rules in [`progression.md`](progression.md);
the theme this system exists to play in [`narrative.md`](narrative.md).

## The idea (and why it's load-bearing)

The Spread doesn't only need saving — it *wants company*. A Calling is a real, ordinary
job the Fool can simply… do. Shelve books. Cut wheat. Pole a ferry. Ring the hour. Not
a minigame wearing a quest's clothes: a repeatable role with a small honest loop, taken
up at a workplace and set down whenever, forever.

This is the game's central tension made playable. A world that cannot end is a
*comfortable* world — that comfort is the Devil's entire argument (arcana.md §XV), the
Stall's seduction, and the Refusal ending's substance. The main quest says *finish it*;
a Calling says *stay*. Letting the player genuinely live inside that temptation — be a
librarian for an evening or for forty hours — is worth more than any dialogue about it.
(Design inspiration: the "live as a peasant in Skyrim" school of play. We don't fight
that impulse; we build for it.)

## Rules of the system

1. **Every Calling is opt-in, repeatable, and endless.** Walk up to the post, take the
   role, do the loop as long as you like, walk away. No fail states, no timers, no
   quest log entry nagging completion. The Almanack records it under "Days Lived," not
   objectives.
2. **The loop is small and honest** — one core interaction per Calling (see table),
   tuned to be gently absorbing rather than demanding. Think rhythm-of-work, not
   score-chase.
3. **It pays like work, not like adventure.** A modest coin wage, a slow trickle of the
   local suit's Renown, and Calling-specific barks. Never gear, never Trumps, never
   gated content — a Calling must tempt with *life*, not loot, or the metaphor dies.
4. **The world starts treating you as the role.** After enough sessions (tracked
   per-Calling), NPC greetings shift via a bark layer (npc-system.md): "morning,
   librarian" replaces "it's the Fool!" The world *forgetting what you are* is the
   temptation made audible. Named NPCs at the workplace develop workplace-memory lines.
5. **Each role has an outfit** (cosmetic, per progression.md's rule) earned by
   practicing it. Wearing it off-duty gets you addressed as the role elsewhere.
6. **The Querent notices.** Light, warm needling at first ("Comfortable, little
   Excuse?" — deliberately the Hanged Man's question). The Querent never blocks or
   scolds; per the Refusal's design, staying is always respected. One aside per
   N sessions, no more — the temptation must be allowed to actually work.
7. **Act III turns Callings poignant.** Same loops, new barks: doing ordinary work in a
   world that knows it's ending is the elegy of the whole game in miniature. A player
   who spends Act III farming has understood the game, not missed it.
8. **State interactions are honored**: a Calling whose fiction depends on the region's
   stasis changes or retires when its Arcana is unbound (table notes), replaced where
   possible by its living-world successor.

## The Callings (one per region minimum; drafts — tune at content pass)

| Region | Calling | The loop | Notes / world-state |
|---|---|---|---|
| The Prestige | Stagehand | Set props, pull ropes on cue during the show | Post-MQ01: becomes market porter (`WS_TROUPE_SETTLED`) or troupe roadie (`WS_TROUPE_TRAVELING`) |
| The Veil | Under-librarian | Shelve returned volumes by suit/number; hush violators | Post-MQ02: new books actually arrive |
| The Bower | Farmhand | Scythe-work rows of wheat; stack sheaves | Pre-MQ03 nothing may be *finished* being cut — the row regrows behind you (play the futility); post: real harvests |
| The Bastion | Junior clerk | Stamp writs to the gong-rhythm | Post-MQ04: stamping requires *judgment* (rules changed) |
| The Chantry | Bell-ringer's mate | Ring the changes on cue | Post-MQ05: learn *new* peals |
| The Divide | Ferry hand | Row the gossip ferry; balance passengers | Post-MQ06: bridge tollkeeper instead |
| The Longroad | Waystation keeper | Sweep, refill lanterns, greet travelers | Post-MQ07: fast-travel arrivals to welcome |
| The Maw | Shepherd | Herd goats to pasture with Pip | Pip's favorite Calling (canon) |
| The Dim | Lamplighter | Walk the dusk routes lighting wicks | Post-MQ09: fewer lamps needed — shorter, sadder round |
| The Wheelhouse | Croupier | Deal a simple honest table game | Post-MQ10: odds actually vary |
| The Assize | Queue-warden | Keep the knitting queues in order; fetch tea | Post-MQ11: usher for real hearings |
| The Gallowwood | Rope-checker | Inspect and re-knot canopy lines | Post-MQ12: right-way-up trail warden |
| The Stillmarsh | Ferryman's mate | Pole Old Sallow's lantern route | Post-MQ13: the route means something else; Sallow says so |
| The Confluence | Mixer's apprentice | Pour-and-temper repeating orders | Post-MQ14: orders can be *finished* |
| The Undervault | Vault-teller | Weigh and ledger deposits | The most comfortable Calling in the game — on purpose |
| The Spire | Bell-watch | Watch the lightning bell; log strikes | Post-MQ16: storm-spotter for real weather |
| The Mere | Wish-tender | Trim wicks on the wish-lights | Doing MQ17's vigil forever, by choice |
| The Mirrormarsh | Fog-warden | Walk the rope-line; guide the lost out | Post-MQ18: guide them *home* instead |
| The Noonlands | Harvest hand | Sheaf-toss at the eternal festival | Post-MQ19: seasonal — the first *last* harvest |
| The Hollows | Groundskeeper | Tend plots, water, weed | Gated with the region; post-MQ20: gardener of the bloom |
| The Axis | — | The Axis offers no Calling. The center has exactly one job, and it is taken. | |

## Sub-systems it leans on

- **Bark layers** (npc-system.md): Callings add a per-role greeting pool and a
  workplace-rumor pool; role-recognition inserts above renown greetings, below
  world-state barks.
- **Renown** (progression.md): wage Renown accrues to the region's dominant suit;
  capped per in-game day so Callings never out-earn play.
- **Almanack**: a "Days Lived" page — sessions per Calling, small hand-drawn stamps.
  No percentages, no checkmarks. It is a diary, not a checklist.

## Open questions

- Session definition (an in-game day? a fixed loop count?) — tuning at implementation.
- Whether two Callings can be "held" simultaneously (proposed: no — one at a time,
  switching is free; holding one is part of the fantasy).
- Minimum viable loop interactions at M-milestone scope: the table's 21 loops range
  from trivial (lamplighter) to systemic (croupier); a scoping pass must pick the 5-6
  that ship first, favoring regions in the vertical slice's path.
