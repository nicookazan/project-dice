extends SceneTree
## Capturas del paso J05: cuadros de cada animación y los aros dorados. Requiere GPU (sin --headless).
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const T = preload("res://tests/felt_drop_tests.gd")
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
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.game.cup.stickers = {"pair_loose": 3, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1}
	scene.render()
	scene.background.set_process(false)
	var props = scene.background.props
	await shot("reposo")
	scene.background.pour_layer.queue_redraw()
	for f in [6, 14, 22, 30, 44, 60]:
		await frame("thermos", f, "termo-%02d" % f)
	for f in [8, 16, 26, 40]:
		await frame("soda_left", f, "sifon-%02d" % f)
	for f in [4, 10]:
		await frame("flag", f, "bandera-%02d" % f)
	props.stop_all()
	for target in ["BarProp_flag", "BarProp_soda_left", "BarProp_soda_right", "InspectThermos"]:
		var node: Control = scene.ui.get_node(target)
		await T.motion(scene, node.get_global_rect().get_center())
		for ring in node.get_children():
			if ring is BarProps.Ring: ring._process(0.0)
		await shot("aro-" + target)
	print("PROPS REVIEW OK")
	quit(0)

func frame(id: String, f: int, name: String) -> void:
	var props = scene.background.props
	props.elapsed.clear()
	props.elapsed[id] = (f + 0.5) * BarProps.SPECS[id].seconds
	scene.background.queue_redraw()
	scene.background.pour_layer.queue_redraw()
	await shot(name)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/props-" + name + ".png")
