extends RefCounted
## Fase E de docs/PLAN-JEFES.md: animación del termo robado (presentación pura).
const Backdrop = preload("res://scripts/backdrop.gd")
const CatalogTests = preload("res://tests/boss_catalog_tests.gd")
const Presentation = preload("res://scripts/presentation_state.gd")

static func profile(stolen: bool) -> Dictionary:
	return {"environment": "tarde", "actor": "common", "level": 1, "thermos_stolen": stolen}

static func run(scene, check: Callable) -> void:
	var moving := {"reduced_motion": false, "speed": 1}
	var still := {"reduced_motion": true, "speed": 1}
	# Cargar a mitad del jefe: aparece directo en su posición final.
	var loaded := Backdrop.new()
	loaded.configure(profile(true), moving)
	check.call(loaded.thermos_t == 1.0, "Thermos theft: loading mid-boss shows the final floating position")
	# Entrar al jefe en la sesión: sube con ritmo suave y el aviso no se repite.
	var live := Backdrop.new()
	live.configure(profile(false), moving)
	live.configure(profile(true), moving)
	check.call(live.thermos_t == 0.0, "Thermos theft: entering the boss starts from the table")
	live._process(1.0)
	var halfway: float = live.thermos_t
	live.configure(profile(true), moving)
	check.call(halfway > 0.0 and halfway < 1.0 and live.thermos_t == halfway, "Thermos theft: it rises gradually and re-rendering does not restart the flight")
	live._process(10.0)
	check.call(live.thermos_t == 1.0, "Thermos theft: it ends floating next to the hand")
	# Al vencer al jefe vuelve con el recorrido inverso.
	live.configure(profile(false), moving)
	live._process(1.0)
	check.call(live.thermos_t > 0.0 and live.thermos_t < 1.0, "Thermos theft: it returns floating the same way")
	live._process(10.0)
	check.call(live.thermos_t == 0.0, "Thermos theft: it lands back on the table")
	# Movimiento reducido o apagado: cuadro final directo, sin animar.
	var calm := Backdrop.new()
	calm.configure(profile(false), still)
	calm.configure(profile(true), still)
	check.call(calm.thermos_t == 1.0, "Thermos theft: reduced motion shows the final frame")
	calm.configure(profile(false), still)
	check.call(calm.thermos_t == 0.0, "Thermos theft: reduced motion returns it at once")
	var off := Backdrop.new()
	off.configure(profile(false), {"reduced_motion": false, "speed": 0})
	off.configure(profile(true), {"reduced_motion": false, "speed": 0})
	check.call(off.thermos_t == 1.0, "Thermos theft: motion off shows the final frame")
	for backdrop in [loaded, live, calm, off]: backdrop.free()
	# Estado del juego: solo mientras se juega el jefe 2A.
	var cebador = CatalogTests.forced_boss("l2_cebador", true)
	var rival = CatalogTests.forced_boss("l2_cebador", false)
	var other = CatalogTests.forced_boss("l2_referi", true)
	check.call(cebador.thermos_stolen() and not rival.thermos_stolen() and not other.thermos_stolen(), "Thermos theft: stolen only during Don Cebador's encounter")
	check.call(Presentation.profile(cebador).thermos_stolen and not Presentation.profile(rival).thermos_stolen, "Thermos theft: the presentation profile carries the flag")
	var before: Dictionary = cebador.snapshot()
	scene.detail.hide()
	scene.game = cebador
	scene.render()
	var button: Button = scene.ui.get_node("InspectThermos")
	check.call(button.position == Backdrop.STOLEN_THERMOS_RECT.position, "Thermos theft: the thermos button follows the floating thermos")
	button.pressed.emit()
	check.call(scene.detail.title == "Termo robado" and "robó" in scene.detail_text and scene.game.snapshot() == before, "Thermos theft: the button explains the theft without changing the game")
	scene.detail.hide()
	scene.game = rival
	scene.render()
	check.call(scene.ui.get_node("InspectThermos").position == Backdrop.THERMOS_RECT.position, "Thermos theft: the button is back on the table outside the boss")
	cebador.phase = "reward"
	check.call(not cebador.thermos_stolen(), "Thermos theft: it is returned when the boss is beaten")
