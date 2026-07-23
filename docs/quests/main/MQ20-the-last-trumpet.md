---
id: MQ20
title: The Last Trumpet
type: main
status: script
arcana: XX. Judgement
region: The Hollows
requires: [WS_DEATH_UNBOUND]
fires: [WS_JUDGEMENT_UNBOUND]
---

# MQ20 — The Last Trumpet

## Introduction

The player can only reach the Hollows after Death has been unbound — this is one of the
game's two hard story gates (`world.md` §Hard and soft gates), and it is diegetic:
Judgement cannot call souls that cannot leave. Because MQ13 is a hard prerequisite, the
global `CONFESSED` state is always set the moment the player arrives here — every scene
below plays in the post-confession world as its *baseline*, not as an `[If CONFESSED]`
variant. There is no un-confessed version of this quest to write, and that is by
construction, not omission (see the always-confessed note below).

The Hollows are terraced graveyards ringing the Axis approach, tended for three hundred
years by a Herald with a trumpet and no one yet able to answer its call. Since Death was
unbound, the terraces have filled — with the newly-able-to-die and the long-overdue, all
waiting to be called on. The player crosses the terraces (meeting a waiting spirit, a
reluctant ghost named Fennimore Ashgrove, and the region's inert ancestor shrines) and
descends to the amphitheater of open graves, where the Herald waits. The fight is a
conversation between two Trumps: the Herald's trumpet re-raises the Fool's fallen enemies
on a meter the player can watch fill, and — if Passage (Trump XIII, always in hand by now,
since Death is required) is slotted — its Reap execute denies the resurrection outright.
Kill order is the whole puzzle. Unbinding the Herald fires `WS_JUDGEMENT_UNBOUND`: every
goodbye in the game arrives at once, the Hollows bloom, and the ancestor shrines give
their final gifts. The quest must earn that "every goodbye at once" line, and play the
emptying as release, not horror.

---

## [If CONFESSED] — the always-confessed baseline

This quest is hard-gated behind `WS_DEATH_UNBOUND` (MQ13), and completing MQ13 is the
event that sets the global `CONFESSED` state (`world.md` §Global states; `narrative.md`
§Act structure). Every scene here is therefore, by construction, post-confession — the
Hollows already know exactly what a visit from the Fool means, and are glad of it. There
is **no un-confessed variant to write**, and this is stated explicitly rather than
silently omitted, since every other main quest from MQ02 onward is expected to carry
both. Where this quest still varies is **how far the journey has progressed** at time of
play: MQ20 is reachable in either `ACT_II` (7–14 unbound) or `ACT_III` (15–21), and the
goodbye wave in the aftermath scales in volume and specificity with the Arcana count, not
with `CONFESSED` — those variants are written `[If ACT_II]` / `[If ACT_III]` below.

---

## QUEST: THE LAST TRUMPET

### EXT. THE HOLLOWS: The Terraced Approach — LOW LIGHT / STATE-DEPENDENT

THIRD PERSON GAMEPLAY

The road down from the last region gentles into terraces — long shelves of turned earth
and worn headstones stepping down and down toward a low centre the eye keeps sliding
back to. Every grave here stands open: not violated, not dug, simply *unlatched*, the way
a door stands open for someone expected. Nothing is overgrown. Three hundred years of
tending shows in every level path, every weeded verge, every headstone set true. It is
the most cared-for place the Fool has yet walked, and there is not one living soul in
sight — only the pale, patient shapes of those waiting between the stones, turned toward
the centre, none of them in any hurry.

[If WS_SUN_UNBOUND: a real dusk lies over the terraces now, the first the Hollows have
ever kept — long gold light going blue in the open graves, and a proper darkness gathering
in the low centre.] [Else: the light here never changes — a held, even greyness, the
colour of the hour before a thing is decided, that has been the hour before a thing was
decided for three hundred years.]

**[Combat prompt: none yet. The waiting spirits do not stir as the Fool passes. This
approach is a walk, deliberately — the region introduces itself before it asks anything.]**

Pip does not run ahead here. He walks close to the Fool's heel, ears half-down, tail low
and slow — not frightened, exactly. Respectful. The way a dog is in a house where someone
is sleeping.

**THE QUERENT**
> Mind your feet, little Excuse. This is the Hollows — the last graveyards before the
> Axis, and the only ground in the whole Spread that was *never* barred to you. It's been
> standing open this entire time. It was only ever waiting for permission.

A beat. Wind moves along the terraces without disturbing a single blade of the trimmed
grass.

**THE QUERENT**
> You gave it that, you know. Back in the Stillmarsh. Every grave down here came unlatched
> the hour you let Death go. They just haven't been *called* yet. That's the last piece.
> That's what's still waiting.

### EXT. THE HOLLOWS: The Waiting Terraces — LOW LIGHT

THIRD PERSON GAMEPLAY

The Fool crosses a broad shelf of the terraces where the waiting are thickest — dozens of
pale spirits standing among the open graves, each at their own stone, faces turned down
toward the amphitheater. None reach for the Fool. None mob. They simply notice, the way a
long queue notices a newcomer: a small settling of attention, and then patience again.

One spirit nearest the path — an old figure, unhurried, hands folded — inclines their head
as the Fool draws level. Where a Blank has a blank oval, this one has the worn suggestion
of a real face, gone soft at the edges like a coin handled for centuries.

**A WAITING SPIRIT approaches the Fool.**

**A Waiting Spirit Random Lines** *(repeatable greeting; pick one at random)*

> New feet. We don't get new feet down here. We don't get *anything* down here, really —
> that's rather the arrangement.

> You'll be the one, then. The one who lets things go. Take your time. We've had practice
> at that. We've had nothing *but* practice at that.

> Mind the low ground. That's where the caller stands. She's been standing there longer
> than any of us have been lying here, if you can credit it.

TRANSITION TO CUT SCENE

### CUT SCENE

**A WAITING SPIRIT**
> Three hundred years I've stood at this stone. My own stone — I'll show you the name, if
> you like, though it's stopped meaning much even to me.

**THE FOOL**
> Isn't that a terrible thing to wait for?

**A WAITING SPIRIT**
> Oh, it was. The first year it was dreadful. The fiftieth, less so. Somewhere round
> there it stopped being a grief and started being a *Tuesday*. You'd be astonished what
> a soul can make ordinary, given the centuries to practise.

He says it without a scrap of self-pity — the way a man describes the weather he has
always lived in and no longer notices.

**A WAITING SPIRIT**
> [If CONFESSED: We know what you are, mind. Word came down with the last card you turned.
> You're the ending, come walking. Don't look so stricken about it — you're the best news
> this hillside has had since it was dug.]

END CUT SCENE

### CHOICE DIALOG — the waiting spirit *(all questions may be exhausted)*

| The Fool | The Waiting Spirit's response |
|---|---|
| What are you all waiting for? | The trumpet, dear. One clear note with our name in it. Three centuries she's had the horn to her lips and not once been let to blow it true. |
| Doesn't the waiting hurt? | It did. Then it was Tuesday. Now it's just — *long*. There's a difference, and you learn it about year fifty, and not a day before. |
| Who's "she"? | The one in the low ground. The caller. Don't call her by any name — she hasn't got one to give, poor soul. That's rather the whole trouble down here. |
| I'll have you called soon. *(earnest)* | I believe you will. First soul in three hundred years to say so and mean it. Go careful getting there. She won't make it easy — not out of spite. Out of *habit*. |

[All versions pick up here:]

The waiting spirit folds his hands again and turns back toward the low centre, patient as
the stone he stands beside. The way on descends.

### EXT. THE HOLLOWS: The Restless Terraces — LOW LIGHT

THIRD PERSON GAMEPLAY

Lower down, the tended calm frays. On these shelves the waiting are not patient — they
are *restless*, pacing their own open graves, flickering, catching and snagging on the
edge of rising and sinking back. As the Fool crosses, three of them tear loose entirely
and rise between the stones: pale, grave-grey figures, faceless as Blanks but colder,
each dragging up out of its grave with the wrong, jointless motion of a thing called
before its time.

**[Combat prompt: light string and dodge as normal. These restless spirits fight like
Blanks but harder — and note the tell: when one falls, it does not scatter to a card and
drift off elsewhere. It sinks straight back into the open grave it rose from, still there,
still waiting. Nothing here leaves. Foreshadows the amphitheater's whole problem.]**

The Fool puts the three restless spirits down; each collapses back into its own grave and
lies quiet — for now.

**THE QUERENT**
> See that? They don't scatter and reassemble like the Blanks up-country. Down here
> nothing *goes* anywhere. You put them down, they stay put — right where they are, in the
> ground they can't leave. Keep the shape of that in your head. You're going to need it.

### BARKS — the restless terraces *(during and between the small scuffles)*

**Restless Spirit Random Lines** *(faceless; the voice comes from everywhere and nowhere)*

> Not yet — not *yet* — I was told there'd be a note first —

> Is it now? Is it my turn? No. No. Down again, then. Down again.

> Three hundred years lying still and now I can't hold still at all. Funny, that. Nobody's
> laughing.

**A Waiting Spirit Random Lines** *(the patient ones, watching the restless)*

> Don't mind them. They came in nearer the end — never learned the trick of the waiting.
> You get better at it. You get horribly, horribly good at it.

### EXT. THE HOLLOWS: Fennimore's Plot — LOW LIGHT

THIRD PERSON GAMEPLAY

A quieter shelf, set a little apart, with one grave tended finer than the rest — the turf
patted down, a posy of dried flowers three hundred years old laid square on the stone. A
ghost sits on the lip of the open grave with his feet dangling into it, entirely at ease,
in no danger of being called and plainly relieved about it. This is FENNIMORE ASHGROVE.
He waves the Fool over with something close to alarm.

**FENNIMORE ASHGROVE approaches the Fool.**

**Fennimore Ashgrove Random Lines** *(repeatable greeting; pick one at random)*

> Ah — you. You're the one they're all whispering about. The one who hurries things along.
> Could I — could I ask you not to? On my account, specifically?

> Don't misunderstand, I'm glad *someone's* coming to end the waiting. Marvellous news.
> Wonderful. Only — could it be everyone *else* first, and me a bit later on?

> Sit a moment. There's no rush. That's the one luxury this place has ever offered and I
> intend to enjoy it right up until the moment it's taken away.

TRANSITION TO CUT SCENE

### CUT SCENE

**FENNIMORE ASHGROVE**
> The caller's meter says I'm ready. The caller's meter has said I'm ready for about two
> hundred and forty years. I'd like it on record that the caller's meter and I *disagree*.

**THE FOOL**
> You don't want to be called?

**FENNIMORE ASHGROVE**
> Want! Who said anything about want. I'm not *ready*. There's a difference, and it's the
> whole of me, and I'd thank the world to notice it. Everyone talks about ending like it's
> a mercy you'll be grateful for. And it is. I know it is. I've watched three centuries of
> people ache for it. I simply — haven't finished sitting here yet.

He kicks his heels against the inside of his own grave, gently, like a boy on a wall.

**FENNIMORE ASHGROVE**
> [If CONFESSED: And I know what you are. I do. You'll go down there and turn her loose,
> and the note will come, and it'll come for *me* too, whether I've worked up to it or not.
> I'm not asking you to stop. I know you can't. I'm only asking you to know that when it
> comes, I still won't be ready. And that you'll do it anyway. Somebody ought to have to
> know that.]

END CUT SCENE

### CHOICE DIALOG — Fennimore Ashgrove *(all questions may be exhausted)*

| The Fool | Fennimore's response |
|---|---|
| What are you still waiting to finish? | Nothing. That's the joke of it. Nothing at all. I just like it here, and the light, and the quiet. Is that so small a thing to want a little longer? |
| Everyone else wants to go. | I know. I *know*. Makes me the odd one out on the whole hillside. Always was the odd one out. Suppose I'll be the odd one going, too. |
| The call won't wait for ready. | No. It won't, will it. It never has, for anyone. That's rather the cruel kindness of the thing. Comes when it comes. Doesn't check first. |
| I'll go gently, then. *(earnest)* | Gently. Yes. If you can't go *later*, at least go *gently* — I'll take that trade. Go on. Don't let me keep you. Everyone else has earned it, even if I haven't. |

[All versions pick up here:]

Fennimore settles back onto the lip of his grave, feet swinging, and turns his soft old
face up toward the changeless light, savouring it while it lasts. **[He is flagged for the
aftermath: Fennimore is the last ghost in the Hollows to fade, beat 14.]**

### EXT. THE HOLLOWS: The Shrine Rim — LOW LIGHT

THIRD PERSON GAMEPLAY

The lowest terrace before the descent is ringed with small stone shrines — ancestor
shrines, one every few paces along the amphitheater's rim, each a niche of offerings gone
to careful moss: a cup, a coin, a folded cloth, a child's toy, kept dusted and straight.
They are plainly loved. They are just as plainly *inert* — no glow, no stir, no answer,
however the Fool interacts with them.

A groundskeeper works among them: YEW HALLOWAY, weeding a verge with the unbothered
rhythm of a man three centuries into the same round. He tips his hat to the Fool without
stopping.

**[Combat prompt: none. Interact with a shrine — the offerings can be inspected; nothing
activates. This seeds the payoff in beat 12 rather than springing it cold.]**

**YEW HALLOWAY**
> You can look. They'll not answer you. Not yet. These are the ancestor shrines — folk
> keep them for the ones already gone on, back before the Stall, when going-on was still a
> thing that happened. Left offerings. Kept them nice.

He straightens, one hand at the small of his back, and considers the inert niches with the
fondness of long acquaintance.

**YEW HALLOWAY**
> Story goes they give a gift back, the shrines — a last one, to whoever kept them — the
> day the trumpet's finally let to sound. Final gifts, they're called. Nobody living's
> ever seen it. Been keeping mine ready three hundred years all the same. Keeping a thing
> ready's the whole of my trade. You get *very* good at ready, down here.

**Yew Halloway Random Lines** *(repeatable; while tending)*

> Every verge level, every stone true, every shrine dusted. For three hundred years and
> nobody to see it. You don't tend a graveyard for the crowds. You tend it for the day it
> finally means something.

> Go on down when you're ready. She's waiting on you same as we all are — only she's the
> one who has to *watch* everyone wait. Reckon that's the harder end of the deal.

> [If CONFESSED: Aye, I know what you're carrying down there. Best news these shrines ever
> heard, if you ask me. Go and let them give their gifts. Long overdue, the lot of it.]

**THE QUERENT** *(as the Fool leaves the rim)*
> Ancestor shrines. Keep those in the back of your mind — they've been holding their
> breath as long as everything else down here. They'll matter more in a moment than they
> look like they do now. Most things in the Hollows do.

The descent opens ahead: a ramp of white stone stepping down into the amphitheater's low
centre, where a single figure stands.

### EXT. THE HOLLOWS: The Amphitheater of Open Graves — LOW LIGHT

THIRD PERSON GAMEPLAY

The terraces bank down on every side into a great round floor of pale stone, and the whole
hillside above becomes an audience of the waiting — thousands of them now, ranked up the
terraces, all turned inward, all silent. At the centre stands the HERALD: an angel taller
than the Fool by half again, robed in grave-grey, wings folded and still, a long brass
trumpet held two-handed at her breast. She does not raise it. She has not raised it, truly,
in three hundred years. Her face carries the particular exhaustion of a duty that is
always, always about to be done and never once is.

**[Combat prompt: none yet. The Herald does not attack on the Fool's approach. She waits.
This is the third space in a row the region has refused to rush — the fight lands harder
for it.]**

TRANSITION TO CUT SCENE

### CUT SCENE

The Herald watches the Fool cross the floor. When she speaks, her voice is low and worn
smooth, like a bell that has rung the same note so long it has forgotten it can ring
another.

**THE HERALD**
> I have stood in this ground three hundred years with a call in my throat and no leave to
> give it. Do you know what that is? To hold a mercy in your two hands, and see the ones
> who need it ranked up the whole hill in front of you, and not be *permitted*?

She looks up the terraces — at the waiting, at the restless, at the patient old spirit and
the reluctant one and all the rest.

**THE HERALD**
> Every one of them ready. Most of them long past ready. And the door shut, and the horn
> silent, and me the keeper of a promise I was never once allowed to keep. That is not
> patience you are looking at, little Fool. Patience ends. This is the thing that comes
> after patience, when patience has been used entirely up.

She lifts the trumpet — not to her lips, only to the light, turning it so its bell catches
the grey.

**THE HERALD**
> [If CONFESSED: They tell me you are the ending. That every card you turn comes loose and
> every soul you touch is let go. Good. *Good.* Then you will understand why I cannot
> simply stand aside and let you pass. If the call is finally to mean something, it must be
> *earned* — from me, in the only coin I have left. Come and take the horn, if you can.
> Nothing in this ground has answered it in three centuries. Let us see if you can make it
> lie.]
>
> I will raise them against you. The ones you strike down — I will call them back up, on
> the count you can see filling there. Not to harm you. To *show* you. This is what it is
> to end a thing in a world that will not let anything stay ended. Learn it here, where it
> only costs you a fight. I have learned it every hour for three hundred years.

END CUT SCENE

### GAMEPLAY — the encounter, phase one *(the meter)*

GAMEPLAY: The Herald sounds the trumpet — one long brass note — and the open graves ring
the floor give up their restless: a first wave of grave-grey spirits, faceless, cold. Over
the Herald's head a **visible meter** begins to fill, one clean bar rising with every
passing second and with every blow she lands. The Fool strikes the restless down and they
sink into the floor's open graves as before — *provisionally*. When the meter tops out,
the Herald blows again, and every fallen spirit still in the ground rises back up. Every
kill is on loan until the meter is managed.

**[Combat prompt: watch the meter, not just the enemies. Killing everything as fast as
possible only stocks the graves for her next blast. The floor's open graves glow faintly
where a fallen spirit waits to be re-raised — read them.]**

**THE HERALD Random Lines** *(mid-fight; pick one at random per blast)*

> Up. Up again. This is the world you have been walking through — did you never wonder why
> nothing you struck down stayed down?

> I take no joy in it. I never have. But you asked to pass, and this is the toll, and the
> toll is the truth.

> Three hundred years I have raised them and had no leave to *release* them. Now you know
> the weight of a horn that only ever calls one way.

### GAMEPLAY — the encounter, phase two *(kill order)*

GAMEPLAY: The floor's real puzzle surfaces. The restless come in two weights — light
spirits, quick to fall, and heavier ones that take real work to put down. Ending a heavy
spirit early only means the Herald raises it again at full strength on the next blast.
The solution is **kill order**: cull the light spirits to keep the floor clear, hold the
heavy ones until the meter is nearly reset, then end them in the window before it fills —
so the blast that would raise them comes to an empty grave.

The encounter forks here on the Fool's loadout.

**[If the Fool has Passage (Trump XIII) slotted — Reap available:]**

GAMEPLAY: Passage's Reap execute (any lesser enemy below ⅓ health; `arcana.md` §XIII)
does more here than finish — a Reaped spirit does *not* sink into the floor to wait. It is
ended outright, the grave beneath it closing over. The Herald's meter can top out and her
blast can sound, and the Reaped simply do not answer. The synergy is the intended Hollows
loadout (`arcana.md` §Cross-Trump synergy): the two Trumps of ending and returning,
argued out on the amphitheater floor. The optimal line becomes a *conversation* — Reap the
light spirits to thin the raising, manage kill order on the heavy ones the meter can still
reach, and watch the Herald's blasts come up shorter and shorter as fewer and fewer graves
have anyone left in them to call.

**THE HERALD** *(as Reap begins denying her raises)*
> Ah. *There* it is. The other horn — the door that only opens the once. You would end them
> past my calling. You would take them somewhere even I cannot reach to raise. Do you know
> — I think I am *glad* of it. I have wanted, for three hundred years, to lose this
> argument.

**[If the Fool does not have Passage slotted:]**

GAMEPLAY: Pure kill-order. With no execute to deny the raise, every spirit the Fool ends
sinks into the floor to await the next blast, and victory is entirely a matter of timing —
starving the meter, clearing the light spirits between blasts, and landing the heavy ones'
final blows inside the narrow window after a reset and before the meter climbs. Slower,
tenser, and wholly fair: the fight teaches the same lesson Passage would hand the player,
the long way round.

**THE HERALD** *(as the Fool learns to time the meter)*
> You are learning it. The count, the window, the patience of it. Good. That is the shape
> of every ending that ever meant anything — not a blow, but a *waiting for the right one*.
> I could almost teach, if anyone had ever come to be taught.

[All versions pick up here:]

The floor empties. Wave by wave the restless are ended and stay ended, the open graves
around the rim closing one by one, and the Herald's blasts come up thinner each time —
fewer to raise, fewer to raise, until the meter tops out over a floor with almost no one
left in the ground to answer.

### GAMEPLAY — the falter

GAMEPLAY: The last of the restless goes down and stays down. The meter fills, full and
bright — and the Herald, out of three hundred years of unbroken habit, raises the trumpet
and blows.

Nothing rises.

The note goes out over an empty floor, over closed graves, over a silence that has never
once, in three centuries, followed one of her blasts. She lowers the horn a fraction and
stares at the ground as if it has done something she does not have a word for.

**[Combat prompt: none. Hold. The first silence in the fight is the tell — do not attack
into it. The Herald is not defeated; the office is *cracking*, which is a different thing.]**

**THE HERALD** *(barely above a breath)*
> ...Nothing. I called, and nothing rose. Do you understand what — no. No, you cannot
> understand it, because you have never once in your life blown a note and had it *answered
> by silence*. That is what a finished thing sounds like. I had forgotten. I had genuinely
> forgotten there was such a sound.

TRANSITION TO CUT SCENE

### CUT SCENE

The Herald stands over the empty, quiet floor. The grave-grey of her robe seems to lift a
shade. And then the office — three hundred years of the horn, the meter, the mercy held
back — audibly cracks, the way river-ice cracks in the first warm hour: a long, splitting,
travelling sound, and then release.

**THE HERALD**
> It is coming apart. The — the *keeping*. The part of me that was only ever a locked door
> with a horn behind it. It is — oh. Oh, I remember now. I remember there was more of me
> than this. There was a — there was a *name* —

Something surfaces in her, the way a held breath finally lets go, the way a bell rung too
long remembers it can ring another note entirely.

**THE HERALD**
> ...*Clemency.*

She says it slowly, wonderingly — the mercy she was made to guard, turning out all along
to have been her own name, waiting three hundred years in her own throat to be called.

**CLEMENCY**
> Clemency. Yes. That is — that was mine, before the office, before the ground, before the
> waiting. I am Clemency. And I have been holding this call so long I forgot it was a
> *kindness* and not a *cage*.

For the first time in three centuries, she lowers the trumpet all the way — down, and
away, no longer at her breast, no longer ready, simply *held*, the long vigil set down at
last. She looks at it in her own two hands like a tool she is finally, finally allowed to
use for what it was made for.

**CLEMENCY**
> [If CONFESSED: You are the ending. I know. And I find I am not afraid of you at all — I
> have been *waiting* for you, longer than any soul on this hill. You did not come to take
> the horn from me. You came to let me *sound* it. There is a difference, and it is the
> whole of me, and you are the first in three hundred years to know it.]

She holds the trumpet out — no longer a keeper's burden, now a gift plainly, simply hers
to give.

**CLEMENCY**
> Take it. Trump the Twentieth — Reveille, they'll call it, the waking-note. It only ever
> knew how to raise. In your hands let it learn to *release*, too. Both are the same
> breath. I was three hundred years understanding that. You may have it for free.

**[Reward: the Fool receives Trump XX (Reveille). The Pocket Spread's Present slot is
already unlocked by this point — Passage (Trump XIII) is a hard prerequisite of reaching
the Hollows at all, so no first-Trump unlock beat is possible or needed here.]**

**[No loot drops. No one is killed. The unbinding is: office cracks → the name Clemency
returns → the trumpet is lowered for the first time in three centuries and Trump XX is
handed over, personally.]**

END CUT SCENE

### EXT. THE HOLLOWS: The Amphitheater Floor — LOW LIGHT

THIRD PERSON GAMEPLAY

Clemency turns from the Fool, and — gently, deliberately, with three hundred years of
withheld tenderness behind it — raises the trumpet to her lips and sounds it *true*, at
last, out over the ranked terraces and every waiting soul on them.

CUT SCENE

The note is nothing like the blasts of the fight. It is clear, and it is kind, and it does
not call anyone *up*. It calls them *on*.

And every goodbye in the game arrives at once.

**[This is the goodbye wave — `WS_JUDGEMENT_UNBOUND`. Staged as release, not horror.
Scripted in three concentric rings: the amphitheater, the Hollows terraces, then the whole
Spread as a montage. It must earn the "every goodbye at once" line and never play it as a
mass death — nothing here dies; everything here is finally, gladly *let go*.]**

Up the terraces, the waiting begin to fade — not snuffed, not falling: rising, thinning,
turning toward the note like faces toward a window, and going. The patient old spirit from
the upper shelf lifts a hand to the Fool in passing — *first soul in three hundred years to
mean it* — and is gone between one breath and the next, unafraid, at ease, three centuries
of Tuesdays finally spent.

**[If ACT_III (15–21 unbound): the goodbye wave is at full volume — the whole Spread has
been woken, and the note reaches every region at once. The montage rings wide: ghost NPCs
in every settled region the player has freed turn from whatever they were waiting on and
say their farewells together, closing every "waiting" thread the game has planted since
MQ13 in one long, overlapping wave — a hundred small goodbyes the player half-remembers,
all landing in the same held minute.]**

**[If ACT_II (7–14 unbound): the wave is quieter and closer — most of the Spread is still
frozen, so the note carries mainly through the regions already freed and the Hollows
themselves. The montage is spare and intimate rather than world-spanning; the farewells
that land are the ones the player has actually reached. The line is earned at a smaller
scale, not diminished — fewer goodbyes, each given more room.]**

**[If SQ-HOLLOWS-02 resolved — Petronella's apology delivered: Elder Petronella Dusk is
among the amphitheater's going, and she goes *content* — her one overdue thing finally
done, the call arriving as pure mercy on an account already closed. She does not speak;
she only meets the Fool's eye, and there is nothing left unfinished in it.]** **[If
SQ-HOLLOWS-02 unresolved or never started: Petronella is called on with the wave all the
same — the note does not wait for anyone to be ready — her apology still unsaid. The wave
does not close her thread by force; it leaves the wronged soul's marker lingering a beat
longer on the terraces, exactly as SQ-HOLLOWS-02's memorial coda requires, so that errand
stays reachable afterward as its own quieter, sadder shape. MQ20 calls the souls on; it
does not reach up-region to resolve threads it cannot see (see Open questions).]**

END CUT SCENE

### EXT. THE HOLLOWS: The Shrine Rim — LOW LIGHT

THIRD PERSON GAMEPLAY

As the note fades, the ancestor shrines around the rim — inert for three hundred years —
answer it. One by one the mossed niches warm and stir, and each gives up its final gift to
the one who kept it: a soft light unfolding out of the offerings, settling on the tenders
who have dusted and straightened these shrines through three centuries of silence.

Yew Halloway stands among his shrines with his hat off, watching the light gather, saying
nothing at all.

**[The ancestor shrines' final gifts are staged as the world-state effect they are
(`world.md` §World-state matrix, `WS_JUDGEMENT_UNBOUND`). The gifts go to the Hollows folk
who tended them — Yew, Bess Corrigan, the residents — not to the Fool; MQ20 does not hand
the Fool a shrine gift, leaving those beats to the region's side quests. The Fool's reward
for this quest is Trump XX, already given.]**

**YEW HALLOWAY**
> Three hundred years keeping them ready. And they had something to give back the whole
> while. Waiting on the note, same as everyone. Same as me. Well. There it is, then. There
> it finally is.

### EXT. THE HOLLOWS: The Terraces — LOW LIGHT → BLOOM

THIRD PERSON GAMEPLAY

The Hollows change while the Fool watches. The open graves, one after another all up the
terraced hillside, close over soft — not filled in, *grown* over, turf drawing across them
like a blanket pulled up. And out of the closing graves the flowers come: fast, and then
faster, greening and blooming up every level shelf until the whole amphitheater of open
graves is, visibly, unmistakably, a *garden* — a hillside in flower where a waiting-room
used to be.

[If WS_SUN_UNBOUND: the first true dusk over the Hollows deepens toward the region's first
real night, and the bloom opens under it — pale night-flowers unfolding among the day's,
the graveyard greener in the dark than it ever was in the changeless grey.] [Else: even
in the held, changeless light, the colour comes — the one thing on this hillside that has
ever truly *changed* in three hundred years, and it changes everything.]

Pip, who kept an easy, companionable heel the whole approach — game as ever, matching
the hush the way a good dog matches a walking pace — breaks away now and races up a
terrace of new flowers, tail a full blur, rolling once in the green for the sheer joy
of it.

### EXT. THE HOLLOWS: Fennimore's Plot — LOW LIGHT → BLOOM

THIRD PERSON GAMEPLAY

On the quiet shelf set apart, one ghost has not yet gone. Fennimore Ashgrove still sits on
the lip of his grave — the last waiting soul in the whole Hollows — feet swinging, the
bloom coming up green all around him, the note's kindness plainly reaching for him and
plainly, gently, not letting him refuse.

CUT SCENE

**FENNIMORE ASHGROVE**
> There. You see. Everyone else went the moment she sounded it, glad as anything, and
> here's me — still on the wall, still not ready. Told you. Always the odd one out.

**THE FOOL**
> You don't have to be ready. Just gentle.

**FENNIMORE ASHGROVE**
> *Gentle.* Yes. You promised me gentle. And — do you know — it is. It's terribly gentle.
> That's almost the worst of it. I kept thinking if I put it off long enough I'd finish
> whatever it was I was sitting here to finish. And there never was anything. I just liked
> the light.

He stands, at last, and the flowers come up green under where he sat, and he looks around
the blooming hillside as though seeing it — really seeing it — for the very first and very
last time.

**FENNIMORE ASHGROVE**
> Would you look at that. It was going to do *this* the whole time, and none of us ever
> got to see it, because none of us would go. And now I have to leave the exact moment it
> got beautiful. That's the joke, isn't it. That's been the joke all along.

A beat. He laughs — small, and real, and only a little wet.

**FENNIMORE ASHGROVE**
> Not ready. Still not ready. Going anyway. Because it doesn't wait for ready — you told me
> that, and I didn't want to hear it, and you were right, and it's a *mercy*, and it still
> aches, and both those things are true at once and I've had three hundred years to make
> peace with neither. Go on, then, little ending. Be gentle. You promised.

He fades — slower than everyone else, a beat longer, the way he wanted and the way it was
never going to grant — and then, gently, he is gone, and the flowers are where he was.

END CUT SCENE

### EXT. THE HOLLOWS: The Amphitheater, Blooming — LOW LIGHT → BLOOM

THIRD PERSON GAMEPLAY

The Fool stands on the floor of the amphitheater with the whole hillside in flower above,
every grave closed and green, every waiting soul let go, Clemency somewhere among the
blooms with the horn held easy at her side and the vigil of three centuries set down for
good.

CUT SCENE

**THE QUERENT** *(quiet; the closing beat)*
> That was the last of the waiting, little Excuse. Every soul on this hill, and a hundred
> more up-country you never met, all called on in the one breath. Every goodbye the world
> was holding back — it let them all go at once, and look what came up where the waiting
> was.

A beat. The Querent's voice does something it rarely does: it gentles all the way down.

**THE QUERENT**
> Everyone's been let go now. Every last one that was waiting to be. Including, I think —
> when the time comes — you.

END CUT SCENE

### BARKS — the Hollows, blooming *(post-unbinding, ambient)*

**Yew Halloway Random Lines** *(now the gardener of the bloom)*

> Never grew a thing in three hundred years. Now the whole hill wants tending at once.
> Foxgloves. *Foxgloves.* No idea what I'm doing. Best work I've ever had.

**Hollows Resident Random Lines** *(the newly-able-to-die, walking the garden)*

> Buried nobody here in three centuries and now there's a *garden* on top of all of them.
> Feels right. Can't say why. Feels right.

> My gran's shrine gave me something. A gift. Won't say what. But I sat down and cried in
> a graveyard and it was the *good* kind, first time in my life. First time in anyone's.

**THE QUERENT Random Lines** *(if the Fool lingers in the bloom)*

> Go up and look at the flowers. You earned those. Well — they earned themselves. You just
> stopped standing in their way.

> Quietest it's ever been down here. And the fullest. Odd, that the two came together.
> Suppose that's the Hollows all over.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Clemency unbound (encounter won + cutscene) | `WS_JUDGEMENT_UNBOUND` | The Herald sounds the true note. Ghost NPCs across the Spread say their goodbyes at once, closing every "waiting" sidequest thread seeded since MQ13 (scaled by act state — see below); the Hollows' open graves close and bloom into a garden; the ancestor shrines give their final gifts to those who tended them. The Fool receives Trump XX (Reveille); the Present slot is already unlocked (Passage is a hard prerequisite). |
| Wave played in `ACT_III` (15–21 unbound) | (no separate flag — reads `ACT_III`) | Full world-spanning goodbye montage; every reachable "waiting" thread closes in one overlapping wave. |
| Wave played in `ACT_II` (7–14 unbound) | (no separate flag — reads `ACT_II`) | Spare, intimate wave through the regions already freed; the line is earned at smaller scale. |

## Consistency references

- `arcana.md` §XX. Judgement — the Herald encounter, the raising meter, kill-order puzzle,
  Passage/Reap resurrection-denial synergy (the intended Hollows loadout), Trump XX
  (Reveille) slots, the unbinding effect ("every goodbye in the game arrives at once; the
  Hollows bloom"). §XIII. Passage — Reap's execute and the "defeated stay ended" rule the
  synergy leans on. §Cross-Trump synergy notes — Passage ⟷ Reveille.
- `world.md` §The Hollows (fills after Death, empties and blooms after Judgement), §Hard
  and soft gates (Death→Judgement is one of two hard story gates; the diegetic rationale),
  §World-state matrix (`WS_DEATH_UNBOUND`, `WS_JUDGEMENT_UNBOUND`: goodbye wave, bloom,
  ancestor shrines' final gifts), §Global states (`CONFESSED` at MQ13; `ACT_II`/`ACT_III`
  scaling of the wave).
- `characters.md` §XX. Judgement — Clemency (solemn, patient, the grief of a duty
  perpetually almost-done; the freed name, spoken only at the unbinding beat; the
  never-self-name rule while bound). §Regional named NPCs, The Hollows — Fennimore Ashgrove
  (the mourning NPC, beats at his plot and as the last to fade), Yew Halloway (groundskeeper;
  the shrine explanation and post-bloom gardener), and the light non-preempting cameos of
  the region's other named residents.
- `narrative.md` §Act structure (the always-confessed region; no un-confessed variant),
  §Themes 1 (endings are a mercy — the emptying plays as release), 2 (offices eat people;
  the Herald's name returns), and 3 (freedom isn't wanted by everyone — Fennimore), §The
  Querent (the single fourth-wall wink, spent on the closing "including, I think, you"),
  §Dialogue style guide (Fool lines ≤ 12 words with an earnest/foolish option; one honest
  beat per comic scene, one laugh per sad one; storybook register, no modern slang).
- `npc-system.md` §Bark layers — the goodbye wave's world-wide farewells resolve as layer-3
  world-state barks (`WS_JUDGEMENT_UNBOUND`) and rumor propagation; the Hollows' post-bloom
  ambient pools (Yew, residents) sit in layers 1–4.
- `callings.md` — the Groundskeeper Calling (post-MQ20: "gardener of the bloom"), which Yew
  embodies here without this quest duplicating its loop.
- MQ13 (`main/MQ13-an-ending.md`) — the confession this quest's post-confession baseline
  assumes throughout, and the source of the `WS_DEATH_UNBOUND` gate and `CONFESSED` state.
- `quests/side/SQ-HOLLOWS-01`, `-02`, `-03` — the Hollows side-quest threads this quest's
  aftermath must not contradict: the reserved-plot bloom (Yew), the long-overdue's apology
  window (Petronella; staged so its post-MQ13/pre-MQ20 window and memorial coda both read
  coherently), and the headstone carver (Bess).
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- **Carried forward from outline (unresolved):** Should the "both variants" rule in
  `quests/README.md` be formally amended to exempt quests hard-gated behind post-MQ13
  content (this one, SQ-HOLLOWS-01/02/03, and any future one gated the same way), or is the
  explicit always-confessed note (kept above) sufficient documentation on its own? Pending a
  README decision, this quest documents the exemption in-line.
- **Carried forward from outline, now partially surveyable:** The goodbye wave (beat 11)
  promises to close "every waiting ghost thread seeded since MQ13," and the wave is
  authored to scale with act state rather than to name specific closures it can't guarantee.
  Within the Hollows the known waiting thread is SQ-HOLLOWS-02 (Petronella; staged above so
  the wave neither force-closes it nor contradicts its memorial coda). A full cross-region
  survey of Spread-wide "waiting" ghost threads still does not exist and must be run at the
  Act III content pass before this quest can claim a literal one-to-one closure; until then
  the wave is written as an earned atmospheric convergence, not a checklist of resolved
  side quests. SQ-HOLLOWS-02 requests registration in exactly this survey.
- Confirm Yew Halloway's pre-bloom shrine cameo here does not preempt his own hook in
  SQ-HOLLOWS-01 (which discovers him post-bloom over his reserved plot). As written, MQ20
  keeps him strictly to tending and explaining the ancestor shrines and deliberately does
  not touch the reserved-plot beat; a content-pass read of both docs together should verify
  the two introductions sit comfortably.
- The unnamed waiting spirit who delivers beat 2's tone-setting lines is kept deliberately
  unnamed (per the outline's allowance) rather than promoted to `characters.md`, to avoid
  inventing canon at script status. Confirm this is acceptable, or promote a named spirit in
  a separate `characters.md` change first if a recurring named presence is wanted there.
- Reveille's Present/Future costs and the exact fill-rate and reset timing of the Herald's
  raising meter are combat-tuning values (`arcana.md` cost-tier note); the script assumes a
  meter slow enough to make kill order legible and fast enough to keep pressure on.
