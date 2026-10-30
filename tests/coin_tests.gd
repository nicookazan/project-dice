extends RefCounted
const Game = preload("res://scripts/game.gd")
const Coins = preload("res://scripts/coins.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(check: Callable) -> Dictionary:
	_test_catalog_and_instances(check)
	_test_transactions(check)
	return _test_effects_and_contexts(check)

static func _test_catalog_and_instances(check: Callable) -> void:
	check.call(Coins.catalog().size() == 8 and Coins.PASSIVES.size() == 6 and Coins.CONSUMABLES.size() == 2, "coins: only initial six passives and two consumables are offered")
	for id in Coins.catalog():
		var data := Coins.definition(id)
		var complete := true
		for field in ["id", "code", "type", "scope", "trigger", "duration", "price", "resale", "description", "effect", "amount", "use_contexts"]:
			complete = complete and data.has(field)
		check.call(complete and data.id == id and data.provisional_economy, "coins: complete inspectable initial definition " + id)
	var info := Coins.definition("boost")
	info.use_contexts.append("shop")
	info.price = 999
	check.call(not Coins.can_use("boost", "shop") and Coins.definition("boost").price == 2, "coins: definition copies cannot alter live price or use window")
	var first := Coins.instance("full", 1)
	var second := Coins.instance("full", 2)
	first.state["fixture"] = {"nested": 8}
	check.call(second.state.is_empty() and not Coins.definition("full").has("state"), "coins: future instances have independent state, never embedded in catalog")
	check.call(first.instance_id != second.instance_id and first.coin_id == second.coin_id, "coins: instance identity differs from definition identity")
	check.call(Coins.definition("unknown").is_empty() and not Coins.can_use("unknown", "play"), "coins: unknown definition has no fallback power")
	var game = Game.new(100)
	game.passives = ["full", "even"]
	game.consumable = "boost"
	check.call(game.coin_inventory.equipped.size() == 2 and game.coin_inventory.consumables.size() == 1 and game.coin_inventory.shared_capacity == 5, "coins: real game inventory owns instances with shared capacity five")
	var snapshot := game.snapshot()
	snapshot.coin_inventory.equipped[0].state["nested"] = 1
	snapshot.coin_inventory.consumables.clear()
	check.call(game.coin_inventory.equipped[0].state.is_empty() and game.consumable == "boost", "coins: snapshot isolates equipped and stored instances")
	var ids: Array = game.passives
	ids.append("odd")
	check.call(game.passives == ["full", "even"], "coins: compatibility ID view cannot mutate authoritative instances")

static func _test_transactions(check: Callable) -> void:
	var game = Game.new(101)
	game.phase = "shop"
	game.cash = 100
	game.offers = ["full", "boost"]
	check.call(game.buy(0) and game.cash == 96 and game.passives == ["full"] and game.offers[0] == "", "coins: passive purchase stores instance, charges once and empties offer")
	var serial: int = game.coin_inventory.equipped[0].instance_id
	var before := game.snapshot()
	check.call(not game.buy(0) and game.snapshot() == before, "coins: double purchase does not create another instance")
	Fixture.set_coin_offer(game, 0, "full")
	before = game.snapshot()
	check.call(not game.buy(0) and game.snapshot() == before, "coins: duplicate remains forbidden even if an offer supplies it")
	check.call(game.buy(1) and game.cash == 94 and game.consumable == "boost", "coins: consumable gets its own stored instance")
	Fixture.set_coin_offer(game, 1, "roll")
	before = game.snapshot()
	check.call(not game.buy(1) and game.snapshot() == before, "coins: occupied single-use slot rejects purchase without charge or replacement")
	check.call(game.sell("boost") and game.cash == 95 and game.consumable == "", "coins: provisional consumable resale is one and frees the slot")
	check.call(game.buy(1) and game.consumable == "roll", "coins: freed single-use slot accepts later offer")
	var retained: int = game.coin_inventory.equipped[0].instance_id
	Fixture.set_coin_offer(game, 0, "even")
	game.buy(0)
	check.call(game.coin_inventory.equipped[0].instance_id == retained and game.coin_inventory.equipped[1].instance_id > serial, "coins: adding an instance never recreates existing identities")
	check.call(game.sell("full") and game.passives == ["even"] and game.coin_inventory.equipped[0].coin_id == "even", "coins: sell removes only selected instance")
	before = game.snapshot()
	check.call(not game.sell("full") and game.snapshot() == before, "coins: repeated sale cannot pay twice")
	game.passives = ["full", "straight", "generala", "poker", "even"]
	Fixture.set_coin_offer(game, 0, "odd")
	before = game.snapshot()
	check.call(not game.buy(0) and game.snapshot() == before and game.passives.size() == 5, "coins: five shared slots block sixth without discarding existing inventory")
	Fixture.set_coin_offer(game, 0, "unknown")
	before = game.snapshot()
	check.call(not game.buy(0) and game.snapshot() == before, "coins: unknown offered coin is rejected atomically")
	Fixture.set_coin_offer(game, 0, "odd")
	game.sell("even")
	game.cash = 3
	before = game.snapshot()
	check.call(not game.buy(0) and game.snapshot() == before, "coins: insufficient cash changes neither offer nor instance sequence")
	game.cash = 4
	check.call(game.buy(0) and game.cash == 0 and game.passives.size() == 5, "coins: exact funds complete purchase after a slot is freed")
	game.shop_state = {}
	game.generate_offers()
	check.call(game.offers.all(func(id): return id not in game.passives and Coins.DATA.has(id)), "coins: provisional uniform generator excludes owned passives")
	for phase in ["play", "hand_result", "reward", "repair", "won", "lost", "sticker_choice"]:
		game.phase = phase
		before = game.snapshot()
		check.call(not game.buy(0) and not game.sell("odd") and game.snapshot() == before, "coins: invalid transaction context has no charge/consumption " + phase)

static func _test_effects_and_contexts(check: Callable) -> Dictionary:
	for sample in [
		["full", [2, 2, 3, 3, 3], [0, 1, 2, 3, 4], 86],
		["straight", [1, 2, 3, 4, 5], [0, 1, 2, 3, 4], 70],
		["generala", [2, 2, 2, 2, 2], [0, 1, 2, 3, 4], 120],
		["poker", [2, 2, 2, 2, 6], [0, 1, 2, 3], 102]]:
		var game = Game.new(102)
		game.passives = [sample[0]]
		Fixture.set_values(game, sample[1])
		game.form_group(sample[2])
		check.call(game.preview().total == sample[3], "coins: existing category effect via instances " + sample[0])
	var parity = Game.new(103)
	parity.passives = ["even", "odd"]
	parity.global_points["4"] = 3
	Fixture.set_values(parity, [4, 1, 2, 3, 5])
	check.call(parity.preview().rows[0].die_rows[0].points == 9 and parity.preview().total == 28, "coins: improved four worth seven still gets even bonus; odd leftovers also apply")
	for context in ["shop", "hand_result", "reward", "repair", "sticker_choice", "won", "lost"]:
		for id in Coins.CONSUMABLES:
			var game = Game.new(104)
			game.consumable = id
			game.phase = context
			var before := game.snapshot()
			check.call(not game.use_consumable() and game.snapshot() == before, "coins: invalid use window preserves stored instance " + id + " " + context)
	var boosted = Game.new(105)
	boosted.consumable = "boost"
	Fixture.set_values(boosted, [1, 1, 3, 3, 6])
	boosted.form_group([0, 1])
	boosted.move_die(4, "cup")
	boosted.move_die(4, "reserve")
	var groups: Array = boosted.groups.duplicate(true)
	var dice: Array = boosted.dice.duplicate(true)
	var budget: int = boosted.rolls_left
	check.call(boosted.use_consumable() and boosted.boost and boosted.consumable == "" and boosted.rolls_left == budget and boosted.hand == 1, "U01: use consumes its instance, never a roll or hand")
	check.call(boosted.groups == groups and boosted.dice == dice and boosted.preview().total == 31, "U01: locked group and leftovers gain points without changing dice or members")
	var before := boosted.snapshot()
	check.call(not boosted.use_consumable() and boosted.snapshot() == before, "U01: consumed instance never fires twice")
	boosted.score_hand()
	var first: Dictionary = boosted.history[0].score.duplicate(true)
	boosted.next_hand()
	check.call(boosted.boost and boosted.consumable == "", "U01: boost survives hand reset; consumed instance stays gone")
	Fixture.set_values(boosted, [6, 6, 6, 6, 6])
	boosted.form_group([0, 1, 2, 3, 4])
	boosted.score_hand()
	check.call(boosted.history[0].score == first, "U01: later effects never recalculate old credited hands")
	boosted.close_encounter()
	check.call(not boosted.boost, "U01: closing victory ends the boost immediately, including before optional repairs")
	boosted.open_shop()
	boosted.leave_shop()
	check.call(not boosted.boost and boosted.consumable == "", "U01: next encounter clears temporary boost without restoring consumed coin")
	var extra = Game.new(106)
	extra.consumable = "roll"
	var rng_state: int = extra.rng.state
	check.call(extra.use_consumable() and extra.rolls_left == 4 and extra.rolls_made == 0 and extra.rng.state == rng_state, "U02: use before initial throw grants four chances, no RNG")
	extra.roll()
	Fixture.set_results(extra, [6, 6, 6, 6, 6])
	extra.form_group([0, 1, 2, 3, 4])
	extra.score_hand()
	extra.next_hand()
	check.call(extra.rolls_left == 3 and extra.consumable == "", "U02: next hand returns to three without restoring coin")
	extra.consumable = "unknown"
	before = extra.snapshot()
	check.call(not extra.use_consumable() and extra.snapshot() == before, "coins: unknown consumable cannot become an extra-roll fallback")
	extra.consumable = "roll"
	extra.rolls_left = 0
	check.call(extra.use_consumable() and extra.rolls_left == 1, "U02: usable with exhausted roll budget before scoring")
	extra.restart(106)
	check.call(not extra.boost and extra.coin_inventory.equipped.is_empty() and extra.coin_inventory.consumables.is_empty() and extra.coin_instance_sequence == 0, "coins: new run clears equipped, stored, used effects and instance sequence")
	return {"catalog": Coins.catalog(), "boosted_first_hand": first, "capacity": Coins.empty_inventory()}
