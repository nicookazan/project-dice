extends Control
## Visual-only damped spring driven by pointer motion, never gameplay RNG.
var visual: Control
var enabled := true
var angle := 0.0
var velocity := 0.0
var previous_mouse := Vector2.ZERO
var offset := Vector2.ZERO
var linear_velocity := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200 # Carry the object above the shop's translucent sale layer.
	previous_mouse = get_global_mouse_position()
	visual.position = Vector2(-31, -31)
	visual.pivot_offset = Vector2(31, 31)

func _process(delta: float) -> void:
	var mouse := get_global_mouse_position()
	step(delta, mouse - previous_mouse)
	previous_mouse = mouse

func step(delta: float, movement: Vector2) -> void:
	if not enabled:
		angle = 0
		velocity = 0
		offset = Vector2.ZERO
		linear_velocity = Vector2.ZERO
	else:
		var dt := minf(delta, 0.05)
		var target := clampf(movement.x * 0.016 + movement.y * 0.0035, -0.34, 0.34)
		velocity += (target - angle) * 160 * dt
		velocity *= exp(-7.5 * dt)
		angle = clampf(angle + velocity * dt, -0.42, 0.42)
		var target_offset := (-movement * 0.12).limit_length(5)
		linear_velocity += (target_offset - offset) * 120 * dt
		linear_velocity *= exp(-9 * dt)
		offset = (offset + linear_velocity * dt).limit_length(6)
	if is_instance_valid(visual):
		visual.rotation = angle
		visual.position = Vector2(-31, -31) + offset
