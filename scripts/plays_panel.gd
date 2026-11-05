extends Control
## Lista de jugadas posibles sobre la tela izquierda: la de más puntos de cada categoría con los dados libres.
## Pasar el mouse marca los dados de la jugada y el clic la arma como grupo. Es solo ayuda: el estado de la partida
## solo cambia cuando se arma el grupo, por el mismo camino que "Armar grupo".

const Rules = preload("res://scripts/rules.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const FeltLayout = preload("res://scripts/felt_layout.gd")

signal play_chosen(ids: Array)

const GOLD := Color("f0c850")
const CREAM := Color("fff0c7")
const NUMBERS := Color("b7a98c")
const ROW_FILL := Color("0d1728")
const ROW_EDGE := Color("6a5230")
const HOVER_FILL := Color("2c4a9a")
## La ficha del dado va debajo de la lista, a partir de acá: la lista no puede bajar de este límite.
const LIMIT := 546.0
const CARD_TOP := 552.0
const TOP_FREE := 322.0
const GROUP_STEP := 103.0
const ORDER := BossRules.CATEGORIES

## Dados de la jugada bajo el mouse (la mesa los resalta).
var hovered_ids: Array = []
var rows: Array = []

# ---------- cálculo ----------

## La mejor jugada de cada categoría con los dados libres (en el vaso o ya agrupados no cuentan), de más a menos puntos.
## Cada entrada: {category, ids, values, total}. Usa las mismas reglas y la misma puntuación que "Armar grupo".
static func best_plays(game) -> Array:
	if game.phase != "play" or game.rolls_made == 0: return []
	var rules: Dictionary = game.active_rules()
	var context: Dictionary = game.boss_context()
	var abducted: int = BossRules.abducted(context)
	var available: Array = []
	for id in range(game.dice.size()):
		if not game.is_grouped(id) and game.dice[id].zone == "reserve" and id != abducted: available.append(id)
	var best: Dictionary = {}
	for mask in range(1, 1 << available.size()):
		var ids: Array = []
		for bit in range(available.size()):
			if mask & (1 << bit): ids.append(available[bit])
		var resolved := Rules.resolve_wildcards(game.dice, ids, rules)
		var category: String = resolved.category
		if category.is_empty() or BossRules.forbidden(context, category): continue
		var candidate := {"ids": ids.duplicate(), "category": category, "locked": false}
		if not resolved.assigned.is_empty(): candidate["assigned"] = resolved.assigned
		var groups: Array = game.groups.duplicate(true)
		groups.append(candidate)
		if not Rules.validate_groups(game.dice, groups, rules).is_empty(): continue
		var score := Rules.score(game.dice, groups, game.passives, game.impulses, game.rolls_made == 1, game.global_points, game.cup.stickers, game.sticker_catalog, context, game.coin_context())
		if not score.valid: continue
		var total: float = score.rows[game.groups.size()].total
		if best.has(category) and best[category].total >= total: continue
		var values: Array = []
		for id in ids: values.append(resolved.assigned.get(id, game.dice[id].value))
		best[category] = {"category": category, "ids": ids, "values": values, "total": total}
	var plays: Array = best.values()
	if BossRules.forecast_hidden(context):
		# Sin puntos a la vista, el orden tampoco puede delatarlos.
		plays.sort_custom(func(a, b): return ORDER.find(a.category) < ORDER.find(b.category))
	else:
		plays.sort_custom(func(a, b): return a.total > b.total or (a.total == b.total and ORDER.find(a.category) < ORDER.find(b.category)))
	return plays

## y de arranque del título según cuántos grupos ya hay armados (los grupos ocupan el costado de arriba).
static func top_for(group_count: int) -> float:
	return TOP_FREE if group_count == 0 else 371.0 + GROUP_STEP * group_count

# ---------- vista ----------

## `format` pasa un puntaje a texto. `drop_zone` recibe los dados soltados sobre las filas.
func setup(plays: Array, group_count: int, hide_points: bool, format: Callable, drop_zone = null) -> void:
	name = "PlaysPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := top_for(group_count)
	var available := LIMIT - (top + 28.0)
	var step := 44.0 if plays.size() * 44.0 <= available else 36.0
	var count := mini(plays.size(), int(floor(available / step)))
	if count <= 0: return
	var title := Label.new()
	title.text = "JUGADAS POSIBLES" if group_count == 0 else "SIGUEN POSIBLES"
	title.position = Vector2(FeltLayout.left(top) + 30.0, top - 2.0)
	title.size = Vector2(FeltLayout.RIGHT - FeltLayout.left(top) - 60.0, 24.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", GOLD)
	add_child(title)
	for i in range(count):
		var play: Dictionary = plays[i]
		var y0 := top + 28.0 + i * step
		var y1 := y0 + step - 6.0
		var row := Row.new()
		row.setup(play, y0, y1, "?" if hide_points else format.call(play.total))
		row.entered.connect(func(): hovered_ids = play.ids.duplicate())
		row.exited.connect(func(): if hovered_ids == play.ids: hovered_ids = [])
		row.chosen.connect(func(): play_chosen.emit(play.ids.duplicate()))
		add_child(row)
		rows.append(row)
		if drop_zone != null: drop_zone.accept_through(row)

class Row extends Control:
	signal chosen
	signal entered
	signal exited
	var polygon := PackedVector2Array()
	var hovered := false
	var texts: Array = []
	var play: Dictionary = {}

	func setup(play_value: Dictionary, y0: float, y1: float, points: String) -> void:
		play = play_value
		var band := FeltLayout.band(y0, y1)
		position = Vector2(band[3].x, y0)
		size = Vector2(band[1].x - band[3].x, y1 - y0)
		for point in band: polygon.append(point - position)
		texts = [play.category, " ".join(play.values.map(func(v): return str(v))), points]
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func():
			hovered = true
			queue_redraw()
			entered.emit())
		mouse_exited.connect(func():
			hovered = false
			queue_redraw()
			exited.emit())

	func _has_point(point: Vector2) -> bool:
		return Geometry2D.is_point_in_polygon(point, polygon)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			chosen.emit()

	func _draw() -> void:
		draw_colored_polygon(polygon, HOVER_FILL if hovered else ROW_FILL)
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, GOLD if hovered else ROW_EDGE, 2.0)
		var font := get_theme_default_font()
		var mid := size.y / 2.0
		draw_string(font, Vector2(14, mid + 6), texts[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
		draw_string(font, Vector2(118, mid + 5), texts[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, NUMBERS)
		draw_string(font, Vector2(size.x - 66, mid + 7), texts[2], HORIZONTAL_ALIGNMENT_RIGHT, 50, 20, GOLD)
