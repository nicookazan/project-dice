extends RefCounted
## Saltar a otro nivel desde el menú de la partida (08/11/2026): adelante y atrás, con el guardado coherente.
const Game = preload("res://scripts/game.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Validator = preload("res://scripts/save_validator.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

static func run(scene, check: Callable) -> void:
	# Reglas del juego.
	var game = Game.new(611)
	game.begin_campaign(611)
	game.begin_level()
	game.cash = 37
	game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	game.cup.stickers = {"trio": 2}
	var dice_before: Array = game.dice.duplicate(true)
	check.call(game.jump_to_level(6), "Level jump: from level 1 you can go straight to level 7")
	check.call(game.level_index == 6 and game.rival == 0 and game.phase == "level_intro" and game.environment_id() == "cielo", "Level jump: you land on the first rival of the chosen level, at its presentation")
	check.call(game.cash == 37 and game.cup.stickers == {"trio": 2} and game.dice.size() == 5 and game.dice[0].faces == dice_before[0].faces, "Level jump: money, dice and stickers are kept")
	check.call(game.selected_bosses.size() == 7 and game.completed_encounters.size() == 18 and Campaign.valid_progress(game.snapshot()), "Level jump: skipped levels get their boss and count as passed, so the progress stays consistent")
	check.call(Validator.validate(SaveTests.payload(game)) == "", "Level jump: the save after jumping forward is valid")
	var restored = SaveTests.roundtrip(game, check)
	check.call(restored != null and restored.level_index == 6 and restored.completed_encounters == game.completed_encounters, "Level jump: saving and loading keeps the chosen level")
	check.call(game.jump_to_level(2), "Level jump: you can also go back")
	check.call(game.level_index == 2 and game.selected_bosses.size() == 3 and game.completed_encounters.size() == 6 and Validator.validate(SaveTests.payload(game)) == "", "Level jump: going back forgets the later levels and the save stays valid")
	game.begin_level()
	game.phase = "purchase_target"
	check.call(not game.can_jump_to_level(4) and not game.jump_to_level(4) and game.level_index == 2, "Level jump: blocked with a pending purchase")
	game.phase = "play"
	check.call(not game.jump_to_level(7) and not game.jump_to_level(-1), "Level jump: levels outside the campaign are rejected")
	var trial = Game.new(612)
	trial.begin_run(612)
	check.call(not trial.can_jump_to_level(0), "Level jump: the single test level has no level jump")
	# Interfaz: menú de la partida -> Ir a otro nivel -> Nivel 7.
	scene.game = CampaignTests.advance_model(Campaign.prototype(), 0)
	scene.render()
	scene.show_game_menu()
	var jump: Button = scene.ui.get_node("GameMenu").find_child("JumpLevel", true, false)
	check.call(jump != null and not jump.disabled, "Level jump: the game menu offers Ir a otro nivel during a campaign")
	jump.pressed.emit()
	var picker: Node = scene.ui.get_node_or_null("LevelPicker")
	var level7: Button = picker.find_child("Level_7", true, false) if picker != null else null
	check.call(level7 != null and not level7.disabled and picker.find_child("Level_1", true, false) != null, "Level jump: the picker lists the seven levels")
	level7.pressed.emit()
	check.call(scene.game.level_index == 6 and scene.game.phase == "level_intro" and scene.ui.get_node_or_null("LevelPicker") == null and UI.find_button(scene.ui, "Empezar primer encuentro") != null, "Level jump: picking level 7 shows its presentation")
	scene.show_game_menu()
	scene.ui.get_node("GameMenu").find_child("JumpLevel", true, false).pressed.emit()
	check.call(scene.ui.get_node("LevelPicker").find_child("Level_7", true, false).disabled, "Level jump: the level you are about to start cannot be picked again")
	scene.close_game_menu()
	var trial_scene = Game.new(613)
	trial_scene.begin_run(613)
	scene.game = trial_scene
	scene.render()
	scene.show_game_menu()
	check.call(scene.ui.get_node("GameMenu").find_child("JumpLevel", true, false) == null, "Level jump: not offered in the single test level")
	scene.close_game_menu()
