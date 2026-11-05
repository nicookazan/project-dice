extends Control
const ART = preload("res://assets/art/club-table-v2.png")
const SHOP_ART = preload("res://assets/art/shop-table-v1.png")
const SELLER_ART = preload("res://assets/art/pixel-v3/tienda-v3.png")
const EXTERIORS = preload("res://assets/art/pixel-v3/exteriores-v3.png")
const TABLE_PROPS = preload("res://assets/art/environment-v2/mesa-proporciones-v3.png")
const CLEAN_TABLE = preload("res://assets/art/environment-v2/mesa-libreta-frontal-v1.png")
const CUP_TABLE_ART = preload("res://assets/art/environment-v2/vaso-cuero-negro-mesa-v2.png")
const CUP_SHOP_ART = preload("res://assets/art/environment-v2/vaso-cuero-negro-tienda-v1.png")
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
const GUARDIAN_ART := [preload("res://assets/art/pixel-v3/guardianes/guardian-ojo-v3.png"), preload("res://assets/art/pixel-v3/guardianes/guardian-figura-v3.png"), preload("res://assets/art/pixel-v3/guardianes/guardian-dado-v3.png")]
const HAND_FRAMES := 8
const HAND_SIZE := Vector2i(61, 53)
const HAND_FRAME_SECONDS := 0.11
const StickerArt = preload("res://scripts/sticker_art.gd")
const StickerDefinitions = preload("res://scripts/stickers.gd")
const BarProps = preload("res://scripts/bar_props.gd")
## Sifones, bandera y termo que reaccionan al clic (animaciones de presentación).
var props := BarProps.new()
var pour_layer: Control
var stickers: Dictionary = {}
const THERMOS_ORIGIN = Vector2(1203, 168)
const THERMOS_RECT = Rect2(1203, 170, 144, 225)
const SHOP_THERMOS_RECT = Rect2(65, 525, 145, 330)
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
	hand_row = BossCatalog.hand_row(profile.get("boss_id", "")) if actor != "common" and actor != "god" else -1
	level = profile.level
	motion = not preferences.reduced_motion and preferences.speed != 0
	speed = preferences.speed
	props.motion = motion
	props.speed = speed
	# Las animaciones solo existen sobre la mesa y con movimiento: cualquier otro cambio las corta.
	if shop_mode or not motion: props.stop_all()
	queue_redraw()
	if is_instance_valid(pour_layer): pour_layer.queue_redraw()

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
	if f < 0 or shop_mode: return
	props.draw_pour_effects(pour_layer, f)
	var pose := BarProps.thermos_pose(f)
	if pose.over: BarProps.draw_thermos(pour_layer, pose.center, pose.rotation, stickers)

func draw_recovered_figure(outline: Array, offset: Vector2, texture: Texture2D = ART) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	for source_point in outline:
		uv.append(source_point / texture_size)
		points.append(source_point * Vector2(1440, 900) / texture_size + offset)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, texture)

func _draw() -> void:
	if shop_mode:
		# The salesman and his case replace the entire playing table and props.
		draw_texture_rect(SELLER_ART, Rect2(0, 0, 1440, 900), false)
		return
	draw_texture_rect(ART if shop_mode else CLEAN_TABLE, Rect2(0, 0, 1440, 900), false)
	if shop_mode:
		# Reuse the original club/hand above the table; only the shop table changes.
		var source_size := Vector2(SHOP_ART.get_width(), SHOP_ART.get_height())
		draw_texture_rect_region(SHOP_ART, Rect2(0, 278, 1440, 622), Rect2(Vector2(0, 278) * source_size / Vector2(1440, 900), Vector2(1440, 622) * source_size / Vector2(1440, 900)))
	# Consume only the edited cup areas; preserve the existing room and props.
	var cup_art: Texture2D = CUP_SHOP_ART if shop_mode else CUP_TABLE_ART
	var cup_patch := Rect2(50, 640, 280, 235) if shop_mode else Rect2(1100, 330, 320, 260)
	var cup_scale := Vector2(cup_art.get_size()) / Vector2(1440, 900)
	if shop_mode: draw_texture_rect_region(cup_art, cup_patch, Rect2(cup_patch.position * cup_scale, cup_patch.size * cup_scale))
	# Pixel-v3 club room (walls, lamps, pictures, chairs); windows are drawn over it.
	else: draw_texture_rect(SALON_V3, Rect2(0, 0, 1440, 300), false)
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
			draw_texture_rect_region(EXTERIORS, window, source)
	# Wooden mullions over the glass (not over the boarded-up "cierre" windows); hand and cloud stay in front.
	if not shop_mode and environment_id != "cierre": draw_texture_rect(MULLIONS_V3, Rect2(0, 0, 1440, 300), false)
	if not shop_mode:
		props.draw_flag(self)
		props.draw_soda(self, "soda_left")
		props.draw_soda(self, "soda_right")
	# Pixel-v3 table (wood, felt, front, floor) over the old plate; the room above it stays.
	if not shop_mode: draw_texture_rect(TABLE_V3, Rect2(0, 272, 1440, 628), false)
	# Only replace the prop strip: all dice areas, the hand and the original
	# room remain sourced from the existing plates. Keep the shop cup below it.
	var props_points := PackedVector2Array([Vector2(0, 137), Vector2(360, 137), Vector2(360, 520), Vector2(322, 715), Vector2(0, 715)]) if shop_mode else PackedVector2Array([Vector2(0, 137), Vector2(360, 137), Vector2(360, 680), Vector2(0, 680)])
	var props_uv := PackedVector2Array()
	for point in props_points: props_uv.append(point / Vector2(1440, 900))
	if shop_mode: draw_polygon(props_points, PackedColorArray([Color.WHITE]), props_uv, TABLE_PROPS)
	if shop_mode:
		# Restore the shop's leather cup without its former oversized notebook.
		draw_recovered_figure([Vector2(184, 719), Vector2(218, 726), Vector2(254, 734), Vector2(286, 748), Vector2(310, 767), Vector2(331, 792), Vector2(347, 825), Vector2(349, 868), Vector2(337, 903), Vector2(312, 932), Vector2(278, 950), Vector2(240, 950), Vector2(205, 940), Vector2(169, 928), Vector2(130, 915), Vector2(103, 901), Vector2(83, 875), Vector2(79, 844), Vector2(84, 809), Vector2(95, 779), Vector2(112, 754), Vector2(133, 738), Vector2(154, 726)], Vector2.ZERO, CUP_SHOP_ART)
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
			if stickers.has(id): StickerArt.draw_on_thermos(self, Vector2.ZERO, id)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(MATE_V3, Rect2(1088, 310, 136, 236), false)
	draw_texture_rect(CUP_V3, Rect2(1280, 426, 144, 188), false)
	# God remains a provisional silhouette; ordinary hands retain existing art.
	var center := Vector2(667, 105 + (sin(elapsed * 1.1) * 3 if motion else 0))
	if actor == "god" and guardian >= 0:
		# Pixel-v3: 124×100 logical px on 2×2 blocks, centered where the triangle was; the bob moves in 2 px steps.
		var god_bob := 2.0 * roundf(sin(elapsed * 1.1) * 1.5) if motion else 0.0
		draw_texture_rect(GUARDIAN_ART[guardian], Rect2(center.x - 124, 5 + god_bob, 248, 200), false)
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
	draw_texture_rect(CLOUD_V3, Rect2(552, 0, 262, 40), false)
	if hand_row >= 0: draw_texture_rect_region(BOSS_HANDS, Rect2(624, 34 + bob, 122, 106), Rect2(frame * HAND_SIZE.x, hand_row * HAND_SIZE.y, HAND_SIZE.x, HAND_SIZE.y))
	else: draw_texture_rect_region(HAND_V3, Rect2(624, 34 + bob, 122, 106), Rect2(frame * 61, 0, 61, 53))

