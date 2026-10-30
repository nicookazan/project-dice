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
