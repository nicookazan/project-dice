extends SceneTree
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Game = preload("res://scripts/game.gd")
var scene
var prefix := ""
var errors := 0
var previous_pointer := Vector2.ZERO

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-drag-groups-" % [root.size.x, root.size.y]
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [2, 2, 2, 5, 5])
	scene.game.passives = ["even", "full"]
	scene.game.consumable = "roll"
	scene.render()
	UI.find_button(scene.ui, "Armar grupos arrastrando").button_pressed = true
	await capture("monedas")
	var before: Dictionary = scene.game.snapshot()
	await motion(scene.table_dice[0].get_global_transform() * Vector2(31, 31))
	await process_frame
	await capture("combinaciones")
	await drag(0, Vector2(450, 600), true)
	verify(scene.selected == [0] and scene.game.snapshot() == before, "Actual first drop stages only the dragged die without changing gameplay")
	await drag(1, Vector2(510, 600))
	verify(scene.selected == [0, 1], "Actual second drop preserves both draft dice")
	await capture("borrador")
	UI.find_button(scene.ui, "Armar grupo").pressed.emit()
	verify(scene.game.groups.size() == 1 and scene.game.groups[0].ids == [0, 1], "Native drag draft forms exact pair")
	await capture("grupo")
	before = scene.game.snapshot()
	await drag(2, Vector2(1415, 875))
	verify(scene.game.snapshot() == before and scene.selected.is_empty() and scene.table_dice[2].modulate.a == 1, "Invalid drop restores appearance and leaves gameplay unchanged")
	print("DRAG GROUP REVIEW: native pointer drag, draft, pair, invalid drop; ", errors, " errors")
	quit(0 if errors == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func motion(point: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = event.position - previous_pointer
	previous_pointer = event.position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)
	await process_frame

func click(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(event, true)
	await process_frame

func drag(id: int, destination: Vector2, review := false) -> void:
	var start: Vector2 = scene.table_dice[id].get_global_transform() * Vector2(31, 31)
	await motion(start)
	await click(start, true)
	await motion(start + Vector2(22, 0), true)
	await motion(start + Vector2(48, 8), true)
	verify(root.gui_is_dragging(), "Pointer movement starts native die drag")
	await motion((start + destination) / 2, true)
	if review: await capture("balanceo")
	await motion(destination, true)
	await click(destination, false)
	await process_frame

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
