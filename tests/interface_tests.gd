extends RefCounted
const Fixture = preload("res://tests/support/game_fixture.gd")
const Game = preload("res://scripts/game.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const PurchaseTests = preload("res://tests/purchase_tests.gd")

static func find_button(node: Node, caption: String):
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var result = find_button(child, caption)
		if result != null: return result
	return null

static func text_in(node: Node, text: String) -> bool:
	if node is Label and text in node.text: return true
	for child in node.get_children():
		if text_in(child, text): return true
	return false

static func dice_in(node: Node) -> Array:
	var result: Array = []
	if node.get_script() == preload("res://scripts/die.gd"): result.append(node)
	for child in node.get_children(): result.append_array(dice_in(child))
	return result

static func key(scene, code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	scene._unhandled_key_input(event)

static func run(scene, check: Callable) -> Dictionary:
	scene.detail.hide()
	scene.game = Game.new(149)
	scene.selected = []
	scene.render()
	check.call(dice_in(scene.ui).is_empty(), "UI: dice inside cup have no visible or clickable table controls before rolling")
	var notebook = scene.ui.get_node("PlayerNotebook")
	check.call(text_in(notebook, "PUNTOS / OBJETIVO") and text_in(notebook, "Mano 1 / 2") and text_in(notebook, "Tiradas restantes: 3") and text_in(notebook, "$0"), "UI: encounter statistics and money belong to the player's notebook")
	check.call(not text_in(scene.ui, "DIOS NO JUEGA") and find_button(scene.ui, "Ver termo") == null, "UI: gameplay has no title banner or visible thermos button")
	var thermos = scene.ui.get_node("InspectThermos")
	check.call(thermos.position.x > 1100 and notebook.rotation == 0 and notebook.size.x >= 300, "UI: thermos hit area is on the right and notebook is a readable frontal panel")
	thermos.pressed.emit()
	check.call("Termo del mate" in scene.detail_text, "UI: the relocated thermos still opens its sticker inspection")
	scene.detail.hide()
	scene.game.roll()
	var rolled_state: Dictionary = scene.game.snapshot()
	scene.render()
	var scattered := dice_in(scene.ui)
	check.call(scattered.size() == 5, "UI: rolling reveals all five dice on the felt")
	var poses: Dictionary = {}
	for die in scattered: poses[die.die_index] = {"position": die.position, "angle": die.rotation_degrees}
	check.call(poses[0].position.y != poses[1].position.y and absf(poses[0].angle) >= 7, "UI: loose dice land at varied positions and angles")
	scene.toggle_die(0)
	var stable := true
	for die in dice_in(scene.ui):
		stable = stable and die.position == poses[die.die_index].position and die.rotation_degrees == poses[die.die_index].angle
	check.call(stable and scene.game.snapshot() == rolled_state, "UI: selection/redraw preserve landing positions and gameplay RNG")
	scene.game.move_die(2, "cup")
	scene.selected = []
	scene.render()
	check.call(dice_in(scene.ui).size() == 4, "UI: returning a die to the cup hides it immediately")
	scene.game.roll()
	scene.render()
	stable = true
	var rerolled_moved := false
	for die in dice_in(scene.ui):
		if die.die_index == 2:
			rerolled_moved = die.position != poses[2].position
		else:
			stable = stable and die.position == poses[die.die_index].position and die.rotation_degrees == poses[die.die_index].angle
	check.call(stable and rerolled_moved and dice_in(scene.ui).size() == 5, "UI: reroll reveals a new landing only for the rerolled die; retained dice stay still")
	var saved_preferences: Dictionary = scene.preferences.duplicate()
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	scene.game = Game.new(148)
	scene.render()
	scene.act(scene.game.roll)
	var animated_state: Dictionary = scene.game.snapshot()
	check.call(scene.throwing and scene.flying_dice.size() == 5 and scene.throw_blocker.mouse_filter == Control.MOUSE_FILTER_STOP, "UI: throw starts five flights from the cup and blocks pointer actions")
	var flight: Dictionary = scene.flying_dice[0]
	var start: Vector2 = flight.node.position
	scene.step_throw(0.3)
	check.call(flight.node.position != start and flight.node.position != flight.landing and flight.node.rotation_degrees != flight.angle, "UI: dice travel and rotate before landing")
	scene.act(scene.game.roll)
	scene.toggle_die(0)
	key(scene, KEY_SPACE)
	check.call(scene.game.snapshot() == animated_state and scene.selected.is_empty(), "UI: clicks and keyboard cannot consume another roll or select dice in flight")
	scene.step_throw(1.0)
	check.call(not scene.throwing and flight.node.position.is_equal_approx(flight.landing) and is_equal_approx(flight.node.rotation_degrees, flight.angle) and flight.node.scale.is_equal_approx(Vector2.ONE), "UI: throw ends at exact scattered landing with interaction restored")
	check.call(scene.game.snapshot() == animated_state, "UI: flight and bounce preserve results and gameplay RNG")
	scene.game.move_die(2, "cup")
	scene.render()
	scene.act(scene.game.roll)
	check.call(scene.throwing and scene.flying_dice.size() == 1 and scene.flying_dice[0].node.die_index == 2, "UI: only the die returned to the cup flies on reroll")
	scene.render()
	check.call(not scene.throwing and scene.flying_dice.is_empty(), "UI: redraw cancels flight safely without stale controls")
	for mode in [0, 2]:
		scene.game = Game.new(148)
		scene.preferences.speed = mode
		scene.render()
		scene.act(scene.game.roll)
		check.call(scene.throwing == (mode == 2), "UI: animation respects instant and fast modes " + str(mode))
		scene.step_throw(0.5)
		check.call(not scene.throwing and scene.game.snapshot() == animated_state, "UI: presentation speed preserves exact rolled state " + str(mode))
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = true
	scene.game = Game.new(148)
	scene.render()
	scene.act(scene.game.roll)
	check.call(not scene.throwing, "UI: reduced motion displays final dice without a flight")
	scene.preferences = saved_preferences
	scene.game = Game.new(150)
	scene.selected = []
	scene.game.dice[0].faces = [1, 4, 3, 4, 5, 6]
	scene.game.global_points["4"] = 3
	scene.game.global_points["4"] = 15
	scene.game.dice[0].material = "steel"
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[0].shell_broken = true
	scene.game.dice[0].element = "earth"
	scene.game.dice[0].encounter_effects["steel_points"] = 6.0
	scene.game.dice[0].hand_effects["earth_points"] = 12.0
	Fixture.set_values(scene.game, [4, 4, 2, 2, 6])
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	for die in dice_in(scene.ui):
		if die.die_index == 0:
			var right := InputEventMouseButton.new()
			right.button_index = MOUSE_BUTTON_RIGHT
			right.pressed = true
			die._gui_input(right)
			check.call(die.shell_broken and not die.chosen, "UI: broken shell marker exists independently of selection/color")
			break
	check.call("Cara 2: 4" in scene.detail_text and "4: 2/6 (33.33%)" in scene.detail_text and "2: 0/6" in scene.detail_text, "UI: die inspection shows six positions and exact changed-face probabilities")
	check.call("Puntos numéricos del resultado: 19" in scene.detail_text and "Número visible: 4" in scene.detail_text, "UI: inspection distinguishes result number from upgraded points")
	check.call("RESQUEBRAJADA" in scene.detail_text and "acero +6" in scene.detail_text and "tierra +12" in scene.detail_text, "UI: inspection separates shell damage and encounter/hand counters")
	check.call(scene.detail_body.text == scene.detail_text and scene.detail_body.scroll_active, "UI: long inspection is fully available in scrollable detail")
	find_button(scene, "TIRAR (1)").pressed.emit()
	key(scene, KEY_SPACE)
	check.call(scene.game.snapshot() == before, "UI: inspection modal blocks mouse callbacks and keyboard play")
	scene.detail.hide()
	key(scene, KEY_1)
	key(scene, KEY_2)
	check.call(scene.selected == [0, 1] and scene.selection_preview().valid and "Par" in scene.selection_preview().text, "UI: keyboard selects exact dice and previews their real category score")
	check.call(scene.game.groups.is_empty() and scene.game.snapshot() == before, "UI: selection preview does not auto-group or mutate game/RNG")
	key(scene, KEY_G)
	check.call(scene.game.groups.size() == 1 and scene.game.groups[0].ids == [0, 1], "UI: keyboard group command invokes actual grouping")
	key(scene, KEY_3)
	key(scene, KEY_C)
	check.call(scene.game.groups[0].locked and scene.game.dice[2].zone == "cup" and text_in(scene.ui, "FIJO"), "UI: keyboard cup movement locks groups with explicit text")
	key(scene, KEY_3)
	key(scene, KEY_V)
	check.call(scene.game.dice[2].zone == "reserve" and scene.game.groups[0].locked, "UI: keyboard reserve keeps existing group lock")
	key(scene, KEY_1)
	check.call(scene.selected.is_empty(), "UI: locked group dice cannot be reselected by keyboard")
	key(scene, KEY_3)
	key(scene, KEY_I)
	check.call(scene.detail.title == "Dado 3 · ficha", "UI: keyboard opens selected die inspection")
	scene.detail.hide()
	key(scene, KEY_ESCAPE)
	check.call(scene.selected.is_empty(), "UI: escape clears selection without changing dice")
	var zone = scene.make_zone(Rect2(0, 0, 1, 1), "cup")
	check.call(not zone._can_drop_data(Vector2.ZERO, {"die": 5}) and not zone._can_drop_data(Vector2.ZERO, {"die": "1"}), "UI: drag protocol rejects sixth die and malformed IDs")
	zone.queue_free()
	scene.game.cup.stickers = {"trio": 2}
	scene.game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	before = scene.game.snapshot()
	scene.inspect_thermos()
	check.call("Termo del mate" in scene.detail_text and "Trío · nivel 2" in scene.detail_text and "+6 puntos" in scene.detail_text, "UI: thermos inspection shows owned sticker level and actual effect")
	scene.detail.hide()
	scene.inspect_coin("boost")
	check.call("Duración: Encuentro actual" in scene.detail_text and "No se usa en tienda" in scene.detail_text, "UI: coin inspection explains duration and allowed use context")
	scene.detail.hide()
	scene.show_help()
	check.call("Doble par" in scene.detail_text and "Servida" in scene.detail_text and "sobrantes" in scene.detail_text and "retirarlos no los desbloquea" in scene.detail_text, "UI: help includes examples and exact grouping/served/leftover rules")
	check.call(scene.game.snapshot() == before, "UI: cup, coin and help inspection never consumes RNG or changes data")
	scene.detail.hide()
	scene.game = ShopTests.game_at_shop(151)
	scene.render()
	var rectangles: Dictionary = {}
	for section in ["coins", "components", "numbers", "stickers", "cup"]:
		var panel = scene.ui.get_node("Shop_" + section)
		rectangles[section] = panel.get_rect()
		check.call(Rect2(0, 0, 1440, 900).encloses(panel.get_rect()), "UI: commercial zone stays within logical viewport " + section)
	check.call(rectangles.numbers.position.y < rectangles.coins.position.y and rectangles.coins.position.x < rectangles.components.position.x and rectangles.cup.position.x < rectangles.coins.position.x and rectangles.cup.size.y > rectangles.cup.size.x and rectangles.numbers.position.x < rectangles.stickers.position.x, "UI: shop places the upright thermos at lower left, separate from all merchandise")
	var separated := true
	var zones: Array = rectangles.keys()
	for a in range(zones.size()):
		for b in range(a + 1, zones.size()): separated = separated and not rectangles[zones[a]].intersects(rectangles[zones[b]])
	check.call(separated, "UI: five simultaneous commercial zones never overlap")
	for section in ["coins", "components", "numbers", "stickers"]:
		var refresh = scene.ui.get_node("Shop_" + section + "/Refresh")
		check.call(refresh.text.is_empty() and "$1" in refresh.tooltip_text and refresh.position.y < 0, "UI: each section has a retry icon beside its header with price on hover " + section)
	before = scene.game.snapshot()
	scene.render()
	check.call(scene.game.snapshot() == before, "UI: rendering full five-zone shop never regenerates offers")
	scene.ui.get_node("Shop_components/Refresh").pressed.emit()
	check.call("$2" in scene.ui.get_node("Shop_components/Refresh").tooltip_text and "$1" in scene.ui.get_node("Shop_coins/Refresh").tooltip_text and "$1" in scene.ui.get_node("Shop_stickers/Refresh").tooltip_text, "UI: renewing components updates only its own price")
	scene.game = Game.new(152)
	scene.game.sticker_catalog = preload("res://tests/sticker_tests.gd").definitions()
	scene.game.cup.stickers = {"pair_loose": 2}
	scene.game.dice[0].shell = "ruby"
	scene.game.dice[1].material = "copper"
	scene.game.dice[1].element = "wind"
	Fixture.set_values(scene.game, [4, 4, 1, 2, 3])
	scene.game.dice[1].encounter_effects["copper_multiplier"] = 1.0
	scene.game.dice[1].hand_effects["wind_multiplier"] = 0.5
	scene.game.form_group([0, 1])
	scene.render()
	scene.show_detail(scene.game.preview().rows[0])
	check.call("×4.5" in scene.detail_text and "Total: 76.5" in scene.detail_text and scene.game.preview().total == 92, "UI: decimal factor and group result remain exact while hand rounds once")
	scene.detail.hide()
	scene.game = PurchaseTests.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.render()
	var received_button = find_button(scene, "$7")
	received_button.pressed.emit()
	received_button.pressed.emit()
	check.call(scene.detail.title == "Paquete recibido" and "Trío · nivel 1" in scene.detail_text and "Full · nivel 1" in scene.detail_text and scene.game.cash == 93, "UI: receive-two pack reports both granted stickers and modal prevents a repeated click")
	scene.detail.hide()
	scene.game = Game.new(153)
	scene.game.rival = 2
	Fixture.set_values(scene.game, [4, 4, 4, 4, 4])
	scene.selected = [0, 1, 2, 3, 4]
	before = scene.game.snapshot()
	key(scene, KEY_G)
	check.call(not scene.selection_preview().valid and scene.game.snapshot() == before, "UI: selection preview respects boss prohibition before enabling group command")
	scene.selected = []
	scene.game = Game.new(154)
	Fixture.set_values(scene.game, [4, 4, 2, 2, 6])
	scene.render()
	await scene.get_tree().process_frame
	var first_die = dice_in(scene.ui)[0]
	var point: Vector2 = first_die.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	scene.get_viewport().push_input(motion, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		scene.get_viewport().push_input(click, true)
	check.call(scene.selected == [0], "UI: native viewport mouse press/release still selects a die")
	before = scene.game.snapshot()
	var inspect_click := InputEventMouseButton.new()
	inspect_click.position = point
	inspect_click.button_index = MOUSE_BUTTON_RIGHT
	inspect_click.pressed = true
	scene.get_viewport().push_input(inspect_click, true)
	check.call(scene.detail.visible and scene.detail.title == "Dado 1 · ficha" and scene.game.snapshot() == before, "UI: native right click opens inspection without changing game")
	scene.detail.hide()
	scene.selected = []
	scene.game = PurchaseTests.fixture("global", {"number": 4, "amount": 2}, 3)
	scene.render()
	find_button(scene, "$3").pressed.emit()
	check.call(scene.game.global_points == {"4": 2} and scene.game.cash == 97, "UI: real purchase applies global improvement from stored offer")
	find_button(scene, "Ir al siguiente rival →").pressed.emit()
	find_button(scene, "TIRAR (3)").pressed.emit()
	Fixture.set_results(scene.game, [4, 4, 4, 4, 4])
	scene.render()
	for code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]: key(scene, code)
	check.call(scene.selection_preview().row.total == 130, "UI: selection preview includes bought upgrade and served category base")
	key(scene, KEY_G)
	var prediction: Dictionary = scene.game.preview()
	find_button(scene, "ANOTAR MANO").pressed.emit()
	check.call(scene.game.last_score == prediction and scene.game.points == 130 and text_in(scene.ui.get_node("PlayerNotebook"), "Anotado"), "UI: full purchase/throw/select/group/annotate flow credits exact preview and switches notebook ink")
	return {"shop_zones": str(rectangles), "credited": scene.game.last_score.total, "inspection_pure": true}
