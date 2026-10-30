extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Gems = preload("res://scripts/gems.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Upgrades = preload("res://scripts/number_upgrades.gd")

static func run(check: Callable) -> Dictionary:
	_test_individual(check)
	_test_suspension(check)
	return _test_mixed(check)

static func _pair(shell: String):
	var game = Game.new(71)
	game.dice[0].shell = shell
	Fixture.set_values(game, [4, 4, 1, 2, 3])
	game.form_group([0, 1])
	return game

static func _test_individual(check: Callable) -> void:
	var emerald = _pair("emerald")
	emerald.dice[0].element = "fire"
	Upgrades.apply_global(emerald.global_points, 4, 3)
	var row: Dictionary = emerald.preview().rows[0]
	check.call(row.die_rows[0].points == 24 and row.die_rows[0].before_factors == 12, "emerald: approved (4+3+5)x2 gives twenty-four")
	check.call(row.base == 5 and row.die_rows[1].points == 7 and row.total == 36, "emerald: category base and companion never double")
	check.call(row.die_rows[0].point_factors == [{"source": "shell:emerald:0", "amount": 2.0}], "emerald: own factor is sourced exactly once")
	for element in ["water", "electricity", "earth"]:
		var game = _pair("emerald")
		game.dice[0].element = element
		Fixture.set_results(game, [2, 2, 1, 3, 4])
		game.dice[0].hand_effects["earth_points"] = 6.0
		var gain: int = 5 if element == "water" else (3 if element == "electricity" else 6)
		check.call(game.preview().rows[0].die_rows[0].points == (2 + gain) * 2, "emerald: doubles own " + element + " bonus")
	var odd = _pair("emerald")
	Fixture.set_results(odd, [3, 3, 1, 2, 4])
	odd.passives = ["odd"]
	odd.boost = true
	check.call(odd.preview().rows[0].die_rows[0].points == 16 and odd.preview().rows[0].die_rows[1].points == 8, "emerald: odd coin and consumable enter own sum before doubling")
	var sapphire = _pair("sapphire")
	sapphire.dice[1].shell = "sapphire"
	check.call(sapphire.preview().rows[0].multiplier_sum == 5 and sapphire.preview().rows[0].total == 65, "sapphire: two shells add four to initial multiplier")
	var ruby = _pair("ruby")
	ruby.dice[1].shell = "ruby"
	check.call(ruby.preview().rows[0].multiplier == 2.25 and ruby.preview().rows[0].total == 29.25, "ruby: two shells multiply their factors to two and a quarter")
	var ordered = _pair("sapphire")
	ordered.dice[1].shell = "ruby"
	Upgrades.apply_global(ordered.global_points, 4, 7)
	row = ordered.preview().rows[0]
	check.call(row.subtotal == 27 and row.multiplier_sum == 3 and row.multiplier == 4.5 and row.total == 121.5, "gems: globally improved subtotal plus sapphire then ruby gives 121.5")
	var diamond = _pair("diamond")
	diamond.dice[1].shell = "diamond"
	Fixture.set_results(diamond, [6, 6, 1, 2, 3])
	Upgrades.apply_global(diamond.global_points, 6, 83)
	row = diamond.preview().rows[0]
	check.call(row.original_total == 183 and row.copy_count == 2 and row.total == 549, "diamond: two copies of globally improved 183 give 549")
	check.call(row.copies.size() == 2 and row.copies[0].source != row.copies[1].source, "diamond: each equipped source contributes one copy")
	var fractional = _pair("ruby")
	Fixture.set_results(fractional, [1, 1, 2, 2, 3])
	fractional.dice[2].shell = "ruby"
	fractional.form_group([2, 3])
	var score: Dictionary = fractional.preview()
	check.call(score.rows[0].total == 10.5 and score.rows[1].total == 13.5 and score.raw_total == 27 and score.total == 27, "gems: fractional groups sum before rounding, not twenty-eight")
	for sample in [
		{"values": [2, 2, 2, 4, 5], "ids": [0, 1, 2]},
		{"values": [2, 2, 2, 2, 5], "ids": [0, 1, 2, 3]},
		{"values": [2, 2, 2, 2, 2], "ids": [0, 1, 2, 3, 4]},
		{"values": [2, 2, 4, 4, 6], "ids": [0, 1, 2, 3]},
		{"values": [1, 2, 3, 4, 5], "ids": [0, 1, 2, 3, 4]}]:
		var game = Game.new(72)
		game.dice[0].shell = "diamond"
		Fixture.set_values(game, sample.values)
		game.form_group(sample.ids)
		check.call(game.preview().rows[0].copy_count == 1, "gems: power works in valid category " + game.groups[0].category)

static func _test_suspension(check: Callable) -> void:
	for shell in ["emerald", "sapphire", "ruby", "diamond"]:
		var game = _pair(shell)
		game.dice[0].shell_broken = true
		var row: Dictionary = game.preview().rows[0]
		check.call(row.total == 13 and row.multiplier == 1 and row.copy_count == 0 and row.die_rows[0].point_factors.is_empty(), "gems: broken " + shell + " has no arithmetic effect")
		check.call(not row.die_rows[0].shell_effect.active and "resquebrajada" in row.die_rows[0].shell_effect.reason, "gems: broken shell explains inactivity " + shell)
		game.dice[0].shell_broken = false
		game.ungroup(0)
		row = game.preview().rows[0]
		check.call(row.total == 14 and row.multiplier == 1 and row.copy_count == 0 and row.die_rows[0].points == 4, "gems: leftover " + shell + " has no shell power")
		check.call(not row.die_rows[0].shell_effect.active and "combinación" in row.die_rows[0].shell_effect.reason, "gems: leftover explains condition " + shell)
		game.form_group([0, 1])
		check.call(game.preview().rows[0].die_rows[0].shell_effect.active, "gems: intact grouped " + shell + " activates again without changing state")
	var unknown = _pair("glass")
	check.call(unknown.preview().rows[0].total == 13 and Gems.definition("").is_empty() and Gems.definition("glass").is_empty(), "gems: absent or unknown shells introduce no invented power")
	var info := Gems.definition("ruby")
	info.multiplier_factor = 99
	check.call(Gems.definition("ruby").multiplier_factor == 1.5, "gems: metadata copies cannot alter the catalog")
	var mixed = _pair("emerald")
	mixed.dice[0].shell_broken = true
	mixed.dice[0].material = "steel"
	mixed.dice[0].encounter_effects.steel_points = 3.0
	mixed.dice[0].element = "fire"
	check.call(mixed.preview().rows[0].die_rows[0].points == 12, "gems: suspended shell preserves active material and element")

static func _test_mixed(check: Callable) -> Dictionary:
	var game = Game.new(73)
	game.dice[0].material = "steel"
	game.dice[0].element = "earth"
	game.dice[2].material = "copper"
	game.dice[2].element = "wind"
	for id in range(5): game.dice[id].shell = ["emerald", "sapphire", "ruby", "diamond", "diamond"][id]
	Upgrades.apply_global(game.global_points, 4, 3)
	Upgrades.apply_global(game.global_points, 4, 12)
	game.passives = ["even"]
	game.roll()
	for iteration in range(2):
		game.move_die(2, "cup")
		game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	game.form_group([0, 1, 2, 3, 4])
	var before: Dictionary = game.snapshot()
	var score: Dictionary = game.preview()
	var row: Dictionary = score.rows[0]
	check.call(row.die_rows[0].before_factors == 39 and row.die_rows[0].points == 78, "gems mixed: emerald doubles numeric, steel, earth and even coin together")
	check.call(row.subtotal == 141 and row.multiplier_sum == 5 and row.multiplier == 7.5, "gems mixed: sapphire, copper and wind sum before ruby")
	check.call(row.original_total == 1057.5 and row.copy_count == 2 and score.raw_total == 3172.5 and score.total == 3173, "gems mixed: diamonds copy full resolved group and final half rounds once")
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "gems: twenty previews never mutate counters, shells, groups, events or RNG")
	var copied: Dictionary = game.preview()
	copied.rows[0].die_rows[0].shell_effect.point_factor = 999
	check.call(game.preview() == score, "gems: mutating returned effect metadata cannot change later scores")
	var rng_state: int = game.rng.state
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.state = rng_state
	for id in range(5): expected_rng.randf()
	var events_before: int = game.events.size()
	check.call(game.score_hand() and game.last_score == score and game.history[0].score == score, "gems: exact preview commits to score and history")
	check.call(game.rng.state == expected_rng.state and game.events.size() == events_before + 1 and game.events[-1].payload.score == score, "gems: scoring adds one event and exactly five shell checks, not one per copy")
	before = game.snapshot()
	check.call(not game.score_hand() and game.snapshot() == before, "gems: repeated scoring cannot duplicate credits or copies")
	check.call(game.next_hand() and game.dice[0].shell == "emerald", "gems: next hand preserves equipped shells after risk checks")
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 2])
	game.form_group([0, 1, 2, 3, 4])
	game.score_hand()
	check.call(game.history[0].score == score, "gems: later hand never rewrites previous copied score")
	game.close_encounter()
	if game.phase == "repair": game.resolve_repairs([])
	check.call(game.open_shop() and game.leave_shop() and game.dice[3].shell == "diamond", "gems: equipment survives reward/repair/shop transition")
	game.restart(73)
	check.call(game.dice[0].shell == "" and game.dice[4].shell == "", "gems: new run clears shells")
	return score
