extends SceneTree
const Tests = preload("res://tests/encounter_choice_tests.gd")
const Stickers = preload("res://scripts/stickers.gd")
const UI = preload("res://tests/interface_tests.gd")
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
	await create_timer(0.2).timeout
	prefix = "%dx%d-thermos-" % [root.size.x, root.size.y]
	scene.game = Tests.reward_game()
	for id in Stickers.NAMES: scene.game.cup.stickers[id] = 2
	scene.game.skip_shop()
	scene.render()
	verify(UI.text_in(scene.ui, "0/5") and not UI.text_in(scene.ui, "MONEDAS"), "Match coin inventory displays only the capacity fraction")
	var before: Dictionary = scene.game.snapshot()
	await capture("mesa-curvatura")
	await click(scene.ui.get_node("InspectThermos"), root)
	verify(scene.detail.visible and scene.thermos_panel.artwork.stickers.size() == 6 and not scene.detail_body.visible, "Clicking thermos opens enlarged illustration with all six owned stickers")
	await capture("ampliado")
	for id in Stickers.NAMES:
		var target: Control = scene.thermos_panel.get_node("Sticker_" + id)
		var motion := InputEventMouseMotion.new()
		motion.position = scene.get_global_transform_with_canvas() * (Vector2(scene.detail.position) + target.get_global_rect().get_center())
		root.push_input(motion, true)
		verify(scene.thermos_panel.title.text == Stickers.NAMES[id] + " · nivel 2" and "Efecto total con nivel 2" in scene.thermos_panel.description.text, "Native hover describes owned sticker " + id)
		if id == "full": await capture("hover-full")
	verify(scene.game.snapshot() == before, "All thermos hovers leave money, inventory and RNG unchanged")
	scene.detail.hide()
	scene.inspect_coin("boost")
	verify(scene.detail_body.visible and not scene.thermos_panel.visible, "Other detail dialogs remain usable after inspecting thermos")
	scene.detail.hide()
	scene.game.cup.stickers = {}
	scene.render()
	await click(scene.ui.get_node("InspectThermos"), root)
	verify(scene.thermos_panel.title.text == "Sin stickers" and scene.thermos_panel.artwork.stickers.is_empty(), "Empty thermos shows clean body and useful empty-state text")
	await capture("vacio")
	print("THERMOS REVIEW: ", errors, " errors")
	quit(0 if errors == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func click(target: Control, viewport: Viewport) -> void:
	await process_frame
	var point := target.get_global_transform_with_canvas() * (target.size / 2)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)
	await process_frame

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
