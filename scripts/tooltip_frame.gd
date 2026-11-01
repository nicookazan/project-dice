extends StyleBox
## Velvet fill from the case (pixel-v3, repeated 1:1 so each logical pixel stays 2×2) and native rectangular trim.
const VELVET = preload("res://assets/art/pixel-v3/terciopelo-v3.png")

func _draw(canvas_item: RID, rect: Rect2) -> void:
	var tile := Vector2(VELVET.get_size())
	var y := 0.0
	while y < rect.size.y:
		var h := minf(tile.y, rect.size.y - y)
		var x := 0.0
		while x < rect.size.x:
			var w := minf(tile.x, rect.size.x - x)
			VELVET.draw_rect_region(canvas_item, Rect2(rect.position + Vector2(x, y), Vector2(w, h)), Rect2(0, 0, w, h))
			x += tile.x
		y += tile.y
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color.TRANSPARENT
	frame.border_color = Color("a86826")
	frame.set_border_width_all(4)
	frame.anti_aliasing = false
	frame.draw(canvas_item, rect)
	frame.border_color = Color("f5cc77")
	frame.set_border_width_all(1)
	frame.draw(canvas_item, rect.grow(-1))
