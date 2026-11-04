extends SceneTree
## Capturas de la fase B: panel de la mano en rival, jefe y Dios (requiere GPU, sin --headless).
const CampaignTests = preload("res://tests/campaign_tests.gd")
const Campaign = preload("res://scripts/campaign.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-mano-"
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 0)
	scene.game.begin_level() if scene.game.phase == "level_intro" else null
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	await capture("rival")
	scene.detail.hide()
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 2)
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	await capture("jefe")
	scene.detail.hide()
	scene.game = CatalogTests.red_card_game(700, ["even", "odd"])
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	await capture("referi")
	scene.detail.hide()
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 20)
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	await capture("dios")
	print("BOSS HAND REVIEW: 4 captures")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
