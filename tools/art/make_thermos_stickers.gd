extends SceneTree
## Genera termo-v3.png (72×165 px lógicos) y stickers-v3.png (6 × 19×19).
## Ejecutar: godot --headless --path . --script res://tools/art/make_thermos_stickers.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const STICKER_IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
const STICKER_COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}

const RED := [Color("5a1426"), Color("a02a40"), Color("e0506a")]
const COOL_HINT := Color("8a98b0")
const WARM_HINT := Color("a07468")

# Acero en escala de grises, de izquierda a derecha: [color, ancho]. Un toque cálido en el
# reflejo izquierdo y frío en el borde derecho; el resto es gris puro para dar volumen.
const BODY_BANDS := [
	["32323a", 1], ["50505a", 2], ["74747e", 2], ["9c9ca4", 2], ["c6c4c4", 2], ["e8e4de", 2], ["fbf9f4", 1],
	["dedee0", 2], ["b8b8bc", 3], ["9c9ca4", 3], ["8c8c96", 4], ["a0a0aa", 3], ["84848e", 3],
	["70707a", 3], ["60606a", 3], ["52525c", 3], ["6a707c", 1], ["44444e", 2], ["2c2c34", 2]]

func body_colors() -> Array:
	var out: Array = []
	for band in BODY_BANDS:
		for i in range(band[1]): out.append(Color(band[0]))
	while out.size() < 48: out.insert(out.size() / 2, Color("8c8c96"))
	return out.slice(0, 48)

## Desplazamiento en arco (borde inferior de un cilindro visto desde arriba): 0 en los
## extremos y `depth` en el centro.
func arc(x: int, depth: float, x0: int, x1: int) -> int:
	var t := (x - (x0 + x1) / 2.0) / ((x1 - x0) / 2.0)
	return roundi(depth * (1.0 - t * t))

func tint(c: Color, x: int, y: int) -> Color:
	var amount := 0.0
	var color := COOL_HINT
	if y < 44: amount = 0.08
	elif y < 46: amount = 0.08 if (x + y) % 2 == 0 else 0.0
	elif y >= 128: amount = 0.09; color = WARM_HINT
	elif y >= 126: amount = 0.09 if (x + y) % 2 == 0 else 0.0; color = WARM_HINT
	return c.lerp(color, amount)

## Cilindro con sombreado por columnas y borde inferior en arco.
func shaped_cylinder(img: Image, x0: int, x1: int, y0: int, y1: int, depth: float, ramp: Array) -> void:
	var half := (x1 - x0) / 2.0
	var cx := (x0 + x1) / 2.0
	for x in range(x0, x1 + 1):
		var t := (x - cx) / half
		var c: Color
		if t < -0.78: c = ramp[1]
		elif t < -0.4: c = ramp[3]
		elif t < -0.05: c = ramp[4]
		elif t < 0.45: c = ramp[3]
		elif t < 0.8: c = ramp[2]
		else: c = ramp[1]
		var bottom := y1 + arc(x, depth, x0, x1)
		for y in range(y0, bottom + 1): PixelLib.put(img, x, y, c)
		PixelLib.put(img, x, bottom, ramp[0])

func make_thermos() -> Image:
	var img := PixelLib.make(72, 165)
	var blk := PixelLib.BLACK
	var cols := body_colors()
	# Cuerpo cilíndrico: base redondeada en arco y pie con aro curvo.
	for x in range(48):
		var px := 19 + x
		var collar_bottom := 29 + arc(px, 2, 19, 66)
		var bottom := 159 + arc(px, 3, 19, 66)
		var foot := 146 + arc(px, 3, 19, 66)
		for y in range(24, bottom + 1):
			var c := tint(cols[x], x, y)
			if y > foot + 1: c = c.darkened(0.22)
			if y == foot: c = cols[x].darkened(0.55)
			if y == foot + 1: c = cols[x].lightened(0.3)
			if y == bottom: c = cols[x].darkened(0.6)
			var under := y - collar_bottom
			if under >= 0 and under < 4: c = c.darkened([0.45, 0.3, 0.18, 0.08][under])
			if under == 4: c = c.lightened(0.15)
			PixelLib.put(img, px, y, c)
	for p in [Vector2i(19, 158), Vector2i(66, 158), Vector2i(19, 159), Vector2i(66, 159), Vector2i(20, 160), Vector2i(65, 160)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	for p in [Vector2i(30, 70), Vector2i(30, 71), Vector2i(48, 88), Vector2i(48, 89), Vector2i(55, 104), Vector2i(36, 128)]:
		PixelLib.put(img, p.x, p.y, img.get_pixel(p.x, p.y).lightened(0.18))
	# Collar negro (más angosto que el cuerpo) con aro de latón tenue, ambos en arco.
	shaped_cylinder(img, 20, 65, 20, 28, 2, blk)
	for x in range(20, 66):
		PixelLib.put(img, x, 20, blk[3] if x < 32 else blk[2])
		var t := float(x - 20) / 45.0
		var brass := PixelLib.GOLD[3].lerp(Color("a8a098"), 0.35)
		var shade := brass if t < 0.3 else (brass.darkened(0.2) if t < 0.65 else brass.darkened(0.5))
		var ring_y := 24 + arc(x, 2, 20, 65)
		PixelLib.put(img, x, ring_y, shade.lightened(0.15))
		PixelLib.put(img, x, ring_y + 1, shade.darkened(0.15))
	# Anillo fino y tapa estriada.
	shaped_cylinder(img, 24, 61, 16, 18, 1, blk)
	shaped_cylinder(img, 26, 59, 9, 15, 1, blk)
	for x in range(28, 58, 2):
		for y in range(11, 15 + arc(x, 1, 26, 59)): PixelLib.put(img, x, y, blk[0])
	for x in range(28, 58):
		var top := 6 - arc(x, 1, 28, 57)
		for y in range(top, 9): PixelLib.put(img, x, y, blk[4] if (x < 38 and y == top) else (blk[3] if y == top else blk[2]))
	for p in [Vector2i(28, 8), Vector2i(57, 8), Vector2i(28, 7), Vector2i(57, 7)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# Pico rojo inclinado sobre la tapa (escalera de 4 pasos).
	for i in range(4):
		PixelLib.put(img, 43 - i, 1 + i, RED[2])
		PixelLib.put(img, 44 - i, 1 + i, RED[2])
		PixelLib.put(img, 45 - i, 1 + i, RED[1])
	PixelLib.put(img, 41, 5, RED[0])
	PixelLib.put(img, 42, 5, RED[0])
	# Asa de gancho negra, redondeada, que cuelga libre.
	PixelLib.cylinder(img, 3, 22, 7, 86, blk)
	PixelLib.cylinder(img, 3, 21, 20, 25, blk)
	for p in [Vector2i(3, 21), Vector2i(3, 86), Vector2i(7, 86), Vector2i(3, 85), Vector2i(7, 85), Vector2i(3, 22)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	for y in range(26, 86):
		for x in range(8, 19): img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(8, 19): PixelLib.put(img, x, 25, blk[0])
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
