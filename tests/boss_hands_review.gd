extends SceneTree
## Capturas de la fase C: la mano de cada jefe dentro del juego real, en su ambiente, junto a la mano común
## del mismo nivel (requiere GPU, sin --headless). Escribe en test-results/manos/.
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const CROP := Rect2i(480, 0, 440, 230)
var scene

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/manos"))
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	var ids := Catalog.ROWS.filter(func(row): return row.level <= Catalog.GOD_LEVEL).map(func(row): return row.id)
	for id in ids:
		scene.game = CatalogTests.forced_boss(id, true)
		scene.background.thermos_configured = false
		scene.render()
		await capture(id)
	# Mano común de cada nivel (rival 1), para comparar contraste y escala.
	for level in range(1, 7):
		var first: String = Catalog.of_level(level)[0].id
		scene.game = CatalogTests.forced_boss(first, false)
		scene.background.thermos_configured = false
		scene.render()
		await capture("comun-l%d" % level)
	# Los tres guardianes de Dios sobre el cielo del nivel 7.
	for id in Catalog.GUARDIANS.keys():
		scene.game = CatalogTests.forced_boss(id, true)
		scene.background.thermos_configured = false
		scene.render()
		await capture(id)
	print("BOSS HANDS REVIEW: %d bosses + 6 common + 3 guardians" % ids.size())
	quit()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.get_region(CROP).save_png(ProjectSettings.globalize_path("res://test-results/manos/" + name + ".png"))
