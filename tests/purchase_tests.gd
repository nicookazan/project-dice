extends RefCounted
const Game = preload("res://scripts/game.gd")
const Shop = preload("res://scripts/shop.gd")
const StickerTests = preload("res://tests/sticker_tests.gd")

static func fixture(kind: String, effect: Dictionary, price: int = 5, rarity: String = "common"):
	var game = Game.new(140)
	game.phase = "shop"
	game.cash = 100
	game.sticker_catalog = StickerTests.definitions()
	game.shop_state = Shop.empty_state()
	var section: String = {"coin": "coins", "global": "numbers", "local": "numbers", "face": "numbers", "sticker": "stickers", "pack": "stickers"}.get(kind, "components")
	game.shop_state[section].configured = true
	game.shop_state[section].slots[0] = {"offer_id": "fixture:1", "kind": kind, "price": price, "effect": effect.duplicate(true)}
	if section == "numbers": game.shop_state[section].slots[0]["rarity"] = rarity
	return game

static func run(check: Callable) -> Dictionary:
	_test_targets(check)
	_test_atomicity(check)
	return _test_stickers(check)

static func _test_targets(check: Callable) -> void:
	var game = fixture("shell", {"id": "sapphire", "intact": true})
	var die: Dictionary = game.dice[0]
	die.material = "steel"
	die.shell = "ruby"
	die.shell_broken = true
	die.element = "fire"
	die.faces[1] = 4
	die.encounter_effects["steel_points"] = 6.0
	die.hand_effects["unrelated"] = 3
	var before := game.snapshot()
	check.call(game.begin_purchase("components", "fixture:1").code == "target_required" and game.phase == "purchase_target" and game.cash == 100, "purchase: selecting target does not charge")
	check.call(game.shop_state == before.shop_state and game.dice == before.dice and game.rng.state == before.rng_state, "purchase: beginning selection preserves stock, dice and RNG")
	check.call(game.set_purchase_target({"die_id": 0}) and game.purchase_preview().ok, "purchase: preview validates chosen die without applying")
	var pending := game.snapshot()
	for iteration in range(10): game.purchase_preview()
	check.call(game.snapshot() == pending, "purchase: repeated target preview is pure")
	var copy := game.snapshot()
	copy.pending_purchase.offer.effect.id = "corrupt"
	copy.pending_purchase.target.die_id = 4
	check.call(game.pending_purchase.target.die_id == 0 and game.pending_purchase.offer.effect.id == "sapphire", "purchase: pending selection snapshot is detached")
	check.call(game.cancel_purchase() and game.phase == "shop" and game.dice == before.dice and game.cash == before.cash and game.shop_state == before.shop_state, "purchase: cancel preserves wallet, inventory and offer")
	game.begin_purchase("components", "fixture:1")
	game.set_purchase_target({"die_id": 0})
	var previous: Dictionary = die.duplicate(true)
	var result: Dictionary = game.confirm_purchase()
	previous.shell = "sapphire"
	previous.shell_broken = false
	check.call(result.ok and die == previous and game.dice[0] == previous and game.dice.size() == 5, "purchase: broken ruby replaced by intact sapphire, preserving steel/fire/faces/local and persistent die reference")
	check.call(game.cash == 95 and game.shop_state.components.slots[0].is_empty() and game.purchase_receipts["fixture:1"].paid == 5, "purchase: one commit applies effect, pays and consumes identified stock")
	check.call("Dado 1" in result.message and "Zafiro" in result.message and "$5" in result.message, "purchase: result explains objective, replacement and cost")
	before = game.snapshot()
	check.call(not game.confirm_purchase().ok and not game.purchase_offer("components", "fixture:1").ok and game.snapshot() == before, "purchase: repeated confirmation cannot charge/apply twice")
	var material = fixture("material", {"id": "copper"})
	material.dice[1].material = "steel"
	material.dice[1].shell = "ruby"
	material.dice[1].element = "earth"
	material.dice[1].encounter_effects = {"steel_points": 6.0, "unrelated": 2}
	material.dice[1].hand_effects = {"earth_points": 4.0}
	material.begin_purchase("components", "fixture:1")
	material.set_purchase_target({"die_id": 1})
	check.call(material.confirm_purchase().ok and material.dice[1].material == "copper" and material.dice[1].encounter_effects == {"unrelated": 2}, "purchase: material replacement clears only old material accumulation")
	check.call(material.dice[1].shell == "ruby" and material.dice[1].element == "earth" and material.dice[1].hand_effects.earth_points == 4, "purchase: material replacement preserves other families and counters")
	var element = fixture("element", {"id": "water"})
	element.dice[2].element = "earth"
	element.dice[2].material = "steel"
	element.dice[2].encounter_effects = {"steel_points": 6.0}
	element.dice[2].hand_effects = {"earth_points": 4.0, "unrelated": 2}
	element.begin_purchase("components", "fixture:1")
	element.set_purchase_target({"die_id": 2})
	check.call(element.confirm_purchase().ok and element.dice[2].element == "water" and element.dice[2].hand_effects == {"unrelated": 2} and element.dice[2].encounter_effects.steel_points == 6, "purchase: element replacement clears only element counters and preserves material")
	var removed = fixture("local", {"number": 4, "amount": 12}, 8, "rare")
	check.call(not removed.begin_purchase("numbers", "fixture:1").ok, "purchase: removed local offers are rejected")
	var global_game = fixture("global", {"number": 4, "amount": 2}, 3)
	global_game.global_points["4"] = 3
	check.call(global_game.purchase_offer("numbers", "fixture:1").ok and global_game.global_points == {"4": 5} and not global_game.dice[0].has("local_points"), "purchase: number upgrade accumulates globally without per-die state")
	var face = fixture("face", {"number": 4}, 4)
	face.dice[0].value = 2
	face.dice[0].face_index = 1
	face.global_points["2"] = 9
	face.begin_purchase("numbers", "fixture:1")
	face.set_purchase_target({"die_id": 0})
	check.call(not face.purchase_preview().ok, "purchase: face offer also requires source face position")
	face.set_purchase_target({"die_id": 0, "face_index": 1})
	check.call(face.confirm_purchase().ok and face.dice[0].faces == [1, 4, 3, 4, 5, 6] and face.dice[1].faces == [1, 2, 3, 4, 5, 6], "purchase: offered four replaces chosen second face only")
	check.call(face.global_points == {"2": 9} and face.dice[0].value == 2 and face.dice[0].face_index == 1, "purchase: face replacement preserves global improvements and historical result")

static func _test_atomicity(check: Callable) -> void:
	var game = fixture("material", {"id": "steel"}, 8)
	game.begin_purchase("components", "fixture:1")
	var before := game.snapshot()
	check.call(not game.refresh_shop("coins") and not game.leave_shop() and not game.sell("full") and not game.use_consumable() and game.snapshot() == before, "purchase: pending target blocks unrelated transactions and gameplay")
	for target in [{"die_id": -1}, {"die_id": 5}, {"die_id": 1.0}, {"die_id": true}, {"die_id": 0, "face_index": 6}]:
		check.call(not game.set_purchase_target(target) and game.snapshot() == before, "purchase: invalid target selection is rejected atomically " + str(target))
	game.set_purchase_target({"die_id": 0})
	game.cash = 7
	before = game.snapshot()
	check.call(not game.confirm_purchase().ok and game.snapshot() == before, "purchase: confirmation revalidates money after selection without partial changes")
	game.cash = 100
	game.shop_state.components.slots[0].price = 9
	before = game.snapshot()
	check.call(game.confirm_purchase().code == "stale_offer" and game.snapshot() == before, "purchase: same identity with changed price/payload cannot confirm stale selection")
	game.cancel_purchase()
	game.shop_state.components.slots[0].price = 8
	game.begin_purchase("components", "fixture:1")
	game.set_purchase_target({"die_id": 0})
	game.shop_state.components.slots[0] = {}
	before = game.snapshot()
	check.call(not game.confirm_purchase().ok and game.snapshot() == before, "purchase: removed stock cannot be confirmed")
	for sample in [["material", {"id": "unknown"}], ["shell", {"id": "ruby", "intact": false}], ["die", {"id": 5}]]:
		var invalid = fixture(sample[0], sample[1])
		before = invalid.snapshot()
		check.call(not invalid.begin_purchase("components", "fixture:1").ok and invalid.snapshot() == before, "purchase: invalid family or sixth die never offered " + sample[0])
	var unchanged_face = fixture("face", {"number": 4})
	unchanged_face.begin_purchase("numbers", "fixture:1")
	unchanged_face.set_purchase_target({"die_id": 0, "face_index": 3})
	before = unchanged_face.snapshot()
	check.call(not unchanged_face.confirm_purchase().ok and unchanged_face.snapshot() == before, "purchase: invalid no-change face target never charges")
	var coin = fixture("coin", {"coin_id": "odd"}, 4)
	coin.passives = ["full", "straight", "generala", "poker", "even"]
	before = coin.snapshot()
	check.call(coin.purchase_offer("coins", "fixture:1").code == "inventory_full" and coin.snapshot() == before, "purchase: full coin capacity rejects without partial changes")
	var debt = fixture("global", {"number": 4, "amount": 2}, 3)
	debt.cash = -1
	before = debt.snapshot()
	check.call(debt.purchase_offer("numbers", "fixture:1").code == "insufficient_funds" and debt.snapshot() == before, "purchase: repair debt never authorizes buying on credit")
	debt.phase = "play"
	before = debt.snapshot()
	check.call(not debt.purchase_offer("numbers", "fixture:1").ok and debt.snapshot() == before, "purchase: buying requires shop context")

static func _test_stickers(check: Callable) -> Dictionary:
	var single = fixture("sticker", {"id": "trio"}, 4)
	single.cup.stickers = {"trio": 2}
	check.call(single.purchase_offer("stickers", "fixture:1").ok and single.cup.stickers == {"trio": 3} and single.cash == 96 and single.shop_state.stickers.slots[0].is_empty(), "purchase: real individual sticker stock upgrades existing type once")
	var both = fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	both.cup.stickers = {"trio": 1, "full": 2}
	check.call(both.purchase_offer("stickers", "fixture:1").ok and both.cup.stickers == {"trio": 2, "full": 3} and both.cash == 93, "purchase: real two-sticker pack applies both distinct owned upgrades atomically")
	var choose = fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	choose.cup.stickers = {"trio": 2, "full": 1}
	check.call(choose.purchase_offer("stickers", "fixture:1").ok and choose.cash == 93 and choose.phase == "sticker_choice" and choose.cup.stickers == {"trio": 2, "full": 1}, "purchase: real choice pack charges and consumes stock before waiting, without applying candidates")
	var before := choose.snapshot()
	for iteration in range(20): choose.inspect_shop_offer("stickers", "fixture:1")
	check.call(choose.snapshot() == before and not choose.cancel_purchase(), "purchase: closing/reopening choice cannot restore consumed offer or refund/grant all candidates")
	check.call(not choose.choose_sticker("poker") and not choose.leave_shop() and not choose.purchase_offer("stickers", "fixture:1").ok and choose.snapshot() == before, "purchase: pending pack rejects absent choices and further purchases")
	var pending: Dictionary = choose.snapshot()
	check.call(choose.choose_sticker("trio") and choose.cash == 93 and choose.cup.stickers == {"trio": 3, "full": 1} and choose.purchase_receipts["fixture:1"].selected == ["trio"], "purchase: choosing applies only selected sticker and records receipt without charging again")
	before = choose.snapshot()
	check.call(not choose.choose_sticker("full") and not choose.purchase_offer("stickers", "fixture:1").ok and choose.snapshot() == before, "purchase: duplicate callback cannot obtain a discarded sticker")
	var detached: Dictionary = choose.snapshot()
	detached.purchase_receipts["fixture:1"].selected.clear()
	check.call(choose.purchase_receipts["fixture:1"].selected == ["trio"], "purchase: receipts and pending pack state are detached for future persistence")
	return {"pending_choice": pending, "resolved": choose.snapshot(), "balance": "Explicit fixtures; D01/D02/D04 remain pending"}
