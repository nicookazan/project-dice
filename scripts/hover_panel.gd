extends Panel
signal activated

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		activated.emit()
		accept_event()

func _get_tooltip(_at_position: Vector2) -> String:
	return ""

func _make_custom_tooltip(text: String) -> Object:
	if text.strip_edges().is_empty(): return null
	return preload("res://scripts/item_tooltip.gd").content(text)
