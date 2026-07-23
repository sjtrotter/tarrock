---
id: MQ10
title: Round and Round
type: main
status: script
arcana: X. Wheel of Fortune
region: The Wheelhouse
requires: []
fires: [WS_FORTUNE_UNBOUND]
---

# MQ10 — Round and Round

## Introduction

The player arrives in the Wheelhouse, a casino-city built on a titanic stopped wheel and
split down the middle by luck itself: one side of every street gilded and absurdly
fortunate, the other side ruined and absurdly cursed, and no one has moved house in three
hundred years. The way in is a walk across both halves — a rigged dice parlour on the
lucky side where the player literally cannot lose, and the cursed side's hazard streets
where the player literally cannot catch a break — down into the access tunnels beneath the
Wheel. There the quest's climax is the first thing to actually turn in this whole frozen
casino: a ring-arena that begins spinning the instant the fight starts, sweeping "fortune
weather" — random buff and calamity zones — across the Fool and the Wheel's Blank crew
alike, while the player smashes the brake-shoes seizing the ring. The fight teaches that
fair and random are not enemies. Unbinding the Wheel sets `WS_FORTUNE_UNBOUND`, and from
then on luck cycles: the Wheelhouse's districts trade fortunes on a schedule, and drop
rates world-wide gain small, periodic fortune weather. If the player reaches the Wheelhouse
after MQ13 (Death, "An Ending"), the key scenes carry `[If CONFESSED: …]` variants — by
then the Wheel's presiding spirit can see exactly which way the Fool is spinning.

---

## QUEST: ROUND AND ROUND

### EXT. THE WHEELHOUSE: The Split Street — STATE-DEPENDENT

THIRD PERSON GAMEPLAY

The road opens onto the strangest thoroughfare the Fool has yet walked. One side of the
street is gold: fresh paint, unbroken glass, awnings so new they still smell of dye, a
fountain that runs wine into a basin already full to the brim. The *other* side of the same
street, close enough to spit across, is ruin: sagging roofs, cracked shutters, a signboard
hanging by one nail, a puddle that seems to find every boot no matter where the boot steps.
The gutter down the middle is the exact line between them, and it has not moved in three
centuries.

Over it all, filling the sky at the city's heart, stands the Wheel — titanic, iron-ribbed,
spoked like a cathedral rose window laid flat, and utterly, deafeningly *still*. Every clock
in the Wheelhouse is set to the moment it stopped.

[If WS_SUN_UNBOUND: it is honest day or night now, but the Wheelhouse barely notices — the
gaslamps burn the same gold at every hour, because a casino that lets you see the time is a
casino that lets you leave.]

[If any Arcana already unbound elsewhere: word has run ahead of the Fool. Lucky-siders and
cursed-siders alike sneak the newcomer a second look — the stranger with the white dog who's
been turning cards loose region by region.]

Pip trots straight down the middle of the gutter-line, one paw in fortune and one in
calamity, entirely unbothered by either.

**THE QUERENT** *(as the Fool takes it in)*
> The Wheelhouse. Loveliest, cruellest street on the whole Spread, and it can't tell you
> which half is which without checking the signage. Luck went and sat down here three
> hundred years ago, little Excuse, and it never once got up to swap chairs.

DEUCE HALLOWAY — a lean, grey-templed croupier in a visor and a waistcoat worn shiny at the
elbows, a dealer's shoe of cards under one arm — is doing the one thing nobody else on this
street does: walking *across* the line, lucky side to cursed side and back, sweeping the
gutter with a push-broom as he goes. He clocks the Fool without surprise.

**DEUCE HALLOWAY Random Lines** *(repeatable greeting; pick one at random)*

> New face. Don't stand with your feet either side of the gutter, friend — the House hates
> a hedged bet, and so do my knees.

> Lucky half, cursed half, one broom for both. Somebody's got to sweep the line. Might as
> well be the man who stopped finding it funny.

> [If CONFESSED: I've heard what you are and what you leave behind you. Sweeping's honest
> work while it lasts. Come on, then — I'll walk you in.]

TRANSITION TO CUT SCENE

### CUT SCENE

**DEUCE HALLOWAY**
> Deuce Halloway. Croupier — the *only* croupier who works both districts, which makes me
> either the fairest man in the Wheelhouse or the maddest. Three hundred years I've dealt
> the lucky their wins and the cursed their losses, same hands, same deck, and never once
> got to see which way a card would fall on its own.

**THE FOOL**
> Nobody ever moves across?

**DEUCE HALLOWAY**
> Nobody *can*. You're born your side of the gutter and you die your side of it, except
> nobody here does the dying part either. The lucky can't lose. The cursed can't win. And
> me, I walk it both ways every morning, and I'll tell you the truth I don't tell the
> paying customers —
>
> — it stopped being funny about two hundred and ninety years ago. A joke you can't get out
> of isn't a joke. It's just the room you're in.

He nods up at the vast, motionless Wheel.

**DEUCE HALLOWAY**
> That's the heart of it up there. Turn *that*, and maybe a cursed man catches a good
> morning for once. Maybe a lucky one learns what a bad one costs. Access is down through
> the tunnels, cursed side. But you'll want to see both halves first, or you won't
> understand what you're breaking.

END CUT SCENE

### CHOICE DIALOG — Deuce's Wheelhouse *(all questions may be exhausted)*

| The Fool | Deuce's response |
|---|---|
| Which half is better off? | Ask me on a full stomach and I'll say the lucky. Ask me at three in the morning and I'll say the cursed — at least they've got each other. Luck's a lonely thing to have guaranteed. |
| Why doesn't the Wheel turn? | Same reason the sun won't set two regions over. Somebody up there stopped playing and called it winning. A wheel that can't turn isn't luck, friend. It's a verdict with a paint job. |
| Can I really change it? | You're the first thing to walk in here that the odds don't have a number for. So — maybe. That's more "maybe" than this town's seen in three centuries. |
| Show me the lucky side. *(foolish)* | 'Course you want the lucky side first. Everyone does. Go on — go win a bit. See how long it takes to feel wrong. |

[All versions pick up here:]

**DEUCE HALLOWAY**
> Gilded Parlour's up the lucky side — the house dealer there works the dice, and you cannot
> lose a throw to save your life. Tunnels are down the cursed side, past the falling signs.
> Mind your head over there. Mind everything, really.

He goes back to sweeping the line, one long stroke at a time, cursed to lucky and back.

### INT. THE WHEELHOUSE: The Gilded Parlour — GASLIT

THIRD PERSON GAMEPLAY

The lucky side's dice-hall is a wonder and a horror at once: chandeliers dripping, tables
green as spring, and a crowd of eternally-fortunate players who wear the specific dead-eyed
serenity of people who have not felt a single stake in three hundred years. Winning chips
pile up untouched — there is nothing here anyone still wants to buy. OSTENTATION PRYCE, a
lucky-side debtor draped in staggering finery, holds court at the roulette wheel, betting
sums he does not have against a house that will never collect. *(Walk-on: Pryce's own story
is SQ-WHEELHOUSE-03.)*

**OSTENTATION PRYCE** *(delighted, oblivious)*
> Watch this — everything on the black. Everything I own, everything I *owe*, all of it,
> black. Ha! Black again! It's simply never *not* black, isn't it marvellous, isn't it —
>
> *(a flicker, quickly buried)* — isn't it just going to go on forever.

**[Gameplay: sit at the house dice table. The Fool throws. Every single throw wins —
naturals, doubles, the exact number called, no matter how the dice are cast. There is no
input that produces a loss. A short "keep playing" prompt lets the player throw as many
times as they like; the wins stop meaning anything by the third.]**

The house dealer — a Blank croupier, dealer's visor over a blank oval face, a Ten of Coins on
the tabard — rakes the Fool's guaranteed winnings across with a mechanical, mirthless
courtesy, and pushes the dice back for another throw that will also, inevitably, win.

**THE QUERENT** *(quiet, as the wins pile up)*
> Feel that? That little sag in your chest every time you win? That's the sound of a game
> with the danger taken out of it. Guaranteed fortune, little Excuse. Turns out it's the
> exact shape of no fortune at all — you just can't tell from the outside.
>
> And you *do* keep winning, don't you. Someone's thumb has been on these dice since before
> you were dealt. Not mine — I only ask the questions. But the hand that's holding all of
> this up right now, every roll, every step? That hand has never once thrown honest either.
> Funny old game, isn't it. Do go easy on it.

### CHOICE DIALOG — the rigged table *(all questions may be exhausted)*

| The Fool | The house dealer's response *(a bound Blank; toneless, courteous)* |
|---|---|
| I can't lose. Is that the game? | *(no mouth to answer; a slate propped at the table reads, in the house's own hand:)* THE HOUSE THANKS YOU FOR YOUR CUSTOM. THE HOUSE HAS NEVER LOST. THE HOUSE IS VERY TIRED. |
| Doesn't anyone want to stop? | *(the slate, flipped:)* STOPPING IS NOT A WAGER THE HOUSE OFFERS. PLEASE PLACE ANOTHER BET. |
| Keep the winnings. *(earnest)* | *(the Blank pushes the whole pile gently back across the felt, and points, with a dealer's flat palm, at the door. There is nothing here to spend it on.)* |

[All versions pick up here:]

The Fool leaves the winnings on the felt — as everyone here eventually does — and steps back
out to the gutter-line, where the gold ends and the ruin begins.

### EXT. THE WHEELHOUSE: The Cursed Streets — GASLIT

THIRD PERSON GAMEPLAY

Across the line the city turns to slapstick disaster made permanent. Signboards drop the
instant the Fool passes beneath them; loose cobbles tip underfoot; a ladder that was against
a wall a second ago is now, somehow, exactly where a shin will find it. None of it is
deadly — the White Rose barely notices — but all of it *lands*, relentlessly, the way bad
luck lands on people who've had nothing but.

**[Gameplay: a hazard-traversal stretch toward the tunnel mouth — read the environmental
tells (a creaking bracket, a wobbling stack, a puddle's ripple) and time movement through
falling signs and tipping cobbles. It is chronic bad luck made physical: the exact inverse
of the parlour, and it teaches the same eye the fight will need — watch the space, move with
what it does to you, not against it.]**

The cursed-siders, though — they are the warmest people the Fool has met since the Cliff.
They shout warnings a half-second before each disaster, catch each other's dropped baskets,
and laugh, genuinely, every time the street does its worst. DELLA QUILL, an elder mending a
neighbour's roof that will surely leak again by morning, waves the Fool past a sign about to
fall. *(Walk-on: Della's district and its "Bad Luck Book" are SQ-WHEELHOUSE-01.)*

**DELLA QUILL**
> Mind the bracket, love — no, the *other* — there. See, you learn the rhythm of it. Bad
> luck's only a stranger the once. After that it's just a neighbour with terrible timing,
> and we've made our peace with worse.

**Cursed-Sider Random Lines** *(barks along the hazard streets)*

> Duck! ...Bit late. Sorry. You'll want to trust the "duck" faster than that round here.

> Three hundred years of the roof leaking and I still put the bucket out hoping. That's not
> stupidity, that's *manners*.

> They say the wheel might turn. Won't believe it till a good morning happens to *me*. But
> it'd be nice. It'd be very nice.

The tunnel mouth waits at the cursed street's dead end: a black iron door in the base of the
Wheel itself, unlocked and unguarded, because nobody in three hundred years has had the luck
to reach it or the curse to want to.

### EXT. THE WHEELHOUSE: The Tunnel Mouth — GASLIT

THIRD PERSON GAMEPLAY

A carriage that costs more than the whole cursed street stands parked at the tunnel mouth,
absurdly out of place. BARONESS FETTLE steps down from it — the lucky district's wealthiest
resident, jewelled to the throat, and, beneath the poise, more frightened than her charmed
face has ever had cause to be. She plants herself between the Fool and the iron door.

**BARONESS FETTLE Random Lines** *(repeatable greeting; pick one at random)*

> There you are. I had my people watch every road in. One does not become the richest woman
> in a rigged city by leaving things to chance, dear — that's rather the *point* of me.

> Don't. Whatever it is you came to do to that wheel — don't. I'll make it worth every coin
> you can imagine, and I can imagine a very great many.

> [If CONFESSED: I know what you are now. I've heard what "setting things right" ends up
> meaning, all the way down. You're not here to fix a wheel. You're here to start it rolling
> toward the last card, aren't you.]

TRANSITION TO CUT SCENE

### CUT SCENE

**BARONESS FETTLE**
> Let me be plain, because I am always plain about money and never about anything else.
> Everything I have — this carriage, my house, my *name* — is built on that wheel staying
> exactly where it is. A rigged game where I hold every winning number. Turn it, and my
> fortune has to survive an honest morning for the first time in three centuries. It won't.
> *I* won't.

**THE FOOL**
> You'd keep the whole city frozen? For you?

**BARONESS FETTLE**
> Don't say it like that. I'd keep it frozen because *frozen is safe*, and a fair wheel is
> the most dangerous thing I can imagine. You've seen the cursed side. You think a real
> chance is a kindness. Dear, a real chance is a thing that can go *wrong*. I have spent
> three hundred years never once finding out what that feels like, and I should like to
> keep it that way.

**BARONESS FETTLE**
> [If CONFESSED: And it isn't only my money any more, is it. I've done the sums the others
> won't. Every card you turn loose winds this world a notch closer to done. So no — this
> isn't a bribe for a fortune. It's a bribe for *forever*. Name your price for leaving
> forever alone.]

END CUT SCENE

### CHOICE DIALOG — Fettle's offer *(first pick commits; the door opens regardless)*

| The Fool | Fettle's response |
|---|---|
| Keep your coins. I can't spend them. *(earnest)* | ...No. No, of course you can't. What a horrifying thing you are — a card with nothing to lose. There's no thumb heavy enough for those dice. |
| What are you so afraid of? | *A roll I can't call.* One honest throw where the wheel owes me nothing. I'd sooner be cursed, if you must know — at least the cursed know how their story goes. |
| I'll take the bribe. *(foolish)* | *(she brightens, then falters as the Fool steps past her toward the door anyway)* You — you're not even going to — oh. Oh, you were never going to stop, were you. Nobody told the new card the rules. |

[All versions pick up here:]

Fettle does not physically bar the way — she cannot; luck has never made her strong, only
comfortable. She steps aside, and her voice drops to something almost honest.

**BARONESS FETTLE**
> Go on, then. Break the one thing that ever kept me safe. But when it's spinning and you're
> gone, remember I *told* you — nobody down here ever asked to find out what a fair chance
> feels like. We just lost the argument.

The Fool opens the iron door. Cold, still air breathes up out of the dark under the Wheel.

### INT. THE WHEELHOUSE: The Access Tunnels — DARK

THIRD PERSON GAMEPLAY

Down under the city the noise finally stops. The tunnels run between the great iron
brake-shoes that clamp the Wheel's rim from below — each one a wagon-sized wedge of black
metal, driven hard against the ring and glowing faintly at the point of contact, as though
even holding still costs the machine something. Chains as thick as the Fool's waist run
slack where three hundred years ago they ran taut.

**[Gameplay: a short descent past the seized machinery — the brake-shoes shown up close, so
the player reads the fight's objective before the fight names it. No combat. A Waystation
sits at the tunnel's midpoint, tucked in an old maintenance shrine; resting regrows the Rose
and lets the player set the Pocket Spread before the encounter.]**

[If WS_CHARIOT_UNBOUND: the Waystation glows as a fast-travel anchor — the first way in or
out of the Wheelhouse's underworks that doesn't cost a walk through both districts.]

Ahead, the tunnel opens into the base of the Wheel itself: a vast circular chamber, floored
in inlaid segments like a roulette wheel laid flat, ringed by a silent gallery of Blank
croupiers standing motionless at their stations. It is the first true quiet in the whole
Wheelhouse — the held breath before a throw.

**THE QUERENT** *(hushed)*
> Listen to that. Nothing. First quiet this town's had since it forgot how to turn. Savour
> it, little Excuse. You're about to be the one who ends it.

At the chamber's centre, on a dealer's dais that rotates a slow half-inch and then catches,
straining against its own stuck bearing, stands the Wheel of Fortune.

TRANSITION TO CUT SCENE

### CUT SCENE

Light blooms across the chamber — every gaslamp, every gilt segment, snapping alight at once,
and the presiding spirit of the Wheelhouse rises grinning from the dais like a game-show host
walking out to the biggest crowd of a career that never had a second night. Bound, theatrical,
radiant, and — under the glitter — bone-tired in a way three centuries of showmanship can't
quite paint over.

**WHEEL OF FORTUNE**
> *Well* now. Round and round and round she'd go — if only somebody would give her a
> *push!* Three hundred years the House has kept every chair, dealt every hand, called every
> number, and never once — not *once* — got to see which way a card would fall on its own.
> And here comes a stray little nothing with a dog, wandered in off the losing streak of the
> whole world.

**THE FOOL**
> I came to make it fair.

**WHEEL OF FORTUNE**
> *Fair!* Oh, that's the loveliest filth anybody's said in this chamber in an age. You think
> fair and *fun* are on the same side, do you? Everyone does, right up until the odds sit
> down across the table. But the House has a soft spot — the House cannot *help* a soft spot
> — for a variable it can't price. So here's the wager, wanderer:

**WHEEL OF FORTUNE**
> [If CONFESSED: — and don't think the House can't see which way you're spinning, hm? Card by
> card, region by region, straight toward the very last number on the board. We'll get to
> that. We always get to that. But first —]
>
> — knock the shoes off the rim. Every last brake. Do it, and she turns. Fail, and you join
> the gallery, and the House deals you in *forever*. Place your bets. Let's! Play!

END CUT SCENE

### THE ENCOUNTER — the Turning Ring

THIRD PERSON GAMEPLAY

**[Gameplay, exactly per `arcana.md` §X:]**

**[The instant the fight begins, the ring-arena starts to turn — grinding, shuddering, then
smoother — the first true motion in the Wheelhouse in three hundred years. The Fool fights on
a floor that is rotating beneath their feet.]**

**[The objective is the brake-shoes: several wagon-sized iron wedges clamped around the ring's
rim, glowing where they grip. Each must be smashed. As shoes fall, the ring turns faster and
freer, and the fight's whole feel accelerates with it.]**

**[Fortune weather sweeps the arena. The rotation drags shifting zones across the floor —
segments of blessing and segments of calamity — and, crucially, they hit *everyone* standing
in them: the Fool AND the Wheel's Blank crew alike. A wash of gold steadies the hand and
mends a scratch; a squall of bad luck fouls footing and drops sparks from the rig above; and
half a dozen more besides, cycling as the ring carries them round. The exact weather set is
tuned at combat pass — do not fix it here.]**

The Wheel's Blank crew — croupiers, rakers, and dice-callers in dealer's visors, each bearing
a Coins or a mixed-suit card on the tabard — join the fight as lesser enemies. And the game's
own lesson plays out in the comedy: a Blank caught in a bad-luck squall slips on nothing, its
card fluttering loose to raise a new bearer elsewhere; a Blank washed in gold steadies and
comes on harder. The weather does not take sides. That is the entire point.

**WHEEL OF FORTUNE** *(mid-fight patter, delighted, from the shifting dais)*
> Ohh, you're *reading* it! Look at that — riding the good weather, ducking the bad, dancing
> with a wheel instead of shoving at it! Nobody's played the House like a partner in three
> hundred years! More! MORE! Round we GO!

**THE QUERENT** *(over the din, easy)*
> There it is. Stop fighting the luck and start *surfing* it — good zone, hit hard; bad zone,
> get gone; let the wheel bring the next one round. Fair and random were never enemies, little
> Excuse. They're just two hands of the same dealer.

**[Gameplay: as the last brake-shoe cracks, the whole ring lurches free with a groan that
shakes dust from three centuries out of the gallery rafters — and turns. Truly turns, for the
first time since the Stall, smooth and enormous and unstoppable, carrying Fool, Blanks, and
Wheel all round together in one long, giddy revolution.]**

The Blank crew, mid-swing, simply... stop fighting. One by one they look up — visorless faces
somehow watching — at the ceiling wheeling past overhead, and the fight dissolves not in
defeat but in wonder, dealers setting down their rakes to feel the floor move under them for
the first time in their unremembered lives.

TRANSITION TO CUT SCENE

### CUT SCENE — the Unbinding

The Wheel of Fortune stands at the centre of the turning ring, arms flung wide, laughing —
and then the office cracks. The game-show glitz, the host's grin, the three-hundred-year
patter: it comes apart like gilt flaking off a fairground sign, and underneath is just a
person, dizzy and delighted and suddenly, wonderfully unsure.

**WHEEL OF FORTUNE**
> It's — oh. Oh, it's *moving.* One does forget. One forgets there was ever a before the
> stopping, and then it moves and there's a — there's a *name* under all the noise, there's —

She stops. Puts a hand to her chest as the ring carries her slowly round. Something surfaces
the way a coin comes up out of a fountain — bright, and hers, and long, long lost.

**WHEEL OF FORTUNE**
> ...*Penny.* Penny Farthing.

She says it and then laughs at it, giddy, tasting the small daft music of it — a penny and a
farthing, the least and the littlest of change, and a great wheel besides.

**PENNY FARTHING**
> Penny Farthing! Of *course.* Smallest coins in the purse and the biggest wheel in the
> world, all in the one silly name. I'd forgotten I was ever a person and not just a *verdict
> in a nice frock.* Oh, that's much better. That's ever so much better.

She turns to the Fool — and there is nothing bound about her delight now, only a person
looking at the strangest, best thing to happen to her in three hundred years.

**PENNY FARTHING**
> Do you know what you *are?* Three centuries the odds ran this town and every soul in it had
> a number stamped on them the day they were dealt — lucky, cursed, rich, ruined, sorted and
> settled and never once surprising. And then in walks *you.* No number. No odds. Nothing the
> House could price.
>
> The first unpredictable variable in three hundred years. Turn my whole wheel over with a
> dog and a stick, and the House never saw you coming — because there was no *coming* to see.
> Oh, I could kiss you. I shan't. But I could.

**PENNY FARTHING**
> [If CONFESSED: And I can see the rest of it, dear, plain as a called number — the way you're
> spinning. Card by card, straight for the last one on the board, the one that ends the whole
> game. *(lightly, between two truths)* You unfroze me knowing what unfreezing everything
> finally costs. That's not cruelty and it's not innocence. That's just what a Fool does when
> a Fool's done standing still. I'd not have it any other way. Round we go.]

She reaches into the turning air and draws out a card — no flourish, no patter, just a spin of
the wrist and there it is — and hands it to the Fool herself, delighted, like passing the dice
to the one player at the table she actually likes.

**PENNY FARTHING**
> Trump the Tenth. *Spin* — one throw off the House's own table, one of eight ways it can land,
> and you'll learn the whole set if you play it enough. That's the trick nobody ever learned
> down here: the wheel was always *knowable*. Fair and random, dear, dancing partners the
> pair of them. Go on. Give the world a good turn on my account.

**[Gameplay prompt: the Fool receives Trump X (Spin). Slot it in the Pocket Spread to try its
Present effect — a single throw off the fixed, learnable table.]**

END CUT SCENE

### EXT. THE WHEELHOUSE: The Split Street — AFTERMATH

THIRD PERSON GAMEPLAY

Up top, the whole city has felt it. The great Wheel fills the sky and it is *turning* now,
slow and majestic, and along the split street the impossible is happening in real time: the
gutter-line is *drifting.* A cursed shutter, for no reason it has ever been given before,
swings shut clean on its hinge. A lucky fountain, for the first time in three hundred years,
runs a little short. Luck has stopped being a verdict and started being *weather* — and weather
moves.

[If WS_SUN_UNBOUND: and for once the Wheelhouse lets a clock be honest — the gaslamps dim as
real evening comes on, and nobody minds, because now there's a morning worth waiting up for.]

Baroness Fettle stands where her carriage was, watching the gutter-line creep toward her side
of the street. She holds a single die in one gloved hand, turning it over and over, and for the
first time in three centuries she cannot tell you what it will show.

### CUT SCENE — Fettle's Mourning

**BARONESS FETTLE**
> I've fought duels. Did you know that? Ordered ruin on rivals, faced down creditors, once
> stared a mad Arcanum in his stopped-clock eyes and did not blink. And *this* —

She holds up the die. Her hand is not quite steady.

**BARONESS FETTLE**
> — a die I might *lose.* An ordinary roll that owes me nothing. It's the most frightened I've
> been since before the world stood still, and it hasn't even landed yet. That's your gift to
> me, card. You didn't curse me. You did something so much worse. You made me *play.*

She rolls it, once, against the cobbles — and then can't bear to look, and turns away before it
settles, and walks back toward a lucky house that is, from this evening on, only as lucky as
the next honest morning allows.

END CUT SCENE

### EXT. THE WHEELHOUSE: The Cursed Streets — EVENING

THIRD PERSON GAMEPLAY

Across the gutter-line, the opposite. As the districts' fortunes begin to trade on the Wheel's
new schedule, the cursed side gets its first good turn in three hundred years — and pours into
the street to meet it. A signboard stays *up.* A roof, mended that morning, does not leak.
Someone wins a hand of cards fair and honest and simply cannot stop laughing. The whole
district spills out cheering, loud enough to drown out any dread drifting over from the gilded
half — at least for one evening.

Della Quill stands in her doorway with the Bad Luck Book under her arm, watching her neighbours
dance in a street that isn't trying to kill them, and shakes her head, grinning.

**DELLA QUILL**
> Three hundred years I've written down every rotten thing that happened on this street so we
> could laugh at it together of an evening. *(she opens the Book to a fresh page)* Suppose I'd
> best start a second column. Good luck's going to need writing down too, now — else who'd
> believe us.

**Cursed-Sider Random Lines** *(post-turn celebration barks)*

> It stayed UP! The sign stayed UP! Get everyone, get *everyone*, the sign stayed up!

> First good morning of my whole life and I'm three hundred years old for it. Better late,
> better late, better anything than never.

> [If CONFESSED: someone in the dancing crowd calls out, only half joking —] Here — if the
> world's really winding down like they say, how many good turns have we got left, then? ...Ah,
> never mind. Enough for tonight. Tonight's enough.

Deuce Halloway leans on his broom at the drifting gutter-line, watching both halves at once, and
for the first time in nearly three hundred years, something at the corner of his weary mouth
looks a great deal like it might, given a moment, become a smile.

**DEUCE HALLOWAY**
> Well. There's a first. Two crowds on one street and I can't tell you which of 'em's the lucky
> one tonight. *(he sets the broom aside)* Reckon I'll leave the line unswept a while. See where
> it wanders. Been a long time since I didn't know how a thing was going to land.

The road on out of the Wheelhouse lies open, and every street behind the Fool is turning.

### BARKS — the Wheelhouse *(post-turn, both districts)*

**Lucky-Sider Random Lines**

> Lost a hand of cards this morning. First time ever. Cried a bit, then wanted to play again
> straight off. Is that — is that normal? Is that what you all *feel?*

> The fountain ran short today. I stood and watched it like it was a miracle. Suppose it was.

**Cursed-Sider Random Lines**

> Bought a lottery ticket out of habit. Habit of *losing*, mind. And then it — well. Come round
> the house, you have to *see* it.

> Wheel's on our side this week, they reckon. Next week it won't be. And you know what? That's
> the most fair a thing's ever been to us. We'll take the turn *and* the losing of it.

**Croupier (Blank crew) Random Lines** *(the freed Wheel-crew, now dealing honest tables)*

> [The Blank dealers still bear their cards and still cannot speak — but their slates now read:]
> THE HOUSE NO LONGER ALWAYS WINS. THE HOUSE FINDS THIS ENORMOUSLY INTERESTING. PLACE YOUR BET.

*(Walk-on nod: "Honest" Marrow Vance, the one croupier who dealt fair even while the Wheel was
stopped, now finds his lonely three-century virtue is simply how everyone plays — his story is
SQ-WHEELHOUSE-02.)*

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Penny Farthing unbound (final brake-shoe + cutscene) | `WS_FORTUNE_UNBOUND` | The Wheel turns again: the Wheelhouse's luck districts begin cycling their fortunes on a schedule (dynamic region); world-wide drop rates gain small, periodic "fortune weather." The Fool receives Trump X (Spin) and may slot it in the Pocket Spread. Downstream Wheelhouse content unlocks (SQ-WHEELHOUSE-01 requires this flag; SQ-WHEELHOUSE-02's `[If WS_FORTUNE_UNBOUND]` variant and SQ-WHEELHOUSE-03's coda both key off it; the Croupier Calling's odds begin to vary). |

## Consistency references

- `arcana.md` §X. Wheel of Fortune — the rotating ring-arena that begins turning as the fight
  starts; fortune weather (buff/calamity zones) hitting player and the Wheel's Blank crew alike;
  brake-shoes as the objective; the "fair and random are not enemies / dance partner" lesson;
  Trump X (Spin) and its fixed, learnable 8-entry table (contents TBD at combat tuning — staged,
  not altered here); `WS_FORTUNE_UNBOUND` as the unbinding flag.
- `world.md` §The Wheelhouse — the casino-city on the titanic stopped wheel; the lucky/cursed
  street-by-street split; the "no one may move house" rule; economy hub, dense side-quest den.
- `world.md` §World-state matrix (`WS_FORTUNE_UNBOUND`) — exact world effect: luck districts
  begin cycling; world-wide periodic fortune weather.
- `characters.md` §X. Wheel of Fortune (Penny Farthing; she/her) — genial, theatrical,
  quietly aware that a wheel that cannot turn is a verdict not luck; delights in the Fool as the
  first unpredictable variable in 300 years. §Regional named NPCs — The Wheelhouse: Deuce
  Halloway (weary line-walking croupier), Baroness Fettle (this quest's mourning NPC), and
  walk-on nods to Della Quill, "Honest" Marrow Vance, Ostentation Pryce (their own side quests).
- `narrative.md` §Themes 1 (endings are a mercy; a frozen "win" is the villain, not the Wheel),
  2 (offices eat people; Penny's name returns at the unbinding), 3 (freedom hurts someone
  ordinary — Fettle), 4 (the Fool is nobody, hence the unpriceable variable); §Dialogue style
  guide (storybook British; Fool lines ≤ 12 words with an earnest/foolish option; bound Arcana
  never pair "I" with a personal name; one Querent wink per quest; melancholy rule); §Act II
  (`CONFESSED` variants).
- `npc-system.md` §Bark layers — Wheelhouse bark pools authored here (layer-1 quest-scripted and
  layer-3 `WS_FORTUNE_UNBOUND` deltas for both districts); the "NPCs are aware" pillar drives the
  pre/post-turn split and the rumor-preceded arrival variant.
- `callings.md` §The Callings — Croupier ("Deal a simple honest table game"; post-MQ10 odds
  actually vary), reflected in the freed Blank crew's post-turn slates.
- `quests/TEMPLATE.md` — script format followed throughout.
- Cross-checked against SQ-WHEELHOUSE-01/02/03 (no contradictions; the named side-quest NPCs
  appear only as walk-on nods, their arcs left to their own docs).

## Open questions

- The Spin table's 8 entries remain TBD at combat tuning in `arcana.md` — this script stages the
  handover ("one of eight ways it can land, learnable") without fixing the set; flag for the
  fight's final beat-by-beat pass, and confirm whether the unbinding cutscene's tutorial cast of
  Spin should be a discounted or free first throw (cf. MQ01's Manifest first-cast question).
- The arena "fortune weather" zone-set (distinct from Trump X's Spin table) is likewise left to
  combat pass; this script names a few evocative zones (gold/steadying, bad-luck squall) as
  flavor only — confirm the tuned set and how many brake-shoes the fight uses.
- Should Baroness Fettle recur as a later Wheelhouse side-quest antagonist protecting her fading
  fortune, or does her arc close at this quest's mourning beat? (Carried forward from the outline;
  still unresolved. If she recurs, her `die she cannot call` here is the natural seed.)
- Does the Wheelhouse Waystation predate MQ10, or only appear/activate with the tunnels opened
  for this quest? Placed here at the tunnel midpoint for pacing; confirm against the region's
  Waystation placement once the Wheelhouse is greyboxed.
