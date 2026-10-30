extends SceneTree
const Flow = preload("res://tests/level_flow_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	var valid: bool = scene.campaign_mode and UI.text_in(scene.ui, "21 encuentros")
	Flow.click(scene, "Nueva partida")
	valid = valid and scene.game.campaign.size() == 7 and scene.game.phase == "level_intro" and scene.game.cash == 0 and scene.game.passives.is_empty() and scene.game.global_points.is_empty() and not scene.game.shop_tables.components.is_empty()
	print("CAMPAIGN DEFAULT UI: 7 levels, 21 encounters, provisional catalog, zero starting cash/coins/extra points = ", valid)
	quit(0 if valid else 1)
