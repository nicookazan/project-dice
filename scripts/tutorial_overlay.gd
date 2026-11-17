extends Control
## Carteles del tutorial: una capa encima de la pantalla con un texto junto a cada zona y un solo «Continuar» que los cierra.
## Mientras está abierta bloquea el mouse; cerrada, solo deja el botón «?» para volver a verlos. Sin «Saltear tutorial».
signal dismissed
signal reopened
const Tutorial = preload("res://scripts/tutorial_script.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const BUBBLE_WIDTH := 300.0
const SCREEN := Vector2(1440, 900)
var notes: Array = []
var open := true
var continue_button: Button
var help_button: Button

## Posición del cartel junto a la zona (lado "right", "left", "above" o "below"), sin salirse de la pantalla.
static func bubble_rect(zone: Rect2, side: String, size: Vector2) -> Rect2:
	var at := Vector2.ZERO
	match side:
		"left": at = Vector2(zone.position.x - size.x - 14, zone.position.y)
		"above": at = Vector2(zone.position.x + (zone.size.x - size.x) / 2.0, zone.position.y - size.y - 14)
		"below": at = Vector2(zone.position.x + (zone.size.x - size.x) / 2.0, zone.end.y + 14)
		_: at = Vector2(zone.end.x + 14, zone.position.y)
	at.x = clampf(at.x, 8.0, SCREEN.x - size.x - 8.0)
	at.y = clampf(at.y, 8.0, SCREEN.y - size.y - 8.0)
	return Rect2(at, size)

func setup(step_notes: Array, show_notes: bool, gold: Color, cream: Color) -> void:
	notes = step_notes
	open = show_notes and not notes.is_empty()
	name = "TutorialOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	if open:
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.03, 0.06, 0.55)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		for entry in notes:
			var zone: Rect2 = Tutorial.ZONES.get(entry.zone, Rect2(560, 300, 320, 200))
			var frame := Panel.new()
			frame.name = "Zone_" + entry.zone
			frame.position = zone.position
			frame.size = zone.size
			var edge := StyleBoxFlat.new()
			edge.bg_color = Color(1, 0.9, 0.5, 0.06)
			edge.border_color = gold
			edge.set_border_width_all(3)
			edge.set_corner_radius_all(6)
			frame.add_theme_stylebox_override("panel", edge)
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(frame)
			var bubble := Panel.new()
			bubble.name = "Note"
			var text := Label.new()
			text.text = entry.text
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.size = Vector2(BUBBLE_WIDTH - 28, 0)
			text.position = Vector2(14, 12)
			text.add_theme_font_size_override("font_size", 17)
			text.add_theme_color_override("font_color", cream)
			text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bubble.add_child(text)
			var height := 34.0 + 22.0 * ceilf(entry.text.length() / 28.0)
			var rect := bubble_rect(zone, entry.side, Vector2(BUBBLE_WIDTH, height))
			bubble.position = rect.position
			bubble.size = rect.size
			var skin := StyleBoxFlat.new()
			skin.bg_color = Color("0d1728")
			skin.border_color = gold
			skin.set_border_width_all(3)
			skin.set_corner_radius_all(8)
			bubble.add_theme_stylebox_override("panel", skin)
			bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(bubble)
		continue_button = Button.new()
		continue_button.name = "TutorialContinue"
		continue_button.text = "Continuar"
		continue_button.size = Vector2(200, 48)
		continue_button.position = Vector2(SCREEN.x - 224, SCREEN.y - 76)
		for state in ["normal", "hover", "pressed"]: continue_button.add_theme_stylebox_override(state, UiSkin.button(state, true))
		continue_button.pressed.connect(func(): dismissed.emit())
		add_child(continue_button)
	elif not notes.is_empty():
		help_button = Button.new()
		help_button.name = "TutorialHelp"
		help_button.text = "?"
		help_button.tooltip_text = "Volver a ver los carteles de esta pantalla"
		help_button.size = Vector2(40, 40)
		help_button.position = Vector2(SCREEN.x - 54, 78)
		help_button.add_theme_font_size_override("font_size", 22)
		for state in ["normal", "hover", "pressed"]: help_button.add_theme_stylebox_override(state, UiSkin.button(state, true))
		help_button.pressed.connect(func(): reopened.emit())
		add_child(help_button)
