extends SceneTree
## Capturas del paso J06: cuadros del vaso que tira. Requiere GPU (sin --headless).
const Game = preload("res://scripts/game.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	root.add_child(scene)
	await process_frame
	scene.game = Game.new(148)
	scene.render()
	scene.background.set_process(false)
	scene.set_process(false)
	scene.click_cup()
	for f in [3, 14, 24, 30, 36, 46, 53]:
		scene.throw_elapsed = 0.0
		scene.step_throw((f + 0.5) * scene.throw_frame_seconds)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/cup-%02d.png" % f)
	print("CUP REVIEW OK")
	quit(0)
