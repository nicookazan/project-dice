extends RefCounted
## Menú inicial sobre la mesa (D20, paso PS2). Sin recuadro ni título: los botones van sobre el paño izquierdo y lo que
## sigue (elegir modo, la pregunta del tutorial, Colecciones) en el paño del medio. La mano de la ventana no está
## (`Backdrop.menu_mode`) y del fondo solo responde el mate: el termo y la calabaza lo ceban.
const Backdrop = preload("res://scripts/backdrop.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const Coins = preload("res://scripts/coins.gd")
const Stickers = preload("res://scripts/stickers.gd")
const StickerBook = preload("res://scripts/sticker_book.gd")
const ItemTooltip = preload("res://scripts/item_tooltip.gd")
const CoinShelf = preload("res://scripts/coin_shelf.gd")
const ValidationProfile = preload("res://scripts/validation_profile.gd")

## Paños de la mesa (coordenadas lógicas 1440 × 900), dentro del borde dorado. El izquierdo tiene el costado inclinado.
const PANO1 := Rect2(350, 320, 340, 330)
const PANO2 := Rect2(712, 320, 372, 330)
## Borde dorado del paño del medio: el izquierdo es recto (x 712) y el derecho se abre con la perspectiva de la mesa.
const PANO2_LEFT := 712.0

## Centro horizontal del paño del medio a la altura `y` (el borde derecho va de x 1028 arriba a x 1083 abajo).
static func pano2_center(y: float) -> float:
	return (PANO2_LEFT + 1040.0 + (y - 400.0) * 0.18) / 2.0

## Eje de la columna del paño del medio: su centro a media altura. Todo va alineado en esa columna (centrar cada fila
## a su altura las escalonaba).
static func pano2_axis() -> float:
	return roundf(pano2_center(PANO2.get_center().y))

## Rectángulo de ancho `w` centrado en el eje del paño del medio.
static func pano2_row(y: float, w: float, h: float) -> Rect2:
	return Rect2(roundf(pano2_axis() - w / 2.0), y, w, h)
## Columna de botones del paño izquierdo, ya corrida para no tocar el costado inclinado.
const COLUMN_X := 412.0
const COLUMN_W := 256.0
## La calabaza del mate, al lado del termo: el clic hace lo mismo que el termo (lo ceba).
const MATE_RECT := Rect2(1092, 418, 112, 124)
## Modos de juego: solo la campaña existe; los otros lugares quedan en gris, sin nombre (D20).
const GREY_MODES := 2

static func build(host) -> void:
	var menu := Control.new()
	menu.name = "MainMenu"
	menu.size = Vector2(1440, 900)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixelate(host, menu)
	host.ui.add_child(menu)
	var entries: Array = []
	if host.has_run_save(): entries.append(["ContinueRun", "Continuar partida", host.continue_run])
	entries.append(["NewRun", "Nueva partida", func(): host.request_navigation("new")])
	entries.append(["Collections", "Colecciones", func(): host.open_menu_panel("collections")])
	entries.append(["Options", "Opciones", host.show_options])
	entries.append(["Quit", "Salir", func(): host.request_navigation("quit")])
	if OS.has_feature("debug"): entries.append(["NewRunDebug", "Nueva partida debug", func(): host.request_navigation("new_debug")])
	var pitch := 54.0 if entries.size() > 5 else 60.0
	var top := PANO1.position.y + (PANO1.size.y - (entries.size() * pitch - (pitch - 46.0))) / 2.0
	var first: Button
	for index in entries.size():
		var entry: Array = entries[index]
		var item: Button = host.button(menu, entry[1], Rect2(COLUMN_X, top + index * pitch, COLUMN_W, 46), entry[2], false, index == 0)
		item.name = entry[0]
		if entry[0] == "NewRunDebug": item.add_theme_font_size_override("font_size", 15)
		if index == 0: first = item
	match host.menu_panel:
		"modes": _modes(host, menu)
		"tutorial": _tutorial(host, menu)
		"collections": _collections(host, menu)
		_: if is_instance_valid(first): first.grab_focus()
	if host.profile_message != "":
		var note: Label = host.label(menu, host.profile_message, Vector2(PANO1.position.x, 664), 15, host.gold, 740)
		note.name = "ProfileMessage"
	_mate(host)

## Textos y botones pixelados, como en la tienda: la letra de la interfaz pixel (sin suavizado) y los marcos con
## filtro «nearest». Se aplica a un contenedor y lo heredan todos sus hijos.
static func pixelate(host, container: Control) -> void:
	var pixel_theme: Theme = host.theme.duplicate()
	pixel_theme.default_font = ItemTooltip.pixel_font()
	container.theme = pixel_theme
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## Paño del medio: título y, debajo, una columna de botones centrada entre los bordes dorados (`pano2_row`).
static func _panel(host, menu: Control, title: String, subtitle := "") -> Dictionary:
	var w := 272.0
	var heading := _centered(host, menu, title, pano2_row(PANO2.position.y + 16, w, 30), 24, host.gold)
	heading.name = "PanelTitle"
	var y := PANO2.position.y + 56
	if subtitle != "":
		_centered(host, menu, subtitle, pano2_row(y - 6, w + 20, 44), 16, host.cream)
		y += 44
	return {"w": w, "y": y}

static func _back(host, menu: Control, target: String) -> Button:
	var back: Button = host.button(menu, "Volver", pano2_row(PANO2.end.y - 58, 160, 40), func(): host.open_menu_panel(target))
	back.name = "PanelBack"
	return back

static func _modes(host, menu: Control) -> void:
	var at := _panel(host, menu, "ELEGÍ UN MODO")
	var campaign: Button = host.button(menu, "Campaña", pano2_row(at.y, at.w, 52), host.choose_campaign, false, true)
	campaign.name = "ModeCampaign"
	for index in GREY_MODES:
		var grey: Button = host.button(menu, "Próximamente", pano2_row(at.y + 66 + index * 60, at.w, 46), func(): pass, true)
		grey.name = "ModeSoon_%d" % index
		grey.tooltip_text = "Modo todavía sin definir."
	_back(host, menu, "")
	campaign.grab_focus()

## La pregunta del tutorial: solo la primera vez, con un progreso nuevo (D20; después se juega desde Opciones).
static func _tutorial(host, menu: Control) -> void:
	var at := _panel(host, menu, "CAMPAÑA", "¿Querés jugar el tutorial?")
	var yes: Button = host.button(menu, "Sí, jugar el tutorial", pano2_row(at.y + 6, at.w, 50), func(): host.start_new_run(-1, false, true), false, true)
	yes.name = "TutorialYes"
	var no: Button = host.button(menu, "No, ir a la campaña", pano2_row(at.y + 68, at.w, 48), func(): host.start_new_run())
	no.name = "TutorialNo"
	_back(host, menu, "modes").name = "TutorialBack"
	yes.grab_focus()

## Colecciones (PS7, versión básica sin boceto propio): vistas de solo lectura con nombre y descripción.
static func _collections(host, menu: Control) -> void:
	var at := _panel(host, menu, "COLECCIONES")
	var sections := [
		["CollectionDice", "Dados y gemas", host.show_dice_gallery],
		["CollectionComponents", "Materiales y elementos", host.show_component_gallery],
		["CollectionStickers", "Stickers", func(): open_stickers(host)],
		["CollectionCoins", "Monedas", func(): open_coins(host)]]
	var first: Button
	for index in sections.size():
		var section: Array = sections[index]
		var item: Button = host.button(menu, section[1], pano2_row(at.y - 4 + index * 52, at.w, 44), section[2])
		item.name = section[0]
		if index == 0: first = item
	_back(host, menu, "")
	first.grab_focus()

## Stickers: el álbum del termo en modo colección (todos encendidos, con lo que da cada nivel).
static func open_stickers(host) -> Control:
	if is_instance_valid(host.sticker_book): return host.sticker_book
	var book := StickerBook.new()
	book.collection = true
	book.setup({}, ValidationProfile.stickers(), "trio")
	host.sticker_book = book
	host.ui.add_child(book)
	return book

## Monedas: estantes con todas las monedas, de a páginas.
static func open_coins(host) -> Control:
	var existing = host.ui.find_child("CoinShelf", false, false)
	if existing != null: return existing
	var shelf := CoinShelf.new()
	host.ui.add_child(shelf)
	return shelf

static func _centered(host, parent: Node, text: String, rect: Rect2, size: int, color: Color) -> Label:
	var node: Label = host.label(parent, text, rect.position, size, color, rect.size.x)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node

## Lo único del fondo que responde en el menú: el termo y la calabaza, que ceban el mate.
static func _mate(host) -> void:
	for spec in [["MenuMate", Backdrop.THERMOS_RECT, true], ["MenuMateCup", MATE_RECT, false]]:
		var zone: Button = host.button(host.ui, "", spec[1], func(): host.background.props.play("thermos"))
		zone.name = spec[0]
		zone.focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed", "disabled"]: zone.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		if spec[2]: BarProps.attach_ring(zone, "thermos", host.background.props)
