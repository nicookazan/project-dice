extends SceneTree
## Revisión visual de La Semilla (docs/LA-SEMILLA.md): semilla chica, muerte del guardián, bar agrietado, mano con el
## maletín, derrumbe, viaje de la semilla, terminal final y créditos. Escribe en test-results/la-semilla/.
## Uso (con GPU, sin --headless): godot --path . --script res://tests/la_semilla_review.gd
const T = preload("res://tests/la_semilla_tests.gd")
const Game = preload("res://scripts/game.gd")
const OUT := "res://test-results/la-semilla"
var scene

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	root.size = Vector2i(1440, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	scene = load("res://main.tscn").instantiate()
	scene.profiles_enabled = false
	scene.preferences_enabled = false
	scene.preferences.muted = true
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	root.add_child(scene)
	await process_frame
	# Semilla chica en la mesa del nivel 7.
	var table = Game.new(2847193650)
	table.begin_campaign(2847193650)
	table.jump_to_level(6)
	table.begin_level()
	scene.game = table
	scene.session_started = true
	scene.render()
	await shot("01-semilla-chica")
	# El bar cruje con el guardián vivo; la mano con el maletín.
	scene.game = T.at_guardian_reward(2847193650)
	scene.finale_shown = ""
	scene.render()
	await shot("02-bar-cruje")
	scene.act(scene.game.open_shop)
	await shot("03-mano-maletin")
	# Al salir de la mano: muere el guardián (A1) y después se derrumba el bar (B1).
	scene.act(scene.game.leave_shop)
	for t in [0.45, 1.1, 1.45, 1.9, 2.4]:
		scene.background.finale.t = t
		await shot("04-muerte-%.2f" % t, false)
	scene.background.finale.stop()
	scene._on_finale_finished("death")
	for t in [0.4, 1.4, 2.4, 3.2, 3.9]:
		scene.background.finale.t = t
		scene.background.finale.sim_frame = -1
		scene.background.finale.blocks = []
		scene.background.finale.dust = []
		for f in int(t / 0.09): scene.background.finale._simulate_collapse(f)
		scene.background.finale.sim_frame = int(t / 0.09)
		await shot("05-derrumbe-%.2f" % t, false)
	scene.background.finale.stop()
	scene._on_finale_finished("collapse")
	for t in [0.4, 1.0, 1.8, 2.6, 3.3]:
		scene.ui.get_node("SeedDisplay").elapsed = t
		await shot("06-viaje-%.2f" % t, false)
	scene._on_seed_intro_finished()
	await shot("07-semilla-final")
	scene.click_hand()
	await shot("08-poder")
	scene.detail.hide()
	# Victoria: tiembla, la mesa cae y la semilla y la Matrix se apagan; después, solos, créditos y recompensas.
	T.beat(scene.game)
	scene.run_recorded = true
	scene.render()
	# En tiempo real: la interfaz cae con su propia animación.
	var waited := 0.0
	for t in [0.6, 1.6, 2.3, 3.0, 3.8]:
		await create_timer(t - waited).timeout
		waited = t
		await shot("09-victoria-%.2f" % t, false)
	await create_timer(1.0).timeout
	await shot("10-creditos")
	scene.show_rewards()
	await shot("11-recompensas")
	quit()

func shot(name: String, settle := true) -> void:
	for i in (4 if settle else 1): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
	print("captura ", name)
