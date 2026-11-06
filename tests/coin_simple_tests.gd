extends RefCounted
## MON5: siete monedas de un uso simples (U10, U11, U13, U15, U16, U17, U18), sin elegir objetivo.
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")

const PAIR = [2, 2, 3, 4, 6]
const UI_STATE = {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}
## [id, código, rareza, precio, reventa, contexto de uso]
const TABLE = [
	["mult_plus2", "U10", "rare", 3, 1, "play"], ["points_bag", "U11", "common", 2, 1, "play"], ["two_rolls", "U13", "epic", 5, 2, "play"],
	["quick_cash", "U15", "common", 2, 1, "play"], ["visit_discount", "U16", "rare", 3, 1, "shop"], ["repair_all", "U17", "epic", 5, 2, "repair"],
	["even_boost", "U18", "common", 2, 1, "play"]]

static func _payload(game) -> Dictionary:
	return {"game": game.snapshot(), "ui": UI_STATE.duplicate(true)}

## Mano con un par de 2 formado y las monedas de un uso pedidas en la mochila.
static func _hand(coins: Array, passives: Array = []) -> Game:
	var game = Game.new(33)
	game.passives = passives
	for id in coins:
		game.coin_instance_sequence += 1
		game.coin_inventory.consumables.append(Coins.instance(id, game.coin_instance_sequence))
	Fixture.set_values(game, PAIR)
	game.form_group([0, 1])
	return game

static func _use(game, id: String) -> bool:
	return game.use_consumable(Coins.ids(game.coin_inventory.consumables).find(id))

static func _row(score: Dictionary, category: String) -> Dictionary:
	for row in score.rows:
		if row.category == category: return row
	return {}

## Cierra un encuentro ganado desde la mano 1 para llegar a la fase de recompensa o reparación.
static func _closed(game) -> void:
	game.phase = "hand_result"
	game.points = 999
	game.last_score = {"total": 999, "rows": [], "served": false, "valid": true}
	game.close_encounter()

static func run(check: Callable) -> void:
	_test_catalog(check)
	_test_mult_plus2(check)
	_test_points_bag(check)
	_test_rolls_and_cash(check)
	_test_visit_discount(check)
	_test_repair_all(check)
	_test_even_boost(check)
	_test_save(check)

static func _test_catalog(check: Callable) -> void:
	for row in TABLE:
		var data := Coins.definition(row[0])
		check.call(data.code == row[1] and data.rarity == row[2] and data.type == "consumable" and data.price == row[3] and data.resale == row[4] and data.use_contexts == [row[5]], "MON5: %s es %s, $%d / $%d y se usa en %s" % [row[0], row[2], row[3], row[4], row[5]])
		check.call(row[0] in Coins.CONSUMABLES and row[0] in CoinArt.NEW_IDS and Coins.SHORT.has(row[0]), "MON5: %s está en el catálogo, tiene arte y abreviatura" % row[0])
	check.call(Coins.catalog().size() == 72 and Coins.CONSUMABLES.size() == 15, "MON5: el catálogo pasa a 72 monedas (15 de un uso)")

static func _test_mult_plus2(check: Callable) -> void:
	var base: int = _hand([]).preview().total
	var plus = _hand(["mult_plus2"])
	var mult_before: float = plus.preview().rows[0].multiplier_sum
	check.call(_use(plus, "mult_plus2") and plus.hand_mult_bonus == 2 and plus.coin_inventory.consumables.is_empty(), "U10 se usa, queda activa y se consume")
	var boosted: Dictionary = plus.preview()
	check.call(boosted.rows[0].multiplier_sum == mult_before + 2.0 and boosted.total > base, "U10 suma 2 al multiplicador de la combinación")
	# Se acumula: dos monedas suman 4.
	var twice = _hand(["mult_plus2", "mult_plus2"])
	_use(twice, "mult_plus2")
	_use(twice, "mult_plus2")
	check.call(twice.hand_mult_bonus == 4 and twice.preview().rows[0].multiplier_sum == mult_before + 4.0, "U10 se acumula")
	# Va antes de Doble mult: (m+2)×2, no 2m+2.
	var doubled = _hand(["double_mult"])
	_use(doubled, "double_mult")
	var both = _hand(["double_mult", "mult_plus2"])
	_use(both, "mult_plus2")
	_use(both, "double_mult")
	var only_plus = _hand(["mult_plus2"])
	_use(only_plus, "mult_plus2")
	check.call(both.preview().rows[0].total == only_plus.preview().rows[0].total * 2 and both.preview().rows[0].total > doubled.preview().rows[0].total, "U10 se suma antes de Doble mult")
	# No aplica a los sobrantes.
	var left: Dictionary = _row(boosted, "Sin combinación")
	var left_base: Dictionary = _row(_hand([]).preview(), "Sin combinación")
	check.call(not left.is_empty() and left.total == left_base.total, "U10 no toca los dados sobrantes")
	# Previsión = anotación, y termina con la mano.
	var forecast: int = plus.preview().total
	check.call(plus.score_hand() and plus.last_score.total == forecast, "U10 la previsión coincide con la anotación")
	check.call(plus.hand_mult_bonus == 0, "U10 termina al anotar la mano")
	var next = _hand(["mult_plus2"])
	_use(next, "mult_plus2")
	next.start_hand()
	check.call(next.hand_mult_bonus == 0, "U10 también se limpia al empezar una mano")

static func _test_points_bag(check: Callable) -> void:
	var base: int = _hand([]).preview().total
	var bag = _hand(["points_bag"])
	check.call(_use(bag, "points_bag") and bag.hand_points_bonus == 20 and bag.coin_inventory.consumables.is_empty(), "U11 se usa, queda activa y se consume")
	var with_bag: Dictionary = bag.preview()
	check.call(with_bag.total == base + 20 and not _row(with_bag, "Moneda · Bolsa de puntos").is_empty(), "U11 suma 20 puntos planos en su propia fila")
	var big = _hand(["points_bag", "mult_plus2", "double_mult"])
	_use(big, "mult_plus2")
	_use(big, "double_mult")
	var plain: int = big.preview().total
	_use(big, "points_bag")
	check.call(big.preview().total == plain + 20, "U11 no se multiplica por Mult +2 ni Doble mult")
	var twice = _hand(["points_bag", "points_bag"])
	_use(twice, "points_bag")
	_use(twice, "points_bag")
	check.call(twice.hand_points_bonus == 40 and twice.preview().total == base + 40, "U11 se acumula")
	var forecast: int = bag.preview().total
	check.call(bag.score_hand() and bag.last_score.total == forecast and bag.hand_points_bonus == 0, "U11 la previsión coincide con la anotación y termina con la mano")

static func _test_rolls_and_cash(check: Callable) -> void:
	var rolls = _hand(["two_rolls"])
	var before: int = rolls.rolls_left
	check.call(_use(rolls, "two_rolls") and rolls.rolls_left == before + 2 and rolls.coin_inventory.consumables.is_empty(), "U13 suma dos tiradas a la mano actual")
	check.call("2 tiradas adicionales" in rolls.message, "U13 el mensaje sale del valor")
	var single = _hand(["roll"])
	_use(single, "roll")
	check.call(single.message == "Una tirada adicional disponible en esta mano.", "U02 conserva su mensaje en singular")
	var cash = _hand(["quick_cash"])
	var money: int = cash.cash
	check.call(_use(cash, "quick_cash") and cash.cash == money + 5 and cash.coin_inventory.consumables.is_empty(), "U15 suma $5 durante el encuentro")
	var shop = _hand(["quick_cash"])
	shop.phase = "shop"
	check.call(not _use(shop, "quick_cash") and shop.cash == money and shop.coin_inventory.consumables.size() == 1, "U15 no se usa en la tienda y no se consume")

static func _shop(coins: Array, passives: Array = []) -> Game:
	var game = Game.new(44)
	game.passives = passives
	for id in coins:
		game.coin_instance_sequence += 1
		game.coin_inventory.consumables.append(Coins.instance(id, game.coin_instance_sequence))
	_closed(game)
	game.open_shop()
	return game

static func _test_visit_discount(check: Callable) -> void:
	var game = _shop(["visit_discount"])
	check.call(game.visit_discount == 0.0 and game.offer_price(10) == 10, "U16 sin usar no cambia los precios")
	check.call(_use(game, "visit_discount") and game.visit_discount == 0.5 and game.offer_price(10) == 5, "U16 baja los precios un 50 %")
	check.call(game.coin_inventory.consumables.is_empty(), "U16 se consume al usarla")
	var renewal: int = game.renewal_price("coins")
	var plain = _shop([])
	check.call(renewal <= plain.renewal_price("coins"), "U16 también alcanza a las renovaciones")
	# Se multiplica con Descuento (C45) y se redondea una sola vez: 6 × 0,8 × 0,5 = 2,4 → 2.
	var both = _shop(["visit_discount"], ["discount"])
	_use(both, "visit_discount")
	check.call(both.offer_price(6) == 2 and both.offer_price(10) == 4, "U16 se multiplica con Descuento y se redondea una sola vez (dio %d)" % both.offer_price(6))
	check.call(CoinEffects.discounted(6, ["discount"]) == 5 and CoinEffects.discounted(6, []) == 6, "C45 sola no cambia con el parámetro nuevo")
	# No se usa dos veces en la misma visita.
	var twice = _shop(["visit_discount", "visit_discount"])
	_use(twice, "visit_discount")
	check.call(not _use(twice, "visit_discount") and twice.coin_inventory.consumables.size() == 1, "U16 no se apila dentro de la misma visita")
	# Termina con la visita.
	game.phase = "reward"
	game.open_shop()
	check.call(game.visit_discount == 0.0 and game.offer_price(10) == 10, "U16 termina al abrir la próxima tienda")
	var fuera = _hand(["visit_discount"])
	check.call(not _use(fuera, "visit_discount") and fuera.visit_discount == 0.0, "U16 solo se usa en la tienda")

static func _broken_game(coins: Array) -> Game:
	var game = Game.new(41)
	for id in coins:
		game.coin_instance_sequence += 1
		game.coin_inventory.consumables.append(Coins.instance(id, game.coin_instance_sequence))
	game.dice[0].shell = "diamond"
	game.dice[0].shell_broken = true
	game.dice[1].shell = "ruby"
	game.dice[1].shell_broken = true
	_closed(game)
	return game

static func _test_repair_all(check: Callable) -> void:
	var game = _broken_game(["repair_all"])
	check.call(game.phase == "repair" and game.repair_resolution.available_ids.size() == 2, "U17 hay dos carcasas rotas en la fase de reparación")
	var cash: int = game.cash
	check.call(_use(game, "repair_all"), "U17 se usa en la fase de reparación")
	check.call(not game.dice[0].shell_broken and not game.dice[1].shell_broken and game.cash == cash, "U17 repara todas sin cobrar")
	check.call(game.phase in ["reward", "won"] and game.repair_resolution.status == "repaired" and game.repair_resolution.cost == 0, "U17 deja la fase destrabada y registrada")
	check.call(game.coin_inventory.consumables.is_empty() and game.open_shop(), "U17 se consume y la partida sigue a la tienda")
	var outside = _hand(["repair_all"])
	check.call(not _use(outside, "repair_all") and outside.coin_inventory.consumables.size() == 1, "U17 solo se usa en la reparación")
	var gem = _broken_game(["repair_gem", "repair_all"])
	check.call(_use(gem, "repair_gem") and _use(gem, "repair_all") and gem.phase in ["reward", "won"], "U17 convive con Reparar gema (U07)")
	check.call(Validator.validate(_payload(_broken_game(["repair_all"]))) == "", "U17 una reparación pendiente con la moneda guardada valida")

static func _test_even_boost(check: Callable) -> void:
	var base: int = _hand([]).preview().total
	var game = _hand(["even_boost"])
	check.call(_use(game, "even_boost") and "even_boost" in game.impulses and game.coin_inventory.consumables.is_empty(), "U18 se usa y queda como impulso activo")
	check.call("cada 2, 4 y 6 suma +2" in game.message and not "2 y 4 y 6" in game.message, "U18 el mensaje lista 2, 4 y 6 sin repetir la y (%s)" % game.message)
	# [2,2,3,4,6]: cuatro dados pares x +2 = 8 puntos en el cálculo.
	var after: int = game.preview().total
	check.call(after > base and after - base >= 8, "U18 suma +2 por cada dado par")
	var stacked = _hand(["even_boost", "boost"])
	_use(stacked, "even_boost")
	_use(stacked, "boost")
	var alone = _hand(["boost"])
	_use(alone, "boost")
	check.call(stacked.impulses.size() == 2 and stacked.preview().total > game.preview().total and stacked.preview().total > alone.preview().total, "U18 se acumula con otros impulsos")
	var forecast: int = game.preview().total
	check.call(game.score_hand() and game.last_score.total == forecast, "U18 la previsión coincide con la anotación")
	check.call("even_boost" in game.impulses, "U18 sobrevive a la mano")
	var win = _hand(["even_boost"])
	_use(win, "even_boost")
	_closed(win)
	check.call(win.impulses.is_empty(), "U18 termina con el encuentro")

static func _test_save(check: Callable) -> void:
	var store := SaveStore.new("user://saves/mon5-test.json")
	for id in ["mult_plus2", "points_bag", "even_boost", "two_rolls"]:
		var game = _hand([id])
		_use(game, id)
		check.call(Validator.validate(_payload(game)) == "", "MON5: guardar con %s activa valida (%s)" % [id, Validator.validate(_payload(game))])
		var restored = store.restore_game(_payload(game))
		check.call(restored != null and restored.hand_mult_bonus == game.hand_mult_bonus and restored.hand_points_bonus == game.hand_points_bonus and restored.impulses == game.impulses and restored.rolls_left == game.rolls_left, "MON5: continuar con %s activa conserva el efecto" % id)
		if restored != null: check.call(restored.preview().total == game.preview().total, "MON5: la previsión tras continuar con %s es la misma" % id)
	var shop = _shop(["visit_discount"])
	_use(shop, "visit_discount")
	var restored_shop = store.restore_game(_payload(shop))
	check.call(Validator.validate(_payload(shop)) == "" and restored_shop != null and restored_shop.visit_discount == 0.5 and restored_shop.offer_price(10) == 5, "MON5: guardar y continuar con el descuento de visita activo (%s / %s)" % [Validator.validate(_payload(shop)), str(restored_shop != null and restored_shop.visit_discount)])

## Pantalla de reparación con la escena real: las monedas usables van en fila, sin pisarse.
static func run_ui(scene, check: Callable) -> void:
	var previous = scene.game
	scene.detail.hide()
	scene.confirmation.hide()
	scene.game = _broken_game(["repair_gem", "repair_all"])
	scene.render()
	var gem = UI.find_button(scene.ui, "Reparar gema")
	var all = UI.find_button(scene.ui, "Reparar todas")
	check.call(gem != null and all != null, "U17 la pantalla de reparación ofrece las dos monedas")
	if gem != null and all != null:
		check.call(not Rect2(gem.position, gem.size).intersects(Rect2(all.position, all.size)), "U17 los botones de reparación no se pisan (%s %s)" % [str(Rect2(gem.position, gem.size)), str(Rect2(all.position, all.size))])
	scene.game = _broken_game(["repair_all"])
	scene.render()
	check.call(UI.find_button(scene.ui, "Usar Reparar todas") != null, "U17 con una sola moneda sigue habiendo un botón")
	scene.game = previous
	scene.render()
