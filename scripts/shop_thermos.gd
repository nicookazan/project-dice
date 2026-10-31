extends Control
## The match's silver thermos with the same stickers as the shop (pixel art v3).
## Local space 144×330 px = 72×165 logical pixels at 2×.
const ART = preload("res://assets/art/pixel-v3/termo-v3.png")
const Stickers = preload("res://scripts/stickers.gd")
const StickerArt = preload("res://scripts/sticker_art.gd")
const AXIS := 86.0
const RADIUS := 46.0
var stickers: Dictionary = {}

static func badge_hit_rect(id: String, levels: Dictionary) -> Rect2:
	var rect := badge_rect(id, levels)
	var start := StickerArt.surface_point(rect.position, AXIS, RADIUS)
	var end := StickerArt.surface_point(rect.end, AXIS, RADIUS)
	return Rect2(start, end - start).grow(2)

static func badge_rect(id: String, levels: Dictionary) -> Rect2:
	var index := 0
	for key in Stickers.NAMES:
		if not levels.has(key): continue
		if key == id: break
		index += 1
	return Rect2(46 + (index % 2) * 42, 112 + int(index / 2.0) * 42, 38, 38)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_texture_rect(ART, Rect2(0, 0, 144, 330), false)
	for id in Stickers.NAMES:
		if not stickers.has(id): continue
		StickerArt.draw_sticker(self, badge_rect(id, stickers), id, AXIS, RADIUS)
