extends RefCounted
const UI = preload("res://tests/interface_tests.gd")
const Shop = preload("res://tests/shop_tests.gd")
const Purchase = preload("res://tests/purchase_tests.gd")

static func run(scene, check: Callable) -> Dictionary:
	scene.detail.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.game = Shop.game_at_shop(162)
	scene.game.passives = ["even", "odd"]
	scene.game.cash = 24
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	var numbers = scene.ui.get_node("Shop_numbers")
	var card = numbers.get_node("Offer_0")
	var object = card.get_node("ObjectHover")
	var tooltip = object._make_custom_tooltip(object.tooltip_text)
	check.call(not scene.detail.visible and "+2 puntos para el número 4" in tooltip.text and scene.game.snapshot() == before, "Shop hover: description exposes stored effect without a modal, charge or RNG change")
	check.call(tooltip.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and tooltip.get_theme_font("font").antialiasing == TextServer.FONT_ANTIALIASING_NONE and UI.find_button(numbers, "?") == null, "Shop hover: wrapped pixel font replaces question buttons")
	tooltip.free()
	check.call(card.get_node("Price").text == "$3" and card.get_node("Price").tooltip_text.is_empty() and card.tooltip_text.is_empty(), "Shop hover: descriptions belong only to artwork, not price or empty card space")
	check.call(card.get_node("Price")._make_custom_tooltip("") == null and object._make_custom_tooltip("  ") == null, "Shop hover: empty descriptions never create a tooltip control")
	scene.detail.hide()
	var sale := {"shop_coin": "even", "instance_id": scene.game.coin_inventory.equipped[0].instance_id}
	scene.show_coin_sale_overlay(sale)
	check.call(scene.coin_sale_overlay.visible and scene.coin_sale_caption.text == "Vender: $2" and scene.game.snapshot() == before, "Shop sale: showing drag overlay quotes real resale without changing state")
	scene.coin_sale_overlay._drop_data(Vector2(100, 100), sale)
	check.call(scene.game.cash == 26 and scene.game.passives == ["odd"], "Shop sale: dropping into case sells exactly its own instance and credits once")
	before = scene.game.snapshot()
	scene.render()
	check.call(scene.game.snapshot() == before and scene.background.shop_mode, "Shop style: table/atlas render leaves all stock and gameplay RNG unchanged")
	scene.game = Purchase.fixture("face", {"number": 4}, 4)
	scene.render()
	var dice := UI.dice_in(scene.ui.get_node("Shop_numbers"))
	check.call(dice.size() == 1 and dice[0].value == 4 and dice[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "Shop style: face artwork shows offered number instead of a static decorative six")
	scene.game.begin_purchase("numbers", "fixture:1")
	scene.game.set_purchase_target({"die_id": 0, "face_index": 1})
	scene.render()
	UI.find_button(scene.ui, "Confirmar · $4").pressed.emit()
	check.call(scene.game.cash == 96 and scene.game.dice[0].faces == [1, 4, 3, 4, 5, 6], "Shop style: themed target confirmation keeps exact face replacement and charge")
	scene.game = Shop.game_at_shop(162)
	scene.game.cash = -3
	scene.render()
	check.call(UI.find_button(scene.ui.get_node("Shop_numbers"), "$3").disabled and scene.ui.get_node("Shop_numbers/Refresh").disabled, "Shop style: debt disables purchase and renewal while keeping continuation available")
	check.call(not UI.find_button(scene.ui, "Ir al siguiente rival →").disabled, "Shop style: debt does not trap player in shop")
	check.call(scene.ui.get_node("ShopInventory").position.y >= 777 and scene.ui.get_node("ShopAdvance").position.y == 25 and scene.ui.get_node("ShopAdvance").position.x >= 1025, "Shop layout: owned coins occupy footer and continuation occupies old upper-right inventory area")
	scene.game = Purchase.fixture("sticker", {"id": "trio"}, 4)
	scene.render()
	check.call(scene.ui.get_node("Shop_cup/ThermosArtwork").stickers.is_empty() and UI.dice_in(scene.ui).filter(func(die): return die.position.y >= 800).size() == 5, "Shop footer: empty thermos invents no stickers and all five player dice belong to blue footer")
	UI.find_button(scene.ui.get_node("Shop_stickers"), "$4").pressed.emit()
	check.call(scene.game.cash == 96 and scene.ui.get_node("Shop_cup/ThermosArtwork").stickers == {"trio": 1}, "Shop footer: real sticker purchase immediately attaches its badge to thermos")
	scene.game.shop_state.stickers.slots[0] = {"offer_id": "fixture:2", "kind": "sticker", "price": 4, "effect": {"id": "trio"}}
	scene.render()
	UI.find_button(scene.ui.get_node("Shop_stickers"), "$4").pressed.emit()
	check.call(scene.ui.get_node("Shop_cup/ThermosArtwork").stickers == {"trio": 2}, "Shop footer: buying same sticker upgrades its badge instead of duplicating it")
	return {"reference_layout": "merchandise in case; dice and thermos in blue footer", "detail_pure": true, "sale_exact": true, "face_illustration_exact": true}
