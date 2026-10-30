extends SceneTree
const UI = preload("res://tests/interface_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	prefix = "%dx%d-debug-" % [root.size.x, root.size.y]
	await capture("menu")
	UI.find_button(scene.ui, "Nueva partida debug").pressed.emit()
	await capture("inicio")
	UI.find_button(scene.ui, "Empezar primer encuentro").pressed.emit()
	UI.find_button(scene.ui, "TIRAR (3)").pressed.emit()
	await capture("mano")
	UI.find_button(scene.ui, "ANOTAR MANO").pressed.emit()
	await capture("anotado")
	scene.game.close_encounter()
	scene.game.open_shop()
	scene.game.cash = 0
	scene.render()
	await capture("tienda")
	print("DEBUG REVIEW: menu, marked intro, damage preview, win and unlimited shop at zero cash")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
