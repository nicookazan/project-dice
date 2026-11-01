extends SceneTree
## Mate de pixel-v3: calabaza redonda con aro, collar y tiras de plata, panel de cuero en dos tonos de marrón
## y bombilla de metal en perspectiva (codo, boquilla con abertura y virola dorada) hundida en la yerba.
## Aprobado como opción Z2 (píxel de 2×2 px, marco 136×236). Salida: assets/art/pixel-v3/mate-v3.png
## y una ampliación ×6 en test-results/propuesta/mate-v3-x6.png.
## Ejecutar: godot --headless --path . --script res://tools/art/make_mate.gd

const OUT := "res://assets/art/pixel-v3/mate-v3.png"
const PREVIEW := "res://test-results/propuesta/mate-v3-x6.png"
const OUTLINE := Color("26140e")
const SILVER := [Color("262c3c"), Color("444c60"), Color("667088"), Color("8c96ac"), Color("b4bece"), Color("dce2ec"), Color("ffffff")]
const GOLD := [Color("3a2408"), Color("6a420e"), Color("a06a18"), Color("d09a28"), Color("f0c850"), Color("ffe488"), Color("fff8c0")]
const YERBA := [Color("1c3010"), Color("2e4a16"), Color("48681e"), Color("688a2c"), Color("8cac48")]
# marrones con corrimiento de tono: sombras hacia el bordó, luces hacia el ocre
const GOURD := [Color("170a0a"), Color("2a1210"), Color("401c14"), Color("58281a"), Color("723620"), Color("8e4826"), Color("aa5e2e"), Color("c47a3c"), Color("dc9a52"), Color("efc078")]

const W := 136
const H := 236
const PX := 2
# el dibujo se modela con el fondo en y = 200; se baja para que apoye sobre la sombra de contacto
# que make_mesa.gd hornea en el paño (y ≈ 226 dentro del marco)
const DROP := 26.0
# contraste entre la mitad clara y la oscura del panel de cuero
const PANEL := 0.24
# punto donde la bombilla entra en la yerba (en el hueco húmedo)
const ENTRY := Vector2(72, 104)
# grosor de la bombilla en la yerba y cuánto se ensancha hacia la punta (perspectiva)
const BW := 4.2
const GROW := 0.5
const N_SHAFT := 24
const N_ELBOW := 6

var chain: Array[Vector2] = []
var last_bomb := false

func pick(r: Array, t: float) -> Color:
	return r[clampi(int(t * r.size()), 0, r.size() - 1)]

func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Array:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var q := a + ab * t
	var n := Vector2(-ab.y, ab.x).normalized()
	return [p.distance_to(q), t, (p - q).dot(n)]

func hash2(x: float, y: float) -> float:
	return fmod(absf(sin(floorf(x / 2.0) * 12.9898 + floorf(y / 2.0) * 78.233) * 43758.5453), 1.0)

func metal(t: float, pal: Array = SILVER) -> Color:
	# perfil de cilindro pulido sin negro puro: borde, brillo, cuerpo, sombra y rebote
	var idx := 3
	if t < 0.08: idx = 1
	elif t < 0.18: idx = 2
	elif t < 0.28: idx = 4
	elif t < 0.36: idx = 6
	elif t < 0.46: idx = 5
	elif t < 0.6: idx = 4
	elif t < 0.76: idx = 3
	elif t < 0.88: idx = 2
	elif t < 0.94: idx = 3
	else: idx = 1
	return pal[idx]

# ---------------- bombilla ----------------
func build_chain() -> void:
	# caño: sale de adentro de la yerba y sube arqueándose hacia la derecha
	var p0 := ENTRY + Vector2(0, 4)
	var p1 := Vector2(75, 62)
	var p2 := Vector2(84, 44)
	var p3 := Vector2(94, 31)
	for i in range(0, N_SHAFT + 1):
		var t := i / float(N_SHAFT)
		chain.append(p0 * pow(1 - t, 3) + p1 * 3 * pow(1 - t, 2) * t + p2 * 3 * (1 - t) * t * t + p3 * pow(t, 3))
	# codo: arco corto que lleva el caño a horizontal
	var c := Vector2(108, 33)
	var r := 14.0
	var a0 := atan2(p3.y - c.y, p3.x - c.x)
	var a1 := -PI / 2.0
	for i in range(1, N_ELBOW + 1):
		var a := lerpf(a0, a1, i / float(N_ELBOW))
		chain.append(c + Vector2(cos(a), sin(a)) * r)

func bombilla(x: float, y: float) -> Variant:
	var p := Vector2(x, y)
	var wmax := BW * (1.0 + GROW)
	# boquilla: pieza achatada horizontal con collarín dorado y la abertura oscura en la punta
	var m0: Vector2 = chain[chain.size() - 1]
	var m1 := m0 + Vector2(13, 1)
	var sm := seg_dist(p, m0, m1)
	var wm := wmax * 0.86
	if sm[0] <= wm and sm[1] > 0.0:
		var tm: float = clampf((sm[2] + wm) / (wm * 2.0), 0.0, 1.0)
		if sm[1] > 0.93: return SILVER[1] if tm > 0.25 and tm < 0.8 else metal(tm)
		if sm[1] < 0.12: return metal(tm, GOLD)
		return metal(tm)
	var best := 1e9
	var bt := -1.0
	var bk := 0.0
	var n := chain.size() - 1
	for i in range(n):
		var sd := seg_dist(p, chain[i], chain[i + 1])
		var k := (float(i) + float(sd[1])) / float(n)
		# perspectiva: la punta está más cerca de la cámara, por eso se ensancha hacia arriba
		var wd := BW * (1.0 + GROW * minf(1.0, k * 1.15))
		if sd[0] <= wd and sd[0] < best:
			best = sd[0]
			bt = clampf((sd[2] + wd) / (wd * 2.0), 0.0, 1.0)
			bk = k
	if bt < 0.0: return null
	# virola dorada a mitad del caño con una línea grabada
	if bk > 0.40 and bk < 0.58:
		if absf(bk - 0.49) < 0.012: return GOLD[1]
		return metal(bt, GOLD)
	# hojitas de yerba pegadas al caño justo sobre la superficie
	if y > ENTRY.y - 12.0 and hash2(x, y) < 0.16: return YERBA[2 + int(hash2(y, x) * 2.0)]
	# destellos sobre la franja de brillo
	if bt > 0.28 and bt < 0.36 and fmod(bk * 60.0, 7.0) < 0.9: return SILVER[6]
	var mc := metal(bt)
	# reflejo verdoso de la yerba en el tramo bajo del metal
	if y > ENTRY.y - 16.0: mc = mc.lerp(YERBA[2], 0.28 * clampf((y - (ENTRY.y - 16.0)) / 14.0, 0.0, 1.0))
	return mc

# ---------------- yerba ----------------
func yerba_px(x: float, y: float) -> Color:
	var bx := floorf(x / 5.0)
	var by := floorf(y / 4.0)
	var n := fmod(absf(sin(bx * 12.9898 + by * 78.233) * 43758.5453), 1.0)
	return pick(YERBA, 0.35 + n * 0.45 + (0.18 if (x < 62.0 and y > 100.0) else 0.0))

func wet_px(x: float, y: float) -> Variant:
	# hueco húmedo donde entra la bombilla: yerba más oscura, sombra a la derecha del caño y un brillo de agua
	var dh := pow((x - ENTRY.x) / 15.0, 2) + pow((y - ENTRY.y) / 5.0, 2)
	if dh > 1.0: return null
	var t := 0.12 + hash2(x, y) * 0.3 + dh * 0.25
	if x > ENTRY.x + 3.0 and x < ENTRY.x + 11.0 and y < ENTRY.y + 1.0: t -= 0.12
	if absf(y - (ENTRY.y - 2.0)) < 0.9 and x < ENTRY.x - 4.0 and x > ENTRY.x - 11.0: return YERBA[4]
	return pick(YERBA, t)

# ---------------- mate ----------------
func mate_px(x: float, y: float) -> Variant:
	last_bomb = false
	# la yerba tapa el arranque de la bombilla con un borde irregular: se ve hundida, no apoyada encima
	var din0 := pow((x - 60.0) / 41.0, 2) + pow((y - 101.0) / 8.5, 2)
	if din0 <= 1.0 and absf(x - ENTRY.x) < 9.0 and y > ENTRY.y - 1.0:
		if y > ENTRY.y + 1.0 or hash2(x + 5.0, y) < 0.5:
			var w: Variant = wet_px(x, y)
			return w if w != null else yerba_px(x, y)
	var bb: Variant = bombilla(x, y)
	last_bomb = bb != null
	if bb != null: return bb
	# boca: aro de plata con yerba
	var dm := pow((x - 60.0) / 50.0, 2) + pow((y - 100.0) / 13.0, 2)
	if dm <= 1.0:
		var din := pow((x - 60.0) / 41.0, 2) + pow((y - 101.0) / 8.5, 2)
		if din <= 1.0:
			var wp: Variant = wet_px(x, y)
			if wp != null: return wp
			var bx := floorf(x / 5.0)
			var by := floorf(y / 4.0)
			var n := fmod(absf(sin(bx * 12.9898 + by * 78.233) * 43758.5453), 1.0)
			var t2 := 0.35 + n * 0.45 + (0.18 if (x < 62.0 and y > 100.0) else 0.0)
			if din > 0.55 and y < 103.0: t2 -= 0.3
			return pick(YERBA, t2)
		var lit := -0.5 * (x - 60.0) / 50.0 - 0.85 * (y - 100.0) / 13.0
		return pick(SILVER, 0.6 + lit * 0.32)
	# panza esférica; el fondo está apenas aplanado y se apoya solo, sin base
	var nx := (x - 60.0) / 54.0
	var ny := (y - 150.0) / 54.0
	var r2 := nx * nx + ny * ny
	if r2 > 1.0 or y < 102.0 or y > 200.0: return null
	var z := sqrt(maxf(0.0, 1.0 - r2))
	# collar de plata bajo la boca, con remaches
	var u := (x - 60.0) / 50.0
	var yy := y - (106.0 + 6.0 * (1.0 - u * u))
	if absf(u) <= 1.0 and yy >= 0.0 and yy < 9.0:
		var lc := -0.6 * u + 0.7 * sqrt(maxf(0.0, 1.0 - u * u))
		if yy > 7.0: return pick(SILVER, 0.18 + lc * 0.3)
		if fmod(x + 400.0, 11.0) < 2.0 and yy > 2.0 and yy < 6.0: return SILVER[1]
		return pick(SILVER, 0.35 + lc * 0.5 - yy * 0.012)
	# tiras de plata: bajan por la panza y rematan en un remache
	for side in [-1.0, 1.0]:
		var rv := Vector2(60.0 + side * 0.8 * sqrt(54.0 * 54.0 - 40.0 * 40.0), 190.0)
		var dr := Vector2(x, y).distance_to(rv)
		if dr <= 3.6: return SILVER[1] if dr > 2.8 else pick(SILVER, 0.75 - (y - rv.y + x - rv.x) * 0.06)
		var sx: float = 60.0 + side * 0.8 * sqrt(maxf(0.0, 54.0 * 54.0 - (y - 150.0) * (y - 150.0)))
		if absf(x - sx) <= 3.0 and y > 114.0 and y < 190.0:
			if absf(x - sx) > 2.2: return SILVER[1]
			return metal(clampf((x - sx + 3.0) / 6.0, 0.0, 1.0))
	# luz difusa desde arriba a la izquierda, con rango completo de la paleta
	var lit3 := -0.55 * nx - 0.6 * ny + 0.75 * z
	var t3 := (lit3 + 0.45) / 1.55
	# panel de cuero: mitad superior más clara, inferior más oscura, con costura dorada en la diagonal
	var dg := y - (130.0 + 0.78 * (x - 26.0))
	t3 += PANEL * 0.5 if dg < 0.0 else -PANEL
	if absf(dg) < 1.1 and fmod(x + 400.0, 6.0) < 3.4 and x > 30.0 and x < 94.0:
		return pick(GOLD, 0.45 + (-0.3 * nx) * 0.3)
	# manchas suaves de la calabaza
	t3 += 0.07 * sin(x * 0.13 + y * 0.07) * sin(y * 0.11 - x * 0.05 + 1.3)
	# brillo puntual arriba a la izquierda y luz de rebote cálida en el borde derecho
	if pow((x - 36.0) / 9.0, 2) + pow((y - 128.0) / 6.0, 2) <= 1.0: t3 += 0.16
	if r2 > 0.8 and nx > 0.45 and ny > -0.4: t3 += 0.1
	if y > 186.0: t3 -= 0.12 * (y - 186.0) / 14.0
	if y > 197.0: t3 -= 0.1
	return pick(GOURD, t3)

func render() -> Image:
	var img := Image.create(W / PX, H / PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bomb_mask := {}
	for j in range(H / PX):
		for i in range(W / PX):
			var c: Variant = mate_px((i + 0.5) * PX, (j + 0.5) * PX - DROP)
			if c != null:
				img.set_pixel(i, j, c)
				if last_bomb: bomb_mask[Vector2i(i, j)] = true
	var marks: Array[Vector2i] = []
	for j in range(img.get_height()):
		for i in range(img.get_width()):
			if img.get_pixel(i, j).a > 0: continue
			var touches_body := false
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = i + dd.x
				var ny: int = j + dd.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and img.get_pixel(nx, ny).a > 0:
					if not bomb_mask.has(Vector2i(nx, ny)): touches_body = true
			# la bombilla va sin contorno negro: su borde oscuro ya la separa del fondo
			if touches_body: marks.append(Vector2i(i, j))
	for m in marks: img.set_pixel(m.x, m.y, OUTLINE)
	return img

func _init() -> void:
	build_chain()
	var img := render()
	img.save_png(OUT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/propuesta/"))
	var big := img.duplicate() as Image
	big.resize(img.get_width() * 6, img.get_height() * 6, Image.INTERPOLATE_NEAREST)
	big.save_png(PREVIEW)
	print("ok mate")
	quit()
