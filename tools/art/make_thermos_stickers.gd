extends SceneTree
## Genera termo-v3.png (72×165 px lógicos) y stickers-v3.png (6 × 19×19).
## Ejecutar: godot --headless --path . --script res://tools/art/make_thermos_stickers.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const STICKER_IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
const STICKER_COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}

const RED := [Color("5a1426"), Color("a02a40"), Color("e0506a")]
const AMBER := Color("e8a860")
const CREAM := Color("fff4d8")
const WINDOW_BLUE := Color("5f86b8")
const CLOTH_RED := Color("c0503c")

# Franjas del acero, de izquierda a derecha: [color, ancho]. Reflejos de color del entorno:
# madera oscura, lámparas ámbar, brillo crema, acero violáceo, ventana azul y paño bordó.
const BODY_BANDS := [
	["4a2e2e", 1], ["7a4a38", 2], ["c98a4a", 2], ["e8b070", 2], ["fff4d8", 1], ["f2dcb0", 2],
	["d2c8b8", 3], ["aeaabc", 4], ["8e8ca8", 3], ["88aed0", 2], ["a6c4dc", 2], ["9890a4", 4],
	["6a6076", 1], ["8a8296", 4], ["a0949a", 3], ["8a7078", 3], ["b05a4e", 3], ["7a3a42", 2], ["3c2430", 2]]

func body_colors() -> Array:
	var out: Array = []
	for band in BODY_BANDS:
		for i in range(band[1]): out.append(Color(band[0]))
	while out.size() < 48: out.insert(out.size() / 2, Color("9890a4"))
	var steel_base := Color("a8a098")
	var mixed: Array = []
	for c in out.slice(0, 48): mixed.append(c.lerp(steel_base, 0.25))
	return mixed

## Tiñe según la altura (ventana arriba, paño abajo) con transición dithereada de 1 px.
func tint(c: Color, x: int, y: int) -> Color:
	var shade := [0.42, 0.28, 0.16, 0.07]
	if y < 35: return c.darkened(shade[y - 31])
	var amount := 0.0
	var color := WINDOW_BLUE
	if y < 57: amount = 0.12
	elif y < 59: amount = 0.12 if (x + y) % 2 == 0 else 0.0
	
	elif y >= 150: amount = 0.34; color = CLOTH_RED
	elif y >= 126: amount = 0.2; color = CLOTH_RED
	elif y >= 124: amount = 0.2 if (x + y) % 2 == 0 else 0.0; color = CLOTH_RED
	
	return c.lerp(color, amount)

func make_thermos() -> Image:
	var img := PixelLib.make(72, 165)
	var blk := PixelLib.BLACK
	var cols := body_colors()
	# Cuerpo de acero con reflejos de color (x 19..66, y 31..162).
	for x in range(48):
		for y in range(31, 163): PixelLib.put(img, 19 + x, y, tint(cols[x], x, y))
	# Labio superior brillante y rayones finos.
	for x in range(48):
		PixelLib.put(img, 19 + x, 35, cols[x].lightened(0.3))
	for p in [Vector2i(30, 70), Vector2i(30, 71), Vector2i(48, 88), Vector2i(48, 89), Vector2i(55, 104), Vector2i(36, 128)]:
		PixelLib.put(img, p.x, p.y, img.get_pixel(p.x, p.y).lightened(0.22))
	# Pie: anillo con reflejo y banda inferior bronce.
	for x in range(48):
		PixelLib.put(img, 19 + x, 149, Color("3c2430"))
		PixelLib.put(img, 19 + x, 150, cols[x].lightened(0.35))
		for y in range(151, 163): PixelLib.put(img, 19 + x, y, tint(cols[x].darkened(0.3), x, y))
		PixelLib.put(img, 19 + x, 162, Color("2a1a20"))
	for p in [Vector2i(19, 162), Vector2i(66, 162)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# Collar negro con aro de latón.
	PixelLib.cylinder(img, 19, 20, 66, 30, blk)
	for x in range(19, 67):
		PixelLib.put(img, x, 20, blk[3] if x < 32 else blk[2])
		PixelLib.put(img, x, 30, blk[0])
	for x in range(21, 25): for y in range(21, 24): PixelLib.put(img, x, y, Color("6a5a48"))  # reflejo ámbar en el collar
	var gold := PixelLib.GOLD
	for x in range(19, 67):
		var t := float(x - 19) / 47.0
		PixelLib.put(img, x, 27, gold[4] if t < 0.3 else (gold[3] if t < 0.6 else gold[1]))
		PixelLib.put(img, x, 28, gold[3] if t < 0.3 else (gold[2] if t < 0.6 else gold[0]))
	# Anillo fino y tapa estriada con luz ámbar.
	PixelLib.cylinder(img, 23, 17, 62, 19, blk)
	for x in range(23, 63): PixelLib.put(img, x, 19, blk[0])
	PixelLib.cylinder(img, 25, 9, 60, 16, blk)
	for x in range(27, 59, 2):
		for y in range(11, 17): PixelLib.put(img, x, y, blk[0])
	for y in range(10, 15): PixelLib.put(img, 26, y, Color("a5703c"))
	for x in range(25, 61): PixelLib.put(img, x, 16, blk[0])
	PixelLib.cylinder(img, 27, 6, 58, 8, blk)
	for x in range(27, 59): PixelLib.put(img, x, 6, Color("d8b080") if x < 36 else blk[3])
	for p in [Vector2i(25, 9), Vector2i(60, 9), Vector2i(27, 6), Vector2i(58, 6)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# Pico rojo inclinado sobre la tapa (escalera de 4 pasos).
	for i in range(4):
		PixelLib.put(img, 43 - i, 1 + i, RED[2])
		PixelLib.put(img, 44 - i, 1 + i, RED[2])
		PixelLib.put(img, 45 - i, 1 + i, RED[1])
	PixelLib.put(img, 41, 5, RED[0])
	PixelLib.put(img, 42, 5, RED[0])
	# Asa de gancho con luz ámbar a la izquierda y reflejo frío a la derecha.
	PixelLib.cylinder(img, 3, 22, 7, 86, blk)
	PixelLib.cylinder(img, 3, 21, 19, 25, blk)
	for p in [Vector2i(3, 21), Vector2i(3, 86), Vector2i(7, 86), Vector2i(3, 85)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	for y in range(26, 86):
		for x in range(8, 19): img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(8, 19): PixelLib.put(img, x, 25, blk[0])
	for y in range(26, 80): PixelLib.put(img, 4, y, Color("8a5a3a") if y < 60 else Color("5a3a2c"))
	for y in range(26, 70): PixelLib.put(img, 7, y, Color("30344a"))
	PixelLib.outline(img)
	return img

func flat_die(img: Image, ox: int, oy: int, w: int, pips: Array, blank_tone := 3) -> void:
	var iv := PixelLib.IVORY
	for y in range(w):
		for x in range(w):
			var c: Color = iv[blank_tone]
			if x == 0 or y == 0: c = iv[4]
			if x == w - 1 or y == w - 1: c = iv[1]
			PixelLib.put(img, ox + x, oy + y, c)
	for p in pips: PixelLib.put(img, ox + p.x, oy + p.y, Color("3a2418"))

func make_sticker(id: String) -> Image:
	var img := PixelLib.make(19, 19)
	var base := Color(STICKER_COLORS[id])
	var base2 := base.darkened(0.12)
	var body: Array = [base.darkened(0.55), base.darkened(0.35), base2, base.lightened(0.25), base.lightened(0.5)]
	var ivory := PixelLib.IVORY
	for y in range(19):
		for x in range(19):
			var dx := x + 0.5 - 9.5
			var dy := y + 0.5 - 9.5
			var d := sqrt(dx * dx + dy * dy)
			if d > 9.5: continue
			var c: Color
			if d > 8.6: c = PixelLib.OUTLINE
			elif d > 7.2: c = ivory[3] if (dx + dy) < 2.0 else ivory[1]
			else: c = body[1] if ((dx + dy) > 4.0 and d > 5.8) else body[2]
			img.set_pixel(x, y, c)
	var pips3 := [Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)]
	var pips4 := [Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 3)]
	match id:
		"pair_loose":
			flat_die(img, 4, 7, 5, pips3)
			flat_die(img, 10, 7, 5, pips3)
		"trio":
			flat_die(img, 4, 4, 5, pips3)
			flat_die(img, 10, 4, 5, pips3)
			flat_die(img, 7, 10, 5, pips3)
		"straight":
			for i in range(5):
				var hgt := 2 * i + 2
				for y in range(hgt):
					for x in range(3):
						var c: Color = ivory[3]
						if y == 0: c = ivory[4]
						if x == 2: c = ivory[1]
						PixelLib.put(img, 2 + i * 3 + x, 15 - hgt + y + 1, c)
		"full":
			for i in range(3): flat_die(img, 3 + i * 5, 4, 4, [], 3)
			for i in range(2): flat_die(img, 5 + i * 6, 10, 4, [], 2)
		"poker":
			for pos in [Vector2i(4, 4), Vector2i(10, 4), Vector2i(4, 10), Vector2i(10, 10)]:
				flat_die(img, pos.x, pos.y, 5, pips4)
		"generala":
			flat_die(img, 5, 5, 9, [Vector2i(2, 2), Vector2i(6, 2), Vector2i(4, 4), Vector2i(2, 6), Vector2i(6, 6)])
			for p in [Vector2i(3, 3), Vector2i(15, 3), Vector2i(3, 15), Vector2i(15, 15)]: img.set_pixel(p.x, p.y, ivory[4])
	return img

func _init() -> void:
	var thermos := make_thermos()
	thermos.save_png("res://assets/art/pixel-v3/termo-v3.png")
	var sheet := PixelLib.make(19 * STICKER_IDS.size(), 19)
	for i in range(STICKER_IDS.size()):
		sheet.blit_rect(make_sticker(STICKER_IDS[i]), Rect2i(0, 0, 19, 19), Vector2i(i * 19, 0))
	sheet.save_png("res://assets/art/pixel-v3/stickers-v3.png")
	var big := thermos.duplicate() as Image
	big.resize(72 * 5, 165 * 5, Image.INTERPOLATE_NEAREST)
	big.save_png("res://test-results/termo-v3-x5.png")
	var big2 := sheet.duplicate() as Image
	big2.resize(sheet.get_width() * 8, 19 * 8, Image.INTERPOLATE_NEAREST)
	big2.save_png("res://test-results/stickers-v3-x8.png")
	print("ok")
	quit()
