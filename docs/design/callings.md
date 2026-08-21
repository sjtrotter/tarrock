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
   objectives. **One Calling at a time:** taking up another sets the first down;
   switching is free, and holding one is part of the fantasy. **The tools are the
   workplace's.** The scythe, the bell-rope, the ledger stay at the post; what the Fool
   carries is the Bindle and its unfoldings ([`combat.md`](combat.md) §Unfoldings) —
   their own few things, never a trade's.
2. **The loop is small and honest** — one core interaction per Calling (see table),
   tuned to be gently absorbing rather than demanding. Think rhythm-of-work, not
   score-chase.
3. **It pays like work, not like adventure.** A modest coin wage, a slow trickle of the
   local suit's Renown, and Calling-specific barks (see **Shifts, wages, and the day**).
   Never gear, never Trumps, never gated content, never an unfolding — a Calling must
   tempt with *life*, not loot, or the metaphor dies.
4. **The world starts treating you as the role.** After enough shifts (tracked
   per-Calling), NPC greetings shift via the role-recognition pool in bark layer 5
   ([`npc-system.md`](npc-system.md) §Bark layers): "morning, librarian" replaces "it's
   the Fool!" The world *forgetting what you are* is the temptation made audible. Named
   NPCs at the workplace develop workplace-memory lines through their ordinary per-NPC
   memory flags.
5. **Each role has an outfit** (cosmetic, per progression.md's rule) earned by
   practicing it. Wearing it off-duty gets you addressed as the role elsewhere.
6. **The Querent notices.** Light, warm needling at first ("Comfortable, little
   Excuse?" — deliberately the Hanged Man's question). The Querent never blocks or
   scolds; per the Refusal's design, staying is always respected. One aside per
   N shifts, no more — the temptation must be allowed to actually work.
7. **Act III turns Callings poignant.** Same loops, new barks: doing ordinary work in a
   world that knows it's ending is the elegy of the whole game in miniature. A player
   who spends Act III farming has understood the game, not missed it.
8. **State interactions are honored**: a Calling whose fiction depends on the region's
   stasis changes or retires when its Arcana is unbound (table notes), replaced where
   possible by its living-world successor.

## Shifts, wages, and the day

The clock is [`world.md`](world.md) §Time's — it runs from the Fool's first step whether
or not the sun has been freed — and a Calling counts against it:

- **A shift is one in-game hour at the post** — one real minute of work. It is the
  session unit everywhere: the Almanack stamps shifts, role-recognition thresholds and
  the Querent's aside cadence count shifts, outfits are earned by shifts.
- **Each loop pays Coins** (the wage; [`progression.md`](progression.md) §Currency).
  **Each shift pays Renown** — a *slight up*, in [`progression.md`](progression.md)
  §Renown's terms — to the region's dominant suit, through the ordinary Renown path.
  Renown from a Calling is **capped per day of play** (twenty-four game hours worked
  through; tuning target three shifts' worth; a Waystation rest sleeps the world forward
  but not this cap), so a day's work is felt and a week's is not a strategy. Coins are
  not capped — the wage is modest by design.
- Leaving mid-shift keeps the loops' Coins and forfeits the shift's Renown. Nothing is
  ever lost that was already paid.
- Walking away, being attacked, or taking up another Calling sets the role down. A
  bound region's held hour does not stop a shift: the clock runs underneath the stalled
  sun, and the Bower's farmhand can work an "hour" under a noon that never moves.

## Loop archetypes (five behaviours, twenty-one roles)

Every Calling in the table below is built from five loops. A role names its archetype —
most one, a few (the Stagehand, the Farmhand, the Junior clerk) a primary and a secondary
they alternate between — and supplies data: targets, cues, routes, fixtures, never a new
behaviour. A Calling that needs a sixth is a design change here first.

| Archetype | The loop | Roles |
|---|---|---|
| **Swing-at-targets** | Targets stand in the world; the work verb hits the nearest; they replenish. A bound region's variant replenishes instantly behind you. | Farmhand, Groundskeeper |
| **Cue-rhythm** | A cue arrives (gong, stage call, peal); act in the window; a miss earns a bark, never a failure. | Junior clerk, Bell-ringer's mate, Stagehand (the ropes), Bell-watch |
| **Carry-and-place** | Take from where it is, walk, set down where it is wanted; the supply is endless. | Under-librarian, Stagehand (the props), Queue-warden, Harvest hand, Farmhand (the sheaves) |
| **Walk-the-route** | An ordered set of stations along a path; act at each; the route's length is the world-state knob (the Dim's round shortens). | Lamplighter, Rope-checker, Fog-warden, Waystation keeper, Wish-tender, Ferryman's mate |
| **Station-operate** | Stand at a fixture; a small repeating choice with a right answer. Feet planted; the fixture hides the lower body. | Vault-teller, Croupier, Mixer's apprentice, Ferry hand, Junior clerk |

The Shepherd is the one role that is not a loop node: it herds with Pip, and which of
Pip's commands that is belongs to [`combat.md`](combat.md) §Pip (**TBD** there); it ships
when Pip's commands do.

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

- **Bark layers** (npc-system.md §Bark layers): Callings add a per-role greeting pool and
  a workplace-rumor pool; where role-recognition sits in the order is that doc's.
- **Renown** (progression.md): paid per shift and capped — see **Shifts, wages, and the
  day**.
- **The clock** (world.md §Time): shifts and the daily cap count against the day that
  runs from the first step; the stalled sun is no obstacle to an honest hour's work.
- **Almanack**: a "Days Lived" page — shifts per Calling, small hand-drawn stamps.
  No percentages, no checkmarks. It is a diary, not a checklist.
- **Unfoldings** (combat.md §Unfoldings) are the other side of the line: the Fool's own
  tools go everywhere with them; a Calling's tools never leave the post.

## Open questions

- First-ship set: the table's 21 loops range from trivial (lamplighter) to systemic
  (croupier); a scoping pass must pick the 5–6 that ship first, favoring regions in the
  vertical slice's path. Proposal: one per archetype on the MQ01–MQ10 path — Stagehand,
  Farmhand, Under-librarian, Bell-ringer's mate, Lamplighter, Croupier.
- The work verb's input: proposal is that `interact` takes up and sets down the role and
  the light-attack input is the work verb while it is held, with dodge cancelling — no
  new action in the input map. Decided at the Callings round (`technical.md` §Input
  actions).
- The exact thresholds — shifts to an outfit, shifts to role-recognition, the Querent's
  N, the daily Renown cap — are tuning targets, set once a Calling is playable.
