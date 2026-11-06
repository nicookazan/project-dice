extends RefCounted
## Compatibility only: current gameplay has no per-die numeric upgrade state.
const Numbers = preload("res://scripts/number_upgrades.gd")

static func global_offer(offer: Dictionary) -> void:
	if offer.get("kind") != "local": return
	offer.kind = "global"
	var rarity: String = offer.get("rarity", "common")
	if Numbers.GLOBAL_RANGES.has(rarity) and offer.get("effect") is Dictionary and offer.effect.get("amount") is int:
		var bounds: Array = Numbers.GLOBAL_RANGES[rarity]
		offer.effect.amount = clampi(offer.effect.amount, bounds[0], bounds[1])

static func global_numbers(game: Dictionary) -> String:
	if not game.get("dice") is Array or not Numbers.valid_points(game.get("global_points")): return "mejoras numéricas anteriores inválidas"
	for die in game.dice:
		if not die is Dictionary or not Numbers.valid_points(die.get("local_points", {})): return "mejora numérica anterior inválida"
		for number in die.get("local_points", {}):
			var amount: int = die.local_points[number]
			if amount > 0 and not Numbers.apply_global(game.global_points, int(number), amount): return "desborde de mejora anterior"
		die.erase("local_points")
	if game.get("shop_tables") is Dictionary and game.shop_tables.get("numbers") is Array:
		for offer in game.shop_tables.numbers:
			if offer is Dictionary: global_offer(offer)
	if game.get("shop_state") is Dictionary and game.shop_state.get("numbers") is Dictionary and game.shop_state.numbers.get("slots") is Array:
		for offer in game.shop_state.numbers.slots:
			if offer is Dictionary: global_offer(offer)
	if game.get("pending_purchase") is Dictionary and game.pending_purchase.get("offer") is Dictionary and game.pending_purchase.offer.get("kind") == "local":
		game.pending_purchase = {}
		if game.phase == "purchase_target": game.phase = "shop"
	return ""

## v6 -> v7: impulses become a list, new per-hand coin counters, per-gem protection mark,
## staged coin stock tables. Wallet, inventory, stock and RNG are never touched.
static func coins_v7(game: Dictionary) -> String:
	# Idempotent: only fills what an older save lacks.
	if not game.get("dice") is Array: return "dados anteriores inválidos"
	if not game.has("impulses"):
		if not game.get("boost") is bool: return "impulso anterior inválido"
		game["impulses"] = ["boost"] if game.boost else []
	game.erase("boost")
	for key in ["double_mult", "free_reroll_used"]:
		if not game.has(key): game[key] = false
	for key in ["free_reroll_tokens", "free_renewals"]:
		if not game.has(key): game[key] = 0
	for die in game.dice:
		if not die is Dictionary: return "dado anterior inválido"
		if not die.has("shell_saved"): die["shell_saved"] = false
	if game.get("shop_tables") is Dictionary and not game.shop_tables.has("coin_type_weights"):
		var staged: Dictionary = preload("res://scripts/shop.gd").default_tables()
		game.shop_tables["coins"] = staged.coins
		game.shop_tables["coin_type_weights"] = staged.coin_type_weights
		game.shop_tables["coin_rarity_weights"] = staged.coin_rarity_weights
	return ""

## v8 -> v9 (etapa de monedas): campos nuevos de la partida y tabla de monedas de la tienda con el catálogo vigente.
## Idempotente: solo rellena lo que falta. Semilla, azar, plata, inventario y ofertas ya generadas no se tocan.
static func coins_v9(game: Dictionary) -> String:
	const Shop = preload("res://scripts/shop.gd")
	var defaults := {"hand_mult_bonus": 0, "hand_points_bonus": 0, "visit_discount": 0.0, "boss_shield_active": false, "once_coins_seen": [], "pending_coin_pack": {}}
	for key in defaults:
		if not game.has(key): game[key] = defaults[key]
	# Las tablas guardadas traen precios de rarezas viejas y no incluyen las monedas nuevas. Solo se
	# reconstruyen las de forma estándar (monedas de peso 1); las tablas de laboratorio se respetan.
	if game.get("shop_tables") is Dictionary and game.shop_tables.get("coins") is Array:
		var standard := true
		for entry in game.shop_tables.coins:
			if not entry is Dictionary or entry.get("kind") != "coin" or entry.get("weight") != 1.0: standard = false
		if standard:
			game.shop_tables["coins"] = Shop.default_tables().coins
			if not game.shop_tables.has("coin_packs"): game.shop_tables["coin_packs"] = Shop.coin_pack_table()
	return ""

## v7 -> v8: los ids de prueba pasan al catálogo de jefes (por nivel y posición) y aparece `boss_state`.
## Se conservan semilla, estado del azar, cartera, inventario y progreso; la regla pasa a ser la del jefe del catálogo.
static func bosses_v8(game: Dictionary) -> String:
	const Catalog = preload("res://scripts/boss_catalog.gd")
	const BossRules = preload("res://scripts/boss_rules.gd")
	const Campaign = preload("res://scripts/campaign.gd")
	if game.has("boss_state"): return ""
	game["boss_state"] = {}
	if not game.get("campaign") is Array or game.campaign.is_empty(): return ""
	if not game.get("selected_bosses") is Dictionary or not game.get("completed_encounters") is Array or not game.get("level_index") is int or not game.get("level_encounters") is Array: return "campaña anterior inválida"
	var selected := {}
	for key in game.selected_bosses:
		var mapped: String = Catalog.map_legacy_id(str(game.selected_bosses[key]))
		if mapped == "": return "jefe de campaña anterior desconocido"
		selected[key] = mapped
	var completed: Array = []
	for id in game.completed_encounters:
		var mapped: String = Catalog.map_legacy_id(str(id))
		if mapped == "": return "encuentro anterior desconocido"
		completed.append(mapped)
	var levels: Array = Campaign.prototype()
	if game.level_index < 0 or game.level_index >= levels.size(): return "nivel anterior fuera de rango"
	var chosen := Campaign.candidate(levels[game.level_index], selected.get(str(game.level_index), ""))
	if chosen.is_empty(): return "jefe del nivel actual desconocido"
	game.campaign = levels
	game.selected_bosses = selected
	game.completed_encounters = completed
	game.level_encounters = Campaign.encounters(levels[game.level_index], chosen)
	game.boss_rule = chosen.rule.duplicate(true)
	# El objetivo del jefe cambia con el catálogo: un cobro ya acreditado no se invalida.
	if game.get("phase") in ["reward", "repair", "won", "shop", "purchase_target", "sticker_choice", "coin_choice"] and game.get("points") is int and game.get("rival") is int and game.rival < game.level_encounters.size():
		game.points = maxi(game.points, game.level_encounters[game.rival].target)
	if game.get("rival") is int and game.rival >= 0 and game.rival < game.level_encounters.size() and game.level_encounters[game.rival].kind == "boss":
		var ids: Array = []
		if game.get("coin_inventory") is Dictionary and game.coin_inventory.get("equipped") is Array:
			for coin in game.coin_inventory.equipped:
				if coin is Dictionary: ids.append(str(coin.get("coin_id", "")))
		game.boss_state = BossRules.draw_state(game.boss_rule, int(game.get("run_seed", 0)), game.level_index, game.rival, ids)
	return ""
