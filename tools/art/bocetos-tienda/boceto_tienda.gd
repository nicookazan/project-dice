extends SceneTree
## Boceto de la tienda con más monedas (pedido del 25/11/2026). Reinterpreta el dibujo del autor sobre el maletín real.
## Opción A (abajo); la opción B invierte las filas:
##   arriba: 4 monedas pasivas (ancho) | 1 moneda de un uso (angosto)
##   abajo:  2 componentes (elemento, material, gema) | 2 números (+número, cambio de cara) | 2 stickers o paquetes
## El acolchado del maletín se repite cada 24 × 16 píxeles de arte: la división vertical original se borra copiando el
## acolchado de 48 px a la izquierda, y la franja de la división (con sus esquineros) se copia corrida en múltiplos de
## 24 px, así las divisiones nuevas empalman sin costuras. No toca el juego ni el arte. Requiere GPU (sin --headless):
##   godot --path . --script res://tools/art/bocetos-tienda/boceto_tienda.gd
const Tests = preload("res://tests/encounter_choice_tests.gd")
const Coins = preload("res://scripts/coins.gd")
const RetryIcon = preload("res://scripts/retry_icon.gd")
const OUT := "res://tools/art/bocetos-tienda/"

## Zona del maletín que se reemplaza (píxeles de arte de `tienda-v3.png`, 720 × 450; en pantalla va ×2).
const REGION := Rect2i(258, 98, 414, 230)
## Franja de la división vertical original (con los esquineros de las cuatro secciones) y la línea del medio.
const STRIP_X := 440
const STRIP_W := 36
const MID_Y := 217
## Corrimientos de las divisiones nuevas (múltiplos de 24 para que el acolchado empalme).
const TOP_SHIFT := 96
const BOTTOM_SHIFTS := [-72, 72]

## Secciones nuevas en pantalla (1440 × 900) y cuántas tarjetas lleva cada una. Opción A: monedas arriba.
const ZONES := {
	"coins": [Rect2(540, 252, 528, 179), 4],
	"once": [Rect2(1146, 252, 176, 179), 1],
	"components": [Rect2(530, 442, 204, 179), 2],
	"numbers": [Rect2(812, 442, 210, 179), 2],
	"stickers": [Rect2(1100, 442, 228, 179), 2]}
## Opción B, con las filas invertidas: componentes, números y stickers arriba; monedas y la de un uso abajo.
const ZONES_B := {
	"components": [Rect2(540, 252, 222, 179), 2],
	"numbers": [Rect2(788, 252, 254, 179), 2],
	"stickers": [Rect2(1074, 252, 240, 179), 2],
	"coins": [Rect2(534, 442, 560, 179), 4],
	"once": [Rect2(1122, 442, 208, 179), 1]}

var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	scene.game = Tests.reward_game()
	scene.game.continue_after_reward()
	scene.game.open_shop()
	scene.render()
	await capture("boceto-tienda-0-hoy")
	fill_offers()
	scene.render()
	lay_out(ZONES, [TOP_SHIFT], BOTTOM_SHIFTS)
	await capture("boceto-tienda-1-propuesta")
	fill_offers()
	scene.render()
	lay_out(ZONES_B, BOTTOM_SHIFTS, [TOP_SHIFT])
	await capture("boceto-tienda-2-filas-invertidas")
	print("BOCETO TIENDA: listo")
	quit()

## Ofertas del boceto: las del stock real y, para las monedas, cuatro pasivas y una de un uso del catálogo.
func fill_offers() -> void:
	var state: Dictionary = scene.game.shop_state
	var template: Dictionary = {}
	for offer in state.coins.slots:
		if offer.get("kind") == "coin": template = offer
	var passives := ["full", "generala", "even", "straight"]
	var slots: Array = []
	for index in passives.size() + 1:
		var id: String = passives[index] if index < passives.size() else "double_mult"
		if Coins.definition(id).is_empty(): id = Coins.DATA.keys()[index]
		var offer: Dictionary = template.duplicate(true)
		offer.offer_id = "boceto_coin_%d" % index
		offer.effect = {"coin_id": id}
		offer.price = Coins.definition(id).get("price", offer.price)
		slots.append(offer)
	state.coins.slots = slots
	state.coins.configured = true

## Esconde las cuatro secciones de hoy, pone el maletín con las divisiones nuevas y arma las cinco secciones.
func lay_out(zones: Dictionary, top_shifts: Array, bottom_shifts: Array) -> void:
	for section in ["numbers", "components", "coins", "stickers"]:
		var old: Node = scene.ui.find_child("Shop_" + section, false, false)
		if old != null: old.hide()
	var art := TextureRect.new()
	art.name = "BocetoMaletin"
	art.texture = ImageTexture.create_from_image(briefcase(top_shifts, bottom_shifts))
	art.position = Vector2(REGION.position) * 2.0
	art.size = Vector2(REGION.size) * 2.0
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.ui.add_child(art)
	scene.ui.move_child(art, 0)
	for section in zones:
		var rect: Rect2 = zones[section][0]
		var count: int = zones[section][1]
		var zone := Control.new()
		zone.name = "Boceto_" + section
		zone.position = rect.position
		zone.size = rect.size
		scene.ui.add_child(zone)
		# Botón de renovar, como en la tienda de hoy (el ícono necesita un botón como padre).
		var renew := Button.new()
		renew.position = Vector2(rect.size.x / 2.0 - 16.0, -2)
		renew.size = Vector2(32, 30)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: renew.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		zone.add_child(renew)
		var icon := RetryIcon.new()
		icon.position = Vector2(2, 0)
		icon.size = Vector2(28, 30)
		renew.add_child(icon)
		var width: float = (rect.size.x - 24.0) / count
		for index in count:
			var stock_section: String = "coins" if section == "once" else section
			var slot: int = 4 if section == "once" else index
			scene.shop_card(zone, stock_section, slot, Rect2(12 + index * width, 28, width, 145))

## El maletín con las divisiones movidas (corrimientos de la fila de arriba y de la de abajo), recortado a REGION.
func briefcase(top_shifts: Array, bottom_shifts: Array) -> Image:
	var source: Image = load("res://assets/art/pixel-v3/tienda-v3.png").get_image()
	source.convert(Image.FORMAT_RGBA8)
	var art: Image = source.duplicate()
	var top := REGION.position.y
	var bottom := REGION.end.y
	# 1. Borrar la división vertical de hoy con el acolchado de 48 px a la izquierda (la línea del medio sigue igual).
	for y in range(top, bottom):
		for x in range(STRIP_X, STRIP_X + STRIP_W):
			art.set_pixel(x, y, source.get_pixel(x - 48, y))
	# 2. Divisiones nuevas: la franja original (con esquineros) corrida; arriba una, abajo dos.
	for y in range(top, bottom):
		var shifts: Array = top_shifts if y < MID_Y else bottom_shifts
		if y in [MID_Y, MID_Y + 1]: shifts = top_shifts + bottom_shifts
		for shift in shifts:
			for x in range(STRIP_X, STRIP_X + STRIP_W):
				var pixel := source.get_pixel(x, y)
				# En la línea del medio solo se copia el cruce dorado, no el acolchado de alrededor.
				art.set_pixel(x + shift, y, pixel)
	return art.get_region(REGION)

func capture(caption: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1440, 900): image.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + caption + ".png")
