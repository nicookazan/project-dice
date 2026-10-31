extends SceneTree
## Genera termo-v3.png (72×165 px lógicos) y stickers-v3.png (6 × 19×19).
## Ejecutar: godot --headless --path . --script res://tools/art/make_thermos_stickers.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const STICKER_IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
const STICKER_COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}

func make_thermos() -> Image:
	var img := PixelLib.make(72, 165)
	var steel := PixelLib.SILVER
	var blk := PixelLib.BLACK
	# Asa negra a la izquierda.
	PixelLib.cylinder(img, 3, 38, 8, 104, blk)
	PixelLib.cylinder(img, 3, 38, 20, 45, blk)
	PixelLib.cylinder(img, 3, 97, 20, 104, blk)
	for p in [Vector2i(3, 38), Vector2i(3, 104)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	for y in range(38, 105):
		for x in range(3, 21):
			if img.get_pixel(x, y).a > 0 and x > 8 and y > 45 and y < 97: img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(9, 21):  # sombras de las uniones
		PixelLib.put(img, x, 45, blk[0])
		PixelLib.put(img, x, 97, blk[2])
	# Cuerpo.
	PixelLib.cylinder(img, 19, 40, 66, 162, steel)
	for x in range(19, 67):
		PixelLib.put(img, x, 40, steel[0])
		PixelLib.put(img, x, 41, steel[1])
		for y in range(152, 163): PixelLib.put(img, x, y, steel[1] if (x < 24 or x > 60) else steel[2])
		PixelLib.put(img, x, 152, steel[0])
		PixelLib.put(img, x, 162, steel[0])
	for p in [Vector2i(19, 162), Vector2i(66, 162)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# Hombros escalonados.
	PixelLib.cylinder(img, 21, 31, 64, 39, steel)
	for x in range(21, 65): PixelLib.put(img, x, 31, steel[0])
	PixelLib.cylinder(img, 24, 24, 61, 30, steel)
	for x in range(24, 62): PixelLib.put(img, x, 24, steel[0])
	PixelLib.cylinder(img, 27, 17, 58, 23, steel)
	for x in range(27, 59): PixelLib.put(img, x, 17, steel[0])
	# Tapa negra con estrías.
	PixelLib.cylinder(img, 29, 3, 56, 16, blk)
	for x in range(31, 56, 3):
		for y in range(6, 16): PixelLib.put(img, x, y, blk[0])
	for x in range(29, 57): PixelLib.put(img, x, 3, blk[3])
	for p in [Vector2i(29, 3), Vector2i(56, 3)]: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
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
