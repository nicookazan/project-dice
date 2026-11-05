extends RefCounted
## Ronda 3: el agua sale de la lengüeta roja, el termo sirve más rápido y en curva, y el clic en un sticker abre su panel.
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const StickerBook = preload("res://scripts/sticker_book.gd")
const StickerTip = preload("res://scripts/sticker_tip.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func click_event() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

static func stickered(levels: Dictionary):
	var game := Game.new(521)
	Profile.apply(game)
	game.cup.stickers = levels.duplicate()
	Fixture.set_values(game, [3, 3, 2, 3, 6])
	return game

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.end_cup_animation()
	# 1. El pico es la punta de la lengüeta roja del dibujo del termo.
	var image := Image.load_from_file("res://assets/art/pixel-v3/termo-mesa-v3.png")
	var tip_pixel := image.get_pixel(45, 1)
	var tab_point := Vector2(45 * 2 + 1, 1 * 2 + 1) - BarProps.THERMOS_SIZE / 2.0
	check.call(tip_pixel.r > 0.55 and tip_pixel.g < 0.45 and tip_pixel.a > 0.0 and tab_point == BarProps.SPOUT_LIP, "Pour: the spout is the tip of the thermos' red tab")
	var pose := BarProps.thermos_pose(22)
	var spout := BarProps.spout_point(pose)
	var expected: Vector2 = pose.center + BarProps.SPOUT_LIP.rotated(deg_to_rad(pose.rotation))
	check.call(spout.distance_to(expected) < 2.5 and spout.y < BarProps.POUR_TARGET.y - 30.0 and spout.x < BarProps.POUR_TARGET.x, "Pour: the water leaves the tab and falls to the mate, left of the straw")
	# 2. Movimiento: más corto y curvo.
	var seconds: float = BarProps.SPECS.thermos.frames * BarProps.SPECS.thermos.seconds
	check.call(seconds < 3.0, "Pour motion: the whole thing lasts under 3 seconds")
	var arc := BarProps.thermos_pose(6)
	check.call(arc.center.y < minf(BarProps.THERMOS_REST.y, BarProps.POUR_CENTER.y) - 50.0, "Pour motion: it rises along an arc above both ends")
	var tilting := BarProps.thermos_pose(4)
	check.call(tilting.rotation > 10.0 and tilting.center.x < BarProps.THERMOS_REST.x - 40.0 and tilting.center.y < BarProps.THERMOS_REST.y - 40.0, "Pour motion: it tilts while it travels instead of after arriving")
	var max_rotation := 0.0
	var max_step := 0.0
	var previous: Vector2 = BarProps.thermos_pose(0).center
	for f in range(1, 44):
		var p := BarProps.thermos_pose(f)
		max_rotation = maxf(max_rotation, p.rotation)
		max_step = maxf(max_step, p.center.distance_to(previous))
		previous = p.center
	check.call(max_rotation > 68.5 and max_rotation < 80.0 and max_step < 80.0, "Pour motion: a small overshoot past 68 degrees and no jumps between frames")
	check.call(BarProps.thermos_pose(43).center.distance_to(BarProps.THERMOS_REST) < 6.0 and absf(BarProps.thermos_pose(43).rotation) < 3.0, "Pour motion: it ends back in place")
	# 3. Clic en un sticker: abre su panel y el termo no sirve.
	var levels := {"pair_loose": 3, "trio": 2, "straight": 1, "full": 1}
	scene.game = stickered(levels)
	scene.render()
	scene.background.props.stop_all()
	var zone: Control = scene.ui.get_node("InspectThermos").get_node("StickerZone_trio")
	check.call(zone.mouse_filter == Control.MOUSE_FILTER_STOP and zone.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND and zone.has_meta("drop_forward"), "Sticker book: the sticker zone takes the click (so it never reaches the thermos) but still forwards dropped dice")
	var before: Dictionary = scene.game.snapshot()
	zone.gui_input.emit(click_event())
	var book = scene.sticker_book
	check.call(is_instance_valid(book) and not scene.background.props.busy("thermos") and not scene.sticker_tip.visible, "Sticker book: clicking a sticker opens its panel and the thermos does not pour")
	check.call(book.rows.size() == 6 and book.selected == "trio", "Sticker book: the list has all six stickers with the clicked one selected")
	check.call(book.level_label.text == "NIVEL 2", "Sticker book: it shows the level of the chosen sticker")
	var now := StickerTip.effect("trio", 2, scene.game.sticker_catalog)
	var next := StickerTip.effect("trio", 3, scene.game.sticker_catalog)
	check.call(book.upgrades_label.text.contains("+%s puntos · +%s mult." % [StickerTip.number(now.points), StickerTip.number(now.multiplier_addition)]) and book.upgrades_label.text.contains("Nivel 3: +%s puntos" % StickerTip.number(next.points)), "Sticker book: upgrades show what it gives now and with one more level, from the real scoring function")
	check.call(book.effect_label.text.contains("Trío") and scene.game.snapshot() == before, "Sticker book: it says what the sticker does and changes nothing in the game")
	book.rows["poker"].pressed.emit()
	check.call(book.selected == "poker" and book.level_label.text == "SIN CONSEGUIR" and book.upgrades_label.text.contains("Conseguilo en la tienda"), "Sticker book: choosing a sticker you do not have says so")
	book.rows["full"].pressed.emit()
	check.call(book.level_label.text == "NIVEL 1" and book.big_sticker.sticker_id == "full", "Sticker book: choosing another row changes the big sticker and its data")
	# Mientras está abierto no hay ventanita de hover ni atajos.
	await Drop.motion(scene, zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(not scene.sticker_tip.visible, "Sticker book: while it is open the hover window stays closed")
	var rolls: int = scene.game.rolls_made
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	scene._unhandled_key_input(space)
	check.call(scene.game.rolls_made == rolls, "Sticker book: keyboard shortcuts do not act behind it")
	# Cierres: Esc, botón y clic afuera.
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	book._unhandled_key_input(escape)
	await scene.get_tree().process_frame
	check.call(not is_instance_valid(scene.sticker_book), "Sticker book: Esc closes it")
	zone = scene.ui.get_node("InspectThermos").get_node("StickerZone_full")
	zone.gui_input.emit(click_event())
	scene.sticker_book.panel.get_node("Close").pressed.emit()
	await scene.get_tree().process_frame
	check.call(not is_instance_valid(scene.sticker_book), "Sticker book: the Close button closes it")
	zone.gui_input.emit(click_event())
	var outside = scene.sticker_book.get_child(0)
	outside.gui_input.emit(click_event())
	await scene.get_tree().process_frame
	check.call(not is_instance_valid(scene.sticker_book), "Sticker book: a click outside the panel closes it")
	# Un clic en el termo fuera de los stickers sigue sirviendo.
	scene.render()
	scene.ui.get_node("InspectThermos").pressed.emit()
	check.call(scene.background.props.busy("thermos") and not is_instance_valid(scene.sticker_book), "Sticker book: a click on the thermos away from the stickers still pours")
	# Mientras sirve no hay ventanita aunque el mouse esté sobre un sticker.
	zone = scene.ui.get_node("InspectThermos").get_node("StickerZone_trio")
	await Drop.motion(scene, zone.get_global_rect().get_center())
	scene.update_hover_description()
	check.call(not scene.sticker_tip.visible, "Sticker book: the hover window does not stay behind while the thermos is pouring")
	scene.background.props.stop_all()
	# También en la tienda.
	var shop = stickered(levels)
	shop.phase = "shop"
	scene.game = shop
	scene.render()
	scene.ui.get_node("InspectThermos").get_node("StickerZone_straight").gui_input.emit(click_event())
	check.call(is_instance_valid(scene.sticker_book) and scene.sticker_book.selected == "straight", "Sticker book: it opens from the shop thermos too")
	scene.sticker_book.close_book()
	await scene.get_tree().process_frame
	scene.game = Game.new(521)
	scene.preferences.speed = 0
	scene.render()
