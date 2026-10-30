extends SceneTree
const Store = preload("res://scripts/save_store.gd")
const Tests = preload("res://tests/save_tests.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var prefix := ""
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.save_store = Store.new("res://test-results/save-review/" + str(Time.get_ticks_usec()) + "/partida.json")
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-guardado-"
	scene.start_new_run(3)
	Flow.click(scene, "Empezar primer encuentro")
	Flow.click(scene, "TIRAR (3)")
	Flow.click(scene, "Menú")
	await capture("continuar")
	Flow.click(scene, "Nueva partida")
	await capture("confirmar-nueva")
	scene.cancel_navigation()
	Flow.click(scene, "Continuar")
	await capture("reanudada")
	scene.save_store.fail_at = "after_temp"
	scene.selected = [0]
	scene.render()
	await capture("error-escritura")
	scene.save_store.fail_at = ""
	Flow.click(scene, "Error al guardar · reintentar")
	Flow.click(scene, "Menú")
	scene.save_store.write_text(scene.save_store.path, "corrupt original, preserved by explicit recovery")
	scene.refresh_save_status()
	scene.render()
	await capture("respaldo-disponible")
	Flow.click(scene, "Recuperar respaldo y continuar")
	Flow.click(scene, "Menú")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scene.save_store.path))
	envelope.version = 999
	scene.save_store.write_text(scene.save_store.path, JSON.stringify(envelope))
	scene.refresh_save_status()
	scene.render()
	await capture("version-futura")
	# Explicit New Game archives incompatible data and opens a valid checkpoint.
	Flow.click(scene, "Nueva partida")
	scene.confirmation.get_ok_button().pressed.emit()
	var game = Game.new(4)
	game.dice[0].shell = "ruby"
	game.dice[0].shell_broken = true
	Fixture.set_values(game, [6, 6, 6, 6, 6])
	game.form_group([0, 1, 2, 3, 4])
	game.score_hand()
	game.close_encounter()
	scene.game = game
	scene.last_checkpoint = {}
	scene.render()
	var boxes: Array = scene.ui.find_children("*", "CheckBox", true, false)
	boxes[0].button_pressed = true
	Flow.click(scene, "Menú")
	Flow.click(scene, "Continuar")
	await capture("reparacion-pendiente")
	print("SAVE REVIEW: 7 captures, isolated save path: ", scene.save_store.path)
	scene.persistence_enabled = false
	scene.campaign_mode = false
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
