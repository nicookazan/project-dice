extends RefCounted
## Objetos del bar que reaccionan al clic: sifones, bandera y termo (que ceba el mate). Sistema común: una zona
## clickeable, un borde dorado que sigue la silueta al pasar el mouse y una animación que termina en el estado
## inicial. Todo es presentación: el azar es propio (semillas por cuadro), no toca la partida ni su semilla, y se
## apaga con "Reducir movimiento" o velocidad 0.
##
## El estado vive en el fondo (Backdrop), que sobrevive a cada render de la pantalla; las zonas son de la mesa.
## La animación se mide en cuadros como los bocetos aprobados (tools/art/bocetos-jugabilidad/anim.py).

const SALON = preload("res://assets/art/pixel-v3/salon-v3.png")
const FLAG = preload("res://assets/art/pixel-v3/bandera-v3.png")
const FLAG_PATCH = preload("res://assets/art/pixel-v3/bandera-fondo-v3.png")
const THERMOS = preload("res://assets/art/pixel-v3/termo-mesa-v3.png")
const HAND_POSES = preload("res://assets/art/pixel-v3/manos-poses-v3.png")
const Tip = preload("res://scripts/item_tooltip.gd")
const StickerArt = preload("res://scripts/sticker_art.gd")
const StickerDefinitions = preload("res://scripts/stickers.gd")

## Cuadros y segundos por cuadro de cada animación (termo 5,5 s, sifón 3,1 s, bandera 2,4 s).
const SPECS := {
	"thermos": {"frames": 78, "seconds": 0.07},
	"soda_left": {"frames": 52, "seconds": 0.06},
	"soda_right": {"frames": 52, "seconds": 0.06},
	"flag": {"frames": 34, "seconds": 0.07},
	"hand": {"frames": 28, "seconds": 0.075}}
## Desplazamiento de cada sifón respecto del primero (el salón repite el motivo a 432 px).
const SODA_SHIFT := {"soda_left": 0.0, "soda_right": 432.0}
## Aros dorados: textura y lugar en pantalla (los calcula tools/art/make_bar_props.py).
const RINGS := {
	"flag": ["res://assets/art/pixel-v3/aro-bandera-v3.png", Vector2(1302, 60)],
	"soda_left": ["res://assets/art/pixel-v3/aro-sifon-izq-v3.png", Vector2(384, 222)],
	"soda_right": ["res://assets/art/pixel-v3/aro-sifon-der-v3.png", Vector2(816, 222)],
	"thermos": ["res://assets/art/pixel-v3/aro-termo-v3.png", Vector2(1205, 166)],
	"cup": ["res://assets/art/pixel-v3/aro-vaso-v3.png", Vector2(1278, 424)],
	"hand": ["res://assets/art/pixel-v3/aro-mano-v3.png", Vector2(622, 32)]}
## Zonas clickeables de los objetos que no tienen botón propio (el termo usa el suyo).
const ZONES := {
	"flag": Rect2(1298, 56, 80, 180),
	"soda_left": Rect2(380, 218, 26, 46),
	"soda_right": Rect2(812, 218, 26, 46)}
const THERMOS_REST := Vector2(1275, 343)
const THERMOS_KEYS := [
	[0, Vector2(1275, 343), 0.0], [7, Vector2(1275, 232), 0.0], [16, Vector2(1000, 232), 0.0], [24, Vector2(966, 426), 68.0],
	[48, Vector2(966, 426), 68.0], [56, Vector2(1000, 232), 0.0], [65, Vector2(1275, 232), 0.0], [72, Vector2(1275, 343), 0.0], [78, Vector2(1275, 343), 0.0]]
const MATE_MOUTH := Vector2(1156, 432)
const THERMOS_SIZE := Vector2(144, 350)

var motion := true
var speed := 1
var elapsed: Dictionary = {}
## Objetos ocupados por otra animación (la tirada del vaso): sin aro dorado mientras dure.
var held: Dictionary = {}
## Piedra, papel o tijera de la mano del fondo: solo un gesto, sin ganador ni efecto. Azar propio, aparte del de la partida.
const POSES := ["piedra", "papel", "tijera"]
const POSE_WORDS := ["PIEDRA", "PAPEL", "TIJERA"]
const HAND_BEAT_OFFSETS := [-4, -14, -18, -8, 4, 10]
const HAND_CELL := Vector2(61, 53)
## Fila de la hoja de poses de la mano común (después de las 18 de jefe).
const COMMON_HAND_ROW := 18
var hand_result := "papel"
var hand_rng := RandomNumberGenerator.new()
var hand_font: Font

# ---------- estado ----------

## Empieza la animación de `id`. No hace nada si el movimiento está apagado o ya está en marcha.
func play(id: String) -> bool:
	if not motion or not SPECS.has(id) or elapsed.has(id): return false
	elapsed[id] = 0.0
	return true

func busy(id: String) -> bool:
	return elapsed.has(id) or held.has(id)

func any_busy() -> bool:
	return not elapsed.is_empty()

func stop_all() -> void:
	elapsed.clear()

func step(delta: float) -> void:
	var rate := 1.6 if speed == 2 else 1.0
	for id in elapsed.keys():
		elapsed[id] += delta * rate
		if elapsed[id] >= SPECS[id].frames * SPECS[id].seconds: elapsed.erase(id)

## Cuadro actual de `id` (-1 si no está en marcha).
func frame(id: String) -> int:
	if not elapsed.has(id): return -1
	return mini(int(elapsed[id] / SPECS[id].seconds), SPECS[id].frames - 1)

static func ease_value(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

# ---------- termo ----------

## Posición y giro (grados, horario) del termo en el cuadro `f`, y si pasa por delante del mate.
static func thermos_pose(f: int) -> Dictionary:
	for i in range(THERMOS_KEYS.size() - 1):
		var a: Array = THERMOS_KEYS[i]
		var b: Array = THERMOS_KEYS[i + 1]
		if f >= a[0] and f <= b[0]:
			var t := ease_value(float(f - a[0]) / maxf(1.0, float(b[0] - a[0])))
			return {"center": a[1].lerp(b[1], t), "rotation": lerpf(a[2], b[2], t), "over": f >= 7 and f <= 65}
	return {"center": THERMOS_REST, "rotation": 0.0, "over": false}

## Dibuja el termo (con sus stickers) con su centro en `center`, girado `degrees` en sentido horario.
static func draw_thermos(canvas: CanvasItem, center: Vector2, degrees: float, stickers: Dictionary) -> void:
	canvas.draw_set_transform(center, deg_to_rad(degrees), Vector2.ONE)
	canvas.draw_texture_rect(THERMOS, Rect2(-THERMOS_SIZE / 2.0, THERMOS_SIZE), false)
	for id in StickerDefinitions.NAMES:
		if stickers.has(id): StickerArt.draw_on_thermos(canvas, -THERMOS_SIZE / 2.0, id)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func snap(value: float) -> float:
	return floorf(value / 2.0) * 2.0

## Chorro de agua, yerba y vapor del termo que ceba (cuadros 26 a 47 el chorro; el vapor sigue subiendo).
func draw_pour_effects(canvas: CanvasItem, f: int) -> void:
	var pose := thermos_pose(f)
	if f >= 26 and f <= 47:
		var angle := deg_to_rad(-pose.rotation)
		var spout := Vector2(snappedf(pose.center.x - sin(angle) * 175.0, 2.0), snappedf(pose.center.y - cos(angle) * 175.0, 2.0))
		var y := spout.y
		while y < MATE_MOUTH.y:
			var t := (y - spout.y) / maxf(1.0, MATE_MOUTH.y - spout.y)
			var x := snap(lerpf(spout.x, MATE_MOUTH.x, pow(t, 0.6)))
			var water := Color8(214, 238, 248) if (int(y / 2.0) + f) % 3 != 0 else Color8(150, 200, 226)
			canvas.draw_rect(Rect2(x, y, 4, 2), water)
			if (int(y / 2.0) + f) % 5 == 0: canvas.draw_rect(Rect2(x + 4, y, 2, 2), Color8(240, 250, 255))
			y += 2.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 5000 + f
		for k in range(8):
			var px := MATE_MOUTH.x + rng.randi_range(-22, 22)
			var py := MATE_MOUTH.y + rng.randi_range(-4, 6)
			var yerba: Array = [Color8(190, 220, 120), Color8(230, 245, 180), Color8(120, 170, 70)]
			canvas.draw_rect(Rect2(snap(px), snap(py), 2, 2), yerba[rng.randi_range(0, 2)])
	# Vapor: nace cada dos cuadros durante el chorro y sube hasta apagarse.
	for spawn in range(26, 48, 2):
		if spawn > f: break
		var rng := RandomNumberGenerator.new()
		rng.seed = 9000 + spawn
		var x0 := MATE_MOUTH.x + rng.randi_range(-18, 18)
		var life := rng.randi_range(14, 24)
		var x := x0
		var size := life
		var age := f - spawn
		var y_now := MATE_MOUTH.y - 8.0
		for step_index in range(age):
			x += [-2, 0, 2][rng.randi_range(0, 2)]
			y_now -= 4.0
			size -= 1
		if size <= 0: continue
		var gray := 230 - (24 - size) * 4
		canvas.draw_rect(Rect2(snap(x), snap(y_now), 4, 4), Color8(clampi(gray, 0, 255), clampi(gray, 0, 255), clampi(gray, 0, 255)))

# ---------- bandera ----------

## La bandera ondula por filas sobre su dibujo exacto; la onda se amortigua en 34 cuadros.
func draw_flag(canvas: CanvasItem) -> void:
	var f := frame("flag")
	if f < 0: return
	canvas.draw_texture_rect(FLAG_PATCH, Rect2(646 * 2, 31 * 2, 48 * 2, 87 * 2), false)
	var amp := 3.2 * exp(-f / 16.0) * (1.0 if f >= 2 else 0.0)
	for y in range(31, 118):
		var k := pow(maxf(0.0, y - 30.0) / 82.0, 1.3)
		var wave := (y - 30) * 0.13 - f * 0.8
		var dx := int(roundf(amp * k * sin(wave)))
		var shade := 1.0 + 0.09 * cos(wave) * minf(1.0, amp / 2.5) * k
		# Fila `y` del dibujo (columnas 640..700) desplazada `dx`, recortada a la zona tapada (646..694).
		var left := maxi(640 + dx, 646)
		var right := mini(700 + dx, 694)
		if right <= left: continue
		canvas.draw_texture_rect_region(FLAG, Rect2(left * 2, y * 2, (right - left) * 2, 2), Rect2(left - dx - 640, y - 31, right - left, 1), Color(shade, shade, shade))

# ---------- sifón ----------

## El sifón se aprieta (la cabeza baja 2 px), tira un chorro largo que cae en el vaso de al lado y lo llena de espuma.
func draw_soda(canvas: CanvasItem, id: String) -> void:
	var f := frame(id)
	if f < 0: return
	var shift: float = SODA_SHIFT[id]
	var nozzle := Vector2(399.0 + shift, 229.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + f + int(shift)
	if f >= 4 and f <= 34:
		# La cabeza del sifón, 2 px más abajo.
		canvas.draw_texture_rect_region(SALON, Rect2(386.0 + shift, 226, 20, 12), Rect2((386.0 + shift) / 2.0, 112, 10, 6))
		var aim := ease_value((f - 9) / 5.0)
		var power := 1.0 if f < 31 else maxf(0.0, (35 - f) / 4.0)
		var dx := lerpf(110.0, 13.0, aim) * power
		var h := lerpf(22.0, 12.0, aim) * power
		var dr := lerpf(34.0, 20.0, aim) * power
		for k in range(46):
			var t := k / 46.0
			var x := nozzle.x + dx * t
			var y := nozzle.y - h * sin(minf(1.0, t * 1.25) * PI) + dr * t * t
			if (k + f * 2) % 9 == 0: continue
			var water := Color8(214, 240, 250) if (k + f) % 3 != 0 else Color8(150, 205, 232)
			canvas.draw_rect(Rect2(snap(x), snap(y), 4, 4), water)
		for k in range(4):
			var sx := nozzle.x + dx + rng.randi_range(-8, 8)
			var sy := minf(264.0, nozzle.y + dr + rng.randi_range(-6, 8))
			canvas.draw_rect(Rect2(snap(sx), snap(sy), 2, 2), Color8(226, 244, 252))
	# El vaso se va llenando desde que el chorro lo alcanza.
	if f >= 13:
		var fill := ease_value((f - 13) / 20.0)
		var top := snap(lerpf(252.0, 248.0, fill))
		var left := 410.0 + shift
		canvas.draw_rect(Rect2(left, top, 6, 256.0 - top), Color8(200, 124, 26))
		if f > 16:
			var foam_top := top - 2.0 if fill < 1.0 else 244.0
			canvas.draw_rect(Rect2(left, foam_top, 6, top - foam_top), Color8(250, 246, 228))
			for k in range(2):
				var bx := left + 2.0 * rng.randi_range(0, 2)
				var by := snap(rng.randf_range(top, 254.0))
				if f <= 44: canvas.draw_rect(Rect2(bx, by, 2, 2), Color8(236, 186, 92))

# ---------- mano ----------

func _init() -> void:
	hand_rng.randomize()

## La mano golpea tres veces con el puño y juega piedra, papel o tijera al azar (azar cosmético propio).
func play_hand() -> bool:
	if not play("hand"): return false
	hand_result = POSES[hand_rng.randi_range(0, POSES.size() - 1)]
	return true

## Qué muestra la mano en el cuadro `f` de su gesto: pose (0 piedra, 1 papel, 2 tijera), desplazamiento vertical y texto.
static func hand_beat(f: int, result: String) -> Dictionary:
	if f < 18:
		return {"pose": 0, "dy": HAND_BEAT_OFFSETS[f % 6], "text": POSE_WORDS[f / 6] + "...", "final": false}
	return {"pose": maxi(0, POSES.find(result)), "dy": 10 if f < 20 else 2, "text": result.to_upper() + "!", "final": true}

## Dibuja la mano del gesto en lugar de la que tamborilea. `row` es la fila de la mano (-1: la común).
func draw_hand_gesture(canvas: CanvasItem, row: int) -> void:
	var f := frame("hand")
	if f < 0: return
	var beat := hand_beat(f, hand_result)
	var sheet_row := row if row >= 0 else COMMON_HAND_ROW
	canvas.draw_texture_rect_region(HAND_POSES, Rect2(624, 34 + beat.dy, 122, 106), Rect2(beat.pose * HAND_CELL.x, sheet_row * HAND_CELL.y, HAND_CELL.x, HAND_CELL.y))
	if hand_font == null: hand_font = Tip.pixel_font()
	var font := hand_font
	var size := 24 if beat.final else 18
	var width := font.get_string_size(beat.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var origin := Vector2(685.0 - width / 2.0, 176.0 + size)
	canvas.draw_string(font, origin + Vector2(1, 1), beat.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color8(25, 10, 16))
	canvas.draw_string(font, origin, beat.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color8(240, 200, 80) if beat.final else Color8(255, 240, 199))

# ---------- zonas y aro dorado ----------

## Borde dorado sobre la silueta de un objeto: se ve solo con el mouse encima y mientras no se anima.
class Ring extends TextureRect:
	var props: RefCounted
	var prop_id := ""
	var hovered := false

	func _process(_delta: float) -> void:
		visible = hovered and not props.busy(prop_id)

## Le pone a `host` el aro dorado de `id`: aparece al pasar el mouse por `host`.
static func attach_ring(host: Control, id: String, props: RefCounted) -> Ring:
	var ring := Ring.new()
	ring.name = "Ring_" + id
	ring.texture = load(RINGS[id][0])
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ring.stretch_mode = TextureRect.STRETCH_KEEP
	ring.props = props
	ring.prop_id = id
	ring.top_level = true
	ring.position = RINGS[id][1]
	ring.z_index = 20
	ring.hide()
	host.add_child(ring)
	host.mouse_entered.connect(func(): ring.hovered = true)
	host.mouse_exited.connect(func(): ring.hovered = false)
	return ring

## Zona clickeable de un objeto del fondo.
class Zone extends Control:
	signal clicked
	var prop_id := ""

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			clicked.emit()

static func make_zone(id: String, props: RefCounted) -> Zone:
	var zone := Zone.new()
	zone.name = "BarProp_" + id
	zone.prop_id = id
	zone.position = ZONES[id].position
	zone.size = ZONES[id].size
	zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	attach_ring(zone, id, props)
	return zone
