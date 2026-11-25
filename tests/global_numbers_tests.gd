extends RefCounted
const Game = preload("res://scripts/game.gd")
const Store = preload("res://scripts/save_store.gd")
const Saves = preload("res://tests/save_tests.gd")
const Purchases = preload("res://tests/purchase_tests.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const UI = preload("res://tests/interface_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(scene, check: Callable) -> void:
	check.call(Profile.tables().numbers.all(func(offer): return offer.kind in ["global", "face"]), "Global numbers: production tables generate no local upgrade offers")
	scene.detail.hide()
	scene.preferences.drag_groups = false
	# Desde el 25/11 las mejoras de número no se venden: son la recompensa de los rivales.
	var rewarded = Purchases.fixture("global", {"number": 4, "amount": 2}, 3)
	rewarded.pending_reward = {"section": "numbers", "offer": rewarded.shop_state.numbers.slots[0].duplicate(true), "target": {}, "source": "rival"}
	rewarded.phase = "bonus"
	var cash_before: int = rewarded.cash
	scene.game = rewarded
	scene.render()
	scene.ui.find_child("TakeReward", true, false).pressed.emit()
	Fixture.set_values(scene.game, [4, 4, 4, 4, 4])
	check.call(scene.game.cash == cash_before and scene.game.global_points == {"4": 2} and scene.game.pending_reward.is_empty() and scene.game.preview().rows[0].die_rows.all(func(die): return die.points == 6), "Global numbers: taking the reward upgrades all five matching dice for free")
	var before: Dictionary = scene.game.snapshot()
	check.call(not scene.game.take_reward().ok and scene.game.snapshot() == before, "Global numbers: the reward cannot be taken twice")
	var legacy = Saves.shop_game("local", {"number": 4, "amount": 12})
	legacy.shop_state.numbers.slots[0].rarity = "rare"
	legacy.global_points = {"4": 3}
	var data := Saves.payload(legacy)
	data.game.dice[0]["local_points"] = {"4": 12}
	data.game.dice[1]["local_points"] = {"4": 5, "6": 2}
	data.game.phase = "purchase_target"
	data.game.pending_purchase = {"section": "numbers", "offer_id": "fixture:1", "offer": data.game.shop_state.numbers.slots[0].duplicate(true), "target": {"die_id": 0}}
	data.game.shop_tables = Profile.tables()
	data.game.shop_tables.numbers.append({"kind": "local", "rarity": "epic", "price": 4, "weight": 1.0, "effect": {"number": 2, "amount": 9}})
	var service = Store.new("res://test-results/global-number-migration/" + str(Time.get_ticks_usec()) + ".json")
	DirAccess.make_dir_recursive_absolute(service.path.get_base_dir())
	var envelope: Dictionary = JSON.parse_string(service.encode(data))
	envelope.version = 5
	var original := JSON.stringify(envelope)
	service.write_text(service.path, original)
	var loaded: Dictionary = service.inspect()
	check.call(loaded.ok, "Global numbers: old local-upgrade save migrates into valid current state")
	if loaded.ok:
		var restored = service.restore_game(loaded.data)
		check.call(restored.global_points == {"4": 20, "6": 2} and restored.dice.all(func(die): return not die.has("local_points")), "Global numbers: existing local bonuses become accumulated global bonuses and per-die maps disappear")
		check.call(restored.phase == "shop" and restored.pending_purchase.is_empty() and restored.shop_state.numbers.slots[0].kind == "global" and restored.shop_state.numbers.slots[0].effect.amount == 5, "Global numbers: unpaid legacy target is canceled and its offer becomes global within rarity bounds")
		check.call(restored.shop_tables.numbers.all(func(offer): return offer.kind in ["global", "face"]) and restored.cash == legacy.cash and restored.rng.state == legacy.rng.state and FileAccess.get_file_as_string(service.path) == original, "Global numbers: legacy migration changes no wallet/RNG and preserves original file until next save")
