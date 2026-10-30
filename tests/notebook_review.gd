extends SceneTree
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.campaign_mode = false
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	scene.game = Game.new(42)
	scene.render()
	await capture("libreta-frontal-inicio")
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.selected = [2, 3]
	scene.render()
	await capture("libreta-frontal-grupos")
	scene.game.rival = 2
	scene.game.cash = 25
	scene.render()
	await capture("libreta-frontal-jefe")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + caption + ".png")
