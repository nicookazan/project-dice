extends SceneTree
## TX10: capturas de los cinco elementos animados en la mesa, en dos momentos distintos.
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	await create_timer(0.2).timeout
	prefix = "%dx%d-elementos-" % [root.size.x, root.size.y]
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [5, 3, 6, 2, 4])
	var names := ["fire", "water", "electricity", "earth", "wind"]
	for i in range(5): scene.game.dice[i].element = names[i]
	scene.render()
	await create_timer(0.8).timeout
	await capture("mesa-a")
	await create_timer(0.37).timeout
	await capture("mesa-b")
	print("ELEMENTOS REVIEW done")
	quit(0)

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
