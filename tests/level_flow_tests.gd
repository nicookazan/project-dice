extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")

static func click(scene, caption: String) -> bool:
	var control = UI.find_button(scene.ui, caption)
	# Secondary options live inside the in-game menu panel: open it first when the button is not on screen.
	if control == null and caption in ["Recorrido · M", "Opciones", "Abandonar partida", "Guardar y volver al menú", "Seguir jugando"]:
		var menu = UI.find_button(scene.ui, "Menú")
		if menu != null and not menu.disabled:
			menu.pressed.emit()
			control = UI.find_button(scene.ui, caption)
	if control == null or control.disabled: return false
	control.pressed.emit()
	# Advance presentation time before issuing the next synchronous UI action.
	if scene.throwing: scene.step_throw(2.0)
	return true

static func best_groups(game) -> Dictionary:
	var candidates: Array = []
	for mask in range(1, 32):
		var ids: Array = []
		var values: Array = []
		for id in range(5):
			if mask & (1 << id):
				ids.append(id)
				values.append(game.dice[id].value)
		var category: String = Rules.category(values)
		if category == "" or preload("res://scripts/boss_rules.gd").forbidden(game.boss_context(), category): continue
		candidates.append({"ids": ids, "category": category, "locked": false})
	var plans: Array = [[]]
	for a in candidates:
		plans.append([a])
		for b in candidates:
			var overlap := false
			for id in a.ids:
				if id in b.ids: overlap = true
			if not overlap: plans.append([a, b])
	var best := {"groups": [], "total": -1}
	for plan in plans:
		var score: Dictionary = Rules.score(game.dice, plan, game.passives, game.boost, game.rolls_made == 1, game.global_points, game.cup.stickers, game.sticker_catalog, game.boss_context())
		if score.total > best.total: best = {"groups": plan, "total": score.total}
	return best

# Ordinary player actions only: no fixture dice, injected points, money or stock.
static func play_run(game, scene = null) -> Array:
	var trace: Array = []
	var steps := 0
	while game.phase not in ["won", "lost"] and steps < 40:
		steps += 1
		if game.phase == "play":
			if scene == null: game.roll()
			else: click(scene, "TIRAR (%d)" % game.rolls_left)
			var best := best_groups(game)
			while best.total < game.target() - game.points and best.total < 45 and game.rolls_left > 0:
				var counts: Dictionary = {}
				for die in game.dice: counts[die.value] = counts.get(die.value, 0) + 1
				var keep := 0
				for value in counts:
					if counts[value] > counts.get(keep, 1): keep = value
				for die in game.dice:
					if die.value != keep:
						if scene == null: game.move_die(die.id, "cup")
						else: scene.toggle_die(die.id)
				if scene != null: click(scene, "Al vaso →")
				if scene == null: game.roll()
				else: click(scene, "TIRAR (%d)" % game.rolls_left)
				best = best_groups(game)
			for group in best.groups:
				if scene == null: game.form_group(group.ids)
				else:
					for id in group.ids: scene.toggle_die(id)
					click(scene, "Armar grupo")
			if scene == null: game.score_hand()
			else: click(scene, "ANOTAR MANO")
			trace.append({"rival": game.rival, "hand": game.hand, "score": game.last_score.total, "points": game.points})
		elif game.phase == "hand_result":
			if game.points >= game.target():
				if scene == null: game.close_encounter()
				else: click(scene, "Cerrar y cobrar")
			else:
				if scene == null: game.next_hand()
				else: click(scene, "Jugar segunda mano")
		elif game.phase == "reward":
			if scene == null: game.open_shop()
			else: click(scene, "Ir a la tienda →")
		elif game.phase == "shop":
			# Buy the first passive in naturally generated stock, when affordable.
			for slot in game.shop_state.coins.slots:
				if not slot.is_empty() and slot.price == 4 and game.cash >= 4:
					if scene == null: game.purchase_offer("coins", slot.offer_id)
					else: UI.find_button(scene.ui.get_node("Shop_coins"), "$4").pressed.emit()
					break
			if scene == null: game.leave_shop()
			else: click(scene, "Ir al %s →" % ("jefe" if game.rival == 1 else "siguiente rival"))
		else: break
	return trace

static func run(scene, check: Callable) -> Dictionary:
	scene.detail.hide()
	scene.game.return_to_menu()
	scene.render()
	check.call(UI.find_button(scene.ui, "Nueva partida") != null and UI.find_button(scene.ui, "Continuar") == null, "Flow: real menu has new run and no unavailable continue")
	var before: Dictionary = scene.game.snapshot()
	click(scene, "Opciones")
	check.call(scene.detail.visible and "F11" in scene.detail_text and scene.game.snapshot() == before, "Flow: options expose working display control and preserve game")
	scene.detail.hide()
	click(scene, "Nueva partida")
	check.call(scene.game.phase == "level_intro" and UI.text_in(scene.ui, "GENERALA PROHIBIDA"), "Flow: level intro announces boss rule before first encounter")
	check.call(scene.game.cash == 0 and scene.game.passives.is_empty() and scene.game.consumable == "" and scene.game.cup.material == "leather", "Flow: new run starts leather, zero money and zero coins")
	check.call(scene.game.dice == preload("res://scripts/dice_state.gd").create_dice() and scene.game.shop_state.is_empty(), "Flow: five base dice and no initial shop")
	check.call(not scene.game.roll() and not scene.game.leave_shop() and not scene.game.open_shop(), "Flow: announcement cannot roll or skip to shop/encounter")
	click(scene, "Empezar primer encuentro")
	check.call(scene.game.phase == "play" and scene.game.rival == 0 and not scene.game.begin_level(), "Flow: only first encounter starts, intro continuation is idempotent")
	before = scene.game.snapshot()
	check.call(UI.find_button(scene.ui, "Recorrido · M") == null and UI.find_button(scene.ui, "Abandonar partida") == null and UI.find_button(scene.ui, "Opciones") == null and UI.find_button(scene.ui, "Menú") != null, "Flow: table keeps only the Menú button; secondary options are not loose on screen")
	UI.find_button(scene.ui, "Menú").pressed.emit()
	check.call(scene.ui.has_node("GameMenu") and UI.find_button(scene.ui, "Seguir jugando") != null and UI.find_button(scene.ui, "Recorrido · M") != null and UI.find_button(scene.ui, "Opciones") != null and UI.find_button(scene.ui, "Abandonar partida") != null and UI.find_button(scene.ui, "Guardar y volver al menú") != null and scene.game.snapshot() == before, "Flow: Menú opens a panel with route, options, abandon and save-and-exit without changing state")
	UI.find_button(scene.ui, "Seguir jugando").pressed.emit()
	check.call(not scene.ui.has_node("GameMenu") and scene.game.snapshot() == before, "Flow: closing the menu panel keeps the game untouched")
	click(scene, "Recorrido · M")
	check.call("40 → 70 → 110" in scene.detail_text and "trío + par" in scene.detail_text and scene.game.snapshot() == before, "Flow: route consultable during play without changing RNG or state")
	scene.detail.hide()
	click(scene, "Abandonar partida")
	check.call(scene.confirmation.visible and scene.game.snapshot() == before, "Flow: active abandonment asks before changing state")
	UI.key(scene, KEY_SPACE)
	click(scene, "TIRAR (3)")
	check.call(scene.game.snapshot() == before, "Flow: confirmation blocks keyboard and underlying buttons")
	scene.confirmation.get_cancel_button().pressed.emit()
	check.call(not scene.confirmation.visible and scene.pending_navigation == "" and scene.game.snapshot() == before, "Flow: cancel abandonment returns exact active session")
	scene.request_navigation("new")
	check.call(scene.confirmation.visible, "Flow: active new run also needs confirmation")
	scene.confirmation.get_ok_button().pressed.emit()
	check.call(scene.game.phase == "level_intro" and scene.pending_navigation == "", "Flow: confirm new run opens fresh intro")
	scene.request_navigation("menu")
	scene.confirmation.get_ok_button().pressed.emit()
	check.call(scene.game.phase == "menu", "Flow: confirm abandon returns to menu")
	scene.start_new_run(92)
	scene.game.begin_level()
	scene._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check.call(scene.confirmation.visible and scene.pending_navigation == "quit", "Flow: window close protects active run too")
	scene.confirmation.get_cancel_button().pressed.emit()

	# Target already met: spending the extra hand removes exactly the unused-hand prize.
	var early = Game.new(5)
	Fixture.set_values(early, [6, 6, 6, 6, 5])
	early.form_group([0, 1, 2, 3])
	early.score_hand()
	var late = Game.new(5)
	Fixture.set_values(late, [6, 6, 6, 6, 5])
	late.form_group([0, 1, 2, 3])
	late.score_hand()
	scene.game = late
	scene.render()
	check.call(UI.find_button(scene.ui, "Cerrar y cobrar") != null and UI.find_button(scene.ui, "Jugar segunda mano") != null and UI.text_in(scene.ui, "$2"), "Flow: achieved target offers cash out or explicit extra-hand cost")
	early.close_encounter()
	click(scene, "Jugar segunda mano")
	Fixture.set_values(late, [1, 2, 2, 4, 6])
	scene.render()
	click(scene, "ANOTAR MANO")
	click(scene, "Cerrar y cobrar")
	check.call(early.payout.hands == 2 and late.payout.hands == 0 and late.hand == 2, "Flow: optional extra hand consumes actual unused-hand reward")
	before = late.snapshot()
	check.call(not late.close_encounter() and not late.score_hand() and late.snapshot() == before, "Flow: leaving score cannot repeat score or payout")
	click(scene, "Ir a la tienda →")
	before = late.snapshot()
	scene.show_route()
	scene.detail.hide()
	scene.render()
	check.call(not late.open_shop() and not late.generate_offers() and late.snapshot() == before, "Flow: route/result redraw cannot repeat initial shop generation")
	click(scene, "Ir al siguiente rival →")
	check.call(late.rival == 1 and late.phase == "play" and not late.leave_shop(), "Flow: shop continues exactly one encounter without skip")

	var loss = Game.new(8)
	for h in range(2):
		Fixture.set_values(loss, [1, 2, 2, 4, 6])
		loss.score_hand()
		if h == 0: loss.next_hand()
	scene.game = loss
	scene.render()
	check.call(loss.phase == "lost" and loss.cash == 0 and loss.payout.is_empty() and not loss.open_shop(), "Flow: two insufficient hands show defeat without shop or reward")
	check.call(UI.find_button(scene.ui, "Nueva partida") != null and UI.find_button(scene.ui, "Volver al menú") != null, "Flow: defeat provides actual restart/menu actions")
	click(scene, "Volver al menú")
	check.call(scene.game.phase == "menu" and not scene.confirmation.visible, "Flow: ended run returns to menu directly")

	var boss = Game.new(9)
	boss.rival = 2
	Fixture.set_values(boss, [6, 6, 6, 6, 6])
	check.call(not boss.form_group([0, 1, 2, 3, 4]) and boss.form_group([0, 1, 2]) and boss.form_group([3, 4]), "Flow: boss rejects generala and accepts explicit trio plus pair")
	boss.cash = -20
	boss.passives = ["even"]
	boss.consumable = "boost"
	boss.dice[0].shell = "ruby"
	boss.dice[0].shell_broken = true
	boss.global_points = {"6": 4}
	boss.cup.stickers = {"trio": 2}
	scene.game = boss
	scene.start_new_run(9)
	check.call(boss.phase == "level_intro" and boss.cash == 0 and boss.dice == preload("res://scripts/dice_state.gd").create_dice(), "Flow: new run clears debt, broken shells, faces and effects")
	check.call(boss.passives.is_empty() and boss.consumable == "" and boss.global_points.is_empty() and boss.cup.stickers.is_empty() and boss.groups.is_empty(), "Flow: new run clears inventory, upgrades, stickers and groups")
	# Final boss preserves D08: optional selective repairs before final victory.
	boss.restart(9)
	boss.rival = 2
	boss.global_points = {"6": 20}
	boss.dice[0].shell = "ruby"
	boss.dice[0].shell_broken = true
	Fixture.set_values(boss, [6, 6, 6, 6, 6])
	boss.form_group([0, 1, 2])
	boss.form_group([3, 4])
	boss.score_hand()
	scene.render()
	click(scene, "Cerrar y cobrar")
	check.call(boss.phase == "repair" and UI.find_button(scene.ui, "Continuar sin reparar") != null, "Flow: winning boss enters pending repairs before final victory")
	before = boss.snapshot()
	click(scene, "Recorrido · M")
	check.call(scene.detail.visible and boss.snapshot() == before, "Flow: route remains accessible during final repairs without repeating payout")
	scene.detail.hide()
	check.call(not boss.open_shop() and not boss.leave_shop() and not boss.close_encounter(), "Flow: pending final repairs cannot skip to shop or collect twice")
	click(scene, "Continuar sin reparar")
	check.call(boss.phase == "won" and boss.dice[0].shell_broken and UI.text_in(scene.ui, "VICTORIA"), "Flow: declining final repairs preserves shell and shows completed level")
	before = boss.snapshot()
	check.call(not boss.resolve_repairs([0]) and boss.snapshot() == before, "Flow: final repair resolution is single use")
	var detached: Array = boss.route()
	detached[0].target = 9000
	check.call(boss.route()[0].target == 40 and boss.route()[2].status == "Superado", "Flow: route is detached, fixed and marks all stops won")

	# Fixed regression seed, generated dice and stock; repeat exclusively via UI controls.
	var seed_value := 3
	var natural = Game.new(seed_value)
	var expected: Array = play_run(natural)
	check.call(natural.phase == "won", "Flow: ordinary generated dice and shop permit completing the level")
	scene.start_new_run(seed_value)
	click(scene, "Empezar primer encuentro")
	var trace := play_run(scene.game, scene)
	check.call(scene.game.phase == "won" and trace == expected, "Flow: menu-to-boss victory through actual UI with natural dice/stock matches model")
	check.call(scene.game.rival == 2 and scene.game.passives.size() > 0 and UI.text_in(scene.ui, "JEFE SUPERADO"), "Flow: natural run includes purchases, two rivals and visible boss victory")
	check.call(scene.game.snapshot() == natural.snapshot(), "Flow: natural UI traversal preserves exact game state, RNG, stock, inventory and payouts")
	before = scene.game.snapshot()
	check.call(not scene.game.open_shop() and not scene.game.close_encounter() and not scene.game.leave_shop() and scene.game.snapshot() == before, "Flow: boss victory is terminal and cannot pay or advance again")
	click(scene, "Prototipo completado · volver a jugar")
	check.call(scene.game.phase == "level_intro" and scene.game.rival == 0 and scene.game.cash == 0, "Flow: victory restart starts fresh level announcement")
	return {"natural_seed": seed_value, "hands": trace, "natural_ui_victory": true, "save_available": false}
