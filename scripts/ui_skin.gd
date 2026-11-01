extends RefCounted
## Pixel-v3 interface frames. Textures are 9-slice sheets already drawn at 2x, so every logical pixel is a
## 2x2 block; the owning control must use TEXTURE_FILTER_NEAREST. Generator: tools/art/make_interfaz.py.
const BUTTONS := {
	"normal": preload("res://assets/art/pixel-v3/ui/boton-normal.png"),
	"hover": preload("res://assets/art/pixel-v3/ui/boton-hover.png"),
	"pressed": preload("res://assets/art/pixel-v3/ui/boton-pressed.png"),
	"disabled": preload("res://assets/art/pixel-v3/ui/boton-disabled.png"),
	"accent": preload("res://assets/art/pixel-v3/ui/boton-accent.png"),
	"accent_hover": preload("res://assets/art/pixel-v3/ui/boton-accent_hover.png")}
const PANEL := preload("res://assets/art/pixel-v3/ui/panel.png")
const TITLE := preload("res://assets/art/pixel-v3/ui/titulo.png")

static func nine(texture: Texture2D, margin: int, content := Vector4(12, 8, 12, 8)) -> StyleBoxTexture:
	var skin := StyleBoxTexture.new()
	skin.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: skin.set_texture_margin(side, margin)
	skin.content_margin_left = content.x
	skin.content_margin_top = content.y
	skin.content_margin_right = content.z
	skin.content_margin_bottom = content.w
	return skin

static func button(state: String, accent := false) -> StyleBoxTexture:
	var key := state
	if accent and state in ["normal", "hover"]: key = "accent" if state == "normal" else "accent_hover"
	return nine(BUTTONS[key], 16)

static func panel(content := Vector4(24, 24, 24, 24)) -> StyleBoxTexture:
	return nine(PANEL, 24, content)

static func title() -> StyleBoxTexture:
	var skin := StyleBoxTexture.new()
	skin.texture = TITLE
	skin.set_texture_margin(SIDE_LEFT, 190)
	skin.set_texture_margin(SIDE_RIGHT, 190)
	skin.set_texture_margin(SIDE_TOP, 30)
	skin.set_texture_margin(SIDE_BOTTOM, 30)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: skin.set_content_margin(side, 10 if side in [SIDE_LEFT, SIDE_RIGHT] else 3)
	return skin
