extends SceneTree
const Store = preload("res://scripts/save_store.gd")
const Tests = preload("res://tests/save_tests.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

func _initialize() -> void:
	var service = Store.new("res://test-results/process-save/partida.json")
	if "--write" in OS.get_cmdline_user_args():
		var game = Game.new(300)
		game.roll()
		Fixture.set_results(game, [4, 4, 2, 2, 6])
		game.form_group([0, 1])
		game.move_die(4, "cup")
		if not service.start(Tests.payload(game)).ok:
			quit(1)
			return
		game.roll()
		var expected := FileAccess.open("res://test-results/process-save/expected.bin", FileAccess.WRITE)
		expected.store_var(game.snapshot())
		expected.close()
		print("PROCESS WRITE: checkpoint and expected next roll written; exiting")
		quit()
	else:
		var loaded: Dictionary = service.inspect()
		if not loaded.get("active", false):
			quit(1)
			return
		var game = service.restore_game(loaded.data)
		game.roll()
		var expected := FileAccess.open("res://test-results/process-save/expected.bin", FileAccess.READ)
		var same: bool = expected != null and expected.get_var() == game.snapshot()
		print("PROCESS READ: separate process restores exact next roll/RNG/state = ", same)
		print("DEFAULT USER PATH (test APPDATA): ", Store.new().path)
		quit(0 if same else 1)
