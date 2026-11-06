extends RefCounted
## MON6: Relanzo total (U09), Voltear dado (U12) y Escudo de jefe (U14).
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const Shop = preload("res://scripts/shop.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

const PAIR = [2, 2, 3, 4, 6]
const UI_STATE = {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}

static func _payload(game) -> Dictionary:
	return {"game": game.snapshot(), "ui": UI_STATE.duplicate(true)}

static func _give(game, ids: Array) -> void:
	for id in ids:
		game.coin_instance_sequence += 1
		game.coin_inventory.consumables.append(Coins.instance(id, game.coin_instance_sequence))

static func _use(game, id: String, target := -1) -> bool:
	return game.use_consumable(Coins.ids(game.coin_inventory.consumables).find(id), target)

## Partida normal con la primera tirada hecha.
static func _rolled(coins: Array, seed_value := 12):
	var game = Game.new(seed_value)
	_give(game, coins)
	game.roll()
	return game

static func _boss(id: String, coins: Array, seed_value := -1):
	var game = CatalogTests.forced_boss(id, true, seed_value)
	_give(game, coins)
	return game

static func run(check: Callable) -> void:
	_test_catalog(check)
	_test_reroll_all(check)
	_test_reroll_all_bosses(check)
	_test_flip_die(check)
	_test_shield(check)
	_test_shield_bosses(check)
	_test_once_per_run(check)
	_test_save(check)

static func _test_catalog(check: Callable) -> void:
	for row in [["reroll_all", "U09"], ["flip_die", "U12"], ["boss_shield", "U14"]]:
		var data := Coins.definition(row[0])
		check.call(data.code == row[1] and data.rarity == "rare" and data.type == "consumable" and data.price == 3 and data.resale == 1 and data.use_contexts == ["play"], "MON6: %s es una moneda de un uso Rara de $3 / $1 que se usa en la mesa" % row[0])
		check.call(row[0] in Coins.CONSUMABLES and row[0] in CoinArt.NEW_IDS and Coins.SHORT.has(row[0]), "MON6: %s está en el catálogo, tiene arte y abreviatura" % row[0])
	check.call(Coins.catalog().size() == 75 and Coins.CONSUMABLES.size() == 18, "MON6: el catálogo pasa a 75 monedas (18 de un uso)")
	check.call(Coins.once_per_run("boss_shield") and not Coins.once_per_run("reroll_all") and Coins.targeted("flip_die") and not Coins.targeted("boss_shield"), "MON6: solo el Escudo es de una vez por partida y solo Voltear dado pide un dado")

static func _test_reroll_all(check: Callable) -> void:
	var fresh = Game.new(12)
	_give(fresh, ["reroll_all"])
	check.call(not _use(fresh, "reroll_all") and fresh.coin_inventory.consumables.size() == 1, "U09 requiere haber tirado y no se consume si no se puede")
	var game = _rolled(["reroll_all"])
	game.lock_groups()
	Fixture.set_values(game, PAIR)
	game.form_group([0, 1])
	game.lock_groups()
	game.rolls_left = 0
	var made: int = game.rolls_made
	var events: int = game.events.size()
	check.call(game.groups.size() == 1 and game.groups[0].locked, "U09 (preparación) hay un grupo bloqueado y cero tiradas")
	check.call(_use(game, "reroll_all"), "U09 se usa con 0 tiradas restantes")
	check.call(game.groups.is_empty() and game.rolls_left == 0 and game.rolls_made == made + 1 and game.coin_inventory.consumables.is_empty(), "U09 deshace los grupos bloqueados, cuenta como tirada hecha y no gasta presupuesto")
	check.call(game.dice.all(func(die): return die.zone == "reserve") and game.events.size() == events + 1 and game.events.back().type == Game.REROLL and game.events.back().payload.rolled_ids.size() == 5, "U09 tira los cinco dados con un evento de relanzo")
	# Misma semilla, mismo resultado.
	var first = _rolled(["reroll_all"], 77)
	var second = _rolled(["reroll_all"], 77)
	_use(first, "reroll_all")
	_use(second, "reroll_all")
	check.call(first.dice.map(func(die): return die.value) == second.dice.map(func(die): return die.value), "U09 con la misma semilla da el mismo resultado")
	# Moneda gastada pierde 1 por dado, igual que un relanzo de los cinco.
	var by_coin = _rolled(["reroll_all"], 31)
	by_coin.passives = ["spent"]
	var by_roll = _rolled([], 31)
	by_roll.passives = ["spent"]
	for die in by_roll.dice: die.zone = "cup"
	by_roll.roll()
	_use(by_coin, "reroll_all")
	check.call(Coins.state_of(by_coin.coin_inventory.equipped) == Coins.state_of(by_roll.coin_inventory.equipped), "U09 desgasta la Moneda gastada igual que un relanzo de cinco dados (%s)" % str(Coins.state_of(by_coin.coin_inventory.equipped)))
	# La previsión sigue a la anotación después de relanzar.
	var forecast = _rolled(["reroll_all"], 5)
	_use(forecast, "reroll_all")
	var expected: int = forecast.preview().total
	check.call(forecast.score_hand() and forecast.last_score.total == expected, "U09 la previsión coincide con la anotación")

static func _test_reroll_all_bosses(check: Callable) -> void:
	# Dado cargado: queda fijo en 1 y no se relanza.
	var loaded = _boss("l4_tahur", ["reroll_all"], 8)
	loaded.roll()
	var marked: int = int(loaded.boss_state.die)
	check.call(marked >= 0 and loaded.dice[marked].value == 1, "U09 (preparación) el dado cargado vale 1")
	_use(loaded, "reroll_all")
	check.call(loaded.dice[marked].value == 1 and marked in loaded.events.back().payload.kept_ids and loaded.events.back().payload.rolled_ids.size() == 4, "U09 deja afuera al dado cargado")
	# Dado abducido: queda afuera con su valor.
	var abducted = _boss("l5_visitante", ["reroll_all"], 9)
	abducted.roll()
	var gone: int = int(abducted.boss_state.die)
	var value_before: int = abducted.dice[gone].value
	_use(abducted, "reroll_all")
	check.call(abducted.dice[gone].value == value_before and gone in abducted.events.back().payload.kept_ids, "U09 deja afuera al dado abducido")
	# Dado asustado: después de relanzar vuelve al vaso, como en cualquier tirada.
	var scared = _boss("l1_palomas", ["reroll_all"], 10)
	scared.roll()
	var shy: int = int(scared.boss_state.die)
	_use(scared, "reroll_all")
	check.call(scared.dice[shy].zone == "cup" and scared.events.back().payload.rolled_ids.size() == 5, "U09 con dado asustado: se relanza y vuelve al vaso")

static func _test_flip_die(check: Callable) -> void:
	var game = _rolled(["flip_die"])
	Fixture.set_values(game, PAIR)
	game.form_group([0, 1])
	var total_before: int = game.preview().total
	check.call(not game.use_consumable(0) and game.coin_inventory.consumables.size() == 1, "U12 sin elegir dado no se usa ni se consume (cancelar no gasta)")
	check.call(not game.use_consumable(0, 0) and game.coin_inventory.consumables.size() == 1, "U12 un dado dentro de un grupo no se puede voltear")
	check.call(not game.use_consumable(0, 9) and game.coin_inventory.consumables.size() == 1, "U12 un dado inexistente no se puede voltear")
	check.call(_use(game, "flip_die", 4), "U12 voltea un dado suelto ya tirado")
	check.call(game.dice[4].value == 1 and game.dice[4].face_index == 0 and game.coin_inventory.consumables.is_empty(), "U12 el 6 pasa a la cara opuesta y la moneda se consume al elegir")
	check.call(game.preview().total < total_before, "U12 la previsión se actualiza con la cara nueva")
	var expected: int = game.preview().total
	check.call(game.score_hand() and game.last_score.total == expected, "U12 la previsión coincide con la anotación")
	# Caras cambiadas: pasa a la cara física opuesta, no al número 7 − x.
	var custom = _rolled(["flip_die"])
	custom.dice[3].faces = [3, 3, 4, 4, 9, 8]
	custom.dice[3].face_index = 0
	custom.dice[3].value = 3
	_use(custom, "flip_die", 3)
	check.call(custom.dice[3].face_index == 5 and custom.dice[3].value == 8, "U12 con caras cambiadas va a la cara física opuesta (dio %d)" % custom.dice[3].value)
	var before = Game.new(3)
	_give(before, ["flip_die"])
	check.call(not _use(before, "flip_die", 0), "U12 requiere dados ya tirados")
	# Dados fijados por un jefe.
	var loaded = _boss("l4_tahur", ["flip_die"], 8)
	loaded.roll()
	var marked: int = int(loaded.boss_state.die)
	check.call(not loaded.use_consumable(0, marked) and loaded.coin_inventory.consumables.size() == 1, "U12 no afecta al dado cargado")
	var other: int = (marked + 1) % 5
	check.call(loaded.use_consumable(0, other), "U12 sí afecta a otro dado en el mismo jefe")

static func _test_shield(check: Callable) -> void:
	var normal = _rolled(["boss_shield"])
	check.call(not _use(normal, "boss_shield") and not normal.boss_shield_active and normal.coin_inventory.consumables.size() == 1, "U14 no se usa contra un rival común")
	var boss = _boss("l1_payador", ["boss_shield", "boss_shield"], 14)
	check.call(not boss.boss_context().is_empty() and boss.boss_power_on(), "U14 (preparación) el poder del jefe está en juego")
	check.call(_use(boss, "boss_shield") and boss.boss_shield_active and not boss.boss_power_on() and boss.boss_context().is_empty(), "U14 apaga el poder del jefe en esta mano")
	check.call(not _use(boss, "boss_shield") and boss.coin_inventory.consumables.size() == 1, "U14 no se apila dos veces en la misma mano")
	Fixture.set_values(boss, [3, 3, 3, 3, 3])
	check.call(boss.form_group([0, 1, 2, 3, 4]), "U14 con el Escudo se puede formar la generala prohibida")
	var forecast: int = boss.preview().total
	check.call(boss.score_hand() and boss.last_score.total == forecast, "U14 la previsión coincide con la anotación")
	check.call(not boss.boss_shield_active and not boss.boss_context().is_empty(), "U14 el poder vuelve después de anotar")
	boss.next_hand()
	Fixture.set_values(boss, [3, 3, 3, 3, 3])
	check.call(not boss.form_group([0, 1, 2, 3, 4]), "U14 en la mano siguiente la generala vuelve a estar prohibida")

static func _test_shield_bosses(check: Callable) -> void:
	# Cada poder del catálogo: el Escudo lo apaga, previsión = anotación y vuelve en la mano siguiente.
	for row in BossCatalog.ROWS:
		if not row.implemented: continue
		var game = _boss(row.id, ["boss_shield"])
		var used := _use(game, "boss_shield")
		Fixture.set_values(game, PAIR)
		var grouped: bool = game.form_group([0, 1]) or game.form_group([2, 3]) or game.form_group([1, 2, 3])
		var forecast: int = game.preview().total
		var no_power: bool = game.boss_context().is_empty() and not BossRules.forecast_hidden(game.boss_context()) and game.boss_marks().is_empty()
		var scored: bool = game.score_hand() and game.last_score.total == forecast
		check.call(used and no_power and scored, "U14 contra %s: apagado, previsión = anotación (usada %s, sin poder %s, anotó %s)" % [row.id, str(used), str(no_power), str(scored)])
		check.call(not game.boss_shield_active, "U14 contra %s: el escudo termina con la mano" % row.id)
		if game.phase == "hand_result" and game.hand < game.hand_limit():
			game.next_hand()
			check.call(game.boss_context() == BossRules.context(game.boss_rule, true, game.boss_state, game.hand), "U14 contra %s: el poder vuelve en la mano siguiente" % row.id)
	# Efectos concretos.
	var kiosk = _boss("l1_kioskero", ["boss_shield"], 21)
	kiosk.cash = 20
	_use(kiosk, "boss_shield")
	Fixture.set_values(kiosk, PAIR)
	kiosk.form_group([0, 1])
	kiosk.score_hand()
	check.call(kiosk.cash == 20 and kiosk.boss_state.tax == 0, "U14 el Kioskero no cobra impuesto en la mano protegida")
	kiosk.next_hand()
	Fixture.set_values(kiosk, PAIR)
	kiosk.form_group([0, 1])
	kiosk.score_hand()
	check.call(kiosk.cash == 18, "U14 el impuesto vuelve a cobrarse en la mano siguiente")
	var memory = _boss("l2_chamuyero", ["boss_shield"], 22)
	_use(memory, "boss_shield")
	Fixture.set_values(memory, PAIR)
	memory.form_group([0, 1])
	memory.score_hand()
	check.call("Par" in memory.boss_state.get("scored", []), "U14 la memoria del Chamuyero se sigue registrando")
	var thief = _boss("l2_cebador", ["boss_shield"], 23)
	check.call(thief.thermos_stolen(), "U14 (preparación) Cebador se lleva el termo")
	_use(thief, "boss_shield")
	check.call(not thief.thermos_stolen(), "U14 el termo vuelve durante la mano protegida")
	Fixture.set_values(thief, PAIR)
	thief.form_group([0, 1])
	thief.score_hand()
	check.call(thief.thermos_stolen(), "U14 el termo se va de nuevo al terminar la mano")
	var red = CatalogTests.red_card_game(700, ["extra_hand"])
	_give(red, ["boss_shield"])
	check.call(red.hand_limit() == 2, "U14 (preparación) Tarjeta roja expulsa a Mano extra")
	_use(red, "boss_shield")
	check.call(red.hand_limit() == 3 and red._active_passives() == ["extra_hand"], "U14 la moneda expulsada vuelve a valer en la mano protegida")
	var god = _boss("l7_dios_dados", ["boss_shield"], 24)
	check.call(_use(god, "boss_shield") and god.boss_context().is_empty(), "U14 también funciona contra Dios")

static func _shield_seen(game, counter: Dictionary) -> void:
	for section in game.shop_state:
		for offer in game.shop_state[section].slots:
			if offer.get("effect", {}).get("coin_id", "") == "boss_shield": counter.count += 1

static func _test_once_per_run(check: Callable) -> void:
	# Con una tabla que solo ofrece el Escudo: sale una vez y no vuelve.
	var tables := Shop.default_tables()
	tables.coins = [{"kind": "coin", "price": 3, "weight": 1.0, "effect": {"coin_id": "boss_shield"}}]
	var first := Shop.generate("coins", tables, {}, [], 1, 0, [])
	var offers: Array = first.section.slots.filter(func(slot): return not slot.is_empty())
	check.call(first.valid and offers.size() == 1 and first.once_seen == ["boss_shield"], "U14 el Escudo sale una sola vez dentro de una misma tanda")
	var second := Shop.generate("coins", tables, {}, [], 2, 10, first.once_seen)
	check.call(second.valid and second.section.slots.all(func(slot): return slot.is_empty()) and second.once_seen == ["boss_shield"], "U14 con el Escudo ya visto no se vuelve a ofrecer")
	# En una partida real: muchas aperturas y renovaciones, nunca dos veces.
	var game = Game.new(5)
	# Se fuerzan monedas de un uso Raras para que el Escudo tenga muchas ocasiones de repetirse.
	game.shop_tables.coin_type_weights = {"consumable": 100.0}
	game.shop_tables.coin_rarity_weights = {"consumable": {"rare": 100.0}}
	game.cash = 100000
	game.phase = "hand_result"
	game.points = 999
	game.last_score = {"total": 999, "rows": [], "served": false, "valid": true}
	game.close_encounter()
	var counter := {"count": 0}
	for visit in range(80):
		game.phase = "reward"
		game.open_shop()
		_shield_seen(game, counter)
		for renewal in range(5):
			game.refresh_shop("coins")
			_shield_seen(game, counter)
	check.call(counter.count == 1, "U14 en 80 visitas con renovaciones aparece exactamente una vez (apareció %d)" % counter.count)
	check.call((counter.count == 1) == ("boss_shield" in game.once_coins_seen), "U14 la partida recuerda haberla generado, se haya comprado o no")
	# Tras guardar y continuar sigue sin repetirse.
	var store := SaveStore.new("user://saves/mon6-test.json")
	var restored = store.restore_game(_payload(game))
	check.call(restored != null and restored.once_coins_seen == game.once_coins_seen, "U14 guardar y continuar conserva lo ya generado (%s)" % Validator.validate(_payload(game)))
	if restored != null:
		restored.cash = 100000
		var after := {"count": 0}
		for visit in range(40):
			restored.phase = "reward"
			restored.open_shop()
			_shield_seen(restored, after)
		check.call(after.count == 0, "U14 tras continuar no aparece una segunda vez")
	var fresh = Game.new(5)
	check.call(fresh.once_coins_seen.is_empty(), "U14 una partida nueva empieza sin monedas vistas")

static func _test_save(check: Callable) -> void:
	var store := SaveStore.new("user://saves/mon6-test.json")
	var shielded = _boss("l1_payador", ["boss_shield"], 14)
	_use(shielded, "boss_shield")
	Fixture.set_values(shielded, [3, 3, 3, 3, 3])
	shielded.form_group([0, 1, 2, 3, 4])
	check.call(Validator.validate(_payload(shielded)) == "", "U14 un guardado con el Escudo activo y una generala formada valida (%s)" % Validator.validate(_payload(shielded)))
	var restored = store.restore_game(_payload(shielded))
	check.call(restored != null and restored.boss_shield_active and restored.preview().total == shielded.preview().total, "U14 continuar conserva el Escudo y la previsión")
	var without = _boss("l1_payador", [], 14)
	Fixture.set_values(without, [3, 3, 3, 3, 3])
	without.groups = [{"ids": [0, 1, 2, 3, 4], "category": "Generala", "locked": false}]
	check.call(Validator.validate(_payload(without)) != "", "U14 sin el Escudo la misma generala se rechaza")
	var stray = _rolled([])
	stray.boss_shield_active = true
	check.call(Validator.validate(_payload(stray)) != "", "U14 un Escudo activo fuera de un jefe se rechaza")
	var late = _boss("l1_payador", [], 14)
	late.boss_shield_active = true
	late.phase = "hand_result"
	check.call(Validator.validate(_payload(late)) != "", "U14 un Escudo activo fuera de la mesa se rechaza")
	# Relanzo total y Voltear dado dejan un guardado válido y reproducible.
	var rerolled = _rolled(["reroll_all"], 61)
	_use(rerolled, "reroll_all")
	var copy = store.restore_game(_payload(rerolled))
	check.call(Validator.validate(_payload(rerolled)) == "" and copy != null and copy.dice.map(func(d): return d.value) == rerolled.dice.map(func(d): return d.value), "U09 guardar y continuar después de relanzar conserva los dados")
	var flipped = _rolled(["flip_die"], 62)
	_use(flipped, "flip_die", 2)
	check.call(Validator.validate(_payload(flipped)) == "", "U12 un guardado después de voltear valida (%s)" % Validator.validate(_payload(flipped)))

## Pantalla con la escena real: Voltear dado se elige en la mesa, se cancela con la misma moneda y gasta al elegir.
static func run_ui(scene, check: Callable) -> void:
	var previous = scene.game
	scene.detail.hide()
	scene.confirmation.hide()
	var game = _rolled(["flip_die"], 12)
	Fixture.set_values(game, PAIR)
	scene.game = game
	scene.render()
	scene.start_flip(0)
	check.call(scene.flip_slot == 0 and game.coin_inventory.consumables.size() == 1, "U12 tocar la moneda activa el modo de elegir dado sin gastarla")
	scene.start_flip(0)
	check.call(scene.flip_slot == -1 and game.coin_inventory.consumables.size() == 1, "U12 tocar la moneda otra vez cancela sin gastar")
	scene.start_flip(0)
	scene.toggle_die(4)
	check.call(scene.flip_slot == -1 and game.dice[4].value == 1 and game.coin_inventory.consumables.is_empty(), "U12 elegir el dado voltea y gasta la moneda")
	check.call(not scene.game.snapshot().has("flip_slot"), "U12 el modo de elegir no se guarda en la partida")
	scene.game = previous
	scene.render()
