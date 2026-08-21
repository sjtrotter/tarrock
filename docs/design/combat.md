# Combat — SSOT

Owns: the player combat kit, enemy design (the Blanks and other families), encounter and
boss-fight philosophy, difficulty modes, and accessibility. Trump power *content* (what
each Arcana's Present/Past/Future effects actually do) belongs to
[`arcana.md`](arcana.md) — this doc only covers how Fortune is earned and spent in a
fight. The equip system (staff heads, Rose graftings, respec) belongs to
[`progression.md`](progression.md) — mentioned here only where it touches the moveset.

## Philosophy

Tarrock is **real-time action combat in the 2D top-down grammar — never turn-based** —
readable and deliberate: Fable's rhythm, not a character-action mash. The form is the one
`GDD.md` §Theme / Setting / Genre states: oblique top-down, with side-view sequences as punctuation; the
combat rules below are written for that grammar and do not change inside a side-view
sequence. (Boss docs sometimes describe an enemy's "rota," "beat," or "bell" — those are
telegraphed real-time attack rhythms the player reads and answers live, not turn-taking.)
Every enemy telegraphs before it commits; every player action
has a clear windup, a clear active frame, and recovery the player can feel. There is no
combo-counter, no style meter, and no button-mash reward loop: pressing more buttons
faster never beats pressing the right button at the right time. Lock-on is available but
optional — outside Focus the game assists target tracking without forcing a hard-lock, so
fights against multiple Blanks stay legible without the player having to hold a stance to
stay alive.

The measure of a good Tarrock fight: a player who has never played it before can *watch*
a skilled player fight and understand what happened. Nothing is hidden in numbers.

## The Bindle: player moveset

The Fool's only weapon is **the Bindle** — a traveler's bundle lashed to a quarterstaff,
unfolded into a fighting staff (and, once the Fool knows the knot, into its
**unfoldings** — see below). One weapon for the whole game keeps the moveset legible
and lets every new Trump and staff head read as a variation on a form the player already
knows, rather than a new weapon to relearn.

| Action | Description |
|---|---|
| **Light string** | Three-hit staff combo, fast and precise. The Fool's default answer to single targets and openings. |
| **Heavy** | Wide crowd sweep — the bundle end drags through the strike, hitting everything in an arc. Answer to groups. |
| **Charged heavy** | Held heavy attack; releases into the **stagger launcher** — the target is lifted off its feet into a brief helpless stagger that opens bonus follow-ups. The opener the launcher always was, without an aerial moveset. |
| **Running attack** | A forward lunge strike, closes distance and interrupts. |

**No aerial moveset.** In the top-down grammar there is no jump verb and nothing to
attack from mid-air; vertical play belongs to the side-view sequences (see **Traversal in
the top-down grammar** below). The stagger launcher gives the opener a launcher gives —
a helpless window and a follow-up — on the ground plane, where it stays readable.

**Staff heads**, found or bought across the Spread, swap onto the Bindle and lightly
retune this moveset (reach, a different heavy shape, an elemental tag) rather than
replacing it — full detail, list, and acquisition is owned by
[`progression.md`](progression.md).

### Unfoldings

The Bindle unfolds into more than a staff. A traveler's bundle is everything its owner
needs, and the Fool's turns out to hold exactly that: pull the right knot and the sack
cinches into a lantern; pull another and it shrinks to a bobber while the cord pays out
from the staff's tip as a line. These are the Fool's **unfoldings** — their own few tools,
as distinct from a Calling's, which belong to the workplace and stay there
([`callings.md`](callings.md)). The card carries it: the Fool's bundle is the provision
they already carry without knowing it.

| Unfolding | The knot | What answers it |
|---|---|---|
| **Lantern** | Pull the knot's tail; the sack cinches into a lamp and the staff is its pole — the Fool, for a moment, a small Hermit. The light is the bag itself. | Anything that wants a flame: the dark (the Undervault, every night once `WS_SUN_UNBOUND` has fired, the ground at the Fool's feet on the Dim), unlit wicks and braziers, and whatever a region declares burnable — a dry thicket, a cobweb, a seal of wax. The burnable list is each region's to author and is **TBD** per greybox. |
| **Rod** | The sack shrinks to a bobber; the cord string-ifies off the staff's tip; the Fool fly-casts with the staff itself. | Any water's edge. Bound water does not bite — nothing in it has moved for three hundred years — so a region's fish arrive with its unbinding. |
| Further unfoldings | **TBD.** A pipe is the leading candidate (busking in squares; Renown to Wands by the craft deed, `progression.md` §Renown); one region-specific find is wanted. | |

Rules:

- **Once learned, usable anywhere, always.** An unfolding is never gated by place or
  state; the *world* decides what answers it. A lantern lit at noon in the Noonlands is
  simply a lantern lit at noon. Whatever it touches that can take a flame, takes it.
- **Unfoldings are verbs, not growth.** None does combat damage, retunes the moveset, or
  changes a number; [`progression.md`](progression.md)'s three growth vectors stay three.
  A lantern lights and burns what the world says is burnable; it is not a torch attack.
- **A light, never a true light.** The lantern unfolding is a traveler's lamp: it does
  not count for the Mirrormarsh's gate ([`world.md`](world.md) §Hard and soft gates),
  reveals nothing Trump IX reveals ([`arcana.md`](arcana.md) §IX), and on the Dim it
  lights the ground at the Fool's feet and nothing of the way — the Hermit's light stays
  on the next ridge.
- **The staff is always one pull away.** Any attack input, Focus, or a hit taken snaps
  the Bindle back to its fighting form in one motion. Nothing is dropped, and the
  unfolding is one press away again afterwards.
- **Staff heads stay on the stick; unfoldings happen to the sack and the knot.** The
  lantern form still wears its head above the cinched bag.
- **No Arcana hands one over.** An unfolding is knot-craft, not a Trump: the Bindle has
  always been able to do this; the Fool just had not found the knot. How each knot is
  learned is **TBD** — the lean is found in the world or shown by a Minor, never by a
  Major, and never as a Calling's reward ([`callings.md`](callings.md) rule 3).
- **There is no spade unfolding.** Finding what is hidden is Pip's (§Pip, Seek) and
  stays his; a Calling's spade is the workplace's.
- The Hermit rhyme — a figure with a lamp on a staff — is deliberate, and licensed for
  one bark on the Dim ([`npc-system.md`](npc-system.md)), not an accident to design
  around.

## Focus (stance and targeting)

Combat maneuvering lives inside a held **Focus** stance (hold the focus input —
OoT-style Z-targeting grammar): the Fool drops into a readable ready-crouch, locks onto a
target when enemies are present, and movement becomes **8-direction strafing around that
target** — the Fool keeps facing the target while circling, backing off, or closing.
Focus is what separates *traveling* from *fighting*:

- **In Focus, the dodge input is directional:** forward or neutral = the dodge roll
  (below); left/right = a strafing side-hop; backward = a backflip. All directional
  dodges share the roll's i-frame rules and can trigger Fool's Chance.
- **Out of Focus, the same input is the plain roll** — a travel dodge, nothing more.
  There is no jump verb: ledge drops are contextual (walk off a marked ledge and the Fool
  drops), and true vertical play lives in the side-view sequences.
- **The grand backflip is the Focus back-dodge**: the backward dodge is performed as a
  high, deliberately *majestic* flip — taller than any other evasion, carrying the Fool
  roughly 1.5 body-widths back, finished with an emphatic landing. It is theater as much
  as evasion (the crouched-jump version is gone with the jump verb; the flourish
  survives here), and a natural candidate for the learned-skill pool below.
- Advanced maneuvers beyond the base roll (the backflip and later additions) may ship
  as **learned skills** rather than defaults — taught in the world (a move teacher or
  similar), not necessarily Trump-granted. Acquisition model: **TBD**, to be settled in
  [`progression.md`](progression.md) before any skill is gated.

## Traversal in the top-down grammar

The 2D form resolves the old **climb-lite TBD**: there is no climbing verb.

- **Elevation reads on the ground plane.** Terraces, ledges, ramps, and drops are level
  design the player walks — the "climbable but punishing ridges" `world.md` soft-gates by
  are *routes* (longer, more exposed, guarded) rather than a stamina minigame. The
  terrain grammar is unchanged: **true cliffs always refuse** (`art-audio.md` swap rule
  5), and free-climbing was and remains ruled out — it would dissolve every geographic
  gate in `world.md`.
- **Drops are contextual.** Walking off a marked ledge drops the Fool; nothing is
  climbed back up that the level design did not provide a way up for.
- **Scripted climbs stay set-pieces**, not a verb: the Emperor colossus (taught in
  miniature in MQ04) and the Spire ascent are authored sequences — both on the canon list
  of side-view sequences owned by [`world.md`](world.md) §Side-view sequences.

### Overturn in 2D

The Hanged Man's Trump is the one power whose meaning is tied to the gravity axis; the
effect itself is owned by [`arcana.md`](arcana.md) §XII, and this is only how the 2D
grammar expresses it.

- **Upright feather-fall** (the Past slot's "traversal headline", owned by
  [`arcana.md`](arcana.md) §XII, which states its top-down reading) is a real traversal
  power in an elevation-readable world, and it is what soft-gates the routes `world.md`
  reserves for it.
- **Inside the side-view sequences the Trump is literal and at full strength** — the
  Gallowwood ordeal is where the card lives, and gravity inversion is native there.
- **Outside side-view spaces, the Present slot's gravity bubble is TBD** — see **Open
  questions** below. It is never to be resolved by whatever falls out of an
  implementation; the doc decides first.

## Defense

- **Dodge roll** — short-range roll with invincibility frames (i-frames) covering the
  commit window. The default escape and reposition tool.
- **Block-step** — a short hop-guard rather than a shield block (the Fool carries no
  shield; the Bindle is used two-handed). Absorbs a hit and repositions slightly, at the
  cost of no counter-window of its own.
- **Fool's Chance** — the skill-expression centerpiece of combat. A dodge timed to the
  final instant before a hit lands triggers Fool's Chance: roughly a 1.5-second
  slow-motion window, during which the Fool moves at normal speed relative to a slowed
  world, **and** the next Present-slot Trump cast is free (no Fortune cost). It rewards
  reading an enemy's telegraph precisely rather than dodging early and often, and it is
  the mechanical bridge between combat and the Pocket Spread — see
  [`progression.md`](progression.md) for what a free Present cast can do at each slot.

Exact i-frame duration and the width of the "perfect" timing window are tuning values,
not design facts, and are expected to move throughout production and post-launch
balance passes.

## Pip

Pip, the Fool's dog, fights alongside the player via a **radial command wheel**:

| Command | Effect |
|---|---|
| **Fetch** | Pip retrieves a dropped or thrown item (a lobbed weapon, a quest object, ammunition) and brings it back to the Fool. |
| **Harry** | Pip pins or distracts one target enemy, holding its attention and briefly reducing its aggression toward the Fool. |
| **Seek** | Pip points toward something hidden nearby — a trap, a secret, a fog-hidden path. Traversal/discovery utility more than a combat command, but shares the wheel. |

Pip cannot die. If reduced to zero health he yelps, retreats out of the fight, shakes it
off, and returns after a short cooldown. This is not a difficulty concession — it is
canon: nothing in the Spread can truly end before `WS_DEATH_UNBOUND` (see
[`world.md`](world.md) §World-state matrix), and Pip is no exception. Pip's
invulnerability needs no in-fiction excuse after that state fires either; he is simply
the one creature the Reading never intended to lose.

## Defeat (the Fool at zero petals)

Owns the player's defeat loop (decided with the director, 2026-07-23). The Fool cannot
die, and the reason is the same one that protects Pip: **nothing in the Spread can truly
end before `WS_DEATH_UNBOUND` — and the Fool, the world's own ending, can be delayed but
never spent even after it.** The Reading protects its last card-turner. Defeat therefore
plays as the world's rule, not a videogame convention:

1. **The fall.** At zero petals the Fool stumbles, goes to one knee, and folds down where
   they stand. No ragdoll, no death sting, no desaturation drama — a body that has been
   told, gently, *not yet*.
2. **Pip's beat.** Pip trots over — matter-of-fact, never performing concern (his canon
   rule holds even here, `characters.md` §Pip) — and licks the Fool's face: a dog solving
   a practical problem, exactly as unbothered as ever. This is the defeat screen. It
   should be allowed to be a little funny every single time.
3. **The fade and the return.** A brief fade over the lick; the Fool wakes at the last
   Waystation rested at, White Rose regrown, Pip already beside them. No currency loss,
   no corpse run, no penalty beyond the walk back (difficulty modes may adjust elsewhere;
   the loop itself never changes).
4. **One voice, rarely.** The Querent may remark on a defeat at most occasionally (a
   rotating low-frequency pool, warm and dry, never scolding). Repeated defeats at the
   same encounter go quiet rather than needling — the game does not rub it in.

Boss-specific defeat barks (e.g. Mortimer's duel) may layer a line per `arcana.md`/quest
scripts, but the loop above is invariant across the whole game. Animation surfaces:
`Defeat_Collapse` and a wake-up rise on the Fool (see the Fool animation manifest), one
`LickFace` interaction clip on Pip's set.

Fortune is the single resource spent by Present-slot Trump powers; its meter size, exact
costs, and out-of-combat earn sources (discovery, daring) are owned by
[`progression.md`](progression.md). In combat specifically, Fortune is earned by:

- **Landing hits** — the baseline trickle, rewarding staying in the fight rather than
  turtling.
- **Fool's Chance** — a disproportionate reward per trigger, since it also grants a free
  cast; this is deliberate, so mastering the parry-dodge is the fastest route to power,
  not a side benefit of playing safe.
- **Discovery mid-encounter** — spotting an ambush before it lands, finding an
  environmental advantage — folded into the same combat-adjacent earn rate rather than
  treated separately.

The combat-side design intent is that a competent player should reach one Present cast
roughly once per sustained fight against a real threat (a Knight, a King, a boss phase),
never so often that casting becomes the whole fight, never so rarely that the Pocket
Spread feels irrelevant in combat.

## Enemies: the Blanks

The standard enemy is the **Blank** — a humanoid soldier-figure with a blank oval face,
one of the casualties of the Stall. Blanks are not literal walking cards: each *bears*
a card whose face went blank — worn as a tabard or heraldic plate carrying its suit and
rank — and the card, not the body, is what the Stall keeps re-arming. The body is a
vessel the card raises; the metaphor stays a metaphor. One base art and animation family carries every suit and rank, keeping the
whole game's enemy roster simple and legible by design, not by budget necessity (see
[`GDD.md`](../GDD.md) §Iteration clause).

**Suit flavors** shape *behavior*:

| Suit | Combat role |
|---|---|
| **Cups** | Fluid skirmishers and ranged lobbers — arcing, evasive, harass at range and reposition. |
| **Swords** | Fast, precise duelists — tight strings, quick punishes, the suit that tests the light string and dodge timing hardest. |
| **Wands** | Reach and fire — polearm-length pokes and flame-tagged attacks that punish standing still. |
| **Coins** | Heavy shielded bruisers — slow, armored, built to be broken through rather than out-traded. |

**Rank** scales *role*, not just stats:

| Rank | Role |
|---|---|
| Two – Ten | Mooks; the printed number on the Blank's back is a simple visual tell of toughness — a Two folds fast, a Ten is a real fight. |
| Page | Scout and alarm-raiser; flees to alert others rather than engaging directly. |
| Knight | Elite duelist; the rank where suit identity is sharpest. |
| Queen | Commander; grants support auras to nearby Blanks (buffs, not summons). |
| King | Roaming mini-boss; a small set piece in its own right, not just a bigger mook. |

Regional skins dress Blanks to match the region they're found in (Bastion Blanks read as
guardsmen, Wheelhouse Blanks read as croupiers, and so on) — cosmetic only; suit and rank
still govern behavior. See [`world.md`](world.md) §Regions for region flavor.

**A defeated Blank slumps and fades while the card it bore flutters free — drifting off
to raise a new bearer elsewhere later** —
consistent with the rule that nothing truly ends before `WS_DEATH_UNBOUND`. This is
presented as a visible, storybook-melancholy effect (a body relieved of duty and a card
still on the clock — never gore, never a "death" animation), not hidden. After
`WS_DEATH_UNBOUND` fires, Death's Trump grants the means to end the *card itself*, which
is what ending a Blank permanently means; the mechanical detail of that Trump is owned
by [`arcana.md`](arcana.md).

## Other enemy families

Two smaller enemy families exist outside the Blanks, both tied to specific regions and
world-states — see [`world.md`](world.md) for the regions themselves:

- **Beasts** — the wildlife of the Maw and other wild spaces. Hostile by default; calmed
  to neutral-until-provoked world-wide once `WS_STRENGTH_UNBOUND` fires.
- **Fog-masks** — the "monsters" of the Mirrormarsh. Revealed as lost people wearing the
  fog's illusions once `WS_MOON_UNBOUND` fires, at which point they lose their ambush
  advantage world-wide. Before that state, they read and fight as their masks, not as
  the people beneath — the reveal is a world-state event, not a combat-time twist.

Both families are intentionally small rosters — one or two art families each, reskinned
by region — for the same reason as the Blanks: craft and legibility, not budget (see
[`GDD.md`](../GDD.md) §Iteration clause).

## Boss philosophy

Every one of the 21 Arcana fights is a handcrafted set piece built on **arena + gimmick +
character**: a bespoke space that itself expresses the card's meaning, one central
mechanical idea unique to that fight, and a boss who is a person (or the ghost of an
office) rather than a stat block. Some Arcana are not "fights" in the conventional sense
at all — a chase, an ordeal, a choice that can only be "won" by choosing correctly. Which
of these each Arcana is, and the full breakdown of arena/gimmick/character per card, is
owned by [`arcana.md`](arcana.md).

**Why this philosophy (it's craft, not economy):** arena + gimmick + character moves a
fight's identity from *animation quantity* to *idea quality* — the fights players
remember from any era are remembered for their one idea, not their move-count. Every
Arcana is a fully bespoke character (unique design, silhouette, and animation set — see
[`GDD.md`](../GDD.md) §Iteration clause and `arcana.md` design rule 7); the discipline
of one central mechanical idea per fight is what keeps 21 bespoke bosses *coherent* and
gives each one room to be iterated to polish. "Some Arcana are not fights" is likewise
a design position, not a cost dodge: a card whose meaning is patience or perspective is
betrayed by a health bar. The 21 Arcana are the product; this philosophy is how each of
them gets to be somebody's favorite.

## Encounter philosophy

- **Fixed difficulty bands, no level scaling.** Regions are tuned to a fixed band (see
  [`world.md`](world.md) §Intended difficulty bands); the player's own skill and Pocket
  Spread carry them into "too-early" regions, not a level number.
- **Readable telegraphs everywhere**, mooks and bosses alike — an enemy that hits without
  a tell is a bug, not a difficulty knob.
- **Few but meaningful ambient encounters.** Tarrock does not fill the map with a
  Blank camp every fifty meters; open-world padding is treated as a cost, not content.
  An ambient encounter exists because a spot in the world earns one (a toll-fort, a
  hunting ground, a haunted crossing), not to fill space between quest markers.

## Difficulty modes

| Mode | Intent |
|---|---|
| **Story** | Combat is a vehicle for narrative; reduced damage taken, generous timing windows, Fortune earns faster. For players here for the world and the story. |
| **Journey** (default) | The tuned experience — readable, deliberate, occasionally punishing against Knights, Kings, and bosses. |
| **Trial** | Tightened timing windows and telegraphs, reduced Fortune income, no damage reduction. For players who want the Fool's Chance mastery curve at its sharpest. |

Whether Trial adds any mechanic beyond tighter numbers (a permadeath option, a
scoring/rank layer) is **TBD** — a decision for closer to the combat-prototype milestone
(M1), not the docs phase.

## Accessibility

- Full input remapping.
- Hold/toggle options for held inputs (block-step, charged heavy, sprint, Focus, the Pip
  command wheel).
- A **Fool's Chance timing-window slider**, independent of difficulty mode — a player on
  Story or Journey can widen the perfect-dodge window without changing anything else
  about combat balance.
- Screen-shake and screen-flash toggles, given how central slow-motion and flash-forward
  feedback (Fool's Chance, charged-heavy releases) are to combat feel.

Further accessibility scope (colorblind palettes for enemy tells, subtitle/caption
detail for combat barks) is owned jointly with [`art-audio.md`](art-audio.md) once that
doc exists — not restated here.

## Open questions (TBD)

- **Overturn's gravity bubble outside side-view spaces.** The Present slot inverts gravity
  in a bubble (`arcana.md` §XII); inside the side-view sequences that is literal and
  needs no reinterpretation, but on the top-down ground plane "invert gravity" has no
  self-evident meaning. Candidate readings (a suspend/hold field, a reversed-pull zone
  that drags enemies to its center, a lift that sets up the stagger launcher's window)
  are **undecided**. It is resolved here, in this doc — never by whatever an
  implementation happens to do first. Until it is decided, no code implements the Present
  slot of Overturn outside a side-view sequence.
- **Whether Trial mode adds any mechanic beyond tighter numbers** — see
  **Difficulty modes** above; a decision for the combat-prototype milestone.
- **The learned-skill acquisition model** — see **Focus**; settled in
  [`progression.md`](progression.md) before any skill is gated.
