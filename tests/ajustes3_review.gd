extends SceneTree
## Capturas de la ronda 3: el agua desde la lengüeta, el recorrido y el panel de stickers. Requiere GPU (sin --headless).
const Tests = preload("res://tests/ajustes3_tests.gd")
const BarProps = preload("res://scripts/bar_props.gd")
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
	scene.game = Tests.stickered({"pair_loose": 3, "trio": 2, "straight": 1, "full": 1})
	scene.render()
	scene.background.set_process(false)
	for f in [5, 24]:
		scene.background.props.elapsed["thermos"] = (f + 0.5) * BarProps.SPECS.thermos.seconds
		scene.background.queue_redraw()
		scene.background.pour_layer.queue_redraw()
		await shot("pour-%d" % f)
	scene.background.props.stop_all()
	scene.background.pour_layer.queue_redraw()
	scene.ui.get_node("InspectThermos").get_node("StickerZone_trio").gui_input.emit(Tests.click_event())
	await shot("libro")
	print("R3 REVIEW OK")
	quit(0)
func shot(n: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/r3-%s.png" % n)
