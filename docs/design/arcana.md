# The Arcana — SSOT

Owns: all 21 Major Arcana as **encounters and rewards** — fight design, gating, Trump
effects (all slots, both orientations), and the shape of each unbinding. Their
personalities live in [`characters.md`](characters.md); their world-state changes in
[`world.md`](world.md) (matrix IDs referenced below); their story weight in
[`narrative.md`](narrative.md). Quest-level scripting lives in `../quests/main/`.

## Design rules

1. **Card first.** Every fight, Trump, and unbinding must be defensible from the card's
   traditional upright and reversed meanings. When a mechanic idea conflicts with the
   card, the card wins.
2. **Arena + gimmick + character.** One handcrafted space, one mechanical idea expressing
   the card, one person under the office. No boss is a damage-sponge with phases.
3. **Not everything is a fight.** Chases, ordeals, vigils, and choices are "boss
   encounters" too. Roughly a third of the Arcana are unbound without conventional combat
   — this is a feature *and* a scope lever.
4. **Unbinding is release, never death.** The moment always plays the same beats: the
   office cracks → the person's *name* returns → they hand over the Trump themselves.
   Nobody drops loot.
5. **Trumps: one card, six expressions.** Each Trump defines a **Past** (passive),
   **Present** (active, costs Fortune), and **Future** (triggered) effect. Slotting a
   card **reversed** strengthens its effect in that slot and attaches its **burden** (one
   drawback theme per card, applied to whichever slot it occupies). This is an equip
   system, **not time travel** — the slots are named for tarot spread positions
   ([`progression.md`](progression.md) owns the rules).
6. **All combat is real-time third-person action** — never turn-based. Where an entry
   below speaks of a boss's "rota," "beat," or "riposte," it describes a telegraphed
   real-time rhythm the player reads and answers live, exactly like any action-game
   boss pattern.
7. **Every Arcana is bespoke.** Each boss is a unique character: own model, own rig,
   own silhouette, own animation set, sized to their encounter. Rig-sharing is a
   Blanks-only (mook) strategy ([`combat.md`](combat.md)). Where the card is more than
   one being, the boss is more than one character — the Lovers are two full duelists;
   the Moon's Anti-Fool wears the *player's* rig by design, not by thrift.
8. **Encounter tiers** for planning iteration depth: **S** = systemic (built mostly
   from existing mechanics), **M** = one bespoke arena gimmick, **L** = setpiece
   (multiple bespoke systems). Tiers schedule iteration effort; they never cap quality.

## Index

Gates (only three exist): XVIII needs a true light source, XX needs `WS_DEATH_UNBOUND`,
XXI is always open (world.md §gates). Everything else can be attempted at any time.

| # | Card | Region / Quest | Encounter type | How it's won (concretely) | Tier |
|---|---|---|---|---|---|
| I | Magician | Prestige — MQ01 "The Greatest Trick" | Fight (trickster) | Spot the real one among three doubles (his rose wilts; the fakes' don't) and beat him through both stage phases. | M |
| II | High Priestess | Veil — MQ02 "Between the Pillars" | Riddle-ordeal | Perform her three tasks honestly — no combat at all. Lie at any step and you must beat her shadow in a duel instead. | S |
| III | Empress | Bower — MQ03 "The Endless Harvest" | Fight (stationary siege) | Cut the crown-roses feeding her living throne while it defends itself; she never moves. | M |
| IV | Emperor | Bastion — MQ04 "Set in Stone" | Fight (climbable colossus) | Climb the 40-foot statue and break the 4 Edicts carved into him, dodging attacks that run on a learnable schedule. | L |
| V | Hierophant | Chantry — MQ05 "The Same Old Song" | Fight (rhythm) | Sabotage the choir-pipes to break his hymn, then hit him in the off-beats the broken music exposes. | M |
| VI | Lovers | Divide — MQ06 "The Longest Engagement" | Fight → forced choice | Damage can't win: fight the two duelists to a standstill, then make the marriage choice they can't — the answer is the finishing blow. | M |
| VII | Chariot | Longroad — MQ07 "The Triumph" | Moving-vehicle fight | Board the galloping procession, fight forward along its roofs to the driver, and physically take the reins. | L |
| VIII | Strength | Maw — MQ08 "The Gentlest Hand" | Grapple-duel | Wrestle-calm the lion she's been holding: stamina grappling + gentleness prompts. Attacking it is the mistake. | M |
| IX | Hermit | Dim — MQ09 "The Light on the Mountain" | Chase (no combat) | Track his lantern-light across the dark mountain and catch him. He hands over the Trump gladly. | S |
| X | Wheel of Fortune | Wheelhouse — MQ10 "Round and Round" | Fight (rotating arena) | Smash the brake-shoes seizing the giant wheel while random buff/debuff zones sweep the spinning arena. | M |
| XI | Justice | Assize — MQ11 "The Adjourned" | Duel (stored damage) | Her scales store all damage you deal; on a visible, telegraphed beat she fires the stored total back. Stagger her to dump the scales safely, then repeat. | M |
| XII | Hanged Man | Gallowwood — MQ12 "A Change of Perspective" | Ordeal (no boss) | Complete his gravity-inverted traversal gauntlet. He never fights; he's delighted either way. | M |
| XIII | Death | Stillmarsh — MQ13 "An Ending" | Pure duel (keystone) | Beat Mortimer in a straight 1v1 scythe duel — no adds, no gimmick, hardest clean fight in the game. He *wants* you to win, but you must earn it. | M |
| XIV | Temperance | Confluence — MQ14 "The Perfect Measure" | Fight (hazard mixing) | She floods the arena in alternating scald/frost bands; redirect her pours into each other to make safe lanes and windows to strike her. | M |
| XV | Devil | Undervault — MQ15 "Terms and Conditions" | Negotiation → fight | First, optionally sign up to 3 real buffs for 3 real costs; then beat him — plus every clause you signed, which he will use. | M |
| XVI | Tower | Spire — MQ16 "Already Falling" | Ascent setpiece | Climb the frozen mid-collapse tower while his lightning un-freezes chunks of it under you; short desperate duel at the top; ride the full collapse down. | L |
| XVII | Star | Mere — MQ17 "The Vigil" | Vigil (no combat) | Keep one night's vigil: tend the wish-lights, hear three pilgrims, sit with Pip. She gives the Trump freely. | S |
| XVIII | Moon | Mirrormarsh — MQ18 "The Path That Lies" | Mirror-fight | Defeat the Anti-Fool: your reflection, using your exact current Pocket Spread, reversed. Your own build, fought honestly. | M |
| XIX | Sun | Noonlands — MQ19 "The First Sunset" | Duel (light-reading) | Duel Aurel: his radiance whites out his body's tells, so read his *shadow* on the sand instead. | L |
| XX | Judgement | Hollows — MQ20 "The Last Trumpet" | Fight (kill order) | Her trumpet re-raises your fallen enemies on a visible meter — win by managing kill order (or denying rezzes with Death's execute). | M |
| XXI | World | Axis — MQ21 "The Shuffle" | Scaling finale | One full phase per still-bound Arcana (their movesets, compressed), then a pure duel with the Dancer. Unbind all 21 first and it's *only* the duel. | L |

---

## I. The Magician — *skill turned to shtick*

**Encounter.** The main tent of the Prestige. The Bataleur (freed name: Wicke) has
performed the same perfect show for 300 years; the fight is the finale he's never been
allowed to reach. Shell-game boss: three spotlights, three Magicians, only one real —
tells are in the *props* (the real one's rose wilts slightly; observation is the
counter). Mid-fight the stage flips to the under-stage ("as above, so below") where the
machinery of every trick is exposed and the duplicates fight as stagehands-turned-cards.

**Trump I — Manifest.**
| Slot | Upright |
|---|---|
| Past | Nimble hands: instant chest/door interactions; vendors show their hidden stock. |
| Present | Conjured hand: grab, carry, and throw objects or man-sized enemies at range. |
| Future | When struck, swap places with a conjured double (once per fight). |

**Reversed burden — *the trick costs the trickster*:** effects grow (bigger hand, second
double) but each trigger nicks 5 Fortune extra, even the Past slot's freebies.

**Unbinding.** `WS_MAGICIAN_UNBOUND`: the show ends; the audience rises for the first
time in centuries; the carnival packs up over in-game days. Player choice routes
`WS_TROUPE_TRAVELING` / `WS_TROUPE_SETTLED` (world.md).

## II. The High Priestess — *knowledge that stopped teaching*

**Encounter.** The Silent Examination. No fight is offered. Between the pillars she asks
three things that must be *done*, not said: bring what the Veil lost, stand where the
moon can't see, and — the third — be told a secret and keep it (the dialogue's correct
option is refusing every "tell" prompt; the game never marks it). Answer falsely at any
step and her shadow peels off the pillars and duels you — a fast, punishing mirror-mage.
Honest players never draw their staff. Liars earn the Trump the hard way; both paths
unbind her.

**Trump II — Secrets.**
| Slot | Upright |
|---|---|
| Past | Read sealed script anywhere; hear what Blanks whisper (ambient lore + hints). |
| Present | Truesight pulse: reveals hidden doors, mimics, buried caches, and false floors. |
| Future | When struck, slip behind the veil: 2s intangible. |

**Reversed burden — *secrets spill*:** stronger effects (pulse stuns; veil 4s) but every
trigger reveals *you* — nearby enemies aggro instantly.

**Unbinding.** `WS_PRIESTESS_UNBOUND` (world.md): the mist lifts; the world starts
dreaming again.

## III. The Empress — *abundance with no harvest*

**Encounter.** The Briar Throne, heart of the Bower. She cannot rise — three centuries
of growth have grown *through* her. The fight is pruning: sever the crown-roses that
feed the throne while it counterattacks with lash-vines and pollen-drunk Blanks; every
crown-rose cut, the arena's choking canopy opens and light changes the fight. She thanks
you between phases. It is not a metaphor she enjoys.

**Trump III — Bloom.**
| Slot | Upright |
|---|---|
| Past | Forage yields double; the White Rose regrows slowly even in bound regions. |
| Present | Grow a briar snare (roots enemies) **or** a climbing vine at a marked surface. |
| Future | On a killing blow against you: briar cocoon — survive at 1 petal (once per rest). |

**Reversed burden — *overgrowth*:** everything grows bigger and lingers, and lingering
growth is indiscriminate — snares and cocoon briars hurt you too if touched.

**Unbinding.** `WS_EMPRESS_UNBOUND` (world.md): harvests complete everywhere.

## IV. The Emperor — *order that cannot amend*

**Encounter (setpiece).** A forty-foot colossus of law-graven granite that has not risen
from its cube throne since the Stall. SotC-style: climb him, reach the four carved
Edicts (wrists, shoulders, crown) and break them. His attacks run on a strict, learnable
rota — the fight is literally a timetable, and mastering it feels like bureaucratic
judo. At one Edict remaining, he does the most frightening thing in the fight: he
*amends the schedule*. Once.

**Trump IV — Decree.**
| Slot | Upright |
|---|---|
| Past | Fixed fair prices at all shops; guards overlook petty trespass. |
| Present | Stomp shockwave; lesser Blanks caught in it halt in place for 3s (a decree). |
| Future | After a block-step, hyperarmor through the next hit. |

**Reversed burden — *tyranny*:** decrees double in radius and duration, but Minors fear
a tyrant — Renown with all suits ticks down slowly while slotted reversed.

**Unbinding.** `WS_EMPEROR_UNBOUND` (world.md): the gates open; so does petty crime.

## V. The Hierophant — *the song that forgot it was music*

**Encounter.** The organ-colosseum of the Chantry. The Hierophant conducts the eternal
hymn; he is untouchable while the harmony holds. Fight = sabotage the music: redirect
choir-pipes, silence bell-Blanks, land hits in the off-beat the broken harmony exposes.
His attacks arrive in strict meter — audio literally telegraphs everything (and the
accessibility mode adds visual beat markers).

**Trump V — Rite.**
| Slot | Upright |
|---|---|
| Past | Waystation blessings last twice as long; shrines and offerings give more. |
| Present | Sanctify a circle: heal-over-time inside, lesser Blanks won't cross the line. |
| Future | When your last petal is spent, a litany grants 3s invulnerability + 1 petal (once per rest). |

**Reversed burden — *dogma*:** the circle grows cathedral-sized and the ward absolute —
but while you stand inside, your other two slots are sealed (doctrine admits no rivals).

**Unbinding.** `WS_HIEROPHANT_UNBOUND` (world.md): the bells learn new songs.

## VI. The Lovers — *a choice refused for 300 years*

**Encounter.** The Betrothed: one duelist from each town of the Divide, fighting as a
perfectly mirrored pair on the unfinished bridge. While mirrored they cannot be harmed;
the fight is about *separating* them (terrain, tethers, timing) — and every separation
they re-mirror, because the alternative is choosing. The fight cannot be won by damage.
At the standstill, the choice dialog appears, and the player answers the question the
whole canyon has refused: the wedding happens **east** or **west**. That answer is the
killing blow. The quest doc owns making both options ache.

**Trump VI — Union.**
| Slot | Upright |
|---|---|
| Past | Pip's bond deepens: Harry pins two enemies; Seek range doubled. |
| Present | Tether two enemies: shared damage; yank to slam them together. |
| Future | Dodging leaves a mirror decoy that taunts nearby enemies. |

**Reversed burden — *possession*:** tether and decoy last far longer, but the bond runs
both ways — a fraction of tethered enemies' pain arrives in your Fortune bar as drain.

**Unbinding.** `WS_LOVERS_UNBOUND` + branch flag (world.md): the bridge completes.

## VII. The Chariot — *victory that outlived its war*

**Encounter (setpiece).** The procession never stops, so neither does the fight: leap
aboard the war-train at full gallop, battle up its length — carriage roofs, banner
rigging, Blanks in parade armor — to the Charioteer, who fights one-handed because the
reins are in the other. You do not defeat him. You take the reins, and you *pull*. The
procession's halt — dust settling, banners folding, three centuries of momentum dying in
one long skid — is the unbinding.

**Trump VII — Triumph.**
| Slot | Upright |
|---|---|
| Past | The Chariot answers: summonable mount anywhere outdoors. **The traversal headline.** |
| Present | Battering dash: crash through enemies, barriers, and lines of fire. |
| Future | Dodging while sprinting becomes a dash-through with full i-frames. |

**Reversed burden — *momentum*:** dash and mount speed surge, but stopping is no longer
entirely your decision (overshoot; long skids; comedy and cliffs).

**Unbinding.** `WS_CHARIOT_UNBOUND` (world.md): **Waystation fast travel activates.**

## VIII. Strength — *the hand that may never tire*

**Encounter.** She has held the lion's jaws since the Stall — not conquering it,
*sparing* it, forever, without rest. She asks one thing: hold it for me. The encounter
is a grapple-duel with the lion — stamina wrestling, break-away timing, and "gentleness
prompts" where attacking is the mistake — while she watches with empty hands for the
first time in 300 years. Damage is not the win condition; calm is.

**Trump VIII — Tame.**
| Slot | Upright |
|---|---|
| Past | Beasts everywhere are neutral until provoked. |
| Present | Grapple a large enemy: wrestle, steer, briefly ride it as a weapon. |
| Future | At one petal remaining: quiet fury — damage up, staff strikes stagger harder. |

**Reversed burden — *ferocity*:** grapples slam like siege weapons, but the wild smells
it on you — beast neutrality is suspended while slotted reversed.

**Unbinding.** `WS_STRENGTH_UNBOUND` (world.md): the lion becomes a friend of the road.

## IX. The Hermit — *the answer that walked away*

**Encounter (no combat).** The Long Chase. His light is always on the next ridge of the
Dim; the gauntlet is cold, dark wayfinding — the region *is* the boss. When you finally
corner the light, he's sitting beside it with two cups poured, because being caught was
the point: a lantern is for being *followed*, and nobody had followed in 300 years. He
asks the Fool one question over tea (the player's answer is barked back by NPCs much,
much later). Then he hands over the lantern like it weighs a mountain, because it does.

**Trump IX — Lantern.**
| Slot | Upright |
|---|---|
| Past | Nearby undiscovered points of interest ping softly on the Almanack. |
| Present | Raise the lantern: reveal hidden paths, rout shadow-Blanks, **counts as true light** (Mirrormarsh gate). |
| Future | Dodging leaves a blinding afterimage. |

**Reversed burden — *the moth problem*:** the light doubles in power and radius, and
everything in the dark can see it. Spawns converge on you while raised.

**Unbinding.** `WS_HERMIT_UNBOUND` (world.md): stars over the Dim; the lost come home.

## X. Wheel of Fortune — *luck, seized up*

**Encounter.** Inside the titanic stopped Wheel: a ring-arena that begins turning as the
fight starts — the first motion in the Wheelhouse in 300 years. Rotating "fortune
weather" cycles buffs and calamities across arena segments, hitting player and the
Wheel's Blank crew alike; the objective is smashing the brake-shoes that keep seizing
the ring. Design intent: the fight teaches that fair and random are not enemies — read
the weather, surf the luck, and the Wheel starts to feel like a dance partner.

**Trump X — Spin.**
| Slot | Upright |
|---|---|
| Past | Drops and finds improve everywhere. |
| Present | Spin the wheel: one random effect from a fixed, learnable 8-entry table (heal, coin burst, lightning, decoy, big hand, slow-time, smoke, jackpot = all of them). Table contents TBD at combat tuning. |
| Future | Any hit has a 10% chance to simply miss you. Fate's coin. |

**Reversed burden — *all in*:** the Spin table doubles its stakes — jackpot odds up,
but two entries become genuinely bad for you. The Future miss-chance becomes 20%, but
so does a 5% chance your *own* heavy swings whiff.

**Unbinding.** `WS_FORTUNE_UNBOUND` (world.md): the luck districts begin to cycle.

## XI. Justice — *the verdict deferred*

**Encounter.** The Magistrate, blindfolded, in the highest empty courtroom. Her scales
hang above the arena and *fill with everything you deal her*. On a visible, telegraphed
rhythm — a courtroom bell, loud and readable — she pours the scales back: a single
riposte carrying the stored total, to be dodged or suffered in full. (Real-time, like
everything else; the bell is a boss pattern, not a turn.) The fight is tempo: build
damage, then stagger her *before the bell* to dump the scales harmlessly and start the
cycle again. Cheap tactics — backstabs, mid-duel healing, reversed-Trump burdens dodged
onto her — weigh double in the scales. The fight quietly audits how you've been playing
the whole game, and players will feel *seen*.

**Trump XI — Verdict.**
| Slot | Upright |
|---|---|
| Past | Arbitrate: NPC dispute events unlock across the Spread (side content; world.md). |
| Present | Mark a foe: your next strike lands as judged true damage. |
| Future | A perfectly timed dodge reflects the attack back to its source. |

**Reversed burden — *the harsh sentence*:** judged damage doubles — and a tithe of every
judgment lands on you as well. The scales must balance.

**Unbinding.** `WS_JUSTICE_UNBOUND` (world.md): verdicts land; three of the freed are
guilty (characters.md names them; each seeds a side quest).

## XII. The Hanged Man — *the pause that found peace*

**Encounter (ordeal, no boss).** He is the only Arcana who is *happy* — the Stall gave
him exactly what his card wanted, and he radiates the calm of a man three centuries
into a good hang. He won't fight; he invites. The Ordeal: hang from the World-Tree's
bough (a deliberate rhyme with the Cliff's leap of faith), and traverse the Gallowwood's
inverted gauntlet — gravity-flipped glades, canopy bridges walked from beneath — with
the controls' camera honestly inverted in marked spaces. At the end he asks the Fool
his only question: "Comfortable?" — and hands over the Trump either way, delighted by
both answers.

**Trump XII — Overturn.**
| Slot | Upright |
|---|---|
| Past | Feather-fall, always. Fall damage ceases to exist. **Traversal headline #2.** |
| Present | Invert gravity in a bubble for 4s: puzzles, ambushes, juggling Coins-rank bruisers. |
| Future | Struck while airborne: right yourself instantly with a beat of slow-motion. |

**Reversed burden — *surrender*:** the bubble grows and holds 8s — and includes you.
Commit.

**Unbinding.** `WS_HANGEDMAN_UNBOUND` (world.md): the Gallowwood rights itself; his
peace spreads into the world's barks.

## XIII. Death — *the ending, denied* (KEYSTONE)

**Encounter.** Mortimer is the only Arcana who asks for it. He has watched the
Stillmarsh fill for 300 years with people who came to him to finish and cannot. But an
ending must be *earned* — "anything less would be disrespect to the office" — so he
fights with total sincerity: a scythe duel by candle-light, no adds, no arena gimmick,
no gimmick at all. The purest test of the combat system in the game; the difficulty
peak among the duels, by design. Mid-fight, between phases, he talks — this is the
canonical confession scene ([`narrative.md`](narrative.md)): what the final card is,
what the journey means, and that he will not pretend otherwise. He says it kindly,
with his scythe at rest: *"You are the ending, little Excuse. I am only the door."*
The player walks into phase two knowing everything.

**Trump XIII — Passage.**
| Slot | Upright |
|---|---|
| Past | Blanks you defeat stay ended — they no longer reassemble elsewhere. |
| Present | Reap: execute any lesser enemy below ⅓ health. |
| Future | On death: rise where you fell at 1 petal — *not yet* (once per rest). |

**Reversed burden — *hunger*:** the execute threshold rises to ½ health and Reap
refunds Fortune — but the scythe must be fed: your maximum petals are reduced by one
while slotted reversed.

**Unbinding.** `WS_DEATH_UNBOUND` (world.md): **mortality returns.** The single largest
world change; activates `CONFESSED` dialogue variants everywhere.

## XIV. Temperance — *the mixture never poured*

**Encounter.** The Mixer stands astride the two rivers, pouring eternally between the
colossal cups — a blend that may never be finished, because finished is a kind of
ending. The arena floods in alternating bands of scald and frost as she pours; the
counter is *tempering* — redirect her own pours into each other to cut neutral paths
and expose her between mixtures. Patience-and-geometry fight; rewards players who
stop dodging frantically and start conducting.

**Trump XIV — Blend.**
| Slot | Upright |
|---|---|
| Past | Elixir-craft at mixers' benches; carried elixirs +2 (system detail: progression.md). |
| Present | The Middle Way: a wave that neutralizes elemental ground hazards and strips enemy buffs. |
| Future | Incoming elemental damage partially converts to Fortune. |

**Reversed burden — *oversteep*:** the wave also converts — hazards become *your*
allies briefly, but the conversion drinks from you: each cast steeps away a sliver of
max Fortune until rest.

**Unbinding.** `WS_TEMPERANCE_UNBOUND` (world.md): the rivers reach the sea; the delta
drains; new land surfaces.

## XV. The Devil — *the comfortable cage*

**Encounter.** Old Nick Lowry does not fight fair; he fights *contractually*. Phase
zero is a negotiation at a beautiful desk: he offers three genuine, mechanically real
buffs for three genuine terms (a cut of your coins; a petal; Pip waits outside — that
one hurts). Take none and the fight is brutal and proud. Take all three and he barely
needs to fight you — and mid-fight he exercises a clause: he borrows your equipped
Trumps and casts them reversed against you. Every contract is honest. That's the
horror. The fight itself: chains, the gilded pit's tiers, and your own choices.

**Trump XV — Bargain.**
| Slot | Upright |
|---|---|
| Past | Fine-print stock at every shop: potent goods with their costs printed honestly. |
| Present | Chain-tether: bind an enemy — yank fliers down, drag runners back, anchor bruisers. |
| Future | When Fortune empties: instant full refill + one stacking curse (until rest). |

**Reversed burden — *the house always wins*:** everything stronger, everything cheaper —
and 10% of all coins you earn are simply gone. You will not find where. He will not say.

**Unbinding.** `WS_DEVIL_UNBOUND` (world.md): the chains fall; not everyone leaves.

## XVI. The Tower — *the fall that never finished*

**Encounter (setpiece).** The Spire's collapse froze mid-catastrophe; the Warden — a
crowned figure at the summit who was king of the tower when the lightning struck —
has spent 300 years *refusing to let it finish falling*. The ascent is the fight:
climb suspended rubble while his lightning re-awakens gravity in patches, dropping
whole staircases you were about to use. The summit duel is short and desperate, a man
fighting bare-handed for a ruin. Unbinding = the Tower finally falls with you aboard —
ride the collapse down (scripted descent, Overturn/feather-fall players get style
options). Visible from every region in the game: the skyline loses its broken tooth.

**Trump XVI — Ruin.**
| Slot | Upright |
|---|---|
| Past | Breakable walls and unstable structures shimmer faintly. |
| Present | Call a lightning strike at a marked point. |
| Future | Taking a heavy hit discharges a stagger-nova (once per fight). |

**Reversed burden — *catastrophe*:** the strike becomes a rolling storm — which does
not distinguish. Strikes land near you, too.

**Unbinding.** `WS_TOWER_UNBOUND` (world.md): the skyline changes forever; storms join
the weather.

## XVII. The Star — *hope, on hold*

**Encounter (no combat).** The Mere resists violence — Fortune doesn't charge here,
Blanks don't enter, and the Warden of the Mere pours her waters and simply asks the
Fool to keep one night's vigil: tend the wish-lights, listen to three pilgrims, sit
with Pip on the jetty. It is the game exhaling on purpose, placed among the hardest
regions. At vigil's end she gives the Trump freely — the only Arcana unbound by
kindness alone. (The player *can* attack her. She does not resist, the Trump comes
anyway, and the Mere's post-unbinding state is permanently dimmer — one bark pool, no
mechanical punishment. The game just remembers.)

**Trump XVII — Wish.**
| Slot | Upright |
|---|---|
| Past | Fortune regenerates slowly at all times. |
| Present | A guiding light traces the path to the current objective or nearest secret. |
| Future | Once per fight, at zero petals: the White Rose fully reblossoms. |

**Reversed burden — *wishful thinking*:** regeneration doubles and the light finds
rarer secrets — but hope untempered spends you: maximum Fortune −20 while slotted.

**Unbinding.** `WS_STAR_UNBOUND` (world.md): wish-wells wake; the night sky fills —
when there is a night (`WS_SUN_UNBOUND` interaction, world.md).

## XVIII. The Moon — *the path that lies*

**Encounter.** Hard-gated on true light (world.md). Pip refuses to enter — the only
thing in the world he fears — and partway through the fog, "Pip" trots up anyway and
confidently leads. It is not Pip. Players who know Pip's rules feel the wrongness
before the reveal; that dread is the region working. The fog leads to black glass
water under the Moon, where the boss surfaces: **the Anti-Fool** — your reflection,
carrying your exact current Pocket Spread, casting your own cards reversed. A
build-check mirror. At the climax, the real Pip's howl cracks the glamour and the
glass. Bring the right spread, or fight your favorite one.

**Trump XVIII — Glamour.**
| Slot | Upright |
|---|---|
| Past | See through mimics, false walls, and fog-masks (their true faces show). |
| Present | Become illusion: enemies lose you; your next strike from unseen staggers. |
| Future | Dodging swaps you with an illusory copy of yourself. |

**Reversed burden — *the lie deepens*:** the illusion holds twice as long and the
unseen strike hits twice as hard — but while you are a lie, Pip cannot find you. No
Pip commands.

**Unbinding.** `WS_MOON_UNBOUND` (world.md): the fog lifts; the monsters were people.

## XIX. The Sun — *noon, nailed in place*

**Encounter (setpiece).** Aurel — the champion of the Noonlands, a radiant child-knight
on a white pony, undefeated for 300 years because the sun has never been allowed to set
on him. He is *delighted* to fight you; it's the first new thing to happen in his whole
long childhood. Sunflower coliseum at permanent high noon: his radiance whites out
normal telegraphs — **read his shadow, not his body** (the fight's single teaching).
Joyous, breakneck, and the closest the game comes to a classic duel-with-a-gimmick.
Unbinding: he finally loses, laughs — and grows up in the light of the first sunset in
three centuries. **The trailer moment.** MQ19 owns the sequence.

**Trump XIX — Daybreak.**
| Slot | Upright |
|---|---|
| Past | Healing is stronger in daylight. |
| Present | Solar flare: AoE burst that also cleanses curses (Bargain synergy is deliberate). |
| Future | Enemies that strike you are flash-blinded. |

**Reversed burden — *scorch*:** the flare doubles and salts the ground with burning
light — and burns a petal per cast. Noon, unnailed, still remembers being cruel.

**Unbinding.** `WS_SUN_UNBOUND` (world.md): the first sunset; day and night begin.

## XX. Judgement — *the call, unanswered*

**Encounter.** Gated on `WS_DEATH_UNBOUND` — the graves cannot open while nothing can
leave. The Herald waits in the Hollows' amphitheater of open graves: an angel whose
trumpet raises your fallen enemies mid-fight, on a meter you can see filling. Kill
order becomes the puzzle; Passage's Reap (deliberate synergy) denies resurrections.
The fight is a conversation between the two Trumps of ending and returning.

**Trump XX — Reveille.**
| Slot | Upright |
|---|---|
| Past | The waiting dead speak: ghost NPCs give hints and close their old accounts (world.md). |
| Present | Trumpet blast: knockback + your fallen enemies rise briefly as allies. |
| Future | Full self-revive with all petals. (Revive-class rule: only one revive-class Future fires per rest — this, Passage, or Bloom; progression.md owns the rule.) |

**Reversed burden — *the call compels*:** raised allies come back stronger — and after
ten seconds they answer to no one, including you.

**Unbinding.** `WS_JUDGEMENT_UNBOUND` (world.md): every goodbye in the game arrives at
once. The Hollows bloom.

## XXI. The World — *the previous Fool*

**Encounter (finale — always open).** The Axis admits anyone, at any time; that is the
point (world.md gates). At its center: the Dancer, who has held the world together
since the last Shuffle — the previous Fool, who completed this same journey, took this
same office, and has been waiting three hundred years for the Stall to break and a new
Fool to come relieve them.

**The fight scales to the journey:** every still-bound Arcana lends the Dancer their
office as a full phase (borrowed movesets, compressed). Walk in at hour two and face a
21-phase gauntlet — possible, legendary, and the harsh Early Shuffle ending
([`narrative.md`](narrative.md) §Endings). Unbind all 21 first, and the Dancer has
nothing left to borrow: the finale becomes a single perfect duel, two Fools dancing —
deliberately rhyming with MQ13's purity — followed by the choice, the Querent's answer,
and the True Shuffle.

**No Trump.** The World's card is not carried. It is turned.

`WS_WORLD_UNBOUND` (world.md). MQ21 owns the endings' scripting.

---

## Cross-Trump synergy notes (for tuning later)

- Passage ⟷ Reveille: execute denies resurrection; the intended Hollows loadout.
- Lantern / Wish / Daybreak: the three "true lights" — Mirrormarsh honors any.
- Triumph + Overturn: mounted feather-fall is the traversal endgame; let it be silly.
- Bargain's curses exist so Daybreak's cleanse matters. Keep at least one cleanse.
- The Anti-Fool (XVIII) reads the player's spread — its difficulty is self-balancing
  and playtests the player's own favorite build against them.
