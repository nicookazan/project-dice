extends SceneTree
const Die = preload("res://scripts/die.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Purchase = preload("res://tests/purchase_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-componentes-"
	scene.show_component_gallery()
	await capture("galeria-arriba")
	var scroll: ScrollContainer = scene.dice_gallery.get_child(2)
	scroll.scroll_vertical = 850
	await capture("galeria-abajo")
	scene.detail.hide()
	scene.game = Game.new(903)
	Fixture.set_values(scene.game, [5, 6, 4, 2, 3])
	for i in range(5):
		scene.game.dice[i].material = ["steel", "copper", "basic", "steel", "copper"][i]
		scene.game.dice[i].element = ["electricity", "fire", "water", "earth", "wind"][i]
		scene.game.dice[i].shell = ["diamond", "ruby", "sapphire", "emerald", "diamond"][i]
	scene.render()
	await capture("mesa-combinados")
	scene.game.dice[0].shell_broken = true
	scene.selected = [0]
	scene.render()
	await capture("danado-seleccion")
	scene.game = Purchase.fixture("material", {"id": "steel"}, 3)
	scene.game.shop_state.components.slots[1] = {"kind": "element", "effect": {"id": "electricity"}, "price": 3, "offer_id": "review:electricity"}
	scene.render()
	await capture("tienda")
	print("COMPONENT REVIEW complete")
	quit()

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + name + ".png")
