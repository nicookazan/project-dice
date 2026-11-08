extends RefCounted
## TX9 (D17): las monedas en ficha esmaltada. Una hoja con todas las celdas, en el orden de Coins.DATA más los paquetes.
const CoinArt = preload("res://scripts/coin_art.gd")
const Coins = preload("res://scripts/coins.gd")

static func _icon(id: String) -> CoinArt:
	var icon := CoinArt.new()
	icon.coin_id = id
	icon._ready()
	return icon

static func run(check: Callable) -> void:
	var expected: Array = Coins.DATA.keys()
	expected.append_array(["pack_small", "pack_large"])
	check.call(CoinArt.ALL_IDS == expected, "TX9: ALL_IDS sigue el orden de Coins.DATA más los dos paquetes (%d ids)" % CoinArt.ALL_IDS.size())
	var seen: Dictionary = {}
	for id in CoinArt.ALL_IDS: seen[id] = true
	check.call(seen.size() == CoinArt.ALL_IDS.size(), "TX9: ningún id se repite en la hoja")
	var sheet: Texture2D = CoinArt.SHEET
	check.call(sheet.get_width() == CoinArt.COLUMNS * 32 and sheet.get_height() == CoinArt.ROWS * 32, "TX9: la hoja mide %d × %d px (celdas de 32)" % [CoinArt.COLUMNS * 32, CoinArt.ROWS * 32])
	check.call(CoinArt.COLUMNS * CoinArt.ROWS >= CoinArt.ALL_IDS.size(), "TX9: la hoja tiene lugar para todas las celdas")
	var image: Image = sheet.get_image()
	var empty: Array = []
	var no_corner: Array = []
	for index in range(CoinArt.ALL_IDS.size()):
		var id: String = CoinArt.ALL_IDS[index]
		var icon := _icon(id)
		var atlas := icon.texture as AtlasTexture
		var expected_region := Rect2(Vector2(index % CoinArt.COLUMNS, index / CoinArt.COLUMNS) * 32.0, Vector2(32, 32))
		check.call(atlas != null and atlas.atlas == sheet and atlas.region == expected_region and not icon.has_node("Provisional"), "TX9: %s toma su celda y no cae en la ficha provisional" % id)
		var cell_x: int = (index % CoinArt.COLUMNS) * 32
		var cell_y: int = (index / CoinArt.COLUMNS) * 32
		var opaque := 0
		for y in range(32):
			for x in range(32):
				if image.get_pixel(cell_x + x, cell_y + y).a > 0: opaque += 1
		if opaque <= 150: empty.append(id)
		if not (image.get_pixel(cell_x, cell_y).a == 0 and image.get_pixel(cell_x + 31, cell_y + 31).a == 0): no_corner.append(id)
		icon.free()
	check.call(empty.is_empty(), "TX9: toda celda tiene dibujo (vacías: %s)" % str(empty))
	check.call(no_corner.is_empty(), "TX9: toda celda tiene las esquinas transparentes (sin: %s)" % str(no_corner))
	# Cada moneda del catálogo, aun las que antes eran provisionales, se dibuja con su ficha.
	var plain := _icon("pair_pts")
	check.call(plain.texture != null and not plain.has_node("Provisional"), "TX9: una moneda que antes era provisional ya tiene su dibujo")
	plain.free()
	var unknown := _icon("no_existe")
	check.call(unknown.texture == null, "TX9: un id fuera del catálogo no toma ninguna celda")
	unknown.free()
