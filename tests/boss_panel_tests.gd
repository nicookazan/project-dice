extends RefCounted
## Fase B de docs/PLAN-JEFES.md: la mano del fondo muestra el poder del jefe.
const Game = preload("res://scripts/game.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const BossInfo = preload("res://scripts/boss_info.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")

static func forced_boss(id: String, at_boss: bool):
	return CatalogTests.forced_boss(id, at_boss)

static func show(scene, game) -> Node:
	scene.detail.hide()
	scene.game = game
	scene.render()
	return scene.ui.get_node_or_null("InspectBoss")

static func run(scene, check: Callable) -> void:
	scene.persistence_enabled = false
	# Los 21 jefes: el panel sale del catálogo, tanto en el jefe como desde un rival.
	for row in Catalog.ROWS:
		var boss: Dictionary = BossInfo.panel(forced_boss(row.id, true))
		check.call(row.power in boss.text and row.text in boss.text and "Objetivo: %d puntos" % Catalog.target_of(row) in boss.text and "Recompensa base: $%d" % Catalog.reward_of(row) in boss.text, "Boss panel: boss encounter shows power, text, target and reward for " + row.id)
		var rival: Dictionary = BossInfo.panel(forced_boss(row.id, false))
		check.call(rival.text.begins_with("Rival común: objetivo") and "Próximo jefe: " + row.name in rival.text and row.power in rival.text, "Boss panel: rival shows the upcoming boss and power for " + row.id)
	# Botón real en la mesa.
	var rival_game = CampaignTests.advance_model(Campaign.prototype(), 0)
	rival_game.begin_level() if rival_game.phase == "level_intro" else null
	var hand = show(scene, rival_game)
	check.call(hand != null and hand is Button and hand.focus_mode == Control.FOCUS_ALL and hand.tooltip_text != "", "Boss panel: hand button exists on a common rival, focusable and with alternative text")
	var before: Dictionary = scene.game.snapshot()
	hand.pressed.emit()
	check.call(scene.detail.visible and "Próximo jefe" in scene.detail_text and scene.game.snapshot() == before, "Boss panel: clicking the hand on a rival announces the next boss without changing the game")
	var boss_game = CampaignTests.advance_model(Campaign.prototype(), 2)
	hand = show(scene, boss_game)
	check.call(boss_game.is_boss() and hand != null and hand.position == Backdrop.HAND_RECT.position, "Boss panel: hand button over the boss's hand")
	hand.pressed.emit()
	var info := BossInfo.panel(boss_game)
	check.call(scene.detail.visible and info.text in scene.detail_text and scene.detail.title == info.title, "Boss panel: boss encounter opens the boss's own power")
	var god = CampaignTests.advance_model(Campaign.prototype(), 20)
	hand = show(scene, god)
	check.call(god.is_boss() and BossInfo.is_god(god) and hand != null and hand.position == Backdrop.GOD_RECT.position, "Boss panel: God's triangle has its own button")
	hand.pressed.emit()
	check.call(scene.detail.title == "Dios" and ("Objetivo: %d puntos" % Campaign.candidate(god.campaign[6], god.selected_bosses["6"]).target) in scene.detail_text, "Boss panel: God shows the drawn rule and its target")
	var referee = CatalogTests.red_card_game(700, ["even", "odd"])
	hand = show(scene, referee)
	hand.pressed.emit()
	var coin_name: String = preload("res://scripts/coins.gd").definition(referee.boss_state.coin).name
	check.call("Expulsada: " + coin_name in scene.detail_text, "Boss panel: shows the referee's own draw")
	var shop_game = CampaignTests.advance_model(Campaign.prototype(), 0)
	shop_game.begin_level()
	preload("res://tests/support/game_fixture.gd").set_values(shop_game, [4, 4, 4, 4, 4])
	shop_game.form_group([0, 1, 2, 3, 4])
	shop_game.score_hand()
	shop_game.close_encounter()
	shop_game.open_shop()
	check.call(shop_game.phase == "shop" and show(scene, shop_game) == null, "Boss panel: no hand button in the shop")
	scene.detail.hide()

static func bare_boss(id: String, values: Array):
	var game = forced_boss(id, true)
	game.roll()
	preload("res://tests/support/game_fixture.gd").set_values(game, values)
	return game

static func run_hidden_forecast(scene, check: Callable) -> void:
	var sleeper = bare_boss("l6_durmiente", [3, 3, 3, 5, 2])
	sleeper.form_group([0, 1, 2])
	show(scene, sleeper)
	check.call(preload("res://tests/interface_tests.gd").text_in(scene.ui, "Previsión oculta"), "Boss panel: the notebook hides the forecast under the Durmiente")
	var plain = bare_boss("l6_relojero", [3, 3, 3, 5, 2])
	plain.form_group([0, 1, 2])
	show(scene, plain)
	check.call(not preload("res://tests/interface_tests.gd").text_in(scene.ui, "Previsión oculta"), "Boss panel: other bosses keep the forecast visible")
