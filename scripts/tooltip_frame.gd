extends StyleBox
## Tile-free velvet fill and native rectangular trim; no case-edge pixels.
const CLOTH = preload("res://assets/art/shop-salesman-v1.png")

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var unit := Vector2(CLOTH.get_size()) / Vector2(1440, 900)
	# Sample only the unobstructed interior, away from all perspective edges.
	CLOTH.draw_rect_region(canvas_item, rect, Rect2(Vector2(620, 295) * unit, Vector2(240, 100) * unit))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color.TRANSPARENT
	frame.border_color = Color("a86826")
	frame.set_border_width_all(4)
	frame.anti_aliasing = false
	frame.draw(canvas_item, rect)
	frame.border_color = Color("f5cc77")
	frame.set_border_width_all(1)
	frame.draw(canvas_item, rect.grow(-1))
