extends RefCounted
## Paso J04: ventanita de los stickers del termo al pasar el mouse (mesa y tienda).
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const StickerTip = preload("res://scripts/sticker_tip.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const ShopThermos = preload("res://scripts/shop_thermos.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func stickered_game(levels: Dictionary):
	var game := Game.new(521)
	Profile.apply(game)
	game.cup.stickers = levels.duplicate()
	Fixture.set_values(game, [3, 3, 3, 1, 2])
	return game

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.speed = 0
	# Los valores salen de la misma función que la puntuación.
	var levels := {"trio": 2, "full": 1, "pair_loose": 3}
	var game = stickered_game(levels)
	game.form_group([0, 1, 2])
	var row: Dictionary = game.preview().rows[0]
	var effect: Dictionary = StickerTip.effect("trio", 2, game.sticker_catalog)
	check.call(row.category == "Trío" and is_equal_approx(effect.points, row.sticker_effect.points) and is_equal_approx(effect.multiplier_addition, row.sticker_effect.multiplier_addition), "Sticker tip: the shown effect equals what the scoring adds for that category and level")
	var text := StickerTip.bbcode("trio", 2, game.sticker_catalog)
	check.call(text.begins_with("Trío · Nivel 2") and text.contains("+%s puntos · +%s mult." % [StickerTip.number(effect.points), StickerTip.number(effect.multiplier_addition)]), "Sticker tip: the text names the play and level and gives the totals for that level")
	var higher: Dictionary = StickerTip.effect("trio", 3, game.sticker_catalog)
	check.call(higher.points > effect.points or higher.multiplier_addition > effect.multiplier_addition, "Sticker tip: a higher level shows higher totals")
	check.call(StickerTip.bbcode("poker", 1, {}).contains("pendientes"), "Sticker tip: a sticker without defined effects says so instead of inventing numbers")
	# Zonas invisibles sobre cada sticker, solo los que se tienen.
	scene.game = game
	scene.render()
	var button: Button = scene.ui.get_node("InspectThermos")
	var names: Array = []
	for child in button.get_children():
		if child.has_meta("sticker_id"): names.append(child.get_meta("sticker_id"))
	names.sort()
	check.call(names == ["full", "pair_loose", "trio"], "Sticker tip: there is a hover zone only over the stickers the thermos has")
	var trio_zone: Control = button.get_node("StickerZone_trio")
	var expected := ShopThermos.badge_hit_rect("trio", levels)
	check.call(trio_zone.mouse_filter == Control.MOUSE_FILTER_PASS and trio_zone.get_global_rect().position.is_equal_approx(Backdrop.THERMOS_ORIGIN + expected.position), "Sticker tip: the zone sits on the sticker and lets clicks and drops through to the thermos")
	# Mouse sobre el sticker: aparece la ventanita a la izquierda del termo, con su borde dorado.
	var snapshot: Dictionary = scene.game.snapshot()
	check.call(not scene.sticker_tip.visible, "Sticker tip: nothing shows before hovering a sticker")
	await Drop.motion(scene, trio_zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(scene.sticker_tip.visible and scene.sticker_tip.label.text.begins_with("Trío · Nivel 2") and scene.sticker_tip.panel.position.x + scene.sticker_tip.panel.size.x < trio_zone.get_global_rect().position.x and scene.game.snapshot() == snapshot, "Sticker tip: on the table the window opens to the left of the sticker without changing the game")
	await Drop.motion(scene, Vector2(20, 880))
	scene.update_hover_description()
	check.call(not scene.sticker_tip.visible, "Sticker tip: moving away hides it")
	# Arrastrando un dado no se abre.
	var die_center: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(31, 31)
	await Drop.motion(scene, die_center)
	await Drop.press(scene, die_center, true)
	await Drop.motion(scene, die_center + Vector2(24, 0))
	await Drop.motion(scene, die_center + Vector2(52, 8))
	await Drop.motion(scene, trio_zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(scene.get_viewport().gui_is_dragging() and not scene.sticker_tip.visible, "Sticker tip: while dragging a die it stays closed")
	await Drop.motion(scene, Vector2(100, 120))
	await Drop.press(scene, Vector2(100, 120), false)
	# El clic sigue funcionando y la zona no tapa nada del termo.
	scene.render()
	scene.ui.get_node("InspectThermos").pressed.emit()
	check.call(scene.detail.visible and scene.detail.title == "Termo y stickers", "Sticker tip: the thermos click still opens its detail")
	scene.detail.hide()
	# Termo robado: sin zonas ni ventanitas.
	var thief = CatalogTests.forced_boss("l2_cebador", true)
	thief.cup.stickers = levels.duplicate()
	scene.game = thief
	scene.render()
	var stolen_zones := 0
	for child in scene.ui.get_node("InspectThermos").get_children():
		if child.has_meta("sticker_id"): stolen_zones += 1
	check.call(thief.thermos_stolen() and stolen_zones == 0 and not scene.sticker_tip.visible, "Sticker tip: while the thermos is stolen there are no zones or windows")
	# Tienda: la ventanita va a la derecha.
	var shop = stickered_game(levels)
	shop.phase = "shop"
	scene.game = shop
	scene.render()
	var shop_button: Button = scene.ui.get_node("InspectThermos")
	var shop_zone: Control = shop_button.get_node("StickerZone_full")
	check.call(shop_zone.get_global_rect().position.is_equal_approx(Backdrop.SHOP_THERMOS_RECT.position + ShopThermos.badge_hit_rect("full", levels).position), "Sticker tip: the shop zones sit on the shop thermos")
	await Drop.motion(scene, shop_zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(scene.sticker_tip.visible and scene.sticker_tip.label.text.begins_with("Full · Nivel 1") and scene.sticker_tip.panel.position.x > shop_zone.get_global_rect().end.x, "Sticker tip: in the shop the window opens to the right of the sticker")
	await Drop.motion(scene, Vector2(20, 880))
	scene.game = Game.new(521)
	scene.render()
