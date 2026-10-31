extends RefCounted
## Utilidades de dibujo pixel art para generar los assets pixel-v3.
## Una luz fija arriba-izquierda; rampas de 5 tonos [sombra, medio, base, luz, brillo].

const OUTLINE := Color("2a1a14")

const GOLD := [Color("5a3a14"), Color("a8701c"), Color("e0a030"), Color("f6d060"), Color("fff0a8")]
const SILVER := [Color("2c3446"), Color("5c6478"), Color("98a0b4"), Color("cdd3e0"), Color("f2f4fa")]
const COPPER := [Color("4a2010"), Color("8a4220"), Color("b8683a"), Color("de9460"), Color("f4c898")]
const BLUE := [Color("14285a"), Color("204a9c"), Color("3070d0"), Color("6a9ae8"), Color("b8d0f8")]
const IVORY := [Color("6b4a2a"), Color("c9a36a"), Color("efe0b8"), Color("fff6dc"), Color("ffffff")]

static func make(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

## Convierte una máscara ASCII ('#' forma, 'o' detalle oscuro, '.' vacío) en pixel art
## autosombreado: sombra proyectada abajo-derecha, borde claro arriba-izquierda.
static func stamp_mask(img: Image, rows: Array, ox: int, oy: int, ramp: Array, _face: Color = Color.BLACK) -> void:
	var h := rows.size()
	var w: int = rows[0].length()
	for y in range(h):
		for x in range(w):
			if _solid(rows, x, y) and not _solid(rows, x + 1, y + 1) and rows[mini(y + 1, h - 1)][mini(x + 1, w - 1)] != "o":
				put(img, ox + x + 1, oy + y + 1, ramp[0])
	for y in range(h):
		for x in range(w):
			var ch: String = rows[y][x]
			if ch == ".": continue
			if ch == "o":
				put(img, ox + x, oy + y, ramp[0])
				continue
			var c: Color = ramp[3]
			if not _solid(rows, x, y + 1) or not _solid(rows, x + 1, y):
				c = ramp[2]
			elif not _solid(rows, x, y - 1) or not _solid(rows, x - 1, y):
				c = ramp[4]
			put(img, ox + x, oy + y, c)

static func _solid(rows: Array, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[0].length(): return false
	return rows[y][x] == "#"

## Moneda redonda con borde sombreado por ángulo, contorno y cara plana.
static func coin(img: Image, ox: int, oy: int, size: int, rim: Array, face: Color) -> void:
	var r := size / 2.0
	for y in range(size):
		for x in range(size):
			var dx := x + 0.5 - r
			var dy := y + 0.5 - r
			var d := sqrt(dx * dx + dy * dy)
			if d > r: continue
			var c: Color
			if d > r - 1.0:
				c = OUTLINE
			elif d > r - 4.0:
				var t := (dx * -0.7 + dy * -0.7) / maxf(d, 0.001)
				if t > 0.6: c = rim[4]
				elif t > 0.1: c = rim[3]
				elif t > -0.45: c = rim[2]
				else: c = rim[1]
			elif d > r - 5.0:
				c = rim[0]
			else:
				c = face
			put(img, ox + x, oy + y, c)

const BLACK := [Color("14141a"), Color("2a2a32"), Color("44444e"), Color("6a6a76"), Color("9a9aa6")]

## Contorno de 1 px alrededor de todo lo opaco (pixeles transparentes con vecino opaco).
static func outline(img: Image, color: Color = OUTLINE) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var marks: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0: continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and img.get_pixel(nx, ny).a > 0:
					marks.append(Vector2i(x, y))
					break
	for m in marks: img.set_pixel(m.x, m.y, color)

## Relleno rectangular con sombreado cilíndrico por columnas (luz a la izquierda).
static func cylinder(img: Image, x0: int, y0: int, x1: int, y1: int, ramp: Array) -> void:
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
		for y in range(y0, y1 + 1): put(img, x, y, c)
