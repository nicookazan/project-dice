extends RefCounted
const Game = preload("res://scripts/game.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Store = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
const PurchaseRoute = preload("res://tests/level_validation_tests.gd")

static func reload_ui(scene, check: Callable, label: String) -> void:
	var before: Dictionary = scene.checkpoint_data()
	check.call(scene.save_error == "" and scene.save_store.inspect().get("active", false), "Campaign: valid durable checkpoint " + label + " / " + scene.save_error)
	if scene.save_error != "": return
	Flow.click(scene, "Volver al menú" if scene.game.phase == "level_intro" else "Guardar y volver al menú")
	check.call(Flow.click(scene, "Continuar") and scene.checkpoint_data() == before, "Campaign: exact UI resume " + label)

static func persistent_parts(game) -> Dictionary:
	var dice: Array = []
	for die in game.dice:
		dice.append({"id": die.id, "faces": die.faces.duplicate(), "material": die.material, "shell": die.shell, "shell_broken": die.shell_broken, "element": die.element})
	return {"dice": dice, "global": game.global_points.duplicate(), "cup": game.cup.duplicate(true), "coins": game.coin_inventory.duplicate(true), "cash": game.cash}

static func run(scene, check: Callable) -> Dictionary:
	var definitions: Array = Campaign.prototype()
	check.call(Campaign.valid(definitions) and definitions.size() == 7 and definitions.all(func(level): return level.candidates.size() == 3), "Campaign: seven levels, 18 alternatives plus three God rules")
	var first = Game.new(600)
	var same = Game.new(600)
	check.call(first.begin_campaign(600) and same.begin_campaign(600) and first.snapshot() == same.snapshot(), "Campaign: reproducible first boss chosen once at level entry")
	var fixed_targets: Array = first.level_encounters.duplicate(true)
	first.global_points = {"4": 9999}
	first.passives = ["even", "odd"]
	check.call(first.level_encounters == fixed_targets and first.campaign == definitions, "Campaign: inventory power never adapts fixed targets")
	var before: Dictionary = first.snapshot()
	check.call(not first.leave_shop() and not first.open_shop() and first.campaign_route().size() == 21 and first.snapshot() == before, "Campaign: route cannot skip or resample encounters")
	scene.detail.hide()
	scene.cancel_navigation()
	scene.validation_profile = false
	scene.campaign_mode = true
	scene.persistence_enabled = true
	scene.save_store = Store.new("res://test-results/campaign/" + str(Time.get_ticks_usec()) + "/partida.json")
	scene.start_new_run(600)
	check.call(scene.game.campaign.size() == 7 and scene.game.cash == 0 and scene.game.passives.is_empty(), "Campaign UI: default new run starts full provisional campaign with zero cash/coins")
	# Strong explicit laboratory build makes all 21 objectives reachable without measuring balance.
	scene.game.global_points = {"4": 250}
	scene.game.cash = 100
	scene.render()
	var trace: Array = []
	var comparisons: Array = []
	var level_boundaries := 0
	var repairs := 0
	for encounter in range(21):
		if scene.game.phase == "level_intro":
			check.call(UI.text_in(scene.ui, "NIVEL %d / 7" % (scene.game.level_index + 1)), "Campaign UI: announce level and boss before encounter")
			reload_ui(scene, check, "level announcement")
			Flow.click(scene, "Empezar primer encuentro")
		check.call(scene.game.level_index == int(encounter / 3) and scene.game.rival == encounter % 3, "Campaign: exact sequential encounter " + str(encounter + 1))
		var rule_before: Dictionary = scene.game.boss_rule.duplicate(true)
		var chosen_before: Dictionary = scene.game.selected_bosses.duplicate()
		Flow.click(scene, "TIRAR (3)")
		if encounter > 0:
			scene.toggle_die(1)
			Flow.click(scene, "Al vaso →")
			Flow.click(scene, "TIRAR (2)")
		Fixture.set_results(scene.game, [4, 4, 4, 4, 4])
		scene.render()
		var groups: Array = [[0, 1, 2], [3, 4]] if Boss.forbidden(scene.game.boss_context(), "Generala") else [[0, 1, 2, 3, 4]]
		for ids in groups:
			for id in ids: scene.toggle_die(id)
			Flow.click(scene, "Armar grupo")
		reload_ui(scene, check, "grouped hand " + str(encounter + 1))
		var expected: Dictionary = scene.game.preview()
		Flow.click(scene, "ANOTAR MANO")
		comparisons.append({"encounter": encounter + 1, "predicted": expected.total, "credited": scene.game.last_score.total})
		check.call(scene.game.last_score == expected and scene.game.points >= scene.game.target(), "Campaign: laboratory preview/credit exact and target met")
		var score_control = UI.find_button(scene.ui, "Cerrar y cobrar")
		score_control.pressed.emit()
		var paid: Dictionary = scene.game.snapshot()
		score_control.pressed.emit()
		check.call(scene.game.snapshot() == paid and scene.game.completed_encounters.size() == encounter + 1, "Campaign: reward/completion not duplicated by second click")
		trace.append({"level": scene.game.level_index + 1, "position": scene.game.rival + 1, "target": scene.game.target(), "boss_id": scene.game.selected_bosses[str(scene.game.level_index)], "points": scene.game.points, "payout": scene.game.payout.duplicate(true)})
		if scene.game.phase == "repair":
			repairs += 1
			var boxes: Array = scene.ui.find_children("*", "CheckBox", true, false)
			boxes[0].button_pressed = true
			reload_ui(scene, check, "selected repair")
			var quote: Dictionary = scene.game.repair_quote(scene.repair_selection)
			Flow.click(scene, "Reparar selección · $%d" % quote.cost)
		if encounter == 20: break
		check.call(scene.game.phase == "reward" and scene.save_store.inspect().active, "Campaign: each non-final victory reaches reward, not terminal win")
		reload_ui(scene, check, "paid encounter " + str(encounter + 1))
		Flow.click(scene, "Ir a la tienda →")
		if encounter == 0:
			PurchaseRoute.buy_controlled(scene, "face", "", check, 0, 0)
			PurchaseRoute.buy_controlled(scene, "global", "", check, 0)
			PurchaseRoute.buy_controlled(scene, "material", "steel", check, 0)
			PurchaseRoute.buy_controlled(scene, "element", "earth", check, 0)
			PurchaseRoute.buy_controlled(scene, "shell", "ruby", check, 0)
			PurchaseRoute.buy_controlled(scene, "sticker", "trio", check)
			PurchaseRoute.buy_controlled(scene, "coin", "even", check)
		reload_ui(scene, check, "generated shop " + str(encounter + 1))
		var gear := persistent_parts(scene.game)
		var uninterrupted = scene.save_store.restore_game(scene.checkpoint_data())
		uninterrupted.leave_shop()
		if scene.game.rival == 2:
			level_boundaries += 1
			Flow.click(scene, "Entrar al nivel %d →" % (scene.game.level_index + 2))
			check.call(scene.game.phase == "level_intro" and scene.game.points == 0 and scene.game.dice[0].encounter_effects.is_empty() and scene.game.dice[0].hand_effects.is_empty(), "Campaign: boss-to-level clears score/counters before new announcement")
			check.call(persistent_parts(scene.game) == gear and scene.game.selected_bosses.size() == scene.game.level_index + 1, "Campaign: faces/local/material/shell/element/coins/stickers/cash persist at boundary")
			check.call(scene.background.environment_id == scene.game.campaign[scene.game.level_index].environment, "Campaign UI: environment changes with new level")
		else:
			Flow.click(scene, "Ir al %s →" % ("jefe" if scene.game.rival == 1 else "siguiente rival"))
			check.call(scene.game.boss_rule == rule_before and scene.game.selected_bosses == chosen_before, "Campaign: normal advance keeps announced boss stable")
		check.call(scene.game.snapshot() == uninterrupted.snapshot(), "Campaign: next encounter/boss draw equals uninterrupted execution after reload")
		await scene.get_tree().process_frame
	check.call(scene.game.phase == "won" and scene.game.level_index == 6 and scene.game.rival == 2 and scene.game.completed_encounters.size() == 21, "Campaign: exactly 21 encounters and final God victory")
	check.call(level_boundaries == 6 and not scene.game.open_shop() and not scene.game.leave_shop() and not scene.game.has_next_encounter(), "Campaign: God closes version without level 8/store")
	check.call(not scene.save_store.inspect().active and UI.text_in(scene.ui, "DIOS SUPERADO"), "Campaign UI: final victory visible and cannot be resumed")
	for index in range(7):
		check.call(not Campaign.candidate(scene.game.campaign[index], scene.game.selected_bosses[str(index)]).is_empty(), "Campaign: selected boss belongs to own level pool " + str(index + 1))
	var losses: Array = _test_losses_and_migration(check)
	scene.persistence_enabled = false
	scene.campaign_mode = false
	scene.session_started = false
	return {"profile": Campaign.ID, "trace": trace, "comparisons": comparisons, "completed": 21, "level_boundaries": level_boundaries, "repairs": repairs, "losses": losses, "type": "controlled laboratory route, not balance evidence", "catalog_d07": "provisional", "save_version": Store.VERSION}

static func advance_model(definitions: Array, stop: int):
	var game = Game.new(601)
	game.begin_campaign(601, definitions)
	game.global_points = {"4": 250}
	for index in range(stop):
		if game.phase == "level_intro": game.begin_level()
		Fixture.set_values(game, [4, 4, 4, 4, 4])
		if Boss.forbidden(game.boss_context(), "Generala"):
			game.form_group([0, 1, 2])
			game.form_group([3, 4])
		else: game.form_group([0, 1, 2, 3, 4])
		game.score_hand()
		game.close_encounter()
		game.open_shop()
		game.leave_shop()
	if game.phase == "level_intro": game.begin_level()
	return game

static func _test_losses_and_migration(check: Callable) -> Array:
	var service = Store.new("res://test-results/campaign-loss/" + str(Time.get_ticks_usec()) + "/partida.json")
	var game = Game.new(601)
	game.begin_campaign(601)
	game.begin_level()
	for hand in range(2):
		Fixture.set_values(game, [1, 2, 2, 4, 6])
		game.score_hand()
		if hand == 0: game.next_hand()
	check.call(game.phase == "lost" and game.completed_encounters.is_empty() and not game.open_shop(), "Campaign: opening defeat does not complete encounter or open shop")
	var losses: Array = [{"level": 1, "position": 1, "completed": 0}]
	for stop in [10, 20]:
		var later = advance_model(Campaign.prototype(), stop)
		later.global_points = {}
		check.call(later.level_index == int(stop / 3) and later.rival == stop % 3 and later.completed_encounters.size() == stop, "Campaign: controlled prefix reaches later loss position without skips")
		for hand in range(2):
			Fixture.set_values(later, [1, 2, 2, 4, 6])
			later.score_hand()
			if hand == 0: later.next_hand()
		check.call(later.phase == "lost" and later.payout.is_empty() and later.completed_encounters.size() == stop and not later.open_shop() and not later.leave_shop(), "Campaign: defeat mid-campaign/against God grants no reward, advance or completion")
		check.call(Validator.validate(SaveTests.payload(later)) == "", "Campaign: later defeat remains a consistent terminal snapshot")
		losses.append({"level": later.level_index + 1, "position": later.rival + 1, "completed": later.completed_encounters.size()})
	var custom := Campaign.prototype()
	for candidate in custom[0].candidates: candidate.base_reward = 17
	var prize = advance_model(custom, 2)
	Fixture.set_values(prize, [4, 4, 4, 4, 4])
	if Boss.forbidden(prize.boss_context(), "Generala"):
		prize.form_group([0, 1, 2])
		prize.form_group([3, 4])
	else: prize.form_group([0, 1, 2, 3, 4])
	prize.score_hand()
	prize.close_encounter()
	check.call(prize.payout.base == 17, "Campaign: boss base reward comes from fixed definition, not hardcoded or power-adapted")
	var data := SaveTests.payload(Game.new(602))
	for key in ["campaign", "level_index", "selected_bosses", "completed_encounters"]: data.game.erase(key)
	var bytes := var_to_bytes(data)
	var text := JSON.stringify({"format": Store.FORMAT, "version": 2, "payload": Marshalls.raw_to_base64(bytes), "sha256": bytes.hex_encode().sha256_text()})
	DirAccess.make_dir_recursive_absolute(service.path.get_base_dir())
	service.write_text(service.path, text)
	var loaded: Dictionary = service.read_file(service.path)
	check.call(loaded.ok and loaded.data.game.campaign.is_empty() and FileAccess.get_file_as_string(service.path) == text, "Campaign: v2 legacy save migrates to short run without expanding or overwriting")
	var restored = service.restore_game(loaded.data)
	check.call(restored.snapshot() == Game.new(602).snapshot(), "Campaign: legacy short state preserved exactly")
	var before: Dictionary = restored.snapshot()
	var invalid := Campaign.prototype()
	invalid[0].candidates[0].target = -1
	check.call(not restored.begin_campaign(2, invalid) and restored.snapshot() == before, "Campaign: invalid campaign rejected without replacing live state")
	var inconsistent := SaveTests.payload(first_campaign_state())
	inconsistent.game.selected_bosses["0"] = "boss_from_another_level"
	check.call(Validator.validate(inconsistent) != "", "Campaign: wrong-level boss save rejected without resampling")
	inconsistent = SaveTests.payload(first_campaign_state())
	inconsistent.game.completed_encounters = ["skipped"]
	check.call(Validator.validate(inconsistent) != "", "Campaign: invalid completion path rejected instead of allowing skips")
	return losses

static func first_campaign_state():
	var game = Game.new(604)
	game.begin_campaign(604)
	return game
