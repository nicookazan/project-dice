extends RefCounted
## Selección de encuentro y cobro (D20, pasos PS4 y PS5). Dibuja sobre la mesa, sin carteles: el paño izquierdo tiene
## el objetivo y «Jugar contra…», el del medio la tienda, y donde va la libreta quedan Opciones y Abandonar partida.
## Las reglas viven en Game (`lobby_next_index`, `shop_available`, `play_next`, `open_shop`, `continue_after_reward`).
const Campaign = preload("res://scripts/campaign.gd")
const StartMenu = preload("res://scripts/start_menu.gd")

const PLAY_RECT := Rect2(380, 430, 292, 58)
const SKIP_RECT := Rect2(434, 572, 176, 42)
## Centrados en el eje del paño del medio (`StartMenu.pano2_axis`, x 884: el borde derecho sigue la perspectiva).
const SHOP_RECT := Rect2(748, 430, 272, 58)
const OPTIONS_RECT := Rect2(60, 300, 236, 50)
const ABANDON_RECT := Rect2(60, 366, 236, 50)
const CONTINUE_RECT := Rect2(768, 510, 232, 56)
const SHOP_CLOSED_TEXT := "Se abre después de ganar\nel primer encuentro del nivel."

## Lo que muestra la selección del próximo encuentro: objetivo, a quién se enfrenta y la línea de nivel/rival/jefe.
static func next_encounter(game) -> Dictionary:
	var index: int = game.lobby_next_index()
	if index < 0:
		# Solo con Game.SHOP_AFTER_BOSS: el próximo es el primero del nivel siguiente y su jefe todavía no se sorteó.
		var level: int = game.level_index + 1
		var count := 4 if level == game.campaign.size() - 1 else 3
		return {"target": int(game.campaign[level].targets[0]), "who": "el siguiente rival",
			"line": "Nivel %d · Rival 1/%d · Jefe: se anuncia al entrar" % [level + 1, count]}
	var count: int = game.level_encounters.size()
	var prefix := "Tutorial" if game.tutorial else ("Nivel de prueba" if game.campaign.is_empty() else "Nivel %d" % (game.level_index + 1))
	if game.is_seed(index):
		return {"target": int(game.level_encounters[index].target), "who": "La Semilla", "line": "%s · Encuentro final · %s" % [prefix, Campaign.SEED_NAME]}
	if game.is_boss(index):
		return {"target": int(game.level_encounters[index].target), "who": "el jefe", "line": "%s · Jefe %d/%d · %s" % [prefix, index + 1, count, _boss_name(game)]}
	return {"target": int(game.level_encounters[index].target), "who": "el siguiente rival", "line": ("%s · Rival %d/%d" % [prefix, index + 1, count]) + ("" if game.campaign.is_empty() and not game.tutorial else " · Jefe: %s" % _boss_name(game))}

## Nombre del jefe del nivel (no el de La Semilla, aunque el encuentro actual sea ella).
static func _boss_name(game) -> String:
	if game.tutorial or game.campaign.is_empty(): return game.boss_name()
	return Campaign.candidate(game.campaign[game.level_index], game.selected_bosses[str(game.level_index)]).name

static func shop_caption(game) -> String:
	if not game.shop_available(): return SHOP_CLOSED_TEXT
	if game.is_seed_shop_visit() and not game.shop_state.is_empty(): return "La mano con el maletín te espera.\nPodés volver las veces que quieras."
	if game.is_seed_shop_visit(): return "La mano con el maletín regala\nuno de cada sección."
	if not game.shop_state.is_empty(): return "Podés volver a entrar\nlas veces que quieras."
	return "Comprá mejoras para tus dados."

static func build(host) -> void:
	var game = host.game
	var lobby := Control.new()
	lobby.name = "EncounterLobby"
	lobby.size = Vector2(1440, 900)
	lobby.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StartMenu.pixelate(host, lobby)
	host.ui.add_child(lobby)
	var next := next_encounter(game)
	var x := PLAY_RECT.position.x
	var w := PLAY_RECT.size.x
	_centered(host, lobby, "OBJETIVO", Rect2(x, 342, w, 24), 17, host.cream)
	_centered(host, lobby, "%d PUNTOS" % next.target, Rect2(x, 364, w, 46), 36, host.gold).name = "LobbyTarget"
	var play: Button = host.button(lobby, "Jugar contra %s" % next.who, PLAY_RECT, func(): host.act(game.play_next), not host.tutorial_allows("play_next"), true)
	play.name = "PlayNext"
	play.add_theme_font_size_override("font_size", 15)
	_centered(host, lobby, next.line, Rect2(x - 16, 498, w + 32, 44), 15, host.cream).name = "LobbyInfo"
	var skip: Button = host.button(lobby, "Saltear", SKIP_RECT, func(): pass, true)
	skip.name = "Skip"
	skip.tooltip_text = "Próximamente."
	var shop: Button = host.button(lobby, "Ir a la tienda", SHOP_RECT, func(): host.act(game.open_shop), not game.shop_available() or not host.tutorial_allows("open_shop"), game.shop_available())
	shop.name = "OpenShop"
	if not game.shop_available(): shop.tooltip_text = "La tienda se abre después de ganar el primer encuentro del nivel."
	_centered(host, lobby, shop_caption(game), StartMenu.pano2_row(500, SHOP_RECT.size.x + 40, 50), 15, host.cream).name = "ShopCaption"
	_centered(host, lobby, "Tenés %s" % host.money_text(game.cash), StartMenu.pano2_row(380, SHOP_RECT.size.x, 30), 20, host.gold).name = "LobbyCash"
	host.button(lobby, "Opciones", OPTIONS_RECT, host.show_options).name = "LobbyOptions"
	host.button(lobby, "Abandonar partida", ABANDON_RECT, func(): host.request_navigation("menu")).name = "LobbyAbandon"
	if not play.disabled: play.grab_focus()

## Al ganar: solo el total cobrado sobre la mesa y «Continuar», que lleva a la selección de encuentro.
static func build_payout(host) -> void:
	var game = host.game
	var total: int = int(game.payout.get("total", 0))
	var area := StartMenu.PANO2
	var payout := Control.new()
	payout.name = "Payout"
	payout.size = Vector2(1440, 900)
	payout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StartMenu.pixelate(host, payout)
	host.ui.add_child(payout)
	# El número se dibuja a la mitad y se escala ×2 sin suavizado: así se ven los píxeles de la letra, como en la tienda.
	var big := _centered(host, payout, "+$%d" % total, Rect2(StartMenu.pano2_axis() - area.size.x / 2.0, 404, area.size.x / 2.0, 44), 36, host.gold)
	big.name = "PayoutTotal"
	big.scale = Vector2(2, 2)
	big.add_theme_color_override("font_outline_color", Color("2a0a10"))
	big.add_theme_constant_override("outline_size", 4)
	var go: Button = host.button(payout, "Continuar", CONTINUE_RECT, func(): host.act(game.continue_after_reward), not host.tutorial_allows("continue"), true)
	go.name = "ContinueReward"
	go.grab_focus()
	# Entrada corta del número: sube y aparece. Sin movimiento (o velocidad cero), queda quieto desde el principio.
	if host.preferences.speed != 0 and not host.preferences.reduced_motion:
		big.modulate.a = 0.0
		big.position.y += 18
		var tween := big.create_tween().set_parallel()
		tween.tween_property(big, "modulate:a", 1.0, 0.3 / maxi(host.preferences.speed, 1))
		tween.tween_property(big, "position:y", big.position.y - 18, 0.35 / maxi(host.preferences.speed, 1)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _centered(host, parent: Node, text: String, rect: Rect2, size: int, color: Color) -> Label:
	var node: Label = host.label(parent, text, rect.position, size, color, rect.size.x)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node
