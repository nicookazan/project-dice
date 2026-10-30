extends SceneTree
## Render a reproducible throw as individual frames for visual review.

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	scene.game.restart(42)
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	scene.render()
	scene.set_process(false)
	scene.act(scene.game.roll)
	DirAccess.make_dir_recursive_absolute("res://test-results/lanzamiento")
	for frame in range(30):
		if frame > 0: scene.step_throw(1.0 / 25.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.save_png("res://test-results/lanzamiento/%02d.png" % frame)
	quit()
