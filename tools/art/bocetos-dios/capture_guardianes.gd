extends SceneTree
## Capturas de la animación al clic de los tres guardianes de Dios ya integrada (08/11/2026): reposo y tres cuadros.
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-dios/capture_guardianes.gd
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const BarProps = preload("res://scripts/bar_props.gd")
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	var shots: Array[Image] = []
	for id in ["l7_dios_dados", "l7_dios_metales", "l7_dios_carcasas"]:
		scene.game = CatalogTests.forced_boss(id, true)
		scene.render()
		scene.preferences.reduced_motion = false
		for f in [0, 4, 8, 11]:
			scene.background.props.elapsed["guardian"] = (f + 0.5) * BarProps.SPECS.guardian.seconds
			scene.background.elapsed = 0.0
			scene.background.queue_redraw()
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			shots.append(root.get_texture().get_image().get_region(Rect2i(470, 0, 400, 230)))
		scene.background.props.stop_all()
		if id == "l7_dios_metales":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/bocetos-dios"))
			root.get_texture().get_image().save_png("res://test-results/bocetos-dios/juego-figura-completa.png")
	var sheet := Image.create(400 * 4, 230 * 3, false, Image.FORMAT_RGBA8)
	for i in shots.size(): sheet.blit_rect(shots[i], Rect2i(0, 0, 400, 230), Vector2i((i % 4) * 400, (i / 4) * 230))
	sheet.save_png("res://test-results/bocetos-dios/juego-guardianes.png")
	print("capturas ", shots.size())
	# Parpadeo del ojo solar en reposo: cerrado, mirando a un lado y al otro.
	scene.game = CatalogTests.forced_boss("l7_dios_dados", true)
	scene.render()
	var blinks := Image.create(400 * 3, 230, false, Image.FORMAT_RGBA8)
	var i := 0
	for f in [3, 8, 11]:
		scene.background.elapsed = (f + 0.3) * scene.background.EYE_IDLE_SECONDS
		scene.background.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		blinks.blit_rect(root.get_texture().get_image().get_region(Rect2i(470, 0, 400, 230)), Rect2i(0, 0, 400, 230), Vector2i(i * 400, 0))
		i += 1
	blinks.save_png("res://test-results/bocetos-dios/juego-ojo-reposo.png")
	quit()
