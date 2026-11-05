extends RefCounted
## Paso J06: el vaso que tira (clic en el vaso o TIRAR) con la animación A.
const Game = preload("res://scripts/game.gd")
const CupThrow = preload("res://scripts/cup_throw.gd")
const UI = preload("res://tests/interface_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	scene.finish_throw()
	# Recorrido del vaso: sacudida, sube a (1230, 372), se inclina 118 grados y vuelve.
	var start := CupThrow.pose(0)
	var lifted := CupThrow.pose(CupThrow.SHAKE + CupThrow.LIFTING + 2)
	var done := CupThrow.pose(CupThrow.FRAMES - 1)
	check.call(CupThrow.FRAMES == 55 and start.center.distance_to(CupThrow.REST) < 1.0 and start.shaking, "Cup throw: 55 frames starting with the shake at the cup's place")
	check.call(lifted.center.is_equal_approx(Vector2(1230, 372)) and is_equal_approx(lifted.rotation, -118.0) and not lifted.shaking, "Cup throw: it lifts to (1230, 372) tilted 118 degrees")
	check.call(done.center.is_equal_approx(CupThrow.REST) and done.rotation == 0.0, "Cup throw: it ends back in its place")
	var mouth := CupThrow.mouth()
	check.call(is_equal_approx(mouth.distance_to(CupThrow.LIFT), 88.0), "Cup throw: the dice leave from the tilted mouth, 88 px from the cup's center")
	# Los dados: ocultos hasta salir, parten de la boca y terminan exactamente en su lugar.
	var landing := Vector2(800, 500)
	check.call(not CupThrow.die_state(0, 5, landing).visible and not CupThrow.die_state(4, 19 + 2, landing).visible, "Cup throw: dice stay hidden behind the cup until their turn")
	var leaving := CupThrow.die_state(0, 19 + 1, Vector2(1100, 430))
	check.call(leaving.visible and leaving.center.distance_to(mouth) < 40.0, "Cup throw: a die first shows up at the cup's mouth")
	var settled := CupThrow.die_state(3, CupThrow.FRAMES - 1, landing)
	check.call(settled.visible and settled.center == landing and settled.spin == 0.0, "Cup throw: every die ends exactly at its landing place")
	# El clic en el vaso tira igual que TIRAR: mismo resultado para la misma semilla.
	scene.game = Game.new(148)
	scene.selected.clear()
	scene.render()
	scene.click_cup()
	var by_cup: Dictionary = scene.game.snapshot()
	check.call(scene.game.rolls_made == 1 and scene.throwing and scene.flying_dice.size() == 5, "Cup throw: clicking the cup rolls once and starts the throw")
	check.call(scene.background.cup_hidden and is_instance_valid(scene.cup_throw) and scene.background.props.busy("cup"), "Cup throw: the cup is drawn apart while it throws")
	scene.click_cup()
	check.call(scene.game.snapshot() == by_cup, "Cup throw: it cannot throw again while it throws")
	scene.step_throw(0.2)
	check.call(scene.flying_dice.all(func(f): return not f.node.visible), "Cup throw: during the shake no die is on the felt yet")
	scene.step_throw(5.0)
	check.call(not scene.throwing and not scene.background.cup_hidden and not is_instance_valid(scene.cup_throw) and not scene.background.props.busy("cup"), "Cup throw: it ends with the cup back in the background and the dice on the felt")
	check.call(UI.dice_in(scene.ui).all(func(d): return d.visible), "Cup throw: all the dice end visible")
	var by_button := Game.new(148)
	scene.game = by_button
	scene.render()
	scene.act(scene.game.roll)
	scene.step_throw(5.0)
	check.call(scene.game.snapshot() == by_cup, "Cup throw: the cup and the TIRAR button give the same roll with the same seed")
	# Sin tiradas, la información; sin movimiento, tirada directa.
	scene.game = Game.new(148)
	scene.game.rolls_left = 0
	scene.render()
	scene.click_cup()
	check.call(scene.detail.visible and scene.game.rolls_made == 0, "Cup throw: with no rolls left the click shows the cup information")
	scene.detail.hide()
	scene.preferences.reduced_motion = true
	scene.game = Game.new(148)
	scene.render()
	scene.click_cup()
	check.call(scene.game.rolls_made == 1 and not scene.throwing and not scene.background.cup_hidden, "Cup throw: with reduced motion the click rolls directly")
	scene.preferences.reduced_motion = false
	# Si la pantalla cambia a mitad de la tirada, todo se limpia.
	scene.game = Game.new(148)
	scene.render()
	scene.click_cup()
	scene.render()
	check.call(not scene.throwing and not scene.background.cup_hidden and not is_instance_valid(scene.cup_throw) and scene.flying_dice.is_empty(), "Cup throw: redrawing mid-throw cleans everything up")
	scene.preferences.speed = 0
	scene.game = Game.new(521)
	scene.render()
