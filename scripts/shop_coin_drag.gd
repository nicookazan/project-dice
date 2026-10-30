extends "res://scripts/hover_button.gd"
signal drag_started(data: Dictionary)
signal drag_finished
var coin_id := ""
var instance_id := 0
var sway_enabled := true
var drag_allowed: Callable
var own_drag := false
var block_click := false

func _get_drag_data(_at: Vector2) -> Variant:
	if not drag_allowed.is_valid() or not drag_allowed.call(): return null
	var visual := preload("res://scripts/coin_art.gd").new()
	visual.coin_id = coin_id
	visual.size = Vector2(62, 62)
	var sway := preload("res://scripts/drag_sway.gd").new()
	sway.visual = visual
	sway.enabled = sway_enabled
	sway.add_child(visual)
	set_drag_preview(sway)
	own_drag = true
	block_click = true
	modulate.a = 0.35
	var data := {"shop_coin": coin_id, "instance_id": instance_id}
	drag_started.emit(data)
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and own_drag:
		own_drag = false
		modulate.a = 1
		drag_finished.emit()
		call_deferred("clear_click_block")

func clear_click_block() -> void:
	block_click = false
