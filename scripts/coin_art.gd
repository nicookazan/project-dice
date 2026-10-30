extends TextureRect
const SHEET = preload("res://assets/art/coins-v2.png")
const IDS = ["full", "straight", "generala", "poker", "even", "odd", "boost", "roll"]
var coin_id := "full"

func _ready() -> void:
	var index: int = IDS.find(coin_id)
	if index < 0: return
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	var cell := Vector2(SHEET.get_width() / 4.0, SHEET.get_height() / 2.0)
	atlas.region = Rect2(Vector2(index % 4, int(index / 4.0)) * cell, cell)
	texture = atlas
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
