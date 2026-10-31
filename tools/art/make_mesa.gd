extends SceneTree
## Genera el arte pixel-v3 de la mesa de juego (Fase 3):
##   mesa-v3.png        madera + paño bordó + frente + piso (720×314 lógicos, desde la fila 136)
##   termo-mesa-v3.png  el termo de la tienda alargado para la mesa (72×175)
##   mate-v3.png, vaso-v3.png  objetos sobre el paño
## Ejecutar: godot --path . --script res://tools/art/make_mesa.gd   (con GPU no hace falta; headless sirve)

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const OUT := "res://assets/art/pixel-v3/"
const W := 720
const H := 450
const TOP := 136
const BASE_PLATE := "res://assets/art/environment-v2/mesa-libreta-frontal-v1.png"

const WOOD := [Color("3b1608"), Color("6e2f10"), Color("9c4a16"), Color("c4661f"), Color("e08a32")]
const FLOOR := [Color("1f0f08"), Color("33190d"), Color("4a2612"), Color("62331a")]
const NAVY := [Color("0a1430"), Color("0f2048"), Color("163060")]
const PANO := [Color("2a0a12"), Color("6e1424"), Color("8c1c2e"), Color("a62838")]
const GREEN := [Color("0a2a1c"), Color("10402c"), Color("185a3c")]
const YERBA := [Color("2a4210"), Color("4a6a1c"), Color("6a8c2a")]
const BRASS_HI := Color("ffd060")
const BRASS := Color("e8a030")
const BRASS_LO := Color("8a4a18")

func hash2(x: int, y: int, s: int = 0) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 1442695041) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0

# ---------- geometría del paño (en px de 1440×900) ----------
func xl(xb: float, ypx: float) -> float:
	return 700.0 + (xb - 700.0) * (0.845 + 0.155 * (ypx - 315.0) / 339.0)

func in_pano(x: int, y: int) -> bool:
	var px := x * 2 + 1.0
	var py := y * 2 + 1.0
	return py >= 306.0 and py <= 671.0 and px >= xl(320.0, py) and px <= xl(1548.0, py)

const PANELS := [[339.0, 694.0], [714.0, 1086.0], [1104.0, 1529.0]]

func gold_at(x: int, y: int) -> Variant:
	var px := x * 2 + 1.0
	var py := y * 2 + 1.0
	for p in PANELS:
		var a := xl(p[0], py)
		var b := xl(p[1], py)
		if py >= 313.0 and py <= 655.0:
			if absf(px - a) < 1.0: return BRASS_HI
			if absf(px - b) < 1.0: return BRASS
			if px > a and px < b:
				if absf(py - 315.0) < 1.0: return BRASS_HI
				if absf(py - 653.0) < 1.0: return BRASS
	return null

const ORNAMENT := ["..##.##.....", ".####.###...", "######.####.", ".###..#####.", "..#.#..###..", ".#...#..#...", "#...........", "............"]

func flip_rows(rows: Array, fx: bool, fy: bool) -> Array:
	var out: Array = []
	for r in rows:
		var s: String = r
		if fx:
			var t := ""
			for i in range(s.length() - 1, -1, -1): t += s[i]
			s = t
		out.append(s)
	if fy: out.reverse()
	return out

func shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if x < 0 or x >= W or y < 0 or y >= H or not in_pano(x, y): continue
			var d := pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2)
			if d < 0.5: img.set_pixel(x, y, PANO[0].lerp(PANO[1], 0.35))
			elif d < 1.0: img.set_pixel(x, y, PANO[1].lerp(PANO[0], 0.65))
			elif d < 1.25 and (x + y) % 2 == 0: img.set_pixel(x, y, PANO[1].lerp(PANO[2], 0.45))

# ---------- mesa ----------
func edge_y(x: int) -> int:
	var t := (x - 363.0) / 363.0
	return TOP + roundi(11.5 * t * t) - 1

## Vetas en bloques: franjas de 2–3 filas con tramos largos de un tono, sin ruido fino.
func wood_tone(x: int, y: int, edge: int) -> Color:
	var band := int((y + int(hash2(int(y / 9), 2) * 3)) / 3)
	var run_len := 22 + int(hash2(band, 7) * 60)
	var rid := int((x + int(hash2(band, 3) * 90)) / run_len)
	var r := hash2(rid, band, 5)
	var idx := 3
	if r < 0.28: idx = 2
	elif r > 0.86: idx = 4
	var glow := (1.0 - float(y - edge) / 14.0) * (1.0 - absf(x - 380.0) / 420.0)
	if glow > 0.45: idx += 1
	return WOOD[clampi(idx, 1, 4)]

func navy_tone(x: int, y: int) -> Color:
	var idx := 1
	if (y - 371) % 7 == 0 and hash2(int(x / 40), int((y - 371) / 7), 9) > 0.45: idx = 0
	elif (y - 371) % 7 == 1 and hash2(int(x / 40), int((y - 371) / 7), 9) > 0.45: idx = 2
	return NAVY[idx]

func floor_tone(x: int, y: int) -> Color:
	var run_len := 14 + int(hash2(y, 17) * 40)
	var r := hash2(int((x + int(hash2(y, 4) * 80)) / run_len), y, 6)
	var idx := 2
	if r < 0.25: idx = 1
	elif r > 0.82: idx = 3
	var depth := y - 420
	if depth < 4: idx -= 2
	elif depth < 9: idx -= 1 if (x + y) % 2 == 0 or depth < 7 else 0
	var py := y * 2 + 1.0
	for k in range(-6, 7):
		var seam := 720.0 + k * 115.0
		var sx := seam + (seam - 720.0) * 0.105 * (py - 838.0) / 62.0
		if absf((x * 2 + 1.0) - sx) < 1.0: return FLOOR[0]
	return FLOOR[clampi(idx, 0, 3)]

func bracket(img: Image, ox: int, oy: int, mirror: bool) -> void:
	var m := Mask.new(15, 46)
	m.rect(0, 0, 3, 46)
	m.rect(0, 42, 8, 4)
	m.disc(8, 8, 6.4)
	m.erase_disc(8, 8, 3.2)
	m.erase_disc(2, 8, 2)
	m.rect(3, 14, 3, 10)
	m.disc(8, 28, 4.4)
	m.erase_disc(8, 28, 1.8)
	m.erase_disc(2, 28, 2)
	var rows := m.rows()
	if mirror: rows = flip_rows(rows, true, false)
	PixelLib.stamp_mask(img, rows, ox, oy, WOOD, WOOD[3])

func make_table() -> Image:
	var img := PixelLib.make(W, H)
	for y in range(TOP, H):
		for x in range(W):
			var c: Variant = null
			var edge := edge_y(x)
			if y < edge: continue
			if y < 353: c = wood_tone(x, y, edge)
			elif y < 355: c = WOOD[4] if y == 353 else WOOD[3]
			elif y < 363: c = WOOD[2] if y < 359 else WOOD[1]
			elif y < 367: c = WOOD[0].lerp(NAVY[0], 0.4 + 0.15 * (y - 363))
			elif y < 370: c = NAVY[0]
			elif y == 370: c = BRASS
			elif y == 371: c = BRASS_LO
			elif y < 416: c = navy_tone(x, y)
			elif y == 416: c = BRASS
			elif y < 420: c = Color("120a06")
			else: c = floor_tone(x, y)
			img.set_pixel(x, y, c)
	# línea oscura de borde trasero y brillo de la madera junto al fondo
	for x in range(W):
		var e := edge_y(x)
		img.set_pixel(x, e, WOOD[0])
	# paño: relleno con pelo corto, sombra proyectada y contorno
	for y in range(TOP, 345):
		for x in range(W):
			if not in_pano(x, y): continue
			var r := hash2(int(x / 2), y, 21)
			var c: Color = PANO[2]
			if r < 0.045: c = PANO[1]
			elif r > 0.97: c = PANO[3]
			img.set_pixel(x, y, c)
	for x in range(W):
		for k in range(3):
			var y := 336 + k
			var px := x * 2 + 1.0
			if px >= xl(320.0, 671.0) and px <= xl(1548.0, 671.0) and y == 336:
				img.set_pixel(x, y, PANO[0])
			if k > 0 and px >= xl(320.0, 671.0) + 4 and px <= xl(1548.0, 671.0) and y > 336:
				var wc: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, wc.darkened(0.45 if k == 1 else 0.25))
	for y in range(TOP, 345):
		for x in range(W):
			if not in_pano(x, y): continue
			var c: Variant = gold_at(x, y)
			if c != null: img.set_pixel(x, y, c)
	var corner_rows := {
		"tl": ORNAMENT, "tr": flip_rows(ORNAMENT, true, false),
		"bl": flip_rows(ORNAMENT, false, true), "br": flip_rows(ORNAMENT, true, true)}
	for p in PANELS:
		for corner in ["tl", "tr", "bl", "br"]:
			var ypx: float = 315.0 if corner.begins_with("t") else 653.0
			var xpx := xl(p[0] if corner.ends_with("l") else p[1], ypx)
			var lx := roundi(xpx / 2.0) + (3 if corner.ends_with("l") else -15)
			var ly := roundi(ypx / 2.0) + (3 if corner.begins_with("t") else -11)
			if lx < -8 or lx > W: continue
			PixelLib.stamp_mask(img, corner_rows[corner], lx, ly, PixelLib.GOLD, PixelLib.GOLD[2])
	# contorno del paño
	var marks: Array[Vector2i] = []
	for y in range(TOP, 345):
		for x in range(W):
			if in_pano(x, y) and not (in_pano(x - 1, y) and in_pano(x + 1, y) and in_pano(x, y - 1) and in_pano(x, y + 1)):
				marks.append(Vector2i(x, y))
	for m in marks: img.set_pixel(m.x, m.y, PANO[0])
	# sombras de contacto de los objetos sobre el paño
	shadow(img, 642, 260, 36, 6)
	shadow(img, 580, 266, 32, 6)
	shadow(img, 684, 307, 40, 7)
	# ménsulas del frente
	bracket(img, 2, 370, false)
	bracket(img, W - 17, 370, true)
	return img

# ---------- termo alargado ----------
func make_thermos_table() -> Image:
	var src := Image.load_from_file(ProjectSettings.globalize_path(OUT + "termo-v3.png"))
	var img := PixelLib.make(72, 175)
	for y in range(175):
		var sy := y if y <= 120 else (120 if y <= 130 else y - 10)
		for x in range(72): img.set_pixel(x, y, src.get_pixel(x, sy))
	return img

# ---------- mate ----------
func make_mate() -> Image:
	var img := PixelLib.make(68, 118)
	var cx := 30.0
	var wood: Array = WOOD
	# panza
	for y in range(58, 113):
		var hw := 0.0
		var foot := y >= 103
		if foot:
			hw = 13.0 + (y - 103) * 0.15
		else:
			var t := (y - 58.0) / 44.0
			hw = lerpf(24.0, 13.0, pow(t, 2.2)) + 6.0 * sin(PI * pow(t, 0.9))
		for x in range(int(cx - hw) - 1, int(cx + hw) + 2):
			var u := (x + 0.5 - cx) / hw
			if absf(u) > 1.0: continue
			var v := (y - 80.0) / 32.0
			var lit := -0.75 * u - 0.45 * v
			var idx := 0
			if lit > 0.62: idx = 4
			elif lit > 0.18: idx = 3
			elif lit > -0.28: idx = 2
			elif lit > -0.72: idx = 1
			if foot: idx = maxi(idx - 1, 0)
			var c: Color = wood[idx]
			if not foot:
				var d := pow((x + 0.5 - (cx + 3)) / 11.0, 2) + pow((y - 82.0) / 15.0, 2)
				var d2 := pow((x + 0.5 - (cx + 3)) / 5.0, 2) + pow((y - 82.0) / 7.0, 2)
				if absf(d - 1.0) < 0.2 or absf(d2 - 1.0) < 0.3: c = wood[maxi(idx - 1, 0)]
			img.set_pixel(x, y, c)
	for x in range(int(cx - 14), int(cx + 15)):
		img.set_pixel(x, 103, wood[0])
		img.set_pixel(x, 104, wood[3] if x < cx else wood[2])
	# virola de plata con greca
	for y in range(47, 58):
		for x in range(int(cx - 25), int(cx + 25)):
			var u := (x + 0.5 - cx) / 25.0
			var s := PixelLib.SILVER
			var idx := 2
			if u < -0.8: idx = 1
			elif u < -0.3: idx = 3
			elif u < 0.05: idx = 4
			elif u < 0.5: idx = 3
			elif u < 0.85: idx = 2
			else: idx = 1
			var c: Color = s[idx]
			var gy := y - 49
			if gy >= 0 and gy < 6:
				var gx := (x - 6) % 8
				var pat: Array = ["########", "#......#", "#.####.#", "#.#..#..", "#.#.####", "#.#....."]
				if String(pat[gy])[gx] == "#": c = s[0] if idx >= 3 else s[0].lerp(s[1], 0.3)
			img.set_pixel(x, y, c)
	# boca: aro de plata y yerba
	for y in range(36, 52):
		for x in range(int(cx - 26), int(cx + 27)):
			var d := pow((x + 0.5 - cx) / 25.0, 2) + pow((y - 44.0) / 7.0, 2)
			if d > 1.0: continue
			var c: Color = PixelLib.SILVER[3]
			if d < 0.66:
				var r := hash2(x, y, 31)
				c = YERBA[1]
				if r < 0.2: c = YERBA[0]
				elif r > 0.78: c = YERBA[2]
				if y < 42: c = c.darkened(0.12)
			elif x + y < cx + 44: c = PixelLib.SILVER[4]
			img.set_pixel(x, y, c)
	# bombilla
	for i in range(0, 41):
		var t := i / 40.0
		var bx := roundi(lerpf(33.0, 59.0, t))
		var by := roundi(lerpf(44.0, 6.0, t))
		PixelLib.put(img, bx, by, PixelLib.SILVER[3])
		PixelLib.put(img, bx + 1, by, PixelLib.SILVER[2])
		PixelLib.put(img, bx + 2, by, PixelLib.SILVER[1])
	for i in range(4):
		PixelLib.put(img, 58 + i, 4 + int(i / 3), PixelLib.SILVER[3 if i < 2 else 2])
		PixelLib.put(img, 58 + i, 5 + int(i / 3), PixelLib.SILVER[1])
	for i in range(23, 27):
		var t2 := i / 40.0
		var rx := roundi(lerpf(33.0, 59.0, t2))
		var ry := roundi(lerpf(44.0, 6.0, t2))
		for k in range(3): PixelLib.put(img, rx + k, ry, PixelLib.COPPER[3 if k == 0 else (2 if k == 1 else 1)])
	PixelLib.outline(img)
	return img

# ---------- vaso de cuero ----------
func arc(x: int, depth: float, x0: int, x1: int) -> int:
	var t := (x - (x0 + x1) / 2.0) / ((x1 - x0) / 2.0)
	return roundi(depth * (1.0 - t * t))

func make_cup() -> Image:
	var img := PixelLib.make(72, 94)
	var cx := 35.5
	var blk: Array = PixelLib.BLACK
	for y in range(8, 92):
		var hw := lerpf(35.0, 31.0, (y - 8.0) / 83.0)
		for x in range(int(cx - hw) - 1, int(cx + hw) + 2):
			var u := (x + 0.5 - cx) / hw
			if absf(u) > 1.0: continue
			var bottom := 87 + arc(x, 4.0, int(cx - hw), int(cx + hw))
			if y > bottom: continue
			var idx := 0
			if u < -0.84: idx = 1
			elif u < -0.6: idx = 2
			elif u < -0.42: idx = 1
			elif u > 0.8: idx = 0
			var c: Color = blk[idx]
			if y >= bottom - 1: c = blk[0].darkened(0.4)
			img.set_pixel(x, y, c)
	# costuras doradas
	for row in [[15, 3.0, 16], [83, 4.0, 4]]:
		for x in range(6, 66):
			if (x / 4) % 3 == 2: continue
			var hw2 := lerpf(35.0, 31.0, (row[0] - 8.0) / 83.0)
			if absf(x + 0.5 - cx) > hw2 - 2.0: continue
			var yy: int = row[0] + arc(x, float(row[1]), 4, 67)
			var shade := PixelLib.GOLD[3] if x < 30 else (PixelLib.GOLD[2] if x < 50 else PixelLib.GOLD[1])
			PixelLib.put(img, x, yy, shade)
	# boca: aro de cuero y fieltro verde
	for y in range(0, 17):
		for x in range(0, 72):
			var d := pow((x + 0.5 - cx) / 35.5, 2) + pow((y - 8.0) / 8.0, 2)
			if d > 1.0: continue
			var c: Color = blk[2] if (x + y) < 40 else blk[1]
			if d < 0.8:
				var din := pow((x + 0.5 - cx) / 31.5, 2) + pow((y - 8.5) / 6.0, 2)
				if din < 1.0:
					c = GREEN[2] if y > 7 else (GREEN[1] if y > 4 else GREEN[0])
					pass
				else:
					c = blk[1]
			img.set_pixel(x, y, c)
	PixelLib.outline(img)
	return img


func upscale(img: Image, k: int) -> Image:
	var big := img.duplicate() as Image
	big.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return big

func blit(dst: Image, src: Image, px: int, py: int) -> void:
	dst.blend_rect(upscale(src, 2), Rect2i(0, 0, src.get_width() * 2, src.get_height() * 2), Vector2i(px, py))

func _init() -> void:
	var table := make_table()
	var thermos := make_thermos_table()
	var mate := make_mate()
	var cup := make_cup()
	table.get_region(Rect2i(0, TOP, W, H - TOP)).save_png(OUT + "mesa-v3.png")
	thermos.save_png(OUT + "termo-mesa-v3.png")
	mate.save_png(OUT + "mate-v3.png")
	cup.save_png(OUT + "vaso-v3.png")
	# vista previa 1440×900 con las mismas posiciones que usa backdrop.gd
	var plate := Image.load_from_file(ProjectSettings.globalize_path(BASE_PLATE))
	plate.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	plate.convert(Image.FORMAT_RGBA8)
	blit(plate, table, 0, 0)
	blit(plate, thermos, 1203, 168)
	blit(plate, mate, 1088, 310)
	blit(plate, cup, 1280, 426)
	plate.save_png("res://test-results/mesa-v3-preview.png")
	print("ok mesa")
	quit()
