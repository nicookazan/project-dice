extends RefCounted
## Ajustes del 5 de noviembre: chorro del termo, dados sin recuadro, aros de stickers, dados usables al caer,
## arrastre de varios dados, cartel de venta y ofertas de la tienda con manito y borde.
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const CupEntry = preload("res://scripts/cup_entry.gd")
const CupThrow = preload("res://scripts/cup_throw.gd")
const StickerTip = preload("res://scripts/sticker_tip.gd")
const OfferRing = preload("res://scripts/offer_ring.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func rolled(scene, seed_value := 521, values := [3, 3, 2, 3, 6]) -> void:
	scene.game = Game.new(seed_value)
	Fixture.set_values(scene.game, values)
	scene.selected.clear()
	scene.preferences.drag_groups = false
	scene.render()

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.finish_throw()
	scene.end_cup_animation()
	# 1. El agua sale del pico, no del eje del termo.
	var pose := BarProps.thermos_pose(30)
	var axis_top := Vector2(pose.center.x + sin(deg_to_rad(pose.rotation)) * 175.0, pose.center.y - cos(deg_to_rad(pose.rotation)) * 175.0)
	var spout := BarProps.spout_point(pose)
	check.call(spout.y > axis_top.y + 30.0 and spout.y < BarProps.MATE_MOUTH.y - 20.0 and spout.x < BarProps.MATE_MOUTH.x, "Pour: the water leaves the thermos lip, well below the old axis point and above the mate")
	# 2. Los dados de la entrada y de la sacudida no traen recuadro.
	rolled(scene)
	var entry := CupEntry.new()
	scene.add_child(entry)
	entry.play(scene.game.dice[2], scene.game.boss_context(), Vector2(1330, 470), 5.0)
	var entry_die: Control = entry.get_child(0)
	check.call(entry_die.get_theme_stylebox("normal") is StyleBoxEmpty and entry_die.get_theme_stylebox("disabled") is StyleBoxEmpty, "Cup entry: the die has no button frame, just its texture")
	entry.queue_free()
	var shaker := CupThrow.new()
	scene.add_child(shaker)
	shaker.setup(scene.game.dice, scene.game.boss_context())
	check.call(shaker.inner_dice.all(func(d): return d.get_theme_stylebox("normal") is StyleBoxEmpty), "Cup throw: the dice inside the cup have no button frame either")
	shaker.queue_free()
	# 3. Aros dorados de los stickers sobre su silueta.
	var rings_ok := true
	for id in ["pair_loose", "trio", "straight", "full", "poker", "generala"]:
		var tex: Texture2D = StickerTip.ring_texture(id)
		rings_ok = rings_ok and tex != null and tex.get_size() == Vector2(144, 350) and not tex.get_image().is_invisible()
	check.call(rings_ok, "Sticker ring: every sticker has its own gold outline in thermos space")
	scene.game = Game.new(521)
	scene.game.cup.stickers = {"trio": 2, "full": 1}
	scene.render()
	var zone: Control = scene.ui.get_node("InspectThermos").get_node("StickerZone_trio")
	await Drop.motion(scene, zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(scene.sticker_tip.visible and scene.sticker_tip.ring.texture == StickerTip.ring_texture("trio") and scene.sticker_tip.ring.position == zone.get_meta("thermos_origin"), "Sticker ring: hovering a sticker shows its outline on the thermos along with the text box")
	await Drop.motion(scene, Vector2(20, 880))
	# 4. Dados usables apenas cae el último; el vaso baja por su cuenta.
	rolled(scene, 148, [1, 2, 3, 4, 5])
	scene.game = Game.new(148)
	scene.render()
	scene.click_cup()
	var landed := CupThrow.landed_frame(4)
	check.call(scene.throwing and landed < CupThrow.FRAMES - 10, "Throw: the last die lands well before the cup finishes coming back")
	scene.step_throw((landed - 2) * scene.throw_frame_seconds)
	check.call(scene.throwing and not scene.flying_dice.is_empty(), "Throw: just before the last die lands the dice are still locked")
	scene.step_throw(4 * scene.throw_frame_seconds)
	var final_positions_ok: bool = not scene.throwing and scene.flying_dice.is_empty() and is_instance_valid(scene.cup_throw) and scene.background.cup_hidden
	check.call(final_positions_ok, "Throw: when the last die lands the dice are usable and the cup keeps going down on its own")
	scene.toggle_die(0)
	scene.game.move_die(1, "cup")
	check.call(0 in scene.selected, "Throw: a die can be selected while the cup is still coming back")
	check.call(is_instance_valid(scene.cup_throw), "Throw: selecting a die redraws the table without cutting the cup")
	scene.click_cup()
	check.call(scene.throwing and scene.game.rolls_made == 2, "Throw: rolling again while the cup is coming back starts the new throw")
	scene.step_throw(5.0)
	check.call(not scene.throwing and not is_instance_valid(scene.cup_throw) and not scene.background.cup_hidden, "Throw: everything is back in place at the end")
	# 5. Arrastrar varios dados seleccionados.
	rolled(scene, 521, [5, 3, 2, 6, 4])
	scene.toggle_die(1)
	scene.toggle_die(3)
	scene.toggle_die(4)
	var members: Array = scene.group_for_drag(3)
	check.call(members.size() == 3 and scene.dragged_group == [1, 3, 4], "Multi drag: dragging a selected die takes the whole selection")
	check.call(scene.group_for_drag(0).is_empty() and scene.dragged_group.is_empty(), "Multi drag: dragging a die that is not selected moves only that die")
	scene.preferences.drag_groups = true
	check.call(scene.group_for_drag(3).is_empty(), "Multi drag: with drag-groups mode the single-die behavior stays")
	scene.preferences.drag_groups = false
	var center: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(31, 31)
	await Drop.motion(scene, center)
	await Drop.press(scene, center, true)
	await Drop.motion(scene, center + Vector2(24, 0))
	await Drop.motion(scene, center + Vector2(52, 8))
	var drag_data: Variant = scene.get_viewport().gui_get_drag_data()
	check.call(scene.get_viewport().gui_is_dragging() and drag_data is Dictionary and drag_data.dice == [1, 3, 4] and drag_data.die == 3, "Multi drag: the native drag carries every selected die")
	check.call(scene.table_dice[1].modulate.a < 1.0 and scene.table_dice[4].modulate.a < 1.0 and scene.table_dice[0].modulate.a == 1.0, "Multi drag: the dice being carried fade on the felt and the rest stay")
	scene.handle_die_drop(3, "cup")
	await Drop.press(scene, center, false)
	check.call(scene.game.dice[1].zone == "cup" and scene.game.dice[3].zone == "cup" and scene.game.dice[4].zone == "cup" and scene.game.dice[0].zone == "reserve" and scene.selected.is_empty(), "Multi drag: dropping on the cup sends all of them to the cup")
	var entries := 0
	for child in scene.get_children():
		if child is CupEntry: entries += 1
	check.call(entries == 3 and scene.dragged_group.is_empty(), "Multi drag: each die falls into the cup and the group is cleared when the drag ends")
	rolled(scene, 521, [5, 3, 2, 6, 4])
	scene.selected = [0, 2]
	scene.render()
	scene.dragged_group = [0, 2]
	var before_rolled: Dictionary = scene.game.snapshot()
	scene.handle_die_drop(0, "reserve")
	var scattering: Control = scene.table_dice[0]
	check.call(scene.game.snapshot() == before_rolled and scattering.scale.x > 1.0 and scattering.z_index == 20, "Multi drag: dropping on the felt changes nothing in the game; the dice fall and scatter")
	await scene.get_tree().create_timer(1.0).timeout
	var home: Vector2 = scene.table_dice[0].position
	check.call(scene.table_dice[0].scale == Vector2.ONE and scene.table_dice[0].z_index == 0 and home == scene.loose_die_pose(0).position, "Multi drag: they end exactly at their usual places")
	scene.dragged_group = []
	# 6. Cartel de venta.
	scene.game = ShopTests.game_at_shop(151)
	scene.render()
	var sale = scene.coin_sale_overlay
	check.call(sale.shape.size() == 4 and Geometry2D.is_point_in_polygon(Vector2(400, 190), sale.shape) and not Geometry2D.is_point_in_polygon(Vector2(2, 3), sale.shape), "Sale sign: it follows the trapezoid of the case's inside")
	var sale_font: Font = scene.coin_sale_caption.get_theme_font("font")
	check.call(sale_font is SystemFont and sale_font.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "Sale sign: the text uses the game's pixel font")
	# 7. Ofertas de la tienda: manito y borde dorado.
	var ring_unit := OfferRing.ring_from(_square_image())
	var ring_image: Image = ring_unit.get_image()
	var ring_ok := ring_image.get_pixel(4, 6).a > 0.0 and ring_image.get_pixel(3, 6).a > 0.0 and ring_image.get_pixel(2, 6).a == 0.0 and ring_image.get_pixel(6, 6).a == 0.0
	check.call(ring_ok, "Offer ring: the outline is 2 px around the object and never covers it")
	var cards := 0
	var cursors_ok := true
	var shop_ring: Control
	for section in ["coins", "components", "numbers", "stickers"]:
		var panel = scene.ui.get_node("Shop_" + section)
		for card in panel.get_children():
			if not str(card.name).begins_with("Offer_") or card.get_node_or_null("OfferRing") == null: continue
			cards += 1
			cursors_ok = cursors_ok and card.get_node("ObjectHover").mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND and card.get_node("Price").mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND
			if shop_ring == null: shop_ring = card.get_node("OfferRing")
	check.call(cards >= 6 and cursors_ok, "Shop offers: every offer shows the pointing hand on the object and on its price")
	var state_before: Dictionary = scene.game.snapshot()
	OfferRing.cache[shop_ring.key] = ring_unit   # sin pantalla no se puede dibujar el icono: se usa un aro de ejemplo
	shop_ring.hover(true)
	for i in range(8): await scene.get_tree().process_frame
	check.call(shop_ring.texture != null and shop_ring.visible and scene.game.snapshot() == state_before, "Shop offers: hovering builds the gold outline from the object's own drawing without touching the game")
	shop_ring.hover(true)
	shop_ring.hover(false)
	check.call(shop_ring.visible, "Shop offers: the outline stays while either the object or the price is under the mouse")
	shop_ring.hover(false)
	check.call(not shop_ring.visible, "Shop offers: the outline goes away when the mouse leaves")
	scene.game = Game.new(521)
	scene.preferences.speed = 0
	scene.render()

static func _square_image() -> Image:
	var image := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in range(5, 9):
		for x in range(5, 9): image.set_pixel(x, y, Color(1, 1, 1, 1))
	return image
