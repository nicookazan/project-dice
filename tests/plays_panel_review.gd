extends SceneTree
## Capturas del paso J03: lista de jugadas, mouse sobre una fila, grupo armado y ficha juntos. Requiere GPU (sin --headless).
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
const T = preload("res://tests/felt_drop_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [2, 2, 2, 5, 5])
	scene.game.global_points = {"5": 3}
	scene.render()
	await shot("lista")
	var row = scene.plays_panel.rows[1]
	row.entered.emit()
	row.hovered = true
	row.queue_redraw()
	scene.update_hover_description()
	await shot("fila")
	row.exited.emit()
	row.hovered = false
	var center: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(31, 31)
	await T.motion(scene, center)
	scene.update_hover_description()
	await shot("lista-y-ficha")
	await T.motion(scene, Vector2(20, 880))
	scene.plays_panel.play_chosen.emit(scene.plays_panel.rows[3].play.ids)
	await process_frame
	await shot("armado")
	scene.preferences.drag_groups = true
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [1, 2, 3, 4, 5])
	scene.render()
	await shot("arrastre")
	scene.show_options()
	await shot("opciones")
	print("PLAYS REVIEW OK")
	quit(0)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/plays-" + name + ".png")
