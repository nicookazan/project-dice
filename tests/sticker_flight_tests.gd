extends RefCounted
## Paso J08: vuelo del sticker suelto (nuevo y repetido) y paquetes que solo hacen volar lo nuevo.
const StickerFlight = preload("res://scripts/sticker_flight.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const Purchases = preload("res://tests/purchase_tests.gd")

static func offer_price(scene, index := 0) -> Button:
	return scene.ui.get_node("Shop_stickers/Offer_%d/Price" % index)

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	# Reglas puras del vuelo.
	check.call(StickerFlight.is_new_sticker(0) and not StickerFlight.is_new_sticker(1), "Sticker flight: a sticker is new only when the thermos did not have it")
	check.call(StickerFlight.notice_text("trio", 0, 1) == "¡Nuevo! Trío · Nivel 1" and StickerFlight.notice_text("trio", 1, 2) == "Trío · Nivel 1 → 2", "Sticker flight: the notice says new or the level change")
	var start := Vector2(1035, 530)
	var target := Vector2(173, 659)
	var mid := StickerFlight.flight_point(start, target, 10)
	check.call(StickerFlight.flight_point(start, target, 0).is_equal_approx(start) and StickerFlight.flight_point(start, target, StickerFlight.FLIGHT - 1).is_equal_approx(target) and mid.y < minf(start.y, target.y) - 50.0, "Sticker flight: it goes from the offer to the thermos slot along an arc")
	# Sticker suelto nuevo.
	var game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.game = game
	scene.render()
	var cash_before: int = game.cash
	offer_price(scene).pressed.emit()
	check.call(game.cup.stickers.get("trio", 0) == 1 and game.cash == cash_before - 4, "Sticker flight: the purchase is already done and paid before anything animates")
	var flight = scene.ui.get_node_or_null("StickerFlight")
	check.call(flight != null and flight.is_new and flight.thermos.stickers.has("trio") == false, "Sticker flight: a new loose sticker flies and the thermos does not show it yet")
	check.call(Backdrop.THERMOS_RECT.grow(20).has_point(flight.slot) and flight.from.x < flight.slot.x and not scene.background.stickers.has("trio"), "Sticker flight: in the shop on the table it flies to the table thermos beside the offers, drawn by the room without it")
	check.call(scene.ui.get_node_or_null("StickerReveal") == null and not scene.sticker_animation_active(), "Sticker flight: no dark overlay and the shop is not blocked")
	flight.step(StickerFlight.FRAME * (StickerFlight.HOLD + 8))
	check.call(flight.badge.visible and flight.thermos.stickers.has("trio") == false, "Sticker flight: in mid-air the sticker is in flight and not yet on the thermos")
	flight.step(StickerFlight.FRAME * (StickerFlight.FLIGHT + 1))
	check.call(flight.thermos.stickers.get("trio", 0) == 1 and not flight.badge.visible, "Sticker flight: on landing it is stuck on the thermos")
	check.call(scene.background.stickers.get("trio", 0) == 1, "Sticker flight: on landing the room draws it on the table thermos")
	flight.step(5.0)
	check.call(not is_instance_valid(flight) or flight.finished, "Sticker flight: it ends by itself")
	await scene.get_tree().process_frame
	check.call(scene.ui.get_node("Shop_cup/ThermosArtwork").stickers.get("trio", 0) == 1 and game.cup.stickers.get("trio", 0) == 1, "Sticker flight: the thermos ends with the real state")
	# Cortar el vuelo (cambiar de pantalla / omitir) deja el termo correcto.
	game = Purchases.fixture("sticker", {"id": "full"}, 6)
	scene.game = game
	scene.render()
	offer_price(scene).pressed.emit()
	var cut = scene.ui.get_node("StickerFlight")
	cut.finish()
	check.call(cut.thermos.stickers.get("full", 0) == 1, "Sticker flight: skipping it leaves the thermos right")
	scene.render()
	check.call(scene.ui.get_node_or_null("StickerFlight") == null and scene.ui.get_node("Shop_cup/ThermosArtwork").stickers.get("full", 0) == 1, "Sticker flight: redrawing mid-flight leaves the thermos right")
	# Sticker suelto repetido: no vuela, sube el aviso de nivel.
	game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	game.cup.stickers = {"trio": 1}
	scene.game = game
	scene.render()
	offer_price(scene).pressed.emit()
	var repeated = scene.ui.get_node("StickerFlight")
	check.call(game.cup.stickers.trio == 2 and not repeated.is_new and repeated.thermos.stickers.get("trio", 0) == 2, "Sticker flight: a repeated sticker levels up and the thermos keeps it")
	repeated.step(StickerFlight.FRAME * 10)
	check.call(not repeated.badge.visible and repeated.notice.visible and repeated.notice.text == "Trío · Nivel 1 → 2", "Sticker flight: a repeated sticker does not fly; the level notice rises")
	repeated.finish()
	# Sin movimiento no hay vuelo.
	scene.preferences.reduced_motion = true
	game = Purchases.fixture("sticker", {"id": "poker"}, 7)
	scene.game = game
	scene.render()
	offer_price(scene).pressed.emit()
	check.call(game.cup.stickers.get("poker", 0) == 1 and scene.ui.get_node_or_null("StickerFlight") == null, "Sticker flight: with reduced motion the purchase is direct")
	scene.preferences.reduced_motion = false
	# Paquete de dos con uno nuevo y uno repetido: solo vuela lo nuevo; lo repetido se desvanece en su lugar.
	game = Purchases.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	game.cup.stickers = {"trio": 2}
	scene.game = game
	scene.render()
	offer_price(scene).pressed.emit()
	var reveal = scene.sticker_animation
	check.call(reveal != null and reveal.items == ["trio", "full"] and game.cup.stickers == {"trio": 3, "full": 1}, "Sticker flight: the two-sticker pack is bought and saved before animating")
	reveal.set_process(false)
	reveal.step(2.5)
	var repeated_badge: Control = reveal.badges[0]
	var new_badge: Control = reveal.badges[1]
	check.call(repeated_badge.position == reveal.origins[0] and repeated_badge.scale == Vector2.ONE and repeated_badge.modulate.a < 1.0 and new_badge.position != reveal.origins[1], "Sticker flight: in a pack only the new sticker flies; the repeated one fades in place")
	reveal.finish()
	await scene.get_tree().process_frame
	check.call(scene.ui.get_node("Shop_cup/ThermosArtwork").stickers == {"trio": 3, "full": 1}, "Sticker flight: skipping the pack animation leaves the thermos right")
	# Paquete de elegir uno: un repetido se desvanece, uno nuevo vuela.
	game = Purchases.fixture("pack", {"pack_kind": "choose_one", "items": ["trio", "full", "poker"]}, 7)
	game.cup.stickers = {"trio": 1}
	scene.game = game
	scene.render()
	offer_price(scene).pressed.emit()
	check.call(game.phase == "sticker_choice" or game.pending_sticker_pack.size() > 0, "Sticker flight: the choose-one pack waits for the pick")
	scene.game = Purchases.fixture("sticker", {"id": "trio"}, 4)
	scene.render()
	scene.preferences.speed = 0
