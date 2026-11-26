extends SceneTree
## Capturas del estado actual para los bocetos del ítem 6 (pantallas y diseños). Requiere GPU (sin --headless).
const Tests = preload("res://tests/encounter_choice_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	await capture("menu")
	scene.start_new_run(7)
	await capture("anuncio")
	scene.game.begin_level()
	scene.render()
	await capture("mesa")
	scene.game = Tests.reward_game()
	scene.render()
	await capture("cobro")
	quit()

func capture(caption: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tools/art/bocetos-pantallas/base-" + caption + ".png")
