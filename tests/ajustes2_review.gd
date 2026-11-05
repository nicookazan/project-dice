extends SceneTree
## Capturas de los ajustes del 5 de noviembre: aro de las ofertas, aro de los stickers y arrastre de varios dados.
## Requiere GPU (sin --headless).
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const T = preload("res://tests/felt_drop_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	root.add_child(scene)
	await process_frame
	# Tienda: aro de todas las ofertas
	scene.game = ShopTests.game_at_shop(151)
	scene.render()
	scene.background.set_process(false)
	var rings := []
	for section in ["coins", "components", "numbers", "stickers"]:
		for card in scene.ui.get_node("Shop_" + section).get_children():
			var ring = card.get_node_or_null("OfferRing")
			if ring != null:
				ring.hover(true)
				rings.append(ring)
	for i in range(8): await process_frame
	await shot("tienda")
	# Stickers
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.game.cup.stickers = {"pair_loose": 3, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1}
	scene.render()
	var zone: Control = scene.ui.get_node("InspectThermos").get_node("StickerZone_full")
	await T.motion(scene, zone.get_global_rect().get_center())
	scene.update_hover_description()
	await shot("sticker")
	# Arrastre de varios dados
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [5, 3, 2, 6, 4])
	scene.render()
	scene.toggle_die(1)
	scene.toggle_die(3)
	scene.toggle_die(4)
	var c: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(31, 31)
	await T.motion(scene, c)
	await T.press(scene, c, true)
	await T.motion(scene, c + Vector2(24, 0))
	await T.motion(scene, c + Vector2(60, 20))
	await T.motion(scene, c + Vector2(110, 30))
	await T.motion(scene, c + Vector2(130, 36))
	await shot("arrastre")
	print("AJUSTES2 REVIEW OK")
	quit(0)

func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/aj2-" + name + ".png")
