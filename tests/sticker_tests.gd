extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

# Explicit arithmetic/transaction fixtures; no approved balance or live offers.
static func definitions() -> Dictionary:
	return {
		"pair_loose": {"points_per_level": 2, "multiplier_per_level": 0.25, "price": 3},
		"trio": {"points_per_level": 3, "multiplier_per_level": 0.5, "price": 4},
		"straight": {"points_per_level": 0, "multiplier_per_level": 1, "price": 5},
		"full": {"points_per_level": 4, "multiplier_per_level": 0.75, "price": 6},
		"poker": {"points_per_level": 5, "multiplier_per_level": 1.25, "price": 7},
		"generala": {"points_per_level": 7, "multiplier_per_level": 1.5, "price": 8}
	}

static func run(check: Callable) -> Dictionary:
	_test_validation(check)
	var score := _test_scoring(check)
	var pack := _test_transactions(check)
	return {"score": score, "pending_pack": pack, "balance": "test fixtures only; D02 remains pending"}

static func _test_validation(check: Callable) -> void:
	var defaults := Stickers.catalog()
	check.call(Stickers.missing(defaults).size() == 6 and not defaults.has("double_pair"), "stickers: six unbalanced types, no invented double-pair sticker")
	check.call(Stickers.offer("single", ["trio"], 4, defaults).is_empty(), "stickers: missing balance cannot silently become a purchasable offer")
	for invalid in [null, -1, NAN, INF, "2", true]:
		var data := definitions()
		data.trio.points_per_level = invalid
		check.call(not Stickers.defined("trio", data), "stickers: invalid or missing increment rejected " + str(invalid))
	for levels in [{"trio": 0}, {"trio": -1}, {"trio": 1.5}, {"trio": true}, {"unknown": 1}]:
		check.call(not Stickers.valid_levels(levels, definitions()), "stickers: invalid owned level rejected " + str(levels))
	for sample in [
		["choose_one", ["trio", "trio", "full"], 5], ["receive_two", ["trio", "trio"], 5],
		["choose_one", ["trio", "full"], 5], ["receive_two", ["trio", "unknown"], 5],
		["single", ["trio"], 8], ["single", ["trio"], -1], ["unknown", ["trio"], 4]]:
		check.call(Stickers.offer(sample[0], sample[1], sample[2], definitions()).is_empty(), "stickers: invalid offer never created " + str(sample))
	check.call(Stickers.increased({"trio": 999}, ["trio"], definitions()).levels.trio == 1000, "stickers: no designed upgrade cap or duplicate inventory slot")
	var game = Game.new(90)
	game.cup.stickers.trio = 1
	Fixture.set_values(game, [6, 6, 6, 2, 2])
	game.form_group([0, 1, 2])
	var before := game.snapshot()
	check.call(not game.preview().valid and not game.score_hand() and game.history.is_empty(), "stickers: owned missing balance is explicitly invalid, never silently ignored")
	check.call(game.cash == before.cash and game.rng.state == before.rng_state, "stickers: missing balance never charges or consumes RNG")

static func _test_scoring(check: Callable) -> Dictionary:
	var game = Game.new(91)
	game.sticker_catalog = definitions()
	game.cup.stickers = {"trio": 2}
	Fixture.set_values(game, [6, 6, 6, 2, 2])
	game.form_group([0, 1, 2])
	game.form_group([3, 4])
	var score: Dictionary = game.preview()
	check.call(score.rows[0].total == 68 and score.rows[1].total == 9 and score.total == 77, "stickers: level-two trio adds six points and one multiplier only to trio")
	check.call(score.rows[0].die_rows[0].points == 6 and score.rows[0].sticker_effect.level == 2, "stickers: category points never become per-die bonuses")
	var before := game.snapshot()
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "stickers: repeated scoring previews preserve levels, pack state and RNG")
	game.score_hand()
	check.call(game.last_score == score and game.history[0].score == score, "stickers: committed score exactly matches pure preview")
	game.next_hand()
	check.call(game.cup.stickers.trio == 2, "stickers: levels persist between hands")
	Fixture.set_values(game, [4, 4, 1, 2, 3])
	game.cup.stickers = {"pair_loose": 1}
	game.form_group([0, 1])
	var shared: Dictionary = game.preview()
	check.call(shared.rows[0].total == 18.75 and shared.rows[1].total == 10 and shared.total == 29, "stickers: shared type improves pair and unified leftovers, rounding once")
	game.cup.stickers = {"pair_loose": 2}
	game.dice[0].shell = "ruby"
	game.dice[1].material = "copper"
	game.dice[1].encounter_effects.copper_multiplier = 1.0
	game.dice[1].element = "wind"
	game.dice[1].hand_effects.wind_multiplier = 0.5
	var mixed: Dictionary = game.preview().rows[0]
	check.call(mixed.subtotal == 17 and mixed.multiplier_sum == 3 and mixed.multiplier == 4.5 and mixed.total == 76.5, "stickers: category points then sticker/copper/wind additions then ruby")
	check.call(mixed.multiplier_additions[0].source == "sticker:pair_loose", "stickers: breakdown identifies category multiplier source")
	var double_pair = Game.new(92)
	double_pair.sticker_catalog = definitions()
	double_pair.cup.stickers = {"pair_loose": 5}
	Fixture.set_values(double_pair, [2, 2, 4, 4, 6])
	double_pair.form_group([0, 1, 2, 3])
	check.call(double_pair.preview().rows[0].total == 27 and not double_pair.preview().rows[0].has("sticker_effect"), "stickers: shared pair type never expands to double pair")
	for id in ["straight", "full", "poker", "generala"]:
		var values: Array = {"straight": [1, 2, 3, 4, 5], "full": [2, 2, 3, 3, 3], "poker": [2, 2, 2, 2, 6], "generala": [2, 2, 2, 2, 2]}[id]
		var sample = Game.new(93)
		sample.sticker_catalog = definitions()
		sample.cup.stickers[id] = 1
		Fixture.set_values(sample, values)
		sample.form_group([0, 1, 2, 3] if id == "poker" else [0, 1, 2, 3, 4])
		check.call(sample.preview().rows[0].sticker_effect.id == id, "stickers: exact category mapping " + id)
	return {"trio_pair": score, "shared": shared, "mixed": mixed}

static func _test_transactions(check: Callable) -> Dictionary:
	var game = Game.new(94)
	game.sticker_catalog = definitions()
	check.call(game.register_sticker_offer("single", ["trio"], 4) == "", "stickers: offers register only during shop")
	game.phase = "shop" # Explicit shop transaction fixture, no production offers.
	game.cash = 40
	var first: String = game.register_sticker_offer("single", ["trio"], 4)
	check.call(game.inspect_sticker_offer(first).kind == "single" and game.inspect_sticker_offer(first).price == 4, "stickers: offer discloses type and exact price before charge")
	check.call(game.buy_sticker_offer(first) and game.cup.stickers == {"trio": 1} and game.cash == 36, "stickers: first purchase creates one owned level")
	var before := game.snapshot()
	check.call(not game.buy_sticker_offer(first) and game.snapshot() == before, "stickers: double click cannot rebuy the same offer")
	var second: String = game.register_sticker_offer("single", ["trio"], 4)
	check.call(game.buy_sticker_offer(second) and game.cup.stickers == {"trio": 2} and game.cash == 32, "stickers: reappeared offer upgrades same type at unchanged base price")
	var choose: String = game.register_sticker_offer("choose_one", ["trio", "full", "pair_loose"], 7)
	check.call(game.buy_sticker_offer(choose) and game.phase == "sticker_choice" and game.cash == 25 and game.cup.stickers == {"trio": 2}, "packs: choose-one charges once and waits without applying candidates")
	var pending := game.snapshot()
	for iteration in range(10): game.inspect_sticker_offer(choose)
	var detached := game.inspect_sticker_offer(choose)
	detached.items.clear()
	check.call(game.snapshot() == pending and game.rng.state == pending.rng_state, "packs: reopening/inspecting neither charges, rerolls nor mutates contents")
	check.call(not game.buy_sticker_offer(choose) and not game.leave_shop() and not game.refresh_shop() and not game.buy(0) and game.snapshot() == pending, "packs: pending choice blocks purchases, refresh and shop exit")
	check.call(not game.choose_sticker("straight") and game.snapshot() == pending, "packs: discarded or absent selection cannot apply")
	check.call(game.choose_sticker("trio") and game.cash == 25 and game.cup.stickers == {"trio": 3} and game.phase == "shop", "packs: choose owned type upgrades once, other two never apply")
	before = game.snapshot()
	check.call(not game.choose_sticker("full") and not game.buy_sticker_offer(choose) and game.snapshot() == before, "packs: repeated choice never grants discarded candidates")
	game.cup.stickers["full"] = 2
	var both: String = game.register_sticker_offer("receive_two", ["trio", "full"], 8)
	var bought: bool = game.buy_sticker_offer(both)
	check.call(bought and game.cup.stickers.trio == 4 and game.cup.stickers.full == 3 and game.cash == 17, "packs: receive-two distinct owned types each upgrade once")
	before = game.snapshot()
	check.call(not game.buy_sticker_offer(both) and game.snapshot() == before, "packs: receive-two is atomic and cannot be redeemed twice")
	var expensive: String = game.register_sticker_offer("receive_two", ["poker", "straight"], 18)
	before = game.snapshot()
	check.call(not game.buy_sticker_offer(expensive) and game.snapshot() == before, "packs: insufficient money consumes no offer and applies no upgrade")
	check.call(game.register_sticker_offer("receive_two", ["trio", "trio"], 1) == "", "packs: duplicate contents cannot register")
	var saved: Dictionary = game.snapshot()
	saved.cup.stickers.trio = 999
	saved.sticker_catalog.trio.price = 999
	saved.sticker_offers[first].items.clear()
	check.call(game.cup.stickers.trio == 4 and game.sticker_catalog.trio.price == 4 and game.sticker_offers[first].items.size() == 1, "packs: snapshots isolate levels, balance, offers and receipts")
	check.call(game.leave_shop() and game.cup.stickers.trio == 4 and game.sticker_offers.is_empty(), "stickers: next encounter keeps levels, clears old offers")
	game.restart(94)
	check.call(game.cup.stickers.is_empty() and game.pending_sticker_pack.is_empty() and game.sticker_offers.is_empty() and Stickers.missing(game.sticker_catalog).size() == 6, "stickers: new run clears ownership/offers and restores unbalanced catalog")
	return pending
