extends RefCounted
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Upgrades = preload("res://scripts/number_upgrades.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(check: Callable) -> Dictionary:
	var game = Game.new(42)
	Fixture.set_values(game, [4, 4, 1, 2, 3])
	check.call(Upgrades.apply_global(game.global_points, 4, 3), "numbers: apply global +3 to four")
	check.call(game.form_group([0, 1]), "numbers: improved fours keep their pair identity")
	var score: Dictionary = game.preview()
	check.call(score.rows[0].die_rows[0].points == 7 and score.rows[0].die_rows[1].points == 7 and score.total == 25, "numbers: every matching die receives the same global bonus exactly once")
	check.call(score.rows[0].die_rows[0].point_additions == [{"source": "number:global:4", "amount": 3}], "numbers: breakdown contains only global numeric sources")
	check.call(game.dice.all(func(die): return not die.has("local_points")), "numbers: current dice have no per-die numeric upgrade map")
	game.passives = ["even"]
	check.call(game.preview().total == 31, "numbers: global upgrades retain face parity for passive coins")
	game.passives = []
	check.call(Upgrades.apply_global(game.global_points, 4, 8) and game.global_points["4"] == 11, "numbers: repeated global upgrades accumulate")
	check.call(game.preview().rows[0].die_rows.all(func(die): return die.points == 15), "numbers: stacked upgrades apply equally to both fours")
	var before: Dictionary = game.snapshot()
	var forecast: Dictionary = game.preview()
	for iteration in range(20): game.preview()
	check.call(game.snapshot() == before, "numbers: global preview never changes state or RNG")
	check.call(game.score_hand() and game.last_score == forecast and game.points == forecast.total, "numbers: preview equals committed score and total")
	var history: Dictionary = game.last_score.duplicate(true)
	Upgrades.apply_global(game.global_points, 4, 2)
	check.call(game.last_score == history and game.history[0].score == history, "numbers: later upgrades preserve historical scoring")

	var faces = Game.new(7)
	faces.dice[0].material = "steel"
	faces.dice[0].encounter_effects.steel_points = 6.0
	Upgrades.apply_global(faces.global_points, 4, 12)
	check.call(Upgrades.change_face(faces.dice, 0, 3, 5), "numbers: face changes remain a separate targeted operation")
	Fixture.set_values(faces, [5, 4, 1, 2, 3])
	check.call(faces.preview().rows[0].die_rows[0].points == 11 and faces.preview().rows[0].die_rows[1].points == 16, "numbers: bonus follows displayed number across all dice rather than original face position")
	check.call(Upgrades.change_face(faces.dice, 0, 3, 4) and faces.global_points == {"4": 12}, "numbers: changing faces preserves global improvements")
	faces.dice[0].value = 4
	faces.dice[0].face_index = 3
	check.call(faces.preview().rows[0].die_rows[0].points == 22, "numbers: restored four receives global bonus plus its steel accumulation")
	var copy := faces.snapshot()
	copy.global_points["4"] = 99
	copy.dice[0].faces[0] = 6
	check.call(faces.global_points["4"] == 12 and faces.dice[0].faces[0] == 1, "numbers: global and face snapshots are deeply detached")

	for args in [[0, 3], [7, 3], ["4", 3], [4, 0], [4, -1], [4, 1.5], [4, true], [4, "3"]]:
		before = faces.snapshot()
		check.call(not Upgrades.apply_global(faces.global_points, args[0], args[1]) and faces.snapshot() == before, "numbers: invalid global operation is atomic " + str(args))
	for args in [[-1, 0, 4], [5, 0, 4], [0, -1, 4], [0, 6, 4], [0, 1.5, 4], [0, "1", 4], [0, 0, 0], [0, 0, 7], [0, 0, 4.5], [0, 0, 1]]:
		before = faces.snapshot()
		check.call(not Upgrades.change_face(faces.dice, args[0], args[1], args[2]) and faces.snapshot() == before, "numbers: invalid face operation is atomic " + str(args))
	var overflow := {"4": 9223372036854775807}
	check.call(not Upgrades.apply_global(overflow, 4, 1) and overflow["4"] == 9223372036854775807, "numbers: overflow is rejected before writing")
	check.call(not Rules.score(Fixture.dice_with_values([4, 4, 1, 2, 3]), [], [], false, false, {"4": "bad"}).valid, "numbers: malformed scoring data fails safely")
	for sample in [["common", 1, 3], ["rare", 4, 5], ["epic", 6, 8], ["legendary", 9, 10]]:
		for amount in [sample[1], sample[2]]:
			check.call(Upgrades.global_offer(4, amount, sample[0], 6).valid, "numbers: explicit rarity bounds accepted " + str([sample[0], amount]))
		check.call(not Upgrades.global_offer(4, sample[1] - 1, sample[0], 6).valid and not Upgrades.global_offer(4, sample[2] + 1, sample[0], 6).valid, "numbers: out-of-range offer magnitudes rejected " + sample[0])
	check.call(not Upgrades.global_offer(0, 3, "common", 6).valid and not Upgrades.global_offer(4, 3, "unknown", 6).valid and not Upgrades.global_offer(4, 3, "common", 0).valid, "numbers: offer number, rarity and positive price validated")
	faces.restart(7)
	check.call(faces.global_points.is_empty() and faces.dice.all(func(die): return not die.has("local_points")), "numbers: new run clears global upgrades without recreating local state")
	return {"scope": "global_only", "pair": score.rows[0], "hand_total": score.total}
