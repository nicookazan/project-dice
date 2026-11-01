extends SceneTree
## Captures the in-game menu panel on the table and in the shop (needs a GPU; run without --headless).
const Flow = preload("res://tests/level_flow_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var prefix := ""

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-menu-"
	scene.start_new_run(3)
	Flow.click(scene, "Empezar primer encuentro")
	await capture("mesa")
	scene.show_game_menu()
	await capture("mesa-panel")
	scene.close_game_menu()
	scene.game.phase = "shop"
	scene.render()
	await capture("tienda")
	scene.show_game_menu()
	await capture("tienda-panel")
	quit()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + name + ".png")
