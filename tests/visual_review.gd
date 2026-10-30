extends SceneTree
const NumberUpgrades = preload("res://scripts/number_upgrades.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
## Controlled review scenes, never used by the playable run.
func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	scene.game.restart(42)
	scene.game.roll()
	for i in range(5): scene.game.dice[i].value = [6, 6, 6, 2, 2][i]
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	await capture("grupos")

	scene.game.restart(42)
	scene.game.roll()
	for i in range(5): scene.game.dice[i].value = [2, 2, 5, 5, 6][i]
	scene.selected = [0, 1, 2, 3]
	scene.act(func(): scene.game.form_group(scene.selected))
	await capture("doble-par")
	scene.game.score_hand()
	scene.render()
	await capture("doble-par-anotado")
	scene.game.phase = "shop"
	scene.game.cash = 11
	scene.game.offers = ["full", "boost"]
	scene.render()
	await capture("tienda")
	scene.game.phase = "hand_result"
	scene.game.cash = 0
	scene.game.points = 37
	scene.game.last_score = scene.game.preview()
	scene.game.next_hand()
	scene.game.roll()
	for i in range(5): scene.game.dice[i].value = [6, 6, 6, 6, 5][i]
	scene.game.form_group([0, 1, 2, 3])
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.render()
	await capture("cobro")
	scene.game.restart(42)
	scene.game.roll()
	for i in range(5): scene.game.dice[i].value = [1, 1, 1, 2, 2][i]
	scene.game.passives = ["full", "even", "odd"]
	scene.game.boost = true
	scene.game.form_group([0, 1, 2, 3, 4])
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	await capture("desglose-puntos")
	scene.detail.hide()
	scene.game.restart(42)
	NumberUpgrades.apply_global(scene.game.global_points, 4, 3)
	NumberUpgrades.apply_global(scene.game.global_points, 4, 12)
	NumberUpgrades.change_face(scene.game.dice, 0, 1, 4)
	scene.game.roll()
	for i in range(5):
		scene.game.dice[i].value = [4, 4, 1, 2, 3][i]
		scene.game.dice[i].face_index = scene.game.dice[i].faces.find(scene.game.dice[i].value)
	scene.game.form_group([0, 1])
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	await capture("mejoras-numericas")
	scene.detail.hide()
	scene.game.restart(42)
	scene.game.dice[0].material = "steel"
	scene.game.dice[1].material = "steel"
	scene.game.dice[2].material = "copper"
	scene.game.dice[3].material = "copper"
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.move_die(2, "cup")
	scene.game.move_die(3, "cup")
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([2, 3])
	scene.game.move_die(4, "cup")
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.render()
	await capture("metales")
	scene.show_detail(scene.game.preview().rows[0])
	await capture("acero")
	scene.detail.hide()
	scene.show_detail(scene.game.preview().rows[1])
	await capture("cobre")
	scene.detail.hide()
	scene.game.restart(42)
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].element = "fire"
	scene.game.dice[1].element = "water"
	scene.game.dice[2].material = "copper"
	scene.game.dice[2].element = "electricity"
	scene.game.dice[3].element = "water"
	NumberUpgrades.apply_global(scene.game.global_points, 4, 3)
	NumberUpgrades.apply_global(scene.game.global_points, 4, 12)
	scene.game.roll()
	scene.game.move_die(2, "cup")
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 2])
	scene.game.form_group([0, 1])
	scene.game.form_group([2, 3, 4])
	scene.render()
	await capture("elementos")
	scene.show_detail(scene.game.preview().rows[0])
	await capture("fuego-agua")
	scene.detail.hide()
	scene.show_detail(scene.game.preview().rows[1])
	await capture("electricidad")
	scene.detail.hide()
	scene.game.restart(42)
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].element = "earth"
	scene.game.dice[2].material = "copper"
	scene.game.dice[2].element = "wind"
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	for iteration in range(2):
		scene.game.move_die(2, "cup")
		scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([2, 3])
	scene.render()
	await capture("elementos-mano")
	scene.show_detail(scene.game.preview().rows[0])
	await capture("tierra-acero")
	scene.detail.hide()
	scene.show_detail(scene.game.preview().rows[1])
	await capture("viento-cobre")
	scene.detail.hide()
	scene.game.score_hand()
	scene.game.next_hand()
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.form_group([2, 3])
	scene.render()
	await capture("reinicio-elementos-mano")
	scene.game.restart(73)
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].element = "earth"
	scene.game.dice[2].material = "copper"
	scene.game.dice[2].element = "wind"
	for id in range(5): scene.game.dice[id].shell = ["emerald", "sapphire", "ruby", "diamond", "diamond"][id]
	NumberUpgrades.apply_global(scene.game.global_points, 4, 3)
	NumberUpgrades.apply_global(scene.game.global_points, 4, 12)
	scene.game.passives = ["even"]
	scene.game.roll()
	for iteration in range(2):
		scene.game.move_die(2, "cup")
		scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 2])
	scene.game.form_group([0, 1, 2, 3, 4])
	scene.render()
	await capture("gemas")
	scene.show_detail(scene.game.preview().rows[0])
	await capture("gemas-desglose")
	scene.detail.hide()
	scene.game.dice[0].shell_broken = true
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	await capture("gema-resquebrajada")
	scene.detail.hide()
	scene.game.restart(86)
	for id in range(4):
		scene.game.dice[id].shell = ["emerald", "ruby", "sapphire", "diamond"][id]
		scene.game.dice[id].shell_broken = true
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.points = scene.game.target()
	scene.game.cash = -20
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.repair_selection = [0, 3]
	scene.render()
	await capture("reparacion-seleccion")
	scene.game.resolve_repairs([0, 3])
	scene.render()
	await capture("reparacion-cobrada")
	scene.game.restart(95)
	scene.game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	scene.game.cup.stickers = {"trio": 2}
	scene.game.roll()
	Fixture.set_results(scene.game, [6, 6, 6, 2, 2])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	await capture("stickers-categorias")
	scene.show_detail(scene.game.preview().rows[0])
	await capture("sticker-desglose")
	scene.detail.hide()
	scene.game.restart(110)
	scene.game.passives = ["full", "straight", "generala", "poker", "even"]
	scene.game.consumable = "roll"
	scene.render()
	await capture("monedas-inventario")
	scene.inspect_coin("full")
	await capture("moneda-inspeccion")
	scene.detail.hide()
	scene.game.phase = "shop"
	scene.game.cash = 100
	scene.game.offers = ["odd", "boost"]
	scene.render()
	await capture("monedas-limites-tienda")
	scene.game = preload("res://tests/shop_tests.gd").game_at_shop(130)
	scene.shop_section = "coins"
	scene.render()
	await capture("tienda-monedas-cuatro")
	scene.shop_section = "components"
	scene.render()
	await capture("tienda-componentes")
	scene.game.refresh_shop("components")
	scene.shop_section = "numbers"
	scene.render()
	await capture("tienda-numeros")
	scene.shop_section = "stickers"
	scene.render()
	await capture("tienda-stickers")
	scene.game = preload("res://tests/purchase_tests.gd").fixture("shell", {"id": "sapphire", "intact": true})
	scene.game.dice[1].material = "steel"
	scene.game.dice[1].shell = "ruby"
	scene.game.dice[1].shell_broken = true
	scene.game.dice[1].element = "fire"
	scene.shop_section = "components"
	scene.game.begin_purchase("components", "fixture:1")
	scene.game.set_purchase_target({"die_id": 1})
	scene.render()
	await capture("compra-reemplazo")
	scene.game.confirm_purchase()
	scene.render()
	await capture("compra-confirmada")
	scene.game = preload("res://tests/purchase_tests.gd").fixture("face", {"number": 4}, 4)
	scene.shop_section = "numbers"
	scene.game.begin_purchase("numbers", "fixture:1")
	scene.game.set_purchase_target({"die_id": 0, "face_index": 1})
	scene.render()
	await capture("compra-cara")
	scene.game = preload("res://tests/purchase_tests.gd").fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	scene.game.cup.stickers = {"trio": 2}
	scene.shop_section = "stickers"
	scene.game.purchase_offer("stickers", "fixture:1")
	scene.render()
	await capture("compra-pack-eleccion")
	quit()

func capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	root.get_texture().get_image().save_png("res://test-results/" + filename + ".png")
