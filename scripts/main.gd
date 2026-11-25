extends Control
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Die = preload("res://scripts/die.gd")
const Zone = preload("res://scripts/drop_zone.gd")
const FeltLayout = preload("res://scripts/felt_layout.gd")
const TableDragOverlay = preload("res://scripts/table_drag_overlay.gd")
const CupEntry = preload("res://scripts/cup_entry.gd")
const DieCard = preload("res://scripts/die_card.gd")
const Confetti = preload("res://scripts/confetti.gd")
const PlaysPanel = preload("res://scripts/plays_panel.gd")
const StickerTip = preload("res://scripts/sticker_tip.gd")
const ShopThermos = preload("res://scripts/shop_thermos.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const CupThrow = preload("res://scripts/cup_throw.gd")
const StickerFlight = preload("res://scripts/sticker_flight.gd")
const OfferRing = preload("res://scripts/offer_ring.gd")
const StickerBook = preload("res://scripts/sticker_book.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const ShopArt = preload("res://scripts/shop_art.gd")
const ShopFixtures = preload("res://scripts/shop_fixtures.gd")
const ThiefPigeon = preload("res://scripts/thief_pigeon.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const ItemTooltip = preload("res://scripts/item_tooltip.gd")
const CoinPackPanel = preload("res://scripts/coin_pack_panel.gd")
const HoverButton = preload("res://scripts/hover_button.gd")
const HoverPanel = preload("res://scripts/hover_panel.gd")
const StartMenu = preload("res://scripts/start_menu.gd")
const EncounterLobby = preload("res://scripts/encounter_lobby.gd")
const Materials = preload("res://scripts/materials.gd")
const Elements = preload("res://scripts/elements.gd")
const Gems = preload("res://scripts/gems.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Coins = preload("res://scripts/coins.gd")
const CoinEffects = preload("res://scripts/coin_effects.gd")
const Shop = preload("res://scripts/shop.gd")
const Purchases = preload("res://scripts/purchases.gd")
const ProfileStore = preload("res://scripts/profile_store.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Achievements = preload("res://scripts/achievements.gd")
const TutorialScript = preload("res://scripts/tutorial_script.gd")
const TutorialOverlay = preload("res://scripts/tutorial_overlay.gd")
const ValidationProfile = preload("res://scripts/validation_profile.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const BossInfo = preload("res://scripts/boss_info.gd")
const Preferences = preload("res://scripts/presentation_preferences.gd")
const Presentation = preload("res://scripts/presentation_state.gd")
const PresentationAudio = preload("res://scripts/presentation_audio.gd")
const SeedDisplay = preload("res://scripts/seed_display.gd")
const Campaign = preload("res://scripts/campaign.gd")
## Final de La Semilla (docs/LA-SEMILLA.md). `finale_shown`: etapa ya presentada en esta sesión; `finale_anim`: animación
## en curso («death», «collapse» o «travel»), que bloquea la mesa hasta terminar.
var finale_shown := ""
var finale_anim := ""
var finale_seen_session := false
var seed_display: Control
var showing_credits := false
## Después de los créditos: las recompensas por ganar (todavía sin definir).
var showing_rewards := false
## Se sube con cada pantalla de créditos para que un temporizador viejo no avance la nueva.
var credits_token := 0
var preferences_enabled := true
var preference_store = Preferences.new()
var preferences: Dictionary = Preferences.DEFAULTS.duplicate()
var presentation = Presentation.new()
var audio: Node
var settings_panel: Control
var dice_gallery: Control
var feedback_text := ""
var feedback_remaining := 0.0
var feedback_label: Label
var validation_profile := "--validation-profile" in OS.get_cmdline_user_args()
var campaign_mode := not validation_profile and "--short-run" not in OS.get_cmdline_user_args()
var background: Control
## Partidas guardadas (metaprogreso, no jugadas). Las pruebas apagan `profiles_enabled` para no escribir en el disco real.
var profiles_enabled := true
var profile_store = ProfileStore.new()
var run_store = SaveStore.new("user://saves/ultima-tienda-v1.json")
var profile_slot := 0
var profile_message := ""
var run_recorded := false
var session_started := false
## Tutorial: pasos cuyos carteles ya se cerraron en esta jugada (solo de pantalla).
var tutorial_seen: Array = []
var tutorial_current: Dictionary = {}
var pending_tutorial_choice := false
## Ranura del progreso recién creado que todavía no vio la pregunta del tutorial (D20: solo se pregunta la primera vez);
## 0 si no hay ninguno.
var tutorial_offer_slot := 0
## Qué muestra el paño del medio en el menú inicial (D20): "" nada, "modes" elegir modo, "tutorial" la pregunta del
## tutorial, "collections" Colecciones. "tutorial" va siempre junto con `pending_tutorial_choice`.
var menu_panel := ""
var game = Game.new()
var selected: Array = []
## Ranura de la moneda "Voltear dado" mientras se elige el dado; solo de pantalla, nunca se guarda (-1 = sin elegir).
var flip_slot := -1
var repair_selection: Array = []
var shop_section := "coins"
var purchase_error := ""
var pack_panel_open := true
## Moneda del paquete que se está por reemplazar ("" = ninguna). Solo de pantalla, nunca se guarda.
var coin_pack_replacing := ""
var sticker_animation: Control
var ui: Control
var cup_zone: Zone
var coin_sale_overlay
var coin_sale_caption: Label
var hover_description: PanelContainer
var die_card: DieCard
var plays_panel: PlaysPanel
var sticker_tip: StickerTip
var sticker_book: Control
var hover_description_body: Label
var detail: AcceptDialog
var detail_body: RichTextLabel
var detail_text := ""
var confirmation: ConfirmationDialog
var pending_navigation := ""
var windowed_mode := DisplayServer.WINDOW_MODE_WINDOWED
var ink := Color("423d38")
var cream := Color("eee2c7")
var gold := Color("edbb67")
var throw_elapsed := 0.0
var throw_duration := 0.85
var throw_frame_seconds := 0.055
var cup_throw: Control
## Dados que viajan juntos mientras se arrastra una selección (la pone el dado arrastrado; ver Die.drag_group).
var dragged_group: Array = []
var throwing := false
var flying_dice: Array = []
var table_dice: Dictionary = {}
## Paloma ladrona (jefe 1C): dado que se muestra en la mesa hasta que la paloma se lo lleva. `thief_next` lo deja `act`
## para el próximo render; `thief_pending` es el que está en pantalla; `thief_node` es la paloma en vuelo.
var thief_next := -1
var thief_pending := -1
var thief_node: Control
var throw_blocker: Control
## Tema con la letra pixel para toda la interfaz de la partida (menos la libreta).
var pixel_theme: Theme

func _ready() -> void:
	if preferences_enabled:
		preferences = preference_store.load_values()
		preferences["drag_groups"] = false # Siempre arranca desactivada; se activa desde Opciones.
	audio = PresentationAudio.new()
	add_child(audio)
	var theme_value := Theme.new()
	theme_value.default_font_size = 18
	var display_font := SystemFont.new()
	display_font.font_names = PackedStringArray(["Bahnschrift", "Consolas", "Menlo", "Monaco"])
	display_font.font_weight = 600
	theme_value.default_font = display_font
	theme_value.set_stylebox("panel", "TooltipPanel", ItemTooltip.skin())
	theme_value.set_font("font", "TooltipLabel", ItemTooltip.pixel_font())
	theme_value.set_font_size("font_size", "TooltipLabel", 18)
	theme_value.set_color("font_color", "TooltipLabel", cream)
	# Pixel-v3 look for every Godot dialog and its buttons (fichas, confirmaciones, opciones).
	for state in ["normal", "hover", "pressed", "disabled"]: theme_value.set_stylebox(state, "Button", UiSkin.button(state))
	theme_value.set_stylebox("focus", "Button", box(Color.TRANSPARENT, Color.WHITE, 3))
	theme_value.set_color("font_color", "Button", cream)
	theme_value.set_color("font_hover_color", "Button", Color("fff0c7"))
	theme_value.set_color("font_disabled_color", "Button", Color("85867b"))
	theme = theme_value
	# Todo el texto de la partida va en letra pixel (D20); la libreta conserva la letra de siempre (se retoca después).
	pixel_theme = theme_value.duplicate()
	pixel_theme.default_font = ItemTooltip.pixel_font()
	background = Backdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	background.copa_stars_complete.connect(_celebrate_copa)
	background.finale_finished.connect(_on_finale_finished)
	detail = AcceptDialog.new()
	detail.theme = pixel_theme
	detail.exclusive = true
	detail.title = "Libreta · detalle de cálculo"
	detail.min_size = Vector2i(520, 260)
	add_child(detail)
	skin_dialog(detail)
	detail_body = RichTextLabel.new()
	detail_body.name = "DetailText"
	detail_body.selection_enabled = true
	detail_body.bbcode_enabled = false
	detail_body.focus_mode = Control.FOCUS_ALL
	detail.add_child(detail_body)
	confirmation = ConfirmationDialog.new()
	confirmation.theme = pixel_theme
	confirmation.title = "Abandonar partida"
	confirmation.exclusive = true
	confirmation.ok_button_text = "Abandonar"
	confirmation.cancel_button_text = "Seguir jugando"
	skin_dialog(confirmation)
	confirmation.confirmed.connect(confirm_navigation)
	confirmation.canceled.connect(cancel_navigation)
	confirmation.get_cancel_button().pressed.connect(cancel_navigation)
	add_child(confirmation)
	get_tree().auto_accept_quit = false
	game.phase = "menu"
	render()
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results")
		get_viewport().get_texture().get_image().save_png("res://test-results/mesa.png")
		get_tree().quit()

func skin_dialog(window: Window) -> void:
	# Pixel-v3 card for Godot's embedded dialogs. The decoration is left empty and the framed panel carries the look;
	# the title floats above it in gold with a dark outline so it reads over any background.
	window.add_theme_stylebox_override("embedded_border", StyleBoxEmpty.new())
	window.add_theme_stylebox_override("embedded_unfocused_border", StyleBoxEmpty.new())
	window.add_theme_stylebox_override("panel", UiSkin.panel(Vector4(20, 20, 20, 20)))
	window.add_theme_color_override("title_color", gold)
	window.add_theme_color_override("title_outline_modulate", Color("0d1728"))
	window.add_theme_constant_override("title_height", 40)
	window.add_theme_constant_override("title_outline_size", 10)
	window.add_theme_font_size_override("title_font_size", 22)
	window.add_theme_font_override("title_font", ItemTooltip.pixel_font())

func present_detail(title: String, text: String, compact := false) -> void:
	detail.add_theme_stylebox_override("panel", UiSkin.panel(Vector4(20, 20, 20, 20)))
	if is_instance_valid(settings_panel): settings_panel.hide()
	if is_instance_valid(dice_gallery): dice_gallery.hide()
	if is_instance_valid(profiles_panel): profiles_panel.hide()
	detail_body.show()
	detail.title = title
	detail_text = text
	detail.dialog_text = "" # RichTextLabel owns the text; the built-in label must not enlarge the dialog.
	detail.get_label().hide()
	detail_body.text = text
	detail_body.custom_minimum_size = Vector2(500, 180) if compact else Vector2(760, 460)
	detail_body.scroll_to_line(0)
	detail.popup_centered(Vector2i(540, 270) if compact else Vector2i(820, 560))

## Voltear dado: primer toque en la moneda elige el modo, segundo toque lo cancela; la moneda se gasta al elegir el dado.
func start_flip(slot: int) -> void:
	flip_slot = -1 if flip_slot == slot else slot
	if flip_slot >= 0: game.message = "Voltear dado: elegí un dado suelto ya tirado. Tocá la moneda de nuevo para cancelar."
	render()

func toggle_die(index: int) -> void:
	if throwing: return
	if flip_slot >= 0:
		var slot := flip_slot
		flip_slot = -1
		act(func(): game.use_consumable(slot, index))
		return
	if preferences.drag_groups or not tutorial_allows("select"): return
	if game.phase != "play" or detail.visible or game.rolls_made == 0 or game.is_grouped(index): return
	if index in selected: selected.erase(index)
	else: selected.append(index)
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if sticker_animation_active():
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]: sticker_animation.finish()
		get_viewport().set_input_as_handled()
		return
	if throwing: return
	if not event is InputEventKey or not event.pressed or event.echo or detail.visible or confirmation.visible or is_instance_valid(sticker_book): return
	if tutorial_notes_open(): return
	if event.keycode == KEY_F1:
		show_help()
	elif event.keycode == KEY_M and game.phase != "menu":
		show_route()
	elif game.phase == "purchase_target" and event.keycode == KEY_ESCAPE:
		act(game.cancel_purchase)
	elif game.phase == "play":
		if event.keycode >= KEY_1 and event.keycode <= KEY_5: toggle_die(int(event.keycode - KEY_1))
		elif event.keycode == KEY_SPACE:
			if tutorial_allows("roll"): act(game.roll)
		elif event.keycode == KEY_G and selection_preview().valid:
			if tutorial_allows("group"): act(func(): game.form_group(selected))
		elif event.keycode == KEY_C: move_selected("cup")
		elif event.keycode == KEY_V: move_selected("reserve")
		elif event.keycode == KEY_I and selected.size() == 1: inspect_die(selected[0])
		elif event.keycode == KEY_ESCAPE:
			selected.clear()
			render()
		else: return
	else: return
	get_viewport().set_input_as_handled()

func selection_preview() -> Dictionary:
	for id in selected:
		if not id is int or id < 0 or id >= game.dice.size() or game.is_grouped(id) or game.dice[id].zone != "reserve": return {"valid": false, "text": "Selección: reservá los dados antes de agrupar."}
	var resolved := Rules.resolve_wildcards(game.dice, selected, game.active_rules())
	var category: String = resolved.category
	if BossRules.forbidden(game.boss_context(), category): return {"valid": false, "text": "Selección: el jefe prohíbe %s%s." % [category.to_lower(), "; podés armar trío + par" if category == "Generala" else ""]}
	if category.is_empty(): return {"valid": false, "text": "Selección: %d dado(s) · sin combinación válida" % selected.size()}
	var groups: Array = game.groups.duplicate(true)
	var candidate := {"ids": selected.duplicate(), "category": category}
	if not resolved.assigned.is_empty(): candidate["assigned"] = resolved.assigned
	groups.append(candidate)
	var score := Rules.score(game.dice, groups, game.passives, game.impulses, game.rolls_made == 1, game.global_points, game.cup.stickers, game.sticker_catalog, game.boss_context(), game.coin_context())
	if score.valid:
		var row: Dictionary = score.rows[game.groups.size()]
		return {"valid": true, "text": "Selección: %s · %s · G para agrupar" % [category, "puntos ocultos" if BossRules.forecast_hidden(game.boss_context()) else number(row.total) + " puntos"], "row": row}
	return {"valid": false, "text": "Selección: no se puede calcular este grupo."}

func inspect_die(id: int) -> void:
	if id < 0 or id >= game.dice.size(): return
	var die: Dictionary = game.dice[id]
	var lines: Array[String] = ["Número visible: %s · posición de cara: %s" % [str(die.value) if die.value > 0 else "sin tirar", str(die.face_index + 1) if die.face_index >= 0 else "—"], "El número de la cara determina combinaciones y paridad; sus puntos se calculan aparte.", "", "Seis posiciones de cara:"]
	if BossRules.suspended(game.boss_context(), "shell", die.shell): lines.insert(1, "SUSPENDIDA POR JEFE: sin poder ni sorteos de rotura durante este encuentro.")
	if BossRules.suspended(game.boss_context(), "material", die.material): lines.insert(1, "MATERIAL SUSPENDIDO: sin poder ni acumulación nueva. Se conservan reinicios normales.")
	if die.face_index >= 0 and die.value != die.faces[die.face_index]:
		lines.insert(1, "Resultado anterior al cambio de cara. La cara comprada se usa en futuras tiradas; la mano anotada se conserva.")
	for index in range(6): lines.append("Cara %d: %d" % [index + 1, die.faces[index]])
	lines.append("Probabilidades por número en cada tirada:")
	for n in range(1, 7): lines.append("%d: %d/6 (%.2f%%)" % [n, die.faces.count(n), die.faces.count(n) * 100.0 / 6.0])
	lines.append("\nMejoras globales por número: " + point_upgrades(game.global_points))
	if die.value > 0: lines.append("Puntos numéricos del resultado: %s (antes de material, elemento, monedas y gema)" % number(die.value + game.global_points.get(str(die.value), 0)))
	var material := Materials.inspect(die)
	lines.append("\nMaterial: " + material.name)
	if Materials.is_metal(die.material):
		var material_text := shop_offer_text({"kind": "material", "effect": {"id": die.material}})
		lines.append(material_text[1])
	var shell := Gems.definition(die.shell)
	lines.append("Material de los puntos: " + shell.get("name", "Negro base") + (" · gema RESQUEBRAJADA (R), poder suspendido" if die.shell_broken else " · intacta" if not shell.is_empty() else ""))
	if not shell.is_empty(): lines.append("%s Riesgo: %d%% al puntuar en combinación; reparación $%d." % [shell.description, int(shell.break_risk * 100), shell.repair_cost])
	var element := Elements.definition(die.element)
	lines.append("Elemento: " + element.get("name", "Sin elemento"))
	if not element.is_empty(): lines.append(element.condition + " Permanece durante la partida; no se gasta.")
	lines.append("\nAcumulación de encuentro: hierro +%s puntos; cobre +%s al multiplicador." % [number(Materials.steel_points(die)), number(Materials.copper_multiplier(die))])
	lines.append("Acumulación de mano: tierra +%s puntos; viento +%s al multiplicador; madera +%s puntos." % [number(Elements.earth_points(die)), number(Elements.wind_multiplier(die)), number(Materials.wood_points(die))])
	lines.append("Hierro/cobre (y sus variantes) duran el encuentro; tierra/viento se reinician cada mano.")
	present_detail("Dado %d · ficha" % [id + 1], "\n".join(lines))

func point_upgrades(points: Dictionary) -> String:
	var entries: Array[String] = []
	for n in range(1, 7):
		if points.has(str(n)): entries.append("%d → +%d" % [n, points[str(n)]])
	return "; ".join(entries) if not entries.is_empty() else "ninguna"

## Clic en el vaso: tira, igual que TIRAR, mientras haya tiradas; si no, muestra su información.
func click_cup() -> void:
	if game.phase == "play" and game.rolls_left > 0 and not throwing: act(game.roll)
	else: inspect_cup()

func inspect_cup() -> void:
	present_detail("Vaso de cuero", "Cinco dados fijos; el vaso no modifica su cantidad.\nLos stickers están pegados al termo del mate. Tocá el termo para ver sus niveles y efectos.", true)

## Zonas invisibles sobre cada sticker del termo; el mouse encima abre su ventanita. No tapan el clic ni el soltado
## de dados: pasan los eventos al botón del termo.
func add_sticker_zones(host: Control, origin: Vector2) -> void:
	for id in Stickers.NAMES:
		if game.cup.stickers.get(id, 0) <= 0: continue
		var rect := ShopThermos.badge_hit_rect(id, game.cup.stickers)
		var zone := Control.new()
		zone.name = "StickerZone_" + id
		zone.position = origin + rect.position - host.position
		zone.size = rect.size
		# El clic en un sticker abre su panel y no llega al termo (que sirve el mate); los dados sí se pueden soltar encima.
		zone.mouse_filter = Control.MOUSE_FILTER_STOP
		zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sticker_id: String = id
		zone.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				zone.accept_event()
				if not background.props.busy("thermos"): open_sticker_book(sticker_id))
		zone.set_meta("sticker_id", id)
		zone.set_meta("thermos_origin", origin)
		host.add_child(zone)

## Panel de los stickers del termo, con el elegido en grande (nivel, mejoras y qué hace).
func open_sticker_book(sticker_id: String) -> void:
	if throwing or detail.visible or confirmation.visible or sticker_animation_active() or is_instance_valid(sticker_book): return
	sticker_book = StickerBook.new()
	sticker_book.setup(game.cup.stickers, game.sticker_catalog, sticker_id)
	ui.add_child(sticker_book)
	if is_instance_valid(sticker_tip): sticker_tip.hide()

func inspect_thermos() -> void:
	# En la mesa el termo ceba el mate (los stickers se leen al pasar el mouse); robado explica el robo. En la tienda no
	# abre nada: los stickers se ven en el termo y en Colecciones.
	if game.thermos_stolen(): show_thermos_detail()
	elif not background.shop_mode: background.props.play("thermos")

## Detalle del termo cambiado: explica el cambio y que los stickers no aportan mientras dure el jefe.
func show_thermos_detail() -> void:
	present_detail("Termo cambiado", "Don Cebador te cambió el termo: el tuyo flota junto a su mano y en la mesa quedó el suyo, sin stickers. Tus %d stickers no aportan nada mientras dure el jefe.
Cuando lo venzas, te lo devuelve." % game.cup.stickers.size(), true)

func box(bg: Color, border := Color.TRANSPARENT, width := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.shadow_color = Color(0.02, 0.01, 0.02, 0.55)
	s.shadow_size = 3 if width > 0 else 0
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func panel(parent: Node, rect: Rect2, bg: Color, border := Color.TRANSPARENT) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(bg, border, 2 if border.a > 0 else 0))
	if border == gold and bg in [Color("0d1728"), Color("263c3d")] and not preferences.high_contrast:
		node.add_theme_stylebox_override("panel", UiSkin.panel())
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(node)
	return node

func label(parent: Node, text_value: String, pos: Vector2, font_size := 18, color := Color("f0e6ce"), width := 0.0) -> Label:
	var node := Label.new()
	node.position = pos
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if color == cream or color == gold:
		node.add_theme_color_override("font_shadow_color", Color("140d12"))
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 2)
	if width > 0:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size.x = width
	node.text = text_value
	parent.add_child(node)
	return node

func button(parent: Node, text_value: String, rect: Rect2, action: Callable, disabled := false, accent := false) -> Button:
	var node := HoverButton.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.disabled = disabled
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal", "hover", "pressed", "disabled"]: node.add_theme_stylebox_override(state, UiSkin.button(state, accent))
	node.add_theme_color_override("font_color", cream)
	node.add_theme_color_override("font_disabled_color", Color("85867b"))
	if preferences.high_contrast:
		node.add_theme_stylebox_override("normal", box(Color("080b10"), Color.WHITE, 3))
		node.add_theme_stylebox_override("disabled", box(Color("252525"), Color("b0b0b0"), 2))
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_color_override("font_disabled_color", Color("bdbdbd"))
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, Color.WHITE, 3))
	if is_instance_valid(background) and background.shop_mode: skin_shop_button(node)
	# The font's ascent leaves the label about 1 px above the optical centre: push it down 1 px.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var skin: StyleBox = node.get_theme_stylebox(state)
		if skin != null and not (skin is StyleBoxEmpty):
			skin = skin.duplicate()
			skin.set_content_margin(SIDE_TOP, skin.get_margin(SIDE_TOP) + 2)
			node.add_theme_stylebox_override(state, skin)
	node.pressed.connect(func():
		if not throwing and not sticker_animation_active() and not detail.visible and not confirmation.visible: action.call())
	parent.add_child(node)
	return node

func act(action: Callable) -> void:
	if throwing: return
	var previous_event: int = game.event_sequence
	purchase_error = ""
	action.call()
	selected.clear()
	thief_next = thief_candidate(previous_event)
	render()
	if game.event_sequence > previous_event and not game.events.is_empty():
		var event: Dictionary = game.events.back()
		if event.type in [Game.INITIAL_ROLL, Game.REROLL]: begin_throw(event.payload.rolled_ids)

## Dado que la paloma ladrona se lleva en esta tirada (-1 si no corresponde): primera tirada de la mano contra el jefe 1C, con movimiento.
func thief_candidate(previous_event: int) -> int:
	if game.event_sequence <= previous_event or game.events.is_empty() or game.events.back().type != Game.INITIAL_ROLL: return -1
	if preferences.speed == 0 or preferences.reduced_motion or not game.boss_power_on() or not BossRules.is_power(game.boss_rule, "scared_die"): return -1
	var marked := int(game.boss_state.get("die", -1))
	return marked if marked >= 0 and marked < game.dice.size() and game.dice[marked].zone == "cup" else -1

## La paloma sale de la mano del jefe, agarra el dado que quedó en la mesa y se lo lleva al vaso.
func start_thief() -> void:
	var ghost: Control = table_dice.get(thief_pending)
	if not is_instance_valid(ghost):
		thief_pending = -1
		return
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.disabled = true
	thief_node = ThiefPigeon.new()
	thief_node.die = ghost
	thief_node.start = Vector2(685, 120)
	thief_node.grab = ghost.get_global_rect().get_center()
	thief_node.drop = Backdrop.CUP_RECT.get_center() + Vector2(0, -30)
	thief_node.speed = 1.6 if preferences.speed == 2 else 1.0
	ui.add_child(thief_node)

## Termina la escena de la paloma: el dado ya no está en la mesa.
func end_thief() -> void:
	if is_instance_valid(thief_node): thief_node.queue_free()
	thief_node = null
	var ghost: Control = table_dice.get(thief_pending)
	if is_instance_valid(ghost):
		flying_dice = flying_dice.filter(func(flight): return flight.node != ghost)
		ghost.queue_free()
		table_dice.erase(thief_pending)
	thief_pending = -1

func begin_throw(ids: Array) -> void:
	if preferences.speed == 0 or preferences.reduced_motion: return
	end_cup_animation()
	throwing = true
	throw_elapsed = 0.0
	throw_frame_seconds = CupThrow.FRAME_SECONDS / (1.6 if preferences.speed == 2 else 1.0)
	throw_duration = CupThrow.FRAMES * throw_frame_seconds
	feedback_text = "Tirando…"
	if is_instance_valid(feedback_label): feedback_label.text = feedback_text
	for index in ids:
		if not table_dice.has(index): continue
		var die: Control = table_dice[index]
		flying_dice.append({"node": die, "landing": die.position, "angle": die.rotation_degrees, "order": flying_dice.size()})
		die.z_index = 20
		die.visible = false
	# El vaso se dibuja aparte mientras tira (el quieto es parte del fondo) y por delante de los dados.
	cup_throw = CupThrow.new()
	add_child(cup_throw)
	cup_throw.setup(game.dice, game.boss_context())
	background.cup_hidden = true
	background.props.held["cup"] = true
	background.queue_redraw()
	throw_blocker = Control.new()
	throw_blocker.name = "ThrowInputBlocker"
	throw_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	throw_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	throw_blocker.z_index = 30
	ui.add_child(throw_blocker)
	step_throw(0.0)

func step_throw(delta: float) -> void:
	if not throwing and not is_instance_valid(cup_throw): return
	throw_elapsed += delta
	var f := mini(int(throw_elapsed / throw_frame_seconds), CupThrow.FRAMES - 1)
	if is_instance_valid(cup_throw): cup_throw.set_frame(f)
	if throwing:
		var last_landing := CupThrow.SHAKE + CupThrow.LIFTING
		for flight in flying_dice:
			var die: Control = flight.node
			var landing_center: Vector2 = die.get_parent().position + flight.landing + die.size / 2.0
			var state := CupThrow.die_state(flight.order, f, landing_center)
			die.visible = state.visible
			die.position = state.center - die.get_parent().position - die.size / 2.0
			die.rotation_degrees = flight.angle + state.spin
			last_landing = maxi(last_landing, CupThrow.landed_frame(flight.order))
		# Los dados se pueden usar apenas cae el último; el vaso termina de bajar por su cuenta.
		if f >= last_landing and thief_pending >= 0:
			if thief_node == null: start_thief()
			elif thief_node.done:
				end_thief()
				release_dice()
				feedback_text = "Tirada resuelta · elegí tus grupos"
				if is_instance_valid(feedback_label): feedback_label.text = feedback_text
		elif f >= last_landing:
			release_dice()
			feedback_text = "Tirada resuelta · elegí tus grupos"
			if is_instance_valid(feedback_label): feedback_label.text = feedback_text
	if throw_elapsed >= throw_duration: end_cup_animation()

## Deja los dados en su lugar y de nuevo usables; el vaso puede seguir animándose.
func release_dice() -> void:
	for flight in flying_dice:
		if not is_instance_valid(flight.node): continue
		flight.node.position = flight.landing
		flight.node.rotation_degrees = flight.angle
		flight.node.scale = Vector2.ONE
		flight.node.modulate.a = 1.0
		flight.node.visible = true
		flight.node.z_index = 0
	flying_dice.clear()
	throwing = false
	if is_instance_valid(throw_blocker):
		throw_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		throw_blocker.queue_free()

## El vaso vuelve al fondo y la animación termina.
func end_cup_animation() -> void:
	if is_instance_valid(cup_throw):
		cup_throw.queue_free()
		cup_throw = null
	if is_instance_valid(background):
		background.cup_hidden = false
		background.props.held.erase("cup")
		background.queue_redraw()

## Al redibujar la pantalla: si los dados todavía vuelan se corta todo; si solo falta que el vaso baje, sigue.
func finish_throw() -> void:
	if thief_pending >= 0 or is_instance_valid(thief_node): end_thief()
	if throwing:
		release_dice()
		end_cup_animation()

## Modo de desarrollo: --boss=l3_conde,l5_visitante fuerza esos jefes al entrar a su nivel.
func forced_boss_arguments() -> Array:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--boss="): return Array(argument.trim_prefix("--boss=").split(",")).filter(func(id): return id != "")
	return []

## `seeded_run`: jugada con semilla elegida (reintentar la misma al perder): al terminar no suma nada a la partida guardada.
func start_new_run(seed_value: int = -1, debug_run := false, tutorial_run := false, seeded_run := false) -> void:
	if is_instance_valid(background): background.thermos_configured = false
	presentation.observed.clear()
	feedback_remaining = 0
	selected.clear()
	repair_selection.clear()
	purchase_error = ""
	pack_panel_open = true
	pending_tutorial_choice = false
	menu_panel = ""
	tutorial_seen.clear()
	game.forced_boss_ids = forced_boss_arguments()
	if tutorial_run: game.begin_tutorial(seed_value)
	elif campaign_mode: game.begin_campaign(seed_value)
	else: game.begin_run(seed_value)
	if validation_profile or campaign_mode or tutorial_run: ValidationProfile.apply(game)
	game.debug_mode = debug_run
	game.seeded = seeded_run and not tutorial_run
	game.unlocked_coins = unlocked_coins_of_profile(debug_run)
	finale_shown = ""
	finale_anim = ""
	showing_credits = false
	showing_rewards = false
	session_started = true
	clear_run_save()
	run_recorded = false
	render()

## La jugada no se guarda: esto solo es lo que las pruebas y las capturas comparan.
func checkpoint_data() -> Dictionary:
	return {"game": game.snapshot(), "ui": {"selected": selected.duplicate(), "repair_selection": repair_selection.duplicate(), "shop_section": shop_section, "pack_panel_open": pack_panel_open}}

## Partida guardada en uso: la última usada si existe; si no, la primera con datos; si no hay ninguna, se crea la 1.
## 0 si los perfiles están apagados o el archivo elegido está dañado (la jugada sigue, pero no suma estadísticas).
func active_profile(create := true) -> int:
	if not profiles_enabled: return 0
	var last: int = preferences.get("last_profile", 0)
	var slot := 0
	if ProfileStore.valid_slot(last) and FileAccess.file_exists(profile_store.path_of(last)): slot = last
	else:
		for candidate in range(1, ProfileStore.SLOTS + 1):
			if FileAccess.file_exists(profile_store.path_of(candidate)):
				slot = candidate
				break
	if slot == 0 and create:
		var made: Dictionary = profile_store.create(1)
		profile_message = "" if made.ok else made.message
		slot = 1 if made.ok else 0
	if slot != 0 and slot != last: remember_profile(slot)
	return slot

func remember_profile(slot: int) -> void:
	preferences["last_profile"] = slot
	if preferences_enabled: preference_store.save_values(preferences)

func unlocked_coins_of_profile(debug_run := false) -> Array:
	if debug_run: return []
	profile_slot = active_profile()
	if profile_slot == 0: return []
	var found: Dictionary = profile_store.read(profile_slot)
	if not found.ok:
		profile_message = found.message
		return []
	profile_message = ""
	return found.data.unlocked_coins.duplicate()

## Una jugada terminada (ganada o perdida) suma a la partida guardada; abandonar o cerrar el juego no escribe nada.
func record_finished_run() -> void:
	run_recorded = true
	clear_run_save()
	# Con la semilla elegida no se suma nada: ni jugadas ni victorias ni nivel ni desbloqueos.
	if game.seeded: return
	if not profiles_enabled or profile_slot == 0: return
	var level: int = game.level_index + 1 if not game.campaign.is_empty() else 1
	var result: Dictionary = profile_store.record_run(profile_slot, {"won": game.phase == "won", "level": level, "tutorial": game.tutorial, "debug": game.debug_mode})
	profile_message = "" if result.ok else result.message
	if result.ok and game.tutorial: game.unlocked_coins = unlocked_coins_of_profile()

## «Continuar partida»: al estar en la tienda se guarda la jugada (último estado estable de esa tienda, con lo comprado hasta el momento).
## Se borra al terminar la jugada, ganada o perdida, y al empezar otra. Sin tutorial ni debug. Las pruebas apagan `profiles_enabled`.
func run_save_allowed() -> bool:
	return profiles_enabled and session_started and not game.tutorial and not game.debug_mode and validation_profile == false

func save_shop_checkpoint() -> void:
	if not run_save_allowed() or game.phase not in ["shop", "lobby"]: return
	var data := checkpoint_data()
	if run_store.write_text(run_store.path + ".tmp", run_store.encode(data)) and run_store.read_file(run_store.path + ".tmp").ok:
		DirAccess.rename_absolute(run_store.path + ".tmp", run_store.path)

func resume_hint() -> String:
	return "\nPodés volver a la mesa con «Continuar partida»." if profiles_enabled and FileAccess.file_exists(run_store.path) else ""

func clear_run_save() -> void:
	if not profiles_enabled: return
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(run_store.path + suffix): DirAccess.remove_absolute(run_store.path + suffix)

func has_run_save() -> bool:
	if not profiles_enabled or not FileAccess.file_exists(run_store.path): return false
	var found: Dictionary = run_store.read_file(run_store.path)
	return found.ok and found.active

func continue_run() -> void:
	var found: Dictionary = run_store.read_file(run_store.path)
	var restored = run_store.restore_game(found.data) if found.ok and found.active else null
	if restored == null:
		profile_message = "No se pudo continuar: el guardado de la partida está dañado. Se conserva sin cambios."
		render()
		return
	if is_instance_valid(background): background.thermos_configured = false
	presentation.observed.clear()
	feedback_remaining = 0
	selected.clear()
	repair_selection.clear()
	purchase_error = ""
	pending_tutorial_choice = false
	tutorial_seen.clear()
	game = restored
	game.debug_mode = false
	# Al volver a una tienda no se repite lo que ya pasó (la muerte del guardián): se muestra la etapa quieta.
	finale_shown = Presentation.finale_stage(game)
	finale_anim = ""
	showing_credits = false
	showing_rewards = false
	game.unlocked_coins = unlocked_coins_of_profile(false)
	campaign_mode = not game.campaign.is_empty()
	var ui_state: Dictionary = found.data.get("ui", {})
	shop_section = String(ui_state.get("shop_section", shop_section))
	pack_panel_open = bool(ui_state.get("pack_panel_open", true))
	session_started = true
	run_recorded = false
	profile_message = ""
	render()

var game_menu: Control

func close_game_menu() -> void:
	if is_instance_valid(game_menu):
		if game_menu.get_parent() != null: game_menu.get_parent().remove_child(game_menu)
		game_menu.queue_free()
	game_menu = null

## In-game menu: every secondary option lives here so the table and the shop stay uncluttered.
func show_game_menu() -> void:
	close_game_menu()
	game_menu = Control.new()
	game_menu.name = "GameMenu"
	game_menu.size = Vector2(1440, 900)
	game_menu.z_index = 120
	ui.add_child(game_menu)
	var dim := ColorRect.new()
	dim.size = game_menu.size
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	game_menu.add_child(dim)
	var entries := [
		["Seguir jugando", close_game_menu, true],
		["Recorrido · M", func(): close_game_menu(); show_route(), false],
		["Opciones", func(): close_game_menu(); show_options(), false],
		["Abandonar partida", func(): close_game_menu(); request_navigation("menu"), false]]
	# Saltar niveles: solo en la campaña (el nivel de prueba tiene uno solo) y fuera de una compra a medio resolver.
	if not game.campaign.is_empty():
		var jump := ["Ir a otro nivel", func(): close_game_menu(); show_level_picker(), false]
		entries.insert(3, jump)
	var card := panel(game_menu, Rect2(520, 450 - (110 + entries.size() * 72) / 2, 400, 110 + entries.size() * 72), Color("0d1728"), gold)
	var title := label(card, "MENÚ", Vector2(0, 24), 30, gold, 400)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in range(entries.size()):
		var entry: Array = entries[index]
		var item := button(card, entry[0], Rect2(50, 92 + index * 72, 300, 54), entry[1], false, entry[2])
		if entry[0] == "Ir a otro nivel":
			item.name = "JumpLevel"
			item.disabled = game.phase in Game.LEVEL_JUMP_BLOCKED
			if item.disabled: item.tooltip_text = "Terminá primero la compra o el paquete pendiente."

const LEVEL_NAMES := {"dia": "Día", "tarde": "Tarde", "noche": "Noche", "cierre": "Cierre", "espacio": "Espacio", "agujero_negro": "Agujero negro", "cielo": "Cielo · Dios"}

## Elegir a qué nivel ir. Ir a uno abre su presentación desde el primer rival: se conservan plata, dados, monedas y
## stickers; se pierde el encuentro en curso. Los niveles salteados quedan como superados en el recorrido.
func show_level_picker() -> void:
	close_game_menu()
	game_menu = Control.new()
	game_menu.name = "LevelPicker"
	game_menu.size = Vector2(1440, 900)
	game_menu.z_index = 120
	ui.add_child(game_menu)
	var dim := ColorRect.new()
	dim.size = game_menu.size
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	game_menu.add_child(dim)
	var card := panel(game_menu, Rect2(420, 195, 600, 510), Color("0d1728"), gold)
	var title := label(card, "IR A OTRO NIVEL", Vector2(0, 24), 30, gold, 600)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(card, "Empezás el nivel elegido desde el primer rival. Conservás plata, dados, monedas y stickers; se pierde el encuentro en curso.", Vector2(40, 74), 16, cream, 520)
	for index in range(game.campaign.size()):
		var level_id := index
		var current: bool = index == game.level_index and game.phase == "level_intro"
		var name_text := "Nivel %d · %s" % [index + 1, LEVEL_NAMES.get(game.campaign[index].environment, game.campaign[index].environment)]
		if index == game.level_index: name_text += "  (actual)"
		var go := button(card, name_text, Rect2(60 + (index % 2) * 250, 150 + int(index / 2) * 66, 230, 52), func():
			close_game_menu()
			act(func(): game.jump_to_level(level_id)), current or not game.can_jump_to_level(index), index == game.level_index)
		go.name = "Level_%d" % (index + 1)
	button(card, "Volver", Rect2(60, 430, 480, 48), func(): show_game_menu()).name = "Back"

## Destinos: "menu" (abandonar la jugada), "new" (nueva partida: elegir modo), "tutorial" (jugar el tutorial, desde Opciones), "new_debug" (solo desarrollo),
## "quit" (salir del juego). Las jugadas no se guardan: abandonar o salir las pierde y no suma estadísticas.
func request_navigation(destination: String) -> void:
	if destination not in ["menu", "new", "new_debug", "quit", "tutorial"]: return
	var in_progress: bool = session_started and game.phase not in ["menu", "won", "lost"]
	pending_navigation = destination
	if destination == "quit" or in_progress:
		confirmation.title = {"quit": "Salir del juego", "menu": "Abandonar partida", "new": "Nueva partida", "new_debug": "Nueva partida debug", "tutorial": "Jugar el tutorial"}[destination]
		confirmation.ok_button_text = {"quit": "Salir", "menu": "Abandonar", "new": "Empezar de nuevo", "new_debug": "Empezar de nuevo", "tutorial": "Empezar el tutorial"}[destination]
		confirmation.cancel_button_text = "Seguir jugando" if in_progress else "Cancelar"
		confirmation.dialog_text = "¿Salir del juego?" + ("\nLa partida en curso no cuenta para tus estadísticas." + resume_hint() if in_progress else "") if destination == "quit" else ("Abandonar la partida no cuenta para tus estadísticas." + resume_hint() if destination == "menu" else "Hay una partida en curso: empezar otra la pierde y no cuenta para tus estadísticas.")
		confirmation.popup_centered(Vector2i(620, 220))
		return
	confirm_navigation()

func confirm_navigation() -> void:
	var destination := pending_navigation
	pending_navigation = ""
	confirmation.hide()
	if destination == "quit": get_tree().quit()
	elif destination == "new": new_run_from_result()
	elif destination == "new_debug": start_new_run(-1, true)
	elif destination == "tutorial": start_new_run(-1, false, true)
	elif destination.begins_with("load_"): load_profile(int(destination.trim_prefix("load_")))
	elif destination.begins_with("delete1_"):
		var slot := int(destination.trim_prefix("delete1_"))
		pending_navigation = "delete2_%d" % slot
		confirmation.title = "Borrar progreso"
		confirmation.ok_button_text = "Sí, borrar"
		confirmation.cancel_button_text = "No, conservarla"
		confirmation.dialog_text = "¿Estás muy, muy seguro?\nSe pierden las estadísticas, los logros y las monedas desbloqueadas del Progreso %d." % slot
		confirmation.popup_centered(Vector2i(620, 220))
	elif destination.begins_with("delete2_"): delete_profile(int(destination.trim_prefix("delete2_")))
	elif destination == "menu":
		selected.clear()
		repair_selection.clear()
		purchase_error = ""
		pending_tutorial_choice = false
		menu_panel = ""
		game.return_to_menu()
		session_started = false
		render()

var profiles_panel: Control

## Cargar una partida guardada (o crear una vacía): queda en uso y arranca una jugada nueva con la pregunta del tutorial.
func request_load_profile(slot: int) -> void:
	var in_progress: bool = session_started and game.phase not in ["menu", "won", "lost"]
	if not in_progress:
		load_profile(slot)
		return
	detail.hide()
	pending_navigation = "load_%d" % slot
	confirmation.title = "Cargar progreso"
	confirmation.ok_button_text = "Cargar"
	confirmation.cancel_button_text = "Seguir jugando"
	confirmation.dialog_text = "Hay una partida en curso: cargar otro progreso la pierde y no cuenta para tus estadísticas."
	confirmation.popup_centered(Vector2i(620, 220))

func load_profile(slot: int) -> void:
	if not profiles_enabled or not ProfileStore.valid_slot(slot): return
	var found: Dictionary = profile_store.read(slot)
	if found.ok and not found.exists:
		found = profile_store.create(slot)
		# Progreso recién creado: la primera Campaña pregunta por el tutorial.
		if found.ok: tutorial_offer_slot = slot
	if not found.ok:
		profile_message = found.message
		if is_instance_valid(profiles_panel): show_profiles()
		return
	remember_profile(slot)
	profile_message = ""
	detail.hide()
	selected.clear()
	repair_selection.clear()
	game.return_to_menu()
	session_started = false
	open_menu_panel("modes")

func request_delete_profile(slot: int) -> void:
	detail.hide()
	pending_navigation = "delete1_%d" % slot
	confirmation.title = "Borrar progreso"
	confirmation.ok_button_text = "Borrar"
	confirmation.cancel_button_text = "Conservarla"
	confirmation.dialog_text = "¿Seguro que querés borrar este progreso?\nProgreso %d." % slot
	confirmation.popup_centered(Vector2i(620, 220))

func delete_profile(slot: int) -> void:
	var result: Dictionary = profile_store.delete(slot)
	profile_message = "" if result.ok else result.message
	if result.ok and preferences.get("last_profile", 0) == slot: remember_profile(0)
	show_profiles()

## Botón común para los paneles que viven dentro del diálogo de detalle (`button()` no responde con el diálogo abierto).
func dialog_button(parent: Node, text_value: String, rect: Rect2, action: Callable, disabled := false) -> Button:
	var node := Button.new()
	node.text = text_value
	node.position = rect.position
	node.size = rect.size
	node.disabled = disabled
	node.pressed.connect(action)
	parent.add_child(node)
	return node

## Las tres ranuras con sus datos, «Cargar» y «Borrar».
func show_profiles() -> void:
	present_detail("Progreso guardado", "")
	detail_body.hide()
	if is_instance_valid(profiles_panel):
		detail.remove_child(profiles_panel)
		profiles_panel.queue_free()
	profiles_panel = Control.new()
	profiles_panel.name = "ProfilesPanel"
	profiles_panel.custom_minimum_size = Vector2(760, 470)
	detail.add_child(profiles_panel)
	var current: int = preferences.get("last_profile", 0)
	var slots: Array = profile_store.slots() if profiles_enabled else []
	for entry in slots:
		var slot: int = entry.slot
		var top := 4.0 + (slot - 1) * 140.0
		var card := panel(profiles_panel, Rect2(0, top, 760, 128), Color("0d1728"), gold)
		card.name = "Slot_%d" % slot
		label(card, "Progreso %d%s" % [slot, "  ·  en uso" if slot == current else ""], Vector2(16, 10), 21, gold, 460)
		var text: String = "Vacía: se crea al cargarla." if entry.ok and not entry.exists else (ProfileStore.summary(entry.data) if entry.ok else entry.message)
		label(card, text, Vector2(16, 42), 15, cream, 470)
		var load_caption := "Cargar" if entry.ok and entry.exists else "Crear y cargar"
		var load_button := dialog_button(card, load_caption, Rect2(520, 16, 220, 44), func(): request_load_profile(slot), not entry.ok)
		load_button.name = "Load_%d" % slot
		var delete_button := dialog_button(card, "Borrar", Rect2(520, 70, 220, 40), func(): request_delete_profile(slot), not FileAccess.file_exists(profile_store.path_of(slot)))
		delete_button.name = "Delete_%d" % slot
	label(profiles_panel, profile_message if profile_message != "" else "Tu progreso guarda estadísticas, logros y monedas desbloqueadas, no partidas en curso.", Vector2(0, 424), 15, gold, 480)
	dialog_button(profiles_panel, "Volver a las opciones", Rect2(500, 428, 260, 38), show_options).name = "BackToOptions"
	detail.popup_centered(Vector2i(820, 620))

## La pregunta del tutorial (solo la primera vez, ver `choose_campaign`). No: sigue la campaña; sí: jugada guiada.
func ask_tutorial() -> void:
	open_menu_panel("tutorial")

## Cambia lo que muestra el paño del medio del menú inicial ("" lo deja vacío).
func open_menu_panel(panel_name: String) -> void:
	menu_panel = panel_name
	pending_tutorial_choice = panel_name == "tutorial"
	render()

## «Campaña» en la elección de modo: arranca directo. Solo la primera vez (sin progreso todavía, o con uno recién
## creado) pregunta por el tutorial; después el tutorial se juega desde Opciones.
func choose_campaign() -> void:
	if should_offer_tutorial():
		tutorial_offer_slot = 0
		ask_tutorial()
	else: start_new_run()

func should_offer_tutorial() -> bool:
	if not profiles_enabled: return false
	var slot := active_profile(false)
	return slot == 0 or slot == tutorial_offer_slot

func cancel_navigation() -> void:
	var cancelled := pending_navigation
	pending_navigation = ""
	confirmation.hide()
	# Las confirmaciones de partidas salen del panel de Opciones: al cancelar se vuelve a él.
	if cancelled.begins_with("load_") or cancelled.begins_with("delete"): show_profiles()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: dragged_group = []
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(confirmation):
		if detail.visible: detail.hide()
		request_navigation("quit")

func route_text() -> String:
	if not game.campaign.is_empty():
		var lines: Array[String] = ["CAMPAÑA DE PRUEBA · %d / %d encuentros superados" % [game.completed_encounters.size(), game.campaign_route().size()], "Objetivos fijos, catálogo provisional. Solo se avanza al siguiente encuentro.", ""]
		for stop in game.campaign_route():
			lines.append("Nivel %d · %s · %s · %s" % [stop.level, stop.name, str(stop.target) + " puntos" if stop.target > 0 else "objetivo del jefe por anunciar", stop.status])
			if stop.position >= 3: lines.append("  " + stop.rule)
		lines.append("\nRegla de este nivel: " + BossRules.description(game.boss_rule))
		return "\n".join(lines)
	var lines: Array[String] = ["Nivel de prueba · " + " → ".join(game.level_encounters.map(func(encounter): return str(encounter.target))), ""]
	for stop in game.route():
		lines.append("%s · objetivo %d · %s\n%s" % [stop.name, stop.target, stop.status, stop.rule])
		lines.append("")
	lines.append(BossRules.description(game.boss_rule))
	lines.append("El recorrido es de consulta. Solo se avanza al siguiente encuentro, después de cobrar, resolver reparaciones y pasar por la tienda.")
	return "\n".join(lines)

func show_route() -> void:
	present_detail("Recorrido del nivel", route_text())

func show_options() -> void:
	present_detail("Opciones y controles", "F11: pantalla completa. F1: ayuda. M: recorrido. 1–5: seleccionar. G: agrupar. C/V: vaso/reserva. Espacio: tirar. I: inspeccionar.")
	detail_body.hide()
	if is_instance_valid(settings_panel):
		detail.remove_child(settings_panel)
		settings_panel.queue_free()
	settings_panel = Control.new()
	settings_panel.custom_minimum_size = Vector2(760, 615)
	detail.add_child(settings_panel)
	var mute := CheckButton.new()
	mute.name = "Mute"
	mute.text = "Silenciar todo"
	mute.position = Vector2(390, 0)
	mute.button_pressed = preferences.muted
	mute.toggled.connect(func(value): set_preference("muted", value))
	settings_panel.add_child(mute)
	label(settings_panel, "AUDIO", Vector2(12, 10), 22)
	var families := ["dice", "club", "ambient", "effects"]
	var names := ["Dados y cuero", "Club", "Ambiente", "Efectos"]
	for i in range(4):
		label(settings_panel, names[i], Vector2(12, 60 + i * 43), 19)
		var slider := HSlider.new()
		slider.name = families[i] + "Volume"
		slider.position = Vector2(245, 60 + i * 43)
		slider.size = Vector2(350, 28)
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = preferences[families[i] + "_volume"] * 100
		var amount := label(settings_panel, "%d%%" % slider.value, Vector2(620, 61 + i * 43), 19)
		var key: String = families[i] + "_volume"
		slider.value_changed.connect(func(value):
			amount.text = "%d%%" % value
			set_preference(key, value / 100.0))
		settings_panel.add_child(slider)
	label(settings_panel, "PRESENTACIÓN", Vector2(12, 245), 22)
	var speed_control := OptionButton.new()
	speed_control.name = "AnimationSpeed"
	speed_control.position = Vector2(310, 240)
	speed_control.size = Vector2(310, 38)
	for caption in ["Sin animación", "Velocidad normal", "Velocidad rápida"]: speed_control.add_item(caption)
	speed_control.select(preferences.speed)
	speed_control.item_selected.connect(func(index): set_preference("speed", index))
	settings_panel.add_child(speed_control)
	var keys := ["reduced_motion", "reduced_flashes", "high_contrast", "drag_groups", "plays_list"]
	var captions := ["Reducir movimiento", "Reducir destellos", "Mayor contraste en controles", "Armar grupos arrastrando", "Mostrar jugadas posibles"]
	for i in range(keys.size()):
		var toggle := CheckButton.new()
		toggle.name = keys[i]
		toggle.text = captions[i]
		toggle.position = Vector2(12, 287 + i * 40)
		toggle.button_pressed = preferences[keys[i]]
		var key: String = keys[i]
		toggle.toggled.connect(func(value): set_preference(key, value))
		settings_panel.add_child(toggle)
	var preview := Button.new()
	preview.text = "Probar dados"
	preview.position = Vector2(440, 310)
	preview.size = Vector2(230, 45)
	preview.pressed.connect(func(): audio.cue("roll"))
	settings_panel.add_child(preview)
	var faces_button := Button.new()
	faces_button.text = "Ver diseños de dados"
	faces_button.position = Vector2(440, 365)
	faces_button.size = Vector2(230, 40)
	faces_button.pressed.connect(show_dice_gallery)
	settings_panel.add_child(faces_button)
	var profiles_button := Button.new()
	profiles_button.name = "Profiles"
	profiles_button.text = "Progreso guardado"
	profiles_button.position = Vector2(440, 415)
	profiles_button.size = Vector2(230, 40)
	profiles_button.pressed.connect(show_profiles)
	settings_panel.add_child(profiles_button)
	# El tutorial se juega desde acá (D20); solo la primera vez, al estrenar un progreso, se pregunta al elegir Campaña.
	var tutorial_button := Button.new()
	tutorial_button.name = "PlayTutorial"
	tutorial_button.text = "Jugar el tutorial"
	tutorial_button.position = Vector2(440, 457)
	tutorial_button.size = Vector2(230, 36)
	tutorial_button.pressed.connect(func():
		detail.hide()
		request_navigation("tutorial"))
	settings_panel.add_child(tutorial_button)
	label(settings_panel, "Las señales siempre incluyen texto. Ninguna opción cambia la partida.\n" + detail_text, Vector2(12, 498), 17, cream, 725)
	var status := label(settings_panel, preference_store.last_error if preference_store.last_error != "" else "Opciones guardadas aparte de la partida.", Vector2(12, 585), 16, gold, 725)
	status.name = "PreferenceStatus"
	detail.popup_centered(Vector2i(820, 710))

func show_dice_gallery() -> void:
	present_detail("Dados · seis caras y gemas brillantes", "Cuerpo marfil, puntos negros o gemas de colores intensos con facetas y reflejos. Esta galería no equipa piezas ni modifica la partida.")
	detail_body.hide()
	if is_instance_valid(dice_gallery):
		detail.remove_child(dice_gallery)
		dice_gallery.queue_free()
	dice_gallery = Control.new()
	dice_gallery.name = "DiceGallery"
	dice_gallery.custom_minimum_size = Vector2(1100, 610)
	detail.add_child(dice_gallery)
	var materials := ["", "ruby", "sapphire", "emerald", "diamond"]
	var names := ["NEGRO", "RUBÍ", "ZAFIRO", "ESMERALDA", "DIAMANTE"]
	for number_value in range(1, 7): label(dice_gallery, str(number_value), Vector2(220 + (number_value - 1) * 145, 4), 20, gold)
	for row in range(5):
		label(dice_gallery, names[row], Vector2(12, 75 + row * 103), 20, cream)
		for number_value in range(1, 7):
			var die := Die.new()
			die.value = number_value
			die.pip_material = materials[row]
			die.disabled = true
			die.locked = true
			die.mouse_filter = Control.MOUSE_FILTER_IGNORE
			die.position = Vector2(184 + (number_value - 1) * 145, 35 + row * 103)
			die.scale = Vector2(1.5, 1.5)
			die.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
			dice_gallery.add_child(die)
	label(dice_gallery, "30 caras · puntos negros y gemas brillantes", Vector2(14, 575), 17, cream, 550)
	button(dice_gallery, "Ver materiales y elementos", Rect2(610, 573, 460, 35), show_component_gallery)
	detail.popup_centered(Vector2i(1140, 700))

func show_component_gallery() -> void:
	present_detail("Dados · materiales, elementos y combinación", "")
	detail_body.hide()
	if is_instance_valid(dice_gallery):
		detail.remove_child(dice_gallery)
		dice_gallery.queue_free()
	dice_gallery = Control.new()
	dice_gallery.custom_minimum_size = Vector2(1100, 610)
	detail.add_child(dice_gallery)
	button(dice_gallery, "Volver a gemas", Rect2(12, 5, 235, 35), show_dice_gallery)
	label(dice_gallery, "Cuerpo + bordes + puntos · desplazá para ver todas las variantes", Vector2(270, 11), 18, cream, 800)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 50)
	scroll.size = Vector2(1100, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dice_gallery.add_child(scroll)
	var sheet := Control.new()
	sheet.custom_minimum_size = Vector2(1080, 1160)
	scroll.add_child(sheet)
	var variants := [["HIERRO", "steel", "", ""], ["COBRE", "copper", "", ""], ["ORO", "gold", "", ""], ["MADERA", "wood", "", ""], ["FUEGO", "basic", "fire", ""], ["AGUA", "basic", "water", ""], ["ELECTRICIDAD", "basic", "electricity", ""], ["TIERRA", "basic", "earth", ""], ["VIENTO", "basic", "wind", ""], ["COMBINADO", "steel", "electricity", "diamond"]]
	for row in range(variants.size()):
		var variant: Array = variants[row]
		label(sheet, variant[0], Vector2(12, 42 + row * 103), 17, cream, 180)
		for value in range(1, 7):
			var die := Die.new()
			die.value = value
			die.body_material = variant[1]
			die.element = variant[2]
			animate_element(die, row + value)
			die.pip_material = variant[3]
			die.disabled = true
			die.locked = true
			die.mouse_filter = Control.MOUSE_FILTER_IGNORE
			die.position = Vector2(184 + (value - 1) * 145, 10 + row * 103)
			die.scale = Vector2(1.5, 1.5)
			die.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
			sheet.add_child(die)
	detail.popup_centered(Vector2i(1140, 700))

func set_preference(key: String, value: Variant) -> void:
	var candidate := preferences.duplicate()
	candidate[key] = value
	if not Preferences.valid(candidate): return
	preferences = candidate
	if key == "drag_groups": selected.clear()
	if preferences_enabled: preference_store.save_values(preferences)
	if is_instance_valid(settings_panel):
		var status = settings_panel.get_node_or_null("PreferenceStatus")
		if status: status.text = preference_store.last_error if preference_store.last_error != "" else "Opciones guardadas aparte de la partida."
	render()

func signal_action(sound: String, text_value: String) -> void:
	feedback_text = text_value
	feedback_remaining = 3.0
	audio.cue(sound)

## Las tres estrellas de la copa prendidas: confeti de victoria (se omite con «Reducir movimiento» o velocidad cero).
func _celebrate_copa() -> void:
	if preferences.reduced_motion or preferences.speed == 0: return
	var confetti := Confetti.new()
	confetti.speed = float(preferences.speed)
	add_child(confetti)

func _process(delta: float) -> void:
	step_throw(delta)
	update_hover_description()
	feedback_remaining = maxf(0, feedback_remaining - delta * (2 if preferences.speed == 2 else 1))
	if is_instance_valid(feedback_label):
		feedback_label.visible = feedback_remaining > 0
		# Reduced motion/instant mode retains static, readable text without a fade.
		feedback_label.modulate.a = 1.0 if preferences.reduced_motion or preferences.reduced_flashes or preferences.speed == 0 else minf(1, feedback_remaining)

## Mientras el termo sirve sus stickers no están donde estaban: sus zonas dejan de recibir el mouse.
func sync_sticker_zones() -> void:
	var pouring: bool = is_instance_valid(background) and background.props.busy("thermos")
	var thermos_button := ui.get_node_or_null("InspectThermos")
	if thermos_button == null: return
	for zone in thermos_button.get_children():
		if not zone.has_meta("sticker_id"): continue
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE if pouring else Control.MOUSE_FILTER_STOP
		zone.mouse_default_cursor_shape = Control.CURSOR_ARROW if pouring else Control.CURSOR_POINTING_HAND

func update_hover_description() -> void:
	if not is_instance_valid(hover_description): return
	sync_sticker_zones()
	var hovered := get_viewport().gui_get_hovered_control()
	var blocked: bool = get_viewport().gui_is_dragging() or detail.visible or confirmation.visible or is_instance_valid(sticker_book) or game.phase in ["purchase_target", "sticker_choice", "coin_choice"]
	var hovered_die: Die = hovered if hovered != null and hovered.get_script() == Die and hovered.die_index >= 0 and hovered.die_index < game.dice.size() and not blocked else null
	var text := ""
	if hovered != null and hovered is Control and hovered_die == null and not blocked:
		text = hovered.tooltip_text.strip_edges()
	var hinted_ids: Array = []
	if hovered_die != null and game.phase == "play" and not background.shop_mode:
		for combination in possible_combinations(hovered_die.die_index):
			for id in combination.ids:
				if id not in hinted_ids: hinted_ids.append(id)
	if is_instance_valid(plays_panel) and plays_panel.is_inside_tree() and not blocked:
		for id in plays_panel.hovered_ids:
			if id not in hinted_ids: hinted_ids.append(id)
	for id in table_dice:
		var die = table_dice[id]
		var hinted: bool = id in hinted_ids
		if is_instance_valid(die) and die.combo_hint != hinted:
			die.combo_hint = hinted
			die.queue_redraw()
	if is_instance_valid(sticker_tip):
		var sticker_id: String = hovered.get_meta("sticker_id", "") if hovered != null and not blocked else ""
		if sticker_id == "" or game.thermos_stolen() or game.cup.stickers.get(sticker_id, 0) <= 0 or background.props.busy("thermos"): sticker_tip.hide()
		else: sticker_tip.show_for(sticker_id, game.cup.stickers[sticker_id], game.sticker_catalog, hovered.get_global_rect(), background.shop_mode, hovered.get_meta("thermos_origin", Vector2.ZERO))
	if is_instance_valid(die_card):
		if hovered_die == null:
			die_card.hide()
		else:
			var rect := Rect2(hovered_die.global_position, hovered_die.size * hovered_die.scale)
			die_card.show_for(game.dice[hovered_die.die_index], game.global_points, game.boss_context(), DieCard.Style.SHOP if background.shop_mode else DieCard.Style.FELT, rect, PlaysPanel.CARD_TOP if is_instance_valid(plays_panel) and not plays_panel.rows.is_empty() else DieCard.FELT_TOP)
	hover_description.visible = not text.is_empty()
	if text.is_empty(): return
	if hover_description_body.text != text:
		hover_description_body.text = text
		hover_description_body.add_theme_font_size_override("font_size", 16 if text.length() > 650 else 18)
		hover_description.reset_size()
	place_hover_description(hovered)

## La ayuda de la mano del jefe sale centrada debajo de la mano (D20, PS6), dentro de la pantalla; si no entra abajo,
## va arriba. El resto de las ayudas sigue en su lugar de siempre, sobre la libreta.
func place_hover_description(hovered: Control) -> void:
	var offer := offer_card_of(hovered)
	# En la tienda todo sale arriba de lo señalado: la tarjeta del objeto a la venta, o la moneda o el dado propio.
	if offer == null and is_instance_valid(background) and background.shop_mode and hovered != null: offer = hovered
	if offer != null:
		# Arriba de la tarjeta o del objeto (abajo si no entra).
		var card_rect := offer.get_global_rect()
		var box := hover_description.size
		var above := Vector2(card_rect.get_center().x - box.x / 2.0, card_rect.position.y - box.y - 6.0)
		if above.y < 12.0: above.y = card_rect.end.y + 6.0
		hover_description.position = Vector2(clampf(above.x, 12.0, 1440.0 - box.x - 12.0), clampf(above.y, 12.0, 888.0 - box.y))
		return
	if hovered == null or hovered.name != "InspectBoss":
		hover_description.position = HOVER_DEFAULT
		return
	var rect := hovered.get_global_rect()
	var box_size := hover_description.size
	var at := Vector2(rect.get_center().x - box_size.x / 2.0, rect.end.y + 8.0)
	if at.y + box_size.y > 888.0: at.y = rect.position.y - box_size.y - 8.0
	at.x = clampf(at.x, 12.0, 1440.0 - box_size.x - 12.0)
	at.y = clampf(at.y, 12.0, 888.0 - box_size.y)
	hover_description.position = at

## La tarjeta de la tienda (`Offer_N`) que contiene al control, o null si no está en una.
func offer_card_of(hovered: Control) -> Control:
	if not background.shop_mode: return null
	var node: Node = hovered
	while node != null and node != ui:
		if node is Control and String(node.name).begins_with("Offer_"): return node
		node = node.get_parent()
	return null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11 and not confirmation.visible:
		var current := DisplayServer.window_get_mode()
		if current == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(windowed_mode)
		else:
			windowed_mode = current
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if detail.visible and detail.title == "Opciones y controles": show_options()
		get_viewport().set_input_as_handled()

func render_entry() -> void:
	if game.phase == "menu":
		render_menu()
		return
	render_tutorial_intro()

## Pantalla inicial (D20): el menú va sobre el paño izquierdo de la mesa; ver `start_menu.gd`.
func render_menu() -> void:
	StartMenu.build(self)

## Lugar de siempre de la ayuda al pasar el mouse (sobre la libreta).
const HOVER_DEFAULT := Vector2(30, 400)

const SELLER_LINE := "Veo que querés desafiar a Dios. Él no juega a los dados, pero quizás puedas vencerlo."

## Presentación del tutorial: el vendedor te recibe y arranca el primer encuentro.
func render_tutorial_intro() -> void:
	var bubble := panel(ui, Rect2(500, 150, 600, 330), Color("0d1728"), gold)
	bubble.name = "SellerIntro"
	label(bubble, "EL VENDEDOR", Vector2(30, 22), 28, gold, 540)
	var speech := label(bubble, SELLER_LINE + "\n\nAntes de sentarte a la mesa, dejame mostrarte cómo se juega: se tira, se arma el grupo, se anota y después pasás por mi maletín. Seguí los carteles.", Vector2(30, 76), 20, cream, 540)
	speech.name = "SellerSpeech"
	# Leve animación y un sonido básico al hablar: el texto se escribe de a poco y el cartel se mece. Sin animación, todo junto.
	if preferences.speed != 0 and not preferences.reduced_motion:
		var seconds := 0.03 * speech.text.length() / maxi(preferences.speed, 1)
		speech.visible_ratio = 0.0
		speech.create_tween().tween_property(speech, "visible_ratio", 1.0, seconds)
		var bob := bubble.create_tween().set_loops(maxi(int(seconds / 0.8), 1))
		bob.tween_property(bubble, "position:y", bubble.position.y - 3, 0.4).set_trans(Tween.TRANS_SINE)
		bob.tween_property(bubble, "position:y", bubble.position.y, 0.4).set_trans(Tween.TRANS_SINE)
		var blips := bubble.create_tween().set_loops(maxi(int(seconds / 0.14), 1))
		blips.tween_callback(func(): if is_instance_valid(audio): audio.cue("speak"))
		blips.tween_interval(0.14)
	var start := button(bubble, "Empezar el tutorial", Rect2(120, 250, 360, 56), func(): act(game.begin_level), false, true)
	start.name = "TutorialStart"
	start.grab_focus()
	button(ui, "Abandonar partida", Rect2(1220, 23, 185, 38), func(): request_navigation("menu"))

func render() -> void:
	sticker_animation = null
	if is_instance_valid(hover_description):
		hover_description.free()
	finish_throw()
	table_dice.clear()
	var profile := Presentation.profile(game)
	background.shop_mode = game.phase in ["shop", "purchase_target", "sticker_choice", "coin_choice"] or (game.tutorial and game.phase == "level_intro")
	if game.phase in ["won", "lost"] and session_started and not run_recorded: record_finished_run()
	save_shop_checkpoint()
	background.stickers = game.cup.stickers.duplicate()
	background.menu_mode = game.phase == "menu"
	background.quiet = game.phase == "menu" or game.in_lobby()
	if is_instance_valid(background): background.configure(profile, preferences)
	_update_finale(profile)
	if is_instance_valid(audio): audio.configure(preferences, profile.environment)
	var cue: Dictionary = presentation.observe(game)
	if not cue.is_empty(): signal_action(cue.sound, cue.text)
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = pixel_theme
	# La capa ocupa toda la pantalla: sin esto se comía los clics que van al fondo (estrellas de la copa).
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	hover_description = PanelContainer.new()
	hover_description.name = "HoverDescription"
	hover_description.position = HOVER_DEFAULT
	hover_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description.add_theme_stylebox_override("panel", ItemTooltip.skin())
	hover_description_body = ItemTooltip.content("")
	hover_description_body.custom_minimum_size.x = 422
	hover_description.add_child(hover_description_body)
	hover_description.hide()
	# Draw above ordinary UI without becoming a mouse target.
	hover_description.z_index = 90
	ui.add_child(hover_description)
	die_card = DieCard.new()
	ui.add_child(die_card)
	sticker_tip = StickerTip.new()
	ui.add_child(sticker_tip)
	if showing_credits:
		render_credits()
		return
	if game.phase == "menu" or (game.phase == "level_intro" and game.tutorial):
		render_entry()
		render_tutorial_layer()
		return
	# Selección de encuentro (D20): la mesa sin libreta ni botonera, con la bandeja de abajo.
	if game.in_lobby():
		EncounterLobby.build(self)
		render_inventory()
		render_seed()
		finish_render()
		return
	# Cobro (D20): la libreta en blanco, sin dados ni botonera; «+$total» y Continuar salen en `render_result`.
	if game.phase in ["reward", "bonus"]:
		render_notebook(true)
		render_inventory()
		render_seed()
		finish_render()
		return
	if game.phase not in ["sticker_choice", "coin_choice"]: pack_panel_open = true
	if game.phase != "coin_choice": coin_pack_replacing = ""
	if background.shop_mode:
		render_shop()
		finish_render()
		return
	# El menú de la partida está en la esquina de la libreta (render_inventory), no arriba.
	if game.phase not in ["shop", "purchase_target", "sticker_choice", "coin_choice"]: shop_section = "coins"
	if game.phase not in ["sticker_choice", "coin_choice"]: pack_panel_open = true
	render_notebook()
	render_table()
	render_inventory()
	render_actions()
	render_seed()
	finish_render()

func finish_render() -> void:
	if game.debug_mode: label(ui, "DEBUG · DAÑO ∞ · PLATA ∞", Vector2(480, 114), 16, gold, 460)
	var thermos_rect: Rect2 = Backdrop.SHOP_THERMOS_RECT if background.shop_mode else (Backdrop.STOLEN_THERMOS_RECT if game.thermos_stolen() else Backdrop.THERMOS_RECT)
	var thermos_button := button(ui, "", thermos_rect, inspect_thermos)
	thermos_button.name = "InspectThermos"
	if background.shop_mode and not game.thermos_stolen(): thermos_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if not background.shop_mode and background.finale_stage != "matrix":
		# En la selección de encuentro y el cobro, bandera y sifones no responden (D20).
		for prop in ([] if game.in_lobby() or game.phase == "reward" else ["flag", "soda_left", "soda_right"]):
			var zone := BarProps.make_zone(prop, background.props)
			zone.clicked.connect(func(): background.props.play(prop))
			ui.add_child(zone)
			ui.move_child(zone, thermos_button.get_index())
		if not game.thermos_stolen(): BarProps.attach_ring(thermos_button, "thermos", background.props)
	else:
		# La bandera de la tienda también ondula al hacer clic.
		var shop_flag := BarProps.make_zone("shop_flag", background.props)
		shop_flag.clicked.connect(func(): background.props.play("shop_flag"))
		ui.add_child(shop_flag)
	for state in ["normal", "hover", "pressed"]: thermos_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if not background.shop_mode and is_instance_valid(cup_zone) and cup_zone.is_inside_tree(): cup_zone.accept_through(thermos_button)
	if not game.thermos_stolen():
		add_sticker_zones(thermos_button, Backdrop.SHOP_THERMOS_RECT.position if background.shop_mode else Backdrop.THERMOS_ORIGIN)
		if not background.shop_mode and is_instance_valid(cup_zone):
			for child in thermos_button.get_children():
				if child.has_meta("sticker_id"): cup_zone.accept_through(child)
	if not background.shop_mode: render_boss_hand()
	# En la tienda no queda texto de estado abajo: solo se avisa si una compra no se pudo hacer.
	if background.shop_mode and not purchase_error.is_empty(): label(ui, purchase_error, Vector2(38, 864), 17, cream, 1360).name = "ShopError"
	if game.phase != "repair": repair_selection.clear()
	# Ganarle a La Semilla no muestra cartel: la mesa se cae y vienen los créditos.
	if game.phase in ["reward", "won", "lost", "repair"] and not (game.phase == "won" and background.finale_stage == "ending"): render_result()
	elif game.phase == "purchase_target": render_purchase_target()
	elif game.phase == "bonus": render_reward_choice()
	elif game.phase == "sticker_choice":
		if pack_panel_open: render_pack_choice()
		else: button(ui, "Elegir sticker pendiente", Rect2(1045, 748, 355, 40), func():
			pack_panel_open = true
			render())
	elif game.phase == "coin_choice":
		if pack_panel_open: CoinPackPanel.build(self)
		else: button(ui, "Elegir moneda pendiente", Rect2(1045, 748, 355, 40), func():
			pack_panel_open = true
			render())
	render_tutorial_layer()
	if finale_anim != "": render_finale_blocker()
	if finale_anim == "ending": _animate_ending_ui()

## Estado visible que usa el guion para elegir el paso (ver TutorialScript.step).
func tutorial_context() -> Dictionary:
	var cup: Array = []
	for die in game.dice:
		if die.zone == "cup": cup.append(die.id)
	return {"phase": game.phase, "rival": game.rival, "hand": game.hand, "rolls_made": game.rolls_made, "grouped": game.groups.size(),
		"cup": cup, "selected": selected.duplicate(), "points": game.points, "target": game.target() if not game.level_encounters.is_empty() else 0,
		"shop_visited": not game.shop_state.is_empty()}

## Paso del tutorial según el estado; {} fuera del tutorial.
func tutorial_step() -> Dictionary:
	return TutorialScript.step(tutorial_context()) if game.tutorial and session_started else {}

## ¿El tutorial deja hacer esta acción ahora? Fuera del tutorial, siempre. `to_cup` y `group` además exigen la selección del cartel.
func tutorial_allows(action: String) -> bool:
	if not game.tutorial: return true
	var current := tutorial_step()
	if not TutorialScript.allows(current, action): return false
	if action == "to_cup" and current.has("to_cup_select"): return TutorialScript.selection_matches(current.to_cup_select, selected)
	if action == "group" and current.has("group_select"): return TutorialScript.selection_matches(current.group_select, selected)
	return true

## Carteles del paso actual: abiertos hasta que se aprietan «Continuar»; después queda el «?» para volver a verlos.
func render_tutorial_layer() -> void:
	tutorial_current = tutorial_step()
	if tutorial_current.is_empty() or tutorial_current.notes.is_empty(): return
	var overlay := TutorialOverlay.new()
	var blocking: bool = tutorial_current.get("blocking", false)
	# Los pasos de acción no tapan nada ni piden «Continuar»: el cartel dice qué tocar y se toca.
	overlay.setup(tutorial_current.notes, not blocking or tutorial_current.id not in tutorial_seen, gold, cream, blocking)
	for zone in tutorial_current.get("glow_zones", []):
		if zone == "play_first":
			if is_instance_valid(plays_panel) and not plays_panel.rows.is_empty(): overlay.add_follow_glow(plays_panel.rows[0], func(): return not throwing)
		else: overlay.add_glow(TutorialScript.ZONES[zone])
	for id in tutorial_current.get("highlight", []):
		var die = table_dice.get(id)
		if is_instance_valid(die): overlay.add_follow_glow(die, func(): return not throwing, 76.0)
	overlay.dismissed.connect(func():
		tutorial_seen.append(tutorial_current.id)
		render())
	overlay.reopened.connect(func():
		tutorial_seen.erase(tutorial_current.id)
		render())
	ui.add_child(overlay)

func tutorial_notes_open() -> bool:
	return game.tutorial and not tutorial_current.is_empty() and tutorial_current.get("blocking", false) and tutorial_current.id not in tutorial_seen

## `blank`: la hoja vacía del cobro (D20), solo con el título.
func render_notebook(blank := false) -> void:
	var note := panel(ui, Rect2(22, 25, 310, 630), Color("f3e6c7"), Color("856a47"))
	note.name = "PlayerNotebook"
	note.theme = theme
	# Flat paper belongs to the player's interface, with no table perspective.
	for line_y in range(44, 621, 24):
		var rule := ColorRect.new()
		rule.position = Vector2(18, line_y)
		rule.size = Vector2(275, 1)
		rule.color = Color(0.45, 0.54, 0.61, 0.16)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.add_child(rule)
	var margin := ColorRect.new()
	margin.position = Vector2(17, 12)
	margin.size = Vector2(1, 605)
	margin.color = Color(0.62, 0.23, 0.22, 0.35)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(margin)
	label(note, "LIBRETA", Vector2(28, 14), 22, ink)
	if blank: return
	label(note, "PUNTOS / OBJETIVO", Vector2(28, 49), 14, ink)
	label(note, "%d / %d" % [game.points, game.target()], Vector2(28, 69), 32, ink)
	label(note, "Mano %d / %d" % [game.hand, game.hand_limit()], Vector2(28, 115), 18, ink)
	label(note, money_text(game.cash), Vector2(211, 115), 22, ink)
	label(note, "Tiradas restantes: %d" % game.rolls_left, Vector2(28, 143), 18, ink)
	label(note, "Nivel %d · Rival %d / %d" % [game.level_index + 1, game.rival + 1, game.level_encounters.size()], Vector2(28, 177), 15, ink)
	label(note, game.boss_name() if game.is_boss() else "Próximo jefe: " + game.boss_rule.name, Vector2(28, 200), 14, ink, 254)
	var rule_text := RichTextLabel.new()
	rule_text.name = "EncounterRule"
	rule_text.position = Vector2(28, 236)
	rule_text.size = Vector2(254, 60)
	rule_text.add_theme_color_override("default_color", ink)
	rule_text.add_theme_font_size_override("normal_font_size", 14)
	rule_text.text = BossRules.description(game.boss_rule, game.boss_state, game.hand)
	note.add_child(rule_text)
	label(note, "GRUPOS", Vector2(28, 304), 17, ink)
	var preview_value: Dictionary = game.preview() if game.phase == "play" else game.last_score
	var hidden_forecast: bool = game.phase == "play" and BossRules.forecast_hidden(game.boss_context())
	if preview_value.is_empty(): preview_value = {"total": 0, "rows": [], "served": false}
	if hidden_forecast: preview_value = {"total": 0, "rows": [], "served": false}
	var final_ink := Color("244b91") if game.phase != "play" else ink
	# Calculations stay scrollable without shrinking the text.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(25, 333)
	scroll.size = Vector2(262, 122)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	note.add_child(scroll)
	var entries := Control.new()
	entries.custom_minimum_size = Vector2(245, maxf(122, preview_value.rows.size() * 46))
	scroll.add_child(entries)
	var y := 0.0
	for row in preview_value.rows:
		var r: Dictionary = row
		var row_button := button(entries, "%s  ·  %s" % [r.category, number(r.total)], Rect2(0, y, 245, 25), func(): show_detail(r))
		row_button.clip_text = true
		row_button.add_theme_font_size_override("font_size", 14)
		row_button.add_theme_color_override("font_color", final_ink)
		row_button.add_theme_color_override("font_hover_color", Color("176294"))
		var row_style := box(Color(0.8, 0.68, 0.48, 0.1))
		row_style.content_margin_top = 2
		row_style.content_margin_bottom = 2
		row_button.add_theme_stylebox_override("normal", row_style)
		row_button.add_theme_stylebox_override("hover", row_style)
		row_button.add_theme_stylebox_override("pressed", row_style)
		var formula := "(%s + %s + %s) ×%s" % [number(r.base), number(r.dice), number(r.added), number(r.multiplier)]
		if r.get("copy_count", 0) > 0:
			formula += " ×%s" % number(1 + r.copy_count)
		label(entries, formula, Vector2(4, y + 25), 12, final_ink)
		y += 46
	if preview_value.rows.is_empty(): label(entries, ("Previsión oculta: la ves al anotar." if hidden_forecast else "Tirá los dados para empezar."), Vector2(4, 15), 14, ink, 240)
	label(note, "TOTAL DE MANO", Vector2(28, 464), 14, ink)
	label(note, "?" if hidden_forecast else number(preview_value.total), Vector2(215, 457), 28, final_ink)
	label(note, "Previsión oculta" if hidden_forecast else ("Previsión" if game.phase == "play" else "Anotado"), Vector2(28, 486), 12, final_ink)
	if preview_value.served: label(note, "SERVIDA", Vector2(130, 486), 12, Color("94663b"))
	if not selected.is_empty(): label(note, selection_preview().text, Vector2(28, 509), 13, ink, 254)
	feedback_label = label(note, feedback_text, Vector2(28, 546), 13, Color("244b91"), 254)
	feedback_label.visible = feedback_remaining > 0
	var status := RichTextLabel.new()
	status.name = "NotebookStatus"
	status.position = Vector2(28, 583)
	status.size = Vector2(254, 36)
	status.add_theme_color_override("default_color", ink)
	status.add_theme_font_size_override("normal_font_size", 13)
	if flip_slot >= game.coin_inventory.consumables.size() or game.phase != "play": flip_slot = -1
	status.text = purchase_error if not purchase_error.is_empty() else game.message
	if game.boss_shield_active: status.text += "\nEscudo de jefe activo en esta mano."
	for impulse in game.impulses: status.text += "\nImpulso activo: %s." % Coins.definition(impulse).name
	if game.double_mult: status.text += "\nDoble mult activo en esta mano."
	note.add_child(status)

func money_text(amount: int) -> String:
	return "$∞" if game.debug_mode else "$%d" % amount

func number(value: float) -> String:
	return str(int(value)) if value == floor(value) else str(value)

func source_name(source: String) -> String:
	if source.begins_with("sticker:"):
		return "Sticker · " + Stickers.NAMES.get(source.get_slice(":", 1), source)
	if source.begins_with("shell:"):
		var shell := Gems.definition(source.get_slice(":", 1))
		if not shell.is_empty():
			return "%s · dado %d" % [shell.name, source.get_slice(":", 2).to_int() + 1]
	if source.begins_with("element:"):
		var element := Elements.definition(source.get_slice(":", 1))
		if not element.is_empty():
			return "%s · dado %d" % [element.name, source.get_slice(":", 2).to_int() + 1]
	if source.begins_with("material:"):
		var material := Materials.display_name(source.get_slice(":", 1))
		return "%s · dado %d" % [material, source.get_slice(":", 2).to_int() + 1]
	if source.begins_with("number:global:"):
		return "Mejora global del " + source.get_slice(":", 2)
	if source.begins_with("boss:face:"): return "Jefe · cara " + source.get_slice(":", 2) + " rebajada"
	if source == "boss:repeat": return "Jefe · categoría repetida al 50 %"
	if source == "boss:roulette": return "Jefe · ruleta de la mano"
	var coin := source.trim_prefix("coin:").trim_prefix("consumable:")
	return Rules.COINS[coin].name if Rules.COINS.has(coin) else source

func show_detail(row: Dictionary) -> void:
	detail.title = "Libreta · detalle de cálculo"
	var lines: Array[String] = [row.category, "",
		"Base: %s · categoría %s + servida %s" % [number(row.base), number(row.get("category_base", row.base)), number(row.get("served_bonus", 0))],
		"Valores de dados: +%s" % number(row.dice),
		"Mejoras de puntos: +%s" % number(row.added), ""]
	for die in row.get("die_rows", []):
		var own := "Dado %d · cara %d: %s" % [die.id + 1, die.number, number(die.base_points)]
		for entry in die.point_additions:
			own += " +%s (%s)" % [number(entry.amount), source_name(entry.source)]
		for entry in die.point_factors:
			own += " ×%s (%s)" % [number(entry.amount), source_name(entry.source)]
		lines.append(own + " = " + number(die.points))
		if die.has("element_effect"):
			var effect: Dictionary = die.element_effect
			lines.append("  %s · %s: %s" % [effect.name, "activo" if effect.active else "inactivo", effect.reason])
		if die.has("shell_effect"):
			var shell: Dictionary = die.shell_effect
			lines.append("  %s · %s: %s" % [shell.name, "activo" if shell.active else "inactivo", shell.reason])
	lines.append("")
	lines.append("Subtotal: " + number(row.get("subtotal", row.base + row.dice + row.added)))
	if row.has("sticker_effect"):
		var sticker: Dictionary = row.sticker_effect
		lines.append("Sticker · %s · nivel %d: +%s puntos al grupo" % [sticker.name, sticker.level, number(sticker.points)])
	lines.append("Multiplicador inicial: ×" + number(row.get("multiplier_base", 1)))
	for entry in row.get("multiplier_additions", []):
		lines.append("  +%s · %s" % [number(entry.amount), source_name(entry.source)])
	for entry in row.get("multiplier_factors", []):
		lines.append("  ×%s · %s" % [number(entry.amount), source_name(entry.source)])
	lines.append("Multiplicador del grupo: ×" + number(row.multiplier))
	if row.get("copy_count", 0) > 0:
		lines.append("Resultado original: " + number(row.original_total))
		for entry in row.copies:
			lines.append("  +%s copia(s) · %s" % [number(entry.amount), source_name(entry.source)])
	lines.append("")
	lines.append("Total: " + number(row.total))
	present_detail("Libreta · detalle de cálculo", "\n".join(lines))

func make_zone(rect: Rect2, destination: String) -> Panel:
	var zone := Zone.new()
	zone.position = rect.position
	zone.size = rect.size
	zone.destination = destination
	zone.add_theme_stylebox_override("panel", box(Color(0.12, 0.01, 0.035, 0.08)))
	zone.die_dropped.connect(handle_die_drop)
	ui.add_child(zone)
	return zone

## Dados que viajan con `index` al arrastrarlo: toda la selección si él está seleccionado, si no solo él.
func group_for_drag(index: int) -> Array:
	dragged_group = []
	if preferences.drag_groups or game.phase != "play" or index not in selected or selected.size() < 2: return []
	var members: Array = []
	for id in selected:
		if table_dice.has(id) and is_instance_valid(table_dice[id]) and not table_dice[id].locked: members.append(table_dice[id])
	if members.size() < 2: return []
	for member in members: dragged_group.append(member.die_index)
	return members

func handle_die_drop(index: int, destination: String) -> void:
	if throwing or detail.visible or confirmation.visible or game.phase != "play" or index < 0 or index >= game.dice.size() or game.is_grouped(index) or game.dice[index].value == 0: return
	var group: Array = dragged_group.duplicate() if index in dragged_group else [index]
	group = group.filter(func(id): return id is int and id >= 0 and id < game.dice.size() and not game.is_grouped(id) and game.dice[id].value != 0)
	if destination == "draft":
		if not preferences.drag_groups or game.dice[index].zone != "reserve": return
		for id in group:
			if game.dice[id].zone == "reserve" and id not in selected: selected.append(id)
		render()
		return
	if destination not in ["reserve", "cup"]: return
	var from := ui.get_local_mouse_position()
	var moved: Array = []
	for id in group:
		if game.move_die(id, destination):
			selected.erase(id)
			moved.append(id)
	var animate: bool = preferences.speed != 0 and not preferences.reduced_motion
	if destination == "cup" and animate:
		for k in range(moved.size()):
			var entry := CupEntry.new()
			add_child(entry)
			entry.play(game.dice[moved[k]], game.boss_context(), from + Die.PILE_OFFSETS[k % Die.PILE_OFFSETS.size()], 0.3 if preferences.speed == 2 else 0.5, k * 0.12)
	if not moved.is_empty() or (destination == "reserve" and group.size() > 1):
		render()
		if destination == "reserve" and group.size() > 1 and animate: scatter_dice(group, from)

## Dados soltados juntos en la mesa: caen donde se soltaron y se desparraman a sus lugares. Solo presentación.
func scatter_dice(ids: Array, from: Vector2) -> void:
	for k in range(ids.size()):
		var die: Control = table_dice.get(ids[k])
		if die == null or not is_instance_valid(die): continue
		var landing := die.position
		var angle := die.rotation_degrees
		die.position = from + Die.PILE_OFFSETS[k % Die.PILE_OFFSETS.size()] - die.get_parent().position - die.size / 2.0
		die.rotation_degrees = Die.PILE_ANGLES[k % Die.PILE_ANGLES.size()]
		die.scale = Vector2.ONE * 1.25
		die.z_index = 20
		var speed_factor := 0.6 if preferences.speed == 2 else 1.0
		var tween := die.create_tween()
		tween.tween_property(die, "scale", Vector2.ONE, 0.12 * speed_factor)
		tween.tween_property(die, "position", landing, 0.42 * speed_factor).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(k * 0.03)
		tween.parallel().tween_property(die, "rotation_degrees", angle, 0.42 * speed_factor).set_delay(k * 0.03)
		tween.tween_callback(func(): die.z_index = 0)

func possible_combinations(index: int) -> Array:
	if game.phase != "play" or game.rolls_made == 0 or index < 0 or index >= game.dice.size() or game.is_grouped(index) or game.dice[index].zone != "reserve": return []
	var available: Array = []
	for id in range(game.dice.size()):
		if not game.is_grouped(id) and game.dice[id].zone == "reserve": available.append(id)
	var best: Dictionary = {}
	for mask in range(1, 1 << available.size()):
		var ids: Array = []
		var values: Array = []
		for bit in range(available.size()):
			if mask & (1 << bit):
				ids.append(available[bit])
				values.append(game.dice[available[bit]].value)
		if index not in ids: continue
		var resolved := Rules.resolve_wildcards(game.dice, ids, game.active_rules())
		var category: String = resolved.category
		if category.is_empty() or BossRules.forbidden(game.boss_context(), category): continue
		for slot in range(ids.size()):
			if resolved.assigned.has(ids[slot]): values[slot] = resolved.assigned[ids[slot]]
		if not best.has(category): best[category] = {"category": category, "ids": ids, "values": values}
	return best.values()

func loose_die_pose(index: int) -> Dictionary:
	# Separate landing areas prevent overlap; small offsets and rotations break the grid.
	const LANDINGS = [Vector2(48, 35), Vector2(238, 61), Vector2(146, 133), Vector2(79, 234), Vector2(255, 239)]
	var last_throw := 0
	for event in game.events:
		if event.type in [Game.INITIAL_ROLL, Game.REROLL] and index in event.payload.rolled_ids:
			last_throw = event.sequence
	# A private generator leaves gameplay RNG untouched and keeps retained dice still.
	var visual_rng := RandomNumberGenerator.new()
	visual_rng.seed = hash("%d:%d:%d" % [game.run_seed, index, last_throw])
	var offset := Vector2(visual_rng.randf_range(-8, 8), visual_rng.randf_range(-8, 8))
	var angle := visual_rng.randf_range(7, 22) * (-1 if visual_rng.randi() % 2 == 0 else 1)
	return {"position": LANDINGS[index] + offset, "angle": angle}

func render_table() -> void:
	var felt := FeltLayout.bounds()
	var group_area := make_zone(felt, "draft") if preferences.drag_groups else panel(ui, felt, Color(0.12, 0.01, 0.035, 0.08))
	group_area.name = "GroupArea"
	if preferences.drag_groups:
		var local_shape := PackedVector2Array()
		for point in FeltLayout.polygon(): local_shape.append(point - felt.position)
		group_area.shape = local_shape
	# Los grupos conservan su lugar de siempre (366, 324); la zona de soltado ahora llega hasta el borde dorado.
	var content := Control.new()
	content.name = "GroupContent"
	content.position = Vector2(366, 324) - felt.position
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group_area.add_child(content)
	var plays: Array = PlaysPanel.best_plays(game) if preferences.plays_list else []
	if preferences.drag_groups:
		if plays.is_empty(): label(content, "Arrastrá los dados acá", Vector2(16, 12), 16, cream, 290)
		for slot in range(selected.size()):
			add_die(content, selected[slot], Vector2(8 + slot * 61, 255))
	var y := 58.0
	for group_index in range(game.groups.size()):
		var group: Dictionary = game.groups[group_index]
		var current_index := group_index
		label(content, group.category + (" · FIJO" if group.locked else " · EDITABLE"), Vector2(26, y), 15, cream)
		var x := 20.0
		for index in group.ids:
			add_die(content, index, Vector2(x, y + 27), true)
			x += 60
		if not group.locked and game.phase == "play" and not game.tutorial:
			# Arriba de la fila de dados, a la altura del nombre del grupo, para no taparlos.
			button(content, "Desarmar", Rect2(211, y - 13, 112, 26), func(): act(func(): game.ungroup(current_index))).name = "Ungroup_%d" % current_index
		y += 103
	plays_panel = null
	if not plays.is_empty():
		plays_panel = PlaysPanel.new()
		plays_panel.play_chosen.connect(func(ids: Array):
			var current := tutorial_step()
			if not game.tutorial or (TutorialScript.allows(current, "group") and TutorialScript.selection_matches(current.get("group_select", ids), ids)): act(func(): game.form_group(ids)))
		ui.add_child(plays_panel)
		plays_panel.setup(plays, game.groups.size(), BossRules.forecast_hidden(game.boss_context()), number, group_area if preferences.drag_groups else null)
	var reserve := make_zone(Rect2(712, 324, 350, 330), "reserve")
	thief_pending = thief_next
	thief_next = -1
	for index in range(game.dice.size()):
		if (game.dice[index].zone == "reserve" or index == thief_pending) and not game.is_grouped(index) and not (preferences.drag_groups and index in selected):
			var pose := loose_die_pose(index)
			add_die(reserve, index, pose.position, false, pose.angle)
	var cup := make_zone(Rect2(1082, 324, 358, 330), "cup")
	cup_zone = cup
	var cup_button := button(cup, "", Rect2(Backdrop.CUP_RECT.position - cup.position, Backdrop.CUP_RECT.size), click_cup)
	cup_button.name = "InspectCup"
	BarProps.attach_ring(cup_button, "cup", background.props)
	for state in ["normal", "hover", "pressed"]: cup_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	cup.accept_through(cup_button)
	var overlay := TableDragOverlay.new()
	overlay.cup_zone = cup.get_rect()
	overlay.smooth = not preferences.reduced_motion and preferences.speed != 0
	overlay.reserve_ok = func(index: int) -> bool: return preferences.drag_groups and game.phase == "play" and index >= 0 and index < game.dice.size() and game.dice[index].zone == "reserve" and not game.is_grouped(index) and index not in selected
	ui.add_child(overlay)

func add_die(parent: Node, index: int, pos: Vector2, grouped := false, angle := 0.0) -> void:
	var die := Die.new()
	die.configure_appearance(game.dice[index], game.boss_context())
	die.boss_mark = game.boss_marks().get(index, "")
	for group in game.groups:
		if group.get("assigned", {}).has(index): die.wild_number = group.assigned[index]
	die.die_index = index
	die.chosen = index in selected
	die.drag_group = group_for_drag.bind(index)
	die.locked = grouped or game.phase != "play"
	die.position = pos
	die.size = Vector2(62, 62)
	die.pivot_offset = die.size / 2.0
	die.rotation_degrees = angle
	die.sway_enabled = not preferences.reduced_motion and preferences.speed != 0
	animate_element(die, index)
	die.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	die.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	die.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	die.inspect_requested.connect(inspect_die)
	die.pressed.connect(func(): toggle_die(index))
	parent.add_child(die)
	table_dice[index] = die

func render_actions() -> void:
	var playing: bool = game.phase == "play"
	var preview := selection_preview()
	button(ui, "Armar grupo", Rect2(375, 681, 210, 47), func(): act(func(): game.form_group(selected)), not playing or not preview.valid or not tutorial_allows("group"))
	button(ui, "Al vaso →", Rect2(597, 681, 157, 47), func(): move_selected("cup"), not playing or selected.is_empty() or game.rolls_left == 0 or not tutorial_allows("to_cup"))
	button(ui, "← Reservar", Rect2(766, 681, 157, 47), func(): move_selected("reserve"), not playing or selected.is_empty() or not tutorial_allows("reserve"))
	button(ui, "Inspeccionar", Rect2(934, 681, 137, 47), func(): inspect_die(selected[0]), selected.size() != 1)
	button(ui, "TIRAR (%d)" % game.rolls_left, Rect2(1082, 681, 312, 47), func(): act(game.roll), not playing or game.rolls_left <= 0 or not tutorial_allows("roll"), true)
	button(ui, "ANOTAR MANO", Rect2(40, 681, 292, 47), func(): act(game.score_hand), not playing or game.rolls_made == 0 or not tutorial_allows("score"), true)
	if game.phase == "hand_result":
		if game.points >= game.target():
			button(ui, "Cerrar y cobrar", Rect2(375, 626, 236, 42), func(): act(game.close_encounter), not tutorial_allows("close"), true)
		if game.hand < game.hand_limit():
			var next_name: String = ["", "primera", "segunda", "tercera", "cuarta"][mini(game.hand + 1, 4)]
			button(ui, "Jugar %s mano" % next_name, Rect2(725, 626, 262, 42), func(): act(game.next_hand), not tutorial_allows("next_hand"))
			if game.points >= game.target():
				label(ui, "Otra mano consume el premio de $2 por mano sobrante.", Vector2(375, 593), 16, cream, 690)

func move_selected(destination: String) -> void:
	if throwing or not tutorial_allows("to_cup" if destination == "cup" else "reserve"): return
	var moved := false
	for index in selected:
		if game.dice[index].zone != destination and game.move_die(index, destination): moved = true
	if moved: signal_action("move", "Dados al vaso" if destination == "cup" else "Dados reservados")
	selected.clear()
	render()

func render_inventory() -> void:
	label(ui, "%d/%d" % [game.passives.size(), game.coin_inventory.shared_capacity], Vector2(42, 750), 14, gold)
	var step := minf(90.0, 740.0 / maxf(game.coin_inventory.shared_capacity, 1))
	for i in range(game.passives.size()):
		var coin: String = game.passives[i]
		var b := button(ui, "", Rect2(175 + i * step, 748, 64, 60), func(): inspect_coin(coin))
		b.name = "EquippedCoin_" + str(i)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		add_coin(b, coin, Rect2(1, 1, 58, 58))
		b.tooltip_text = Rules.COINS[coin].name + "\n" + Rules.COINS[coin].description + coin_total_line(game.coin_inventory.equipped[i].instance_id)
		if BossRules.suspended(game.boss_context(), "coin", coin):
			label(b, "SUSP", Vector2(1, 43), 11, gold)
			b.tooltip_text += " Suspendida por el jefe; conserva su espacio."
	label(ui, "UN USO", Vector2(922, 751), 13, gold)
	for i in range(game.coin_inventory.consumables.size()):
		var stored: String = game.coin_inventory.consumables[i].coin_id
		var slot := i
		var use := button(ui, "", Rect2(999 + i * 74, 748, 64, 60), (func(): start_flip(slot)) if Coins.targeted(stored) else (func(): act(func(): game.use_consumable(slot))), not Coins.can_use(stored, game.phase) or BossRules.suspended(game.boss_context(), "coin", stored))
		use.name = "ConsumableCoin" if i == 0 else "ConsumableCoin_" + str(i)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: use.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		use.tooltip_text = Rules.COINS[stored].description + " Clic para consumir."
		add_coin(use, stored, Rect2(1, 1, 58, 58))
		if BossRules.suspended(game.boss_context(), "coin", stored):
			label(use, "SUSP", Vector2(1, 43), 11, gold)
			use.tooltip_text = "Suspendida por el jefe. No se consume y conserva su espacio."
	# El menú de la partida (Recorrido, Opciones, Abandonar…) en la esquina de la libreta (25/11, pedido del autor).
	# En la selección de encuentro ya están Opciones y Abandonar sobre la libreta: no se repite.
	if not game.in_lobby(): button(ui, "Menú", Rect2(1273, 748, 120, 60), show_game_menu).name = "TableMenu"

## Línea «Total: …» para la ayuda de una moneda propia que suma algo que cambia; vacía para las demás.
## `instance`: id de la instancia equipada o de un uso.
func coin_total_line(instance: int) -> String:
	for owned in game.coin_inventory.equipped + game.coin_inventory.consumables:
		if owned.get("instance_id", -1) == instance: return coin_total_for(owned.coin_id, owned, true)
	return ""

## «Total: …» de una moneda que suma algo que cambia: lo acumulado (Acumulada, Veterana, Racha, Gastada, Cazajefes) o lo
## que da ahora según el saldo, los stickers, las monedas equipadas o el nivel. A la venta (`owned` falso) se calcula
## como si ya la tuvieras. Las que dependen de la mano (tiradas, sobrantes) no muestran total.
func coin_total_for(coin_id: String, instance: Dictionary, owned: bool) -> String:
	var state := coin_state_text(instance if not instance.is_empty() else Coins.instance(coin_id, 0)).strip_edges()
	if state != "": return "\nTotal: " + state
	for effect in Coins.DATA.get(coin_id, {}).get("effects", []):
		var amount := float(effect.get("amount", 0))
		match effect.get("per", ""):
			"cash_fifth": return "\nTotal: +%d puntos de mano (con %s)" % [int(maxi(game.cash, 0) / 5) * int(amount), money_text(game.cash)]
			"sticker_levels":
				var levels := 0
				for level in game.cup.stickers.values(): levels += int(level)
				return "\nTotal: +%s mult (%d niveles de stickers)" % [number(levels * amount), levels]
			"equipped":
				var count: int = game.coin_inventory.equipped.size() + (0 if owned else 1)
				return "\nTotal: +%s mult (%d monedas equipadas)" % [number(count * amount), count]
			"campaign_level": return "\nTotal: +%s mult (nivel %d)" % [number((game.level_index + 1) * amount), game.level_index + 1]
	return ""

## Progress of coins that keep state (C18, C48-C51), one line for tooltips and the inspector.
func coin_state_text(instance: Dictionary) -> String:
	var state: Dictionary = instance.state
	match instance.coin_id:
		"spent": return "Fuerza %d / 40\n" % state.strength
		"veteran": return "+%s mult acumulado\n" % number(state.wins * 0.5)
		"accumulated": return "+%d puntos acumulados\n" % (state.hands * 3)
		"streak": return "+%s mult de racha\n" % number(state.streak * 0.5)
		"bosshunter": return "+%d mult acumulado\n" % state.bosses
	return ""

## TX10: the element emblem animates with the same switches as the rest of the motion (reduced motion, speed, flashes).
func animate_element(die: Die, slot: int) -> void:
	die.element_animated = not preferences.reduced_motion and preferences.speed != 0
	die.element_frame_ms = 75 if preferences.speed == 2 else 120
	die.element_phase = (slot * 5) % Die.ELEMENT_FRAMES
	die.flashes_reduced = preferences.reduced_flashes

func add_coin(parent: Node, coin: String, rect: Rect2) -> void:
	var icon := CoinArt.new()
	icon.coin_id = coin
	icon.position = rect.position
	icon.size = rect.size
	parent.add_child(icon)

func inspect_coin(coin: String) -> void:
	var data := Coins.definition(coin)
	if data.is_empty(): return
	var duration: String = {"equipped": "Mientras está equipada", "hand": "Mano actual", "encounter": "Encuentro actual", "instant": "Inmediata", "visit": "Visita actual a la tienda"}[data.duration]
	var windows := {"play": "durante la partida", "shop": "en la tienda", "repair": "en la fase de reparación"}
	var use_windows: Array = data.use_contexts.map(func(window): return windows.get(window, window))
	var context := "Pasiva al puntuar; no se consume." if data.type == "passive" else "Se usa " + ", ".join(use_windows) + "."
	if data.type == "consumable" and "shop" not in data.use_contexts: context += " No se usa en tienda."
	if BossRules.suspended(game.boss_context(), "coin", coin): context += "\nSUSPENDIDA POR JEFE: conserva su espacio; sin poder durante el encuentro."
	var progress := ""
	for instance in game.coin_inventory.equipped:
		if instance.coin_id == coin: progress = coin_state_text(instance)
	present_detail("Moneda · " + data.name, "%s\n\n%s%s · %s · %s\nDuración: %s\n%s\nPrecio: $%d · Reventa: $%d" % [data.description, progress, data.code, Coins.RARITY_NAMES[data.rarity], "Pasiva equipada" if data.type == "passive" else "Un uso", duration, context, data.price, data.resale], true)

func show_help() -> void:
	present_detail("Cómo jugar", "1. Tirás cinco dados; tres tiradas por mano y dos manos por rival.\n2. Seleccionás dados y armás grupos exactos. La selección muestra su categoría y puntos; no reparte dados automáticamente.\n3. Conservás sueltos o los enviás al vaso. Enviarlos fija los grupos; retirarlos no los desbloquea.\n4. Anotás grupos y sobrantes. Los sobrantes forman un único grupo sin combinación.\n\nDoble par: elegí 2-2-5-5; base 15 + caras 14 = 29, más los sobrantes. También podés formar dos pares separados.\nServida: anotar tras la primera tirada sin relanzar. Escaleras: 12345, 23456 y 34561.\nCon generala prohibida podés separar cinco iguales en trío + par. Consultá Recorrido para la regla de este nivel. Al alcanzar el objetivo podés cobrar o jugar otra mano disponible.\n\nSEL indica selección; FIJO indica grupo bloqueado. R y una grieta indican carcasa resquebrajada: solo suspende la gema.\nClic derecho en un dado para su ficha; Ver termo muestra los stickers pegados al termo del mate. Las ilustraciones actuales de monedas son provisionales.\n\nPodés activar Armar grupos arrastrando en la mesa o en Opciones: llevá los dados al sector izquierdo y pulsá Armar grupo. Arrastralos de vuelta para corregir el borrador. Al pasar el mouse por un dado se muestran sus combinaciones posibles.\n\nTeclado: con el modo de clic, 1–5 seleccionan dados, G agrupa, C envía al vaso, V reserva, espacio tira, I inspecciona la selección, Esc la limpia y F1 abre ayuda. Tab recorre botones; Enter los activa.\nUsá monedas de un uso antes de anotar; sus fichas explican duración y contexto. Cada sección de la tienda tiene su propio costo de renovación. Cancelar una compra sin confirmar no cobra. Un paquete ya pagado conserva sus opciones al cerrar el panel.")

func shop_offer_text(offer: Dictionary) -> Array:
	var effect: Dictionary = offer.effect
	match offer.kind:
		"coin": return [Coins.definition(effect.coin_id).name, "%s · %s
%s" % [Coins.definition(effect.coin_id).code, Coins.RARITY_NAMES[Coins.definition(effect.coin_id).rarity], Coins.definition(effect.coin_id).description]]
		"material": return [Materials.display_name(effect.id), "Recuerda los números que sacó en la mano; cuando forma grupo, los suma todos como puntos. Se borra al empezar otra mano." if Materials.base_of(effect.id) == "wood" else "+3 puntos propios al conservarlo en un relanzamiento ajeno; relanzarlo borra el bono. Dura el encuentro." if Materials.base_of(effect.id) == "steel" else "+0.5 al multiplicador de su grupo por relanzamiento propio. Dura el encuentro."]
		"shell":
			var shell: Dictionary = Gems.definition(effect.id)
			return ["Puntos · " + shell.name, "%s\nRotura: %d%% · Reparación: $%d" % [shell.description, int(shell.break_risk * 100), shell.repair_cost]]
		"element": return [Elements.definition(effect.id).name, Elements.definition(effect.id).condition]
		"global": return ["Mejora global", "+%d puntos para el número %d.\nSe aplica a todos tus dados." % [effect.amount, effect.number]]
		"face": return ["Cambio de cara", "Nueva cara: %d." % effect.number]
		"sticker":
			var data: Dictionary = game.sticker_catalog[effect.id]
			var level: int = game.cup.stickers.get(effect.id, 0)
			return [Stickers.NAMES[effect.id], "Nivel %d → %d · +%s puntos/nivel\n+%s al multiplicador/nivel\nCategorías: %s." % [level, level + 1, number(data.points_per_level), number(data.multiplier_per_level), ", ".join(Stickers.CATEGORIES[effect.id])]]
		"coin_pack": return ["Paquete de monedas", "%s. No se ve el contenido hasta comprarlo.
Se puede comprar con el inventario lleno: después elegís y, si no hay lugar, reemplazás una moneda tuya." % CoinPackPanel.closed_text(effect)]
		"pack": return ["Paquete de stickers", "Elegí uno entre tres distintos." if effect.pack_kind == "choose_one" else "Recibís dos stickers distintos."]
	return ["Oferta", ""]

func shop_skin(ornate := false) -> StyleBoxTexture:
	return UiSkin.title() if ornate else UiSkin.button("normal")

func skin_shop_button(node: Button) -> void:
	if preferences.high_contrast: return
	for state in ["normal", "hover", "pressed", "disabled"]: node.add_theme_stylebox_override(state, UiSkin.button(state))
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func shop_frame(rect: Rect2, ornate := false) -> Panel:
	var frame := panel(ui, rect, Color.TRANSPARENT)
	frame.add_theme_stylebox_override("panel", shop_skin(ornate))
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return frame

func shop_caption(parent: Node, text_value: String, rect: Rect2, font_size := 18, color := Color("fff0c7")) -> Label:
	var caption := label(parent, text_value, rect.position, font_size, color)
	caption.size = rect.size
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.clip_text = true
	return caption

func shop_icon(parent: Node, offer: Dictionary, rect: Rect2) -> void:
	if offer.kind == "sticker":
		var sticker := preload("res://scripts/sticker_art.gd").new()
		sticker.sticker_id = offer.effect.id
		sticker.level = game.cup.stickers.get(offer.effect.id, 0) + 1  # the offer shows the style it will have once bought
		sticker.position = rect.position
		sticker.size = rect.size
		parent.add_child(sticker)
		return
	if offer.kind == "coin":
		add_coin(parent, offer.effect.coin_id, rect)
		return
	if offer.kind == "coin_pack":
		add_coin(parent, "pack_small" if offer.effect.size == "small" else "pack_large", Rect2(rect.position + Vector2(rect.size.x * 0.12, 2), rect.size - Vector2(rect.size.x * 0.24, 18)))
		return
	if offer.kind in ["face", "shell", "material", "element"]:
		var face := Die.new()
		face.value = offer.effect.number if offer.kind == "face" else 5
		face.pip_material = offer.effect.id if offer.kind == "shell" else ""
		face.body_material = offer.effect.id if offer.kind == "material" else "basic"
		face.element = offer.effect.id if offer.kind == "element" else ""
		animate_element(face, int(rect.position.x / 100.0))
		face.disabled = true
		face.locked = true
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.scale = Vector2(1.4, 1.4)
		face.position = rect.get_center() - Vector2(31, 31) * face.scale
		for state in ["normal", "disabled"]: face.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		parent.add_child(face)
		return
	var icon := ShopArt.new()
	icon.position = rect.position
	icon.size = rect.size
	match offer.kind:
		"material", "shell", "element": icon.icon_id = offer.effect.id
		"global": icon.icon_id = "number_" + str(offer.effect.number)
		"face": icon.icon_id = "face"
		"pack": icon.icon_id = "pack"
		"sticker": icon.icon_id = "portrait" if offer.effect.id == "trio" else "sticker"
	parent.add_child(icon)
	if offer.kind == "pack":
		shop_caption(parent, "?" if offer.effect.pack_kind == "choose_one" else "2", Rect2(rect.position + Vector2(0, 5), rect.size - Vector2(0, 5)), 29)

## Gancho con hilos arriba y etiqueta de cartón abajo, detrás de lo que cuelga de la tarjeta (se agrega primero).
func shop_hook(card: Control, sold: bool) -> void:
	var fixture := ShopFixtures.new()
	fixture.name = "Hook"
	fixture.size = card.size
	fixture.sold = sold
	card.add_child(fixture)

func shop_card(parent: Node, section: String, index: int, rect: Rect2) -> void:
	var stock: Dictionary = game.shop_state.get(section, {"slots": [], "configured": false})
	var card := HoverPanel.new()
	card.name = "Offer_" + str(index)
	card.position = rect.position
	card.size = rect.size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(card)
	card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var offer: Dictionary = stock.slots[index] if index < stock.slots.size() else {}
	if offer.is_empty():
		if stock.configured:
			# El gancho queda vacío y la etiqueta dice VENDIDO.
			shop_hook(card, true)
			var tag_caption := shop_caption(card, "VENDIDO", Rect2(rect.size.x / 2.0 - 32, 112, 64, 24), 13, ShopFixtures.TAG_INK_SOLD)
			tag_caption.name = "SoldCaption"
		else:
			shop_caption(card, "Sin ofertas", Rect2(0, 53, rect.size.x, 34), 17, Color("c6ac88"))
		return
	shop_hook(card, false)
	var text: Array = shop_offer_text(offer)
	var compact := section in ["coins", "single_use"]
	shop_icon(card, offer, Rect2((rect.size.x - 100) / 2, 10, 100, 91))
	var object_hover := HoverPanel.new()
	object_hover.name = "ObjectHover"
	object_hover.position = Vector2((rect.size.x - 100) / 2, 10)
	object_hover.size = Vector2(100, 91)
	object_hover.mouse_filter = Control.MOUSE_FILTER_STOP
	object_hover.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	object_hover.tooltip_text = text[0] + "\n" + text[1] + (coin_total_for(offer.effect.coin_id, {}, false) if offer.kind == "coin" else "")
	card.add_child(object_hover)
	var unavailable: bool = game.phase != "shop" or not game.can_afford(game.charged_price(offer)) or not Purchases.valid_offer(section, offer, game.sticker_catalog)
	if offer.kind == "coin": unavailable = unavailable or not Coins.can_store(game.coin_inventory, offer.effect.coin_id)
	var id: String = offer.offer_id
	var price_text := "Gratis" if offer.offer_id in game.shop_gifts else "$%d" % game.charged_price(offer)
	var purchase := button(card, price_text, Rect2((rect.size.x - minf(102, rect.size.x - 8)) / 2, 109, minf(102, rect.size.x - 8), 30), func():
		var previous_stickers: Dictionary = game.cup.stickers.duplicate(true)
		var icon_center: Vector2 = card.get_global_rect().position + Vector2(rect.size.x / 2.0, 55.0)
		var result: Dictionary = game.begin_purchase(section, id)
		purchase_error = "" if result.ok else result.message
		render()
		# La compra ya está hecha y guardada; el vuelo del sticker suelto es solo presentación.
		if result.ok and offer.kind == "sticker" and preferences.speed != 0 and not preferences.reduced_motion:
			show_sticker_flight(offer.effect.id, previous_stickers.get(offer.effect.id, 0), icon_center)
		if result.ok and offer.kind == "pack" and offer.effect.pack_kind == "receive_two":
			show_sticker_reveal(offer.effect.items, previous_stickers), unavailable, true)
	purchase.name = "Price"
	# Todo lo que se vende se marca como clickeable: manito y borde amarillo sobre la silueta del objeto.
	var offer_ring := OfferRing.new()
	offer_ring.name = "OfferRing"
	offer_ring.position = Vector2((rect.size.x - 100) / 2 - OfferRing.MARGIN, 10 - OfferRing.MARGIN)
	offer_ring.key = JSON.stringify([offer.kind, offer.effect])
	offer_ring.make_icon = func(holder: Node): shop_icon(holder, offer, Rect2(0, 0, 100, 91))
	card.add_child(offer_ring)
	for target in [object_hover, purchase]:
		target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		target.mouse_entered.connect(func(): offer_ring.hover(true))
		target.mouse_exited.connect(func(): offer_ring.hover(false))
	object_hover.activated.connect(func():
		if not purchase.disabled: purchase.pressed.emit())
	# «Gratis» (regalo de la mano con el maletín) es más largo que un precio: más chico para que entre en la etiqueta.
	purchase.add_theme_font_size_override("font_size", 13 if offer.offer_id in game.shop_gifts else (20 if compact else 22))
	for state in ["normal", "hover", "pressed", "disabled"]: purchase.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	# El precio va escrito sobre la etiqueta de cartón que cuelga del gancho.
	purchase.add_theme_color_override("font_color", ShopFixtures.TAG_INK)
	purchase.add_theme_color_override("font_hover_color", ShopFixtures.TAG_INK_SOLD)
	purchase.add_theme_color_override("font_disabled_color", Color("8a7a60"))

## Secciones del maletín en pantalla (coinciden con las divisiones de `tienda-secciones-v4.png`).
const SHOP_ZONES := {"components": Rect2(538, 252, 367, 179), "stickers": Rect2(929, 252, 388, 179),
	"coins": Rect2(534, 442, 560, 179), "single_use": Rect2(1122, 442, 208, 179)}

func render_shop() -> void:
	shop_frame(Rect2(30, 14, 400, 75), true)
	shop_caption(ui, "TIENDA", Rect2(55, 34, 350, 38), 34)
	var inventory := panel(ui, Rect2(770, 777, 635, 80), Color.TRANSPARENT)
	inventory.name = "ShopInventory"
	inventory.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	render_inventory_trays()
	for index in range(game.coin_inventory.shared_capacity):
		var x := 785 + index * minf(78.0, 400.0 / maxf(game.coin_inventory.shared_capacity, 1))
		if index < game.passives.size():
			var coin: String = game.passives[index]
			var inspect := owned_shop_coin(coin, game.coin_inventory.equipped[index].instance_id, Rect2(x, 811, 62, 52))
			add_coin(inspect, coin, Rect2(5, 0, 52, 52))
	shop_frame(Rect2(518, 30, 193, 80))
	shop_caption(ui, "PLATA", Rect2(530, 38, 169, 22), 18)
	shop_caption(ui, money_text(game.cash), Rect2(530, 60, 169, 42), 34, gold)
	# Sin cartel de capacidad (25/11): un contador «monedas equipadas / lugares» abajo a la derecha de su bandeja.
	var capacity: int = game.coin_inventory.shared_capacity
	var tray_right: float = 785.0 + (capacity - 1) * minf(78.0, 400.0 / maxf(capacity, 1)) + 31.0 + 50.0
	var counter := shop_caption(ui, "%d/%d" % [game.passives.size(), capacity], Rect2(tray_right - 74, 856, 62, 18), 14, gold)
	counter.name = "CoinCounter"
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for id in range(5):
		var die := Die.new()
		die.configure_appearance(game.dice[id], game.boss_context())
		animate_element(die, id)
		die.die_index = id
		die.position = Vector2(361 + id * 72, 811)
		die.scale = Vector2(0.78, 0.78)
		die.pressed.connect(func(): inspect_die(id))
		die.inspect_requested.connect(inspect_die)
		for state in ["normal", "hover", "pressed"]: die.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		ui.add_child(die)
	var cup_zone := panel(ui, Backdrop.SHOP_THERMOS_RECT, Color.TRANSPARENT)
	cup_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cup_zone.name = "Shop_cup"
	var thermos := preload("res://scripts/shop_thermos.gd").new()
	thermos.name = "ThermosArtwork"
	thermos.size = cup_zone.size
	thermos.stickers = game.cup.stickers.duplicate(true)
	cup_zone.add_child(thermos)
	for slot in range(game.coin_inventory.consumables.size()):
		var stored: Dictionary = game.coin_inventory.consumables[slot]
		var offset: float = 1260.0 - (game.coin_inventory.consumables.size() - 1) * 38.0 + slot * 76.0
		var inspect := owned_shop_coin(stored.coin_id, stored.instance_id, Rect2(offset, 813, 62, 46))
		add_coin(inspect, stored.coin_id, Rect2(8, 0, 46, 46))
		if Coins.can_use(stored.coin_id, "shop"):
			var slot_index := slot
			var use_button := button(ui, "Usar", Rect2(offset, 880, 62, 18), func(): act(func(): game.use_consumable(slot_index)), game.phase != "shop")
			use_button.name = "UseShopCoin_" + str(slot)
			use_button.add_theme_font_size_override("font_size", 13)
	# Arriba componentes y stickers (los números son recompensa de los rivales); abajo las monedas y la de un uso.
	var zones := SHOP_ZONES
	var renew_names := {"coins": "monedas", "single_use": "moneda de un uso", "components": "componentes", "numbers": "números", "stickers": "stickers"}
	for section in zones:
		var section_id: String = section
		var zone := panel(ui, zones[section], Color.TRANSPARENT)
		zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		zone.name = "Shop_" + section
		var title_width := 0.0   # sin texto: el botón de renovar queda solo y centrado
		var header_x: float = (zones[section].size.x - title_width - 32) / 2
		var title := button(zone, "", Rect2(header_x, 0, title_width, 26), func(): shop_section = section_id)
		title.name = "Title"
		for state in ["normal", "hover", "pressed"]: title.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		title.add_theme_font_size_override("font_size", 18)
		var count: int = Shop.SIZES[section]
		var width: float = (zones[section].size.x - 24) / count
		for index in range(count): shop_card(zone, section, index, Rect2(12 + index * width, 28, width, 145))
		var stock: Dictionary = game.shop_state.get(section, {"slots": [], "configured": false})
		if game.is_seed_shop_visit(): continue # la mano con el maletín solo tiene la tanda completa (abajo)
		var renew := button(zone, "", Rect2(header_x, -2, 32, 30), func(): act(func(): game.refresh_shop(section_id)), game.phase != "shop" or not stock.configured or not game.can_afford(game.renewal_price(section_id)))
		renew.name = "Refresh"
		renew.tooltip_text = "Renovar %s · $%d\nCambia solo las ofertas de esta zona.\nEl costo aumenta solo para esta zona durante esta visita." % [renew_names[section], game.renewal_price(section_id)]
		for state in ["normal", "hover", "pressed", "disabled"]: renew.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var retry_icon := preload("res://scripts/retry_icon.gd").new()
		retry_icon.position = Vector2(2, 0)
		retry_icon.size = Vector2(28, 30)
		renew.add_child(retry_icon)
	# Salir de la tienda vuelve a la selección de encuentro (D20): ahí se elige jugar o volver a entrar.
	var next_label := "Volver a la mesa →"
	if game.is_seed_shop_visit():
		# La mano con el maletín: un regalo por sección; la tanda nueva cuesta siempre lo mismo y ya se paga.
		var restock := button(ui, "Otra tanda · $%d" % Campaign.SEED_SHOP_RESTOCK_PRICE, Rect2(1025, 170, 380, 40), func(): act(game.restock_seed_shop), game.phase != "shop" or not game.can_afford(Campaign.SEED_SHOP_RESTOCK_PRICE))
		restock.name = "SeedRestock"
		restock.tooltip_text = "La mano trae otra tanda de un ítem por sección.\nCuesta siempre $%d y lo nuevo ya no es gratis." % Campaign.SEED_SHOP_RESTOCK_PRICE
		restock.add_theme_font_size_override("font_size", 16)
		shop_caption(ui, "UN REGALO POR SECCIÓN" if not game.shop_gifts.is_empty() else "LA MANO YA NO REGALA", Rect2(1025, 214, 380, 22), 13, gold)
	var next_button := button(ui, next_label, Rect2(1025, 25, 380, 93), func(): act(game.exit_shop), game.phase != "shop", true)
	next_button.name = "ShopAdvance"
	next_button.add_theme_font_size_override("font_size", 18)
	var game_menu_button := button(ui, "Menú", Rect2(1025, 126, 380, 36), show_game_menu)
	game_menu_button.add_theme_font_size_override("font_size", 16)
	shop_caption(ui, "NIVEL %d · %s · DATOS PROVISIONALES" % [game.level_index + 1, game.environment_id().replace("_", " ").to_upper()], Rect2(30, 94, 400, 22), 11)
	coin_sale_overlay = preload("res://scripts/coin_sale_zone.gd").new()
	coin_sale_overlay.name = "CoinSaleOverlay"
	coin_sale_overlay.position = Vector2(518, 248)
	coin_sale_overlay.size = Vector2(819, 377)
	coin_sale_overlay.z_index = 100
	coin_sale_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	coin_sale_overlay.accepts = can_sell_dragged_coin
	coin_sale_overlay.coin_dropped.connect(sell_dragged_coin)
	coin_sale_overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	ui.add_child(coin_sale_overlay)
	# La zona de venta sigue la forma de la valija (el interior es un trapecio) y usa la letra del juego.
	var sale_shape := PackedVector2Array([Vector2(22, -2), Vector2(793, -2), Vector2(819, 377), Vector2(0, 377)])
	coin_sale_overlay.shape = sale_shape
	var sale_fill := Polygon2D.new()
	sale_fill.polygon = sale_shape
	sale_fill.color = Color(0.46, 0.025, 0.10, 0.62)
	coin_sale_overlay.add_child(sale_fill)
	var sale_edge := Line2D.new()
	sale_edge.points = sale_shape
	sale_edge.closed = true
	sale_edge.width = 2.0
	sale_edge.default_color = Color(0.93, 0.73, 0.40, 0.80)
	coin_sale_overlay.add_child(sale_edge)
	coin_sale_caption = shop_caption(coin_sale_overlay, "", Rect2(0, 140, 819, 90), 38)
	coin_sale_caption.add_theme_font_override("font", ItemTooltip.pixel_font())
	coin_sale_overlay.hide()

## Bandejas de madera con vivo dorado donde se apoyan tus dados (paño verde) y tus monedas (terciopelo bordó); la de un uso
## lleva un hueco con aro dorado. Se adaptan a la capacidad de monedas (coordenadas lógicas de 2×2 px).
func render_inventory_trays() -> void:
	var capacity: int = game.coin_inventory.shared_capacity
	var step := minf(78.0, 400.0 / maxf(capacity, 1))
	var first := 785.0 + 31.0
	var last := 785.0 + (capacity - 1) * step + 31.0
	var singles := maxi(game.coin_inventory.consumables.size(), 1)
	var first_use := 1260.0 - (singles - 1) * 38.0 + 31.0
	var last_use := first_use + (singles - 1) * 76.0
	var holes: Array = []
	for k in range(singles): holes.append(Vector2i(int((first_use + k * 76.0) / 2.0), 418))
	var fixtures := ShopFixtures.new()
	fixtures.name = "InventoryTrays"
	fixtures.mode = "trays"
	fixtures.size = Vector2(1440, 900)
	fixtures.trays = [
		{"rect": Rect2i(172, 397, 358, 439), "felt": "green", "holes": []},
		{"rect": Rect2i(int((first - 50.0) / 2.0), 397, int((last + 50.0) / 2.0), 439), "felt": "bordo", "holes": []},
		{"rect": Rect2i(int((first_use - 38.0) / 2.0), 397, int((last_use + 38.0) / 2.0), 439), "felt": "bordo", "holes": holes}]
	ui.add_child(fixtures)

func owned_shop_coin(coin: String, instance: int, rect: Rect2) -> Button:
	var node := preload("res://scripts/shop_coin_drag.gd").new()
	node.name = "OwnedCoin_" + coin
	node.coin_id = coin
	node.instance_id = instance
	node.position = rect.position
	node.size = rect.size
	node.sway_enabled = not preferences.reduced_motion and preferences.speed != 0
	node.drag_allowed = func(): return can_sell_dragged_coin({"shop_coin": coin, "instance_id": instance})
	node.drag_started.connect(show_coin_sale_overlay)
	node.drag_finished.connect(hide_coin_sale_overlay)
	node.tooltip_text = Coins.definition(coin).name + "\n" + Coins.definition(coin).description + coin_total_line(instance)
	node.mouse_default_cursor_shape = Control.CURSOR_DRAG
	for state in ["normal", "hover", "pressed", "disabled", "focus"]: node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	node.pressed.connect(func():
		if not node.block_click and not detail.visible and not confirmation.visible: inspect_coin(coin))
	ui.add_child(node)
	return node

func can_sell_dragged_coin(data: Variant) -> bool:
	if game.phase != "shop" or detail.visible or confirmation.visible or throwing or not data is Dictionary: return false
	if not data.get("shop_coin") is String or not data.get("instance_id") is int: return false
	for instance in game.coin_inventory.equipped + game.coin_inventory.consumables:
		if instance.coin_id == data.shop_coin and instance.instance_id == data.instance_id: return true
	return false

func show_coin_sale_overlay(data: Dictionary) -> void:
	if not can_sell_dragged_coin(data) or not is_instance_valid(coin_sale_overlay): return
	coin_sale_caption.text = "Vender: $%d" % Coins.definition(data.shop_coin).resale
	coin_sale_overlay.show()
	hover_description.hide()

func hide_coin_sale_overlay() -> void:
	if is_instance_valid(coin_sale_overlay): coin_sale_overlay.hide()

func sell_dragged_coin(data: Dictionary) -> void:
	if not can_sell_dragged_coin(data): return
	hide_coin_sale_overlay()
	act(func(): game.sell(data.shop_coin))

func render_purchase_target() -> void:
	panel(ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	var modal := panel(ui, Rect2(290, 105, 860, 690), Color.TRANSPARENT)
	modal.name = "PurchaseTarget"
	modal.add_theme_stylebox_override("panel", ItemTooltip.skin())
	modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pending: Dictionary = game.pending_purchase
	var offer: Dictionary = pending.offer
	var text: Array = shop_offer_text(offer)
	shop_caption(modal, text[0].to_upper(), Rect2(32, 24, 796, 38), 28, gold)
	shop_caption(modal, "Precio: $%d   ·   Saldo: %s" % [game.charged_price(offer), money_text(game.cash)], Rect2(32, 68, 796, 28), 18)
	shop_caption(modal, "1. ELEGÍ UN DADO", Rect2(32, 114, 796, 26), 18, gold)
	var target: Dictionary = pending.target
	for id in range(5):
		var die_id := id
		var state: Dictionary = game.dice[id].duplicate(true)
		if state.value == 0: state.value = state.faces[0]
		purchase_die_choice(modal, "Die_%d" % id, state, Rect2(72 + id * 146, 151, 132, 116), "DADO %d" % [id + 1], target.get("die_id", -1) == id, func():
			game.set_purchase_target({"die_id": die_id})
			purchase_error = ""
			render())
	var description := "Elegí el dado que recibirá la mejora."
	if target.has("die_id"):
		var die: Dictionary = game.dice[target.die_id]
		var material := Materials.display_name(die.material)
		var shell: String = Gems.definition(die.shell).get("name", "Sin carcasa")
		var element: String = Elements.definition(die.element).get("name", "Sin elemento")
		description = "Dado %d · %s · %s%s · %s" % [die.id + 1, material, shell, " (rota)" if die.shell_broken else "", element]
		if offer.kind == "face":
			shop_caption(modal, "2. ELEGÍ LA CARA A REEMPLAZAR", Rect2(32, 326, 796, 26), 18, gold)
			for index in range(6):
				var face_index := index
				var face_state: Dictionary = die.duplicate(true)
				face_state.value = die.faces[index]
				purchase_die_choice(modal, "Face_%d" % index, face_state, Rect2(72 + index * 120, 366, 116, 116), "CARA %d" % [index + 1], target.get("face_index", -1) == index, func():
					game.set_purchase_target({"die_id": die.id, "face_index": face_index})
					purchase_error = ""
					render())
	shop_caption(modal, description, Rect2(32, 282, 796, 32), 17)
	if offer.kind != "face":
		var summary := label(modal, text[1], Vector2(64, 347), 18, cream, 732)
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif not target.has("die_id"):
		shop_caption(modal, "Después elegí qué cara cambiar por un %d." % offer.effect.number, Rect2(32, 378, 796, 40), 19)
	var preview: Dictionary = game.purchase_preview()
	var hint := "Reemplaza solo esta familia. Las otras mejoras se conservan."
	if offer.kind == "face": hint = "La cara elegida pasará a tener un %d." % offer.effect.number
	shop_caption(modal, hint, Rect2(32, 500, 796, 32), 17)
	button(modal, "Confirmar · $%d" % game.charged_price(offer), Rect2(64, 554, 732, 46), func():
		var result: Dictionary = game.confirm_purchase()
		purchase_error = "" if result.ok else result.message
		render(), not preview.ok, true)
	button(modal, "Cancelar compra", Rect2(64, 620, 732, 40), func():
		game.cancel_purchase()
		purchase_error = ""
		render())

## Recompensa del encuentro (fase «bonus»): la misma elección de dado (y cara) que en la tienda, pero gratis. Un rival
## da una mejora de número o un cambio de cara; un jefe, una gema. «Dejarla» sigue sin tomarla.
func render_reward_choice() -> void:
	panel(ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	# Sin dado que elegir (mejora de número) la ventana es más baja.
	var compact: bool = game.pending_reward.offer.kind not in Purchases.TARGETED
	var modal := panel(ui, Rect2(290, 225, 860, 420) if compact else Rect2(290, 105, 860, 690), Color.TRANSPARENT)
	modal.name = "RewardChoice"
	modal.add_theme_stylebox_override("panel", ItemTooltip.skin())
	modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var reward: Dictionary = game.pending_reward
	var offer: Dictionary = reward.offer
	var text: Array = shop_offer_text(offer)
	shop_caption(modal, "RECOMPENSA", Rect2(32, 20, 796, 34), 28, gold)
	shop_caption(modal, "%s · gratis por vencer %s" % [text[0], "al jefe" if reward.source == "boss" else "al rival"], Rect2(32, 58, 796, 28), 18)
	var icon_holder := Control.new()
	icon_holder.position = Vector2(380, 92)
	icon_holder.size = Vector2(100, 91)
	modal.add_child(icon_holder)
	shop_icon(icon_holder, offer, Rect2(0, 0, 100, 91))
	var target: Dictionary = reward.target
	var targeted: bool = offer.kind in Purchases.TARGETED
	if targeted:
		shop_caption(modal, "1. ELEGÍ UN DADO", Rect2(32, 190, 796, 26), 18, gold)
		for id in range(5):
			var die_id := id
			var state: Dictionary = game.dice[id].duplicate(true)
			if state.value == 0: state.value = state.faces[0]
			purchase_die_choice(modal, "RewardDie_%d" % id, state, Rect2(72 + id * 146, 222, 132, 116), "DADO %d" % [id + 1], target.get("die_id", -1) == id, func():
				game.set_reward_target({"die_id": die_id})
				render())
		if offer.kind == "face" and target.has("die_id"):
			var die: Dictionary = game.dice[target.die_id]
			shop_caption(modal, "2. ELEGÍ LA CARA A REEMPLAZAR", Rect2(32, 350, 796, 26), 18, gold)
			for index in range(6):
				var face_index := index
				var face_state: Dictionary = die.duplicate(true)
				face_state.value = die.faces[index]
				purchase_die_choice(modal, "RewardFace_%d" % index, face_state, Rect2(72 + index * 120, 382, 116, 116), "CARA %d" % [index + 1], target.get("face_index", -1) == index, func():
					game.set_reward_target({"die_id": die.id, "face_index": face_index})
					render())
	var summary := label(modal, text[1], Vector2(64, 200 if compact else (512 if offer.kind == "face" else 360)), 18, cream, 732)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var preview: Dictionary = game.reward_preview()
	var take := button(modal, "Tomar recompensa", Rect2(64, 304 if compact else 574, 732, 46), func():
		var result: Dictionary = game.take_reward()
		purchase_error = "" if result.ok else result.message
		act(func(): pass), not preview.ok, true)
	take.name = "TakeReward"
	var skip := button(modal, "Dejarla", Rect2(64, 362 if compact else 632, 732, 38), func(): act(game.skip_reward))
	skip.name = "SkipReward"
	if preview.ok: take.grab_focus()

func purchase_die_choice(parent: Control, node_name: String, state: Dictionary, rect: Rect2, caption: String, picked: bool, action: Callable) -> Button:
	var choice := button(parent, "", rect, action)
	choice.name = node_name
	choice.tooltip_text = caption.capitalize()
	for mode in ["normal", "hover", "pressed"]:
		choice.add_theme_stylebox_override(mode, box(Color("153c50") if picked else Color("091923"), Color("68d8ef") if picked else gold if mode != "normal" else Color("785335"), 2))
	var icon := Die.new()
	icon.name = "DieArtwork"
	icon.configure_appearance(state)
	icon.position = Vector2((rect.size.x - 74.4) / 2, 8)
	icon.scale = Vector2(1.2, 1.2)
	icon.locked = true
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for mode in ["normal", "hover", "pressed", "disabled"]: icon.add_theme_stylebox_override(mode, StyleBoxEmpty.new())
	choice.add_child(icon)
	icon.tooltip_text = ""
	shop_caption(choice, caption, Rect2(0, 85, rect.size.x, 25), 15, Color("8ae6f2") if picked else cream)
	return choice

func render_pack_choice() -> void:
	panel(ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	var modal := panel(ui, Rect2(290, 160, 860, 580), Color.TRANSPARENT)
	modal.name = "StickerChoice"
	modal.add_theme_stylebox_override("panel", ItemTooltip.skin())
	modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop_caption(modal, "ELEGÍ UN STICKER", Rect2(32, 24, 796, 44), 28, gold)
	shop_caption(modal, "Paquete pagado: $%d · Tocá el sticker que querés llevar al termo." % game.pending_sticker_pack.paid, Rect2(32, 80, 796, 36), 17)
	var index := 0
	for id in game.pending_sticker_pack.items:
		var sticker_id: String = id
		var level: int = game.cup.stickers.get(id, 0)
		var choice := button(modal, "", Rect2(58 + index * 254, 147, 236, 325), func():
			var previous: Dictionary = game.cup.stickers.duplicate(true)
			if not game.choose_sticker(sticker_id): return
			purchase_error = ""
			render()
			show_sticker_reveal([sticker_id], previous))
		choice.name = "Sticker_" + id
		for mode in ["normal", "hover", "pressed"]:
			choice.add_theme_stylebox_override(mode, box(Color("091923") if mode == "normal" else Color("153c50"), gold if mode != "normal" else Color("785335"), 2))
		shop_icon(choice, {"kind": "sticker", "effect": {"id": id}}, Rect2(46, 14, 144, 144))
		shop_caption(choice, Stickers.NAMES[id], Rect2(8, 164, 220, 30), 18, gold)
		shop_caption(choice, "Nivel %d → %d" % [level, level + 1], Rect2(8, 202, 220, 26), 17)
		var growth: Dictionary = game.sticker_catalog[id]
		var effect := label(choice, "+%s puntos\n+%s al multiplicador\npor nivel" % [number(growth.points_per_level), number(growth.multiplier_per_level)], Vector2(12, 242), 16, cream, 212)
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.tooltip_text = "Por nivel: +%s puntos y +%s al multiplicador. Categorías: %s." % [number(growth.points_per_level), number(growth.multiplier_per_level), ", ".join(Stickers.CATEGORIES[id])]
		index += 1
	button(modal, "Cerrar panel", Rect2(64, 506, 732, 42), func():
		pack_panel_open = false
		render())

## Vuelo (o aviso de nivel) de un sticker suelto recién comprado. No bloquea la tienda: se corta solo si cambia la pantalla.
func show_sticker_flight(sticker_id: String, level_before: int, from: Vector2) -> void:
	var thermos_node = ui.get_node_or_null("Shop_cup/ThermosArtwork")
	if thermos_node == null or game.cup.stickers.get(sticker_id, 0) <= 0: return
	var flight := StickerFlight.new()
	flight.setup(sticker_id, level_before, game.cup.stickers[sticker_id], from, thermos_node, preferences.speed == 2)
	ui.add_child(flight)

func sticker_animation_active() -> bool:
	return is_instance_valid(sticker_animation) and not sticker_animation.finished and not sticker_animation.is_queued_for_deletion()

func show_sticker_reveal(items: Array, previous: Dictionary) -> void:
	sticker_animation = preload("res://scripts/sticker_reveal.gd").new()
	sticker_animation.items = items.duplicate()
	sticker_animation.before = previous.duplicate(true)
	sticker_animation.after = game.cup.stickers.duplicate(true)
	sticker_animation.thermos = ui.get_node("Shop_cup/ThermosArtwork")
	sticker_animation.still = preferences.reduced_motion or preferences.speed == 0
	sticker_animation.fast = preferences.speed == 2
	ui.add_child(sticker_animation)
	skin_shop_button(sticker_animation.get_node("Continue"))
	hover_description.hide()

func render_result() -> void:
	if game.phase == "reward":
		EncounterLobby.build_payout(self)
		return
	panel(ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	button(ui, "Menú", Rect2(1220, 23, 185, 38), show_game_menu)
	if game.phase == "repair":
		render_repairs()
		return
	if game.tutorial:
		render_tutorial_end()
		return
	var modal := panel(ui, Rect2(400, 240, 640, 480), Color("263c3d"), gold)
	if game.phase == "lost":
		label(modal, "ESTA VEZ, GANÓ EL AZAR", Vector2(36, 33), 29, gold)
		label(modal, "%d / %d puntos\n\n%s: se agotaron las manos sin llegar al objetivo.\nPodés volver a intentar con la misma semilla\no empezar una nueva partida." % [game.points, game.target(), "Nivel %d, encuentro %d" % [game.level_index + 1, game.rival + 1] if not game.campaign.is_empty() else "Rival %d" % (game.rival + 1)], Vector2(36, 103), 21, cream, 560)
		button(modal, "Reintentar misma semilla", Rect2(36, 306, 566, 49), func(): start_new_run(game.run_seed, false, false, true), false, true).tooltip_text = "Con la misma semilla la partida no suma nada a tu progreso."
		button(modal, "Nueva partida", Rect2(36, 371, 566, 45), new_run_from_result)
	else:
		label(modal, "LA SEMILLA DERROTADA" if game.phase == "won" and not game.campaign.is_empty() else "JEFE SUPERADO" if game.phase == "won" else "ENCUENTRO GANADO", Vector2(36, 30), 32, gold)
		if game.phase == "won": label(modal, ("VICTORIA · %d ENCUENTROS COMPLETADOS" % game.campaign_route().size()) if not game.campaign.is_empty() else "VICTORIA · NIVEL DE PRUEBA COMPLETADO", Vector2(36, 69), 16, cream)
		var p: Dictionary = game.payout
		label(modal, "%d / %d puntos\n\nVictoria                              $%d\nManos sobrantes                  $%d\nExceso de puntos                 $%d\nIntereses                             $%d\n\nTOTAL COBRADO                  $%d" % [game.points, game.target(), p.base, p.hands, p.excess, p.interest, p.total], Vector2(36, 90), 21, cream)
		if p.get("coins", 0) > 0: label(modal, "Incluye $%d de Cobrador." % p.coins, Vector2(36, 330), 16, gold)
		if game.phase == "won" and not game.campaign.is_empty():
			# Premio al ganar: mecánica posterior (docs/LA-SEMILLA.md). Por ahora, créditos y vuelta al inicio.
			var credits := button(modal, "Ver créditos →", Rect2(36, 371, 566, 49), show_credits, false, true)
			credits.name = "ShowCredits"
		else: button(modal, "Prototipo completado · volver a jugar", Rect2(36, 371, 566, 49), new_run_from_result, false, true)
	button(modal, "Volver al menú", Rect2(36, 437, 566, 36), func(): request_navigation("menu"))

## Desde la pantalla de victoria o derrota: vuelve al menú y hace la pregunta del tutorial de la jugada nueva.
func new_run_from_result() -> void:
	selected.clear()
	repair_selection.clear()
	purchase_error = ""
	game.return_to_menu()
	session_started = false
	open_menu_panel("modes")

## Cierre del tutorial (ganado o perdido): anuncia el logro y la moneda desbloqueada. Abandonar no llega acá.
func render_tutorial_end() -> void:
	var modal := panel(ui, Rect2(400, 190, 640, 520), Color("263c3d"), gold)
	modal.name = "TutorialEnd"
	label(modal, "TUTORIAL COMPLETADO", Vector2(36, 30), 32, gold)
	var intro := "Le ganaste al vendedor, pero igual se quedó con toda tu plata." if game.phase == "won" else "El azar te ganó esta vez, pero ya viste todo lo que hay que saber."
	label(modal, intro, Vector2(36, 84), 19, cream, 566)
	label(modal, "LOGRO · " + Achievements.name_of("tutorial_completed"), Vector2(36, 160), 22, gold, 566)
	var gift := Coins.definition("vendor_gift")
	label(modal, "Desbloqueaste la moneda «%s»:\n%s\nEn las próximas partidas de este progreso puede aparecer en la tienda." % [gift.name, gift.description], Vector2(36, 205), 19, cream, 566)
	if profile_message != "": label(modal, profile_message, Vector2(36, 345), 16, gold, 566)
	elif not profiles_enabled or profile_slot == 0: label(modal, "Sin progreso activo: el logro no se guardó.", Vector2(36, 345), 16, gold, 566)
	button(modal, "Nueva partida", Rect2(36, 395, 566, 49), new_run_from_result, false, true).name = "TutorialEndNew"
	button(modal, "Volver al menú", Rect2(36, 457, 566, 40), func(): request_navigation("menu"))

func render_repairs() -> void:
	var modal := panel(ui, Rect2(350, 160, 740, 580), Color("263c3d"), gold)
	label(modal, "REPARAR CARCASAS", Vector2(30, 24), 30, gold)
	# Las monedas de reparación usables van en fila, una al lado de la otra.
	var repair_slots: Array = []
	for slot in range(game.coin_inventory.consumables.size()):
		var stored: Dictionary = game.coin_inventory.consumables[slot]
		var is_free_one: bool = Coins.effects(stored.coin_id)[0].kind == "use_repair_free"
		if Coins.can_use(stored.coin_id, "repair") and not (is_free_one and game.repair_resolution.get("free_one", false)):
			repair_slots.append(slot)
	var button_width := 280.0 if repair_slots.size() <= 1 else 160.0
	for i in range(repair_slots.size()):
		var slot_index: int = repair_slots[i]
		var use_button := button(modal, ("Usar " if repair_slots.size() <= 1 else "") + Coins.definition(game.coin_inventory.consumables[slot_index].coin_id).name, Rect2(710 - button_width * (repair_slots.size() - i) - 8.0 * (repair_slots.size() - i - 1), 18, button_width, 40), func(): act(func(): game.use_consumable(slot_index)))
		use_button.name = "UseRepairCoin"
		if repair_slots.size() > 1: use_button.add_theme_font_size_override("font_size", 14)
	label(modal, "Ya cobraste $%d · Saldo: %s\nElegí cuáles reparar o continuá sin reparar." % [game.payout.total, money_text(game.cash)], Vector2(30, 78), 21, cream, 680)
	var y := 150.0
	for id in game.repair_resolution.available_ids:
		var shell := Gems.definition(game.dice[id].shell)
		var die_id: int = id
		var choice := CheckBox.new()
		choice.position = Vector2(30, y)
		choice.size = Vector2(675, 36)
		choice.text = "Dado %d · %s · $%d" % [id + 1, shell.name, Gems.repair_quote(game.dice, [id], {"half": CoinEffects.gem_rule(game.passives, "repair_half")}).cost]
		choice.button_pressed = id in repair_selection
		choice.toggled.connect(func(pressed: bool):
			if pressed: repair_selection.append(die_id)
			else: repair_selection.erase(die_id)
			render())
		modal.add_child(choice)
		y += 40
	var quote: Dictionary = game.repair_quote(repair_selection)
	label(modal, "Costo total: $%d · Saldo después: %s\nPodés reparar aunque el saldo quede en deuda." % [quote.cost, money_text(game.cash - quote.cost)], Vector2(30, 362), 21, cream, 680)
	button(modal, "Reparar selección · $%d" % quote.cost, Rect2(30, 445, 680, 46), func(): act(func(): game.resolve_repairs(repair_selection)), repair_selection.is_empty(), true)
	button(modal, "Continuar sin reparar", Rect2(30, 507, 680, 43), func(): act(func(): game.resolve_repairs([])))


## La mano (o el triángulo de Dios) del fondo abre el poder del jefe. Mismo patrón que el termo: botón transparente.
## Clic en la mano del fondo: cada jefe hace su animación. Los guardianes de Dios hacen la suya y al terminar muestran
## su información (sin movimiento, la muestran enseguida). El poder del jefe se lee en la libreta y al pasar el mouse.
func click_hand() -> void:
	if game.is_seed():
		inspect_boss_hand()
		return
	if not (BossInfo.is_god(game) and game.is_boss()):
		background.props.play_hand(background.hand_boss)
		return
	if background.props.busy("guardian"): return
	if background.guardian < 0 or not background.props.play("guardian"):
		inspect_boss_hand()
		return
	var shown = game
	while is_instance_valid(background) and background.props.busy("guardian"): await get_tree().process_frame
	if game == shown and not detail.visible and not confirmation.visible: inspect_boss_hand()

func render_boss_hand() -> void:
	var info := BossInfo.panel(game)
	var guardian_hand: bool = BossInfo.is_god(game) and game.is_boss()
	var hand_rect: Rect2 = Backdrop.GOD_RECT if guardian_hand else Backdrop.HAND_RECT
	if game.is_seed(): hand_rect = SeedDisplay.final_box(str(game.run_seed).length())
	var hand_button := button(ui, "", hand_rect, click_hand)
	hand_button.name = "InspectBoss"
	hand_button.tooltip_text = "" if info.is_empty() else info.alt
	if not guardian_hand:
		if background.hand_boss != "": BarProps.attach_hand_ring(hand_button, background.hand_boss, background.props)
		else: BarProps.attach_ring(hand_button, "hand", background.props)
	hand_button.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "pressed"]: hand_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	# Resalte mínimo al pasar el mouse; el foco de teclado conserva el contorno del tema.
	hand_button.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.07)))

func inspect_boss_hand() -> void:
	var info := BossInfo.panel(game)
	if info.is_empty(): return
	present_detail(info.title, info.text, true)


# ---------------------------------------------------------------- La Semilla

## La semilla en la mesa: chica arriba a la izquierda durante toda la jugada; en el encuentro contra La Semilla, la terminal
## (que viaja desde la chica mientras dura la animación «travel»). El tutorial no la muestra.
func render_seed() -> void:
	if game.tutorial or not session_started: return
	seed_display = SeedDisplay.new()
	seed_display.name = "SeedDisplay"
	ui.add_child(seed_display)
	if game.is_seed() and finale_anim not in ["death", "collapse"]:
		seed_display.top_level = true # en la victoria se apaga en su lugar, no cae con la mesa
		seed_display.setup(game.run_seed, "terminal", finale_anim == "travel", preferences)
		seed_display.intro_finished.connect(_on_seed_intro_finished)
	else: seed_display.setup(game.run_seed, "small", false, preferences)

func finale_motion() -> bool:
	return not preferences.reduced_motion and preferences.speed != 0

## Arranca las animaciones del final cuando la jugada entra en una etapa nueva (nunca al continuar una partida).
func _update_finale(profile: Dictionary) -> void:
	var stage: String = profile.get("finale", "")
	if stage == finale_shown: return
	var previous := finale_shown
	finale_shown = stage
	if not finale_motion() or not session_started:
		finale_anim = ""
		if stage == "ending" and session_started: showing_credits = true
		return
	# El guardián sigue vivo (con el bar crujiendo) mientras está la mano con el maletín; muere al salir de la tienda,
	# justo antes del derrumbe.
	if stage == "matrix" and previous != "matrix":
		finale_anim = "death"
		background.play_finale("death")
	elif stage == "ending":
		# Victoria: tiembla todo, la mesa cae, la semilla y la Matrix se apagan; después, solos, los créditos.
		finale_anim = "ending"
		background.play_finale("ending")

func _on_finale_finished(anim: String) -> void:
	if anim != finale_anim: return
	if anim == "death":
		finale_anim = "collapse"
		background.play_finale("collapse")
	elif anim == "ending":
		finale_anim = ""
		showing_credits = true
	else: finale_anim = "travel" if anim == "collapse" else ""
	render()

func _on_seed_intro_finished() -> void:
	if finale_anim != "travel": return
	finale_anim = ""
	mark_finale_seen()
	render()

## Mientras corre la animación no se puede tocar la mesa. Desde la segunda vez (en esta partida guardada) se puede omitir.
func render_finale_blocker() -> void:
	var blocker := Control.new()
	blocker.name = "FinaleBlocker"
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 95
	blocker.top_level = true # no cae con la mesa en la victoria
	blocker.position = Vector2.ZERO
	blocker.size = Vector2(1440, 900)
	ui.add_child(blocker)
	# La muerte de La Semilla (victoria) no se puede omitir.
	if finale_seen() and finale_anim != "ending":
		var skip := button(blocker, "Omitir animación", Rect2(570, 600, 300, 44), skip_finale)
		skip.name = "SkipFinale"

func skip_finale() -> void:
	background.finale.stop()
	finale_anim = ""
	render()

## Ya se vio el final entero alguna vez: en la partida guardada activa o, sin partida, en esta sesión.
func finale_seen() -> bool:
	if finale_seen_session: return true
	if not profiles_enabled or profile_slot == 0: return false
	var found: Dictionary = profile_store.read(profile_slot)
	return found.ok and bool(found.data.get(ProfileStore.SEED_FINALE_KEY, false))

func mark_finale_seen() -> void:
	finale_seen_session = true
	if profiles_enabled and profile_slot != 0 and not game.debug_mode: profile_store.mark_seed_finale_seen(profile_slot)

func show_credits() -> void:
	showing_credits = true
	render()

## Victoria: la interfaz de la mesa (libreta, botones, bandeja) tiembla y cae con la mesa; la semilla se apaga.
## Mismos tiempos que `SeedFinale` (cuadros de 90 ms): tiembla hasta el 22, cae desde el 12 y se apaga del 22 al 38.
func _animate_ending_ui() -> void:
	var fall := ui.create_tween()
	for i in 12:
		var dx := float((i * 7) % 7 - 3) * 2.0
		var dy := float((i * 5) % 7 - 3) * 2.0
		fall.tween_property(ui, "position", Vector2(dx, dy), 0.09)
	fall.tween_property(ui, "position", Vector2(0, 900), 1.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Los números de la semilla se apagan parpadeando: cada vez prenden menos y quedan apagados más tiempo.
	if is_instance_valid(seed_display):
		var blink := seed_display.create_tween()
		blink.tween_interval(20 * 0.09)
		for step in [[0.08, 0.30], [0.10, 0.22], [0.14, 0.16], [0.18, 0.10], [0.24, 0.07], [0.30, 0.04]]:
			blink.tween_property(seed_display, "modulate:a", 0.0, 0.0)
			blink.tween_interval(step[0])
			blink.tween_property(seed_display, "modulate:a", 1.0, 0.0)
			blink.tween_interval(step[1])
		blink.tween_property(seed_display, "modulate:a", 0.0, 0.0)

## Créditos provisionales: el contenido se arma más adelante (docs/LA-SEMILLA.md).
const CREDITS := ["DIOS NO JUEGA A LOS DADOS", "", "Créditos provisionales", "", "Se completan más adelante.", "", "Gracias por jugar."]

## Créditos después de vencer a La Semilla (aparecen solos); después, las recompensas y la vuelta al inicio.
func render_credits() -> void:
	if showing_rewards:
		render_rewards()
		return
	credits_token += 1
	var token := credits_token
	var backdrop := panel(ui, Rect2(0, 0, 1440, 900), Color.BLACK)
	backdrop.name = "Credits"
	var lines := VBoxContainer.new()
	lines.position = Vector2(320, 140)
	lines.size = Vector2(800, 560)
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	backdrop.add_child(lines)
	for i in CREDITS.size():
		var line := Label.new()
		line.text = CREDITS[i]
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 34 if i == 0 else 20)
		line.add_theme_color_override("font_color", Color("5cff6a") if i == 0 else cream)
		lines.add_child(line)
	var next := button(backdrop, "Continuar", Rect2(570, 760, 300, 50), show_rewards, false, true)
	next.name = "CreditsNext"
	next.grab_focus()
	# Si nadie toca nada, a los pocos segundos pasan solas las recompensas.
	if is_inside_tree(): get_tree().create_timer(CREDITS_SECONDS).timeout.connect(func():
		if showing_credits and not showing_rewards and token == credits_token: show_rewards())

const CREDITS_SECONDS := 8.0

func show_rewards() -> void:
	showing_rewards = true
	render()

## Recompensas por ganarle a La Semilla: mecánica posterior, todavía sin definir.
func render_rewards() -> void:
	var backdrop := panel(ui, Rect2(0, 0, 1440, 900), Color.BLACK)
	backdrop.name = "Rewards"
	var title := label(backdrop, "RECOMPENSAS", Vector2(320, 300), 34, Color("5cff6a"), 800)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := label(backdrop, "Las recompensas por ganarle a La Semilla todavía no están definidas.", Vector2(320, 380), 20, cream, 800)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var back := button(backdrop, "Volver al inicio", Rect2(570, 760, 300, 50), back_to_start, false, true)
	back.name = "CreditsBack"
	back.grab_focus()

func back_to_start() -> void:
	showing_credits = false
	showing_rewards = false
	selected.clear()
	repair_selection.clear()
	purchase_error = ""
	game.return_to_menu()
	session_started = false
	render()
