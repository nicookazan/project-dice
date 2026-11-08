extends SceneTree
## Revisión visual de la paloma ladrona (jefe 1C): capturas de la primera tirada hasta que se lleva el dado (requiere GPU).
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const CROP := Rect2i(340, 0, 1100, 700)
var scene

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/paloma"))
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	root.add_child(scene)
	await process_frame
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.game = CatalogTests.forced_boss("l1_palomas", true)
	scene.render()
	scene.act(scene.game.roll)
	var n := 0
	var t := 0.0
	while t < 6.0 and n < 60:
		await process_frame
		t += 1.0 / 60.0
		if int(t * 60) % 12 == 0:
			root.get_texture().get_image().get_region(CROP).save_png(ProjectSettings.globalize_path("res://test-results/paloma/f%02d.png" % n))
			n += 1
		if n > 0 and not scene.throwing and scene.thief_pending < 0 and t > 1.0: break
	print("PALOMA frames=", n, " pending=", scene.thief_pending, " throwing=", scene.throwing, " tables=", scene.table_dice.size())
	quit()
