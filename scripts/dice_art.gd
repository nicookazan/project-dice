extends RefCounted
## Generated faces are display data only. No gameplay RNG or dice mutation.
const SHEETS = {
	"": preload("res://assets/art/dice-faces-v1/negro-v1.png"),
	"ruby": preload("res://assets/art/dice-faces-v1/ruby-v1.png"),
	"sapphire": preload("res://assets/art/dice-faces-v1/sapphire-v1.png"),
	"emerald": preload("res://assets/art/dice-faces-v1/emerald-v1.png"),
	"diamond": preload("res://assets/art/dice-faces-v1/diamond-v1.png")}
const BLANK = preload("res://assets/art/dice-faces-v1/sin-tirar-v1.png")
# Trim the padding in source coordinates so every result has the same footprint.
const REGIONS = [Rect2(80, 56, 416, 424), Rect2(560, 56, 416, 424), Rect2(1040, 56, 416, 424), Rect2(80, 536, 416, 424), Rect2(560, 536, 416, 424), Rect2(1040, 536, 416, 424)]
const BLANK_REGION = Rect2(352, 88, 832, 848)
const DISPLAY = Rect2(3, 2, 56, 57)
static var cache: Dictionary = {}
static var pip_bounds_cache: Dictionary = {}

# Read the original pip silhouettes once; faceting follows the actual image,
# including the different positions of 1/2/3 and six distinct pips.
static func pip_bounds(material: String, value: int) -> Array:
	if not SHEETS.has(material) or value not in range(1, 7): return []
	var key := material + str(value)
	if pip_bounds_cache.has(key): return pip_bounds_cache[key]
	var image: Image = SHEETS[material].get_image().get_region(Rect2i(REGIONS[value - 1]))
	var width := int(image.get_width() / 2)
	var height := int(image.get_height() / 2)
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in range(int(height * 0.23), int(height * 0.86)):
		for x in range(int(width * 0.12), int(width * 0.88)):
			var color := image.get_pixel(x * 2, y * 2)
			if color.a > 0.75 and maxf(color.r, maxf(color.g, color.b)) < 0.5: mask[y * width + x] = 1
	var bounds: Array = []
	for index in range(mask.size()):
		if mask[index] == 0: continue
		mask[index] = 0
		var queue: Array[int] = [index]
		var cursor := 0
		var low := Vector2(index % width, int(index / width))
		var high := low
		while cursor < queue.size():
			var current: int = queue[cursor]
			cursor += 1
			var point := Vector2(current % width, int(current / width))
			low = low.min(point)
			high = high.max(point)
			for next in [current - width, current + width, current - 1, current + 1]:
				if next >= 0 and next < mask.size() and mask[next] == 1:
					mask[next] = 0
					queue.append(next)
		if queue.size() > 10:
			var factor := DISPLAY.size / Vector2(image.get_size()) * 2
			bounds.append(Rect2(DISPLAY.position + low * factor, (high - low + Vector2.ONE) * factor))
	pip_bounds_cache[key] = bounds
	return bounds

static func face(material: String, value: int) -> AtlasTexture:
	var key := material + ":" + str(value)
	if cache.has(key): return cache[key]
	var result := AtlasTexture.new()
	result.atlas = SHEETS.get(material, SHEETS[""]) if value in range(1, 7) else BLANK
	result.region = REGIONS[value - 1] if value in range(1, 7) else BLANK_REGION
	result.filter_clip = true
	cache[key] = result
	return result

static func pip_centers(value: int) -> Array:
	var grid := {1: [Vector2(0.5, 0.55)], 2: [Vector2(0.26, 0.35), Vector2(0.73, 0.75)], 3: [Vector2(0.26, 0.35), Vector2(0.5, 0.55), Vector2(0.73, 0.75)], 4: [Vector2(0.26, 0.35), Vector2(0.73, 0.35), Vector2(0.26, 0.75), Vector2(0.73, 0.75)], 5: [Vector2(0.26, 0.35), Vector2(0.73, 0.35), Vector2(0.5, 0.55), Vector2(0.26, 0.75), Vector2(0.73, 0.75)], 6: [Vector2(0.26, 0.35), Vector2(0.73, 0.35), Vector2(0.26, 0.55), Vector2(0.73, 0.55), Vector2(0.26, 0.75), Vector2(0.73, 0.75)]}
	var points: Array = []
	for point in grid.get(value, []): points.append(DISPLAY.position + point * DISPLAY.size)
	return points
