extends Control
const EXTERIORS = preload("res://assets/art/pixel-v3/exteriores-v3.png")
const CLEAN_TABLE = preload("res://assets/art/environment-v2/mesa-libreta-frontal-v1.png")
const TABLE_V3 = preload("res://assets/art/pixel-v3/mesa-v3.png")
const SALON_V3 = preload("res://assets/art/pixel-v3/salon-v3.png")
const MULLIONS_V3 = preload("res://assets/art/pixel-v3/parteluces-v3.png")
const THERMOS_TABLE_V3 = preload("res://assets/art/pixel-v3/termo-mesa-v3.png")
const MATE_V3 = preload("res://assets/art/pixel-v3/mate-v3.png")
const CUP_V3 = preload("res://assets/art/pixel-v3/vaso-v3.png")
const CLOUD_V3 = preload("res://assets/art/pixel-v3/nube-v3.png")
const HAND_V3 = preload("res://assets/art/pixel-v3/mano-v3.png")
const BOSS_HANDS = preload("res://assets/art/pixel-v3/manos-jefes-v3.png")
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const HandClips = preload("res://scripts/boss_hand_clips.gd")
## Animación al clic de los guardianes (make_guardianes_clic_v4.py): una fila por guardián, 16 cuadros de 124×100.
const GUARDIAN_CLIC = preload("res://assets/art/pixel-v3/guardianes/guardianes-clic-v4.png")
const GUARDIAN_SIZE := Vector2(124, 100)
## El ojo solar parpadea y mira a los lados cada tanto mientras está en reposo (16 cuadros de 110 ms y una pausa).
const EYE_IDLE = preload("res://assets/art/pixel-v3/guardianes/guardian-ojo-reposo-v4.png")
const EYE_IDLE_FRAMES := 16
const EYE_IDLE_SECONDS := 0.11
const EYE_IDLE_PAUSE := 3.0
## La figura de luz en reposo: las esferas respiran y titilan estrellas (24 cuadros de 120 ms, en bucle, sin pausa) y
## flota un poco más alto y más lento que los otros guardianes.
const FIGURE_IDLE = preload("res://assets/art/pixel-v3/guardianes/guardian-figura-reposo-v4.png")
const FIGURE_IDLE_FRAMES := 24
const FIGURE_IDLE_SECONDS := 0.12
const GUARDIAN_ART := [preload("res://assets/art/pixel-v3/guardianes/guardian-ojo-v3.png"), preload("res://assets/art/pixel-v3/guardianes/guardian-figura-v3.png"), preload("res://assets/art/pixel-v3/guardianes/guardian-dado-v3.png")]
const HAND_FRAMES := 8
const HAND_SIZE := Vector2i(61, 53)
const HAND_FRAME_SECONDS := 0.11
const StickerArt = preload("res://scripts/sticker_art.gd")
const StickerDefinitions = preload("res://scripts/stickers.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const WindowFx = preload("res://scripts/window_fx.gd")
## Sifones, bandera y termo que reaccionan al clic (animaciones de presentación).
var props := BarProps.new()
## Fondos animados de las ventanas (TX2): textura aparte que solo existe con movimiento y en ambientes animados.
var window_fx: SubViewport
var fx_key := ""
var pour_layer: Control
## Mientras el vaso tira se dibuja aparte (CupThrow): el del fondo se oculta.
var cup_hidden := false
var last_shop_mode := false
var stickers: Dictionary = {}
const THERMOS_ORIGIN = Vector2(1203, 168)
const THERMOS_RECT = Rect2(1203, 170, 144, 225)
const CUP_RECT = Rect2(1260, 400, 145, 180)
## Zona clickeable de la mano del fondo (con el vaivén) y del triángulo de Dios.
const HAND_RECT = Rect2(624, 31, 122, 112)
const GOD_RECT = Rect2(567, 25, 200, 170)
const CUP_MOUTH = Vector2(1330, 425)
## Termo robado por Don Cebador: flota junto a la mano mientras dura el jefe (solo presentación).
const STOLEN_THERMOS_POS := Vector2(792, 34)
const STOLEN_THERMOS_SCALE := 0.42
const STOLEN_THERMOS_RECT := Rect2(792, 30, 62, 152)
const THERMOS_FLIGHT_SECONDS := 2.6
var thermos_stolen := false
var thermos_t := 0.0
var thermos_configured := false
## Fila de la hoja de manos de jefe (-1: la mano común).
var hand_row := -1
## Id del jefe cuya mano v4 (con animación propia) se dibuja; "" = la mano de la hoja anterior (El Gótico, la común).
var hand_boss := ""
## Guardián de Dios (-1: sin figura, queda el triángulo provisional).
var guardian := -1
var shop_mode := false
const WINDOWS = [Rect2(470, 0, 47, 217), Rect2(534, 0, 378, 219), Rect2(952, 0, 92, 215), Rect2(1198, 43, 73, 177)]
var environment_id := "dia"
var actor := "common"
var level := 0
var motion := true
var speed := 1
var elapsed := 0.0

func configure(profile: Dictionary, preferences: Dictionary) -> void:
	var stolen: bool = profile.get("thermos_stolen", false)
	motion = not preferences.reduced_motion and preferences.speed != 0
	# Primera lectura (carga a mitad del jefe) o movimiento apagado: directo a la posición final.
	if not thermos_configured or not motion: thermos_t = 1.0 if stolen else 0.0
	thermos_stolen = stolen
	thermos_configured = true
	environment_id = profile.environment
	actor = profile.actor
	guardian = BossCatalog.guardian(profile.get("boss_id", "")) if actor == "god" else -1
	# Todos los encuentros de un nivel (rivales y jefe) muestran la mano del jefe del nivel; Dios y los niveles sin jefe, la común.
	hand_row = BossCatalog.hand_row(profile.get("boss_id", "")) if actor != "god" else -1
	hand_boss = profile.get("boss_id", "") if actor != "god" and HandClips.CLIPS.has(profile.get("boss_id", "")) else ""
	level = profile.level
	motion = not preferences.reduced_motion and preferences.speed != 0
	speed = preferences.speed
	props.motion = motion
	props.speed = speed
	_configure_window_fx(profile)
	# Las animaciones solo existen sobre la mesa y con movimiento: cualquier otro cambio las corta.
	if shop_mode != last_shop_mode or not motion: props.stop_all()
	last_shop_mode = shop_mode
	queue_redraw()
	if is_instance_valid(pour_layer): pour_layer.queue_redraw()

## Activa, cambia o apaga el fondo animado. Sin movimiento (o en «cierre») se ve el cuadro fijo de siempre.
func _configure_window_fx(profile: Dictionary) -> void:
	if not (motion and WindowFx.is_animated(environment_id)):
		fx_key = ""
		if window_fx != null: window_fx.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var gothic: bool = WindowFx.is_gothic(profile)
	if window_fx == null:
		window_fx = WindowFx.new()
		add_child(window_fx)
	var key := "%s:%s" % [environment_id, gothic]
	if key != fx_key:
		window_fx.setup(environment_id, gothic)
		fx_key = key
	window_fx.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(delta: float) -> void:
	if props.any_busy():
		props.step(delta)
		queue_redraw()
		pour_layer.queue_redraw()
	var goal := 1.0 if thermos_stolen else 0.0
	if motion and thermos_t != goal:
		thermos_t = move_toward(thermos_t, goal, delta * speed / THERMOS_FLIGHT_SECONDS)
		queue_redraw()
	if motion:
		elapsed += delta * speed
		if fx_key != "": window_fx.update_time(elapsed)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# El termo que cruza por delante del mate y su chorro se dibujan encima de los dados de la mesa.
	pour_layer = Control.new()
	pour_layer.name = "PourLayer"
	pour_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pour_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pour_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pour_layer.z_index = 5
	pour_layer.draw.connect(_draw_pour_layer)
	add_child(pour_layer)

func _draw_pour_layer() -> void:
	var f := props.frame("thermos")
	if f < 0: return
	props.draw_pour_effects(pour_layer, f)
	var pose := BarProps.thermos_pose(f)
	if pose.over: BarProps.draw_thermos(pour_layer, pose.center, pose.rotation, stickers)

## Cuadro del parpadeo del ojo solar en el instante `t` (segundos de presentación): parpadea y mira, y descansa
## EYE_IDLE_PAUSE segundos con el dibujo de siempre (cuadro 0).
static func eye_idle_frame(t: float) -> int:
	var blink := EYE_IDLE_FRAMES * EYE_IDLE_SECONDS
	var at := fmod(maxf(t, 0.0), blink + EYE_IDLE_PAUSE)
	return int(at / EYE_IDLE_SECONDS) if at < blink else 0

## Cuadro del reposo de la figura de luz en el instante `t`: un bucle continuo.
static func figure_idle_frame(t: float) -> int:
	return int(fmod(maxf(t, 0.0), FIGURE_IDLE_FRAMES * FIGURE_IDLE_SECONDS) / FIGURE_IDLE_SECONDS)

## Cuánto sube y baja el guardián `g` (en pantalla, pasos de 2 px): la figura de luz flota más alto y más despacio.
static func guardian_bob(g: int, t: float) -> float:
	if g == 1: return 2.0 * roundf(sin(t * 0.8) * 3.0)
	return 2.0 * roundf(sin(t * 1.1) * 1.5)

func _draw() -> void:
	# La tienda (08/11/2026) se arma sobre esta misma mesa: sin vendedor ni maletín, con la sala y sus animaciones.
	draw_texture_rect(CLEAN_TABLE, Rect2(0, 0, 1440, 900), false)
	# Pixel-v3 club room (walls, lamps, pictures, chairs); windows are drawn over it.
	draw_texture_rect(SALON_V3, Rect2(0, 0, 1440, 300), false)
	var panels := {"dia": 0, "tarde": 1, "noche": 2, "espacio": 3, "agujero_negro": 4, "cielo": 5}
	var cell := Vector2(EXTERIORS.get_size()) / Vector2(2, 3)
	var index: int = panels.get(environment_id, 0)
	var origin := Vector2(index % 2, int(index / 2.0)) * cell
	# All apertures look onto the same panorama; stars/clouds do not repeat.
	var panorama := Rect2(470, 0, 801, 220)
	for window in WINDOWS:
		if environment_id == "cierre":
			draw_rect(window, Color("261b19"))
			for y in range(int(window.position.y), int(window.end.y), 25):
				draw_rect(Rect2(window.position.x, y, window.size.x, minf(22, window.end.y - y)), Color("654936"))
		else:
			# Pixel-v3 panels are 401×110 logical px: every logical pixel lands on a 2×2 block of the window.
			var source := Rect2(origin + (window.position - panorama.position) / 2.0, window.size / 2.0)
			# Con el fondo animado el panel vive en su propia textura (402×111, origen en 0,0); si no, se recorta de la hoja.
			if fx_key != "": draw_texture_rect_region(window_fx.get_texture(), window, Rect2((window.position - panorama.position) / 2.0, window.size / 2.0))
			else: draw_texture_rect_region(EXTERIORS, window, source)
	# Wooden mullions over the glass (not over the boarded-up "cierre" windows); hand and cloud stay in front.
	if environment_id != "cierre": draw_texture_rect(MULLIONS_V3, Rect2(0, 0, 1440, 300), false)
	props.draw_flag(self)
	props.draw_soda(self, "soda_left")
	props.draw_soda(self, "soda_right")
	# Pixel-v3 table (wood, felt, front, floor) over the old plate; the room above it stays.
	draw_texture_rect(TABLE_V3, Rect2(0, 272, 1440, 628), false)
	# Thermos with its stickers, then the mate and the dice cup in front of it.
	# Mientras ceba el mate se dibuja aparte: debajo del mate al subir y bajar, y por delante mientras cruza y vierte.
	var pour_frame := props.frame("thermos")
	var pour: Dictionary = BarProps.thermos_pose(pour_frame) if pour_frame >= 0 else {}
	if pour_frame >= 0 and not pour.over: BarProps.draw_thermos(self, pour.center, pour.rotation, stickers)
	var lift := smoothstep(0.0, 1.0, thermos_t)
	var thermos_bob := 2.0 * roundf(sin(elapsed * 1.3) * 1.5) if motion and thermos_t >= 1.0 else 0.0
	var sway := 2.0 * roundf(sin(thermos_t * TAU * 2.0) * 3.0) if motion and thermos_t > 0.0 and thermos_t < 1.0 else 0.0
	if pour_frame < 0:
		var thermos_origin := THERMOS_ORIGIN.lerp(STOLEN_THERMOS_POS, lift) + Vector2(sway, thermos_bob)
		draw_set_transform(thermos_origin, 0.0, Vector2.ONE * lerpf(1.0, STOLEN_THERMOS_SCALE, lift))
		draw_texture_rect(THERMOS_TABLE_V3, Rect2(Vector2.ZERO, Vector2(144, 350)), false)
		# Every sticker sits on its own fixed spot of the thermos (same layout as the shop).
		for id in StickerDefinitions.NAMES:
			if stickers.has(id): StickerArt.draw_on_thermos(self, Vector2.ZERO, id, 86.0, 46.0, int(stickers[id]))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(MATE_V3, Rect2(1088, 310, 136, 236), false)
	if not cup_hidden: draw_texture_rect(CUP_V3, Rect2(1280, 426, 144, 188), false)
	# En la tienda no hay rival: ni nube ni mano en la ventana.
	if shop_mode: return
	# God remains a provisional silhouette; ordinary hands retain existing art.
	var center := Vector2(667, 105 + (sin(elapsed * 1.1) * 3 if motion else 0))
	if actor == "god" and guardian >= 0:
		# Pixel-v3: 124×100 logical px on 2×2 blocks, centered where the triangle was; the bob moves in 2 px steps.
		var god_bob := guardian_bob(guardian, elapsed) if motion else 0.0
		var clic := props.frame("guardian")
		var at := Rect2(center.x - 124, 5 + god_bob, 248, 200)
		# Reposo animado: el ojo parpadea cada tanto y la figura respira; el dado cósmico queda quieto.
		var idle_sheet: Texture2D = null
		var idle := 0
		if motion and guardian == 0: idle_sheet = EYE_IDLE; idle = eye_idle_frame(elapsed)
		elif motion and guardian == 1: idle_sheet = FIGURE_IDLE; idle = figure_idle_frame(elapsed)
		if clic > 0: draw_texture_rect_region(GUARDIAN_CLIC, at, Rect2(Vector2(clic, guardian) * GUARDIAN_SIZE, GUARDIAN_SIZE))
		elif idle > 0: draw_texture_rect_region(idle_sheet, at, Rect2(Vector2(idle, 0) * GUARDIAN_SIZE, GUARDIAN_SIZE))
		else: draw_texture_rect(GUARDIAN_ART[guardian], at, false)
		return
	if actor == "god":
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -35), center + Vector2(-53, 29), center + Vector2(53, 29)]), Color("eac16c"))
		draw_circle(center + Vector2(0, 7), 18, Color("f6eed4"))
		draw_circle(center + Vector2(0, 7), 9, Color("302532"))
		return
	# Pixel-v3 cloud and hand: logical pixels land on 2x2 blocks, so the bob moves in 2 px steps and the
	# fingers drum through an 8-frame cycle (frame 0 when motion is reduced or off).
	var bob := 2.0 * roundf(sin(elapsed * 1.1) * 1.5) if motion else 0.0
	var frame := int(elapsed / HAND_FRAME_SECONDS) % HAND_FRAMES if motion else 0
	if hand_boss != "":
		var clip_frame := props.hand_clip_frame(hand_boss)
		var clip_dy := 0.0 if clip_frame > 0 else bob
		props.draw_hand_clip(self, hand_boss, true, clip_frame, clip_dy)
		draw_texture_rect(CLOUD_V3, Rect2(552, 0, 262, 40), false)
		props.draw_hand_clip(self, hand_boss, false, clip_frame, clip_dy)
		return
	draw_texture_rect(CLOUD_V3, Rect2(552, 0, 262, 40), false)
	if props.busy("hand"): props.draw_hand_gesture(self, hand_row)
	elif hand_row >= 0: draw_texture_rect_region(BOSS_HANDS, Rect2(624, 34 + bob, 122, 106), Rect2(frame * HAND_SIZE.x, hand_row * HAND_SIZE.y, HAND_SIZE.x, HAND_SIZE.y))
	else: draw_texture_rect_region(HAND_V3, Rect2(624, 34 + bob, 122, 106), Rect2(frame * 61, 0, 61, 53))

