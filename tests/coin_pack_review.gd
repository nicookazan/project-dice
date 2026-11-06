extends SceneTree
## MON8: capturas del paquete de monedas en test-results/ (requiere GPU, sin --headless).
const PackTests = preload("res://tests/coin_pack_tests.gd")
const Coins = preload("res://scripts/coins.gd")
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
	DirAccess.make_dir_recursive_absolute("res://test-results")
	prefix = "%dx%d-pack-" % [root.size.x, root.size.y]
	# Tienda con paquete chico y grande (carta cerrada, sin contenido).
	var small = _find("small", [], func(offer): return true)
	var large = _find("large", PackTests.INVENTORIES["lleno"].passives, func(offer): return offer.effect.items.filter(func(id): return id in Coins.PASSIVES).size() >= 2)
	show(small)
	verify(scene.ui.get_node_or_null("Shop_coins/Offer_3") != null, "la tienda dibuja el paquete chico")
	await capture("tienda-chico")
	show(large)
	await capture("tienda-grande-inventario-lleno")
	# Panel del paquete chico.
	show(small)
	scene.ui.get_node("Shop_coins/Offer_3/Price").pressed.emit()
	await capture("panel-chico")
	# Panel grande y reemplazo con inventario lleno.
	show(large)
	scene.ui.get_node("Shop_coins/Offer_3/Price").pressed.emit()
	await capture("panel-grande")
	var passive: String = large.pending_coin_pack.items.filter(func(id): return id in Coins.PASSIVES)[0]
	scene.ui.get_node("CoinChoice/PackCoin_" + passive).pressed.emit()
	await capture("reemplazo-inventario-lleno")
	scene.ui.get_node("CoinChoice/ReplaceBack").pressed.emit()
	scene.ui.get_node("CoinChoice").get_node("PackCoin_" + passive).pressed.emit()
	scene.ui.get_node("CoinChoice/ReplaceCoin_%d" % large.coin_inventory.equipped[1].instance_id).pressed.emit()
	await capture("tras-primera-eleccion")
	# Cerrado y reabierto.
	scene.pack_panel_open = false
	scene.render()
	await capture("panel-cerrado")
	scene.pack_panel_open = true
	scene.render()
	await capture("panel-reabierto")
	# Moneda de ranura bloqueada (Bolsillo).
	var pocket = _find("large", PackTests.INVENTORIES["con Bolsillo"].passives, func(offer): return offer.effect.items.filter(func(id): return id in Coins.PASSIVES).size() >= 2)
	show(pocket)
	scene.ui.get_node("Shop_coins/Offer_3/Price").pressed.emit()
	var wanted: String = pocket.pending_coin_pack.items.filter(func(id): return id in Coins.PASSIVES)[0]
	scene.ui.get_node("CoinChoice/PackCoin_" + wanted).pressed.emit()
	verify(scene.ui.get_node("CoinChoice/ReplaceCoin_%d" % pocket.coin_inventory.equipped[0].instance_id).disabled, "Bolsillo aparece apagado")
	await capture("ranura-bloqueada")
	# Textos largos: las cinco descripciones más largas del catálogo.
	var longest: Array = Coins.catalog().keys()
	longest.sort_custom(func(a, b): return Coins.definition(a).description.length() > Coins.definition(b).description.length())
	var heavy = _find("large", [], func(offer): return true)
	show(heavy)
	scene.ui.get_node("Shop_coins/Offer_3/Price").pressed.emit()
	heavy.pending_coin_pack.items = longest.slice(0, 5)
	scene.render()
	await capture("textos-largos")
	print("COIN PACK REVIEW: capturas en test-results/; ", errors, " errores")
	quit(0 if errors == 0 else 1)

func _find(size: String, passives: Array, accept: Callable):
	for seed_value in range(1, 400):
		var game = PackTests._shop_game(seed_value, passives)
		var offer: Dictionary = PackTests._pack(game)
		if not offer.is_empty() and offer.effect.size == size and accept.call(offer): return game
	push_error("sin paquete " + size)
	return PackTests._shop_game(1, passives)

func show(game) -> void:
	scene.game = game
	scene.pack_panel_open = true
	scene.coin_pack_replacing = ""
	scene.render()

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error(message)

func capture(caption: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
