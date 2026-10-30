extends Control
## One illustration shared by shop offers, pack contents and the thermos.
const DiceArt = preload("res://scripts/dice_art.gd")
const COLORS = {"pair_loose": "c7a25b", "trio": "c77849", "straight": "70a5c0", "full": "6da77e", "poker": "b578ac", "generala": "e0b445"}
const FACES = {"pair_loose": [3, 3], "trio": [3, 3, 3], "straight": [1, 2, 3, 4, 5], "full": [3, 3, 3, 2, 2], "poker": [4, 4, 4, 4], "generala": [5, 5, 5, 5, 5]}
var sticker_id := "trio"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func surface_point(point: Vector2, axis: float, radius: float) -> Vector2:
	if radius <= 0: return point
	var angle := (point.x - axis) / radius
	return Vector2(axis + sin(angle) * radius, point.y + (1 - cos(angle)) * 4)

static func surface_color(color: Color, x: float, axis: float, radius: float) -> Color:
	if radius <= 0: return color
	var angle := (x - axis) / radius
	# Ink follows the cylinder's light: subdued paper, darker toward its edges.
	var light := 0.68 + 0.25 * cos(angle) - 0.08 * sin(angle)
	return Color(color.r * light, color.g * light, color.b * light, color.a)

static func surface_polygon(canvas: CanvasItem, points: PackedVector2Array, color: Color, axis: float, radius: float) -> void:
	var projected := PackedVector2Array()
	var colors := PackedColorArray()
	for point in points:
		projected.append(surface_point(point, axis, radius))
		colors.append(surface_color(color, point.x, axis, radius))
	canvas.draw_polygon(projected, colors)

static func surface_face(canvas: CanvasItem, rect: Rect2, value: int, axis: float, radius: float) -> void:
	var atlas := DiceArt.face("", value)
	var texture: Texture2D = atlas.atlas
	# Narrow strips curve the illustration and its pips together, with no shadow
	# behind the paper. Sampling the atlas directly keeps every UV on its face.
	for i in range(6):
		var u0 := i / 6.0
		var u1 := (i + 1) / 6.0
		var corners := [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1)]
		var points := PackedVector2Array()
		var uv := PackedVector2Array()
		var colors := PackedColorArray()
		for corner in corners:
			var point: Vector2 = rect.position + corner * rect.size
			points.append(surface_point(point, axis, radius))
			uv.append((atlas.region.position + corner * atlas.region.size) / Vector2(texture.get_size()))
			colors.append(surface_color(Color.WHITE, point.x, axis, radius))
		canvas.draw_polygon(points, colors, uv, texture)

static func draw_sticker(canvas: CanvasItem, rect: Rect2, id: String, axis := 0.0, cylinder_radius := 0.0) -> void:
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.47
	var outline := PackedVector2Array()
	var inside := PackedVector2Array()
	for i in range(16):
		var direction := Vector2.from_angle(TAU * i / 16.0 - PI / 8)
		outline.append((center + direction * radius).round())
		inside.append((center + direction * (radius - rect.size.x * 0.045)).round())
	surface_polygon(canvas, outline, Color("f6df9e"), axis, cylinder_radius)
	surface_polygon(canvas, inside, Color(COLORS.get(id, "c77849")), axis, cylinder_radius)
	var rim := PackedVector2Array()
	for point in outline: rim.append(surface_point(point, axis, cylinder_radius))
	canvas.draw_polyline(rim + PackedVector2Array([rim[0]]), Color("69401e"), maxf(1, rect.size.x * 0.018))
	var faces: Array = FACES.get(id, [3, 3, 3])
	var side := rect.size.x * (0.27 if faces.size() > 3 else 0.32)
	for i in range(faces.size()):
		var top_count := 2 if faces.size() > 2 else faces.size()
		var top := i < top_count
		var count := top_count if top else faces.size() - top_count
		var column := i if top else i - top_count
		var offset := Vector2((column - (count - 1) / 2.0) * side * 0.94, 0 if faces.size() == 2 else (-side * 0.48 if top else side * 0.48))
		var face_rect := Rect2(center + offset - Vector2.ONE * side / 2, Vector2.ONE * side)
		if cylinder_radius > 0: surface_face(canvas, face_rect, faces[i], axis, cylinder_radius)
		else: canvas.draw_texture_rect(DiceArt.face("", faces[i]), face_rect, false)

func _draw() -> void:
	draw_sticker(self, Rect2(Vector2.ZERO, size), sticker_id)
