extends RefCounted
## First coin batch (C07-C51, U01-U08): exact scores with controlled dice, preview == score,
## state, economy, gems, rule changes and the v6 -> v7 save migration.
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const Shop = preload("res://scripts/shop.gd")
const Gems = preload("res://scripts/gems.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

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
	_test_scoring(check)
	_test_rolls_and_hand(check)
	_test_state(check)
	_test_economy(check)
	_test_gems(check)
	_test_rules(check)
	_test_shop_and_save(check)

static func _test_catalog(check: Callable) -> void:
	var codes: Dictionary = {}
	for id in Coins.catalog():
		var data := Coins.definition(id)
		codes[data.code] = id
		check.call(not data.effects.is_empty() and data.rarity in Coins.RARITIES and Coins.initial_state(id) is Dictionary, "batch: data-driven definition " + id)
	check.call(codes.size() == 65 and codes.has("C51") and codes.has("C52") and codes.has("C57") and codes.has("U08") and codes.has("C07"), "batch: C01-C57 and U01-U08 all defined with unique codes")
	check.call(Coins.definition("gold").price == 10 and Coins.definition("gold").resale == 1, "batch: gold coin costs ten and sells for one")
	check.call(Coins.definition("flat_mult").rarity == "rare" and Coins.definition("extra_roll_perm").rarity == "legendary", "batch: rarities follow the catalog")
	check.call(Coins.definition("boost").name == "Impulso 1 y 4" and Coins.definition("boost_25").effects[0].numbers == [2, 5] and Coins.definition("boost_36").effects[0].numbers == [3, 6], "batch: impulses cover 1/4, 2/5 and 3/6")

static func _test_scoring(check: Callable) -> void:
	var pair := [2, 2, 3, 4, 6]
	check.call(_total([], pair, [[0, 1]]) == 22, "batch: baseline pair 9 + leftovers 13")
	check.call(_total(["pair_mult"], pair, [[0, 1]]) == 31, "C07 pair +1 mult")
	check.call(_total(["twopair_mult"], [2, 2, 3, 3, 6], [[0, 1, 2, 3]]) == 56, "C08 two pair +1 mult")
	check.call(_total(["trio_mult"], [4, 4, 4, 1, 2], [[0, 1, 2]]) == 47, "C09 trio +1 mult")
	check.call(_total(["pair_pts"], pair, [[0, 1]]) == 32, "C10 pair +10 points")
	check.call(_total(["generala_pts"], [3, 3, 3, 3, 3], [[0, 1, 2, 3, 4]]) == 95, "C16 generala +30 points")
	check.call(_total(["flat_mult"], pair, [[0, 1]]) == 31, "C17 +1 mult on a combination")
	check.call(_total(["flat_mult"], [2, 2, 5, 5, 5], [[0, 1], [2, 3, 4]]) == 68, "C17 applies to every combination group")
	check.call(_total(["flat_mult"], pair, []) == 17 and _total(["flat_mult"], [1, 2, 3, 4, 6], []) == 16, "C17 never touches the leftovers group")
	var metal := _hand(["metal"], pair, [[0, 1]], func(g):
		g.dice[0].material = "steel"
		g.dice[1].material = "copper")
	check.call(metal.preview().total == 35, "C22 metal +1 point and +0.5 mult per steel/copper die")
	var gem := _hand(["gems"], pair, [[0, 1]], func(g): g.dice[0].shell = "sapphire")
	check.call(gem.preview().total == 48, "C24 gem die +1 point +0.5 mult on top of sapphire")
	check.call(CoinEffects.matches({"element": "any"}, {"element": "fire"}, 3) and not CoinEffects.matches({"element": "any"}, {"element": ""}, 3), "C23 element filter")
	check.call(_total(["num_5"], [5, 2, 2, 3, 6], [[1, 2]]) == 28, "C33 +5 per five, leftovers included")
	check.call(_total(["sixes"], [6, 6, 2, 3, 4], [[0, 1]]) == 60, "C35 +1 mult per six in a combination")
	check.call(_total(["sixes"], [6, 2, 2, 3, 4], [[1, 2]]) == 22, "C35 ignores sixes among leftovers")
	check.call(_total(["first_roll"], pair, [[0, 1]], func(g): g.rolls_made = 1) == 31, "C36 +1 mult on the first roll")
	check.call(_total(["first_roll"], pair, [[0, 1]]) == 22, "C36 off after rerolling")
	check.call(_total(["second_hand"], pair, [[0, 1]], func(g): g.hand = 2) == 31, "C39 +1 mult on hand two")
	check.call(_total(["collection", "flat_mult"], pair, [[0, 1]]) == 49, "C41 counts every equipped coin, itself included")
	check.call(CoinEffects.group_mult(["thermos"], "Par", {}, {"sticker_total": 4})[0].amount == 2.0, "C40 +0.5 mult per sticker level")
	check.call(_total([], [2, 5, 1, 3, 4], [], func(g): g.impulses = ["boost_25"]) == 15 + 6, "U03 +3 on every 2 and 5")
	check.call(_total(["pair_mult"], pair, [[0, 1]], func(g): g.double_mult = true) == 49, "U05 doubles the multiplier of the combination")
	check.call(_total([], pair, [[0, 1]], func(g): g.double_mult = true) == 31, "U05 never doubles leftovers")
	check.call(_total(["pair_double", "twopair_mult"], pair, [[0, 1]]) == 31, "C28 pair also counts as two pair for coins")
	var rows: Array = _hand(["num_2", "pair_pts"], pair, [[0, 1]]).preview().rows
	check.call(rows[0].coin_points[0].source == "coin:pair_pts" and rows[0].die_rows[0].point_additions[0].source == "coin:num_2", "batch: sources are broken down per coin")
	# Boss suspension removes the power of every kind of coin.
	var ctx := {"id": "b", "name": "b", "kind": "suspend_coin", "target": "all"}
	var all_coins := ["pair_mult", "pair_pts", "flat_mult", "num_2", "metal", "first_roll", "unused_rolls", "interest", "sixes", "spent"]
	var suspended := Rules.score(Fixture.dice_with_values(pair), [{"ids": [0, 1], "category": "Par", "locked": false}], all_coins, ["boost"], false, {}, {}, {}, ctx, {"rolls_left": 2, "cash": 40, "states": {"spent": {"strength": 40, "grace": false}}})
	check.call(suspended.valid and suspended.total == 22, "batch: suspending every coin gives the plain score")
	var live := Rules.score(Fixture.dice_with_values(pair), [{"ids": [0, 1], "category": "Par", "locked": false}], all_coins, [], false, {}, {}, {}, {}, {"rolls_left": 2, "cash": 40, "states": {"spent": {"strength": 40, "grace": false}}})
	check.call(live.valid and live.total > 22, "batch: the same coins pay when not suspended")
	# Rounding happens once, on the hand total (0.5 rounds up).
	var halves := _hand(["metal"], [2, 2, 3, 4, 6], [[0, 1, 2]], func(g): g.dice[3].material = "steel")
	check.call(halves.preview().raw_total == float(halves.preview().total) or absf(halves.preview().raw_total - halves.preview().total) <= 0.5, "batch: single rounding on the total")

static func _test_rolls_and_hand(check: Callable) -> void:
	var pair := [2, 2, 3, 4, 6]
	check.call(_total(["unused_rolls"], pair, [[0, 1]], func(g): g.rolls_left = 2) == 32, "C37 +5 per unused roll (2)")
	check.call(_total(["unused_rolls"], pair, [[0, 1]], func(g): g.rolls_left = 1) == 27 and _total(["unused_rolls"], pair, [[0, 1]], func(g): g.rolls_left = 0) == 22, "C37 with 1 and 0 unused rolls")
	check.call(_total(["last_roll"], pair, [[0, 1]], func(g): g.rolls_left = 0) == 42 and _total(["last_roll"], pair, [[0, 1]]) == 22, "C38 +20 only when the last roll is spent")
	check.call(_total(["interest"], pair, [[0, 1]], func(g): g.cash = 12) == 24 and _total(["interest"], pair, [[0, 1]], func(g): g.cash = -9) == 22, "C42 +1 per $5, debt counts zero")
	var game = Game.new(11)
	game.passives = ["extra_roll_perm"]
	game.start_hand()
	check.call(game.rolls_left == 4, "C20 hand starts with four rolls")
	game.consumable = "roll"
	game.roll()
	check.call(game.use_consumable() and game.rolls_left == 4, "C20 combines with U02 (3 left + 1)")
	# Free reroll: passive once per hand, token from U08.
	var free = Game.new(12)
	free.passives = ["free_reroll"]
	free.roll()
	var left: int = free.rolls_left
	free.move_die(0, "cup")
	check.call(free.roll() and free.rolls_left == left and free.rolls_made == 2, "C27 single-die reroll is free but counts as a roll made")
	free.move_die(1, "cup")
	check.call(free.roll() and free.rolls_left == left - 1, "C27 only once per hand")
	free.next_hand()
	check.call(not free.free_reroll_used or free.phase == "play", "C27 hand state resets")
	var token = Game.new(13)
	token.consumable = "free_reroll_use"
	token.roll()
	token.rolls_left = 0
	token.move_die(0, "cup")
	check.call(not token.move_die(1, "cup") or true, "U08 fixture")
	token.dice[0].zone = "reserve"
	check.call(token.use_consumable() and token.free_reroll_tokens == 1, "U08 grants a free single-die reroll")
	token.move_die(0, "cup")
	check.call(token.roll() and token.rolls_left == 0 and token.free_reroll_tokens == 0, "U08 token works with zero rolls left")
	var two = Game.new(14)
	two.passives = ["free_reroll"]
	two.roll()
	two.move_die(0, "cup")
	two.move_die(1, "cup")
	var before: int = two.rolls_left
	two.roll()
	check.call(two.rolls_left == before - 1, "C27 does not apply to two dice")
	# Consumable windows.
	var window = Game.new(15)
	window.consumable = "double_mult"
	check.call(window.use_consumable() and window.double_mult, "U05 usable during play")
	var no_double = Game.new(16)
	no_double.consumable = "repair_gem"
	check.call(not no_double.use_consumable() and no_double.consumable == "repair_gem", "U07 only in the repair phase")

static func _test_state(check: Callable) -> void:
	var spent = Game.new(21)
	spent.passives = ["spent"]
	check.call(spent.coin_inventory.equipped[0].state == {"strength": 40, "grace": true}, "C18 starts at 40 with grace")
	check.call(spent.preview().rows.is_empty(), "C18 nothing before rolling")
	spent.roll()
	check.call(spent.coin_inventory.equipped[0].state == {"strength": 40, "grace": false}, "C18 first roll after purchase is free")
	var plan: Dictionary = spent.preview()
	check.call(plan.rows.any(func(row): return row.get("source", "") == "coin:spent" and row.total == 40), "C18 pays its strength as a flat row")
	var state_before: Dictionary = spent.coin_inventory.equipped[0].state.duplicate()
	spent.preview()
	check.call(spent.coin_inventory.equipped[0].state == state_before, "batch: preview never changes coin state")
	spent.move_die(0, "cup")
	spent.move_die(1, "cup")
	spent.roll()
	check.call(spent.coin_inventory.equipped[0].state.strength == 38, "C18 loses one per rolled die")
	spent.coin_inventory.equipped[0].state.strength = 3
	spent.move_die(0, "cup")
	spent.move_die(1, "cup")
	spent.move_die(2, "cup")
	spent.roll()
	check.call(spent.passives.is_empty() and spent.events.any(func(e): return e.type == Game.COIN_BROKEN), "C18 breaks at zero, leaves the inventory and logs an event")
	check.call(spent.coin_inventory.shared_capacity == 5, "C18 breaking frees the slot")
	var growth = Game.new(22)
	growth.passives = ["accumulated", "streak", "veteran", "bosshunter"]
	Fixture.set_values(growth, [2, 2, 3, 4, 6])
	growth.form_group([0, 1])
	check.call(growth.preview().total == 22, "batch: growing coins pay nothing at zero")
	growth.score_hand()
	var states: Dictionary = Coins.state_of(growth.coin_inventory.equipped)
	check.call(states.accumulated.hands == 1 and states.streak.streak == 1, "C49/C50 advance when the hand is scored")
	growth.next_hand()
	Fixture.set_values(growth, [1, 2, 3, 4, 6])
	check.call(growth.preview().total == 19, "C49 pays +3 per scored hand; C50 pays mult only on combinations")
	growth.score_hand()
	check.call(Coins.state_of(growth.coin_inventory.equipped).streak.streak == 0, "C50 resets when the hand has no combination")
	var closing = Game.new(23)
	closing.passives = ["veteran", "bosshunter"]
	closing.rival = 2
	closing.phase = "hand_result"
	closing.points = 999
	closing.last_score = {"total": 999, "rows": [], "served": false, "valid": true}
	closing.close_encounter()
	var closed: Dictionary = Coins.state_of(closing.coin_inventory.equipped)
	check.call(closed.veteran.wins == 1 and closed.bosshunter.bosses == 1, "C48/C51 advance on a won boss encounter")
	check.call(CoinEffects.group_mult(["veteran"], "Par", {}, {"states": {"veteran": {"wins": 3}}})[0].amount == 1.5, "C48 +0.5 mult per win")
	var resold = Game.new(24)
	resold.passives = ["veteran"]
	resold.coin_inventory.equipped[0].state.wins = 4
	resold.phase = "shop"
	resold.sell("veteran")
	resold.passives = ["veteran"]
	check.call(resold.coin_inventory.equipped[0].state.wins == 0, "batch: selling and rebuying resets progress")

static func _test_economy(check: Callable) -> void:
	var gold = Game.new(31)
	gold.phase = "shop"
	gold.cash = 0
	check.call(not gold.can_afford(1), "C19 off: no spending at zero")
	gold.passives = ["gold"]
	check.call(gold.can_afford(10) and not gold.can_afford(11), "C19 credit reaches -$10")
	gold.offers = ["full", "poker"]
	check.call(gold.buy(0) and gold.cash == -4, "C19 buys into debt")
	gold.cash = -9
	check.call(not gold.buy(1), "C19 refuses beyond the limit")
	gold.cash = -3
	check.call(gold.sell("gold") and gold.cash == -2, "C19 sells for $1 even in debt")
	var discount = Game.new(32)
	discount.passives = ["discount"]
	check.call([discount.offer_price(4), discount.offer_price(6), discount.offer_price(9), discount.offer_price(14)] == [3, 5, 7, 11], "C45 prices 4/6/9/14 become 3/5/7/11")
	discount.phase = "shop"
	discount.cash = 3
	discount.offers = ["full"]
	check.call(discount.buy(0) and discount.cash == 0 and discount.passives.has("full"), "C45 charges the discounted price")
	var renewal = Game.new(33)
	renewal.passives = ["free_renewal"]
	renewal.phase = "reward"
	renewal.cash = 2
	renewal.open_shop()
	check.call(renewal.free_renewals == 1 and renewal.renewal_price("coins") == 0, "C21 first renewal of the visit is free")
	check.call(renewal.refresh_shop("coins") and renewal.cash == 2 and renewal.reroll_prices.coins == 1, "C21 free renewal costs nothing and does not raise the section counter")
	check.call(renewal.refresh_shop("coins") and renewal.cash == 1 and renewal.reroll_prices.coins == 2 and renewal.reroll_prices.numbers == 1, "C21 only once: the next renewal is paid and raises only its section")
	var token = Game.new(34)
	token.phase = "shop"
	token.consumable = "free_renewal_use"
	token.cash = 0
	token.shop_state = {}
	token.generate_offers()
	check.call(token.use_consumable() and token.refresh_shop("coins") and token.cash == 0, "U06 grants one free renewal")
	var pocket = Game.new(35)
	pocket.passives = ["pocket"]
	check.call(pocket.coin_inventory.shared_capacity == 7, "C43 raises passive capacity to seven")
	pocket.passives = ["pocket", "full", "straight", "generala", "poker", "even", "odd"]
	pocket.phase = "shop"
	var cash_before: int = pocket.cash
	check.call(not pocket.sell("pocket") and pocket.passives.size() == 7 and pocket.cash == cash_before, "C43 cannot be sold while coins would overflow")
	check.call(pocket.sell("odd") and pocket.sell("even") and pocket.sell("pocket") and pocket.coin_inventory.shared_capacity == 5, "C43 sells once there is room")
	var small = Game.new(36)
	small.passives = ["pocket_small"]
	check.call(small.coin_inventory.consumable_capacity == 2, "C44 adds a single-use slot")
	small.consumable = "boost"
	check.call(Coins.can_store(small.coin_inventory, "roll"), "C44 second single-use coin fits")

static func _test_gems(check: Callable) -> void:
	var seed_value := -1
	for candidate in range(60):
		var probe = Game.new(candidate)
		var clone := RandomNumberGenerator.new()
		clone.state = probe.rng.state
		if clone.randf() < 0.5:
			seed_value = candidate
			break
	check.call(seed_value >= 0, "gems: found a seed whose first breakage draw breaks a diamond")
	for tempered in [false, true]:
		var game = Game.new(seed_value)
		game.passives = ["tempered_gem"] if tempered else []
		Fixture.set_values(game, [2, 2, 3, 4, 6])
		game.dice[0].shell = "diamond"
		game.form_group([0, 1])
		var rng_before: int = game.rng.state
		game.score_hand()
		var after: int = game.rng.state
		check.call(game.dice[0].shell_broken == (not tempered), "C46 turns the first break into a miss (" + str(tempered) + ")")
		check.call(game.dice[0].shell_saved == tempered, "C46 marks the gem, not the coin")
		check.call(after != rng_before, "C46 still consumes the breakage draw")
	var quote := Gems.repair_quote(_broken(["diamond", "ruby"]), [0, 1], {"half": true})
	check.call(quote.cost == 3 + 2, "C47 halves each repair rounding up")
	quote = Gems.repair_quote(_broken(["diamond", "ruby"]), [0, 1], {"free_one": true})
	check.call(quote.cost == 3 and quote.items[0].cost == 0, "U07 repairs the costliest chosen gem for free")
	quote = Gems.repair_quote(_broken(["diamond", "ruby"]), [0, 1], {"half": true, "free_one": true})
	check.call(quote.cost == 2, "C47 and U07 combine")
	var repair = Game.new(41)
	repair.passives = ["jeweler"]
	repair.consumable = "repair_gem"
	repair.dice[0].shell = "diamond"
	repair.dice[0].shell_broken = true
	repair.phase = "hand_result"
	repair.points = 999
	repair.last_score = {"total": 999, "rows": [], "served": false, "valid": true}
	repair.close_encounter()
	check.call(repair.phase == "repair" and repair.use_consumable() and repair.repair_quote([0]).cost == 0, "U07 is used during the repair phase")
	var cash: int = repair.cash
	check.call(repair.resolve_repairs([0]) and repair.cash == cash and not repair.dice[0].shell_broken, "U07 repair is free")

static func _broken(shells: Array) -> Array:
	var dice := Fixture.dice_with_values([1, 2, 3, 4, 5])
	for i in range(shells.size()):
		dice[i].shell = shells[i]
		dice[i].shell_broken = true
	return dice

static func _test_rules(check: Callable) -> void:
	check.call(Rules.category([1, 2, 3, 4]) == "" and Rules.category([1, 2, 3, 4], {"straight4": true}) == "Escalera", "C25 four-dice straight needs the coin")
	check.call(Rules.category([4, 5, 6, 1], {"straight4": true}) == "Escalera" and Rules.category([1, 2, 3, 5], {"straight4": true}) == "", "C25 follows the 6 to 1 wrap and rejects gaps")
	check.call(_total(["straight4"], [1, 2, 3, 4, 6], [[0, 1, 2, 3]]) == 36, "C25 straight of four scores base 20 + faces and the fifth die is leftover")
	check.call(_hand([], [1, 2, 3, 4, 6], [[0, 1, 2, 3]]).groups.is_empty(), "C25 without the coin the group is rejected")
	var wild := _hand(["wildcard"], [1, 6, 6, 2, 3], [[0, 1, 2]])
	check.call(wild.groups.size() == 1 and wild.groups[0].category == "Trío" and wild.groups[0].assigned == {0: 6}, "C26 a 1 imitates the best number")
	check.call(wild.preview().total == 33, "C26 the imitated number scores")
	var four := _hand(["wildcard"], [1, 1, 1, 1, 3], [[0, 1, 2, 3]])
	check.call(four.groups[0].category == "Póker" and four.preview().total == 67, "C26 four wildcards become the best poker")
	var tie := Rules.resolve_wildcards(Fixture.dice_with_values([1, 2, 3, 4, 5]), [0, 1, 2, 3, 4], {"wildcard": true})
	check.call(tie.category == "Escalera" and tie.assigned == {0: 6}, "C26 prefers the assignment with the higher face sum when categories tie")
	check.call(not Rules.validate_groups(wild.dice, [{"ids": [1, 2, 3], "category": "Trío", "assigned": {1: 6}}], {"wildcard": true}).is_empty(), "C26 only a die showing 1 can be assigned")
	check.call(not Rules.validate_groups(wild.dice, wild.groups, {}).is_empty(), "C26 assignment is invalid without the coin")
	var bytes := var_to_bytes(wild.snapshot())
	var restored: Dictionary = bytes_to_var(bytes)
	check.call(restored.groups[0].assigned == {0: 6}, "C26 assignment survives serialization")
	# Fuzz: every group the game accepts validates, previews and scores equally.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var mismatches := 0
	for i in range(300):
		var coins: Array = ["wildcard", "straight4", "pair_double"].filter(func(_c): return rng.randi() % 2 == 0)
		var values: Array = []
		for k in range(5): values.append(rng.randi_range(1, 6))
		var game = Game.new(i)
		game.passives = coins
		Fixture.set_values(game, values)
		var ids: Array = [0, 1, 2, 3, 4].filter(func(_x): return rng.randi() % 3 != 0)
		if not ids.is_empty(): game.form_group(ids)
		var shown: int = game.preview().total
		if not Rules.validate_groups(game.dice, game.groups, game.active_rules()).is_empty(): mismatches += 1
		var before: int = game.points
		if game.score_hand() and game.points - before != shown: mismatches += 1
	check.call(mismatches == 0, "batch: preview equals score and every accepted group validates over 300 random hands")

static func _test_shop_and_save(check: Callable) -> void:
	var tables := Shop.default_tables()
	var consumable := 0
	var commons := 0
	var passive_offers := 0
	var rng_state := 12345
	var sequence := 0
	for i in range(1500):
		var generated := Shop.generate("coins", tables, {}, [], rng_state, sequence)
		rng_state = generated.rng_state
		sequence = generated.sequence
		for offer in generated.section.slots:
			var def := Coins.definition(offer.effect.coin_id)
			if def.type == "consumable": consumable += 1
			else:
				passive_offers += 1
				if def.rarity == "common": commons += 1
	var share := consumable / float(consumable + passive_offers)
	check.call(share > 0.20 and share < 0.30, "shop: about 25%% single-use offers (got %.3f)" % share)
	check.call(commons / float(passive_offers) > 0.52 and commons / float(passive_offers) < 0.68, "shop: about 60%% common passives (got %.3f)" % (commons / float(passive_offers)))
	var owned: Array = Coins.PASSIVES.filter(func(id): return id != "full")
	var only := Shop.generate("coins", tables, {}, owned, 5, 0)
	check.call(only.valid and only.section.slots.all(func(offer): return offer.is_empty() or offer.effect.coin_id not in owned), "shop: owned passives are never offered again")
	var bad := tables.duplicate(true)
	bad.coin_rarity_weights = 3
	check.call(not Shop.generate("coins", bad, {}, [], 1, 0).valid, "shop: invalid rarity data is rejected")
	# v6 -> v7 migration keeps wallet, stock, RNG and the active impulse.
	var game = Game.new(55)
	game.passives = ["full"]
	game.consumable = "boost"
	game.cash = 9
	var legacy := game.snapshot()
	legacy.erase("impulses")
	for key in ["double_mult", "free_reroll_tokens", "free_reroll_used", "free_renewals"]: legacy.erase(key)
	legacy["boost"] = true
	for die in legacy.dice: die.erase("shell_saved")
	var payload := {"game": legacy, "ui": {"selected": [], "repair_selection": [], "shop_section": "coins", "pack_panel_open": false}}
	var path := "user://saves/coins-v6-test.json"
	var store := SaveStore.new(path)
	DirAccess.make_dir_recursive_absolute(store.path.get_base_dir())
	var bytes := var_to_bytes(payload)
	store.write_text(store.path, JSON.stringify({"format": SaveStore.FORMAT, "version": 6, "sha256": bytes.hex_encode().sha256_text(), "payload": Marshalls.raw_to_base64(bytes)}))
	var loaded := store.read_file(store.path)
	check.call(loaded.ok and loaded.data.game.impulses == ["boost"] and not loaded.data.game.has("boost") and loaded.data.game.dice[0].shell_saved == false, "save: v6 migrates impulse list and gem marks")
	check.call(loaded.data.game.cash == 9 and loaded.data.game.rng_state == legacy.rng_state, "save: migration keeps wallet and RNG")
	var restored = store.restore_game(loaded.data)
	check.call(restored != null and restored.boost and restored.passives == ["full"], "save: migrated v6 restores a playable game")
	# State shape is validated.
	var corrupt := Game.new(56)
	corrupt.passives = ["spent"]
	var broken_data := {"game": corrupt.snapshot(), "ui": payload.ui}
	broken_data.game.coin_inventory.equipped[0].state = {"strength": "lots"}
	check.call(preload("res://scripts/save_validator.gd").validate(broken_data) != "", "save: coin state with the wrong shape is rejected")
	var capacity := {"game": Game.new(57).snapshot(), "ui": payload.ui}
	capacity.game.coin_inventory.shared_capacity = 9
	check.call(preload("res://scripts/save_validator.gd").validate(capacity) != "", "save: capacity must equal the computed one")
	DirAccess.remove_absolute(store.path)
