extends RefCounted
const Game = preload("res://scripts/game.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Rules = preload("res://scripts/rules.gd")
const Store = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Flow = preload("res://tests/level_flow_tests.gd")

static func rule(kind: String, target: String) -> Dictionary:
	var names := {"steel": "Acero", "copper": "Cobre", "ruby": "Rubí", "even": "Pares", "roll": "Tirada extra", "all": "Familia completa"}
	var title := str(names.get(target, target)) + " suspendido"
	if kind == "suspend_coin": title = "Moneda " + str(names.get(target, target)) + " suspendida"
	if target == "all": title = {"suspend_material": "Metales suspendidos", "suspend_shell": "Carcasas suspendidas", "suspend_coin": "Monedas suspendidas"}[kind]
	return {"id": "test_" + kind + "_" + target, "name": title, "kind": kind, "target": target}

static func encounters(index := 2, target := 110) -> Array:
	var plan := Boss.default_encounters()
	plan[2].kind = "normal"
	plan[index].kind = "boss"
	plan[index].target = target
	return plan

static func game_for(definition: Dictionary, index := 2, target := 110):
	var game = Game.new(500)
	game.begin_run(500, encounters(index, target), [definition])
	game.begin_level()
	game.rival = index # Explicit fixture location; production advances only via shop.
	return game

static func run(scene, check: Callable) -> Dictionary:
	var banned = game_for(Boss.NONE, 1, 99)
	check.call(banned.is_boss() and banned.target() == 99 and banned.boss_rule.id == "sin_generala", "Boss: definition, encounter position and target are independent")
	Fixture.set_values(banned, [4, 4, 4, 4, 4])
	check.call(not banned.form_group([0, 1, 2, 3, 4]) and banned.form_group([0, 1, 2]) and banned.form_group([3, 4]), "Boss: non-final boss forbids generala but permits explicit trio+pair")
	var bad_group := [{"ids": [0, 1, 2, 3, 4], "category": "Generala", "locked": false}]
	check.call(not Rules.score(banned.dice, bad_group, [], false, false, {}, {}, {}, banned.boss_context()).valid, "Boss: pure scoring enforces prohibition even when groups bypass UI")
	banned.groups = bad_group
	var before: Dictionary = banned.snapshot()
	check.call(not banned.score_hand() and banned.points == 0 and banned.rng.state == before.rng_state and banned.breakage_by_hand.is_empty(), "Boss: authoritative annotation rejects injected prohibited group without points/risk")
	var normal = game_for(Boss.NONE, 1)
	normal.rival = 2
	Fixture.set_values(normal, [4, 4, 4, 4, 4])
	check.call(not normal.is_boss() and normal.form_group([0, 1, 2, 3, 4]) and normal.preview().valid, "Boss: last position alone no longer forbids generala")

	var pool: Array = [Boss.NONE, rule("suspend_coin", "even")]
	var chosen = Game.new(501)
	check.call(chosen.begin_run(501, Boss.default_encounters(), pool), "Boss: level entry accepts explicit candidate pool")
	var initial: Dictionary = chosen.snapshot()
	var copy = Game.new(501)
	copy.begin_run(501, Boss.default_encounters(), pool)
	check.call(copy.snapshot() == initial, "Boss: same seed chooses the same announced rule and RNG")
	var announcement: Dictionary = chosen.boss_rule.duplicate(true)
	for i in range(10): chosen.route()
	check.call(chosen.snapshot() == initial, "Boss: route inspection never draws another rule")
	chosen.begin_level()
	Fixture.set_values(chosen, [6, 6, 6, 6, 6])
	chosen.form_group([0, 1, 2, 3, 4])
	chosen.score_hand()
	chosen.close_encounter()
	chosen.open_shop()
	var service = Store.new("res://test-results/boss/" + str(Time.get_ticks_usec()) + "/checkpoint.json")
	check.call(service.start(SaveTests.payload(chosen)).ok, "Boss: selected rule persists through generated shop")
	var loaded: Dictionary = service.inspect()
	var resumed = service.restore_game(loaded.data)
	check.call(resumed.snapshot() == chosen.snapshot() and resumed.boss_rule == announcement, "Boss: loading shop preserves exact chosen definition and RNG")
	chosen.refresh_shop("coins")
	resumed.refresh_shop("coins")
	check.call(resumed.snapshot() == chosen.snapshot() and resumed.boss_rule == announcement, "Boss: renewal after load preserves rule and exact next stock")
	resumed.leave_shop()
	check.call(resumed.boss_context().is_empty() and resumed.boss_rule == announcement, "Boss: second normal rival keeps announcement without activating it")
	var valid_before: Dictionary = resumed.snapshot()
	check.call(not resumed.begin_run(5, [], [{"id": "bad"}]) and resumed.snapshot() == valid_before, "Boss: invalid new definition is rejected without resetting live game")

	var coin = game_for(rule("suspend_coin", "even"), 1, 12)
	coin.passives = ["even", "odd"]
	var inventory: Dictionary = coin.coin_inventory.duplicate(true)
	Fixture.set_values(coin, [4, 4, 1, 2, 3])
	coin.form_group([0, 1])
	var suspended_total: int = coin.preview().total
	check.call(suspended_total == 23 and coin.coin_inventory == inventory, "Boss: suspended even coin stays equipped; odd coin still contributes")
	coin.score_hand()
	coin.close_encounter()
	check.call(coin.phase == "reward" and coin.boss_context().is_empty() and coin.preview().total == 29 and coin.coin_inventory == inventory, "Boss: closing non-final boss immediately restores coin without replacing instances")
	coin.open_shop()
	coin.leave_shop()
	Fixture.set_values(coin, [4, 4, 1, 2, 3])
	coin.form_group([0, 1])
	check.call(coin.preview().total == 29 and coin.coin_inventory == inventory, "Boss: following encounter has restored equipment")
	var consumable = game_for(rule("suspend_coin", "roll"), 1, 12)
	consumable.consumable = "roll"
	before = consumable.snapshot()
	check.call(not consumable.use_consumable() and consumable.snapshot() == before, "Boss: suspended consumable cannot be spent or grant rolls")
	check.call(Boss.cooldown_can_advance(consumable.boss_context(), "future_active"), "Boss: future active recharge contract stays enabled during suspension")

	var metal = game_for(rule("suspend_material", "all"))
	metal.dice[0].material = "steel"
	metal.dice[1].material = "copper"
	metal.dice[0].element = "earth"
	metal.dice[1].element = "wind"
	metal.dice[0].encounter_effects.steel_points = 6.0
	metal.dice[1].encounter_effects.copper_multiplier = 1.5
	metal.roll()
	metal.move_die(1, "cup")
	metal.roll()
	check.call(metal.dice[0].encounter_effects.steel_points == 6.0 and metal.dice[1].encounter_effects.copper_multiplier == 1.5, "Boss: suspended steel/copper neither accumulate nor erase counters just for suspension")
	check.call(metal.dice[0].hand_effects.earth_points > 0 and metal.dice[1].hand_effects.wind_multiplier == 0.5, "Boss: suspending material preserves independent earth/wind gains")
	metal.move_die(0, "cup")
	metal.roll()
	check.call(metal.dice[0].encounter_effects.steel_points == 0.0, "Boss: steel own-reroll reset still occurs while suspended")
	Fixture.set_results(metal, [4, 4, 2, 2, 6])
	metal.form_group([0, 1])
	var row: Dictionary = metal.preview().rows[0]
	check.call(row.multiplier == 1.5, "Boss: copper bonus is suppressed while wind remains active")
	metal.score_hand()
	metal.next_hand()
	check.call(metal.dice[0].hand_effects.is_empty() and metal.dice[1].hand_effects.is_empty() and metal.dice[1].encounter_effects.copper_multiplier == 1.5, "Boss: hand resets remain separate from encounter counters")
	metal._start_encounter()
	check.call(metal.dice[0].encounter_effects.is_empty() and metal.dice[1].encounter_effects.is_empty() and metal.dice[0].material == "steel", "Boss: normal encounter reset clears counters but retains suspended pieces")

	var shells = game_for(rule("suspend_shell", "all"))
	for i in range(4): shells.dice[i].shell = ["emerald", "sapphire", "ruby", "diamond"][i]
	Fixture.set_values(shells, [4, 4, 4, 2, 2])
	shells.form_group([0, 1, 2])
	shells.form_group([3, 4])
	var score: Dictionary = shells.preview()
	check.call(score.total == 31 and score.rows[0].die_rows[0].shell_effect.active == false, "Boss: all four shell powers suppressed with explicit inactive detail")
	var rng_before: int = shells.rng.state
	shells.score_hand()
	check.call(shells.rng.state == rng_before and shells.breakage_by_hand["1"].is_empty() and shells.dice.all(func(die): return not die.shell_broken), "Boss: complete shell suspension performs no risk draws and preserves shells")
	var saved: Dictionary = shells.snapshot()
	check.call(not shells.score_hand() and shells.snapshot() == saved, "Boss: suspended hand cannot repeat scoring or risk")
	var single = game_for(rule("suspend_shell", "ruby"))
	single.dice[0].shell = "ruby"
	single.dice[1].shell = "diamond"
	Fixture.set_values(single, [4, 4, 4, 2, 2])
	single.form_group([0, 1, 2])
	single.form_group([3, 4])
	single.score_hand()
	check.call(single.breakage_by_hand["1"].size() == 1 and single.breakage_by_hand["1"][0].id == 1, "Boss: targeted shell suspension leaves other shells' powers and risks intact")
	var restored_shells = game_for(rule("suspend_shell", "all"), 1, 1)
	restored_shells.dice[0].shell = "ruby"
	restored_shells.dice[1].shell = "diamond"
	restored_shells.dice[1].shell_broken = true
	Fixture.set_values(restored_shells, [4, 4, 4, 2, 2])
	restored_shells.form_group([0, 1, 2])
	restored_shells.form_group([3, 4])
	restored_shells.score_hand()
	restored_shells.close_encounter()
	check.call(restored_shells.phase == "repair" and restored_shells.boss_context().is_empty() and restored_shells.preview().total == 42, "Boss: shell powers restore after closure even before optional repairs")
	check.call(restored_shells.dice[0].shell == "ruby" and not restored_shells.dice[0].shell_broken and restored_shells.dice[1].shell_broken, "Boss: suspension neither breaks intact shells nor repairs old broken shells")
	restored_shells.resolve_repairs([])
	restored_shells.open_shop()
	restored_shells.leave_shop()
	Fixture.set_values(restored_shells, [4, 4, 4, 2, 2])
	restored_shells.form_group([0, 1, 2])
	restored_shells.form_group([3, 4])
	restored_shells.score_hand()
	check.call(restored_shells.breakage_by_hand["1"].size() == 1 and restored_shells.breakage_by_hand["1"][0].id == 0, "Boss: normal shell risk resumes next encounter, old broken shell stays inactive")
	var transition = game_for(Boss.NONE, 1, 12)
	transition.rival = 0
	Fixture.set_values(transition, [6, 6, 6, 6, 6])
	transition.form_group([0, 1, 2, 3, 4])
	transition.score_hand()
	transition.close_encounter()
	transition.open_shop()
	var announcement_before: Dictionary = transition.boss_rule.duplicate(true)
	transition.leave_shop()
	check.call(transition.is_boss() and not transition.boss_context().is_empty() and transition.boss_rule == announcement_before, "Boss: shop advance activates exactly the previously announced boss")
	var clone = service.restore_game(SaveTests.payload(transition))
	check.call(clone.boss_context() == transition.boss_context() and clone.snapshot() == transition.snapshot(), "Boss: direct restore reconstructs active boss context without redraw")
	_test_migration(service, check)
	_test_ui(scene, check)
	return {"rules": [Boss.NONE, rule("suspend_coin", "even"), rule("suspend_material", "all"), rule("suspend_shell", "all")], "d09": "user chose complete suspension, normal resets remain", "save_version": Store.VERSION, "legacy_v1": "migrated without RNG draws", "production_pool": [Boss.NONE.id], "catalog_d07": "pending"}

static func _test_migration(service, check: Callable) -> void:
	var legacy = Game.new(502)
	legacy.roll()
	legacy.move_die(0, "cup")
	var data := SaveTests.payload(legacy)
	data.game.erase("boss_rule")
	data.game.erase("level_encounters")
	for key in ["campaign", "level_index", "selected_bosses", "completed_encounters"]: data.game.erase(key)
	var bytes := var_to_bytes(data)
	var content := JSON.stringify({"format": Store.FORMAT, "version": 1, "payload": Marshalls.raw_to_base64(bytes), "sha256": bytes.hex_encode().sha256_text()})
	service.write_text(service.path, content)
	var migrated: Dictionary = service.read_file(service.path)
	check.call(migrated.ok and FileAccess.get_file_as_string(service.path) == content, "Boss: legacy v1 migrates in memory without overwriting original")
	var restored = service.restore_game(migrated.data)
	check.call(restored.snapshot() == legacy.snapshot(), "Boss: legacy migration adds only known default rule/layout, preserving exact state")
	legacy.roll()
	restored.roll()
	check.call(restored.snapshot() == legacy.snapshot(), "Boss: migration preserves exact next random roll")
	check.call(service.save(SaveTests.payload(restored)).ok and JSON.parse_string(FileAccess.get_file_as_string(service.path)).version == Store.VERSION and FileAccess.get_file_as_string(service.path + ".bak") == content, "Boss: first new checkpoint publishes v2 and preserves original v1 as backup")
	var bad: Dictionary = SaveTests.payload(restored)
	bad.game.boss_rule.target = "unknown"
	check.call(Validator.validate(bad) != "", "Boss: unknown saved rule is rejected instead of replaced/resampled")

static func _test_ui(scene, check: Callable) -> void:
	scene.persistence_enabled = false
	scene.campaign_mode = false
	scene.validation_profile = false
	scene.detail.hide()
	scene.game = game_for(rule("suspend_coin", "even"), 1)
	scene.game.passives = ["even"]
	scene.game.consumable = "roll"
	scene.render()
	scene.show_route()
	check.call("Moneda Pares suspendida" in scene.detail_text and "Generala prohibida" not in scene.detail_text, "Boss UI: route consults actual chosen rule without stale generala claim")
	scene.detail.hide()
	scene.inspect_coin("even")
	check.call("SUSPENDIDA POR JEFE" in scene.detail_text, "Boss UI: equipped coin inspection exposes temporary suspension")
	scene.detail.hide()
	scene.game = game_for(rule("suspend_coin", "roll"))
	scene.game.consumable = "roll"
	scene.render()
	check.call(scene.ui.get_node("ConsumableCoin").disabled, "Boss UI: suspended consumable is visibly disabled")
	scene.game = game_for(rule("suspend_shell", "ruby"))
	scene.game.dice[0].shell = "ruby"
	scene.render()
	scene.inspect_die(0)
	check.call("sin poder ni sorteos de rotura" in scene.detail_text, "Boss UI: shell inspection explains risk suppression")
	scene.detail.hide()
	scene.game.begin_run(503, Boss.default_encounters(), [rule("suspend_coin", "even")])
	scene.render()
	check.call(UI.text_in(scene.ui, "MONEDA PARES SUSPENDIDA"), "Boss UI: selected rule announced before first encounter")
	scene.game = game_for(Boss.NONE, 1, 12)
	scene.game.rival = 0
	Fixture.set_values(scene.game, [6, 6, 6, 6, 6])
	scene.game.form_group([0, 1, 2, 3, 4])
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.game.open_shop()
	scene.render()
	check.call(UI.find_button(scene.ui, "Ir al jefe →") != null, "Boss UI: shop names next encounter from data even with boss at second position")
	Flow.click(scene, "Ir al jefe →")
	check.call(scene.game.is_boss() and Boss.forbidden(scene.game.boss_context(), "Generala"), "Boss UI: real shop control activates the data-defined boss")
