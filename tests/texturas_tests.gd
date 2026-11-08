extends RefCounted
## TX10 (D17): los elementos son un emblema animado en la cara de arriba del dado. Nunca tapan un punto (ni el seis),
## respetan «Reducir movimiento», la velocidad y «Reducir destellos», y no tocan el azar de la partida.
const Art = preload("res://scripts/dice_art.gd")
const Die = preload("res://scripts/die.gd")
const ELEMENTS := ["fire", "water", "electricity", "earth", "wind"]

static func _opaque(image: Image, rect: Rect2i) -> int:
	var count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y).a > 0.0: count += 1
	return count

static func run(scene, check: Callable) -> void:
	var atlas := Image.load_from_file("res://assets/art/pixel-v3/elementos-v4.png")
	var cell: Vector2i = Die.ELEMENT_CELL
	check.call(atlas.get_width() == cell.x * Die.ELEMENT_FRAMES and atlas.get_height() == cell.y * ELEMENTS.size() and Die.ELEMENT_FRAMES == 12, "TX10: la hoja tiene 5 filas de 12 cuadros de 62×16")
	check.call(Die.ELEMENT_CELLS.size() == ELEMENTS.size(), "TX10: el dado conoce los 5 elementos")
	for element in ELEMENTS:
		var row: int = Die.ELEMENT_CELLS.get(element, -1)
		check.call(row == ELEMENTS.find(element), "TX10: %s apunta a su fila de la hoja" % element)
		var counts: Array = []
		var covered := 0
		for frame in range(Die.ELEMENT_FRAMES):
			var rect := Rect2i(frame * cell.x, row * cell.y, cell.x, cell.y)
			counts.append(_opaque(atlas, rect))
			for value in range(1, 7):
				for box in Art.pip_bounds("", value):
					var pip := Rect2i(Vector2i(box.position), Vector2i(box.size)).intersection(Rect2i(0, 0, cell.x, cell.y))
					for y in range(pip.position.y, pip.end.y):
						for x in range(pip.position.x, pip.end.x):
							if atlas.get_pixel(rect.position.x + x, rect.position.y + y).a > 0.0: covered += 1
		check.call(counts.all(func(n): return n > 25), "TX10: %s tiene dibujo en los 12 cuadros (mínimo %d px)" % [element, counts.min()])
		check.call(covered == 0, "TX10: %s no tapa ningún punto del 1 al 6 (%d px encima)" % [element, covered])
		var distinct: Dictionary = {}
		for frame in range(Die.ELEMENT_FRAMES):
			distinct[atlas.get_region(Rect2i(frame * cell.x, row * cell.y, cell.x, cell.y)).get_data().hex_encode()] = true
		check.call(distinct.size() >= 6, "TX10: %s se anima (%d cuadros distintos de 12)" % [element, distinct.size()])

	# Qué cuadro se ve en cada momento.
	check.call(Die.element_frame_at(5000, 120, 3, false) == 0, "TX10: sin animación queda el primer cuadro")
	check.call(Die.element_frame_at(0, 120, 0, true) == 0 and Die.element_frame_at(120, 120, 0, true) == 1 and Die.element_frame_at(120 * 12, 120, 0, true) == 0, "TX10: un cuadro cada 120 ms y la vuelta se cierra a los 12")
	check.call(Die.element_frame_at(0, 120, 5, true) == 5 and Die.element_frame_at(120 * 9, 120, 5, true) == 2, "TX10: la fase corre el cuadro sin salirse de la hoja")
	check.call(Die.element_frame_at(750, 75, 0, true) == 10 and Die.element_frame_at(750, 120, 0, true) == 6, "TX10: la velocidad rápida acorta el cuadro")
	check.call(Die.element_frame_at(120 * 11, 120, 0, true, "electricity", false) == 11 and Die.element_frame_at(120 * 11, 120, 0, true, "electricity", true) == 9, "TX10: «Reducir destellos» salta los pasos de destello del rayo")
	check.call(Die.element_frame_at(120 * 11, 120, 0, true, "fire", true) == 11, "TX10: «Reducir destellos» no toca a los otros elementos")
	var calm := atlas.get_region(Rect2i(0, 2 * cell.y, cell.x, cell.y))
	var flash := atlas.get_region(Rect2i(10 * cell.x, 2 * cell.y, cell.x, cell.y))
	check.call(_brightest(flash) > _brightest(calm), "TX10: los cuadros 10 y 11 del rayo son los de destello y el 0 no")

	# El dado.
	var die := Die.new()
	die.element = "fire"
	die.value = 6
	die.size = Vector2(62, 62)
	check.call(not die.element_animated and die._element_frame == 0, "TX10: un dado hecho sin la mesa no se anima")
	die.element_animated = true
	die.element_suspended = true
	die._process(0.0)
	check.call(die._element_frame == 0, "TX10: un elemento suspendido por un jefe se ve quieto")
	die.free()

	# La mesa decide si hay animación, con los mismos interruptores que el resto del movimiento y sin tocar el azar.
	var before: Dictionary = scene.game.snapshot()
	var d := Die.new()
	var old_motion: bool = scene.preferences.reduced_motion
	var old_speed: int = scene.preferences.speed
	var old_flashes: bool = scene.preferences.reduced_flashes
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.preferences.reduced_flashes = false
	scene.animate_element(d, 3)
	check.call(d.element_animated and d.element_frame_ms == 120 and d.element_phase == 3 and not d.flashes_reduced, "TX10: la mesa anima a velocidad normal con la fase de su lugar")
	var phases: Dictionary = {}
	for slot in range(5):
		scene.animate_element(d, slot)
		phases[d.element_phase] = true
	check.call(phases.size() == 5, "TX10: los cinco dados de la mano arrancan en cuadros distintos")
	scene.preferences.speed = 2
	scene.animate_element(d, 0)
	check.call(d.element_frame_ms == 75, "TX10: la velocidad rápida baja el cuadro a 75 ms")
	scene.preferences.speed = 0
	scene.animate_element(d, 0)
	check.call(not d.element_animated, "TX10: con velocidad cero queda el primer cuadro")
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = true
	scene.animate_element(d, 0)
	check.call(not d.element_animated, "TX10: con «Reducir movimiento» queda el primer cuadro")
	scene.preferences.reduced_motion = false
	scene.preferences.reduced_flashes = true
	scene.animate_element(d, 0)
	check.call(d.flashes_reduced, "TX10: «Reducir destellos» llega al dado")
	scene.preferences.reduced_motion = old_motion
	scene.preferences.speed = old_speed
	scene.preferences.reduced_flashes = old_flashes
	d.free()
	check.call(scene.game.snapshot() == before, "TX10: animar los elementos no cambia el estado ni el azar de la partida")

static func _brightest(image: Image) -> float:
	var best := 0.0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c := image.get_pixel(x, y)
			if c.a > 0.0: best = maxf(best, c.r + c.g + c.b)
	return best
