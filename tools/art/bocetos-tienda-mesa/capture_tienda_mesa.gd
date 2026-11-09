extends SceneTree
## Capturas de la tienda sobre la mesa ya integrada (08/11/2026): completa y con un sticker volando al termo.
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-tienda-mesa/capture_tienda_mesa.gd
const ShopTests = preload("res://tests/shop_tests.gd")
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	scene.game = ShopTests.game_at_shop(162)
	scene.game.message = "Elegí una oferta o continuá al siguiente encuentro."
	scene.game.passives = ["even", "odd", "full"]
	scene.game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(scene.game.shop_state, scene.game.passives)
	scene.game.consumable = "even_boost"
	scene.game.cash = 24
	scene.game.cup.stickers = {"pair_loose": 1, "full": 2}
	scene.render()
	await capture("completa")
	# Comprar el sticker suelto y fotografiar el vuelo a mitad de camino y al pegarse.
	for card in scene.ui.get_node("Shop_stickers").get_children():
		var price = card.get_node_or_null("Price")
		if price != null and scene.game.shop_state.stickers.slots[card.get_index()].get("kind", "") == "sticker":
			price.pressed.emit()
			break
	var flight = scene.ui.get_node_or_null("StickerFlight")
	if flight != null:
		flight.set_process(false)
		flight.step(flight.FRAME * (flight.HOLD + 10))
		await capture("vuelo")
		flight.step(flight.FRAME * (flight.FLIGHT - 7))
		await capture("pegado")
	scene.ui.get_node("BarProp_flag").clicked.emit()
	scene.ui.get_node("BarProp_soda_left").clicked.emit()
	for i in 12: await process_frame
	await capture("sala-animada")
	quit()

func capture(caption: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/bocetos-tienda-mesa"))
	root.get_texture().get_image().save_png("res://test-results/bocetos-tienda-mesa/integrada-" + caption + ".png")
	print("captura ", caption)
