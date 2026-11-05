extends RefCounted
## Paso J01: dónde se puede soltar un dado (vaso, termo, tela izquierda) y las ayudas visuales del arrastre.
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const FeltLayout = preload("res://scripts/felt_layout.gd")
const UI = preload("res://tests/interface_tests.gd")

static var pointer := Vector2.ZERO
static var held := false

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.drag_groups = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	# Geometría de la tela: sigue el borde dorado, incluida la esquina inferior izquierda.
	check.call(FeltLayout.contains(Vector2(345, 640)) and not FeltLayout.contains(Vector2(350, 330)) and FeltLayout.contains(Vector2(690, 320)) and not FeltLayout.contains(Vector2(700, 400)), "Felt layout: the left felt follows the gold border (bottom-left corner in, slanted top-left corner out)")
	check.call(is_equal_approx(FeltLayout.left(340.0), 392.0) and FeltLayout.bounds().position.y == FeltLayout.TOP and is_equal_approx(FeltLayout.bounds().end.x, FeltLayout.RIGHT), "Felt layout: bounds match the measured border")
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.selected.clear()
	scene.render()
	var zone = scene.ui.get_node("GroupArea")
	var felt := FeltLayout.bounds()
	var snapshot: Dictionary = scene.game.snapshot()
	check.call(zone._can_drop_data(Vector2(345, 640) - felt.position, {"die": 4}), "Felt drop: the bottom-left corner of the felt accepts a die")
	check.call(not zone._can_drop_data(Vector2(350, 330) - felt.position, {"die": 4}) and not zone._can_drop_data(Vector2(50, 50), {"die": 9}), "Felt drop: outside the felt or an invalid die is refused")
	zone._drop_data(Vector2(350, 330) - felt.position, {"die": 4})
	check.call(scene.selected.is_empty() and scene.game.snapshot() == snapshot, "Felt drop: an invalid drop changes nothing")
	# Soltar sobre el vaso, el termo y la tela libre del vaso manda el dado al vaso.
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.selected.clear()
	scene.render()
	var cup_button: Button = scene.cup_zone.get_node("InspectCup")
	var thermos_button: Button = scene.ui.get_node("InspectThermos")
	for case in [["InspectCup", cup_button, Vector2(1330, 500)], ["InspectThermos", thermos_button, Vector2(1270, 350)]]:
		var fw: Dictionary = case[1].get_meta("drop_forward")
		var at: Vector2 = case[2] - case[1].global_position
		check.call(fw.can.call(at, {"die": 4}), "Cup drop: %s forwards a drop over it to the cup zone" % case[0])
		fw.drop.call(at, {"die": 4})
		check.call(scene.game.dice[4].zone == "cup", "Cup drop: dropping on %s sends the die to the cup" % case[0])
		scene.game = Game.new(521)
		Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
		scene.render()
		cup_button = scene.cup_zone.get_node("InspectCup")
		thermos_button = scene.ui.get_node("InspectThermos")
	var above_zone: Dictionary = thermos_button.get_meta("drop_forward")
	check.call(not above_zone.can.call(Vector2(1270, 200) - thermos_button.global_position, {"die": 4}), "Cup drop: the thermos part above the table does not accept dice")
	for label in {"free felt": Vector2(1120, 620)}:
		scene.game = Game.new(521)
		Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
		scene.selected.clear()
		scene.render()
		var die = scene.table_dice[4]
		var start: Vector2 = die.get_global_transform() * Vector2(31, 31)
		await drag(scene, start, Vector2(1120, 620))
		check.call(scene.game.dice[4].zone == "cup", "Cup drop: dropping on %s sends the die to the cup" % label)
	# El clic en el vaso sigue abriendo su información.
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.render()
	scene.game.rolls_left = 0
	scene.cup_zone.get_node("InspectCup").pressed.emit()
	check.call(scene.detail.visible, "Cup drop: with no rolls left clicking the cup opens its information")
	scene.detail.hide()
	# Dados reservados: "Reservar" y el brillo aparecen solo mientras se arrastra.
	scene.render()
	var overlay = scene.ui.get_node("TableDragOverlay")
	overlay.update_hints(0.1, Vector2(100, 120))
	check.call(not overlay.reserve.visible and overlay.glow.modulate.a == 0.0, "Drag hints: nothing shows when no die is being dragged")
	var die = scene.table_dice[4]
	var start2: Vector2 = die.get_global_transform() * Vector2(31, 31)
	await motion(scene, start2)
	await press(scene, start2, true)
	await motion(scene, start2 + Vector2(30, 5))
	await motion(scene, Vector2(1100, 560))
	overlay.update_hints(1.0, Vector2(1100, 560))
	check.call(scene.get_viewport().gui_is_dragging() and overlay.reserve.visible and overlay.glow.modulate.a > 0.9, "Drag hints: dragging a reserve die shows Reservar and lights the cup")
	await motion(scene, Vector2(500, 600))
	overlay.update_hints(1.0, Vector2(1000, 560))
	var near_alpha: float = overlay.glow.modulate.a
	await motion(scene, Vector2(100, 120))
	overlay.update_hints(1.0, Vector2(100, 120))
	check.call(overlay.glow.modulate.a < near_alpha and overlay.glow.modulate.a > 0.34, "Drag hints: the glow fades as the die moves away")
	await press(scene, Vector2(100, 120), false)
	await scene.get_tree().process_frame
	check.call(scene.game.dice[4].zone == "reserve", "Drag hints: releasing over nothing leaves the die where it was")
	scene.render()
	overlay = scene.ui.get_node("TableDragOverlay")
	check.call(not overlay.reserve.visible, "Drag hints: Reservar is gone after the drag")
	# Sin "Armar grupos arrastrando" la tela izquierda no ofrece Reservar.
	scene.preferences.drag_groups = false
	scene.render()
	var plain = scene.ui.get_node("GroupArea")
	check.call(not plain.has_method("_drop_data") and not scene.ui.get_node("TableDragOverlay").reserve_ok.call(4), "Drag hints: with drag groups off the left felt offers no Reservar")
	scene.preferences.drag_groups = true
	scene.render()
	# Opciones: el interruptor de grupos no pisa el texto de abajo.
	scene.show_options()
	var toggle: Control = scene.settings_panel.get_node("drag_groups")
	var footer: Label
	for child in scene.settings_panel.get_children():
		if child is Label and child.text.begins_with("Las señales"): footer = child
	check.call(footer != null and toggle.position.y + toggle.get_combined_minimum_size().y <= footer.position.y, "Options: the drag-groups toggle ends above the footer text")
	scene.detail.hide()

static func drag(scene, from: Vector2, to: Vector2) -> void:
	await motion(scene, from)
	await press(scene, from, true)
	await motion(scene, from + Vector2(24, 0))
	await motion(scene, from + Vector2(52, 8))
	await motion(scene, to)
	await motion(scene, to + Vector2(1, 1))
	await press(scene, to + Vector2(1, 1), false)
	await scene.get_tree().process_frame

static func motion(scene, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.relative = to - pointer
	pointer = to
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	scene.get_tree().root.push_input(event, true)
	await scene.get_tree().process_frame

static func press(scene, at: Vector2, down: bool) -> void:
	held = down
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	scene.get_tree().root.push_input(event, true)
	await scene.get_tree().process_frame
