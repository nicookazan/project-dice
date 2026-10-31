extends SceneTree
## Genera el arte pixel-v3 de la mesa de juego (Fase 3):
##   mesa-v3.png        madera + paño bordó + frente + piso (720×314 lógicos, desde la fila 136)
##   termo-mesa-v3.png  el termo de la tienda alargado para la mesa (72×175)
##   (mate-v3.png y vaso-v3.png salen de make_mate_vaso.gd)
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

## Sombra de contacto de un objeto apoyado en el paño: una sombra proyectada hacia la
## derecha (luz arriba-izquierda) y un núcleo más oscuro justo bajo la base. Dos tonos planos.
func shadow(img: Image, cx: float, base_y: float, rx: float) -> void:
	var cast_c := Vector2(cx + rx * 0.3, base_y + 1.0)
	var cast_r := Vector2(rx * 1.3, 6.0)
	var core_c := Vector2(cx, base_y - 1.0)
	var core_r := Vector2(rx * 0.97, 4.5)
	for y in range(int(base_y) - 8, int(base_y) + 9):
		for x in range(int(cx - rx * 1.7), int(cx + rx * 1.7)):
			if x < 0 or x >= W or y < 0 or y >= H or not in_pano(x, y): continue
			var dc := pow((x - core_c.x) / core_r.x, 2) + pow((y - core_c.y) / core_r.y, 2)
			var dk := pow((x - cast_c.x) / cast_r.x, 2) + pow((y - cast_c.y) / cast_r.y, 2)
			if dc <= 1.0: img.set_pixel(x, y, Color("3e0a16"))
			elif dk <= 1.0: img.set_pixel(x, y, Color("5c1222"))

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
	shadow(img, 644, 256, 24)
	shadow(img, 574, 268, 22)
	shadow(img, 676, 303, 34)
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

# ---------- vaso de cuero ----------
func upscale(img: Image, k: int) -> Image:
	var big := img.duplicate() as Image
	big.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return big

func blit(dst: Image, src: Image, px: int, py: int) -> void:
	dst.blend_rect(upscale(src, 2), Rect2i(0, 0, src.get_width() * 2, src.get_height() * 2), Vector2i(px, py))

func _init() -> void:
	var table := make_table()
	var thermos := make_thermos_table()
	var mate := Image.load_from_file(ProjectSettings.globalize_path(OUT + "mate-v3.png"))
	var cup := Image.load_from_file(ProjectSettings.globalize_path(OUT + "vaso-v3.png"))
	table.get_region(Rect2i(0, TOP, W, H - TOP)).save_png(OUT + "mesa-v3.png")
	thermos.save_png(OUT + "termo-mesa-v3.png")
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
