extends SceneTree
## Capturas de las pantallas de D20 (menú en la mesa, selección de encuentro, cobro, ayuda de la mano) recorriendo el
## flujo real con los botones. Requiere GPU (sin --headless):
##   godot --path . --script res://tests/pantallas_review.gd
const Tests = preload("res://tests/encounter_choice_tests.gd")
var scene
var prefix := ""

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = true
	root.add_child(scene)
	await process_frame
	prefix = "pantallas-"
	await capture("1-menu")
	press("NewRun")
	await capture("2-modos")
	press("ModeCampaign")
	await capture("3-tutorial")
	press("TutorialBack")
	press("PanelBack")
	press("Collections")
	await capture("4-colecciones")
	press("PanelBack")
	scene.start_new_run(7)
	await capture("5-seleccion-primer-encuentro")
	press("PlayNext")
	await capture("6-mesa")
	scene.game = Tests.reward_game()
	scene.render()
	await capture("7-cobro")
	press("ContinueReward")
	await capture("8-seleccion-rival-2")
	press("OpenShop")
	await capture("9-tienda")
	press("ShopAdvance")
	await capture("10-vuelta-de-la-tienda")
	press("PlayNext")
	var hand: Control = scene.ui.find_child("InspectBoss", true, false)
	var motion := InputEventMouseMotion.new()
	motion.position = hand.get_global_rect().get_center() * Vector2(root.size) / Vector2(1440, 900)
	Input.warp_mouse(motion.position)
	root.push_input(motion, true)
	await capture("11-ayuda-mano")
	print("PANTALLAS REVIEW: listo")
	quit()

func press(node_name: String) -> void:
	var control = scene.ui.find_child(node_name, true, false)
	if control == null or control.disabled:
		push_error("No se pudo tocar " + node_name)
		return
	control.pressed.emit()

func capture(caption: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1440, 900): image.resize(1440, 900, Image.INTERPOLATE_NEAREST)
	image.save_png("res://test-results/" + prefix + caption + ".png")
