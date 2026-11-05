extends Control
## Un dado cae por la boca del vaso y desaparece detrás de su pared delantera. Solo presentación:
## se crea después de que la partida ya movió el dado y se libera sola.

const Die = preload("res://scripts/die.gd")
const FRONT = preload("res://assets/art/pixel-v3/vaso-frente-v3.png")
const FRONT_POS := Vector2(1280, 426)
const MOUTH := Vector2(1330, 432)

func _init() -> void:
	name = "CupEntry"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40

## `die_state` y `context` son los mismos que usa la mesa para dibujar el dado.
func play(die_state, context, from: Vector2, seconds: float) -> void:
	var die := Die.new()
	die.configure_appearance(die_state, context)
	die.locked = true
	die.focus_mode = Control.FOCUS_NONE
	die.size = Vector2(62, 62)
	die.pivot_offset = die.size / 2.0
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	die.position = from - die.size / 2.0
	add_child(die)
	var wall := TextureRect.new()
	wall.texture = FRONT
	wall.position = FRONT_POS
	wall.size = Vector2(FRONT.get_size()) * 2.0
	wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	var mouth := MOUTH - die.size / 2.0
	var tween := create_tween()
	tween.tween_property(die, "position", mouth, seconds * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(die, "scale", Vector2.ONE * 0.62, seconds * 0.45)
	tween.tween_property(die, "position:y", mouth.y + 70.0, seconds * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
