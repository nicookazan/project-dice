extends RefCounted
## Fase D de docs/PLAN-JEFES.md, por familias. Cada poder: solo durante el jefe, previsión = anotación,
## guardado a mitad de mano exacto, otro jefe no hereda el efecto y sorteos reproducibles.
const Boss = preload("res://scripts/boss_rules.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const SaveTests = preload("res://tests/save_tests.gd")
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
