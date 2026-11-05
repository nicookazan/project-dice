extends RefCounted
## MON1: arte de las monedas nuevas. La hoja original no cambia y cada id nuevo toma su celda.
const CoinArt = preload("res://scripts/coin_art.gd")
const Coins = preload("res://scripts/coins.gd")

## sha256 de assets/art/pixel-v3/coins-v3.png (las 8 monedas originales, aprobadas): no se puede tocar.
const ORIGINAL_SHEET_SHA := "ab09151f44f2fd8bb1049d9815bf9979ad8ca1ad1aa782542de2118d378ca2fd"

static func _icon(id: String) -> CoinArt:
	var icon := CoinArt.new()
	icon.coin_id = id
	icon._ready()
	return icon

static func run(check: Callable) -> void:
	check.call(FileAccess.get_sha256("res://assets/art/pixel-v3/coins-v3.png") == ORIGINAL_SHEET_SHA, "MON1: la hoja de las 8 monedas originales no cambió")
	var ids: Array = CoinArt.NEW_IDS
	check.call(ids.size() == CoinArt.NEW_COLUMNS * CoinArt.NEW_ROWS and ids.size() == 18, "MON1: 16 monedas y 2 paquetes llenan la hoja de 6 × 3")
	var seen: Dictionary = {}
	for id in ids: seen[id] = true
	check.call(seen.size() == ids.size() and CoinArt.IDS.all(func(id): return not seen.has(id)), "MON1: los ids nuevos no se repiten ni pisan a los originales")
	var sheet: Texture2D = CoinArt.SHEET_NEW
	check.call(sheet.get_width() == 192 and sheet.get_height() == 96, "MON1: la hoja nueva mide 192 × 96 px (celdas de 32)")
	var image: Image = sheet.get_image()

	for index in range(ids.size()):
		var icon := _icon(ids[index])
		var atlas := icon.texture as AtlasTexture
		var expected := Rect2(Vector2(index % 6, index / 6) * 32.0, Vector2(32, 32))
		check.call(atlas != null and atlas.atlas == sheet and atlas.region == expected, "MON1: %s toma su celda de la hoja nueva" % ids[index])
		var cell_x: int = (index % 6) * 32
		var cell_y: int = (index / 6) * 32
		var opaque := 0
		for y in range(32):
			for x in range(32):
				if image.get_pixel(cell_x + x, cell_y + y).a > 0: opaque += 1
		check.call(opaque > 150, "MON1: la celda de %s tiene dibujo (%d píxeles)" % [ids[index], opaque])
		var corner_clear: bool = image.get_pixel(cell_x, cell_y).a == 0 and image.get_pixel(cell_x + 31, cell_y + 31).a == 0
		check.call(corner_clear, "MON1: la celda de %s tiene las esquinas transparentes" % ids[index])
		icon.free()

	# Las monedas originales siguen leyendo la hoja original en su lugar.
	var full := _icon("full")
	var roll := _icon("roll")
	check.call((full.texture as AtlasTexture).atlas == CoinArt.SHEET and (full.texture as AtlasTexture).region == Rect2(0, 0, 32, 32), "MON1: Full sigue en la primera celda de la hoja original")
	check.call((roll.texture as AtlasTexture).atlas == CoinArt.SHEET and (roll.texture as AtlasTexture).region == Rect2(96, 32, 32, 32), "MON1: Una tirada más sigue en su celda de la hoja original")
	full.free()
	roll.free()
	# Una moneda del catálogo sin arte sigue mostrando su abreviatura.
	var plain := _icon("pair_pts")
	check.call(plain.texture == null and plain.has_node("Provisional"), "MON1: una moneda sin arte sigue mostrando su abreviatura")
	check.call(Coins.DATA.has("pair_pts"), "MON1: la prueba usa una moneda real del catálogo")
	plain.free()
