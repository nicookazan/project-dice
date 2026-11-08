extends Control
## Panel de los stickers del termo: a la izquierda la lista de todos los stickers (los que se tienen con su nivel,
## los demás apagados) y a la derecha el elegido en grande, con su nivel, sus mejoras y lo que hace.
## Solo presentación: lee el estado, nunca lo cambia.

const Stickers = preload("res://scripts/stickers.gd")
const StickerArt = preload("res://scripts/sticker_art.gd")
const StickerTip = preload("res://scripts/sticker_tip.gd")
const Tip = preload("res://scripts/item_tooltip.gd")

signal closed

const PANEL := Rect2(230, 120, 980, 660)
const ROW_SIZE := Vector2(400, 74)
const GOLD := Color("f0c850")
const CREAM := Color("fff0c7")
const DIM := Color("8f8676")
const CATEGORY_TEXT := {
	"pair_loose": "Par y sobrantes: suma a toda jugada de Par y a los dados que quedan sueltos al anotar.",
	"trio": "Trío: suma a toda jugada de Trío.",
	"straight": "Escalera: suma a toda jugada de Escalera.",
	"full": "Full: suma a toda jugada de Full.",
	"poker": "Póker: suma a toda jugada de Póker.",
	"generala": "Generala: suma a toda jugada de Generala."}

var levels: Dictionary = {}
var catalog: Dictionary = {}
var selected := "trio"
var rows: Dictionary = {}
var medallion: Control
var big_sticker: Control
var level_label: Label
var upgrades_label: Label
var effect_label: Label
var level_bar: Control
var panel: Panel

func setup(owned_levels: Dictionary, definitions: Dictionary, first: String) -> void:
	levels = owned_levels.duplicate(true)
	catalog = definitions
	selected = first if Stickers.NAMES.has(first) else "trio"

func _ready() -> void:
	name = "StickerBook"
	size = Vector2(1440, 900)
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.06, 0.07, 0.84)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	# Un clic afuera del panel lo cierra.
	shade.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: close_book())
	add_child(shade)
	panel = Panel.new()
	panel.position = PANEL.position
	panel.size = PANEL.size
	panel.add_theme_stylebox_override("panel", Tip.skin())
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	caption("STICKERS DEL TERMO", Rect2(32, 22, PANEL.size.x - 64, 40), 28, GOLD)
	var y := 86.0
	for id in Stickers.NAMES:
		rows[id] = make_row(id, Vector2(36, y))
		y += ROW_SIZE.y + 8.0
	build_detail()
	var close := Button.new()
	close.name = "Close"
	close.text = "Cerrar"
	close.position = Vector2(PANEL.size.x - 36 - 200, PANEL.size.y - 66)
	close.size = Vector2(200, 42)
	close.add_theme_font_override("font", Tip.pixel_font())
	close.pressed.connect(close_book)
	panel.add_child(close)
	select(selected)

func close_book() -> void:
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_book()

func caption(text: String, rect: Rect2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_override("font", Tip.pixel_font())
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color("190a10"))
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(node)
	return node

static func row_style(chosen: bool, owned: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("153c50") if chosen else Color("091923")
	style.border_color = GOLD if chosen else (Color("785335") if owned else Color("3b2a30"))
	style.set_border_width_all(2)
	return style

func make_row(id: String, pos: Vector2) -> Button:
	var owned: bool = levels.get(id, 0) > 0
	var row := Button.new()
	row.name = "Row_" + id
	row.position = pos
	row.size = ROW_SIZE
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]: row.add_theme_stylebox_override(state, row_style(false, owned))
	row.add_theme_stylebox_override("hover", row_style(true, owned))
	row.pressed.connect(func(): select(id))
	panel.add_child(row)
	var icon := StickerArt.new()
	icon.sticker_id = id
	icon.level = maxi(1, levels.get(id, 1))
	icon.position = Vector2(14, 11)
	icon.size = Vector2(52, 52)
	icon.modulate = Color.WHITE if owned else Color(0.35, 0.35, 0.4, 0.8)
	row.add_child(icon)
	var title := Label.new()
	title.text = Stickers.NAMES[id]
	title.position = Vector2(82, 10)
	title.size = Vector2(190, 30)
	title.add_theme_font_override("font", Tip.pixel_font())
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CREAM if owned else DIM)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)
	var sub := Label.new()
	sub.text = "Nivel %d" % levels[id] if owned else "Sin conseguir"
	sub.position = Vector2(82, 40)
	sub.size = Vector2(190, 24)
	sub.add_theme_font_override("font", Tip.pixel_font())
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", GOLD if owned else DIM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sub)
	if owned:
		var data := StickerTip.effect(id, levels[id], catalog)
		var total := Label.new()
		total.text = "" if data.is_empty() else "+%s · +%s" % [StickerTip.number(data.points), StickerTip.number(data.multiplier_addition)]
		total.position = Vector2(236, 22)
		total.size = Vector2(150, 30)
		total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		total.add_theme_font_override("font", Tip.pixel_font())
		total.add_theme_font_size_override("font_size", 17)
		total.add_theme_color_override("font_color", GOLD)
		total.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(total)
	return row

## Medallón redondo con el sticker en grande.
class Medallion extends Control:
	var sticker_id := "trio"
	var owned := true
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 112.0, Color("785335"))
		draw_circle(c, 108.0, Color("f0c850"))
		draw_circle(c, 102.0, Color("091923"))
		draw_circle(c, 98.0, Color("153c50"))

func build_detail() -> void:
	var x0 := 36.0 + ROW_SIZE.x + 36.0
	var width := PANEL.size.x - x0 - 36.0
	medallion = Medallion.new()
	medallion.position = Vector2(x0 + width / 2.0 - 112.0, 84)
	medallion.size = Vector2(224, 224)
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(medallion)
	big_sticker = StickerArt.new()
	big_sticker.size = Vector2(156, 156)  # 3× the 52 px art
	big_sticker.position = Vector2(34, 34)
	medallion.add_child(big_sticker)
	level_label = caption("", Rect2(x0, 322, width, 36), 28, GOLD)
	upgrades_label = caption("", Rect2(x0, 366, width, 110), 18, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	upgrades_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	upgrades_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label = caption("", Rect2(x0, 486, width, 100), 18, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	effect_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Texto de las mejoras: lo que da ahora y lo que daría con un nivel más.
func upgrades_text(id: String) -> String:
	var level: int = levels.get(id, 0)
	if not Stickers.defined(id, catalog): return "MEJORAS\nEfectos pendientes de definición."
	var data: Dictionary = catalog[id]
	var per_level := "+%s puntos y +%s mult. por nivel" % [StickerTip.number(data.points_per_level), StickerTip.number(data.multiplier_per_level)]
	if level <= 0: return "MEJORAS\nCada nivel suma %s.\nConseguilo en la tienda." % per_level
	var now := StickerTip.effect(id, level, catalog)
	var next := StickerTip.effect(id, level + 1, catalog)
	return "MEJORAS\nAhora: +%s puntos · +%s mult.\nNivel %d: +%s puntos · +%s mult.\n(%s)" % [StickerTip.number(now.points), StickerTip.number(now.multiplier_addition), level + 1, StickerTip.number(next.points), StickerTip.number(next.multiplier_addition), per_level]

func select(id: String) -> void:
	selected = id
	for key in rows:
		var owned: bool = levels.get(key, 0) > 0
		rows[key].add_theme_stylebox_override("normal", row_style(key == id, owned))
	var owned_now: bool = levels.get(id, 0) > 0
	big_sticker.sticker_id = id
	big_sticker.level = maxi(1, levels.get(id, 1))
	big_sticker.modulate = Color.WHITE if owned_now else Color(0.35, 0.35, 0.4, 0.8)
	big_sticker.queue_redraw()
	level_label.text = "NIVEL %d" % levels[id] if owned_now else "SIN CONSEGUIR"
	level_label.add_theme_color_override("font_color", GOLD if owned_now else DIM)
	upgrades_label.text = upgrades_text(id)
	effect_label.text = "QUÉ HACE\n" + CATEGORY_TEXT.get(id, "")
