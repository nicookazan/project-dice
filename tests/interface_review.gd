extends SceneTree
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const PurchaseTests = preload("res://tests/purchase_tests.gd")
var prefix := ""

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-"
	scene.game = Game.new(160)
	scene.game.dice[0].faces = [1, 4, 3, 4, 5, 6]
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[0].shell_broken = true
	scene.game.dice[0].element = "earth"
	scene.game.global_points["4"] = 3
	scene.game.global_points["4"] = 15
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.dice[0].encounter_effects["steel_points"] = 6.0
	scene.game.dice[0].hand_effects["earth_points"] = 12.0
	scene.game.form_group([0, 1])
	scene.game.move_die(4, "cup")
	scene.game.move_die(4, "reserve")
	scene.selected = [2]
	scene.render()
	await capture("mesa-estados")
	scene.inspect_die(0)
	await capture("ficha-dado")
	scene.detail.hide()
	scene.game = Game.new(161)
	scene.game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	scene.game.cup.stickers = {"pair_loose": 2}
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[1].material = "copper"
	scene.game.dice[1].element = "wind"
	Fixture.set_values(scene.game, [4, 4, 1, 2, 3])
	scene.game.dice[1].encounter_effects["copper_multiplier"] = 1.0
	scene.game.dice[1].hand_effects["wind_multiplier"] = 0.5
	scene.game.form_group([0, 1])
	scene.selected = []
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	await capture("detalle-decimal")
	scene.detail.hide()
	scene.inspect_cup()
	await capture("ficha-vaso")
	scene.detail.hide()
	scene.game = ShopTests.game_at_shop(162)
	scene.game.passives = ["full", "straight", "generala", "poker", "even"]
	scene.game.consumable = "boost"
	scene.render()
	await capture("tienda-cinco-zonas")
	for section in ["coins", "components", "numbers", "stickers"]:
		for offer in scene.game.shop_state[section].slots.duplicate(true): scene.game.commit_shop_offer(section, offer.offer_id)
	scene.render()
	await capture("tienda-vacia")
	scene.game = PurchaseTests.fixture("face", {"number": 4}, 4)
	scene.game.begin_purchase("numbers", "fixture:1")
	scene.game.set_purchase_target({"die_id": 0, "face_index": 1})
	scene.render()
	await capture("seleccion-cara")
	scene.game = PurchaseTests.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	scene.game.purchase_offer("stickers", "fixture:1")
	scene.render()
	await capture("pack-elegir")
	scene.game = PurchaseTests.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.render()
	click_button(scene, "$7")
	await capture("pack-recibir")
	scene.detail.hide()
	scene.inspect_coin("boost")
	await capture("ficha-moneda")
	scene.detail.hide()
	quit()

func click_button(node: Node, text: String) -> bool:
	if node is Button and node.text == text:
		node.pressed.emit()
		return true
	for child in node.get_children():
		if click_button(child, text): return true
	return false

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + name + ".png")
