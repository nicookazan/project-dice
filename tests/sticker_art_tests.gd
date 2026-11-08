extends RefCounted
## TX8 (D17): los stickers cambian de estilo con el nivel. Calcomanía brillante hasta el nivel 9, medallón dorado desde el 10.
const StickerArt = preload("res://scripts/sticker_art.gd")
const Thermos = preload("res://scripts/shop_thermos.gd")

static func _opaque(image: Image, rect: Rect2i) -> int:
	var count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y).a > 0: count += 1
	return count

## Cuántos píxeles dorados (tono del aro del medallón) hay en una celda.
static func _gold(image: Image, rect: Rect2i) -> int:
	var count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := image.get_pixel(x, y)
			if c.a > 0 and c.r > 0.7 and c.g > 0.5 and c.b < 0.35 and c.r - c.b > 0.45: count += 1
	return count

static func run(check: Callable) -> void:
	check.call(StickerArt.GOLD_FROM_LEVEL == 10, "TX8: el medallón dorado empieza en el nivel 10")
	var expected: Array = [[1, 0], [5, 0], [9, 0], [10, 1], [11, 1], [99, 1]]
	var umbral_ok := true
	for pair in expected:
		if StickerArt.style_for_level(pair[0]) != pair[1]: umbral_ok = false
	check.call(umbral_ok, "TX8: los niveles 1 a 9 usan la calcomanía y del 10 en adelante el medallón")

	var sheet: Texture2D = StickerArt.SHEET
	var ids: Array = StickerArt.IDS
	check.call(sheet.get_width() == ids.size() * StickerArt.CELL and sheet.get_height() == 2 * StickerArt.CELL and StickerArt.CELL == 52, "TX8: la hoja grande tiene 6 × 2 celdas de 52 px")
	var thermos_sheet: Texture2D = StickerArt.THERMOS_SHEET
	check.call(thermos_sheet.get_width() == ids.size() * StickerArt.THERMOS_CELL and thermos_sheet.get_height() == 2 * StickerArt.THERMOS_CELL, "TX8: la hoja del termo tiene 6 × 2 celdas de 25 px")
	var image: Image = sheet.get_image()
	var thermos_image: Image = thermos_sheet.get_image()
	var big_a_gold := 0
	var big_b_gold := 0
	for i in range(ids.size()):
		for style in range(2):
			var cell := Rect2i(i * StickerArt.CELL, style * StickerArt.CELL, StickerArt.CELL, StickerArt.CELL)
			check.call(_opaque(image, cell) > 1200, "TX8: %s tiene dibujo grande en el estilo %d" % [ids[i], style])
			check.call(image.get_pixel(cell.position.x, cell.position.y).a == 0, "TX8: %s grande (estilo %d) tiene la esquina transparente" % [ids[i], style])
			var tcell := Rect2i(i * StickerArt.THERMOS_CELL, style * StickerArt.THERMOS_CELL, StickerArt.THERMOS_CELL, StickerArt.THERMOS_CELL)
			check.call(_opaque(thermos_image, tcell) > 150, "TX8: %s tiene dibujo en el termo, estilo %d" % [ids[i], style])
			if style == 0: big_a_gold += _gold(image, cell)
			else: big_b_gold += _gold(image, cell)
	check.call(big_b_gold > big_a_gold * 2 and big_b_gold > 1000, "TX8: el estilo del nivel 10 es el dorado (%d contra %d píxeles de oro)" % [big_b_gold, big_a_gold])

	# El nivel llega al dibujo: cada vista toma el estilo de su sticker.
	var icon := StickerArt.new()
	check.call(icon.level == 1, "TX8: un sticker nuevo se dibuja con el estilo del nivel 1")
	icon.level = 10
	check.call(StickerArt.style_for_level(icon.level) == 1, "TX8: el mismo sticker en el nivel 10 pasa al medallón")
	icon.free()
	# Las zonas de clic y los lugares fijos del termo no se mueven con el estilo.
	var rect_before := StickerArt.thermos_rect("trio")
	var hit_1 := Thermos.badge_hit_rect("trio", {"trio": 9})
	var hit_2 := Thermos.badge_hit_rect("trio", {"trio": 10})
	check.call(rect_before == Rect2(Vector2(108, 134) - Vector2(19, 19), Vector2(38, 38)) and hit_1 == hit_2, "TX8: el lugar de cada sticker en el termo no cambia al pasar al nivel 10")
