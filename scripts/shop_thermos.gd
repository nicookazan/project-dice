extends Control
## Reuses the match's silver thermos artwork with owned placeholder stickers.
const ART = preload("res://assets/art/environment-v2/mesa-libreta-frontal-v1.png")
const Stickers = preload("res://scripts/stickers.gd")
const Tooltip = preload("res://scripts/item_tooltip.gd")
const ORIGIN = Vector2(1180, 160)
const MARKS = {"pair_loose": "P", "trio": "3", "straight": "E", "full": "F", "poker": "4", "generala": "G"}
const COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}
var stickers: Dictionary = {}
var badge_font: Font = Tooltip.pixel_font()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func piece(outline: Array, silver_body := false) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for source: Vector2 in outline:
		points.append(source - ORIGIN)
		# Extend clean brushed metal below the part covered by the playing cup.
		var sample := source
		if silver_body: sample.y = 245 + (source.y - 240) * 0.60
		uv.append(sample / Vector2(1440, 900))
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, ART)

func _draw() -> void:
	# Clip each part to its silhouette, never copying the room or table.
	# Complete the black handle where the match's mate overlaps its source.
	draw_polyline(PackedVector2Array([Vector2(39, 78), Vector2(17, 78), Vector2(10, 84), Vector2(10, 201), Vector2(17, 208), Vector2(39, 208)]), Color("090d14"), 12, false)
	draw_polyline(PackedVector2Array([Vector2(37, 75), Vector2(16, 75), Vector2(6, 83), Vector2(6, 200), Vector2(15, 211), Vector2(36, 211)]), Color("454344"), 3, false)
	piece([Vector2(1218, 240), Vector2(1314, 240), Vector2(1314, 475), Vector2(1309, 481), Vector2(1284, 486), Vector2(1241, 484), Vector2(1218, 477)], true)
	piece([Vector2(1226, 184), Vector2(1267, 179), Vector2(1282, 165), Vector2(1288, 166), Vector2(1274, 185), Vector2(1304, 189), Vector2(1306, 199), Vector2(1305, 219), Vector2(1310, 227), Vector2(1310, 241), Vector2(1218, 241), Vector2(1218, 221), Vector2(1222, 218), Vector2(1220, 199)])
	var index := 0
	for id in Stickers.NAMES:
		if not stickers.has(id): continue
		var x := 49 + (index % 2) * 36
		var y := 151 + int(index / 2.0) * 39
		draw_rect(Rect2(x, y + 1, 30, 30), Color("172129"))
		draw_rect(Rect2(x, y, 28, 28), Color("f1dfb4"))
		draw_rect(Rect2(x + 2, y + 2, 24, 24), Color(COLORS[id]))
		draw_string(badge_font, Vector2(x + 8, y + 20), MARKS[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("172129"))
		draw_string(badge_font, Vector2(x + 17, y + 29), str(stickers[id]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff0c7"))
		index += 1
