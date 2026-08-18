class_name DialogueNode
extends Resource

## One node of a dialogue graph: a line, a choice table, a world-state branch, an
## event, a Random Lines pool, or the end of a thread.
##
## The kinds are the quest script format compiled (`docs/quests/TEMPLATE.md`):
## a `**CHARACTER**` block is a `LINE`, a `### CHOICE DIALOG` table is a `CHOICE`
## whose options carry the "If the Fool asked ..." threads, a `[If WS_...]` /
## `[If CONFESSED:]` variant is a `BRANCH`, a `**... Random Lines**` list is a
## `POOL`, and `[All versions pick up here:]` is where a table's `after_all` lands.
##
## Every kind uses only the fields its own section documents; the rest stay at their
## defaults. One Resource with six shapes is deliberate - it keeps a graph one
## readable `.tres` instead of six interleaved sub-resource types, and
## `DialogueGraph.validate()` is what holds each kind to its own fields.

## What this node is.
enum Kind {
	## Someone says one line, and the conversation waits for `advance()`.
	LINE,
	## A choice table: the Fool picks a line, which opens that option's thread.
	CHOICE,
	## A world-state question. Never presented - the runner walks straight through
	## it to `then_node` or `else_node`.
	BRANCH,
	## Raises a `QuestEvents` id and walks on. Never presented.
	EVENT,
	## Random Lines: one key out of several, then the conversation waits.
	POOL,
	## The end of a thread. In an exhaustible table it returns to the choice; at
	## the top level it ends the conversation.
	END,
}

## How a choice table may be played (`docs/quests/TEMPLATE.md`: "Mark whether all
## options may be exhausted or the first pick commits").
enum ChoiceMode {
	## *(all questions may be exhausted)* - every option's thread returns to the
	## table, and the table is done when they have all been taken or the Fool leaves.
	EXHAUST_ALL,
	## *(first pick commits)* - the chosen option's thread simply continues on, and
	## the table is never offered again.
	FIRST_PICK_COMMITS,
}

## `requires_confessed` values. CONFESSED is `WS_DEATH_UNBOUND`
## (`docs/design/world.md` §Global states), queried through `WorldStateService`.
const CONFESSED_ANY := -1
const CONFESSED_NO := 0
const CONFESSED_YES := 1

## A `min_act` of 0 is `Act.ACT_I`, which is every act: no constraint.
const MIN_ACT_ANY := 0

## This node's id inside its graph, e.g. `&"Q_WHO_ARE_YOU"`. Unique per graph.
@export var id: StringName = &""

## Which of the six shapes below this node has.
@export var kind: Kind = Kind.LINE

# --- LINE and POOL -----------------------------------------------------------

## Who speaks (`Speakers`). `LINE` and `POOL` only.
@export var speaker: StringName = &""

## The line, as a translation key. `LINE` only.
@export var text_key: StringName = &""

## Where the conversation goes next. `LINE`, `POOL` and `EVENT`.
@export var next: StringName = &""

## The Random Lines this pool picks one of. `POOL` only.
@export var text_keys: PackedStringArray = PackedStringArray()

# --- CHOICE ------------------------------------------------------------------

## Exhaustible or committing. `CHOICE` only.
@export var mode: ChoiceMode = ChoiceMode.EXHAUST_ALL

## The table's rows, in script order. `CHOICE` only.
@export var options: Array[DialogueOption] = []

## Where an `EXHAUST_ALL` table goes once every option has been taken, or the Fool
## leaves it - the script's `[All versions pick up here:]`. `CHOICE` only.
##
## A `FIRST_PICK_COMMITS` table normally leaves it empty, because its chosen thread
## simply continues on and never comes back. It is only read on that table if the
## thread does come back round to it: a committed table is never offered twice, so
## the runner walks through it to here, and an empty id ends the conversation.
@export var after_all: StringName = &""

## True for a table the style guide's earnest-option rule is deliberately waived
## for. Requires a `notes` reason: the waiver is a review decision, recorded.
@export var earnest_exempt: bool = false

# --- BRANCH ------------------------------------------------------------------

## `WS_*` ids that must all have fired. `BRANCH` only.
@export var requires_fired: Array[StringName] = []

## `WS_*` ids that must all be unfired. `BRANCH` only.
@export var requires_not_fired: Array[StringName] = []

## `CONFESSED_ANY` / `CONFESSED_NO` / `CONFESSED_YES`. `BRANCH` only.
@export var requires_confessed: int = CONFESSED_ANY

## The earliest act this branch's `then_node` is taken in, as a
## `WorldStateService.Act` value. `MIN_ACT_ANY` for no constraint. `BRANCH` only.
@export var min_act: int = MIN_ACT_ANY

## Where the conversation goes when every condition above holds. `BRANCH` only.
@export var then_node: StringName = &""

## Where it goes when any of them does not. `BRANCH` only.
@export var else_node: StringName = &""

# --- EVENT -------------------------------------------------------------------

## The `QuestEvents` id this node raises. `EVENT` only.
@export var event: StringName = &""

# --- Documentation -----------------------------------------------------------

## Why this node exists, in the quest doc's own words - normally the slugline or
## table it was lifted from, and the reason for an `earnest_exempt` waiver.
## Documentation for a reviewer, **never displayed**: one of the doc-only resource
## properties the localization lint exempts.
@export var notes: String = ""


## Every problem with this node in isolation, one string per problem.
##
## Whether the ids it names resolve - nodes, events, translation keys - needs the
## whole graph or the whole game, so `DialogueGraph.validate()` asks those.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("a dialogue node has an empty id")
	match kind:
		Kind.LINE:
			errors.append_array(_validate_line())
		Kind.CHOICE:
			errors.append_array(_validate_choice())
		Kind.BRANCH:
			errors.append_array(_validate_branch())
		Kind.EVENT:
			errors.append_array(_validate_event())
		Kind.POOL:
			errors.append_array(_validate_pool())
		Kind.END:
			pass
	return errors


## Every node id this node can hand control to, in evaluation order.
func exits() -> Array[StringName]:
	var found: Array[StringName] = []
	match kind:
		Kind.LINE, Kind.POOL, Kind.EVENT:
			if next != &"":
				found.append(next)
		Kind.CHOICE:
			for option: DialogueOption in options:
				if option != null and option.next != &"":
					found.append(option.next)
			if after_all != &"":
				found.append(after_all)
		Kind.BRANCH:
			if then_node != &"":
				found.append(then_node)
			if else_node != &"":
				found.append(else_node)
	return found


## True when this table offers the earnest option the style guide asks for, or is
## exempt with a recorded reason. A table with a single option is not asked: there
## is nothing to choose between (`docs/design/narrative.md` §Dialogue style guide).
func has_earnest_option() -> bool:
	if options.size() < 2:
		return true
	if earnest_exempt:
		return true
	for option: DialogueOption in options:
		if option != null and option.is_earnest:
			return true
	return false


## True when this branch's world-state conditions all hold right now. Conditions are
## WorldState **queries** - `docs/design/technical.md`'s data-model row for
## `DialogueGraph` is explicit that they are never hardcoded booleans.
func conditions_met(world_state: WorldStateService) -> bool:
	if world_state == null:
		return false
	for flag: StringName in requires_fired:
		if not world_state.is_fired(flag):
			return false
	for flag: StringName in requires_not_fired:
		if world_state.is_fired(flag):
			return false
	if requires_confessed == CONFESSED_YES and not world_state.is_confessed():
		return false
	if requires_confessed == CONFESSED_NO and world_state.is_confessed():
		return false
	if min_act > MIN_ACT_ANY and int(world_state.act()) < min_act:
		return false
	return true


func _validate_line() -> PackedStringArray:
	var errors := PackedStringArray()
	if speaker == &"":
		errors.append("the line %s has no speaker" % id)
	if text_key == &"":
		errors.append("the line %s has no text key" % id)
	if next == &"":
		errors.append("the line %s leads nowhere" % id)
	return errors


func _validate_choice() -> PackedStringArray:
	var errors := PackedStringArray()
	if options.is_empty():
		errors.append("the choice %s offers nothing" % id)
	for option: DialogueOption in options:
		if option == null:
			errors.append("the choice %s has an empty option slot" % id)
			continue
		errors.append_array(option.validate())
	if not has_earnest_option():
		errors.append("the choice %s offers no earnest option and claims no exemption" % id)
	if earnest_exempt and notes.is_empty():
		errors.append("the choice %s waives the earnest option without a reason" % id)
	if mode == ChoiceMode.EXHAUST_ALL and after_all == &"":
		errors.append("the exhaustible choice %s has nowhere to pick up afterwards" % id)
	return errors


func _validate_branch() -> PackedStringArray:
	var errors := PackedStringArray()
	if then_node == &"":
		errors.append("the branch %s has no then node" % id)
	if else_node == &"":
		errors.append("the branch %s has no else node" % id)
	for flag: StringName in requires_not_fired:
		if requires_fired.has(flag):
			errors.append("the branch %s needs %s both fired and unfired" % [id, flag])
	if requires_confessed < CONFESSED_ANY or requires_confessed > CONFESSED_YES:
		errors.append("the branch %s asks for confessed state %d" % [id, requires_confessed])
	if min_act < MIN_ACT_ANY:
		errors.append("the branch %s asks for act %d" % [id, min_act])
	return errors


func _validate_event() -> PackedStringArray:
	var errors := PackedStringArray()
	if event == &"":
		errors.append("the event node %s raises nothing" % id)
	if next == &"":
		errors.append("the event node %s leads nowhere" % id)
	return errors


func _validate_pool() -> PackedStringArray:
	var errors := PackedStringArray()
	if speaker == &"":
		errors.append("the pool %s has no speaker" % id)
	if text_keys.is_empty():
		errors.append("the pool %s holds no lines" % id)
	for key: String in text_keys:
		if key.is_empty():
			errors.append("the pool %s holds an empty key" % id)
	if next == &"":
		errors.append("the pool %s leads nowhere" % id)
	return errors
