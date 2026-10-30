extends Control
## Stepped circular arrow, matching the shop's pixel edges at small sizes.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := get_parent() as Button
	button.mouse_entered.connect(queue_redraw)
	button.mouse_exited.connect(queue_redraw)
	button.focus_entered.connect(queue_redraw)
	button.focus_exited.connect(queue_redraw)

func _draw() -> void:
	var button := get_parent() as Button
	var color := Color("85867b") if button.disabled else Color("fff0c7") if button.is_hovered() or button.has_focus() else Color("edbb67")
	draw_polyline(PackedVector2Array([Vector2(5, 18), Vector2(3, 14), Vector2(3, 9), Vector2(7, 4), Vector2(12, 2), Vector2(18, 2), Vector2(23, 6), Vector2(25, 11), Vector2(25, 15), Vector2(22, 20), Vector2(18, 23), Vector2(10, 23)]), color, 3, false)
	draw_colored_polygon(PackedVector2Array([Vector2(7, 23), Vector2(14, 17), Vector2(14, 28)]), color)
