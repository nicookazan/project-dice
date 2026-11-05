extends Panel
signal coin_dropped(data: Dictionary)
var accepts: Callable
## Si no está vacío, solo se acepta soltar dentro de este polígono (coordenadas locales).
var shape := PackedVector2Array()

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not shape.is_empty() and not Geometry2D.is_point_in_polygon(at, shape): return false
	return accepts.is_valid() and accepts.call(data)

func _drop_data(_at: Vector2, data: Variant) -> void:
	if _can_drop_data(_at, data): coin_dropped.emit(data)
