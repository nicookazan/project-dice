extends Control
## Compra de un sticker suelto en la tienda (animación aprobada, sin oscurecer la pantalla):
##  - nuevo: vuela desde la oferta hasta su lugar en el termo siguiendo un arco, con estela, y se pega con destellos;
##  - repetido: no vuela; sube el aviso "Trío · Nivel 1 → 2" junto a su lugar.
## Solo presentación: la compra ya está hecha y guardada; al terminar (o al cortarse) el termo queda con el estado real.

const Art = preload("res://scripts/sticker_art.gd")
const Thermos = preload("res://scripts/shop_thermos.gd")
const Stickers = preload("res://scripts/stickers.gd")
const Tip = preload("res://scripts/item_tooltip.gd")

const FRAME := 0.055
const HOLD := 6
const FLIGHT := 20
const BURST := 12
const NOTICE_FRAMES := 18
const ARC := 150.0
const START_SIZE := 76.0
const END_SCALE := 0.5
const GOLD := Color8(240, 200, 80)

var sticker_id := "trio"
var level_before := 0
var level_after := 1
var thermos: Control
var from := Vector2.ZERO
var slot := Vector2.ZERO
var fast := false
var elapsed := 0.0
var finished := false
var is_new := false
var badge: Control
var notice: Label

static func is_new_sticker(before: int) -> bool:
	return before <= 0

static func notice_text(id: String, before: int, after: int) -> String:
	if is_new_sticker(before): return "¡Nuevo! %s · Nivel %d" % [Stickers.NAMES.get(id, id), after]
	return "%s · Nivel %d → %d" % [Stickers.NAMES.get(id, id), before, after]

## Posición del centro del sticker en el cuadro de vuelo `f` (0..FLIGHT-1), de la oferta al termo.
static func flight_point(start: Vector2, finish_at: Vector2, f: int) -> Vector2:
	var t := smoothstep(0.0, 1.0, f / float(FLIGHT - 1))
	return start.lerp(finish_at, t) - Vector2(0, sin(t * PI) * ARC)

## `after` es el estado real de los stickers; mientras el nuevo vuela, el termo se ve sin él.
func setup(id: String, before: int, after: int, start: Vector2, thermos_node: Control, is_fast: bool) -> void:
	sticker_id = id
	level_before = before
	level_after = after
	from = start
	thermos = thermos_node
	fast = is_fast
	is_new = is_new_sticker(before)

func _ready() -> void:
	name = "StickerFlight"
	size = Vector2(1440, 900)
	z_index = 140
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if is_instance_valid(thermos):
		slot = thermos.get_global_rect().position + Thermos.badge_hit_rect(sticker_id, {sticker_id: level_after}).get_center()
		if is_new:
			var hidden: Dictionary = thermos.stickers.duplicate(true)
			hidden.erase(sticker_id)
			thermos.stickers = hidden
			thermos.queue_redraw()
	badge = Art.new()
	badge.sticker_id = sticker_id
	badge.level = level_after
	badge.size = Vector2(START_SIZE, START_SIZE)
	badge.pivot_offset = badge.size / 2.0
	badge.visible = false
	add_child(badge)
	notice = Label.new()
	notice.text = notice_text(sticker_id, level_before, level_after)
	notice.add_theme_font_override("font", Tip.pixel_font())
	notice.add_theme_font_size_override("font_size", 18)
	notice.add_theme_color_override("font_color", Color("fff0c7") if is_new else GOLD)
	notice.add_theme_color_override("font_shadow_color", Color8(25, 10, 16))
	notice.add_theme_constant_override("shadow_offset_x", 1)
	notice.add_theme_constant_override("shadow_offset_y", 1)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.visible = false
	add_child(notice)
	step(0.0)

func _process(delta: float) -> void:
	step(delta * (1.6 if fast else 1.0))

func total_frames() -> int:
	return (HOLD + FLIGHT + BURST) if is_new else NOTICE_FRAMES + 6

## Termina ya: el termo queda con el estado real de la compra.
func finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(thermos):
		var real: Dictionary = thermos.stickers.duplicate(true)
		real[sticker_id] = level_after
		thermos.stickers = real
		thermos.queue_redraw()
	hide()
	queue_free()

func step(delta: float) -> void:
	if finished: return
	elapsed += delta
	var f := int(elapsed / FRAME)
	if f >= total_frames():
		finish()
		return
	queue_redraw()
	if is_new:
		var flying := f >= HOLD and f < HOLD + FLIGHT
		badge.visible = flying
		if flying:
			var k := f - HOLD
			var t := smoothstep(0.0, 1.0, k / float(FLIGHT - 1))
			badge.position = flight_point(from, slot, k) - badge.size / 2.0
			badge.scale = Vector2.ONE * lerpf(1.0, END_SCALE, t)
			badge.rotation = deg_to_rad(sin(t * PI * 3.0) * 22.0) + t * Art.thermos_tilt(sticker_id)
		var landed := f >= HOLD + FLIGHT
		if landed and is_instance_valid(thermos) and not thermos.stickers.has(sticker_id):
			var shown: Dictionary = thermos.stickers.duplicate(true)
			shown[sticker_id] = level_after
			thermos.stickers = shown
			thermos.queue_redraw()
		var b := f - HOLD - FLIGHT
		notice.visible = landed and b < 10
		notice.position = notice_at(slot + Vector2(40, -40 - b))
	else:
		notice.visible = f >= 6
		var n := f - 6
		notice.position = notice_at(slot + Vector2(40, -30 - n))
		notice.modulate.a = 1.0 if n < 12 else 1.0 - (n - 12) / 6.0

## El aviso va a la derecha del lugar del sticker; si no entra en pantalla (el termo de la mesa está contra el borde), a la izquierda.
func notice_at(right: Vector2) -> Vector2:
	var width := notice.get_combined_minimum_size().x
	if right.x + width <= size.x - 8.0: return right
	return Vector2(right.x - 80.0 - width, right.y)

## Estela dorada detrás del sticker que vuela y destellos al pegarse.
func _draw() -> void:
	if not is_new: return
	var f := int(elapsed / FRAME)
	if f >= HOLD and f < HOLD + FLIGHT:
		var k := f - HOLD
		for g in range(1, 4):
			var back := maxi(0, int(k - g * 1.4))
			var p := flight_point(from, slot, back)
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), GOLD)
	var b := f - HOLD - FLIGHT
	if b >= 0 and b < 8:
		var r := 10.0 + b * 8.0
		for a in range(0, 360, 45):
			var p := slot + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * r
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color8(255, 232, 130))
