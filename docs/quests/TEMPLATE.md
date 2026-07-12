# Quest Script Template

Markdown adaptation of the original `Tarrock.docx` script format. Copy this file to
write a quest at `script` status; outlines use the lighter structure in
[`README.md`](README.md). Everything in `<angle brackets>` is replaced; everything in
`[square brackets]` is a scripting note that stays.

Format rules (from the source template, kept as law):

- Write the introductory paragraph **from the player's perspective**, not the
  character's — what the player does and needs to know, including other quests or world
  situations that bear on this one.
- In gameplay blocks, never write "walks around" filler — only specific actions that
  progress the quest ("Opens the door to Flick's wagon", "Picks up the torn ticket").
- NPCs with repeatable interactions get **Random Lines** (greeting variants).
- Choice dialogs are tables: player option → NPC response. Mark whether all options may
  be exhausted or the first pick commits.
- Branches are labeled with their condition and all branches are written. Every branch
  ends at a common pickup point marked `[All versions pick up here:]` — or explicitly
  ends the quest differently (then say so in World-state changes).
- Barks: ambient NPC random lines for the space the quest moves through.
- The Querent gets at most **one** fourth-wall wink per quest (narrative.md).

---

```yaml
---
id: <MQnn | SQ-REGION-nn>
title: <Title>
type: <main | side>
status: script
arcana: <card or none>
region: <region>
requires: [<flags/quests>]
fires: [<flags>]
branches:
  - [<flag-a>, <flag-b>]
---
```

# <ID> — <Title>

## Introduction

<Player-perspective paragraph: the quest's premise, where it starts, what the player
needs to know, relevant world situations and other quests.>

---

## QUEST: <SEQUENCE NAME>

### INT./EXT. <LEAD LOCATION>: <SPECIFIC LOCATION> — <DAY / NIGHT / STATE-DEPENDENT>

THIRD PERSON GAMEPLAY

<Specific player actions that progress the quest.>

<Describe what the player sees in a new space: sights, sounds, what moves and what
doesn't. Tie descriptions to world-state variants where they differ:>
[If WS_<FLAG>: <how this space differs>]

<CHARACTER> approaches the Fool.

**<CHARACTER> Random Lines** *(repeatable greeting; pick one at random)*

> <Line variant 1>

> <Line variant 2>

> <Line variant 3>

TRANSITION TO CUT SCENE

### CUT SCENE

**<CHARACTER 1>**
> <Dialogue>

**<CHARACTER 2>**
> <Dialogue>

[Continue alternating as needed.]

END CUT SCENE

### CHOICE DIALOG — <topic> *(all questions may be exhausted | first pick commits)*

| The Fool | <NPC>'s response |
|---|---|
| <Option/question 1 (≤ 12 words; include one earnest/foolish option)> | <Response 1> |
| <Option/question 2> | <Response 2> |
| <Option/question 3> | <Response 3> |

[The following dialogues answer follow-ups if the player pursues them.]

**If the Fool asked <question 1>:**

| The Fool | <NPC>'s response |
|---|---|
| <Follow-up> | <Answer> |

**If the Fool asked <question 2>:**

**<NPC>**
> <Dialogue>

**THE FOOL**
> <Chosen line plays back>

[All versions pick up here:]

<NPC> hands the Fool <ITEM>.

### BARKS — <space the quest moves through>

**<NPC type 1> Random Lines**
> <Bark>

**<NPC type 2> Random Lines**
> <Bark>

**<NPC type 3> Random Lines**
> <Bark>

[The next scene depends on how <CONDITION> goes:]

**If the player <found/did/won> <BLANK>:**

<Outcome. If this opens choices, present the Choice Options table:>

### CHOICE OPTIONS — <the decision> *(first pick commits; confirm prompt)*

| Choice | Consequence |
|---|---|
| <Choice 1> | <World-state change / outcome 1> |
| <Choice 2> | <World-state change / outcome 2> |

**If the player did not <find/do/win> <BLANK>:**

<Different outcome — a quest may "fail forward" into a lesser result, never a dead end.>

[All subsets end here:]

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| <Completion / choice> | `<WS_FLAG>` | <what changes in the world> |

## Consistency references

- `<design doc §section>` — <what this quest takes from it>

## Open questions

- <Decision needed, phrased as a decision>
