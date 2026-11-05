extends TextureRect
## Borde dorado de una oferta de la tienda que sigue la silueta del objeto (moneda, dado, sticker, sobre...).
## Se arma la primera vez que se pasa el mouse: el icono se dibuja una vez en un SubViewport, se dilata su alfa
## 2 px y el resultado queda en caché. Solo presentación.

const RING_COLOR := Color8(255, 224, 120)
const MARGIN := 2
static var cache: Dictionary = {}

## Crea el icono en el nodo recibido, con su rectángulo en (0, 0, 100, 91).
var make_icon: Callable
var key := ""
var hovering := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_KEEP
	z_index = 5
	hide()

## Llamar con true al entrar el mouse y con false al salir; los dos controles de una oferta comparten el aro.
func hover(entered: bool) -> void:
	hovering = maxi(0, hovering + (1 if entered else -1))
	refresh()

func refresh() -> void:
	if hovering > 0 and texture == null: await build()
	visible = hovering > 0 and texture != null

func build() -> void:
	if cache.has(key):
		texture = cache[key]
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(100 + MARGIN * 2, 91 + MARGIN * 2)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var holder := Control.new()
	holder.position = Vector2(MARGIN, MARGIN)
	viewport.add_child(holder)
	make_icon.call(holder)
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(viewport): return
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null: return   # sin render (modo sin pantalla): no hay aro
	texture = ring_from(image)
	cache[key] = texture

## Aro de 2 px alrededor de lo que se dibujó (píxeles con alfa), sin tocar el objeto.
static func ring_from(image: Image) -> ImageTexture:
	var w := image.get_width()
	var h := image.get_height()
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y in range(h):
		for x in range(w): solid[y * w + x] = 1 if image.get_pixel(x, y).a > 0.1 else 0
	var grown := solid.duplicate()
	for step in range(2):
		var next := grown.duplicate()
		for y in range(h):
			for x in range(w):
				if grown[y * w + x] == 1: continue
				if (x > 0 and grown[y * w + x - 1] == 1) or (x < w - 1 and grown[y * w + x + 1] == 1) or (y > 0 and grown[(y - 1) * w + x] == 1) or (y < h - 1 and grown[(y + 1) * w + x] == 1):
					next[y * w + x] = 1
		grown = next
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			if grown[y * w + x] == 1 and solid[y * w + x] == 0: out.set_pixel(x, y, RING_COLOR)
	return ImageTexture.create_from_image(out)
