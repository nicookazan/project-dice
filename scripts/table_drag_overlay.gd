extends Control
## Ayudas visuales mientras se arrastra un dado de la mesa: "Reservar" sobre la tela izquierda y el brillo
## dorado del vaso, que crece al acercarse. Solo presentación: no toca el estado de la partida.

const FeltLayout = preload("res://scripts/felt_layout.gd")
const GLOW = preload("res://assets/art/pixel-v3/vaso-brillo-v3.png")
const GLOW_RECT := Rect2(1264, 410, 176, 220)
const RESERVE_COLOR := Color(0.46, 0.025, 0.10, 0.62)
const GLOW_REACH := 260.0

## Rect donde el vaso recibe el dado: dentro de él el brillo está al máximo.
var cup_zone := Rect2()
## ¿Puede ofrecerse "Reservar" para este dado? (lo decide la mesa)
var reserve_ok: Callable = func(_index: int) -> bool: return false
var smooth := true

var reserve: Polygon2D
var glow: TextureRect

func _ready() -> void:
	name = "TableDragOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reserve = Polygon2D.new()
	reserve.name = "ReserveHint"
	reserve.polygon = FeltLayout.polygon()
	reserve.color = RESERVE_COLOR
	reserve.visible = false
	var caption := Label.new()
	caption.text = "Reservar"
	caption.position = Vector2(FeltLayout.left(484), 440)
	caption.size = Vector2(FeltLayout.RIGHT - FeltLayout.left(484), 90)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 38)
	caption.add_theme_color_override("font_color", Color("fff0c7"))
	reserve.add_child(caption)
	add_child(reserve)
	glow = TextureRect.new()
	glow.name = "CupGlow"
	glow.texture = GLOW
	glow.position = GLOW_RECT.position
	glow.size = GLOW_RECT.size
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate.a = 0.0
	add_child(glow)

func _process(delta: float) -> void:
	update_hints(delta, get_local_mouse_position())

func update_hints(delta: float, pointer: Vector2) -> void:
	var viewport := get_viewport()
	var data: Variant = viewport.gui_get_drag_data() if viewport.gui_is_dragging() else null
	var dragging: bool = data is Dictionary and data.get("die") is int
	reserve.visible = dragging and reserve_ok.call(data.die)
	var target := 0.0
	if dragging:
		var distance := _distance_to(pointer, cup_zone)
		target = clampf(1.0 - distance / GLOW_REACH, 0.0, 1.0)
		target = 0.35 + 0.65 * target
	glow.modulate.a = move_toward(glow.modulate.a, target, delta * 6.0) if smooth else target

func _distance_to(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)
