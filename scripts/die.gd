extends Button
## Front-facing ivory die, with an orthogonal pip grid for readable results.
const Art = preload("res://scripts/dice_art.gd")
const BODY_SHADER = preload("res://scripts/die_body.gdshader")
signal inspect_requested(index: int)
const PIPS = {
	1: [[1, 1]],
	2: [[0, 0], [2, 2]],
	3: [[0, 0], [1, 1], [2, 2]],
	4: [[0, 0], [2, 0], [0, 2], [2, 2]],
	5: [[0, 0], [2, 0], [1, 1], [0, 2], [2, 2]],
	6: [[0, 0], [2, 0], [0, 1], [2, 1], [0, 2], [2, 2]]
}
var die_index := 0
var value := 0
var chosen := false
var locked := false
var hovering := false
var combo_hint := false
var sway_enabled := true
var own_drag := false
var shell_broken := false
var pip_material := ""
var pip_suspended := false
var body_material := "basic"
var element := ""
var body_suspended := false
var element_suspended := false
var body_view: TextureRect
var body_shader: ShaderMaterial

func configure_appearance(state: Dictionary, context: Dictionary = {}) -> void:
	value = state.value
	body_material = state.material
	element = state.element
	pip_material = state.shell
	shell_broken = state.shell_broken
	var bosses = preload("res://scripts/boss_rules.gd")
	pip_suspended = bosses.suspended(context, "shell", pip_material)
	body_suspended = bosses.suspended(context, "material", body_material)
	element_suspended = bosses.suspended(context, "element", element)
	queue_redraw()

func _ready() -> void:
	body_view = TextureRect.new()
	body_view.name = "MaterialBody"
	body_view.position = Art.DISPLAY.position
	body_view.size = Art.DISPLAY.size
	body_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_view.show_behind_parent = true
	body_shader = ShaderMaterial.new()
	body_shader.shader = BODY_SHADER
	body_view.material = body_shader
	add_child(body_view)
	custom_minimum_size = Vector2(62, 62)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var instructions := "Dado %d · %s" % [die_index + 1, "en grupo" if locked else "clic para seleccionar; arrastrá al vaso o a reserva"]
	tooltip_text = instructions if tooltip_text.is_empty() else instructions + "\n" + tooltip_text
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	mouse_entered.connect(func(): hovering = true; queue_redraw())
	mouse_exited.connect(func(): hovering = false; queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		inspect_requested.emit(die_index)
		accept_event()

func _make_custom_tooltip(text: String) -> Object:
	if text.strip_edges().is_empty(): return null
	return preload("res://scripts/item_tooltip.gd").content(text)

func _get_tooltip(_at_position: Vector2) -> String:
	return ""

func face_point(u: float, v: float) -> Vector2:
	# No skew or perspective: identical x coordinates in every row.
	return Vector2(0.14 + 0.72 * u, 0.24 + 0.64 * v) * 62.0

func _draw() -> void:
	var metal := body_material in ["steel", "copper"]
	if is_instance_valid(body_view):
		body_view.visible = metal
		if metal:
			body_view.texture = Art.face(pip_material, value)
			body_shader.set_shader_parameter("body_kind", 1 if body_material == "steel" else 2)
			var boxes := PackedVector4Array()
			var bounds: Array = Art.pip_bounds(pip_material, value)
			for box in bounds:
				var start: Vector2 = box.position - Art.DISPLAY.position
				var end: Vector2 = start + box.size
				boxes.append(Vector4(start.x, start.y, end.x, end.y))
			while boxes.size() < 6: boxes.append(Vector4.ZERO)
			body_shader.set_shader_parameter("pip_boxes", boxes)
			body_shader.set_shader_parameter("pip_count", bounds.size())
	if not metal: draw_texture_rect(Art.face(pip_material, value), Art.DISPLAY, false, Color("fff9ee") if hovering and not locked else Color.WHITE)
	if not pip_material.is_empty():
		for bounds in Art.pip_bounds(pip_material, value): draw_gem(bounds)
	draw_element_edges()
	if value == 0:
		draw_string(ThemeDB.fallback_font, Vector2(25, 42), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("71553b"))
	if chosen:
		selection_brackets(Color("64d4ff"))
		draw_string(ThemeDB.fallback_font, Vector2(2, 12), "SEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("143b50"))
	elif hovering and not locked:
		selection_brackets(Color("e6bc72"))
	elif combo_hint:
		selection_brackets(Color("e6bc72"))
	if has_focus(): selection_brackets(Color("ffdc80"))
	if shell_broken:
		var bounds := Art.pip_bounds(pip_material, value)
		if not bounds.is_empty():
			var center: Vector2 = bounds[0].get_center().round()
			draw_polyline(PackedVector2Array([center + Vector2(-1, -3), center + Vector2(1, -1), center + Vector2(-1, 1), center + Vector2(1, 3)]), Color("d6c6a5"), 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(47, 13), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("762f30"))
	if pip_suspended or body_suspended or element_suspended:
		draw_string(ThemeDB.fallback_font, Vector2(2, 61), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("663a30"))

func draw_element_edges() -> void:
	# Edge-only accents leave every pip unobstructed, including the six.
	for side in [-1, 1]:
		var x: float = 31.0 + side * 27.0
		match element:
			"electricity":
				var path := PackedVector2Array([Vector2(x - side * 6, 4), Vector2(x - side * 2, 10), Vector2(x - side * 4, 15), Vector2(x, 20), Vector2(x - side * 2, 25)])
				draw_polyline(path, Color("d78205"), 3)
				draw_polyline(path, Color("ffe72c"), 1.6)
				draw_polyline(PackedVector2Array([Vector2(x, 36), Vector2(x - side * 2, 42), Vector2(x, 46), Vector2(x - side * 3, 51), Vector2(x - side * 6, 56)]), Color("ffdc22"), 2)
			"fire":
				draw_polyline(PackedVector2Array([Vector2(x - side * 2, 49), Vector2(x - side * 3, 54), Vector2(x - side * 7, 57), Vector2(x - side * 11, 57)]), Color("e6541a"), 2)
				for y in [13, 34, 48, 54]:
					var edge_x: float = x - side * (3 if y == 54 else 0)
					draw_rect(Rect2(edge_x - 1, y, 3, 4), Color("e74612"))
					draw_rect(Rect2(edge_x, y - 2, 1.5, 3), Color("ffd04a"))
			"water":
				for y in [12, 31, 46, 54]:
					var edge_x: float = x - side * (4 if y == 54 else 0)
					draw_rect(Rect2(edge_x - 1, y, 3, 3), Color("168ad0"))
					draw_rect(Rect2(edge_x, y, 1, 1), Color("a6f5ff"))
				draw_line(Vector2(x - side * 8, 57), Vector2(x - side * 3, 55), Color("47d3ed"), 2)
				draw_line(Vector2(x - side * 13, 57), Vector2(x - side * 9, 57), Color("168ad0"), 1.5)
			"earth":
				for distance in [6, 11]:
					draw_rect(Rect2(x - side * distance - 1, 55, 3, 3), Color("916136"))
					draw_rect(Rect2(x - side * distance - 1, 55, 2, 1), Color("d6aa6e"))
				for y in [15, 38, 49, 54]:
					var edge_x: float = x - side * (4 if y == 54 else 0)
					draw_rect(Rect2(edge_x - 1, y, 3, 3), Color("795131"))
					draw_rect(Rect2(edge_x - 1, y, 2, 1), Color("c99558"))
			"wind":
				draw_polyline(PackedVector2Array([Vector2(x - side * 5, 56), Vector2(x - side * 11, 57), Vector2(x - side * 13, 55)]), Color("71d9e9"), 1.5)
				for y in [10, 35, 51]:
					draw_polyline(PackedVector2Array([Vector2(x - side * 3, y - 3), Vector2(x, y), Vector2(x - side * 1, y + 3), Vector2(x - side * 4, y + 3)]), Color("71d9e9"), 1.5)

func pixel_pip(center: Vector2, radius: float, color: Color) -> void:
	var r := radius
	var points := PackedVector2Array([
		center + Vector2(-r + 1, -r), center + Vector2(r - 1, -r),
		center + Vector2(r, -r + 1), center + Vector2(r, r - 1),
		center + Vector2(r - 1, r), center + Vector2(-r + 1, r),
		center + Vector2(-r, r - 1), center + Vector2(-r, -r + 1)
	])
	draw_colored_polygon(points, color)

func draw_gem(bounds: Rect2) -> void:
	# Static pixel facets: readable at table size, without flashing or changing RNG.
	var palettes := {
		"ruby": ["26020b", "750009", "d90018", "ff1227", "ff4758", "fff1eb"],
		"sapphire": ["020b2b", "05266e", "0758dc", "009dff", "60ddff", "f1fbff"],
		"emerald": ["021f13", "005532", "009d49", "00e36d", "75ffb3", "effff5"],
		"diamond": ["20333d", "476575", "85b9cc", "c5efff", "e8fcff", "ffffff"]}
	var palette: Array = palettes.get(pip_material, palettes.diamond)
	var rows := ["    0000    ", "  00111100  ", " 0133332210 ", "013553322210", "015543322210", "014443322210", "011443344410", "011144344410", "011114344410", " 0111144410 ", "  00111100  ", "    0000    "]
	var step := bounds.size / 12.0
	for y in range(12):
		for x in range(12):
			var pixel: String = rows[y][x]
			if pixel != " ": draw_rect(Rect2(bounds.position + Vector2(x, y) * step, step + Vector2(0.02, 0.02)), Color(palette[pixel.to_int()]))

func selection_brackets(color: Color) -> void:
	for origin in [Vector2(1, 1), Vector2(61, 1), Vector2(1, 61), Vector2(61, 61)]:
		var direction := Vector2(1 if origin.x < 31 else -1, 1 if origin.y < 31 else -1)
		draw_line(origin, origin + Vector2(direction.x * 11, 0), color, 2)
		draw_line(origin, origin + Vector2(0, direction.y * 11), color, 2)

func _get_drag_data(_at: Vector2) -> Variant:
	if locked or value == 0: return null
	var preview = get_script().new()
	preview.value = value
	preview.pip_material = pip_material
	preview.body_material = body_material
	preview.element = element
	preview.body_suspended = body_suspended
	preview.element_suspended = element_suspended
	preview.shell_broken = shell_broken
	preview.pip_suspended = pip_suspended
	preview.locked = true
	preview.size = Vector2(62, 62)
	preview.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	preview.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sway := preload("res://scripts/drag_sway.gd").new()
	sway.visual = preview
	sway.enabled = sway_enabled
	sway.add_child(preview)
	set_drag_preview(sway)
	own_drag = true
	modulate.a = 0.35
	return {"die": die_index}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and own_drag:
		own_drag = false
		modulate.a = 1

