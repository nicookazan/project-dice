extends RefCounted
const Game = preload("res://scripts/game.gd")
const ForcedGame = preload("res://tests/support/breakage_game.gd")
const Gems = preload("res://scripts/gems.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(check: Callable) -> Dictionary:
	_test_risk(check)
	return _test_repairs(check)

static func _test_risk(check: Callable) -> void:
	for shell in ["emerald", "ruby", "sapphire", "diamond"]:
		var risk: float = Gems.RISKS[shell]
		for draw in [0.0, risk - 0.0001, risk, risk + 0.0001, 0.999]:
			var game = ForcedGame.new(80)
			game.dice[0].shell = shell
			game.draws = [draw]
			Fixture.set_values(game, [4, 4, 1, 2, 3])
			game.form_group([0, 1])
			var prediction: Dictionary = game.preview()
			game.score_hand()
			check.call(game.dice[0].shell_broken == (draw < risk) and game.draw_count == 1, "risk: exact threshold " + shell + " " + str(draw))
			check.call(game.credited_before_draw and game.last_score == prediction and game.history[0].score == prediction, "risk: checks only after unchanged credit/history for " + shell)
	var game = ForcedGame.new(81)
	game.dice[0].shell = "ruby"
	game.dice[0].material = "steel"
	game.dice[0].element = "fire"
	game.global_points["4"] = 12
	game.draws = [0.0]
	Fixture.set_values(game, [4, 4, 1, 2, 3])
	var before: Dictionary = game.snapshot()
	for iteration in range(10): game.preview()
	check.call(game.snapshot() == before and game.draw_count == 0, "risk: leftovers and preview never draw")
	game.form_group([0, 1])
	game.ungroup(0)
	game.move_die(4, "cup")
	game.move_die(4, "reserve")
	check.call(game.draw_count == 0, "risk: grouping and movement never draw")
	game.form_group([0, 1])
	var die_before: Dictionary = game.dice[0].duplicate(true)
	var prediction: Dictionary = game.preview()
	game.score_hand()
	check.call(game.last_score.rows[0].multiplier == 1.5 and game.last_score == prediction and game.dice[0].shell_broken, "risk: broken ruby still contributed to the just-credited hand")
	die_before.shell_broken = true
	check.call(game.dice[0] == die_before and game.dice.size() == 5, "risk: breakage changes only shell damage, never identity, faces or other layers")
	before = game.snapshot()
	var event: Dictionary = game.events[-1].duplicate(true)
	game._after_hand_scored(event)
	check.call(not game.score_hand() and game.snapshot() == before and game.draw_count == 1, "risk: repeated hook and score cannot repeat risk or credit")
	game.next_hand()
	Fixture.set_values(game, [4, 4, 1, 2, 3])
	game.form_group([0, 1])
	check.call(game.preview().rows[0].multiplier == 1 and game.preview().rows[0].die_rows[0].points == 21, "risk: next hand suspends ruby but keeps local points and fire")
	game.score_hand()
	check.call(game.draw_count == 1 and game.breakage_by_hand["2"].is_empty(), "risk: already broken shells do not draw next hand")
	var copies = ForcedGame.new(82)
	copies.dice[0].shell = "diamond"
	copies.dice[1].shell = "diamond"
	copies.dice[2].shell = "ruby"
	copies.dice[2].shell_broken = true
	copies.dice[4].shell = "emerald"
	copies.draws = [0.0, 0.999]
	Fixture.set_values(copies, [6, 6, 1, 2, 3])
	copies.form_group([0, 1])
	copies.score_hand()
	check.call(copies.draw_count == 2 and copies.breakage_by_hand["1"].size() == 2 and copies.last_score.rows[0].copy_count == 2, "risk: two diamonds create three results but only two risk checks; leftovers and broken shells excluded")
	var losing = ForcedGame.new(83)
	losing.hand = 2
	losing.dice[0].shell = "ruby"
	losing.draws = [0.0]
	Fixture.set_values(losing, [1, 1, 1, 1, 1])
	losing.form_group([0, 1])
	losing.score_hand()
	check.call(losing.phase == "lost" and losing.dice[0].shell_broken and losing.credited_before_draw, "risk: last losing hand checks risk after credit and before loss evaluation")
	check.call(not losing.resolve_repairs([0]), "repair: loss never offers repair")

static func _victory(rival: int = 0):
	var game = ForcedGame.new(84)
	game.rival = rival
	for id in range(4):
		game.dice[id].shell = ["emerald", "ruby", "sapphire", "diamond"][id]
		game.dice[id].shell_broken = true
	Fixture.set_values(game, [4, 4, 2, 2, 6])
	game.form_group([0, 1])
	game.points = game.target()
	game.score_hand()
	return game

static func _test_repairs(check: Callable) -> Dictionary:
	var game = _victory()
	var before: Dictionary = game.snapshot()
	check.call(not game.resolve_repairs([0]) and game.snapshot() == before, "repair: never allowed between hands or before reward")
	game.cash = -3
	game.close_encounter()
	check.call(game.phase == "repair" and game.payout.interest == 0 and game.cash == -3 + game.payout.total, "repair: reward credits once before offer; negative balance earns zero interest")
	var paid: int = game.cash
	before = game.snapshot()
	check.call(not game.close_encounter() and not game.open_shop() and not game.next_hand() and game.snapshot() == before, "repair: pending resolution blocks repeated payout and further play/shop")
	check.call(game.repair_quote([0, 1, 2, 3]).cost == 14, "repair: costs two three four five total fourteen")
	for id in range(4):
		check.call(game.repair_quote([id]).cost == id + 2, "repair: exact individual cost " + str(id))
	for ids in [[0, 0], [-1], [5], [0.0], [true], [4], [0, 4]]:
		check.call(not game.resolve_repairs(ids) and game.snapshot() == before, "repair: invalid or duplicate selection is atomic " + str(ids))
	var quote: Dictionary = game.repair_quote([0, 3])
	quote.items[0].cost = 999
	check.call(game.repair_quote([0, 3]).cost == 7 and game.snapshot() == before, "repair: cost previews and returned copies never mutate game")
	var dice_before: Array = game.dice.duplicate(true)
	check.call(game.resolve_repairs([0, 3]) and game.cash == paid - 7 and game.phase == "reward", "repair: exact selected costs deducted after reward")
	dice_before[0].shell_broken = false
	dice_before[3].shell_broken = false
	check.call(game.dice == dice_before and game.dice[1].shell_broken and game.dice[2].shell_broken, "repair: only selected damage flags change; other broken shells stay broken")
	before = game.snapshot()
	check.call(not game.resolve_repairs([1]) and not game.close_encounter() and game.snapshot() == before, "repair: duplicate confirmation cannot charge or pay again")
	var evidence: Dictionary = game.snapshot()
	evidence.repair_resolution.selected_ids.clear()
	evidence.breakage_by_hand.clear()
	check.call(game.repair_resolution.selected_ids == [0, 3] and not game.breakage_by_hand.is_empty(), "repair: snapshot isolates persisted resolution markers")
	game.open_shop()
	game.leave_shop()
	check.call(not game.dice[0].shell_broken and game.dice[1].shell_broken and game.repair_resolution.is_empty() and game.breakage_by_hand.is_empty(), "repair: new rival preserves damage/repair results and clears encounter markers")
	Fixture.set_values(game, [4, 4, 2, 2, 6])
	game.form_group([0, 1])
	game.form_group([2, 3])
	check.call(game.preview().rows[0].die_rows[0].points == 8 and game.preview().rows[0].multiplier == 1 and game.preview().rows[1].copy_count == 1, "repair: repaired emerald/diamond regain powers while unrepaired ruby/sapphire remain suspended")
	var declined = _victory()
	declined.close_encounter()
	paid = declined.cash
	check.call(declined.resolve_repairs([]) and declined.cash == paid and declined.dice[0].shell_broken and declined.repair_resolution.status == "declined", "repair: decline charges nothing and leaves damage")
	var debt = _victory()
	debt.hand = 2
	debt.cash = -3
	debt.points = debt.target()
	debt.close_encounter()
	check.call(debt.cash == 5 and debt.payout.total == 8, "repair: minus three plus reward eight equals five, with no interest")
	debt.resolve_repairs([0, 1, 2, 3])
	check.call(debt.cash == -9 and debt.repair_resolution.cost == 14, "repair: accepted selection may enter debt")
	debt.open_shop()
	debt.leave_shop()
	Fixture.set_values(debt, [1, 2, 3, 4, 5])
	debt.points = debt.target()
	debt.score_hand()
	paid = debt.cash
	debt.close_encounter()
	check.call(debt.cash == paid + debt.payout.total and debt.payout.interest == 0, "repair: later rewards add to debt normally without negative interest")
	var boss = _victory(2)
	boss.close_encounter()
	check.call(boss.phase == "repair" and boss.repair_resolution.next_phase == "won", "repair: final boss offers same optional repair before completed screen")
	check.call(boss.resolve_repairs([1]) and boss.phase == "won" and not boss.dice[1].shell_broken, "repair: final boss selection resolves before final victory")
	var fresh = Game.new(85)
	Fixture.set_values(fresh, [6, 6, 6, 6, 6])
	fresh.form_group([0, 1, 2, 3, 4])
	fresh.score_hand()
	fresh.close_encounter()
	check.call(fresh.phase == "reward" and fresh.repair_resolution.status == "not_needed", "repair: no broken shells skips offer without consuming RNG")
	var result: Dictionary = {"selected": game.snapshot(), "debt": debt.cash, "final_boss": boss.repair_resolution.duplicate(true)}
	boss.restart(84)
	check.call(boss.breakage_by_hand.is_empty() and boss.repair_resolution.is_empty() and boss.dice[1].shell == "", "repair: new run clears damage and resolution state")
	return result
