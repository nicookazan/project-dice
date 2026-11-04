extends RefCounted
## Fase F de docs/PLAN-JEFES.md: recorrido de los 21 encuentros con cada jefe forzado al menos una vez.
const Game = preload("res://scripts/game.gd")
const Catalog = preload("res://scripts/boss_catalog.gd")
const Validator = preload("res://scripts/save_validator.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const SaveTests = preload("res://tests/save_tests.gd")

static func run(check: Callable) -> Dictionary:
	var seen: Array = []
	for slot in [1, 2, 3]:
		var forced: Array = Catalog.ROWS.filter(func(row): return row.slot == slot).map(func(row): return row.id)
		var game = Game.new(800 + slot)
		game.development_bosses = true
		game.forced_boss_ids = forced
		check.call(game.begin_campaign(800 + slot), "Boss run %d: campaign starts with forced bosses" % slot)
		var steps := 0
		var consistent := true
		while game.phase != "won" and steps < 30:
			steps += 1
			if game.phase == "level_intro": game.begin_level()
			if game.is_boss():
				var expected: String = forced[game.level_index]
				if game.selected_bosses[str(game.level_index)] != expected or game.boss_rule.id != expected: consistent = false
				if expected not in seen: seen.append(expected)
			if Validator.validate(SaveTests.payload(game)) != "": consistent = false
			Fixture.set_values(game, [1, 2, 3, 4, 5])
			if not game.score_hand(): consistent = false
			if Validator.validate(SaveTests.payload(game)) != "": consistent = false
			game.points = maxi(game.points, game.target())
			if not game.close_encounter(): consistent = false
			if game.phase == "repair": game.resolve_repairs([])
			if game.phase == "reward":
				if game.has_next_encounter() and not game.open_shop(): consistent = false
				if game.phase == "shop" and not game.leave_shop(): consistent = false
		check.call(game.phase == "won" and steps == 21 and game.completed_encounters.size() == 21, "Boss run %d: the 21 encounters complete (%d steps)" % [slot, steps])
		check.call(consistent, "Boss run %d: forced bosses, boss rules and every checkpoint stay consistent" % slot)
	check.call(seen.size() == 21, "Boss run: every one of the 21 bosses was played at least once")
	var unforced = Game.new(809)
	unforced.development_bosses = false
	unforced.forced_boss_ids = ["l3_conde"]
	unforced.begin_campaign(809)
	check.call(unforced.forced_boss_ids == ["l3_conde"] and unforced.selected_bosses["0"] != "l3_conde", "Boss run: forcing only works in development builds")
	return {"bosses_played": seen.size(), "runs": 3, "encounters_per_run": 21}
