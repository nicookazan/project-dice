extends RefCounted
const Store = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Purchases = preload("res://tests/purchase_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
static var serial := 0
static var folder := ""

static func store():
	serial += 1
	return Store.new(folder + "/case-" + str(serial) + ".json")

static func payload(game, repairs: Array = []) -> Dictionary:
	return {"game": game.snapshot(), "ui": {"selected": [], "repair_selection": repairs, "shop_section": "coins", "pack_panel_open": true}}

static func roundtrip(game, check: Callable, repairs: Array = []):
	var service = store()
	var data := payload(game, repairs)
	var reason: String = Validator.validate(data)
	check.call(reason == "", "Save: valid phase %s (%s)" % [game.phase, reason])
	var result: Dictionary = service.start(data)
	check.call(result.ok, "Save: real file write in phase " + game.phase)
	var loaded: Dictionary = service.inspect()
	check.call(loaded.ok and loaded.active, "Save: active validated checkpoint in phase " + game.phase)
	if not loaded.has("data"): return game
	var clone = service.restore_game(loaded.data)
	check.call(clone != null and clone.snapshot() == game.snapshot() and loaded.data.ui.repair_selection == repairs, "Save: exact phase/RNG/inventory/decisions roundtrip " + game.phase)
	return clone

static func shop_game(kind: String, effect: Dictionary):
	var game = Purchases.fixture(kind, effect)
	game.points = 60
	game.payout = Rules.reward(0, 60, 40, 1)
	return game

static func run(scene, check: Callable) -> Dictionary:
	folder = "res://test-results/save-cases/" + str(Time.get_ticks_usec())
	var intro = Game.new(200)
	intro.begin_run(200)
	roundtrip(intro, check)
	var game = Game.new(201)
	game.dice[0].material = "steel"
	game.dice[0].element = "earth"
	game.dice[1].material = "copper"
	game.dice[1].element = "wind"
	game.passives = ["even"]
	game.consumable = "boost"
	game.use_consumable()
	game.cash = -7
	game.roll()
	game.move_die(1, "cup")
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([0, 1])
	game.move_die(4, "cup")
	var clone = roundtrip(game, check)
	check.call(clone.groups[0].locked and clone.dice[4].zone == "cup" and clone.cash == -7 and clone.boost and clone.consumable == "", "Save: locked group, cup, debt and spent consumable preserved")
	check.call(clone.dice[0].encounter_effects == game.dice[0].encounter_effects and clone.dice[1].hand_effects == game.dice[1].hand_effects, "Save: steel/copper and earth/wind accumulations survive")
	game.roll()
	clone.roll()
	check.call(game.snapshot() == clone.snapshot(), "Save: next random roll and earned effects match uninterrupted execution")
	game.score_hand()
	clone = roundtrip(game, check)
	var before: Dictionary = clone.snapshot()
	check.call(not clone.score_hand() and clone.snapshot() == before, "Save: restored hand result cannot credit score or roll shell risk twice")

	var reward = Game.new(202)
	Fixture.set_values(reward, [6, 6, 6, 6, 6])
	reward.form_group([0, 1, 2, 3, 4])
	reward.score_hand()
	reward.close_encounter()
	clone = roundtrip(reward, check)
	before = clone.snapshot()
	check.call(not clone.close_encounter() and clone.snapshot() == before, "Save: restored payout never credits money twice")
	reward.open_shop()
	clone.open_shop()
	check.call(clone.snapshot() == reward.snapshot(), "Save: next shop offers/IDs/RNG equal uninterrupted execution")
	reward.purchase_offer("coins", reward.shop_state.coins.slots[0].offer_id)
	reward.refresh_shop("coins")
	clone = roundtrip(reward, check)
	before = clone.snapshot()
	check.call(not clone.open_shop() and not clone.generate_offers() and clone.snapshot() == before, "Save: restored shop keeps empty slots, purchases and renewal cost without regeneration")
	reward.refresh_shop("coins")
	clone.refresh_shop("coins")
	check.call(clone.snapshot() == reward.snapshot(), "Save: paid renewal after reload generates exact same offers")

	var repair = Game.new(203)
	repair.dice[0].shell = "diamond"
	repair.dice[0].shell_broken = true
	Fixture.set_values(repair, [6, 6, 6, 6, 6])
	repair.form_group([0, 1, 2, 3, 4])
	repair.score_hand()
	repair.close_encounter()
	clone = roundtrip(repair, check, [0])
	before = clone.snapshot()
	check.call(not clone.close_encounter() and clone.snapshot() == before and clone.repair_resolution.status == "pending", "Save: pending repairs restore after payout without paying twice")
	var cash: int = clone.cash
	check.call(clone.resolve_repairs([0]) and clone.cash == cash - 5 and not clone.resolve_repairs([0]), "Save: loaded repair selection is charged once")

	var risk = Game.new(204)
	risk.dice[0].shell = "ruby"
	Fixture.set_values(risk, [6, 6, 6, 6, 6])
	risk.form_group([0, 1, 2, 3, 4])
	risk.score_hand()
	clone = roundtrip(risk, check)
	check.call(clone.breakage_by_hand == risk.breakage_by_hand and clone.rng.state == risk.rng.state, "Save: exact post-risk draw and guard preserved")

	var target = shop_game("face", {"number": 4})
	target.begin_purchase("numbers", "fixture:1")
	target.set_purchase_target({"die_id": 2, "face_index": 1})
	clone = roundtrip(target, check)
	check.call(clone.confirm_purchase().ok and clone.dice[2].faces[1] == 4 and clone.cash == 95 and not clone.confirm_purchase().ok, "Save: restored die/face target applies purchase and payment only once")

	var pack = shop_game("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]})
	pack.purchase_offer("stickers", "fixture:1")
	clone = roundtrip(pack, check)
	check.call(clone.pending_sticker_pack.items == ["trio", "full", "pair_loose"] and clone.cash == 95 and clone.choose_sticker("trio") and not clone.choose_sticker("full") and clone.cash == 95, "Save: paid pack keeps candidates and grants choice exactly once")

	var exact = Game.new(0)
	exact.run_seed = 9223372036854775807
	exact.rng.seed = exact.run_seed
	exact.rng.state = -9223372036854775807
	clone = roundtrip(exact, check)
	exact.roll()
	clone.roll()
	check.call(clone.run_seed == 9223372036854775807 and clone.snapshot() == exact.snapshot(), "Save: int64 seed/RNG exceed JSON precision without losing any bits")

	_test_files(check)
	_test_invalid(check)
	_test_ui(scene, check)
	return {"version": Store.VERSION, "directory": folder, "exact_int64": true, "roundtrip_phases": ["level_intro", "play", "hand_result", "reward", "shop", "repair", "purchase_target", "sticker_choice"], "isolated_from_player": true}

static func _test_files(check: Callable) -> void:
	var legacy_service = store()
	var old_game = Game.new(209)
	var old_data := payload(old_game)
	old_data.game.erase("reroll_prices")
	old_data.game["reroll_price"] = 5
	var legacy_envelope: Dictionary = JSON.parse_string(legacy_service.encode(old_data))
	legacy_envelope.version = 3
	DirAccess.make_dir_recursive_absolute(legacy_service.path.get_base_dir())
	legacy_service.write_text(legacy_service.path, JSON.stringify(legacy_envelope))
	var migrated: Dictionary = legacy_service.inspect()
	check.call(migrated.ok and migrated.data.game == old_game.snapshot(), "Save: legacy shared renewal counter migrates to independent one-dollar counters without changing wallet, stock or RNG")
	var legacy_v4 := payload(old_game)
	legacy_v4.game.erase("debug_mode")
	var v4_envelope: Dictionary = JSON.parse_string(legacy_service.encode(legacy_v4))
	v4_envelope.version = 4
	legacy_service.write_text(legacy_service.path, JSON.stringify(v4_envelope))
	var v4_loaded: Dictionary = legacy_service.inspect()
	check.call(v4_loaded.ok and not v4_loaded.data.game.debug_mode and v4_loaded.data.game == old_game.snapshot(), "Save: version 4 migrates to normal mode without activating cheats or changing progress")
	var independent = shop_game("face", {"number": 4})
	independent.reroll_prices = {"coins": 4, "components": 2, "numbers": 3, "stickers": 1}
	var independent_clone = roundtrip(independent, check)
	check.call(independent_clone.reroll_prices == independent.reroll_prices, "Save: independent zone prices survive exact reload")
	var duplicated = shop_game("coin", {"coin_id": "full"})
	duplicated.passives = ["even"]
	duplicated.shop_state.coins.slots[1] = {"offer_id": "old:duplicate", "kind": "coin", "price": 4, "effect": {"coin_id": "full"}}
	duplicated.shop_state.coins.slots[2] = {"offer_id": "old:owned", "kind": "coin", "price": 4, "effect": {"coin_id": "even"}}
	var old_rng: int = duplicated.rng.state
	var repaired = legacy_service.restore_game(payload(duplicated))
	check.call(repaired != null and repaired.shop_state.coins.slots[0].effect.coin_id == "full" and repaired.shop_state.coins.slots[1].is_empty() and repaired.shop_state.coins.slots[2].is_empty() and repaired.rng.state == old_rng and repaired.cash == duplicated.cash, "Save: restoring old stock removes duplicate and owned passive offers without reroll or charge")
	var service = store()
	var game = Game.new(210)
	var first := payload(game)
	check.call(service.start(first).ok, "Save: initial publication succeeds on Windows")
	game.roll()
	var second := payload(game)
	check.call(service.save(second).ok and service.read_file(service.path).data == second and service.read_file(service.path + ".bak").data == first, "Save: atomic replacement preserves previous validated backup")
	game.move_die(0, "cup")
	for stage in ["before_write", "after_temp", "after_backup"]:
		service.fail_at = stage
		check.call(not service.save(payload(game)).ok and service.inspect().data == second, "Save: injected failure preserves recoverable last checkpoint: " + stage)
	service.fail_at = ""
	var original := "corrupt original"
	service.write_text(service.path, original)
	check.call(service.inspect().code == "backup" and service.inspect().active and FileAccess.get_file_as_string(service.path) == original, "Save: damaged primary offers backup without touching original")
	check.call(not service.save(payload(game)).ok and FileAccess.get_file_as_string(service.path) == original, "Save: automatic write cannot overwrite damaged sole evidence")
	check.call(service.recover().ok and service.inspect().data == second, "Save: explicit recovery publishes validated backup")
	var preserved := false
	for name in DirAccess.get_files_at(service.path.get_base_dir()):
		if name.begins_with(service.path.get_file() + ".preserved-") and FileAccess.get_file_as_string(service.path.get_base_dir().path_join(name)) == original: preserved = true
	check.call(preserved, "Save: recovery preserves original corrupt bytes as separate file")
	var future: Dictionary = JSON.parse_string(service.encode(second))
	future.version = 999
	var future_text := JSON.stringify(future)
	service.write_text(service.path, future_text)
	check.call(service.inspect().code == "version" and not service.inspect().active and not service.save(second).ok and FileAccess.get_file_as_string(service.path) == future_text, "Save: future version blocks continue/overwrite even with an older valid backup")
	check.call(service.start(first).ok and service.inspect().active, "Save: explicit new game archives incompatible previous files")
	for ending in ["won", "lost", "abandoned"]:
		check.call(service.close_session().ok and not service.inspect().active and service.inspect().code == "closed", "Save: closed marker prevents resurrection from primary or backup: " + ending)
		service.write_text(service.path, "damaged after terminal state")
		check.call(not service.inspect().active, "Save: corrupt terminal primary cannot resurrect earlier active backup: " + ending)
		service.start(first)
	DirAccess.remove_absolute(service.path)
	check.call(service.inspect().code == "backup" and service.recover().ok, "Save: interrupted publication missing primary recovers complete backup")
	var no_backup = store()
	DirAccess.make_dir_recursive_absolute(no_backup.path.get_base_dir())
	no_backup.write_text(no_backup.path, "{broken")
	check.call(not no_backup.inspect().active and no_backup.inspect().code == "invalid" and FileAccess.get_file_as_string(no_backup.path) == "{broken", "Save: corrupt sole file stays untouched and gives readable failure")
	var invalid_checksum: Dictionary = JSON.parse_string(service.encode(first))
	invalid_checksum.sha256 = "bad"
	no_backup.write_text(no_backup.path, JSON.stringify(invalid_checksum))
	check.call(no_backup.inspect().code == "checksum", "Save: checksum detects payload corruption")

static func _test_invalid(check: Callable) -> void:
	var good := payload(Game.new(220))
	for pair in [["phase", "mystery"], ["rival", 3], ["hand", 0], ["cash", "50"], ["rng_state", 1.5], ["rolls_left", -1], ["dice", []], ["coin_inventory", {}]]:
		var bad: Dictionary = good.duplicate(true)
		bad.game[pair[0]] = pair[1]
		check.call(Validator.validate(bad) != "", "Save: rejects malformed field " + str(pair[0]))
	var bad: Dictionary = good.duplicate(true)
	bad.game.dice[0].faces[0] = 99
	check.call(Validator.validate(bad) != "", "Save: rejects out-of-range face")
	bad = good.duplicate(true)
	bad.ui.repair_selection = [0]
	check.call(Validator.validate(bad) != "", "Save: rejects repair selection outside repair phase")
	bad = good.duplicate(true)
	bad.game.erase("breakage_by_hand")
	check.call(Validator.validate(bad) != "", "Save: rejects missing risk guard rather than regenerating defaults")
	bad = good.duplicate(true)
	bad.game.dice[0].hand_effects["earth_points"] = NAN
	check.call(Validator.validate(bad) != "", "Save: rejects nonfinite numeric state")

static func _test_ui(scene, check: Callable) -> void:
	scene.persistence_enabled = true
	scene.save_store = store()
	scene.game.return_to_menu()
	scene.session_started = false
	scene.refresh_save_status()
	scene.render()
	check.call(UI.find_button(scene.ui, "Continuar") == null, "Save UI: fresh menu hides continue")
	Flow.click(scene, "Nueva partida")
	check.call(scene.save_store.inspect().active and scene.save_store.inspect().data.game.phase == "level_intro", "Save UI: new game writes announcement checkpoint")
	Flow.click(scene, "Empezar primer encuentro")
	Flow.click(scene, "TIRAR (3)")
	var saved: Dictionary = scene.checkpoint_data()
	check.call(scene.save_store.inspect().data == saved, "Save UI: actual throw is saved after resolution")
	scene.render()
	check.call(scene.save_store.read_file(scene.save_store.path + ".bak").data.game.rolls_made == 0, "Save UI: redraw does not replace backup or write another checkpoint")
	Flow.click(scene, "Menú")
	check.call(scene.game.phase == "menu" and UI.find_button(scene.ui, "Continuar") != null, "Save UI: menu preserves active save and offers Continue")
	Flow.click(scene, "Continuar")
	check.call(scene.checkpoint_data() == saved, "Save UI: Continue restores exact phase without throwing again")
	scene.save_store.fail_at = "after_temp"
	scene.selected = [0]
	scene.render()
	check.call(scene.save_error != "" and UI.find_button(scene.ui, "Error al guardar · reintentar") != null, "Save UI: write failure is visible without losing live state")
	scene.save_store.fail_at = ""
	Flow.click(scene, "Error al guardar · reintentar")
	check.call(scene.save_error == "" and scene.save_store.inspect().data.ui.selected == [0], "Save UI: retry publishes current decision after failed write")
	Flow.click(scene, "Abandonar partida")
	scene.confirmation.get_cancel_button().pressed.emit()
	check.call(scene.save_store.inspect().active, "Save UI: cancel abandonment keeps resumable save")
	Flow.click(scene, "Abandonar partida")
	scene.confirmation.get_ok_button().pressed.emit()
	check.call(scene.game.phase == "menu" and not scene.save_store.inspect().active and UI.find_button(scene.ui, "Continuar") == null, "Save UI: confirmed abandonment closes save and hides Continue")
	# A second scene simulates closing/reopening the application, using the same isolated file.
	scene.start_new_run(221)
	Flow.click(scene, "Empezar primer encuentro")
	Flow.click(scene, "TIRAR (3)")
	saved = scene.checkpoint_data()
	var reopened = load("res://main.tscn").instantiate()
	reopened.save_store = scene.save_store
	scene.get_tree().root.add_child(reopened)
	check.call(reopened.game.phase == "menu" and UI.find_button(reopened.ui, "Continuar") != null, "Save UI: fresh app instance discovers checkpoint")
	Flow.click(reopened, "Continuar")
	check.call(reopened.checkpoint_data() == saved, "Save UI: app reopen resumes exact state")
	reopened.persistence_enabled = false
	reopened.queue_free()
	# Persist pending UI selections, not just model dictionaries.
	var repair = Game.new(222)
	repair.dice[0].shell = "ruby"
	repair.dice[0].shell_broken = true
	Fixture.set_values(repair, [6, 6, 6, 6, 6])
	repair.form_group([0, 1, 2, 3, 4])
	repair.score_hand()
	repair.close_encounter()
	scene.game = repair
	scene.last_checkpoint = {}
	scene.selected = []
	scene.render()
	var boxes: Array = scene.ui.find_children("*", "CheckBox", true, false)
	boxes[0].button_pressed = true
	check.call(scene.save_store.inspect().data.ui.repair_selection == [0], "Save UI: selecting a shell checkpoints pending repair choice without charging")
	Flow.click(scene, "Menú")
	Flow.click(scene, "Continuar")
	check.call(scene.repair_selection == [0] and UI.find_button(scene.ui, "Reparar selección · $3") != null, "Save UI: Continue restores selected repair and quoted total")
	Flow.click(scene, "Reparar selección · $3")
	check.call(scene.save_store.inspect().data.game.repair_resolution.status == "repaired" and not scene.game.dice[0].shell_broken, "Save UI: confirmed repair checkpoints resolved choice and exact payment")
	var pack = shop_game("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]})
	pack.purchase_offer("stickers", "fixture:1")
	scene.game = pack
	scene.repair_selection = []
	scene.render()
	Flow.click(scene, "Cerrar panel")
	saved = scene.checkpoint_data()
	Flow.click(scene, "Menú")
	Flow.click(scene, "Continuar")
	check.call(scene.checkpoint_data() == saved and not scene.pack_panel_open and scene.game.cash == 95, "Save UI: closed paid pack panel reopens without new candidates or payment")
	Flow.click(scene, "Elegir sticker pendiente")
	Flow.click(scene, "Trío · nivel 0 → 1")
	check.call(scene.save_store.inspect().data.game.cup.stickers == {"trio": 1} and scene.game.cash == 95, "Save UI: loaded pack choice is saved once")
	scene.start_new_run(3)
	Flow.click(scene, "Empezar primer encuentro")
	Flow.play_run(scene.game, scene)
	check.call(scene.game.phase == "won" and scene.save_error == "" and not scene.save_store.inspect().active, "Save UI: natural full run autosaves each transition and closes save at victory")
	Flow.click(scene, "Volver al menú")
	check.call(UI.find_button(scene.ui, "Continuar") == null, "Save UI: victory cannot be resumed from older active backup")
	scene.persistence_enabled = false
	scene.campaign_mode = false
	scene.save_error = ""
	scene.session_started = false
