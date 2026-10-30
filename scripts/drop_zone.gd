extends Panel
signal die_dropped(index: int, destination: String)
var destination := "reserve"

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("die") is int and data.die >= 0 and data.die < 5

func _drop_data(_at: Vector2, data: Variant) -> void:
	if _can_drop_data(_at, data): die_dropped.emit(data.die, destination)
