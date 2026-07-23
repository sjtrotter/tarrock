---
id: MQ06
title: The Longest Engagement
type: main
status: script
arcana: VI. The Lovers
region: The Divide
requires: []
fires: [WS_LOVERS_UNBOUND]
branches:
  - [WS_DIVIDE_EASTMARRIED, WS_DIVIDE_WESTMARRIED]
---

# MQ06 — The Longest Engagement

## Introduction

The player reaches the Divide, a canyon splitting two towns that have glared at each
other across an unfinished bridge for 300 years — joined by an engagement that was
never sealed. The way in is Ferryman Pell, the canyon's gossip and go-between, who rows
the Fool across and cheerfully talks both banks' business without ever taking a side.
The player is meant to visit both towns before the bridge — the bride's household on the
east bank, the groom's on the west — and hear each town make its case for a wedding it
has spent three centuries preparing to host and never once holding. At the bridge's
broken end wait the Betrothed, one duelist from each town, fighting as a perfectly
mirrored pair: this is a boss the Fool cannot win with the Bindle, because while the two
are mirrored they cannot be harmed at all. The fight is separation the Betrothed keep
undoing, fought to a standstill — and the standstill forces open the question the whole
canyon has refused to ask for 300 years. The Fool answers it. The wedding happens east
or west, the answer is permanent, and the answer is the killing blow. Because MQ06's
`requires` is empty, this may be the very first Arcana the player unbinds, so nothing
here assumes a Trump already held; if it is reached after MQ13 (Death, "An Ending"), key
scenes carry their `[If CONFESSED: …]` variants — the Betrothed, and Pell, already know
what a Fool who finishes the journey is bringing.

---

## QUEST: THE LONGEST ENGAGEMENT

### EXT. THE DIVIDE: The East Ferry Landing — DAY

THIRD PERSON GAMEPLAY

The road ends at a lip of rock and simply gives up. Below, a canyon so deep the bottom
is lost to blue haze; above, strung between two clifftop towns, an unfinished bridge —
two half-spans reaching toward each other from opposite banks and stopping, arm's length
apart, over nothing at all. Both towns wear wedding bunting. It has faded to the colour
of old bone, and it snaps crisp in a wind that has not once let it rest.

On the east rim, a chapel faces out to a far grey line of sea; on the west, across the
gap, a great stone hall stands shuttered and waiting. Between them the empty air holds
the shape of a ceremony that never happened.

[If WS_HIEROPHANT_UNBOUND: faint on the wind from somewhere far inland, wedding bells
ring a bright new song — the first the Spread has heard in three centuries. Neither town
here answers them. The bunting snaps on, and both chapels stay silent.]

At the water-stair, a flat-bottomed ferry knocks against its post, and FERRYMAN PELL — a
broad, unhurried old man with a pole worn smooth as a bannister and the settled look of
someone who has heard everything twice — lifts a hand without getting up.

**[Tutorial prompt: approach Ferryman Pell at the landing.]**

**FERRYMAN PELL Random Lines** *(repeatable greeting; pick one at random)*

> Fresh face, and both feet still on the same bank. Rare thing round here. Most folk
> have picked a side before they've picked their nose.

> Mind the bunting, friend — it's older than your grandmother and prouder than mine.
> Three hundred years and nobody's had the heart to take it down.

> Down from the road, are you? Then you'll not know the story yet. Sit in the boat. I
> only know the one, but I know it *very* well.

> [If CONFESSED: I've heard about you, you know. The one turning the cards loose,
> ending what won't end. Well. Get in. If anyone in this canyon needs a thing ended,
> it's this lot.]

TRANSITION TO CUT SCENE

### CUT SCENE

The Fool steps down into the ferry. Pell pushes off with one lean of the pole, and the
canyon opens up around them, vast and quiet, the two half-spans passing overhead.

**FERRYMAN PELL**
> Three hundred years ago, the two best houses on this canyon agreed to join. East gives
> her daughter, west gives his son, and the bridge gets finished for the wedding
> procession to cross. Grand idea. Everybody wept. Bunting went up.

**THE FOOL**
> And then?

**FERRYMAN PELL**
> And then the world stopped, friend, right on the day. Bridge half-built. Bride on one
> side, groom on the other, and the small matter of *whose town holds the wedding* never
> quite settled. Been not-settling it ever since.

He poles on, entirely content.

**FERRYMAN PELL**
> Me, I've the best seat in the canyon. Only man who touches both banks. I carry the
> east's letters west and the west's grievances east and I take not one side, because a
> ferryman who picks a bank is a ferryman with half a trade.

END CUT SCENE

### CHOICE DIALOG — Pell's gossip *(all questions may be exhausted)*

| The Fool | Ferryman Pell's response |
|---|---|
| Whose fault was it, really? | Ah, now. Ask the east and it's the west's for wanting the wedding in their fine cold hall. Ask the west and it's the east's pride. Ask me and it's nobody's, which is why it's lasted. |
| Why not just finish the bridge? | Oh, they've tried. Old Cutwright Fenn's crew tries every day of their lives, three generations of them, and they stick on the same plank every time. Bridge isn't waiting on carpentry, friend. It's waiting on a *choice*. |
| Does no one cross at all? | Only me, and only two old ones's letters — an aunt on this bank and an uncle on that, been writing across the gap since before the freeze. Kept the peace their young folk couldn't. Don't tell either town I said so. |
| Can the two just marry anywhere? *(earnest)* | Bless you for asking it plain. No. It has to be somewhere, and somewhere means a bank, and a bank means a town wins and a town loses. That's the whole knot, said kindly. |

**If the Fool asked "Whose fault was it, really?":**

| The Fool | Ferryman Pell's response |
|---|---|
| You sound like you enjoy it. | I'd be a liar to say otherwise, and I'm a ferryman, not a liar — different trade. It's the only story on the canyon. A man grows fond of the thing that fills his days. |

**If the Fool asked "Why not just finish the bridge?":**

| The Fool | Ferryman Pell's response |
|---|---|
| [If CONFESSED] What happens to you when it's finished? | *(a beat; then dry as ever)* Then I've rowed my last, haven't I. Don't fret it on my account. A ferryman who's afraid of the far bank was always in the wrong line of work. |

[All versions pick up here:]

The ferry bumps a landing.

**FERRYMAN PELL**
> There. Two banks, two towns, one wedding that won't happen. Go and let both sides tell
> you it's the other lot's doing. Then go up top, to where the bridge stops. That's where
> the pair of them are. Been standing there a long while.
>
> Whistle when you want ferrying. I'll not be far. I'm never far — it's a boat, not a
> career with prospects.

**[Tutorial prompt: the two towns and the bridge's broken end are marked. They may be
visited in any order.]**

### INT./EXT. THE DIVIDE: The East Town, the Bride's Hall — DAY

THIRD PERSON GAMEPLAY

The east town climbs the cliff in salt-bleached tiers of blue and shell-white, open
collars and open doors — Cups folk to the bone, a town that greets before it asks a name.
Every threshold has a cup set out on it. Every window faces the sea. And every one of them
has a wedding garland hung above it, three hundred years dry.

At the top stands the bride's household hall, and its sea-facing chapel, whose bell has
not rung once since the day the world stopped — the town saving its voice, all this time,
for a wedding.

**[Tutorial prompt: enter the bride's hall and speak with the household elder.]**

An ELDER OF THE BRIDE'S HOUSE — stooped, sea-eyed, a garland kept folded in her lap like
a christening gown — rises to welcome the Fool with both hands, because that is what a Cups
house does before anything else.

TRANSITION TO CUT SCENE

### CUT SCENE

**ELDER OF THE BRIDE'S HOUSE**
> Blessings on your road, and sit, and be welcome — no, don't refuse, we've a cup out and
> a cup out means it's poured. *(she pours)* You've come about the wedding. Everyone comes
> about the wedding, eventually. Even the sea keeps coming back to ask.

**THE FOOL**
> Tell me the east's side.

**ELDER OF THE BRIDE'S HOUSE**
> Our girl. Our chapel, blessed by every one of our dead in the ground beneath it. The
> wedding was promised *here*, with the sea to witness — and if it goes across to that
> cold stone hall over the water, our own dead go unhonoured by the one ceremony they were
> owed, and our girl sails away, and this town has nothing left to wait for.
>
> We are the poorer town, you'll have seen. When the pilgrims come for a wedding by the
> sea, they come *here*. That is all we have coming. That, and her.

She sets a second cup out. Not for the Fool. For the one across the water. It has been set
out, and never drunk from, for three hundred years.

[If CONFESSED: She holds the Fool's gaze a moment longer than is comfortable.]

[If CONFESSED:]

**ELDER OF THE BRIDE'S HOUSE**
> They say you end things. That where you walk, the long pause breaks. Then break ours,
> child — choose, and choose *soon*, while there's still a bride young enough to be one.
> Better a wedding we lose than a wedding that never comes at all.

END CUT SCENE

### CHOICE DIALOG — the bride's house *(all questions may be exhausted)*

| The Fool | Elder of the bride's house's response |
|---|---|
| What is she like? | Kind. Frightened. In love across a canyon with a man she cannot reach or refuse. Same as the day it froze. She's been almost-brave for three hundred years — it's a wearing thing to watch. |
| Why not send her across to marry there? | And lose her *and* the wedding? No. If she must go, let her go married from her own chapel, with her own bell rung, her own dead glad. Send a daughter off honoured, or don't send her at all. |
| What happens to the town if it goes west? | The bell stays silent for good. The pilgrims stop coming. We keep our pride and lose our future, and pride makes a thin soup. But she'd be *married*. I'd take it. I'd hate it, and I'd take it. |
| Would you forgive the west? *(earnest)* | *(a long breath, half a laugh)* Ask me at the wedding. If it's over there, I'll be the old woman crying in the wrong hall — and I'll mean every tear, half grief, half gladness. That's Cups for you. We weep at both. |

[All versions pick up here:]

The Elder pours the untouched second cup back into the jug, gently, and sets the empty
vessel out again. Ready. Always ready.

### BARKS — the east town *(pre-unbinding)*

**East Townsfolk (Cups) Random Lines**

> Gods turn your card, stranger. Mind the garlands — dry as they are, they're the only
> promise we've kept.

> My grandmother sewed that bunting. Her grandmother, I should say. Nobody living
> remembers sewing it, and all of us remember why.

> The bell'll ring for the wedding. That's the arrangement. Silent till the wedding.
> *(quieter)* I'd like to hear a bell before I go. Any bell.

> [If WS_HIEROPHANT_UNBOUND: They've weddings ringing all over the Spread now, they say.
> Everywhere but here. We're saving ours. We've always been saving ours.]

> [If CONFESSED: You're the ending one, aren't you. Don't look so grim. Half this town's
> been hoping for an ending for longer than the other half's been dreading one.]

### INT./EXT. THE DIVIDE: The West Town, the Groom's Hall — DAY

THIRD PERSON GAMEPLAY

Across the gorge — a short ferry, or a long look — the west town is stone where the east
is timber: a proud grey terrace climbing to a great ancestral hall, banners on every
course, a house built by a lineage for the express purpose of one day hosting the
grandest wedding the canyon had ever seen. The hall's doors stand open onto a swept and
empty floor. It has been swept, and stood empty, for three hundred years.

**[Tutorial prompt: climb to the groom's ancestral hall and speak with the household
elder.]**

An ELDER OF THE GROOM'S HOUSE — upright, dry, a ledger of the ceremony's every
arrangement still open on a lectern, its ink not faded because nothing here is allowed to
fade — meets the Fool at the threshold with a formal, weary bow.

TRANSITION TO CUT SCENE

### CUT SCENE

**ELDER OF THE GROOM'S HOUSE**
> You'll have heard the east's version first. Everyone hears the east's first — they've
> the prettier chapel and the sadder eyes. Hear ours now, and judge with a full hand.

**THE FOOL**
> Tell me the west's side.

**ELDER OF THE GROOM'S HOUSE**
> This hall was raised for it. Stone on stone, generation on generation, every one of them
> building toward the single day their line would host the joining of the two towns. That
> is not pride, whatever the east calls it. That is three hundred years of *purpose*, cut
> off one plank short of the door.
>
> If the wedding goes east, this hall is a monument to a party that never came. Our dead
> built a promise, and the promise was hosted somewhere else. What is a lineage that never
> gets to do the one thing it was for?

He turns a page in the open ledger — seating, courses, the order of the toasts — all of it
arranged, none of it ever used.

[If CONFESSED:]

**ELDER OF THE GROOM'S HOUSE**
> And now they tell me an *ending* walks the canyon. Good. Then let it end our way. If the
> pause must break, let it break with our doors full at last — I would rather host one
> wedding and lose the boy after than shut these doors forever on an empty floor. Choose,
> and choose here.

END CUT SCENE

### CHOICE DIALOG — the groom's house *(all questions may be exhausted)*

| The Fool | Elder of the groom's house's response |
|---|---|
| What is he like? | Dutiful. Proud. So afraid of choosing wrong he has chosen nothing for three centuries, and calls it honour. He loves her. He has simply never once been able to say *where*. |
| Why not send him east to marry there? | Then he leaves his seat, his title, his line — everything this house *is* — to be a guest at his own wedding on another man's floor. He'd do it, I think. That's the pity of it. He'd do it and be gladly ruined. |
| What happens to the town if it goes east? | This hall goes dark. The line ends its long errand having never run it. We keep the boy's happiness and lose the whole reason we were a house at all. A cold trade. But his, to make, and never made. |
| Which town deserves it more? *(earnest)* | *(a thin smile)* Deserves. There's the foolish word, and I mean that kindly — you've the right of it by asking. Neither. Both. That is precisely why nobody has been able to say it for three hundred years. |

[All versions pick up here:]

The Elder closes the ledger, then — as if the gesture would be unlucky — opens it again to
the same page. The arrangements wait. Everything here waits.

### BARKS — the west town *(pre-unbinding)*

**West Townsfolk Random Lines**

> Swept the hall this morning. Sweep it every morning. A floor that clean and never danced
> on — it's a strange thing to be proud of, and I am.

> The east has the sea and the sorrow. We've the stone and the standing. Let them keep
> their pretty grief; we've a wedding to be *ready* for.

> Three hundred years ready. You'd think we'd have lost the knack of it. We polish the
> knack. It's all we do.

> [If WS_HIEROPHANT_UNBOUND: Bells ringing new songs the world over, and our hall still
> swept and silent. Ready for a music that never starts. Don't it make you want to *scream*.]

> [If CONFESSED: The ending's come to the canyon at last, they say. About time. A house
> can't stay ready forever. Even stone gets tired of waiting.]

### EXT. THE DIVIDE: The Broken Span — DAY

THIRD PERSON GAMEPLAY

The way to the bridge's end is no way at all — no finished path leads there any more than a
finished bridge does. The Fool reaches it by a rope-and-scaffold traverse rigged over the
gorge: Cutwright Fenn's work, generations of it, ladders and guy-ropes and swaying planks
lashed to the half-span, every rung a small refusal to give up.

A tally is carved into the scaffold's main post — hundreds of scratches, a lifetime of
attempts, the newest ink-fresh. The last legible mark reads *same plank, gods turn its
card.*

**[Tutorial prompt: cross the rope-and-scaffold traverse to the bridge's broken end —
timed balance and grip, no combat.]**

The traverse ends on the flat of the east half-span. Ahead, the stone simply stops at a
clean broken lip, and beyond it: the gap. An arm's length of empty air, and then the west
half-span reaching back the same way, stopped the same distance short.

And on the two lips, facing each other across the gap, stand the Betrothed.

CUT SCENE

They are dressed to be married. They have been dressed to be married for three hundred
years — a gown gone grey, a coat gone thin, garlands crumbled to thread. The bride stands
on the east lip, the groom on the west, each with one hand lifted and reaching across the
gap toward the other, fingers a hand's breadth apart, exactly as far apart as the bridge.
Everything the one does, the other does. Mirrored. Perfect. Frozen mid-reach.

Pip stops at the traverse's end and sits, quiet and entirely at ease, watching the two
reaching figures with the frank attention he gives weather — present, unbothered,
waiting to be needed.

**THE QUERENT** *(quiet, in the Fool's ear)*
> There they are. Closest two people on the whole Spread, that pair. Three hundred years
> reaching, and never once a hand's breadth closer. It'd be funny if it didn't ache.

The Fool steps onto the span. Both heads turn — the same turn, the same tilt, one on each
bank — and regard the intruder with the same weary displeasure.

**THE BETROTHED (East)**
> No.

**THE BETROTHED (West)**
> No. This is not for watching.

**THE BETROTHED (both)**
> There are no onlookers here. There were never meant to be onlookers.

[If CONFESSED:]

**THE BETROTHED (both)**
> And *you*. We know what you are now. Word crosses even this gap. You are the one who
> finishes things — who unbinds a world only to end it. You think we do not know what
> your kind of ending costs?

**THE BETROTHED (East)**
> We have refused a great many things for three hundred years, witness.

**THE BETROTHED (West)**
> An ending most of all.

They lower their reaching hands — the same motion, mirror-clean — and raise them again as
duelists.

END CUT SCENE

### EXT. THE DIVIDE: The Broken Span, the Standstill — DAY

GAMEPLAY: The Betrothed fight as one motion in two bodies — the Fool strikes at the bride
on the east lip and the groom on the west parries the blow that never touched him; every
attack lands on a mirror and does nothing. **While the two are mirrored, they cannot be
harmed at all** — the Bindle passes through the fight like a hand through a reflection.

The only lever is *separation*. The half-spans, the scaffold, and Cutwright Fenn's rigging
give the Fool tools the Union tether is not needed for: pull a guy-rope to swing one span
wide of the other; use a counterweight to drop one duelist a beat behind their mirror;
time a dodge into Fool's Chance to slip inside the instant their motions fall out of sync.
Send Pip with Harry to pin one Betrothed's attention east while the Fool works the west —
Pip's herding is the one thing on the span that can hold one of them still, for a moment.

And it works — for a moment. Each time the Fool pulls the two out of true, the mirror
cracks, a real blow lands, one of them staggers, actually *hurt* — and then, always, both
turn back toward the gap and toward each other and re-mirror, closing the sync, healing the
break, because the only alternative to mirroring the other is *choosing* the other, and
that they will not do.

**THE BETROTHED (both)** *(mid-fight, over the mirrored blows)*
> You cannot separate what refuses to be separated. Pull us apart and we will only reach
> harder. That is the whole of the last three hundred years, witness, and you will not
> undo it with a stick.

The Fool separates them again — harder, cleaner, Pip pinning east, a counterweight dropping
west — and this time they hang apart a long, straining beat, both faces open with something
that is almost relief and almost terror. And then they close it. Again.

**THE BETROTHED (East)**
> Better this than to choose.

**THE BETROTHED (West)**
> Better forever than to lose the other's town its wedding.

**THE BETROTHED (both)**
> Better to reach and never touch than to touch and know what it cost.

The fight settles into the truth of itself: no blow will win it. However well the Fool
fights, the two only re-mirror, and the span comes to a standstill — Fool and Betrothed
and dog, all held, exactly as everything on this canyon has been held for three centuries.
The Bindle cannot finish this. Only the question can.

**THE QUERENT** *(gently, as the standstill holds)*
> There. Feel that? That's the fight ending without being won. Some knots don't cut,
> little Excuse. They're waiting on the one thing nobody in three hundred years would say
> out loud.
>
> You're nobody. You belong to neither bank. Which means you're the only soul who *can*
> say it — and, between you and me and the whole watching canyon, the only one who was
> ever going to have to. Go on. Answer the question they've been dying not to ask.

The reaching hands lift once more, and hold, a hand's breadth apart, over the gap. Both
Betrothed turn their faces to the Fool. For the first time, they are not asking the Fool to
leave. They are waiting.

**THE BETROTHED (both)**
> ...Say it, then. Say where. We have never once been able to.

### CHOICE OPTIONS — the wedding *(first pick commits; confirm prompt)*

[The game makes the weight diegetic before the pick lands. As the Fool draws breath, both
Betrothed speak the rule themselves, so the player knows exactly what an answer is:]

**THE BETROTHED (both)**
> Understand what you are saying before you say it. An answer cannot be unsaid. Name a
> bank, and the other bank loses forever — the reaching stops, the pause breaks, and
> whatever we are now, we will no longer be. Your word is the blow. There is no other kind
> of ending for us.

[Confirm prompt. Both options are permanent; neither is the "kind" choice — the quest's
whole work is that they ache equally.]

| Choice | Consequence |
|---|---|
| **"The wedding happens here. On the east bank."** | `WS_LOVERS_UNBOUND`, `WS_DIVIDE_EASTMARRIED`. The bride keeps her home; the sea-facing chapel, blessed by generations of the east's own dead, finally rings its bell. But the groom leaves his family seat, his title, and his line behind entirely to be married on another town's floor — and the west loses the wedding it spent three hundred years being *built* to host. Its ancestral hall stays swept and empty for good; its dead built a promise that was kept somewhere else. |
| **"The wedding happens there. On the west bank."** | `WS_LOVERS_UNBOUND`, `WS_DIVIDE_WESTMARRIED`. The groom's house finally hosts the ceremony its whole lineage was raised around; the west's long vigil ends, at last, on its own floor. But the bride leaves her home and her sea; her family's chapel falls permanently silent, its bell never rung; and the east — the poorer town, counting on the wedding's pilgrims and trade — loses the one future it had left to wait for. |

**If the Fool chooses the east bank** *(`WS_DIVIDE_EASTMARRIED`)*:

**THE FOOL**
> Here. Marry here, by the sea.

The words cross the gap like a struck bell. The west Betrothed's reaching hand — the groom's
— closes on nothing, and understands, and does not pull away. Instead he *steps*: off his
own lip, across the gap that was never bridged, and the moment his weight leaves the west
stone, the mirror is broken because the two are no longer doing the same thing. One has
crossed. One has stayed. The reflection shatters like ice off a thaw.

**If the Fool chooses the west bank** *(`WS_DIVIDE_WESTMARRIED`)*:

**THE FOOL**
> There. Marry there, in the hall.

The words cross the gap like a struck bell. The east Betrothed's reaching hand — the
bride's — closes on nothing, and understands, and does not pull away. Instead she *steps*:
off her own lip, across the gap that was never bridged, and the moment her weight leaves
the east stone, the mirror is broken because the two are no longer doing the same thing.
One has crossed. One has stayed. The reflection shatters like ice off a thaw.

[All versions pick up here:]

### CUT SCENE

The two Betrothed stand at last on the *same* half-span — one who stayed, one who crossed
the gap that no bridge ever spanned — and for the first time in three hundred years they
are not mirrored, because one of them chose the other. Their joined reach finally closes.
A hand's breadth becomes nothing. They touch.

And the office cracks — in both of them at once, the same instant, the frozen-bride and the
frozen-groom splitting open along the same seam like a single garment coming apart at the
shoulder. Three hundred years of reaching, of nearly, of *no* — all of it flaking away.

Something surfaces under the crack in each of them. Not a wound. Two names, rising the way
a held breath finally lets go — and rising *together*, because they were always going to
have to arrive in the same breath or not at all.

**ELSBETH**
> ...Elsbeth—

**WYSTAN**
> —and Wystan.

**ELSBETH**
> Elsbeth. That's mine. I'd forgotten the shape of my own—

**WYSTAN**
> Wystan. Say it again. Say them together, the way they were always meant to be said.

**ELSBETH and WYSTAN** *(together)*
> Elsbeth and Wystan.

They say it like a vow — the vow, the one that was owed and never given, spoken three
centuries late and not one word less true for it. They are two people now, holding hands on
a broken bridge, dressed in ruined finery, plainly and simply *married*, in the only way
that ever counted.

[If WS_DIVIDE_EASTMARRIED: Wystan looks back once across the gap at the west bank he left —
his hall, his line, his name's whole errand — and then he looks at Elsbeth, and does not
look back again.]

[If WS_DIVIDE_WESTMARRIED: Elsbeth looks back once across the gap at the east bank she left
— her chapel, her sea, the bell she will never hear rung — and then she looks at Wystan, and
does not look back again.]

Elsbeth turns to the Fool. There is no office in her voice now. Only a person, mortified and
grateful in equal measure.

**ELSBETH**
> Three hundred years, and it took a stranger with no dog in the fight — *(Pip, at the
> traverse, tilts his head)* — no offence to the actual dog — to say the one word we
> couldn't. You unwelcome, impossible, necessary witness. Thank you. We are so sorry you
> had to see us like that. We are so glad you did.

Wystan lifts his and Elsbeth's joined hands, and in the gesture, without any flourish,
there is a card between their two palms — Trump VI, offered by both of them at once, because
it could never have been one of theirs to give alone.

**WYSTAN**
> Trump VI. Union, they'll call it. It's the two of us, so it takes the two of us to hand
> it over — that's rather the whole point of the thing. Take it. And take this with it,
> from people who'd know:

**ELSBETH and WYSTAN** *(together)*
> Reaching is not the same as choosing. We reached for three hundred years. It was choosing
> that let us touch.

**[Tutorial prompt: receive Trump VI (Union). Slot it at the next Waystation to try its
effects — Past: Pip's bond deepens (Harry pins two, Seek range doubled); Present: tether
two enemies; Future: a dodge leaves a mirror decoy that taunts. If this is the player's
first Trump, the Pocket Spread's Present slot unlocks now.]**

[If CONFESSED:]

**ELSBETH**
> We spoke cruelly to you, before, about what you are. About endings.

**WYSTAN**
> We were three hundred years frightened of exactly the thing you just gave us. Turns out
> an ending was only ever the far side of a beginning we couldn't reach. If your journey's
> ending is anything like ours—

**ELSBETH and WYSTAN** *(together)*
> —then walk toward it, and don't look down, and for pity's sake choose faster than we did.

END CUT SCENE

### EXT. THE DIVIDE: The Two Banks — DAYS LATER

THIRD PERSON GAMEPLAY

Over the following in-game days the canyon changes in a way three centuries could not
manage overnight: the bridge *completes*. The two half-spans grow toward each other and
meet — the gap that was always the choice made physical, closed now that the choice is
made — and the last plank, Cutwright Fenn's plank, the one that never seated, seats itself
in the night with a sound like a lock turning.

**[Tutorial prompt: the finished bridge is now the way between the towns. Cross it to
continue.]**

At the western foot of the new span stands CUTWRIGHT FENN, staring at a finished bridge he
spent his whole life failing to build. He has his chisel out. He is not sure what to do with
it.

**CUTWRIGHT FENN**
> Done overnight. By a *wedding*. Three generations of us and the same cursed plank, and it
> goes and finishes itself while I sleep, on account of two people finally making up their
> minds.
>
> *(he looks a long moment across the span, then huffs a laugh)* Well. A finished bridge is
> a finished bridge, however it got finished. First Fenn to walk it. That'll do. That'll do
> nicely.

He crosses to the far bank — the first of his line to reach it — and carves one last word
into the new stone rail, beneath three generations of tally scratches: *done.*

Beyond him the two towns are already becoming one thing, and the two things they are
becoming are not the same:

**[If WS_DIVIDE_EASTMARRIED:]** The sea-facing chapel's bell rings — the first sound out of
it in three hundred years, and it does not stop, ringing the wedding the east waited its
whole existence to host. Pilgrims are already on the roads. And across the finished bridge,
the west's great hall stands open on a swept and empty floor that will now stay empty
forever; the wedding it was built for happened across the water, and its doors are being
quietly, permanently closed. In an upstairs room, a west family folds banners into a chest,
packing to cross the bridge and live where the town is going, because there is nothing left
on this side to be host of.

**[If WS_DIVIDE_WESTMARRIED:]** The west's great hall throws open every door, its swept floor
dancing at last, the ceremony three centuries of a lineage was built to hold finally held.
Toasts carry across the gorge. And across the finished bridge, the east's sea-facing chapel
stands dark; its bell, saved all this time for a wedding, will never now be rung, and the
town lets it go silent for good. On the chapel step an east family sits with their bags
packed, watching the pilgrims who used to come for a wedding by the sea take the new bridge
straight over their heads to the celebrations on the far side.

Elsbeth and Wystan, married and mortal and holding hands, walk the finished bridge together
— toward whichever bank is now their home, and away from whichever one is not. Neither of
them looks back at the empty hall or the silent chapel. They have looked back enough for one
lifetime.

### EXT. THE DIVIDE: The Old Ferry Landing — DAYS LATER

THIRD PERSON GAMEPLAY

At the foot of the cliffs, the ferry landing is deserted. The traffic that was Pell's whole
trade walks over his head now, across the bridge, and the flat-bottomed boat knocks its post
with no one in it. FERRYMAN PELL sits in it all the same, pole across his knees, watching the
crossings go by above.

**[Tutorial prompt: speak with Ferryman Pell at the old landing.]**

**FERRYMAN PELL**
> There it is, then. A bridge. Grand thing. Everyone crossing, nobody sinking, everybody
> pleased. *(he pats the gunwale of his idle boat)* And me with the one trade the canyon
> doesn't need any more, on account of it having *two* banks that talk to each other now
> instead of one man who carried the talking.
>
> I always said a ferryman who's afraid of the far bank's in the wrong line of work. Never
> thought the far bank would come to *me*, mind. Reached right across and put my boat out of
> a job.

He is quiet a moment. Then, because he is Pell, he finds the dry end of it.

**FERRYMAN PELL**
> Still. I knew every soul on both banks by their business for three hundred years. A man
> who knows a canyon that well doesn't stop being useful just because the canyon got easier
> to cross. There's a toll-house wants keeping on that bridge, I hear. Same gossip, drier
> feet. Might take it up. Might just sit here and watch the water a while first. I've earned
> a sit.

**FERRYMAN PELL Random Lines** *(post-unbinding; repeatable)*

> Best story on the canyon, and I helped it end. Proud of that. Bit bereft, too. Both at
> once. That's a ferryman for you — always carrying two things across at the same time.

> [If WS_DIVIDE_EASTMARRIED: Hear that bell? Three hundred years I ferried the east's grief
> across and never once heard that bell. Worth losing the trade to hear it. Nearly.]

> [If WS_DIVIDE_WESTMARRIED: Hear that hall? Dancing, at last, on a floor swept flat by
> waiting. Three hundred years I ferried the west's readiness across. Worth it to hear it
> spent.]

> [If CONFESSED: You're off to end the rest of it, then. The whole Reading. Well — you
> ended ours kindly enough. I'll ferry you across for free, the once, for the road. For the
> one taking us all over, eventually.]

### EXT. THE DIVIDE: The Finished Bridge — DAY

THIRD PERSON GAMEPLAY

The bridge stands whole for the first time in three hundred years, spanning the gap that was
never a matter of stone. The Fool walks out onto it — past the halfway mark, past the seam
where the two half-spans met, over the empty air that held a wedding's shape for three
centuries — and reaches the far bank on foot.

**THE QUERENT**
> First person ever to walk clean across, you know. Everyone before you either stopped at
> the gap or paid Pell to go round it. You just — chose a side and kept walking. *(a warm
> pause)* Funny thing about a bridge, little Excuse. It's only ever finished once somebody
> decides which shore they're standing on. The rest is just very hopeful carpentry.

Behind the Fool, the canyon carries its two sounds at once — a bell that will not stop
ringing, or a hall that will not stop dancing, and under either of them, quieter, a chapel
gone dark or a hall gone still. One town got its wedding. One town got the bridge. Both got
a person married, and lost a future, and neither will ever be quite sure the trade was fair.

MQ06 ends here. The roads out of the Divide, long severed by a gap nobody would close, lie
open across the finished span.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Betrothed unbound (standstill + THE CHOICE, either bank) | `WS_LOVERS_UNBOUND` | The Divide is bridged: the two half-spans complete overnight; Cutwright Fenn's cursed plank finally seats; ferry traffic is replaced by bridge traffic; the Fool receives Trump VI (Union), handed over by both Betrothed together. (If Union is the player's first Trump, the Pocket Spread's Present slot unlocks here.) |
| Player chooses the east bank | `WS_DIVIDE_EASTMARRIED` | The bride keeps her home; the sea-facing chapel rings its long-saved bell and pilgrims return; the west's ancestral hall closes for good on an empty floor and a west family packs to cross. The towns unite around the east chapel. |
| Player chooses the west bank | `WS_DIVIDE_WESTMARRIED` | The groom's house hosts the ceremony its lineage was built for; the west hall dances at last; the east's chapel bell falls permanently silent and an east family watches its lost pilgrim-trade cross overhead. The towns unite around the west hall. |

Both branches unbind the Betrothed and complete the bridge identically; they differ only in
which town celebrates and which town mourns. Neither branch is the "correct" or "kind" one —
per the outline's core demand, whichever town wins the wedding still loses a person, and
whichever town loses the wedding still loses the future it built its whole identity around.

## Consistency references

- `arcana.md` §VI. The Lovers — the mirrored-pair fight (unharmable while mirrored; the fight
  is separation the Betrothed keep undoing; damage cannot win), the standstill producing THE
  CHOICE, the answer as killing blow, Trump VI (Union) slots, the unbinding beats. Canon;
  staged, not altered.
- `world.md` §The Divide — two towns glaring across an unfinished bridge and unsealed
  engagement, the gossiping ferry culture; "romantic, ridiculous, quietly sad."
- `world.md` §World-state matrix (`WS_LOVERS_UNBOUND`, branch flags `WS_DIVIDE_EASTMARRIED` /
  `WS_DIVIDE_WESTMARRIED`) — exact world effects: bridge completes, towns unite per choice,
  ferry replaced by bridge traffic.
- `world.md` §Interaction rules — order-independence (MQ06 `requires: []`, so it may be the
  first unbinding; nothing here assumes a prior Trump); the `[If WS_HIEROPHANT_UNBOUND]`
  variants handle the weddings-resume state without depending on it.
- `characters.md` §VI. The Lovers — Elsbeth (east) and Wystan (west); devotion turned
  "exquisite cowardice"; the "unwelcome witness" framing; names never used bound, returning
  together at the unbinding.
- `characters.md` §Regional named NPCs (The Divide) — Ferryman Pell (canon; the neutral
  gossip and the quest's mourner); Cutwright Fenn (SQ-DIVIDE-01, natural reuse in the
  aftermath); the two letter-writing elders (Aunt Perpetua / Uncle Osric, SQ-DIVIDE-03)
  referenced only in Pell's gossip, not staged, to avoid contradicting their side quest.
- `characters.md` §The Minors: suit-cultures — Cups (feeling, hospitality, blessings, quick
  to weep) as the east town's register.
- `narrative.md` §Themes (1: endings are a mercy; 3: freedom isn't wanted by everyone —
  both towns' mourning; 4: the Fool belongs nowhere, which is why only the Fool can say the
  word), §Dialogue style guide (Fool lines ≤ 12 words with one earnest/foolish option; one
  honest beat per comic scene, one laugh per sad scene; storybook British; the one Querent
  wink, spent at the standstill), §Act II (`CONFESSED` variants).
- `npc-system.md` §Bark layers — the pre- and post-unbinding bark sets are layer-3
  world-state pools keyed to `WS_LOVERS_UNBOUND` and the branch flags; the `[If CONFESSED]`
  lines are layer-4.
- `callings.md` §The Divide (Ferry hand → bridge tollkeeper post-MQ06) — Pell's mourning
  and his mooted toll-house are the Calling's world-state successor.
- `progression.md` §The Pocket Spread — Present-slot unlock only if Union is the first Trump
  held (order-independence).
- `quests/TEMPLATE.md` — script format followed throughout.
- Side quests not contradicted: `SQ-DIVIDE-01` (Fenn's bridge crew — his plank seats here,
  as that quest's post-unbinding variant already anticipates), `SQ-DIVIDE-02` (Sculley Marsh
  the ferry hand — see Open questions), `SQ-DIVIDE-03` (the letter-writers — nodded to, not
  staged), `SQ-CUPS-01` (east-bank Cups guest-right — same culture, no overlap).

## Open questions

- Should the East/West household elders (the bride's-house and groom's-house advocates) be
  new named NPCs of their own, or should Ferryman Pell's gossip stand in for their case to
  keep the NPC budget to one proposal? This script keeps them **unnamed** — partisan
  advocates distinct from the canon letter-writing elders Aunt Perpetua and Uncle Osric
  (SQ-DIVIDE-03), who are specifically the *peace-keeping* kin and would contradict a
  partisan role. Carried forward unresolved; the "no new named NPCs" brief keeps them
  unnamed for now, but a promotion pass may want to name them.
- Does either branch have downstream side-quest hooks (e.g., the losing town's elder seeking
  the Fool out later, or the packing family recurring as displaced NPCs across the bridge),
  or does this quest's ache stand alone?
- **Reconcile Ferryman Pell with Sculley Marsh (SQ-DIVIDE-02).** That side quest already
  flags the collision — both are written as "the Divide's gossip ferryman who mourns the
  ferry's obsolescence," and both this quest and SQ-DIVIDE-02 stage that mourning and the
  same toll-house successor. This script keeps the mourning on **Pell** (per the outline and
  `characters.md`) and does not stage Sculley at all, leaving SQ-DIVIDE-02's proposed
  resolution (same character, or owner-Pell / hand-Sculley) open. Resolve across both docs
  before either reaches `implemented`.
- Exact Fortune cost and tuning of Union's Present (Tether) effect is TBD at combat tuning
  per `arcana.md`; not decided here.
