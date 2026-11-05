extends Panel
signal die_dropped(index: int, destination: String)
var destination := "reserve"
## Si no está vacío, solo acepta soltados dentro de este polígono (coordenadas locales de la zona).
var shape := PackedVector2Array()

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("die") is int and data.die >= 0 and data.die < 5): return false
	return shape.is_empty() or Geometry2D.is_point_in_polygon(at, shape)

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at, data): die_dropped.emit(data.die, destination)

## Hace que otro control (que tapa parte de esta zona con su propio clic) mande los soltados acá.
## `at` llega relativo al control que tapa. Las funciones quedan en el meta "drop_forward" para las pruebas.
func accept_through(source: Control) -> void:
	var to_zone := func(at: Vector2) -> Vector2: return at + source.global_position - global_position
	var can_drop := func(at: Vector2, data: Variant) -> bool: return Rect2(Vector2.ZERO, size).has_point(to_zone.call(at)) and _can_drop_data(to_zone.call(at), data)
	var drop := func(at: Vector2, data: Variant) -> void: _drop_data(to_zone.call(at), data)
	source.set_drag_forwarding(Callable(), can_drop, drop)
	source.set_meta("drop_forward", {"can": can_drop, "drop": drop})
