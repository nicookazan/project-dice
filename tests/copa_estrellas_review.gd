extends SceneTree
## Captura de la mesa con las estrellas de la copa prendidas y el confeti en vuelo. Requiere GPU (sin --headless).
const Confetti = preload("res://scripts/confetti.gd")
func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.campaign_mode = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	scene.game.restart(42)
	scene.game.roll()
	scene.render()
	scene.background.light_copa_star(0)
	scene.background.light_copa_star(1)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/copa-dos.png")
	scene.background.light_copa_star(2)           # dispara el confeti
	for f in [10, 22]:
		var c = scene.get_node("Confetti")
		c.elapsed = f * Confetti.STEP_SECONDS
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/copa-confeti-%02d.png" % f)
	quit(0)
