extends SceneTree
## Captura del menú de la partida y del selector «Ir a otro nivel» (08/11/2026).
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-dios/capture_selector.gd
const Campaign = preload("res://scripts/campaign.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
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
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 4)
	scene.render()
	scene.show_game_menu()
	await capture("menu")
	scene.show_level_picker()
	await capture("selector")
	quit()

func capture(caption: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/bocetos-dios"))
	root.get_texture().get_image().save_png("res://test-results/bocetos-dios/nivel-" + caption + ".png")
