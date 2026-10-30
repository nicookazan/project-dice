extends TextureRect
## Fixed atlas regions are illustrations only; game definitions own every effect.
const SHEET = preload("res://assets/art/shop-items-v1.png")
const ICONS = {"steel": 0, "copper": 1, "emerald": 2, "sapphire": 3, "ruby": 4, "diamond": 5, "fire": 6, "water": 7, "electricity": 8, "earth": 9, "wind": 10, "pack": 11, "portrait": 12, "sticker": 13, "number": 14, "face": 15}
var icon_id := "face"

func _ready() -> void:
	var index: int = ICONS.get(icon_id, 15)
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var cell := Vector2(SHEET.get_width() / 4.0, SHEET.get_height() / 4.0)
	atlas.region = Rect2(Vector2(index % 4, int(index / 4.0)) * cell, cell)
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
