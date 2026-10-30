extends SceneTree
const Tests = preload("res://tests/campaign_tests.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Profile = preload("res://scripts/validation_profile.gd")
const Store = preload("res://scripts/save_store.gd")
const Boss = preload("res://scripts/boss_rules.gd")
const Fixture = preload("res://tests/support/game_fixture.gd")
const Flow = preload("res://tests/level_flow_tests.gd")
var scene
var prefix := ""

func win(game) -> void:
	Fixture.set_values(game, [4, 4, 4, 4, 4])
	if Boss.forbidden(game.boss_context(), "Generala"):
		game.form_group([0, 1, 2])
		game.form_group([3, 4])
	else: game.form_group([0, 1, 2, 3, 4])
	game.score_hand()
	game.close_encounter()

func _initialize() -> void:
	scene = load("res://main.tscn").instantiate()
	scene.persistence_enabled = false
	root.add_child(scene)
	await process_frame
	prefix = str(root.size.x) + "x" + str(root.size.y) + "-campana-"
	await capture("menu")
	scene.start_new_run(601)
	await capture("anuncio-inicial")
	scene.game = Tests.advance_model(Campaign.prototype(), 2)
	Profile.apply(scene.game)
	win(scene.game)
	scene.game.open_shop()
	scene.render()
	await capture("tienda-tras-jefe")
	Flow.click(scene, "Entrar al nivel 2 →")
	await capture("anuncio-siguiente")
	scene.save_store = Store.new("res://test-results/campaign-review/" + str(Time.get_ticks_usec()) + "/partida.json")
	scene.persistence_enabled = true
	scene.session_started = true
	var created: Dictionary = scene.save_store.start(scene.checkpoint_data())
	if not created.ok:
		push_error(created.message)
		quit(1)
		return
	scene.last_checkpoint = scene.checkpoint_data()
	var before: Dictionary = scene.checkpoint_data()
	Flow.click(scene, "Volver al menú")
	Flow.click(scene, "Continuar")
	if scene.checkpoint_data() != before:
		push_error("Campaign review resume mismatch")
		quit(1)
		return
	await capture("anuncio-reanudado")
	scene.persistence_enabled = false
	scene.show_route()
	await capture("recorrido-21")
	scene.detail.hide()
	scene.game = Tests.advance_model(Campaign.prototype(), 6)
	scene.render()
	await capture("ambiente-noche")
	scene.game = Tests.advance_model(Campaign.prototype(), 20)
	scene.render()
	await capture("dios")
	win(scene.game)
	scene.render()
	await capture("victoria-final")
	scene.game = Tests.advance_model(Campaign.prototype(), 20)
	scene.game.global_points = {}
	for hand in range(2):
		Fixture.set_values(scene.game, [1, 2, 2, 4, 6])
		scene.game.score_hand()
		if hand == 0: scene.game.next_hand()
	scene.render()
	await capture("derrota-dios")
	print("CAMPAIGN REVIEW: 10 captures, exact level-boundary UI resume, laboratory scenes")
	quit()

func capture(caption: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + prefix + caption + ".png")
