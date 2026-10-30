extends RefCounted
const Game = preload("res://scripts/game.gd")
const Materials = preload("res://scripts/materials.gd")
const Upgrades = preload("res://scripts/number_upgrades.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Rules = preload("res://scripts/rules.gd")

static func run(check: Callable) -> Dictionary:
	_test_steel_triggers(check)
	_test_steel_reset(check)
	_test_copper_leftovers(check)
	_test_copper_with_coins(check)
	var grouped := _test_grouped_materials(check)
	var lifetime := _test_lifetime(check)
	return {"grouped": grouped, "lifetime": lifetime}

static func _send_and_roll(game, ids: Array) -> bool:
	for id in ids:
		if not game.move_die(id, "cup"): return false
	return game.roll()

static func _test_steel_triggers(check: Callable) -> void:
	var game = Game.new(42)
	game.dice[0].material = "steel"
	check.call(game.roll() and Materials.steel_points(game.dice[0]) == 0, "steel: initial throw grants no points")
	Fixture.set_results(game, [4, 1, 2, 3, 5])
	game.move_die(1, "cup")
	game.move_die(1, "reserve")
	check.call(Materials.steel_points(game.dice[0]) == 0, "steel: send/withdraw without throwing grants nothing")
	check.call(not game.roll() and Materials.steel_points(game.dice[0]) == 0, "steel: empty throw grants nothing")
	check.call(_send_and_roll(game, [1]) and Materials.steel_points(game.dice[0]) == 3, "steel: keeping a loose steel during one other die reroll grants three")
	check.call(game.dice[0].value == 4, "steel: keeping the die preserves its number")
	check.call(_send_and_roll(game, [1, 2, 3, 4]) and Materials.steel_points(game.dice[0]) == 6, "steel: rerolling four others grants only another three")
	var score: Dictionary = game.preview()
	check.call(score.rows[0].die_rows[0].points == 10 and score.rows[0].multiplier == 1, "steel: leftover four plus six earned points contributes ten")
	check.call(score.rows[0].die_rows[0].point_additions == [{"source": "material:steel:0", "amount": 6.0}], "steel: own-point breakdown identifies the exact source")
	var reference := RandomNumberGenerator.new()
	reference.seed = 42
	for draw in range(10): reference.randi_range(0, 5)
	check.call(game.rng.state == reference.state, "materials: counters consume no RNG beyond actual dice throws")
	var before: Dictionary = game.snapshot()
	for iteration in range(20):
		game.preview()
		Materials.inspect(game.dice[0])
	check.call(game.snapshot() == before, "materials: repeated previews and inspection do not earn points or mutate events/RNG")
	var info := Materials.inspect(game.dice[0])
	check.call(info.name == "Acero" and info.duration == "encounter" and info.points == 6 and info.applies_to_leftovers and info.resets_on_own_reroll, "steel: inspection exposes its power, duration and reset")
	info.points = 999
	check.call(Materials.steel_points(game.dice[0]) == 6, "materials: inspection data is detached")
	var one = Game.new(7)
	var four = Game.new(7)
	one.dice[0].material = "steel"
	four.dice[0].material = "steel"
	one.roll()
	four.roll()
	_send_and_roll(one, [1])
	_send_and_roll(four, [1, 2, 3, 4])
	check.call(Materials.steel_points(one.dice[0]) == 3 and Materials.steel_points(four.dice[0]) == 3, "steel: one and four other thrown dice give the same single activation")

static func _test_steel_reset(check: Callable) -> void:
	var game = Game.new(9)
	var die: Dictionary = game.dice[0]
	die.material = "steel"
	die.shell = "ruby"
	die.shell_broken = true
	die.element = "fire"
	die.faces = [4, 4, 4, 4, 4, 4]
	Upgrades.apply_global(game.global_points, 4, 3)
	Upgrades.apply_global(game.global_points, 4, 12)
	game.roll()
	die.encounter_effects["unrelated"] = 7
	die.hand_effects["unrelated"] = 9
	_send_and_roll(game, [1])
	check.call(Materials.steel_points(die) == 3 and game.preview().rows[0].die_rows[0].points == 22, "steel: material points add to global/local upgrades")
	game.move_die(0, "cup")
	check.call(Materials.steel_points(die) == 3, "steel: entering cup alone does not erase earned points")
	check.call(game.roll() and Materials.steel_points(die) == 0, "steel: actual own reroll erases all steel accumulation")
	check.call(game.preview().rows[0].die_rows[0].points == 19, "steel: own reroll retains the four's numeric improvements")
	check.call(die.encounter_effects == {"unrelated": 7, "steel_points": 0.0} and die.hand_effects == {"unrelated": 9}, "steel: reset erases only steel, not other counters")
	check.call(not die.has("local_points") and game.global_points == {"4": 15} and die.faces == [4, 4, 4, 4, 4, 4], "steel: own reroll preserves faces and global upgrades")
	check.call(die.shell == "ruby" and die.shell_broken and die.element == "fire", "steel: own reroll preserves other components and shell damage")

static func _test_copper_leftovers(check: Callable) -> void:
	var game = Game.new(10)
	game.dice[0].material = "copper"
	game.roll()
	check.call(Materials.copper_multiplier(game.dice[0]) == 0, "copper: initial throw grants no multiplier")
	game.move_die(0, "cup")
	game.move_die(0, "reserve")
	check.call(Materials.copper_multiplier(game.dice[0]) == 0, "copper: moving without rolling grants no multiplier")
	check.call(_send_and_roll(game, [0]) and Materials.copper_multiplier(game.dice[0]) == 0.5, "copper: own first reroll earns half a multiplier")
	check.call(_send_and_roll(game, [0]) and Materials.copper_multiplier(game.dice[0]) == 1, "copper: second own reroll adds without resetting")
	var exhausted: Dictionary = game.snapshot()
	check.call(not game.roll() and game.snapshot() == exhausted, "copper: a rejected throw with no budget cannot earn or emit anything")
	Fixture.set_results(game, [4, 4, 1, 2, 3])
	var leftovers: Dictionary = game.preview()
	check.call(leftovers.rows[0].category == "Sin combinación" and leftovers.rows[0].multiplier == 1 and leftovers.total == 14, "copper: ungrouped repeated numbers do not activate its multiplier")
	check.call(Materials.copper_multiplier(game.dice[0]) == 1, "copper: leaving it as leftover does not erase accumulation")
	check.call(game.form_group([0, 1]), "copper: an earned copper can subsequently form a valid pair")
	var paired: Dictionary = game.preview()
	check.call(paired.rows[0].multiplier == 2 and paired.rows[0].total == 26 and paired.total == 32, "copper: accumulated one applies only to its own pair")
	check.call(paired.rows[0].multiplier_additions == [{"source": "material:copper:0", "amount": 1.0}], "copper: group breakdown identifies its die source")
	var info := Materials.inspect(game.dice[0])
	check.call(info.name == "Cobre" and info.multiplier_addition == 1 and not info.applies_to_leftovers and not info.resets_on_own_reroll, "copper: inspection describes duration/leftover/reset differences")
	var kept = Game.new(11)
	kept.dice[0].material = "copper"
	kept.roll()
	_send_and_roll(kept, [1, 2, 3, 4])
	check.call(Materials.copper_multiplier(kept.dice[0]) == 0, "copper: rerolling other dice never awards a kept copper")

static func _test_copper_with_coins(check: Callable) -> void:
	var game = Game.new(14)
	game.dice[0].material = "copper"
	game.dice[1].material = "copper"
	Upgrades.apply_global(game.global_points, 4, 3)
	Upgrades.apply_global(game.global_points, 4, 12)
	game.passives = ["full"]
	game.roll()
	_send_and_roll(game, [0, 1])
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	game.form_group([0, 1, 2, 3, 4])
	var row: Dictionary = game.preview().rows[0]
	check.call(row.subtotal == 74 and row.multiplier_sum == 3 and row.total == 222, "copper: global numeric upgrades and category coin compose with two coppers")
	check.call(row.multiplier_additions == [{"source": "material:copper:0", "amount": 0.5}, {"source": "material:copper:1", "amount": 0.5}, {"source": "coin:full", "amount": 1.0}], "copper: each material and category coin remain distinct additive sources")
	var factored := Rules.resolve_group(row.base, row.dice, row.added, row.multiplier_base, row.multiplier_additions, [{"source": "fixture:factor", "amount": 1.5}])
	check.call(factored.multiplier == 4.5 and factored.total == 333, "copper: earned additions precede later factors in shared arithmetic")

static func _test_grouped_materials(check: Callable) -> Dictionary:
	var game = Game.new(12)
	game.dice[0].material = "steel"
	game.dice[1].material = "steel"
	game.dice[2].material = "copper"
	game.dice[3].material = "copper"
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([0, 1])
	check.call(_send_and_roll(game, [2, 3]) and game.groups[0].locked, "materials: reroll fixes the steel pair")
	check.call(Materials.steel_points(game.dice[0]) == 3 and Materials.steel_points(game.dice[1]) == 3, "steel: each grouped steel earns once, not per thrown die")
	check.call(Materials.copper_multiplier(game.dice[2]) == 0.5 and Materials.copper_multiplier(game.dice[3]) == 0.5, "copper: each rerolled copper keeps its own half")
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([2, 3])
	var first: Dictionary = game.preview()
	check.call(first.rows[0].total == 19 and first.rows[1].total == 18 and first.total == 43, "materials: steel pair nineteen, copper pair eighteen and leftover six")
	check.call(first.rows[1].multiplier_additions.size() == 2 and first.rows[1].multiplier_sum == 2, "copper: two die contributions add in one group")
	var group_ids: Array = game.groups[0].ids.duplicate()
	_send_and_roll(game, [4])
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	var second: Dictionary = game.preview()
	check.call(Materials.steel_points(game.dice[0]) == 6 and Materials.steel_points(game.dice[1]) == 6 and second.rows[0].total == 25, "steel: a locked group still gains from later rerolls")
	check.call(Materials.copper_multiplier(game.dice[2]) == 0.5 and second.rows[1].total == 18, "copper: kept grouped copper earns no additional multiplier")
	check.call(game.groups[0].ids == group_ids and not game.ungroup(0) and not game.move_die(0, "cup"), "materials: gaining points never changes or unlocks a fixed group")
	check.call(second.total == 49, "materials: both groups retain independent scopes")
	var before: Dictionary = game.snapshot()
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "materials: locked-group previews do not activate material powers")
	game.score_hand()
	check.call(game.last_score == second and game.events[-1].payload.score == second, "materials: committed result matches preview and event")
	var history: Dictionary = game.history[0].score.duplicate(true)
	var committed: Dictionary = game.snapshot()
	check.call(not game.score_hand() and game.snapshot() == committed, "materials: repeated scoring does not retrigger or duplicate effects")
	return {"values": [4, 4, 2, 2, 6], "after_first_reroll": first, "after_second_reroll": second,
		"credited": game.points, "history": history}

static func _test_lifetime(check: Callable) -> Dictionary:
	var game = Game.new(13)
	game.dice[0].material = "steel"
	game.dice[1].material = "copper"
	Upgrades.apply_global(game.global_points, 4, 3)
	Upgrades.apply_global(game.global_points, 4, 12)
	Upgrades.change_face(game.dice, 0, 1, 4)
	game.roll()
	_send_and_roll(game, [1])
	_send_and_roll(game, [1])
	Fixture.set_results(game, [4, 4, 1, 2, 3])
	game.form_group([0, 1])
	game.score_hand()
	check.call(game.points == 104, "materials: global upgrades plus steel/copper credit 104 in first hand")
	var first_score: Dictionary = game.last_score.duplicate(true)
	check.call(game.next_hand() and Materials.steel_points(game.dice[0]) == 6 and Materials.copper_multiplier(game.dice[1]) == 1, "materials: both accumulations survive hand reset")
	check.call(game.roll() and Materials.steel_points(game.dice[0]) == 6 and Materials.copper_multiplier(game.dice[1]) == 1, "materials: next hand initial throw neither wipes steel nor increments copper")
	_send_and_roll(game, [1])
	check.call(Materials.steel_points(game.dice[0]) == 9 and Materials.copper_multiplier(game.dice[1]) == 1.5, "materials: next hand rerolls continue encounter accumulation")
	Fixture.set_results(game, [4, 4, 1, 2, 3])
	game.form_group([0, 1])
	game.score_hand()
	check.call(game.last_score.total == 136 and game.points == 240, "materials: second hand credits 136 and accumulates 240")
	check.call(game.history[0].score == first_score, "materials: later gains never rewrite an earlier hand")
	var second_score: Dictionary = game.last_score.duplicate(true)
	check.call(game.close_encounter() and game.open_shop(), "materials: complete encounter reaches actual reward and shop")
	check.call(Materials.steel_points(game.dice[0]) == 9 and Materials.copper_multiplier(game.dice[1]) == 1.5, "materials: counters stay available through reward/shop until next rival")
	check.call(game.leave_shop() and game.dice[0].encounter_effects.is_empty() and game.dice[1].encounter_effects.is_empty(), "materials: new rival resets both material counters")
	check.call(game.dice[0].material == "steel" and game.dice[1].material == "copper" and game.global_points == {"4": 15} and not game.dice[0].has("local_points") and game.dice[0].faces == [1, 4, 3, 4, 5, 6], "materials: new rival preserves material identities, faces and global numeric upgrades")
	game.roll()
	check.call(Materials.steel_points(game.dice[0]) == 0 and Materials.copper_multiplier(game.dice[1]) == 0, "materials: next rival initial throw starts with neutral accumulation")
	var copy: Dictionary = game.snapshot()
	copy.dice[0].encounter_effects["steel_points"] = 99
	check.call(Materials.steel_points(game.dice[0]) == 0, "materials: snapshot counters cannot mutate live dice")
	game.restart(13)
	check.call(game.dice[0].material == "basic" and game.dice[1].material == "basic" and game.dice[0].encounter_effects.is_empty(), "materials: restart removes run materials and earned counters")
	return {"first_hand": first_score, "second_hand": second_score, "accumulated": 186,
		"next_rival_steel": 0, "next_rival_copper": 0}
