extends Control
## One illustration shared by shop offers, pack contents and the thermos.
const DiceArt = preload("res://scripts/dice_art.gd")
const COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}
const FACES = {"pair_loose": [3, 3], "trio": [3, 3, 3], "straight": [1, 2, 3, 4, 5], "full": [3, 3, 3, 2, 2], "poker": [4, 4, 4, 4], "generala": [5, 5, 5, 5, 5]}
var sticker_id := "trio"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func draw_sticker(canvas: CanvasItem, rect: Rect2, id: String) -> void:
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.47
	var outline := PackedVector2Array()
	var inside := PackedVector2Array()
	for i in range(16):
		var direction := Vector2.from_angle(TAU * i / 16.0 - PI / 8)
		outline.append((center + direction * radius).round())
		inside.append((center + direction * (radius - rect.size.x * 0.045)).round())
	canvas.draw_colored_polygon(outline, Color("f6df9e"))
	canvas.draw_colored_polygon(inside, Color(COLORS.get(id, "c77849")))
	canvas.draw_polyline(outline + PackedVector2Array([outline[0]]), Color("69401e"), maxf(1, rect.size.x * 0.025))
	var faces: Array = FACES.get(id, [3, 3, 3])
	var side := rect.size.x * (0.27 if faces.size() > 3 else 0.32)
	for i in range(faces.size()):
		var top_count := 2 if faces.size() > 2 else faces.size()
		var top := i < top_count
		var count := top_count if top else faces.size() - top_count
		var column := i if top else i - top_count
		var offset := Vector2((column - (count - 1) / 2.0) * side * 0.94, 0 if faces.size() == 2 else (-side * 0.48 if top else side * 0.48))
		canvas.draw_texture_rect(DiceArt.face("", faces[i]), Rect2(center + offset - Vector2.ONE * side / 2, Vector2.ONE * side), false)

func _draw() -> void:
	draw_sticker(self, Rect2(Vector2.ZERO, size), sticker_id)
