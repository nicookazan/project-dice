extends SceneTree
## Revisión visual de las manos de jefe v4 dentro del juego real: reposo, tres cuadros del clic y el aro dorado de cada jefe
## (requiere GPU, sin --headless). Escribe en test-results/manos-v4/.
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const HandClips = preload("res://scripts/boss_hand_clips.gd")
const CROP := Rect2i(480, 0, 440, 230)
var scene

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/manos-v4"))
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	for id in HandClips.CLIPS.keys():
		scene.game = CatalogTests.forced_boss(id, true)
		scene.background.thermos_configured = false
		scene.render()
		await capture(id + "-reposo")
		var frames: int = HandClips.CLIPS[id].frames
		for pick in [frames / 4, frames / 2, (3 * frames) / 4]:
			scene.background.props.elapsed.erase("hand")
			scene.background.props.hand_clip = id
			scene.background.props.elapsed["hand"] = (pick + 0.5) * scene.background.props.HAND_CLIP_SECONDS
			scene.background.queue_redraw()
			await capture("%s-clic%d" % [id, pick])
		scene.background.props.stop_all()
		scene.background.queue_redraw()
		scene.find_child("Ring_hand", true, false).hovered = true
		await capture(id + "-aro")
	print("BOSS HANDS V4 REVIEW: %d bosses" % HandClips.CLIPS.size())
	quit()

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().get_region(CROP).save_png(ProjectSettings.globalize_path("res://test-results/manos-v4/" + name + ".png"))
