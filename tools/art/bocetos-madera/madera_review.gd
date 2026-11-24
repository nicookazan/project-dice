extends SceneTree
## Bocetos de la madera: cuatro diseños con las seis caras, junto a hierro, cobre y oro. Requiere GPU (sin --headless).
const Die = preload("res://scripts/die.gd")
const SKETCH = preload("res://tools/art/bocetos-madera/die_body_madera.gdshader")
func _initialize() -> void:
	var holder := Control.new()
	holder.size = Vector2(1250, 800)
	root.add_child(holder)
	var back := ColorRect.new()
	back.color = Color("244638")
	back.size = holder.size
	holder.add_child(back)
	var rows := [["steel", 0], ["copper", 0], ["gold", 0], ["steel", 1], ["steel", 2], ["steel", 3], ["steel", 4]]
	var dice: Array = []
	for r in rows.size():
		for value in range(1, 7):
			var die := Die.new()
			die.value = value
			die.body_material = rows[r][0]
			die.disabled = true
			die.mouse_filter = Control.MOUSE_FILTER_IGNORE
			die.position = Vector2(150 + (value - 1) * 175, 6 + r * 112)
			die.scale = Vector2(1.5, 1.5)
			die.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
			holder.add_child(die)
			dice.append([die, rows[r][1]])
	for r in rows.size():
		var name := Label.new()
		name.text = ["Hierro", "Cobre", "Oro", "A · Roble", "B · Nogal", "C · Tablones", "D · Anillos"][r]
		name.position = Vector2(14, 44 + r * 112)
		name.add_theme_font_size_override("font_size", 20)
		holder.add_child(name)
	for i in 4: await process_frame
	for entry in dice:
		if entry[1] > 0:
			entry[0].body_shader.shader = SKETCH
			entry[0].body_shader.set_shader_parameter("design", entry[1])
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/boceto-madera")
	root.get_texture().get_image().get_region(Rect2i(0, 0, 1250, 800)).save_png("res://test-results/boceto-madera/madera-opciones.png")
	quit(0)
