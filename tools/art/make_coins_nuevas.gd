extends SceneTree
## Etapa de monedas (MON1): 16 monedas nuevas + 2 paquetes, celdas de 32×32 px lógicos (hoja de 6×3, bocetos
## aprobados por el autor el 5/11/2026). Escribe assets/art/pixel-v3/coins-nuevas-v3.png y su versión ×8 en
## test-results/. coins-v3.png (las 8 monedas originales) no se toca. El orden de celdas está en coin_art.gd (NEW_IDS).
## Ejecutar: godot --headless --path . --script res://tools/art/make_coins_nuevas.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const S := 32
const COLUMNS := 6
const OUT := "res://assets/art/pixel-v3/coins-nuevas-v3.png"
const OUT_BIG := "res://test-results/coins-nuevas-v3-x8.png"

const PURPLE := [Color("2a1448"), Color("5a2a8c"), Color("8a4cc8"), Color("b784e8"), Color("e6ccff")]
## Borde por rareza: Común cobre, Rara plata, Épica violeta, Legendaria oro.
const RIM_BY_RARITY := {"common": PixelLib.COPPER, "rare": PixelLib.SILVER, "epic": PURPLE, "legendary": PixelLib.GOLD}

const GLYPHS := {
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"2": ["###", "..#", "###", "#..", "###"],
	"3": ["###", "..#", "###", "..#", "###"],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "###", "..#", "###"],
	"6": ["##.", "#..", "###", "#.#", "###"],
	"+": ["...", ".#.", "###", ".#.", "..."],
	"%": ["#.#", "..#", ".#.", "#..", "#.#"],
	"x": ["...", "#.#", ".#.", "#.#", "..."],
	"$": ["..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
}

## Texto en la máscara; devuelve el ancho dibujado.
func _text(m: Mask, text: String, x: int, y: int, scale: int, ch := "#") -> int:
	var cursor := x
	for c in text:
		var rows: Array = GLYPHS[c]
		for gy in range(rows.size()):
			for gx in range(rows[gy].length()):
				if rows[gy][gx] == "#": m.rect(cursor + gx * scale, y + gy * scale, scale, scale, ch)
		cursor += rows[0].length() * scale + scale
	return cursor - x - scale

func _poly(m: Mask, points: Array, ch := "#") -> void:
	var polygon := PackedVector2Array(points)
	for y in range(m.h):
		for x in range(m.w):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon): m.set_cell(x, y, ch)

# ---------- Pasivas ----------

func _hand() -> Mask:  # Mano extra
	var m := Mask.new(18, 19)
	m.rect(3, 9, 12, 9)
	m.rect(3, 3, 2, 7)
	m.rect(6, 0, 2, 10)
	m.rect(9, 1, 2, 9)
	m.rect(12, 4, 2, 6)
	m.rect(14, 4, 2, 6)
	m.line(2, 14, 0, 9)
	m.line(3, 14, 1, 9)
	m.line(3, 14, 1, 10)
	m.set_cell(6, 13, "o"); m.set_cell(9, 13, "o"); m.set_cell(12, 13, "o")
	return m

func _cup() -> Mask:  # Tirada de reserva: vaso con +
	var m := Mask.new(16, 18)
	_poly(m, [Vector2(0, 0), Vector2(16, 0), Vector2(13, 18), Vector2(3, 18)])
	m.rect(0, 0, 16, 2, "o")
	m.rect(7, 6, 2, 8, "o")
	m.rect(4, 9, 8, 2, "o")
	return m

func _stack() -> Mask:  # Cobrador: pila de monedas de canto
	var m := Mask.new(17, 17)
	var offsets := [1, 0, 2]
	for k in range(3):
		var y := 2 + k * 5
		var xo: int = offsets[k]
		m.rect(xo + 2, y, 11, 1)
		m.rect(xo, y + 1, 15, 3)
		m.rect(xo + 1, y + 4, 13, 1)
		m.rect(xo + 1, y + 3, 13, 1, "o")
	return m

func _chevrons() -> Mask:  # Veterano de nivel: galones
	var m := Mask.new(19, 18)
	for k in range(3):
		var y := k * 5.0
		_poly(m, [Vector2(0, 5 + y), Vector2(9.5, y), Vector2(19, 5 + y), Vector2(19, 8 + y), Vector2(9.5, 3 + y), Vector2(0, 8 + y)])
	return m

func _served() -> Mask:  # Servida: dado con 1 y destello
	var m := Mask.new(20, 18)
	m.rect(0, 6, 12, 12)
	m.rect(5, 11, 2, 2, "o")
	m.rect(16, 0, 1, 9)
	m.rect(12, 4, 9, 1)
	m.set_cell(14, 2, "#"); m.set_cell(18, 2, "#"); m.set_cell(14, 6, "#"); m.set_cell(18, 6, "#")
	return m

func _leftovers() -> Mask:  # Sobrantes: cuatro juntos y uno suelto
	var m := Mask.new(19, 17)
	for pos in [[0, 0], [6, 0], [0, 6], [6, 6]]: m.rect(pos[0], pos[1], 5, 5)
	m.rect(13, 11, 6, 6)
	m.rect(14, 12, 4, 4, ".")
	m.rect(15, 13, 2, 2, "o")
	return m

# ---------- Un solo uso ----------

func _ring(m: Mask, inner := 6.8) -> void:  # flecha circular de las monedas de tirada
	m.disc(9.5, 9.5, 9.0)
	m.erase_disc(9.5, 9.5, inner)
	for y in range(0, 7):
		for x in range(11, 19): m.set_cell(x, y, ".")
	for hy in range(5): m.rect(11, hy, [2, 4, 5, 4, 2][hy], 1)

func _roll_all() -> Mask:  # Relanzo total: flecha con los cinco dados
	var m := Mask.new(19, 19)
	_ring(m)
	for pos in [[5, 6], [11, 6], [8, 9], [5, 12], [11, 12]]: m.rect(pos[0], pos[1], 2, 2)
	return m

func _two_rolls() -> Mask:  # Dos tiradas más: flecha con un 2
	var m := Mask.new(19, 19)
	_ring(m)
	for x in [4, 10]:
		m.rect(x, 7, 5, 5)
		m.set_cell(x + 2, 9, "o")
	return m

func _mult2() -> Mask:  # Mult +2
	var m := Mask.new(20, 15)
	_text(m, "+", 0, 5, 2)
	_text(m, "2", 7, 0, 3)
	_text(m, "x", 17, 0, 1, "o")
	return m

func _points_bag() -> Mask:  # Bolsa de puntos: +30
	var m := Mask.new(20, 10)
	_text(m, "+30", 0, 0, 2)
	return m

func _flip() -> Mask:  # Voltear dado: un 1 y un 6 con flechas de ida y vuelta
	var m := Mask.new(20, 17)
	m.rect(0, 9, 8, 8)
	m.rect(3, 12, 2, 2, "o")
	m.rect(12, 9, 8, 8)
	for pos in [[13, 10], [17, 10], [13, 12], [17, 12], [13, 14], [17, 14]]: m.rect(pos[0], pos[1], 2, 2 if false else 1, "o")
	m.rect(3, 2, 14, 2)
	_poly(m, [Vector2(0, 3), Vector2(5, 0), Vector2(5, 6)])
	_poly(m, [Vector2(20, 3), Vector2(15, 0), Vector2(15, 6)])
	return m

func _shield() -> Mask:  # Escudo de jefe
	var m := Mask.new(18, 20)
	_poly(m, [Vector2(0, 0), Vector2(18, 0), Vector2(18, 10), Vector2(9, 20), Vector2(0, 10)])
	m.line(4, 4, 9, 9, "o")
	m.line(14, 4, 9, 9, "o")
	m.line(4, 5, 9, 10, "o")
	m.line(14, 5, 9, 10, "o")
	return m

func _quick_cash() -> Mask:  # Plata rápida: $5
	var m := Mask.new(20, 14)
	_text(m, "$", 0, 0, 2)
	_text(m, "5", 14, 2, 2)
	return m

func _discount_tag() -> Mask:  # Descuento de visita: etiqueta con %
	var m := Mask.new(19, 17)
	_poly(m, [Vector2(0, 8.5), Vector2(6, 1), Vector2(19, 1), Vector2(19, 16), Vector2(6, 16)])
	m.rect(3, 7, 2, 2, "o")
	m.rect(8, 3, 3, 3, "o")
	m.rect(14, 11, 3, 3, "o")
	m.line(16, 3, 8, 13, "o")
	m.line(15, 3, 7, 13, "o")
	m.line(17, 4, 9, 14, "o")
	return m

func _gems() -> Mask:  # Reparar todas: tres gemas
	var m := Mask.new(19, 17)
	for pos in [[5, 0], [0, 9], [10, 9]]:
		_poly_offset(m, pos[0], pos[1])
	return m

func _poly_offset(m: Mask, ox: int, oy: int) -> void:
	var gem := [Vector2(2, 0), Vector2(7, 0), Vector2(9, 3), Vector2(4.5, 8), Vector2(0, 3)]
	var polygon := PackedVector2Array(gem.map(func(p): return p + Vector2(ox, oy)))
	for y in range(m.h):
		for x in range(m.w):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon): m.set_cell(x, y)
	m.rect(ox + 1, oy + 3, 8, 1, "o")

func _even_boost() -> Mask:  # Impulso par: 2 4 6
	var m := Mask.new(20, 10)
	_text(m, "246", 0, 0, 2)
	return m

# ---------- Paquetes ----------

func _pouch(big: bool) -> Image:
	var img := PixelLib.make(S, S)
	var body := Mask.new(S, S)
	var radius := 12.0 if big else 9.0
	var cy := 20.0 if big else 21.0
	body.disc(16, cy, radius)
	body.rect(16 - (5 if big else 4), int(cy - radius) - 2, 10 if big else 8, 6)
	body.rect(16 - (8 if big else 6), int(cy - radius) - 6, 16 if big else 12, 5)
	PixelLib.stamp_mask(img, body.rows(), 0, 0, PixelLib.COPPER)
	var band := Mask.new(S, S)
	var band_y := int(cy - radius) - 1
	band.rect(16 - (6 if big else 5), band_y, 12 if big else 10, 3)
	if big: band.rect(16 - 10, band_y + 18, 20, 2)
	PixelLib.stamp_mask(img, band.rows(), 0, 0, PixelLib.GOLD)
	var patch := Mask.new(S, S)
	var px := 12 if big else 12
	var py := int(cy) - 3
	patch.rect(px, py, 8, 10)
	_text(patch, "5" if big else "2", px + 1, py + 2, 2 if false else 1, "o")
	PixelLib.stamp_mask(img, patch.rows(), 0, 0, PixelLib.IVORY)
	PixelLib.outline(img)
	return img

func _init() -> void:
	var cells := [
		# [máscara, rareza]; los paquetes van aparte.
		[_hand(), "legendary"], [_cup(), "rare"], [_stack(), "rare"], [_chevrons(), "rare"], [_served(), "rare"], [_leftovers(), "rare"],
		[_roll_all(), "rare"], [_mult2(), "rare"], [_points_bag(), "common"], [_flip(), "rare"], [_two_rolls(), "epic"], [_shield(), "rare"],
		[_quick_cash(), "common"], [_discount_tag(), "rare"], [_gems(), "epic"], [_even_boost(), "common"],
	]
	var rows := (cells.size() + 2 + COLUMNS - 1) / COLUMNS
	var img := PixelLib.make(S * COLUMNS, S * rows)
	for i in range(cells.size()):
		var rim: Array = RIM_BY_RARITY[cells[i][1]]
		var ox: int = (i % COLUMNS) * S
		var oy: int = (i / COLUMNS) * S
		PixelLib.coin(img, ox, oy, S, rim, rim[1])
		var mask_rows: Array = (cells[i][0] as Mask).rows()
		var mw: int = mask_rows[0].length()
		var mh: int = mask_rows.size()
		PixelLib.stamp_mask(img, mask_rows, ox + (S - mw) / 2, oy + (S - mh) / 2, rim)
	for k in range(2):
		var index := cells.size() + k
		img.blit_rect(_pouch(k == 1), Rect2i(0, 0, S, S), Vector2i((index % COLUMNS) * S, (index / COLUMNS) * S))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results"))
	img.save_png(OUT)
	var big := img.duplicate() as Image
	big.resize(img.get_width() * 8, img.get_height() * 8, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT_BIG)
	print("ok ", OUT)
	quit()
