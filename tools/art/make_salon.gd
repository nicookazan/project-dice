extends SceneTree
## Genera pixel-v3/salon-v3.png: el salón del club (720×150 px lógicos = 1440×300 px).
## Las ventanas se dibujan aparte (panorama animado); acá solo se dibuja su marco.
## Ejecutar: godot --headless --path . --script res://tools/art/make_salon.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const OUT := "res://assets/art/pixel-v3/salon-v3.png"
const BASE_PLATE := "res://assets/art/environment-v2/mesa-libreta-frontal-v1.png"
const W := 720
const H := 150

const WALL := [Color("2a160c"), Color("43240f"), Color("5e3414"), Color("7c4a1c"), Color("9a6228")]
const BEAM := [Color("1a0c06"), Color("2e1810"), Color("422212"), Color("5c3318")]
const CHAIR := [Color("1c0d07"), Color("33180c"), Color("4d2812"), Color("6a3a18")]
const SHADE := [Color("8a4a10"), Color("c87a18"), Color("f0a828"), Color("ffd060"), Color("fff0a0")]
const LEAF := [Color("0e2a14"), Color("1a4a22"), Color("2c6a30"), Color("4a8c3c")]
const FRAME := Color("c08a30")
const FRAME_DK := Color("6a3e12")
const PAPER := Color("d8c8a0")
const INK := Color("2a1a14")
const WINDOWS := [Rect2(470, 0, 47, 217), Rect2(534, 0, 378, 219), Rect2(952, 0, 92, 215), Rect2(1198, 43, 73, 177)]
# lámparas: [x, y de la pantalla, tamaño, ¿colgante?]
const LAMPS := [[150, 54, 17, true], [161, 86, 8, false], [547, 50, 17, true], [559, 88, 8, false]]

var img: Image

func hash2(x: int, y: int, s: int = 0) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0

func put(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H: img.set_pixel(x, y, c)

func rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(h):
		for i in range(w): put(x + i, y + j, c)

func halo(x: int, y: int) -> int:
	var boost := 0
	for l in LAMPS:
		var d := Vector2(x - l[0], (y - l[1]) * 1.25).length()
		var r: float = l[2] * 2.2
		if d < r * 0.5: boost = maxi(boost, 2)
		elif d < r: boost = maxi(boost, 1)
		elif d < r * 1.3 and (x + y) % 2 == 0: boost = maxi(boost, 1)
	return boost

func wall_color(x: int, y: int) -> Color:
	var idx := 2
	if y < 12: idx = 1
	if y >= 93:  # friso: boiserie de madera con tablones verticales
		idx = 1
		if y == 93: idx = 3
		elif y == 94: idx = 0
		elif (x + 5) % 22 == 0: idx = 0
	elif y > 88 and y < 93: idx = 1
	else:
		if y % 14 == 7 and hash2(x / 30, y, 1) > 0.6: idx -= 1
	idx = clampi(idx + halo(x, y), 0, 4)
	return WALL[idx]

func in_window(x: int, y: int) -> bool:
	for w in WINDOWS:
		if x * 2 >= w.position.x - 1 and x * 2 < w.end.x + 1 and y * 2 >= w.position.y and y * 2 < w.end.y: return true
	return false

func beam(x: int, y0: int, y1: int, w: int) -> void:
	for y in range(y0, y1):
		for i in range(w):
			var c: Color = BEAM[2]
			if i == 0: c = BEAM[0]
			elif i == 1: c = BEAM[3]
			elif i == w - 1: c = BEAM[0]
			elif i == w - 2: c = BEAM[1]
			put(x + i, y, c)

func window_frames() -> void:
	for w in WINDOWS:
		var x0 := int(w.position.x / 2.0)
		var x1 := ceili(w.end.x / 2.0)
		var y0 := int(w.position.y / 2.0)
		var y1 := ceili(w.end.y / 2.0)
		beam(x0 - 4, y0 - (4 if y0 > 0 else 0), y1 + 4, 4)
		beam(x1, y0 - (4 if y0 > 0 else 0), y1 + 4, 4)
		if y0 > 0:
			for x in range(x0 - 4, x1 + 4):
				put(x, y0 - 4, BEAM[0]); put(x, y0 - 3, BEAM[3]); put(x, y0 - 2, BEAM[2]); put(x, y0 - 1, BEAM[1])
		for x in range(x0 - 6, x1 + 6):
			put(x, y1, WALL[4]); put(x, y1 + 1, WALL[3]); put(x, y1 + 2, WALL[1]); put(x, y1 + 3, WALL[0])

func lamp(l: Array) -> void:
	var cx: int = l[0]
	var cy: int = l[1]
	var s: int = l[2]
	if l[3]:
		for y in range(0, cy - int(s * 0.5)): put(cx, y, BEAM[1])
		var hw := s
		for i in range(int(s * 0.9)):
			var y := cy - int(s * 0.45) + i
			var half := int(lerpf(s * 0.35, hw, i / (s * 0.9)))
			for x in range(cx - half, cx + half + 1):
				var u := float(x - cx) / maxf(half, 1)
				var idx := 3 if u < -0.35 else (4 if u < 0.1 else (3 if u < 0.5 else 2))
				if i >= int(s * 0.9) - 2: idx = 4
				put(x, y, SHADE[idx])
			put(cx - half - 1, y, SHADE[0]); put(cx + half + 1, y, SHADE[0])
		for x in range(cx - hw - 1, cx + hw + 2): put(x, cy + int(s * 0.45), SHADE[0])
		rect(cx - 2, cy - int(s * 0.5) - 2, 5, 3, BEAM[2])
	else:
		# lámpara de mesa: pie fino y pantalla chica
		rect(cx - 1, cy + 3, 2, 22, BEAM[1])
		rect(cx - 4, cy + 24, 9, 2, BEAM[2])
		for i in range(7):
			var half := 2 + i / 2
			for x in range(cx - half, cx + half + 1):
				put(x, cy - 3 + i, SHADE[3 if x < cx else 2])
			put(cx - half - 1, cy - 3 + i, SHADE[0]); put(cx + half + 1, cy - 3 + i, SHADE[0])
		for x in range(cx - 6, cx + 7): put(x, cy + 4, SHADE[4])

func picture(x: int, y: int, w: int, h: int, kind: String) -> void:
	rect(x, y, w, h, FRAME_DK)
	rect(x + 1, y + 1, w - 2, h - 2, FRAME)
	rect(x + 3, y + 3, w - 6, h - 6, FRAME_DK)
	rect(x + 4, y + 4, w - 8, h - 8, PAPER)
	for i in range(w - 8): put(x + 4 + i, y + h - 5, PAPER.darkened(0.12))
	var cx := x + w / 2
	var by := y + h - 5
	match kind:
		"dancers":
			for k in [-1, 1]:
				var hx: int = cx + k * 6
				for yy in range(by - 22, by): put(hx, yy, INK); put(hx + 1, yy, INK)
				for yy in range(by - 20, by - 8):
					for xx in range(hx - 1 - (by - 20 - yy) / 6 * 0 , hx + 3): put(xx, yy, INK)
				for a in range(-2, 3):
					for b in range(-2, 3):
						if a * a + b * b <= 5: put(hx + 1 + a, by - 26 + b, INK)
			for xx in range(cx - 6, cx + 8): put(xx, by - 14, INK)
		"building":
			rect(cx - 12, by - 14, 24, 14, INK)
			for a in range(-8, 9):
				for b in range(0, 9):
					if a * a + b * b * 1.4 <= 64: put(cx + a, by - 14 - b, INK)
			rect(cx, by - 30, 1, 10, INK)
			for k in range(-9, 10, 6): rect(cx + k, by - 10, 2, 7, PAPER)
		_:
			for a in range(-5, 6):
				for b in range(-5, 6):
					if a * a + b * b <= 22: put(cx + a, y + h / 2 - 6 + b, INK)
			for a in range(-9, 10):
				for b in range(0, 9):
					if a * a + b * b * 3 <= 84: put(cx + a, y + h / 2 + 2 + b, INK)

func chair(x: int, base: int, scale: int) -> void:
	var w := 14 * scale
	var h := 17 * scale
	var top := base - h
	for j in range(h):
		for i in range(w):
			var c: Color = WALL[0]
			var post := i < 4 or i >= w - 4
			if post:
				c = CHAIR[3] if i == 1 else (CHAIR[2] if i < 4 and i > 1 else (CHAIR[1] if i == w - 4 or i == w - 3 else CHAIR[0]))
			elif j < 4:
				c = CHAIR[3] if j == 0 else (CHAIR[2] if j < 3 else CHAIR[0])
			elif j >= h - 5:
				c = CHAIR[2] if j < h - 2 else CHAIR[0]
			elif (i - 4) % 6 < 3:
				c = CHAIR[2] if (i - 4) % 6 == 0 else CHAIR[1]
			put(x + i, top + j, c)

func table_top(x: int, y: int, rx: int) -> void:
	for dy in range(-2, 3):
		for dx in range(-rx, rx + 1):
			if (dx * dx) / float(rx * rx) + (dy * dy) / 6.0 <= 1.0:
				put(x + dx, y + dy, WALL[4] if dy < 0 else (WALL[3] if dy == 0 else WALL[2]))
	rect(x - rx + 2, y + 3, rx * 2 - 3, 1, WALL[0])

func pennant(x: int, y: int) -> void:
	rect(x - 2, y - 3, 38, 2, Color("d8a030"))
	for yy in range(0, 62):
		for xx in range(34):
			var c := Color("7cb8e0")
			if xx >= 11 and xx < 23: c = Color("f2f2ee")
			if xx == 0 or xx == 33: c = Color("2a5a8a")
			put(x + xx, y + yy, c)
	for k in range(0, 18):
		for xx in range(k, 34 - k):
			var c2 := Color("7cb8e0")
			if xx >= 11 and xx < 23: c2 = Color("f2f2ee")
			put(x + xx, y + 62 + k, c2)
	for a in range(-4, 5):
		for b in range(-4, 5):
			if a * a + b * b <= 14: put(x + 17 + a, y + 26 + b, Color("e8a830"))
	for xx in range(34): put(x + xx, y, Color("2a5a8a"))

func plant(x: int, base: int) -> void:
	rect(x - 12, base - 14, 26, 14, PixelLib.COPPER[2])
	rect(x - 12, base - 14, 26, 2, PixelLib.COPPER[3])
	rect(x - 12, base - 2, 26, 2, PixelLib.COPPER[0])
	rect(x - 14, base - 18, 30, 4, PixelLib.COPPER[1])
	for k in range(9):
		var ang := lerpf(-1.25, 1.25, k / 8.0)
		var len := 34 + (k % 3) * 8
		for t in range(len):
			var p := Vector2(x, base - 18) + Vector2(sin(ang) * t * 0.9, -cos(ang) * t * 0.8 + t * t * 0.004 * absf(sin(ang)))
			var th := 2 if t < len * 0.7 else 1
			for q in range(-th, th + 1):
				put(roundi(p.x) + q, roundi(p.y), LEAF[3 if q < 0 else (2 if q == 0 else 1)])
	for k in range(7):
		var ang2 := lerpf(-0.9, 0.9, k / 6.0)
		for t in range(0, 26 + (k % 2) * 6):
			var pt := Vector2(x, base - 18) + Vector2(sin(ang2) * t * 0.8, -cos(ang2) * t)
			put(roundi(pt.x), roundi(pt.y), LEAF[0])

func make() -> void:
	img = PixelLib.make(W, H)
	for y in range(H):
		for x in range(W): img.set_pixel(x, y, wall_color(x, y))
	# fondo del salón detrás del ventanal: mesas y sillas lejanas
	for tx in [[60, 134, 24], [175, 134, 22], [300, 134, 26], [440, 134, 24], [632, 134, 22], [695, 134, 24]]:
		table_top(tx[0], tx[1], tx[2])
	for c in [[-8, 146, 2], [26, 146, 2], [100, 146, 2], [196, 146, 2], [236, 146, 2], [280, 146, 2], [322, 146, 2], [360, 146, 2], [400, 146, 2], [490, 146, 2], [524, 146, 2], [566, 146, 2], [610, 146, 2], [650, 146, 2], [684, 146, 2]]:
		chair(c[0], c[1], c[2])
	beam(70, 0, 147, 13)
	beam(182, 0, 147, 11)
	beam(545, 0, 147, 11)
	window_frames()
	picture(0, 14, 50, 64, "dancers")
	picture(88, 20, 44, 64, "building")
	picture(160, 8, 22, 34, "portrait")
	picture(198, 30, 20, 30, "portrait")
	picture(552, 28, 20, 34, "portrait")
	picture(702, 14, 18, 62, "portrait")
	for l in LAMPS: lamp(l)
	pennant(656, 8)
	plant(704, 136)

func upscale(src: Image, k: int) -> Image:
	var big := src.duplicate() as Image
	big.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return big

func _init() -> void:
	make()
	img.save_png(OUT)
	var plate := Image.load_from_file(ProjectSettings.globalize_path(BASE_PLATE))
	plate.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	plate.convert(Image.FORMAT_RGBA8)
	var back := plate.duplicate() as Image
	plate.blend_rect(upscale(img, 2), Rect2i(0, 0, W * 2, H * 2), Vector2i(0, 0))
	for w in WINDOWS: plate.blit_rect(back, Rect2i(w), Vector2i(w.position))
	plate.save_png("res://test-results/salon-v3-preview.png")
	print("ok salon")
	quit()
