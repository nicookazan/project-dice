extends Control
## Ficha de un dado: material · gema · elemento en color, sus seis caras (la actual en dorado) y cuánto vale.
## Se ve al pasar el mouse sobre un dado: sobre la tela izquierda en la mesa, arriba del dado en la tienda.
## Solo presentación: lee el estado, nunca lo cambia.

const Rules = preload("res://scripts/rules.gd")
const Materials = preload("res://scripts/materials.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const FeltLayout = preload("res://scripts/felt_layout.gd")
const Tip = preload("res://scripts/item_tooltip.gd")

enum Style { FELT, SHOP }

## Colores aprobados en los bocetos.
const COLORS := {
	"steel": "b8c4d4", "copper": "e89a5c",
	"emerald": "55d890", "ruby": "ff5f70", "sapphire": "74a4f0", "diamond": "cdf2ff",
	"fire": "ff8e30", "water": "52bcf2", "electric": "ffe24f", "earth": "c4955a", "wind": "a4e6c6",
	"gold": "f0c850", "dim": "8f8676", "text": "fff0c7"}
const NAMES := {
	"steel": "Acero", "copper": "Cobre",
	"emerald": "Esmeralda", "ruby": "Rubí", "sapphire": "Zafiro", "diamond": "Diamante",
	"fire": "Fuego", "water": "Agua", "electric": "Electricidad", "earth": "Tierra", "wind": "Viento"}
const FELT_TOP := 322.0
const FELT_HEIGHT := 88.0
const FELT_FILL := Color(0.17, 0.03, 0.07, 0.96)
const FELT_EDGE := Color(0.93, 0.73, 0.40)
const SHOP_SIZE := Vector2(320, 90)
const SHOP_MARGIN := 16

var felt_panel: Polygon2D
var felt_border: Line2D
var shop_panel: PanelContainer
var label: RichTextLabel

func _ready() -> void:
	name = "DieCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	felt_panel = Polygon2D.new()
	felt_panel.color = FELT_FILL
	add_child(felt_panel)
	felt_border = Line2D.new()
	felt_border.closed = true
	felt_border.width = 2.0
	felt_border.default_color = FELT_EDGE
	add_child(felt_border)
	shop_panel = PanelContainer.new()
	shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := Tip.skin()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: skin.set_content_margin(side, SHOP_MARGIN)
	shop_panel.add_theme_stylebox_override("panel", skin)
	add_child(shop_panel)
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", Tip.pixel_font())
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_color_override("default_color", Color(COLORS.text))
	add_child(label)
	hide()

## Muestra la ficha de `die`. En la tienda, `anchor` es el rectángulo del dado y la ficha va arriba.
func show_for(die: Dictionary, global_points: Dictionary, boss_context: Dictionary, style: Style, anchor := Rect2()) -> void:
	label.text = bbcode(die, global_points, boss_context)
	if style == Style.FELT:
		var points := FeltLayout.band(FELT_TOP, FELT_TOP + FELT_HEIGHT)
		felt_panel.polygon = points
		felt_border.points = points
		felt_panel.show()
		felt_border.show()
		shop_panel.hide()
		label.position = Vector2(FeltLayout.left(FELT_TOP + FELT_HEIGHT) + 26.0, FELT_TOP + 8.0)
		label.size = Vector2(FeltLayout.RIGHT - label.position.x - 14.0, 76.0)
	else:
		felt_panel.hide()
		felt_border.hide()
		shop_panel.show()
		shop_panel.custom_minimum_size = SHOP_SIZE
		shop_panel.size = SHOP_SIZE
		var x := clampf(anchor.get_center().x - SHOP_SIZE.x / 2.0, 8.0, 1440.0 - SHOP_SIZE.x - 8.0)
		shop_panel.position = Vector2(x, anchor.position.y - SHOP_SIZE.y - 10.0)
		label.position = shop_panel.position + Vector2(SHOP_MARGIN, SHOP_MARGIN)
		label.size = SHOP_SIZE - Vector2(SHOP_MARGIN, SHOP_MARGIN) * 2.0
	show()

# ---------- contenido ----------

static func color_text(color: String, text: String) -> String:
	return "[color=#%s]%s[/color]" % [COLORS[color], text]

## Una pieza del dado: en su color; tachada y apagada si está rota o suspendida.
static func part(family: String, id: String, die: Dictionary, boss_context: Dictionary) -> String:
	if not NAMES.has(id): return ""   # sin material/gema/elemento ("" o "basic")
	var name: String = NAMES[id]
	if BossRules.suspended(boss_context, family, id): return color_text("dim", "[s]%s[/s] suspendido por el jefe" % name)
	if family == "shell" and die.get("shell_broken", false): return color_text("dim", "[s]%s[/s] rota" % name)
	return color_text(id, name)

static func parts_line(die: Dictionary, boss_context: Dictionary) -> String:
	var parts: Array[String] = []
	for entry in [["material", die.get("material", "")], ["shell", die.get("shell", "")], ["element", die.get("element", "")]]:
		var text := part(entry[0], entry[1], die, boss_context)
		if text != "": parts.append(text)
	return " · ".join(parts) if not parts.is_empty() else color_text("dim", "Dado común")

static func faces_line(die: Dictionary) -> String:
	var faces: Array[String] = []
	for face in die.faces:
		faces.append(color_text("gold", str(face)) if die.value > 0 and face == die.value else str(face))
	return " · ".join(faces)

## Puntos propios del dado según la puntuación: su número, la mejora global de ese número, el bono del acero y la
## pérdida de cara de un jefe. Lo que depende de la jugada (gema, elemento, monedas) se explica en Inspeccionar.
static func worth(die: Dictionary, global_points: Dictionary, boss_context: Dictionary) -> int:
	if die.value <= 0: return 0
	var additions: Array = []
	var global_bonus: int = global_points.get(str(die.value), 0)
	if global_bonus > 0: additions.append({"source": "number:global:" + str(die.value), "amount": global_bonus})
	var face_loss: float = die.value - die.value * BossRules.face_scale(boss_context, die.value)
	if face_loss > 0: additions.append({"source": "boss:face:" + str(die.value), "amount": -face_loss})
	var steel_bonus := 0.0 if BossRules.suspended(boss_context, "material", die.material) else Materials.steel_points(die)
	if steel_bonus > 0: additions.append({"source": "material:steel:" + str(die.id), "amount": steel_bonus})
	return int(round(Rules.resolve_die(die, additions, []).points))

static func bbcode(die: Dictionary, global_points: Dictionary, boss_context: Dictionary) -> String:
	var last := color_text("dim", "Todavía en el vaso") if die.value <= 0 else color_text("gold", "Vale %d %s" % [worth(die, global_points, boss_context), "punto" if worth(die, global_points, boss_context) == 1 else "puntos"])
	return parts_line(die, boss_context) + "\n" + faces_line(die) + "\n" + last
