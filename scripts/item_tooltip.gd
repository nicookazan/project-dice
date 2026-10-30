extends RefCounted
## One native hover presentation for merchandise, dice and inventory controls.

static func pixel_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Menlo", "Monaco"])
	font.font_weight = 700
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	return font

static func skin() -> StyleBox:
	var style := preload("res://scripts/tooltip_frame.gd").new()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 24)
	return style

static func content(text: String) -> Label:
	var body := Label.new()
	body.name = "ItemDescription"
	body.text = text
	body.custom_minimum_size.x = 350
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", pixel_font())
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color("fff0c7"))
	body.add_theme_color_override("font_shadow_color", Color("190a10"))
	body.add_theme_constant_override("shadow_offset_x", 1)
	body.add_theme_constant_override("shadow_offset_y", 1)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return body
