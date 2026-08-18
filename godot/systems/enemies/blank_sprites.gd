class_name BlankSprites
extends RefCounted

## The Blank family's art, as a `CharacterAnimator` table.
##
## `docs/design/combat.md` §Enemies: "One base art and animation family carries every
## suit and rank", so there is one of these for the whole roster and a suit is told
## apart by a tint (`EnemyRules.suit_tints`) until its own sheet exists. That tint is
## a stopgap and is listed as an art request in `systems/enemies/README.md`.
##
## **Every offset here was measured, not eyeballed**, by
## `godot/tools/measure_sprite_pivots.py --family blank_sword_two`, using
## `CharacterAnimator`'s convention: the anchor is (alpha-weighted centroid x, lowest
## opaque pixel y) and the offset is (cell centre - anchor). The centroid is the
## steadiest horizontal landmark across a cycle and the lowest opaque pixel is the
## planted foot, so the Blank stays on its ground line instead of bobbing. Re-run the
## tool if the art is redrawn; do not adjust a number by eye.
##
## The action rows are drawn **south-east facing only** - the same gap
## `scripts/player.gd` has for the Fool - so seven of the eight facings fall back to
## their static frame while walking, which is what `CharacterAnimator`'s `static`
## action is for.

## The eight facings, in the pack's own order.
const DIRECTIONS: Array[String] = [
	"east",
	"southeast",
	"south",
	"southwest",
	"west",
	"northwest",
	"north",
	"northeast",
]

## The one facing the action rows are drawn for.
const AUTHORED_ACTION_DIRECTION := "southeast"

const DIRECTION_TEXTURES := {
	"east": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/east.png"),
	"southeast": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/southeast.png"),
	"south": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/south.png"),
	"southwest": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/southwest.png"),
	"west": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/west.png"),
	"northwest": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/northwest.png"),
	"north": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/north.png"),
	"northeast": preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/directions/northeast.png"),
}

## Measured from the 384x512 direction sheet's alpha. Do not eyeball these.
const DIRECTION_OFFSETS := {
	"east": Vector2(32.2, -227.0),
	"southeast": Vector2(65.8, -228.0),
	"south": Vector2(-4.2, -227.0),
	"southwest": Vector2(10.8, -230.0),
	"west": Vector2(31.1, -228.0),
	"northwest": Vector2(54.5, -226.0),
	"north": Vector2(-19.7, -226.0),
	"northeast": Vector2(18.3, -226.0),
}

## Solved so a Blank stands the same height on screen as the Fool: the Fool's
## direction sheet is 435 px of opaque bbox at his authored 0.28, which is 121.8 px;
## the Blank's eight facings average 456.5 px of bbox, so 121.8 / 456.5 = 0.2668.
const DIRECTION_SCALE := 0.2668

## The 320 px action cells need their own scale for the same reason
## `scripts/player.gd`'s walk cycle does. Solved against the WALK row's mean bbox
## (274.5 px) and used for every action row, so the defeat row's shorter frames read
## as a figure going down rather than as a figure being resized.
const ACTION_SCALE := 0.4437

const WALK_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/walk-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/walk-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/walk-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/walk-3.png"),
]
const WALK_OFFSETS := [
	Vector2(-16.1, -150.0),
	Vector2(-1.5, -147.0),
	Vector2(25.8, -145.0),
	Vector2(48.5, -151.0),
]

const ATTACK_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/attack-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/attack-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/attack-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/attack-3.png"),
]
const ATTACK_OFFSETS := [
	Vector2(-10.6, -130.0),
	Vector2(12.4, -131.0),
	Vector2(38.9, -130.0),
	Vector2(49.8, -131.0),
]

const HIT_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/hit-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/hit-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/hit-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/hit-3.png"),
]
const HIT_OFFSETS := [
	Vector2(0.9, -111.0),
	Vector2(21.7, -102.0),
	Vector2(53.6, -111.0),
	Vector2(51.1, -159.0),
]

const DEFEAT_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/defeat-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/defeat-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/defeat-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/blank_sword_two/actions/defeat-3.png"),
]
const DEFEAT_OFFSETS := [
	Vector2(0.1, -95.0),
	Vector2(47.7, -99.0),
	Vector2(35.9, -106.0),
	Vector2(37.8, -113.0),
]

## Playback rates, from `art/game-ready-sprites-v1/manifest.json` ->
## `characters.blank_sword_two.rows`. The manifest is authoritative for the pack, so
## these are transcribed rather than chosen.
const WALK_FPS := 7.0
const ATTACK_FPS := 9.0
const HIT_FPS := 8.0
const DEFEAT_FPS := 7.0

## The action names a `Blank` asks for. Named here so no node types one.
const ACTION_STATIC := "static"
const ACTION_WALK := "walk"
const ACTION_ATTACK := "attack"
const ACTION_HIT := "hit"
const ACTION_DEFEAT := "defeat"


## (direction, action) -> clip, for `CharacterAnimator.configure()`. Built fresh per
## caller rather than shared, because a clip Dictionary is handed to the animator
## which reads `frames`, `offsets` and `scale` out of it; the textures inside are the
## same preloaded resources either way, so nothing is copied that matters.
##
## Add a direction's cycle here as its art lands.
static func build_animation_table() -> Dictionary:
	var static_action: Dictionary = {}
	for direction: String in DIRECTIONS:
		static_action[direction] = CharacterAnimator.make_clip(
			[DIRECTION_TEXTURES[direction]],
			[DIRECTION_OFFSETS[direction]],
			DIRECTION_SCALE,
			1.0,
			false
		)
	return {
		ACTION_STATIC: static_action,
		ACTION_WALK: {
			AUTHORED_ACTION_DIRECTION: CharacterAnimator.make_clip(
				WALK_FRAMES, WALK_OFFSETS, ACTION_SCALE, WALK_FPS, true
			),
		},
		ACTION_ATTACK: {
			AUTHORED_ACTION_DIRECTION: CharacterAnimator.make_clip(
				ATTACK_FRAMES, ATTACK_OFFSETS, ACTION_SCALE, ATTACK_FPS, false
			),
		},
		ACTION_HIT: {
			AUTHORED_ACTION_DIRECTION: CharacterAnimator.make_clip(
				HIT_FRAMES, HIT_OFFSETS, ACTION_SCALE, HIT_FPS, false
			),
		},
		ACTION_DEFEAT: {
			AUTHORED_ACTION_DIRECTION: CharacterAnimator.make_clip(
				DEFEAT_FRAMES, DEFEAT_OFFSETS, ACTION_SCALE, DEFEAT_FPS, false
			),
		},
	}


## Which of the eight facings a direction vector reads as. The same eight-way split
## `scripts/player.gd` uses, kept here so the Blank and the Fool round a heading the
## same way.
static func facing_name(direction: Vector2) -> String:
	if direction.is_zero_approx():
		return DIRECTIONS[0]
	var index := wrapi(roundi(direction.angle() / (PI / 4.0)), 0, DIRECTIONS.size())
	return DIRECTIONS[index]
