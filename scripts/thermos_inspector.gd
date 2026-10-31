extends Control
const Thermos = preload("res://scripts/shop_thermos.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Tooltip = preload("res://scripts/item_tooltip.gd")
var levels: Dictionary = {}
var catalog: Dictionary = {}
var description: Label
var title: Label
var artwork: Control

func _ready() -> void:
	name = "ThermosInspector"
	custom_minimum_size = Vector2(640, 440)
	theme = Theme.new()
	theme.default_font = Tooltip.pixel_font()
	theme.default_font_size = 18
	artwork = Thermos.new()
	artwork.name = "ThermosArtwork"
	artwork.position = Vector2(36, 50)
	artwork.scale = Vector2.ONE
	artwork.size = Vector2(144, 330)
	artwork.stickers = levels.duplicate(true)
	add_child(artwork)
	var heading := make_label("TU TERMO", Rect2(215, 20, 390, 38), 26)
	heading.add_theme_color_override("font_color", Color("eac16c"))
	var frame := Panel.new()
	frame.position = Vector2(215, 92)
	frame.size = Vector2(390, 280)
	frame.add_theme_stylebox_override("panel", Tooltip.skin())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	title = make_label("", Rect2(235, 110, 350, 48), 20)
	title.add_theme_color_override("font_color", Color("eac16c"))
	description = make_label("", Rect2(235, 173, 350, 180), 18)
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	reset_description()
	for id in Stickers.NAMES:
		if not levels.has(id): continue
		var sticker_id: String = id
		var hit := Button.new()
		hit.name = "Sticker_" + id
		var bounds := Thermos.badge_hit_rect(id, levels)
		hit.position = artwork.position + bounds.position * artwork.scale
		hit.size = bounds.size * artwork.scale
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed"]: hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("eac16c")
		focus.set_border_width_all(1)
		hit.add_theme_stylebox_override("focus", focus)
		hit.mouse_entered.connect(func(): show_sticker(sticker_id))
		hit.focus_entered.connect(func(): show_sticker(sticker_id))
		hit.pressed.connect(func(): show_sticker(sticker_id))
		hit.mouse_exited.connect(reset_description)
		hit.focus_exited.connect(reset_description)
		add_child(hit)
	make_label("Pasá el mouse por los stickers del termo.", Rect2(200, 391, 420, 32), 15)

func make_label(text: String, rect: Rect2, font_size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("fff0c7"))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func reset_description() -> void:
	title.text = "Sin stickers" if levels.is_empty() else "Tus stickers"
	description.text = "Los stickers que compres se pegan acá y conservan sus niveles." if levels.is_empty() else "Pasá el mouse por un sticker para ver su nivel y lo que aporta."

func show_sticker(id: String) -> void:
	if not levels.has(id): return
	var level: int = levels[id]
	title.text = "%s · nivel %d" % [Stickers.NAMES[id], level]
	if not Stickers.defined(id, catalog):
		description.text = "Efectos pendientes de definición."
		return
	var data: Dictionary = catalog[id]
	description.text = "%s\n\n+%s puntos de grupo\n+%s al multiplicador\n\nEfecto total con nivel %d." % [", ".join(Stickers.CATEGORIES[id]), str(data.points_per_level * level), str(data.multiplier_per_level * level), level]
