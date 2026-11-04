extends SceneTree
## Comprueba en el juego real dónde se puede soltar un dado para mandarlo al vaso.
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var last := Vector2.ZERO

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	for spot in [["sobre el dibujo del vaso", Vector2(1330, 490)], ["tela libre de la zona del vaso", Vector2(1120, 620)]]:
		scene.game = Game.new(521)
		Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
		scene.preferences.drag_groups = true
		scene.render()
		await process_frame
		var start: Vector2 = scene.table_dice[4].get_global_transform() * Vector2(31, 31)
		await motion(start, false)
		await press(start, true)
		await motion(start + Vector2(22, 0), true)
		await motion(start + Vector2(48, 8), true)
		var dragging: bool = root.gui_is_dragging()
		await motion(spot[1], true)
		await motion(spot[1] + Vector2(1, 1), true)
		await press(spot[1] + Vector2(1, 1), false)
		await process_frame
		print("RESULT %s: arrastrando=%s zona_final=%s" % [spot[0], dragging, scene.game.dice[4].zone])
	quit(0)

func motion(p: Vector2, held: bool) -> void:
	var e := InputEventMouseMotion.new(); e.position = p; e.relative = p - last; last = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(e, true)
	await process_frame

func press(p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new(); e.position = p; e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(e, true)
	await process_frame
