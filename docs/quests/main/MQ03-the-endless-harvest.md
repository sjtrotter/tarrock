---
id: MQ03
title: The Endless Harvest
type: main
status: script
arcana: III. The Empress
region: The Bower
requires: []
fires: [WS_EMPRESS_UNBOUND]
---

# MQ03 — The Endless Harvest

## Introduction

The player pushes into the Bower expecting a garden and finds a horror wearing a garden's
face: wheat gone to the horizon and never cut, orchard boughs bowed low enough to weep sap
onto the road, air thick with rot-sweet honey. The quest begins at the old cart road on
the region's border, swallowed to the axles in unharvested grain, and moves inward through
a hungry Coins-culture family's roadside stall, an orchardman's devoted pruning, and an
attendants' tribute-path, to the Briar Throne at the region's heart. There sits the
Empress, grown through by three centuries of her own abundance and unable to rise. The
player's task is not to kill anything that wants killing — it is to **prune**: sever the
crown-roses feeding her living throne while it defends itself, and let daylight back into a
garden that has been strangling on its own love since the Stall. Two soft choices colour
the road — whether to share food with the hungry family, and whether to heed the
orchardman's warning or press past it — but neither gates the fight, and both are
NPC-level only. On completion the world's harvests finally come in and the Fool receives
**Trump III (Bloom)**, handed over personally, mid-fuss. Because MQ03 requires nothing
(`requires: []`), it may be a player's first region or their fifth; where another
world-state changes a scene the script carries the variant, and every key scene carries an
`[If CONFESSED]` variant for players who have already heard Death's confession.

---

## QUEST: THE ENDLESS HARVEST

### EXT. THE BOWER: The Swallowed Cart Road — ENDLESS AFTERNOON

THIRD PERSON GAMEPLAY

The road into the Bower simply drowns. What was once a proper cart track — two ruts and a
grassy crown — runs on for a hundred yards and then goes under: wheat to either side has
crept inward and upward until the track is a seam of shadow in a sea of gold, stalks nodding
heavy-headed over it, buried to the axles of a hay-cart that stopped here so long ago its
wheels have gone to green. Nobody unloaded it. Nobody will. The light is a thick, honeyed
late-afternoon that does not advance an inch, and the whole air smells of fruit a day past
its best.

Pip trots to the cart, sniffs a wheel, and sneezes once at the pollen, entirely unbothered.

**[Tutorial-adjacent prompt (if MQ03 is played early): the White Rose stirs faintly near
the wheat, as it does near all growing things in the Bower — no mechanical effect yet.]**

**THE QUERENT**
> Here's where "later" set in, little Excuse. Somebody parked that cart three hundred years
> ago meaning to bring it round after the harvest — and the harvest was never called, so the
> cart's still waiting on a word that never came. Whole region's like that. Everything ripe,
> nothing gathered. Mind the smell. You get used to it. That's rather the trouble.

### BARKS — the swallowed road *(idle, pre-unbinding)*

**THE QUERENT Random Lines**

> Gold as far as the eye goes, and not a loaf to show for it. There's a lesson in that,
> though I'll be blowed if I can make it a cheerful one.

> Careful of the low boughs further in. They weep. Sap in the hair is a two-day business.

> [If CONFESSED: She'll be glad to see you, this one. That's the hard part. Glad right up to
> the end.]

### EXT. THE BOWER: The Roadside Stall — ENDLESS AFTERNOON

THIRD PERSON GAMEPLAY

Where the swallowed road meets a lane, a lean-to stall stands in the shade of a granary so
full its doors bulge — grain trickling in a thin gold thread from a split board seam, a
waste nobody stoops to catch. At the stall sits a Coins-culture family: a spare, sun-browned
man in a pocketed brown coat with a ledger on his belt; a woman shelling the one thing they
are allowed, a handful of windfall crabs; and two thin children who watch Pip with the frank
attention of the genuinely hungry. Behind them: everything. In front of them: crab-apples and
the discipline not to touch the rest.

Opens the conversation at the stall.

**Coins Stallholder Random Lines** *(repeatable greeting; pick one at random)*

> Custom! First we've had in — [he consults the ledger, entirely deadpan] — some while.
> Mind, we've nothing to sell you and no leave to give it away. But you're very welcome to
> look.

> Grand harvest we're not having this year. Same as every year. Consistency's worth
> something, my old dad used to say, before he starved of it.

> [If CONFESSED: We've heard about you, friend. The one who turns the cards loose. If it's
> all the same to you — turn ours soon. The children have got the theory of bread down
> perfect and none of the practice.]

TRANSITION TO CUT SCENE

### CUT SCENE

**COINS STALLHOLDER**
> You'll be wanting through to the middle, by the look of you. Nobody wants through to the
> middle except folk with business at the Throne. Bad business, generally. Good luck to you,
> then — and I mean that in the full and ruinous sense.

**THE FOOL**
> Why not just eat the grain behind you?

**COINS STALLHOLDER** *(no bitterness, only arithmetic)*
> Ah. Now. It's hers, see. All of it, hers, until the harvest's *called* — and she's never
> called it, and a body that helps itself before the word is a body that's stolen from the
> Lady who loves us. That's the deal. Bursting granaries and a lawful little hunger.
> Beautiful, in its way. I'd charge admission if I thought anyone'd pay to see it.

END CUT SCENE

### CHOICE DIALOG — the hungry family *(all questions may be exhausted)*

| The Fool | The Stallholder's response |
|---|---|
| Who calls the harvest? | The Empress. Only the Empress. And she'd sooner grow you a peach in your hand than let one fall to the ground uncounted. |
| May I borrow a billhook? | Take it, and welcome — it's the one thing here that's mine to lend. You'll want it for the road ahead. Cut, mind. Don't expect the cut to *stay* cut. |
| Take some of my food. *(earnest)* | [a long pause; pride and hunger doing brief, silent battle] ...The little ones first, then. That's — that's a kind thing. We'll not forget the face that did it. |
| Has anyone ever asked her nicely? *(foolish)* | Oh, several. She fed them very well and sent them home. You don't out-*love* the Empress, friend. Wiser folk than you have tried and left three stone heavier. |

**If the Fool chose "Take some of my food":**

The Fool shares out rations from the Bindle. The children eat like it's a festival; the
mother turns away to compose herself; the stallholder writes something small in his ledger
with a hand that isn't quite steady. **[NPC-level kindness memory set — no `WS_*` flag; this
NPC's later barks and the closing beat soften accordingly.]**

**If the Fool asked "May I borrow a billhook":**

The stallholder hands over a worn, curved orchard blade.

**COINS STALLHOLDER**
> There. Now you can make yourself a path. Whether the path makes *you* anything back is
> between you and the wheat.

[All versions pick up here:]

The billhook goes into the Bindle. The lane ahead vanishes under grain within a dozen paces.

### EXT. THE BOWER: The Swallowed Lane — ENDLESS AFTERNOON

THIRD PERSON GAMEPLAY

Cuts a path through the swallowed lane with the billhook.

**[Gameplay: billhook traversal — clear grain to open the way forward. Per `callings.md`
§Farmhand, pre-`WS_EMPRESS_UNBOUND` nothing may be *finished* being cut: each swathe the Fool
opens seals shut behind them within a few paces, green stalks standing back up as though
never touched. The path forward opens; the path back closes. The Bower does not let you
un-arrive.]**

**THE QUERENT**
> Watch behind you. Go on — watch. See it stand back up? Three hundred years of gardeners
> have tried to cut this region down to something a person could live in, and it grows back
> faster than a body can swing. There's a fellow up ahead who never learned to stop. Do be
> gentle with him. He means it.

### EXT. THE BOWER: Gaffer Nettle's Orchard — ENDLESS AFTERNOON

THIRD PERSON GAMEPLAY

The wheat gives way to orchard: rank on rank of fruit trees bowed so low with unpicked apples
and pears and quince that the boughs graze the grass, some split clean under the weight and
still fruiting from the wound. Sap runs down the bark in slow amber ropes. And in the middle
of it, on a three-legged stool that has worn its own hollow into the ground, sits GAFFER
NETTLE — an old, old orchardman, hands like knots of applewood, a pair of long shears across
his knees, trimming briars off a bough with the unhurried certainty of a man who has done
exactly this every day for longer than anyone alive.

Approaches Gaffer Nettle.

**GAFFER NETTLE Random Lines** *(repeatable greeting; pick one at random)*

> Mind the sap. And mind the stool — she made it grow up under me one afternoon, kind as you
> please, so I'd never have to fetch my own seat again. Can't rightly leave it now. Roots.

> Come to see the Lady, have you. They always have. Sit a while first. Nothing in this garden
> was ever improved by hurrying at it.

> [If CONFESSED: I've heard what you are, young'un. The one that ends things. I'll not stop
> you — I couldn't — but I'll tell you now, I mean to keep these shears going for as long as
> there's a garden left to prune. A man ought to have a thing to do of a morning.]

TRANSITION TO CUT SCENE

### CUT SCENE

**GAFFER NETTLE**
> Now. I know that look. That's a *helping* look. Put it away.

**THE FOOL**
> I only want to reach the Throne.

**GAFFER NETTLE**
> Aye, and you'll reach it, and you'll get some fool notion in your head about *fixing* her,
> and it'll break your heart and hers besides. I've pruned these briars sixty years, boy.
> Sixty years, every day, and look — [he gestures at the drowning orchard, the split boughs,
> the endless weeping fruit] — look how *well* it's going. She doesn't take kindly to help.
> Trust an old hand. The most a body can do for the Lady is trim a little and love her and
> let her be.

END CUT SCENE

### CHOICE OPTIONS — Gaffer Nettle's warning *(first pick commits; NPC-level only, no confirm)*

| Choice | Consequence |
|---|---|
| Heed him — wait to be invited to the Throne. | **NPC-level memory: heeded.** Gaffer nods, mollified, and walks the Fool part-way along the attendants' path himself, naming the trees. A slightly longer, gentler approach; the Empress greets an invited guest. |
| Press on past him to the Throne. | **NPC-level memory: pressed.** Gaffer sighs and lets the Fool by without another word, shears already back at the briars. A slightly shorter approach; the Empress notes, faintly, that this one did not wait. |

**[Both choices set an NPC-level flag only — no `WS_*` flag. They change the Empress's opening
line at the Throne and a small approach-time difference, nothing else.]**

[All versions pick up here:]

The path inward runs on through the trees toward a canopy so thick it swallows the light.

### EXT. THE BOWER: The Attendants' Tribute-Path — ENDLESS AFTERNOON, UNDER CANOPY

THIRD PERSON GAMEPLAY

Under the closed canopy the endless afternoon goes green and dim, the air so heavy with
pollen it hangs in visible gold drifts. A trodden path winds inward, marked every few yards
by little heaps of tribute-fruit left to rot sweet in wooden bowls — offerings the garden
never asked for and never eats. A few Bower folk, Coins and Wands orchard-hands gone
slow-eyed and dreamy, still shuffle fruit up the path out of three centuries of habit, laying
it down and drifting back for more.

Follows the tribute-path inward. Along it, **pollen-drunk Blanks** — soldier-figures bloated
and sluggish on three centuries of unharvested fruit, ivy grown through their tabards, cards
faded to ghosts of a suit — lurch up from the bowls and swing.

**[Gameplay: light combat through the tribute-path. The pollen-drunk Blanks are slow and
telegraph wide; ideal ground to practice Fool's Chance dodges. Pip's Harry herds the
stragglers back off the path. Felled Blanks slump and their faded cards drift off through the
canopy as ever — nothing here ends.]**

### BARKS — the tribute-path *(pollen-drunk attendants; pre-unbinding)*

**Dreamy Orchard-Hand Random Lines**

> Tribute for the Lady. Always more tribute. She does so love a full bowl. I forget, now, what
> we did before the bowls.

> Don't wake me, there's a dear. It's such a *soft* afternoon. It's always such a soft
> afternoon.

> [If CONFESSED: They say when you've done your business at the Throne the afternoon ends.
> Ends. Imagine that. I can't. I've been trying for a hundred years and I can't.]

The path opens, at its end, onto light of a wholly different kind.

### EXT. THE BOWER: The Briar Throne — ENDLESS AFTERNOON

THIRD PERSON GAMEPLAY

The canopy breaks over a great sunken bower, and at its heart: the Briar Throne. It is not a
chair. It is a swelling of the garden itself — a vast knot of root, bramble, and flowering
briar risen up chest-high and wide as a cottage, every inch of it fruiting and blooming at
once, and grown *through* the woman seated at its centre. THE EMPRESS. She is huge with the
garden and cannot be told where she ends and it begins: briars laced through her sleeves,
roses opened along her arms, a crown of them at her brow, roots at her feet gone down past
finding. In one open hand she holds out a single perfect peach. She has been holding it out
for three hundred years. She cannot draw it back, and she cannot rise, and she is *smiling*,
and the smile is the worst thing in the garden.

Approaches the Throne.

**[If NPC-level memory = heeded: the Empress's first line is the warm welcome below.]**
**[If NPC-level memory = pressed: she opens instead with — "Straight past dear old Nettle,
were we? In such a hurry. Well. You're here now, and you're *thin*. Sit."]**

**THE EMPRESS** *(warm welcome variant)*
> There you are. There you *are* — oh, come in, come in, out of the draught, not that there's
> a draught, I'd never allow one. Let me look at you. [a beat] You've come a long way on very
> little, haven't you. When did you last eat? Never mind. Eat this. Eat it here where I can
> see you do it.

She cannot move the hand. The peach stays exactly where it is.

### CHOICE DIALOG — the Empress at the Throne *(all questions may be exhausted; last option commits to the fight)*

| The Fool | The Empress's response |
|---|---|
| Why can't you stand? | Stand? Whatever for? Everything I love is right here, in reach. If I stood I might leave something un-tended. I couldn't bear that. Sit down, you're making me anxious. |
| The whole region is starving. | Starving? Nobody starves in *my* garden — look at it, there's food on every branch! They only have to wait for me to call it. I'll call it soon. I've been about to call it for the longest while. |
| Doesn't holding still hurt? | [a flicker; then the smile, firmer] Love doesn't hurt, child. Love *stays*. I stayed. That's all a mother is, in the end — a thing that would not leave. Now. Have you eaten or haven't you. |
| I've come to prune your garden. *(earnest — commits to the fight)* | ...*Prune.* [the warmth doesn't drop so much as crack] Oh. You're one of *those*. You've the same look they all had, the ones with the shears and the kindness. You want to *cut things down*. In my garden. Because you think it would be *better*. [very quietly, wounded past anger] I made all of this so that nothing would ever have to end. And you've walked into the middle of it to end it. Sit down. Sit *down*. ...No. No, you won't, will you. Then I'm sorry, little one. I truly am. But I won't let you take my garden from me. Not while I can hold it. |

**[The first three questions may be exhausted freely. Selecting "I've come to prune your
garden" commits: the Empress's briars rear, the crown-roses at the Throne's four corners
flush blood-bright, and the fight begins.]**

TRANSITION TO GAMEPLAY

### EXT. THE BOWER: The Briar Throne — THE PRUNING

THIRD PERSON GAMEPLAY

**[Boss encounter, per `arcana.md` §III (stationary siege, tier M). The Empress never moves —
she cannot. The *Throne* fights: lash-vines whip from the bramble on a readable rhythm,
pollen-drunk Blanks haul themselves up from the roots as adds, and the whole bower is roofed
in a strangling canopy that keeps the arena dim. The win condition is pruning, not damage to
the Empress: sever the great **crown-roses** that feed the Throne. Each crown-rose cut collapses
a section of the choking canopy overhead, and real light floods that quarter of the arena —
the ground the Fool fights on visibly changes with the brightening, hazards and cover shifting
as the garden opens. She does not defend herself. She defends the garden.]**

**[Number of crown-roses / phases is written here as three for pacing; exact count is TBD at
combat tuning — see Open questions.]**

**THE EMPRESS** *(over the fight, not shouting — she never raises her voice)*
> You'll tire before I do, little one. I've held all this three hundred years. I can hold it
> through one more headstrong child with a knife.

**[On the FIRST crown-rose severed — the north canopy caves in; a bar of hard daylight falls
across the bower for the first time in centuries. Brief cut to the Empress:]**

### CUT SCENE — after the first crown-rose

**THE EMPRESS**
> — Thank you.

A silence. The word plainly surprised her more than it surprised the Fool.

**THE EMPRESS**
> ...Why did I *say* that. You've cut a thing I grew and I — [she stops, genuinely lost] — the
> light. It's so bright where you cut. I'd forgotten bright. Go on, then. Don't you dare go on.
> Go on.

> [If CONFESSED: I know what you are, you know. What this is. It isn't one rose. It's all of
> them, everywhere, and then it's me, and then it's the whole Reading gathered up like
> windfalls. And I'm *thanking* you for the first cut. What does that make me. Oh, what does
> that make me.]

END CUT SCENE

**[Gameplay resumes. The Empress's between-phase thanks recur after each subsequent crown-rose,
each costing her visibly more — gratitude for being hurt is not a metaphor she enjoys, and the
game never plays it as one. The lash-vine patterns intensify as the arena brightens; the adds
thin as their pollen-canopy is stripped away.]**

### CUT SCENE — after the second crown-rose

**THE EMPRESS**
> Thank you. There — I've said it a-purpose this time, so it's mine and not just torn out of
> me. Thank you. It is the hardest thing I have ever done and I have held a garden up with my
> own body since the world stopped. [her smile is wet now, and still a smile] You're not
> cruel. That's the pity of it. If you were cruel I could hate you and hate is *warm*, hate
> would keep me. But you're kind, and kindness doesn't stay, kindness *moves you along*—

> [If CONFESSED: — and I know exactly where it moves you along *to*. I've done the sum, same
> as you have. Every card you free is a step nearer the last one, and the last one is the
> door closing on all of us for good. And still. And *still*. Thank you for the light. Grief
> and gratitude, all in one breath. I never knew they were the same shape.]

END CUT SCENE

**[Gameplay resumes. Final phase: only the great southern crown-rose remains, and the Throne
throws everything left into the last of its lash-vines. Severing it collapses the last of the
canopy.]**

**[On the FINAL crown-rose severed:]**

The last briar parts. The whole roof of the bower comes down in a slow rain of dead leaf and
spent blossom, and — for the first time since the Stall — full daylight reaches the Briar
Throne, top to bottom, gold and merciless and clean.

**[If WS_SUN_UNBOUND: it is a night when the Fool finishes — then it is not daylight that
reaches the Throne but the first honest starlight, cool and enormous, the garden silvered
instead of gilded. Either way: real sky, at last, after three hundred years of ceiling.]**

TRANSITION TO CUT SCENE

### CUT SCENE — the unbinding

The Throne, unfed, gives all at once. It does not shatter. It *splits* — slow and clean along
a seam, like a seedpod come finally, three centuries late, to term — and folds open around the
woman at its heart, briars withering back from her sleeves, roses closing, roots letting go of
her feet with a sound like a held breath released.

**THE EMPRESS**
> Oh. Oh, there's so much of it. When did it get so — I couldn't feel where I stopped. For the
> longest time I couldn't feel where I *stopped*—

Something surfaces under the office, the way a name does: not injury, not defeat, just a thing
long buried coming up for air.

**THE EMPRESS**
> ...Damson.

She says it the way you'd say a word in a language you spoke as a child. Testing that it still
fits the mouth.

**DAMSON**
> Damson. That was — that's *me*. I had a name before the garden had me. Damson. [she laughs,
> astonished, and it breaks halfway into something else] I was a girl who liked things to grow.
> That was all. That was the whole of it, at the start.

She looks at the Fool — properly, for the first time, no longer smiling because she has to.

**DAMSON**
> [If CONFESSED: You came all this way carrying what you carry, and you sat and let me feed you
> anyway, and you cut me loose knowing exactly what loose *costs*. That's — I don't have a word
> for that. My whole vocabulary was fruit.]
>
> You're still far too thin. I noticed the whole time, I couldn't say it and hold the garden
> both. Here.

From the open bower she draws a single card — no flourish, only a mother handing over the one
thing she has that's worth having.

**DAMSON**
> Trump the Third. Bloom, they'll call it, if anyone writes it kindly. Take it. It'll make
> things grow for you — a snare, a vine, a rose that comes back even where the ground says no.
> [a beat, and the mournful heart of her] Grow something you can bear to cut down, this time.
> That's the trick I never learned. Everything I loved, I loved so hard it couldn't end. Don't
> do that to a garden. Don't do that to anyone. Now go on. *Eat*, first. Then go on.

**[Trump III (Bloom) received. If Bloom is the Fool's first Trump, the Pocket Spread's Present
slot unlocks here per `progression.md` §Slot unlock pacing — the first Trump opens the Present
slot regardless of which region it comes from.]**

END CUT SCENE

### EXT. THE BOWER: Gaffer Nettle's Orchard — ENDLESS AFTERNOON GIVING WAY

THIRD PERSON GAMEPLAY

Passes back out through the orchard. The change is already running ahead of the Fool through
the trees: the stranglevines that roofed the tribute-path are receding visibly, sliding back
off the boughs; the split, over-fruited branches are letting go their loads at last, apples
and pears coming down in a soft continuous drumming all across the orchard, three centuries of
unpicked harvest hitting the grass at once. The interior groves stand open where the vines have
pulled back. The heavy honeyed light is thinning toward an ordinary, mortal evening.

Gaffer Nettle stands in the middle of the falling fruit, shears in one hand, and does not lift
them. There is nothing left to prune. The briars he tended for sixty years are simply gone.

**GAFFER NETTLE** *(mourning; he is not angry, which is worse)*
> Well. There it is. Sixty years of mornings, and now the trees do it themselves and don't
> want me. [he turns the shears over in his hands] Funny thing about a job you never asked
> whether it needed doing. You find out all at once, on a Tuesday, that it didn't. And you're
> left holding the shears. [a dry, wet laugh] Don't mind me, young'un. It's a good thing you've
> done. It's a *good* thing. I'll want a day or two to remember what my hands are for otherwise,
> is all.

> [If CONFESSED: I told you I'd keep pruning as long as there was a garden. Well — there's a
> garden yet, only now it's a garden that *lives*, and a living garden still wants a hand on it,
> here and there. So I'll not be idle after all. Slower work. Kinder work. I'll manage. You go
> on and do the rest of them. Somebody has to. Might as well be the one who came and *sat* with
> a man first.]

### EXT. THE BOWER: The Roadside Stall — EVENING

THIRD PERSON GAMEPLAY

Reaches the stall on the way out. The granary doors stand open — not burst, *opened* — and the
Coins family is on its feet, because from somewhere deep in the garden and everywhere at once a
sound is going up that this region has not heard since the Stall: a long, ringing, joyous call,
the harvest being *called*, three hundred years late, by a woman who at last remembers she is
allowed to let a thing be finished.

**COINS STALLHOLDER** *(the driest man in the Bower, undone)*
> That's — [he checks the ledger from pure reflex, then puts it down, which for him is a
> confession] — that's the call. That's the *harvest call*. I never once believed I'd hear it.
> I costed it out years ago as a nil return. [he laughs, ragged] Children. *Children.* You may
> touch the grain. You may touch all of it. It's lawful. It's finally, blessedly lawful.

> [If the Fool shared food earlier: And you — you fed mine when there was nothing in it for
> you and no law said you must. A body remembers a thing like that longer than a good year. If
> you're ever hungry on this road again, friend, you'll not be. That's a debt, and I keep my
> books.]

> [If CONFESSED: We know what your road does, in the end. We've heard. This harvest here — it's
> not one that comes forever now, is it. It'll want *bringing in*, and sowing again, and
> watching over, like harvests did before the world stopped playing safe. [steady] Good. Let it
> cost something. Bread that can't run out was never really bread. Thank you, friend. Truly.]

### CUT SCENE — leaving the Bower

The children are already running the grain through their fingers. The Querent lets it sit a
moment before speaking, fond and unhurried.

**THE QUERENT**
> Three hundred years she held all that up so nobody would ever have to say goodbye to a
> summer. And it took a stranger with a dog and a borrowed billhook to show her that a garden
> only means anything *because* it ends — that you have to let the apples fall to get another
> spring. [a pause] You've been doing that all along, you know. Pruning. The whole Spread,
> card by card, one careful cut at a time — and I've been standing just off the edge of every
> one of them, holding the shears steady while you learn the weight. *(the one wink — warm,
> direct, and gone as fast as it comes)* Don't look at me like that. Somebody has to hold the
> shears. Go on, little Excuse. There's more garden yet.

END CUT SCENE

The lane out of the Bower, choked to the axles when the Fool arrived, lies open behind the
falling harvest — cut, this time, and staying cut. MQ03 ends here.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion (Empress unbound) | `WS_EMPRESS_UNBOUND` | Harvests complete across the Spread; food prices halve (systemic, owned by economy design); the Bower's stranglevines recede, opening its interior groves and the tribute-path; the famine sidequests resolve, and SQ-BOWER-03 ("The Hoarder's Ledger") becomes available. The Fool receives **Trump III (Bloom)**. |
| Player shares food with the hungry family | *(none — NPC-level memory only)* | The Coins stallholder's later barks and the closing beat soften; a standing debt-of-honour is spoken, not mechanized. No `WS_*` flag; no other quest reads it. |
| Player heeds / presses past Gaffer Nettle | *(none — NPC-level memory only)* | Changes the Empress's opening line at the Throne and a small approach-time difference. No `WS_*` flag; the fight is identical either way. |

## Consistency references

- `arcana.md` §III. The Empress — the pruning-fight design (stationary siege; sever the
  crown-roses feeding the living Throne while it defends with lash-vines and pollen-drunk
  Blanks; she never moves; each cut opens the canopy and changes the light; "she thanks you
  between phases; it is not a metaphor she enjoys"), tier M, and Trump III (Bloom). Staged, not
  altered.
- `characters.md` §III. The Empress — Damson: loved the Bower into being and cannot stop; sees
  the Fool as a child to fuss over and feed; genuinely wounded that this arrival wants to change
  the garden. §Regional named NPCs (The Bower) — Gaffer Nettle (canon), the devoted orchardman
  and his mourning. §The Minors (Coins row — measured, transactional, prices everything fondly,
  the driest jokes in the game) — the roadside family's voice. §The Fool, §Pip, §The Querent —
  Fool voiced by choice (≤12 words, earnest/foolish option), Pip unbothered, the never-self-name
  rule for bound Arcana and the one-wink rule.
- `world.md` §The Bower — overripe abundance as horror-lite; wheat to the horizon that may never
  be cut; the abundance-as-famine irony. §World-state matrix (`WS_EMPRESS_UNBOUND`) — exact world
  effects staged above. §Regions/compass — the Bower as an eastern "morning" entry region.
- `narrative.md` §Themes (1: endings are a mercy, the frozen world is the villain and the Empress
  is not; 2: offices eat people — her name returns; 3: every unbinding hurts someone ordinary —
  Gaffer Nettle, shown not resolved). §Act I tone (playful, joyous unbinding) and §Act II
  `CONFESSED` variants. §Dialogue style guide — storybook British, the melancholy rule (every sad
  scene one laugh, every comic scene one honest beat), the one Querent wink.
- `callings.md` §The Callings (Farmhand) — pre-MQ03 rows/paths regrow behind you (the swallowed-
  lane traversal plays that futility); post-`WS_EMPRESS_UNBOUND` real harvests, staged in the
  aftermath and closing beats.
- `progression.md` §Slot unlock pacing — the first Trump opens the Present slot regardless of
  region, handled for players who reach the Bower before the Prestige.
- `npc-system.md` §Bark layers — the Random Lines / Barks sets are authored as this quest's
  layer-1 (quest-scripted) and region layer-3/`CONFESSED` layer-4 content per the seven-layer
  model.
- `quests/side/SQ-BOWER-01`, `SQ-BOWER-02`, `SQ-BOWER-03` — the Bower slate NPCs (Tibb Wren,
  Coraline Ashe, Marchpane Boll) are left off-screen here and unnamed walk-ons are used, so no
  side quest is contradicted; SQ-BOWER-03 is one of the famine sidequests this quest's flag
  resolves.
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- Should Gaffer Nettle survive as a recurring Bower NPC after this quest (a candidate for a short
  side quest about learning a new trade), or is his arc complete here? *(Carried from outline —
  unresolved. The `[If CONFESSED]` mourning variant above tentatively keeps him working "kinder,
  slower" post-unbinding, which would support a recurring role, but the non-CONFESSED variant
  leaves it open; canon to decide.)*
- Does the "food prices halve" world-state need a visible price-tag / vendor UI beat in-quest
  (e.g. the closing stall scene showing the change), or is that purely a systemic change owned by
  economy design? *(Carried from outline — unresolved. Script currently treats pricing as systemic
  and stages the change narratively via the harvest call only.)*
- **New (delta):** exact number of crown-roses / fight phases is written as three for pacing but
  is not fixed by `arcana.md` — confirm at combat tuning. The between-phase "thanks" cut scenes are
  written for a three-rose structure; more or fewer roses will change how many escalating thanks
  beats are authored.
- **New (delta):** the hungry Coins family at the roadside stall is deliberately left **unnamed**
  (unnamed walk-ons per the no-new-canon rule). SQ-BOWER-03's open question proposes cross-linking
  them to Marchpane Boll (as a household he gouged or quietly fed); keeping them unnamed here
  preserves that option without committing to it. Decide the cross-link when SQ-BOWER-03 reaches
  script status.
- **Resolved:** `progression.md` §Slot unlock pacing now reads "the first Trump acquired,
  whichever quest grants it," and MQ01's unlock beat carries an `[If first Trump / Else]`
  conditional — this script's handling is the intended pattern.
