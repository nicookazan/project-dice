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
const THERMOS_TABLE_V3 = preload("res://assets/art/pixel-v3/termo-mesa-v3.png")
const MATE_V3 = preload("res://assets/art/pixel-v3/mate-v3.png")
const CUP_V3 = preload("res://assets/art/pixel-v3/vaso-v3.png")
const StickerArt = preload("res://scripts/sticker_art.gd")
const StickerDefinitions = preload("res://scripts/stickers.gd")
var stickers: Dictionary = {}
const THERMOS_ORIGIN = Vector2(1203, 168)
const THERMOS_RECT = Rect2(1203, 170, 144, 225)
const SHOP_THERMOS_RECT = Rect2(65, 525, 145, 330)
const CUP_RECT = Rect2(1260, 400, 145, 180)
const CUP_MOUTH = Vector2(1330, 425)
var shop_mode := false
# Texture polygons reuse the recovered plate's actual pixels, without repainting
# the approved hand/cloud or carrying a rectangular piece of its old sky.
const CLOUD_OUTLINE = [Vector2(658, 0), Vector2(946, 0), Vector2(942, 13), Vector2(929, 24), Vector2(908, 29), Vector2(895, 27), Vector2(882, 36), Vector2(860, 38), Vector2(844, 30), Vector2(826, 34), Vector2(815, 25), Vector2(801, 29), Vector2(788, 35), Vector2(773, 37), Vector2(754, 44), Vector2(733, 43), Vector2(714, 34), Vector2(697, 30), Vector2(679, 28), Vector2(665, 20)]
const HAND_OUTLINE = [Vector2(788, 25), Vector2(810, 24), Vector2(828, 38), Vector2(834, 53), Vector2(849, 65), Vector2(860, 79), Vector2(870, 94), Vector2(871, 101), Vector2(863, 104), Vector2(853, 102), Vector2(842, 90), Vector2(841, 82), Vector2(832, 78), Vector2(817, 83), Vector2(815, 92), Vector2(810, 98), Vector2(800, 98), Vector2(794, 92), Vector2(793, 107), Vector2(796, 124), Vector2(792, 131), Vector2(779, 132), Vector2(776, 125), Vector2(774, 116), Vector2(773, 121), Vector2(764, 122), Vector2(759, 116), Vector2(756, 107), Vector2(753, 112), Vector2(746, 112), Vector2(741, 106), Vector2(737, 98), Vector2(736, 85), Vector2(740, 78), Vector2(745, 70), Vector2(755, 59), Vector2(763, 53), Vector2(770, 46), Vector2(782, 40)]
const WINDOWS = [Rect2(470, 0, 47, 217), Rect2(534, 0, 378, 219), Rect2(952, 0, 92, 215), Rect2(1198, 43, 73, 177)]
var environment_id := "dia"
var actor := "common"
var level := 0
var motion := true
var speed := 1
var elapsed := 0.0

func configure(profile: Dictionary, preferences: Dictionary) -> void:
	environment_id = profile.environment
	actor = profile.actor
	level = profile.level
	motion = not preferences.reduced_motion and preferences.speed != 0
	speed = preferences.speed
	queue_redraw()

func _process(delta: float) -> void:
	if motion:
		elapsed += delta * speed
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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
	draw_texture_rect(THERMOS_TABLE_V3, Rect2(THERMOS_ORIGIN, Vector2(144, 350)), false)
	var occupied := 0
	for id in StickerDefinitions.NAMES:
		if not stickers.has(id): continue
		var target := Rect2(THERMOS_ORIGIN + Vector2(46 + (occupied % 2) * 42, 112 + int(occupied / 2.0) * 42), Vector2(38, 38))
		StickerArt.draw_sticker(self, target, id, THERMOS_ORIGIN.x + 86.0, 46)
		occupied += 1
	draw_texture_rect(MATE_V3, Rect2(1088, 310, 136, 236), false)
	draw_texture_rect(CUP_V3, Rect2(1280, 426, 144, 188), false)
	# God remains a provisional silhouette; ordinary hands retain existing art.
	var center := Vector2(667, 105 + (sin(elapsed * 1.1) * 3 if motion else 0))
	if actor == "god":
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -35), center + Vector2(-53, 29), center + Vector2(53, 29)]), Color("eac16c"))
		draw_circle(center + Vector2(0, 7), 18, Color("f6eed4"))
		draw_circle(center + Vector2(0, 7), 9, Color("302532"))
		return
	var offset := Vector2(-45, 12 + (sin(elapsed * 1.1) * 3 if motion else 0))
	draw_recovered_figure(CLOUD_OUTLINE, Vector2(-45, 0))
	draw_recovered_figure(HAND_OUTLINE, offset)

