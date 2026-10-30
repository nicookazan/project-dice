extends SceneTree
const Purchases = preload("res://tests/purchase_tests.gd")
const UI = preload("res://tests/interface_tests.gd")
var scene
var errors := 0
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-sticker-pack-" % [root.size.x, root.size.y]
	scene.game = Purchases.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.game.cup.stickers = {"trio": 2, "generala": 1}
	scene.render()
	await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
	verify(scene.sticker_animation_active() and scene.game.cash == 93 and scene.game.cup.stickers == {"trio": 3, "full": 1, "generala": 1}, "Pack commits one payment and both levels before animation")
	var paid: Dictionary = scene.game.snapshot()
	var reveal = scene.sticker_animation
	reveal.set_process(false)
	verify(not scene.game.begin_purchase("stickers", "fixture:1").ok and scene.game.snapshot() == paid, "Already consumed pack cannot pay twice")
	reveal.step(0.8)
	await capture("revelados")
	verify(reveal.thermos.stickers == {"trio": 2, "generala": 1}, "Thermos retains prior artwork until stickers arrive")
	reveal.step(1.65)
	await capture("vuelo")
	verify(reveal.badges[0].position.x < reveal.origins[0].x and reveal.badges[0].scale.x < 1 and scene.game.snapshot() == paid, "Revealed stickers fly and shrink without mutating saved gameplay or RNG")
	reveal.step(2)
	verify(reveal.finished and reveal.thermos.stickers == scene.game.cup.stickers, "Automatic arrival attaches both illustrations at their final levels")
	await capture("termo")
	scene.game = Purchases.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "pair_loose"]}, 7)
	scene.game.cup.stickers = {"trio": 2}
	scene.render()
	await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
	var candidates: Array = scene.game.pending_sticker_pack.items.duplicate()
	verify(scene.game.cash == 93 and scene.game.cup.stickers == {"trio": 2}, "Choice pack pays once and applies no unchosen sticker")
	await click(UI.find_button(scene.ui, "Cerrar panel"))
	await click(UI.find_button(scene.ui, "Elegir sticker pendiente"))
	verify(scene.game.pending_sticker_pack.items == candidates and scene.game.cash == 93, "Closing and reopening choice keeps paid candidates")
	await capture("eleccion")
	await click(scene.ui.get_node("StickerChoice/Sticker_full"))
	verify(scene.game.cup.stickers == {"trio": 2, "full": 1} and scene.game.cash == 93 and scene.sticker_animation.items == ["full"], "Clicking sticker artwork grants and animates only the chosen sticker")
	scene.sticker_animation.finish()
	scene.game = Purchases.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.preferences.reduced_motion = true
	scene.render()
	await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
	reveal = scene.sticker_animation
	reveal.set_process(false)
	var origin: Vector2 = reveal.badges[0].position
	reveal.step(0.9)
	verify(reveal.still and reveal.badges[0].position == origin and reveal.badges[0].scale == Vector2.ONE, "Reduced motion shows contents without flight or wobble")
	await click(reveal.get_node("Continue"))
	verify(not scene.sticker_animation_active() and scene.ui.get_node("Shop_cup/ThermosArtwork").stickers == {"trio": 1, "full": 1}, "Skipping attaches stickers immediately and unlocks shop")
	print("STICKER PACK REVIEW: ", errors, " errors")
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
