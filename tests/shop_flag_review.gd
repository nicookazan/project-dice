extends SceneTree
## Captura del paso de ajustes: la bandera de la tienda ondulando. Requiere GPU (sin --headless).
const Purchases = preload("res://tests/purchase_tests.gd")
const BarProps = preload("res://scripts/bar_props.gd")
func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	scene.game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.render()
	scene.background.set_process(false)
	for f in [0, 5, 9, 14]:
		scene.background.props.elapsed["shop_flag"] = (f + 0.5) * BarProps.SPECS.shop_flag.seconds
		scene.background.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/shopflag-%02d.png" % f)
	quit(0)
