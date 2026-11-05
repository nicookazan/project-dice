extends Control
## El vaso que tira (animación A aprobada): se sacude con los dados detrás de su pared, sube a (1230, 372), se inclina
## 118° y los dados salen por su boca hasta sus lugares; después baja y se asienta. Se dibuja aparte mientras dura
## (el vaso quieto es parte del fondo) y por delante de los dados, para que salgan de atrás de su borde.
## Solo presentación: no usa el azar de la partida; los lugares de aterrizaje son los de siempre (loose_die_pose).

const Die = preload("res://scripts/die.gd")
const CUP = preload("res://assets/art/pixel-v3/vaso-v3.png")
const FRONT = preload("res://assets/art/pixel-v3/vaso-frente-v3.png")

const REST := Vector2(1352, 520)
const LIFT := Vector2(1230, 372)
const TILT := 118.0
const CUP_SIZE := Vector2(144, 188)
## Cuadros de cada tramo: sacudida, subida, vuelco, bajada y asiento (55 cuadros, unos 3 s).
const SHAKE := 10
const LIFTING := 9
const POURING := 22
const RETURNING := 10
const SETTLING := 4
const FRAMES := SHAKE + LIFTING + POURING + RETURNING + SETTLING
const FRAME_SECONDS := 0.055
const SHAKE_X := [0, -6, 6, -8, 8, -6, 6, -4, 4, 0]
const SHAKE_Y := [0, -2, 0, -4, 0, -2, 0, -2, 0, 0]
const INNER_OFFSETS := [-32.0, 0.0, 30.0]
const DELAYS := [0, 2, 3, 5, 6]
const SPIN := [540.0, -480.0, 600.0, -520.0, 460.0]
const MOUTH_UP := 88.0
const DICE_SIZE := Vector2(62, 62)

var cup_center := REST
var cup_rotation := 0.0
var shaking := false
var inner_dice: Array = []
var front_wall: TextureRect

static func ease_value(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

## Posición del centro del vaso y giro (grados, horario) en el cuadro `f`.
static func pose(f: int) -> Dictionary:
	f = clampi(f, 0, FRAMES - 1)
	if f < SHAKE:
		return {"center": REST + Vector2(SHAKE_X[f], SHAKE_Y[f]), "rotation": 0.0, "shaking": true}
	f -= SHAKE
	if f < LIFTING:
		var t := ease_value((f + 1) / float(LIFTING))
		return {"center": REST.lerp(LIFT, t), "rotation": -TILT * t, "shaking": false}
	f -= LIFTING
	if f < POURING:
		var jolt: bool = f < 8 and f % 2 == 1
		return {"center": LIFT + Vector2(0, 3 if jolt else 0), "rotation": -(TILT + (6.0 if jolt else 0.0)), "shaking": false}
	f -= POURING
	if f < RETURNING:
		var t := ease_value((f + 1) / float(RETURNING))
		return {"center": REST.lerp(LIFT, 1.0 - t) - Vector2(0, sin(t * PI) * 10.0), "rotation": -TILT * (1.0 - t), "shaking": false}
	f -= RETURNING
	return {"center": REST - Vector2(0, 4 if f == 1 else 0), "rotation": 0.0, "shaking": false}

## Boca del vaso inclinado (centro de la abertura), de donde salen los dados.
static func mouth() -> Vector2:
	var angle := deg_to_rad(-TILT)
	return LIFT + Vector2(MOUTH_UP * sin(angle), -MOUTH_UP * cos(angle))

## Estado de un dado en el cuadro `f`: {visible, center, rotation_offset}. `order` es su lugar en la tirada y
## `landing` el centro donde termina. Antes de salir está oculto; al final queda exactamente en `landing`.
static func die_state(order: int, f: int, landing: Vector2) -> Dictionary:
	var pour_start := SHAKE + LIFTING
	if f < pour_start: return {"visible": false, "center": landing, "spin": 0.0}
	var delay: int = DELAYS[order % DELAYS.size()]
	var g := f - pour_start
	if f >= pour_start + POURING: return {"visible": true, "center": landing, "spin": 0.0}
	var t := (g - delay) / 12.0
	if t <= 0.0: return {"visible": false, "center": landing, "spin": 0.0}
	t = minf(1.0, t)
	var out := mouth() + Vector2((order - 2) * 6.0, 6.0)
	var travel := 1.0 - pow(1.0 - t, 2.0)
	var center := out.lerp(landing, travel)
	center.y = lerpf(out.y, landing.y, t) + sin(t * PI) * 28.0 * (1.0 - t)
	if t >= 1.0:
		var rolling := g - delay - 12
		center.y -= absf(sin(rolling * 0.9)) * 7.0 * maxf(0.0, 1.0 - rolling / 5.0)
	return {"visible": true, "center": center, "spin": SPIN[order % SPIN.size()] * (1.0 - t)}

func _init() -> void:
	name = "CupThrow"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## `dice` son los estados de los dados (se usan los tres primeros, dentro del vaso, mientras se sacude).
func setup(dice: Array, context: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in range(3):
		var die := Die.new()
		die.configure_appearance(dice[k], context)
		die.locked = true
		die.focus_mode = Control.FOCUS_NONE
		die.size = DICE_SIZE
		die.pivot_offset = DICE_SIZE / 2.0
		die.scale = Vector2.ONE * 0.78
		die.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(die)
		inner_dice.append(die)
	front_wall = TextureRect.new()
	front_wall.texture = FRONT
	front_wall.size = Vector2(FRONT.get_size()) * 2.0
	front_wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	front_wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(front_wall)
	set_frame(0)

func set_frame(f: int) -> void:
	var state := pose(f)
	cup_center = state.center
	cup_rotation = state.rotation
	shaking = state.shaking
	front_wall.visible = shaking
	front_wall.position = cup_center - CUP_SIZE / 2.0
	for k in range(inner_dice.size()):
		var die: Control = inner_dice[k]
		die.visible = shaking
		var y := 452.0 + (cup_center.y - REST.y) - ((f + k) % 3) * 5.0
		die.position = Vector2(cup_center.x + INNER_OFFSETS[k], y) - DICE_SIZE / 2.0
		die.rotation_degrees = f * 37.0 + k * 50.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(cup_center, deg_to_rad(cup_rotation), Vector2.ONE)
	draw_texture_rect(CUP, Rect2(-CUP_SIZE / 2.0, CUP_SIZE), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
