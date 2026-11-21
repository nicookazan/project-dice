extends Control
## Confeti de victoria (boceto C del autor): dos cañones en las esquinas de abajo disparan piezas hacia el centro y
## serpentinas que se desenrollan. Todo a saltos de 0,1 s sobre una grilla de 4 px, como el resto de la presentación.
## Solo presentación: no toca el estado del juego y se borra solo al terminar.

const COLORS := [Color("74acdf"), Color.WHITE, Color("fcbf49"), Color("ffe278"), Color("568ec8")]
const STEP_SECONDS := 0.1
const FRAMES := 55
const PIECE_COUNT := 220
const STREAMER_COUNT := 10
const STREAMER_LENGTH := 14
const FLOOR_Y := 920.0
const CANNON_Y := 780.0
const CANNON_X := 20.0
const SCREEN_W := 1440.0
const GRID := 4.0
## Cuántas veces más rápido corre el reloj (la velocidad de la presentación).
var speed := 1.0
var elapsed := 0.0
var pieces: Array = []
var streamers: Array = []

func _ready() -> void:
	name = "Confetti"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	build(7)

func build(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	pieces.clear()
	streamers.clear()
	for i in PIECE_COUNT:
		var side := 1 if i % 2 == 1 else -1
		var angle := deg_to_rad(rng.randf_range(-80.0, -40.0) if side == 1 else rng.randf_range(-140.0, -100.0))
		var power := rng.randf_range(14.0, 30.0)
		pieces.append({"i": i, "side": side, "vx": cos(angle) * power, "vy": sin(angle) * power, "t0": rng.randi_range(0, 2), "sway": rng.randf_range(0.0, TAU), "color": COLORS[i % COLORS.size()]})
	for k in STREAMER_COUNT:
		var side := 1 if k % 2 == 1 else -1
		var angle := deg_to_rad(rng.randf_range(-75.0, -50.0) if side == 1 else rng.randf_range(-130.0, -105.0))
		var power := rng.randf_range(16.0, 28.0)
		streamers.append({"side": side, "vx": cos(angle) * power, "vy": sin(angle) * power, "phase": rng.randf_range(0.0, TAU), "color": COLORS[(k + 1) % 3]})

## Posición (px de pantalla de 1440×900) de una pieza `t` pasos después de salir del cañón, o Vector2.INF si ya no se ve.
static func position_at(side: int, vx: float, vy: float, sway: float, t: float, wobble: float) -> Vector2:
	var ox := CANNON_X if side == 1 else SCREEN_W - CANNON_X
	var p := Vector2(ox + vx * t * 0.8 + sin(t * 0.8 + sway) * wobble, CANNON_Y + vy * t + 0.8 * t * t)
	return Vector2.INF if p.y > FLOOR_Y else p

func _process(delta: float) -> void:
	elapsed += delta * speed
	queue_redraw()
	if elapsed >= FRAMES * STEP_SECONDS: queue_free()

func _draw() -> void:
	var f := int(elapsed / STEP_SECONDS)
	for piece in pieces:
		var t: float = f - piece.t0
		if t < 0.0: continue
		var p := position_at(piece.side, piece.vx, piece.vy, piece.sway, t, 5.0)
		if p == Vector2.INF: continue
		var shape: int = (piece.i + f) % 3
		var size := Vector2(8, 8) if shape == 0 else (Vector2(12, 4) if shape == 1 else Vector2(4, 12))
		draw_rect(Rect2((p / GRID).floor() * GRID, size), piece.color)
	for streamer in streamers:
		for j in STREAMER_LENGTH:
			var t: float = f - j * 0.7
			if t < 0.0: continue
			var p := position_at(streamer.side, streamer.vx, streamer.vy, streamer.phase, t, 18.0)
			if p == Vector2.INF: continue
			draw_rect(Rect2((p / GRID).floor() * GRID, Vector2(GRID, GRID)), streamer.color)
