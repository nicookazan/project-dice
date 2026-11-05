extends SceneTree
## Capturas reales del juego para los bocetos M/T. No toca nada del proyecto: todo overlay vive solo acá.
## Uso: godot --path . --resolution 1440x900 --script res://tools/art/bocetos-jugabilidad/capture.gd (sin --headless). Escribe en test-results/bocetos/cap.
var OUT := ProjectSettings.globalize_path("res://test-results/bocetos/")
const Game = preload("res://scripts/game.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const ShopTests = preload("res://tests/shop_tests.gd")
const Purchases = preload("res://tests/purchase_tests.gd")
const Tip = preload("res://scripts/item_tooltip.gd")
const StickerArt = preload("res://scripts/sticker_art.gd")
const Die = preload("res://scripts/die.gd")
const C := {"steel":"b8c4d4","copper":"e89a5c","emerald":"55d890","ruby":"ff5f70","sapphire":"74a4f0","diamond":"cdf2ff","fire":"ff8e30","water":"52bcf2","electric":"ffe24f","earth":"c4955a","wind":"a4e6c6","gold":"f0c850","dim":"8f8676"}
var scene
var layer: CanvasLayer

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT + "cap")
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	layer = CanvasLayer.new(); layer.layer = 60; root.add_child(layer)
	await table_shots()
	await drag_sequence()
	print("CAPTURE OK")
	quit(0)

func table_game(values := [5, 5, 2, 5, 2], stickers := {"trio": 2, "full": 1, "pair_loose": 3, "poker": 1}):
	var g = Game.new(521)
	Profile.apply(g)
	g.cup.stickers = stickers.duplicate()
	g.dice[3].material = "steel"; g.dice[3].shell = "ruby"; g.dice[3].element = "fire"
	g.dice[1].shell = "emerald"
	g.global_points = {"5": 3}
	Fixture.set_values(g, values)
	return g

func clear_layer() -> void:
	for c in layer.get_children(): c.queue_free()
	await process_frame

func shot(name: String, region := Rect2i()) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if region.size != Vector2i.ZERO: image = image.get_region(region)
	image.save_png(OUT + "cap/" + name + ".png")

func pointer(at: Vector2) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(0,0),Vector2(0,20),Vector2(5,15),Vector2(9,24),Vector2(13,22),Vector2(9,14),Vector2(16,14)])
	p.color = Color.WHITE; p.position = at
	var l := Line2D.new(); l.points = p.polygon; l.closed = true; l.width = 2; l.default_color = Color.BLACK; l.position = at
	layer.add_child(p); layer.add_child(l)

func text_card(rect: Rect2, bb: String, size := 18, center := false) -> PanelContainer:
	var card := PanelContainer.new()
	var st: StyleBox = Tip.skin()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: st.set_content_margin(side, 16)
	card.add_theme_stylebox_override("panel", st)
	card.position = rect.position; card.custom_minimum_size = rect.size; card.size = rect.size
	var r := RichTextLabel.new()
	r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false
	r.add_theme_font_override("normal_font", Tip.pixel_font())
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", Color("fff0c7"))
	r.text = ("[center]%s[/center]" % bb) if center else bb
	card.add_child(r)
	layer.add_child(card)
	return card

func die_bb(mat: String, gem: String, el: String) -> String:
	var parts := []
	if mat != "": parts.append("[color=#%s]%s[/color]" % [C[mat], {"steel":"Acero","copper":"Cobre"}[mat]])
	if gem != "": parts.append("[color=#%s]%s[/color]" % [C[gem], {"emerald":"Esmeralda","ruby":"Rubí","sapphire":"Zafiro","diamond":"Diamante"}[gem]])
	if el != "": parts.append("[color=#%s]%s[/color]" % [C[el], {"fire":"Fuego","water":"Agua","electric":"Electricidad","earth":"Tierra","wind":"Viento"}[el]])
	return " · ".join(parts) if not parts.is_empty() else "[color=#%s]Dado común[/color]" % C.dim

func faces_bb(current: int, faces := [1,2,3,4,5,6]) -> String:
	var out := []
	for f in faces: out.append(("[color=#%s]%d[/color]" % [C.gold, f]) if f == current else str(f))
	return " · ".join(out)

func worth(text: String) -> String:
	return "[color=#%s]%s[/color]" % [C.gold, text]

func table_shots() -> void:
	scene.game = table_game()
	scene.preferences.drag_groups = true
	scene.render()
	await create_timer(0.1).timeout
	scene.background.set_process(false)
	await shot("mesa_base")
	# M2: ficha, dos variantes de "cuánto vale"
	var p: Vector2 = scene.table_dice[3].get_global_transform() * Vector2(40, 40)
	felt_card(322.0, die_bb("steel","ruby","fire") + "\n" + faces_bb(5) + "\n" + worth("Vale 8 puntos"))
	pointer(p)
	await shot("m2_a")
	await clear_layer()
	# Estados de la ficha
	var bg := ColorRect.new(); bg.color = Color("241014"); bg.size = Vector2(1440, 900); layer.add_child(bg)
	text_card(Rect2(30, 30, 340, 90), die_bb("steel","ruby","fire") + "\n" + faces_bb(5) + "\n" + worth("Vale 8 puntos"))
	text_card(Rect2(400, 30, 340, 90), die_bb("","","") + "\n" + faces_bb(3) + "\n" + worth("Vale 3 puntos"))
	text_card(Rect2(770, 30, 340, 90), die_bb("copper","","wind") + "\n" + faces_bb(6, [1,2,3,6,6,6]) + "\n" + worth("Vale 6 puntos"))
	text_card(Rect2(30, 160, 340, 90), "[color=#%s][s]Esmeralda[/s] rota[/color] · [color=#%s]Agua[/color]\n" % [C.dim, C.water] + faces_bb(2) + "\n" + worth("Vale 2 puntos"))
	text_card(Rect2(400, 160, 340, 90), "[color=#%s][s]Acero[/s] suspendido por el jefe[/color]\n" % C.dim + faces_bb(4) + "\n" + worth("Vale 4 puntos"))
	text_card(Rect2(770, 160, 340, 90), die_bb("","diamond","electric") + "\n" + faces_bb(-1) + "\n[color=#%s]Todavía en el vaso[/color]" % C.dim)
	await shot("m2_estados", Rect2i(0, 0, 1140, 280))
	await clear_layer()
	# Glosario en la inspección que ya existe
	scene.present_detail("Dado 4 · qué hace cada cosa", "Acero: +3 puntos propios al conservarlo en un relanzamiento ajeno; relanzarlo borra el bono. Dura el encuentro.\n\nRubí: multiplica ×1.5 el multiplicador después de las sumas. Requiere combinación desde par.\n\nFuego: se activa con cara 4, 5 o 6 en una combinación desde par.\n\nCaras: 1 · 2 · 3 · 4 · 5 · 6\nVale ahora: 8 puntos.", true)
	await shot("m2_glosario")
	scene.detail.hide()
	# M3: jugadas posibles (partida limpia para que los puntos sean creíbles)
	scene.game = plain_game()
	scene.preferences.drag_groups = false
	var combos := best_combos()
	print("COMBOS ", combos)
	scene.selected.clear(); scene.render(); scene.background.set_process(false)
	combo_list(combos, -1)
	await shot("m3_lista")
	await clear_layer()
	var trio := 0
	for i in range(combos.size()):
		if combos[i].cat == "Trío": trio = i
	scene.selected = combos[trio].ids.duplicate(); scene.render(); scene.background.set_process(false)
	combo_list(combos, trio)
	pointer(Vector2(600, 372 + trio * 44))
	await shot("m3_hover")
	await clear_layer()
	scene.selected.clear()
	scene.game.form_group(combos[trio].ids)
	var rest := best_combos()
	print("REST ", rest)
	scene.render(); scene.background.set_process(false)
	nudge_group_area()
	combo_list(rest, -1, 470.0, 44.0, "SIGUEN POSIBLES")
	await shot("m3_armado")
	await clear_layer()
	# M2 + M3 juntas: la lista arriba y la ficha abajo
	scene.game = plain_game(); scene.game.dice[3].material = "steel"; scene.game.dice[3].shell = "ruby"; scene.game.dice[3].element = "fire"
	combos = best_combos()
	scene.selected.clear(); scene.render(); scene.background.set_process(false)
	combo_list(combos, -1, 336, 44)
	text_card(Rect2(378, 552, 301, 90), die_bb("steel","ruby","fire") + "
" + faces_bb(5) + "
" + worth("Vale 5 puntos"))
	pointer(scene.table_dice[3].get_global_transform() * Vector2(40, 40))
	await shot("m2m3")
	await clear_layer()
	scene.preferences.drag_groups = true
	scene.game = table_game(); scene.preferences.drag_groups = true; scene.render(); scene.background.set_process(false)
	scene.show_options()
	var check := CheckButton.new(); check.text = "Mostrar jugadas posibles"; check.button_pressed = true
	check.position = Vector2(390, 412); check.add_theme_font_size_override("font_size", 19)
	scene.settings_panel.add_child(check)
	await shot("m3_opciones")
	scene.detail.hide()
	# M5: sticker con ventanita
	scene.game = table_game([5, 5, 2, 5, 2], {"pair_loose": 3, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1})
	scene.render(); scene.background.set_process(false)
	await shot("m5_base")
	var r := StickerArt.thermos_rect("full"); r.position += Vector2(1203, 168)
	var cat: Dictionary = scene.game.sticker_catalog["full"]
	sticker_ring(r)
	text_card(Rect2(r.position.x - 332, r.position.y - 28, 314, 72), "Full · Nivel 1\n" + worth("+%s puntos · +%s mult." % [scene.number(cat.points_per_level), scene.number(cat.multiplier_per_level)]))
	pointer(r.get_center())
	await shot("m5_hover")
	await clear_layer()

func sticker_ring(r: Rect2) -> void:
	var ring := ReferenceRect.new(); ring.position = r.position - Vector2(4, 4); ring.size = r.size + Vector2(8, 8); ring.border_color = Color(C.gold); ring.border_width = 2; ring.editor_only = false; layer.add_child(ring)

func best_combos() -> Array:
	var best := {}
	for mask in range(1, 32):
		var ids := []
		for b in range(5): if mask & (1 << b): ids.append(b)
		scene.selected = ids
		var pv: Dictionary = scene.selection_preview()
		if pv.valid and pv.has("row"):
			var cat: String = pv.row.category
			if cat == "Sin combinación": continue
			if not best.has(cat) or pv.row.total > best[cat].total: best[cat] = {"cat": cat, "ids": ids.duplicate(), "total": pv.row.total}
	scene.selected = []
	var arr: Array = best.values()
	arr.sort_custom(func(a, b): return a.total > b.total)
	return arr

func plain_game():
	var g = Game.new(521)
	Profile.apply(g)
	Fixture.set_values(g, [5, 5, 2, 5, 2])
	return g

## Borde dorado de la tela izquierda, medido sobre la captura: arriba y=314-315, abajo y=652-653, derecha x=694-695.
const FELT_TOP := 316.0
const FELT_BOTTOM := 652.0
const FELT_RIGHT := 694.0

func felt_left(y: float) -> float:
	return 392.0 - 0.1692 * (y - 340.0)

## Banda que sigue la inclinación del borde izquierdo y llega hasta el borde derecho, a `inset` px del dorado.
func felt_band(top: float, bottom: float, inset := 6.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(felt_left(top) + inset, top), Vector2(FELT_RIGHT - inset, top), Vector2(FELT_RIGHT - inset, bottom), Vector2(felt_left(bottom) + inset, bottom)])

func band_panel(points: PackedVector2Array, fill: Color, edge: Color, width := 2.0) -> void:
	var poly := Polygon2D.new(); poly.polygon = points; poly.color = fill; layer.add_child(poly)
	if width > 0.0:
		var line := Line2D.new(); line.points = points; line.closed = true; line.width = width; line.default_color = edge; layer.add_child(line)

## Ficha de la opción A, impresa sobre la tela siguiendo su borde dorado.
func felt_card(top: float, bb: String) -> void:
	var bottom := top + 88.0
	band_panel(felt_band(top, bottom), Color(0.17, 0.03, 0.07, 0.96), Color(0.93, 0.73, 0.40))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false
	r.position = Vector2(felt_left(bottom) + 26, top + 8); r.size = Vector2(FELT_RIGHT - felt_left(bottom) - 40, 76)
	r.add_theme_font_override("normal_font", Tip.pixel_font())
	r.add_theme_font_size_override("normal_font_size", 18)
	r.add_theme_color_override("default_color", Color("fff0c7"))
	r.text = bb
	layer.add_child(r)

func combo_list(combos: Array, hovered: int, top := 322.0, step := 44.0, heading := "JUGADAS POSIBLES") -> void:
	var title := Label.new(); title.text = heading; title.position = Vector2(felt_left(top) + 30, top - 2); title.size = Vector2(FELT_RIGHT - felt_left(top) - 60, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 17); title.add_theme_color_override("font_color", Color(C.gold)); layer.add_child(title)
	for i in range(combos.size()):
		var c: Dictionary = combos[i]
		var y0 := top + 28.0 + i * step
		var y1 := y0 + step - 6.0
		band_panel(felt_band(y0, y1), Color("2c4a9a") if i == hovered else Color("0d1728"), Color(C.gold) if i == hovered else Color("6a5230"))
		var x0 := felt_left(y1) + 16.0
		var vals := []
		for id in c.ids: vals.append(str(scene.game.dice[id].value))
		var a := Label.new(); a.text = c.cat; a.position = Vector2(x0, y0 + (step - 6 - 26) / 2); a.add_theme_font_size_override("font_size", 18); a.add_theme_color_override("font_color", Color("fff0c7")); layer.add_child(a)
		var b := Label.new(); b.text = " ".join(vals); b.position = Vector2(x0 + 104, y0 + (step - 6 - 22) / 2); b.add_theme_font_size_override("font_size", 15); b.add_theme_color_override("font_color", Color("b7a98c")); layer.add_child(b)
		var d := Label.new(); d.text = str(int(round(c.total))); d.position = Vector2(FELT_RIGHT - 66, y0 + (step - 6 - 28) / 2); d.size = Vector2(50, 28); d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; d.add_theme_font_size_override("font_size", 20); d.add_theme_color_override("font_color", Color(C.gold)); layer.add_child(d)

## El grupo armado también se corre para no pisar el borde inclinado.
func nudge_group_area() -> void:
	for child in scene.ui.get_node("GroupArea").get_children():
		child.position.x += 8.0 if child is Button and not child is Die else 26.0

func empty_shots() -> void:
	var g = Game.new(521); Profile.apply(g); g.cup.stickers = {"trio": 2, "full": 1}
	scene.game = g; scene.preferences.drag_groups = true; scene.render()
	await create_timer(0.1).timeout
	scene.background.set_process(false)
	scene.background.elapsed = 0.0; scene.background.queue_redraw()
	await shot("mesa_vacia")
	scene.background.thermos_t = 1.0; scene.background.queue_redraw()
	await shot("mesa_sin_termo")
	scene.background.thermos_t = 0.0; scene.background.queue_redraw()
	await process_frame

func die_sprites() -> void:
	var bg := ColorRect.new(); bg.color = Color(1, 0, 1); bg.size = Vector2(1440, 900); layer.add_child(bg)
	var g = Game.new(5)
	for v in range(1, 7):
		var data: Dictionary = g.dice[0].duplicate(true)
		data.value = v; data.face_index = data.faces.find(v); data.zone = "reserve"
		var d := Die.new(); d.configure_appearance(data, g.boss_context())
		d.position = Vector2(100 * v, 100); d.size = Vector2(62, 62); d.locked = true
		for state in ["normal", "hover", "pressed"]: d.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		layer.add_child(d)
	await shot("dados_magenta", Rect2i(90, 90, 620, 90))
	await clear_layer()

func drag_sequence() -> void:
	scene.game = table_game(); scene.preferences.drag_groups = true; scene.render(); scene.background.set_process(false)
	var moving := 4
	var src: Control = scene.table_dice[moving]
	var start: Vector2 = src.global_position
	src.modulate.a = 0.35
	scene.ui.get_node("GroupArea").get_child(0).hide()
	var zone := Polygon2D.new(); zone.polygon = felt_band(FELT_TOP, FELT_BOTTOM, 0.0); zone.color = Color(0.46, 0.025, 0.10, 0.62); layer.add_child(zone)
	var cap := Label.new(); cap.text = "Reservar"; cap.position = Vector2(felt_left(484), 440); cap.size = Vector2(FELT_RIGHT - felt_left(484), 90); cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 38); cap.add_theme_color_override("font_color", Color("fff0c7")); zone.add_child(cap)
	var glow := TextureRect.new()
	glow.texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/art/pixel-v3/vaso-brillo-v3.png"))
	glow.position = Vector2(1280 - 16, 426 - 16); glow.size = Vector2(176, 220); glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; glow.modulate.a = 0
	layer.add_child(glow)
	var d := Die.new(); d.configure_appearance(scene.game.dice[moving], scene.game.boss_context()); d.size = Vector2(62, 62); d.pivot_offset = Vector2(31, 31); d.locked = true
	for state in ["normal", "hover", "pressed"]: d.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	layer.add_child(d)
	var front := TextureRect.new()
	front.texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/art/pixel-v3/vaso-frente-v3.png"))
	front.position = Vector2(1280, 426); front.size = Vector2(144, 188); front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(front)
	var left := Vector2(500, 450); var cup := Vector2(1320, 470); var mouth := Vector2(1322, 400)
	var region := Rect2i(320, 262, 1120, 410)
	for f in range(62):
		var pos: Vector2
		if f < 14: pos = start.lerp(left, smoothstep(0, 13, f))
		elif f < 20: pos = left
		elif f < 40: pos = left.lerp(cup, smoothstep(20, 39, f))
		elif f < 44: pos = cup.lerp(mouth, smoothstep(40, 43, f))
		else: pos = mouth
		var dist := pos.distance_to(cup)
		glow.modulate.a = (1.0 - smoothstep(60, 330, dist)) * (0.75 + 0.25 * sin(f * 0.9)) if f < 50 else maxf(0, 1.0 - (f - 50) / 6.0)
		zone.visible = f < 46
		zone.modulate.a = 1.0 if pos.distance_to(left) < 170 else 0.55
		d.rotation_degrees = sin(f * 0.55) * 9.0
		if f >= 44:
			d.position = Vector2(mouth.x, mouth.y + (f - 44) * 15)
			d.scale = Vector2.ONE * 0.88
			d.visible = f < 52
		else:
			d.position = pos
		src.visible = f < 44
		await shot("seq_m1_%02d" % f, region)
	await clear_layer()

func shop_game(stickers: Dictionary):
	var g = ShopTests.game_at_shop(162)
	g.cash = 24
	g.cup.stickers = stickers.duplicate()
	Fixture.set_results(g, [1, 2, 3, 4, 5])
	g.dice[3].material = "copper"; g.dice[3].shell = "sapphire"; g.dice[3].element = "water"
	return g

func shop_shots() -> void:
	scene.game = shop_game({"pair_loose": 3, "trio": 2, "straight": 1, "full": 1, "poker": 1, "generala": 1})
	scene.render()
	await create_timer(0.1).timeout
	await shot("tienda_base")
	var art: Control = scene.ui.get_node("Shop_cup/ThermosArtwork")
	var dice := preload("res://tests/interface_tests.gd").dice_in(scene.ui)
	var target: Control = dice[3]
	var tp := target.get_global_rect().get_center()
	text_card(Rect2(tp.x - 160, 660, 320, 90), die_bb("copper","sapphire","water") + "\n" + faces_bb(4) + "\n" + worth("Vale 4 puntos"))
	pointer(tp)
	await shot("t2_hover")
	await clear_layer()
	var r := StickerArt.thermos_rect("full"); r.position += art.global_position
	sticker_ring(r)
	var cat: Dictionary = scene.game.sticker_catalog["full"]
	text_card(Rect2(r.end.x + 16, r.position.y - 20, 314, 72), "Full · Nivel 1\n" + worth("+%s puntos · +%s mult." % [scene.number(cat.get("points_per_level", 4)), scene.number(cat.get("multiplier_per_level", 0.75))]))
	pointer(r.get_center())
	await shot("t3_hover")
	await clear_layer()
	print("THERMOS AT ", art.global_position)
	# T1: la animación real de hoy (paquete) y base para la propuesta (suelto)
	scene.game = Purchases.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.game.cup.stickers = {"trio": 2, "generala": 1}
	scene.render()
	await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
	var reveal = scene.sticker_animation
	reveal.set_process(false)
	for f in range(36):
		if not is_instance_valid(reveal): break
		reveal.step(0.09)
		await shot("seq_t1hoy_%02d" % f)
	if is_instance_valid(reveal): reveal.finish()
	await process_frame
	# Propuesta de paquete: solo vuela el sticker nuevo; el repetido se queda y sube de nivel en su lugar.
	scene.game = Purchases.fixture("pack", {"pack_kind": "receive_two", "items": ["trio", "full"]}, 7)
	scene.game.cup.stickers = {"trio": 2, "generala": 1}
	scene.render()
	await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
	reveal = scene.sticker_animation
	reveal.set_process(false)
	var keep: Vector2 = reveal.origins[0]
	for f in range(36):
		if not is_instance_valid(reveal): break
		reveal.step(0.09)
		if not is_instance_valid(reveal) or reveal.finished: break
		var fly := clampf((reveal.elapsed - 2.0) / 0.9, 0, 1)
		reveal.badges[0].position = keep
		reveal.badges[0].scale = Vector2.ONE
		reveal.badges[0].rotation = 0.0
		reveal.badges[0].modulate.a = 1.0 - fly
		await shot("seq_t1prop_%02d" % f)
	if is_instance_valid(reveal): reveal.finish()
	await process_frame
	# Suelto con la tienda real: sticker nuevo y sticker repetido
	for variant in [["nuevo", {"generala": 1}], ["repetido", {"trio": 1, "generala": 1}]]:
		scene.game = shop_game(variant[1])
		scene.render()
		await create_timer(0.1).timeout
		await shot("t1_%s_antes" % variant[0])
		var off: Control = scene.ui.get_node("Shop_stickers/Offer_0")
		print("OFFER ", off.get_global_rect(), " ", scene.game.shop_state.get("stickers", {}))
		await click(scene.ui.get_node("Shop_stickers/Offer_0/ObjectHover"))
		if scene.sticker_animation_active(): scene.sticker_animation.finish()
		await create_timer(0.1).timeout
		scene.render()
		await shot("t1_%s_despues" % variant[0])
		print("STICKERS ", scene.game.cup.stickers)

func click(target: Control) -> void:
	await process_frame
	var point := target.get_global_transform_with_canvas() * (target.size / 2)
	var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion, true)
	for down in [true, false]:
		var e := InputEventMouseButton.new(); e.position = point; e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down
		root.push_input(e, true)
	await process_frame

func throw_now() -> void:
	var g = Game.new(521); Profile.apply(g); g.cup.stickers = {"trio": 2, "full": 1}
	scene.game = g; scene.render()
	scene.background.set_process(false)
	scene.set_process(false)
	scene.act(scene.game.roll)
	for f in range(30):
		if f > 0: scene.step_throw(1.0 / 25.0)
		await shot("seq_tirada_%02d" % f, Rect2i(350, 262, 1090, 410))
