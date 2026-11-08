extends Control
## Termo de la mesa visto como nodo (tienda sobre la mesa, 08/11/2026). El termo lo dibuja el fondo; este nodo invisible
## ocupa su lugar para que el vuelo y el reparto de stickers (StickerFlight, StickerReveal) sepan adónde ir y puedan
## mostrar u ocultar un sticker mientras vuela: `stickers` es el mismo diccionario que dibuja el fondo.
## Mismo espacio local que ShopThermos: los lugares de cada sticker salen de ShopThermos.badge_hit_rect.

var backdrop: Control
var stickers: Dictionary = {}:
	set(value):
		stickers = value
		if is_instance_valid(backdrop):
			backdrop.stickers = value
			backdrop.queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Quien cambia `stickers` en el lugar llama a queue_redraw(): el aviso pasa al fondo, que es quien dibuja el termo.
func _draw() -> void:
	if is_instance_valid(backdrop): backdrop.queue_redraw.call_deferred()
