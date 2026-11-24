extends SceneTree
## Capturas base para los bocetos de La Semilla (24/11/2026): la mesa del nivel 7 con cada guardián quieto,
## el triángulo provisional (para recuperar el cielo detrás de los guardianes) y solo la interfaz sobre magenta
## (para saber qué píxeles son libreta y botones).
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-semilla/capture_base.gd
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const OUT := "res://test-results/bocetos-semilla/base"
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	var names := {"l7_dios_dados": "ojo", "l7_dios_metales": "figura", "l7_dios_carcasas": "dado"}
	for id in names:
		scene.game = CatalogTests.forced_boss(id, true)
		scene.render()
		await shot(names[id])
	# El triángulo provisional tapa menos cielo que los guardianes.
	scene.background.guardian = -1
	scene.background.queue_redraw()
	await shot("triangulo")
	# Solo interfaz: sin fondo, sobre magenta.
	scene.game = CatalogTests.forced_boss("l7_dios_metales", true)
	scene.render()
	RenderingServer.set_default_clear_color(Color(1, 0, 1))
	scene.background.visible = false
	await shot("interfaz")
	quit()

func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	# Cerrar carteles de inicio de jefe si quedaron abiertos.
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
	print("captura ", name)
