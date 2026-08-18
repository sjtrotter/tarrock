class_name UiFrames
extends RefCounted

## The manuscript framing every Tarrock control sits inside, built from the UI
## gauntlet's own vector art.
##
## `docs/design/art-audio.md` Visual pillar 3: "all UI chrome (menus, dialogue boxes,
## the Almanack, card art borders) borrows gilded, hand-lettered manuscript framing
## rather than modern flat-UI chrome". The framing is therefore ART, not a StyleBox:
## the SVGs under `res://art/ui/` are copies of round U1's concepts
## (`docs/gauntlet-ui/concepts/`) with the placeholder copy and the presentation
## background stripped, and they are drawn as `NinePatchRect`s so the frame grows with
## the text it holds - which is exactly what `art-audio.md` §Accessibility notes asks
## of large text sizes.
##
## Patch margins are the width of each frame's own border art, measured off the SVG;
## the corner ornaments sit inside the margin so they are never stretched.

const DIALOGUE_TEXTURE := "res://art/ui/dialogue_frame.svg"
const CHIP_TEXTURE := "res://art/ui/prompt_chip.svg"
const PANEL_TEXTURE := "res://art/ui/panel.svg"
const NAME_PLATE_TEXTURE := "res://art/ui/name_plate.svg"
const CARD_FACE_TEXTURE := "res://art/ui/card_face.svg"
const CARD_BACK_TEXTURE := "res://art/ui/card_back.svg"
const PETAL_TEXTURE := "res://art/ui/petal.svg"
const CARET_TEXTURE := "res://art/ui/caret.svg"

## The four suit marks, indexed by `Suit.Id`. `art-audio.md` §Accessibility notes:
## "no suit-identifying UI element may rely on color alone - shape and card-rank pip
## count are always the primary read", so these are SHAPES, drawn in ink only.
const SUIT_TEXTURES: Array[String] = [
	"res://art/ui/suit_cups.svg",
	"res://art/ui/suit_swords.svg",
	"res://art/ui/suit_wands.svg",
	"res://art/ui/suit_coins.svg",
]

## The vine corners of the dialogue frame reach 130 px in and 100 px down.
const DIALOGUE_MARGINS := Vector4(180.0, 100.0, 180.0, 100.0)

## The chip's rails.
const CHIP_MARGINS := Vector4(60.0, 40.0, 60.0, 40.0)

## The generic panel's triple rail.
const PANEL_MARGINS := Vector4(52.0, 40.0, 52.0, 40.0)

## The name plate's angled ends.
const NAME_PLATE_MARGINS := Vector4(40.0, 0.0, 40.0, 0.0)

## Parchment, ink and gold - the U1 palette, and the only colours the shell mixes.
const INK := Color(0.129, 0.102, 0.071, 1.0)
const PARCHMENT := Color(0.917, 0.851, 0.678, 1.0)
const GOLD := Color(0.722, 0.541, 0.173, 1.0)
const PALE_GOLD := Color(0.941, 0.874, 0.667, 1.0)
const GROUND := Color(0.114, 0.094, 0.067, 1.0)

## How faint a spent White Rose petal is drawn. Not gone - spent
## (`docs/design/progression.md` §The White Rose: petals regrow).
const SPENT_ALPHA := 0.25


## A framed background, sized by whatever it is put behind. `margins` is
## (left, top, right, bottom).
static func nine_patch(texture_path: String, margins: Vector4) -> NinePatchRect:
	var frame := NinePatchRect.new()
	frame.texture = load(texture_path) as Texture2D
	frame.patch_margin_left = int(margins.x)
	frame.patch_margin_top = int(margins.y)
	frame.patch_margin_right = int(margins.z)
	frame.patch_margin_bottom = int(margins.w)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return frame


## The broad parchment panel a conversation is written on.
static func dialogue_frame() -> NinePatchRect:
	return nine_patch(DIALOGUE_TEXTURE, DIALOGUE_MARGINS)


## The small marginal slip a prompt is written on.
static func chip_frame() -> NinePatchRect:
	return nine_patch(CHIP_TEXTURE, CHIP_MARGINS)


## The generic framed panel every menu sits on.
static func panel_frame() -> NinePatchRect:
	return nine_patch(PANEL_TEXTURE, PANEL_MARGINS)


## The gilded cartouche a speaker's name is lettered on.
static func name_plate_frame() -> NinePatchRect:
	return nine_patch(NAME_PLATE_TEXTURE, NAME_PLATE_MARGINS)


## The same framing as a `StyleBoxTexture`, for a container that must GROW with what
## it holds.
##
## A `NinePatchRect` is a background: it is as big as it is put, which is right behind a
## full-screen page whose own container carries the margins. A plate that has to fit a
## name, at any text size, is the other case - so it is a `PanelContainer` wearing this
## stylebox, and `art-audio.md` §Accessibility notes' "degrade gracefully at large sizes
## rather than break its frame art" is then a property of the layout rather than a thing
## anybody has to remember.
static func style_box(texture_path: String, margins: Vector4) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(texture_path) as Texture2D
	box.texture_margin_left = margins.x
	box.texture_margin_top = margins.y
	box.texture_margin_right = margins.z
	box.texture_margin_bottom = margins.w
	box.content_margin_left = margins.x
	box.content_margin_top = maxf(margins.y, 6.0)
	box.content_margin_right = margins.z
	box.content_margin_bottom = maxf(margins.w, 6.0)
	return box


## A container that draws one of these frames behind itself and grows with its child.
static func framed(texture_path: String, margins: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", style_box(texture_path, margins))
	return panel


## The gilded cartouche a speaker's name is lettered on, as a container that fits the
## name it is given.
static func name_plate() -> PanelContainer:
	return framed(NAME_PLATE_TEXTURE, NAME_PLATE_MARGINS)


## The suit mark for a suit, or `null` for no suit.
static func suit_texture(suit_id: int) -> Texture2D:
	if suit_id < 0 or suit_id >= SUIT_TEXTURES.size():
		return null
	return load(SUIT_TEXTURES[suit_id]) as Texture2D
