# Side Quest Slate — Premise Inventory

This file is the master **premise inventory** for Tarrock's side quests: one pitch per
row, not a script. A premise graduates to its own outline file (`SQ-<REGION>-<nn>-
<kebab-title>.md`, `status: outline`) when it is scheduled for writing, per the workflow
in [`../README.md`](../README.md). Nothing here is canon until it is promoted — this
file may be reordered, cut, or rewritten freely; the promoted outline is the SSOT for
that quest from the moment it exists.

Every region gets three premises (63 total across 21 regions; the Cliff is excluded as
tutorial-only and sealed from the Spread, per `design/world.md`). The Prestige counts
the existing [`SQ-PRESTIGE-01-the-vanishing-act.md`](SQ-PRESTIGE-01-the-vanishing-act.md)
(status: script) as one of its three and adds two new premises below.

**Format:** bold title, 3–5 sentences (hook → complication → the ache or the laugh), key
NPC (canon or proposed), and tags — `[pre/post/either unbinding]`, themes touched
(`narrative.md` §Themes, numbered 1–4), and a Calling hook if the premise touches an
existing Calling (`design/callings.md`) without duplicating its loop.

> **Status note (2026-07-23):** every premise below has been promoted to its own outline
> file in this directory (`SQ-<REGION>-<nn>-<kebab-title>.md`, per the titles below), and
> all proposed NPCs are canon in `characters.md` §Regional named NPCs. Per this file's
> own rule, the promoted outlines are now the SSOT; this slate remains as the premise
> record. Four names changed at promotion to clear collisions: MQ07's soldier is
> **Corporal Pike** (was Fitch), the Spire's bell-watch veteran is **Harrow Brock** (was
> Vane), the Confluence alchemist is **Comfrey Cross** (was Betony), and the Stillmarsh
> ferryman's mate is **Tarn Loach** (was Perrin).

**Rules honored throughout:** no premise invents a new `WS_*` flag — world-state hooks
here only *reference* flags already in `design/world.md` §World-state matrix; new NPCs
are marked `(proposed — promote to characters.md before script status)`; every premise
fits its region's stasis and, where relevant, notes a believable post-unbinding variant;
rewards, where a premise implies one, are limited to what `design/progression.md`
allows (coins, rose graftings, staff heads, cosmetic outfits, Renown).

---

## The Prestige (I. The Magician)

Perpetual showtime; the audience cannot leave its seats. `WS_MAGICIAN_UNBOUND` ends the
show and packs the carnival up over in-game days.

**Existing:** [`SQ-PRESTIGE-01-the-vanishing-act.md`](SQ-PRESTIGE-01-the-vanishing-act.md)
— Bram and Wyn's 300-year-stuck goodbye behind the House of Mirrors. (status: script)

### The Barker's Bet

Flick's rival barker, Old Cutter Voss, has spent 300 years insisting his own strongman
sideshow is the "real" main event, and challenges any passerby — gods-turn-your-card, a
stranger with a dog will do nicely — to out-showman him at his own game. The catch: his
signature trick is rigged in a way even he's forgotten how to unrig, so winning it
honestly means working out the gimmick first. Flick will not stop narrating from the
sidelines. It's a small, silly, decades-deep grudge match with real affection underneath
it. [If WS_MAGICIAN_UNBOUND: packing up his stall, Voss admits he never once beat Flick
honestly either — the whole rivalry was theatre too, and the two part as friends.]

*Key NPC:* Old Cutter Voss, rival barker (canon, `characters.md` §Regional named NPCs); Flick (canon, `characters.md`) as scene partner.

*Tags:* [either unbinding] · themes: — · Calling hook: Stagehand

### The Front-Row Faithful

Mags Dellow has sat in the same third-row seat at every single showing for 300 years —
she can recite Wicke's patter better than he can, and swears she once saw him almost
break character on a Tuesday that never came again. She isn't stuck like the crowd
around her; something in her chose this seat, and she's afraid to examine why. When
`WS_MAGICIAN_UNBOUND` fires and the audience finally rises and disperses, Mags is the
last one still sitting, blinking at empty benches, with nowhere she's ever chosen to be
instead. The ache is real; so is the stubborn, funny way she eventually stands up anyway.

*Key NPC:* Mags Dellow, lifelong audience member (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding, playable pre as setup] · themes: 3 · Calling hook: none

---

## The Veil (II. The High Priestess)

Moonlit cloister-library; the world's secrets shelved and sealed. `WS_PRIESTESS_UNBOUND`
lifts the mist and makes hidden doors visible to everyone.

### The Book That Isn't Finished

Under-librarian Brother Fenwick Cray has built decades of quiet faith around one shelved
volume he's convinced predicts the Reading can never end. Hunting a different lost text
with Pip's nose, the Fool finds Cray's book is simply unfinished — the ink runs out
mid-sentence, exactly as everything else in the Veil does. Cray doesn't want this pointed
out kindly or cruelly; he wants it left alone. A gentle puzzle about a library that has
mistaken its own paralysis for prophecy.

*Key NPC:* Brother Fenwick Cray, under-librarian (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Under-librarian

### What the Silence Costs

One archivist-nun breaks three centuries of vow to whisper the Fool a warning about "a
shelf that shouldn't be opened," then looks horrified at her own voice, as if she's
forgotten how loud a whisper can be. The warning proves correct — a minor hazard, nothing
world-breaking — but she must now sit with having spoken at all, in a cloister that
worships withholding. A small, dry comedy about the one exception nobody ever tested.

*Key NPC:* Sister Aveline (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 2 · Calling hook: none

### The Keeper's Last Secret

Sister Marrow has guarded one particular drawer, and only that drawer, for 300 years —
she has never said what's inside, and the withholding is the entire shape of her days.
When `WS_PRIESTESS_UNBOUND` fires and hidden doors become visible to all, her drawer
opens itself in front of anyone who walks past, and the secret (something genuinely
modest — old love letters between two long-dead archivists) is simply there to be read.
She isn't angry. She's grieving a purpose, and doesn't yet know what a keeper is once
there's nothing left to keep.

*Key NPC:* Sister Marrow, archivist-nun (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Under-librarian

---

## The Bower (III. The Empress)

Overripe abundance, unharvested for 300 years. `WS_EMPRESS_UNBOUND` completes every
harvest and halves food prices Spread-wide.

### The Uncut Row

Farmhand Tibb Wren has convinced himself that finishing one single row before the wheat
regrows behind him will break the Bower's whole curse. He is wrong, and he knows he is
wrong, and he does it every morning anyway, timing his strokes like a man racing a tide
he's never once beaten. Helping him try is earnest and useless, which is rather the
point. [If WS_EMPRESS_UNBOUND: the row he was cutting when the harvests finally complete
stays half-cut forever, by his own request — a monument, not a failure.]

*Key NPC:* Tibb Wren, farmhand (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Farmhand

### The Hive That Never Swarms

Apiarist Coraline Ashe tends a hive whose bees have not swarmed, foraged further, or
changed their comb in 300 years — perfect, static, faintly wrong. She's built a loving
theory of "patient bees" around it rather than admit what she suspects. Waking one
experimental hive box, post-unbinding, produces the Bower's messiest, happiest scene:
bees finally going everywhere at once.

*Key NPC:* Coraline Ashe, apiarist (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: none

### The Hoarder's Ledger

Coins-culture grain broker Marchpane Boll has run the Bower's "famine" like a private
fiefdom for 300 years — rationing, favor-trading, quietly wealthy off a scarcity that was
never really scarcity, just stasis wearing famine's mask. He isn't quite a villain; he's
kept several households fed who'd otherwise have starved on principle alone, and knows
exactly how thin that excuse has worn. When `WS_EMPRESS_UNBOUND` fires and prices halve
overnight, his entire trade — and half his self-regard — evaporates by morning.

*Key NPC:* Marchpane Boll, grain broker (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

---

## The Bastion (IV. The Emperor)

Granite city, unamendable law. `WS_EMPEROR_UNBOUND` opens the gates and lets petty crime
return.

### The Amendment That Wasn't

Goodwife Nan Ostler has filed the same request for 300 years: not pardon, not protest,
just a tiny correction to an Edict that misnames her late husband's guild on a public
plaque. The Bastion's legal machine is too perfectly unamendable to fix even a spelling
error. Helping her navigate the clerks is a small comic tour of bureaucratic absurdity
with a genuinely tender want underneath it.

*Key NPC:* Nan Ostler, petitioner (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Junior clerk

### The Clerk Who Loved the Schedule

Junior clerk Pell Ashgrove has stamped writs to the same gong-rhythm for years and finds
it genuinely comforting — a life with no decisions in it, to him, is a kind of mercy.
When `WS_EMPEROR_UNBOUND` fires and stamping starts requiring judgment for the first
time, Pell is handed his first real discretionary case, and it is quietly the most
frightening moment of his life. The Fool can talk him through it, or simply stand by
while he manages alone — either way, a small, unglamorous act of becoming a person.

*Key NPC:* Pell Ashgrove, junior clerk (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Junior clerk

### The Petty Thief's Apprentice

Post-unbinding, petty crime returns to the Bastion for the first time in 300 years — and
its very first thief is spectacularly bad at it, with no living tradition to learn from.
Catching him mid-fumble opens a gentle comic choice: report him, scold him, or quietly
teach him to at least be competent. Freedom, it turns out, needs practice.

*Key NPC:* "Sixpence" Loft, the Bastion's first thief in 300 years (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: — · Calling hook: none

---

## The Chantry (V. The Hierophant)

Cathedral-town, one hymn ringing forever. `WS_HIEROPHANT_UNBOUND` lets the bells learn
new songs and festivals resume.

### The Wrong Note

Chorister Sister Perpetua Vane has sung one note flat in the eternal hymn for 300 years,
and no one has ever noticed but her — three centuries of quiet private horror at her own
tiny imperfection inside supposed perfection. The Fool is the first person she's ever
told. It's very funny, and then it isn't, because her flat note is the only proof left
that time passed at all before the Stall caught her mid-breath.

*Key NPC:* Sister Perpetua Vane, chorister (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: none

### The Bell-Ringer's Mate Who Can't Learn New Songs

Old Rennick Coombe's hands know the bell-rope better than his own name. When
`WS_HIEROPHANT_UNBOUND` fires and the bells begin learning new peals, everyone in the
Chantry rejoices except Rennick, whose hands shake trying to learn a rhythm that isn't
the one holding his whole life together. Sitting with him through one bad practice is
most of what actually helps.

*Key NPC:* Rennick Coombe, bell-ringer's mate (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Bell-ringer's mate

### The Wedding That Waits

A young Cups-culture couple wants to marry in the Chantry, but doctrine says weddings
happen only at the sacred hour — the one hour that, since the Stall, never actually
arrives. They've been "nearly married" for years, banns read and re-read. Finding the
loophole, or simply the kindness, that lets the ceremony happen anyway is a lovely small
rehearsal for what `WS_HIEROPHANT_UNBOUND` later does for the whole region.

*Key NPC:* Wren and Sorrel Tamsin, the waiting couple (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: none

---

## The Divide (VI. The Lovers)

Two towns glaring across a canyon; an unsealed engagement. `WS_LOVERS_UNBOUND` completes
the bridge and unites the towns per the player's branch choice.

### The Bridge That Almost Was

Three generations of amateur engineers, led by old Cutwright Fenn, have tried to finish
the Divide's unfinished bridge by hand, always failing at the exact plank the Stall left
half-nailed. Lending a hand for one more attempt fails exactly the same way it always
does, on schedule, and Fenn takes it with a shrug that's half despair and half running
joke by now — a small, funny, aching rehearsal of MQ06's real ending.

*Key NPC:* Cutwright Fenn, amateur bridge-builder (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: none

### The Ferryman's Gossip

Ferry hand Sculley Marsh has rowed the Divide's gossip-ferry so long he knows every
household's business on both banks better than they know it themselves — he's the
canyon's true bridge, long before the stone one exists. When `WS_LOVERS_UNBOUND` fires
and the real bridge completes, foot traffic simply walks across, and Sculley's boat sits
idle. He's proud of the marriage he helped nudge along and quietly bereft of the only
thing he was ever needed for.

*Key NPC:* Sculley Marsh, ferry hand (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Ferry hand

### The Letters That Cross Anyway

Two elderly relatives of the Betrothed — one from each town — have exchanged letters by
trained messenger-bird across the canyon for 300 years, quietly keeping a peace their
younger kin couldn't manage. Delivering one particularly overdue letter by hand reveals
the correspondence is the real reason the Divide never came to open war during the Stall.
Warm, funny, a little embarrassed to be found out.

*Key NPC:* Aunt Perpetua (east bank) and Uncle Osric (west bank) (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: none

---

## The Longroad (VII. The Chariot)

The eternal triumphal procession. `WS_CHARIOT_UNBOUND` halts it and activates Waystation
fast travel.

### What the Highwayman Left Behind

Post-`WS_JUSTICE_UNBOUND`, Gorrister Vale is free and back on the Longroad — not robbing
pilgrims this time, but standing at the exact milestone where he committed his worst
crime, unable to decide whether to run or confess. Whether he's genuinely changed or
simply between jobs stays honestly uncertain; the quest resolves in restitution to one
specific family he wronged, not in his redemption being declared for him.

*Key NPC:* Gorrister Vale (canon, `characters.md`).

*Tags:* [post-unbinding] · themes: 2 · Calling hook: none

### The Toll-Keeper Left Behind

Toll-fort keeper Grubb Farrow has collected the same toll from the same eternally-
marching procession for 300 years — a captive audience for terrible jokes and genuinely
excellent maps. When `WS_CHARIOT_UNBOUND` fires and the procession halts, caravans and
fast-travelling strangers pass without needing him at all, and Grubb must learn, late in
a very long life, how to talk to someone who isn't obligated to stop and listen.

*Key NPC:* Grubb Farrow, toll-fort keeper (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Marching Band's Last Tune

Procession drummer Fitch Yarrow has played the same triumphal march for 300 years and
secretly composes new music at night, terrified of what it means to want something the
procession doesn't allow. Once `WS_CHARIOT_UNBOUND` fires, Fitch is the first to play
something new at a newly-active Waystation — nervous, off-tempo, and utterly triumphant
regardless.

*Key NPC:* Fitch Yarrow, procession drummer (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Waystation keeper

---

## The Maw (VIII. Strength)

Savage highlands; a woman holding a lion's jaws forever. `WS_STRENGTH_UNBOUND` makes
beasts neutral-until-provoked.

### The Spring No One's Found

Local hunters swear the Maw's high river simply appears partway down the crags, "born of
the mountain's own will." Pip's nose and some honest climbing lead to the actual source:
a modest spring high in the limestone, exactly where gravity says it should be. The
region's proudest myth turns out to be nobody having climbed high enough to look — a
small, satisfying puzzle rewarding the player who reads the land as land.

*Key NPC:* Herder Sask Combe, who first tells the myth (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: — · Calling hook: none

### The Trophy Hunter's Empty Wall

Wren Astley has built her whole reputation, and her whole self-regard, on being the
Maw's finest beast-hunter — trophies floor to ceiling, a wall of proof. When
`WS_STRENGTH_UNBOUND` fires and the wild goes neutral-until-provoked, hunting stops
meaning what it meant, and Wren spends the quest deciding whether she was ever anything
besides the wall. The Fool doesn't get to decide for her; the ending stays honestly
unresolved, per the region's own dry, hard-won grace.

*Key NPC:* Wren Astley, hunter (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Thirteenth Goat

Every night, one goat from the Shepherd Calling's flock slips away to the same crag and
can't be found until morning. Following her (Pip delighted, obviously) reveals she's
been visiting the frozen tableau of the lion and the woman holding its jaws — closer to
it, unbothered, than any human dares get. [If WS_STRENGTH_UNBOUND: the freed lion and the
thirteenth goat are, against all sense, still inseparable — the game's silliest and
most heart-warming landmark friendship.]

*Key NPC:* none named — features the Lion of the Maw (canon, `characters.md`).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Shepherd

---

## The Dim (IX. The Hermit)

A dusk-locked mountain, one distant lantern. `WS_HERMIT_UNBOUND` returns stars and brings
lost travelers down from the hills.

### The Stream That Starts in the Dark

A lamplighter mentions, in passing, that the Dim's one visible stream seems to vanish
into a ravine and never come out the other side — locals call it "swallowed." Tracing it
(dusk-blind, careful climbing) shows it simply continues underground before daylighting
further down the slope toward the lowlands, exactly where gravity and geology say it
must — a quiet, satisfying answer to a "mystery" that was never supernatural.

*Key NPC:* Lamplighter's apprentice Fenn Dusk (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: — · Calling hook: Lamplighter

### The One Who Stayed

When `WS_HERMIT_UNBOUND` fires and the Dim's lost travelers finally come down from the
hills, the Corvenna family's long-missing son is not among them. Asked to check, the Fool
finds him alive, well, and having built an entire quiet second life on the mountain he
was never actually lost on. Coming home would undo everything he's made of himself; not
coming home means the family's 300-year vigil never gets its ending. The Fool delivers
his answer, not one of their own making.

*Key NPC:* Ansel Corvenna, the "lost" son (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Lamplighter's Count

Eccentric lamplighter Old Wick Hollin has privately counted every lamp still burning on
his rounds for decades, convinced the number means something if it ever comes out even.
It never has. One round in the Fool's company is enough for him to finally admit the
counting was never about the number.

*Key NPC:* Wick Hollin, lamplighter (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Lamplighter

---

## The Wheelhouse (X. Wheel of Fortune)

A gambling city split between eternal luck and eternal calamity. `WS_FORTUNE_UNBOUND`
starts the luck districts cycling.

### The Cursed Side's Quiet Pride

The Wheelhouse's eternally-cursed district has built, over 300 years, a genuine
community out of shared bad luck — gallows humor, mutual aid, a dry solidarity the
lucky side has never needed. When `WS_FORTUNE_UNBOUND` fires and luck begins actually
cycling, one resident's sudden lucky streak threatens to unravel the very solidarity
that got the district through three centuries of misfortune. There's no clean fix; the
Fool can only help the district decide, together, what kind of neighbors they want to be
now that luck is real again.

*Key NPC:* Della Quill, cursed-district elder (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Croupier's Tell

The Wheelhouse's most legendary croupier, "Honest" Marrow Vance, has dealt one perfectly
fair table for 300 years without ever once cheating — tremendous personal pride in a
city that assumes everyone's rigged. He'll teach the Fool the difference between a good
bluff and an honest tell, purely for the pleasure of a student who'll actually listen.

*Key NPC:* Marrow Vance, croupier (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: — · Calling hook: Croupier

### The Lucky House's Debt

On the eternally-lucky side, Ostentation Pryce has lived spectacularly on credit for 300
years, certain his luck can never run out — and technically, until now, it hasn't had
to. The prospect of `WS_FORTUNE_UNBOUND` terrifies him in a way nothing else in his
charmed life ever has. Helping him quietly settle his debts before the wheel turns, or
watching him gamble on his own luck holding one more day, is dry, funny, and a little
cruel — exactly the best Wheelhouse stories.

*Key NPC:* Ostentation Pryce, debtor (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: none

---

## The Assize (XI. Justice)

Courts eternally adjourned; the accused wait in patient queues, knitting.
`WS_JUSTICE_UNBOUND` lands the verdicts.

### The Longest Wait, Decided

Goodman Otho Petts has knitted an almost architectural quantity of scarves awaiting a
verdict on a minor land dispute, patient past all reasonable patience. When
`WS_JUSTICE_UNBOUND` fires, his case is finally heard — and he loses, fair and square,
after 300 years of hope. The dry comedy of the scarves collides with the very real grief
of the wait meaning nothing in the end; Justice, the quest insists, was never a promise
that waiting makes you right.

*Key NPC:* Otho Petts, petitioner (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Queue-warden

### The Scribe Who Copied Nothing New

Court scribe Wilhelmina Coates has spent centuries transcribing the same dead-end
filings with flawless, loving precision, taking genuine pride in penmanship nobody will
ever read. A request for one particular old record turns into an afternoon watching a
true craftsman work — the Assize's driest, gentlest comedy.

*Key NPC:* Wilhelmina Coates, scribe (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Queue-warden

### What the Ninefingers Sold

Post-`WS_JUSTICE_UNBOUND`, Corvin "Ninefingers" Rook is free, and can be pressed —
carefully, since he owes nothing to anyone now — for names of people he once fenced
across the suit-cultures. What turns up is one still-living family, long since given up
for lost, and a reunion that is unambiguously good news wrapped around an unrepentant man
who will absolutely charge for the information.

*Key NPC:* Corvin "Ninefingers" Rook (canon, `characters.md`).

*Tags:* [post-unbinding] · themes: 3 · Calling hook: none

---

## The Gallowwood (XII. The Hanged Man)

Gravity forgot which way it was going. `WS_HANGEDMAN_UNBOUND` rights the forest and
spreads the Hanged Man's peace into the world's barks.

### The World-Tree's Other Visitor

Hermit-adjacent pilgrim Fenwick Sorrel has spent 300 years trying to strike up a real
conversation with the Hanged Man, convinced there's a profound teaching he's simply not
patient enough to receive yet. He isn't wrong that patience is the lesson; he's wrong
that it's a lesson meant for him alone. A whimsical, gently comedy about seeking
enlightenment from someone who's just having a very long nap.

*Key NPC:* Fenwick Sorrel, seeker (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: none

### The House That Faced the Wrong Way

Canopy-dweller Wick Alder built her whole home, and her whole rope-checking trade,
oriented to the Gallowwood's inverted gravity — floor overhead, door underfoot, a life's
competence built sideways to everyone else's. When `WS_HANGEDMAN_UNBOUND` fires and the
forest rights itself, her home is suddenly, quietly upside-down by the world's new
standard, and she must decide whether to rebuild it "correctly" or love it exactly as it
was.

*Key NPC:* Wick Alder, canopy-dweller (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Rope-checker

### The Reversible Knot

An apprentice rope-checker is being taught, by an exacting master, to tie only knots
that can be undone in one pull — "a knot you can't reverse isn't a knot, it's a mistake
with rope in it." A small traversal-flavored teaching quest that doubles as the
Gallowwood's clearest statement of the Hanged Man's whole philosophy, worn completely
lightly.

*Key NPC:* Master rope-checker Corbenic Yew (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Rope-checker

---

## The Stillmarsh (XIII. Death)

Where the dying gather and cannot pass. `WS_DEATH_UNBOUND` returns mortality and unlocks
the Hollows.

### The Lantern Ledger

Old Sallow's newest ferryman's mate has taken to privately recording, in a battered
little book, the name of every soul who's ever waited at the ferry landing and not yet
been able to pass — hundreds of names, kept for no purpose except that somebody ought to
remember they were once here. Finding one particular missing name (misfiled, not lost)
is a small, quiet honor.

*Key NPC:* young ferryman's mate Tarn Loach (canon, `characters.md` §Regional named NPCs); Old Sallow (canon, `characters.md`) present throughout.

*Tags:* [either unbinding] · themes: 1 · Calling hook: Ferryman's mate

### The Family That Waited Right

The Hallow family has kept vigil at the Stillmarsh for their great-grandmother for
generations, taking shifts, believing their patient presence somehow keeps her
comfortable while she "nearly" dies. When `WS_DEATH_UNBOUND` fires, she finally, actually
dies — gently, in her sleep, exactly as everyone always said she would — and the family,
prepared for this for 300 years, discovers no amount of preparation makes the actual
grief smaller. The quest doesn't resolve their grief; it only makes sure the Fool is
present for it, which Old Sallow says is the whole job.

*Key NPC:* The Hallow family, generations of vigil-keepers (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 1, 3 · Calling hook: none

### The Candle That Won't Gutter

Widower Corse Millbank tends a candle for his wife that has burned, unconsumed, since the
night before the Stall — three centuries of wax that never drips. He knows exactly what
it means and tends it anyway, with a dry running joke about the tallow merchant's lost
business. Gentle, funny, aching, and entirely undecided by the quest's end, per the
Stillmarsh's whole character.

*Key NPC:* Corse Millbank, widower (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1, 3 · Calling hook: none

---

## The Confluence (XIV. Temperance)

A delta city where nothing may be finished. `WS_TEMPERANCE_UNBOUND` drains the delta and
lets the rivers reach the sea.

### Where the Two Rivers Actually Meet

The Confluence's mixers argue endlessly over which river is "senior" at the eternal
pour, treated as high philosophy. Careful surveying (and one very wet climb behind the
great cups) shows the two rivers meet exactly where physics says a confluence must, no
matter what doctrine claims — and that the "eternal pour" is simply water that's been
waiting 300 years to finish arriving at the sea.

*Key NPC:* Mixer's apprentice Delphine Marchetti (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: — · Calling hook: Mixer's apprentice

### The Bridge-Broker's Last Case

Diplomat Osgood Fenn has built a genuinely respected career mediating the dispute over
the Confluence's half-finished bridge — a role requiring immense tact given the bridge
cannot, structurally, ever be finished. When `WS_TEMPERANCE_UNBOUND` fires and the delta
drains, the bridge is simply completed by physics, and Osgood's entire profession — and
his rather large sense of self-importance — evaporates in an afternoon.

*Key NPC:* Osgood Fenn, bridge-broker (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Tea That Never Steeps Right

An alchemist has been trying, for 300 years, to brew one perfect cup of tea — always
interrupted at the ideal moment, because nothing here is allowed to finish. Helping her
steal thirty uninterrupted seconds is a small comic caper against a whole region's
metaphysics. [If WS_TEMPERANCE_UNBOUND: she finally gets her cup, drinks it, and is
quietly disappointed it's merely very good tea and not a revelation — the most human beat
in the region.]

*Key NPC:* Alchemist Comfrey Cross (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Mixer's apprentice

---

## The Undervault (XV. The Devil)

A gilded pit where the chained chose their chains. `WS_DEVIL_UNBOUND` breaks them — and
some walk back down.

### Old Nick's Fine Print

Gambler Fessy Dunmore signed a Devil's bargain generations ago for a run of good luck and
now wants desperately out, convinced there must be a loophole in Old Nick's scrupulously
honest contract. There is — the terms were always in plain print — but finding it means
actually reading the whole thing, which nobody, including Fessy, ever has. A dry caper
that plays the Devil's honesty as the joke it always is.

*Key NPC:* Fessy Dunmore, contracted gambler (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: — · Calling hook: none

### The One Who Walked Back Down

When `WS_DEVIL_UNBOUND` fires, the Corrigan family is overjoyed to have their son freed
from the Undervault's chains — and devastated three days later when he quietly walks
back down into the pit, unable to bear a life without the comfort his contract promised.
The family cannot understand it and the Fool cannot fix it; the quest's only mercy is
making sure the goodbye, this time, gets said properly.

*Key NPC:* Wend Corrigan, the one who returned (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 3 · Calling hook: none

### The Vault-Teller's Ledger

Vault-teller Prosper Vane takes tremendous, genuine pride in the most comfortable Calling
in the game, weighing and logging deposits with the serene contentment of a man who has
never once questioned his cage. One offhand, perfectly cheerful line — about how he
hasn't seen actual sunlight in longer than he can remember and doesn't miss it — is the
whole region's darkest comedy in miniature, delivered without a flicker of self-pity.

*Key NPC:* Prosper Vane, vault-teller (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Vault-teller

---

## The Spire (XVI. The Tower)

A tower frozen mid-collapse. `WS_TOWER_UNBOUND` finally lets it fall.

### The Debris Reader

A local fortune-teller has spent decades "reading" the exact configuration of rubble
frozen mid-fall, insisting each hanging chunk's position predicts weather, luck, love. It
is charming nonsense, and the Fool's own arrival is the first thing to genuinely disrupt
her readings in living memory — his presence nudges one piece of debris a visible inch,
to her utter delight and mild panic.

*Key NPC:* Fortune-reader Wisp Callow (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: — · Calling hook: none

### The Spotter's Last Watch

Bell-watch veteran Harrow Brock has built his entire identity around watching, logging,
and lecturing tourists on the Spire's frozen collapse — the region's foremost expert on a
disaster that never finishes happening. When `WS_TOWER_UNBOUND` fires and the Spire
finally falls, Harrow's post is destroyed out from under him, and a family in the town
below loses their home to the very real, non-metaphorical falling debris he spent 300
years failing to meaningfully warn anyone about. The quest sits with both losses without
pretending either cancels the other out.

*Key NPC:* Harrow Brock, bell-watch veteran (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Bell-watch

### The Bell-Watch's Count

The Spire's bell-watch keeps an obsessive strike-log of every lightning hit for 300
years, dry numerical entries that, read end to end, quietly become a kind of poem about
waiting for something to finally finish. The Fool is the first person ever to read the
whole log straight through, which matters more to its keeper than either expects.

*Key NPC:* junior bell-watch keeper, unnamed (proposed — promote to characters.md before
script status); distinct from Harrow Brock above.

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Bell-watch

---

## The Mere (XVII. The Star)

Night-locked lakeland; paused wishes. `WS_STAR_UNBOUND` wakes the wish-wells and fills
the sky.

### What the Lake Holds

Wish-tender Isolde Fenn has quietly wondered for 300 years whether the wishes dropped
into the Mere go anywhere, or simply sit at the bottom forever — the lake, after all, is
one long held breath. A dive (within the region's gentle, no-combat rules) finds the lake
does have a modest, real outlet: a slow spring-fed seep that has, this whole time, been
carrying one coin's worth of wish a year to a marsh three days south. Proof the world was
never as stopped as it looked, in the one region built entirely around looking stopped.

*Key NPC:* Isolde Fenn, wish-tender (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: Wish-tender

### The Last Wisher

Elderly pilgrim Thomlin Reeve has kept vigil beside one specific wish-light for 300
years — his own, made the night before the Stall, for something he can barely bring
himself to name aloud. When `WS_STAR_UNBOUND` fires and the wish-wells wake, his wish is
finally, quietly answered (small and true: a letter, at last delivered, forgiving him for
something old). Having spent three centuries as "the man who's waiting," he doesn't know
how to be anything else, and the Fool can only sit with him while he finds out.

*Key NPC:* Thomlin Reeve, pilgrim (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Pilgrim Who Wished Wrong

A different pilgrim, young and mortified, confesses her wish — made in a moment of petty
spite three centuries ago against a sister she's long since forgiven — and begs the Fool
to help her retract it before it can ever come true. The region's gentle rules mean
there's no danger in this, only comedy and a very real, very old embarrassment finally
spoken aloud.

*Key NPC:* Pilgrim Betsy Marrow (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: — · Calling hook: none

---

## The Mirrormarsh (XVIII. The Moon)

Illusion-fog wetlands; paths, lights, and faces lie. `WS_MOON_UNBOUND` lifts the fog and
reveals the "monsters" as lost people.

### The One Truth in the Fog

A frustrated cartographer, Rue Aldous, has tried for years to map the Mirrormarsh and
failed every time — paths, even landmarks, lie. The insight, with true light in hand, is
that water doesn't: following the marsh's actual water-flow (always downhill, always
toward the one real outlet) cuts a true line through the illusion where nothing else can.
Rue's finished map, framed in her cottage, becomes the region's one reliably honest
document.

*Key NPC:* Rue Aldous, cartographer (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding; requires any true light per world.md's Mirrormarsh gate] ·
themes: — · Calling hook: Fog-warden

### The One Who Didn't Want to Go Home

When `WS_MOON_UNBOUND` fires and the fog's "monsters" are revealed as lost people, one of
them — long assumed a straightforward tragedy by the family searching for him — has
built an entire new life and self in the marsh's fog, and does not want the rescue
everyone else calls a happy ending. The Fool delivers his answer, not the family's hoped-
for one, and the region's post-unbinding joy gets its one honest, unresolved shadow.

*Key NPC:* Corin Vesk, the reluctant returnee (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: none

### The Fog-Warden's Rope

The fog-warden's guide-rope has one frayed, badly-knotted section she refuses to
replace, out of a superstition that a "perfect" rope would stop working — the marsh, she
reasons, likes to be needed as much as anyone. A small, whimsical pre-unbinding beat
about care disguised as ritual.

*Key NPC:* fog-warden Nettle Vance (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: 1 · Calling hook: Fog-warden

---

## The Noonlands (XIX. The Sun)

Golden fields under a sun nailed at noon; drought creeping in. `WS_SUN_UNBOUND` brings
the first sunset in 300 years.

### The Canal That Ran Dry

Farmers blame the Noonlands' spreading drought on the Sun's stalled noon burning the land
dry from above. The truth, findable by walking the region's one irrigation canal to its
source, is more mundane and more fixable: a collapsed culvert, silted for 300 years, has
been quietly starving the western fields long before drought became visible anywhere
else. Clearing it doesn't cure the region's deeper problem, but it does save one farm,
now, honestly.

*Key NPC:* Farmer Thatch Corley (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: — · Calling hook: none

### The Reveller Afraid of the Dark

Harvest-hand and festival dancer Sunny Loft has never once experienced night, has never
needed to, and has built her whole joyful personality around an endless noon that asks
nothing of her but delight. When `WS_SUN_UNBOUND` fires and the first sunset in 300 years
arrives, Sunny is the Noonlands' most frightened resident — not of the dark exactly, but
of the rest it's clearly asking her to finally take. Sitting with her through her first
sunset turns out to be enough.

*Key NPC:* Sunny Loft, harvest-hand (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 2, 3 · Calling hook: Harvest hand

### The Harvest Hand's Wager

A running, good-natured sheaf-toss rivalry between two harvest hands has apparently been
tied, exactly, every single day for 300 years — an impossibility neither will admit
noticing. The Fool's arrival, and one honestly-thrown sheaf, finally breaks the tie, to
the enormous, delighted outrage of both competitors.

*Key NPC:* rival harvest hands Poll and Fenner Straw (canon, `characters.md` §Regional named NPCs).

*Tags:* [pre-unbinding] · themes: — · Calling hook: Harvest hand

---

## The Hollows (XX. Judgement)

Terraced graveyards, gated on `WS_DEATH_UNBOUND`. `WS_JUDGEMENT_UNBOUND` closes every
waiting story and blooms the Hollows.

### The Groundskeeper's Empty Plot

Groundskeeper Yew Halloway has spent 300 years tending one plot reserved, by ancient
arrangement, for a soul who was never actually going to die while the Stall held — a
strange, patient act of hope-as-gardening. When `WS_JUDGEMENT_UNBOUND` fires and the
Hollows finally bloom, that plot is the first to flower, wildly, and Yew must find
something new to tend in a graveyard that's finally, properly at peace.

*Key NPC:* Yew Halloway, groundskeeper (canon, `characters.md` §Regional named NPCs).

*Tags:* [post-unbinding] · themes: 1, 3 · Calling hook: Groundskeeper

### The Long-Overdue's Last Request

An ancient soul who has waited centuries to finally be able to die has one thing left
undone — an apology, decades overdue even before the Stall — and asks the Fool's help
delivering it before Judgement's trumpet can call them on. A quiet errand that makes an
ending feel earned rather than simply arrived at.

*Key NPC:* Elder Petronella Dusk, long-overdue soul (canon, `characters.md` §Regional named NPCs).

*Tags:* [requires WS_DEATH_UNBOUND, before WS_JUDGEMENT_UNBOUND] · themes: 1 · Calling
hook: none

### The Headstone Carver's Practice

A stonemason has taken to carving practice epitaphs for people who haven't died yet —
including, cheerfully, her own eventual one — as a way of making peace with mortality
newly returned to the world. It's funnier than it sounds and sadder than it looks, and
she'll carve one for the Fool too, if asked, delivered as the single best joke in the
Hollows.

*Key NPC:* Stonemason Bess Corrigan (canon, `characters.md` §Regional named NPCs).

*Tags:* [requires WS_DEATH_UNBOUND] · themes: 1 · Calling hook: Groundskeeper

---

## The Axis (XXI. The World)

The still center; a lone dancing figure, visible from everywhere. Always open; no
Calling.

### The Telescope-Makers

A family of lens-grinders has spent four generations building ever-better spyglasses
trying to see the Dancer at the Axis's center clearly, certain that resolving the figure
a little better would answer some question. They are, gently, wrong about what the
answer will turn out to be, and the Fool — who will eventually walk right up to the
Dancer — is the only person who could ever tell them so, and doesn't, because it isn't
kind to yet.

*Key NPC:* the Loach family, lens-grinders across generations (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1 · Calling hook: none

### The Rim-Watcher

An old man has stood at the outermost edge of the Axis's approach for as long as anyone
can remember, watching the still figure at the center, never once stepping closer. He
isn't gated from entering — nothing is — he simply can't make himself, afraid of what it
will mean if the dancing ever stops. When the Fool finally does what he never could, he
asks only one thing: to be told, gently, what it looked like up close.

*Key NPC:* Corvin Rathe, rim-watcher (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 1, 3 · Calling hook: none

### The Silent Wreath-Order

A small order tends the Axis amphitheater's wreath-stone in total, ritual silence,
genuinely believing their unbroken maintenance is what holds the world together. It
never was — the Dancer alone has held it — but the order's one elderly member who
finally admits this aloud, to the Fool alone, does so with the particular relief of a
person setting down an office they never actually needed to carry.

*Key NPC:* Elder Sister Loveday of the Wreath-Order (canon, `characters.md` §Regional named NPCs).

*Tags:* [either unbinding] · themes: 2 · Calling hook: none
