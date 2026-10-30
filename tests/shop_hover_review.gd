extends SceneTree
const Shop = preload("res://tests/shop_tests.gd")
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
	prefix = "%dx%d-tienda-hover-" % [root.size.x, root.size.y]
	await hover(preload("res://tests/interface_tests.gd").find_button(scene.ui, "Nueva partida"), Vector2(25, 20), false)
	await capture("menu-sin-cuadro")
	scene.game = Shop.game_at_shop(162)
	scene.game.cash = 24
	scene.game.passives = ["even", "odd", "full"]
	scene.game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(scene.game.shop_state, scene.game.passives)
	Fixture.set_results(scene.game, [1, 2, 3, 4, 5])
	scene.render()
	await capture("ofertas")
	var before: Dictionary = scene.game.snapshot()
	await hover(scene.ui.get_node("Shop_components/Offer_1"), Vector2(80, 50))
	await capture("gema")
	if scene.game.snapshot() != before or scene.detail.visible: push_error("Hover changed game state or opened modal")
	await hover(scene.ui.get_node("Shop_components/Refresh"), Vector2(14, 14))
	await capture("renovar")
	scene.game.cash = -3
	scene.render()
	await hover(scene.ui.get_node("Shop_numbers/Offer_0/Price"), Vector2(40, 15), false)
	await capture("precio-deuda")
	await hover(scene.ui.get_node("Shop_numbers/Offer_0"), Vector2(3, 50), false)
	scene.game.dice[4].shell = "diamond"
	scene.render()
	await hover(scene.ui.get_node("Shop_components/Offer_0"), Vector2(90, 48))
	await capture("material")
	var inventory_dice := preload("res://tests/interface_tests.gd").dice_in(scene.ui)
	for die in inventory_dice:
		if die.die_index == 4 and die.pip_material == "diamond":
			await hover(die, Vector2(30, 30))
			await capture("dado-inventario")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(15, 850) * Vector2(root.size) / Vector2(1440, 900)
	root.push_input(motion, true)
	await create_timer(0.2).timeout
	await capture("sin-descripcion")
	scene.game = preload("res://tests/purchase_tests.gd").fixture("sticker", {"id": "trio"}, 4)
	scene.render()
	preload("res://tests/interface_tests.gd").find_button(scene.ui.get_node("Shop_stickers"), "$4").pressed.emit()
	await capture("sticker-comprado")
	scene.game = Shop.game_at_shop(162)
	scene.game.cash = 24
	Fixture.set_results(scene.game, [1, 2, 3, 4, 5])
	for id in scene.game.sticker_catalog: scene.game.cup.stickers[id] = 2
	scene.render()
	await capture("termo-seis-stickers")
	print("SHOP HOVER REVIEW: actual mouse hover, disabled price, pure game state")
	quit()

func hover(target: Control, offset: Vector2, expected := true) -> void:
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = target.get_global_transform_with_canvas() * offset
	root.push_input(motion, true)
	await process_frame
	motion = InputEventMouseMotion.new()
	motion.position = target.get_global_transform_with_canvas() * (offset + Vector2(1, 0))
	root.push_input(motion, true)
	# No dwell timer: capture the tooltip after the next rendered frame.
	await process_frame
	await process_frame
	var hovered := root.gui_get_hovered_control()
	print("HOVER ", target.get_path(), " -> ", hovered.get_path() if hovered != null else "none")
	if scene.hover_description.visible != expected: push_error("Unexpected description visibility on " + str(target.get_path()))
	if scene.hover_description.position != Vector2(30, 400): push_error("Description moved with cursor")

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
