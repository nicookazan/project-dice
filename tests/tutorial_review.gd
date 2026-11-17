extends SceneTree
## Capturas de la pantalla inicial, las partidas guardadas y el tutorial (necesita GPU: sin --headless).
const Flow = preload("res://tests/level_flow_tests.gd")
const ProfileStore = preload("res://scripts/profile_store.gd")
var prefix := ""

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = true
	scene.profile_store = ProfileStore.new("res://test-results/tutorial-review/" + str(Time.get_ticks_usec()))
	scene.preferences_enabled = false
	scene.campaign_mode = true
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-tutorial-"
	await capture("1-menu")
	scene.ask_tutorial()
	await capture("2-pregunta")
	scene.start_new_run(-1, false, true)
	await capture("3-vendedor")
	scene.act(scene.game.begin_level)
	await capture("4-mesa-carteles")
	scene.tutorial_seen.append("h1_roll_0")
	scene.render()
	scene.game.roll()
	scene.render()
	await capture("5-mesa-con-signo")
	scene.game.points = 50
	scene.game.phase = "hand_result"
	scene.game.close_encounter()
	scene.tutorial_seen.append("close_1")
	scene.render()
	await capture("6-eleccion")
	scene.act(scene.game.open_shop)
	await capture("7-tienda-carteles")
	scene.game.phase = "lost"
	scene.render()
	await capture("8-cierre")
	scene.game.return_to_menu()
	scene.session_started = false
	scene.pending_tutorial_choice = false
	scene.render()
	scene.show_profiles()
	await capture("9-partidas")
	quit()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	root.get_texture().get_image().save_png("res://test-results/" + prefix + name + ".png")
