extends RefCounted
const Shop = preload("res://tests/shop_tests.gd")
const UI = preload("res://tests/interface_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.game = Shop.game_at_shop(622)
	scene.game.passives = ["even", "odd"]
	scene.game.consumable = "boost"
	scene.game.cash = 12
	scene.render()
	var even := {"shop_coin": "even", "instance_id": scene.game.coin_inventory.equipped[0].instance_id}
	var boost := {"shop_coin": "boost", "instance_id": scene.game.coin_inventory.consumables[0].instance_id}
	var before: Dictionary = scene.game.snapshot()
	scene.show_coin_sale_overlay(even)
	check.call(scene.coin_sale_overlay.visible and scene.coin_sale_caption.text == "Vender: $2" and scene.game.snapshot() == before and UI.find_button(scene.ui, "Vender $2") == null, "Coin drag: transparent case overlay quotes passive resale; old sale buttons are gone")
	scene.hide_coin_sale_overlay()
	check.call(not scene.coin_sale_overlay.visible and scene.game.snapshot() == before, "Coin drag: canceling or returning to inventory neither removes coin nor credits money")
	scene.show_coin_sale_overlay(boost)
	check.call(scene.coin_sale_caption.text == "Vender: $1", "Coin drag: consumable overlay uses its own resale price")
	scene.coin_sale_overlay._drop_data(Vector2.ZERO, boost)
	check.call(scene.game.cash == 13 and scene.game.consumable == "" and scene.game.passives == ["even", "odd"], "Coin drag: consumable sale removes only its instance and credits one")
	before = scene.game.snapshot()
	scene.sell_dragged_coin(boost)
	check.call(scene.game.snapshot() == before, "Coin drag: stale/repeated drop cannot pay again")
	var forged := even.duplicate()
	forged.instance_id += 100
	check.call(not scene.can_sell_dragged_coin(forged) and not scene.can_sell_dragged_coin({"die": 0}) and not scene.can_sell_dragged_coin("even"), "Coin drag: mismatched instances, dice and malformed payloads cannot sell")
	scene.game.phase = "purchase_target"
	check.call(not scene.can_sell_dragged_coin(even), "Coin drag: pending purchases block selling")
	scene.game.phase = "shop"
	scene.render()
	scene.ui.get_node("OwnedCoin_even").pressed.emit()
	check.call(scene.detail.visible and scene.game.cash == 13 and scene.game.passives == ["even", "odd"], "Coin drag: clicking artwork inspects it without selling")
	scene.detail.hide()
	even["resale"] = 9999
	scene.sell_dragged_coin(even)
	check.call(scene.game.cash == 15 and scene.game.passives == ["odd"], "Coin drag: payout comes from catalog rather than payload")
	var sway = preload("res://scripts/drag_sway.gd").new()
	sway.step(0.04, Vector2(30, 0))
	check.call(absf(sway.angle) > 0.04 and sway.offset.length() > 0, "Drag feel: stronger rotation and inertia visibly respond to pointer motion")
	sway.enabled = false
	sway.step(0.04, Vector2(80, 80))
	check.call(sway.angle == 0 and sway.offset == Vector2.ZERO, "Drag feel: reduced motion disables both sway and inertia")
	sway.free()
