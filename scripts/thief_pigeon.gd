extends Control
## Paloma ladrona (jefe 1C): sale de la mano del jefe, baja al dado marcado, lo agarra y se lo lleva al vaso.
## Solo presentación: en el juego el dado ya está en el vaso desde que se tiró. `done` avisa cuando termina.
const SHEET = preload("res://assets/art/pixel-v3/paloma-ladrona-v4.png")
const FRAME := Vector2(18, 16)
const SCALE := 4.0
const FLAP := [0, 1, 2, 1]
const FLAP_SECONDS := 0.09
const ARRIVE := 0.8
const GRAB := 0.3
const CARRY := 1.0

var die: Control
var start := Vector2.ZERO
var grab := Vector2.ZERO
var drop := Vector2.ZERO
var speed := 1.0
var elapsed := 0.0
var done := false
var facing_left := false
var position_now := Vector2.ZERO

func _init() -> void:
	name = "ThiefPigeon"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 35
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## Dónde está la paloma en el instante `t` (segundos de animación): llega, baja al dado y lo lleva al vaso.
static func place(t: float, begin: Vector2, above: Vector2, down: Vector2, away: Vector2) -> Vector2:
	if t < ARRIVE: return begin.lerp(above, 1.0 - pow(1.0 - t / ARRIVE, 2.0))
	if t < ARRIVE + GRAB: return above.lerp(down, (t - ARRIVE) / GRAB)
	var u := clampf((t - ARRIVE - GRAB) / CARRY, 0.0, 1.0)
	var lift := sin(u * PI) * 40.0
	return down.lerp(away, u * u * (3.0 - 2.0 * u)) - Vector2(0, lift)

func _process(delta: float) -> void:
	if done: return
	elapsed += delta * speed
	var above := grab + Vector2(0, -34)
	var previous := position_now
	position_now = place(elapsed, start, above, grab + Vector2(0, -6), drop)
	if absf(position_now.x - previous.x) > 0.2: facing_left = position_now.x < previous.x
	if elapsed >= ARRIVE + GRAB and is_instance_valid(die):
		var u := clampf((elapsed - ARRIVE - GRAB) / CARRY, 0.0, 1.0)
		die.global_position = position_now + Vector2(0, 30) - die.size / 2.0
		die.scale = Vector2.ONE * lerpf(1.0, 0.45, u)
		die.modulate.a = 1.0 if u < 0.7 else (1.0 - u) / 0.3
	if elapsed >= ARRIVE + GRAB + CARRY: done = true
	queue_redraw()

func _draw() -> void:
	if done: return
	var frame: int = FLAP[int(elapsed / FLAP_SECONDS) % FLAP.size()]
	var size_px := FRAME * SCALE
	var rect := Rect2(position_now - size_px / 2.0, size_px)
	if facing_left: rect = Rect2(rect.position + Vector2(size_px.x, 0), Vector2(-size_px.x, size_px.y))
	draw_texture_rect_region(SHEET, rect, Rect2(frame * FRAME.x, 0, FRAME.x, FRAME.y))
