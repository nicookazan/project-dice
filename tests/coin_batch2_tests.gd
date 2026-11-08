extends RefCounted
## MON3: las cinco pasivas nuevas (C53-C57): Tirada de reserva, Cobrador, Veterano de nivel, Servida y Sobrantes.
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")

const NEW = ["reserve_roll", "collector", "level_veteran", "served", "leftovers"]
const PAIR = [2, 2, 3, 4, 6]

static func _hand(coins: Array, values: Array, groups: Array, setup: Callable = Callable()) -> Game:
	var game = Game.new(7)
	game.passives = coins
	Fixture.set_values(game, values)
	if setup.is_valid(): setup.call(game)
	for ids in groups: game.form_group(ids)
	return game

static func _total(coins: Array, values: Array, groups: Array, setup: Callable = Callable()) -> int:
	return _hand(coins, values, groups, setup).preview().total

static func run(check: Callable) -> void:
	_test_catalog(check)
	_test_reserve_roll(check)
	_test_served_and_veteran(check)
	_test_leftovers(check)
	_test_collector(check)
	_test_forecast_matches_score(check)
	_test_suspension(check)

static func _test_catalog(check: Callable) -> void:
	var codes := ["C53", "C54", "C55", "C56", "C57"]
	for i in range(NEW.size()):
		var data := Coins.definition(NEW[i])
		check.call(data.code == codes[i] and data.rarity == "rare" and data.type == "passive" and data.price == 6 and data.resale == 3, "MON3: %s es una pasiva Rara de $6 / $3" % NEW[i])
		check.call(NEW[i] in Coins.PASSIVES and NEW[i] in CoinArt.ALL_IDS and Coins.SHORT.has(NEW[i]), "MON3: %s está en el catálogo, tiene arte y abreviatura" % NEW[i])
	check.call(Coins.catalog().size() >= 64, "MON3: el catálogo incluye las cinco pasivas nuevas")

static func _test_reserve_roll(check: Callable) -> void:
	var game = Game.new(21)
	game.passives = ["reserve_roll"]
	game.start_hand()
	check.call(game.hand == 1 and game.rolls_left == 4, "C53 la primera mano empieza con 4 tiradas")
	game.hand = 2
	game.start_hand()
	check.call(game.rolls_left == 3, "C53 la segunda mano vuelve a 3 tiradas")
	game.hand = 1
	game._start_encounter()
	check.call(game.rolls_left == 4, "C53 se renueva en la primera mano de cada encuentro")
	game.passives = ["reserve_roll", "extra_roll_perm"]
	game.start_hand()
	check.call(game.rolls_left == 5, "C53 se suma a Tirada permanente (C20)")
	var unused = Game.new(22)
	unused.passives = ["reserve_roll", "unused_rolls"]
	unused.start_hand()
	Fixture.set_results(unused, PAIR)
	unused.rolls_made = 1
	unused.form_group([0, 1])
	var plain: int = _total(["reserve_roll"], PAIR, [[0, 1]], func(g): g.rolls_made = 1; g.rolls_left = 4)
	check.call(unused.rolls_left == 4 and unused.preview().total == plain + 20, "C53 la tirada extra también cuenta para Tiradas sin usar")

static func _test_served_and_veteran(check: Callable) -> void:
	var base := _total([], PAIR, [[0, 1]])
	var first := func(g): g.rolls_made = 1
	check.call(_total(["served"], PAIR, [[0, 1]], first) == base + 18, "C56 +2 mult en la primera tirada (+18 sobre un par de 9)")
	check.call(_total(["served"], PAIR, [[0, 1]]) == base, "C56 no suma después de relanzar")
	check.call(_total(["served", "first_roll"], PAIR, [[0, 1]], first) == base + 27, "C56 se acumula con Primera tirada: +3 mult")
	check.call(_total(["served"], PAIR, [], first) == _total([], PAIR, []), "C56 no toca a los sobrantes")
	var level1 := _total(["level_veteran"], PAIR, [[0, 1]])
	var level7 := _total(["level_veteran"], PAIR, [[0, 1]], func(g): g.level_index = 6)
	check.call(level1 == 24 and level7 == 38, "C55 +0,25 mult en el nivel 1 (24) y +1,75 en el nivel 7 (38); dio %d y %d" % [level1, level7])
	check.call(_total(["level_veteran"], PAIR, [], func(g): g.level_index = 6) == _total([], PAIR, []), "C55 no toca a los sobrantes")

static func _test_leftovers(check: Callable) -> void:
	var base := _total([], PAIR, [[0, 1]])
	check.call(_total(["leftovers"], PAIR, [[0, 1]]) == base + 6, "C57 tres dados sobrantes dan +6 puntos de mano")
	check.call(_total(["leftovers"], [3, 3, 3, 3, 3], [[0, 1, 2, 3, 4]]) == _total([], [3, 3, 3, 3, 3], [[0, 1, 2, 3, 4]]), "C57 da 0 con los cinco dados en combinación")
	check.call(_total(["leftovers"], PAIR, []) == _total([], PAIR, []) + 10, "C57 sin ningún grupo los cinco dados sobran (+10)")
	var four := [1, 2, 3, 4, 6]
	check.call(_total(["leftovers", "straight4"], four, [[0, 1, 2, 3]]) == _total(["straight4"], four, [[0, 1, 2, 3]]) + 2, "C57 con Escaleras de 4 cuenta el quinto dado")
	# El dado abducido no queda como sobrante.
	var ctx := {"id": "b", "name": "b", "kind": "abduct", "target": "4"}
	var with_coin := Rules.score(Fixture.dice_with_values(PAIR), [{"ids": [0, 1], "category": "Par", "locked": false}], ["leftovers"], [], false, {}, {}, {}, ctx, {})
	var without := Rules.score(Fixture.dice_with_values(PAIR), [{"ids": [0, 1], "category": "Par", "locked": false}], [], [], false, {}, {}, {}, ctx, {})
	check.call(with_coin.valid and without.valid and with_coin.total == without.total + 4, "C57 el dado abducido no cuenta (+4 por dos sobrantes)")
	var rows: Array = _hand(["leftovers"], PAIR, [[0, 1]]).preview().rows
	check.call(rows.any(func(row): return row.get("source", "") == "coin:leftovers"), "C57 aparece como su propia fila de puntos de mano")

## Anota una mano real y cierra el encuentro con el objetivo cumplido, como lo haría una partida.
static func _closed(coins: Array) -> Game:
	var game = Game.new(31)
	game.passives = coins
	Fixture.set_values(game, PAIR)
	game.form_group([0, 1])
	game.score_hand()
	game.points = game.target()
	game.close_encounter()
	return game

static func _test_collector(check: Callable) -> void:
	var with_coin := _closed(["collector"])
	var plain := _closed([])
	check.call(with_coin.phase in ["reward", "repair"] and plain.phase in ["reward", "repair"], "C54 el encuentro se cierra con y sin la moneda")
	check.call(with_coin.payout.get("coins", 0) == 1 and with_coin.payout.total == plain.payout.total + 1 and with_coin.cash == plain.cash + 1, "C54 suma $1 al cobro y a la plata")
	check.call(not plain.payout.has("coins"), "C54 sin la moneda el cobro no cambia")
	var data := {"game": with_coin.snapshot(), "ui": {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}}
	check.call(Validator.validate(data) == "", "C54 un guardado con el cobro extra valida (%s)" % Validator.validate(data))
	var legacy := {"game": plain.snapshot(), "ui": data.ui}
	check.call(Validator.validate(legacy) == "", "C54 un guardado sin el cobro extra sigue validando (%s)" % Validator.validate(legacy))

## Pantalla del cobro con la escena real: Cobrador aparece solo si pagó.
static func run_ui(scene, check: Callable, text_in: Callable) -> void:
	var previous = scene.game
	scene.detail.hide()
	scene.confirmation.hide()
	scene.game = _closed(["collector"])
	scene.render()
	check.call(scene.game.phase == "reward" and text_in.call(scene.ui, "Cobrador") and text_in.call(scene.ui, "TOTAL COBRADO: $%d" % scene.game.payout.total), "C54 la pantalla del cobro muestra la fila de Cobrador y el total")
	scene.game = _closed([])
	scene.render()
	check.call(scene.game.phase == "reward" and not text_in.call(scene.ui, "Cobrador") and text_in.call(scene.ui, "TOTAL COBRADO: $%d" % scene.game.payout.total), "C54 sin la moneda la pantalla del cobro no cambia")
	scene.game = previous
	scene.render()

static func _test_forecast_matches_score(check: Callable) -> void:
	for id in NEW:
		for first in [true, false]:
			var game = _hand([id], PAIR, [[0, 1]], func(g): g.level_index = 3; g.rolls_made = 1 if first else 2)
			var forecast: int = game.preview().total
			var before: int = game.points
			game.score_hand()
			check.call(game.last_score.total == forecast and game.points == before + forecast, "%s: la previsión coincide con la anotación (%s)" % [id, "primera tirada" if first else "relanzada"])

static func _test_suspension(check: Callable) -> void:
	# Todas las monedas nuevas suspendidas: puntaje liso.
	var ctx := {"id": "b", "name": "b", "kind": "suspend_coin", "target": "all"}
	var coins: Array = ["served", "level_veteran", "leftovers"]
	var plain := Rules.score(Fixture.dice_with_values(PAIR), [{"ids": [0, 1], "category": "Par", "locked": false}], [], [], false, {}, {}, {}, ctx, {"rolls_made": 1, "level": 7})
	var suspended := Rules.score(Fixture.dice_with_values(PAIR), [{"ids": [0, 1], "category": "Par", "locked": false}], coins, [], false, {}, {}, {}, ctx, {"rolls_made": 1, "level": 7})
	var live := Rules.score(Fixture.dice_with_values(PAIR), [{"ids": [0, 1], "category": "Par", "locked": false}], coins, [], false, {}, {}, {}, {}, {"rolls_made": 1, "level": 7})
	check.call(suspended.total == plain.total and live.total > plain.total, "MON3: una moneda suspendida por el jefe no aporta")
	# Tarjeta roja sobre una moneda de tiradas: C20 y C53 no dan tiradas; Cobrador no paga.
	for id in ["extra_roll_perm", "reserve_roll"]:
		var game = CatalogTests.red_card_game(700, [id])
		game.start_hand()
		check.call(game.boss_state.coin == id and game.rolls_left == 3, "MON3: %s expulsada por el jefe no da tiradas" % id)
		game.boss_state = {"coin": ""}
		game.start_hand()
		check.call(game.rolls_left == (4), "MON3: %s sin expulsar sí da la tirada extra" % id)
	var shut = CatalogTests.red_card_game(700, ["collector"])
	shut.points = shut.target()
	shut.phase = "hand_result"
	shut.close_encounter()
	check.call(shut.boss_state.coin == "collector" and not shut.payout.has("coins"), "MON3: Cobrador expulsada por el jefe no paga")
	var open = CatalogTests.red_card_game(700, ["collector"])
	open.boss_state = {"coin": ""}
	open.points = open.target()
	open.phase = "hand_result"
	open.close_encounter()
	check.call(open.payout.get("coins", 0) == 1, "MON3: Cobrador sin expulsar paga en el jefe")
