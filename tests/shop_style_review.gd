extends SceneTree
const ShopTests = preload("res://tests/shop_tests.gd")
const Purchases = preload("res://tests/purchase_tests.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const UI = preload("res://tests/interface_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-tienda-estilo-"
	scene.game = ShopTests.game_at_shop(162)
	Fixture.set_results(scene.game, [1, 2, 3, 4, 5])
	scene.game.message = "Elegí una oferta o continuá al siguiente encuentro."
	scene.game.passives = ["even", "odd", "full"]
	scene.game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(scene.game.shop_state, scene.game.passives)
	scene.game.cash = 24
	scene.render()
	await capture("ofertas")
	var before: Dictionary = scene.game.snapshot()
	scene.render()
	if scene.game.snapshot() != before: push_error("Shop redraw mutated state")
	scene.game.passives = ["full", "straight", "generala", "poker", "even"]
	scene.game.consumable = "boost"
	scene.render()
	await capture("inventario-lleno")
	scene.game.cash = -3
	scene.render()
	await capture("deuda")
	scene.game = Purchases.fixture("shell", {"id": "sapphire", "intact": true}, 5)
	scene.game.begin_purchase("components", "fixture:1")
	scene.game.set_purchase_target({"die_id": 0})
	scene.render()
	await capture("confirmacion")
	scene.game = Purchases.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	scene.game.purchase_offer("stickers", "fixture:1")
	scene.render()
	await capture("paquete")
	scene.game = ShopTests.game_at_shop(162)
	for section in ["coins", "components", "numbers", "stickers"]:
		for offer in scene.game.shop_state[section].slots.duplicate(true): scene.game.commit_shop_offer(section, offer.offer_id)
	scene.render()
	await capture("vendido")
	scene.preferences.high_contrast = true
	scene.render()
	await capture("contraste")
	print("SHOP STYLE REVIEW: 7 captures; exact redraw snapshot; purchases/pack/debt/full stock")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
