extends RefCounted
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Store = preload("res://scripts/save_store.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")

static func reward_game():
	var game = Game.new(920)
	Profile.apply(game)
	game.cash = 20
	game.cup.stickers = {"trio": 2, "full": 1}
	game.dice[0].material = "steel"
	Fixture.set_values(game, [6, 6, 6, 6, 6])
	game.form_group([0, 1, 2, 3, 4])
	game.score_hand()
	game.close_encounter()
	return game

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.cancel_navigation()
	scene.persistence_enabled = false
	scene.game = reward_game()
	scene.render()
	check.call(scene.ui.has_node("EncounterChoice") and UI.find_button(scene.ui, "Ir a la tienda →") != null and UI.find_button(scene.ui, "Seguir sin tienda →") != null, "Destination: victory offers shop and direct continuation on one screen")
	var service = Store.new("res://test-results/encounter-choice/" + str(Time.get_ticks_usec()) + ".json")
	check.call(service.start(SaveTests.payload(scene.game)).ok, "Destination: intermediate choice is a durable reward checkpoint")
	var stored: Dictionary = service.inspect().data
	var persistent: Dictionary = CampaignTests.persistent_parts(scene.game)
	var rng_before: int = scene.game.rng.state
	var serial: int = scene.game.shop_offer_sequence
	var advance = UI.find_button(scene.ui, "Seguir sin tienda →")
	advance.pressed.emit()
	var advanced: Dictionary = scene.game.snapshot()
	advance.pressed.emit()
	check.call(scene.game.rival == 1 and scene.game.phase == "play" and scene.game.snapshot() == advanced, "Destination: repeated direct-continuation click advances only one encounter")
	check.call(scene.game.rng.state == rng_before and scene.game.shop_offer_sequence == serial and scene.game.shop_state.is_empty(), "Destination: skipping never generates offers or consumes shop RNG")
	check.call(CampaignTests.persistent_parts(scene.game) == persistent and scene.game.groups.is_empty() and scene.game.rolls_made == 0 and scene.game.points == 0, "Destination: direct advance preserves inventory and credited reward, resetting encounter state")
	check.call(scene.background.stickers == scene.game.cup.stickers and not scene.background.shop_mode, "Match thermos: purchased sticker levels reach the playing-table artwork")
	scene.game = service.restore_game(stored)
	scene.render()
	UI.find_button(scene.ui, "Ir a la tienda →").pressed.emit()
	check.call(scene.game.phase == "shop" and not scene.game.shop_state.is_empty() and CampaignTests.persistent_parts(scene.game) == persistent, "Destination: restored choice can visit shop without recollecting reward")
	scene.game.leave_shop()
	check.call(CampaignTests.persistent_parts(scene.game) == persistent and scene.game.rival == 1, "Destination: both routes preserve the same upgrades and money")
	var repair = reward_game()
	repair.dice[0].shell = "ruby"
	repair.dice[0].shell_broken = true
	repair.phase = "repair"
	repair.repair_resolution = {"status": "pending", "available_ids": [0], "next_phase": "reward"}
	var before: Dictionary = repair.snapshot()
	check.call(not repair.skip_shop() and repair.snapshot() == before, "Destination: pending repairs cannot be bypassed by direct continuation")
	check.call(repair.resolve_repairs([]) and repair.phase == "reward" and repair.skip_shop() and repair.dice[0].shell_broken, "Destination: declining repairs reaches choice and preserves broken shell when skipping shop")
	var campaign = Game.new(921)
	campaign.begin_campaign(921)
	Profile.apply(campaign)
	campaign.debug_mode = true
	campaign.cup.stickers = {"trio": 2, "full": 1}
	var intros := 0
	var wins := 0
	for encounter in range(21):
		if campaign.phase == "level_intro":
			intros += 1
			campaign.begin_level()
		campaign.roll()
		if not campaign.score_hand() or not campaign.close_encounter(): break
		wins += 1
		if campaign.phase == "repair": campaign.resolve_repairs([])
		if campaign.phase == "reward": campaign.skip_shop()
	check.call(wins == 21 and intros == 7 and campaign.phase == "won" and campaign.completed_encounters.size() == 21 and campaign.shop_offer_sequence == 0, "Destination: all 21 encounters can skip shops, preserving seven level announcements and terminal God victory")
	before = campaign.snapshot()
	check.call(not campaign.skip_shop() and campaign.snapshot() == before and campaign.cup.stickers == {"trio": 2, "full": 1}, "Destination: final victory offers no further advance and retains purchased stickers")
