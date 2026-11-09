extends RefCounted
## Paso J05: objetos del bar (sifones, bandera, termo que ceba) y su aro dorado.
const Game = preload("res://scripts/game.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const FeltLayout = preload("res://scripts/felt_layout.gd")
const Drop = preload("res://tests/felt_drop_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	# Estado y tiempos de cada animación.
	var props := BarProps.new()
	check.call(props.play("flag") and not props.play("flag") and props.busy("flag") and props.frame("flag") == 0, "Bar props: an animation starts once and ignores clicks while it runs")
	props.step(10.0)
	check.call(not props.busy("flag") and props.frame("flag") == -1 and not props.any_busy(), "Bar props: the animation ends by itself and returns to the initial state")
	check.call(props.play("thermos") and props.play("soda_left") and props.play("soda_right") and props.any_busy(), "Bar props: every object can play on its own")
	props.step(3.0)
	check.call(not props.busy("thermos") and props.busy("soda_left") and props.frame("soda_left") == 50, "Bar props: each animation runs on its own clock (thermos 5.5 s, soda 3.1 s)")
	props.stop_all()
	props.motion = false
	check.call(not props.play("flag") and not props.any_busy(), "Bar props: with reduced motion nothing animates")
	var rest: Dictionary = BarProps.thermos_pose(0)
	var pouring: Dictionary = BarProps.thermos_pose(30)
	var back: Dictionary = BarProps.thermos_pose(60)
	check.call(rest.center == BarProps.THERMOS_REST and rest.rotation == 0.0 and not rest.over, "Bar props: the thermos starts at its resting place")
	check.call(pouring.center.distance_to(Vector2(950, 402)) < 4.0 and absf(pouring.rotation - 68.0) < 4.0 and pouring.over, "Bar props: it pours at about (950, 402) tilted 68 degrees, in front of the mate")
	check.call(back.center == BarProps.THERMOS_REST and back.rotation == 0.0 and not BarProps.thermos_pose(0).over and BarProps.thermos_pose(20).over, "Bar props: it ends back in place and crosses in front of the mate only while it travels")
	# Zonas en la mesa.
	scene.game = Game.new(521)
	Fixture.set_values(scene.game, [3, 3, 2, 3, 6])
	scene.selected.clear()
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	var names: Array = []
	for child in scene.ui.get_children():
		if child.name.begins_with("BarProp_"): names.append(str(child.name))
	names.sort()
	check.call(names == ["BarProp_flag", "BarProp_soda_left", "BarProp_soda_right"], "Bar props: the table has a zone over the flag and each siphon")
	var clear_of_felt := true
	for id in BarProps.ZONES:
		if id != "shop_flag": clear_of_felt = clear_of_felt and BarProps.ZONES[id].end.y < FeltLayout.TOP
	check.call(clear_of_felt, "Bar props: the zones are above the felt, so they never block dropping dice")
	scene.background.props.stop_all()
	for id in ["flag", "soda_left", "soda_right"]:
		scene.ui.get_node("BarProp_" + id).clicked.emit()
		check.call(scene.background.props.busy(id), "Bar props: clicking %s starts its animation" % id)
	scene.ui.get_node("BarProp_flag").clicked.emit()
	check.call(scene.background.props.elapsed.size() == 3, "Bar props: a second click on a running object is ignored")
	# El estado de la partida y el azar quedan iguales aunque se anime y se dibuje cada cuadro.
	scene.background.props.stop_all()
	scene.background.props.play("thermos")
	scene.background.props.play("soda_left")
	scene.background.props.play("flag")
	for f in range(78):
		scene.background.props.elapsed["thermos"] = (f + 0.5) * BarProps.SPECS.thermos.seconds
		scene.background.props.elapsed["soda_left"] = (mini(f, 51) + 0.5) * BarProps.SPECS.soda_left.seconds
		scene.background.props.elapsed["flag"] = (mini(f, 33) + 0.5) * BarProps.SPECS.flag.seconds
		scene.background.queue_redraw()
		scene.background.pour_layer.queue_redraw()
		await scene.get_tree().process_frame
	check.call(scene.game.snapshot() == before, "Bar props: animating and drawing every frame leaves the game state and its randomness untouched")
	scene.background.props.stop_all()
	# El termo: un clic ceba el mate y no abre ventana; durante la animación no acepta otro.
	scene.render()
	var thermos: Button = scene.ui.get_node("InspectThermos")
	thermos.pressed.emit()
	var started: float = scene.background.props.elapsed.get("thermos", -1.0)
	thermos.pressed.emit()
	check.call(started == 0.0 and scene.background.props.elapsed.size() == 1 and scene.background.props.elapsed.thermos == 0.0 and not scene.detail.visible, "Bar props: the thermos pours on click, opens no window and ignores clicks while pouring")
	# Con movimiento apagado no se anima nada, pero el aro sigue señalando lo clickeable.
	scene.background.props.stop_all()
	scene.preferences.reduced_motion = true
	scene.render()
	scene.ui.get_node("InspectThermos").pressed.emit()
	scene.ui.get_node("BarProp_flag").clicked.emit()
	check.call(not scene.background.props.any_busy(), "Bar props: with reduced motion the clicks do nothing visible")
	scene.preferences.reduced_motion = false
	scene.render()
	# Aro dorado: aparece al pasar el mouse y se apaga mientras anima.
	var zone: Control = scene.ui.get_node("BarProp_soda_left")
	var ring = zone.get_node("Ring_soda_left")
	zone.mouse_entered.emit()
	ring._process(0.0)
	check.call(ring.visible and ring.texture != null and ring.position == BarProps.RINGS.soda_left[1], "Bar props: hovering a siphon shows its gold border on its silhouette")
	scene.background.props.play("soda_left")
	ring._process(0.0)
	check.call(not ring.visible, "Bar props: the border hides while the object animates")
	scene.background.props.stop_all()
	zone.mouse_exited.emit()
	ring._process(0.0)
	check.call(not ring.visible, "Bar props: the border is gone when the mouse leaves")
	var thermos_ring = scene.ui.get_node("InspectThermos").get_node("Ring_thermos")
	check.call(thermos_ring != null and thermos_ring.texture != null, "Bar props: the thermos has its gold border too")
	# Al cambiar de pantalla las animaciones se cortan; la tienda se arma sobre la misma mesa y conserva bandera y sifones.
	scene.background.props.play("flag")
	scene.preferences.speed = 1
	scene.game.phase = "shop"
	scene.render()
	var shop_zones: Array = []
	for child in scene.ui.get_children():
		if child.name.begins_with("BarProp_"): shop_zones.append(str(child.name))
	check.call(not scene.background.props.any_busy() and shop_zones == ["BarProp_flag", "BarProp_soda_left", "BarProp_soda_right"], "Bar props: changing screen cuts the animations and the shop keeps the room's flag and siphons")
	var shop_before: Dictionary = scene.game.snapshot()
	for prop in ["flag", "soda_left", "soda_right"]:
		scene.ui.get_node("BarProp_" + prop).clicked.emit()
	check.call(scene.background.props.busy("flag") and scene.background.props.busy("soda_left") and scene.background.props.busy("soda_right"), "Bar props: in the shop the flag waves and the siphons spray when clicked")
	for f in range(34):
		scene.background.props.step(0.07)
		scene.background.queue_redraw()
		await scene.get_tree().process_frame
	check.call(scene.game.snapshot() == shop_before, "Bar props: drawing the room animations in the shop leaves the game untouched")
	scene.background.props.step(10.0)
	check.call(not scene.background.props.any_busy(), "Bar props: the shop's room animations stop by themselves")
	scene.ui.get_node("InspectThermos").pressed.emit()
	check.call(scene.background.props.busy("thermos") and scene.game.snapshot() == shop_before, "Bar props: in the shop the thermos also pours the mate")
	scene.background.props.stop_all()
	scene.game = Game.new(521)
	scene.preferences.speed = 0
	scene.render()
