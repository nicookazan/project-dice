extends RefCounted
## Cuadro de la copa (salón): tres estrellas clicables que se prenden y, con las tres, confeti de victoria.
const Confetti = preload("res://scripts/confetti.gd")

## Recorrido de los nodos en el orden de reparto de clics de Godot: el último hijo primero y los hijos antes que el padre.
static func _click_order(node: Node, out: Array) -> void:
	var kids := node.get_children()
	kids.reverse()
	for kid in kids: _click_order(kid, out)
	out.append(node)

static func run(scene, check: Callable) -> void:
	var backdrop = scene.background
	var done: Array = [0]
	var counter := func(): done[0] += 1
	backdrop.copa_stars_complete.connect(counter)
	var previous: bool = scene.preferences.reduced_motion
	scene.preferences.reduced_motion = true            # sin confeti en pantalla durante la prueba
	check.call(backdrop.copa_hits.size() == 3 and backdrop.copa_lit == [false, false, false], "Copa stars: three clickable stars, all off at the start")
	backdrop.light_copa_star(2)
	backdrop.light_copa_star(0)
	check.call(backdrop.copa_lit == [true, false, true] and done[0] == 0, "Copa stars: any order, no confetti with two stars on")
	backdrop.light_copa_star(0)
	check.call(done[0] == 0, "Copa stars: clicking a lit star again changes nothing")
	backdrop.light_copa_star(1)
	backdrop.light_copa_star(1)
	check.call(done[0] == 1, "Copa stars: the third star fires the celebration exactly once")
	backdrop.copa_stars_complete.disconnect(counter)
	for i in 3: backdrop.copa_lit[i] = false
	scene.preferences.reduced_motion = previous
	# El clic sobre la estrella llega a la zona clicable (36 px alrededor de la estrella, en pantalla de 1440×900).
	var zone: Control = backdrop.copa_hits[1]
	check.call(zone.size.x >= 30.0 and Rect2(zone.position, zone.size).has_point((backdrop.COPA_STAR_ORIGINS[1] + Vector2(6.5, 6.5)) * 2.0), "Copa stars: the click zone covers the star")
	# Ninguna capa de la interfaz que se dibuja encima del fondo (y que no sea la propia zona clicable) tapa la estrella:
	# un Control a pantalla completa con filtro «parar» se come los clics. (La ventana de pruebas mide 64×64, así que no se
	# puede empujar un clic real; se revisa el árbol.)
	var center: Vector2 = (backdrop.COPA_STAR_ORIGINS[0] + Vector2(6.5, 6.5)) * 2.0
	var hit: Control = backdrop.copa_hits[0]
	var order: Array = []
	_click_order(scene, order)                         # en el orden en que se reparten los clics: lo de arriba primero
	var blockers: Array = []
	var seen_hit := false
	for node in order:
		if node == hit:
			seen_hit = true
			break
		if not (node is Control) or node.is_ancestor_of(hit): continue
		var control: Control = node
		if control.is_visible_in_tree() and control.mouse_filter == Control.MOUSE_FILTER_STOP and control.get_global_rect().has_point(center): blockers.append(control.name)
	check.call(seen_hit and blockers.is_empty(), "Copa stars: no interface layer above the background blocks the click (%s)" % str(blockers))
	# Confeti: 220 piezas y 10 serpentinas; cada pieza sale de una esquina de abajo y deja de verse bajo el piso.
	var confetti = Confetti.new()
	confetti.build(7)
	check.call(confetti.pieces.size() == Confetti.PIECE_COUNT and confetti.streamers.size() == Confetti.STREAMER_COUNT, "Confetti: pieces and streamers are built")
	check.call(Confetti.position_at(1, 10.0, -20.0, 0.0, 0.0, 0.0).x < 100.0 and Confetti.position_at(-1, -10.0, -20.0, 0.0, 0.0, 0.0).x > 1340.0, "Confetti: the cannons sit at the bottom corners")
	check.call(Confetti.position_at(1, 10.0, -20.0, 0.0, 200.0, 0.0) == Vector2.INF, "Confetti: pieces disappear below the floor")
	confetti.free()
