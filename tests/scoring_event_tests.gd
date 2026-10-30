extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const ObservedGame = preload("res://tests/support/observed_game.gd")

static func run(check: Callable) -> Dictionary:
	_test_breakdown(check)
	var arithmetic := _test_arithmetic(check)
	_test_validation(check)
	var events := _test_events(check)
	return {"arithmetic": arithmetic, "events": events}

static func _test_breakdown(check: Callable) -> void:
	var dice := Fixture.dice_with_values([1, 1, 1, 2, 2])
	var groups := [{"ids": [0, 1, 2, 3, 4], "category": "Full"}]
	var before_dice := dice.duplicate(true)
	var before_groups := groups.duplicate(true)
	var passives := ["full", "odd", "even"]
	var score := Rules.score(dice, groups, passives, true, true)
	var row: Dictionary = score.rows[0]
	check.call(score.valid and score.total == 122 and score.raw_total == 122.0, "score: served full with parity/boost/category coin remains correct")
	check.call(row.category_base == 30 and row.served_bonus == 5 and row.base == 35, "score: category and served bonus are distinct")
	check.call(row.dice == 7 and row.added == 19 and row.subtotal == 61, "score: face numbers and added own points are distinct")
	check.call(row.multiplier_base == 1 and row.multiplier_sum == 2 and row.multiplier == 2, "score: additive multiplier stage is explicit")
	check.call(row.multiplier_additions == [{"source": "coin:full", "amount": 1.0}], "score: multiplier additions identify their source")
	check.call(row.die_rows.size() == 5 and row.die_rows[0].id == 0 and row.die_rows[0].number == 1, "score: per-die identity and number are preserved")
	check.call(row.die_rows[0].point_additions == [{"source": "coin:odd", "amount": 2.0}, {"source": "consumable:boost", "amount": 3.0}], "score: parity and boost are separate per-die sources")
	check.call(row.die_rows[0].base_points == 1 and row.die_rows[0].points == 6, "score: per-die base and improved points are distinct")
	check.call(row.die_rows[3].point_additions == [{"source": "coin:even", "amount": 2.0}] and row.die_rows[3].points == 4, "score: parity uses the actual number")
	check.call(row.original_total == row.total and row.copy_count == 0 and row.multiplier_factors.is_empty(), "score: inactive factors/copies have explicit neutral stages")
	check.call(dice == before_dice and groups == before_groups and passives == ["full", "odd", "even"], "score: calculation does not mutate any inputs")
	row.ids.clear()
	row.die_rows[0].point_additions[0].amount = 500
	check.call(groups == before_groups and dice == before_dice, "score: returned breakdown has no aliases into dice or groups")
	var trio_pair := Rules.score(Fixture.dice_with_values([6, 6, 6, 2, 2]),
		[{"ids": [0, 1, 2], "category": "Trío"}, {"ids": [3, 4], "category": "Par"}], [], false, false)
	check.call(trio_pair.total == 37 and trio_pair.rows[0].total == 28 and trio_pair.rows[1].total == 9, "score: trio 28 plus pair 9 equals 37")
	var generala := Rules.score(Fixture.dice_with_values([6, 6, 6, 6, 6]),
		[{"ids": [0, 1, 2, 3, 4], "category": "Generala"}], [], false, true)
	check.call(generala.total == 130 and generala.rows[0].served_bonus == 50, "score: served sixes generala is 130, not an auto-win")
	var loose := Rules.score(Fixture.dice_with_values([2, 2, 3, 4, 5]), [], [], false, false)
	check.call(loose.rows.size() == 1 and loose.rows[0].category == "Sin combinación" and loose.total == 16, "score: leftovers never auto-form a pair")

static func _test_arithmetic(check: Callable) -> Dictionary:
	var additions := [{"source": "fixture:add", "amount": 1.0}]
	var factors := [{"source": "fixture:factor", "amount": 1.5}]
	var ordered := Rules.resolve_group(10.0, 0.0, 0.0, 2.0, additions, factors)
	check.call(ordered.multiplier_sum == 3 and ordered.multiplier == 4.5 and ordered.total == 45, "score: (2 + 1) x1.5 resolves to multiplier 4.5")
	var own := Rules.resolve_die(Fixture.dice_with_values([4])[0],
		[{"source": "fixture:numeric", "amount": 3.0}, {"source": "fixture:element", "amount": 5.0}],
		[{"source": "fixture:own_factor", "amount": 2.0}])
	check.call(own.number == 4 and own.before_factors == 12 and own.points == 24, "score: own-point factor follows additions without changing number")
	var multiplied := Rules.resolve_group(10.0, 0.0, 0.0, 1.0, [],
		[{"source": "fixture:factor1", "amount": 1.5}, {"source": "fixture:factor2", "amount": 1.5}])
	check.call(multiplied.multiplier == 2.25 and multiplied.total == 22.5, "score: repeated factors multiply, not add")
	var copies := Rules.resolve_group(100.0, 0.0, 0.0, 1.0, [], [],
		[{"source": "fixture:copy1", "amount": 1}, {"source": "fixture:copy2", "amount": 1}])
	check.call(copies.original_total == 100 and copies.copy_count == 2 and copies.total == 300, "score: copies use original total and never recursively copy")
	var first := Rules.resolve_group(0.0, 10.25, 0.0)
	var second := Rules.resolve_group(0.0, 10.25, 0.0)
	var result := Rules.finish_score([first, second], false)
	check.call(result.rows[0].total == 10.25 and result.rows[1].total == 10.25, "score: group fractions are never rounded")
	check.call(result.raw_total == 20.5 and result.total == 21, "score: two groups of 10.25 credit 21 after one final rounding")
	var fractional_game = ObservedGame.new(9)
	fractional_game.roll()
	fractional_game.fixture_rows = [first, second]
	check.call(fractional_game.score_hand() and fractional_game.points == 21 and fractional_game.last_score.raw_total == 20.5, "score: real hand transition credits 21 from a controlled fractional fixture")
	check.call(fractional_game.events[-1].payload.score.rows[0].total == 10.25 and fractional_game.observations[-1].total == 21, "score: event preserves raw group fractions and observes rounded credit")
	var credited_state: Dictionary = fractional_game.snapshot()
	check.call(not fractional_game.score_hand() and fractional_game.snapshot() == credited_state, "score: fractional credit is also idempotent")
	check.call(Rules.finish_score([Rules.resolve_group(0, 160.49, 0)], false).total == 160, "score: less than half rounds down")
	check.call(Rules.finish_score([Rules.resolve_group(0, 160.5, 0)], false).total == 161, "score: exact half rounds up")
	ordered.multiplier_additions[0].amount = 99
	ordered.multiplier_factors[0].amount = 99
	result.rows[0].total = 99
	check.call(additions[0].amount == 1 and factors[0].amount == 1.5 and first.total == 10.25, "score: arithmetic outputs deeply detach contribution/row inputs")
	return {"multiplier": 4.5, "group_totals": [first.total, second.total], "raw_total": result.raw_total, "credited": result.total, "copies_of_100": copies.total}

static func _test_validation(check: Callable) -> void:
	var dice := Fixture.dice_with_values([2, 2, 5, 5, 6])
	var invalid := [
		[{"ids": [], "category": "Par"}],
		[{"ids": [0, 0], "category": "Par"}],
		[{"ids": [-1, 0], "category": "Par"}],
		[{"ids": [0, 5], "category": "Par"}],
		[{"ids": [0.5, 1], "category": "Par"}],
		[{"ids": [0, 1], "category": "Par"}, {"ids": [0, 1], "category": "Par"}],
		[{"ids": [0, 1], "category": "Generala"}],
		[{"ids": [0, 1, 2, 3, 4], "category": "Doble par"}],
		[{"ids": [0, 1], "category": "Sin combinación"}],
		[{"ids": [0, 1], "category": "Desconocida"}],
		[{"ids": "01", "category": "Par"}]
	]
	for index in range(invalid.size()):
		var outcome := Rules.score(dice, invalid[index], [], false, false)
		check.call(not outcome.valid and outcome.total == 0 and outcome.rows.is_empty() and not outcome.errors.is_empty(), "score: invalid exact partition rejected safely " + str(index))
	var unrolled := Fixture.dice_with_values([1, 2, 3, 4, 5])
	unrolled[0].value = 0
	check.call(not Rules.score(unrolled, [], [], false, false).valid, "score: unrolled die cannot be credited by low-level scoring")
	var unknown := Rules.score(dice, [], ["not-a-coin"], false, false)
	check.call(not unknown.valid, "score: unknown passive fails without crashing")
	var game = Game.new(17)
	game.roll()
	Fixture.set_values(game, [2, 2, 5, 5, 6])
	game.groups = [{"ids": [0, 1], "category": "Generala", "locked": false}]
	var before_events: Array = game.events.duplicate(true)
	var before_rng: int = game.rng.state
	check.call(not game.score_hand() and game.points == 0 and game.history.is_empty() and game.phase == "play", "score: invalid hand never credits history/points or consumes the hand")
	check.call(game.events == before_events and game.rng.state == before_rng, "score: rejected hand emits no event and consumes no RNG")

static func _test_events(check: Callable) -> Array:
	var game = ObservedGame.new(42)
	check.call(game.events.is_empty() and game.event_sequence == 0, "events: creating state emits no action")
	game.roll()
	var initial: Dictionary = game.events[0]
	check.call(initial.type == Game.INITIAL_ROLL and initial.sequence == 1, "events: first effective throw emits initial roll exactly once")
	check.call(initial.payload.rolled_ids == [0, 1, 2, 3, 4] and initial.payload.kept_ids.is_empty(), "events: initial roll identifies all thrown dice")
	check.call(initial.payload.results.size() == 5 and game.roll_hooks == 1 and game.observations[0].rolls_made == 1, "events: roll hook sees resolved dice and roll budget")
	var count: int = game.events.size()
	check.call(not game.roll() and game.events.size() == count and game.roll_hooks == 1, "events: empty cup does not emit or activate roll hook")
	Fixture.set_values(game, [6, 6, 6, 6, 1])
	game.rolls_made = 1
	game.rolls_left = 2
	game.form_group([0, 1, 2, 3])
	check.call(game.preview().rows[0].base == 45, "events: poker has served base before reroll")
	game.move_die(4, "cup")
	game.move_die(4, "reserve")
	check.call(game.events.size() == count and game.roll_hooks == 1, "events: moving dice and locking groups are not throws")
	game.move_die(4, "cup")
	game.roll()
	var reroll: Dictionary = game.events[-1]
	check.call(reroll.type == Game.REROLL and reroll.payload.rolled_ids == [4] and reroll.payload.kept_ids == [0, 1, 2, 3], "events: effective reroll separates thrown and kept/grouped ids")
	check.call(not game.preview().served and game.preview().rows[0].base == 40 and game.groups[0].locked, "events: rerolling only leftover removes served bonus from locked poker")
	var before: Dictionary = game.snapshot()
	var prediction: Dictionary = game.preview()
	for iteration in range(20):
		game.preview()
	check.call(game.snapshot() == before and game.score_hooks == 0 and game.roll_hooks == 2, "events: twenty previews preserve all state, hooks, events and RNG")
	check.call(game.score_hand(), "events: valid hand commits")
	check.call(game.points == prediction.total and game.last_score == prediction, "events: committed result exactly matches preview")
	var scored: Dictionary = game.events[-1]
	var observed: Dictionary = game.observations[-1]
	check.call(scored.type == Game.HAND_SCORED and scored.payload.score == prediction and game.score_hooks == 1, "events: score event contains the once-credited exact breakdown")
	check.call(observed.points == prediction.total and observed.history_size == 1 and observed.phase == "hand_result", "events: after-score hook runs only after points/history/phase commit")
	check.call(game.last_score.total != -999 and not game.last_score.rows.is_empty() and scored.payload.score.total != -999, "events: hook event copy cannot mutate score/history/event log")
	var committed: Dictionary = game.snapshot()
	check.call(not game.score_hand() and game.snapshot() == committed and game.score_hooks == 1, "events: repeated annotate never credits or fires hooks again")
	var snapshot: Dictionary = game.snapshot()
	snapshot.events[-1].payload.score.rows.clear()
	check.call(not game.events[-1].payload.score.rows.is_empty(), "events: snapshots deeply detach event payloads")
	var cash_before: int = game.cash
	check.call(game.close_encounter(), "events: completed target closes encounter")
	var closed: Dictionary = game.events[-1]
	check.call(closed.type == Game.ENCOUNTER_CLOSED and closed.payload.cash_before == cash_before and closed.payload.cash_after == game.cash, "events: closing event observes the already-paid reward")
	var closed_state: Dictionary = game.snapshot()
	check.call(not game.close_encounter() and game.snapshot() == closed_state, "events: repeated close does not pay or emit twice")
	var summary: Array = game.events.duplicate(true)
	game.open_shop()
	game.leave_shop()
	check.call(game.events.is_empty() and game.event_sequence == 4, "events: next encounter clears its log but keeps run sequence")
	game.roll()
	check.call(game.events[0].type == Game.INITIAL_ROLL and game.events[0].sequence == 5, "events: next rival starts with initial throw, not a reroll")
	game.restart(42)
	check.call(game.events.is_empty() and game.event_sequence == 0, "events: new run clears log and sequence")
	var two_hands = Game.new(10)
	two_hands.roll()
	Fixture.set_values(two_hands, [1, 1, 1, 1, 1])
	two_hands.score_hand()
	check.call(two_hands.next_hand() and two_hands.roll(), "events: next hand can make its first effective throw")
	check.call(two_hands.events[-1].type == Game.INITIAL_ROLL and two_hands.events[-1].hand == 2 and two_hands.events[-1].sequence == 3, "events: second hand initial throw never counts as a reroll")
	return summary
