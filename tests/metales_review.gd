extends SceneTree
## Capturas de TX3/TX4: los cinco metales con las seis caras, y combinados con gemas y elementos. Requiere GPU (sin --headless).
const Die = preload("res://scripts/die.gd")
func _initialize() -> void:
	var holder := Control.new()
	holder.size = Vector2(1100, 760)
	root.add_child(holder)
	var back := ColorRect.new()
	back.color = Color("244638")
	back.size = holder.size
	holder.add_child(back)
	var rows := [["steel", "", ""], ["copper", "", ""], ["rust_iron", "", ""], ["rust_copper", "", ""], ["gold", "", ""], ["rust_iron", "ruby", "fire"], ["rust_copper", "diamond", "water"], ["gold", "emerald", "wind"], ["gold", "sapphire", "electricity"]]
	for r in rows.size():
		for value in range(1, 7):
			var die := Die.new()
			die.value = value
			die.body_material = rows[r][0]
			die.pip_material = rows[r][1]
			die.element = rows[r][2]
			die.disabled = true
			die.mouse_filter = Control.MOUSE_FILTER_IGNORE
			die.position = Vector2(30 + (value - 1) * 175, 10 + r * 82)
			die.scale = Vector2(1.2, 1.2)
			die.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
			holder.add_child(die)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	root.get_texture().get_image().get_region(Rect2i(0, 0, 1100, 760)).save_png("res://test-results/metales-dados.png")
	print("METALES REVIEW OK")
	quit(0)
