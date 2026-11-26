extends SceneTree
## Bocetos del ítem 6 (pantallas y diseños): monta las pantallas propuestas con los botones y fuentes reales
## sobre la mesa de siempre. No toca el juego. Requiere GPU (sin --headless):
##   godot --path . --script res://tools/art/bocetos-pantallas/bocetos_review.gd
const SinMano = preload("res://tools/art/bocetos-pantallas/sin_mano.gd")
const OUT := "res://tools/art/bocetos-pantallas/"
var scene

# Paños de la mesa (coordenadas del juego, 1440×900).
const PANO1 := Rect2(350, 320, 340, 330)
const PANO2 := Rect2(712, 320, 372, 330)
const LIBRETA := Rect2(22, 25, 310, 630)

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	swap_background()

	# --- 1. Menú inicial sobre el paño 1, sin la mano.
	scene.background.hide_hand = true
	menu_base()
	await capture("1a-menu")
	menu_base()
	mode_panel()
	await capture("1b-nueva-partida-modo")
	menu_base()
	tutorial_panel()
	await capture("1c-nueva-partida-tutorial")

	# --- 4. Selección de encuentro: primer encuentro del nivel (tienda en gris) y rival 2.
	scene.background.hide_hand = false
	scene.start_new_run(7)
	scene.game.begin_level()
	scene.render()
	lobby(true)
	await capture("4a-seleccion-primer-encuentro")
	scene.game.rival = 1
	scene.game._start_encounter()
	scene.render()
	lobby(false)
	await capture("4b-seleccion-rival-2")

	# --- 5. Cobro: libreta en blanco, +$total y Continuar.
	scene.start_new_run(7)
	scene.game.begin_level()
	scene.render()
	payout(16)
	await capture("5-cobro")

	# --- 6. Ayuda de la mano del jefe: hoy y propuesta.
	scene.start_new_run(7)
	scene.game.begin_level()
	scene.render()
	await hover_hand(false)
	await capture("6a-mano-hoy")
	await hover_hand(true)
	await capture("6b-mano-propuesta")
	quit()

func swap_background() -> void:
	var old = scene.background
	var fresh = SinMano.new()
	var parent: Node = old.get_parent()
	var index: int = old.get_index()
	parent.add_child(fresh)
	parent.move_child(fresh, index)
	parent.remove_child(old)
	old.queue_free()
	scene.background = fresh
	scene.render()

func clear_ui(keep: Array) -> void:
	for child in scene.ui.get_children():
		if child.name in keep: continue
		child.queue_free()

func centered(parent: Node, text: String, rect: Rect2, size: int, color: Color) -> Label:
	var node: Label = scene.label(parent, text, rect.position, size, color, rect.size.x)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

func menu_base() -> void:
	scene.game.return_to_menu()
	scene.render()
	clear_ui(["MenuMate", "HoverDescription"])
	var x := PANO1.position.x + 62
	var w := PANO1.size.x - 92
	var y := PANO1.position.y + 12
	var items := ["Nueva partida", "Colecciones", "Opciones", "Salir", "Nueva partida debug"]
	for i in items.size():
		var b: Button = scene.button(scene.ui, items[i], Rect2(x, y + i * 60, w, 48), func(): pass, false, i == 0)
		if i == 4: b.add_theme_font_size_override("font_size", 15)
	scene.label(scene.ui, "solo en builds de desarrollo", Vector2(x, y + 4 * 60 + 50), 13, scene.gold, w)

func mode_panel() -> void:
	var x := PANO2.position.x + 46
	var w := PANO2.size.x - 92
	var y := PANO2.position.y + 16
	centered(scene.ui, "ELEGÍ UN MODO", Rect2(x, y, w, 30), 24, scene.gold)
	scene.button(scene.ui, "Campaña", Rect2(x, y + 50, w, 52), func(): pass, false, true)
	for i in 2:
		var grey: Button = scene.button(scene.ui, "Próximamente", Rect2(x, y + 116 + i * 62, w, 48), func(): pass, true)
		grey.tooltip_text = "Modo todavía sin definir"
	scene.button(scene.ui, "Volver", Rect2(x + 60, y + 260, w - 120, 40), func(): pass)

func tutorial_panel() -> void:
	var x := PANO2.position.x + 46
	var w := PANO2.size.x - 92
	var y := PANO2.position.y + 16
	centered(scene.ui, "CAMPAÑA", Rect2(x, y, w, 30), 24, scene.gold)
	centered(scene.ui, "¿Querés jugar el tutorial?", Rect2(x, y + 40, w, 30), 19, scene.cream)
	scene.button(scene.ui, "Sí, jugar el tutorial", Rect2(x, y + 86, w, 50), func(): pass, false, true)
	scene.button(scene.ui, "No, ir a la campaña", Rect2(x, y + 150, w, 48), func(): pass)
	scene.button(scene.ui, "Volver", Rect2(x + 60, y + 260, w - 120, 40), func(): pass)

## Saca la libreta, la botonera y el botón Menú; deja la bandeja de abajo, el termo, la mano y la semilla.
func strip_table(keep_notebook := false) -> void:
	for child in scene.ui.get_children():
		if child.name == "PlayerNotebook" and keep_notebook: continue
		if child.name == "PlayerNotebook": child.queue_free(); continue
		if child is Button and child.position.y >= 600 and child.position.y <= 740 and child.position.x < 1400: child.queue_free(); continue
		if child is Button and child.text == "Menú": child.queue_free()

func lobby(first: bool) -> void:
	strip_table()
	var game = scene.game
	var x := PANO1.position.x + 34
	var w := PANO1.size.x - 64
	var y := PANO1.position.y + 26
	centered(scene.ui, "OBJETIVO", Rect2(x, y, w, 24), 17, scene.cream)
	centered(scene.ui, "%d PUNTOS" % game.target(), Rect2(x, y + 22, w, 44), 36, scene.gold)
	var who := "el jefe" if game.is_boss() else "el siguiente rival"
	scene.button(scene.ui, "Jugar contra %s" % who, Rect2(x, y + 84, w, 58), func(): pass, false, true)
	var boss_name: String = game.boss_name()
	centered(scene.ui, "Nivel %d · Rival %d/%d · Jefe: %s" % [game.level_index + 1, game.rival + 1, game.level_encounters.size(), boss_name], Rect2(x - 10, y + 152, w + 20, 40), 15, scene.cream)
	var skip: Button = scene.button(scene.ui, "Saltear", Rect2(x + 50, y + 222, w - 100, 42), func(): pass, true)
	skip.tooltip_text = "Próximamente"
	var sx := PANO2.position.x + 50
	var sw := PANO2.size.x - 100
	var shop: Button = scene.button(scene.ui, "Ir a la tienda", Rect2(sx, PANO2.position.y + 110, sw, 58), func(): pass, first, not first)
	if first:
		centered(scene.ui, "Se abre después de ganar\nel primer encuentro del nivel.", Rect2(sx - 10, PANO2.position.y + 180, sw + 20, 50), 15, scene.cream)
	else:
		centered(scene.ui, "Podés entrar y salir\nlas veces que quieras.", Rect2(sx - 10, PANO2.position.y + 180, sw + 20, 50), 15, scene.cream)
	# Mesa libre donde estaba la libreta.
	scene.button(scene.ui, "Opciones", Rect2(60, 300, 236, 50), func(): pass)
	scene.button(scene.ui, "Abandonar partida", Rect2(60, 366, 236, 50), func(): pass)

func payout(total: int) -> void:
	strip_table(true)
	var note: Node = scene.ui.get_node("PlayerNotebook")
	for child in note.get_children():
		if child is Label and child.text != "LIBRETA": child.queue_free()
		elif not (child is Label or child is ColorRect): child.queue_free()
	var big := centered(scene.ui, "+$%d" % total, Rect2(PANO2.position.x, PANO2.position.y + 80, PANO2.size.x, 90), 72, scene.gold)
	big.add_theme_color_override("font_outline_color", Color("2a0a10"))
	big.add_theme_constant_override("outline_size", 8)
	scene.button(scene.ui, "Continuar", Rect2(PANO2.position.x + 70, PANO2.position.y + 190, PANO2.size.x - 140, 56), func(): pass, false, true)

func hover_hand(proposal: bool) -> void:
	var hand: Control = scene.ui.get_node("InspectBoss")
	var center := hand.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center * Vector2(root.size) / Vector2(1440, 900)
	Input.warp_mouse(motion.position)
	root.push_input(motion, true)
	for i in 3: await process_frame
	if proposal:
		var box: Control = scene.hover_description
		box.reset_size()
		var rect := hand.get_global_rect()
		var pos := Vector2(rect.get_center().x - box.size.x / 2, rect.end.y + 8)
		pos.x = clampf(pos.x, 12, 1440 - box.size.x - 12)
		box.position = pos

func capture(caption: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1440, 900): image.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + "boceto-" + caption + ".png")
	print("boceto ", caption, " ", image.get_size())
