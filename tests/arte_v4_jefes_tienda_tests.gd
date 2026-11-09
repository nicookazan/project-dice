extends RefCounted
## Arte v4 (08/11): manos de jefe con animación propia al clic, y la tienda con ganchos, etiquetas y bandejas.
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const HandClips = preload("res://scripts/boss_hand_clips.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const ShopFixtures = preload("res://scripts/shop_fixtures.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")
const BossCatalogTests = preload("res://tests/boss_catalog_tests.gd")
const ShopTests = preload("res://tests/shop_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	# Tabla de recortes: todos los jefes de los niveles 1 a 6 menos El Gótico, y cada fila cabe en la hoja.
	var front := Image.load_from_file("res://assets/art/pixel-v3/manos-clic-v4.png")
	var rings := Image.load_from_file("res://assets/art/pixel-v3/manos-contorno-v4.png")
	var expected: Array = BossCatalog.ROWS.filter(func(row): return row.level <= BossCatalog.GOD_LEVEL and row.id != "l3_gotico").map(func(row): return row.id)
	var table_ok := HandClips.CLIPS.size() == expected.size() and not HandClips.CLIPS.has("l3_gotico")
	var fits := true
	for id in expected:
		table_ok = table_ok and HandClips.CLIPS.has(id)
		if not HandClips.CLIPS.has(id): continue
		var clip: Dictionary = HandClips.CLIPS[id]
		fits = fits and clip.frames >= 10 and clip.sheet_y + clip.size.y <= front.get_height() and clip.size.x * clip.frames <= front.get_width()
		fits = fits and clip.ring_y + clip.size.y * 2 + 4 <= rings.get_height() and clip.size.x * 2 + 4 <= rings.get_width()
	check.call(table_ok, "Boss hand v4: the 17 bosses have an own click animation and El Gótico keeps the old hand")
	check.call(fits, "Boss hand v4: every clip row (frames, ring) fits inside its sheet")
	# Cada jefe: reposo en el fondo, clic con su animación (sin piedra, papel o tijera) y vuelta al reposo.
	var god_free := true
	var plays := true
	var rest_visible := true
	for id in expected:
		scene.game = BossCatalogTests.forced_boss(id, true)
		scene.render()
		rest_visible = rest_visible and scene.background.hand_boss == id and scene.ui.find_child("Ring_hand", true, false) != null
		scene.background.props.stop_all()
		plays = plays and scene.background.props.play_hand(scene.background.hand_boss) and scene.background.props.hand_clip == id
		var duration: float = HandClips.CLIPS[id].frames * BarProps.HAND_CLIP_SECONDS
		scene.background.props.step(duration * 0.5)
		plays = plays and scene.background.props.busy("hand") and scene.background.props.hand_clip_frame(id) > 0
		scene.background.queue_redraw()
		await scene.get_tree().process_frame
		scene.background.props.step(duration)
		plays = plays and not scene.background.props.busy("hand") and scene.background.props.hand_clip_frame(id) == 0
	check.call(rest_visible, "Boss hand v4: each boss shows its own hand and golden ring")
	check.call(plays, "Boss hand v4: the click plays the boss's own clip, runs for its length and returns to rest")
	# El Gótico y la mano común siguen con piedra, papel o tijera.
	scene.game = BossCatalogTests.forced_boss("l3_gotico", true)
	scene.render()
	scene.background.props.stop_all()
	scene.background.props.play_hand(scene.background.hand_boss)
	check.call(scene.background.hand_boss == "" and scene.background.props.hand_clip == "" and scene.background.props.busy("hand"), "Boss hand v4: El Gótico still plays rock, paper or scissors")
	scene.background.props.stop_all()
	# Movimiento reducido: el clic no anima.
	scene.preferences.reduced_motion = true
	scene.game = BossCatalogTests.forced_boss("l1_palomas", true)
	scene.render()
	check.call(not scene.background.props.play_hand(scene.background.hand_boss), "Boss hand v4: with reduced motion the click does not animate")
	scene.preferences.reduced_motion = false
	scene.background.props.stop_all()
	# Nombres nuevos.
	check.call(BossCatalog.entry("l2_chamuyero").name == "El Vendedor Ambulante" and BossCatalog.entry("l4_tahur").name == "El Timbero" and BossCatalog.entry("l4_payaso").name == "El Payaso", "Boss catalog: renamed Vendedor Ambulante, Timbero and Payaso")
	# Tienda sobre la mesa: cada oferta apoyada en el paño lleva su etiqueta con el precio encima.
	scene.game = ShopTests.game_at_shop(162)
	scene.render()
	var tags := 0
	var tags_with_price := 0
	for card in scene.ui.find_children("Offer_*", "Control", true, false):
		var tag = card.get_node_or_null("Tag")
		if tag != null and tag.get_script() == ShopFixtures and not tag.sold: tags += 1
		var price = card.get_node_or_null("Price")
		if tag != null and price != null and Rect2(tag.position, tag.size).encloses(Rect2(price.position, price.size).grow(-2)): tags_with_price += 1
	check.call(tags >= 4 and tags_with_price == tags, "Shop on the table: every offer lies on the felt with its price written on its tag")
	# Paquetes: celdas 75 y 76 de la hoja de monedas con la bolsita de terciopelo (ya no son las viejas).
	var coins_sheet := Image.load_from_file("res://assets/art/pixel-v3/coins-v4.png")
	var small := coins_sheet.get_region(Rect2i(9 * 32, 6 * 32, 32, 32))
	var big := coins_sheet.get_region(Rect2i(10 * 32, 6 * 32, 32, 32))
	check.call(small.get_data() != big.get_data() and not small.is_invisible() and not big.is_invisible(), "Coin packs: the two pouch cells are drawn and differ from each other")
