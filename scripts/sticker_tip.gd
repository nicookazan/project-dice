extends Control
## Ventanita de un sticker del termo (sin recuadro sobre el sticker): "Jugada · Nivel N" y, debajo, lo que aporta en ese nivel. Se ve al pasar el
## mouse sobre el sticker: a la izquierda del termo en la mesa, a la derecha en la tienda. Solo presentación.

const Stickers = preload("res://scripts/stickers.gd")
const Tip = preload("res://scripts/item_tooltip.gd")
const GOLD := "f0c850"
const SIZE := Vector2(314, 72)
const MARGIN := 16
const GAP := 16.0

var panel: PanelContainer
var label: RichTextLabel

func _ready() -> void:
	name = "StickerTip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := Tip.skin()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: skin.set_content_margin(side, MARGIN)
	panel.add_theme_stylebox_override("panel", skin)
	panel.custom_minimum_size = SIZE
	panel.size = SIZE
	add_child(panel)
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", Tip.pixel_font())
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_color_override("default_color", Color("fff0c7"))
	panel.add_child(label)
	hide()

## `rect` es el sticker en pantalla. `to_right`: la ventanita va a la derecha (tienda) en vez de a la izquierda (mesa).
func show_for(id: String, level: int, catalog: Dictionary, rect: Rect2, to_right: bool) -> void:
	label.text = bbcode(id, level, catalog)
	if to_right: panel.position = Vector2(rect.end.x + GAP, rect.position.y - 20.0)
	else: panel.position = Vector2(rect.position.x - SIZE.x - GAP - 2.0, rect.position.y - 28.0)
	show()

## Lo que el sticker suma en su categoría con este nivel; sale de la misma función que usa la puntuación.
static func effect(id: String, level: int, catalog: Dictionary) -> Dictionary:
	if not Stickers.defined(id, catalog): return {}
	return Stickers.evaluate(Stickers.CATEGORIES[id][0], {id: level}, catalog)

static func number(value: float) -> String:
	return str(int(value)) if value == floor(value) else str(value)

static func bbcode(id: String, level: int, catalog: Dictionary) -> String:
	var head := "%s · Nivel %d" % [Stickers.NAMES.get(id, id), level]
	var data := effect(id, level, catalog)
	if data.is_empty(): return head + "\n[color=#8f8676]Efectos pendientes de definición[/color]"
	return head + "\n[color=#%s]+%s puntos · +%s mult.[/color]" % [GOLD, number(data.points), number(data.multiplier_addition)]
