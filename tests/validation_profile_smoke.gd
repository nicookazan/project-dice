extends SceneTree
const Profile = preload("res://scripts/validation_profile.gd")
const UI = preload("res://tests/interface_tests.gd")
const Store = preload("res://scripts/save_store.gd")

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false # Check launcher behavior without writing any user file.
	root.add_child(scene)
	await process_frame
	var valid: bool = scene.validation_profile and scene.save_store.path == Store.new(Profile.SAVE_PATH).path and UI.text_in(scene.ui, "DATOS DE PRUEBA")
	scene.start_new_run(1)
	valid = valid and scene.game.shop_tables == Profile.tables() and scene.game.sticker_catalog == Profile.stickers() and scene.game.cash == 0
	print("VALIDATION PROFILE CLI: flag/banner/catalog/separate path/zero starting cash = ", valid)
	quit(0 if valid else 1)
