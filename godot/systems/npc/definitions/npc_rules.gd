class_name NpcRules
extends TarrockDefinition

## The one tuning table the whole NPC system runs on.
##
## HAND-AUTHORED at `res://data/npc/npc_rules.tres`. `docs/design/npc-system.md` states
## every number here as an open question, on purpose, and says so twice: its §Open
## questions list the rumour delays as "a pacing number to tune once a real playthrough
## timeline exists, not a docs-phase decision", and §Dialogue volume calls its whole
## table "**tuning targets**, not locked numbers - set for real once a region is
## greyboxed and its NPC density is known". So every figure in this file is a
## PLACEHOLDER a balance pass owns, and they are gathered in one resource precisely so
## the pass has one file to open.
##
## The `schedule_variants` are not tuning: they are §Daily life's own bullet, read into
## rows. See `ScheduleVariant` for why they are hand-authored rather than generated.

## How many of a pool's most recent picks are held back from the next one.
##
## §Bark layers: "**Repeats decay.** Each pool tracks recently-spent lines per NPC (or
## per ambient context, for Minors sharing a pool) and excludes them from the next few
## picks. An NPC should not say the same 'aware' line twice in a row". "The next few"
## is the whole specification, so this is the number that word becomes. TBD.
@export var recent_pick_memory: int = 3

## In-game hours before the regions bordering a completed main quest's home region hear
## about it.
##
## §"The world talks about you": "**Adjacent regions first** - the regions bordering the
## quest's home region gain rumour barks after a short in-game-time delay (hours, not
## seconds - long enough that a player who fast-travels immediately still beats the
## news)." Hours-not-seconds is the only constraint the doc gives, and it is a
## constraint on the SHAPE; the figure is TBD.
@export var rumor_adjacent_delay_hours: float = 6.0

## In-game hours before every region has heard.
##
## §"The world talks about you": "**World-wide after a longer delay** - every region's
## generic rumour layer picks up a version of the same event once enough in-game time
## has passed, phrased through that region's own suit-culture voice". Longer than the
## adjacent delay is the whole rule; the figure is TBD.
@export var rumor_world_delay_hours: float = 48.0

## How many seconds of `GameClock` time make one in-game hour.
##
## The conversion the two delays above are measured in, and the one number nothing in
## `docs/` speaks to at all: no doc gives the world a day length. It is here rather
## than in `GameClock` because the clock is honestly just seconds (see its class doc)
## and "what is an hour" is a content decision, not a timing one. TBD, and load-bearing
## for both the rumour delays and the time bands.
@export var seconds_per_in_game_hour: float = 60.0

## The hour each time band begins, indexed by `TimeBand.Id` and ignoring index 0
## (`NONE` begins nowhere). A band runs until the next one starts, and `NIGHT` wraps.
##
## Four bands and these boundaries are this system's reading: `npc-system.md` says
## "day/night" and nothing finer, and §Daily life asks only for "a simple time-of-day
## loop". TBD in every figure.
@export var time_band_start_hours: PackedFloat32Array = PackedFloat32Array()

## Hours in an in-game day. 24 because the world is a storybook Britain and not because
## a doc says so.
@export var hours_per_day: float = 24.0

## The kinds of day an unbound region gains, and the unbinding that brings each.
## §Daily life's third bullet, read into rows - see `ScheduleVariant`.
@export var schedule_variants: Array[ScheduleVariant] = []

## The pool-size targets of §Dialogue volume, indexed by layer number (index 0 is
## unused padding). INFORMATIONAL ONLY - nothing reads them and no check enforces them.
##
## They are here because the doc's table is a real authoring instruction and a writer
## opening the tuning file should find it, and they are inert because §Dialogue volume
## is explicit that these are "tuning targets, not locked numbers": a validator that
## failed a region for having five act-state lines instead of six would be enforcing a
## number the doc refuses to lock.
@export var pool_size_targets: PackedInt32Array = PackedInt32Array()

## The doc sections these numbers answer to.
@export var doc_ref: String = ""

## Which figures are placeholders and what would settle them. Doc text; never displayed.
@export var notes: String = ""


## Seconds of in-game time in this many in-game hours.
func hours_to_seconds(hours: float) -> float:
	return hours * seconds_per_in_game_hour


## The delay before a region this far from the news hears it, in seconds.
##
## `adjacent` is the graph's own answer, not a guess: see `RumorService`.
func rumor_delay_seconds(adjacent: bool) -> float:
	return hours_to_seconds(rumor_adjacent_delay_hours if adjacent else rumor_world_delay_hours)


## The band of the day this many in-game seconds land in.
##
## `TimeBand.Id.NONE` when the bands are not configured - a world with no hours in it
## has no time of day, which is the same answer it gives before `WS_SUN_UNBOUND`.
func band_at_seconds(seconds: float) -> TimeBand.Id:
	if time_band_start_hours.size() != TimeBand.NAME_KEYS.size() or hours_per_day <= 0.0:
		return TimeBand.Id.NONE
	if seconds_per_in_game_hour <= 0.0:
		return TimeBand.Id.NONE
	var hour := fposmod(seconds / seconds_per_in_game_hour, hours_per_day)
	var best := TimeBand.Id.NIGHT
	var best_start := -1.0
	for band: TimeBand.Id in TimeBand.ALL:
		var start := time_band_start_hours[band]
		if hour >= start and start > best_start:
			best = band
			best_start = start
	return best


## The variant of this kind, or `null` when no row names it.
func variant_of(kind: ScheduleVariant.Kind) -> ScheduleVariant:
	for variant: ScheduleVariant in schedule_variants:
		if variant != null and variant.kind == kind:
			return variant
	return null


## Every problem with the table, one string per problem.
func validate() -> PackedStringArray:
	var errors := super()
	if recent_pick_memory < 0:
		errors.append("%s holds back %d picks" % [id, recent_pick_memory])
	if seconds_per_in_game_hour <= 0.0:
		errors.append("%s makes an in-game hour %f seconds long" % [id, seconds_per_in_game_hour])
	if hours_per_day <= 0.0:
		errors.append("%s gives the day %f hours" % [id, hours_per_day])
	if rumor_adjacent_delay_hours < 0.0 or rumor_world_delay_hours < 0.0:
		errors.append("%s makes news travel backwards in time" % id)
	if rumor_world_delay_hours < rumor_adjacent_delay_hours:
		errors.append("%s has the far side of the Spread hearing before the next region does" % id)
	if time_band_start_hours.size() != TimeBand.NAME_KEYS.size():
		errors.append("%s gives %d bands of the day start hours; there are %d" % [
			id, time_band_start_hours.size(), TimeBand.NAME_KEYS.size()
		])
	else:
		var previous := -1.0
		for band: TimeBand.Id in TimeBand.ALL:
			var start := time_band_start_hours[band]
			if start < 0.0 or start >= hours_per_day:
				errors.append("%s starts %s at hour %f" % [id, TimeBand.name_key(band), start])
			if start <= previous:
				errors.append("%s starts %s before the band before it" % [
					id, TimeBand.name_key(band)
				])
			previous = start
	var kinds: Dictionary = {}
	for index: int in schedule_variants.size():
		var variant := schedule_variants[index]
		if variant == null:
			errors.append("%s schedule variant %d is empty" % [id, index])
			continue
		if kinds.has(variant.kind):
			errors.append("%s names the %s day twice" % [
				id, ScheduleVariant.name_key(variant.kind)
			])
		kinds[variant.kind] = true
	return errors


## Every problem only the world-state matrix can find: a kind of day waiting on an
## unbinding nobody defines.
func validate_against(world_states: WorldStateCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	for variant: ScheduleVariant in schedule_variants:
		if variant != null:
			errors.append_array(variant.validate(world_states))
	return errors
