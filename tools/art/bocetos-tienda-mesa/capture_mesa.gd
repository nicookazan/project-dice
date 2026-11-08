extends SceneTree
## Captura de la mesa de juego antes de tirar, para el boceto de la tienda sobre la mesa (08/11/2026).
## Uso (con GPU, sin --headless): godot --path . --script res://tools/art/bocetos-tienda-mesa/capture_mesa.gd
const Game = preload("res://scripts/game.gd")
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	scene.game = Game.new(160)
	scene.render()
	await capture("mesa")
	# Mesa limpia: sin vaso, sin botones de juego ni textos de la libreta (el boceto dibuja los suyos).
	scene.background.cup_hidden = true
	scene.background.queue_redraw()
	for node in all_nodes(scene):
		if node is BaseButton or node is Label or node is RichTextLabel or node is ScrollContainer: node.visible = false
	await capture("mesa-limpia")
	scene.background.cup_hidden = false
	scene.background.queue_redraw()
	await capture("mesa-limpia-vaso")
	quit()

func capture(caption: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-results/bocetos-tienda-mesa"))
	root.get_texture().get_image().save_png("res://test-results/bocetos-tienda-mesa/" + caption + ".png")
	print("captura ", caption)

func all_nodes(n: Node) -> Array:
	var out := [n]
	for c in n.get_children(): out.append_array(all_nodes(c))
	return out
