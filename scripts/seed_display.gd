extends Control
## La semilla en pantalla (docs/LA-SEMILLA.md), con una letra de 5×7 píxeles lógicos (cada uno ocupa 2×2 de pantalla).
##   «small»: arriba a la izquierda, sobre la libreta, tenue pero legible. Se ve durante toda la jugada en la mesa.
##   «terminal»: La Semilla como jefe (boceto C2 + C3): recuadro verde de terminal con esquinas marcadas y cursor. Con
##   `intro`, viaja desde la semilla chica al centro mientras crece y cada número gira entre dígitos al azar hasta
##   fijarse; espera y sube a su lugar arriba. Después parpadea el cursor y cada tanto un número se «bugea» un cuadro.
## Solo presentación: el azar visual sale de la semilla y del tiempo, nunca del azar de la jugada.
signal intro_finished

const FONT := {
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
	"6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	" ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
}
const SMALL_PREFIX := "SEMILLA "
## Origen de la semilla chica en píxeles lógicos (arriba a la izquierda, encima de la libreta).
const SMALL_ORIGIN := Vector2(15, 3)
const SMALL_COLOR := Color("cdbb8f")
const SMALL_SHADOW := Color(0.08, 0.05, 0.03, 0.8)
const GREEN := Color("5cff6a")
const GLOW := Color(0.118, 0.604, 0.196, 0.55)
const TEXT := Color("dcffe0")
const BOX := Color(0, 0, 0, 0.88)
## Lugar final del número grande (centro, en píxeles lógicos) y su escala.
const FINAL_CENTER := Vector2(360, 62)
const BIG := 4
## Tiempos del viaje, en cuadros de 90 ms como el boceto: viaja 14, espera hasta el 26, sube 10.
const FRAME := 0.09
const TRAVEL_FRAMES := 14.0
const RISE_FROM := 26.0
const RISE_FRAMES := 10.0
const INTRO_FRAMES := 40.0

var seed_text := "0"
var mode := "small"
var intro := false
var motion := true
var speed := 1.0
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func setup(run_seed: int, display_mode: String, animate_intro := false, preferences: Dictionary = {}) -> void:
	seed_text = str(run_seed)
	mode = display_mode
	motion = not preferences.get("reduced_motion", false) and preferences.get("speed", 1) != 0
	speed = float(maxi(int(preferences.get("speed", 1)), 1))
	intro = animate_intro and motion and mode == "terminal"
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if mode != "terminal" or not motion: return
	elapsed += delta * speed
	queue_redraw()
	if intro and elapsed / FRAME >= INTRO_FRAMES:
		intro = false
		intro_finished.emit()

## Ancho en píxeles lógicos de un texto a escala 1.
static func text_width(text: String) -> int:
	return text.length() * 6 - 1

## Rectángulo de pantalla del recuadro de la terminal en su lugar final (para el botón que muestra el poder).
static func final_box(digits: int) -> Rect2:
	var width := (digits * 6 - 1) * BIG
	var pad := 10
	var logical := Rect2(FINAL_CENTER.x - width / 2.0 - pad, FINAL_CENTER.y - 7 * BIG / 2.0 - pad, width + pad * 2, 7 * BIG + pad * 2)
	return Rect2(logical.position * 2.0, logical.size * 2.0)

## Dibuja un texto con la letra 5×7. `origin` en píxeles lógicos; `grow` agranda cada punto (para el brillo).
func draw_text_at(text: String, origin: Vector2, scale: int, color: Color, grow := 0) -> void:
	for i in text.length():
		var glyph: Array = FONT.get(text[i], FONT[" "])
		for row in 7:
			var line: String = glyph[row]
			for col in 5:
				if line[col] != "1": continue
				var at := origin + Vector2((i * 6 + col) * scale - grow, row * scale - grow)
				draw_rect(Rect2(at * 2.0, Vector2(scale + grow * 2, scale + grow * 2) * 2.0), color)

func _draw() -> void:
	if mode == "small":
		var text := SMALL_PREFIX + seed_text
		draw_text_at(text, SMALL_ORIGIN + Vector2.ONE, 1, SMALL_SHADOW)
		draw_text_at(text, SMALL_ORIGIN, 1, SMALL_COLOR)
		return
	var frame := elapsed / FRAME if motion and intro else (elapsed / FRAME + INTRO_FRAMES if motion else INTRO_FRAMES)
	var t1 := smoothstep(0.0, 1.0, frame / TRAVEL_FRAMES)
	var t2 := smoothstep(0.0, 1.0, (frame - RISE_FROM) / RISE_FRAMES)
	# Empieza donde está la parte numérica de la semilla chica.
	var start := SMALL_ORIGIN + Vector2(text_width(SMALL_PREFIX) + 1 + text_width(seed_text) / 2.0, 3.5)
	var middle := Vector2(360, 225)
	var center := start.lerp(middle, t1) + Vector2(0, (FINAL_CENTER.y - middle.y) * t2)
	var scale := maxi(1, roundi(lerpf(1.0, BIG, t1)))
	var width := text_width(seed_text) * scale
	var origin := (center - Vector2(width / 2.0, 7 * scale / 2.0)).round()
	var tick := int(frame)
	# Decodificación: cada número gira hasta fijarse (solo en el viaje); después, de vez en cuando uno se «bugea».
	var shown := ""
	for i in seed_text.length():
		var locked := not intro or frame >= 12.0 + i * 1.6
		shown += seed_text[i] if locked else str(_noise(tick, i) % 10)
	if not intro and motion and tick % 7 == 3:
		var j := _noise(tick, 99) % seed_text.length()
		shown = shown.substr(0, j) + str(_noise(tick, 7) % 10) + shown.substr(j + 1)
	if frame > 2.0:
		var pad := maxi(2, int(10.0 * scale / BIG))
		var box := Rect2(origin - Vector2(pad, pad), Vector2(width + pad * 2, 7 * scale + pad * 2))
		draw_rect(Rect2(box.position * 2.0, box.size * 2.0), BOX)
		draw_rect(Rect2(box.position * 2.0, box.size * 2.0), GREEN, false, 2.0)
		var arm := maxi(3, int(8.0 * scale / BIG))
		for corner in [box.position + Vector2(-2, -2), Vector2(box.end.x + 1, box.position.y - 2), Vector2(box.position.x - 2, box.end.y + 1), box.end + Vector2(1, 1)]:
			var sx := 1.0 if corner.x < center.x else -1.0
			var sy := 1.0 if corner.y < center.y else -1.0
			var c: Vector2 = corner
			draw_rect(Rect2(Vector2(minf(c.x, c.x + sx * arm), minf(c.y, c.y + sy * 2)) * 2.0, Vector2(arm, 2) * 2.0), GREEN)
			draw_rect(Rect2(Vector2(minf(c.x, c.x + sx * 2), minf(c.y, c.y + sy * arm)) * 2.0, Vector2(2, arm) * 2.0), GREEN)
	# Fallas de imagen: copias roja y celeste corridas, unos pocos cuadros cada tanto.
	var glitch := motion and (tick % 37 in [31, 32] or (not intro and tick % 53 == 41))
	if glitch:
		var shift := 3 + _noise(tick, 3) % 4
		draw_text_at(shown, origin + Vector2(shift, 0), scale, Color(1, 0.15, 0.2, 0.6))
		draw_text_at(shown, origin - Vector2(shift, 0), scale, Color(0.1, 1, 1, 0.6))
	draw_text_at(shown, origin, scale, GLOW, maxi(1, scale / 2))
	draw_text_at(shown, origin, scale, TEXT)
	if frame > 14.0 and (not motion or int(frame / 4.0) % 2 == 0):
		draw_rect(Rect2((origin + Vector2(width + 2 * scale, 0)) * 2.0, Vector2(4 * scale, 7 * scale) * 2.0), GREEN)

## Ruido visual reproducible (no usa el azar de la jugada).
func _noise(tick: int, salt: int) -> int:
	return absi(("%s:%d:%d" % [seed_text, tick, salt]).hash())
