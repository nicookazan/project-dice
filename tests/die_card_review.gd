extends SceneTree
## Capturas del paso J02: ficha del dado en la mesa (varios casos) y en la tienda. Requiere GPU (sin --headless).
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
const T = preload("res://tests/felt_drop_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.drag_groups = true
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [5, 5, 2, 5, 2])
	scene.game.global_points = {"5": 3}
	scene.game.dice[3].material = "steel"; scene.game.dice[3].shell = "ruby"; scene.game.dice[3].element = "fire"
	scene.game.dice[1].shell = "emerald"; scene.game.dice[1].shell_broken = true; scene.game.dice[1].element = "water"
	scene.game.dice[0].faces = [1, 2, 3, 5, 5, 5]
	scene.render()
	var n := 0
	for index in [3, 1, 0, 2]:
		var center: Vector2 = scene.table_dice[index].get_global_transform() * Vector2(31, 31)
		await T.motion(scene, center)
		scene.update_hover_description()
		await shot("mesa-%d" % index)
	scene.game.phase = "shop"
	scene.render()
	for child in scene.ui.get_children():
		if child.get_script() == scene.Die and child.die_index == 3:
			await T.motion(scene, child.get_global_transform() * Vector2(31, 31))
			scene.update_hover_description()
	await shot("tienda")
	print("CARD REVIEW OK")
	quit(0)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/card-" + name + ".png")
