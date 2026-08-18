class_name QuestBranchGroup
extends Resource

## One mutually exclusive set of `WS_*` branch flags a quest's choice picks between.
##
## `docs/quests/README.md`'s frontmatter carries these as `branches` - a YAML list of
## lists, each inner list one group (`[WS_TROUPE_TRAVELING, WS_TROUPE_SETTLED]`), and
## `docs/design/world.md` §World-state matrix is where the flags themselves are
## defined. `godot/tools/gen_definitions.py` lifts the groups onto the generated
## `QuestDefinition`.
##
## The rule the group exists for: **exactly one member is ever fired**, and it is
## fired only when the quest completes. `QuestService` enforces both halves - it
## records the choice through `WorldStateService.set_quest_choice()` (set-once) and
## refuses to complete a quest that still owes a group its choice. Nothing here
## enforces anything; this is the data the runner enforces it with.

## The group's stable id, e.g. `&"MQ01_TROUPE"` - the same id
## `WorldStateDefinition.branch_group` carries on each member.
@export var group_id: StringName = &""

## The `WS_*` ids in the group, in doc order. Two or more; a choice with one option
## is not a choice.
@export var flags: Array[StringName] = []

## The fewest members a real choice can have.
const MINIMUM_MEMBERS := 2


## Every problem with this group, one string per problem; empty means valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if group_id == &"":
		errors.append("a quest branch group has no group id")
	if flags.size() < MINIMUM_MEMBERS:
		errors.append("branch group %s has %d members, fewer than %d" % [
			group_id, flags.size(), MINIMUM_MEMBERS
		])
	var seen: Dictionary = {}
	for flag: StringName in flags:
		if flag == &"":
			errors.append("branch group %s lists an empty flag id" % group_id)
			continue
		if seen.has(flag):
			errors.append("branch group %s lists %s twice" % [group_id, flag])
		seen[flag] = true
	return errors


## True when this group is the one `flag` belongs to.
func has_flag(flag: StringName) -> bool:
	return flags.has(flag)
