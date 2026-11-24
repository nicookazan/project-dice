extends RefCounted
## Continuar partida: la tienda se guarda al visitarla, el menú ofrece volver a ella y el guardado se borra al terminar o empezar otra jugada.
const SaveStore = preload("res://scripts/save_store.gd")
const ProfileStore = preload("res://scripts/profile_store.gd")
const SaveTests = preload("res://tests/save_tests.gd")

static func run(scene, check: Callable) -> void:
	var old_profiles: bool = scene.profiles_enabled
	var old_store = scene.run_store
	var old_profile_store = scene.profile_store
	var old_game = scene.game
	var old_session: bool = scene.session_started
	scene.profile_store = ProfileStore.new("user://prueba-continuar")
	scene.run_store = SaveStore.new("user://prueba-continuar/ultima-tienda.json")
	scene.profiles_enabled = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://prueba-continuar"))
	scene.clear_run_save()
	# Sin tienda visitada no hay nada que continuar.
	scene.game = SaveTests.shop_game("face", {"number": 4})
	scene.game.phase = "play"
	scene.session_started = true
	scene.render()
	check.call(not scene.has_run_save(), "Continuar: sin tienda visitada no hay guardado")
	# Al estar en la tienda se guarda, y volver al menú ofrece continuar.
	scene.game.phase = "shop"
	scene.render()
	check.call(scene.has_run_save(), "Continuar: al visitar la tienda se guarda la jugada")
	var cash: int = scene.game.cash
	var seed_value: int = scene.game.run_seed
	scene.game.return_to_menu()
	scene.session_started = false
	scene.render()
	check.call(scene.ui.get_node_or_null("MainMenu/ContinueRun") != null and scene.ui.get_node_or_null("MainMenu/NewRun") != null, "Continuar: el menú muestra «Continuar partida» junto a «Nueva jugada»")
	# Continuar vuelve a esa tienda con el mismo estado.
	scene.continue_run()
	check.call(scene.game.phase == "shop" and scene.game.cash == cash and scene.game.run_seed == seed_value and scene.session_started, "Continuar: vuelve a la tienda con la plata y la semilla de antes")
	# Empezar otra jugada o terminar la actual borra el guardado.
	scene.start_new_run(7)
	check.call(not scene.has_run_save(), "Continuar: empezar una jugada nueva borra el guardado")
	scene.game = SaveTests.shop_game("face", {"number": 4})
	scene.render()
	check.call(scene.has_run_save(), "Continuar: la tienda de la jugada nueva se guarda")
	scene.game.phase = "lost"
	scene.render()
	check.call(not scene.has_run_save(), "Continuar: al perder la jugada el guardado se borra")
	# El tutorial y el modo debug no guardan.
	scene.start_new_run(-1, true)
	scene.game = SaveTests.shop_game("face", {"number": 4})
	scene.game.debug_mode = true
	scene.render()
	check.call(not scene.has_run_save(), "Continuar: el modo debug no guarda")
	# Un archivo dañado no se pisa ni rompe el menú.
	var broken := FileAccess.open(scene.run_store.path, FileAccess.WRITE)
	broken.store_string("no es un guardado")
	broken.close()
	check.call(not scene.has_run_save(), "Continuar: un archivo dañado no ofrece continuar")
	scene.clear_run_save()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prueba-continuar"))
	scene.profiles_enabled = old_profiles
	scene.run_store = old_store
	scene.profile_store = old_profile_store
	scene.game = old_game
	scene.session_started = old_session
	scene.render()
