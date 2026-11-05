extends RefCounted
## MON4: Mano extra (C52). El encuentro pasa de 2 a 3 manos; pérdida, cobro, jefes, guardado y pantalla lo respetan.
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

const LOW = [1, 1, 1, 1, 1]
const PAIR = [2, 2, 3, 4, 6]
const UI_STATE = {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}

static func _payload(game) -> Dictionary:
	return {"game": game.snapshot(), "ui": UI_STATE.duplicate(true)}

## Anota manos bajas (sin llegar al objetivo) hasta quedar en la mano `n`, lista para jugarse.
static func _at_hand(game, n: int) -> void:
	for i in range(n - 1):
		Fixture.set_values(game, LOW)
		game.score_hand()
		game.next_hand()

## Anota una mano buena que alcanza el objetivo y cierra el encuentro, como en una partida.
static func _win(game) -> void:
	Fixture.set_values(game, PAIR)
	game.points = game.target() - 1
	game.score_hand()
	game.close_encounter()

static func _game(coins: Array, n := 1, seed_value := 41) -> Game:
	var game = Game.new(seed_value)
	game.passives = coins
	_at_hand(game, n)
	return game

static func run(check: Callable) -> void:
	_test_catalog(check)
	_test_limit_and_loss(check)
	_test_payout(check)
	_test_suspension(check)
	_test_bosses(check)
	_test_save(check)

static func _test_catalog(check: Callable) -> void:
	var data := Coins.definition("extra_hand")
	check.call(data.code == "C52" and data.rarity == "legendary" and data.type == "passive" and data.price == 14 and data.resale == 7, "C52 es una pasiva Legendaria de $14 / $7")
	check.call("extra_hand" in Coins.PASSIVES and "extra_hand" in CoinArt.NEW_IDS and Coins.SHORT.has("extra_hand"), "C52 está en el catálogo, tiene arte y abreviatura")
	check.call(Coins.catalog().size() == 65 and Coins.PASSIVES.size() == 57, "el catálogo pasa a 65 monedas (57 pasivas y 8 de un uso)")

static func _test_limit_and_loss(check: Callable) -> void:
	check.call(_game([]).hand_limit() == 2 and _game(["extra_hand"]).hand_limit() == 3, "C52 el límite pasa de 2 a 3 manos")
	var game := _game(["extra_hand"])
	Fixture.set_values(game, LOW)
	game.score_hand()
	check.call(game.phase == "hand_result" and game.next_hand() and game.hand == 2, "C52 la primera mano baja no pierde y deja pasar a la segunda")
	Fixture.set_values(game, LOW)
	game.score_hand()
	check.call(game.phase == "hand_result" and game.next_hand() and game.hand == 3, "C52 la segunda mano baja tampoco pierde y deja pasar a la tercera")
	Fixture.set_values(game, LOW)
	game.score_hand()
	check.call(game.phase == "lost" and game.hand_limit() == 3 and not game.next_hand(), "C52 se pierde recién al terminar la tercera mano")
	var plain := _game([], 2)
	Fixture.set_values(plain, LOW)
	plain.score_hand()
	check.call(plain.phase == "lost" and not plain.next_hand(), "sin la moneda se sigue perdiendo al terminar la segunda mano")
	var wins := _game(["extra_hand"], 3)
	_win(wins)
	check.call(wins.hand == 3 and wins.phase == "reward" and not wins.payout.is_empty(), "C52 se puede ganar y cerrar en la tercera mano")
	var third_plain = _game(["extra_hand"], 3)
	Fixture.set_values(third_plain, PAIR)
	third_plain.form_group([0, 1])
	var third_second = _game(["extra_hand", "second_hand"], 3)
	Fixture.set_values(third_second, PAIR)
	third_second.form_group([0, 1])
	check.call(third_plain.preview().total == third_second.preview().total, "C39 solo paga en la mano 2: en la tercera no cambia el puntaje")

static func _test_payout(check: Callable) -> void:
	var rows := {}
	for n in [1, 2, 3]:
		var game := _game(["extra_hand"], n)
		_win(game)
		rows[n] = game.payout.get("hands", -1)
	check.call(rows[1] == 4 and rows[2] == 2 and rows[3] == 0, "C52 cada mano sobrante paga $2: ganar en la primera paga $4, en la segunda $2 y en la tercera $0 (dio %s)" % str(rows))
	var plain := {}
	for n in [1, 2]:
		var game := _game([], n)
		_win(game)
		plain[n] = game.payout.get("hands", -1)
	check.call(plain[1] == 2 and plain[2] == 0, "sin la moneda el cobro por manos sobrantes no cambia (dio %s)" % str(plain))

static func _test_suspension(check: Callable) -> void:
	var game = CatalogTests.red_card_game(700, ["extra_hand"])
	check.call(game.boss_state.coin == "extra_hand" and game.hand_limit() == 2, "C52 expulsada por Tarjeta roja deja 2 manos")
	Fixture.set_values(game, LOW)
	game.score_hand()
	game.next_hand()
	Fixture.set_values(game, LOW)
	game.score_hand()
	check.call(game.phase == "lost" and game.hand == 2, "C52 expulsada: el jefe se pierde al terminar la segunda mano")
	var free = CatalogTests.red_card_game(700, ["extra_hand"])
	free.boss_state = {"coin": ""}
	check.call(free.hand_limit() == 3, "C52 sin expulsar vale también contra el jefe")

static func _test_bosses(check: Callable) -> void:
	# Ruleta del instante: la tercera mano repite la ruleta de la segunda (decisión 11).
	var clock = CatalogTests.forced_boss("l6_relojero", true, 5)
	clock.passives = ["extra_hand"]
	clock.hand = 2
	var second: float = Boss.hand_factor(clock.boss_context())
	clock.hand = 3
	check.call(clock.boss_state.has("roulette") and Boss.hand_factor(clock.boss_context()) == second and second != 1.0, "C52 la tercera mano repite la ruleta de la segunda")
	# Chamuyero: la memoria sigue siendo la de la mano 1 y vale en la tercera.
	var talker = CatalogTests.forced_boss("l2_chamuyero", true, 9)
	talker.passives = ["extra_hand"]
	Fixture.set_values(talker, PAIR)
	talker.form_group([0, 1])
	talker.score_hand()
	talker.next_hand()
	Fixture.set_values(talker, LOW)
	talker.score_hand()
	var remembered: Array = talker.boss_state.get("scored", [])
	check.call(talker.next_hand() and talker.hand == 3 and "Par" in remembered and Boss.repeat_factor(talker.boss_context(), "Par") == 0.5, "C52 Chamuyero recuerda la mano 1 también en la tercera mano")
	# Impuesto al kiosco: hasta $6 con tres manos, y el guardado lo acepta.
	var rule := {"kind": "boss_power", "target": "kiosk_tax"}
	check.call(Boss.valid_state(rule, {"tax": 6}, true) and not Boss.valid_state(rule, {"tax": 7}, true), "C52 el impuesto al kiosco admite hasta $6")
	var kiosk = CatalogTests.forced_boss("l1_kioskero", true, 11)
	kiosk.passives = ["extra_hand"]
	kiosk.cash = 50
	_at_hand(kiosk, 3)
	Fixture.set_values(kiosk, LOW)
	kiosk.score_hand()
	check.call(kiosk.boss_state.get("tax", 0) == 6 and kiosk.phase == "lost" and Validator.validate(_payload(kiosk)) == "", "C52 tres manos con el impuesto del Kioskero: $6 y el guardado valida (%s)" % Validator.validate(_payload(kiosk)))

static func _test_save(check: Callable) -> void:
	var third := _game(["extra_hand"], 3)
	check.call(third.hand == 3 and Validator.validate(_payload(third)) == "", "C52 un guardado en la tercera mano valida (%s)" % Validator.validate(_payload(third)))
	var lost := _game(["extra_hand"], 3)
	Fixture.set_values(lost, LOW)
	lost.score_hand()
	check.call(lost.phase == "lost" and Validator.validate(_payload(lost)) == "", "C52 un guardado perdido en la tercera mano valida (%s)" % Validator.validate(_payload(lost)))
	var early := _game(["extra_hand"], 2)
	Fixture.set_values(early, LOW)
	early.score_hand()
	early.phase = "lost"
	check.call(Validator.validate(_payload(early)) != "", "C52 perdido en la segunda mano con la moneda equipada es inconsistente")
	var no_coin := _game(["extra_hand"], 3)
	no_coin.passives = []
	check.call(Validator.validate(_payload(no_coin)) != "", "una tercera mano sin Mano extra en juego se rechaza")
	var red = CatalogTests.red_card_game(700, ["extra_hand"])
	red.hand = 3
	check.call(Validator.validate(_payload(red)) != "", "una tercera mano con Mano extra expulsada por el jefe se rechaza")
	# Vender la moneda en la tienda no invalida el guardado: la mano es solo un recuerdo del encuentro cerrado.
	var closed := _game(["extra_hand"], 3)
	_win(closed)
	closed.passives = []
	check.call(closed.phase == "reward" and closed.hand == 3 and Validator.validate(_payload(closed)) == "", "C52 vendida o perdida después de cerrar, el guardado sigue valiendo (%s)" % Validator.validate(_payload(closed)))

## Pantalla con la escena real: contador de manos y botón de la mano siguiente.
static func run_ui(scene, check: Callable) -> void:
	var previous = scene.game
	scene.detail.hide()
	scene.confirmation.hide()
	scene.game = _game(["extra_hand"])
	scene.render()
	check.call(UI.text_in(scene.ui, "Mano 1 / 3"), "C52 la libreta muestra Mano 1 / 3")
	Fixture.set_values(scene.game, LOW)
	scene.game.score_hand()
	scene.render()
	check.call(UI.find_button(scene.ui, "Jugar segunda mano") != null, "C52 tras la primera mano se ofrece jugar la segunda")
	scene.game.next_hand()
	Fixture.set_values(scene.game, LOW)
	scene.game.score_hand()
	scene.render()
	check.call(UI.find_button(scene.ui, "Jugar tercera mano") != null and UI.find_button(scene.ui, "Jugar segunda mano") == null, "C52 tras la segunda mano se ofrece jugar la tercera")
	scene.game.next_hand()
	scene.render()
	check.call(UI.text_in(scene.ui, "Mano 3 / 3"), "C52 la libreta muestra Mano 3 / 3")
	scene.game = _game([])
	scene.render()
	check.call(UI.text_in(scene.ui, "Mano 1 / 2"), "sin la moneda la libreta sigue mostrando Mano 1 / 2")
	scene.game = previous
	scene.render()
