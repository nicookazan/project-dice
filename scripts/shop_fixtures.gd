extends Control
## Etiqueta de cartón de la tienda (tienda sobre la mesa, 08/11/2026): apoyada en el paño junto a cada oferta, con su
## sombra; `sold` la ensancha para el cartel «VENDIDO». Se dibuja con píxeles lógicos de 2×2 como el resto del arte v3,
## sin texturas, desde (0, 0) del nodo. Antes también dibujaba los ganchos del maletín y las bandejas del inventario.
const U := 2
const TAG := Color("f2e6c0")
const TAG_SHADE := Color("c9b48a")
const TAG_LIGHT := Color("fff8e0")
const SHADOW := Color(0, 0, 0, 0.35)
## Tinta de los textos que van sobre el cartón.
const TAG_INK := Color("3a2416")
const TAG_INK_SOLD := Color("7a2418")
## Tamaño en píxeles lógicos de la etiqueta con precio y de la del cartel «VENDIDO».
const TAG_W := 26
const TAG_SOLD_W := 32
const TAG_H := 12

var sold := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var w := TAG_SOLD_W if sold else TAG_W
	_tag(1, 2, w, SHADOW)
	_tag(0, 0, w)

func _rect(x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	draw_rect(Rect2(minf(x0, x1) * U, minf(y0, y1) * U, (absi(x1 - x0) + 1) * U, (absi(y1 - y0) + 1) * U), color)

## Cartón con las esquinas de arriba cortadas y biselado; con `shadow` se dibuja la silueta lisa de ese color.
func _tag(x0: int, ty: int, w: int, shadow := Color.TRANSPARENT) -> void:
	var paper := TAG if shadow.a == 0.0 else shadow
	_rect(x0 + 3, ty, x0 + w - 3, ty, paper)
	_rect(x0 + 2, ty + 1, x0 + w - 2, ty + 1, paper)
	_rect(x0 + 1, ty + 2, x0 + w - 1, ty + 2, paper)
	_rect(x0, ty + 3, x0 + w, ty + TAG_H - 1, paper)
	if shadow.a != 0.0: return
	_rect(x0 + 1, ty + TAG_H - 2, x0 + w - 1, ty + TAG_H - 1, TAG_SHADE)
	_rect(x0 + 1, ty + 3, x0 + 1, ty + TAG_H - 3, TAG_LIGHT)
