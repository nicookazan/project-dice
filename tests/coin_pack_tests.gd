extends RefCounted
## MON7: reglas del paquete de monedas (cuarto espacio de la sección de monedas).
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const Shop = preload("res://scripts/shop.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Validator = preload("res://scripts/save_validator.gd")

const UI_STATE = {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}
## Inventarios extremos para comprobar que el paquete siempre deja una elección legal.
const INVENTORIES = {
	"lleno": {"passives": ["full", "straight", "poker", "even", "odd"], "consumables": []},
	"lleno con un uso": {"passives": ["full", "straight", "poker", "even", "odd"], "consumables": ["boost"]},
	"con Bolsillo": {"passives": ["pocket", "full", "straight", "poker", "even", "odd", "generala"], "consumables": []},
	"con Bolsillo chico": {"passives": ["pocket_small", "full", "straight", "poker", "even"], "consumables": ["boost", "roll"]},
	"una ranura de un uso": {"passives": ["full", "straight"], "consumables": ["boost"]},
	"vacío": {"passives": [], "consumables": []}}

static func _payload(game) -> Dictionary:
	return {"game": game.snapshot(), "ui": UI_STATE.duplicate(true)}

## Tienda abierta en una partida real: encuentro cerrado y `open_shop`, con inventario ya armado.
static func _shop_game(seed_value: int, passives: Array = [], consumables: Array = [], tables: Dictionary = {}):
	var game = Game.new(seed_value)
	game.passives = passives
	for id in consumables:
		game.coin_instance_sequence += 1
		game.coin_inventory.consumables.append(Coins.instance(id, game.coin_instance_sequence))
	Coins.refresh_capacity(game.coin_inventory)
	if not tables.is_empty(): game.shop_tables = tables
	game.cash = 1000
	game.phase = "hand_result"
	game.points = 999
	game.last_score = {"total": 999, "rows": [], "served": false, "valid": true}
	game.close_encounter()
	game.open_shop()
	return game

static func _pack(game) -> Dictionary:
	return game.shop_state.coins.slots[3]

static func _singles(game) -> Array:
	return game.shop_state.coins.slots.slice(0, 3)

static func run(check: Callable) -> void:
	_test_generation(check)
	_test_purchase(check)
	_test_choice(check)
	_test_replacement(check)
	_test_no_dead_end(check)
	_test_save(check)

static func _test_generation(check: Callable) -> void:
	var tables := Shop.default_tables()
	check.call(tables.coin_packs.size() == 2 and tables.coin_packs.all(func(entry): return Shop.valid_coin_pack_entry(entry)), "MON7: la tabla coin_packs trae dos tamaños válidos")
	check.call(tables.coin_packs[0].price == 7 and tables.coin_packs[0].weight == 65.0 and tables.coin_packs[0].effect.shown == 2 and tables.coin_packs[0].effect.picks == 1, "MON7: el paquete chico muestra 2, se elige 1, $7, 65 %")
	check.call(tables.coin_packs[1].price == 14 and tables.coin_packs[1].weight == 35.0 and tables.coin_packs[1].effect.shown == 5 and tables.coin_packs[1].effect.picks == 2, "MON7: el paquete grande muestra 5, se eligen 2, $14, 35 %")
	var sizes := {"small": 0, "large": 0}
	var bad := 0
	for seed_value in range(1, 61):
		var game = _shop_game(seed_value, ["full", "straight"])
		var slots: Array = game.shop_state.coins.slots
		var pack: Dictionary = slots[3]
		if slots.slice(0, 3).any(func(slot): return slot.get("kind") != "coin") or pack.get("kind") != "coin_pack" or not Shop.valid_coin_pack_offer(pack):
			bad += 1
			continue
		sizes[pack.effect.size] += 1
		var items: Array = pack.effect.items
		var single_passives: Array = slots.slice(0, 3).map(func(slot): return slot.effect.coin_id).filter(func(id): return id in Coins.PASSIVES)
		if items.any(func(id): return id in ["full", "straight"] or id in single_passives) or Coins.definition(pack.effect.items[0]).is_empty(): bad += 1
		if pack.effect.size == "large" and items.filter(func(id): return id in Coins.PASSIVES).size() < 2: bad += 1
	check.call(bad == 0, "MON7: en 60 semillas el paquete es válido, sin repetidos, sin pasivas propias ni iguales a las sueltas y el grande con 2 pasivas (%d fallas)" % bad)
	check.call(sizes.small > 0 and sizes.large > 0 and sizes.small > sizes.large, "MON7: salen los dos tamaños y el chico más seguido (%s)" % str(sizes))
	# Sin la tabla coin_packs los cuatro espacios siguen siendo monedas.
	var plain := Shop.default_tables()
	plain.erase("coin_packs")
	var four = _shop_game(7, [], [], plain)
	check.call(four.shop_state.coins.slots.all(func(slot): return slot.get("kind") == "coin"), "MON7: sin tabla coin_packs son cuatro monedas sueltas")
	# Mismo contenido con la misma semilla; mirar no cambia nada.
	var first = _shop_game(19)
	var second = _shop_game(19)
	check.call(_pack(first) == _pack(second) and _singles(first) == _singles(second), "MON7: misma semilla, mismo paquete")
	var before: Dictionary = first.snapshot()
	first.inspect_shop_offer("coins", _pack(first).offer_id)
	check.call(first.snapshot() == before, "MON7: mirar la oferta no cambia la partida")
	# Tabla inválida.
	var broken := Shop.default_tables()
	broken.coin_packs = [{"kind": "coin_pack", "price": 7, "weight": 1.0, "effect": {"size": "huge", "shown": 9, "picks": 1}}]
	check.call(not Shop.generate("coins", broken, {}, [], 1, 0).valid, "MON7: una tabla coin_packs inválida se rechaza")

static func _test_purchase(check: Callable) -> void:
	var game = _shop_game(19)
	var offer: Dictionary = _pack(game)
	var cash: int = game.cash
	var result: Dictionary = game.purchase_offer("coins", offer.offer_id)
	check.call(result.ok and game.phase == "coin_choice" and not game.pending_coin_pack.is_empty() and game.cash == cash - offer.price, "MON7: comprar el paquete descuenta el precio y abre la elección")
	var pending: Dictionary = game.pending_coin_pack
	check.call(pending.paid == offer.price and pending.items == offer.effect.items and pending.picks_left == offer.effect.picks and pending.received.is_empty(), "MON7: se guarda lo pagado, el contenido y las elecciones")
	check.call(game.purchase_receipts[offer.offer_id].paid == offer.price and _pack(game).is_empty(), "MON7: queda el recibo y el espacio se vacía")
	# Bloqueos durante la elección.
	game.coin_inventory.consumables.append(Coins.instance("boost", 9999))
	check.call(not game.refresh_shop("coins") and not game.leave_shop() and not game.use_consumable(0) and not game.buy(0) and not game.sell("boost") and game.phase == "coin_choice", "MON7: durante la elección no se puede renovar, salir, usar, comprar ni vender")
	game.coin_inventory.consumables.clear()
	# Descuento (C45): se paga y se registra lo pagado de verdad.
	var discounted = _shop_game(19, ["discount"])
	var d_offer: Dictionary = _pack(discounted)
	var d_cash: int = discounted.cash
	var expected: int = discounted.offer_price(d_offer.price)
	discounted.purchase_offer("coins", d_offer.offer_id)
	check.call(expected < d_offer.price and discounted.cash == d_cash - expected and discounted.pending_coin_pack.paid == expected and discounted.purchase_receipts[d_offer.offer_id].paid == expected, "MON7: el descuento baja el precio y se registra lo pagado ($%d)" % expected)
	# Sin plata no se compra; con Moneda de oro se puede comprar con deuda.
	var poor = _shop_game(19)
	poor.cash = 0
	check.call(not poor.purchase_offer("coins", _pack(poor).offer_id).ok and poor.phase == "shop", "MON7: sin plata no se compra el paquete")
	var gold = _shop_game(19, ["gold"])
	gold.cash = 0
	var gold_offer: Dictionary = _pack(gold)
	var bought: Dictionary = gold.purchase_offer("coins", gold_offer.offer_id)
	check.call(bought.ok and gold.cash < 0 and gold.phase == "coin_choice", "MON7: Moneda de oro permite comprar el paquete con deuda")
	# Inventario lleno: se compra igual.
	var full = _shop_game(19, INVENTORIES["lleno con un uso"].passives, INVENTORIES["lleno con un uso"].consumables)
	check.call(full.purchase_offer("coins", _pack(full).offer_id).ok, "MON7: se puede comprar con el inventario lleno")

## Elige la primera opción legal del paquete (directa o con reemplazo).
static func _pick_first(game) -> bool:
	for option in game.coin_choice_options():
		if option.direct: return game.choose_coin(option.id)
		if not option.replace.is_empty(): return game.choose_coin(option.id, option.replace[0])
	return false

static func _buy_pack(game) -> void:
	game.purchase_offer("coins", _pack(game).offer_id)

static func _test_choice(check: Callable) -> void:
	var small = null
	var large = null
	for seed_value in range(1, 80):
		var game = _shop_game(seed_value)
		if _pack(game).effect.size == "small" and small == null: small = game
		if _pack(game).effect.size == "large" and large == null: large = game
		if small != null and large != null: break
	_buy_pack(small)
	var choices: Array = small.pending_coin_pack.items.duplicate()
	var wanted: String = choices[0]
	check.call(not small.choose_coin("no_existe"), "MON7: no se puede elegir una moneda ajena al paquete")
	check.call(small.choose_coin(wanted) and small.phase == "shop" and small.pending_coin_pack.is_empty(), "MON7: el paquete chico se cierra con una sola elección")
	check.call(wanted in Coins.ids(small.coin_inventory.equipped + small.coin_inventory.consumables), "MON7: la moneda elegida queda en el inventario")
	check.call(small.purchase_receipts.values().any(func(receipt): return receipt.get("selected", []) == [wanted]), "MON7: el recibo registra lo elegido")
	_buy_pack(large)
	check.call(large.pending_coin_pack.picks_left == 2 and large.pending_coin_pack.items.size() == 5, "MON7: el paquete grande permite dos elecciones entre cinco")
	check.call(_pick_first(large) and large.phase == "coin_choice" and large.pending_coin_pack.picks_left == 1 and large.pending_coin_pack.received.size() == 1, "MON7: tras la primera elección sigue abierto con una elección restante")
	var got: String = large.pending_coin_pack.received[0]
	check.call(not large.choose_coin(got), "MON7: no se puede elegir dos veces la misma moneda")
	check.call(_pick_first(large) and large.phase == "shop" and large.pending_coin_pack.is_empty(), "MON7: la segunda elección cierra el paquete")

static func _test_replacement(check: Callable) -> void:
	# Pasivas llenas: hay que decir cuál se reemplaza, y paga su reventa.
	var passives: Array = INVENTORIES["lleno"].passives
	var game = null
	for seed_value in range(1, 80):
		game = _shop_game(seed_value, passives)
		if _pack(game).effect.items.any(func(id): return id in Coins.PASSIVES): break
	_buy_pack(game)
	var incoming: String = game.pending_coin_pack.items.filter(func(id): return id in Coins.PASSIVES)[0]
	check.call(not game.choose_coin(incoming) and game.phase == "coin_choice" and game.pending_coin_pack.received.is_empty(), "MON7: sin lugar y sin elegir qué reemplazar no se puede")
	var outgoing: Dictionary = game.coin_inventory.equipped[1]
	var cash: int = game.cash
	var resale: int = Coins.definition(outgoing.coin_id).resale
	var consumable_id := 777
	check.call(not game.choose_coin(incoming, consumable_id), "MON7: un instance_id inexistente no reemplaza nada")
	check.call(game.choose_coin(incoming, outgoing.instance_id), "MON7: se reemplaza por instance_id")
	check.call(incoming in game.passives and outgoing.coin_id not in game.passives and game.cash == cash + resale, "MON7: la que sale paga su reventa ($%d)" % resale)
	# Una moneda de un uso no puede reemplazar a una pasiva ni al revés.
	var mixed = null
	for seed_value in range(1, 80):
		mixed = _shop_game(seed_value, passives, ["boost"])
		var items: Array = _pack(mixed).effect.items
		if items.any(func(id): return Coins.definition(id).type == "consumable") and items.any(func(id): return id in Coins.PASSIVES): break
	_buy_pack(mixed)
	var consumable: String = mixed.pending_coin_pack.items.filter(func(id): return Coins.definition(id).type == "consumable")[0]
	var passive_instance: int = mixed.coin_inventory.equipped[0].instance_id
	check.call(not mixed.choose_coin(consumable, passive_instance), "MON7: una moneda de un uso no reemplaza a una pasiva")
	# La recién recibida del mismo paquete no se puede reemplazar.
	var two = null
	for seed_value in range(1, 200):
		two = _shop_game(seed_value, passives)
		if _pack(two).effect.size == "large": break
	_buy_pack(two)
	_pick_first(two)
	var received_instance: int = two.pending_coin_pack.received_instances[0]
	var remaining: Array = two.pending_coin_pack.items.filter(func(id): return id not in two.pending_coin_pack.received and Coins.definition(id).type == "passive")
	if not remaining.is_empty():
		check.call(not two.choose_coin(remaining[0], received_instance), "MON7: la moneda recién recibida del mismo paquete no se puede reemplazar")
	# Bolsillo y Bolsillo chico no se reemplazan si quedarían más monedas que ranuras.
	var pocket := {"equipped": [], "consumables": [], "shared_capacity": 5, "consumable_capacity": 1}
	var serial := 0
	for id in INVENTORIES["con Bolsillo"].passives:
		serial += 1
		pocket.equipped.append(Coins.instance(id, serial))
	Coins.refresh_capacity(pocket)
	check.call(pocket.equipped.size() == 7 and pocket.shared_capacity == 7, "MON7 (preparación) siete pasivas con Bolsillo")
	check.call(not Coins.can_replace(pocket, 1, "metal") and Coins.can_replace(pocket, 2, "metal"), "MON7: Bolsillo no se puede reemplazar si quedarían más monedas que ranuras")
	var small_slot := {"equipped": [], "consumables": [Coins.instance("boost", 90), Coins.instance("roll", 91)], "shared_capacity": 5, "consumable_capacity": 2}
	for id in INVENTORIES["con Bolsillo chico"].passives:
		serial += 1
		small_slot.equipped.append(Coins.instance(id, 100 + serial))
	Coins.refresh_capacity(small_slot)
	check.call(small_slot.consumable_capacity == 2 and not Coins.can_replace(small_slot, small_slot.equipped[0].instance_id, "metal"), "MON7: Bolsillo chico no se puede reemplazar con dos monedas de un uso")
	check.call(Coins.can_replace(small_slot, 90, "boost_25") and not Coins.can_replace(small_slot, 90, "metal"), "MON7: una de un uso reemplaza a una de un uso y no a una pasiva")
	check.call(not Coins.can_replace(pocket, 3, "full"), "MON7: no se reemplaza por una pasiva que ya está equipada")

static func _test_no_dead_end(check: Callable) -> void:
	var stuck := 0
	var runs := 0
	var finished := 0
	var seen_sizes := {"small": 0, "large": 0}
	for name in INVENTORIES:
		var inventory: Dictionary = INVENTORIES[name]
		for seed_value in range(1, 31):
			var game = _shop_game(seed_value * 7 + 3, inventory.passives, inventory.consumables)
			var offer: Dictionary = _pack(game)
			if offer.is_empty():
				stuck += 1
				continue
			seen_sizes[offer.effect.size] += 1
			runs += 1
			_buy_pack(game)
			if game.phase != "coin_choice" or game.coin_choice_options().filter(func(option): return option.direct or not option.replace.is_empty()).is_empty():
				stuck += 1
				continue
			var guard := 0
			while game.phase == "coin_choice" and guard < 4:
				if not _pick_first(game): break
				guard += 1
			if game.phase == "shop" and game.pending_coin_pack.is_empty(): finished += 1
			else: stuck += 1
	check.call(stuck == 0 and finished == runs, "MON7: en %d paquetes con inventarios extremos siempre hay una elección legal y nunca queda trabado (%d trabados)" % [runs, stuck])
	check.call(seen_sizes.small > 0 and seen_sizes.large > 0, "MON7: la prueba de salida cubre los dos tamaños (%s)" % str(seen_sizes))

static func _test_save(check: Callable) -> void:
	var store := SaveStore.new("user://saves/mon7-test.json")
	for want in ["small", "large"]:
		var game = null
		for seed_value in range(1, 200):
			game = _shop_game(seed_value)
			if _pack(game).effect.size == want: break
		check.call(Validator.validate(_payload(game)) == "", "MON7: guardar en la tienda con paquete %s valida (%s)" % [want, Validator.validate(_payload(game))])
		_buy_pack(game)
		check.call(Validator.validate(_payload(game)) == "", "MON7: guardar con la elección abierta (%s) valida (%s)" % [want, Validator.validate(_payload(game))])
		var restored = store.restore_game(_payload(game))
		check.call(restored != null and restored.phase == "coin_choice" and restored.pending_coin_pack == game.pending_coin_pack, "MON7: continuar con la elección abierta (%s) conserva el paquete" % want)
		if restored == null: continue
		check.call(_pick_first(restored), "MON7: se puede elegir después de continuar (%s)" % want)
		check.call(Validator.validate(_payload(restored)) == "", "MON7: guardar después de la primera elección (%s) valida (%s)" % [want, Validator.validate(_payload(restored))])
		var again = store.restore_game(_payload(restored))
		check.call(again != null and again.phase == restored.phase and again.pending_coin_pack == restored.pending_coin_pack, "MON7: continuar después de la primera elección (%s)" % want)
		while restored.phase == "coin_choice":
			if not _pick_first(restored): break
		check.call(restored.phase == "shop" and Validator.validate(_payload(restored)) == "", "MON7: terminar la elección (%s) deja la partida válida" % want)
	# Estados inconsistentes se rechazan.
	var open = null
	for seed_value in range(1, 50):
		open = _shop_game(seed_value)
		if _pack(open).effect.size == "large": break
	_buy_pack(open)
	var broken = open.snapshot()
	broken.phase = "shop"
	check.call(Validator.validate({"game": broken, "ui": UI_STATE.duplicate(true)}) != "", "MON7: un paquete pendiente fuera de la fase de elección se rechaza")
	var wrong = open.snapshot()
	wrong.pending_coin_pack.picks_left = 5
	check.call(Validator.validate({"game": wrong, "ui": UI_STATE.duplicate(true)}) != "", "MON7: elecciones restantes imposibles se rechazan")
	var foreign = open.snapshot()
	foreign.pending_coin_pack.received = ["full"]
	foreign.pending_coin_pack.received_instances = [1]
	foreign.pending_coin_pack.picks_left = 1
	check.call(Validator.validate({"game": foreign, "ui": UI_STATE.duplicate(true)}) != "" or open.pending_coin_pack.items.has("full"), "MON7: una moneda recibida que no era del paquete se rechaza")
