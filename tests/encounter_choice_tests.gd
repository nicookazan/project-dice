extends RefCounted
## Pantallas y diseños (D20): cobro «+$total» → selección de encuentro → tienda a la que se entra varias veces, menú
## inicial sobre la mesa, mano oculta en el menú y ayuda de la mano del jefe debajo de la mano.
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const UI = preload("res://tests/interface_tests.gd")
const Store = preload("res://scripts/save_store.gd")
const SaveTests = preload("res://tests/save_tests.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const StartMenu = preload("res://scripts/start_menu.gd")
const EncounterLobby = preload("res://scripts/encounter_lobby.gd")
const Coins = preload("res://scripts/coins.gd")

static func reward_game():
	var game = Game.new(920)
	Profile.apply(game)
	game.cash = 20
	game.cup.stickers = {"trio": 2, "full": 1}
	game.dice[0].material = "steel"
	Fixture.set_values(game, [6, 6, 6, 6, 6])
	game.form_group([0, 1, 2, 3, 4])
	game.score_hand()
	game.close_encounter()
	return game

## Continuar del cobro y dejar la recompensa (si hay): el camino de antes, hasta la selección o la tienda del jefe.
static func past_reward(game) -> bool:
	var ok: bool = game.continue_after_reward()
	if game.phase == "bonus": ok = game.skip_reward()
	return ok

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.cancel_navigation()
	scene.profiles_enabled = false
	_payout(scene, check)
	_lobby(scene, check)
	_shop_reentry(check)
	_flow_rules(check)
	_menu(scene, check)
	_boss_help(scene, check)

## PS5: sin desglose; la libreta en blanco, «+$total» y Continuar.
static func _payout(scene, check: Callable) -> void:
	scene.game = reward_game()
	scene.render()
	var total = scene.ui.find_child("PayoutTotal", true, false)
	var go = scene.ui.find_child("ContinueReward", true, false)
	check.call(total != null and total.text == "+$%d" % scene.game.payout.total and go != null and not go.disabled, "Cobro: muestra solo el total cobrado y Continuar")
	check.call(not UI.text_in(scene.ui, "Manos sobrantes") and not UI.text_in(scene.ui, "Intereses") and scene.ui.find_child("EncounterChoice", true, false) == null, "Cobro: sin cartel de desglose")
	var note = scene.ui.find_child("PlayerNotebook", true, false)
	check.call(note != null and UI.text_in(note, "LIBRETA") and not UI.text_in(note, "PUNTOS") and UI.dice_in(scene.ui).is_empty(), "Cobro: la libreta queda en blanco y la mesa sin dados")
	# Neto: si se pagó una reparación de gemas, el número muestra lo que quedó de este cobro.
	scene.game.repair_resolution.cost = scene.game.payout.total + 3
	scene.render()
	check.call(scene.ui.find_child("PayoutTotal", true, false).text == "-$3", "Cobro: muestra lo ganado menos lo pagado por reparar gemas")
	scene.game.repair_resolution.cost = 0
	scene.render()
	go = scene.ui.find_child("ContinueReward", true, false)
	var cash: int = scene.game.cash
	go.pressed.emit()
	# Recompensa del rival (25/11): mejora de número o cambio de cara, gratis; se puede tomar o dejar.
	var reward: Dictionary = scene.game.pending_reward
	check.call(scene.game.phase == "bonus" and reward.source == "rival" and reward.offer.kind in ["global", "face"] and scene.ui.find_child("RewardChoice", true, false) != null and scene.game.cash == cash, "Recompensa: vencer a un rival da una mejora de número o un cambio de cara, sin cobrar de nuevo")
	var again = reward_game()
	check.call(again.pending_reward == reward, "Recompensa: misma partida, misma recompensa (azar propio, reproducible)")
	scene.ui.find_child("SkipReward", true, false).pressed.emit()
	check.call(scene.game.phase == "lobby" and scene.game.rival == 0 and scene.game.cash == cash and scene.game.pending_reward.is_empty(), "Cobro: Continuar y dejar la recompensa lleva a la selección sin volver a cobrar")
	# Tomarla: se aplica gratis (con dado y cara si hace falta) y sigue a la selección.
	var taker = reward_game()
	taker.continue_after_reward()
	var offer: Dictionary = taker.pending_reward.offer
	if offer.kind == "face": taker.set_reward_target({"die_id": 2, "face_index": 0})
	var points_before: Dictionary = taker.global_points.duplicate(true)
	var taken: Dictionary = taker.take_reward()
	check.call(taken.ok and taker.phase == "lobby" and taker.cash == cash and (taker.dice[2].faces[0] == offer.effect.number if offer.kind == "face" else taker.global_points != points_before), "Recompensa: tomarla la aplica gratis y sigue a la selección")
	# Jefe: una gema, que va al dado elegido.
	var boss = reward_game()
	boss.rival = 2
	boss.pending_reward = boss._draw_reward()
	check.call(boss.pending_reward.is_empty() or (boss.pending_reward.source == "boss" and boss.pending_reward.offer.kind == "shell"), "Recompensa: vencer a un jefe da una gema")

## PS4: selección de encuentro.
static func _lobby(scene, check: Callable) -> void:
	scene.game = reward_game()
	past_reward(scene.game)
	scene.render()
	var play = scene.ui.find_child("PlayNext", true, false)
	var shop = scene.ui.find_child("OpenShop", true, false)
	var skip = scene.ui.find_child("Skip", true, false)
	check.call(play != null and play.text == "Jugar contra el siguiente rival" and not play.disabled, "Selección: «Jugar contra el siguiente rival» habilitado")
	check.call(skip != null and skip.disabled and shop != null and not shop.disabled, "Selección: «Saltear» en gris y la tienda abierta después de ganar")
	check.call(UI.text_in(scene.ui, "%d PUNTOS" % scene.game.level_encounters[1].target) and UI.text_in(scene.ui, "Rival 2/3"), "Selección: objetivo y rival del próximo encuentro")
	check.call(scene.ui.find_child("LobbyOptions", true, false) != null and UI.find_button(scene.ui, "Abandonar partida") != null and scene.ui.find_child("PlayerNotebook", true, false) == null and UI.find_button(scene.ui, "Menú") == null and UI.find_button(scene.ui, "TIRAR (3)") == null, "Selección: Opciones y Abandonar donde iba la libreta, sin botonera ni Menú")
	check.call(scene.ui.find_child("BarProp_flag", true, false) == null and scene.ui.find_child("BarProp_soda_left", true, false) == null and scene.background.quiet and scene.background.copa_hits.all(func(hit): return not hit.visible), "Selección: bandera, sifones y estrellas no responden")
	var service = Store.new("res://test-results/encounter-choice/" + str(Time.get_ticks_usec()) + ".json")
	check.call(service.start(SaveTests.payload(scene.game)).ok, "Selección: es un punto de guardado válido para «Continuar partida»")
	var rng_before: int = scene.game.rng.state
	var serial: int = scene.game.shop_offer_sequence
	var persistent: Dictionary = CampaignTests.persistent_parts(scene.game)
	play.pressed.emit()
	check.call(scene.game.phase == "play" and scene.game.rival == 1 and scene.game.rng.state == rng_before and scene.game.shop_offer_sequence == serial and CampaignTests.persistent_parts(scene.game) == persistent, "Selección: jugar sin tienda no genera ofertas ni toca el azar")
	# Primer encuentro de un nivel: la tienda en gris.
	scene.start_new_run(921)
	check.call(scene.game.phase == "level_intro" and not scene.game.shop_available() and scene.ui.find_child("OpenShop", true, false).disabled and not scene.game.open_shop(), "Selección: tienda cerrada en el primer encuentro del nivel")
	scene.ui.find_child("PlayNext", true, false).pressed.emit()
	check.call(scene.game.phase == "play" and scene.game.rival == 0, "Selección: Jugar arranca el primer encuentro")

## La tienda se puede abrir varias veces entre dos encuentros sin volver a sortear nada.
static func _shop_reentry(check: Callable) -> void:
	var game = reward_game()
	game.cash = 50
	past_reward(game)
	check.call(game.open_shop() and game.phase == "shop", "Tienda: se abre desde la selección")
	check.call(game.refresh_shop("coins"), "Tienda: renovar una sección")
	var stock: Dictionary = game.shop_state.duplicate(true)
	var rng_after: int = game.rng.state
	var prices: Dictionary = game.reroll_prices.duplicate()
	var cash: int = game.cash
	check.call(game.exit_shop() and game.phase == "lobby" and game.rival == 0, "Tienda: salir vuelve a la selección sin avanzar")
	check.call(game.open_shop() and game.shop_state == stock and game.rng.state == rng_after and game.reroll_prices == prices and game.cash == cash, "Tienda: volver a entrar conserva stock, precios de renovación y azar")
	game.exit_shop()
	check.call(game.play_next() and game.phase == "play" and game.rival == 1 and game.shop_state.is_empty(), "Tienda: el stock se descarta al jugar el siguiente encuentro")
	var direct = reward_game()
	check.call(direct.open_shop() and direct.leave_shop() and direct.phase == "play" and direct.rival == 1, "Tienda: el camino directo (abrir desde el cobro y salir al encuentro) sigue andando")

static func _flow_rules(check: Callable) -> void:
	var repair = reward_game()
	repair.dice[0].shell = "ruby"
	repair.dice[0].shell_broken = true
	repair.phase = "repair"
	repair.repair_resolution = {"status": "pending", "available_ids": [0], "next_phase": "reward"}
	var before: Dictionary = repair.snapshot()
	check.call(not repair.skip_shop() and not past_reward(repair) and repair.snapshot() == before, "Flujo: la reparación pendiente no se saltea")
	check.call(repair.resolve_repairs([]) and repair.phase == "reward" and past_reward(repair) and repair.phase == "lobby" and repair.dice[0].shell_broken, "Flujo: reparación → cobro → selección")
	var campaign = Game.new(921)
	campaign.begin_campaign(921)
	Profile.apply(campaign)
	campaign.debug_mode = true
	campaign.cup.stickers = {"trio": 2, "full": 1}
	var intros := 0
	var lobbies := 0
	var shops := 0
	var wins := 0
	for encounter in range(22):
		if campaign.phase == "level_intro":
			intros += 1
			check.call(not campaign.shop_available(), "Flujo: sin tienda antes del primer encuentro del nivel %d" % (campaign.level_index + 1))
			campaign.play_next()
		campaign.roll()
		if not campaign.score_hand() or not campaign.close_encounter(): break
		wins += 1
		if campaign.phase == "repair": campaign.resolve_repairs([])
		if campaign.phase == "reward": past_reward(campaign)
		# Tras cada jefe se entra sí o sí a la tienda (25/11); al salir queda la selección.
		if campaign.phase == "shop":
			shops += 1
			campaign.exit_shop()
		if campaign.phase == "lobby":
			lobbies += 1
			campaign.play_next()
	check.call(wins == 22 and intros == 1 and lobbies == 21 and shops == 7 and campaign.phase == "won" and campaign.completed_encounters.size() == 22, "Flujo: 22 encuentros, una entrada de nivel (las demás pasan por la tienda del jefe), 21 selecciones con tienda y 7 tiendas obligatorias tras los jefes (guardián incluido), y victoria final")
	var boss = Game.new(922)
	boss.begin_campaign(922)
	Profile.apply(boss)
	boss.debug_mode = true
	boss.play_next()
	for i in range(3):
		boss.roll()
		boss.score_hand()
		boss.close_encounter()
		if boss.phase == "repair": boss.resolve_repairs([])
		if i < 2:
			past_reward(boss)
			boss.play_next()
	check.call(boss.phase == "reward" and boss.rival == 2 and past_reward(boss) and boss.phase == "shop" and not boss.shop_state.is_empty(), "Flujo: después del jefe, Continuar entra sí o sí a la tienda")
	check.call(boss.exit_shop() and boss.phase == "lobby" and boss.lobby_next_index() == -1 and boss.shop_available() and EncounterLobby.next_encounter(boss).line.begins_with("Nivel 2 · Rival 1/3"), "Flujo: al salir de esa tienda, la selección anuncia el primer rival del nivel siguiente")
	check.call(boss.play_next() and boss.level_index == 1 and boss.rival == 0 and boss.phase == "play", "Flujo: desde ahí se juega el primer encuentro del nivel siguiente")

## PS2: menú sobre el paño izquierdo, sin mano, con elección de modo, tutorial y Colecciones en el paño del medio.
static func _menu(scene, check: Callable) -> void:
	scene.open_menu_panel("")
	scene.game.return_to_menu()
	scene.session_started = false
	scene.render()
	var menu = scene.ui.find_child("MainMenu", true, false)
	check.call(menu != null and not UI.text_in(menu, "DIOS NO JUEGA") and not menu is Panel, "Menú: sin recuadro ni título")
	var names := ["NewRun", "Collections", "Options", "Quit"]
	var inside := true
	for node_name in names:
		var item = menu.find_child(node_name, true, false)
		inside = inside and item != null and StartMenu.PANO1.encloses(Rect2(item.position, item.size))
	check.call(inside and UI.find_button(scene.ui, "Salir") != null and UI.find_button(scene.ui, "Colecciones") != null, "Menú: Nueva partida, Colecciones, Opciones y Salir sobre el paño izquierdo")
	check.call(scene.background.menu_mode and scene.ui.find_child("MenuHand", true, false) == null and scene.ui.find_child("BarProp_flag", true, false) == null and scene.ui.find_child("MenuMate", true, false) != null and scene.ui.find_child("MenuMateCup", true, false) != null, "Menú: sin mano ni bandera/sifones; el mate responde")
	check.call(scene.background.copa_hits.all(func(hit): return not hit.visible), "Menú: las estrellas de la copa no responden")
	UI.find_button(scene.ui, "Colecciones").pressed.emit()
	check.call(scene.menu_panel == "collections" and scene.ui.find_child("CollectionCoins", true, false) != null and scene.ui.find_child("CollectionStickers", true, false) != null, "Colecciones: secciones en el paño del medio")
	var snapshot: Dictionary = scene.game.snapshot()
	scene.ui.find_child("CollectionStickers", true, false).pressed.emit()
	var book = scene.ui.find_child("StickerBook", true, false)
	check.call(book != null and book.collection and book.rows.size() == 6 and book.upgrades_label.text.begins_with("MEJORAS\nCada nivel suma") and book.level_label.text == "TRÍO", "Colecciones: Stickers abre el álbum con todos los stickers encendidos")
	book.free()
	scene.ui.find_child("CollectionCoins", true, false).pressed.emit()
	var shelf = scene.ui.find_child("CoinShelf", true, false)
	var pages: int = shelf.page_count() if shelf != null else 0
	check.call(shelf != null and shelf.find_child("PlankWall", true, false) != null, "Colecciones: detrás de los estantes hay una pared de tablones")
	var seen: Array = []
	for page in range(pages):
		shelf.show_page(page)
		for child in shelf.shelf_layer.get_children():
			if child is Button: seen.append(String(child.name).trim_prefix("Coin_"))
	check.call(shelf != null and pages == ceili(Coins.DATA.size() / 18.0) and seen.size() == Coins.DATA.size() and seen.all(func(id): return Coins.DATA.has(id)), "Colecciones: los estantes muestran todas las monedas, de a páginas")
	shelf.show_page(0)
	check.call(shelf.left_arrow.disabled and not shelf.right_arrow.disabled, "Colecciones: en la primera página solo anda la flecha derecha")
	shelf.right_arrow.pressed.emit()
	check.call(shelf.page == 1 and not shelf.left_arrow.disabled and shelf.page_label.text == "Página 2 / %d" % pages, "Colecciones: la flecha pasa de página")
	shelf.show_page(pages - 1)
	check.call(shelf.right_arrow.disabled, "Colecciones: en la última página la flecha derecha se apaga")
	var last_id: String = Coins.DATA.keys()[-1]
	shelf.select(last_id)
	check.call(shelf.name_label.text == Coins.definition(last_id).name and shelf.description_label.text == Coins.definition(last_id).description, "Colecciones: elegir una moneda muestra su nombre y lo que hace")
	shelf.free()
	check.call(scene.game.snapshot() == snapshot, "Colecciones: mirar no cambia nada")
	scene.ui.find_child("PanelBack", true, false).pressed.emit()
	check.call(scene.menu_panel == "", "Colecciones: Volver cierra el paño")
	UI.find_button(scene.ui, "Nueva partida").pressed.emit()
	check.call(scene.menu_panel == "modes" and UI.find_button(scene.ui, "Campaña") != null and scene.ui.find_child("ModeSoon_0", true, false).disabled, "Menú: Nueva partida elige el modo; los otros en gris")
	# Los botones del paño del medio van centrados entre sus bordes dorados (el derecho sigue la perspectiva).
	var centered := true
	for node_name in ["PanelTitle", "ModeCampaign", "ModeSoon_0", "ModeSoon_1", "PanelBack"]:
		var node: Control = scene.ui.find_child(node_name, true, false)
		# Eje: centro del recuadro a media altura (borde izquierdo x 712, derecho x 1055 a la altura y 485).
		if absf(node.get_global_rect().get_center().x - (712.0 + 1040.0 + 85.0 * 0.18) / 2.0) > 1.5: centered = false
	check.call(centered, "Menú: los botones del paño del medio quedan centrados en el recuadro, en una sola columna")
	scene.open_menu_panel("tutorial")
	scene.ui.find_child("TutorialBack", true, false).pressed.emit()
	check.call(scene.menu_panel == "modes" and not scene.pending_tutorial_choice, "Menú: Volver de la pregunta vuelve a los modos")
	UI.find_button(scene.ui, "Campaña").pressed.emit()
	check.call(scene.session_started and scene.game.phase == "level_intro" and not scene.game.tutorial and not scene.pending_tutorial_choice, "Menú: Campaña arranca la partida directo (sin progreso a estrenar)")
	scene.game.return_to_menu()
	scene.session_started = false
	scene.open_menu_panel("")

## PS6: la ayuda de la mano del jefe va debajo de la mano y no tapa la libreta.
static func _boss_help(scene, check: Callable) -> void:
	scene.start_new_run(923)
	scene.game.play_next()
	scene.render()
	check.call(not scene.background.menu_mode and not scene.background.quiet, "Mano: vuelve a verse al empezar la partida")
	var hand: Control = scene.ui.find_child("InspectBoss", true, false)
	scene.hover_description_body.text = hand.tooltip_text if hand.tooltip_text != "" else "Ayuda de prueba"
	scene.hover_description.reset_size()
	scene.place_hover_description(hand)
	var box := Rect2(scene.hover_description.position, scene.hover_description.size)
	check.call(box.position.y >= hand.position.y + hand.size.y and not box.intersects(Rect2(22, 25, 310, 630)) and Rect2(0, 0, 1440, 900).encloses(box), "Mano: la ayuda sale debajo de la mano, sin tapar la libreta")
	scene.place_hover_description(null)
	check.call(scene.hover_description.position == Vector2(30, 400), "Mano: las demás ayudas siguen en su lugar")
	scene.cancel_navigation()
	scene.game.return_to_menu()
	scene.session_started = false
	_table_and_shop(scene, check)

## Ajustes de la mesa y la tienda: Desarmar no tapa los dados, Opciones en la esquina y la ayuda de la tienda arriba.
static func _table_and_shop(scene, check: Callable) -> void:
	scene.start_new_run(924)
	scene.game.play_next()
	scene.game.roll()
	Fixture.set_values(scene.game, [6, 6, 2, 3, 4])
	scene.game.form_group([0, 1])
	scene.render()
	var ungroup: Control = scene.ui.find_child("Ungroup_0", true, false)
	var overlaps := false
	for die in UI.dice_in(scene.ui):
		if die.locked and ungroup != null and ungroup.get_global_rect().intersects(die.get_global_rect()): overlaps = true
	check.call(ungroup != null and not overlaps, "Mesa: Desarmar queda arriba de los dados del grupo, sin taparlos")
	var options: Button = scene.ui.find_child("TableMenu", true, false)
	var top_menu: Array = scene.ui.find_children("*", "Button", true, false).filter(func(b): return b.text == "Menú" and b.position.y < 100)
	check.call(options != null and options.text == "Menú" and UI.find_button(scene.ui, "Ayuda") == null and top_menu.is_empty(), "Mesa: en la esquina de la libreta está el Menú de la partida (y ya no arriba)")
	var pixel := func(control: Control) -> bool:
		var font = control.get_theme_font("font")
		return font is SystemFont and font.antialiasing == TextServer.FONT_ANTIALIASING_NONE
	var note: Control = scene.ui.find_child("PlayerNotebook", true, false)
	var note_label: Label = note.find_children("*", "Label", true, false)[0]
	check.call(pixel.call(options) and pixel.call(scene.ui.find_child("Ungroup_0", true, false)) and not pixel.call(note_label), "Mesa: los textos de la partida van en letra pixel, menos la libreta")
	options.pressed.emit()
	check.call(scene.ui.has_node("GameMenu"), "Mesa: el botón de la esquina abre el menú de la partida")
	scene.close_game_menu()
	scene.game = reward_game()
	past_reward(scene.game)
	scene.render()
	check.call(scene.ui.find_child("TableMenu", true, false) == null and scene.ui.find_child("LobbyOptions", true, false) != null, "Selección: el menú no se repite en la esquina")
	scene.game.open_shop()
	scene.render()
	check.call(not UI.text_in(scene.ui, scene.game.message) and scene.ui.find_child("ShopError", true, false) == null, "Tienda: no queda texto de estado abajo")
	scene.inspect_thermos()
	check.call(not scene.detail.visible, "Tienda: tocar el termo no abre ningún panel")
	# Sin cartel de capacidad: contador de monedas equipadas en su bandeja, y «Total» en las monedas que suman algo.
	var counter: Label = scene.ui.find_child("CoinCounter", true, false)
	check.call(counter != null and counter.text == "%d/%d" % [scene.game.passives.size(), scene.game.coin_inventory.shared_capacity] and not UI.text_in(scene.ui, "CAPACIDAD"), "Tienda: un contador 0/5 de monedas reemplaza a CAPACIDAD")
	scene.game.cash = 23
	check.call(scene.coin_total_for("interest", {}, false) == "\nTotal: +4 puntos de mano (con $23)" and scene.coin_total_for("accumulated", {}, false) == "\nTotal: +0 puntos acumulados" and scene.coin_total_for("full", {}, false) == "", "Tienda: Interés y las que acumulan muestran su total; las fijas no")
	check.call(not scene.ui.find_child("Shop_numbers", true, false) and not scene.game.shop_state.numbers.configured, "Tienda: los números ya no se venden (son recompensa de los rivales)")
	# Opción B (25/11): cinco secciones; abajo las monedas (pasivas sueltas y el paquete) y la de un uso, aparte.
	var single: Control = scene.ui.find_child("Shop_single_use", true, false)
	var coins_zone: Control = scene.ui.find_child("Shop_coins", true, false)
	var once_offer: Dictionary = scene.game.shop_state.single_use.slots[0]
	check.call(single != null and single.find_children("Offer_*", "", false, false).size() == 1 and once_offer.get("kind") == "coin" and Coins.definition(once_offer.effect.coin_id).type == "consumable", "Tienda: la moneda de un uso tiene su sección, con una sola oferta")
	check.call(coins_zone != null and coins_zone.position.y > single.position.y - 1 and scene.ui.find_child("Shop_stickers", true, false).position.y < coins_zone.position.y and scene.game.shop_state.coins.slots.slice(0, 3).all(func(o): return o.is_empty() or Coins.definition(o.effect.coin_id).type == "passive"), "Tienda: arriba componentes, números y stickers; abajo monedas pasivas y la de un uso")
	var old_game: Dictionary = scene.game.snapshot()
	old_game.reroll_prices.erase("single_use")
	old_game.shop_state.erase("single_use")
	check.call(preload("res://scripts/save_migrations.gd").single_use_v11(old_game) == "" and old_game.reroll_prices.single_use == 1 and old_game.shop_state.single_use == {"slots": [{}], "configured": false}, "Guardado v11: una partida de antes recibe la sección de un uso vacía, sin re-sortear")
	var card: Control = scene.ui.find_child("Offer_0", true, false)
	var hover: Control = card.find_child("ObjectHover", true, false) if card != null else null
	if hover == null:
		check.call(false, "Tienda: hay un objeto a la venta para revisar la ayuda")
	else:
		scene.hover_description_body.text = hover.tooltip_text
		scene.hover_description.reset_size()
		scene.place_hover_description(hover)
		var box := Rect2(scene.hover_description.position, scene.hover_description.size)
		var card_rect := card.get_global_rect()
		var fits_above: bool = card_rect.position.y - box.size.y - 6.0 >= 12.0
		check.call((box.end.y <= card_rect.position.y) if fits_above else (box.position.y >= card_rect.end.y), "Tienda: la ayuda del objeto sale arriba de su tarjeta (abajo solo si no entra)")
		check.call(Rect2(0, 0, 1440, 900).encloses(box) and not box.intersects(card_rect), "Tienda: la ayuda entra en pantalla y no tapa el objeto")
	scene.cancel_navigation()
	scene.game.return_to_menu()
	scene.session_started = false
