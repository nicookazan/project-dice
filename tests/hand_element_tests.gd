extends RefCounted
const Game = preload("res://scripts/game.gd")
const Elements = preload("res://scripts/elements.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Upgrades = preload("res://scripts/number_upgrades.gd")

static func run(check: Callable) -> Dictionary:
	_test_triggers(check)
	return _test_mixed_lifetime(check)

static func _test_triggers(check: Callable) -> void:
	for kept_count in range(1, 5):
		var game = Game.new(60)
		game.dice[0].element = "earth"
		game.roll()
		check.call(Elements.earth_points(game.dice[0]) == 0, "earth: initial roll earns nothing")
		for id in range(kept_count, 5): game.move_die(id, "cup")
		game.roll()
		check.call(Elements.earth_points(game.dice[0]) == (kept_count - 1) * 2, "earth: exact other-kept count " + str(kept_count))
		for id in range(kept_count, 5): game.move_die(id, "cup")
		game.roll()
		check.call(Elements.earth_points(game.dice[0]) == (kept_count - 1) * 4, "earth: repeated valid reroll accumulates " + str(kept_count))
	var idle = Game.new(61)
	idle.dice[0].element = "earth"
	idle.dice[1].element = "wind"
	idle.roll()
	var counters: Array = [idle.dice[0].hand_effects.duplicate(true), idle.dice[1].hand_effects.duplicate(true)]
	idle.move_die(0, "cup")
	idle.move_die(0, "reserve")
	idle.move_die(1, "cup")
	idle.move_die(1, "reserve")
	var sequence: int = idle.event_sequence
	check.call(not idle.roll() and idle.event_sequence == sequence and idle.rolls_left == 2, "hand elements: empty cup spends no roll and emits no event")
	check.call(idle.dice[0].hand_effects == counters[0] and idle.dice[1].hand_effects == counters[1], "hand elements: movement and empty roll never earn counters")
	idle.move_die(1, "cup")
	idle.roll()
	check.call(Elements.wind_multiplier(idle.dice[1]) == 0.5 and Elements.earth_points(idle.dice[0]) == 6, "hand elements: simultaneous kept earth and own wind gains")
	idle.dice[0].hand_effects["unrelated"] = 9
	idle.dice[0].encounter_effects["unrelated"] = 11
	idle.dice[0].shell = "ruby"
	Upgrades.apply_global(idle.global_points, 4, 12)
	idle.move_die(0, "cup")
	check.call(Elements.earth_points(idle.dice[0]) == 6, "earth: sending to cup does not clear gain before effective reroll")
	idle.roll()
	check.call(Elements.earth_points(idle.dice[0]) == 0 and idle.dice[0].hand_effects.unrelated == 9 and idle.dice[0].encounter_effects.unrelated == 11, "earth: own reroll clears only earth's counter")
	check.call(idle.global_points["4"] == 12 and idle.dice[0].shell == "ruby" and idle.dice[0].element == "earth", "earth: own reroll preserves global improvements and components")
	check.call(Elements.wind_multiplier(idle.dice[1]) == 0.5, "wind: conserved wind gains nothing and loses nothing")
	var before := idle.snapshot()
	check.call(not idle.roll() and idle.snapshot() == before, "hand elements: rejected exhausted roll changes no counters, RNG or events")
	var winds = Game.new(62)
	winds.dice[0].element = "wind"
	winds.dice[1].element = "wind"
	winds.roll()
	check.call(Elements.wind_multiplier(winds.dice[0]) == 0, "wind: first throw never counts")
	for iteration in range(2):
		winds.move_die(0, "cup")
		winds.move_die(1, "cup")
		winds.roll()
	check.call(Elements.wind_multiplier(winds.dice[0]) == 1 and Elements.wind_multiplier(winds.dice[1]) == 1, "wind: two own rerolls accumulate independently")
	Fixture.set_results(winds, [2, 2, 3, 4, 5])
	check.call(winds.preview().rows[0].multiplier == 1 and not winds.preview().rows[0].die_rows[0].element_effect.active, "wind: leftovers never multiply")
	check.call(Elements.wind_multiplier(winds.dice[0]) == 1, "wind: scoring as leftover does not erase accumulation")
	winds.form_group([0, 1])
	check.call(winds.preview().rows[0].multiplier == 3 and winds.preview().rows[0].total == 27, "wind: multiple wind additions sum within their own group")
	check.call(winds.preview().rows[1].multiplier == 1, "wind: other groups receive no multiplier")
	winds.ungroup(0)
	Fixture.set_results(winds, [2, 2, 3, 3, 3])
	winds.form_group([0, 1, 2, 3, 4])
	winds.passives = ["full"]
	check.call(winds.preview().rows[0].multiplier == 4, "wind: category coin and wind add before future factors")
	var together = Game.new(64)
	for die in together.dice: die.element = "earth"
	together.roll()
	for id in range(5): together.move_die(id, "cup")
	together.roll()
	var zero := true
	for die in together.dice: zero = zero and Elements.earth_points(die) == 0
	check.call(zero, "earth: rerolling all dice gives no kept-die gain")
	together.move_die(4, "cup")
	together.roll()
	check.call(Elements.earth_points(together.dice[0]) == 6 and Elements.earth_points(together.dice[3]) == 6 and Elements.earth_points(together.dice[4]) == 0, "earth: several kept earth dice independently count each other")
	together.consumable = "roll"
	together.use_consumable()
	together.move_die(4, "cup")
	together.roll()
	check.call(Elements.earth_points(together.dice[0]) == 12, "earth: effective extra roll follows the same trigger")
	Upgrades.apply_global(together.global_points, 4, 3)
	Upgrades.apply_global(together.global_points, 4, 12)
	Fixture.set_results(together, [4, 4, 2, 2, 6])
	together.form_group([0, 1])
	check.call(together.preview().rows[0].die_rows[0].points == 31 and together.preview().rows[0].die_rows[1].points == 31, "earth: own accumulation composes with global upgrades on both matching dice")

static func _test_mixed_lifetime(check: Callable) -> Dictionary:
	var game = Game.new(63)
	game.dice[0].material = "steel"
	game.dice[0].element = "earth"
	game.dice[2].material = "copper"
	game.dice[2].element = "wind"
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([0, 1])
	for iteration in range(2):
		game.move_die(2, "cup")
		game.roll()
	check.call(game.groups[0].locked and Elements.earth_points(game.dice[0]) == 12 and game.dice[0].encounter_effects.steel_points == 6, "earth/steel: grouped and loose companions count, gaining six earth plus three steel per reroll")
	check.call(Elements.wind_multiplier(game.dice[2]) == 1 and game.dice[2].encounter_effects.copper_multiplier == 1, "wind/copper: two own rerolls gain one in each scope")
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([2, 3])
	var preview: Dictionary = game.preview()
	check.call(preview.rows[0].die_rows[0].points == 22 and preview.rows[0].total == 31, "earth/steel: independent own-point additions, no extra synergy")
	check.call(preview.rows[1].multiplier == 3 and preview.rows[1].total == 27 and preview.total == 64, "wind/copper: separate additions and exact hand total")
	var sources: Array = []
	for entry in preview.rows[1].multiplier_additions: sources.append(entry.source)
	check.call("element:wind:2" in sources and "material:copper:2" in sources, "hand elements: breakdown distinguishes encounter and hand origins")
	var before := game.snapshot()
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "hand elements: repeated previews preserve counters, groups, RNG and events")
	var reference := RandomNumberGenerator.new()
	reference.seed = 63
	for draw in range(7): reference.randi_range(0, 5)
	check.call(game.rng.state == reference.state and game.events.size() == 3, "hand elements: exactly seven random draws and three roll events")
	check.call(game.score_hand() and game.last_score == preview and game.events[-1].payload.score == preview, "hand elements: preview is credited unchanged and recorded once")
	before = game.snapshot()
	check.call(not game.score_hand() and game.snapshot() == before, "hand elements: duplicate scoring cannot earn or consume a bonus")
	check.call(game.next_hand(), "hand elements: second hand starts through normal transition")
	check.call(game.dice[0].hand_effects.is_empty() and game.dice[2].hand_effects.is_empty(), "hand elements: next hand clears earth and wind")
	check.call(game.dice[0].encounter_effects.steel_points == 6 and game.dice[2].encounter_effects.copper_multiplier == 1, "hand elements: next hand preserves steel and copper")
	game.roll()
	check.call(Elements.earth_points(game.dice[0]) == 0 and Elements.wind_multiplier(game.dice[2]) == 0 and game.dice[0].encounter_effects.steel_points == 6, "hand elements: next hand's initial roll neither earns elements nor erases steel")
	game.move_die(2, "cup")
	game.roll()
	Fixture.set_results(game, [4, 4, 2, 2, 6])
	game.form_group([2, 3])
	var second: Dictionary = game.preview()
	check.call(second.rows[1].die_rows[0].points == 19, "earth: new hand accumulates six fresh points plus preserved/increased steel, even in leftovers")
	check.call(second.rows[0].multiplier == 3 and game.dice[2].encounter_effects.copper_multiplier == 1.5 and Elements.wind_multiplier(game.dice[2]) == 0.5, "wind: next hand combines fresh half with encounter copper one and a half")
	game.score_hand()
	check.call(game.history[0].score == preview, "hand elements: second hand never rewrites first hand history")
	check.call(game.close_encounter() and game.open_shop() and game.leave_shop(), "hand elements: normal encounter/shop transition")
	check.call(game.dice[0].hand_effects.is_empty() and game.dice[0].encounter_effects.is_empty() and game.dice[2].hand_effects.is_empty() and game.dice[2].encounter_effects.is_empty(), "hand elements: new encounter clears both scopes")
	check.call(game.dice[0].element == "earth" and game.dice[2].element == "wind", "hand elements: equipment survives encounter reset")
	game.restart(63)
	check.call(game.dice[0].element == "" and game.dice[2].material == "basic", "hand elements: new run removes both families")
	return {"first_hand": preview, "second_hand": second}
