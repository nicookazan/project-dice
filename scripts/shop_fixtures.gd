extends Control
## Ganchos, etiquetas y bandejas de la tienda (bocetos aprobados el 08/11): de qué cuelgan las ofertas del maletín y dónde
## se apoyan tus dados y tus monedas. Todo se dibuja con píxeles lógicos de 2×2 como el resto del arte v3, sin texturas:
## las bandejas se adaptan a la capacidad de monedas y los ganchos al ancho de cada tarjeta.
##
## `mode` "hook": gancho con dos hilos arriba y etiqueta de cartón abajo (la tarjeta la cubre con su precio); `sold` la
## ensancha para el cartel «VENDIDO». `mode` "trays": las bandejas de `trays` en coordenadas lógicas de la pantalla.
const U := 2
const GOLD := [Color("2e1508"), Color("5c300c"), Color("96601a"), Color("c98f24"), Color("ecbc42"), Color("ffe07a"), Color("fff8c8")]
const WOOD := [Color("1e0f08"), Color("3a1e0e"), Color("5a3418"), Color("7a4a24"), Color("9a6436")]
const FELT_GREEN := [Color("08261a"), Color("1c6a42"), Color("2f9058")]
const FELT_BORDO := [Color("2c0812"), Color("5a1024"), Color("8c1c2e")]
const STRING := Color("e8dcc0")
const TAG := Color("f2e6c0")
const TAG_SHADE := Color("c9b48a")
const TAG_LIGHT := Color("fff8e0")
## Tinta de los textos que van sobre el cartón.
const TAG_INK := Color("3a2416")
const TAG_INK_SOLD := Color("7a2418")
## Tamaño en píxeles lógicos de la etiqueta con precio y de la del cartel «VENDIDO», y dónde empieza (en la tarjeta de 145 px).
const TAG_W := 26
const TAG_SOLD_W := 32
const TAG_TOP := 56
const TAG_H := 12

var mode := "hook"
var sold := false
## Bandejas: {"rect": Rect2i(x0, y0, x1, y1) lógico, "felt": "green"|"bordo", "holes": [Vector2i(cx, cy) lógico]}.
var trays: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if mode == "trays":
		for tray in trays: _tray(tray)
	else:
		_hook_and_tag()

# ---------- primitivas en píxeles lógicos ----------

func _rect(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	draw_rect(Rect2(minf(x0, x1) * U, minf(y0, y1) * U, (absi(x1 - x0) + 1) * U, (absi(y1 - y0) + 1) * U), color)

func _dot(x: int, y: int, color: Color) -> void:
	_rect(x, y, x, y, color)

func _disc(cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			if float(x * x) / (rx * rx + rx) + float(y * y) / (ry * ry + ry) <= 1.0: _dot(cx + x, cy + y, color)

func _line(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(steps + 1):
		var t := float(i) / maxf(steps, 1)
		_dot(roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), color)

# ---------- gancho y etiqueta ----------

func _hook_and_tag() -> void:
	var cx := int(size.x / (2 * U))
	var hy := 3
	# Gancho de bronce con ojal arriba y punta curva; dos hilos abren hacia las esquinas del objeto.
	_disc(cx, hy, 2, 2, GOLD[2]); _disc(cx, hy - 1, 1, 1, GOLD[5]); _dot(cx, hy, GOLD[1])
	_line(cx, hy + 2, cx, hy + 5, GOLD[4])
	_dot(cx + 1, hy + 6, GOLD[4]); _dot(cx + 2, hy + 5, GOLD[4]); _dot(cx + 2, hy + 4, GOLD[4])
	_line(cx, hy + 6, cx - 7, hy + 12, STRING); _line(cx, hy + 6, cx + 7, hy + 12, STRING)
	# Hilo de la etiqueta (queda detrás del objeto) y cartón con biselado.
	_line(cx, TAG_TOP - 9, cx, TAG_TOP, STRING)
	var w := TAG_SOLD_W if sold else TAG_W
	var x0 := cx - w / 2
	var ty := TAG_TOP
	_rect(x0 + 3, ty, x0 + w - 3, ty, TAG)
	_rect(x0 + 2, ty + 1, x0 + w - 2, ty + 1, TAG)
	_rect(x0 + 1, ty + 2, x0 + w - 1, ty + 2, TAG)
	_rect(x0, ty + 3, x0 + w, ty + TAG_H - 1, TAG)
	_rect(x0 + 1, ty + TAG_H - 2, x0 + w - 1, ty + TAG_H - 1, TAG_SHADE)
	_rect(x0 + 1, ty + 3, x0 + 1, ty + TAG_H - 3, TAG_LIGHT)

# ---------- bandejas ----------

func _tray(tray: Dictionary) -> void:
	var r: Rect2i = tray.rect
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.size.x
	var y1 := r.size.y
	var felt: Array = FELT_GREEN if tray.felt == "green" else FELT_BORDO
	# Marco de madera biselado (luz arriba y a la izquierda).
	_rect(x0, y0, x1, y1, WOOD[0])
	_rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, WOOD[2])
	_rect(x0 + 1, y0 + 1, x1 - 1, y0 + 2, WOOD[4]); _rect(x0 + 1, y0 + 1, x0 + 2, y1 - 1, WOOD[3])
	_rect(x0 + 1, y1 - 2, x1 - 1, y1 - 1, WOOD[1]); _rect(x1 - 2, y0 + 1, x1 - 1, y1 - 1, WOOD[1])
	for x in range(x0 + 6, x1 - 4, 7):   # veta
		_dot(x, y0 + 3, WOOD[1]); _dot(x + 3, y1 - 3, WOOD[1])
	# Vivo dorado y paño.
	_rect(x0 + 4, y0 + 4, x1 - 4, y1 - 4, GOLD[2]); _rect(x0 + 4, y0 + 4, x1 - 5, y0 + 4, GOLD[5]); _rect(x0 + 4, y0 + 4, x0 + 4, y1 - 5, GOLD[4])
	_rect(x0 + 5, y0 + 5, x1 - 5, y1 - 5, felt[1])
	_rect(x0 + 5, y0 + 5, x1 - 5, y0 + 6, felt[0]); _rect(x0 + 5, y0 + 5, x0 + 6, y1 - 5, felt[0])
	for y in range(y0 + 8, y1 - 5):      # pelusa del paño, salteada
		for x in range(x0 + 7, x1 - 5):
			if (x * 73 + y * 151) % 97 == 0: _dot(x, y, felt[2])
	# Esquineros en L con tornillo y tachas en el medio de los lados largos.
	for corner in [[x0, 1, y0, 1], [x1, -1, y0, 1], [x0, 1, y1, -1], [x1, -1, y1, -1]]:
		var cx: int = corner[0]
		var sx: int = corner[1]
		var cy: int = corner[2]
		var sy: int = corner[3]
		_rect(cx, cy, cx + sx * 5, cy + sy, GOLD[4])
		_rect(cx, cy, cx + sx, cy + sy * 5, GOLD[4])
		_dot(cx + sx * 2, cy + sy * 2, GOLD[3]); _dot(cx + sx, cy + sy, GOLD[6])
		_dot(cx + sx * 3, cy + sy, GOLD[1]); _dot(cx + sx, cy + sy * 3, GOLD[1])
	var mx := (x0 + x1) / 2
	for y in [y0 + 1, y1 - 2]:
		_rect(mx - 1, y, mx + 1, y + 1, GOLD[4]); _dot(mx - 1, y, GOLD[6])
	# Hueco con aro dorado: solo para la moneda de un uso.
	for hole in tray.get("holes", []):
		_disc(hole.x, hole.y, 12, 12, GOLD[3]); _disc(hole.x, hole.y, 11, 11, felt[1])
