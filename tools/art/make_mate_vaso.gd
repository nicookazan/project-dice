extends SceneTree
## Mate y vaso de pixel-v3 (aprobada la opción A: píxel de 2×2 px). Salida: assets/art/pixel-v3/mate-v3.png y vaso-v3.png.
## También deja la variante fina (B) y la comparación en test-results/propuesta/.
## Ejecutar: godot --headless --path . --script res://tools/art/make_mate_vaso.gd

const OUT := "res://test-results/propuesta/"
const OUTLINE := Color("26140e")
const WOOD := [Color("2a1008"), Color("4a2010"), Color("6e341a"), Color("944a22"), Color("b8662c"), Color("d88840"), Color("f0b062")]
const SILVER := [Color("262c3c"), Color("444c60"), Color("667088"), Color("8c96ac"), Color("b4bece"), Color("dce2ec"), Color("ffffff")]
const COPPER := [Color("3a1808"), Color("6a3012"), Color("9a4a1e"), Color("c4703a"), Color("e89a5c")]
const YERBA := [Color("1c3010"), Color("2e4a16"), Color("48681e"), Color("688a2c"), Color("8cac48")]
const LEATHER := [Color("07070b"), Color("101016"), Color("191921"), Color("24242e"), Color("34343f"), Color("4c4c5a"), Color("7a7a8a")]
const FELT := [Color("051c16"), Color("0a3426"), Color("124c36"), Color("1a6446"), Color("26805a")]
const GOLD := [Color("3a2408"), Color("6a420e"), Color("a06a18"), Color("d09a28"), Color("f0c850"), Color("ffe488"), Color("fff8c0")]
const KEY := ["########", "#......#", "#.####.#", "#.#..#..", "#.#.####", "#.#....."]

func pick(r: Array, t: float) -> Color:
	return r[clampi(int(t * r.size()), 0, r.size() - 1)]

func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Array:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var q := a + ab * t
	var n := Vector2(-ab.y, ab.x).normalized()
	return [p.distance_to(q), t, (p - q).dot(n)]

# ---------------- mate (marco 136×236 px de pantalla) ----------------
func mate_px(x: float, y: float) -> Variant:
	var p := Vector2(x, y)
	# bombilla
	var s1 := seg_dist(p, Vector2(66, 92), Vector2(118, 10))
	if s1[0] <= 3.2:
		var t: float = (s1[2] + 3.2) / 6.4
		var idx := 3
		if t < 0.18: idx = 4
		elif t < 0.42: idx = 6
		elif t < 0.62: idx = 5
		elif t < 0.82: idx = 3
		else: idx = 1
		var u: float = s1[1]
		if (u > 0.5 and u < 0.58) or (u > 0.63 and u < 0.67):
			return COPPER[clampi(int(t * 5.0), 0, 4)]
		return SILVER[idx]
	var s2 := seg_dist(p, Vector2(118, 10), Vector2(133, 4))
	if s2[0] <= 3.0:
		return SILVER[6 if s2[2] < -1.0 else (4 if s2[2] < 1.2 else 2)]
	# boca: aro de plata y yerba
	var dm := pow((x - 60.0) / 52.0, 2) + pow((y - 86.0) / 14.0, 2)
	if dm <= 1.0:
		var din := pow((x - 60.0) / 44.0, 2) + pow((y - 87.0) / 10.0, 2)
		if din <= 1.0:
			var bx := floorf(x / 5.0)
			var by := floorf(y / 4.0)
			var n := fmod(absf(sin(bx * 12.9898 + by * 78.233) * 43758.5453), 1.0)
			var t2 := 0.35 + n * 0.45 + (0.18 if (x < 62.0 and y > 86.0) else 0.0)
			if din > 0.55 and y < 90.0: t2 -= 0.3
			return pick(YERBA, t2)
		var lit := -0.5 * (x - 60.0) / 52.0 - 0.85 * (y - 86.0) / 14.0
		return pick(SILVER, 0.55 + lit * 0.32)
	# virola con greca
	var u := (x - 60.0) / 50.0
	if absf(u) <= 1.0 and y >= 88.0 and y <= 120.0 + 6.0 * (1.0 - u * u):
		var z := sqrt(maxf(0.0, 1.0 - u * u))
		var lit2 := -0.6 * u + 0.8 * z
		var base := pick(SILVER, 0.12 + lit2 * 0.5)
		var yy := y - (94.0 + 5.0 * (1.0 - u * u))
		if yy >= 2.0 and yy < 20.0:
			var gx := int(floorf((x + 400.0) / 3.0)) % 8
			var gy := int(floorf((yy - 2.0) / 3.0))
			if String(KEY[gy])[gx] == "#": return pick(SILVER, 0.08 + lit2 * 0.3)
		if yy > 21.0: return pick(SILVER, 0.2 + lit2 * 0.25)
		return base
	# panza y pie
	var nx := (x - 60.0) / 54.0
	var ny := (y - 150.0) / 62.0
	var inside := nx * nx + ny * ny <= 1.0 and y >= 100.0 and y <= 203.0
	var foot := y > 200.0 and y <= 222.0 + 6.0 * (1.0 - nx * nx) and absf(x - 60.0) <= 28.0 + (y - 203.0) * 0.1
	if inside or foot:
		var z2 := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
		if foot and not inside:
			nx = (x - 60.0) / 30.0
			z2 = sqrt(maxf(0.0, 1.0 - nx * nx))
			ny = 0.3
		var lit3 := -0.5 * nx - 0.55 * ny + 0.65 * z2
		var t3 := (lit3 + 0.35) / 1.35
		if y < 132.0: t3 -= 0.16 * (1.0 - (y - 112.0) / 20.0)
		for ring in [[20.0, 30.0], [11.0, 17.0], [4.5, 7.0]]:
			var d1 := pow((x - 74.0) / ring[0], 2) + pow((y - 160.0) / ring[1], 2)
			if absf(sqrt(d1) - 1.0) < 0.09: t3 -= 0.13
		if nx > 0.74 or ny > 0.82: t3 += 0.08
		if foot and not inside: t3 += 0.02 - (0.2 if y < 208.0 else 0.0)
		return pick(WOOD, t3)
	return null

# ---------------- vaso (marco 144×188 px) ----------------
func cup_px(x: float, y: float) -> Variant:
	var cx := 72.0
	var hw := 70.0 - 10.0 * clampf((y - 16.0) / 160.0, 0.0, 1.0)
	var u := (x - cx) / hw
	# boca
	var do := pow((x - cx) / 70.0, 2) + pow((y - 16.0) / 15.0, 2)
	if do <= 1.0:
		var din := pow((x - cx) / 61.0, 2) + pow((y - 18.0) / 10.5, 2)
		if din <= 1.0:
			var tf := 0.1 + clampf((y - 8.0) / 22.0, 0.0, 1.0) * 0.8
			return pick(FELT, tf)
		var lit := -0.5 * (x - cx) / 70.0 - 0.75 * (y - 16.0) / 15.0
		return pick(LEATHER, 0.62 + lit * 0.3)
	if absf(u) <= 1.0 and y >= 16.0 and y <= 172.0 + 10.0 * (1.0 - u * u):
		var z := sqrt(maxf(0.0, 1.0 - u * u))
		var lit2 := -0.5 * u + 0.78 * z
		var t := (lit2 + 0.2) / 1.5 * 0.7
		if absf(u + 0.56) < 0.045: t += 0.16
		if y < 32.0: t -= 0.12 * (1.0 - (y - 16.0) / 16.0)
		var yb := 172.0 + 10.0 * (1.0 - u * u)
		if y > yb - 3.0: t += 0.1
		if y > yb - 0.8: t -= 0.3
		# arrugas del cuero
		for w in [[30.0, 76.0, 22.0], [86.0, 112.0, 18.0], [52.0, 128.0, 26.0], [104.0, 88.0, 14.0]]:
			if absf(y - (w[1] + 3.0 * (1.0 - u * u))) < 1.2 and x > w[0] and x < w[0] + w[2]: t -= 0.1
		# costuras doradas
		for sy in [40.0, 150.0]:
			var yy: float = sy + 10.0 * (1.0 - u * u)
			if absf(u) < 0.93 and fmod(x + 500.0, 20.0) < 14.0:
				if absf(y - yy) <= 2.3: return pick(GOLD, 0.62 - u * 0.3)
				if y > yy + 2.3 and y < yy + 4.6: t -= 0.14
		return pick(LEATHER, t)
	return null

func render(f: Callable, w: int, h: int, p: int) -> Image:
	var img := Image.create(w / p, h / p, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for j in range(h / p):
		for i in range(w / p):
			var c: Variant = f.call((i + 0.5) * p, (j + 0.5) * p)
			if c != null: img.set_pixel(i, j, c)
	var marks: Array[Vector2i] = []
	for j in range(img.get_height()):
		for i in range(img.get_width()):
			if img.get_pixel(i, j).a > 0: continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = i + d.x
				var ny: int = j + d.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and img.get_pixel(nx, ny).a > 0:
					marks.append(Vector2i(i, j))
					break
	for m in marks: img.set_pixel(m.x, m.y, OUTLINE)
	return img

func up(img: Image, k: int) -> Image:
	var b := img.duplicate() as Image
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var plate := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/environment-v2/mesa-libreta-frontal-v1.png"))
	plate.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	plate.get_region(Rect2i(1080, 300, 370, 330)).save_png(OUT + "original.png")
	for p in [2, 1]:
		var tag := "A" if p == 2 else "B"
		var mate := render(mate_px, 136, 236, p)
		var cup := render(cup_px, 144, 188, p)
		if p == 2:
			mate.save_png("res://assets/art/pixel-v3/mate-v3.png")
			cup.save_png("res://assets/art/pixel-v3/vaso-v3.png")
		up(mate, 6 if p == 2 else 3).save_png(OUT + "mate-" + tag + ".png")
		up(cup, 6 if p == 2 else 3).save_png(OUT + "vaso-" + tag + ".png")
		# escena: paño bordó con ambos, a tamaño de pantalla (×2 para verlo mejor)
		var scene := Image.create(370, 330, false, Image.FORMAT_RGBA8)
		scene.fill(Color("8c1c2e"))
		var mate_big := up(mate, p)
		var cup_big := up(cup, p)
		scene.blend_rect(mate_big, Rect2i(0, 0, 136, 236), Vector2i(10, 70))
		scene.blend_rect(cup_big, Rect2i(0, 0, 144, 188), Vector2i(200, 120))
		scene.resize(740, 660, Image.INTERPOLATE_NEAREST)
		scene.save_png(OUT + "escena-" + tag + ".png")
	print("ok propuesta")
	quit()
