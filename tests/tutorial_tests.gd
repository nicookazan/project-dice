extends RefCounted
## Pantalla inicial, partidas guardadas y tutorial (docs/PARTIDAS-GUARDADAS.md y docs/TUTORIAL.md).
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const Shop = preload("res://scripts/shop.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const Campaign = preload("res://scripts/campaign.gd")
const ProfileStore = preload("res://scripts/profile_store.gd")
const Achievements = preload("res://scripts/achievements.gd")
const Tutorial = preload("res://scripts/tutorial_script.gd")
const Preferences = preload("res://scripts/presentation_preferences.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

static func run(scene, check: Callable) -> void:
	var folder := "res://test-results/tutorial/" + str(Time.get_ticks_usec())
	_test_profile_store(folder, check)
	_test_preferences(folder, check)
	_test_vendor_gift(check)
	_test_tutorial_game(check)
	_test_tutorial_steps(check)
	_test_boss_seller(check)
	_test_ui(scene, folder, check)

static func _test_profile_store(folder: String, check: Callable) -> void:
	var store := ProfileStore.new(folder + "/perfil")
	check.call(store.slots().all(func(entry): return entry.ok and not entry.exists), "Partidas: sin archivos, las tres ranuras están vacías")
	check.call(store.first_free() == 1 and store.create(1).ok and not store.create(1).ok and store.first_free() == 2, "Partidas: crear llena la primera ranura libre y no pisa una existente")
	check.call(store.read(1).exists and store.read(1).data == ProfileStore.empty_data() and not store.read(4).ok, "Partidas: una partida nueva está en cero y la ranura 4 no existe")
	# Estadísticas solo al terminar la jugada.
	check.call(store.record_run(1, {"won": false, "level": 2}).ok and store.read(1).data.plays == 1 and store.read(1).data.wins == 0 and store.read(1).data.best_level == 2, "Partidas: una jugada perdida suma una jugada y el nivel alcanzado")
	check.call(store.record_run(1, {"won": true, "level": 7}).ok and store.read(1).data.plays == 2 and store.read(1).data.wins == 1 and store.read(1).data.best_level == 7, "Partidas: una ganada suma jugada, victoria y sube el nivel más alto")
	check.call(store.record_run(1, {"won": false, "level": 3}).ok and store.read(1).data.best_level == 7, "Partidas: el nivel más alto no baja")
	var before: Dictionary = store.read(1).data
	check.call(store.record_run(1, {"won": true, "level": 7, "debug": true}).skipped and store.read(1).data == before, "Partidas: la jugada debug no escribe nada")
	# Tutorial: logro y moneda, sin sumar jugadas.
	check.call(store.record_run(1, {"tutorial": true, "won": true, "level": 1}).ok, "Partidas: el tutorial terminado se registra")
	var after: Dictionary = store.read(1).data
	check.call(after.plays == before.plays and after.wins == before.wins and after.achievements == ["tutorial_completed"] and after.unlocked_coins == ["vendor_gift"], "Partidas: el tutorial da el logro y desbloquea la moneda sin sumar jugadas ni victorias")
	store.record_run(1, {"tutorial": true})
	check.call(store.read(1).data.achievements == ["tutorial_completed"], "Partidas: repetir el tutorial no duplica el logro")
	# Ranuras independientes.
	store.create(2)
	check.call(store.read(2).data == ProfileStore.empty_data() and not store.read(2).data.unlocked_coins.has("vendor_gift"), "Partidas: cada ranura tiene su propio progreso")
	check.call("Partidas: 3" in ProfileStore.summary(store.read(1).data) and "Tutorial completado" in ProfileStore.summary(store.read(1).data), "Partidas: el resumen muestra jugadas y logros")
	# Archivo dañado: se conserva sin cambios.
	var path: String = store.path_of(3)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ esto no es una partida")
	file.close()
	var damaged := store.read(3)
	check.call(not damaged.ok and not store.record_run(3, {"won": true, "level": 1}).ok and not store.create(3).ok and FileAccess.get_file_as_string(path) == "{ esto no es una partida", "Partidas: un archivo dañado nunca se sobrescribe")
	var tampered := FileAccess.get_file_as_string(store.path_of(1)).replace("\\\"plays\\\":3", "\\\"plays\\\":9")
	file = FileAccess.open(store.path_of(1), FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	check.call(store.read(1).code == "checksum", "Partidas: un archivo alterado falla la suma de control")
	# Escritura interrumpida: la partida anterior sigue intacta.
	var flaky := ProfileStore.new(folder + "/flaky")
	flaky.create(1)
	flaky.record_run(1, {"won": true, "level": 2})
	flaky.fail_at = "after_temp"
	check.call(not flaky.record_run(1, {"won": true, "level": 5}).ok and flaky.read(1).data.best_level == 2 and flaky.read(1).data.plays == 1, "Partidas: una escritura interrumpida conserva la partida anterior")
	check.call(flaky.delete(1).ok and not flaky.read(1).exists and flaky.delete(1).ok, "Partidas: borrar vacía la ranura (y borrar dos veces no falla)")
	check.call(not ProfileStore.valid_data({"plays": 1, "wins": 2, "best_level": 0, "achievements": [], "unlocked_coins": []}) and not ProfileStore.valid_data({"plays": 0, "wins": 0, "best_level": 0, "achievements": ["inventado"], "unlocked_coins": []}) and not ProfileStore.valid_data({"plays": 0, "wins": 0, "best_level": 0, "achievements": [], "unlocked_coins": ["full"]}), "Partidas: se rechazan victorias de más, logros inventados y monedas que no estaban bloqueadas")

static func _test_preferences(folder: String, check: Callable) -> void:
	var preferences := Preferences.new(folder + "/preferencias.cfg")
	var values: Dictionary = preferences.load_values()
	check.call(values.last_profile == 0 and Preferences.valid(values), "Preferencias: la última partida usada empieza en 0 (ninguna)")
	values.last_profile = 2
	check.call(preferences.save_values(values) and preferences.load_values().last_profile == 2, "Preferencias: la última partida usada se guarda aparte")
	values.last_profile = 4
	check.call(not Preferences.valid(values), "Preferencias: una ranura inexistente es inválida")
	var legacy := Preferences.DEFAULTS.duplicate()
	legacy.erase("last_profile")
	var config := ConfigFile.new()
	config.set_value("presentation", "version", 1)
	config.set_value("presentation", "values", legacy)
	config.save(ProjectSettings.globalize_path(folder + "/viejas.cfg"))
	check.call(Preferences.new(folder + "/viejas.cfg").load_values().last_profile == 0, "Preferencias: un archivo anterior sin esa clave sigue valiendo")

static func _test_vendor_gift(check: Callable) -> void:
	var data := Coins.definition("vendor_gift")
	check.call(data.code == "C58" and data.rarity == "rare" and data.type == "passive" and data.price == 6 and data.resale == 3, "C58: pasiva rara, precio 6 y reventa 3")
	check.call(Coins.stackable("vendor_gift") and Coins.locked("vendor_gift") and not Coins.stackable("full") and not Coins.locked("full"), "C58: es la única acumulable y la única bloqueada")
	var inventory := Coins.empty_inventory()
	check.call(Coins.can_store(inventory, "vendor_gift"), "C58: se puede guardar")
	inventory.equipped.append(Coins.instance("vendor_gift", 1))
	check.call(Coins.can_store(inventory, "vendor_gift"), "C58: se puede tener una segunda copia")
	inventory.equipped.append(Coins.instance("full", 2))
	check.call(not Coins.can_store(inventory, "full"), "Las demás pasivas siguen siendo de una sola copia")
	# Precios: porcentajes primero, después $1 por copia, piso de $1, solo monedas sueltas.
	var one := ["vendor_gift"]
	var two := ["vendor_gift", "vendor_gift"]
	check.call(CoinEffects.discounted(6, one, 0.0, true) == 5 and CoinEffects.discounted(6, two, 0.0, true) == 4, "C58: una copia resta $1 y dos copias $2")
	check.call(CoinEffects.discounted(6, one) == 6 and CoinEffects.discounted(14, two) == 14, "C58: no abarata paquetes ni renovaciones (sin el aviso de moneda suelta)")
	check.call(CoinEffects.discounted(2, ["vendor_gift", "vendor_gift", "vendor_gift"], 0.0, true) == 1 and CoinEffects.discounted(1, two, 0.0, true) == 1, "C58: el precio nunca baja de $1")
	check.call(CoinEffects.discounted(0, two, 0.0, true) == 0, "C58: una oferta gratis sigue gratis")
	check.call(CoinEffects.discounted(6, ["vendor_gift", "discount"], 0.0, true) == 4 and CoinEffects.discounted(6, ["discount"], 0.0, true) == 5, "C58 + Descuento (C45): primero el 20 %, después $1 (6 → 5 → 4)")
	check.call(CoinEffects.discounted(10, ["vendor_gift"], 0.5, true) == 4 and CoinEffects.discounted(10, ["vendor_gift", "discount"], 0.5, true) == 3, "C58 + Descuento de visita (U16): el porcentaje va antes y el piso es $1")
	var game := Game.new(31)
	game.passives = ["vendor_gift"]
	check.call(game.offer_price(6, true) == 5 and game.offer_price(6) == 6, "C58: Game.offer_price descuenta solo las monedas sueltas")
	# Bloqueada: no sale sin el desbloqueo, sale con él.
	var tables := Shop.default_tables()
	var locked_seen := 0
	var unlocked_seen := 0
	for seed_value in range(1, 301):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var without := Shop.generate("coins", tables, {}, [], rng.state, 0, [], [])
		var with := Shop.generate("coins", tables, {}, [], rng.state, 0, [], ["vendor_gift"])
		for slot in without.section.slots:
			if slot.get("effect", {}).get("coin_id", "") == "vendor_gift": locked_seen += 1
			if slot.get("kind") == "coin_pack" and "vendor_gift" in slot.effect.items: locked_seen += 1
		for slot in with.section.slots:
			if slot.get("effect", {}).get("coin_id", "") == "vendor_gift": unlocked_seen += 1
	check.call(locked_seen == 0, "C58: sin el desbloqueo nunca sale en la tienda (ni en paquetes)")
	check.call(unlocked_seen > 0, "C58: con el desbloqueo puede salir en la tienda (%d de 300 tiendas)" % unlocked_seen)
	# Con una copia equipada puede volver a ofrecerse; las demás pasivas equipadas no.
	var repeated := 0
	for seed_value in range(1, 301):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var made := Shop.generate("coins", tables, {}, ["vendor_gift", "full"], rng.state, 0, [], ["vendor_gift"])
		for slot in made.section.slots:
			var id: String = slot.get("effect", {}).get("coin_id", "")
			if id == "vendor_gift": repeated += 1
			check.call(id != "full", "Tienda: una pasiva ya equipada que no es acumulable no vuelve a ofrecerse")
	check.call(repeated > 0, "C58: aunque ya tengas una, la tienda puede ofrecer otra copia")
	var cleaned := Shop.clean_passive_offers({"coins": {"slots": [{"effect": {"coin_id": "vendor_gift"}}, {"effect": {"coin_id": "vendor_gift"}}], "configured": true}}, ["vendor_gift"])
	check.call(not cleaned.coins.slots[0].is_empty() and not cleaned.coins.slots[1].is_empty(), "C58: limpiar ofertas no saca las copias de la acumulable")
	# Comprarla dos veces desde la tienda y verificar el efecto real.
	var shopper := Game.new(32)
	shopper.begin_tutorial(32)
	Profile.apply(shopper)
	shopper.begin_level()
	shopper.phase = "shop"
	shopper.cash = 40
	shopper.offers = ["vendor_gift", "vendor_gift"]
	var first_buy := shopper.buy(0)
	var price_after: int = shopper.offer_price(Coins.definition("vendor_gift").price, true)
	var second_buy := shopper.buy(1)
	check.call(first_buy and second_buy and shopper.passives == ["vendor_gift", "vendor_gift"] and shopper.cash == 40 - 6 - price_after and price_after == 5, "C58: comprada dos veces se acumula; la segunda ya cuesta $1 menos")

static func _tutorial_game(seed_value: int):
	var game := Game.new(seed_value)
	game.begin_tutorial(seed_value)
	Profile.apply(game)
	return game

static func _group_all(game, ids: Array) -> bool:
	return game.form_group(ids)

static func _test_tutorial_game(check: Callable) -> void:
	var game = _tutorial_game(901)
	check.call(game.tutorial and game.phase == "level_intro" and game.campaign.is_empty() and game.level_encounters.map(func(e): return e.target) == [40, 70, 125] and game.is_boss(2) and game.boss_name() == "El Vendedor", "Tutorial: tres encuentros fijos (40, 70 y el vendedor con 125), sin campaña")
	check.call(not game.snapshot().has("tutorial") and Game.new(901).tutorial == false, "Tutorial: es solo estado en memoria y una jugada común no lo es")
	game.begin_level()
	var rng_before: int = game.rng.state
	check.call(game.roll() and game.dice.map(func(d): return d.value) == [4, 4, 2, 6, 3], "Tutorial: la primera tirada guionada de la mano 1 sale como dice el guion")
	for id in [2, 3, 4]: game.move_die(id, "cup")
	check.call(game.roll() and game.dice.map(func(d): return d.value) == [4, 4, 4, 1, 5] and game.rng.state == rng_before, "Tutorial: se conservan los 4 y los otros tres salen 4, 1, 5 sin gastar azar de la jugada")
	check.call(_group_all(game, [0, 1, 2]) and game.groups[0].category == "Trío", "Tutorial: se arma el trío de cuatros")
	var expected: int = game.preview().total
	check.call(game.score_hand() and game.last_score.total == expected and game.points == expected, "Tutorial: la previsión coincide con la anotación de la mano 1")
	check.call(game.phase == "hand_result" and game.points < 40 and game.next_hand(), "Tutorial: con la mano 1 todavía falta para el objetivo y se juega la segunda")
	check.call(game.roll() and game.dice.map(func(d): return d.value) == [6, 6, 3, 3, 2], "Tutorial: la mano 2 empieza con 6 6 3 3 2")
	game.move_die(4, "cup")
	check.call(game.roll() and game.dice.map(func(d): return d.value) == [6, 6, 3, 3, 3], "Tutorial: tirar el último dado da el 3 del full")
	check.call(_group_all(game, [0, 1, 2, 3, 4]) and game.groups[0].category == "Full", "Tutorial: se arma el full")
	expected = game.preview().total
	var before_points: int = game.points
	check.call(game.score_hand() and game.points - before_points == expected and game.points >= 40 and game.rng.state == rng_before, "Tutorial: se llega al objetivo de 40 y el azar principal sigue intacto")
	check.call(game.close_encounter() and game.phase == "reward", "Tutorial: se gana el primer encuentro y se llega a la elección")
	# La tienda es forzada, fija, con $20 y sin tocar el azar principal.
	game = _tutorial_game(901)
	game.begin_level()
	game.points = 50
	game.phase = "hand_result"
	game.close_encounter()
	var rng_state: int = game.rng.state
	check.call(game.open_shop() and game.cash == Tutorial.SHOP_CASH and game.rng.state == rng_state, "Tutorial: la tienda arranca con $20 y no consume el azar de la jugada")
	var stock_a: Dictionary = game.shop_state.duplicate(true)
	var other = _tutorial_game(902)
	other.begin_level()
	other.points = 50
	other.phase = "hand_result"
	other.close_encounter()
	other.open_shop()
	var strip := func(state: Dictionary) -> Array:
		var rows: Array = []
		for section in ["coins", "components", "numbers", "stickers"]:
			for slot in state[section].slots:
				var row: Dictionary = slot.duplicate(true)
				row.erase("offer_id")
				rows.append(row)
		return rows
	check.call(strip.call(stock_a) == strip.call(other.shop_state), "Tutorial: la tienda es siempre la misma con cualquier semilla de jugada")
	check.call(stock_a.coins.slots.any(func(s): return s.get("kind") == "coin") and stock_a.components.slots.any(func(s): return not s.is_empty()) and stock_a.numbers.slots.any(func(s): return s.get("kind") == "face") and stock_a.numbers.slots.any(func(s): return s.get("kind") == "global") and stock_a.stickers.slots.any(func(s): return s.get("kind") == "sticker"), "Tutorial: la tienda muestra monedas, componentes, un cambio de cara, una mejora de número y stickers")
	check.call(not stock_a.coins.slots.any(func(s): return s.get("effect", {}).get("coin_id", "") == "vendor_gift"), "Tutorial: la moneda del regalo no sale en la tienda del tutorial")
	game.unlocked_coins = ["vendor_gift"]
	check.call(game.leave_shop() and game.rival == 1 and game.phase == "play", "Tutorial: se sale de la tienda al segundo encuentro")
	# Segundo encuentro: azar normal, sin guion.
	var control = _tutorial_game(901)
	check.call(game.roll() and game.rival == 1 and game.phase == "play", "Tutorial: el segundo encuentro tira con el azar normal")
	check.call(Tutorial.rolls_for(1, 0, 5) == [4, 4, 2, 6, 3] and Tutorial.rolls_for(1, 0, 3).is_empty() and Tutorial.rolls_for(3, 0, 5).is_empty() and control.tutorial, "Tutorial: el guion solo responde a la tirada y la cantidad de dados que espera")
	# Fuera del tutorial nada se guiona aunque se parezca.
	var normal := Game.new(901)
	normal.begin_run(901)
	normal.begin_level()
	normal.roll()
	check.call(not normal.tutorial and normal.rng.state != Game.new(901).rng.state, "Tutorial: una jugada común sortea con el azar de siempre")

static func _test_tutorial_steps(check: Callable) -> void:
	var base := {"phase": "play", "rival": 0, "hand": 1, "rolls_made": 0, "grouped": 0, "cup": [], "selected": [], "points": 0, "target": 40}
	var step: Dictionary = Tutorial.step(base)
	check.call(step.id == "h1_roll_0" and Tutorial.allows(step, "roll") and not Tutorial.allows(step, "score") and not step.notes.is_empty(), "Guion: el primer paso pide tirar y bloquea lo demás")
	var ctx := base.duplicate()
	ctx.rolls_made = 1
	step = Tutorial.step(ctx)
	check.call(step.id == "h1_select_throw" and Tutorial.selection_matches(step.to_cup_select, [4, 2, 3]) and not Tutorial.selection_matches(step.to_cup_select, [0, 1]), "Guion: después de tirar pide elegir los tres dados a volver a tirar")
	ctx.cup = [2, 3, 4]
	check.call(Tutorial.step(ctx).id == "h1_roll_1" and Tutorial.allows(Tutorial.step(ctx), "roll"), "Guion: con los dados en el vaso pide tirar otra vez")
	ctx.rolls_made = 2
	ctx.cup = []
	step = Tutorial.step(ctx)
	check.call(step.id == "h1_group" and Tutorial.selection_matches(step.group_select, [2, 0, 1]) and Tutorial.allows(step, "group") and Tutorial.allows(step, "select"), "Guion: después de la segunda tirada pide armar el trío")
	ctx.grouped = 1
	check.call(Tutorial.step(ctx).id == "h1_score" and Tutorial.allows(Tutorial.step(ctx), "score"), "Guion: con el grupo armado pide anotar")
	var hand_result := {"phase": "hand_result", "rival": 0, "hand": 1, "points": 20, "target": 40}
	check.call(Tutorial.step(hand_result).id == "next_hand_1" and Tutorial.step(hand_result.merged({"points": 41}, true)).id == "close_1", "Guion: tras anotar pide la segunda mano o cerrar el encuentro")
	check.call(Tutorial.step({"phase": "reward", "rival": 0}).id == "reward_1" and Tutorial.allows(Tutorial.step({"phase": "reward", "rival": 0}), "open_shop") and not Tutorial.allows(Tutorial.step({"phase": "reward", "rival": 0}), "skip_shop"), "Guion: la tienda es obligatoria")
	var shop := Tutorial.step({"phase": "shop", "rival": 0})
	var zones_ok := true
	for entry in shop.notes: zones_ok = zones_ok and Tutorial.ZONES.has(entry.zone)
	check.call(shop.id == "shop" and shop.notes.size() >= 5 and shop.get("blocking", false) and zones_ok and Tutorial.allows(shop, "anything"), "Guion: la tienda tiene un cartel por sección (stickers, números, componentes, monedas) y deja comprar")
	check.call(Tutorial.step({"phase": "play", "rival": 1, "hand": 1, "rolls_made": 0}).is_empty() and Tutorial.step({"phase": "play", "rival": 1}).is_empty(), "Guion: el segundo encuentro es sin guía")
	check.call(Tutorial.step({"phase": "play", "rival": 2, "hand": 1, "rolls_made": 0}).id == "boss_intro" and Tutorial.step({"phase": "play", "rival": 2, "hand": 1, "rolls_made": 1}).is_empty(), "Guion: los carteles del jefe aparecen una vez al empezar su encuentro")
	# Ningún paso queda sin salida: toda combinación de estado de las dos manos tiene un paso que permite algo.
	var dead_ends := 0
	for hand in [1, 2]:
		for rolls in range(4):
			for grouped in range(3):
				for cup in [[], [4], [2, 3, 4]]:
					var probe := {"phase": "play", "rival": 0, "hand": hand, "rolls_made": rolls, "grouped": grouped, "cup": cup, "selected": [], "points": 0, "target": 40}
					var current := Tutorial.step(probe)
					if current.is_empty() or current.allow.is_empty(): dead_ends += 1
	check.call(dead_ends == 0, "Guion: ningún estado de la primera mesa queda sin un paso que deje avanzar (%d sin salida)" % dead_ends)

static func _test_boss_seller(check: Callable) -> void:
	var row := BossCatalog.entry("tutorial_vendedor")
	check.call(not row.is_empty() and row.name == "El Vendedor" and BossCatalog.target_of(row) == 125 and BossRules.valid_rule(BossCatalog.rule_of(row)), "Vendedor: existe en el catálogo con objetivo fijo 125 y regla válida")
	check.call(BossCatalog.ROWS.all(func(r): return r.id != "tutorial_vendedor") and Campaign.prototype().all(func(level): return level.candidates.all(func(c): return c.id != "tutorial_vendedor")), "Vendedor: no está entre los jefes de la campaña ni entra al sorteo")
	check.call(BossCatalog.ROWS.size() == 21 and BossCatalog.power_text("tutorial_vendedor") != "", "Vendedor: el catálogo de campaña sigue con 21 jefes y el poder tiene texto")
	var game = _tutorial_game(903)
	game.begin_level()
	game.rival = 2
	game._start_encounter()
	game.cash = 17
	game.points = 130
	game.phase = "hand_result"
	var reward_cash: int = 17
	check.call(game.is_boss() and game.target() == 125 and game.close_encounter(), "Vendedor: se cierra el encuentro del jefe")
	check.call(game.cash == 0 and game.payout.get("drained", 0) > reward_cash and game.phase == "won", "Vendedor: al finalizar te saca todo el dinero (incluido el cobro) y la jugada termina")
	var campaign := Game.new(904)
	campaign.begin_campaign(904)
	campaign.begin_level()
	campaign.cash = 17
	campaign.points = 40
	campaign.phase = "hand_result"
	campaign.close_encounter()
	check.call(campaign.cash > 17, "Vendedor: en la campaña nadie te saca la plata")

static func _find(node: Node, node_name: String):
	return node.find_child(node_name, true, false)

static func _test_ui(scene, folder: String, check: Callable) -> void:
	scene.detail.hide()
	scene.cancel_navigation()
	var old_store = scene.profile_store
	var old_campaign: bool = scene.campaign_mode
	scene.profile_store = ProfileStore.new(folder + "/ui")
	scene.profiles_enabled = true
	scene.campaign_mode = true
	scene.preferences["last_profile"] = 0
	scene.game.return_to_menu()
	scene.session_started = false
	scene.pending_tutorial_choice = false
	scene.render()
	# Pantalla inicial.
	var column = _find(scene.ui, "MainMenu")
	check.call(column != null and UI.find_button(scene.ui, "Nueva partida") != null and UI.find_button(scene.ui, "Opciones") != null and UI.find_button(scene.ui, "Salir del juego") != null and UI.find_button(scene.ui, "Continuar") == null, "Menú: Nueva jugada, Opciones y Salir del juego, sin Continuar")
	check.call(UI.find_button(scene.ui, "Nueva partida debug") != null and column.position.x < 720 and _find(scene.ui, "MenuMate") != null and _find(scene.ui, "MenuHand") != null, "Menú: la columna va a la izquierda y el mate y la mano de Dios quedan en el bar (debug solo en desarrollo)")
	check.call(not _find(scene.ui, "NewRun").focus_mode == Control.FOCUS_NONE, "Menú: se navega con el teclado (los botones toman foco)")
	scene.request_navigation("quit")
	check.call(scene.confirmation.visible and scene.pending_navigation == "quit", "Menú: Salir del juego pide confirmación")
	scene.cancel_navigation()
	# Primera jugada: se crea la Partida guardada 1.
	UI.find_button(scene.ui, "Nueva partida").pressed.emit()
	check.call(scene.pending_tutorial_choice and UI.find_button(scene.ui, "Sí, jugar el tutorial") != null and UI.find_button(scene.ui, "No, ir a la campaña") != null and not scene.session_started, "Menú: cada jugada nueva pregunta por el tutorial")
	UI.find_button(scene.ui, "Volver").pressed.emit()
	check.call(not scene.pending_tutorial_choice and UI.find_button(scene.ui, "Nueva partida") != null, "Menú: la pregunta se puede cancelar")
	UI.find_button(scene.ui, "Nueva partida").pressed.emit()
	UI.find_button(scene.ui, "No, ir a la campaña").pressed.emit()
	check.call(scene.game.phase == "level_intro" and not scene.game.tutorial and scene.profile_slot == 1 and scene.profile_store.read(1).exists and scene.preferences.last_profile == 1, "Partidas: la primera jugada crea la Partida guardada 1 y la deja como última usada")
	# Abandonar no escribe nada; terminar sí.
	scene.game.begin_level()
	scene.render()
	var empty_stats: Dictionary = scene.profile_store.read(1).data
	Flow.click(scene, "Abandonar partida")
	scene.confirmation.get_ok_button().pressed.emit()
	check.call(scene.game.phase == "menu" and scene.profile_store.read(1).data == empty_stats, "Partidas: abandonar una jugada no escribe estadísticas")
	scene.start_new_run(777)
	scene.game.begin_level()
	scene.game.phase = "lost"
	scene.render()
	var after_loss: Dictionary = scene.profile_store.read(1).data
	check.call(after_loss.plays == 1 and after_loss.wins == 0 and after_loss.best_level == 1, "Partidas: perder una jugada suma jugadas y nivel alcanzado")
	scene.render()
	check.call(scene.profile_store.read(1).data == after_loss, "Partidas: volver a dibujar la derrota no suma dos veces")
	scene.start_new_run(-1, true)
	scene.game.phase = "won"
	scene.game.payout = preload("res://scripts/rules.gd").reward(0, 55, 40, 1)
	scene.render()
	check.call(scene.profile_store.read(1).data == after_loss, "Partidas: la jugada debug no escribe nada")
	# Panel de partidas en Opciones.
	scene.game.return_to_menu()
	scene.session_started = false
	scene.render()
	scene.show_options()
	var profiles_button: Button = _find(scene.settings_panel, "Profiles")
	check.call(profiles_button != null, "Opciones: hay un botón de Partidas guardadas")
	profiles_button.pressed.emit()
	var panel: Control = _find(scene.detail, "ProfilesPanel")
	check.call(panel != null and _find(panel, "Slot_1") != null and _find(panel, "Slot_2") != null and _find(panel, "Slot_3") != null, "Opciones: el panel muestra las tres ranuras")
	check.call("Partidas: 1" in _all_text(_find(panel, "Slot_1")) and "en uso" in _all_text(_find(panel, "Slot_1")) and "Vacía" in _all_text(_find(panel, "Slot_2")), "Opciones: cada ranura muestra sus datos y cuál está en uso")
	check.call(_find(panel, "Delete_2").disabled and not _find(panel, "Delete_1").disabled, "Opciones: no se puede borrar una ranura vacía")
	_find(panel, "Load_2").pressed.emit()
	check.call(scene.profile_store.read(2).exists and scene.preferences.last_profile == 2 and scene.pending_tutorial_choice and scene.game.phase == "menu" and not scene.detail.visible, "Opciones: Cargar una ranura vacía la crea, la deja en uso y arranca la pregunta del tutorial")
	scene.pending_tutorial_choice = false
	scene.show_profiles()
	panel = _find(scene.detail, "ProfilesPanel")
	_find(panel, "Delete_2").pressed.emit()
	check.call(scene.confirmation.visible and scene.pending_navigation == "delete1_2", "Opciones: borrar pide una primera confirmación")
	scene.confirm_navigation()
	check.call(scene.confirmation.visible and scene.pending_navigation == "delete2_2" and scene.profile_store.read(2).exists, "Opciones: y una segunda («¿Estás muy, muy seguro?») antes de borrar")
	scene.confirm_navigation()
	check.call(not scene.profile_store.read(2).exists and scene.preferences.last_profile == 0, "Opciones: tras las dos confirmaciones se borra y deja de ser la última usada")
	scene.detail.hide()
	scene.remember_profile(1)
	# Cargar con una jugada en curso avisa que se pierde.
	scene.start_new_run(778)
	scene.game.begin_level()
	scene.request_load_profile(1)
	check.call(scene.confirmation.visible and scene.pending_navigation == "load_1" and scene.game.phase == "play", "Opciones: cargar con una jugada en curso avisa que se pierde")
	scene.cancel_navigation()
	check.call(scene.detail.visible, "Opciones: al cancelar se vuelve al panel de partidas")
	scene.detail.hide()
	# Tutorial de punta a punta.
	scene.game.return_to_menu()
	scene.session_started = false
	scene.start_new_run(-1, false, true)
	check.call(scene.game.tutorial and scene.game.phase == "level_intro" and _find(scene.ui, "SellerIntro") != null and scene.background.shop_mode, "Tutorial: empieza con el vendedor presentándose")
	check.call(UI.text_in(scene.ui, "Veo que querés desafiar a Dios") and UI.find_button(scene.ui, "Empezar el tutorial") != null, "Tutorial: el vendedor dice su frase")
	UI.find_button(scene.ui, "Empezar el tutorial").pressed.emit()
	await _play_tutorial_first_encounter(scene, check)
	# Fin del tutorial: logro y moneda.
	check.call(scene.game.phase == "shop" and scene.game.cash == Tutorial.SHOP_CASH and scene.tutorial_step().id == "shop", "Tutorial: la tienda guiada empieza con $20 y sus carteles")
	var overlay = _find(scene.ui, "TutorialOverlay")
	check.call(overlay != null and overlay.open and overlay.continue_button != null and overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "Tutorial: los carteles de la tienda tapan la pantalla hasta apretar Continuar")
	overlay.continue_button.pressed.emit()
	overlay = _find(scene.ui, "TutorialOverlay")
	check.call(not overlay.open and overlay.help_button != null and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Tutorial: con un solo Continuar se cierran todos y queda el botón «?»")
	overlay.help_button.pressed.emit()
	check.call(_find(scene.ui, "TutorialOverlay").open, "Tutorial: «?» vuelve a mostrar los carteles")
	scene.tutorial_seen.append("shop")
	scene.render()
	scene.game.phase = "lost"
	scene.render()
	var final_stats: Dictionary = scene.profile_store.read(1).data
	check.call(_find(scene.ui, "TutorialEnd") != null and UI.text_in(scene.ui, "TUTORIAL COMPLETADO") and UI.text_in(scene.ui, "El regalo del vendedor"), "Tutorial: la pantalla de cierre anuncia el logro y la moneda")
	check.call(final_stats.achievements == ["tutorial_completed"] and final_stats.unlocked_coins == ["vendor_gift"] and final_stats.plays == after_loss.plays and final_stats.wins == after_loss.wins, "Tutorial: el logro y la moneda se guardan y no suman jugadas")
	check.call(scene.game.unlocked_coins == ["vendor_gift"], "Tutorial: la partida en curso ya conoce la moneda desbloqueada")
	# La jugada siguiente de esa partida puede ofrecer la moneda; otra partida no.
	UI.find_button(scene.ui, "Nueva partida").pressed.emit()
	check.call(scene.game.phase == "menu" and scene.pending_tutorial_choice, "Tutorial: «Nueva jugada» vuelve a preguntar por el tutorial")
	UI.find_button(scene.ui, "No, ir a la campaña").pressed.emit()
	check.call(scene.game.unlocked_coins == ["vendor_gift"], "Partidas: la jugada siguiente de la partida con el logro trae la moneda desbloqueada")
	scene.profile_store.create(3)
	scene.remember_profile(3)
	scene.game.return_to_menu()
	scene.session_started = false
	scene.start_new_run(779)
	check.call(scene.game.unlocked_coins.is_empty() and scene.profile_store.read(3).exists, "Partidas: otra partida sin el logro no la tiene (y se crea al usarla)")
	# Abandonar el tutorial no da logro.
	scene.remember_profile(3)
	scene.game.return_to_menu()
	scene.session_started = false
	scene.start_new_run(-1, false, true)
	scene.game.begin_level()
	scene.render()
	Flow.click(scene, "Abandonar partida")
	scene.confirmation.get_ok_button().pressed.emit()
	check.call(scene.profile_store.read(3).data.achievements.is_empty(), "Tutorial: abandonarlo no da el logro")
	scene.profile_store = old_store
	scene.profiles_enabled = false
	scene.campaign_mode = old_campaign
	scene.preferences["last_profile"] = 0
	scene.game.return_to_menu()
	scene.session_started = false
	scene.pending_tutorial_choice = false
	scene.render()

static func _all_text(node: Node) -> String:
	var text := ""
	if node is Label: text += node.text + "\n"
	for child in node.get_children(): text += _all_text(child)
	return text

static func _dismiss(scene) -> void:
	var step: Dictionary = scene.tutorial_step()
	if not step.is_empty() and not step.notes.is_empty() and step.id not in scene.tutorial_seen:
		scene.tutorial_seen.append(step.id)
		scene.render()

## Juega el primer encuentro siguiendo solo lo que permite cada paso del guion y comprueba los bloqueos.
static func _play_tutorial_first_encounter(scene, check: Callable) -> void:
	check.call(scene.tutorial_step().id == "h1_roll_0" and not scene.tutorial_notes_open() and _find(scene.ui, "TutorialOverlay").open and _find(scene.ui, "TutorialOverlay").mouse_filter == Control.MOUSE_FILTER_IGNORE and _find(scene.ui, "TutorialOverlay").continue_button == null, "Tutorial: los carteles de la mesa señalan sin tapar ni pedir Continuar")
	scene.toggle_die(0)
	check.call(scene.selected.is_empty() and not scene.tutorial_allows("score") and not scene.tutorial_allows("group"), "Tutorial: con una acción obligatoria pendiente las demás quedan bloqueadas")
	var throw_button = UI.find_button(scene.ui, "TIRAR (3)")
	check.call(throw_button != null and not throw_button.disabled and UI.find_button(scene.ui, "ANOTAR MANO").disabled, "Tutorial: tirar está habilitado y anotar bloqueado")
	_dismiss(scene)
	Flow.click(scene, "TIRAR (3)")
	check.call(scene.game.dice.map(func(d): return d.value) == [4, 4, 2, 6, 3] and scene.tutorial_step().id == "h1_select_throw", "Tutorial: sale la tirada guionada y el paso pide elegir los tres dados")
	_dismiss(scene)
	scene.toggle_die(0)
	check.call(not scene.tutorial_allows("to_cup"), "Tutorial: con dados equivocados «Al vaso» no se permite")
	scene.selected.clear()
	for id in [2, 3, 4]: scene.toggle_die(id)
	check.call(scene.tutorial_allows("to_cup"), "Tutorial: con los tres dados del cartel «Al vaso» se permite")
	Flow.click(scene, "Al vaso →")
	_dismiss(scene)
	check.call(scene.tutorial_step().id == "h1_roll_1", "Tutorial: con los dados en el vaso pide tirar de nuevo")
	Flow.click(scene, "TIRAR (2)")
	_dismiss(scene)
	check.call(scene.game.dice.map(func(d): return d.value) == [4, 4, 4, 1, 5] and scene.tutorial_step().id == "h1_group", "Tutorial: salió el trío y el paso pide armarlo")
	check.call(UI.find_button(scene.ui, "Armar grupo").disabled, "Tutorial: «Armar grupo» sigue bloqueado hasta elegir los dados del cartel")
	for id in [0, 1, 2]: scene.toggle_die(id)
	Flow.click(scene, "Armar grupo")
	_dismiss(scene)
	check.call(scene.game.groups.size() == 1 and scene.tutorial_step().id == "h1_score", "Tutorial: el grupo queda armado y el paso pide anotar")
	var forecast: int = scene.game.preview().total
	Flow.click(scene, "ANOTAR MANO")
	check.call(scene.game.points == forecast and scene.game.phase == "hand_result", "Tutorial: la previsión de la libreta es lo que se anota")
	_dismiss(scene)
	check.call(scene.tutorial_step().id == "next_hand_1" and UI.find_button(scene.ui, "Cerrar y cobrar") == null, "Tutorial: sin llegar al objetivo pide jugar la segunda mano")
	Flow.click(scene, "Jugar segunda mano")
	_dismiss(scene)
	Flow.click(scene, "TIRAR (3)")
	_dismiss(scene)
	check.call(scene.game.dice.map(func(d): return d.value) == [6, 6, 3, 3, 2] and scene.tutorial_step().id == "h2_select_throw", "Tutorial: la segunda mano arranca con 6 6 3 3 2 y pide tirar el último dado")
	scene.toggle_die(4)
	Flow.click(scene, "Al vaso →")
	_dismiss(scene)
	Flow.click(scene, "TIRAR (2)")
	_dismiss(scene)
	for id in range(5): scene.toggle_die(id)
	Flow.click(scene, "Armar grupo")
	_dismiss(scene)
	forecast = scene.game.preview().total
	var before_points: int = scene.game.points
	Flow.click(scene, "ANOTAR MANO")
	check.call(scene.game.points - before_points == forecast and scene.game.points >= 40, "Tutorial: la segunda mano alcanza el objetivo con la previsión exacta")
	_dismiss(scene)
	check.call(scene.tutorial_step().id == "close_1", "Tutorial: al llegar al objetivo pide cerrar y cobrar")
	Flow.click(scene, "Cerrar y cobrar")
	_dismiss(scene)
	check.call(scene.game.phase == "reward" and UI.find_button(scene.ui, "Seguir sin tienda →").disabled and not UI.find_button(scene.ui, "Ir a la tienda →").disabled, "Tutorial: tras ganar la tienda es obligatoria")
	Flow.click(scene, "Ir a la tienda →")
