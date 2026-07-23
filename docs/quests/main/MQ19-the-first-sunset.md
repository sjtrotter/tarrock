---
id: MQ19
title: The First Sunset
type: main
status: script
arcana: XIX. The Sun
region: The Noonlands
requires: []
fires: [WS_SUN_UNBOUND]
---

# MQ19 — The First Sunset

## Introduction

The player comes into the Noonlands — golden grain country under a sun nailed at noon
since the Stall — where the harvest festival has been "today" for three hundred years and
the only trouble anyone will name is a drought creeping in at the fields' edges. At the
heart of it stands the Sunflower Coliseum, whose champion, Aurel, has been challenged by
every wanderer who ever passed through and beaten every one, because the sun has never
been allowed to set on him. He is a radiant child-knight on a white pony, and the news of
a fresh challenger is, to him, the single most delightful thing to happen in his whole
long childhood — the Fool is the first *new* thing he has met in three centuries. The
quest is built to be the game's trailer moment. Its fight teaches one clean lesson —
Aurel's own radiance whites out his body's tells, so **read his shadow on the sand, not
his body** — and its aftermath is the largest scripted set-piece in the main line: the
first sunset in three hundred years, playing out in real, visible time while Aurel grows
up inside it. Because MQ19 has no `requires`, it can arrive early or late in the Fool's
Reading — so Daybreak may be the player's first Trump, and the first night that follows
carries `[If WS_STAR_UNBOUND]` variants: the Mere's returned stars have been *waiting* for
a night to shine in, and now one exists. If the Fool reaches the Noonlands after MQ13
(Death, "An Ending"), the fight's warmth carries a `[If CONFESSED]` ache: Aurel, delighted
to duel the one card that ends things, and delighted anyway.

---

## QUEST: THE FIRST SUNSET

### EXT. THE NOONLANDS: The Grain Road — HIGH NOON *(the only hour there is)*

THIRD PERSON GAMEPLAY

The road tops a rise and the whole of the Noonlands opens out flat and gold to a horizon
that shimmers with standing heat. Fields of sunflowers stretch in every direction, and
every last flower faces the same way — up and slightly south, toward a sun sitting fat
and white at the exact top of the sky, casting almost no shadow at all. Bunting strung
between the poles of a harvest festival hangs bleached to the colour of old paper, the
paint of its little painted suns long gone to nothing, but not one flag has ever been
taken down. Music drifts up from the festival ground below — a reel, cheerful, and played
one time too many.

**[The Fool casts a shadow — a small, hard pool directly underfoot. Note it: the Fool is
the only thing on this whole plain throwing a proper one, because the Fool is the only
thing here that arrived from somewhere the sun moves.]**

At the near edge of the fields, the gold gives way to a browning fringe — stalks gone
papery, earth cracked in a fine map of lines, a scarecrow leaning in a patch of dust.
Nobody down at the festival is looking at it.

BRAMBLE COSS — a broad, sun-freckled woman in a festival steward's sash gone thin at the
edges, a clipboard-of-tallies under one arm — is re-pinning a length of bunting that does
not need re-pinning. She sees the Fool and lights up with the reflexive warmth of a woman
whose whole job, for three centuries, has been making strangers welcome.

**BRAMBLE COSS Random Lines** *(repeatable greeting; pick one at random)*

> A new face! Oh, and just in time — you've come on the very best day of the year. It's
> always the very best day of the year, that's the wonderful thing.

> Welcome, welcome. Mind the west fields, they're a touch dry this season — well. This
> *year*. Well. It'll come back. It always used to come back.

> [If CONFESSED: You'll be the one going card to card, then. Word came down the road
> ahead of you. You're welcome all the same — more welcome, if anything. Sit, eat, watch
> the reel. There's time yet.]

TRANSITION TO CUT SCENE

### CUT SCENE

**BRAMBLE COSS**
> Bramble Coss — steward of the harvest festival, thirty-one seasons running. [She
> laughs, and it doesn't quite reach.] Give or take three hundred years. You lose count
> after the first few, if you're sensible, and I have always been terribly sensible.

**THE FOOL**
> It's the same festival every day?

**BRAMBLE COSS**
> Same festival, same day, same lovely reel. And why not! It was a *good* day. We caught
> the light just right and it — stayed. Best harvest anyone could ask for. It just never
> quite got itself *brought in*, is all.

She looks, despite herself, at the browning fringe of the west fields, and then very
deliberately does not look at it again.

END CUT SCENE

### CHOICE DIALOG — the endless festival *(all questions may be exhausted)*

| The Fool | Bramble's response |
|---|---|
| Why hasn't the sun moved? | Because Aurel's still champion, bless him. Sun can't set while the day's own knight stands undefeated — so he stands, and it doesn't, and round we go. Or don't, rather. |
| What's wrong with the fields? | Nothing a good rain won't— [she stops]. It's the noon. Same noon, on the same soil, for longer than soil was ever meant to hold. Even a blessing gets heavy, held that long. |
| Where do I find Aurel? | The Coliseum, love — the great ring of sunflowers, you can't miss it. He takes all challengers. Has done, forever. Do be gentle with him. He does so love the company. |
| Is anyone tired of all this? *(earnest)* | [a long beat] ...You're the first to ask it plain. No. Nobody's tired. That's rather the trouble, isn't it. Nobody's been *let* to be tired. Go on. Go and meet him. |

**If the Fool asked "Is anyone tired of all this?":**

| The Fool | Bramble's response |
|---|---|
| Even you? | Me least of all. I've a festival to run. I'll run it till the poles rot. [quietly] I wouldn't know what to do with an evening if you handed me one wrapped in ribbon. |

[All versions pick up here:]

Bramble waves the Fool on toward the Coliseum with a bunting flag, already turning back
to re-pin the length she has re-pinned a thousand times.

### BARKS — the festival ground *(pre-unbinding)*

**Harvest Hand Random Lines**
> Poll threw a clean forty-cubit sheaf. So did Fenner. Dead level, same as yesterday.
> Same as always. Uncanny lads, the both of 'em.

> West culvert's silted again — or still. Can't rightly say which, the days run
> together so.

**Festival Dancer Random Lines** *(one bright girl at the front of the reel; do not
resolve her — she is Sunny Loft, SQ-NOONLANDS-02's)*
> Come dance! No, I never stop, why would I stop, there's nothing to stop *for* — the
> song just goes round and I go round with it and it's *lovely*.

> Tired? [genuine bafflement] I don't — I don't think I've ever been that. Is it nice?
> It sounds like it might be nice. Or awful. Come dance, I don't want to think about it.

**Festival-goer Random Lines**
> Best day of the year, this. Been the best day of the year my whole life. My whole
> *long* life.

> [If CONFESSED: They say you end things where you go. Odd sort of guest. Still — hot
> work, standing about forever. Some of us wouldn't mind an evening to sit down in.]

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Challenge Gate — HIGH NOON

THIRD PERSON GAMEPLAY

The Coliseum is not built of stone. It is built of sunflowers — a vast living ring of
them, grown improbably tall and packed shoulder to shoulder into a wall two storeys high,
all of them turned inward to face the sanded floor at the centre, so that the whole
audience of the arena is *flowers*, ten thousand gold faces watching a ring they never
blink away from. Between them, on tiered benches of sun-bleached wood, sit the human crowd
— harvest folk in festival best, unaged, leaning forward with the eagerness of people who
have watched the same wonderful thing so many times they can no longer tell it from prayer.

A herald's board at the gate reads, in paint retouched past legibility: ALL CHALLENGERS
WELCOME — THE CHAMPION AWAITS.

**[Interact with the challenge gate to enter the lists. The gate steward, an ambient Blank
in a tourney tabard, waves the Fool through without a word — it has no mouth to ask a
name with.]**

**THE QUERENT**
> Open challenge, this. Anyone may walk up and try the champion — and everyone has, over
> three hundred years, and every one of them lost, and not one of them minded very much.
> That's the strange part. You'll see. Win your way up the lists first; the ring's got a
> ladder, and the boy at the top of it is *worth* the climb.

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Lists — HIGH NOON

THIRD PERSON GAMEPLAY

The qualifying bouts: a short ladder of the Coliseum's standing champions, tourney Blanks
in bright tabards bearing high Coins cards — Pages, then Knights — who have held their
little titles unbeaten for three centuries because nothing here was ever allowed to
change hands. They fight in earnest and lose in earnest, and each one, felled, slumps like
a puppet set gently down while its card peels free and drifts off over the sunflower wall.

**[Fight up the three qualifying bouts. Standard Blank encounters, escalating: a lone
Page, then a pair, then a mounted Knight-Blank whose horse's shadow — small and hard under
the noon — is the only honest read on its charge. This last bout **quietly rehearses the
teaching**: read the shadow, not the glare.]**

**Crowd Random Lines** *(during the qualifying bouts)*
> Ooh, a real go of it! We haven't had a real go of it since — well. We've never *not*
> had one, but this one's got a dog.

> Up you come, up you come. Nobody's ever made it past the Knight, mind. Nobody but you's
> ever going to, either, by the look of that footwork.

The last Blank falls. The crowd's noise swells — and for the first time all afternoon,
the sanded floor of the great ring lies open and empty, waiting.

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Practice Pell — HIGH NOON

THIRD PERSON GAMEPLAY

Before the champion's gate, a squire's practice-pell stands in the sand: a straw dummy in
dented tourney plate, and — bolted above it on a bent armature — a bright disc of polished
tin, angled to throw noon's glare straight into a challenger's eyes. It is exactly the
trick the champion's own radiance plays, built cheap and small so a challenger can learn
it before it matters.

**[Tutorial bout: the practice-pell "attacks" on a rig — a swinging padded arm. The tin
disc whites out the arm's motion completely; the Fool cannot read the swing by watching
the dummy. But the dummy throws a shadow on the sand — small, tight under the noon, but
honest — and the shadow-arm telegraphs every swing a half-beat early. Dodge three swings
by reading the shadow to clear the pell and open the champion's gate.]**

**THE QUERENT**
> There. Feel that? You can't watch the boy himself — he's a lantern with a lance, he'll
> blind you honest. Watch what he throws on the ground. A shadow can't lie about which
> way an arm's going. It's the one plain thing in a very bright place. Don't forget it
> when the bright thing's *laughing* at you.

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Champion's Gate — HIGH NOON

THIRD PERSON GAMEPLAY

The champion's gate — twin sunflowers grown into an arch — swings open, and the whole ring
of ten thousand gold flower-faces seems to lean in at once.

AUREL rides out. A child of perhaps eleven in a suit of white-and-gold tourney armour
polished to a blaze, mounted on a small white pony that steps as neat and proud as any
warhorse, a blunted lance couched easy in one arm. He is *radiant* — not a figure of
speech; light comes off him the way heat comes off the fields, so that the eye waters and
slides and can never quite fix on the shape of him. Under the pony's four hooves lies a
shadow the size of a dinner plate, pooled tight at high noon.

He circles the Fool once, at a delighted canter, taking them in.

**AUREL Random Lines** *(repeatable; pick one at random)*

> A new one! A genuinely, actually new one! Do you know how long it's been since anyone
> was *new*? Don't answer, it's rude to say, but it's a very long time and you are
> *marvellous*.

> You climbed my whole ladder just to reach me. Nobody does that any more. Nobody's
> done that in — [he counts, gives up, beams] — ages and ages. Thank you. Truly.

> Is that your dog? He's brilliant. Everything about today is brilliant. *Today* is
> brilliant, and it's usually just fine.

TRANSITION TO CUT SCENE

### CUT SCENE

Aurel reins the pony up close and leans down over its neck, all eager confidence, to look
the Fool over the way a younger brother looks at an older one who has come home from
somewhere impossible.

**AUREL**
> You've been *everywhere*, haven't you. I can tell. You've got that look — like you've
> seen sundown and rivers running and things that *finish*. [wistful, quick] I've never
> seen a thing finish. Not once. I win, and it's tomorrow, and it's this again, and I
> win.

**THE FOOL**
> You never lose?

**AUREL**
> Never! Isn't it awful. [he laughs — and means both halves of it] I'm the very best
> there's ever been, and I would give absolutely anything for someone to prove I'm not.
> That's a secret. Don't tell the flowers.

He straightens in the saddle, and the wistfulness burns off like dew, and he is nothing
but joy again — a joy so bright and so tired underneath that it is almost hard to look at,
same as the rest of him.

**AUREL**
> [If CONFESSED: They told me what you are. The one who turns us loose, card by card —
> the one who's going to end the whole lovely thing in the end. I thought about it all
> morning. And do you know what I decided? *Good.* Come and beat me. Come and be the
> first new thing that was ever allowed to happen to me. Even if it's the last.]
>
> Best of the day to you, challenger. Let's have the finest bout this old ring's ever
> seen — and it's seen every bout there is.

END CUT SCENE

### CHOICE DIALOG — before the bout *(all questions may be exhausted; first weapon-clash commits)*

| The Fool | Aurel's response |
|---|---|
| Why do you fight so happily? | Because it's the only thing that's *mine* to do! Everyone else stands about being lovely. I get to move. Wouldn't you be happy? |
| What happens if you finally lose? | I don't know! [genuine wonder] That's the whole thrilling bit. Nobody's ever shown me. Maybe you will. Oh, I do hope you will. |
| Aren't you tired? *(earnest)* | [the light flickers, just once] ...People keep asking me that today. I don't know how to be it. I've never had an evening to try. Come on — before I go and *think* about it. |
| You're only a child. | [delighted] I'm three hundred and something! I'm the *oldest* child there has ever been. Now put your staff up, grandfather, and mind my pony. |

**If the Fool asked "Aren't you tired?":**

| The Fool | Aurel's response |
|---|---|
| [If CONFESSED] Growing up costs something. Are you sure? | [a beat, older than his face] I've watched everyone I love hold the same age for three hundred years. Do you know what I'd pay to be allowed to get *bigger*? Anything. The bill can come after. Now — enough. Fight me. |

[All versions pick up here:]

Aurel wheels the pony to the far end of the ring, couches his lance, and salutes the Fool
with it — a bright, sincere, formal little flourish — and then he is coming, laughing, at
a full and terrifying gallop.

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Ring — HIGH NOON *(the duel)*

THIRD PERSON GAMEPLAY — SETPIECE DUEL

**[The single mechanic, taught once, tested for real: Aurel's radiance whites out his body
and his lance — the player cannot read his attacks by watching him. The pony-and-rider
shadow on the sand — kept small and tight by the nailed noon — is the honest tell. Read
the shadow to know which side he strikes from, when he rears, when he charges. Fool's
Chance rewards a dodge timed off the shadow-tell, not the glare.]**

**Phase one — the passes.** Aurel charges on the white pony end to end, lance levelled,
radiance blazing so the lance-point is invisible — but the shadow shows the lance's angle a
half-beat before it lands. Dodge the pass by the shadow; strike the pony's flank as it
thunders by to stagger the charge. He wheels, whoops, and comes again, faster, laughing
the whole time.

**AUREL** *(mid-charge, breathless with joy)*
> You're *reading* me! Nobody reads me! Oh, this is the best one, this is the best bout
> there's ever — mind the lance! Ha! You minded the lance! *Marvellous!*

**Phase two — on foot.** At half health the pony bows out of the ring of its own accord —
a neat, deliberate little bow — and Aurel fights dismounted, quicksilver, a blazing child
with a sword, flurrying faster than the eye can hold. His body is pure glare now; only the
small hard shadow at his feet tells the truth of each cut. Land the counters off the
shadow.

**AUREL** *(mid-flurry, delighted, never once cruel)*
> Faster! You can go faster, I can tell, you've been saving it — don't save it, nobody
> here's ever coming back for a second show, spend it all on *me!*

The Fool times the final counter off Aurel's shadow — reads the one honest thing in all
that light — and lands it clean. Aurel's blade spins away across the sand. He sits down,
hard, in the middle of the ring, plate ringing, and for one long held second the whole
Coliseum of ten thousand flowers and three hundred years of crowd does not make a sound.

And Aurel — sitting in the sand, disarmed, beaten for the first time in three centuries —
throws back his head and *laughs*. Pure, immediate, unfeigned, the happiest sound in the
whole game.

### CUT SCENE

**AUREL**
> I *lost.* [wondering, gasping, joyous] I lost, I lost — oh, that's what it — I didn't
> know it would feel like *that!* Like putting something *down!*

He sits there grinning up at the Fool. And around him, the light begins, very slightly,
to change. Not to dim — to *lean*. To go long. The dinner-plate shadow under him, pinned
tight at noon for three hundred years, twitches — and starts, for the first time since the
Stall, to *stretch*.

Aurel feels it before he sees it. His hand goes flat to the sand beside his own shadow as
it lengthens under his palm.

**AUREL**
> Oh. Oh — it's — the sun's *moving.* Look. Look at the sun. It's going *down.* [very
> quiet] It's allowed to go down now. Because I finally let it.

The office cracks — not a wound, a shell coming off. Three hundred years of undefeated,
of golden, of everyone's favourite, of the day's own knight who could never be spared —
all of it splits along a seam like a suit of armour a boy has finally, impossibly,
outgrown. And through the crack comes a name he has heard ten thousand times from ten
thousand mouths and has never once been allowed to claim as his own.

**AUREL**
> Aurel. They call me — [he stops. Tries it the other way. The way that was never his to
> say.] ...*I'm* Aurel. That's — that's me. I'm Aurel, and I *lost,* and the sun is going
> *down.*

END CUT SCENE

### EXT. THE NOONLANDS: The Sunflower Coliseum, The Ring — THE FIRST SUNSET *(set-piece)*

THIRD PERSON GAMEPLAY

**[The trailer sequence. Play it in real, visible time — no fade, no cut over the change.
The player keeps control and can walk the ring while it happens; nothing attacks. This is
the single largest lighting/art beat in the main-quest line — flag `art-audio.md` for a
priority pass.]**

The sun comes down the sky. Slowly, hugely, unmistakably — three hundred years of held
breath let out over a few real minutes. The white glare of noon warms to gold, and the
gold to amber, and every shadow in the whole vast Coliseum lengthens across the sand in
step: the benches, the gate-arch, the Fool, Pip, and Aurel most of all — Aurel, who casts
a longer and longer shadow across the ring, the first long shadow he has ever thrown in
his life, reaching out ahead of him toward the darkening east.

The ten thousand sunflowers of the arena wall begin, all together, with a sound like a
long slow sigh, to *turn* — tracking the sun down toward the horizon, doing at last the
one thing a sunflower is for and has been forbidden for three centuries: following the
light as it goes.

And in the amber light, sitting in the middle of the ring, Aurel grows up.

**[Aurel's aging, staged tenderly — a relief, never a loss, never body-horror. As the
light goes long and gold across him, the child-knight lengthens into a young man: taller,
the round face going lean and open, the armour that fit a boy now sitting easy on a man's
shoulders. Pace it to the sunset itself, so the growing-up and the sundown are one motion.
He watches his own hands change in the amber light with plain, delighted astonishment.]**

The crowd, silent since the final blow, finds its voice — not a cheer at first, but a
sound with no name, three hundred years of people watching the sky do a thing they had all
quietly stopped believing it could. And *then* the cheer, breaking over the ring like a
wave, harvest folk on their feet in the amber light weeping and laughing and pointing west.

Aurel — a young man now, and knowing it — gets to his feet in the long light and looks at
his own shadow stretching all the way across the ring.

CUT SCENE

**AUREL**
> Look at that. Look how *long* I am. [he laughs, wet-eyed, wholly happy] I've been noon
> my whole life. I never got to be evening. Nobody ever let the day finish so I could
> find out what came after being the best of it.

He turns to the Fool, and for the first time he does not look up at them — he meets them
level, young man to fellow traveller.

**AUREL**
> Thank you for beating me. Truly. It's the kindest thing anyone's done for me in three
> hundred years, and I've been done nothing but kindnesses. [grinning] Turns out growing
> up only takes an evening. You just need someone brave enough to let the sun go down.

He reaches up — a young man's reach now, easy — and takes something out of the last of the
gold light overhead the way another man might pick an apple: a single card, warm to the
touch, and hands it over himself, plainly, because it is at last only his to give.

**AUREL**
> Trump the Nineteenth. Daybreak, if it wants a name — the good half of what I was, kept
> and none of the cruelty. Carry the morning with you. Somebody ought to, now that I get
> to keep the evening.

**[The Fool receives Trump XIX, Daybreak. `[If Daybreak is the Fool's first Trump]`: the
Pocket Spread's Present slot unlocks with it — slot Daybreak to try its Solar Flare (an
AoE burst that also cleanses curses). `[Else]`: Daybreak joins the collection; a brief
reminder notes it can be slotted at the next Waystation.]**

END CUT SCENE

### EXT. THE NOONLANDS: The Sunflower Coliseum — THE FIRST NIGHT

THIRD PERSON GAMEPLAY

The amber goes to violet, the violet to a deep and unfamiliar blue, and the sun slides
under the western fields and is, for the first time in three hundred years, simply *gone*.
Full dark comes down over the Noonlands — the Spread's first true night since the Stall —
and it is enormous, and cool, and quiet, and the harvest folk stand about in it with their
faces turned up, having no idea at all what one is supposed to do with a dark like this.

**[If WS_STAR_UNBOUND: the moment full dark lands, the sky fills — the Mere's returned
stars, which have been waiting all this while for a night to be seen in, are *already*
overhead in their thousands, complete and blazing, as though they had been holding their
breath in the daylight the whole time. The crowd's gasp is for the stars. This is the
other half of the order-motif: the Star gave the sky its lights; the Sun, tonight, gives
them somewhere dark to shine.]**

**[If NOT WS_STAR_UNBOUND: the first sky is dark and bare — a plain, starless, ordinary
night, and no less overwhelming for it. Nobody here has seen the difference between empty
dark and starred dark, so nobody mourns what isn't there yet. The dark alone is the wonder.
Consistent with the order-independence rule (world.md §Interaction rules); the Star's lights
arrive whenever MQ17 is done.]**

In the new dark, over by the reel, the bright festival dancer has stopped dancing for the
first time in three hundred years and is standing very still, staring up, one hand pressed
to her own chest. *(Seed only — this is Sunny Loft's, SQ-NOONLANDS-02. Do not resolve her
here; let her fear stand unanswered.)*

### BARKS — the festival ground *(post-unbinding, first night)*

**Harvest Hand Random Lines**
> It's *cold.* I've never — is this cold? I think this is cold. I don't hate it. I
> thought I'd hate it.

> Poll threw and Fenner threw and — one of 'em *won.* First time ever. They're just
> staring at the tally board. Neither of 'em knows what to say. *(Seed only —
> SQ-NOONLANDS-03; do not resolve.)*

**Festival-goer Random Lines**
> Is it over? The day, I mean. Not the — is the *day* over? What do we do with the bit
> after the day? Does anyone remember?

> [If CONFESSED: So that's what you do. You let things end. It's more beautiful than I
> was afraid of, and sadder. Both. I didn't know a thing could be both.]

**THE QUERENT Random Lines** *(idle, first night)*
> Cool, isn't it. First cool anyone's felt in three hundred years. Go on, enjoy it —
> the night's new to everyone here but me.

### EXT. THE NOONLANDS: The West Fields, The Festival's Edge — THE FIRST NIGHT

THIRD PERSON GAMEPLAY

Away from the crowd, at the browning edge of the west fields where nobody was ever meant
to look, Bramble Coss stands alone in the dark with her clipboard of tallies hanging
forgotten at her side, watching the last violet drain out of the western sky. She is not
cheering. She is not smiling. There are tears on her face, and no performance left in her
at all.

**[Approach Bramble to trigger the aftermath scene. Pip sits down quietly beside her
before the Fool arrives.]**

### CUT SCENE

**BRAMBLE COSS**
> Thirty-one seasons. Three hundred years. I know every flag on every pole and the words
> to the reel and where every soul sits to watch it. [she gestures at the dark] I do not
> know one single thing about *this.* What's it *for*, an evening? What does a person even
> — what do you *do*, when the day's allowed to stop?

**THE FOOL**
> Rest, maybe. *(earnest)*

**BRAMBLE COSS**
> Rest. [she tries the word like a foreign coin] I built a whole life out of never
> needing to. It was a good life. It was the only one I planned for. And you walked in at
> noon and by nightfall it's — gone. The festival's still there, I know it's still there,
> but it won't be *forever* now, will it. Nothing will. That's the deal you brought.

A long beat. Somewhere behind them the crowd is learning to laugh in the dark.

**BRAMBLE COSS**
> [If CONFESSED: And here's the joke of it — I knew. Somewhere I always knew a forever
> festival was a fib we were all standing very still inside. Knowing didn't help. Knowing
> never once made the watching-it-end any easier.]
>
> I'm not asking for noon back. I want you to hear that. I wouldn't take it back if you
> offered. [her voice cracks] I just — I need a minute. To be a woman who lost her whole
> life on the finest evening there ever was. Give me that. Then I'll go and learn what a
> tomorrow's for, same as everybody.

**THE FOOL**
> Take all the minutes you like.

**BRAMBLE COSS**
> [a small, wet laugh] There's a novelty. Minutes I'm allowed to *spend.* ...Thank you.
> Go on. Go and watch the rest of it come down. You'll not see a first one twice.

END CUT SCENE

### EXT. THE NOONLANDS: The Grain Road — THE FIRST NIGHT *(the world registers it)*

THIRD PERSON GAMEPLAY

**[Montage note — do not script other regions' scenes; this is a single reactive beat
carried by the world-state bark layer (npc-system.md §rumor propagation, layer 3 keyed to
`WS_SUN_UNBOUND`). As the first dusk rolls out from the Noonlands, every region with
sightline to the sky registers the change in one line each: a Prestige barker noticing the
striped canvas has gone rose-coloured; a Confluence boatman watching the water turn amber;
a Spire bell-watch seeing the first shadow the broken tower has thrown in centuries; a
Hollows groundskeeper standing bareheaded as it goes dark over the graves. One bark each,
no cutscenes elsewhere — the whole Spread feeling one sundown at once.]**

The Fool walks back up the grain road in the last of the light. The sunflowers along it
have all finished turning west and now hang their heavy heads toward the vanished sun,
tired and satisfied, done for the day at last. Pip trots ahead and, on the crest of the
rise, sits down to watch the final sliver of colour go — ears up, entirely content, as
though he has been waiting three hundred years for someone to finally let the evening in.

### CUT SCENE

**THE QUERENT** *(quiet — the one wink of the quest, and it is spent not on a joke but on
the wonder itself)*
> There it goes. [a pause; the last of the colour drains from the sky] Three hundred
> years I've watched that sun sit up there refusing to budge, and I'd near forgotten what
> the going-down of it *does* to a person. Look at it, little Excuse. Really look. You
> and I are holding all of this up between us, you know — and just now, just this once,
> what we're holding up is the loveliest thing I've seen in three centuries.
>
> [If CONFESSED: a half-second longer before the line, the wonder sharing room with the
> knowing:] ...I'll not pretend I don't know what every sundown is a rehearsal for. Nor
> do you, any more. Doesn't make it less lovely. Might make it more. Go on. Watch. You
> earned this one.

The last light goes. Full dark holds over the Noonlands. Somewhere below, three hundred
years of daylight lets out its held breath, and the first night of the rest of the world
settles in for good.

END CUT SCENE

The eastern reaches of the Noonlands, and the wider night now falling over the whole
Spread, lie open and cool and turning at last. MQ19 ends here.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Aurel unbound (duel won + sunset cutscene) | `WS_SUN_UNBOUND` | The first sunset in 300 years plays as a set-piece; the global day/night cycle begins world-wide; nocturnal content unlocks everywhere; the Noonlands cool and the drought/sunstroke sidequests become resolvable (SQ-NOONLANDS-01, and SQ-NOONLANDS-02/03 unlock in the new evening); the Fool receives Trump XIX (Daybreak). If it is the Fool's first Trump, the Pocket Spread's Present slot unlocks with it. |
| First night, with the Star already unbound | reads `WS_STAR_UNBOUND` (set by MQ17) | The Mere's returned stars, which require a night to be seen, become fully visible the instant the first dark falls — the order-motif's second half. |

## Consistency references

- `arcana.md` §XIX. The Sun — the setpiece framing ("the trailer moment"), the
  radiant child-knight on a white pony, the read-his-shadow-not-his-body teaching as the
  fight's single lesson, the sunflower coliseum at permanent high noon, the loss-then-laugh
  beat, Trump XIX (Daybreak) and its slots, the growing-up-in-the-first-sunset unbinding.
- `world.md` §The Noonlands (the flagship world-change region; endless festival, drought
  at the edges), §World-state matrix (`WS_SUN_UNBOUND` effects; `WS_STAR_UNBOUND` requiring
  night), §Interaction rules (order-independence for the Star/Sun night pair).
- `characters.md` §XIX. The Sun — Aurel (cheer real and exhausting, a little brother's
  hero worship, underneath an envy of anyone allowed to age), §The 21 Arcana dialogue rule
  (a bound Arcanum never pairs "I" with the personal name until unbinding), §Regional named
  NPCs — The Noonlands: Bramble Coss (MQ19's mourner), with Thatch Corley, Sunny Loft, and
  Poll and Fenner Straw seeded only, as their side quests own them.
- `narrative.md` §Themes 1–3 (endings are a mercy; offices eat people — Aurel's name
  returns; freedom isn't wanted by everyone — Bramble's grief, shown not resolved), §Act II
  `CONFESSED` variants, §Dialogue style guide (Fool lines ≤ 12 words with an earnest option;
  the one Querent wink, spent on wonder; every sad scene owns one laugh, every comic one an
  honest beat).
- `npc-system.md` §Bark layers, §rumor propagation — the region-wide first-sunset montage
  carried as a layer-3 world-state bark keyed to `WS_SUN_UNBOUND`, not a set of scripted
  scenes.
- `callings.md` — the Harvest hand Calling (post-MQ19 becomes seasonal, "the first *last*
  harvest"), the working world the festival-ground barks sit in.
- `progression.md` §Slot unlock pacing — the Present slot unlocking with the first Trump
  acquired, whichever quest grants it (handled here for the order-independent case).
- `art-audio.md` — the sunset/first-night sequence is this quest's single largest asset;
  flagged for a priority pass at script status.
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- **[Resolved]** The name-before-unbinding rule: `GLOSSARY.md` §Naming conventions now
  states it precisely — four Arcana (Wicke, Mortimer, Aurel, Old Nick Lowry) are commonly
  named by others as public epithets while bound, and for all twenty-one the bound Arcanum
  never claims the name in their own first person. This script's staging (the Noonlands
  says "Aurel" freely; he never does, until the crack) is the intended pattern.
- Confirm the exact visual budget for the region-wide sky shift (the montage beat) with
  `art-audio.md` — the note assumes every region with Noonlands sightline registers the
  colour change, which may be a significant lighting-system cost.
- Aurel's aging needs an art-direction call: a smooth morph paced to the sunset, a series
  of discrete stages, or a single cut under cover of the light going long? Tone note holds:
  nothing that reads as loss.
- Should the qualifying-bout ladder be skippable for returning players or higher-Renown
  saves, given it is a soft gate rather than a hard one?
- The shadow-reading tutorial is delivered here by an **unnamed** device (a squire's
  practice-pell with a glare-rig) rather than the outline's proposed named squire, to avoid
  inventing canon in a script-status pass. If a named squire is ever wanted, add them to
  `characters.md` §Regional named NPCs first, in the same change.
- Daybreak's Solar Flare Fortune cost for the order-independent first-Trump tutorial cast
  is TBD at combat tuning (`arcana.md` cost-tier note) — does a first cast here need to be
  discounted or free, as with MQ01's Manifest?
