extends SceneTree
## Capturas del paso J08: vuelo del sticker suelto nuevo y aviso del repetido. Requiere GPU (sin --headless).
const Purchases = preload("res://tests/purchase_tests.gd")
const Flight = preload("res://scripts/sticker_flight.gd")
var scene

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.speed = 1
	scene.preferences.reduced_motion = false
	root.add_child(scene)
	await process_frame
	scene.game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.game.cup.stickers = {"full": 1, "poker": 1}
	scene.render()
	scene.ui.get_node("Shop_stickers/Offer_0/Price").pressed.emit()
	var flight = scene.ui.get_node("StickerFlight")
	flight.set_process(false)
	for f in [10, 20, 26, 30]:
		flight.elapsed = 0.0
		flight.step((f + 0.5) * Flight.FRAME)
		await shot("vuelo-%02d" % f)
	flight.finish()
	scene.game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.game.cup.stickers = {"trio": 1, "full": 1}
	scene.render()
	scene.ui.get_node("Shop_stickers/Offer_0/Price").pressed.emit()
	var repeated = scene.ui.get_node("StickerFlight")
	repeated.set_process(false)
	repeated.step(12 * Flight.FRAME)
	await shot("repetido")
	print("FLIGHT REVIEW OK")
	quit(0)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/flight-" + name + ".png")
