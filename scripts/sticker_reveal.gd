extends Control
## Presentation only: the paid transaction is already committed and saved.
const Art = preload("res://scripts/sticker_art.gd")
const Thermos = preload("res://scripts/shop_thermos.gd")
const Stickers = preload("res://scripts/stickers.gd")
var items: Array = []
var before: Dictionary = {}
var after: Dictionary = {}
var thermos: Control
var still := false
var fast := false
var elapsed := 0.0
var finished := false
var badges: Array[Control] = []
var captions: Array[Control] = []
var origins: Array[Vector2] = []
var shade: ColorRect
var pack: Control
var heading: Label

func _ready() -> void:
	name = "StickerReveal"
	size = Vector2(1440, 900)
	z_index = 150
	mouse_filter = Control.MOUSE_FILTER_STOP
	shade = ColorRect.new()
	shade.size = size
	shade.color = Color(0.015, 0.025, 0.04, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	heading = caption("STICKERS CONSEGUIDOS", Rect2(300, 200, 840, 45), 28)
	pack = preload("res://scripts/shop_art.gd").new()
	pack.icon_id = "pack"
	pack.position = Vector2(630, 310)
	pack.size = Vector2(180, 180)
	pack.pivot_offset = pack.size / 2
	add_child(pack)
	for i in range(items.size()):
		var origin := Vector2(720 + (i - (items.size() - 1) / 2.0) * 240 - 72, 330)
		origins.append(origin)
		var badge := Art.new()
		badge.name = "Sticker_" + items[i]
		badge.sticker_id = items[i]
		badge.position = origin
		badge.size = Vector2(144, 144)
		add_child(badge)
		badges.append(badge)
		captions.append(caption("%s\nNivel %d → %d" % [Stickers.NAMES[items[i]], before.get(items[i], 0), after[items[i]]], Rect2(origin.x - 40, 495, 224, 65), 20))
	var skip := Button.new()
	skip.name = "Continue"
	skip.text = "Continuar" if still else "Omitir animación"
	skip.position = Vector2(560, 625)
	skip.size = Vector2(320, 44)
	skip.pressed.connect(finish)
	add_child(skip)
	if is_instance_valid(thermos):
		thermos.stickers = before.duplicate(true)
		thermos.queue_redraw()
	step(0)

func caption(text: String, rect: Rect2, font_size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("fff0c7"))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _process(delta: float) -> void:
	step(delta * (1.6 if fast else 1.0))

func step(delta: float) -> void:
	if finished: return
	elapsed += delta
	if still:
		pack.hide()
		if elapsed >= 2.2: finish()
		return
	pack.visible = elapsed < 0.55
	pack.rotation = sin(elapsed * 32) * 0.10
	pack.scale = Vector2.ONE * (1 + elapsed * 0.25)
	var revealed := elapsed >= 0.55
	var progress := clampf((elapsed - 2.0) / 0.9, 0, 1)
	shade.color.a = 0.86 * (1 - progress)
	heading.modulate.a = 1 - progress
	for i in range(badges.size()):
		var badge := badges[i]
		badge.visible = revealed
		captions[i].visible = revealed and progress == 0
		var flight := clampf((elapsed - 2.0 - i * 0.16) / 0.85, 0, 1)
		var ease := flight * flight * (3 - 2 * flight)
		var destination := origins[i]
		if is_instance_valid(thermos):
			destination = thermos.position + thermos.get_parent().position + Thermos.badge_hit_rect(items[i], after).position + Vector2(2, 2)
		badge.position = origins[i].lerp(destination, ease) + Vector2(0, -90 * sin(PI * flight))
		badge.scale = Vector2.ONE * lerpf(1, 28.0 / 144.0, ease)
		badge.rotation = sin(PI * flight) * (0.2 if i % 2 == 0 else -0.2)
		if flight >= 1 and is_instance_valid(thermos):
			thermos.stickers[items[i]] = after[items[i]]
			thermos.queue_redraw()
			badge.hide()
	if elapsed >= 2.9 + (items.size() - 1) * 0.16: finish()

func finish() -> void:
	if finished: return
	finished = true
	if is_instance_valid(thermos):
		thermos.stickers = after.duplicate(true)
		thermos.queue_redraw()
	hide()
	queue_free()
