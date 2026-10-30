extends SceneTree
const Die = preload("res://scripts/die.gd")

func _initialize() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.campaign_mode = false
	root.add_child(scene)
	await process_frame
	scene.game.restart(42)
	scene.game.roll()
	for i in range(5): scene.game.dice[i].value = [1, 2, 3, 4, 5][i]
	scene.selected = [2]
	scene.render()
	await capture("dados-en-mesa")
	# A separate enlarged review gallery shows all six result faces.
	var plate := ColorRect.new()
	plate.color = Color("2c101c")
	plate.position = Vector2(45, 340)
	plate.size = Vector2(1350, 310)
	scene.add_child(plate)
	for value in range(1, 7):
		var die := Die.new()
		die.value = value
		die.locked = true
		die.size = Vector2(62, 62)
		die.scale = Vector2(2.8, 2.8)
		die.position = Vector2(40 + (value - 1) * 215, 40)
		die.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		plate.add_child(die)
		var caption := Label.new()
		caption.text = str(value)
		caption.position = Vector2(110 + (value - 1) * 215, 239)
		caption.add_theme_font_size_override("font_size", 24)
		plate.add_child(caption)
	await capture("dados-seis-caras")
	quit()

func capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	root.get_texture().get_image().save_png("res://test-results/" + filename + ".png")
