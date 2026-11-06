extends RefCounted
## TX2: fondos de ventana animados. Solo presentación: se apagan sin movimiento y no usan el azar de la partida.
const Backdrop = preload("res://scripts/backdrop.gd")
const WindowFx = preload("res://scripts/window_fx.gd")

static func run(scene, check: Callable) -> void:
	for id in ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]:
		check.call(WindowFx.is_animated(id), "TX2: %s tiene fondo animado" % id)
	check.call(not WindowFx.is_animated("cierre"), "TX2: «cierre» (ventanas tapadas) no se anima")
	# El Gótico: solo en el encuentro del jefe, no en rivales, en Dios ni con otros jefes.
	check.call(WindowFx.is_gothic({"boss_id": "l3_gotico", "actor": "boss_power"}), "TX2: la batiseñal aparece con El Gótico como jefe")
	check.call(not WindowFx.is_gothic({"boss_id": "l3_gotico", "actor": "common"}), "TX2: sin batiseñal en los rivales del nivel")
	check.call(not WindowFx.is_gothic({"boss_id": "l3_gotico", "actor": "god"}) and not WindowFx.is_gothic({"boss_id": "l2_conde", "actor": "boss_power"}), "TX2: sin batiseñal con Dios ni con otros jefes")
	# Datos detectados sobre el dibujo aprobado.
	for id in ["dia", "tarde", "noche", "espacio", "agujero_negro", "cielo"]:
		var fx := WindowFx.new()
		fx.setup(id, false)
		check.call(fx.panel != null and fx.panel.get_size() == Vector2i(402, 111), "TX2: %s recorta su panel de 402x111" % id)
		match id:
			"dia": check.call(fx.data.clouds.size() == 5, "TX2: día tiene cinco nubes")
			"tarde": check.call(fx.data.lights.size() >= 12, "TX2: tarde encuentra ventanas para encender (%d)" % fx.data.lights.size())
			"noche":
				check.call(fx.data.windows.size() >= 6, "TX2: noche encuentra sus ventanas amarillas (%d)" % fx.data.windows.size())
				check.call(fx.data.stars.size() >= 10, "TX2: noche encuentra estrellas (%d)" % fx.data.stars.size())
				var biggest := 0
				for star in fx.data.stars: biggest = maxi(biggest, star.px.size())
				check.call(biggest <= 6, "TX2: la luna no titila, solo las estrellas chicas")
			"espacio":
				check.call(fx.data.galaxy.distance_to(Vector2(225, 60)) < 40.0, "TX2: la galaxia se detecta en el centro del disco %s" % str(fx.data.galaxy))
				check.call(fx.data.rocks.size() == 9 and fx.data.rock_textures.size() == 3, "TX2: espacio tiene nueve rocas con sus giros")
			"agujero_negro": check.call(fx.data.hole.distance_to(Vector2(209, 51)) < 8.0, "TX2: el agujero se detecta en su sitio %s" % str(fx.data.hole))
			"cielo": check.call(fx.data.clouds.size() == 4, "TX2: cielo tiene cuatro nubes")
		fx.update_time(3.0)
		check.call(is_equal_approx(fx.t, 3.0), "TX2: %s avanza con el tiempo que le da el fondo" % id)
		fx.free()
	check.call(WindowFx.pick([Vector2i(1, 1), Vector2i(5, 5), Vector2i(9, 9), Vector2i(20, 3)], 3, 5, 3.0) == WindowFx.pick([Vector2i(1, 1), Vector2i(5, 5), Vector2i(9, 9), Vector2i(20, 3)], 3, 5, 3.0), "TX2: los sorteos de presentación son reproducibles")
	check.call(WindowFx.wrap_x(10.0, 5.0, 1000.0, 20.0) >= -24.0 and WindowFx.wrap_x(10.0, 5.0, 1000.0, 20.0) <= 405.0, "TX2: los objetos que cruzan siempre vuelven a entrar")
	# El Backdrop usa la textura animada solo con movimiento y fuera de la tienda.
	var backdrop = Backdrop.new()
	var profile := {"environment": "noche", "actor": "common", "level": 2, "boss_id": "", "thermos_stolen": false}
	backdrop.configure(profile, {"reduced_motion": true, "speed": 1})
	check.call(backdrop.fx_key == "", "TX2: con Reducir movimiento queda el cuadro fijo")
	backdrop.configure(profile, {"reduced_motion": false, "speed": 0})
	check.call(backdrop.fx_key == "", "TX2: con velocidad cero queda el cuadro fijo")
	backdrop.configure(profile, {"reduced_motion": false, "speed": 1})
	check.call(backdrop.fx_key == "noche:false", "TX2: con movimiento se activa el fondo de la noche")
	backdrop.shop_mode = true
	backdrop.configure(profile, {"reduced_motion": false, "speed": 1})
	check.call(backdrop.fx_key == "" and backdrop.window_fx.render_target_update_mode == SubViewport.UPDATE_DISABLED, "TX2: en la tienda se apaga y no consume")
	backdrop.shop_mode = false
	backdrop.configure({"environment": "cierre", "actor": "common", "level": 3, "boss_id": "", "thermos_stolen": false}, {"reduced_motion": false, "speed": 1})
	check.call(backdrop.fx_key == "", "TX2: «cierre» no activa el fondo animado")
	backdrop.configure({"environment": "noche", "actor": "boss_power", "level": 2, "boss_id": "l3_gotico", "thermos_stolen": false}, {"reduced_motion": false, "speed": 1})
	check.call(backdrop.fx_key == "noche:true" and backdrop.window_fx.gothic, "TX2: con El Gótico la noche pasa a mostrar la batiseñal")
	backdrop.free()
