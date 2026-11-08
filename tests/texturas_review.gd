extends SceneTree
## Capturas de TX10: los cinco elementos sobre el seis y sobre el uno, a tamaño de mesa (primer cuadro). Requiere GPU (sin --headless).
const Die = preload("res://scripts/die.gd")
func _initialize() -> void:
	var holder := Control.new()
	holder.size = Vector2(900, 330)
	var back := ColorRect.new()
	back.color = Color("244638")
	back.size = holder.size
	holder.add_child(back)
	var x := 40.0
	for value in [6, 1]:
		x = 40.0
		for element in ["fire", "water", "electricity", "earth", "wind"]:
			var die = Die.new()
			die.value = value
			die.element = element
			die.size = Vector2(62, 62)
			die.position = Vector2(x, 40.0 if value == 6 else 190.0)
			die.scale = Vector2(2, 2)
			holder.add_child(die)
			x += 170.0
	root.add_child(holder)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/texturas-elementos.png")
	print("TX10 REVIEW OK")
	quit(0)
