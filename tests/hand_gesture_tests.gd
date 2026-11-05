extends RefCounted
## Paso J07: la mano del fondo juega piedra, papel o tijera; cada encuentro muestra la mano del jefe del nivel.
const Campaign = preload("res://scripts/campaign.gd")
const BossCatalog = preload("res://scripts/boss_catalog.gd")
const BossInfo = preload("res://scripts/boss_info.gd")
const BarProps = preload("res://scripts/bar_props.gd")
const Presentation = preload("res://scripts/presentation_state.gd")
const CampaignTests = preload("res://tests/campaign_tests.gd")

static func run(scene, check: Callable) -> void:
	scene.detail.hide()
	scene.confirmation.hide()
	scene.persistence_enabled = false
	scene.preferences_enabled = false
	scene.preferences.reduced_motion = false
	scene.preferences.speed = 1
	# La hoja de poses: 19 manos (18 de jefe + la común) y papel es el dibujo original sin tocar.
	var sheet := Image.load_from_file("res://assets/art/pixel-v3/manos-poses-v3.png")
	var bosses := Image.load_from_file("res://assets/art/pixel-v3/manos-jefes-v3.png")
	var common := Image.load_from_file("res://assets/art/pixel-v3/mano-v3.png")
	check.call(sheet.get_size() == Vector2i(183, 53 * 19) and bosses.get_height() == 53 * 18, "Hand poses: the sheet has rock, paper and scissors for the 18 boss hands and the common one")
	var paper_ok := true
	var rock_differs := true
	for row in range(19):
		var original := (bosses if row < 18 else common).get_region(Rect2i(0, (row if row < 18 else 0) * 53, 61, 53))
		paper_ok = paper_ok and sheet.get_region(Rect2i(61, row * 53, 61, 53)).get_data() == original.get_data()
		rock_differs = rock_differs and sheet.get_region(Rect2i(0, row * 53, 61, 53)).get_data() != original.get_data()
	check.call(paper_ok and rock_differs, "Hand poses: paper is each hand's own drawing and the fist is a different pose of it")
	# Mano de cada encuentro: rivales y jefe del nivel usan la del jefe; Dios y la mano común sin jefe del catálogo.
	var rival = CampaignTests.advance_model(Campaign.prototype(), 0)
	var boss = CampaignTests.advance_model(Campaign.prototype(), 2)
	var boss_id: String = boss.boss_rule.get("id", "")
	scene.game = rival
	scene.render()
	var rival_profile := Presentation.profile(rival)
	check.call(rival.boss_rule.get("id", "") != "" and rival_profile.boss_id == rival.boss_rule.id and scene.background.hand_row == BossCatalog.hand_row(rival.boss_rule.id) and scene.background.hand_row >= 0, "Hand: a common rival shows its level boss's hand")
	scene.game = boss
	scene.render()
	check.call(Presentation.profile(boss).boss_id == boss_id and scene.background.hand_row == BossCatalog.hand_row(boss_id), "Hand: the boss encounter shows the same hand")
	var god = CampaignTests.advance_model(Campaign.prototype(), 20)
	scene.game = god
	scene.render()
	check.call(BossInfo.is_god(god) and god.is_boss() and scene.background.hand_row == -1, "Hand: God has no hand (his guardians are drawn instead)")
	# El gesto.
	var beat0 := BarProps.hand_beat(0, "tijera")
	var beat17 := BarProps.hand_beat(17, "tijera")
	var final := BarProps.hand_beat(20, "tijera")
	check.call(beat0.pose == 0 and beat0.text == "PIEDRA..." and BarProps.hand_beat(6, "tijera").text == "PAPEL..." and beat17.text == "TIJERA..." and not beat17.final, "Hand gesture: three fist beats counting rock, paper, scissors")
	check.call(final.final and final.pose == 2 and final.text == "TIJERA!" and BarProps.hand_beat(20, "piedra").pose == 0 and BarProps.hand_beat(20, "papel").pose == 1, "Hand gesture: the last frames show the chosen play")
	scene.game = rival
	scene.render()
	var before: Dictionary = scene.game.snapshot()
	var hand: Button = scene.ui.get_node("InspectBoss")
	hand.pressed.emit()
	var first: String = scene.background.props.hand_result
	check.call(scene.background.props.busy("hand") and first in BarProps.POSES and not scene.detail.visible, "Hand gesture: clicking the hand starts the gesture")
	hand.pressed.emit()
	check.call(scene.background.props.elapsed.size() == 1 and scene.background.props.hand_result == first, "Hand gesture: repeating the click while it plays changes nothing")
	var drawn := true
	for f in range(28):
		scene.background.props.elapsed["hand"] = (f + 0.5) * BarProps.SPECS.hand.seconds
		scene.background.queue_redraw()
		await scene.get_tree().process_frame
	check.call(drawn and scene.game.snapshot() == before, "Hand gesture: drawing every frame leaves the game state and its randomness untouched")
	scene.background.props.step(10.0)
	check.call(not scene.background.props.busy("hand"), "Hand gesture: it ends by itself and the hand goes back to drumming")
	var results: Dictionary = {}
	for i in range(60):
		scene.background.props.stop_all()
		scene.background.props.play_hand()
		results[scene.background.props.hand_result] = true
	scene.background.props.stop_all()
	check.call(results.size() == 3, "Hand gesture: over many clicks it plays all three")
	# Guardianes: no juegan, siguen mostrando su información.
	scene.game = god
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	check.call(not scene.background.props.busy("hand") and scene.detail.visible and scene.detail.title == "Dios", "Hand gesture: God's guardians do not play; the click shows their information")
	scene.detail.hide()
	# Con movimiento reducido el clic no anima.
	scene.preferences.reduced_motion = true
	scene.game = rival
	scene.render()
	scene.ui.get_node("InspectBoss").pressed.emit()
	check.call(not scene.background.props.busy("hand"), "Hand gesture: with reduced motion the click does not animate")
	scene.preferences.reduced_motion = false
	# El poder del jefe sigue legible al pasar el mouse.
	scene.render()
	check.call(scene.ui.get_node("InspectBoss").tooltip_text != "" and scene.ui.get_node("InspectBoss").get_node("Ring_hand") != null, "Hand gesture: the boss power stays readable on hover and the hand has its gold border")
	scene.preferences.speed = 0
	scene.game = rival
	scene.render()
