extends RefCounted
## Lienzo de máscara: '#' forma, 'o' detalle oscuro, '.' vacío. Para armar emblemas por primitivas.

var w: int
var h: int
var cells: Array = []

func _init(width: int, height: int) -> void:
	w = width
	h = height
	for y in range(h):
		var row: Array = []
		for x in range(w): row.append(".")
		cells.append(row)

func set_cell(x: int, y: int, ch: String = "#") -> void:
	if x >= 0 and y >= 0 and x < w and y < h: cells[y][x] = ch

func rect(x: int, y: int, rw: int, rh: int, ch: String = "#") -> void:
	for j in range(rh):
		for i in range(rw): set_cell(x + i, y + j, ch)

func disc(cx: float, cy: float, r: float, ch: String = "#") -> void:
	for y in range(h):
		for x in range(w):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r: set_cell(x, y, ch)

func erase_disc(cx: float, cy: float, r: float) -> void:
	disc(cx, cy, r, ".")

func line(x0: int, y0: int, x1: int, y1: int, ch: String = "#") -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(steps + 1):
		var t := 0.0 if steps == 0 else float(i) / steps
		set_cell(roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), ch)

func rows() -> Array:
	var out: Array = []
	for row in cells: out.append("".join(row))
	return out
