extends SceneTree
const ShopTests = preload("res://tests/shop_tests.gd")
const Purchases = preload("res://tests/purchase_tests.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
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
	prefix = "%dx%d-object-buy-" % [root.size.x, root.size.y]
	scene.game = ShopTests.game_at_shop(162)
	Fixture.set_values(scene.game, [4, 4, 4, 4, 4])
	scene.render()
	var offer: Dictionary = scene.game.shop_state.numbers.slots[0].duplicate(true)
	var cash: int = scene.game.cash
	await capture("antes")
	await click_object(scene.ui.get_node("Shop_numbers/Offer_0/ObjectHover"))
	verify(scene.game.shop_state.numbers.slots[0].is_empty() and scene.game.cash == cash - offer.price and scene.game.global_points[str(offer.effect.number)] == offer.effect.amount, "Native object click buys global improvement exactly once")
	await capture("comprado")
	scene.game = Purchases.fixture("face", {"number": 6}, 4)
	scene.render()
	await click_object(scene.ui.get_node("Shop_numbers/Offer_0/ObjectHover"))
	verify(scene.game.phase == "purchase_target" and scene.game.cash == 100, "Native face object click opens target selection without premature charge")
	await capture("objetivo")
	await click_object(scene.ui.get_node("PurchaseTarget/Die_2"))
	verify(scene.game.pending_purchase.target == {"die_id": 2} and scene.game.cash == 100, "Dice artwork selects target without charging")
	await click_object(scene.ui.get_node("PurchaseTarget/Face_1"))
	verify(scene.game.pending_purchase.target == {"die_id": 2, "face_index": 1} and scene.game.purchase_preview().ok, "Face artwork selects exact face for confirmation")
	await capture("cara-elegida")
	await click_object(scene.ui.get_node("PurchaseTarget/Die_3"))
	verify(scene.game.pending_purchase.target == {"die_id": 3} and not scene.game.purchase_preview().ok, "Changing die clears previous face selection")
	scene.game = Purchases.fixture("shell", {"id": "sapphire", "intact": true})
	scene.game.dice[1].material = "steel"
	scene.game.dice[1].shell = "ruby"
	scene.game.dice[1].element = "fire"
	scene.game.begin_purchase("components", "fixture:1")
	scene.render()
	await click_object(scene.ui.get_node("PurchaseTarget/Die_1"))
	verify(scene.game.purchase_preview().ok and scene.game.cash == 100, "Component dice artwork selects a valid target")
	await capture("boost-elegido")
	print("OBJECT PURCHASE REVIEW: artwork purchase, global upgrade and face confirmation; ", errors, " errors")
	quit(0 if errors == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func click_object(target: Control) -> void:
	await process_frame
	var point := target.get_global_transform_with_canvas() * Vector2(50, 45)
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
