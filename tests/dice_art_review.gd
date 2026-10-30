extends SceneTree
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Purchase = preload("res://tests/purchase_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-dados-brillantes-"
	await capture("menu")
	UI.find_button(scene.ui, "Ver diseños de dados").pressed.emit()
	await capture("galeria-30")
	scene.detail.hide()
	scene.game = Game.new(902)
	scene.game.cup.stickers = {"pair_loose": 1, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1}
	scene.game.sticker_catalog = preload("res://scripts/validation_profile.gd").stickers()
	Fixture.set_values(scene.game, [1, 2, 3, 4, 6])
	for i in range(5): scene.game.dice[i].shell = ["", "ruby", "sapphire", "emerald", "diamond"][i]
	scene.render()
	await capture("mesa")
	scene.ui.get_node("InspectThermos").pressed.emit()
	await capture("termo-stickers")
	scene.detail.hide()
	scene.game.dice[1].shell_broken = true
	scene.selected = [1]
	scene.render()
	await capture("danado-seleccion")
	scene.game = Purchase.fixture("shell", {"id": "sapphire", "intact": true}, 5)
	scene.game.cup.stickers = {"trio": 2, "generala": 1}
	Fixture.set_results(scene.game, [1, 2, 3, 4, 6])
	for i in range(5): scene.game.dice[i].shell = ["", "ruby", "sapphire", "emerald", "diamond"][i]
	scene.render()
	await capture("tienda")
	scene.show_options()
	scene.show_dice_gallery()
	await capture("galeria-desde-opciones")
	print("DICE ART REVIEW: 7 captures; gallery, real table, thermos/stickers, damage/selection and shop")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
