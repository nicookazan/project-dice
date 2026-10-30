extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Elements = preload("res://scripts/elements.gd")
const Upgrades = preload("res://scripts/number_upgrades.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(check: Callable) -> Dictionary:
	_test_fire_water(check)
	var electricity := _test_electricity(check)
	var mixed := _test_composition(check)
	_test_purity_and_lifetime(check)
	return {"electricity": electricity, "mixed": mixed}

static func _test_fire_water(check: Callable) -> void:
	for element in ["fire", "water"]:
		for number in range(1, 7):
			var game = Game.new(1)
			game.dice[0].element = element
			Fixture.set_values(game, [number, number, 1, 2, 3])
			game.form_group([0, 1])
			var row: Dictionary = game.preview().rows[0]
			var expected_active: bool = number >= 4 if element == "fire" else number <= 3
			var effect: Dictionary = row.die_rows[0].element_effect
			check.call(effect.active == expected_active and row.die_rows[0].points == number + (5 if expected_active else 0), "elements: " + element + " boundary result " + str(number))
			check.call(row.die_rows[1].points == number and row.base == 5 and not effect.reason.is_empty(), "elements: conditional points stay on their own die and explain eligibility " + str([element, number]))
	var fire = Game.new(2)
	fire.dice[0].element = "fire"
	Fixture.set_values(fire, [4, 4, 1, 2, 3])
	check.call(fire.preview().rows[0].die_rows[0].points == 4 and not fire.preview().rows[0].die_rows[0].element_effect.active, "fire: loose four contributes four without activating")
	check.call(fire.preview().rows[0].die_rows[0].element_effect.reason == "Requiere una combinación desde par.", "fire: inactive leftovers explain the grouping condition")
	fire.form_group([0, 1])
	check.call(fire.preview().rows[0].die_rows[0].points == 9, "fire: grouped four contributes nine")
	var water = Game.new(3)
	water.dice[0].element = "water"
	Fixture.set_values(water, [3, 3, 3, 4, 5])
	water.form_group([0, 1, 2])
	check.call(water.preview().rows[0].die_rows[0].points == 8, "water: three in a trio contributes eight")
	water.ungroup(0)
	check.call(water.preview().rows[0].die_rows[0].points == 3 and not water.preview().rows[0].die_rows[0].element_effect.active, "water: low leftover does not activate")
	var improved = Game.new(4)
	improved.dice[0].element = "fire"
	Upgrades.apply_global(improved.global_points, 3, 9)
	Fixture.set_values(improved, [3, 3, 1, 2, 4])
	improved.form_group([0, 1])
	var own: Dictionary = improved.preview().rows[0].die_rows[0]
	check.call(own.points == 12 and own.number == 3 and not own.element_effect.active, "fire: improved three worth twelve remains ineligible")
	check.call(own.element_effect.reason == "La cara debe mostrar 4, 5 o 6.", "fire: wrong face has its own inactive reason")
	improved.dice[0].element = "water"
	check.call(improved.preview().rows[0].die_rows[0].points == 17, "water: high numeric value does not invalidate a low face")
	var straight = Game.new(5)
	straight.dice[0].element = "water"
	straight.dice[3].element = "fire"
	Fixture.set_values(straight, [1, 2, 3, 4, 5])
	straight.form_group([0, 1, 2, 3, 4])
	check.call(straight.preview().rows[0].die_rows[0].points == 6 and straight.preview().rows[0].die_rows[3].points == 9, "elements: both fixed bonuses work in a straight, not just equal-number groups")
	var double_pair = Game.new(6)
	double_pair.dice[0].element = "water"
	double_pair.dice[2].element = "fire"
	Fixture.set_values(double_pair, [2, 2, 4, 4, 6])
	double_pair.form_group([0, 1, 2, 3])
	check.call(double_pair.preview().rows[0].category == "Doble par" and double_pair.preview().rows[0].total == 37, "elements: double pair is an eligible combination for water/fire")

static func _test_electricity(check: Callable) -> Dictionary:
	var samples := [
		{"values": [2, 2, 3, 4, 5], "ids": [0, 1], "gain": 3},
		{"values": [2, 2, 2, 4, 5], "ids": [0, 1, 2], "gain": 6},
		{"values": [2, 2, 2, 2, 5], "ids": [0, 1, 2, 3], "gain": 9},
		{"values": [2, 2, 2, 2, 2], "ids": [0, 1, 2, 3, 4], "gain": 12}
	]
	for sample in samples:
		var game = Game.new(7)
		game.dice[0].element = "electricity"
		Fixture.set_values(game, sample.values)
		game.form_group(sample.ids)
		var die: Dictionary = game.preview().rows[0].die_rows[0]
		check.call(die.points == 2 + sample.gain and die.element_effect.points == sample.gain and die.element_effect.matches == sample.ids.size() - 1, "electricity: own gain for group size " + str(sample.ids.size()))
		check.call(game.preview().rows[0].die_rows[1].points == 2, "electricity: one electric does not give extra points to its companion")
	var full = Game.new(8)
	full.dice[0].element = "electricity"
	full.dice[2].element = "electricity"
	Fixture.set_values(full, [2, 2, 3, 3, 3])
	full.form_group([0, 1, 2, 3, 4])
	check.call(full.preview().rows[0].die_rows[0].points == 5 and full.preview().rows[0].die_rows[2].points == 9 and full.preview().total == 52, "electricity: full counts each electric's own number inside the same mixed group")
	var loose = Game.new(9)
	loose.dice[0].element = "electricity"
	loose.dice[1].element = "electricity"
	loose.dice[2].element = "fire"
	loose.dice[3].element = "water"
	Fixture.set_values(loose, [2, 2, 4, 5, 6])
	var prediction: Dictionary = loose.preview()
	check.call(prediction.rows.size() == 1 and prediction.total == 25, "electricity: two twos in unified leftovers each gain three")
	check.call(prediction.rows[0].die_rows[0].points == 5 and prediction.rows[0].die_rows[1].points == 5, "electricity: both leftover electrics independently count the other")
	check.call(not prediction.rows[0].die_rows[2].element_effect.active and not prediction.rows[0].die_rows[3].element_effect.active, "elements: fire/water remain inactive in the same leftovers")
	var split = Game.new(10)
	for id in [0, 2, 3, 4]: split.dice[id].element = "electricity"
	Fixture.set_values(split, [2, 2, 2, 3, 3])
	split.form_group([0, 1])
	var divided: Dictionary = split.preview()
	check.call(divided.rows[0].die_rows[0].element_effect.matches == 1 and divided.rows[0].die_rows[0].points == 5, "electricity: formed pair excludes equal number in leftovers")
	check.call(divided.rows[1].die_rows[0].points == 2 and not divided.rows[1].die_rows[0].element_effect.active, "electricity: leftover excludes equal numbers from formed pair and never counts itself")
	check.call(divided.rows[1].die_rows[1].points == 6 and divided.rows[1].die_rows[2].points == 6 and divided.total == 26, "electricity: other equal leftovers still match each other")
	var separate = Game.new(11)
	separate.dice[0].element = "electricity"
	separate.dice[3].element = "electricity"
	Fixture.set_values(separate, [2, 2, 2, 2, 2])
	separate.form_group([0, 1, 2])
	separate.form_group([3, 4])
	check.call(separate.preview().rows[0].die_rows[0].points == 8 and separate.preview().rows[1].die_rows[0].points == 5 and separate.preview().total == 34, "electricity: separate trio/pair do not share coincidences")
	var unique = Game.new(12)
	for die in unique.dice: die.element = "electricity"
	Fixture.set_values(unique, [1, 2, 3, 4, 5])
	unique.form_group([0, 1, 2, 3, 4])
	var no_matches := true
	for die in unique.preview().rows[0].die_rows:
		no_matches = no_matches and not die.element_effect.active and die.element_effect.points == 0 and not die.element_effect.reason.is_empty()
	check.call(no_matches, "electricity: a straight of distinct numbers gives no electric gain and explains why")
	var numeric = Game.new(20)
	numeric.dice[0].element = "electricity"
	numeric.dice[1].element = "electricity"
	numeric.dice[2].element = "electricity"
	Upgrades.apply_global(numeric.global_points, 2, 12)
	Upgrades.apply_global(numeric.global_points, 3, 11)
	Fixture.set_values(numeric, [2, 2, 3, 4, 5])
	var numbers: Array = numeric.preview().rows[0].die_rows
	check.call(numbers[0].points == 17 and numbers[1].points == 17 and numbers[0].element_effect.matches == 1, "electricity: equal face numbers share global upgrades and still match")
	check.call(numbers[2].points == 14 and not numbers[2].element_effect.active, "electricity: equal improved point values do not make different face numbers match")
	return {"unified_leftovers": prediction, "pair_and_leftovers": divided}

static func _test_composition(check: Callable) -> Dictionary:
	var game = Game.new(13)
	game.dice[0].material = "steel"
	game.dice[0].shell = "emerald"
	game.dice[0].element = "fire"
	Upgrades.apply_global(game.global_points, 4, 3)
	Upgrades.apply_global(game.global_points, 4, 12)
	game.roll()
	game.move_die(4, "cup")
	game.roll()
	Fixture.set_results(game, [4, 4, 1, 2, 3])
	game.form_group([0, 1])
	var row: Dictionary = game.preview().rows[0]
	check.call(row.die_rows[0].points == 54 and row.die_rows[1].points == 19 and row.total == 78, "elements: steel, global upgrades and fire sum before equipped emerald doubles own points")
	check.call(row.die_rows[0].element_effect.points == 5 and row.die_rows[0].element_effect.source == "element:fire:0", "elements: fire appears once with its source in own-point calculation")
	check.call(game.dice[0].shell == "emerald" and game.dice[0].material == "steel" and game.dice[0].element == "fire", "elements: material, shell and element coexist")
	game.passives = ["even"]
	check.call(game.preview().rows[0].die_rows[0].points == 58 and game.preview().rows[0].die_rows[1].points == 21, "elements: parity coins compose with material/numeric/element points before emerald")
	var copied: Dictionary = game.preview().rows[0].die_rows[0]
	copied.element_effect.points = 999
	check.call(game.preview().rows[0].die_rows[0].element_effect.points == 5, "elements: returned eligibility data is detached")
	var factor_game = Game.new(14)
	factor_game.dice[0].element = "fire"
	Upgrades.apply_global(factor_game.global_points, 4, 3)
	Fixture.set_values(factor_game, [4, 4, 1, 2, 3])
	factor_game.form_group([0, 1])
	var own: Dictionary = factor_game.preview().rows[0].die_rows[0]
	var factored := Rules.resolve_die(factor_game.dice[0], own.point_additions, [{"source": "fixture:own_factor", "amount": 2.0}])
	check.call(own.points == 12 and factored.points == 24, "elements: approved (4+3+5)x2 order works in a future-gem arithmetic fixture")
	var copper = Game.new(15)
	copper.dice[0].material = "copper"
	copper.dice[0].element = "water"
	copper.passives = ["full"]
	copper.roll()
	copper.move_die(0, "cup")
	copper.roll()
	Fixture.set_results(copper, [2, 2, 3, 3, 3])
	copper.form_group([0, 1, 2, 3, 4])
	var water_full: Dictionary = copper.preview().rows[0]
	check.call(water_full.die_rows[0].points == 7 and water_full.subtotal == 48 and water_full.multiplier == 2.5 and water_full.total == 120, "elements: water applies before copper and category multiplier")
	return {"steel_fire_pair": row, "water_copper_full": water_full, "future_own_factor": factored.points}

static func _test_purity_and_lifetime(check: Callable) -> void:
	var game = Game.new(16)
	game.dice[0].element = "fire"
	game.dice[1].element = "water"
	game.dice[2].element = "electricity"
	game.dice[0].faces = [4, 4, 4, 4, 4, 4]
	game.roll()
	game.move_die(0, "cup")
	game.roll()
	game.move_die(0, "cup")
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	game.form_group([0, 1])
	game.form_group([2, 3, 4])
	var before: Dictionary = game.snapshot()
	var prediction: Dictionary = game.preview()
	var reference := RandomNumberGenerator.new()
	reference.seed = 16
	for draw in range(7): reference.randi_range(0, 5)
	check.call(game.rng.state == reference.state, "elements: initial throw and two single-die rerolls consume exactly seven RNG draws")
	check.call(prediction.rows[0].die_rows[0].element_effect.points == 5, "elements: two rerolls never accumulate a ten-point fire")
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "elements: twenty previews preserve dice, RNG, events and both counter scopes")
	var empty_counters := true
	for die in game.dice: empty_counters = empty_counters and die.encounter_effects.is_empty() and die.hand_effects.is_empty()
	check.call(empty_counters, "elements: conditional powers never write persistent accumulation")
	check.call(game.score_hand() and game.last_score == prediction and game.events[-1].payload.score == prediction, "elements: exact preview is credited and recorded once")
	var after: Dictionary = game.snapshot()
	check.call(not game.score_hand() and game.snapshot() == after, "elements: repeated scoring neither consumes nor retriggers a power")
	var first_hand: Dictionary = game.history[0].score.duplicate(true)
	check.call(game.next_hand() and game.dice[0].element == "fire" and game.dice[1].element == "water" and game.dice[2].element == "electricity", "elements: all three element identities survive hand reset")
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	game.form_group([0, 1])
	game.form_group([2, 3, 4])
	check.call(game.preview().rows[0].die_rows[0].element_effect.points == 5 and game.preview().rows[1].die_rows[0].element_effect.points == 6, "elements: next hand evaluates fresh conditions with no decay or consumption")
	game.score_hand()
	check.call(game.history[0].score == first_hand, "elements: later evaluations do not rewrite old hands")
	check.call(game.close_encounter() and game.open_shop() and game.leave_shop() and game.dice[0].element == "fire" and game.dice[1].element == "water" and game.dice[2].element == "electricity", "elements: all powers remain equipped through reward/shop and next rival")
	# Check RNG preservation around evaluation directly, independent of shop draws.
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	var state: int = game.rng.state
	game.preview()
	check.call(game.rng.state == state, "elements: evaluating effects adds no RNG draw")
	game.restart(16)
	var reset := true
	for die in game.dice: reset = reset and die.element == ""
	check.call(reset, "elements: new run clears equipped elements")
	var catalog := Elements.catalog()
	catalog.fire.gain = 999
	check.call(Elements.definition("fire").gain == 5 and Elements.catalog().size() == 5, "elements: catalog copies cannot edit live rules; five initial elements")
	var info := Elements.definition("electricity")
	check.call(info.passive and not info.consumed and info.duration == "run", "elements: metadata states passive, permanent, unconsumed behavior")
