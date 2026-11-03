extends Control
## Offer icons that are neither dice nor coins (pixel-v3). Illustrations only; game definitions own every effect.
## Drawn at an integer scale so every logical pixel keeps an even block (2×2 in the shop, 4×4 in the pack reveal).
const SHEET = preload("res://assets/art/pixel-v3/tienda-iconos-v3.png")
const CELL := 44
## "number_1".."number_6": the medallion with its pixel-art gold digit baked in and centered.
const ICONS = {"number": 0, "pack": 1, "number_1": 2, "number_2": 3, "number_3": 4, "number_4": 5, "number_5": 6, "number_6": 7}
var icon_id := "number"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var index: int = ICONS.get(icon_id, 0)
	var k := maxi(1, floori(minf(size.x, size.y) / CELL))
	var side := Vector2(CELL, CELL) * k
	draw_texture_rect_region(SHEET, Rect2(((size - side) / 2).floor(), side), Rect2(index * CELL, 0, CELL, CELL))
