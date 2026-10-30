extends SceneTree
const Shop = preload("res://tests/shop_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
var scene
var prefix := ""
var errors := 0
var previous_pointer := Vector2.ZERO

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-coins-drag-" % [root.size.x, root.size.y]
	scene.game = Shop.game_at_shop(623)
	scene.game.passives = ["even", "odd"]
	scene.game.consumable = "boost"
	scene.game.shop_state = preload("res://scripts/shop.gd").clean_passive_offers(scene.game.shop_state, scene.game.passives)
	scene.game.cash = 12
	Fixture.set_results(scene.game, [1, 2, 3, 4, 5])
	scene.render()
	await capture("reposo")
	var before: Dictionary = scene.game.snapshot()
	var home := await begin_drag("even", 2)
	await motion(Vector2(920, 440), true)
	await capture("capa")
	await motion(home, true)
	await click(home, false)
	await process_frame
	verify(scene.game.snapshot() == before and not scene.coin_sale_overlay.visible and not scene.detail.visible and scene.ui.get_node("OwnedCoin_even").modulate.a == 1, "Returning a dragged coin restores its slot with no sale or inspection")
	await capture("devuelta")
	await begin_drag("even", 2)
	await motion(Vector2(920, 440), true)
	await click(Vector2(920, 440), false)
	await process_frame
	verify(scene.game.cash == 14 and scene.game.passives == ["odd"] and not scene.coin_sale_overlay.visible, "Case drop sells passive once for two dollars")
	await capture("vendida")
	await begin_drag("boost", 1)
	await motion(Vector2(920, 440), true)
	await capture("consumible")
	await click(Vector2(920, 440), false)
	await process_frame
	verify(scene.game.cash == 15 and scene.game.consumable == "" and scene.game.passives == ["odd"], "Consumable drop sells only that coin for one dollar")
	before = scene.game.snapshot()
	await begin_drag("odd", 2)
	await motion(Vector2(240, 850), true)
	await click(Vector2(240, 850), false)
	await process_frame
	verify(scene.game.snapshot() == before and not scene.coin_sale_overlay.visible, "Drop outside case returns coin without any game mutation")
	print("COIN DRAG REVIEW: native drag, transparent overlay, return, passive/consumable sale; ", errors, " errors")
	quit(0 if errors == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func motion(point: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = point - previous_pointer
	previous_pointer = point
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

func begin_drag(id: String, price: int) -> Vector2:
	var source = scene.ui.get_node("OwnedCoin_" + id)
	var start: Vector2 = source.get_global_transform() * Vector2(31, 19)
	await motion(start)
	await click(start, true)
	await motion(start + Vector2(22, 0), true)
	await motion(start + Vector2(48, -12), true)
	verify(root.gui_is_dragging() and scene.coin_sale_overlay.visible and scene.coin_sale_caption.text == "Vender: $%d" % price, "Native coin drag shows correct sale overlay")
	return start

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
