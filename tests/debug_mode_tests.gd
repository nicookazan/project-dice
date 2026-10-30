extends RefCounted
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Purchase = preload("res://tests/purchase_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
const Saves = preload("res://tests/save_tests.gd")
const Store = preload("res://scripts/save_store.gd")

static func run(scene, check: Callable) -> void:
	var game = Game.new(411)
	game.begin_campaign(411)
	Profile.apply(game)
	game.debug_mode = true
	game.begin_level()
	game.roll()
	var before: Dictionary = game.snapshot()
	var preview: Dictionary = game.preview()
	check.call(preview.total >= game.target() and game.snapshot() == before, "Debug: damage preview guarantees the target without consuming RNG or changing state")
	check.call(game.score_hand() and game.points >= game.target() and game.last_score == preview and not game.score_hand(), "Debug: one valid rolled hand wins and cannot be credited twice")
	game.close_encounter()
	game.open_shop()
	game.cash = 0
	for section in ["coins", "components", "numbers", "stickers"]:
		for count in range(5): game.refresh_shop(section)
	check.call(game.cash == 0 and game.reroll_prices == {"coins": 6, "components": 6, "numbers": 6, "stickers": 6}, "Debug: repeated renewals do not require or spend money; section prices still advance")
	var restored = Saves.roundtrip(game, check)
	check.call(restored.debug_mode and restored.can_afford(1000000000000) and restored.snapshot() == game.snapshot(), "Debug: real save/reload preserves unlimited funds, damage, stock and RNG")
	var targeted = Purchase.fixture("material", {"id": "steel"}, 1000000000000)
	targeted.debug_mode = true
	targeted.cash = 0
	check.call(targeted.begin_purchase("components", "fixture:1").ok and targeted.set_purchase_target({"die_id": 0}) and targeted.confirm_purchase().ok and targeted.cash == 0 and targeted.dice[0].material == "steel", "Debug: targeted purchases accept any price and apply their effect without a finite-money sentinel")
	var sticker = Purchase.fixture("sticker", {"id": "trio"}, 4)
	sticker.debug_mode = true
	sticker.cash = 0
	check.call(sticker.purchase_offer("stickers", "fixture:1").ok and sticker.cup.stickers.trio == 1 and sticker.cash == 0, "Debug: sticker purchases still consume stock and attach the sticker with no charge")
	var pack = Purchase.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	pack.debug_mode = true
	pack.cash = 0
	check.call(pack.purchase_offer("stickers", "fixture:1").ok and pack.phase == "sticker_choice" and pack.choose_sticker("full") and pack.cash == 0, "Debug: unlimited funds preserve paid-pack choice flow")
	game.phase = "repair"
	game.dice[0].shell = "diamond"
	game.dice[0].shell_broken = true
	game.repair_resolution = {"status": "pending", "available_ids": [0], "next_phase": "shop"}
	check.call(game.resolve_repairs([0]) and not game.dice[0].shell_broken and game.cash == 0, "Debug: repairing costs no money and actually repairs the selected die")
	var campaign = Game.new(412)
	campaign.begin_campaign(412)
	Profile.apply(campaign)
	campaign.debug_mode = true
	var won := 0
	for encounter in range(21):
		if campaign.phase == "level_intro": campaign.begin_level()
		campaign.roll()
		if not campaign.score_hand() or not campaign.close_encounter(): break
		won += 1
		if campaign.phase == "repair": campaign.resolve_repairs([])
		if campaign.phase == "reward": campaign.open_shop()
		if campaign.phase == "shop": campaign.leave_shop()
	check.call(won == 21 and campaign.phase == "won" and campaign.debug_mode and campaign.completed_encounters.size() == 21, "Debug: one hand per encounter traverses all seven levels and defeats God")

	var old_store = scene.save_store
	var old_persistence: bool = scene.persistence_enabled
	var old_campaign: bool = scene.campaign_mode
	scene.save_store = Store.new("res://test-results/debug-mode/" + str(Time.get_ticks_usec()) + ".json")
	scene.persistence_enabled = true
	scene.campaign_mode = true
	scene.start_new_run(413)
	var normal_saved: Dictionary = scene.save_store.inspect().data
	scene.request_navigation("pause")
	UI.find_button(scene.ui, "Nueva partida debug").pressed.emit()
	check.call(scene.confirmation.visible and not scene.game.debug_mode and scene.save_store.inspect().data == normal_saved, "Debug UI: button requests existing-game replacement before changing its save")
	scene.confirm_navigation()
	check.call(scene.game.debug_mode and scene.game.phase == "level_intro" and scene.save_store.inspect().data.game.debug_mode, "Debug UI: confirmed new debug game is marked and saved before first encounter")
	scene.request_navigation("pause")
	scene.continue_saved()
	check.call(scene.game.debug_mode and UI.text_in(scene.ui, "DEBUG"), "Debug UI: Continue restores debug settings and visible mode indicator")
	scene.start_new_run(414)
	check.call(not scene.game.debug_mode and not scene.game.can_afford(1) and scene.game.cash == 0, "Debug UI: normal New Game resets cheats and normal economy")
	scene.save_store = old_store
	scene.persistence_enabled = old_persistence
	scene.campaign_mode = old_campaign
