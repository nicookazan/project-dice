extends RefCounted
## Madera: recuerda los números de la mano y, en grupo, los suma todos como puntos propios.
const Game = preload("res://scripts/game.gd")
const Materials = preload("res://scripts/materials.gd")
const DiceState = preload("res://scripts/dice_state.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")

## Primera tirada [4,1,2,5,6] (el dado 0 es madera si `wood`), segunda tirada con el dado 0 y resultado [3,3,2,5,6].
static func _play(wood: bool, group: bool) -> Dictionary:
	var game = Game.new(42)
	if wood: game.dice[0].material = "wood"
	game.roll()
	Fixture.set_results(game, [4, 1, 2, 5, 6])
	game.move_die(0, "cup")
	game.roll()
	var remembered := Materials.wood_points(game.dice[0])
	Fixture.set_results(game, [3, 3, 2, 5, 6])
	if group: game.form_group([0, 1])
	return {"game": game, "remembered": remembered, "preview": game.preview()}

static func run(check: Callable) -> void:
	var wood := _play(true, true)
	var plain := _play(false, true)
	check.call(wood.remembered == 4.0 and plain.remembered == 0.0, "Madera: al relanzar recuerda el 4 anterior; un dado común no acumula")
	check.call(JSON.stringify(wood.preview).contains("material:wood:0") and not JSON.stringify(plain.preview).contains("material:wood"), "Madera: en grupo el bono aparece en el desglose")
	check.call(wood.preview.total > plain.preview.total, "Madera: el par con madera puntúa más que el mismo par con un dado común (%s contra %s)" % [wood.preview.total, plain.preview.total])
	var loose := _play(true, false)
	check.call(not JSON.stringify(loose.preview).contains("material:wood"), "Madera: suelta, sin grupo, no suma su memoria")
	var third = Game.new(42)
	third.dice[0].material = "wood"
	third.roll()
	Fixture.set_results(third, [4, 1, 2, 5, 6])
	third.move_die(0, "cup")
	third.roll()
	Fixture.set_results(third, [3, 1, 2, 5, 6])
	third.move_die(0, "cup")
	third.roll()
	check.call(Materials.wood_points(third.dice[0]) == 7.0, "Madera: tres tiradas acumulan 4 + 3 = 7")
	var next_hand: Dictionary = third.dice[0].duplicate(true)
	DiceState.reset_hand(next_hand)
	check.call(Materials.wood_points(next_hand) == 0.0, "Madera: la memoria se borra al empezar otra mano")
	check.call(Materials.display_name("wood") == "Madera" and Materials.body_kind("wood") == 6 and Materials.wood_points(third.dice[1]) == 0.0, "Madera: nombre y cuerpo del shader")
