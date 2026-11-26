extends "res://scripts/backdrop.gd"
## Solo para los bocetos del ítem 6: el fondo de siempre, sin la mano (queda la nube).

var hide_hand := false

func _draw_actor() -> void:
	if hide_hand:
		draw_texture_rect(CLOUD_V3, Rect2(552, 0, 262, 40), false)
		return
	super()
