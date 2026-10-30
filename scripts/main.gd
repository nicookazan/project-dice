extends Control
const Game = preload("res://scripts/game.gd")
const Rules = preload("res://scripts/rules.gd")
const Die = preload("res://scripts/die.gd")
const Zone = preload("res://scripts/drop_zone.gd")
const Backdrop = preload("res://scripts/backdrop.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const ShopArt = preload("res://scripts/shop_art.gd")
const ItemTooltip = preload("res://scripts/item_tooltip.gd")
const HoverButton = preload("res://scripts/hover_button.gd")
const HoverPanel = preload("res://scripts/hover_panel.gd")
const Materials = preload("res://scripts/materials.gd")
const Elements = preload("res://scripts/elements.gd")
const Gems = preload("res://scripts/gems.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Coins = preload("res://scripts/coins.gd")
const Purchases = preload("res://scripts/purchases.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const ValidationProfile = preload("res://scripts/validation_profile.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const Preferences = preload("res://scripts/presentation_preferences.gd")
const Presentation = preload("res://scripts/presentation_state.gd")
const PresentationAudio = preload("res://scripts/presentation_audio.gd")
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
var persistence_enabled := true
var save_store = SaveStore.new()
var save_status: Dictionary = {}
var last_checkpoint: Dictionary = {}
var save_error := ""
var session_started := false
var game = Game.new()
var selected: Array = []
var repair_selection: Array = []
var shop_section := "coins"
var purchase_error := ""
var pack_panel_open := true
var sticker_animation: Control
var ui: Control
var coin_sale_overlay
var coin_sale_caption: Label
var hover_description: PanelContainer
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
var throwing := false
var flying_dice: Array = []
var table_dice: Dictionary = {}
var throw_blocker: Control

func _ready() -> void:
	if preferences_enabled: preferences = preference_store.load_values()
	audio = PresentationAudio.new()
	add_child(audio)
	if validation_profile: save_store = SaveStore.new(ValidationProfile.SAVE_PATH)
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
	theme = theme_value
	background = Backdrop.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	detail = AcceptDialog.new()
	detail.exclusive = true
	detail.title = "Libreta · detalle de cálculo"
	detail.min_size = Vector2i(520, 260)
	add_child(detail)
	detail_body = RichTextLabel.new()
	detail_body.name = "DetailText"
	detail_body.selection_enabled = true
	detail_body.bbcode_enabled = false
	detail_body.focus_mode = Control.FOCUS_ALL
	detail.add_child(detail_body)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Abandonar partida"
	confirmation.exclusive = true
	confirmation.ok_button_text = "Abandonar"
	confirmation.cancel_button_text = "Seguir jugando"
	confirmation.confirmed.connect(confirm_navigation)
	confirmation.canceled.connect(cancel_navigation)
	confirmation.get_cancel_button().pressed.connect(cancel_navigation)
	add_child(confirmation)
	get_tree().auto_accept_quit = false
	game.phase = "menu"
	refresh_save_status()
	render()
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://test-results")
		get_viewport().get_texture().get_image().save_png("res://test-results/mesa.png")
		get_tree().quit()

func present_detail(title: String, text: String, compact := false) -> void:
	if is_instance_valid(settings_panel): settings_panel.hide()
	if is_instance_valid(dice_gallery): dice_gallery.hide()
	detail_body.show()
	detail.title = title
	detail_text = text
	detail.dialog_text = "" # RichTextLabel owns the text; the built-in label must not enlarge the dialog.
	detail.get_label().hide()
	detail_body.text = text
	detail_body.custom_minimum_size = Vector2(500, 180) if compact else Vector2(760, 460)
	detail_body.scroll_to_line(0)
	detail.popup_centered(Vector2i(540, 270) if compact else Vector2i(820, 560))

func toggle_die(index: int) -> void:
	if throwing: return
	if preferences.drag_groups: return
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
	if not event is InputEventKey or not event.pressed or event.echo or detail.visible or confirmation.visible: return
	if event.keycode == KEY_F1:
		show_help()
	elif event.keycode == KEY_M and game.phase not in ["menu", "level_intro"]:
		show_route()
	elif game.phase == "purchase_target" and event.keycode == KEY_ESCAPE:
		act(game.cancel_purchase)
	elif game.phase == "play":
		if event.keycode >= KEY_1 and event.keycode <= KEY_5: toggle_die(int(event.keycode - KEY_1))
		elif event.keycode == KEY_SPACE: act(game.roll)
		elif event.keycode == KEY_G and selection_preview().valid: act(func(): game.form_group(selected))
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
	var values: Array = []
	for id in selected:
		if not id is int or id < 0 or id >= game.dice.size() or game.is_grouped(id) or game.dice[id].zone != "reserve": return {"valid": false, "text": "Selección: reservá los dados antes de agrupar."}
		values.append(game.dice[id].value)
	var category: String = Rules.category(values)
	if BossRules.forbidden(game.boss_context(), category): return {"valid": false, "text": "Selección: el jefe prohíbe generala; podés armar trío + par."}
	if category.is_empty(): return {"valid": false, "text": "Selección: %d dado(s) · sin combinación válida" % selected.size()}
	var groups: Array = game.groups.duplicate(true)
	groups.append({"category": category, "ids": selected.duplicate()})
	var score := Rules.score(game.dice, groups, game.passives, game.boost, game.rolls_made == 1, game.global_points, game.cup.stickers, game.sticker_catalog, game.boss_context())
	if score.valid:
		var row: Dictionary = score.rows[game.groups.size()]
		return {"valid": true, "text": "Selección: %s · %s puntos · G para agrupar" % [category, number(row.total)], "row": row}
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
	var shell := Gems.definition(die.shell)
	lines.append("Material de los puntos: " + shell.get("name", "Negro base") + (" · gema RESQUEBRAJADA (R), poder suspendido" if die.shell_broken else " · intacta" if not shell.is_empty() else ""))
	if not shell.is_empty(): lines.append("%s Riesgo: %d%% al puntuar en combinación; reparación $%d." % [shell.description, int(shell.break_risk * 100), shell.repair_cost])
	var element := Elements.definition(die.element)
	lines.append("Elemento: " + element.get("name", "Sin elemento"))
	if not element.is_empty(): lines.append(element.condition)
	lines.append("\nAcumulación de encuentro: acero +%s puntos; cobre +%s al multiplicador." % [number(Materials.steel_points(die)), number(Materials.copper_multiplier(die))])
	lines.append("Acumulación de mano: tierra +%s puntos; viento +%s al multiplicador." % [number(Elements.earth_points(die)), number(Elements.wind_multiplier(die))])
	lines.append("Acero/cobre duran el encuentro; tierra/viento se reinician cada mano.")
	present_detail("Dado %d · ficha" % [id + 1], "\n".join(lines))

func die_hover_text(id: int) -> String:
	var die: Dictionary = game.dice[id]
	var lines: Array[String] = ["Caras: " + " · ".join(die.faces.map(func(face): return str(face)))]
	if die.value > 0:
		lines.append("Número: %d · Puntos: %s" % [die.value, number(die.value + game.global_points.get(str(die.value), 0))])
	if not game.global_points.is_empty(): lines.append("Todos tus dados: " + point_upgrades(game.global_points))
	if die.material in ["steel", "copper"]:
		var material_text := shop_offer_text({"kind": "material", "effect": {"id": die.material}})
		lines.append(material_text[0] + ": " + material_text[1])
		lines.append("Acumulado: +%s %s." % [number(Materials.steel_points(die) if die.material == "steel" else Materials.copper_multiplier(die)), "puntos" if die.material == "steel" else "al multiplicador"])
	var gem := Gems.definition(die.shell)
	if not gem.is_empty():
		lines.append(gem.name + ": " + ("Resquebrajada: poder suspendido." if die.shell_broken else gem.description) + " Requiere combinación desde par.")
		lines.append("Rotura: %d%% · Reparación: $%d" % [int(gem.break_risk * 100), gem.repair_cost])
	var element := Elements.definition(die.element)
	if not element.is_empty():
		lines.append(element.name + ": " + element.condition + " Permanece durante la partida; no se gasta.")
		if die.element == "earth": lines.append("Esta mano: +%s puntos. Se reinicia cada mano y al relanzarlo." % number(Elements.earth_points(die)))
		elif die.element == "wind": lines.append("Esta mano: +%s al multiplicador. Se reinicia cada mano." % number(Elements.wind_multiplier(die)))
	for family in ["material", "shell", "element"]:
		if BossRules.suspended(game.boss_context(), family, die[family]): lines.append("%s: suspendido por el jefe." % family)
	return "\n\n".join(lines)

func point_upgrades(points: Dictionary) -> String:
	var entries: Array[String] = []
	for n in range(1, 7):
		if points.has(str(n)): entries.append("%d → +%d" % [n, points[str(n)]])
	return "; ".join(entries) if not entries.is_empty() else "ninguna"

func inspect_cup() -> void:
	present_detail("Vaso de cuero", "Cinco dados fijos; el vaso no modifica su cantidad.\nLos stickers están pegados al termo del mate. Tocá el termo para ver sus niveles y efectos.", true)

func inspect_thermos() -> void:
	var lines: Array[String] = ["Termo del mate", "Stickers pegados al termo:"]
	if game.cup.stickers.is_empty(): lines.append("Sin stickers.")
	for id in game.cup.stickers:
		var level: int = game.cup.stickers[id]
		lines.append("%s · nivel %d" % [Stickers.NAMES.get(id, id), level])
		if Stickers.defined(id, game.sticker_catalog):
			var data: Dictionary = game.sticker_catalog[id]
			lines.append("+%s puntos de grupo y +%s al multiplicador de su categoría." % [number(data.points_per_level * level), number(data.multiplier_per_level * level)])
		else: lines.append("Efectos pendientes de definición.")
	present_detail("Termo y stickers", "\n".join(lines), true)

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
	node.add_theme_stylebox_override("normal", box(Color("0b3152") if accent else Color("101e30"), Color("d39a41"), 3))
	node.add_theme_stylebox_override("hover", box(Color("164e7c") if accent else Color("283d52"), Color("ffcc77"), 3))
	node.add_theme_stylebox_override("pressed", box(Color("631b2a"), gold, 3))
	node.add_theme_stylebox_override("disabled", box(Color("222129"), Color("775c39"), 2))
	node.add_theme_color_override("font_color", cream)
	node.add_theme_color_override("font_disabled_color", Color("85867b"))
	if preferences.high_contrast:
		node.add_theme_stylebox_override("normal", box(Color("080b10"), Color.WHITE, 3))
		node.add_theme_stylebox_override("disabled", box(Color("252525"), Color("b0b0b0"), 2))
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_color_override("font_disabled_color", Color("bdbdbd"))
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, Color.WHITE, 3))
	if is_instance_valid(background) and background.shop_mode: skin_shop_button(node)
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
	render()
	if game.event_sequence > previous_event and not game.events.is_empty():
		var event: Dictionary = game.events.back()
		if event.type in [Game.INITIAL_ROLL, Game.REROLL]: begin_throw(event.payload.rolled_ids)

func begin_throw(ids: Array) -> void:
	if preferences.speed == 0 or preferences.reduced_motion: return
	throwing = true
	throw_elapsed = 0.0
	throw_duration = 0.48 if preferences.speed == 2 else 0.85
	feedback_text = "Tirando…"
	if is_instance_valid(feedback_label): feedback_label.text = feedback_text
	for index in ids:
		if not table_dice.has(index): continue
		var die: Control = table_dice[index]
		var landing := die.position
		var origin: Vector2 = Backdrop.CUP_MOUTH - die.get_parent().position - die.size / 2.0
		flying_dice.append({"node": die, "origin": origin, "landing": landing, "angle": die.rotation_degrees, "delay": flying_dice.size() * 0.035})
		die.z_index = 20
	throw_blocker = Control.new()
	throw_blocker.name = "ThrowInputBlocker"
	throw_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	throw_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	throw_blocker.z_index = 30
	ui.add_child(throw_blocker)
	step_throw(0.0)

func step_throw(delta: float) -> void:
	if not throwing: return
	throw_elapsed += delta
	for flight in flying_dice:
		var die: Control = flight.node
		var t := clampf((throw_elapsed / throw_duration - flight.delay) / 0.82, 0.0, 1.0)
		var travel := 1.0 - pow(1.0 - t, 2.0)
		var height := sin(PI * minf(t / 0.72, 1.0)) * 115.0
		if t > 0.72: height = absf(sin((t - 0.72) / 0.28 * TAU)) * 16.0 * (1.0 - t) / 0.28
		die.position = flight.origin.lerp(flight.landing, travel) - Vector2(0, height)
		die.rotation_degrees = flight.angle + (1.0 - travel) * (540 if die.die_index % 2 == 0 else -540)
		die.scale = Vector2.ONE * (0.65 + 0.35 * minf(t * 4.0, 1.0))
		die.modulate.a = minf(t * 12.0, 1.0)
	if throw_elapsed >= throw_duration:
		finish_throw()
		feedback_text = "Tirada resuelta · elegí tus grupos"
		if is_instance_valid(feedback_label): feedback_label.text = feedback_text

func finish_throw() -> void:
	for flight in flying_dice:
		if not is_instance_valid(flight.node): continue
		flight.node.position = flight.landing
		flight.node.rotation_degrees = flight.angle
		flight.node.scale = Vector2.ONE
		flight.node.modulate.a = 1.0
		flight.node.z_index = 0
	flying_dice.clear()
	throwing = false
	if is_instance_valid(throw_blocker):
		throw_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		throw_blocker.queue_free()

func start_new_run(seed_value: int = -1, debug_run := false) -> void:
	presentation.observed.clear()
	feedback_remaining = 0
	selected.clear()
	repair_selection.clear()
	purchase_error = ""
	pack_panel_open = true
	if campaign_mode: game.begin_campaign(seed_value)
	else: game.begin_run(seed_value)
	if validation_profile or campaign_mode: ValidationProfile.apply(game)
	game.debug_mode = debug_run
	session_started = true
	if persistence_enabled:
		var result: Dictionary = save_store.start(checkpoint_data())
		save_error = "" if result.ok else result.message
		if not result.ok:
			game.phase = "menu"
			session_started = false
		else: last_checkpoint = checkpoint_data()
	refresh_save_status()
	render()

func checkpoint_data() -> Dictionary:
	return {"game": game.snapshot(), "ui": {"selected": selected.duplicate(), "repair_selection": repair_selection.duplicate(), "shop_section": shop_section, "pack_panel_open": pack_panel_open}}

func refresh_save_status() -> void:
	save_status = save_store.inspect() if persistence_enabled else {"ok": false, "active": false, "code": "missing", "message": ""}

func checkpoint() -> bool:
	if not persistence_enabled or not session_started or game.phase == "menu": return true
	var data := checkpoint_data()
	var comparable: Dictionary = data.duplicate(true)
	comparable.game.erase("message")
	var previous: Dictionary = last_checkpoint.duplicate(true)
	if not previous.is_empty(): previous.game.erase("message")
	if comparable == previous: return save_error == ""
	var result: Dictionary = save_store.close_session() if game.phase in ["won", "lost"] else save_store.save(data)
	save_error = "" if result.ok else result.message
	if result.ok: last_checkpoint = data
	refresh_save_status()
	return result.ok

func continue_saved() -> void:
	refresh_save_status()
	if not save_status.get("active", false): return
	var loaded: Dictionary = save_store.recover() if save_status.code == "backup" else save_status
	if not loaded.ok:
		save_error = loaded.message
		render()
		return
	var restored = save_store.restore_game(loaded.data)
	if restored == null:
		save_error = "No se pudo reanudar la partida. El archivo se conserva."
		return
	game = restored
	presentation.observed.clear()
	feedback_remaining = 0
	campaign_mode = not game.campaign.is_empty()
	selected = loaded.data.ui.selected.duplicate()
	repair_selection = loaded.data.ui.repair_selection.duplicate()
	shop_section = loaded.data.ui.shop_section
	pack_panel_open = loaded.data.ui.pack_panel_open
	last_checkpoint = loaded.data.duplicate(true)
	save_error = ""
	purchase_error = ""
	session_started = true
	render()

func request_navigation(destination: String) -> void:
	if destination not in ["menu", "new", "new_debug", "quit", "pause"]: return
	refresh_save_status()
	var new_run: bool = destination in ["new", "new_debug"]
	var replacing: bool = new_run and (save_status.get("active", false) or (save_status.code not in ["missing", "closed", "valid"]))
	if destination == "pause" or (game.phase in ["menu", "won", "lost"] and not replacing):
		pending_navigation = destination
		confirm_navigation()
		return
	pending_navigation = destination
	confirmation.title = "Guardar y salir" if destination == "quit" else ("Nueva partida debug" if destination == "new_debug" else "Nueva partida" if new_run else "Abandonar partida")
	confirmation.ok_button_text = "Guardar y salir" if destination == "quit" else ("Nueva partida" if new_run else "Abandonar")
	confirmation.dialog_text = "Se guardará la partida antes de salir. Podrás usar Continuar." if destination == "quit" else ("Vas a reemplazar la partida anterior por una nueva desde cero.\nLos archivos anteriores se conservarán como respaldo histórico." if new_run else "Esta partida ya no estará disponible en Continuar.\nPara volver al menú conservándola, cancelá y usá el botón Menú.")
	confirmation.popup_centered(Vector2i(620, 220))

func confirm_navigation() -> void:
	var destination := pending_navigation
	pending_navigation = ""
	confirmation.hide()
	if destination == "quit":
		if checkpoint(): get_tree().quit()
		else: present_detail("No se pudo guardar", save_error + "\nLa partida sigue abierta. Podés intentar guardar de nuevo.", true)
	elif destination == "new": start_new_run()
	elif destination == "new_debug": start_new_run(-1, true)
	elif destination in ["menu", "pause"]:
		if destination == "pause" and not checkpoint():
			present_detail("No se pudo guardar", save_error + "\nLa partida sigue abierta.", true)
			return
		if destination == "menu" and persistence_enabled and session_started:
			var result: Dictionary = save_store.close_session()
			if not result.ok:
				present_detail("No se pudo cerrar la partida", result.message, true)
				return
		selected.clear()
		repair_selection.clear()
		purchase_error = ""
		game.return_to_menu()
		session_started = false
		refresh_save_status()
		render()

func cancel_navigation() -> void:
	pending_navigation = ""
	confirmation.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(confirmation):
		if detail.visible: detail.hide()
		request_navigation("quit")

func route_text() -> String:
	if not game.campaign.is_empty():
		var lines: Array[String] = ["CAMPAÑA DE PRUEBA · %d / 21 encuentros superados" % game.completed_encounters.size(), "Objetivos fijos, catálogo provisional. Solo se avanza al siguiente encuentro.", ""]
		for stop in game.campaign_route():
			lines.append("Nivel %d · %s · %s · %s" % [stop.level, stop.name, str(stop.target) + " puntos" if stop.target > 0 else "objetivo del jefe por anunciar", stop.status])
			if stop.position == 3: lines.append("  " + stop.rule)
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
	settings_panel.custom_minimum_size = Vector2(760, 555)
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
	var keys := ["reduced_motion", "reduced_flashes", "high_contrast", "drag_groups"]
	var captions := ["Reducir movimiento", "Reducir destellos", "Mayor contraste en controles", "Armar grupos arrastrando"]
	for i in range(4):
		var toggle := CheckButton.new()
		toggle.name = keys[i]
		toggle.text = captions[i]
		toggle.position = Vector2(12, 295 + i * 42)
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
	label(settings_panel, "Las señales siempre incluyen texto. Ninguna opción cambia la partida.\n" + detail_text, Vector2(12, 435), 17, cream, 725)
	var status := label(settings_panel, preference_store.last_error if preference_store.last_error != "" else "Opciones guardadas aparte de la partida.", Vector2(12, 522), 16, gold, 725)
	status.name = "PreferenceStatus"
	detail.popup_centered(Vector2i(820, 650))

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
	sheet.custom_minimum_size = Vector2(1080, 850)
	scroll.add_child(sheet)
	var variants := [["ACERO", "steel", "", ""], ["COBRE", "copper", "", ""], ["FUEGO", "basic", "fire", ""], ["AGUA", "basic", "water", ""], ["ELECTRICIDAD", "basic", "electricity", ""], ["TIERRA", "basic", "earth", ""], ["VIENTO", "basic", "wind", ""], ["COMBINADO", "steel", "electricity", "diamond"]]
	for row in range(variants.size()):
		var variant: Array = variants[row]
		label(sheet, variant[0], Vector2(12, 42 + row * 103), 17, cream, 180)
		for value in range(1, 7):
			var die := Die.new()
			die.value = value
			die.body_material = variant[1]
			die.element = variant[2]
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

func _process(delta: float) -> void:
	step_throw(delta)
	update_hover_description()
	feedback_remaining = maxf(0, feedback_remaining - delta * (2 if preferences.speed == 2 else 1))
	if is_instance_valid(feedback_label):
		feedback_label.visible = feedback_remaining > 0
		# Reduced motion/instant mode retains static, readable text without a fade.
		feedback_label.modulate.a = 1.0 if preferences.reduced_motion or preferences.reduced_flashes or preferences.speed == 0 else minf(1, feedback_remaining)

func update_hover_description() -> void:
	if not is_instance_valid(hover_description): return
	var hovered := get_viewport().gui_get_hovered_control()
	var text := ""
	if hovered != null and hovered is Control and not get_viewport().gui_is_dragging() and not detail.visible and not confirmation.visible and game.phase not in ["purchase_target", "sticker_choice"]:
		text = hovered.tooltip_text.strip_edges()
	var hinted_ids: Array = []
	if hovered != null and hovered.get_script() == Die and not text.is_empty() and game.phase == "play":
		for combination in possible_combinations(hovered.die_index):
			for id in combination.ids:
				if id not in hinted_ids: hinted_ids.append(id)
	for id in table_dice:
		var die = table_dice[id]
		var hinted: bool = id in hinted_ids
		if is_instance_valid(die) and die.combo_hint != hinted:
			die.combo_hint = hinted
			die.queue_redraw()
	hover_description.visible = not text.is_empty()
	if text.is_empty(): return
	if hover_description_body.text != text:
		hover_description_body.text = text
		hover_description_body.add_theme_font_size_override("font_size", 16 if text.length() > 650 else 18)
		hover_description.reset_size()

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
	var card := panel(ui, Rect2(300, 125, 840, 650), Color("0d1728"), gold)
	label(card, "DIOS NO JUEGA A LOS DADOS", Vector2(40, 30), 34, gold, 760)
	if campaign_mode: label(card, "CAMPAÑA PROVISIONAL v1 · objetivos, jefes y balance de prueba", Vector2(40, 77), 17, gold, 760)
	elif validation_profile: label(card, "DATOS DE PRUEBA v1 · balance provisional · guardado separado", Vector2(40, 77), 17, gold, 760)
	if game.phase == "menu":
		label(card, "Siete niveles · 21 encuentros · hasta Dios" if campaign_mode else "Un nivel de prueba · dos rivales y un jefe", Vector2(40, 112), 24, cream, 760)
		label(card, "Cuero, cinco dados y $0 para empezar.\nSin tienda inicial. El jefe se anuncia al entrar a cada nivel.\nGuardado automático después de cada decisión.", Vector2(40, 176), 22, cream, 760)
		label(card, save_error if save_error != "" else save_status.get("message", ""), Vector2(40, 277), 17, gold, 760)
		button(card, "Nueva partida", Rect2(150, 350, 540, 55), func(): request_navigation("new"), false, true)
		var debug_button := button(card, "Nueva partida debug", Rect2(150, 415, 540, 45), func(): request_navigation("new_debug"))
		debug_button.tooltip_text = "Daño infinito y plata infinita. Tirar y anotar una mano alcanza para vencer al rival. Compras, renovación y reparaciones sin límite de plata."
		if save_status.get("active", false): button(card, "Continuar" if save_status.code != "backup" else "Recuperar respaldo y continuar", Rect2(150, 475, 540, 45), continue_saved, false, true)
		button(card, "Opciones", Rect2(150, 530, 540, 40), show_options)
		button(card, "Salir", Rect2(150, 585, 540, 40), func(): request_navigation("quit"))
		button(ui, "Ver diseños de dados", Rect2(500, 800, 440, 45), show_dice_gallery)
	else:
		if game.debug_mode: label(card, "DEBUG · DAÑO ∞ · PLATA ∞", Vector2(40, 143), 17, gold, 760)
		label(card, "NIVEL %d / 7 · %s" % [game.level_index + 1, "DIOS" if game.level_index == 6 else game.environment_id().to_upper()] if not game.campaign.is_empty() else "NIVEL 1 · CLUB DE BARRIO", Vector2(40, 105), 27, cream, 760)
		var stops: Array = game.route().map(func(stop): return "%s: %d puntos" % [stop.name, stop.target])
		label(card, "  →  ".join(stops) + "\n\n" + game.boss_name() + " · " + game.boss_rule.name.to_upper() + "\n" + BossRules.description(game.boss_rule) + "\n\nDos manos por encuentro y tres tiradas por mano.\nTras ganar: cobro, reparación opcional y tienda.", Vector2(40, 175), 22, cream, 760)
		button(card, "Empezar primer encuentro", Rect2(150, 490, 540, 55), func(): act(game.begin_level), false, true)
		button(card, "Volver al menú", Rect2(150, 565, 540, 45), func(): request_navigation("pause"))

func render() -> void:
	sticker_animation = null
	if is_instance_valid(hover_description):
		hover_description.free()
	finish_throw()
	table_dice.clear()
	var profile := Presentation.profile(game)
	background.shop_mode = game.phase in ["shop", "purchase_target", "sticker_choice"]
	background.stickers = game.cup.stickers.duplicate()
	if is_instance_valid(background): background.configure(profile, preferences)
	if is_instance_valid(audio): audio.configure(preferences, profile.environment)
	var cue: Dictionary = presentation.observe(game)
	if not cue.is_empty(): signal_action(cue.sound, cue.text)
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	hover_description = PanelContainer.new()
	hover_description.name = "HoverDescription"
	hover_description.position = Vector2(30, 400)
	hover_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_description.add_theme_stylebox_override("panel", ItemTooltip.skin())
	hover_description_body = ItemTooltip.content("")
	hover_description_body.custom_minimum_size.x = 422
	hover_description.add_child(hover_description_body)
	hover_description.hide()
	# Draw above ordinary UI without becoming a mouse target.
	hover_description.z_index = 90
	ui.add_child(hover_description)
	if game.phase in ["menu", "level_intro"]:
		render_entry()
		checkpoint()
		return
	if game.phase != "sticker_choice": pack_panel_open = true
	if background.shop_mode:
		render_shop()
		finish_render()
		return
	button(ui, "Menú", Rect2(1220, 23, 185, 38), func(): request_navigation("pause"))
	button(ui, "Abandonar partida", Rect2(590, 23, 195, 38), func(): request_navigation("menu"))
	button(ui, "Recorrido · M", Rect2(1000, 23, 200, 38), show_route)
	button(ui, "Opciones", Rect2(800, 23, 180, 38), show_options)
	if game.phase not in ["shop", "purchase_target", "sticker_choice"]: shop_section = "coins"
	if game.phase != "sticker_choice": pack_panel_open = true
	render_notebook()
	render_table()
	render_inventory()
	render_actions()
	finish_render()

func finish_render() -> void:
	if game.debug_mode: label(ui, "DEBUG · DAÑO ∞ · PLATA ∞", Vector2(480, 114), 16, gold, 460)
	var thermos_button := button(ui, "", Backdrop.SHOP_THERMOS_RECT if background.shop_mode else Backdrop.THERMOS_RECT, inspect_thermos)
	thermos_button.name = "InspectThermos"
	thermos_button.tooltip_text = "Termo del mate · %d stickers · clic para ver niveles y efectos" % game.cup.stickers.size()
	for state in ["normal", "hover", "pressed"]: thermos_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if background.shop_mode: label(ui, purchase_error if not purchase_error.is_empty() else game.message, Vector2(38, 864), 17, cream, 1360)
	if game.phase != "repair": repair_selection.clear()
	if game.phase in ["reward", "won", "lost", "repair"]: render_result()
	elif game.phase == "purchase_target": render_purchase_target()
	elif game.phase == "sticker_choice":
		if pack_panel_open: render_pack_choice()
		else: button(ui, "Elegir sticker pendiente", Rect2(1045, 748, 355, 40), func():
			pack_panel_open = true
			render())
	checkpoint()
	if save_error != "":
		button(ui, "Error al guardar · reintentar", Rect2(590, 72, 390, 38), func():
			last_checkpoint = {}
			checkpoint()
			render())

func render_notebook() -> void:
	var note := panel(ui, Rect2(22, 25, 310, 630), Color("f3e6c7"), Color("856a47"))
	note.name = "PlayerNotebook"
	note.tooltip_text = "Semilla %d · %s" % [game.run_seed, "Campaña provisional" if not game.campaign.is_empty() else "Prototipo"]
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
	label(note, "PUNTOS / OBJETIVO", Vector2(28, 49), 14, ink)
	label(note, "%d / %d" % [game.points, game.target()], Vector2(28, 69), 32, ink)
	label(note, "Mano %d / 2" % game.hand, Vector2(28, 115), 18, ink)
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
	rule_text.text = BossRules.description(game.boss_rule)
	rule_text.tooltip_text = rule_text.text
	note.add_child(rule_text)
	label(note, "GRUPOS", Vector2(28, 304), 17, ink)
	var preview_value: Dictionary = game.preview() if game.phase == "play" else game.last_score
	if preview_value.is_empty(): preview_value = {"total": 0, "rows": [], "served": false}
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
	if preview_value.rows.is_empty(): label(entries, "Tirá los dados para empezar.", Vector2(4, 15), 14, ink, 240)
	label(note, "TOTAL DE MANO", Vector2(28, 464), 14, ink)
	label(note, number(preview_value.total), Vector2(215, 457), 28, final_ink)
	label(note, "Previsión" if game.phase == "play" else "Anotado", Vector2(28, 486), 12, final_ink)
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
	status.text = purchase_error if not purchase_error.is_empty() else game.message
	if game.boost: status.text += "\nImpulso activo: 1 y 3 +3 puntos."
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
		var material := "Acero" if source.get_slice(":", 1) == "steel" else "Cobre"
		return "%s · dado %d" % [material, source.get_slice(":", 2).to_int() + 1]
	if source.begins_with("number:global:"):
		return "Mejora global del " + source.get_slice(":", 2)
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

func handle_die_drop(index: int, destination: String) -> void:
	if throwing or detail.visible or confirmation.visible or game.phase != "play" or index < 0 or index >= game.dice.size() or game.is_grouped(index) or game.dice[index].value == 0: return
	if destination == "draft":
		if not preferences.drag_groups or game.dice[index].zone != "reserve": return
		if index not in selected: selected.append(index)
		render()
		return
	if destination not in ["reserve", "cup"]: return
	if game.move_die(index, destination):
		selected.erase(index)
		render()

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
		var category := Rules.category(values)
		if category.is_empty() or BossRules.forbidden(game.boss_context(), category): continue
		if not best.has(category): best[category] = {"category": category, "ids": ids, "values": values}
	return best.values()

func combination_hint_text(index: int) -> String:
	var lines: Array[String] = []
	for combination in possible_combinations(index):
		lines.append("%s: %s" % [combination.category, " + ".join(combination.values.map(func(value): return str(value)))])
	return "COMBINACIONES POSIBLES\n" + ("\n".join(lines) if not lines.is_empty() else "Sin combinación disponible con este dado.")

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
	var group_area := make_zone(Rect2(366, 324, 325, 330), "draft") if preferences.drag_groups else panel(ui, Rect2(366, 324, 325, 330), Color(0.12, 0.01, 0.035, 0.08))
	group_area.name = "GroupArea"
	var drag_toggle := CheckButton.new()
	drag_toggle.text = "Armar grupos arrastrando"
	drag_toggle.position = Vector2(370, 270)
	drag_toggle.size = Vector2(325, 38)
	drag_toggle.add_theme_font_size_override("font_size", 16)
	drag_toggle.button_pressed = preferences.drag_groups
	drag_toggle.toggled.connect(func(value): set_preference("drag_groups", value))
	ui.add_child(drag_toggle)
	if preferences.drag_groups:
		label(group_area, "Arrastrá los dados acá", Vector2(16, 12), 16, cream, 290)
		for slot in range(selected.size()):
			add_die(group_area, selected[slot], Vector2(8 + slot * 61, 255))
	var y := 58.0
	for group_index in range(game.groups.size()):
		var group: Dictionary = game.groups[group_index]
		var current_index := group_index
		label(group_area, group.category + (" · FIJO" if group.locked else " · EDITABLE"), Vector2(14, y), 15, cream)
		var x := 8.0
		for index in group.ids:
			add_die(group_area, index, Vector2(x, y + 27), true)
			x += 60
		if not group.locked and game.phase == "play":
			button(group_area, "Desarmar", Rect2(199, y - 4, 112, 29), func(): act(func(): game.ungroup(current_index)))
		y += 103
	var reserve := make_zone(Rect2(712, 324, 350, 330), "reserve")
	for index in range(game.dice.size()):
		if game.dice[index].zone == "reserve" and not game.is_grouped(index) and not (preferences.drag_groups and index in selected):
			var pose := loose_die_pose(index)
			add_die(reserve, index, pose.position, false, pose.angle)
	var cup := make_zone(Rect2(1082, 324, 312, 330), "cup")
	var cup_button := button(cup, "", Rect2(Backdrop.CUP_RECT.position - cup.position, Backdrop.CUP_RECT.size), inspect_cup)
	cup_button.name = "InspectCup"
	cup_button.tooltip_text = "Ver vaso"
	for state in ["normal", "hover", "pressed"]: cup_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

func add_die(parent: Node, index: int, pos: Vector2, grouped := false, angle := 0.0) -> void:
	var die := Die.new()
	die.configure_appearance(game.dice[index], game.boss_context())
	die.die_index = index
	die.chosen = index in selected
	die.locked = grouped or game.phase != "play"
	die.position = pos
	die.size = Vector2(62, 62)
	die.pivot_offset = die.size / 2.0
	die.rotation_degrees = angle
	die.sway_enabled = not preferences.reduced_motion and preferences.speed != 0
	die.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	die.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	die.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	die.inspect_requested.connect(inspect_die)
	die.pressed.connect(func(): toggle_die(index))
	parent.add_child(die)
	die.tooltip_text = combination_hint_text(index) + "\n\n" + die_hover_text(index) if not grouped and game.phase == "play" else die_hover_text(index)
	table_dice[index] = die

func render_actions() -> void:
	var playing: bool = game.phase == "play"
	var preview := selection_preview()
	button(ui, "Armar grupo", Rect2(375, 681, 210, 47), func(): act(func(): game.form_group(selected)), not playing or not preview.valid)
	button(ui, "Al vaso →", Rect2(597, 681, 157, 47), func(): move_selected("cup"), not playing or selected.is_empty() or game.rolls_left == 0)
	button(ui, "← Reservar", Rect2(766, 681, 157, 47), func(): move_selected("reserve"), not playing or selected.is_empty())
	button(ui, "Inspeccionar", Rect2(934, 681, 137, 47), func(): inspect_die(selected[0]), selected.size() != 1)
	button(ui, "TIRAR (%d)" % game.rolls_left, Rect2(1082, 681, 312, 47), func(): act(game.roll), not playing or game.rolls_left <= 0, true)
	button(ui, "ANOTAR MANO", Rect2(40, 681, 292, 47), func(): act(game.score_hand), not playing or game.rolls_made == 0, true)
	if game.phase == "hand_result":
		if game.points >= game.target():
			button(ui, "Cerrar y cobrar", Rect2(375, 626, 236, 42), func(): act(game.close_encounter), false, true)
		if game.hand < 2:
			button(ui, "Jugar segunda mano", Rect2(725, 626, 262, 42), func(): act(game.next_hand))
			if game.points >= game.target():
				label(ui, "Otra mano consume el premio de $2 por mano sobrante.", Vector2(375, 593), 16, cream, 690)

func move_selected(destination: String) -> void:
	if throwing: return
	var moved := false
	for index in selected:
		if game.dice[index].zone != destination and game.move_die(index, destination): moved = true
	if moved: signal_action("move", "Dados al vaso" if destination == "cup" else "Dados reservados")
	selected.clear()
	render()

func render_inventory() -> void:
	label(ui, "MONEDAS %d / %d" % [game.passives.size(), game.coin_inventory.shared_capacity], Vector2(42, 750), 14, gold)
	for i in range(game.passives.size()):
		var coin: String = game.passives[i]
		var b := button(ui, "", Rect2(175 + i * 90, 748, 64, 60), func(): inspect_coin(coin))
		b.name = "EquippedCoin_" + str(i)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		add_coin(b, coin, Rect2(1, 1, 58, 58))
		b.tooltip_text = Rules.COINS[coin].name + "\n" + Rules.COINS[coin].description
		if BossRules.suspended(game.boss_context(), "coin", coin):
			label(b, "SUSP", Vector2(1, 43), 11, gold)
			b.tooltip_text += " Suspendida por el jefe; conserva su espacio."
	label(ui, "UN USO", Vector2(922, 751), 13, gold)
	if game.consumable != "":
		var use := button(ui, "", Rect2(999, 748, 64, 60), func(): act(game.use_consumable), not Coins.can_use(game.consumable, game.phase) or BossRules.suspended(game.boss_context(), "coin", game.consumable))
		use.name = "ConsumableCoin"
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: use.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		use.tooltip_text = Rules.COINS[game.consumable].description + " Clic para consumir."
		add_coin(use, game.consumable, Rect2(1, 1, 58, 58))
		if BossRules.suspended(game.boss_context(), "coin", game.consumable):
			label(use, "SUSP", Vector2(1, 43), 11, gold)
			use.tooltip_text = "Suspendida por el jefe. No se consume y conserva su espacio."
	button(ui, "Ayuda", Rect2(1273, 748, 120, 60), show_help)

func add_coin(parent: Node, coin: String, rect: Rect2) -> void:
	var icon := CoinArt.new()
	icon.coin_id = coin
	icon.position = rect.position
	icon.size = rect.size
	parent.add_child(icon)

func inspect_coin(coin: String) -> void:
	var data := Coins.definition(coin)
	if data.is_empty(): return
	var duration: String = {"equipped": "Mientras está equipada", "hand": "Mano actual", "encounter": "Encuentro actual"}[data.duration]
	var context := "Pasiva al puntuar; no se consume." if data.type == "passive" else "Usar antes de anotar, incluso antes de tirar. No se usa en tienda."
	if BossRules.suspended(game.boss_context(), "coin", coin): context += "\nSUSPENDIDA POR JEFE: conserva su espacio; sin poder durante el encuentro."
	present_detail("Moneda · " + data.name, "%s\n\n%s · %s\nDuración: %s\n%s\nPrecio: $%d · Reventa: $%d" % [data.description, data.code, "Pasiva equipada" if data.type == "passive" else "Un uso", duration, context, data.price, data.resale], true)

func show_help() -> void:
	present_detail("Cómo jugar", "1. Tirás cinco dados; tres tiradas por mano y dos manos por rival.\n2. Seleccionás dados y armás grupos exactos. La selección muestra su categoría y puntos; no reparte dados automáticamente.\n3. Conservás sueltos o los enviás al vaso. Enviarlos fija los grupos; retirarlos no los desbloquea.\n4. Anotás grupos y sobrantes. Los sobrantes forman un único grupo sin combinación.\n\nDoble par: elegí 2-2-5-5; base 15 + caras 14 = 29, más los sobrantes. También podés formar dos pares separados.\nServida: anotar tras la primera tirada sin relanzar. Escaleras: 12345, 23456 y 34561.\nCon generala prohibida podés separar cinco iguales en trío + par. Consultá Recorrido para la regla de este nivel. Al alcanzar el objetivo podés cobrar o jugar otra mano disponible.\n\nSEL indica selección; FIJO indica grupo bloqueado. R y una grieta indican carcasa resquebrajada: solo suspende la gema.\nClic derecho en un dado para su ficha; Ver termo muestra los stickers pegados al termo del mate. Las ilustraciones actuales de monedas son provisionales.\n\nPodés activar Armar grupos arrastrando en la mesa o en Opciones: llevá los dados al sector izquierdo y pulsá Armar grupo. Arrastralos de vuelta para corregir el borrador. Al pasar el mouse por un dado se muestran sus combinaciones posibles.\n\nTeclado: con el modo de clic, 1–5 seleccionan dados, G agrupa, C envía al vaso, V reserva, espacio tira, I inspecciona la selección, Esc la limpia y F1 abre ayuda. Tab recorre botones; Enter los activa.\nUsá monedas de un uso antes de anotar; sus fichas explican duración y contexto. Cada sección de la tienda tiene su propio costo de renovación. Cancelar una compra sin confirmar no cobra. Un paquete ya pagado conserva sus opciones al cerrar el panel.")

func shop_offer_text(offer: Dictionary) -> Array:
	var effect: Dictionary = offer.effect
	match offer.kind:
		"coin": return [Coins.definition(effect.coin_id).name, Coins.definition(effect.coin_id).description]
		"material": return ["Acero" if effect.id == "steel" else "Cobre", "+3 puntos propios al conservarlo en un relanzamiento ajeno; relanzarlo borra el bono. Dura el encuentro." if effect.id == "steel" else "+0.5 al multiplicador de su grupo por relanzamiento propio. Dura el encuentro."]
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
		"pack": return ["Paquete de stickers", "Elegí uno entre tres distintos." if effect.pack_kind == "choose_one" else "Recibís dos stickers distintos."]
	return ["Oferta", ""]

func shop_skin(ornate := false) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = Backdrop.SHOP_ART
	var unit := Vector2(atlas.atlas.get_width() / 1440.0, atlas.atlas.get_height() / 900.0)
	atlas.region = Rect2(Vector2(45, 18) * unit, Vector2(462, 143) * unit) if ornate else Rect2(Vector2(554, 168) * unit, Vector2(198, 83) * unit)
	var skin := StyleBoxTexture.new()
	skin.texture = atlas
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(side, 30 if ornate else 15)
		skin.set_content_margin(side, 10 if side in [SIDE_LEFT, SIDE_RIGHT] else 3)
	return skin

func skin_shop_button(node: Button) -> void:
	if preferences.high_contrast: return
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := shop_skin()
		skin.modulate_color = Color("ffffff") if state == "normal" else Color("ffe1a1") if state == "hover" else Color("d5ac73") if state == "pressed" else Color("655d51")
		node.add_theme_stylebox_override(state, skin)
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
		sticker.position = rect.position
		sticker.size = rect.size
		parent.add_child(sticker)
		return
	if offer.kind == "coin":
		add_coin(parent, offer.effect.coin_id, rect)
		return
	if offer.kind in ["face", "shell", "material", "element"]:
		var face := Die.new()
		face.value = offer.effect.number if offer.kind == "face" else 5
		face.pip_material = offer.effect.id if offer.kind == "shell" else ""
		face.body_material = offer.effect.id if offer.kind == "material" else "basic"
		face.element = offer.effect.id if offer.kind == "element" else ""
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
		"global": icon.icon_id = "number"
		"face": icon.icon_id = "face"
		"pack": icon.icon_id = "pack"
		"sticker": icon.icon_id = "portrait" if offer.effect.id == "trio" else "sticker"
	parent.add_child(icon)
	if offer.kind in ["global"]:
		shop_caption(parent, str(offer.effect.number), Rect2(rect.position + Vector2(0, 2), rect.size - Vector2(0, 6)), 37)
	elif offer.kind == "pack":
		shop_caption(parent, "?" if offer.effect.pack_kind == "choose_one" else "2", Rect2(rect.position + Vector2(0, 5), rect.size - Vector2(0, 5)), 29)

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
		shop_caption(card, "VENDIDO" if stock.configured else "Sin ofertas", Rect2(0, 53, rect.size.x, 34), 17, Color("c6ac88"))
		return
	var text: Array = shop_offer_text(offer)
	var compact := section == "coins"
	shop_icon(card, offer, Rect2((rect.size.x - 100) / 2, 10, 100, 91))
	var object_hover := HoverPanel.new()
	object_hover.name = "ObjectHover"
	object_hover.position = Vector2((rect.size.x - 100) / 2, 10)
	object_hover.size = Vector2(100, 91)
	object_hover.mouse_filter = Control.MOUSE_FILTER_STOP
	object_hover.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	object_hover.tooltip_text = text[0] + "\n" + text[1]
	card.add_child(object_hover)
	var unavailable: bool = game.phase != "shop" or not game.can_afford(offer.price) or not Purchases.valid_offer(section, offer, game.sticker_catalog)
	if offer.kind == "coin": unavailable = unavailable or not Coins.can_store(game.coin_inventory, offer.effect.coin_id)
	var id: String = offer.offer_id
	var purchase := button(card, "$%d" % offer.price, Rect2((rect.size.x - minf(102, rect.size.x - 8)) / 2, 109, minf(102, rect.size.x - 8), 30), func():
		var previous_stickers: Dictionary = game.cup.stickers.duplicate(true)
		var result: Dictionary = game.begin_purchase(section, id)
		purchase_error = "" if result.ok else result.message
		render()
		if result.ok and offer.kind == "pack" and offer.effect.pack_kind == "receive_two":
			show_sticker_reveal(offer.effect.items, previous_stickers), unavailable, true)
	purchase.name = "Price"
	object_hover.activated.connect(func():
		if not purchase.disabled: purchase.pressed.emit())
	purchase.add_theme_font_size_override("font_size", 20 if compact else 22)
	for state in ["normal", "hover", "pressed", "disabled"]: purchase.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	purchase.add_theme_color_override("font_color", gold)
	purchase.add_theme_color_override("font_hover_color", Color("fff0c7"))

func render_shop() -> void:
	var shop_theme := theme.duplicate()
	shop_theme.default_font = ItemTooltip.pixel_font()
	ui.theme = shop_theme
	shop_frame(Rect2(30, 14, 400, 75), true)
	shop_caption(ui, "TIENDA", Rect2(55, 34, 350, 38), 34)
	var inventory := panel(ui, Rect2(770, 777, 635, 80), Color.TRANSPARENT)
	inventory.name = "ShopInventory"
	inventory.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	shop_caption(ui, "TUS MONEDAS %d/%d" % [game.passives.size(), game.coin_inventory.shared_capacity], Rect2(770, 777, 410, 18), 13)
	for index in range(game.coin_inventory.shared_capacity):
		var x := 785 + index * 78
		if index < game.passives.size():
			var coin: String = game.passives[index]
			var inspect := owned_shop_coin(coin, game.coin_inventory.equipped[index].instance_id, Rect2(x, 798, 62, 38))
			add_coin(inspect, coin, Rect2(11, 0, 40, 38))
	shop_caption(ui, "UN USO", Rect2(1190, 777, 205, 18), 13)
	shop_frame(Rect2(518, 30, 193, 80))
	shop_caption(ui, "PLATA", Rect2(530, 38, 169, 22), 18)
	shop_caption(ui, money_text(game.cash), Rect2(530, 60, 169, 42), 34, gold)
	shop_frame(Rect2(730, 30, 200, 80))
	shop_caption(ui, "CAPACIDAD", Rect2(742, 38, 176, 22), 18)
	shop_caption(ui, str(game.coin_inventory.shared_capacity), Rect2(742, 60, 176, 42), 34, gold)
	for entry in [["Menú", 1027, func(): request_navigation("pause")], ["Opciones", 1137, show_options], ["Recorrido · M", 1247, show_route]]:
		var nav := button(ui, entry[0], Rect2(entry[1], 166, 106 if entry[0] != "Recorrido · M" else 158, 31), entry[2])
		nav.add_theme_font_size_override("font_size", 13)
	shop_caption(ui, "TUS DADOS", Rect2(350, 777, 370, 22), 15)
	for id in range(5):
		var die := Die.new()
		die.configure_appearance(game.dice[id], game.boss_context())
		die.die_index = id
		die.position = Vector2(361 + id * 72, 805)
		die.scale = Vector2(0.78, 0.78)
		die.pressed.connect(func(): inspect_die(id))
		die.inspect_requested.connect(inspect_die)
		for state in ["normal", "hover", "pressed"]: die.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		ui.add_child(die)
		die.tooltip_text = die_hover_text(id)
	var cup_zone := panel(ui, Backdrop.SHOP_THERMOS_RECT, Color.TRANSPARENT)
	cup_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cup_zone.name = "Shop_cup"
	var thermos := preload("res://scripts/shop_thermos.gd").new()
	thermos.name = "ThermosArtwork"
	thermos.size = cup_zone.size
	thermos.stickers = game.cup.stickers.duplicate(true)
	cup_zone.add_child(thermos)
	if game.consumable != "":
		var coin: String = game.consumable
		var inspect := owned_shop_coin(coin, game.coin_inventory.consumables[0].instance_id, Rect2(1260, 798, 62, 38))
		add_coin(inspect, coin, Rect2(11, 0, 40, 38))
	var zones := {"numbers": Rect2(538, 252, 367, 179), "components": Rect2(929, 252, 388, 179), "coins": Rect2(525, 442, 380, 179), "stickers": Rect2(929, 442, 401, 179)}
	var titles := {"numbers": "Números y caras", "components": "Componentes", "coins": "Monedas", "stickers": "Stickers"}
	var renew_names := {"coins": "monedas", "components": "componentes", "numbers": "números", "stickers": "stickers"}
	for section in zones:
		var section_id: String = section
		var zone := panel(ui, zones[section], Color.TRANSPARENT)
		zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		zone.name = "Shop_" + section
		var title_width: float = ui.theme.default_font.get_string_size(titles[section], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var header_x: float = (zones[section].size.x - title_width - 40) / 2
		var title := button(zone, titles[section], Rect2(header_x, 0, title_width, 26), func(): shop_section = section_id)
		for state in ["normal", "hover", "pressed"]: title.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		title.add_theme_font_size_override("font_size", 18)
		var count := 4 if section == "coins" else 2
		var width: float = (zones[section].size.x - 24) / count
		for index in range(count): shop_card(zone, section, index, Rect2(12 + index * width, 28, width, 145))
		var stock: Dictionary = game.shop_state.get(section, {"slots": [], "configured": false})
		var renew := button(zone, "", Rect2(header_x + title_width + 8, -2, 32, 30), func(): act(func(): game.refresh_shop(section_id)), game.phase != "shop" or not stock.configured or not game.can_afford(game.renewal_price(section_id)))
		renew.name = "Refresh"
		renew.tooltip_text = "Renovar %s · $%d\nCambia solo las ofertas de esta zona.\nEl costo aumenta solo para esta zona durante esta visita." % [renew_names[section], game.renewal_price(section_id)]
		for state in ["normal", "hover", "pressed", "disabled"]: renew.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var retry_icon := preload("res://scripts/retry_icon.gd").new()
		retry_icon.position = Vector2(2, 0)
		retry_icon.size = Vector2(28, 30)
		renew.add_child(retry_icon)
	var next_label := "Entrar al nivel %d →" % (game.level_index + 2) if game.rival + 1 == game.level_encounters.size() and game.has_next_encounter() else "Ir al %s →" % ("jefe" if game.rival + 1 < game.level_encounters.size() and game.is_boss(game.rival + 1) else "siguiente rival")
	var next_button := button(ui, next_label, Rect2(1025, 25, 380, 93), func(): act(game.leave_shop), game.phase != "shop", true)
	next_button.name = "ShopAdvance"
	next_button.add_theme_font_size_override("font_size", 18)
	var leave := button(ui, "Abandonar partida", Rect2(1025, 126, 380, 28), func(): request_navigation("menu"))
	leave.add_theme_font_size_override("font_size", 14)
	shop_caption(ui, "EL MALETÍN · TODAS LAS OFERTAS A LA VISTA", Rect2(410, 750, 980, 31), 15)
	shop_caption(ui, "NIVEL %d · %s · DATOS PROVISIONALES" % [game.level_index + 1, game.environment_id().replace("_", " ").to_upper()], Rect2(30, 94, 400, 22), 11)
	coin_sale_overlay = preload("res://scripts/coin_sale_zone.gd").new()
	coin_sale_overlay.name = "CoinSaleOverlay"
	coin_sale_overlay.position = Vector2(518, 248)
	coin_sale_overlay.size = Vector2(819, 377)
	coin_sale_overlay.z_index = 100
	coin_sale_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	coin_sale_overlay.accepts = can_sell_dragged_coin
	coin_sale_overlay.coin_dropped.connect(sell_dragged_coin)
	coin_sale_overlay.add_theme_stylebox_override("panel", box(Color(0.46, 0.025, 0.10, 0.62), Color(0.93, 0.73, 0.40, 0.80), 2))
	ui.add_child(coin_sale_overlay)
	coin_sale_caption = shop_caption(coin_sale_overlay, "", Rect2(0, 140, 819, 90), 38)
	coin_sale_overlay.hide()

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
	node.tooltip_text = Coins.definition(coin).name + "\n" + Coins.definition(coin).description
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
	shop_caption(modal, "Precio: $%d   ·   Saldo: %s" % [offer.price, money_text(game.cash)], Rect2(32, 68, 796, 28), 18)
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
		var material := "Acero" if die.material == "steel" else ("Cobre" if die.material == "copper" else "Base")
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
	button(modal, "Confirmar · $%d" % offer.price, Rect2(64, 554, 732, 46), func():
		var result: Dictionary = game.confirm_purchase()
		purchase_error = "" if result.ok else result.message
		render(), not preview.ok, true)
	button(modal, "Cancelar compra", Rect2(64, 620, 732, 40), func():
		game.cancel_purchase()
		purchase_error = ""
		render())

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
	panel(ui, Rect2(0, 0, 1440, 900), Color(0.04, 0.06, 0.07, 0.84))
	button(ui, "Recorrido · M", Rect2(1000, 23, 200, 38), show_route)
	button(ui, "Menú", Rect2(1220, 23, 185, 38), func(): request_navigation("pause"))
	button(ui, "Abandonar partida", Rect2(590, 23, 195, 38), func(): request_navigation("menu"))
	if game.phase == "repair":
		render_repairs()
		return
	if game.phase == "reward":
		render_encounter_choice()
		return
	var modal := panel(ui, Rect2(400, 240, 640, 480), Color("263c3d"), gold)
	if game.phase == "lost":
		label(modal, "ESTA VEZ, GANÓ EL AZAR", Vector2(36, 33), 29, gold)
		label(modal, "%d / %d puntos\n\n%s: se agotaron las manos sin llegar al objetivo.\nPodés volver a intentar con la misma semilla\no empezar una nueva partida." % [game.points, game.target(), "Nivel %d, encuentro %d" % [game.level_index + 1, game.rival + 1] if not game.campaign.is_empty() else "Rival %d" % (game.rival + 1)], Vector2(36, 103), 21, cream, 560)
		button(modal, "Reintentar misma semilla", Rect2(36, 306, 566, 49), func(): start_new_run(game.run_seed), false, true)
		button(modal, "Nueva partida", Rect2(36, 371, 566, 45), start_new_run)
	else:
		label(modal, "DIOS SUPERADO" if game.phase == "won" and not game.campaign.is_empty() else "JEFE SUPERADO" if game.phase == "won" else "ENCUENTRO GANADO", Vector2(36, 30), 32, gold)
		if game.phase == "won": label(modal, "VICTORIA · 21 ENCUENTROS COMPLETADOS" if not game.campaign.is_empty() else "VICTORIA · NIVEL DE PRUEBA COMPLETADO", Vector2(36, 69), 16, cream)
		var p: Dictionary = game.payout
		label(modal, "%d / %d puntos\n\nVictoria                              $%d\nManos sobrantes                  $%d\nExceso de puntos                 $%d\nIntereses                             $%d\n\nTOTAL COBRADO                  $%d" % [game.points, game.target(), p.base, p.hands, p.excess, p.interest, p.total], Vector2(36, 90), 21, cream)
		button(modal, "Prototipo completado · volver a jugar", Rect2(36, 371, 566, 49), start_new_run, false, true)
	button(modal, "Volver al menú", Rect2(36, 437, 566, 36), func(): request_navigation("menu"))

func render_encounter_choice() -> void:
	var modal := panel(ui, Rect2(290, 130, 860, 640), Color.TRANSPARENT)
	modal.name = "EncounterChoice"
	modal.add_theme_stylebox_override("panel", ItemTooltip.skin())
	modal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	modal.theme = theme.duplicate()
	modal.theme.default_font = ItemTooltip.pixel_font()
	shop_caption(modal, "ENCUENTRO GANADO", Rect2(32, 25, 796, 42), 30, gold)
	shop_caption(modal, "%d / %d puntos" % [game.points, game.target()], Rect2(32, 75, 796, 30), 20)
	var p: Dictionary = game.payout
	var names := ["Victoria", "Manos sobrantes", "Exceso de puntos", "Intereses"]
	var values: Array = [p.base, p.hands, p.excess, p.interest]
	for i in range(names.size()):
		label(modal, names[i], Vector2(200, 133 + i * 32), 18, cream, 360)
		var amount := label(modal, "$%d" % values[i], Vector2(580, 133 + i * 32), 18, cream, 80)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shop_caption(modal, "TOTAL COBRADO: $%d   ·   SALDO: %s" % [p.total, money_text(game.cash)], Rect2(32, 272, 796, 34), 20, gold)
	shop_caption(modal, "¿CÓMO QUERÉS SEGUIR?", Rect2(32, 335, 796, 32), 22, gold)
	var next_text := "Próximo: %s" % ("jefe" if game.is_boss(game.rival + 1) else "rival %d" % [game.rival + 2]) if game.rival + 1 < game.level_encounters.size() else "Entrar al nivel %d" % [game.level_index + 2]
	shop_caption(modal, "Comprá mejoras para tus dados.", Rect2(42, 390, 374, 28), 16)
	shop_caption(modal, next_text, Rect2(444, 390, 374, 28), 16)
	var visit := button(modal, "Ir a la tienda →", Rect2(48, 435, 366, 56), func(): act(game.open_shop), false, true)
	var advance := button(modal, "Seguir sin tienda →", Rect2(446, 435, 366, 56), func(): act(game.skip_shop))
	for node in [visit, advance]:
		skin_shop_button(node)
		node.add_theme_font_size_override("font_size", 19)
	shop_caption(modal, "La recompensa ya está acreditada. Elegí tu próximo destino.", Rect2(32, 516, 796, 26), 16)
	var menu := button(modal, "Volver al menú", Rect2(250, 571, 360, 38), func(): request_navigation("menu"))
	skin_shop_button(menu)

func render_repairs() -> void:
	var modal := panel(ui, Rect2(350, 160, 740, 580), Color("263c3d"), gold)
	label(modal, "REPARAR CARCASAS", Vector2(30, 24), 30, gold)
	label(modal, "Ya cobraste $%d · Saldo: %s\nElegí cuáles reparar o continuá sin reparar." % [game.payout.total, money_text(game.cash)], Vector2(30, 78), 21, cream, 680)
	var y := 150.0
	for id in game.repair_resolution.available_ids:
		var shell := Gems.definition(game.dice[id].shell)
		var die_id: int = id
		var choice := CheckBox.new()
		choice.position = Vector2(30, y)
		choice.size = Vector2(675, 36)
		choice.text = "Dado %d · %s · $%d" % [id + 1, shell.name, shell.repair_cost]
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

