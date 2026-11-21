extends SceneTree
## Captura de la tienda con la nube animada del vendedor (TX7): varios cuadros del bucle. Requiere GPU (sin --headless).
const Purchases = preload("res://tests/purchase_tests.gd")
func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	scene.game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.render()
	scene.background.set_process(false)
	for f in [0, 9, 21, 30]:
		scene.background.elapsed = (f + 0.5) * scene.background.VENDOR_CLOUD_SECONDS
		scene.background.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/vendedor-nube-%02d.png" % f)
	quit(0)
