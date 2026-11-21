extends SceneTree
## Captura de la mesa de juego (sin tienda) para los bocetos de la copa con estrellas. Requiere GPU (sin --headless).
func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.campaign_mode = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	scene.game.restart(42)
	scene.game.roll()
	scene.render()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/copa-mesa.png")
	quit(0)
