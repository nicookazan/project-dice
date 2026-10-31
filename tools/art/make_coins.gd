extends SceneTree
## Genera assets/art/pixel-v3/coins-v3.png (4×2 monedas de 32×32 px lógicos).
## Ejecutar: godot --headless --path . --script res://tools/art/make_coins.gd

const PixelLib = preload("res://tools/art/pixel_lib.gd")
const Mask = preload("res://tools/art/mask.gd")
const S := 32
const OUT := "res://assets/art/pixel-v3/coins-v3.png"

func _full() -> Mask:
	var m := Mask.new(17, 12)
	for x in [0, 6, 12]:
		m.disc(x + 2.5, 2.5, 2.6)
	for x in [3, 9]:
		m.disc(x + 2.5, 9.5, 2.6)
	return m

func _straight() -> Mask:
	var m := Mask.new(16, 12)
	for i in range(4):
		m.rect(i * 4, 12 - (i + 1) * 3, 16 - i * 4, (i + 1) * 3)
	return m

func _crown() -> Mask:
	var m := Mask.new(18, 16)
	for spike in [[2, 4], [9, 2], [16, 4]]:
		var cx: int = spike[0]
		var ty: int = spike[1]
		for y in range(ty, 11):
			var hw := (y - ty) * 0.6 + 0.5
			for x in range(roundi(cx - hw), roundi(cx + hw) + 1): m.set_cell(x, y)
		m.rect(cx - 1, ty - 2, 2, 2)
	m.rect(1, 10, 16, 5)
	for x in [4, 8, 12]: m.rect(x, 12, 2, 1, "o")
	return m

func _poker() -> Mask:
	var m := Mask.new(14, 14)
	for pos in [[0, 0], [8, 0], [0, 8], [8, 8]]: m.rect(pos[0], pos[1], 6, 6)
	return m

func _sun() -> Mask:
	var m := Mask.new(19, 19)
	m.disc(9.5, 9.5, 4.6)
	for a in range(8):
		var dir := Vector2.from_angle(a * PI / 4.0)
		var p0 := Vector2(9, 9) + dir * 6.2
		var p1 := Vector2(9, 9) + dir * 8.6
		m.line(roundi(p0.x), roundi(p0.y), roundi(p1.x), roundi(p1.y))
	m.set_cell(7, 8, "o")
	m.set_cell(11, 8, "o")
	m.line(8, 11, 10, 11, "o")
	return m

func _moon() -> Mask:
	var m := Mask.new(19, 17)
	m.disc(7.5, 8.5, 7.6)
	m.erase_disc(11.0, 6.5, 6.4)
	m.rect(15, 2, 1, 5)
	m.rect(13, 4, 5, 1)
	m.rect(14, 3, 3, 3)
	return m

func _dice2() -> Mask:
	var m := Mask.new(19, 19)
	m.rect(0, 0, 9, 9)
	m.set_cell(2, 2, "o"); m.set_cell(6, 6, "o")
	m.rect(10, 10, 9, 9)
	m.set_cell(12, 12, "o"); m.set_cell(14, 14, "o"); m.set_cell(16, 16, "o")
	return m

func _roll() -> Mask:
	var m := Mask.new(19, 19)
	m.disc(9.5, 9.5, 9.0)
	m.erase_disc(9.5, 9.5, 6.8)
	for y in range(0, 7):  # hueco arriba a la derecha para la flecha
		for x in range(11, 19): m.set_cell(x, y, ".")
	for hy in range(5):
		m.rect(11, hy, [2, 4, 5, 4, 2][hy], 1)
	m.rect(6, 6, 7, 7)
	m.set_cell(8, 8, "o"); m.set_cell(10, 10, "o")
	return m

func _init() -> void:
	var img := PixelLib.make(S * 4, S * 2)
	var specs := [
		[PixelLib.GOLD, _full(), PixelLib.GOLD],
		[PixelLib.SILVER, _straight(), PixelLib.SILVER],
		[PixelLib.GOLD, _crown(), PixelLib.GOLD],
		[PixelLib.COPPER, _poker(), PixelLib.COPPER],
		[PixelLib.SILVER, _sun(), PixelLib.SILVER],
		[PixelLib.GOLD, _moon(), PixelLib.GOLD],
		[PixelLib.COPPER, _dice2(), PixelLib.IVORY],
		[PixelLib.SILVER, _roll(), PixelLib.SILVER],
	]
	for i in range(specs.size()):
		var spec: Array = specs[i]
		var rim: Array = spec[0]
		var face: Color = rim[1]
		if i == 7: face = PixelLib.BLUE[1]
		var ox: int = (i % 4) * S
		var oy: int = (i / 4) * S
		PixelLib.coin(img, ox, oy, S, rim, face)
		var rows: Array = (spec[1] as Mask).rows()
		var mw: int = rows[0].length()
		var mh: int = rows.size()
		PixelLib.stamp_mask(img, rows, ox + (S - mw) / 2, oy + (S - mh) / 2, spec[2], face)
	img.save_png(OUT)
	var big := img.duplicate() as Image
	big.resize(S * 4 * 6, S * 2 * 6, Image.INTERPOLATE_NEAREST)
	big.save_png("res://test-results/coins-v3-x6.png")
	print("ok ", OUT)
	quit()
