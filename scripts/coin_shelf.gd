extends Control
## Colecciones · Monedas (D20): estantes de madera con todas las monedas del catálogo, de a páginas, con flechas a los
## costados (y las flechas del teclado). Al pasar el mouse o hacer clic en una moneda, abajo se lee su nombre, su
## rareza y lo que hace. Solo presentación: no toca la partida.

const Coins = preload("res://scripts/coins.gd")
const CoinArt = preload("res://scripts/coin_art.gd")
const Tip = preload("res://scripts/item_tooltip.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")

signal closed

const PANEL := Rect2(150, 70, 1140, 760)
const SHELVES := 3
const PER_SHELF := 6
const PER_PAGE := SHELVES * PER_SHELF
## Zona de los estantes dentro del panel, entre las dos flechas.
const SHELF_AREA := Rect2(130, 84, 880, 456)
const COIN_SIZE := 84.0
const GOLD := Color("f0c850")
const CREAM := Color("fff0c7")
const DIM := Color("b7a98c")
## Madera de los estantes: canto claro, frente, sombra y la pared del fondo.
const WOOD_TOP := Color("b07a45")
const WOOD_FRONT := Color("7a4a26")
const WOOD_DARK := Color("3f2614")
const BACK_WALL := Color("2a1418")

var ids: Array = []
var page := 0
var selected := ""
var panel: Panel
var page_label: Label
var name_label: Label
var meta_label: Label
var description_label: Label
var left_arrow: Button
var right_arrow: Button
var shelf_layer: Control

func _ready() -> void:
	name = "CoinShelf"
	size = Vector2(1440, 900)
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ids = Coins.DATA.keys()
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.06, 0.07, 0.84)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: close_shelf())
	add_child(shade)
	panel = Panel.new()
	panel.position = PANEL.position
	panel.size = PANEL.size
	panel.add_theme_stylebox_override("panel", Tip.skin())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	caption("MONEDAS", Rect2(32, 22, PANEL.size.x - 64, 40), 28, GOLD)
	var back := ColorRect.new()
	back.color = BACK_WALL
	back.position = SHELF_AREA.position - Vector2(16, 12)
	back.size = SHELF_AREA.size + Vector2(32, 24)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(back)
	shelf_layer = Control.new()
	shelf_layer.name = "Shelves"
	shelf_layer.position = SHELF_AREA.position
	shelf_layer.size = SHELF_AREA.size
	shelf_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(shelf_layer)
	left_arrow = arrow("PrevPage", "◀", Rect2(36, SHELF_AREA.get_center().y - 56, 64, 112), -1)
	right_arrow = arrow("NextPage", "▶", Rect2(PANEL.size.x - 100, SHELF_AREA.get_center().y - 56, 64, 112), 1)
	page_label = caption("", Rect2(0, SHELF_AREA.end.y + 18, PANEL.size.x, 26), 17, DIM)
	page_label.name = "PageLabel"
	name_label = caption("", Rect2(60, SHELF_AREA.end.y + 54, PANEL.size.x - 120, 30), 22, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.name = "CoinName"
	meta_label = caption("", Rect2(60, SHELF_AREA.end.y + 84, PANEL.size.x - 120, 24), 16, DIM, HORIZONTAL_ALIGNMENT_LEFT)
	description_label = caption("", Rect2(60, SHELF_AREA.end.y + 110, PANEL.size.x - 330, 66), 17, CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	description_label.name = "CoinDescription"
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := Button.new()
	close.name = "Close"
	close.text = "Cerrar"
	close.position = Vector2(PANEL.size.x - 36 - 200, PANEL.size.y - 66)
	close.size = Vector2(200, 42)
	close.add_theme_font_override("font", Tip.pixel_font())
	close.pressed.connect(close_shelf)
	panel.add_child(close)
	show_page(0)

func page_count() -> int:
	return ceili(float(ids.size()) / PER_PAGE)

func show_page(index: int) -> void:
	page = clampi(index, 0, page_count() - 1)
	for child in shelf_layer.get_children(): child.free()
	var pitch_y := SHELF_AREA.size.y / SHELVES
	var pitch_x := SHELF_AREA.size.x / PER_SHELF
	for shelf in SHELVES:
		var plank_y := (shelf + 1) * pitch_y - 26.0
		_plank(Rect2(0, plank_y, SHELF_AREA.size.x, 22))
		for slot in PER_SHELF:
			var index_in_catalog: int = page * PER_PAGE + shelf * PER_SHELF + slot
			if index_in_catalog >= ids.size(): continue
			var id: String = ids[index_in_catalog]
			var spot := Rect2(slot * pitch_x + (pitch_x - COIN_SIZE) / 2.0, plank_y - COIN_SIZE + 4, COIN_SIZE, COIN_SIZE)
			_coin(id, spot)
	page_label.text = "Página %d / %d" % [page + 1, page_count()]
	left_arrow.disabled = page == 0
	right_arrow.disabled = page == page_count() - 1
	var first: String = ids[page * PER_PAGE]
	select(selected if selected != "" and ids.find(selected) / PER_PAGE == page else first)

## Estante: canto claro arriba, frente de madera con vetas y una sombra abajo, todo en bloques de 2 px.
func _plank(rect: Rect2) -> void:
	for part in [[Rect2(rect.position.x, rect.position.y, rect.size.x, 6), WOOD_TOP], [Rect2(rect.position.x, rect.position.y + 6, rect.size.x, rect.size.y - 10), WOOD_FRONT], [Rect2(rect.position.x, rect.end.y - 4, rect.size.x, 4), WOOD_DARK], [Rect2(rect.position.x + 8, rect.end.y, rect.size.x - 16, 6), Color(0, 0, 0, 0.35)]]:
		var piece := ColorRect.new()
		piece.position = part[0].position
		piece.size = part[0].size
		piece.color = part[1]
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shelf_layer.add_child(piece)
	# Vetas: rayitas más oscuras repartidas por el frente.
	for x in range(18, int(rect.size.x) - 30, 74):
		var grain := ColorRect.new()
		grain.position = Vector2(rect.position.x + x, rect.position.y + 10 + (x / 74 % 2) * 4)
		grain.size = Vector2(28, 2)
		grain.color = WOOD_DARK.lerp(WOOD_FRONT, 0.4)
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shelf_layer.add_child(grain)

func _coin(id: String, spot: Rect2) -> void:
	var button := Button.new()
	button.name = "Coin_" + id
	button.position = spot.position
	button.size = spot.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(func(): select(id))
	button.mouse_entered.connect(func(): select(id))
	shelf_layer.add_child(button)
	var art := CoinArt.new()
	art.coin_id = id
	art.position = Vector2.ZERO
	art.size = spot.size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)

func select(id: String) -> void:
	selected = id
	var coin: Dictionary = Coins.definition(id)
	name_label.text = coin.name
	var rarity: String = Coins.RARITY_NAMES.get(coin.get("rarity", "common"), "")
	meta_label.text = rarity + (" · se desbloquea con un logro" if id in Coins.LOCKED else "")
	description_label.text = coin.description
	for child in shelf_layer.get_children():
		if child is Button: child.modulate = Color.WHITE if child.name == "Coin_" + id else Color(0.82, 0.8, 0.78)

func arrow(node_name: String, text: String, rect: Rect2, step: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal", "hover", "pressed", "disabled"]: button.add_theme_stylebox_override(state, UiSkin.button(state, state == "hover"))
	button.add_theme_font_override("font", Tip.pixel_font())
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_disabled_color", Color("6c6258"))
	button.pressed.connect(func(): show_page(page + step))
	panel.add_child(button)
	return button

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

func close_shelf() -> void:
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	if event.keycode == KEY_ESCAPE: close_shelf()
	elif event.keycode == KEY_LEFT: show_page(page - 1)
	elif event.keycode == KEY_RIGHT: show_page(page + 1)
	else: return
	get_viewport().set_input_as_handled()
