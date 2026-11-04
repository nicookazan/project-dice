extends RefCounted
## Fase D de docs/PLAN-JEFES.md, por familias. Cada poder: solo durante el jefe, previsión = anotación,
## guardado a mitad de mano exacto, otro jefe no hereda el efecto y sorteos reproducibles.
const Boss = preload("res://scripts/boss_rules.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const Validator = preload("res://scripts/save_validator.gd")
const BossPanel = preload("res://tests/boss_panel_tests.gd")

static func prepared(id: String, at_boss: bool, values: Array, groups: Array):
	var game = BossPanel.forced_boss(id, at_boss)
	game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	game.cup.stickers = {"trio": 2}
	Fixture.set_values(game, values)
	for ids in groups: game.form_group(ids)
	return game

static func run(check: Callable) -> void:
	_suspensions(check)
	_forbidden_and_value(check)

static func _suspensions(check: Callable) -> void:
	# 2A Don Cebador: sin termo los stickers no aportan.
	var plain = prepared("l2_chamuyero", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	var thief = prepared("l2_cebador", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	var rival = prepared("l2_cebador", false, [3, 3, 3, 5, 2], [[0, 1, 2]])
	check.call(plain.preview().rows[0].has("sticker_effect") and rival.preview().rows[0].has("sticker_effect"), "Boss power Cebador: stickers count in a common rival and under a boss without the power")
	check.call(not thief.preview().rows[0].has("sticker_effect") and thief.preview().total < plain.preview().total, "Boss power Cebador: stolen thermos gives no sticker points")
	var forecast: int = thief.preview().total
	thief.score_hand()
	check.call(thief.last_score.total == forecast, "Boss power Cebador: forecast equals the final score")
	var mid = prepared("l2_cebador", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	check.call(SaveTests.roundtrip(mid, check).preview().total == mid.preview().total, "Boss power Cebador: saving mid-hand keeps the exact forecast")
	check.call(thief.cup.stickers == {"trio": 2}, "Boss power Cebador: stickers stay on the thermos, only suspended")
	# 3B El Conde Sed: fuego apagado.
	var fire_plain = prepared("l2_chamuyero", true, [5, 5, 5, 2, 3], [[0, 1, 2]])
	var fire_count = prepared("l3_conde", true, [5, 5, 5, 2, 3], [[0, 1, 2]])
	var fire_rival = prepared("l3_conde", false, [5, 5, 5, 2, 3], [[0, 1, 2]])
	for game in [fire_plain, fire_count, fire_rival]:
		game.dice[0].element = "fire"
		game.dice[1].element = "water"
	check.call(fire_rival.preview().rows[0].die_rows[0].element_effect.active and fire_plain.preview().rows[0].die_rows[0].element_effect.active, "Boss power Conde: fire counts outside the power")
	var fire_row: Dictionary = fire_count.preview().rows[0]
	check.call(not fire_row.die_rows[0].has("element_effect") and fire_row.die_rows[1].has("element_effect") and fire_count.preview().total < fire_plain.preview().total, "Boss power Conde: only fire is suspended, water keeps working")
	var fire_forecast: int = fire_count.preview().total
	fire_count.score_hand()
	check.call(fire_count.last_score.total == fire_forecast and fire_count.dice[0].element == "fire", "Boss power Conde: forecast equals score and the element stays on the die")
	# 6B Relojero (reemplazo Ruleta): multiplicador por mano, visible y guardado.
	var spin = prepared("l6_relojero", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	var fixed: Array = spin.boss_state.roulette.duplicate()
	check.call(fixed.size() == 2 and fixed.all(func(value): return value in [0.5, 1.5]), "Boss power Ruleta: two hand multipliers drawn on entry")
	var main_rng: int = spin.rng.state
	spin._refresh_boss_state()
	check.call(spin.boss_state.roulette == fixed and spin.rng.state == main_rng, "Boss power Ruleta: draw reproducible by seed without touching the main RNG")
	spin.boss_state = {"roulette": [0.5, 1.5]}
	var base = prepared("l2_chamuyero", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	var reference: float = base.preview().total
	check.call(abs(spin.preview().total - reference * 0.5) <= 1.0, "Boss power Ruleta: hand 1 multiplier x0.5 applies to the whole forecast")
	check.call("×0,5" in Boss.description(spin.boss_rule, spin.boss_state, spin.hand), "Boss power Ruleta: the multiplier is shown before rolling")
	var first_forecast: int = spin.preview().total
	spin.score_hand()
	check.call(spin.last_score.total == first_forecast, "Boss power Ruleta: forecast equals the final score")
	spin.next_hand()
	Fixture.set_values(spin, [3, 3, 3, 5, 2])
	spin.form_group([0, 1, 2])
	check.call(abs(spin.preview().total - reference * 1.5) <= 1.0 and "×1,5" in Boss.description(spin.boss_rule, spin.boss_state, spin.hand), "Boss power Ruleta: hand 2 uses its own multiplier")
	var saved = SaveTests.roundtrip(spin, check)
	check.call(saved.boss_state == spin.boss_state and saved.preview().total == spin.preview().total, "Boss power Ruleta: saved mid-boss without redrawing")
	var outside = prepared("l6_relojero", false, [3, 3, 3, 5, 2], [[0, 1, 2]])
	check.call(outside.boss_state.is_empty() and outside.preview().total == reference, "Boss power Ruleta: a common rival has no multiplier")
	var distinct := {}
	for seed_value in range(40):
		distinct[str(Boss.draw_state({"id": "l6_relojero", "name": "x", "kind": "boss_power", "target": "time_stop"}, seed_value, 5, 2, []).roulette)] = true
	check.call(distinct.size() >= 3, "Boss power Ruleta: outcomes vary with the seed")
	check.call(not Boss.valid_state(spin.boss_rule, {"roulette": [0.5, 2.0]}, true) and not Boss.valid_state(spin.boss_rule, {"roulette": [0.5]}, true), "Boss power Ruleta: invalid saved multipliers are rejected")

static func _forbidden_and_value(check: Callable) -> void:
	# 4B Patovica: Par y Doble par prohibidos.
	var club = BossPanel.forced_boss("l4_patovica", true)
	Fixture.set_values(club, [2, 2, 5, 5, 3])
	check.call(not club.form_group([0, 1]) and not club.form_group([0, 1, 2, 3]), "Boss power Patovica: pair and double pair are refused")
	check.call(club.form_group([0, 1, 4]) == false and club.groups.is_empty(), "Boss power Patovica: invalid selections stay invalid")
	Fixture.set_values(club, [4, 4, 4, 5, 3])
	check.call(club.form_group([0, 1, 2]), "Boss power Patovica: a trio is still allowed")
	var rival_club = BossPanel.forced_boss("l4_patovica", false)
	Fixture.set_values(rival_club, [2, 2, 5, 5, 3])
	check.call(rival_club.form_group([0, 1]), "Boss power Patovica: a common rival allows pairs")
	var tampered := SaveTests.payload(club)
	tampered.game.groups.append({"ids": [3, 4], "category": "Par", "locked": false})
	check.call(Validator.validate(tampered) != "", "Boss power Patovica: a saved pair under the boss is rejected")
	check.call(SaveTests.roundtrip(club, check).groups == club.groups, "Boss power Patovica: save keeps the allowed groups")
	# 3C Lobizón: las caras 6 valen 0 de cara, las combinaciones no cambian.
	var wolf = bare("l3_lobizon", true, [6, 6, 6, 2, 3], [[0, 1, 2]])
	var plain = bare("l2_chamuyero", true, [6, 6, 6, 2, 3], [[0, 1, 2]])
	check.call(plain.preview().rows[0].category == "Trío" and wolf.preview().rows[0].category == "Trío", "Boss power Lobizon: combinations do not change")
	check.call(plain.preview().total - wolf.preview().total == 18, "Boss power Lobizon: three sixes lose their 18 face points")
	var wolf_forecast: int = wolf.preview().total
	wolf.score_hand()
	check.call(wolf.last_score.total == wolf_forecast and wolf.last_score.rows[0].die_rows[0].points == 0.0, "Boss power Lobizon: forecast equals the score and shows 0 for a six")
	var wolf_five = bare("l3_lobizon", true, [5, 5, 5, 2, 3], [[0, 1, 2]])
	var plain_five = bare("l2_chamuyero", true, [5, 5, 5, 2, 3], [[0, 1, 2]])
	check.call(wolf_five.preview().total == plain_five.preview().total, "Boss power Lobizon: other faces are untouched")
	# 6A Horizonte: 5 y 6 valen la mitad de cara.
	var horizon = bare("l6_horizonte", true, [5, 6, 1, 2, 3], [])
	var horizon_plain = bare("l2_chamuyero", true, [5, 6, 1, 2, 3], [])
	check.call(horizon_plain.preview().total == 17 and horizon.preview().total == 12, "Boss power Horizonte: a five and a six lose half of their face (2.5 + 3)")
	var horizon_rival = bare("l6_horizonte", false, [5, 6, 1, 2, 3], [])
	check.call(horizon_rival.preview().total == horizon_plain.preview().total, "Boss power Horizonte: common rivals keep full faces")
	var horizon_forecast: int = horizon.preview().total
	horizon.score_hand()
	check.call(horizon.last_score.total == horizon_forecast, "Boss power Horizonte: forecast equals the final score")
	# 2B Chamuyero: repetir la categoría de la mano 1 en la mano 2 vale 50 %.
	var talker = prepared("l2_chamuyero", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	check.call(talker.boss_state == {"scored": []} and talker.boss_context().is_empty(), "Boss power Chamuyero: nothing remembered in hand 1")
	talker.score_hand()
	check.call(talker.boss_state == {"scored": ["Trío"]}, "Boss power Chamuyero: hand 1 categories are remembered")
	var memory: Dictionary = talker.boss_state.duplicate(true)
	talker.next_hand()
	Fixture.set_values(talker, [4, 4, 4, 1, 2])
	talker.form_group([0, 1, 2])
	var repeated: int = talker.preview().total
	var fresh = prepared("l4_tahur", true, [4, 4, 4, 1, 2], [[0, 1, 2]])
	fresh.hand = 2
	check.call(repeated < fresh.preview().total and talker.boss_state == memory, "Boss power Chamuyero: the repeated trio is worth less in hand 2")
	var reloaded = SaveTests.roundtrip(talker, check)
	check.call(reloaded.boss_state == memory and reloaded.preview().total == repeated, "Boss power Chamuyero: memory survives saving and loading")
	talker.score_hand()
	check.call(talker.last_score.total == repeated, "Boss power Chamuyero: forecast equals the final score")
	var different = prepared("l2_chamuyero", true, [3, 3, 3, 5, 2], [[0, 1, 2]])
	different.score_hand()
	different.next_hand()
	Fixture.set_values(different, [6, 6, 6, 6, 2])
	different.form_group([0, 1, 2, 3])
	check.call(different.groups[0].category == "Póker" and not Boss.repeat_factor(different.boss_context(), "Póker") < 1.0, "Boss power Chamuyero: a different category is not penalised")
	var reset = BossPanel.forced_boss("l2_chamuyero", true)
	check.call(reset.boss_state == {"scored": []}, "Boss power Chamuyero: a new encounter starts with no memory")

static func bare(id: String, at_boss: bool, values: Array, groups: Array):
	var game = prepared(id, at_boss, values, groups)
	game.cup.stickers = {}
	return game
