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
