extends SceneTree
const Flow = preload("res://tests/level_flow_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
var prefix := ""

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-flujo-"
	await capture("menu")
	Flow.click(scene, "Opciones")
	await capture("opciones")
	scene.detail.hide()
	scene.start_new_run(3)
	await capture("anuncio")
	Flow.click(scene, "Empezar primer encuentro")
	Flow.click(scene, "Recorrido · M")
	await capture("recorrido")
	scene.detail.hide()
	Flow.click(scene, "Abandonar partida")
	await capture("abandono")
	scene.cancel_navigation()
	Flow.play_run(scene.game, scene)
	await capture("victoria-natural")
	scene.game = Game.new(5)
	Fixture.set_values(scene.game, [6, 6, 6, 6, 5])
	scene.game.form_group([0, 1, 2, 3])
	scene.game.score_hand()
	scene.render()
	await capture("mano-objetivo")
	Flow.click(scene, "Cerrar y cobrar")
	await capture("cobro")
	Flow.click(scene, "Ir a la tienda →")
	await capture("tienda")
	scene.game = Game.new(9)
	scene.game.rival = 2
	scene.game.global_points = {"6": 20}
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[0].shell_broken = true
	Fixture.set_values(scene.game, [6, 6, 6, 6, 6])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.render()
	await capture("reparacion-final")
	scene.game = Game.new(8)
	for h in range(2):
		Fixture.set_values(scene.game, [1, 2, 2, 4, 6])
		scene.game.score_hand()
		if h == 0: scene.game.next_hand()
	scene.render()
	await capture("derrota")
	# Verify the real display option with the GPU window, not the headless mock.
	var original_mode := DisplayServer.window_get_mode()
	var before: Dictionary = scene.game.snapshot()
	var key := InputEventKey.new()
	key.keycode = KEY_F11
	key.pressed = true
	scene._input(key)
	await process_frame
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		push_error("F11 did not enter fullscreen")
		quit(1)
		return
	scene._input(key)
	await process_frame
	if DisplayServer.window_get_mode() != original_mode or scene.game.snapshot() != before:
		push_error("F11 did not restore window or changed game state")
		quit(1)
		return
	print("FLOW REVIEW: 11 captures; F11 fullscreen/restoration passed; state unchanged")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
