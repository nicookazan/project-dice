extends SceneTree
## Capturas para los bocetos de la tienda (07/11/2026): la tienda completa, la misma sin las ofertas del maletín y la misma
## sin tus dados ni tus monedas. La diferencia entre capturas recorta cada objeto para dibujar repisas y bandejas detrás.
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-jefes/capture_tienda.gd
const ShopTests = preload("res://tests/shop_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	scene.game = ShopTests.game_at_shop(162)
	Fixture.set_results(scene.game, [1, 2, 3, 4, 5])
	scene.game.message = "Elegí una oferta o continuá al siguiente encuentro."
	scene.game.passives = ["even", "odd", "full"]
	scene.game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(scene.game.shop_state, scene.game.passives)
	scene.game.consumable = "even_boost"
	scene.game.cash = 24
	scene.render()
	await capture("completa")
	for node in all_nodes(scene.ui):
		if node is Control and node.name.begins_with("Offer_"): node.visible = false
	await capture("sin-ofertas")
	scene.render()
	for node in all_nodes(scene.ui):
		if node is Control and (node.name.begins_with("OwnedCoin_") or node.get_script() == preload("res://scripts/die.gd") or node.name.begins_with("UseShopCoin_")): node.visible = false
	await capture("sin-inventario")
	quit()

func all_nodes(n: Node) -> Array:
	var out := [n]
	for c in n.get_children(): out.append_array(all_nodes(c))
	return out

func capture(caption: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/bocetos-arte-2"))
	root.get_texture().get_image().save_png("res://test-results/bocetos-arte-2/tienda-" + caption + ".png")
	print("captura ", caption, " ", root.get_texture().get_image().get_size())
