extends SceneTree
## Capturas del paso J04: ventanita de stickers en la mesa y en la tienda. Requiere GPU (sin --headless).
const Tests = preload("res://tests/sticker_tip_tests.gd")
const T = preload("res://tests/felt_drop_tests.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	var levels := {"pair_loose": 3, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1}
	scene.game = Tests.stickered_game(levels)
	scene.render()
	await hover("StickerZone_full", "mesa")
	scene.game = Tests.stickered_game(levels)
	scene.game.phase = "shop"
	scene.render()
	await hover("StickerZone_trio", "tienda")
	print("STICKER REVIEW OK")
	quit(0)

func hover(zone_name: String, shot_name: String) -> void:
	var zone: Control = scene.ui.get_node("InspectThermos").get_node(zone_name)
	await T.motion(scene, zone.get_global_rect().get_center())
	scene.update_hover_description()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/sticker-" + shot_name + ".png")
