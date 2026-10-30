extends RefCounted
const Game = preload("res://scripts/game.gd")
const Shop = preload("res://scripts/shop.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const StickerTests = preload("res://tests/sticker_tests.gd")

static func tables() -> Dictionary:
	# Explicit test prices/weights, never loaded by normal gameplay.
	return {
		"coins": [
			{"kind": "coin", "effect": {"coin_id": "full"}, "price": 4, "weight": 1},
			{"kind": "coin", "effect": {"coin_id": "roll"}, "price": 2, "weight": 1}],
		"components": [
			{"kind": "element", "effect": {"id": "fire"}, "price": 3, "weight": 1},
			{"kind": "material", "effect": {"id": "steel"}, "price": 4, "weight": 1},
			{"kind": "shell", "effect": {"id": "ruby", "intact": true}, "price": 5, "weight": 1}],
		"numbers": [
			{"kind": "global", "effect": {"number": 4, "amount": 2}, "rarity": "common", "price": 3, "weight": 1},
			{"kind": "global", "effect": {"number": 4, "amount": 5}, "rarity": "rare", "price": 8, "weight": 1},
			{"kind": "face", "effect": {"number": 6}, "rarity": "common", "price": 4, "weight": 1}],
		"stickers": [
			{"kind": "sticker", "effect": {"id": "trio"}, "price": 4, "weight": 1},
			{"kind": "pack", "effect": {"pack_kind": "choose_one", "pool": ["trio", "full", "pair_loose", "poker"]}, "price": 7, "weight": 1},
			{"kind": "pack", "effect": {"pack_kind": "receive_two", "pool": ["trio", "full", "pair_loose"]}, "price": 5, "weight": 1}],
		"numeric_rarity_weights": {"common": 3, "rare": 1}
	}

static func game_at_shop(seed_value: int = 120):
	var game = Game.new(seed_value)
	game.shop_tables = tables()
	game.sticker_catalog = StickerTests.definitions()
	game.phase = "reward"
	game.cash = 100
	game.open_shop()
	return game

static func run(check: Callable) -> Dictionary:
	_test_generation(check)
	return _test_stock(check)

static func _test_generation(check: Callable) -> void:
	var game = game_at_shop()
	var ids: Dictionary = {}
	for section in Shop.SIZES:
		check.call(game.shop_state[section].slots.size() == Shop.SIZES[section], "shop: exact slot count " + section)
		for offer in game.shop_state[section].slots:
			check.call(offer.has("kind") and offer.has("effect") and offer.has("price") and not ids.has(offer.offer_id), "shop: offers have distinct identities and concrete payloads")
			ids[offer.offer_id] = true
	check.call(game.shop_state.stickers.slots[0].kind == "sticker" and game.shop_state.stickers.slots[1].kind == "pack", "shop: guaranteed individual plus packet, no swapped quotas")
	var pack: Dictionary = game.shop_state.stickers.slots[1]
	var unique: Dictionary = {}
	for id in pack.effect.items: unique[id] = true
	check.call(unique.size() == pack.effect.items.size() and unique.size() in [2, 3] and not pack.effect.has("pool"), "shop: packet resolves distinct contents once at generation")
	var identical = game_at_shop()
	check.call(identical.snapshot() == game.snapshot(), "shop: same seed and actions reproduce complete stock and RNG")
	game.refresh_shop("components")
	identical.refresh_shop("components")
	check.call(identical.snapshot() == game.snapshot(), "shop: matching section renewals reproduce stock and RNG")
	var before := game.snapshot()
	var offer: Dictionary = game.shop_state.components.slots[0]
	for iteration in range(20): game.inspect_shop_offer("components", offer.offer_id)
	var copy: Dictionary = game.inspect_shop_offer("components", offer.offer_id)
	copy.effect.id = "corrupt"
	check.call(game.snapshot() == before, "shop: repeated inspection is detached and never charges or rerolls")
	var one_type := tables()
	one_type.coins = [one_type.coins[1]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 121
	var generated := Shop.generate("coins", one_type, StickerTests.definitions(), [], rng.state, 0)
	check.call(generated.section.slots.all(func(item): return item.effect.coin_id == "roll"), "shop: all four coin slots may be consumables without guaranteed passive slots")
	one_type.coins = [tables().coins[0]]
	generated = Shop.generate("coins", one_type, StickerTests.definitions(), [], rng.state, 0)
	check.call(generated.section.slots[0].effect.coin_id == "full" and generated.section.slots.filter(func(item): return item.is_empty()).size() == 3, "shop: a single eligible passive fills one slot without repeating it in the other three")
	var owned := Shop.generate("coins", one_type, StickerTests.definitions(), ["full"], rng.state, 0)
	check.call(owned.section.slots.all(func(item): return item.is_empty()) and owned.rng_state == rng.state, "shop: already-owned passive cannot be offered and empty pool consumes no RNG")
	var unique_passives := true
	var stock_tables := Shop.default_tables()
	for seed_value in range(64):
		rng.seed = seed_value
		var stock := Shop.generate("coins", stock_tables, {}, ["even", "full"], rng.state, 0)
		var seen: Array = []
		for item in stock.section.slots:
			if item.is_empty(): continue
			var id: String = item.effect.coin_id
			if id in preload("res://scripts/coins.gd").PASSIVES:
				if id in seen or id in ["even", "full"]: unique_passives = false
				seen.append(id)
	check.call(unique_passives, "shop: mixed stock never repeats a passive or offers owned ones across 64 seeds")
	var legacy = Game.new(125)
	legacy.phase = "shop"
	legacy.cash = 100
	legacy.offers = ["full", "full", "roll", "roll"]
	check.call(legacy.buy(0) and legacy.cash == 96 and legacy.passives == ["full"] and legacy.shop_state.coins.slots[1].is_empty() and legacy.shop_state.coins.slots[2].effect.coin_id == "roll" and legacy.shop_state.coins.slots[3].effect.coin_id == "roll", "shop: buying from legacy duplicated stock removes other copies of that passive while preserving repeat consumables")
	var numeric := tables()
	numeric.numbers = [numeric.numbers[0]]
	numeric.numeric_rarity_weights = {"common": 1}
	generated = Shop.generate("numbers", numeric, StickerTests.definitions(), [], rng.state, 0)
	check.call(generated.section.slots.all(func(item): return item.kind == "global"), "shop: numeric slots impose no quota for global/local/face")
	var later = game_at_shop()
	later.rival = 1
	later.shop_state = {}
	later.rng.state = game_at_shop().rng.state
	var early = game_at_shop()
	early.shop_state = {}
	early.rng.state = later.rng.state
	check.call(early.generate_offers() and later.generate_offers() and early.shop_state.numbers == later.shop_state.numbers, "shop: numeric rarity weights do not depend on level or rival")
	var no_balance = Game.new(122)
	no_balance.phase = "reward"
	check.call(no_balance.open_shop() and no_balance.shop_state.coins.slots.size() == 4 and not no_balance.shop_state.components.configured and not no_balance.shop_state.numbers.configured and not no_balance.shop_state.stickers.configured, "shop: normal game exposes four provisional coin offers without inventing missing commercial tables")
	before = no_balance.snapshot()
	check.call(not no_balance.generate_offers() and not no_balance.open_shop() and no_balance.snapshot() == before, "shop: reopening or calling initial generation cannot reroll existing stock for free")
	for broken in ["negative_weight", "missing_price", "unknown_effect", "missing_rarity", "bad_pack"]:
		var invalid = Game.new(123)
		invalid.phase = "reward"
		invalid.shop_tables = tables()
		invalid.sticker_catalog = StickerTests.definitions()
		match broken:
			"negative_weight": invalid.shop_tables.components[0].weight = -1
			"missing_price": invalid.shop_tables.components[0].erase("price")
			"unknown_effect": invalid.shop_tables.components[0].effect.id = "unknown"
			"missing_rarity": invalid.shop_tables.numeric_rarity_weights = {"legendary": 1}
			"bad_pack": invalid.shop_tables.stickers[1].effect.pool = ["trio", "trio", "trio"]
		before = invalid.snapshot()
		check.call(not invalid.open_shop() and invalid.snapshot() == before, "shop: invalid tables fail atomically without consuming earlier section RNG " + broken)

static func _test_stock(check: Callable) -> Dictionary:
	var game = game_at_shop(124)
	var before := game.snapshot()
	check.call(game.refresh_shop("coins") and game.cash == 99 and game.renewal_price("coins") == 2, "shop: first section renewal costs one")
	check.call(game.shop_state.components == before.shop_state.components and game.shop_state.numbers == before.shop_state.numbers and game.shop_state.stickers == before.shop_state.stickers, "shop: coin renewal preserves every other section")
	var components: Dictionary = game.shop_state.components.duplicate(true)
	var target: String = components.slots[0].offer_id
	check.call(game.commit_shop_offer("components", target) and game.shop_state.components.slots[0].is_empty() and game.shop_state.components.slots[1] == components.slots[1], "shop: successful purchase stock hook empties exactly its identified slot")
	check.call(game.cash == 99 and game.renewal_price("coins") == 2, "shop: committing stock never changes renewal cost or charges on its own")
	before = game.snapshot()
	check.call(not game.commit_shop_offer("components", target) and game.snapshot() == before, "shop: stale or repeated confirmation cannot consume another slot")
	check.call(game.refresh_shop("numbers") and game.cash == 98 and game.renewal_price("numbers") == 2 and game.renewal_price("coins") == 2 and game.renewal_price("components") == 1 and game.shop_state.components.slots[0].is_empty(), "shop: a different section still costs one and preserves other counters and stock")
	check.call(game.refresh_shop("numbers") and game.cash == 96 and game.renewal_price("numbers") == 3 and game.renewal_price("coins") == 2 and game.renewal_price("stickers") == 1, "shop: repeat renewal costs two only in its own section")
	before = game.snapshot()
	check.call(game.refresh_shop("components") and not game.shop_state.components.slots[0].is_empty() and game.shop_state.coins == before.shop_state.coins, "shop: renewing section refills its empty slot, preserves other section")
	var purchased_offer: Dictionary = game.shop_state.coins.slots[0].duplicate(true)
	var cost: int = purchased_offer.price
	var old_price: int = game.renewal_price("coins")
	var wallet: int = game.cash
	check.call(game.buy(0) and game.cash == wallet - cost and game.shop_state.coins.slots[0].is_empty() and game.renewal_price("coins") == old_price, "shop: real coin purchase applies once and leaves renewal counter unchanged")
	var equipped: Dictionary = game.coin_inventory.duplicate(true)
	game.refresh_shop("coins")
	check.call(game.coin_inventory == equipped and not game.shop_state.coins.slots[0].is_empty(), "shop: renewals preserve purchased inventory and refill stock")
	before = game.snapshot()
	check.call(not game.buy(0, purchased_offer.offer_id) and game.snapshot() == before, "shop: stale purchase identity cannot buy a replacement offer after renewal")
	game.cash = game.renewal_price("coins") - 1
	before = game.snapshot()
	check.call(not game.refresh_shop("coins") and game.snapshot() == before, "shop: insufficient renewal funds preserve all stock, RNG and counter")
	game.cash = 100
	var valid_tables: Dictionary = game.shop_tables.duplicate(true)
	game.shop_tables.components[0].weight = -1
	before = game.snapshot()
	check.call(not game.refresh_shop("components") and game.snapshot() == before, "shop: invalid renewal table preserves money, all stock, IDs and RNG")
	game.shop_tables = valid_tables
	before = game.snapshot()
	check.call(not game.refresh_shop("cup") and not game.refresh_shop("unknown") and game.snapshot() == before, "shop: no global, reserved-cup or unknown renewal")
	game.phase = "sticker_choice"
	before = game.snapshot()
	check.call(not game.refresh_shop("coins") and not game.commit_shop_offer("coins", "1") and game.snapshot() == before, "shop: pending choice blocks all section operations")
	game.phase = "shop"
	game.shop_tables.components = [{"kind": "element", "effect": {"id": "fire"}, "price": 3, "weight": 1}]
	game.refresh_shop("components")
	check.call(game.shop_state.components.slots[0].kind == "element", "shop: component section can initially hold only elements")
	game.shop_tables.components = [{"kind": "material", "effect": {"id": "steel"}, "price": 4, "weight": 1}]
	game.refresh_shop("components")
	check.call(game.shop_state.components.slots[0].kind == "material", "shop: renewal may change component family in same slot")
	var snapshot := game.snapshot()
	snapshot.shop_state.components.slots[0].effect.id = "corrupt"
	snapshot.shop_tables.components.clear()
	check.call(game.shop_state.components.slots[0].effect.id == "steel" and not game.shop_tables.components.is_empty(), "shop: snapshot isolates configuration, stock and payloads")
	var evidence := game.snapshot()
	game.leave_shop()
	Fixture.set_values(game, [6, 6, 6, 6, 6])
	game.points = game.target()
	game.score_hand()
	game.close_encounter()
	check.call(game.open_shop() and game.reroll_prices == {"coins": 1, "components": 1, "numbers": 1, "stickers": 1} and game.shop_offer_sequence > evidence.shop_offer_sequence, "shop: next visit resets every section price and creates fresh unique offer IDs")
	return evidence
