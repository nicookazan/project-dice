extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const StateTests = preload("res://tests/state_tests.gd")
const ScoringEventTests = preload("res://tests/scoring_event_tests.gd")
const NumberUpgradeTests = preload("res://tests/number_upgrade_tests.gd")
const NumberUpgrades = preload("res://scripts/number_upgrades.gd")
const MaterialTests = preload("res://tests/material_tests.gd")
const ElementTests = preload("res://tests/element_tests.gd")
const HandElementTests = preload("res://tests/hand_element_tests.gd")
const GemTests = preload("res://tests/gem_tests.gd")
const StickerTests = preload("res://tests/sticker_tests.gd")
const InterfaceTests = preload("res://tests/interface_tests.gd")
const LevelFlowTests = preload("res://tests/level_flow_tests.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const LevelValidationTests = preload("res://tests/level_validation_tests.gd")
const BossTests = preload("res://tests/boss_tests.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const PresentationTests = preload("res://tests/presentation_tests.gd")
const ShopStyleTests = preload("res://tests/shop_style_tests.gd")
const DiceArtTests = preload("res://tests/dice_art_tests.gd")
const DebugModeTests = preload("res://tests/debug_mode_tests.gd")
const DragGroupTests = preload("res://tests/drag_group_tests.gd")
const CoinDragTests = preload("res://tests/coin_drag_tests.gd")
const GlobalNumbersTests = preload("res://tests/global_numbers_tests.gd")
const PurchaseTests = preload("res://tests/purchase_tests.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const CoinTests = preload("res://tests/coin_tests.gd")
const RepairTests = preload("res://tests/repair_tests.gd")
var checks := 0
var failures: Array = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func set_values(game, values: Array) -> void:
	Fixture.set_values(game, values)

func find_button(node: Node, caption: String):
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var found = find_button(child, caption)
		if found != null: return found
	return null

func _initialize() -> void:
	test_double_pair()
	test_current_boundaries()
	var state_demo: Dictionary = StateTests.run(check)
	var scoring_events_demo: Dictionary = ScoringEventTests.run(check)
	var number_upgrades_demo: Dictionary = NumberUpgradeTests.run(check)
	var materials_demo: Dictionary = MaterialTests.run(check)
	var elements_demo: Dictionary = ElementTests.run(check)
	var hand_elements_demo: Dictionary = HandElementTests.run(check)
	var gems_demo: Dictionary = GemTests.run(check)
	var repairs_demo: Dictionary = RepairTests.run(check)
	var stickers_demo: Dictionary = StickerTests.run(check)
	var coins_demo: Dictionary = CoinTests.run(check)
	var shop_demo: Dictionary = ShopTests.run(check)
	var purchases_demo: Dictionary = PurchaseTests.run(check)
	check(Rules.category([1, 1]) == "Par", "exact pair")
	check(Rules.category([3, 3, 3]) == "Trío", "exact trio")
	check(Rules.category([6, 6, 6, 6]) == "Póker", "exact poker")
	check(Rules.category([4, 4, 4, 4, 4]) == "Generala", "exact generala")
	check(Rules.category([2, 2, 5, 5, 5]) == "Full", "full")
	for values in [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6], [3, 4, 5, 6, 1]]:
		check(Rules.category(values) == "Escalera", "straight " + str(values))
	check(Rules.category([1, 2, 2, 4, 5]) == "", "invalid straight")
	check(Rules.category([1, 1, 1, 6]) == "", "no implicit filler")
	var g = Game.new(42)
	check(g.cash == 0 and g.passives.is_empty() and g.consumable == "", "start empty, cash zero")
	check(g.dice.size() == 5 and g.rolls_left == 3 and g.hand == 1, "base dice/hands/rolls")
	check(not g.score_hand(), "cannot score unrolled dice")
	check(g.roll(), "first roll")
	var first_values: Array = g.dice.duplicate(true)
	var same = Game.new(42)
	same.roll()
	check(same.dice == first_values, "seed reproducible")
	check(not g.roll() and g.rolls_left == 2, "empty cup does not spend roll")
	set_values(g, [6, 6, 6, 2, 2])
	check(g.form_group([0, 1, 2]), "form trio")
	check(not g.form_group([0, 1, 2]), "no double use")
	check(not g.form_group([3, 3]), "no duplicate id")
	check(g.ungroup(0), "editable before commit")
	g.form_group([0, 1, 2])
	check(g.move_die(3, "cup"), "send loose die to cup")
	check(g.groups[0].locked, "sending to cup fixes group")
	g.move_die(3, "reserve")
	check(not g.ungroup(0), "removing from cup does not unlock groups")
	check(not g.move_die(0, "cup"), "cannot reroll fixed group")
	check(g.form_group([3, 4]), "pair with remaining dice")
	check(g.preview().total == 37, "trio 28 plus pair 9")
	var before: int = g.preview().total
	g.score_hand()
	check(g.last_score.total == before and g.points == before, "preview equals final")
	check(not g.score_hand() and g.points == before, "cannot score twice")
	check(g.next_hand() and g.hand == 2 and g.rolls_left == 3, "next hand resets rolls")
	check(g.groups.is_empty(), "groups reset each hand")
	# Small/large historical scoring fixtures do not change a live game's five dice.
	var loose_dice := Fixture.dice_with_values([1, 3, 6])
	var loose_score: Dictionary = Rules.score(loose_dice, [], [], false, false)
	check(loose_score.total == 10 and loose_score.rows.size() == 1, "one leftovers group")
	g.passives = ["even", "odd"]
	check(Rules.score(loose_dice, [], g.passives, false, false).total == 16, "parity applies to leftovers")
	g.consumable = "boost"
	check(g.use_consumable() and g.consumable == "", "consume boost")
	check(Rules.score(loose_dice, [], g.passives, g.boost, false).total == 22, "1 and 3 gain three each with parity")
	check(not g.use_consumable(), "cannot consume twice")
	var combo = Game.new(2)
	set_values(combo, [3, 3, 3, 5, 5])
	combo.form_group([0, 1, 2, 3, 4])
	combo.passives = ["full"]
	check(combo.preview().total == 98, "full (30+19) x2")
	combo.rolls_made = 1
	check(combo.preview().total == 108, "served full (35+19) x2")
	set_values(combo, [6, 6, 6, 6, 6])
	combo.groups = []
	combo.form_group([0, 1, 2, 3, 4])
	combo.passives = ["generala"]
	combo.rolls_made = 1
	check(combo.preview().total == 260, "served generala bonus before multiplier")
	combo.rolls_made = 2
	check(combo.preview().total == 160, "reroll removes served bonus")
	combo.rival = 2
	combo.groups = []
	check(not combo.form_group([0, 1, 2, 3, 4]), "boss prohibits generala")
	check(combo.form_group([0, 1, 2]) and combo.form_group([3, 4]), "boss allows trio plus pair")
	check(combo.preview().total == 45, "generala coin does not affect trio plus pair")
	var historical_groups := [{"ids": [0, 1, 2], "category": "Trío"}, {"ids": [3, 4, 5], "category": "Trío"}, {"ids": [6, 7], "category": "Par"}]
	check(Rules.score(Fixture.dice_with_values([6, 6, 6, 6, 6, 6, 2, 2]), historical_groups, [], false, false).total == 75, "two trios plus repeat10 plus pair9")
	var pairs := [{"ids": [0, 1], "category": "Par"}, {"ids": [2, 3], "category": "Par"}]
	check(Rules.score(Fixture.dice_with_values([2, 2, 3, 3]), pairs, [], false, false).total == 20, "pairs have no repeat bonus")
	for example in [[0, 0], [10, 2], [30, 4], [50, 5], [31, 4], [9, 1], [1000, 52]]:
		check(Rules.reward(example[0], 40, 40, 0).interest == example[1], "marginal interest " + str(example))
	check(Rules.reward(0, 55, 40, 1).total == 11, "agreed payout example")
	check(Rules.reward(0, 90, 40, 0).excess == 3, "excess capped")
	check(Rules.reward(0, 49, 40, 0).excess == 0, "only complete excess bands")
	# Complete the real three-encounter state machine, buying and using both consumables.
	var run = Game.new(123)
	for rival_index in range(3):
		check(run.rival == rival_index and run.points == 0, "next encounter resets points")
		if rival_index == 1:
			check(run.consumable == "boost" and run.use_consumable(), "bought boost available next encounter")
		if rival_index == 2:
			check(run.consumable == "roll" and run.use_consumable(), "bought extra roll available at boss")
			check(run.rolls_left == 4, "extra roll before initial throw")
		run.roll()
		set_values(run, [6, 6, 6, 6, 6])
		if rival_index < 2: run.form_group([0, 1, 2, 3, 4])
		else:
			run.form_group([0, 1, 2])
			run.form_group([3, 4])
		run.score_hand()
		if run.points < run.target():
			run.next_hand()
			set_values(run, [6, 6, 6, 6, 5])
			run.form_group([0, 1, 2, 3])
			run.score_hand()
		check(run.points >= run.target(), "encounter can be won")
		check(run.close_encounter(), "close win")
		var after_cash: int = run.cash
		check(not run.close_encounter() and run.cash == after_cash, "cannot collect twice")
		if rival_index == 2: break
		check(run.open_shop(), "open shop")
		check(not run.boost and run.renewal_price("coins") == 1, "encounter boost ends; renewal resets")
		run.offers = ["poker" if rival_index == 0 else "even", "boost" if rival_index == 0 else "roll"]
		var wallet: int = run.cash
		check(run.buy(0) and run.cash == wallet - 4 and run.offers[0] == "", "passive purchase empties offer")
		check(not run.buy(0), "cannot purchase empty slot")
		check(run.buy(1) and run.cash == wallet - 6, "consumable costs two")
		check(not run.use_consumable(), "consumable not valid in shop")
		run.cash += 10 # Test funding, never given in normal gameplay.
		wallet = run.cash
		check(run.refresh_shop() and run.cash == wallet - 1 and run.renewal_price("coins") == 2, "first renewal one")
		check(run.refresh_shop() and run.cash == wallet - 3 and run.renewal_price("coins") == 3, "second renewal two")
		check(run.offers[0] not in run.passives, "owned passives excluded without duplicate enabler")
		Fixture.set_coin_offer(run, 1, "roll")
		check(not run.buy(1), "occupied consumable slot blocks purchase")
		check(run.leave_shop(), "leave shop")
	check(run.phase == "won", "boss win ends prototype")
	run.restart(123)
	check(run.cash == 0 and run.passives.is_empty() and not run.boost and run.rival == 0, "restart resets run")
	var loss = Game.new(8)
	for i in range(2):
		set_values(loss, [1, 1, 1, 1, 1])
		loss.score_hand()
		if i == 0: loss.next_hand()
	check(loss.phase == "lost", "two low hands lose")
	check(not loss.next_hand() and not loss.close_encounter(), "loss cannot continue or collect")
	# Scene smoke check exercises all rendered screens with the actual UI.
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	scene.preferences_enabled = false
	scene.preferences.speed = 0
	root.add_child(scene)
	await process_frame
	check(scene.get_child_count() > 2, "scene instantiates")
	check(scene.game.phase == "menu" and find_button(scene, "Continuar") == null, "boot opens menu without fake continue")
	find_button(scene, "Nueva partida").pressed.emit()
	check(scene.game.phase == "level_intro", "new run opens level announcement")
	find_button(scene, "Empezar primer encuentro").pressed.emit()
	var throw_button = find_button(scene, "TIRAR (3)")
	check(throw_button != null and not throw_button.disabled, "initial throw button enabled")
	throw_button.pressed.emit()
	await process_frame
	check(scene.game.rolls_made == 1, "UI throw invokes actual state transition")
	set_values(scene.game, [6, 6, 6, 2, 2])
	scene.render()
	var die_buttons: Array = []
	collect_dice(scene.ui, die_buttons)
	for die_button in die_buttons:
		if die_button.die_index == 0:
			die_button.pressed.emit()
			break
	check(scene.selected == [0], "UI die click selects exact id")
	scene.selected = [0, 1, 2]
	scene.render()
	find_button(scene, "Armar grupo").pressed.emit()
	check(scene.game.groups.size() == 1, "UI creates group")
	var zone = find_zone(scene.ui, "cup")
	check(zone._can_drop_data(Vector2.ZERO, {"die": 3}), "cup accepts die drag data")
	zone._drop_data(Vector2.ZERO, {"die": 3})
	check(scene.game.dice[3].zone == "cup" and scene.game.groups[0].locked, "drop into cup commits group")
	find_zone(scene.ui, "reserve")._drop_data(Vector2.ZERO, {"die": 3})
	check(scene.game.dice[3].zone == "reserve" and scene.game.groups[0].locked, "drop back preserves lock")
	find_button(scene, "ANOTAR MANO").pressed.emit()
	check(scene.game.phase == "hand_result", "UI score hand")
	scene.game.restart(42)
	set_values(scene.game, [2, 2, 5, 5, 6])
	scene.selected = [0, 1, 2, 3]
	scene.render()
	find_button(scene, "Armar grupo").pressed.emit()
	check(scene.game.groups.size() == 1 and scene.game.groups[0].category == "Doble par", "UI forms double pair from four selected dice")
	var double_pair_row = find_button(scene, "Doble par  ·  29")
	check(double_pair_row != null, "notebook shows double pair subtotal")
	if double_pair_row != null:
		double_pair_row.pressed.emit()
		check("Base: 15" in scene.detail_text and "Total: 29" in scene.detail_text, "notebook explains double pair")
		scene.detail.hide()
	find_button(scene, "ANOTAR MANO").pressed.emit()
	check(scene.game.points == 35 and scene.game.last_score.total == 35, "UI scores double pair plus leftover exactly once")
	var fractional_row := Rules.resolve_group(0, 10.25, 0)
	fractional_row.merge({"category": "Par", "ids": [0, 1], "die_rows": []})
	scene.game.last_score = Rules.finish_score([fractional_row, fractional_row], false)
	scene.render()
	check(find_button(scene, "Par  ·  10.25") != null and scene.game.last_score.total == 21, "UI preserves fractional row totals before the rounded hand total")
	var factor_row := Rules.resolve_group(10, 0, 0, 2, [{"source": "fixture:add", "amount": 1}], [{"source": "fixture:factor", "amount": 1.5}])
	factor_row.merge({"category": "Trío", "ids": [], "die_rows": []})
	scene.show_detail(factor_row)
	check("Multiplicador del grupo: ×4.5" in scene.detail_text and "Total: 45" in scene.detail_text, "UI detail never truncates fractional multipliers")
	scene.detail.hide()
	scene.game.restart(42)
	set_values(scene.game, [4, 4, 1, 2, 3])
	NumberUpgrades.apply_global(scene.game.global_points, 4, 3)
	NumberUpgrades.apply_global(scene.game.global_points, 4, 12)
	scene.selected = [0, 1]
	scene.render()
	find_button(scene, "Armar grupo").pressed.emit()
	var improved_pair = find_button(scene, "Par  ·  43")
	check(improved_pair != null and scene.game.preview().total == 49, "UI shows globally improved pair of 43 plus six leftover points")
	if improved_pair != null:
		improved_pair.pressed.emit()
		check("Mejora global del 4" in scene.detail_text and "Mejora local" not in scene.detail_text, "UI names only global numeric sources")
		check(scene.game.preview().rows[0].die_rows.all(func(die): return die.points == 19), "UI gives both matching fours the same global improvement")
		scene.detail.hide()
	scene.game.restart(42)
	scene.game.dice[0].material = "steel"
	scene.game.dice[1].material = "copper"
	scene.game.roll()
	scene.game.move_die(1, "cup")
	scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 1, 2, 3])
	scene.game.form_group([0, 1])
	scene.render()
	var metal_pair = find_button(scene, "Par  ·  24")
	check(metal_pair != null and scene.game.preview().rows[0].multiplier == 1.5, "UI shows steel/copper pair with decimal multiplier")
	if metal_pair != null:
		metal_pair.pressed.emit()
		check("Acero · dado 1" in scene.detail_text and "Cobre · dado 2" in scene.detail_text and "×1.5" in scene.detail_text, "UI names each material source without truncating the multiplier")
		scene.detail.hide()
	var material_dice: Array = []
	collect_dice(scene.ui, material_dice)
	var has_steel_tooltip := false
	var has_copper_tooltip := false
	for material_die in material_dice:
		if material_die.die_index == 0: has_steel_tooltip = "Acero" in material_die.tooltip_text and "+3" in material_die.tooltip_text
		if material_die.die_index == 1: has_copper_tooltip = "Cobre" in material_die.tooltip_text and "+0.5" in material_die.tooltip_text
	check(has_steel_tooltip and has_copper_tooltip, "UI dice expose material gains and duration for inspection")
	scene.game.restart(42)
	scene.game.dice[0].element = "fire"
	scene.game.dice[1].element = "water"
	set_values(scene.game, [4, 4, 1, 2, 3])
	scene.game.form_group([0, 1])
	scene.render()
	var elemental_pair = find_button(scene, "Par  ·  18")
	check(elemental_pair != null, "UI shows fire gain only on the eligible four")
	if elemental_pair != null:
		elemental_pair.pressed.emit()
		check("Fuego · dado 1" in scene.detail_text and "Fuego · activo" in scene.detail_text, "UI identifies active elemental contribution")
		check("Agua · inactivo" in scene.detail_text and "La cara debe mostrar 1, 2 o 3." in scene.detail_text, "UI explains a wrong-face inactive element")
		scene.detail.hide()
	scene.game.ungroup(0)
	scene.render()
	find_button(scene, "Sin combinación  ·  14").pressed.emit()
	check("Requiere una combinación desde par." in scene.detail_text, "UI explains why loose fire/water do not activate")
	scene.detail.hide()
	var element_dice: Array = []
	collect_dice(scene.ui, element_dice)
	var fire_tooltip := false
	for element_die in element_dice:
		if element_die.die_index == 0: fire_tooltip = "Fuego" in element_die.tooltip_text and "no se gasta" in element_die.tooltip_text
	check(fire_tooltip, "UI element tooltip states condition, permanence and no consumption")
	scene.game.restart(42)
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].element = "earth"
	scene.game.dice[2].material = "copper"
	scene.game.dice[2].element = "wind"
	scene.game.roll()
	for iteration in range(2):
		scene.game.move_die(2, "cup")
		scene.game.roll()
	Fixture.set_results(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.form_group([2, 3])
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	check("Tierra · dado 1" in scene.detail_text and "Acero · dado 1" in scene.detail_text and "Total: 31" in scene.detail_text, "UI separates earth and steel point sources")
	scene.detail.hide()
	scene.show_detail(scene.game.preview().rows[1])
	check("Viento · dado 3" in scene.detail_text and "Cobre · dado 3" in scene.detail_text and "Total: 27" in scene.detail_text, "UI separates wind and copper multiplier sources")
	scene.detail.hide()
	var hand_dice: Array = []
	collect_dice(scene.ui, hand_dice)
	var earth_tip := false
	var wind_tip := false
	for die in hand_dice:
		if die.die_index == 0: earth_tip = "Tierra" in die.tooltip_text and "+12 puntos" in die.tooltip_text and "cada mano y al relanzarlo" in die.tooltip_text
		if die.die_index == 2: wind_tip = "Viento" in die.tooltip_text and "+1 al multiplicador" in die.tooltip_text and "cada mano" in die.tooltip_text
	check(earth_tip and wind_tip, "UI hand-element tooltips display accumulation and reset scope")
	scene.game.restart(73)
	for id in range(5): scene.game.dice[id].shell = ["emerald", "sapphire", "ruby", "diamond", "diamond"][id]
	Fixture.set_values(scene.game, [4, 4, 2, 2, 2])
	scene.game.form_group([0, 1, 2, 3, 4])
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	check("Esmeralda · dado 1" in scene.detail_text and "Zafiro · dado 2" in scene.detail_text and "Rubí · dado 3" in scene.detail_text, "UI identifies own factor, multiplier addition and multiplier factor from shells")
	check("Diamante · dado 4" in scene.detail_text and "Diamante · dado 5" in scene.detail_text and "Resultado original: 216" in scene.detail_text and "Total: 648" in scene.detail_text, "UI distinguishes original score and two final copies")
	scene.detail.hide()
	scene.game.dice[0].shell_broken = true
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	check("Esmeralda · inactivo: Carcasa resquebrajada" in scene.detail_text, "UI explains suspended broken shell")
	scene.detail.hide()
	var shell_dice: Array = []
	collect_dice(scene.ui, shell_dice)
	var shell_tip := false
	for die in shell_dice:
		if die.die_index == 0: shell_tip = "Esmeralda" in die.tooltip_text and "Resquebrajada" in die.tooltip_text and "combinación desde par" in die.tooltip_text
	check(shell_tip, "UI shell tooltip identifies power, condition and broken state")
	scene.game.restart(86)
	for id in range(4):
		scene.game.dice[id].shell = ["emerald", "ruby", "sapphire", "diamond"][id]
		scene.game.dice[id].shell_broken = true
	Fixture.set_values(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.points = scene.game.target()
	scene.game.cash = -20
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.render()
	check(find_button(scene, "Reparar selección · $0").disabled and find_button(scene, "Continuar sin reparar") != null, "UI repair offer starts with no selection and explicit free decline")
	find_button(scene, "Dado 1 · Esmeralda · $2").button_pressed = true
	find_button(scene, "Dado 4 · Diamante · $5").button_pressed = true
	check(scene.game.repair_quote(scene.repair_selection).cost == 7 and not find_button(scene, "Reparar selección · $7").disabled, "UI selected shells update displayed total to seven")
	var balance: int = scene.game.cash
	find_button(scene, "Reparar selección · $7").pressed.emit()
	check(scene.game.cash == balance - 7 and scene.game.cash < 0 and scene.game.phase == "reward" and not scene.game.dice[0].shell_broken and scene.game.dice[1].shell_broken, "UI confirms selected repairs with debt and preserves unselected damage")
	check(scene.repair_selection.is_empty() and find_button(scene, "Ir a la tienda →") != null, "UI confirmed repair clears selection and unlocks continuation")
	scene.game.restart(87)
	scene.game.rival = 2
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[0].shell_broken = true
	Fixture.set_values(scene.game, [4, 4, 2, 2, 6])
	scene.game.form_group([0, 1])
	scene.game.points = scene.game.target()
	scene.game.score_hand()
	scene.game.close_encounter()
	scene.render()
	balance = scene.game.cash
	find_button(scene, "Continuar sin reparar").pressed.emit()
	check(scene.game.phase == "won" and scene.game.cash == balance and scene.game.dice[0].shell_broken, "UI final boss decline reaches completed screen without charge")
	scene.game.restart(95)
	scene.game.sticker_catalog = StickerTests.definitions()
	scene.game.cup.stickers = {"trio": 2}
	Fixture.set_values(scene.game, [6, 6, 6, 2, 2])
	scene.game.form_group([0, 1, 2])
	scene.game.form_group([3, 4])
	scene.render()
	check(find_button(scene, "Trío  ·  68") != null and find_button(scene, "Par  ·  9") != null, "UI sticker affects only its category row")
	scene.show_detail(scene.game.preview().rows[0])
	check("Sticker · Trío · nivel 2: +6 puntos al grupo" in scene.detail_text and "Sticker · Trío" in scene.detail_text and "Total: 68" in scene.detail_text, "UI sticker breakdown explains level, group points and multiplier")
	scene.detail.hide()
	scene.game.restart(110)
	scene.game.passives = ["full", "straight", "generala", "poker", "even"]
	scene.game.consumable = "roll"
	scene.render()
	scene.inspect_coin("full")
	check("C01" in scene.detail_text and "Reventa: $2" in scene.detail_text, "UI coin inspection reads catalog identity and resale data")
	scene.detail.hide()
	scene.ui.get_node("ConsumableCoin").pressed.emit()
	check(scene.game.rolls_left == 4 and scene.game.consumable == "" and scene.game.coin_inventory.consumables.is_empty(), "UI consumes stored instance for extra roll before first throw")
	scene.game.phase = "shop"
	scene.game.cash = 100
	scene.game.offers = ["odd", "boost"]
	scene.render()
	check(find_button(scene, "$4").disabled and not find_button(scene, "$2").disabled, "UI full shared slots block passive but allow free consumable slot")
	find_button(scene, "$2").pressed.emit()
	check(scene.game.consumable == "boost" and scene.game.coin_inventory.consumables.size() == 1, "UI shop purchase creates one stored instance")
	scene.game = ShopTests.game_at_shop(130)
	scene.shop_section = "coins"
	scene.render()
	var stored_shop: Dictionary = scene.game.snapshot()
	find_button(scene, "Componentes").pressed.emit()
	check(scene.shop_section == "components" and scene.game.snapshot() == stored_shop, "UI switching sections never rerolls stored offers")
	scene.ui.get_node("Shop_components/Refresh").pressed.emit()
	check(scene.game.cash == 99 and scene.game.renewal_price("components") == 2 and scene.game.renewal_price("coins") == 1 and scene.game.shop_state.coins == stored_shop.shop_state.coins, "UI renews only chosen section and increments only its price")
	find_button(scene, "Monedas").pressed.emit()
	check("$1" in scene.ui.get_node("Shop_coins/Refresh").tooltip_text, "UI other sections retain their original renewal price")
	stored_shop = scene.game.snapshot()
	scene.render()
	scene.render()
	check(scene.game.snapshot() == stored_shop, "UI repeated shop rendering consumes no RNG or stock")
	scene.game = PurchaseTests.fixture("shell", {"id": "sapphire", "intact": true})
	scene.game.dice[1].material = "steel"
	scene.game.dice[1].shell = "ruby"
	scene.game.dice[1].element = "fire"
	scene.shop_section = "components"
	scene.render()
	find_button(scene, "$5").pressed.emit()
	check(scene.game.phase == "purchase_target" and scene.game.cash == 100 and find_button(scene, "Confirmar · $5").disabled, "UI purchase waits for a target without charge")
	scene.ui.get_node("PurchaseTarget/Die_1").pressed.emit()
	find_button(scene, "Cancelar compra").pressed.emit()
	check(scene.game.phase == "shop" and scene.game.cash == 100 and scene.game.shop_state.components.slots[0].offer_id == "fixture:1", "UI cancel leaves price and stock intact")
	find_button(scene, "$5").pressed.emit()
	scene.ui.get_node("PurchaseTarget/Die_1").pressed.emit()
	var confirm_button = find_button(scene, "Confirmar · $5")
	confirm_button.pressed.emit()
	confirm_button.pressed.emit()
	check(scene.game.cash == 95 and scene.game.dice[1].shell == "sapphire" and scene.game.dice[1].material == "steel" and scene.game.dice[1].element == "fire", "UI double confirmation applies only one replacement and one charge")
	scene.game = PurchaseTests.fixture("face", {"number": 4}, 4)
	scene.shop_section = "numbers"
	scene.purchase_error = ""
	scene.render()
	find_button(scene, "$4").pressed.emit()
	scene.ui.get_node("PurchaseTarget/Die_0").pressed.emit()
	check(find_button(scene, "Confirmar · $4").disabled, "UI face purchase requires selecting source position after die")
	scene.ui.get_node("PurchaseTarget/Face_1").pressed.emit()
	find_button(scene, "Confirmar · $4").pressed.emit()
	check(scene.game.dice[0].faces == [1, 4, 3, 4, 5, 6] and scene.game.cash == 96, "UI face selection applies offered number to exact chosen position")
	scene.game = PurchaseTests.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	scene.game.cup.stickers = {"trio": 2}
	scene.shop_section = "stickers"
	scene.render()
	find_button(scene, "$7").pressed.emit()
	check(scene.game.phase == "sticker_choice" and scene.game.cash == 93 and find_button(scene, "Trío · nivel 2 → 3") != null, "UI paid pack shows only its three persisted choices")
	var paid_pack: Dictionary = scene.game.snapshot()
	find_button(scene, "Cerrar panel").pressed.emit()
	find_button(scene, "Elegir sticker pendiente").pressed.emit()
	check(scene.game.snapshot() == paid_pack, "UI closing and reopening paid pack never charges or rerolls")
	find_button(scene, "Trío · nivel 2 → 3").pressed.emit()
	check(scene.game.cash == 93 and scene.game.cup.stickers == {"trio": 3} and scene.game.phase == "shop", "UI pack selection grants only chosen upgrade and returns to shop")
	var interface_demo: Dictionary = await InterfaceTests.run(scene, check)
	var level_flow_demo: Dictionary = LevelFlowTests.run(scene, check)
	var save_demo: Dictionary = SaveTests.run(scene, check)
	var level_validation_demo: Dictionary = LevelValidationTests.run(scene, check)
	var boss_demo: Dictionary = BossTests.run(scene, check)
	var campaign_demo: Dictionary = await CampaignTests.run(scene, check)
	var presentation_demo: Dictionary = PresentationTests.run(scene, check)
	var shop_style_demo: Dictionary = ShopStyleTests.run(scene, check)
	var dice_art_demo: Dictionary = DiceArtTests.run(scene, check)
	DebugModeTests.run(scene, check)
	DragGroupTests.run(scene, check)
	CoinDragTests.run(scene, check)
	GlobalNumbersTests.run(scene, check)
	for state in ["play", "hand_result", "reward", "shop", "won", "lost"]:
		scene.game.phase = state
		scene.game.last_score = {"total": 0, "rows": [], "served": false}
		scene.game.payout = Rules.reward(0, 55, 40, 1)
		scene.game.offers = ["full", "boost"]
		scene.render()
		await process_frame
	check(true, "all screen states render")
	scene.queue_free()
	await process_frame
	var report := {"checks": checks, "failures": failures, "passed": failures.is_empty(), "state_demo": state_demo, "scoring_events_demo": scoring_events_demo, "number_upgrades_demo": number_upgrades_demo, "materials_demo": materials_demo, "elements_demo": elements_demo, "hand_elements_demo": hand_elements_demo, "gems_demo": gems_demo, "repairs_demo": repairs_demo, "stickers_demo": stickers_demo, "coins_demo": coins_demo, "shop_demo": shop_demo, "purchases_demo": purchases_demo, "interface_demo": interface_demo, "level_flow_demo": level_flow_demo}
	DirAccess.make_dir_recursive_absolute("res://test-results")
	report["save_demo"] = save_demo
	report["level_validation_demo"] = level_validation_demo
	report["boss_demo"] = boss_demo
	report["campaign_demo"] = campaign_demo
	report["presentation_demo"] = presentation_demo
	report["shop_style_demo"] = shop_style_demo
	report["dice_art_demo"] = dice_art_demo
	var file := FileAccess.open("res://test-results/tests.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_double_pair() -> void:
	# Exhaust all 6^4 ordered results: exactly two distinct values, each twice.
	var mismatches := 0
	var matches := 0
	for a in range(1, 7):
		for b in range(1, 7):
			for c in range(1, 7):
				for d in range(1, 7):
					var values := [a, b, c, d]
					var expected: bool = a != b and ((a == c and b == d) or (a == d and b == c))
					expected = expected or (a == b and c == d and a != c)
					var actual: bool = Rules.category(values) == "Doble par"
					if expected != actual: mismatches += 1
					if actual: matches += 1
	check(mismatches == 0 and matches == 90, "all 1296 four-die selections classify double pair correctly")
	check(Rules.category([2, 2, 5, 5, 6]) == "", "double pair cannot absorb a fifth filler die")
	check(Rules.category([2, 2, 2, 5, 5]) == "Full", "five selected dice still classify full")
	var double_pair = Game.new(11)
	set_values(double_pair, [2, 2, 5, 5, 6])
	check(double_pair.form_group([3, 0, 2, 1]), "double pair accepts unordered selection")
	var forecast: Dictionary = double_pair.preview()
	check(forecast.rows.size() == 2 and forecast.rows[0].total == 29 and forecast.total == 35, "agreed double pair example 29 plus leftover six")
	check(forecast.rows[1].ids == [4], "only the fifth die remains outside double pair")
	check(not double_pair.form_group([0, 1]), "cannot reuse dice from double pair")
	double_pair.rolls_made = 1
	check(double_pair.preview().total == 35, "double pair has no invented served bonus")
	double_pair.passives = ["even", "odd"]
	check(double_pair.preview().total == 45, "parity adds two to all five dice without double counting")
	double_pair.passives = ["full", "poker", "generala", "straight"]
	check(double_pair.preview().total == 35, "other category coins do not multiply double pair")
	double_pair.passives = []
	check(double_pair.ungroup(0), "double pair editable before locking")
	check(double_pair.form_group([0, 1]) and double_pair.form_group([2, 3]), "two separate pairs remain an alternative")
	check(double_pair.preview().total == 30, "separate pairs have two bases of five and no repetition bonus")
	double_pair.restart(11)
	set_values(double_pair, [2, 2, 5, 5, 6])
	double_pair.rival = 2
	check(double_pair.form_group([0, 1, 2, 3]), "boss prohibition does not block double pair")
	double_pair.move_die(4, "cup")
	double_pair.move_die(4, "reserve")
	check(not double_pair.ungroup(0), "double pair stays locked after returning fifth die")
	var before: int = double_pair.preview().total
	double_pair.score_hand()
	check(double_pair.points == before and double_pair.last_score.total == before, "double pair forecast matches committed score")
	check(not double_pair.score_hand() and double_pair.points == before, "double pair cannot be credited twice")

func test_current_boundaries() -> void:
	for balance in [-100, -3, -1]:
		var reward: Dictionary = Rules.reward(balance, 40, 40, 0)
		check(reward.interest == 0 and reward.total == 8, "debt produces no negative interest: " + str(balance))
	check(-3 + Rules.reward(-3, 40, 40, 0).total == 5, "agreed debt example: minus three plus eight equals five")
	var game = Game.new(77)
	game.roll()
	var before: Array = game.dice.duplicate(true)
	check(not game.move_die(-1, "cup") and not game.move_die(5, "cup"), "out of range die ids rejected")
	check(game.dice == before, "invalid die movement leaves all five dice unchanged")

func collect_dice(node: Node, result: Array) -> void:
	if node is Button and node.get_script() == preload("res://scripts/die.gd"): result.append(node)
	for child in node.get_children(): collect_dice(child, result)

func find_zone(node: Node, destination: String):
	if node.get_script() == preload("res://scripts/drop_zone.gd") and node.destination == destination: return node
	for child in node.get_children():
		var found = find_zone(child, destination)
		if found != null: return found
	return null
