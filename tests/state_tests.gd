extends RefCounted
const Game = preload("res://scripts/game.gd")
const DiceState = preload("res://scripts/dice_state.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

static func run(check: Callable) -> Dictionary:
	_test_isolation_and_restart(check)
	_test_rng_and_snapshot(check)
	return _test_two_hands_and_encounter(check)

static func _test_isolation_and_restart(check: Callable) -> void:
	var game = Game.new(91)
	check.call(game.dice.size() == 5, "state: exactly five dice at creation")
	var ids: Array = []
	for die in game.dice:
		ids.append(die.id)
	check.call(ids == [0, 1, 2, 3, 4], "state: stable unique ids match fixed slots")
	check.call(game.cup == {"material": "leather", "stickers": {}} and game.global_points.is_empty(), "state: initial leather cup and no global upgrades")
	var die: Dictionary = game.dice[0]
	die.faces[1] = 4
	die.material = "steel"
	die.shell = "ruby"
	die.shell_broken = true
	die.element = "fire"
	die.encounter_effects["steel_points"] = 6.0
	die.hand_effects["earth_points"] = 2.0
	game.global_points["4"] = 3
	game.cup.stickers["trio"] = 1
	game.sticker_catalog["trio"] = {"points_per_level": 0, "multiplier_per_level": 0, "price": 1} # Neutral persistence fixture, not balance.
	var isolated := true
	for index in range(1, 5):
		var other: Dictionary = game.dice[index]
		isolated = isolated and other.faces == [1, 2, 3, 4, 5, 6]
		isolated = isolated and not other.has("local_points") and other.encounter_effects.is_empty() and other.hand_effects.is_empty()
		isolated = isolated and other.material == "basic" and other.shell == "" and other.element == ""
	check.call(isolated, "state: modifying one die never changes the other four")
	var another = Game.new(91)
	check.call(another.dice[0].faces == [1, 2, 3, 4, 5, 6] and another.global_points.is_empty() and another.cup.stickers.is_empty(), "state: runs do not share nested data")
	game.passives = ["even"]
	game.consumable = "roll"
	game.cash = -3
	game.restart(91)
	check.call(game.cash == 0 and game.passives.is_empty() and game.consumable == "", "state: restart clears run inventory and debt")
	check.call(game.global_points.is_empty() and game.cup == {"material": "leather", "stickers": {}}, "state: restart clears globals and stickers")
	var fresh: bool = game.dice.size() == 5
	for index in range(5):
		fresh = fresh and game.dice[index] == DiceState.create_die(index)
	check.call(fresh, "state: restart restores all five basic dice and resets all scopes")
	die.faces[0] = 6
	check.call(game.dice[0].faces[0] == 1, "state: old run references cannot mutate the restarted run")

static func _test_rng_and_snapshot(check: Callable) -> void:
	var reference := RandomNumberGenerator.new()
	reference.seed = 42
	var game = Game.new(42)
	check.call(game.rng.state == reference.state, "state: constructing dice does not draw random numbers")
	var initial: Dictionary = game.snapshot()
	check.call(game.rng.state == initial.rng_state and game.snapshot() == initial, "state: unrolled snapshots are pure and repeatable")
	check.call(game.roll(), "state: first throw works with persistent dice")
	var same_rolls := true
	for die in game.dice:
		same_rolls = same_rolls and die.value == reference.randi_range(1, 6)
		same_rolls = same_rolls and die.face_index >= 0 and die.face_index < 6 and die.value == die.faces[die.face_index]
	check.call(same_rolls and game.rng.state == reference.state, "state: basic dice preserve original seeded rolls and RNG consumption")
	game.move_die(1, "cup")
	game.move_die(4, "cup")
	var conserved: Array = [game.dice[0].value, game.dice[2].value, game.dice[3].value]
	game.roll()
	var expected_one := reference.randi_range(1, 6)
	var expected_four := reference.randi_range(1, 6)
	check.call(game.dice[1].value == expected_one and game.dice[4].value == expected_four and game.rng.state == reference.state, "state: only selected rerolls consume RNG in stable order")
	check.call([game.dice[0].value, game.dice[2].value, game.dice[3].value] == conserved, "state: conserved results stay untouched")
	game.global_points["4"] = 3
	game.cup.stickers["trio"] = 2
	game.sticker_catalog["trio"] = {"points_per_level": 0, "multiplier_per_level": 0, "price": 1}
	game.dice[0].encounter_effects["steel_points"] = 6.0
	game.dice[0].hand_effects["earth_points"] = 2.0
	var before: Dictionary = game.snapshot()
	for iteration in range(20):
		game.preview()
		game.snapshot()
	check.call(game.snapshot() == before, "state: repeated preview and copies change neither data nor RNG")
	var copy: Dictionary = game.snapshot()
	copy.dice[0].faces[0] = 6
	copy.dice[0].encounter_effects["steel_points"] = 99.0
	copy.dice[0].hand_effects["earth_points"] = 99.0
	copy.global_points["4"] = 99
	copy.cup.stickers["trio"] = 99
	copy.passives.append("odd")
	check.call(game.snapshot() == before, "state: snapshot deeply isolates all nested run/encounter/hand fields")
	# Face-to-number mapping remains independent of numeric bonuses and powers.
	var mapped = Game.new(7)
	mapped.dice[0].faces = [4, 4, 4, 4, 4, 4]
	mapped.roll()
	check.call(mapped.dice[0].value == 4 and mapped.dice[0].faces[mapped.dice[0].face_index] == 4, "state: a rolled face index resolves through the stored six faces")

static func _test_two_hands_and_encounter(check: Callable) -> Dictionary:
	var game = Game.new(123)
	var die: Dictionary = game.dice[0]
	die.faces[1] = 4
	die.material = "steel"
	die.shell = "ruby"
	die.shell_broken = true
	die.element = "fire"
	game.global_points["4"] = 3
	game.cup.stickers["trio"] = 1
	game.sticker_catalog["trio"] = {"points_per_level": 0, "multiplier_per_level": 0, "price": 1} # Neutral persistence fixture.
	Fixture.set_values(game, [6, 6, 6, 2, 2])
	die.encounter_effects["steel_points"] = 6.0
	die.hand_effects["earth_points"] = 2.0
	check.call(game.form_group([0, 1, 2]), "state: persistent dice can form exact groups")
	game.move_die(3, "cup")
	game.move_die(3, "reserve")
	check.call(game.groups[0].locked and not game.ungroup(0), "state: persistent group ids retain cup-triggered locking")
	check.call(not game.form_group([0, 1]) and not game.move_die(0, "cup"), "state: grouped persistent die cannot be reused or rerolled")
	game.form_group([3, 4])
	var before: Dictionary = game.snapshot()
	var preview: Dictionary = game.preview()
	check.call(game.snapshot() == before, "state: grouped preview also leaves all scopes and RNG unchanged")
	check.call(preview.total == 48, "state: steel and fire apply while numeric upgrades to four do not affect sixes")
	game.score_hand()
	var first: Dictionary = {"hand": game.hand, "score": game.last_score.total, "ids": [0, 1, 2, 3, 4], "die": game.dice[0].duplicate(true)}
	check.call(game.next_hand(), "state: controlled example starts its second hand")
	check.call(game.dice.size() == 5 and game.groups.is_empty() and game.rolls_left == 3 and game.rolls_made == 0, "state: new hand resets groups and throw budget")
	var reset := true
	for current in game.dice:
		reset = reset and current.zone == "cup" and current.value == 0 and current.face_index == -1 and current.hand_effects.is_empty()
	check.call(reset, "state: new hand clears all results/zones/hand counters")
	check.call(game.dice[0].encounter_effects == {"steel_points": 6.0}, "state: new hand preserves encounter counters")
	check.call(game.dice[0].faces == [1, 4, 3, 4, 5, 6] and not game.dice[0].has("local_points"), "state: new hand preserves modified faces and local upgrades")
	check.call(game.dice[0].shell_broken and game.dice[0].material == "steel" and game.dice[0].shell == "ruby" and game.dice[0].element == "fire", "state: new hand preserves all three components and broken shell")
	die.hand_effects["identity_probe"] = 8
	check.call(game.dice[0].hand_effects.get("identity_probe") == 8, "state: new hand keeps the same actual die, not just a replacement copy")
	game.roll()
	Fixture.set_values(game, [6, 6, 6, 6, 6])
	check.call(game.form_group([0, 1, 2, 3, 4]), "state: same five ids can regroup in next hand")
	game.score_hand()
	check.call(game.points == 139 and game.last_score.total == 91, "state: two-hand example includes steel and fire each hand without consuming either")
	var second: Dictionary = {"hand": game.hand, "score": game.last_score.total, "accumulated": game.points, "die": game.dice[0].duplicate(true)}
	var closed: bool = game.close_encounter()
	if game.phase == "repair": game.resolve_repairs([])
	check.call(closed and game.open_shop(), "state: example reaches real reward/repair/shop transitions")
	check.call(game.dice.size() == 5 and game.dice[0].shell_broken, "state: broken shell never removes its die")
	check.call(game.leave_shop(), "state: example enters the next rival")
	check.call(game.rival == 1 and game.hand == 1 and game.points == 0 and game.history.is_empty(), "state: next rival resets encounter progress")
	check.call(game.dice[0].encounter_effects.is_empty() and game.dice[0].hand_effects.is_empty(), "state: next rival clears both temporary scopes")
	check.call(game.dice[0].faces == [1, 4, 3, 4, 5, 6] and not game.dice[0].has("local_points"), "state: next rival keeps modified faces and every local upgrade")
	check.call(game.global_points == {"4": 3} and game.cup.stickers == {"trio": 1} and game.cup.material == "leather", "state: next rival keeps run globals and leather cup")
	check.call(game.dice[0].id == 0 and game.dice[0].shell_broken and game.dice.size() == 5, "state: stable id and broken shell survive encounter transition")
	var next: Dictionary = {"rival": game.rival, "hand": game.hand, "points": game.points, "die": game.dice[0].duplicate(true)}
	game.history.append({"nested": {"value": 1}})
	var detached: Dictionary = game.snapshot()
	detached.history[0].nested.value = 9
	check.call(game.history[0].nested.value == 1, "state: snapshot also isolates nested score/history records")
	return {"first_hand": first, "second_hand": second, "next_encounter": next, "note": "Controlled test only; steel adds six and fire adds five per valid group. Broken ruby stays suspended; repair is declined before the next rival."}
