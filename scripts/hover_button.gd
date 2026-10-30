extends Button

func _get_tooltip(_at_position: Vector2) -> String:
	return "" # The shared fixed description panel reads tooltip_text.

func _make_custom_tooltip(text: String) -> Object:
	if text.strip_edges().is_empty(): return null
	return preload("res://scripts/item_tooltip.gd").content(text)
