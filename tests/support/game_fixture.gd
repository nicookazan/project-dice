extends RefCounted
## Controlled results for tests only; never loaded by the playable game.
const DiceState = preload("res://scripts/dice_state.gd")

static func dice_with_values(values: Array) -> Array:
	var result: Array = []
	for id in range(values.size()):
		var die := DiceState.create_die(id)
		die.value = values[id]
		die.face_index = values[id] - 1
		die.zone = "reserve"
		result.append(die)
	return result

static func set_values(game, values: Array) -> void:
	set_results(game, values)
	game.rolls_made = 2
	game.rolls_left = 1

static func set_results(game, values: Array) -> void:
	assert(values.size() == DiceState.COUNT, "Game fixtures must keep five dice.")
	# Keep the actual persistent dice and their references/components.
	for id in range(values.size()):
		game.dice[id].value = values[id]
		game.dice[id].face_index = game.dice[id].faces.find(values[id])
		game.dice[id].zone = "reserve"

static func set_coin_offer(game, slot: int, id: String) -> void:
	var ids: Array = game.offers
	ids[slot] = id
	game.offers = ids
