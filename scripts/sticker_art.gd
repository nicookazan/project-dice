extends Control
## One illustration shared by shop offers, pack contents and the thermos.
## Pixel art v3: stickers-v3.png (6 × 19×19 logical px). On the thermos each column is
## compressed along the cylinder and shaded in three flat steps, never smooth gradients.
const SHEET = preload("res://assets/art/pixel-v3/stickers-v3.png")
const IDS = ["pair_loose", "trio", "straight", "full", "poker", "generala"]
const CELL := 19
## On the thermos every sticker has its own fixed spot, as if stuck on by hand: once earned it is pasted there and
## never moves when more arrive. Center in thermos space (144 px wide, axis 86) and tilt in degrees counterclockwise;
## the tilt is baked into stickers-termo-v3.png (tools/art/make_stickers_termo.py keeps the same angles).
const THERMOS_SHEET = preload("res://assets/art/pixel-v3/stickers-termo-v3.png")
const THERMOS_CELL := 25
const THERMOS_SPOTS = {
	"pair_loose": [Vector2(70, 122), -8.0], "trio": [Vector2(108, 134), 15.0], "straight": [Vector2(62, 168), 4.0],
	"full": [Vector2(102, 184), -14.0], "poker": [Vector2(74, 214), 18.0], "generala": [Vector2(108, 232), -5.0]}
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

## The sticker's untilted 38×38 footprint on the thermos (thermos space), used for hit areas and the paste flight.
static func thermos_rect(id: String) -> Rect2:
	var spot: Array = THERMOS_SPOTS.get(id, THERMOS_SPOTS.trio)
	return Rect2(spot[0] - Vector2(19, 19), Vector2(38, 38))

## Tilt in radians for a Control (clockwise positive), matching the baked art.
static func thermos_tilt(id: String) -> float:
	var spot: Array = THERMOS_SPOTS.get(id, THERMOS_SPOTS.trio)
	return deg_to_rad(-spot[1])

## Draws the tilted sticker at its fixed spot on a thermos whose top-left is `origin`, compressing columns along the
## cylinder like draw_sticker. Snapping is relative to the thermos so every logical pixel lands on its 2×2 grid.
static func draw_on_thermos(canvas: CanvasItem, origin: Vector2, id: String, axis := 86.0, radius := 46.0) -> void:
	var index: int = IDS.find(id)
	if index < 0: index = 1
	var spot: Array = THERMOS_SPOTS.get(id, THERMOS_SPOTS.trio)
	var side := THERMOS_CELL * 2.0
	var top := _snap(spot[0].y - side / 2.0)
	var left0: float = spot[0].x - side / 2.0
	for column in range(THERMOS_CELL):
		var left := left0 + column * 2.0
		var x0 := _snap(surface_point(Vector2(left, 0), axis, radius).x)
		var x1 := _snap(surface_point(Vector2(left + 2.0, 0), axis, radius).x)
		if x1 <= x0: continue
		var angle := absf(((left + 1.0) - axis) / radius)
		var shade := 1.0
		if angle > 0.95: shade = 0.62
		elif angle > 0.65: shade = 0.8
		canvas.draw_texture_rect_region(THERMOS_SHEET, Rect2(origin + Vector2(x0, top), Vector2(x1 - x0, side)), Rect2(index * THERMOS_CELL + column, 0, 1, THERMOS_CELL), Color(shade, shade, shade))

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
