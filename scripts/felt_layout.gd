extends RefCounted
## Borde dorado de la tela izquierda de la mesa, medido sobre la captura (coordenadas del juego, 1440×900).
## Arriba y=316, abajo y=652, derecha x=694. El costado izquierdo es inclinado: x = 392 - 0,1692 × (y - 340).
## Solo geometría: la usan la zona de soltado, "Reservar" y (en los pasos siguientes) la ficha del dado y la lista de jugadas.

const TOP := 316.0
const BOTTOM := 652.0
const RIGHT := 694.0
const LEFT_AT_340 := 392.0
const LEFT_SLOPE := 0.1692

static func left(y: float) -> float:
	return LEFT_AT_340 - LEFT_SLOPE * (y - 340.0)

## Polígono de la tela, `inset` px hacia adentro del borde dorado.
static func polygon(inset := 0.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left(TOP) + inset, TOP + inset), Vector2(RIGHT - inset, TOP + inset),
		Vector2(RIGHT - inset, BOTTOM - inset), Vector2(left(BOTTOM) + inset, BOTTOM - inset)])

## Rectángulo que contiene toda la tela (lo que ocupa el Control de la zona).
static func bounds() -> Rect2:
	var x := left(BOTTOM)
	return Rect2(x, TOP, RIGHT - x, BOTTOM - TOP)

static func contains(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon())
