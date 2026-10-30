extends SceneTree
const Tests = preload("res://tests/encounter_choice_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
const Stickers = preload("res://scripts/stickers.gd")
var scene
var errors := 0
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-encounter-choice-" % [root.size.x, root.size.y]
	scene.game = Tests.reward_game()
	for id in Stickers.NAMES: scene.game.cup.stickers[id] = 2
	scene.game.skip_shop()
	scene.render()
	verify(not scene.background.shop_mode and scene.background.stickers == scene.game.cup.stickers and scene.background.stickers.size() == 6, "Match shows all six owned stickers on silver thermos")
	await capture("termo-en-partida")
	scene.game = Tests.reward_game()
	scene.render()
	var cash: int = scene.game.cash
	await capture("destino")
	await click(UI.find_button(scene.ui, "Seguir sin tienda →"))
	verify(scene.game.phase == "play" and scene.game.rival == 1 and scene.game.cash == cash and scene.game.shop_state.is_empty(), "Native direct-continuation click preserves credited money and skips stock generation")
	await capture("siguiente-rival")
	scene.game = Tests.reward_game()
	scene.render()
	await click(UI.find_button(scene.ui, "Ir a la tienda →"))
	verify(scene.game.phase == "shop" and scene.game.cash == cash and scene.background.shop_mode, "Native shop click opens seller with previously credited money")
	await capture("tienda")
	print("ENCOUNTER CHOICE REVIEW: ", errors, " errors")
	quit(0 if errors == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func click(target: Control) -> void:
	await process_frame
	var point := target.get_global_transform_with_canvas() * (target.size / 2)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
