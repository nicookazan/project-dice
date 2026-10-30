extends Panel
signal coin_dropped(data: Dictionary)
var accepts: Callable

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return accepts.is_valid() and accepts.call(data)

func _drop_data(_at: Vector2, data: Variant) -> void:
	if _can_drop_data(_at, data): coin_dropped.emit(data)
