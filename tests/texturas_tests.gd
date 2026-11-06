extends RefCounted
## TX1: las marcas de elemento son grandes pero nunca tapan un punto del dado (ni el seis).
const Art = preload("res://scripts/dice_art.gd")
const Die = preload("res://scripts/die.gd")
const ELEMENTS := ["fire", "water", "electricity", "earth", "wind"]

static func run(scene, check: Callable) -> void:
	var atlas := Image.load_from_file("res://assets/art/pixel-v3/elementos-v3.png")
	check.call(atlas.get_width() == Die.ELEMENT_CELL * ELEMENTS.size() and atlas.get_height() == Die.ELEMENT_CELL, "TX1: la hoja de elementos tiene 5 celdas de 96x96")
	for element in ELEMENTS:
		var cell: int = Die.ELEMENT_CELLS.get(element, -1)
		check.call(cell == ELEMENTS.find(element), "TX1: %s apunta a su celda de la hoja" % element)
		var painted := 0
		var covered := 0
		for value in range(1, 7):
			for box in Art.pip_bounds("", value):
				var rect := Rect2i(Vector2i(box.position) + Vector2i(Die.ELEMENT_MARGIN, Die.ELEMENT_MARGIN) + Vector2i(cell * Die.ELEMENT_CELL, 0), Vector2i(box.size))
				for y in range(rect.position.y, rect.end.y):
					for x in range(rect.position.x, rect.end.x):
						if x >= 0 and y >= 0 and x < atlas.get_width() and y < atlas.get_height() and atlas.get_pixel(x, y).a > 0.0:
							covered += 1
		for y in atlas.get_height():
			for x in range(cell * Die.ELEMENT_CELL, (cell + 1) * Die.ELEMENT_CELL):
				if atlas.get_pixel(x, y).a > 0.0: painted += 1
		check.call(painted > 350, "TX1: %s tiene marcas grandes (%d px, antes unos 100)" % [element, painted])
		check.call(covered == 0, "TX1: %s no tapa ningún punto del 1 al 6 (%d px encima)" % [element, covered])
	var die := Die.new()
	die.element = "fire"
	die.value = 6
	die.size = Vector2(62, 62)
	die.queue_redraw()
	check.call(Die.ELEMENT_CELLS.size() == ELEMENTS.size(), "TX1: el dado conoce los 5 elementos")
	die.free()
