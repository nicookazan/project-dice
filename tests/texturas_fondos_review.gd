extends SceneTree
## Capturas de TX2: las ventanas de cada ambiente en tres instantes distintos. Requiere GPU (sin --headless).
const Backdrop = preload("res://scripts/backdrop.gd")
const WindowFx = preload("res://scripts/window_fx.gd")
func _initialize() -> void:
	var backdrop = Backdrop.new()
	backdrop.size = Vector2(1440, 900)
	root.add_child(backdrop)
	backdrop.set_process(false)
	var shots := [["dia", false], ["tarde", false], ["noche", false], ["noche", true], ["espacio", false], ["agujero_negro", false], ["cielo", false]]
	for shot in shots:
		var profile := {"environment": shot[0], "actor": "boss_power" if shot[1] else "common", "level": 0, "boss_id": "l3_gotico" if shot[1] else "", "thermos_stolen": false}
		backdrop.configure(profile, {"reduced_motion": false, "speed": 1})
		for seconds in [1.0, 6.5, 14.0]:
			backdrop.elapsed = seconds
			backdrop.window_fx.update_time(seconds)
			backdrop.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image().get_region(Rect2i(440, 0, 880, 230))
			image.save_png("res://test-results/tx2-%s%s-%d.png" % [shot[0], "-gotico" if shot[1] else "", int(seconds)])
	print("TX2 REVIEW OK")
	quit(0)
