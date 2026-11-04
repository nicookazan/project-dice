extends SceneTree
## Capturas del paso J01: Reservar, brillo del vaso, entrada del dado y Opciones. Requiere GPU (sin --headless).
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
const T = preload("res://tests/felt_drop_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.drag_groups = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-felt-" % [root.size.x, root.size.y]
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.render()
	await capture("mesa")
	var start: Vector2 = scene.table_dice[4].get_global_transform() * Vector2(31, 31)
	await T.motion(scene, start)
	await T.press(scene, start, true)
	await T.motion(scene, start + Vector2(30, 5))
	await T.motion(scene, Vector2(900, 560))
	var overlay = scene.ui.get_node("TableDragOverlay")
	overlay.set_process(false)
	overlay.update_hints(1.0, Vector2(900, 560))
	await capture("arrastre-lejos")
	await T.motion(scene, Vector2(1150, 560))
	overlay.update_hints(1.0, Vector2(1150, 560))
	await capture("arrastre-cerca")
	await T.motion(scene, Vector2(1180, 520))
	await T.press(scene, Vector2(100, 120), false)
	var entry = scene.CupEntry.new()
	scene.add_child(entry)
	entry.play(scene.game.dice[4], scene.game.boss_context(), Vector2(1180, 520), 0.5)
	for frame in 3: await process_frame
	await capture("entra-1")
	for frame in 8: await process_frame
	await capture("entra-2")
	await create_timer(0.8).timeout
	scene.show_options()
	await capture("opciones")
	print("FELT REVIEW OK")
	quit(0)

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
