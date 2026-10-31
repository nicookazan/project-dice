extends Control
## One illustration shared by shop offers, pack contents and the thermos.
## Pixel art v3: stickers-v3.png (6 × 19×19 logical px). On the thermos each column is
## compressed along the cylinder and shaded in three flat steps, never smooth gradients.
const SHEET = preload("res://assets/art/pixel-v3/stickers-v3.png")
const IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
const CELL := 19
var sticker_id := "trio"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func surface_point(point: Vector2, axis: float, radius: float) -> Vector2:
	if radius <= 0: return point
	var angle := (point.x - axis) / radius
	return Vector2(axis + sin(angle) * radius, point.y)

static func _snap(value: float) -> float:
	return roundf(value / 2.0) * 2.0

static func draw_sticker(canvas: CanvasItem, rect: Rect2, id: String, axis := 0.0, cylinder_radius := 0.0) -> void:
	var index: int = IDS.find(id)
	if index < 0: index = 1
	if cylinder_radius <= 0:
		canvas.draw_texture_rect_region(SHEET, rect, Rect2(index * CELL, 0, CELL, CELL))
		return
	var column_width := rect.size.x / CELL
	for column in range(CELL):
		var left := rect.position.x + column * column_width
		var x0 := _snap(surface_point(Vector2(left, 0), axis, cylinder_radius).x)
		var x1 := _snap(surface_point(Vector2(left + column_width, 0), axis, cylinder_radius).x)
		if x1 <= x0: continue
		var angle := absf(((left + column_width / 2.0) - axis) / cylinder_radius)
		var shade := 1.0
		if angle > 0.95: shade = 0.62
		elif angle > 0.65: shade = 0.8
		canvas.draw_texture_rect_region(SHEET, Rect2(x0, rect.position.y, x1 - x0, rect.size.y), Rect2(index * CELL + column, 0, 1, CELL), Color(shade, shade, shade))

func _draw() -> void:
	draw_sticker(self, Rect2(Vector2.ZERO, size), sticker_id)
